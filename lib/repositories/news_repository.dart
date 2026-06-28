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
    return await _workerService.fetchNews(category: category);
  }

  /// Searches articles.
  Future<List<Article>> searchArticles(String query) async {
    return await _workerService.fetchNews(query: query);
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

    // Completely new: Trigger scrape via Worker
    try {
      final scraped = await _workerService.scrapeArticle(url, title: article.title);
      final updatedArticle = article.copyWithScrapeDetails(
        description: scraped['description'],
        imageUrl: scraped['imageUrl'],
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

      // 2. Fetch fresh by scraping via Worker
      final scraped = await _workerService.scrapeArticle(url, title: article.title);
      final updatedArticle = article.copyWithScrapeDetails(
        description: scraped['description'],
        imageUrl: scraped['imageUrl'],
      );

      // Update both caches
      await _hiveCache.saveArticle(url, updatedArticle);
      await _firestoreCache.saveArticle(url, updatedArticle);
      onUpdated(updatedArticle);
    } catch (e) {
      print('[NewsRepository] Background revalidation failed: $e');
    }
  }
}
