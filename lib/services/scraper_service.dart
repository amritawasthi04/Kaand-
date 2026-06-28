import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as dom;

class ScraperResult {
  final String? imageUrl;
  final String? description;

  ScraperResult({this.imageUrl, this.description});
}

class ScraperService {
  /// Production browser headers that bypass 403 blocks on NDTV, Cricbuzz, PIB, etc.
  static const Map<String, String> _browserHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,'
        'image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9,hi;q=0.8',
    'Cache-Control': 'no-cache',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-User': '?1',
    'Upgrade-Insecure-Requests': '1',
  };

  /// Junk paragraph keywords — paragraphs containing these are skipped.
  static const List<String> _junkKeywords = [
    'privacy policy', 'copyright', 'all rights reserved', 'advertisement',
    'cookie policy', 'terms of service', 'terms and conditions', 'sign in',
    'subscribe', 'newsletter', 'footer', 'navigation', 'cookie banner',
    'login', 'register', 'download the app', 'click here',
  ];

  /// Structural containers that hold logos/icons — images inside these are rejected.
  static const List<String> _logoContainerSelectors = [
    'header', 'nav', 'footer', 'aside',
  ];

  void _log(String tag, String message) {
    print('[ScraperService] [$tag] $message');
  }

  // ─────────────────────────────────────────────────────────
  //  PUBLIC API
  // ─────────────────────────────────────────────────────────

  /// Scrapes the publisher page with one retry. Returns empty result on total failure.
  Future<ScraperResult> scrapePublisherPageWithRetry(String url) async {
    try {
      return await _scrapePublisherPage(url);
    } catch (e) {
      _log('RETRY', 'First attempt failed for $url — $e');
      try {
        return await _scrapePublisherPage(url);
      } catch (e2) {
        _log('FAIL', 'Retry also failed for $url — $e2');
        return ScraperResult();
      }
    }
  }

  /// Strips HTML tags, decodes entities, and returns clean plain text from raw RSS description.
  String? cleanRssDescription(String rawHtml) {
    if (rawHtml.trim().isEmpty) return null;

    // Parse as HTML to get plain text
    final doc = htmlParser.parseFragment(rawHtml);
    String text = doc.text ?? '';

    // Decode remaining HTML entities
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');

    // Collapse whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Remove leftover Google News link fragments
    text = text.replaceAll(RegExp(r'https?://news\.google\.com\S*'), '');

    // Remove "View Full Coverage on Google News" type suffixes
    text = text.replaceAll(
        RegExp(r'View Full Coverage on Google News', caseSensitive: false), '');

    text = text.trim();

    if (text.length < 20) return null;
    return text;
  }

  // ─────────────────────────────────────────────────────────
  //  CORE SCRAPER
  // ─────────────────────────────────────────────────────────

  Future<ScraperResult> _scrapePublisherPage(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        ..._browserHeaders,
        'Referer': 'https://news.google.com/',
      },
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 403) {
      _log('403_BLOCKED', url);
      throw Exception('403 Forbidden');
    }
    if (response.statusCode == 404) {
      _log('404_NOT_FOUND', url);
      throw Exception('404 Not Found');
    }
    if (response.statusCode != 200) {
      _log('HTTP_ERROR', '${response.statusCode} for $url');
      throw Exception('HTTP ${response.statusCode}');
    }

    _log('SCRAPE_STARTED', url);
    final document = htmlParser.parse(response.body);

    final description = _extractDescription(document);
    final imageUrl = _extractImage(document, url);

    _log('IMAGE_SELECTED', imageUrl ?? 'null');
    _log('DESCRIPTION_SELECTED',
        description != null ? '${description.length} chars' : 'null');

    return ScraperResult(imageUrl: imageUrl, description: description);
  }

  // ─────────────────────────────────────────────────────────
  //  DESCRIPTION EXTRACTION (Issue 2)
  // ─────────────────────────────────────────────────────────

  String? _extractDescription(dom.Document document) {
    String? desc;

    // 1. og:description
    desc = _metaContent(document, 'meta[property="og:description"]');
    if (_isGoodDescription(desc)) {
      _log('DESC_SOURCE', 'og:description');
      return _maybeExtendDescription(desc!, document);
    }

    // 2. twitter:description
    desc = _metaContent(document, 'meta[name="twitter:description"]');
    if (_isGoodDescription(desc)) {
      _log('DESC_SOURCE', 'twitter:description');
      return _maybeExtendDescription(desc!, document);
    }

    // 3. JSON-LD description
    desc = _extractDescriptionFromJsonLd(document);
    if (_isGoodDescription(desc)) {
      _log('DESC_SOURCE', 'JSON-LD');
      return _maybeExtendDescription(desc!, document);
    }

    // 4. meta[name="description"]
    desc = _metaContent(document, 'meta[name="description"]');
    if (_isGoodDescription(desc)) {
      _log('DESC_SOURCE', 'meta-description');
      return _maybeExtendDescription(desc!, document);
    }

    // 5. <article> tag content
    desc = _extractFromContainer(document, 'article');
    if (_isGoodDescription(desc)) {
      _log('DESC_SOURCE', '<article>');
      return desc;
    }

    // 6. <main> tag content
    desc = _extractFromContainer(document, 'main');
    if (_isGoodDescription(desc)) {
      _log('DESC_SOURCE', '<main>');
      return desc;
    }

    // 7. Combine first meaningful body paragraphs
    desc = _combineParagraphs(document.querySelectorAll('p'));
    if (_isGoodDescription(desc)) {
      _log('DESC_SOURCE', 'body paragraphs');
      return desc;
    }

    _log('DESC_REJECTED', 'No usable description found');
    return null;
  }

  /// If the current description is under 180 chars, try to extend it with article paragraphs.
  String _maybeExtendDescription(String current, dom.Document document) {
    if (current.length >= 180) return _trimToSentence(current, 500);

    // Try to find longer content from article/main/body paragraphs
    final container =
        document.querySelector('article') ??
        document.querySelector('main') ??
        document.querySelector('body');
    if (container == null) return current;

    final paragraphs = container.querySelectorAll('p');
    final extended = _combineParagraphs(paragraphs, seedText: current);
    return extended ?? current;
  }

  /// Combines 2–5 meaningful paragraphs into a 300–500 char summary ending on a sentence.
  String? _combineParagraphs(List<dom.Element> paragraphs, {String? seedText}) {
    final buffer = StringBuffer();
    if (seedText != null) buffer.write(seedText);
    int usedCount = 0;

    for (var p in paragraphs) {
      if (usedCount >= 5) break;

      final text = p.text.trim();
      if (text.length < 40) continue;
      if (_isJunkParagraph(text)) continue;

      // Skip if this text is already in the buffer (dedup)
      if (buffer.toString().contains(text)) continue;

      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(text);
      usedCount++;

      if (buffer.length >= 300) break;
    }

    final result = buffer.toString().trim();
    if (result.length < 40) return null;
    return _trimToSentence(result, 500);
  }

  /// Extracts meaningful text from a container element (article or main).
  String? _extractFromContainer(dom.Document document, String selector) {
    final container = document.querySelector(selector);
    if (container == null) return null;
    return _combineParagraphs(container.querySelectorAll('p'));
  }

  /// Trims text to maxLength, ending on a complete sentence boundary.
  String _trimToSentence(String text, int maxLength) {
    if (text.length <= maxLength) return text;

    final truncated = text.substring(0, maxLength);
    // Find last sentence-ending punctuation
    final lastPeriod = truncated.lastIndexOf('. ');
    final lastExcl = truncated.lastIndexOf('! ');
    final lastQmark = truncated.lastIndexOf('? ');
    final lastEnd = [lastPeriod, lastExcl, lastQmark]
        .where((i) => i > 0)
        .fold<int>(-1, (a, b) => a > b ? a : b);

    if (lastEnd > maxLength ~/ 2) {
      return truncated.substring(0, lastEnd + 1).trim();
    }
    return '$truncated…';
  }

  bool _isJunkParagraph(String text) {
    final lower = text.toLowerCase();
    for (var kw in _junkKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  bool _isGoodDescription(String? desc) {
    return desc != null && desc.trim().length >= 30;
  }

  String? _metaContent(dom.Document doc, String selector) {
    final el = doc.querySelector(selector);
    final content = el?.attributes['content']?.trim();
    return (content != null && content.isNotEmpty) ? content : null;
  }

  String? _extractDescriptionFromJsonLd(dom.Document document) {
    final scripts =
        document.querySelectorAll('script[type="application/ld+json"]');
    for (var script in scripts) {
      try {
        final decoded = jsonDecode(script.text);
        final desc = _findDescriptionInJson(decoded);
        if (desc != null && desc.trim().length >= 30) return desc.trim();
      } catch (_) {}
    }
    return null;
  }

  String? _findDescriptionInJson(dynamic json) {
    if (json is Map) {
      for (var key in ['description', 'articleBody']) {
        if (json.containsKey(key) && json[key] is String) {
          return json[key] as String;
        }
      }
      for (var val in json.values) {
        final res = _findDescriptionInJson(val);
        if (res != null) return res;
      }
    } else if (json is List) {
      for (var item in json) {
        final res = _findDescriptionInJson(item);
        if (res != null) return res;
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────
  //  IMAGE EXTRACTION (Issue 4 + Issue 5)
  // ─────────────────────────────────────────────────────────

  String? _extractImage(dom.Document document, String pageUrl) {
    String? img;

    // 1. og:image
    img = _metaContent(document, 'meta[property="og:image"]');
    if (_isValidImageUrl(img)) return _absoluteUrl(img!, pageUrl);

    // 2. og:image:url
    img = _metaContent(document, 'meta[property="og:image:url"]');
    if (_isValidImageUrl(img)) return _absoluteUrl(img!, pageUrl);

    // 3. twitter:image
    img = _metaContent(document, 'meta[name="twitter:image"]');
    if (_isValidImageUrl(img)) return _absoluteUrl(img!, pageUrl);

    // 4. JSON-LD image
    img = _extractImageFromJsonLd(document);
    if (_isValidImageUrl(img)) {
      _log('IMAGE_SOURCE', 'JSON-LD');
      return _absoluteUrl(img!, pageUrl);
    }

    // 5. link[rel="image_src"]
    img = document
        .querySelector('link[rel="image_src"]')
        ?.attributes['href'];
    if (_isValidImageUrl(img)) {
      _log('IMAGE_SOURCE', 'image_src');
      return _absoluteUrl(img!, pageUrl);
    }

    // 6. <picture> source
    img = _extractFromPictureSource(document);
    if (_isValidImageUrl(img)) {
      _log('IMAGE_SOURCE', '<picture>');
      return _absoluteUrl(img!, pageUrl);
    }

    // 7. Hero image from article/main/figure containers
    img = _extractHeroImage(document);
    if (_isValidImageUrl(img)) {
      _log('IMAGE_SOURCE', 'hero-img');
      return _absoluteUrl(img!, pageUrl);
    }

    // 8. General fallback: first qualifying <img> in body
    img = _extractFirstQualifyingImg(document);
    if (_isValidImageUrl(img)) {
      _log('IMAGE_SOURCE', 'body-img');
      return _absoluteUrl(img!, pageUrl);
    }

    _log('IMAGE_REJECTED', 'No valid image found');
    return null;
  }

  /// Extracts image from <picture><source> tags.
  String? _extractFromPictureSource(dom.Document document) {
    final sources = document.querySelectorAll('picture source');
    for (var source in sources) {
      final srcset = source.attributes['srcset'];
      if (srcset != null && srcset.isNotEmpty) {
        final candidate = _parseSrcset(srcset);
        if (_isValidImageUrl(candidate)) return candidate;
      }
    }
    return null;
  }

  /// Extracts hero image from article, main, or figure containers — skipping logo zones.
  String? _extractHeroImage(dom.Document document) {
    for (var selector in ['article img', 'main img', 'figure img']) {
      final imgs = document.querySelectorAll(selector);
      for (var img in imgs) {
        if (_isInsideLogoContainer(img)) continue;
        final url = _bestImgUrl(img);
        if (_isValidImageUrl(url)) return url;
      }
    }
    return null;
  }

  /// First qualifying <img> in the page body, skipping logo containers.
  String? _extractFirstQualifyingImg(dom.Document document) {
    final imgs = document.querySelectorAll('img');
    for (var img in imgs) {
      if (_isInsideLogoContainer(img)) continue;
      final url = _bestImgUrl(img);
      if (_isValidImageUrl(url)) return url;
    }
    return null;
  }

  /// Returns the best URL from an <img> element, checking multiple attributes.
  String? _bestImgUrl(dom.Element img) {
    // Priority: srcset (highest res) > data-src > data-lazy-src > data-original > src
    final srcset = img.attributes['srcset'];
    if (srcset != null && srcset.isNotEmpty) {
      final candidate = _parseSrcset(srcset);
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    return img.attributes['data-src'] ??
        img.attributes['data-lazy-src'] ??
        img.attributes['data-original'] ??
        img.attributes['src'];
  }

  /// Checks if an <img> element is inside header/nav/footer/aside (logo zone).
  bool _isInsideLogoContainer(dom.Element img) {
    dom.Element? parent = img.parent;
    int depth = 0;
    while (parent != null && depth < 8) {
      final tag = parent.localName?.toLowerCase() ?? '';
      if (_logoContainerSelectors.contains(tag)) return true;

      // Also check class/id for logo hints
      final cls = (parent.attributes['class'] ?? '').toLowerCase();
      final id = (parent.attributes['id'] ?? '').toLowerCase();
      if (cls.contains('logo') ||
          cls.contains('brand') ||
          cls.contains('icon') ||
          cls.contains('avatar') ||
          cls.contains('nav') ||
          id.contains('logo') ||
          id.contains('brand')) {
        return true;
      }
      parent = parent.parent;
      depth++;
    }
    return false;
  }

  /// Parses srcset attribute and returns the highest-resolution candidate URL.
  String? _parseSrcset(String srcset) {
    try {
      final parts = srcset.split(',');
      if (parts.isEmpty) return null;
      // Last entry is typically the largest
      final lastPart = parts.last.trim();
      final segments = lastPart.split(RegExp(r'\s+'));
      if (segments.isNotEmpty) {
        final url = segments.first;
        if (url.startsWith('http') || url.startsWith('//')) return url;
      }
    } catch (_) {}
    return null;
  }

  /// Resolves protocol-relative and relative URLs to absolute.
  String _absoluteUrl(String url, String pageUrl) {
    if (url.startsWith('//')) return 'https:$url';
    if (url.startsWith('http')) return url;
    // Relative URL — resolve against page
    try {
      return Uri.parse(pageUrl).resolve(url).toString();
    } catch (_) {
      return url;
    }
  }

  // ─────────────────────────────────────────────────────────
  //  IMAGE VALIDATION (Issue 5 — reject logos)
  // ─────────────────────────────────────────────────────────

  bool _isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final lower = url.toLowerCase().trim();

    // Must be a real URL
    if (!lower.startsWith('http://') &&
        !lower.startsWith('https://') &&
        !lower.startsWith('//')) {
      return false;
    }

    // Reject known junk domains & keywords
    const rejectKeywords = [
      'gstatic.com',
      'favicon',
      'logo',
      'icon',
      'brand',
      'avatar',
      'placeholder',
      'spinner',
      'loading',
      'pixel',
      'tracking',
      'beacon',
      'blank.gif',
      'spacer',
      '1x1',
      'transparent',
    ];
    for (var kw in rejectKeywords) {
      if (lower.contains(kw)) {
        _log('IMAGE_REJECTED', 'keyword "$kw" in $url');
        return false;
      }
    }

    // Reject SVGs (usually logos/icons)
    if (lower.endsWith('.svg')) {
      _log('IMAGE_REJECTED', 'SVG file: $url');
      return false;
    }

    // Reject very small images by URL dimension hints (e.g. /50x50/ or w=40)
    final dimMatch = RegExp(r'[/\-_](\d+)x(\d+)[/\-_.]').firstMatch(lower);
    if (dimMatch != null) {
      final w = int.tryParse(dimMatch.group(1)!) ?? 999;
      final h = int.tryParse(dimMatch.group(2)!) ?? 999;
      if (w < 400 || h < 200) {
        _log('IMAGE_REJECTED', 'Too small (${w}x$h): $url');
        return false;
      }
    }

    return true;
  }

  // ─────────────────────────────────────────────────────────
  //  JSON-LD IMAGE EXTRACTION
  // ─────────────────────────────────────────────────────────

  String? _extractImageFromJsonLd(dom.Document document) {
    final scripts =
        document.querySelectorAll('script[type="application/ld+json"]');
    for (var script in scripts) {
      try {
        final decoded = jsonDecode(script.text);
        final img = _findImageInJson(decoded);
        if (img != null && img.isNotEmpty && _isValidImageUrl(img)) {
          return img;
        }
      } catch (_) {}
    }
    return null;
  }

  String? _findImageInJson(dynamic json) {
    if (json is Map) {
      for (var key in ['image', 'thumbnail', 'thumbnailUrl']) {
        if (json.containsKey(key)) {
          final val = json[key];
          if (val is String) return val;
          if (val is Map && val.containsKey('url') && val['url'] is String) {
            return val['url'] as String;
          }
          if (val is List && val.isNotEmpty) {
            final first = val.first;
            if (first is String) return first;
            if (first is Map &&
                first.containsKey('url') &&
                first['url'] is String) {
              return first['url'] as String;
            }
          }
        }
      }
      for (var val in json.values) {
        final res = _findImageInJson(val);
        if (res != null) return res;
      }
    } else if (json is List) {
      for (var item in json) {
        final res = _findImageInJson(item);
        if (res != null) return res;
      }
    }
    return null;
  }
}
