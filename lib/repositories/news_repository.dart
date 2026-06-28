import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/article.dart';
import '../services/firestore_cache.dart';
import '../services/hive_cache.dart';
import '../services/worker_service.dart';

class NewsRepository {
  final WorkerService _workerService = WorkerService();
  final HiveCache _hiveCache = HiveCache();
  final FirestoreCache _firestoreCache = FirestoreCache();

  Future<List<Article>> fetchByCategory(String category) async {
    try {
      final articles = await _workerService.fetchNews(category: category);
      return await _resolveArticlesClientSide(articles);
    } catch (e) {
      print('[NewsRepository] fetchByCategory: $e');
      rethrow;
    }
  }

  Future<List<Article>> searchArticles(String query) async {
    try {
      final articles = await _workerService.fetchNews(query: query);
      return await _resolveArticlesClientSide(articles);
    } catch (e) {
      print('[NewsRepository] searchArticles: $e');
      rethrow;
    }
  }

  Future<List<Article>> _resolveArticlesClientSide(List<Article> articles) async {
    final futures = articles.map((article) async {
      try {
        if (!article.url.contains('news.google.com')) {
          return article;
        }
        final realUrl = await _resolveRedirect(article.url);
        if (realUrl.contains('news.google.com')) {
          return article;
        }
        return article.copyWithScrapeDetails(
          description: article.description,
          imageUrl: article.urlToImage,
          resolvedUrl: realUrl,
        );
      } catch (e) {
        print('[NewsRepository] _resolveArticlesClientSide: $e');
        return article;
      }
    });
    return await Future.wait(futures, eagerError: false);
  }

  Future<Article> getArticleDetails(Article article, {required Function(Article) onUpdated}) async {
    final url = article.url;
    if (url.isEmpty) return article;

    final String workingUrl;
    try {
      workingUrl = url.contains('news.google.com')
          ? await _resolveRedirect(url)
          : url;
    } catch (e) {
      print('[NewsRepository] getArticleDetails url resolution: $e');
      return article;
    }

    if (workingUrl.contains('news.google.com')) {
      return article;
    }

    Article? cached;
    try {
      cached = _hiveCache.getArticle(workingUrl);
    } catch (e) {
      print('[NewsRepository] HiveCache read in getArticleDetails: $e');
    }

    if (cached != null) {
      bool isFresh = false;
      try {
        isFresh = _hiveCache.isFresh(workingUrl, Constants.detailTtl);
      } catch (e) {
        print('[NewsRepository] HiveCache isFresh: $e');
      }

      if (isFresh) {
        return cached;
      }
      
      _backgroundRevalidate(article, onUpdated);
      return cached;
    }

    Article? firestoreArticle;
    try {
      firestoreArticle = await _firestoreCache.getArticle(workingUrl);
    } catch (e) {
      print('[NewsRepository] FirestoreCache read in getArticleDetails: $e');
    }

    if (firestoreArticle != null) {
      try {
        await _hiveCache.saveArticle(workingUrl, firestoreArticle);
      } catch (e) {
        print('[NewsRepository] HiveCache write in getArticleDetails: $e');
      }
      return firestoreArticle;
    }

    final Map<String, String?> scraped;
    try {
      scraped = await _workerService.scrapeArticle(workingUrl, title: article.title);
    } catch (e) {
      print('[NewsRepository] Worker scrapeArticle in getArticleDetails: $e');
      return article;
    }

    final updatedArticle = article.copyWithScrapeDetails(
      description: scraped['description'],
      imageUrl: scraped['imageUrl'],
      resolvedUrl: scraped['url'] ?? workingUrl,
    );

    try {
      await _hiveCache.saveArticle(workingUrl, updatedArticle);
    } catch (e) {
      print('[NewsRepository] HiveCache save updatedArticle in getArticleDetails: $e');
    }

    try {
      await _firestoreCache.saveArticle(workingUrl, updatedArticle);
    } catch (e) {
      print('[NewsRepository] FirestoreCache save updatedArticle in getArticleDetails: $e');
    }

    return updatedArticle;
  }

