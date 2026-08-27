import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/article.dart';

/// Service for real-time Firestore listeners
class FirestoreRealtimeService {
  static final FirestoreRealtimeService _instance = FirestoreRealtimeService._internal();
  factory FirestoreRealtimeService() => _instance;
  FirestoreRealtimeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  StreamSubscription<QuerySnapshot>? _articlesSubscription;
  StreamSubscription<QuerySnapshot>? _breakingNewsSubscription;
  
  final List<Article> _liveArticles = [];
  final List<Article> _breakingArticles = [];
  
  final ValueNotifier<List<Article>> liveArticlesNotifier = ValueNotifier([]);
  final ValueNotifier<List<Article>> breakingArticlesNotifier = ValueNotifier([]);
  
  bool _isListening = false;

  bool get isListening => _isListening;

  /// Start listening to all articles in real-time
  void startListening({String? category, int limit = 50}) {
    if (_isListening) return;
    
    _isListening = true;
    
    Query query = _firestore
        .collection('articles')
        .orderBy('ingestedAt', descending: true)
        .limit(limit);
    
    if (category != null && category != 'general') {
      query = query.where('category', isEqualTo: category);
    }
    
    _articlesSubscription = query.snapshots().listen(
      (snapshot) {
        _processSnapshot(snapshot);
      },
      onError: (error) {
        print('Firestore listener error: $error');
      },
    );
    
    // Also listen for breaking news (articles with breaking tag or very recent)
    _startBreakingNewsListener();
  }

  /// Start listening for breaking news specifically
  void _startBreakingNewsListener() {
    Query query = _firestore
        .collection('articles')
        .where('isBreaking', isEqualTo: true)
        .orderBy('ingestedAt', descending: true)
        .limit(10);
    
    _breakingNewsSubscription = query.snapshots().listen(
      (snapshot) {
        _processBreakingSnapshot(snapshot);
      },
      onError: (error) {
        print('Breaking news listener error: $error');
      },
    );
  }

  void _processSnapshot(QuerySnapshot snapshot) {
    final articles = <Article>[];
    
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      articles.add(Article.fromJson(data));
    }
    
    _liveArticles
      ..clear()
      ..addAll(articles);
    
    liveArticlesNotifier.value = List.from(_liveArticles);
  }

  void _processBreakingSnapshot(QuerySnapshot snapshot) {
    final articles = <Article>[];
    final now = DateTime.now();
    
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      final article = Article.fromJson(data);
      
      // Only consider articles from last 30 minutes as breaking
      if (article.publishedAt != null) {
        try {
          final published = DateTime.parse(article.publishedAt!);
          if (now.difference(published).inMinutes <= 30) {
            articles.add(article);
          }
        } catch (_) {
          articles.add(article);
        }
      } else {
        articles.add(article);
      }
    }
    
    _breakingArticles
      ..clear()
      ..addAll(articles);
    
    breakingArticlesNotifier.value = List.from(_breakingArticles);
  }

  /// Get current live articles
  List<Article> get liveArticles => List.from(_liveArticles);
  
  /// Get current breaking articles
  List<Article> get breakingArticles => List.from(_breakingArticles);

  /// Stop all listeners
  void stopListening() {
    _articlesSubscription?.cancel();
    _breakingNewsSubscription?.cancel();
    _articlesSubscription = null;
    _breakingNewsSubscription = null;
    _isListening = false;
    
    _liveArticles.clear();
    _breakingArticles.clear();
    liveArticlesNotifier.value = [];
    breakingArticlesNotifier.value = [];
  }

  /// Listen to a specific category
  Stream<List<Article>> watchCategory(String category, {int limit = 20}) {
    Query query = _firestore
        .collection('articles')
        .where('category', isEqualTo: category)
        .orderBy('ingestedAt', descending: true)
        .limit(limit);
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Article.fromJson(data);
      }).toList();
    });
  }

  /// Listen to search results
  Stream<List<Article>> watchSearch(String query, {int limit = 20}) {
    // Firestore doesn't support full-text search natively
    // This would need Algolia or similar, or we filter client-side
    return _firestore
        .collection('articles')
        .orderBy('ingestedAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) {
          final allArticles = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Article.fromJson(data);
          }).toList();
          
          final lowerQuery = query.toLowerCase();
          return allArticles.where((a) {
            final titleMatch = a.title.toLowerCase().contains(lowerQuery);
            final descMatch = a.description?.toLowerCase().contains(lowerQuery) ?? false;
            final srcMatch = a.sourceName?.toLowerCase().contains(lowerQuery) ?? false;
            return titleMatch || descMatch || srcMatch;
          }).take(limit).toList();
        });
  }

  void dispose() {
    stopListening();
    liveArticlesNotifier.dispose();
    breakingArticlesNotifier.dispose();
  }
}

/// Helper class for managing realtime listeners in widgets
class RealtimeListenerHelper {
  final FirestoreRealtimeService _realtimeService = FirestoreRealtimeService();
  VoidCallback? _breakingListener;
  
  void init({
    String? category,
    Function(List<Article>)? onBreakingNews,
  }) {
    _realtimeService.startListening(category: category);
    
    _breakingListener = () {
      if (onBreakingNews != null && _realtimeService.breakingArticles.isNotEmpty) {
        onBreakingNews(_realtimeService.breakingArticles);
      }
    };
    
    _realtimeService.breakingArticlesNotifier.addListener(_breakingListener!);
  }
  
  void dispose() {
    if (_breakingListener != null) {
      _realtimeService.breakingArticlesNotifier.removeListener(_breakingListener!);
    }
    _realtimeService.stopListening();
  }
}