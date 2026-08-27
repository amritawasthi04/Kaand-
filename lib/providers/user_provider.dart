import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../models/article.dart';
import '../models/user_blog.dart';

class UserProvider extends ChangeNotifier {
  String _name = '';
  String get name => _name.isEmpty ? 'Reader' : _name;

  bool get isOnboarded => _name.isNotEmpty;
  bool get hasName => _name.isNotEmpty;

  List<Article> _bookmarks = [];
  List<Article> get bookmarks => _bookmarks;

  List<UserBlog> _userBlogs = [];
  List<UserBlog> get userBlogs => List.unmodifiable(_userBlogs);

  int _currentStreak = 0;
  int get currentStreak => _currentStreak;

  int _longestStreak = 0;
  int get longestStreak => _longestStreak;

  UserProvider() {
    _loadName();
    _loadBookmarks();
    _loadUserBlogs();
    _loadReadingStreak();
  }

  void _loadName() {
    if (!Hive.isBoxOpen(Constants.hiveUserBox)) {
      _name = '';
      return;
    }
    final box = Hive.box(Constants.hiveUserBox);
    _name = box.get('username', defaultValue: '') as String;
  }

  void _loadBookmarks() {
    if (!Hive.isBoxOpen(Constants.hiveUserBox)) return;
    final box = Hive.box(Constants.hiveUserBox);
    final rawBookmarks = box.get('bookmarks', defaultValue: []) as List;
    _bookmarks = rawBookmarks
        .map((m) => Article.fromMap(Map<dynamic, dynamic>.from(m)))
        .toList();
  }

  void _loadUserBlogs() {
    if (!Hive.isBoxOpen(Constants.hiveUserBox)) return;
    final box = Hive.box(Constants.hiveUserBox);
    final rawBlogs = box.get('user_blogs', defaultValue: []) as List;
    _userBlogs = rawBlogs
        .map((item) => UserBlog.fromMap(Map<dynamic, dynamic>.from(item as Map)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void _loadReadingStreak() {
    if (!Hive.isBoxOpen(Constants.hiveUserBox)) return;
    final box = Hive.box(Constants.hiveUserBox);
    _currentStreak = box.get('current_read_streak', defaultValue: 0) as int;
    _longestStreak = box.get('longest_read_streak', defaultValue: 0) as int;
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

  Future<void> saveBlog({UserBlog? existing, required String title, required String body}) async {
    final now = DateTime.now();
    final blog = existing == null
        ? UserBlog(
            id: now.microsecondsSinceEpoch.toString(),
            title: title.trim(),
            body: body.trim(),
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(title: title.trim(), body: body.trim(), updatedAt: now);

    _userBlogs.removeWhere((item) => item.id == blog.id);
    _userBlogs.insert(0, blog);
    final box = Hive.box(Constants.hiveUserBox);
    await box.put('user_blogs', _userBlogs.map((item) => item.toMap()).toList());
    notifyListeners();
  }

  Future<void> deleteBlog(String id) async {
    _userBlogs.removeWhere((item) => item.id == id);
    final box = Hive.box(Constants.hiveUserBox);
    await box.put('user_blogs', _userBlogs.map((item) => item.toMap()).toList());
    notifyListeners();
  }

  Future<void> recordReadingDay() async {
    if (!Hive.isBoxOpen(Constants.hiveUserBox)) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final box = Hive.box(Constants.hiveUserBox);
    final lastRead = DateTime.tryParse(box.get('last_read_day', defaultValue: '') as String? ?? '');
    final lastDay = lastRead == null ? null : DateTime(lastRead.year, lastRead.month, lastRead.day);

    if (lastDay != null && lastDay == today) return;

    final yesterday = today.subtract(const Duration(days: 1));
    _currentStreak = lastDay == yesterday ? _currentStreak + 1 : 1;
    _longestStreak = _currentStreak > _longestStreak ? _currentStreak : _longestStreak;

    await box.put('last_read_day', today.toIso8601String());
    await box.put('current_read_streak', _currentStreak);
    await box.put('longest_read_streak', _longestStreak);
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
