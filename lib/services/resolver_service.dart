import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;

class ResolverService {
  void _log(String message) {
    print('[ResolverService] $message');
  }


  /// Resolves the raw Google News article redirect link to the original publisher page.
  Future<String?> resolveGoogleNewsUrl(String googleUrl) async {
    _log('Starting resolution for: $googleUrl');
    try {
      final uri = Uri.parse(googleUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isEmpty) {
        _log('Error: Path segments are empty.');
        return null;
      }
      
      String? token;
      final int articlesIndex = pathSegments.indexOf('articles');
      final int readIndex = pathSegments.indexOf('read');
      if (articlesIndex != -1 && articlesIndex + 1 < pathSegments.length) {
        token = pathSegments[articlesIndex + 1];
      } else if (readIndex != -1 && readIndex + 1 < pathSegments.length) {
        token = pathSegments[readIndex + 1];
      } else {
        token = pathSegments.last;
      }
      
      if (token.isEmpty) {
        _log('Error: Extracted token is empty.');
        return null;
      }

      String? signature;
      String? timestamp;
      
      // Attempt 1: Fetch signature/timestamp from /articles/
      try {
        final res = await http.get(
          Uri.parse('https://news.google.com/articles/$token'),
          headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'},
        ).timeout(const Duration(seconds: 5));
        
        if (res.statusCode == 200) {
          final doc = htmlParser.parse(res.body);
          final element = doc.querySelector('c-wiz div[jscontroller]');
          if (element != null) {
            signature = element.attributes['data-n-a-sg'];
            timestamp = element.attributes['data-n-a-ts'];
          }
        }
      } catch (e) {
        _log('Attempt 1 (/articles/) failed: $e');
      }
      
      // Attempt 2: Fallback to /rss/articles/
      if (signature == null || timestamp == null) {
        try {
          final res = await http.get(
            Uri.parse('https://news.google.com/rss/articles/$token'),
            headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'},
          ).timeout(const Duration(seconds: 5));
          
          if (res.statusCode == 200) {
            final doc = htmlParser.parse(res.body);
            final element = doc.querySelector('c-wiz div[jscontroller]');
            if (element != null) {
              signature = element.attributes['data-n-a-sg'];
              timestamp = element.attributes['data-n-a-ts'];
            }
          }
        } catch (e) {
          _log('Attempt 2 (/rss/articles/) failed: $e');
        }
      }
      
      if (signature == null || timestamp == null) {
        _log('Failed: signature/timestamp extraction failed for token: $token');
        return null;
      }

      // Execute Google RPC DotsSplashUi batchexecute
      final String postUrl = 'https://news.google.com/_/DotsSplashUi/data/batchexecute';
      final innerPayload = [
        'garturlreq',
        [
          ['X', 'X', ['X', 'X'], null, null, 1, 1, 'US:en', null, 1, null, null, null, null, null, 0, 1],
          'X',
          'X',
          1,
          [1, 1, 1],
          1,
          1,
          null,
          0,
          0,
          null,
          0
        ],
        token,
        int.parse(timestamp),
        signature
      ];
      
      final payload = [
        [
          'Fbv4je',
          jsonEncode(innerPayload),
          null,
          'generic'
        ]
      ];
      
      final String reqBody = 'f.req=' + Uri.encodeQueryComponent(jsonEncode([payload]));
      
      final response = await http.post(
        Uri.parse(postUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36',
        },
        body: reqBody,
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode != 200) {
        _log('Failed: RPC batchexecute returned HTTP status ${response.statusCode}');
        return null;
      }
      
      final String bodyText = response.body;
      final List<String> parts = bodyText.split('\n\n');
      if (parts.length < 2) {
        _log('Failed: RPC response parts mismatch');
        return null;
      }
      
      final List<dynamic> parsedData = jsonDecode(parts[1]);
      if (parsedData.isEmpty || parsedData[0] == null) {
        _log('Failed: RPC response first element null');
        return null;
      }
      
      final String innerJsonStr = parsedData[0][2];
      final List<dynamic> resolvedArray = jsonDecode(innerJsonStr);
      if (resolvedArray.length > 1) {
        final resolvedUrl = resolvedArray[1] as String;
        _log('Success: Resolved to: $resolvedUrl');
        return resolvedUrl;
      }
      
      _log('Failed: Resolved array empty or short');
      return null;
    } catch (e) {
      _log('Error during resolution: $e');
      return null;
    }
  }
}
