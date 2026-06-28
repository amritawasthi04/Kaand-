import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/article.dart';

class GuardianService {
  Future<List<Article>> fetchBlogs({String? section, String? query}) async {
    final Map<String, String> queryParams = {
      'api-key': Constants.guardianApiKey,
      'show-fields': 'headline,trailText,thumbnail,byline,bodyText',
      'page-size': '20',
    };

    if (section != null && section.toLowerCase() != 'all') {
      queryParams['section'] = section;
    }
    if (query != null && query.trim().isNotEmpty) {
      queryParams['q'] = query;
    }

    final uri = Uri.parse('${Constants.guardianBaseUrl}/search').replace(queryParameters: queryParams);
    
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch from Guardian API: status ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final results = data['response']?['results'] as List? ?? [];
    return results.map((x) => Article.fromGuardian(x)).toList();
  }
}
