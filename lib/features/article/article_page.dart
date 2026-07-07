import 'package:flutter/material.dart';

class ArticlePage extends StatelessWidget {
  final String articleId;

  const ArticlePage({
    super.key,
    required this.articleId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('KAAND Article Screen: $articleId'),
      ),
    );
  }
}
