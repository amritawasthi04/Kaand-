import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';

class NewsService {
  // Get free key at: https://open-platform.theguardian.com/access/
  static const String _apiKey = 'cd760a37-962a-475d-a08f-75738e87a663';
  static const String _baseUrl = 'https://content.guardianapis.com';

  // Guardian section mapping — their sections ≠ NewsAPI categories
  // Guardian uses section IDs like: technology, business, sport, science, culture, health, world
  static const Map<String, String> _categoryToSection = {
    'general':       'world',
    'business':      'business',
    'entertainment': 'culture',
    'health':        'lifeandstyle',
    'science':       'science',
    'sports':        'sport',
    'technology':    'technology',
  };

  /// Fetch articles by category section
  Future<List<Article>> fetchTopHeadlines({String category = 'general'}) async {
    final section = _categoryToSection[category] ?? 'world';

    final uri = Uri.parse(
      '$_baseUrl/search'
          '?section=$section'
          '&page-size=20'
          '&order-by=newest'
          '&show-fields=headline,trailText,thumbnail,bodyText,byline'
          '&api-key=$_apiKey',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['response']['results'] as List<dynamic>;
      return results
          .map((e) => Article.fromGuardian(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Guardian API error ${response.statusCode}: ${response.body}',
      );
    }
  }

  /// Full-text search across all Guardian content
  Future<List<Article>> searchArticles(String query) async {
    final uri = Uri.parse(
      '$_baseUrl/search'
          '?q=${Uri.encodeComponent(query)}'
          '&page-size=20'
          '&order-by=relevance'
          '&show-fields=headline,trailText,thumbnail,bodyText,byline'
          '&api-key=$_apiKey',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['response']['results'] as List<dynamic>;
      return results
          .map((e) => Article.fromGuardian(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Guardian search error ${response.statusCode}: ${response.body}',
      );
    }
  }
}