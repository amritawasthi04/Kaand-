import '../core/constants.dart';
import '../models/article.dart';
import '../services/api_service.dart';
import '../services/hive_cache.dart';

class NewsRepository {
  final ApiService _apiService = ApiService();
  final HiveCache _hiveCache = HiveCache();

  Future<List<Article>> fetchByCategory(String category, {void Function(List<Article>)? onUpdated}) async {
    final cacheKey = 'category_$category';
    final cached = _hiveCache.getArticleList(cacheKey);
    final isFresh = _hiveCache.isFresh(cacheKey, Constants.headlinesTtl);

    if (cached != null) {
      if (!isFresh && onUpdated != null) {
        _backgroundFetchCategory(category, cacheKey, onUpdated);
      }
      return cached;
    }

    final fresh = await _apiService.fetchNews(category: category == 'general' ? null : category);
    await _hiveCache.saveArticleList(cacheKey, fresh);
    return fresh;
  }

  Future<List<Article>> fetchGuardian({String? section, void Function(List<Article>)? onUpdated}) async {
    final cacheKey = 'guardian_${section ?? 'world'}';
    final cached = _hiveCache.getArticleList(cacheKey);
    final isFresh = _hiveCache.isFresh(cacheKey, Constants.headlinesTtl);

    if (cached != null) {
      if (!isFresh && onUpdated != null) {
        _backgroundFetchGuardian(section, cacheKey, onUpdated);
      }
      return cached;
    }

    final fresh = await _apiService.fetchGuardian(section: section);
    await _hiveCache.saveArticleList(cacheKey, fresh);
    return fresh;
  }

  Future<Article> getArticleDetails(Article article, {required void Function(Article) onUpdated}) async {
    final cacheKey = 'detail_${article.url}';
    final cached = _hiveCache.getArticle(cacheKey);
    final isFresh = _hiveCache.isFresh(cacheKey, Constants.headlinesTtl);

    if (cached != null) {
      if (!isFresh) {
        _backgroundFetchDetails(article.url, cacheKey, onUpdated);
      }
      return cached;
    }

    final fresh = await _apiService.fetchArticleDetails(article.url);
    final merged = article.copyWithScrapeDetails(
      description: fresh.description,
      imageUrl: fresh.urlToImage,
      summary: fresh.summary,
      content: fresh.content,
      readTime: fresh.readTime,
      author: fresh.author,
      tags: fresh.tags,
    );
    await _hiveCache.saveArticle(cacheKey, merged);
    return merged;
  }

  Future<void> _backgroundFetchCategory(String category, String cacheKey, void Function(List<Article>) onUpdated) async {
    try {
      final fresh = await _apiService.fetchNews(category: category == 'general' ? null : category);
      await _hiveCache.saveArticleList(cacheKey, fresh);
      onUpdated(fresh);
    } catch (e) {
      print('[NewsRepository] Background fetch category error: $e');
    }
  }

  Future<void> _backgroundFetchGuardian(String? section, String cacheKey, void Function(List<Article>) onUpdated) async {
    try {
      final fresh = await _apiService.fetchGuardian(section: section);
      await _hiveCache.saveArticleList(cacheKey, fresh);
      onUpdated(fresh);
    } catch (e) {
      print('[NewsRepository] Background fetch Guardian error: $e');
    }
  }

  Future<void> _backgroundFetchDetails(String url, String cacheKey, void Function(Article) onUpdated) async {
    try {
      final fresh = await _apiService.fetchArticleDetails(url);
      await _hiveCache.saveArticle(cacheKey, fresh);
      onUpdated(fresh);
    } catch (e) {
      print('[NewsRepository] Background fetch details error: $e');
    }
  }
}
