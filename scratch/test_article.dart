import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final links = [
    'https://www.bbc.co.uk/news/articles/cy9r2x4pz1wo?at_medium=RSS&at_campaign=rss',
    'https://techcrunch.com/2026/07/03/artificial-intelligence-definition-glossary-hallucinations-guide-to-common-ai-terms/',
    'https://www.ndtv.com/world-news/deeply-disturbing-germany-on-reports-of-china-training-russian-troops-11727046',
    'https://www.theguardian.com/world/article/2026/jul/04/south-korea-parliament-unification-ministry-demolition'
  ];

  for (final link in links) {
    print('Testing: $link');
    final url = Uri.parse('https://kaand-mauve.vercel.app/api/article?url=${Uri.encodeComponent(link)}');
    final response = await http.get(url).timeout(const Duration(seconds: 25));
    print('  Status: ${response.statusCode}');
    
    final json = jsonDecode(response.body);
    print('  Success: ${json['success']}');
    if (json['success'] == true) {
      final data = json['data'];
      print('  Title: ${data['title']}');
      print('  Content Length: ${data['content']?.toString().length}');
      print('  Image: ${data['image']}');
      print('  Author: ${data['author']}');
      print('  Score: ${data['extractionScore']}');
      print('  Extractor: ${data['extractorUsed']}');
    } else {
      print('  Message: ${json['message']}');
    }
    print('');
  }
}
