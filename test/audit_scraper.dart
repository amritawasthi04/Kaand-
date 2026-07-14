import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

// Direct RSS Feeds mapping for all supported publishers
final Map<String, String> publisherFeeds = {
  // Indian
  'NDTV': 'https://feeds.feedburner.com/ndtvnews-top-stories',
  'The Hindu': 'https://www.thehindu.com/news/national/feeder/default.rss',
  'Indian Express': 'https://indianexpress.com/feed/',
  'Times of India': 'https://timesofindia.indiatimes.com/rssfeedmostrecent.cms',
  'Hindustan Times': 'https://www.hindustantimes.com/feeds/rss/india-news/rssfeed.xml',
  'News18': 'https://www.news18.com/rss/india.xml',
  'Firstpost': 'https://www.firstpost.com/rss/india.xml',
  'Moneycontrol': 'https://www.moneycontrol.com/rss/latestnews.xml',
  'LiveMint': 'https://www.livemint.com/rss/news',
  'Economic Times': 'https://economictimes.indiatimes.com/rssfeedstopstories.cms',
  'Zee News': 'https://zeenews.india.com/rss/india-national-news.xml',
  'India Today': 'https://www.indiatoday.in/rss/home',
  'Republic World': 'https://www.republicworld.com/rss/india-news.xml',
  'ANI': 'https://aninews.in/rss/feed/',
  
  // International
  'BBC': 'http://feeds.bbci.co.uk/news/rss.xml',
  'Reuters': 'https://news.google.com/rss/search?q=site:reuters.com&hl=en-US&gl=US&ceid=US:en',
  'CNN': 'http://rss.cnn.com/rss/edition.rss',
  'AP News': 'https://apnews.com/hub/ap-top-news.rss',
  'Al Jazeera': 'https://www.aljazeera.com/xml/rss/all.xml',
  'The Guardian': 'https://www.theguardian.com/international/rss',
  'New York Times': 'https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml',
  'Washington Post': 'https://www.washingtonpost.com/rss/national',
  'Bloomberg': 'https://news.google.com/rss/search?q=site:bloomberg.com&hl=en-US&gl=US&ceid=US:en',
  'CNBC': 'https://www.cnbc.com/id/100003114/device/rss/rss.html',
  'Fox News': 'https://moxie.foxnews.com/feed/latest.xml',
  'ABC News': 'https://abcnews.go.com/abcnews/topstories',
  'Sky News': 'https://news.sky.com/feeds/info/public/home.xml',
  'NBC News': 'https://feeds.nbcnews.com/nbcnews/public/world',
  
  // Tech
  'TechCrunch': 'https://techcrunch.com/feed/',
  'The Verge': 'https://www.theverge.com/rss/index.xml',
  'Wired': 'https://www.wired.com/feed/rss',
  'Ars Technica': 'https://feeds.arstechnica.com/arstechnica/index',
  'Engadget': 'https://www.engadget.com/rss.xml',
  'Android Authority': 'https://www.androidauthority.com/feed/',
  '9to5Google': 'https://9to5google.com/feed/',
  
  // Sports
  'ESPN': 'https://www.espn.com/espn/rss/news',
  'Cricbuzz': 'https://www.cricbuzz.com/tony/soccer/rss1/news',
  'ICC': 'https://news.google.com/rss/search?q=site:icc-cricket.com&hl=en-US&gl=US&ceid=US:en',
  'FIFA': 'https://news.google.com/rss/search?q=site:fifa.com&hl=en-US&gl=US&ceid=US:en',
  'Formula1': 'https://www.formula1.com/content/fom-website/en/latest/all.xml.rss',
  
  // Entertainment
  'Variety': 'https://variety.com/feed/',
  'Deadline': 'https://deadline.com/feed/',
  'Rolling Stone': 'https://www.rollingstone.com/feed/',
  'IGN': 'https://feeds.feedburner.com/ign/news',
};

String resolveGoogleNewsUrl(String link) {
  if (!link.contains('news.google.com/rss/articles/')) return link;
  try {
    final uri = Uri.parse(link);
    final segments = uri.pathSegments;
    if (segments.length < 3) return link;
    final b64 = segments[2];
    
    var normalized = b64;
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }
    
    final bytes = base64.decode(normalized);
    final decoded = utf8.decode(bytes, allowMalformed: true);
    
    final match = RegExp(r"https?://[^\s\x00-\x1F\x7F-\x9F\u00A0-\uFFFF]+").firstMatch(decoded);
    if (match != null) {
      var urlStr = match.group(0)!;
      while (urlStr.isNotEmpty && urlStr.codeUnitAt(urlStr.length - 1) > 126) {
        urlStr = urlStr.substring(0, urlStr.length - 1);
      }
      return urlStr;
    }
  } catch (e) {
    print('Failed to resolve Google News link: $e');
  }
  return link;
}

Future<String?> getRecentArticleUrlFromFeed(String name, String feedUrl) async {
  try {
    final response = await http.get(Uri.parse(feedUrl)).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final document = xml.XmlDocument.parse(response.body);
    final items = document.findAllElements('item');
    if (items.isEmpty) return null;

    // Try finding direct link inside item
    final linkEl = items.first.findElements('link');
    if (linkEl.isEmpty) return null;
    final link = linkEl.first.innerText.trim();
    
    return resolveGoogleNewsUrl(link);
  } catch (e) {
    print('Error parsing feed for $name: $e');
    return null;
  }
}

