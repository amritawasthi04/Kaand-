import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../core/utils/hash.dart';
import '../models/article.dart';

class HiveCache {
  Box _getBox() {
    return Hive.box(Constants.hiveNewsBox);
  }

  Future<void> saveArticle(String url, Article article) async {
    final box = _getBox();
    final key = md5Hash(url);
    final cacheData = {
      'cachedAt': DateTime.now().toIso8601String(),
      'article': article.toMap(),
    };
    await box.put(key, cacheData);
  }

  Article? getArticle(String url) {
    final box = _getBox();
    final key = md5Hash(url);
    final data = box.get(key);
    if (data == null) return null;
    
    final articleMap = data['article'] as Map?;
    if (articleMap == null) return null;
    
    return Article.fromMap(articleMap);
  }

  bool isFresh(String url, Duration ttl) {
    final box = _getBox();
    final key = md5Hash(url);
    final data = box.get(key);
    if (data == null) return false;

    final cachedAtStr = data['cachedAt'] as String?;
    if (cachedAtStr == null) return false;

    final cachedAt = DateTime.tryParse(cachedAtStr);
    if (cachedAt == null) return false;

    return DateTime.now().difference(cachedAt) < ttl;
  }

  Future<void> clearCache() async {
    final box = _getBox();
    await box.clear();
  }
}
