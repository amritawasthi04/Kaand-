import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import '../providers/user_provider.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/kaand_splash_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/search_screen.dart';
import '../screens/blogs_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/user_blogs_screen.dart';
import '../screens/scores_tab.dart';
import '../models/article.dart';
import '../models/user_blog.dart';
import '../screens/discover/discover_page.dart';
import '../screens/discover/category_details_page.dart';
import '../screens/discover/publishers_page.dart';
import '../screens/discover/topics_page.dart';
import '../screens/discover/trending_page.dart';

// Page builder that returns a FadeThrough Transition (respects accessibility)
Page<T> buildFadeThroughPage<T>({
  required Widget child,
  required LocalKey key,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.of(context).disableAnimations) return child;
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );
      final secondaryCurvedAnimation = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInOutCubic,
      );
      return FadeThroughTransition(
        animation: curvedAnimation,
        secondaryAnimation: secondaryCurvedAnimation,
        fillColor: Colors.transparent,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 350),
  );
}

// Page builder that returns a SharedAxis Transition (default to horizontal for tab level nav)
Page<T> buildSharedAxisPage<T>({
  required Widget child,
  required LocalKey key,
  SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.of(context).disableAnimations) return child;
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );
      final secondaryCurvedAnimation = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInOutCubic,
      );
      return SharedAxisTransition(
        animation: curvedAnimation,
        secondaryAnimation: secondaryCurvedAnimation,
        transitionType: type,
        fillColor: Colors.transparent,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 350),
  );
}

// Page builder that returns a SharedAxis Vertical Transition (mimicking container transform)
Page<T> buildDetailTransitionPage<T>({
  required Widget child,
  required LocalKey key,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.of(context).disableAnimations) return child;
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );
      final secondaryCurvedAnimation = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInOutCubic,
      );
      return SharedAxisTransition(
        animation: curvedAnimation,
        secondaryAnimation: secondaryCurvedAnimation,
        transitionType: SharedAxisTransitionType.vertical,
        fillColor: Colors.transparent,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 380),
  );
}

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter createRouter(UserProvider userProvider) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: userProvider,
    redirect: (context, state) {
      final isOnboarded = userProvider.isOnboarded;
      final goingToOnboarding = state.matchedLocation == '/onboarding';
      final goingToSplash = state.matchedLocation == '/splash';

      if (goingToSplash) return null;

      if (!isOnboarded && !goingToOnboarding) {
        return '/onboarding';
      }
      if (isOnboarded && goingToOnboarding) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeThroughPage<void>(
          key: state.pageKey,
          child: const KaandSplashScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeThroughPage<void>(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => buildSharedAxisPage<void>(
                  key: state.pageKey,
                  child: const HomeTab(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/categories',
                pageBuilder: (context, state) => buildSharedAxisPage<void>(
                  key: state.pageKey,
                  child: const DiscoverPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scores',
                pageBuilder: (context, state) => buildSharedAxisPage<void>(
                  key: state.pageKey,
                  child: const ScoresTab(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookmarks',
                pageBuilder: (context, state) => buildSharedAxisPage<void>(
                  key: state.pageKey,
                  child: const BookmarksTab(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => buildSharedAxisPage<void>(
                  key: state.pageKey,
                  child: const ProfileTab(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Full screen / pushed routes
      GoRoute(
        path: '/detail',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final article = state.extra as Article;
          return buildDetailTransitionPage<void>(
            key: state.pageKey,
            child: DetailScreen(article: article),
          );
        },
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeThroughPage<void>(
          key: state.pageKey,
          child: const SearchScreen(),
        ),
      ),
      GoRoute(
        path: '/blogs',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeThroughPage<void>(
          key: state.pageKey,
          child: const BlogsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeThroughPage<void>(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/my-blogs',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeThroughPage<void>(
          key: state.pageKey,
          child: const UserBlogsScreen(),
        ),
      ),
      GoRoute(
        path: '/write-blog',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeThroughPage<void>(
          key: state.pageKey,
          child: UserBlogEditorScreen(blog: state.extra as UserBlog?),
        ),
      ),
      GoRoute(
        path: '/trending',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => buildFadeThroughPage<void>(
          key: state.pageKey,
          child: const TrendingPage(),
        ),
      ),
      GoRoute(
        path: '/publishers',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final publisherName = state.extra as String? ?? '';
          return buildFadeThroughPage<void>(
            key: state.pageKey,
            child: PublishersPage(publisherName: publisherName),
          );
        },
      ),
      GoRoute(
        path: '/topics',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final topicTag = state.extra as String? ?? '';
          return buildFadeThroughPage<void>(
            key: state.pageKey,
            child: TopicsPage(topicTag: topicTag),
          );
        },
      ),
      GoRoute(
        path: '/category-detail',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final categoryName = state.extra as String? ?? '';
          return buildFadeThroughPage<void>(
            key: state.pageKey,
            child: CategoryDetailsPage(categoryName: categoryName),
          );
        },
      ),
    ],
  );
}
