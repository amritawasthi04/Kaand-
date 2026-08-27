import 'package:dio/dio.dart';
import '../models/sports_score.dart';
import '../services/api_services.dart';

class ScoresRepository {
  final Dio _dio = dio;

  Future<List<SportsScore>> fetchLiveScores({String? sport}) async {
    try {
      final response = await _dio.get(
        'scores',
        queryParameters: {
          if (sport != null) 'sport': sport,
        },
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> scoresData = response.data['data']['scores'] ?? [];
        return scoresData
            .map((json) => SportsScore.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching live scores: $e');
      return [];
    }
  }

  Future<List<SportsScore>> fetchScoresByLeague(String league) async {
    try {
      final response = await _dio.get(
        'scores/league/$league',
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> scoresData = response.data['data']['scores'] ?? [];
        return scoresData
            .map((json) => SportsScore.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching league scores: $e');
      return [];
    }
  }

  // Parse scores from sports news articles as fallback
  Future<List<SportsScore>> parseScoresFromArticles(List<dynamic> articles) async {
    final scores = <SportsScore>[];
    
    for (final article in articles) {
      final title = article['title'] as String? ?? '';
      final url = article['url'] as String? ?? '';
      final source = article['source'] as String? ?? '';
      
      final score = SportsScoreParser.extractScoreFromTitle(title, url, source);
      if (score != null) {
        scores.add(score);
      }
    }
    
    return scores;
  }
}