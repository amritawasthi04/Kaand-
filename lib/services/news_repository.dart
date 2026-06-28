import 'package:xml/xml.dart';
import '../models/article_model.dart';
import 'news_service.dart';

class NewsRepository {
  final NewsService _newsService = NewsService();

  // Topic mapping to Google News topic sections
  static const Map<String, String> _categoryToTopic = {
    'business':      'BUSINESS',
    'entertainment': 'ENTERTAINMENT',
    'health':        'HEALTH',
    'science':       'SCIENCE',
    'sports':        'SPORTS',
    'technology':    'TECHNOLOGY',
  };

  /// Fetch top headlines (corresponds to general news)
  Future<List<Article>> fetchTopHeadlines() async {
    final uri = Uri.parse('https://news.google.com/rss?hl=en-IN&gl=IN&ceid=IN:en');
    return _newsService.fetchAndParseRss(uri, 'general');
  }

  /// Fetch by category
  Future<List<Article>> fetchByCategory(String category) async {
    final topic = _categoryToTopic[category.toLowerCase()];
    if (topic == null) {
      // Fallback to top headlines if category is general or unrecognized
      return fetchTopHeadlines();
    }
    final uri = Uri.parse('https://news.google.com/rss/headlines/section/topic/$topic?hl=en-IN&gl=IN&ceid=IN:en');
    return _newsService.fetchAndParseRss(uri, category);
  }

  /// Search articles using search RSS feed
  Future<List<Article>> searchArticles(String query) async {
    final uri = Uri.parse('https://news.google.com/rss/search?q=${Uri.encodeComponent(query)}&hl=en-IN&gl=IN&ceid=IN:en');
    return _newsService.fetchAndParseRss(uri, 'general');
  }

  /// Public test helper to process a single item
  Future<Article?> processItemForTest(XmlElement element, String category) {
    return _newsService.processItem(element, category);
  }
}