void main() async {
  print('=== STARTING KAAND UNIVERSAL ARTICLE EXTRACTION ENGINE QA AUDIT ===\n');

  final results = <Map<String, dynamic>>[];
  int passes = 0;
  int fails = 0;

  for (final entry in publisherFeeds.entries) {
    final name = entry.key;
    final feedUrl = entry.value;

    print('Testing $name...');
    final articleUrl = await getRecentArticleUrlFromFeed(name, feedUrl);
    if (articleUrl == null) {
      print('❌ FAILED to get recent article link from RSS feed ($feedUrl).');
      fails++;
      results.add({
        'publisher': name,
        'status': 'FAIL',
        'error': 'Could not parse RSS feed XML',
        'scrapeTime': '0.00',
      });
      continue;
    }

    final stopwatch = Stopwatch()..start();
    try {
      final baseUrl = Platform.environment['API_URL'] ?? 'http://localhost:3000/api';
      final apiUrl = Uri.parse('$baseUrl/article?url=${Uri.encodeComponent(articleUrl)}');
      final apiResponse = await http.get(apiUrl).timeout(const Duration(seconds: 25));
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;
      final elapsedSec = (elapsedMs / 1000).toStringAsFixed(2);

      if (apiResponse.statusCode != 200) {
        print('❌ FAILED with status code: ${apiResponse.statusCode} | URL: $articleUrl');
        fails++;
        results.add({
          'publisher': name,
          'status': 'FAIL',
          'scrapeTime': elapsedSec,
          'error': 'API returned status code ${apiResponse.statusCode}. Msg: ${apiResponse.body.substring(0, Math.min(apiResponse.body.length, 100))}',
          'url': articleUrl,
        });
        continue;
      }

      final jsonMap = jsonDecode(apiResponse.body) as Map<String, dynamic>;
      if (jsonMap['success'] != true) {
        print('❌ FAILED: success field is false. URL: $articleUrl');
        fails++;
        results.add({
          'publisher': name,
          'status': 'FAIL',
          'scrapeTime': elapsedSec,
          'error': jsonMap['message'] ?? 'Unknown error response',
          'url': articleUrl,
        });
        continue;
      }

      final data = jsonMap['data'] as Map<String, dynamic>?;
      if (data == null) {
        print('❌ FAILED: Data block is missing. URL: $articleUrl');
        fails++;
        results.add({
          'publisher': name,
          'status': 'FAIL',
          'scrapeTime': elapsedSec,
          'error': 'Data block is null',
          'url': articleUrl,
        });
        continue;
      }

      // Verify fields
      final title = data['title'] as String?;
      final description = data['description'] as String?;
      final content = data['content'] as String?;
      final image = data['image'] as String?;
      final author = data['author'] as String?;
      final publishedAt = data['publishedAt'] as String?;
      final extractorUsed = data['extractorUsed'] as String? ?? 'generic';

      final titlePass = title != null && title.isNotEmpty;
      final descPass = description != null && description.isNotEmpty;
      final contentPass = content != null && content.trim().length > 100;
      final imagePass = image != null && image.isNotEmpty && image.startsWith('https://');
      final authorPass = author != null && author.isNotEmpty;
      final datePass = publishedAt != null && publishedAt.isNotEmpty;

      final isPass = titlePass && contentPass; // Critical criteria: Title & Content must exist

      if (isPass) {
        print('✅ PASSED in $elapsedSec seconds. Extractor: $extractorUsed');
        passes++;
      } else {
        print('❌ FAILED field validation. Title: $titlePass, Content: $contentPass');
        fails++;
      }

      results.add({
        'publisher': name,
        'status': isPass ? 'PASS' : 'FAIL',
        'scrapeTime': elapsedSec,
        'title': titlePass ? 'PASS' : 'FAIL',
        'description': descPass ? 'PASS' : 'FAIL',
        'content': contentPass ? 'PASS' : 'FAIL',
        'image': imagePass ? 'PASS' : 'FAIL',
        'author': authorPass ? 'PASS' : 'FAIL',
        'date': datePass ? 'PASS' : 'FAIL',
        'extractorUsed': extractorUsed,
        'url': articleUrl,
        'error': isPass ? null : 'Missing title or content block',
      });
    } catch (e) {
      stopwatch.stop();
      print('❌ ERROR: $e');
      fails++;
      results.add({
        'publisher': name,
        'status': 'FAIL',
        'scrapeTime': (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2),
        'error': e.toString(),
      });
    }

    // Rate limit ourselves slightly to avoid spamming Vercel / RSS search
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Calculate stats
  final total = passes + fails;
  final rate = total > 0 ? (passes / total * 100).toStringAsFixed(1) : '0';

  print('\n=== QA AUDIT CONCLUSION ===');
  print('Total Publishers: $total');
  print('Passed: $passes');
  print('Failed: $fails');
  print('Success Rate: $rate%');

  // Print raw report JSON format to console so it can be extracted
  print('\nJSON_REPORT_START');
  print(jsonEncode(results));
  print('JSON_REPORT_END');
}

class Math {
  static int min(int a, int b) => a < b ? a : b;
}