  Future<void> _backgroundRevalidate(Article article, Function(Article) onUpdated) async {
    final url = article.url;
    if (url.isEmpty) return;

    try {
      final String workingUrl;
      try {
        workingUrl = url.contains('news.google.com')
            ? await _resolveRedirect(url)
            : url;
      } catch (e) {
        print('[NewsRepository] _backgroundRevalidate url resolution: $e');
        return;
      }

      if (workingUrl.contains('news.google.com')) {
        return;
      }

      Article? firestoreArticle;
      try {
        firestoreArticle = await _firestoreCache.getArticle(workingUrl);
      } catch (e) {
        print('[NewsRepository] FirestoreCache read in _backgroundRevalidate: $e');
      }

      if (firestoreArticle != null) {
        try {
          await _hiveCache.saveArticle(workingUrl, firestoreArticle);
        } catch (e) {
          print('[NewsRepository] HiveCache write firestoreArticle in _backgroundRevalidate: $e');
        }
        onUpdated(firestoreArticle);
        return;
      }

      final Map<String, String?> scraped;
      try {
        scraped = await _workerService.scrapeArticle(workingUrl, title: article.title);
      } catch (e) {
        print('[NewsRepository] Worker scrapeArticle in _backgroundRevalidate: $e');
        return;
      }

      final updatedArticle = article.copyWithScrapeDetails(
        description: scraped['description'],
        imageUrl: scraped['imageUrl'],
        resolvedUrl: scraped['url'] ?? workingUrl,
      );

      try {
        await _hiveCache.saveArticle(workingUrl, updatedArticle);
      } catch (e) {
        print('[NewsRepository] HiveCache save updatedArticle in _backgroundRevalidate: $e');
      }

      try {
        await _firestoreCache.saveArticle(workingUrl, updatedArticle);
      } catch (e) {
        print('[NewsRepository] FirestoreCache save updatedArticle in _backgroundRevalidate: $e');
      }

      onUpdated(updatedArticle);
    } catch (e) {
      print('[NewsRepository] _backgroundRevalidate outer error: $e');
    }
  }

  Future<String> _resolveRedirect(String url) async {
    if (!url.contains('news.google.com')) return url;
    try {
      final uri = Uri.parse(url);
      final pathParts = uri.pathSegments;
      final articlesIdx = pathParts.indexOf('articles');
      if (articlesIdx == -1 || articlesIdx + 1 >= pathParts.length) return url;
      final base64Id = pathParts[articlesIdx + 1];
      if (base64Id.isEmpty) return url;

      // Try decoding base64url offline first (old style decoder fallback)
      try {
        String base64Standard = base64Id.replaceAll('-', '+').replaceAll('_', '/');
        while (base64Standard.length % 4 != 0) {
          base64Standard += '=';
        }
        final decodedBytes = base64.decode(base64Standard);
        final decodedStr = utf8.decode(decodedBytes, allowMalformed: true);
        
        // Strip prefix if any
        String cleanStr = decodedStr;
        final prefix = String.fromCharCodes([0x08, 0x13, 0x22]);
        if (cleanStr.startsWith(prefix)) {
          cleanStr = cleanStr.substring(prefix.length);
        } else if (cleanStr.isNotEmpty && cleanStr.codeUnitAt(0) == 0x08) {
          cleanStr = cleanStr.substring(1);
        }

        // Strip suffix if any
        final suffix = String.fromCharCodes([0xd2, 0x01, 0x00]);
        if (cleanStr.endsWith(suffix)) {
          cleanStr = cleanStr.substring(0, cleanStr.length - suffix.length);
        }

        if (cleanStr.isNotEmpty) {
          final len = cleanStr.codeUnitAt(0);
          if (len >= 0x80) {
            cleanStr = cleanStr.substring(2, len + 2);
          } else {
            cleanStr = cleanStr.substring(1, len + 1);
          }
        }

        if (!cleanStr.startsWith('AU_yqL') && (cleanStr.startsWith('http://') || cleanStr.startsWith('https://'))) {
          return cleanStr;
        }
      } catch (_) {
        // Fallback to batchexecute API
      }

      // Resolve new style 'AU_yqL' via Google's batchexecute API
      final innerPayload = [
        "garturlreq",
        [
          ["en-US", "US", ["FINANCE_TOP_INDICES", "WEB_TEST_1_0_0"], null, null, 1, 1, "US:en", null, 180, null, null, null, null, null, 0, null, null, [1608992183, 723341000]],
          "en-US",
          "US",
          1,
          [2, 3, 4, 8],
          1,
          0,
          "655000234",
          0,
          0,
          null,
          0
        ],
        base64Id
      ];

      final outerPayload = [[["Fbv4je", json.encode(innerPayload), null, "generic"]]];

      final response = await http.post(
        Uri.parse("https://news.google.com/_/DotsSplashUi/data/batchexecute?rpcids=Fbv4je"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded;charset=utf-8",
          "Referer": "https://news.google.com/",
        },
        body: 'f.req=${Uri.encodeQueryComponent(json.encode(outerPayload))}',
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return url;
      final text = response.body;

      const header = r'[\"garturlres\",\"';
      const footer = r'\",';
      if (!text.contains(header)) {
        return url;
      }
      final startIdx = text.indexOf(header) + header.length;
      final start = text.substring(startIdx);
      final endIdx = start.indexOf(footer);
      if (endIdx == -1) return url;
      
      String resolvedUrl = start.substring(0, endIdx);
      resolvedUrl = resolvedUrl.replaceAll(r'\/', '/');
      return resolvedUrl;
    } catch (e) {
      return url;
    }
  }
}
