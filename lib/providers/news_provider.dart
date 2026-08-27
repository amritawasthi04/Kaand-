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

  List<Article> _trendingArticles = [];
  List<Article> get trendingArticles => _trendingArticles;
  List<Article> _latestArticles = [];
  List<Article> get latestArticles => _latestArticles;

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

  // Pagination states
  int _homePage = 1;
  bool _homeHasMore = true;
  bool _homeLoadingMore = false;
  bool get homeHasMore => _homeHasMore;
  bool get homeLoadingMore => _homeLoadingMore;

  int _searchPage = 1;
  bool _searchHasMore = true;
  bool _searchLoadingMore = false;
  bool get searchHasMore => _searchHasMore;
  bool get searchLoadingMore => _searchLoadingMore;

  int _blogsPage = 1;
  bool _blogsHasMore = true;
  bool _blogsLoadingMore = false;
  bool get blogsHasMore => _blogsHasMore;
  bool get blogsLoadingMore => _blogsLoadingMore;

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
    _homePage = 1;
    _homeHasMore = true;
    _homeLoadingMore = false;
    notifyListeners();

    try {
      final newsList = await _repository
          .fetchByCategory(_selectedCategory, page: 1)
          .catchError((_) => <Article>[]);

      final guardianWorldList = await _repository
          .fetchGuardian(section: 'world', page: 1)
          .catchError((_) => <Article>[]);

      final guardianOpinionList = await _repository
          .fetchGuardian(section: 'opinion', page: 1)
          .catchError((_) => <Article>[]);

      final trendingList = await _repository.trendingService
          .getTrending(limit: 5)
          .catchError((_) => <Article>[]);

      _allArticles = newsList;
      _guardianArticles = guardianWorldList;
      if (guardianWorldList.isNotEmpty) {
        _heroArticle = guardianWorldList.first;
      }
      _blogs = guardianOpinionList.isNotEmpty
          ? guardianOpinionList
          : guardianWorldList;
      _trendingArticles =
          trendingList.isNotEmpty ? trendingList : newsList.take(5).toList();

      _filterArticlesLocal();
      _status =
          _filteredArticles.isNotEmpty ? NewsStatus.success : NewsStatus.error;
      if (_status == NewsStatus.error) {
        _errorMessage = 'Unable to fetch news feed. Please try again.';
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status =
          _filteredArticles.isEmpty ? NewsStatus.error : NewsStatus.success;
    }

    notifyListeners();
  }

  Future<void> loadNextHeadlinesPage() async {
    if (_homeLoadingMore || !_homeHasMore) return;
    _homeLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _homePage + 1;
      final fresh = await _repository.fetchByCategory(
        _selectedCategory,
        page: nextPage,
      );
      if (fresh.isEmpty || fresh.length < 20) {
        _homeHasMore = false;
      } else {
        _homePage = nextPage;
        _appendArticles(fresh);
      }
    } catch (_) {}
    _homeLoadingMore = false;
    notifyListeners();
  }

  void _appendArticles(List<Article> fresh) {
    final seen = _allArticles.map((a) => a.url).toSet();
    for (final art in fresh) {
      if (!seen.contains(art.url)) {
        _allArticles.add(art);
        seen.add(art.url);
      }
    }
    _filterArticlesLocal();
  }

  Future<void> loadBlogs() async {
    _blogsStatus = NewsStatus.loading;
    _blogsPage = 1;
    _blogsHasMore = true;
    _blogsLoadingMore = false;
    notifyListeners();
    try {
      _blogs = await _repository.fetchGuardian(
        section: 'opinion',
        page: 1,
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

  Future<void> loadNextBlogsPage() async {
    if (_blogsLoadingMore || !_blogsHasMore) return;
    _blogsLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _blogsPage + 1;
      final fresh = await _repository.fetchGuardian(
        section: 'opinion',
        page: nextPage,
      );
      if (fresh.isEmpty || fresh.length < 20) {
        _blogsHasMore = false;
      } else {
        _blogsPage = nextPage;
        final seen = _blogs.map((a) => a.url).toSet();
        for (final art in fresh) {
          if (!seen.contains(art.url)) {
            _blogs.add(art);
          }
        }
      }
    } catch (_) {}
    _blogsLoadingMore = false;
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _isSearchActive = query.trim().isNotEmpty;

    if (!_isSearchActive) {
      _errorMessage = '';
      _filteredArticles = [];
      _status = NewsStatus.success;
      notifyListeners();
      _searchDebounce?.cancel();
      return;
    }

    notifyListeners();

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (_isSearchActive) {
        _performSearchBackend();
      }
    });
  }

  Future<void> retrySearch() async {
    if (_isSearchActive) {
      await _performSearchBackend();
    }
  }

  Future<void> _performSearchBackend() async {
    _status = NewsStatus.loading;
    _errorMessage = '';
    _searchPage = 1;
    _searchHasMore = true;
    _searchLoadingMore = false;
    notifyListeners();
    try {
      final results =
          await _repository.searchService.searchArticles(_searchQuery, page: 1);
      _filteredArticles = results;
      _status = NewsStatus.success;
    } catch (e) {
      _status = NewsStatus.error;
      _errorMessage = e is Exception
          ? e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')
          : 'An unexpected error occurred while searching.';
    }
    notifyListeners();
  }

  Future<void> loadNextSearchPage() async {
    if (!_isSearchActive || _searchLoadingMore || !_searchHasMore) return;
    _searchLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _searchPage + 1;
      final fresh = await _repository.searchService.searchArticles(
        _searchQuery,
        page: nextPage,
      );
      if (fresh.isEmpty || fresh.length < 20) {
        _searchHasMore = false;
      } else {
        _searchPage = nextPage;
        final seen = _filteredArticles.map((a) => a.url).toSet();
        for (final art in fresh) {
          if (!seen.contains(art.url)) {
            _filteredArticles.add(art);
          }
        }
      }
    } catch (_) {}
    _searchLoadingMore = false;
    notifyListeners();
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
    if (_trendingArticles.isEmpty) {
      _trendingArticles = _filteredArticles.take(5).toList();
    }
    _latestArticles =
        _filteredArticles.length > 5 ? _filteredArticles.sublist(5) : [];
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

        int guardIndex =
            _guardianArticles.indexWhere((a) => a.url == updated.url);
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
