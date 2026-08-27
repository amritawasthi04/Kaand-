import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newstler/models/article.dart';
import 'package:newstler/screens/home_screen.dart';

void main() {
  final sampleArticle = Article(
    title: 'A fairly long headline needed to exercise two-line clamping on cards',
    url: 'https://example.com/a',
    sourceName: 'Outlet',
    sectionName: 'World',
    publishedAt: '2026-08-27T10:00:00Z',
  );

  const matrix = <(Size, double)>[
    (Size(320, 568), 0.85),
    (Size(320, 568), 1.25),
    (Size(360, 640), 1.0),
    (Size(390, 844), 1.0),
    (Size(600, 1024), 1.25),
  ];

  Future<void> pumpAt(
    WidgetTester tester,
    Widget child,
    Size size,
    double textScale,
  ) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = size * 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
    await tester.pump();
    final exception = tester.takeException();
    expect(exception, isNull,
        reason: 'overflow at size=$size scale=$textScale');
  }

  testWidgets('CategorySquareChip never overflows', (tester) async {
    for (final (size, scale) in matrix) {
      await pumpAt(
        tester,
        CategorySquareChip(
          label: 'Business',
          emoji: '📈',
          isSelected: false,
          onTap: () {},
        ),
        size,
        scale,
      );
    }
  });

  testWidgets('TrendingCard never overflows', (tester) async {
    for (final (size, scale) in matrix) {
      await pumpAt(
        tester,
        TrendingCard(
          article: sampleArticle,
          onTap: () {},
          isBookmarked: true,
          onBookmarkToggle: () {},
        ),
        size,
        scale,
      );
    }
  });

  testWidgets('HeadlineTile never overflows', (tester) async {
    for (final (size, scale) in matrix) {
      await pumpAt(
        tester,
        HeadlineTile(
          article: sampleArticle,
          onTap: () {},
          isBookmarked: false,
          onBookmarkToggle: () {},
        ),
        size,
        scale,
      );
    }
  });
}
