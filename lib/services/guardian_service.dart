import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/article.dart';

class GuardianService {
  Future<List<Article>> fetchBlogs({String? section, String? query}) async {
    final Map<String, String> queryParams = {
      'key': Constants.guardianApiKey,
    };

    if (query != null && query.trim().isNotEmpty) {
      queryParams['q'] = query;
    } else {
      queryParams['section'] = section ?? 'world';
    }

    final uri = Uri.parse('${Constants.workerBaseUrl}/guardian')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch from Guardian endpoint: status ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data['status'] != 'ok') {
      throw Exception('Guardian endpoint returned error');
    }

    final List articlesList = data['articles'] ?? [];
    return articlesList.map((x) => Article.fromWorkerJson(x)).toList();
  }
}
