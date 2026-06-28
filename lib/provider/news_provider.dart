import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../services/news_repository.dart';

enum NewsStatus { idle, loading, success, error }

class NewsProvider extends ChangeNotifier {
  final NewsRepository _repository = NewsRepository();

  List<Article> _articles = [];
  List<Article> get articles => _articles;

  NewsStatus _status = NewsStatus.idle;
  NewsStatus get status => _status;

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
}