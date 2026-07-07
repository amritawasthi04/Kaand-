import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/component_showcase.dart';

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
      home: const ComponentShowcasePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
