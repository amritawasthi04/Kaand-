import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../core/constants.dart';
import '../models/article.dart';

final Dio dio = _createDio();

Dio _createDio() {
  final baseUrl = 'http://192.168.31.4:3000/api/';

  final options = BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );

  final client = Dio(options);
  client.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      options.headers['User-Agent'] = 'KAAND Flutter Client';
      return handler.next(options);
    },
    onError: (DioException e, handler) {
      print('[API Error] ${e.requestOptions.path}: ${e.message}');
      return handler.next(e);
    },
  ));
  return client;
}

class NewsService {
  Future<List<Article>> fetchNews({String? category, String? search, int page = 1, int limit = 20}) async {
    final response = await dio.get('news', queryParameters: {
      if (category != null) 'category': category,
      if (search != null) 'search': search,
      'page': page,
      'limit': limit,
    });
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List articles = response.data['data']['articles'];
      return articles.map((json) => Article.fromJson(json)).toList();
    }
    throw Exception(response.data['message'] ?? 'Failed to load news');
  }
}

class ArticleService {
  Future<Article> fetchArticleDetails(String url) async {
    final response = await dio.get('article', queryParameters: {'url': url});
    if (response.statusCode == 200 && response.data['success'] == true) {
      return Article.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to load article details');
  }
}

class CategoryService {
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await dio.get('categories');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List cats = response.data['data'];
      return cats.map((c) => Map<String, dynamic>.from(c)).toList();
    }
    throw Exception(response.data['message'] ?? 'Failed to load categories');
  }

  Future<List<Article>> getCategoryNews(String categoryId, {int page = 1, int limit = 20}) async {
    final response = await dio.get('category/$categoryId', queryParameters: {
      'page': page,
      'limit': limit,
    });
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List articles = response.data['data']['articles'];
      return articles.map((json) => Article.fromJson(json)).toList();
    }
    throw Exception(response.data['message'] ?? 'Failed to load category news');
  }
}

class SearchService {
  Future<List<Article>> searchArticles(String query, {String? category, int page = 1, int limit = 20}) async {
    final response = await dio.get('search', queryParameters: {
      'q': query,
      if (category != null) 'category': category,
      'page': page,
      'limit': limit,
    });
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List articles = response.data['data']['articles'];
      return articles.map((json) => Article.fromJson(json)).toList();
    }
    throw Exception(response.data['message'] ?? 'Search failed');
  }
}

class PublisherService {
  Future<List<Map<String, dynamic>>> getPublishers() async {
    final response = await dio.get('publishers');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List pubs = response.data['data'];
      return pubs.map((p) => Map<String, dynamic>.from(p)).toList();
    }
    throw Exception(response.data['message'] ?? 'Failed to load publishers');
  }

  Future<List<Article>> getPublisherNews(String publisherId, {int page = 1, int limit = 20}) async {
    final response = await dio.get('publisher/$publisherId', queryParameters: {
      'page': page,
      'limit': limit,
    });
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List articles = response.data['data']['articles'];
      return articles.map((json) => Article.fromJson(json)).toList();
    }
    throw Exception(response.data['message'] ?? 'Failed to load publisher news');
  }
}

class TrendingService {
  Future<List<Article>> getTrending({int limit = 20}) async {
    final response = await dio.get('trending', queryParameters: {'limit': limit});
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List articles = response.data['data'];
      return articles.map((json) => Article.fromJson(json)).toList();
    }
    throw Exception(response.data['message'] ?? 'Failed to load trending news');
  }
}

class HistoryService {
  static const String _historyKey = 'reading_history';

  Future<List<Article>> getHistory() async {
    final box = Hive.box(Constants.hiveNewsBox);
    final List? raw = box.get(_historyKey);
    if (raw == null) return [];
    return raw.map((item) => Article.fromMap(item as Map)).toList();
  }

  Future<void> addToHistory(Article article) async {
    final box = Hive.box(Constants.hiveNewsBox);
    final list = await getHistory();
    // Remove if already in history to move to top
    list.removeWhere((a) => a.url == article.url);
    list.insert(0, article);
    // Limit history size to 50 items
    if (list.length > 50) {
      list.removeLast();
    }
    await box.put(_historyKey, list.map((a) => a.toMap()).toList());
  }

  Future<void> clearHistory() async {
    final box = Hive.box(Constants.hiveNewsBox);
    await box.delete(_historyKey);
  }
}

class NotificationService {
  Future<List<Map<String, dynamic>>> getNotifications() async {
    // Return mock notification items as no backend notification DB exists yet
    return [
      {
        'id': '1',
        'title': 'Breaking News',
        'body': 'US Consumer Prices drop in June as energy costs tumble.',
        'time': '10m ago',
        'type': 'alert'
      },
      {
        'id': '2',
        'title': 'Tech Update',
        'body': 'DeepSeek reportedly in talks to raise \$1.5B before listing IPO.',
        'time': '1h ago',
        'type': 'news'
      },
      {
        'id': '3',
        'title': 'Sports Alert',
        'body': 'Diego Maradona tribute held in Argentina for World Cup anniversary.',
        'time': '3h ago',
        'type': 'sports'
      }
    ];
  }
}

class HealthService {
  Future<Map<String, dynamic>> checkHealth() async {
    final response = await dio.get('health');
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    throw Exception('Backend health check failed');
  }
}
