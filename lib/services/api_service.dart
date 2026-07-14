import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../core/constants.dart';
import '../models/article.dart';

class ApiService {

  String _sanitizeXml(String xmlStr) {
    xmlStr = xmlStr.trim().replaceFirst(RegExp(r'^[^<]+'), '');
    xmlStr = xmlStr.replaceAllMapped(RegExp(r'&(?!(#[0-9]+|[a-zA-Z0-9]+);)'), (match) => '&amp;');
    xmlStr = xmlStr.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x84\x86-\x9F]'), '');
    return xmlStr;
  }

  String _normalizeSource(String feedUrl) {
    final lower = feedUrl.toLowerCase();
    if (lower.contains('techcrunch')) return 'TechCrunch';
    if (lower.contains('bbc')) return 'BBC';
    if (lower.contains('theguardian')) return 'The Guardian';
    if (lower.contains('thehindu')) return 'The Hindu';
    if (lower.contains('indianexpress')) return 'Indian Express';
    if (lower.contains('ndtv')) return 'NDTV';
    if (lower.contains('espn')) return 'ESPN';
    if (lower.contains('hindustantimes')) return 'Hindustan Times';
    if (lower.contains('moneycontrol')) return 'Moneycontrol';
    if (lower.contains('livemint')) return 'LiveMint';
    if (lower.contains('economictimes')) return 'Economic Times';
    if (lower.contains('zeenews')) return 'Zee News';
    if (lower.contains('indiatoday')) return 'India Today';
    if (lower.contains('republicworld')) return 'Republic World';
    if (lower.contains('aninews')) return 'ANI';
    return 'News';
  }

  double _titleSimilarity(String t1, String t2) {
    Set<String> getWords(String str) {
      return str
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toSet();
    }
    
    final words1 = getWords(t1);
    final words2 = getWords(t2);
    
    if (words1.isEmpty || words2.isEmpty) return 0.0;
    
    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;
    return intersection / union;
  }

  Future<String> _resolveGoogleNewsUrl(String link) async {
    if (!link.contains('news.google.com/rss/articles/')) return link;
    try {
      final uri = Uri.parse(link);
      final segments = uri.pathSegments;
      if (segments.length < 3) return link;
      final b64 = segments[2];
      
      // First try: URL-safe base64 decoding (for simple redirects)
      var normalized = b64.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      
      try {
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
      } catch (_) {}
      
      // Second try: full batchexecute resolution for complex obfuscated links
      final response = await http.get(Uri.parse(link), headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36'
      }).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final html = response.body;
        final tsMatch = RegExp(r'data-n-a-ts="(\d+)"').firstMatch(html);
        final sgMatch = RegExp(r'data-n-a-sg="([^"]+)"').firstMatch(html);
        if (tsMatch != null && sgMatch != null) {
          final ts = tsMatch.group(1)!;
          final sg = sgMatch.group(1)!;
          
          final rpcUrl = 'https://news.google.com/_/DotsSplashUi/data/batchexecute?rpcids=Fbv4je';
          final param = json.encode([
            "garturlreq",
            [
              ["X","X",["X","X"],null,null,1,1,"US:en",null,1,null,null,null,null,null,0,1],
              "X",
              "X",
              1,
              [1,1,1],
              1,
              1,
              null,
              0,
              0,
              null,
              0
            ],
            b64,
            int.parse(ts),
            sg
          ]);

          final envelope = [
            "Fbv4je",
            param
          ];

          final fReq = json.encode([[envelope]]);
          
          final postResponse = await http.post(
            Uri.parse(rpcUrl),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36',
            },
            body: 'f.req=${Uri.encodeQueryComponent(fReq)}'
          ).timeout(const Duration(seconds: 5));
          
          if (postResponse.statusCode == 200) {
            final splitParts = postResponse.body.split('\n\n');
            if (splitParts.length > 1) {
              final cleaned = splitParts[1];
              final rawData = json.decode(cleaned);
              final innerDataStr = rawData[0][2];
              final innerData = json.decode(innerDataStr);
              final resolvedUrl = innerData[1];
              if (resolvedUrl != null && resolvedUrl is String) {
                return resolvedUrl;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Failed to resolve Google News link client-side: $e');
    }
    return link;
  }

  Future<List<Article>> fetchNews({String? category, String? search, int page = 1, int limit = 20}) async {
    try {
      final actualCategory = category ?? 'general';
      final feeds = Constants.categoryFeeds[actualCategory] ?? [];
      
      final List<Article> allArticles = [];

      for (final feedUrl in feeds) {
        try {
          final uri = Uri.parse(feedUrl);
          final response = await http.get(uri, headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
          }).timeout(const Duration(seconds: 10));
          
          if (response.statusCode != 200) continue;
          
          final sanitizedXmlStr = _sanitizeXml(response.body);
          final document = xml.XmlDocument.parse(sanitizedXmlStr);
          final items = document.findAllElements('item');
          
          for (final item in items) {
            final rawTitle = item.findElements('title').firstOrNull?.innerText ?? 'No Title';
            final link = item.findElements('link').firstOrNull?.innerText.trim() ?? '';
            if (link.isEmpty) continue;
            
            // Normalize title & source like the backend did
            String title = rawTitle;
            String source = _normalizeSource(feedUrl);
            final hyphen = rawTitle.lastIndexOf(' - ');
            if (hyphen != -1) {
              title = rawTitle.substring(0, hyphen).trim();
              source = rawTitle.substring(hyphen + 3).trim();
            }
            
            final description = item.findElements('description').firstOrNull?.innerText ?? '';
            final publishedAt = item.findElements('pubDate').firstOrNull?.innerText ?? '';
            
            // Enclosure or media images
            var imageUrl = '';
            final enclosure = item.findElements('enclosure').firstOrNull;
            if (enclosure != null) {
              imageUrl = enclosure.getAttribute('url') ?? '';
            }
            if (imageUrl.isEmpty) {
              final mediaContent = item.findElements('media:content').firstOrNull;
              if (mediaContent != null) {
                imageUrl = mediaContent.getAttribute('url') ?? '';
              }
            }
            
            allArticles.add(Article(
              title: title,
              description: description,
              url: link,
              urlToImage: imageUrl,
              author: 'Staff',
              sourceName: source,
              publishedAt: publishedAt,
              sectionName: actualCategory,
            ));
          }
        } catch (e) {
          print('[ApiService] Error fetching feed $feedUrl: $e');
        }
      }

      // 1. Perform deduplication based on title similarity and URL matching
      final List<Article> dedupedArticles = [];
      final Set<String> seenUrls = {};
      
      for (final art in allArticles) {
        if (seenUrls.contains(art.url)) continue;
        
        bool isDupe = false;
        for (final existing in dedupedArticles) {
          if (_titleSimilarity(existing.title, art.title) > 0.6) {
            isDupe = true;
            break;
          }
        }
        
        if (!isDupe) {
          seenUrls.add(art.url);
          dedupedArticles.add(art);
        }
      }

      // 3. Paginate
      final startIndex = (page - 1) * limit;
      if (startIndex >= dedupedArticles.length) {
        return [];
      }
      final endIndex = (startIndex + limit) < dedupedArticles.length
          ? (startIndex + limit)
          : dedupedArticles.length;
          
      return dedupedArticles.sublist(startIndex, endIndex);
    } catch (e) {
      print('[ApiService] fetchNews error: $e');
      rethrow;
    }
  }

  Future<List<Article>> fetchGuardian({String? section, int page = 1, int limit = 20}) async {
    try {
      final actualSection = section ?? 'world';
      final uri = Uri.parse('${Constants.guardianBaseUrl}/search?api-key=${Constants.guardianApiKey}&section=$actualSection&page=$page&page-size=$limit&show-fields=all');
      
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['response'] != null && data['response']['results'] is List) {
          final List results = data['response']['results'];
          return results.map((item) {
            final fields = item['fields'] ?? {};
            return Article(
              title: item['webTitle'] ?? 'No Title',
              description: fields['trailText'] ?? fields['standfirst'] ?? '',
              url: item['webUrl'] ?? '',
              urlToImage: fields['thumbnail'] ?? '',
              author: fields['byline'] ?? 'The Guardian',
              sourceName: 'The Guardian',
              publishedAt: item['webPublicationDate'] ?? '',
              sectionName: item['sectionName'] ?? 'world',
            );
          }).toList();
        }
      }
      throw Exception('Failed to load Guardian news');
    } catch (e) {
      print('[ApiService] fetchGuardian error: $e');
      rethrow;
    }
  }

  Future<Article> fetchArticleDetails(String articleUrl) async {
    try {
      // 1. Resolve URL in case it's a redirect
      final targetUrl = await _resolveGoogleNewsUrl(articleUrl);
      
      // 2. Fetch the HTML
      final response = await http.get(Uri.parse(targetUrl), headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
      }).timeout(const Duration(seconds: 12));
      
      if (response.statusCode != 200) {
        throw Exception('Status code: ${response.statusCode}');
      }
      
      final html = response.body;
      final document = html_parser.parse(html);
      
      // 3. Extract Metadata
      String getMeta(List<String> properties) {
        for (final prop in properties) {
          final el = document.querySelector('meta[property="$prop"]') ??
                     document.querySelector('meta[name="$prop"]') ??
                     document.querySelector('meta[itemprop="$prop"]');
          if (el != null) {
            final content = el.attributes['content'];
            if (content != null && content.trim().isNotEmpty) {
              return content.trim();
            }
          }
        }
        return '';
      }
      
      final title = getMeta(['og:title', 'twitter:title']).isNotEmpty 
          ? getMeta(['og:title', 'twitter:title']) 
          : (document.querySelector('h1')?.text.trim() ?? 'No Title');
          
      final description = getMeta(['og:description', 'description', 'twitter:description']);
      final image = getMeta(['og:image', 'twitter:image', 'thumbnailUrl']);
      final author = getMeta(['og:author', 'author']).isNotEmpty
          ? getMeta(['og:author', 'author'])
          : 'Staff';
          
      final date = getMeta(['article:published_time', 'pubdate', 'datePublished']).isNotEmpty
          ? getMeta(['article:published_time', 'pubdate', 'datePublished'])
          : DateTime.now().toIso8601String();
          
      // 4. Extract Article Content (paragraphs)
      final List<String> paragraphs = [];
      
      // Target common selectors for article text containers
      final containerSelectors = [
        'article',
        'main',
        '.article-body',
        '.post-content',
        '.entry-content',
        '.body'
      ];
      
      html_dom.Element? mainElement;
      for (final selector in containerSelectors) {
        final el = document.querySelector(selector);
        if (el != null) {
          mainElement = el;
          break;
        }
      }
      
      final targetScope = mainElement ?? document.body;
      if (targetScope != null) {
        final pElements = targetScope.querySelectorAll('p');
        for (final p in pElements) {
          final text = p.text.trim();
          if (text.length > 30 &&
              !text.toLowerCase().contains('cookie') &&
              !text.toLowerCase().contains('subscribe') &&
              !text.toLowerCase().contains('sign up')) {
            paragraphs.add(text);
          }
        }
      }
      
      final rawContent = paragraphs.join('\n\n');
      final finalContent = rawContent.isNotEmpty
          ? rawContent
          : (description.isNotEmpty ? description : 'No content extracted.');

      // 5. Compute read time from word count
      final wordCount = finalContent.split(RegExp(r'\s+')).length;
      final readTime = math.max(1, (wordCount / 200).ceil());

      return Article(
        title: title,
        description: description,
        urlToImage: image,
        url: targetUrl,
        author: author,
        sourceName: _normalizeSource(targetUrl),
        publishedAt: date,
        content: finalContent,
        sectionName: 'general',
        readTime: readTime,
      );
    } catch (e) {
      print('[ApiService] fetchArticleDetails error: $e');
      rethrow;
    }
  }
}
