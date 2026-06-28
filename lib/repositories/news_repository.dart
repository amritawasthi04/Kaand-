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

  /// Fetches news by category. Employs a quick cache read first for RSS parsed lists.
  Future<List<Article>> fetchByCategory(String category) async {
    final articles = await _workerService.fetchNews(category: category);
    return await _resolveArticlesRedirects(articles);
  }

  /// Searches articles.
  Future<List<Article>> searchArticles(String query) async {
    final articles = await _workerService.fetchNews(query: query);
    return await _resolveArticlesRedirects(articles);
  }

  /// Scrapes the detail details of an article (body content description, image url)
  /// using Stale-While-Revalidate (SWR) logic.
  /// Calls [onUpdated] callback when background refresh finishes with new data.
  Future<Article> getArticleDetails(Article article, {required Function(Article) onUpdated}) async {
    final url = article.url;
    if (url.isEmpty) return article;

    // 1. Check local Hive Cache
    final cached = _hiveCache.getArticle(url);
    if (cached != null) {
      final isFresh = _hiveCache.isFresh(url, Constants.detailTtl);
      if (isFresh) {
        return cached;
      }
      
      // STALE: return cached immediately, fetch fresh in background
      _backgroundRevalidate(article, onUpdated);
      return cached;
    }

    // MISS: No local cache.
    // Try shared Firestore Cache first
    final firestoreArticle = await _firestoreCache.getArticle(url);
    if (firestoreArticle != null) {
      await _hiveCache.saveArticle(url, firestoreArticle);
      return firestoreArticle;
    }

    // Completely new: Resolve redirect on client then scrape via Worker
    try {
      String scrapeUrl = url;
      if (url.contains('news.google.com')) {
        scrapeUrl = await _resolveRedirect(url);
      }
      final scraped = await _workerService.scrapeArticle(scrapeUrl, title: article.title);
      final updatedArticle = article.copyWithScrapeDetails(
        description: scraped['description'],
        imageUrl: scraped['imageUrl'],
        resolvedUrl: scraped['url'] ?? scrapeUrl,
      );

      // Save to Hive and Firestore
      await _hiveCache.saveArticle(url, updatedArticle);
      await _firestoreCache.saveArticle(url, updatedArticle);
      return updatedArticle;
    } catch (e) {
      print('[NewsRepository] Error scraping article details: $e');
      return article; // Return original
    }
  }

  /// Background revalidation logic for stale articles
  Future<void> _backgroundRevalidate(Article article, Function(Article) onUpdated) async {
    final url = article.url;
    try {
      // 1. Fetch fresh from Firestore cache
      final firestoreArticle = await _firestoreCache.getArticle(url);
      if (firestoreArticle != null) {
        await _hiveCache.saveArticle(url, firestoreArticle);
        onUpdated(firestoreArticle);
        return;
      }

      // 2. Fetch fresh by scraping via Worker (resolve redirect first)
      String scrapeUrl = url;
      if (url.contains('news.google.com')) {
        scrapeUrl = await _resolveRedirect(url);
      }
      final scraped = await _workerService.scrapeArticle(scrapeUrl, title: article.title);
      final updatedArticle = article.copyWithScrapeDetails(
        description: scraped['description'],
        imageUrl: scraped['imageUrl'],
        resolvedUrl: scraped['url'] ?? scrapeUrl,
      );

      // Update both caches
      await _hiveCache.saveArticle(url, updatedArticle);
      await _firestoreCache.saveArticle(url, updatedArticle);
      onUpdated(updatedArticle);
    } catch (e) {
      print('[NewsRepository] Background revalidation failed: $e');
    }
  }

  /// Resolves the redirects of multiple articles in parallel on the client side.
  Future<List<Article>> _resolveArticlesRedirects(List<Article> articles) async {
    final futures = articles.map((article) async {
      if (article.url.startsWith('https://news.google.com')) {
        final resolvedUrl = await _resolveRedirect(article.url);
        return article.copyWithScrapeDetails(
          description: article.description,
          imageUrl: article.urlToImage,
          resolvedUrl: resolvedUrl,
        );
      }
      return article;
    });
    return await Future.wait(futures);
  }

  /// Resolves Google News redirect URLs to original publisher URLs on the client device
  /// using Google's internal batchexecute API. Since Google News redirect links
  /// return a 200 OK HTML page with JavaScript-based redirection (not a standard
  /// 301/302 HTTP redirect), standard redirect followers fail. This method resolves
  /// them directly and quickly from the phone (which is not blocked by Google WAF).
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
