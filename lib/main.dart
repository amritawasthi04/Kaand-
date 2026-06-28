import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'provider/news_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('news_images');

  // Provider lifted here — survives hot reload without recreating
  runApp(
    ChangeNotifierProvider(
      create: (_) => NewsProvider()..loadHeadlines(),
      child: const NewsApp(),
    ),
  );
}

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Newstler',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primaryAccent,
        onPrimary: AppColors.primaryText,
        secondary: AppColors.secondaryAccent,
        onSecondary: AppColors.primaryText,
        tertiary: AppColors.highlight,
        onTertiary: AppColors.background,
        background: AppColors.background,
        onBackground: AppColors.primaryText,
        surface: AppColors.surface,
        onSurface: AppColors.primaryText,
        surfaceVariant: AppColors.secondarySurface,
        onSurfaceVariant: AppColors.secondaryText,
        outline: AppColors.divider,
        error: AppColors.error,
        onError: AppColors.primaryText,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.primaryText),
        actionsIconTheme: IconThemeData(color: AppColors.secondaryText),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryText,
          letterSpacing: -0.3,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.elevatedCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: AppColors.primaryText, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.secondaryText, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.mutedText, fontSize: 12),
        labelLarge: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: AppColors.secondaryText),
        labelSmall: TextStyle(color: AppColors.mutedText),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.btnPrimaryBackground,
          foregroundColor: AppColors.primaryText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.elevatedCard,
          foregroundColor: AppColors.primaryText,
          side: const BorderSide(color: AppColors.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
