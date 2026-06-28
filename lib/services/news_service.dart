import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/article_model.dart';
import 'cache_service.dart';
import 'resolver_service.dart';
import 'scraper_service.dart';

class NewsService {
  final CacheService _cacheService = CacheService();
  final ResolverService _resolverService = ResolverService();
  final ScraperService _scraperService = ScraperService();

  static const Duration _cacheTtl = Duration(hours: 24);

  void _log(String tag, String message) {
    print('[NewsService] [$tag] $message');
  }

  /// Fetches and parses an RSS feed, returning processed articles.
  Future<List<Article>> fetchAndParseRss(Uri uri, String category) async {
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load RSS feed: status code ${response.statusCode}');
    }

    final document = XmlDocument.parse(response.body);
    final items = document.findAllElements('item').toList();
    _log('RSS_PARSED', '${items.length} items from ${uri.host}');

    final List<Article?> results = List.filled(items.length, null);
    int currentIndex = 0;
    const int concurrencyLimit = 5;

    Future<void> worker() async {
      while (currentIndex < items.length) {
        final int i = currentIndex++;
        results[i] = await processItem(items[i], category);
      }
    }

    final List<Future<void>> workers = List.generate(
      concurrencyLimit < items.length ? concurrencyLimit : items.length,
      (_) => worker(),
    );

    await Future.wait(workers);

    return results.whereType<Article>().toList();
  }

  /// Processes a single RSS <item> element through the full pipeline:
  /// cache check → resolve redirect → scrape publisher → RSS fallback → cache save.
  Future<Article?> processItem(XmlElement element, String category) async {
    try {
      final rawTitle = element.findElements('title').firstOrNull?.innerText ?? 'No Title';
      final googleRssLink = element.findElements('link').firstOrNull?.innerText ?? '';
      final pubDateStr = element.findElements('pubDate').firstOrNull?.innerText ?? '';
      final sourceName = element.findElements('source').firstOrNull?.innerText ?? 'Google News';
      final rssDescRaw = element.findElements('description').firstOrNull?.innerText ?? '';

      // Clean title: strip " - Source Name" suffix
      String cleanTitle = rawTitle;
      final sourceSuffix = ' - $sourceName';
      if (cleanTitle.endsWith(sourceSuffix)) {
        cleanTitle = cleanTitle.substring(0, cleanTitle.length - sourceSuffix.length);
      }

      final parsedDate = _parseRfc822Date(pubDateStr);
      final publishedAt = parsedDate?.toIso8601String() ?? pubDateStr;

      if (googleRssLink.isEmpty) {
        return Article(
          title: cleanTitle,
          description: _scraperService.cleanRssDescription(rssDescRaw),
          url: '',
          publishedAt: publishedAt,
          sourceName: sourceName,
          sectionName: category,
        );
      }

      // ── STAGE: Cache Check ──
      final cachedArticle = await _cacheService.getArticle(googleRssLink, _cacheTtl);
      if (cachedArticle != null) {
        _log('HIVE_CACHE_HIT', cleanTitle);
        return cachedArticle;
      }
      _log('HIVE_CACHE_MISS', cleanTitle);

      // ── STAGE: Resolve Google redirect ──
      final resolvedUrl = await _resolverService.resolveGoogleNewsUrl(googleRssLink);
      final finalUrl = resolvedUrl ?? googleRssLink;
      if (resolvedUrl != null) {
        _log('RESOLVED_URL', resolvedUrl);
      }

      // ── STAGE: Scrape publisher page ──
      String? imageUrl;
      String? description;

      if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
        final scrapeRes = await _scraperService.scrapePublisherPageWithRetry(resolvedUrl);
        imageUrl = scrapeRes.imageUrl;
        description = scrapeRes.description;
      }

      // ── STAGE: RSS Fallback (Issue 3) ──
      // If scraping yielded no description, fall back to cleaned RSS text.
      if (description == null || description.isEmpty) {
        final rssClean = _scraperService.cleanRssDescription(rssDescRaw);
        if (rssClean != null) {
          description = rssClean;
          _log('FALLBACK_TO_RSS', '${description.length} chars from RSS');
        }
      }

      final article = Article(
        title: cleanTitle,
        description: description,
        url: finalUrl,
        publishedAt: publishedAt,
        sourceName: sourceName,
        urlToImage: imageUrl,
        sectionName: category,
      );

      // ── STAGE: Cache Save (Issue 6) ──
      // Always cache, even if image/description are null.
      // This prevents re-scraping blocked publishers on every refresh.
      await _cacheService.saveArticle(googleRssLink, article);
      _log('HIVE_SAVED', cleanTitle);

      return article;
    } catch (e) {
      _log('ERROR', 'Failed to process item: $e');
      return null;
    }
  }

  DateTime? _parseRfc822Date(String dateString) {
    try {
      final cleaned = dateString.replaceAll(RegExp(r'\s+'), ' ').trim();
      final parts = cleaned.split(' ');
      if (parts.length < 4) return null;

      final day = int.tryParse(parts[1]);
      final monthStr = parts[2].toLowerCase();
      final year = int.tryParse(parts[3]);

      if (day == null || year == null) return null;

      final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
      final month = months.indexOf(monthStr) + 1;
      if (month == 0) return null;

      int hour = 0, minute = 0, second = 0;
      if (parts.length > 4) {
        final timeParts = parts[4].split(':');
        if (timeParts.length >= 2) {
          hour = int.tryParse(timeParts[0]) ?? 0;
          minute = int.tryParse(timeParts[1]) ?? 0;
        }
        if (timeParts.length >= 3) {
          second = int.tryParse(timeParts[2]) ?? 0;
        }
      }

      return DateTime.utc(year, month, day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }
}
