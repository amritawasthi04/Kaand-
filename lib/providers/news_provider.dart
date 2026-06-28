import 'package:flutter/material.dart';
import '../models/article.dart';
import '../repositories/news_repository.dart';
import '../services/guardian_service.dart';

enum NewsStatus { idle, loading, success, error }

class NewsProvider extends ChangeNotifier {
  final NewsRepository _repository = NewsRepository();
  final GuardianService _guardianService = GuardianService();

  List<Article> _articles = [];
  List<Article> get articles => _articles;

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
    _isSearchActive = false;
    notifyListeners();

    try {
      _articles = await _repository.fetchByCategory(_selectedCategory);
      _status = NewsStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = NewsStatus.error;
    }

    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchQuery = '';
      loadHeadlines();
      return;
    }

    _status = NewsStatus.loading;
    _isSearchActive = true;
    _searchQuery = query;
    notifyListeners();

    try {
      _articles = await _repository.searchArticles(query);
      _status = NewsStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = NewsStatus.error;
    }

    notifyListeners();
  }

  Future<void> loadBlogs() async {
    _blogsStatus = NewsStatus.loading;
    notifyListeners();

    try {
      _blogs = await _guardianService.fetchBlogs();
      _blogsStatus = NewsStatus.success;
    } catch (e) {
      _blogsStatus = NewsStatus.error;
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
    loadHeadlines();
  }

  /// Revalidates and updates details for a single article
  Future<Article> loadDetails(Article article) async {
    return await _repository.getArticleDetails(
      article,
      onUpdated: (updated) {
        int index = _articles.indexWhere((a) => a.url == updated.url);
        if (index != -1) {
          _articles[index] = updated;
          notifyListeners();
        }
        
        int blogIndex = _blogs.indexWhere((a) => a.url == updated.url);
        if (blogIndex != -1) {
          _blogs[blogIndex] = updated;
          notifyListeners();
        }
      },
    );
  }
}
