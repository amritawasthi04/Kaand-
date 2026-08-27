import 'package:flutter_test/flutter_test.dart';
import 'package:newstler/main.dart';
import 'package:newstler/providers/news_provider.dart';
import 'package:newstler/providers/user_provider.dart';
import 'package:newstler/screens/kaand_splash_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Newstler app boots into ORBIT splash', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => NewsProvider()),
        ],
        child: const NewsApp(),
      ),
    );

    expect(find.byType(NewsApp), findsOneWidget);
    expect(find.byType(KaandSplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2500));

    expect(find.byType(NewsApp), findsOneWidget);
  });
}
