import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:newstler/main.dart';
import 'package:newstler/providers/news_provider.dart';
import 'package:newstler/providers/user_provider.dart';

void main() {
  testWidgets('Newstler home screen smoke test', (WidgetTester tester) async {
    // Build our app with the providers and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => NewsProvider()),
        ],
        child: const NewsApp(),
      ),
    );

    // Verify that the app builds.
    expect(find.byType(NewsApp), findsOneWidget);
  });
}
