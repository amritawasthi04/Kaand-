import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../models/article.dart';

class HiveCache {
  Box _getBox() {
    return Hive.box(Constants.hiveNewsBox);
  }

  Future<void> saveArticle(String url, Article article) async {
    final box = _getBox();
    final cacheData = {
      'cachedAt': DateTime.now().toIso8601String(),
      'article': article.toMap(),
    };
    await box.put(url, cacheData);
  }

  Article? getArticle(String url) {
    final box = _getBox();
    final data = box.get(url);
    if (data == null) return null;
    
    final articleMap = data['article'] as Map?;
    if (articleMap == null) return null;
    
    return Article.fromMap(articleMap);
  }

  bool isFresh(String key, Duration ttl) {
    final box = _getBox();
    final data = box.get(key);
    if (data == null) return false;

    final cachedAtStr = data['cachedAt'] as String?;
    if (cachedAtStr == null) return false;

    final cachedAt = DateTime.tryParse(cachedAtStr);
    if (cachedAt == null) return false;

    return DateTime.now().difference(cachedAt) < ttl;
  }

  Future<void> saveArticleList(String key, List<Article> list) async {
    final box = _getBox();
    final cacheData = {
      'cachedAt': DateTime.now().toIso8601String(),
      'list': list.map((a) => a.toMap()).toList(),
    };
    await box.put(key, cacheData);
  }

  List<Article>? getArticleList(String key) {
    final box = _getBox();
    final data = box.get(key);
    if (data == null) return null;

    final listRaw = data['list'] as List?;
    if (listRaw == null) return null;

    return listRaw.map((a) => Article.fromMap(a as Map)).toList();
  }

  Future<void> clearCache() async {
    final box = _getBox();
    await box.clear();
  }

  Future<void> clearAll() async {
    final box = _getBox();
    await box.clear();
    final userBox = Hive.box(Constants.hiveUserBox);
    await userBox.clear();
  }
}
