import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/article.dart';

class WorkerService {
  Future<List<Article>> fetchNews({String? category, String? query, String? hl, String? gl}) async {
    final Map<String, String> queryParams = {};
    if (category != null && category.toLowerCase() != 'all' && category.toLowerCase() != 'general') {
      queryParams['cat'] = category.toUpperCase();
    }
    if (query != null && query.trim().isNotEmpty) {
      queryParams['q'] = query;
    }
    if (hl != null) queryParams['hl'] = hl;
    if (gl != null) queryParams['gl'] = gl;

    final uri = Uri.parse('${Constants.workerBaseUrl}/news').replace(queryParameters: queryParams);
    
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch news from Worker: status ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data['status'] != 'ok') {
      throw Exception('Worker returned error: ${data['message']}');
    }

    final List articlesList = data['articles'] ?? [];
    return articlesList.map((x) => Article.fromWorkerJson(x)).toList();
  }

  Future<Map<String, String?>> scrapeArticle(String articleUrl, {String? title}) async {
    final Map<String, String> queryParams = {'url': articleUrl};
    if (title != null) queryParams['title'] = title;

    final uri = Uri.parse('${Constants.workerBaseUrl}/article').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to scrape article from Worker: status ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data['status'] != 'ok') {
      throw Exception('Worker scrape failed: ${data['message']}');
    }

    return {
      'description': data['description'] as String?,
      'imageUrl': data['imageUrl'] as String?,
      'url': data['url'] as String?,
    };
  }
}
