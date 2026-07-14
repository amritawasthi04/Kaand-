import '../core/constants.dart';
import '../models/article.dart';
import '../services/api_services.dart';
import '../services/hive_cache.dart';

class NewsRepository {
  final NewsService _newsService = NewsService();
  final ArticleService _articleService = ArticleService();
  final CategoryService _categoryService = CategoryService();
  final SearchService _searchService = SearchService();
  final PublisherService _publisherService = PublisherService();
  final TrendingService _trendingService = TrendingService();
  final HistoryService _historyService = HistoryService();
  final NotificationService _notificationService = NotificationService();
  final HealthService _healthService = HealthService();
  final HiveCache _hiveCache = HiveCache();

  Future<List<Article>> fetchByCategory(String category, {int page = 1, int limit = 20, void Function(List<Article>)? onUpdated}) async {
    final cacheKey = 'category_${category}_page_$page';
    final cached = _hiveCache.getArticleList(cacheKey);
    final isFresh = _hiveCache.isFresh(cacheKey, Constants.headlinesTtl);

    if (cached != null) {
      if (!isFresh && onUpdated != null) {
        _backgroundFetchCategory(category, page, limit, cacheKey, onUpdated);
      }
      return cached;
    }

    final fresh = await _newsService.fetchNews(category: category == 'general' ? null : category, page: page, limit: limit);
    await _hiveCache.saveArticleList(cacheKey, fresh);
    return fresh;
  }

  Future<List<Article>> fetchGuardian({String? section, int page = 1, int limit = 20, void Function(List<Article>)? onUpdated}) async {
    final cacheKey = 'guardian_${section ?? 'world'}_page_$page';
    final cached = _hiveCache.getArticleList(cacheKey);
    final isFresh = _hiveCache.isFresh(cacheKey, Constants.headlinesTtl);

    if (cached != null) {
      if (!isFresh && onUpdated != null) {
        _backgroundFetchGuardian(section, page, limit, cacheKey, onUpdated);
      }
      return cached;
    }

    // Call the guardian proxy endpoint on backend
    final response = await dio.get('guardian', queryParameters: {
      if (section != null) 'section': section,
      'page': page,
      'limit': limit,
    });
    final List list = response.data['data'] ?? [];
    final fresh = list.map((json) => Article.fromJson(json)).toList();

    await _hiveCache.saveArticleList(cacheKey, fresh);
    return fresh;
  }

  Future<Article> getArticleDetails(Article article, {required void Function(Article) onUpdated}) async {
    final cacheKey = 'detail_${article.url}';
    final cached = _hiveCache.getArticle(cacheKey);
    final isFresh = _hiveCache.isFresh(cacheKey, Constants.headlinesTtl);

    // Save to local reading history box
    await _historyService.addToHistory(article);

    if (cached != null) {
      if (!isFresh) {
        _backgroundFetchDetails(article.url, cacheKey, onUpdated);
      }
      return cached;
    }

    final fresh = await _articleService.fetchArticleDetails(article.url);
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

  // Exposed helper services for other components (e.g. search, publishers, trending)
  SearchService get searchService => _searchService;
  PublisherService get publisherService => _publisherService;
  CategoryService get categoryService => _categoryService;
  TrendingService get trendingService => _trendingService;
  HistoryService get historyService => _historyService;
  NotificationService get notificationService => _notificationService;
  HealthService get healthService => _healthService;

  Future<void> _backgroundFetchCategory(String category, int page, int limit, String cacheKey, void Function(List<Article>) onUpdated) async {
    try {
      final fresh = await _newsService.fetchNews(category: category == 'general' ? null : category, page: page, limit: limit);
      await _hiveCache.saveArticleList(cacheKey, fresh);
      onUpdated(fresh);
    } catch (e) {
      print('[NewsRepository] Background fetch category error: $e');
    }
  }

  Future<void> _backgroundFetchGuardian(String? section, int page, int limit, String cacheKey, void Function(List<Article>) onUpdated) async {
    try {
      final response = await dio.get('guardian', queryParameters: {
        if (section != null) 'section': section,
        'page': page,
        'limit': limit,
      });
      final List list = response.data['data'] ?? [];
      final fresh = list.map((json) => Article.fromJson(json)).toList();
      await _hiveCache.saveArticleList(cacheKey, fresh);
      onUpdated(fresh);
    } catch (e) {
      print('[NewsRepository] Background fetch Guardian error: $e');
    }
  }

  Future<void> _backgroundFetchDetails(String url, String cacheKey, void Function(Article) onUpdated) async {
    try {
      final fresh = await _articleService.fetchArticleDetails(url);
      await _hiveCache.saveArticle(cacheKey, fresh);
      onUpdated(fresh);
    } catch (e) {
      print('[NewsRepository] Background fetch details error: $e');
    }
  }
}
