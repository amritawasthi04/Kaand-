import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

void main() async {
  final feeds = {
    'BBC': 'http://feeds.bbci.co.uk/news/rss.xml',
    'TechCrunch': 'https://techcrunch.com/feed/',
    'NDTV': 'https://feeds.feedburner.com/ndtvnews-top-stories',
    'The Guardian': 'https://www.theguardian.com/international/rss',
  };

  for (final entry in feeds.entries) {
    print('Testing feed for ${entry.key}: ${entry.value}');
    try {
      final response = await http.get(Uri.parse(entry.value)).timeout(const Duration(seconds: 10));
      print('  Status: ${response.statusCode}');
      
      final document = xml.XmlDocument.parse(response.body);
      final items = document.findAllElements('item');
      if (items.isNotEmpty) {
        final link = items.first.findElements('link').first.innerText.trim();
        print('  Direct URL: $link');
      } else {
        print('  No items found in feed.');
      }
    } catch (e) {
      print('  Error: $e');
    }
    print('');
  }
}
