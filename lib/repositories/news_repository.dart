import 'dart:io';
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

  /// Uses dart:io HttpClient to follow the full redirect chain from the mobile device.
  /// Mobile IPs are not blocked by Google, unlike Cloudflare Worker datacenter IPs.
  Future<String> _resolveRedirect(String url) async {
    try {
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 8);
      final request = await httpClient.getUrl(Uri.parse(url));
      request.followRedirects = true;
      request.maxRedirects = 10;
      final response = await request.close();
      String finalUrl = url;
      if (response.redirects.isNotEmpty) {
        finalUrl = response.redirects.last.location.toString();
      } else {
        // If no redirect objects, use the response's actual URI
        finalUrl = response.headers.value('location') ?? url;
      }
      await response.drain();
      httpClient.close();
      return finalUrl;
    } catch (e) {
      return url;
    }
  }
}
