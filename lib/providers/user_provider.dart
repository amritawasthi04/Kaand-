import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../models/article.dart';

class UserProvider extends ChangeNotifier {
  String _name = '';
  String get name => _name.isEmpty ? 'Reader' : _name;

  bool get isOnboarded => _name.isNotEmpty;
  bool get hasName => _name.isNotEmpty;

  List<Article> _bookmarks = [];
  List<Article> get bookmarks => _bookmarks;

  UserProvider() {
    _loadName();
    _loadBookmarks();
  }

  void _loadName() {
    if (!Hive.isBoxOpen(Constants.hiveUserBox)) {
      _name = '';
      return;
    }
    final box = Hive.box(Constants.hiveUserBox);
    _name = box.get('username', defaultValue: '') as String;
    notifyListeners();
  }

  void _loadBookmarks() {
    if (!Hive.isBoxOpen(Constants.hiveUserBox)) return;
    final box = Hive.box(Constants.hiveUserBox);
    final rawBookmarks = box.get('bookmarks', defaultValue: []) as List;
    _bookmarks = rawBookmarks
        .map((m) => Article.fromMap(Map<dynamic, dynamic>.from(m)))
        .toList();
    notifyListeners();
  }

  bool isBookmarked(Article article) {
    return _bookmarks.any((a) => a.url == article.url);
  }

  Future<void> toggleBookmark(Article article) async {
    if (isBookmarked(article)) {
      _bookmarks.removeWhere((a) => a.url == article.url);
    } else {
      _bookmarks.add(article);
    }
    final box = Hive.box(Constants.hiveUserBox);
    await box.put('bookmarks', _bookmarks.map((a) => a.toMap()).toList());
    notifyListeners();
  }

  Future<void> saveName(String userName) async {
    final box = Hive.box(Constants.hiveUserBox);
    await box.put('username', userName.trim());
    _name = userName.trim();
    notifyListeners();
  }

  Future<void> clearName() async {
    final box = Hive.box(Constants.hiveUserBox);
    await box.delete('username');
    _name = '';
    notifyListeners();
  }
}
