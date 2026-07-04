import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../models/article.dart';

class ApiService {
  final Dio _dio = DioClient().dio;

  Future<List<Article>> fetchNews({String? category, String? search, int page = 1, int limit = 20}) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'page': page,
        'limit': limit,
      };
      if (category != null && category.isNotEmpty) {
        queryParameters['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await _dio.get('/news', queryParameters: queryParameters);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['success'] == true) {
          final payload = data['data'];
          final List articlesList;
          if (payload is List) {
            articlesList = payload;
          } else if (payload is Map && payload['articles'] is List) {
            articlesList = payload['articles'];
          } else {
            articlesList = [];
          }
          return articlesList.map((x) => Article.fromJson(Map<String, dynamic>.from(x))).toList();
        }
      }
      throw Exception('Failed to load news');
    } catch (e) {
      print('[ApiService] fetchNews error: $e');
      rethrow;
    }
  }

  Future<List<Article>> fetchGuardian({String? section, int page = 1, int limit = 20}) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'page': page,
        'limit': limit,
      };
      if (section != null && section.isNotEmpty) {
        queryParameters['section'] = section;
      }

      final response = await _dio.get('/guardian', queryParameters: queryParameters);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['success'] == true) {
          final payload = data['data'];
          final List articlesList;
          if (payload is List) {
            articlesList = payload;
          } else if (payload is Map && payload['articles'] is List) {
            articlesList = payload['articles'];
          } else {
            articlesList = [];
          }
          return articlesList.map((x) => Article.fromJson(Map<String, dynamic>.from(x))).toList();
        }
      }
      throw Exception('Failed to load Guardian news');
    } catch (e) {
      print('[ApiService] fetchGuardian error: $e');
      rethrow;
    }
  }

  Future<Article> fetchArticleDetails(String articleUrl) async {
    try {
      final response = await _dio.get('/article', queryParameters: {
        'url': articleUrl,
      });
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['success'] == true) {
          final payload = data['data'];
          if (payload != null && payload is Map) {
            return Article.fromJson(Map<String, dynamic>.from(payload));
          }
        }
      }
      throw Exception('Failed to load article details');
    } catch (e) {
      print('[ApiService] fetchArticleDetails error: $e');
      rethrow;
    }
  }
}
