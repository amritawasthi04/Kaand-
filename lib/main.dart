import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KaandApp());
}

class KaandApp extends StatelessWidget {
  const KaandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KAAND',
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
