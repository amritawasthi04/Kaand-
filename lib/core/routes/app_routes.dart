import 'package:flutter/material.dart';
import '../../features/splash/splash_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/onboarding/username_page.dart';
import '../../features/home/main_shell.dart';
import '../../features/article/article_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String username = '/username';
  static const String home = '/home';
  static const String article = '/article';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());
      case username:
        return MaterialPageRoute(builder: (_) => const UsernamePage());
      case home:
        return MaterialPageRoute(builder: (_) => const MainShellPage());
      case article:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => ArticlePage(
            articleId: args['articleId'] ?? '',
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
        );
    }
  }
}
