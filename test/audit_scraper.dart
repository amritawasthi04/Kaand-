import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

// Supported publishers mapping
final Map<String, String> publishers = {
  // Indian
  'NDTV': 'ndtv.com',
  'The Hindu': 'thehindu.com',
  'Indian Express': 'indianexpress.com',
  'Times of India': 'timesofindia.indiatimes.com',
  'Hindustan Times': 'hindustantimes.com',
  'News18': 'news18.com',
  'Firstpost': 'firstpost.com',
  'Moneycontrol': 'moneycontrol.com',
  'LiveMint': 'livemint.com',
  'Economic Times': 'economictimes.indiatimes.com',
  'Zee News': 'zeenews.india.com',
  'India Today': 'indiatoday.in',
  'Republic World': 'republicworld.com',
  'ANI': 'aninews.in',
  // International
  'BBC': 'bbc.com',
  'Reuters': 'reuters.com',
  'CNN': 'cnn.com',
  'AP News': 'apnews.com',
  'Al Jazeera': 'aljazeera.com',
  'The Guardian': 'theguardian.com',
  'New York Times': 'nytimes.com',
  'Washington Post': 'washingtonpost.com',
  'Bloomberg': 'bloomberg.com',
  'CNBC': 'cnbc.com',
  'Fox News': 'foxnews.com',
  'ABC News': 'abcnews.go.com',
  'Sky News': 'news.sky.com',
  'NBC News': 'nbcnews.com',
  // Tech
  'TechCrunch': 'techcrunch.com',
  'The Verge': 'theverge.com',
  'Wired': 'wired.com',
  'Ars Technica': 'arstechnica.com',
  'Engadget': 'engadget.com',
  'Android Authority': 'androidauthority.com',
  '9to5Google': '9to5google.com',
  // Sports
  'ESPN': 'espn.com',
  'Cricbuzz': 'cricbuzz.com',
  'ICC': 'icc-cricket.com',
  'FIFA': 'fifa.com',
  'Formula1': 'formula1.com',
  // Entertainment
  'Variety': 'variety.com',
  'Deadline': 'deadline.com',
  'Rolling Stone': 'rollingstone.com',
  'IGN': 'ign.com',
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
    
    final match = RegExp(r'https?://[^\s\x00-\x1F\x7F-\x9F\u00A0-\uFFFF]+').firstMatch(decoded);
    if (match != null) {
      var urlStr = match.group(0)!;
      // Truncate any trailing garbage characters
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

Future<String?> getRecentArticleUrl(String domain) async {
  try {
    final searchUrl = Uri.parse('https://news.google.com/rss/search?q=site:$domain&hl=en-US&gl=US&ceid=US:en');
    final response = await http.get(searchUrl).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final document = xml.XmlDocument.parse(response.body);
    final items = document.findAllElements('item');
    if (items.isEmpty) return null;

    // Get the first item link
    final link = items.first.findElements('link').first.innerText;
    return resolveGoogleNewsUrl(link);
  } catch (e) {
    print('Error finding article for $domain: $e');
    return null;
  }
}

void main() async {
  print('=== STARTING KAAND UNIVERSAL ARTICLE EXTRACTION ENGINE QA AUDIT ===\n');

  final results = <Map<String, dynamic>>[];
  int passes = 0;
  int fails = 0;

  for (final entry in publishers.entries) {
    final name = entry.key;
    final domain = entry.value;

    print('Testing $name ($domain)...');
    final articleUrl = await getRecentArticleUrl(domain);
    if (articleUrl == null) {
      print('❌ FAILED to get recent article link from RSS feed.');
      fails++;
      results.add({
        'publisher': name,
        'status': 'FAIL',
        'error': 'Could not fetch sample article URL from RSS',
        'scrapeTime': 0,
      });
      continue;
    }

    final stopwatch = Stopwatch()..start();
    try {
      final apiUrl = Uri.parse('https://kaand-mauve.vercel.app/api/article?url=${Uri.encodeComponent(articleUrl)}');
      final apiResponse = await http.get(apiUrl).timeout(const Duration(seconds: 25));
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;
      final elapsedSec = (elapsedMs / 1000).toStringAsFixed(2);

      if (apiResponse.statusCode != 200) {
        print('❌ FAILED with status code: ${apiResponse.statusCode}');
        fails++;
        results.add({
          'publisher': name,
          'status': 'FAIL',
          'scrapeTime': elapsedSec,
          'error': 'API returned status code ${apiResponse.statusCode}. Body: ${apiResponse.body.substring(0, Math.min(apiResponse.body.length, 100))}',
        });
        continue;
      }

      final jsonMap = jsonDecode(apiResponse.body) as Map<String, dynamic>;
      if (jsonMap['success'] != true) {
        print('❌ FAILED: success field is false. Error: ${jsonMap['message']}');
        fails++;
        results.add({
          'publisher': name,
          'status': 'FAIL',
          'scrapeTime': elapsedSec,
          'error': jsonMap['message'] ?? 'Unknown error response',
        });
        continue;
      }

      final data = jsonMap['data'] as Map<String, dynamic>?;
      if (data == null) {
        print('❌ FAILED: Data block is missing.');
        fails++;
        results.add({
          'publisher': name,
          'status': 'FAIL',
          'scrapeTime': elapsedSec,
          'error': 'Data block is null',
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

      final titlePass = title != null && title.isNotEmpty;
      final descPass = description != null && description.isNotEmpty;
      final contentPass = content != null && content.trim().length > 100;
      final imagePass = image != null && image.isNotEmpty && image.startsWith('https://');
      final authorPass = author != null && author.isNotEmpty;
      final datePass = publishedAt != null && publishedAt.isNotEmpty;

      final isPass = titlePass && contentPass; // Critical criteria: Title & Content must exist

      if (isPass) {
        print('✅ PASSED in $elapsedSec seconds.');
        passes++;
      } else {
        print('❌ FAILED field validation.');
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
