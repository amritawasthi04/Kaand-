import 'dart:async';
import 'package:flutter/material.dart';
import '../models/article.dart';
import '../repositories/news_repository.dart';

enum NewsStatus { idle, loading, success, error }

class NewsProvider extends ChangeNotifier {
  final NewsRepository _repository = NewsRepository();

  List<Article> _allArticles = [];
  List<Article> _filteredArticles = [];
  List<Article> get articles => _filteredArticles;

  List<Article> get trendingArticles => _filteredArticles.take(5).toList();
  List<Article> get latestArticles => _filteredArticles.skip(5).toList();

  Article? _heroArticle;
  Article? get heroArticle => _heroArticle;

  List<Article> _guardianArticles = [];
  List<Article> get guardianArticles => _guardianArticles;

  List<Article> _blogs = [];
  List<Article> get blogs => _blogs;

  NewsStatus _status = NewsStatus.idle;
  NewsStatus get status => _status;

  NewsStatus _blogsStatus = NewsStatus.idle;
  NewsStatus get blogsStatus => _blogsStatus;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  String _selectedCategory = 'general';
  String get selectedCategory => _selectedCategory;

  bool _isSearchActive = false;
  bool get isSearchActive => _isSearchActive;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Timer? _searchDebounce;

  static const List<String> categories = [
    'general',
    'business',
    'entertainment',
    'health',
    'science',
    'sports',
    'technology',
  ];

  Future<void> loadHeadlines() async {
    _status = NewsStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final futures = await Future.wait([
        _repository.fetchByCategory(_selectedCategory, onUpdated: (freshNews) {
          _allArticles = freshNews;
          _filterArticlesLocal();
        }),
        _repository.fetchGuardian(section: 'world', onUpdated: (freshGuardian) {
          _guardianArticles = freshGuardian;
          if (freshGuardian.isNotEmpty) {
            _heroArticle = freshGuardian.first;
          }
          notifyListeners();
        }),
        _repository.fetchGuardian(section: 'opinion', onUpdated: (freshBlogs) {
          _blogs = freshBlogs;
          notifyListeners();
        }),
      ]);

      final newsList = futures[0] as List<Article>;
      final guardianList = futures[1] as List<Article>;
      final blogsList = futures[2] as List<Article>;

      _allArticles = newsList;
      _guardianArticles = guardianList;
      if (guardianList.isNotEmpty) {
        _heroArticle = guardianList.first;
      }
      _blogs = blogsList.isNotEmpty ? blogsList : guardianList;

      _filterArticlesLocal();
      _status = NewsStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      if (_filteredArticles.isEmpty) {
        _status = NewsStatus.error;
      } else {
        _status = NewsStatus.success;
      }
    }

    notifyListeners();
  }

  Future<void> loadBlogs() async {
    _blogsStatus = NewsStatus.loading;
    notifyListeners();
    try {
      _blogs = await _repository.fetchGuardian(
        section: 'opinion',
        onUpdated: (freshBlogs) {
          _blogs = freshBlogs;
          notifyListeners();
        },
      );
      _blogsStatus = NewsStatus.success;
    } catch (e) {
      _blogsStatus = NewsStatus.error;
    }
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _isSearchActive = query.trim().isNotEmpty;
    notifyListeners();

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _filterArticlesLocal();
    });
  }

  void _filterArticlesLocal() {
    if (_searchQuery.trim().isEmpty) {
      _filteredArticles = List.from(_allArticles);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredArticles = _allArticles.where((a) {
        final titleMatch = a.title.toLowerCase().contains(query);
        final descMatch = a.description?.toLowerCase().contains(query) ?? false;
        final srcMatch = a.sourceName?.toLowerCase().contains(query) ?? false;
        return titleMatch || descMatch || srcMatch;
      }).toList();
    }
    notifyListeners();
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    loadHeadlines();
  }

  void clearSearch() {
    _isSearchActive = false;
    _searchQuery = '';
    _filterArticlesLocal();
  }

  /// Loads details for a single article (AI summary + content)
  Future<Article> loadDetails(Article article) async {
    return await _repository.getArticleDetails(
      article,
      onUpdated: (updated) {
        int index = _allArticles.indexWhere((a) => a.url == updated.url);
        if (index != -1) {
          _allArticles[index] = updated;
          _filterArticlesLocal();
        }
        
        int blogIndex = _blogs.indexWhere((a) => a.url == updated.url);
        if (blogIndex != -1) {
          _blogs[blogIndex] = updated;
          notifyListeners();
        }

        if (_heroArticle?.url == updated.url) {
          _heroArticle = updated;
          notifyListeners();
        }

        int guardIndex = _guardianArticles.indexWhere((a) => a.url == updated.url);
        if (guardIndex != -1) {
          _guardianArticles[guardIndex] = updated;
          notifyListeners();
        }
      },
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
