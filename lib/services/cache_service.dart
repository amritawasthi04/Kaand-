import 'package:hive/hive.dart';
import '../models/article_model.dart';

class CacheService {
  static const String _boxName = 'news_images';

  void _log(String tag, String message) {
    print('[CacheService] [$tag] $message');
  }

  /// Open the cache box (lazy — reuses if already open).
  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  /// Retrieve a cached article. Returns null on cache miss or TTL expiry.
  Future<Article?> getArticle(String url, Duration ttl) async {
    try {
      final box = await _getBox();
      final String cacheKey = 'article_${url.hashCode}';

      if (!box.containsKey(cacheKey)) return null;

      final cachedData = box.get(cacheKey);
      if (cachedData is Map) {
        // New format with TTL wrapper
        if (cachedData.containsKey('article') && cachedData.containsKey('cachedAt')) {
          final cachedAt = cachedData['cachedAt'] as int;
          final age = DateTime.now().millisecondsSinceEpoch - cachedAt;

          if (age > ttl.inMilliseconds) {
            _log('TTL_EXPIRED', 'Removing stale entry for key $cacheKey');
            await box.delete(cacheKey);
            return null;
          }

          final articleMap = cachedData['article'];
          if (articleMap is Map) {
            return Article.fromMap(articleMap);
          }
        } else {
          // Old format compatibility (no TTL wrapper — treat as valid)
          return Article.fromMap(cachedData);
        }
      }
    } catch (e) {
      _log('READ_ERROR', '$e');
    }
    return null;
  }

  /// Save article to cache with TTL timestamp and scrapedAt metadata.
  Future<void> saveArticle(String url, Article article) async {
    try {
      final box = await _getBox();
      final String cacheKey = 'article_${url.hashCode}';
      final now = DateTime.now().millisecondsSinceEpoch;

      final cacheData = {
        'article': {
          ...article.toMap(),
          'scrapedAt': DateTime.now().toIso8601String(),
        },
        'cachedAt': now,
      };

      await box.put(cacheKey, cacheData);
    } catch (e) {
      _log('SAVE_ERROR', '$e');
    }
  }

  /// Remove all entries whose TTL has expired.
  Future<void> cleanExpiredCache(Duration ttl) async {
    try {
      final box = await _getBox();
      final now = DateTime.now().millisecondsSinceEpoch;
      final keysToDelete = <dynamic>[];

      for (var key in box.keys) {
        final val = box.get(key);
        if (val is Map && val.containsKey('cachedAt')) {
          final cachedAt = val['cachedAt'] as int;
          if (now - cachedAt > ttl.inMilliseconds) {
            keysToDelete.add(key);
          }
        }
      }

      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);
        _log('CLEANED', '${keysToDelete.length} expired entries removed');
      }
    } catch (e) {
      _log('CLEAN_ERROR', '$e');
    }
  }
}
