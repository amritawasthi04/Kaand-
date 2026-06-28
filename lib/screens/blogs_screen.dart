import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/article_card.dart';
import '../widgets/shimmer_card.dart';
import 'detail_screen.dart';

class BlogsScreen extends StatefulWidget {
  const BlogsScreen({super.key});

  @override
  State<BlogsScreen> createState() => _BlogsScreenState();
}

class _BlogsScreenState extends State<BlogsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<NewsProvider>(context, listen: false).loadBlogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Editorial'),
      ),
      body: Consumer<NewsProvider>(
        builder: (context, provider, child) {
          if (provider.blogsStatus == NewsStatus.loading) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => const ShimmerCard(),
            );
          }

          if (provider.blogsStatus == NewsStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load blogs',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => provider.loadBlogs(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final blogs = provider.blogs;
          if (blogs.isEmpty) {
            return const Center(
              child: Text(
                'No editorial posts available.',
                style: TextStyle(color: AppColors.mutedText),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadBlogs(),
            color: AppColors.primaryAccent,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: blogs.length,
              itemBuilder: (context, index) {
                final blog = blogs[index];
                return ArticleCard(
                  article: blog,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(article: blog),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
