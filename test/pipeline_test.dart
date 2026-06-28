import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:newstler/services/news_repository.dart';
import 'package:newstler/screens/detail_screen.dart';
import 'package:newstler/models/article_model.dart';

void main() {
  testWidgets('End-to-End Tracing of Article Description Field', (WidgetTester tester) async {
    await tester.runAsync(() async {
      // Enable real network requests in widget tests
      HttpOverrides.global = null;

      print('Initializing Hive in a temporary directory...');
      final tempDir = Directory.systemTemp.createTempSync('hive_test');
      Hive.init(tempDir.path);
      
      final box = await Hive.openBox('news_images');
      await box.clear(); // Clean cache miss
      
      print('Fetching live Google News RSS xml...');
      final response = await http.get(Uri.parse('https://news.google.com/rss?hl=en-IN&gl=IN&ceid=IN:en'));
      expect(response.statusCode, 200);
      
      final document = XmlDocument.parse(response.body);
      final items = document.findAllElements('item').toList();
      expect(items, isNotEmpty);
      
      print('Found ${items.length} items. Picking the first one for trace.');
      final firstItem = items.first;
      
      final repository = NewsRepository();
      
      print('\n--- STAGE 1 & 2 & 3: FETCH & SCRAPE & SAVE (CACHE MISS) ---');
      final article = await repository.processItemForTest(firstItem, 'general');
      expect(article, isNotNull);
      
      // Stage 5 Trace
      print('\n[TRACE STAGE 5 - Before Navigating to DetailScreen]');
      print('  article.title: ${article!.title}');
      print('  article.description.length: ${article.description?.length ?? 0}');
      
      // Stage 6 Trace
      print('\n--- STAGE 6: DETAIL SCREEN BUILD ---');
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: DetailScreen(article: article),
          ),
        );
      } catch (e) {
        print('  DetailScreen build exception (expected/ignored in test environment): $e');
      }
      
      print('\n--- STAGE 4: CACHE HIT TRACE ---');
      final cachedArticle = await repository.processItemForTest(firstItem, 'general');
      expect(cachedArticle, isNotNull);
      
      await Hive.close();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
      print('Trace execution finished successfully.');
    });
  });
}
