import 'package:flutter_test/flutter_test.dart';
import 'package:newstler/models/article.dart';

void main() {
  group('Core Unit Tests', () {
    test('Article toMap and fromMap serialization', () {
      final article = Article(
        title: 'Test Title',
        description: 'Test Description',
        url: 'https://example.com/article',
        publishedAt: '2026-06-28',
        sourceName: 'Example News',
      );

      final map = article.toMap();
      expect(map['title'], 'Test Title');
      expect(map['description'], 'Test Description');
      expect(map['url'], 'https://example.com/article');

      final fromMap = Article.fromMap(map);
      expect(fromMap.title, 'Test Title');
      expect(fromMap.description, 'Test Description');
      expect(fromMap.url, 'https://example.com/article');
    });
  });
}
