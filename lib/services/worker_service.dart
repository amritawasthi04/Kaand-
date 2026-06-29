import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/article.dart';

class WorkerService {
  Future<List<Article>> fetchNews(
      {String? category, String? query, String? hl, String? gl}) async {
    final hlVal = hl ?? 'en-IN';
    final glVal = gl ?? 'IN';

    final String rssUrl;
    if (query != null && query.trim().isNotEmpty) {
      rssUrl =
          'https://news.google.com/rss/search?q=${Uri.encodeComponent(query)}&hl=$hlVal&gl=$glVal&ceid=$glVal:en';
    } else if (category != null &&
        category.toLowerCase() != 'all' &&
        category.toLowerCase() != 'general') {
      rssUrl =
          'https://news.google.com/rss/headlines/section/topic/${Uri.encodeComponent(category.toUpperCase())}?hl=$hlVal&gl=$glVal&ceid=$glVal:en';
    } else {
      rssUrl = 'https://news.google.com/rss?hl=$hlVal&gl=$glVal&ceid=$glVal:en';
    }

    try {
      final response = await http.get(Uri.parse(rssUrl), headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch news directly from Google News: status ${response.statusCode}');
      }

      final parsed = _parseRSS(response.body);
      return parsed.take(20).toList();
    } catch (e) {
      throw Exception('Failed to fetch news: $e');
    }
  }

  List<Article> _parseRSS(String xml) {
    final List<Article> items = [];
    final itemRegex = RegExp(r'<item>([\s\S]*?)</item>', caseSensitive: false);
    final titleRegex = RegExp(
      r'<title><!\[CDATA\[([\s\S]*?)\]\]></title>|<title[^>]*>([\s\S]*?)</title>',
      caseSensitive: false,
    );
    final linkRegex =
        RegExp(r'<link[^>]*>([\s\S]*?)</link>', caseSensitive: false);
    final dateRegex =
        RegExp(r'<pubDate[^>]*>([\s\S]*?)</pubDate>', caseSensitive: false);
    final srcRegex = RegExp(
      r'<source[^>]*><!\[CDATA\[([\s\S]*?)\]\]></source>|<source[^>]*>([\s\S]*?)</source>',
      caseSensitive: false,
    );

    for (final match in itemRegex.allMatches(xml)) {
      final content = match.group(1) ?? '';

      // title
      final titleMatch = titleRegex.firstMatch(content);
      String rawTitle = '';
      if (titleMatch != null) {
        rawTitle = (titleMatch.group(1) ?? titleMatch.group(2) ?? '').trim();
      }

      // link
      final linkMatch = linkRegex.firstMatch(content);
      final link = linkMatch != null ? linkMatch.group(1)!.trim() : '';

      // pubDate
      final dateMatch = dateRegex.firstMatch(content);
      final pubDate = dateMatch != null ? dateMatch.group(1)!.trim() : '';

      // source
      final srcMatch = srcRegex.firstMatch(content);
      String source = srcMatch != null
          ? (srcMatch.group(1) ?? srcMatch.group(2) ?? 'Google News').trim()
          : 'Google News';

      // clean title/source
      final hyphen = rawTitle.lastIndexOf(' - ');
      if (hyphen != -1) {
        source = rawTitle.substring(hyphen + 3).trim();
        rawTitle = rawTitle.substring(0, hyphen).trim();
      }

      if (link.isNotEmpty) {
        items.add(Article(
          title: _cleanXmlEntities(rawTitle),
          url: link,
          publishedAt: pubDate,
          sourceName: _cleanXmlEntities(source),
        ));
      }
    }
    return items;
  }

  String _cleanXmlEntities(String str) {
    return str
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&hellip;', '…');
  }

  Future<Map<String, String?>> scrapeArticle(String articleUrl,{String? title}) async {
    final cleanUrl = articleUrl.trim();
    final Map<String, String> queryParams = {'url': cleanUrl};

    final uri = Uri.parse('${Constants.workerBaseUrl}/article').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to scrape article from Worker: status ${response.statusCode}');
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
