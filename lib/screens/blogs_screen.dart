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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent * 0.8) {
        Provider.of<NewsProvider>(context, listen: false).loadNextBlogsPage();
      }
    });

    Future.microtask(() {
      if (!mounted) return;
      Provider.of<NewsProvider>(context, listen: false).loadBlogs();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: blogs.length + 1,
              itemBuilder: (context, index) {
                if (index == blogs.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        if (provider.blogsLoadingMore)
                          const Center(
                            child: CircularProgressIndicator(color: AppColors.onboardingSecondary),
                          )
                        else if (!provider.blogsHasMore)
                          Center(
                            child: Text(
                              "You've reached the end",
                              style: TextStyle(color: AppColors.mutedText.withOpacity(0.6), fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  );
                }
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
