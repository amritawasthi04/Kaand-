import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/hash.dart';
import '../models/article.dart';

class FirestoreCache {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference get _articlesCollection => _firestore.collection('scraped_articles');

  Future<Article?> getArticle(String url) async {
    try {
      final docId = md5Hash(url);
      final doc = await _articlesCollection.doc(docId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return Article.fromMap(data);
      }
    } catch (e) {
      print('[FirestoreCache] Error getting cached article: $e');
    }
    return null;
  }

  Future<void> saveArticle(String url, Article article) async {
    try {
      final docId = md5Hash(url);
      await _articlesCollection.doc(docId).set(article.toMap());
    } catch (e) {
      print('[FirestoreCache] Error saving cached article: $e');
    }
  }
}
