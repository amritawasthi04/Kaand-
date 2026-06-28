import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:newstler/main.dart';
import 'package:newstler/provider/news_provider.dart';

void main() {
  testWidgets('Newstler home screen smoke test', (WidgetTester tester) async {
    // Build our app with the provider and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => NewsProvider(),
        child: const NewsApp(),
      ),
    );

    // Verify that the header greeting is present on the screen.
    expect(find.textContaining('Good Evening'), findsOneWidget);

    // Verify that the tagline "Stay " is present.
    expect(find.textContaining('Stay'), findsAtLeast(1));
  });
}
