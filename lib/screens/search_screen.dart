import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/news_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/article_card.dart';
import '../widgets/shimmer_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent * 0.8) {
        Provider.of<NewsProvider>(context, listen: false).loadNextSearchPage();
      }
    });

    Future.microtask(() {
      if (!mounted) return;
      Provider.of<NewsProvider>(context, listen: false).clearSearch();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search headlines...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.mutedText),
          ),
          style: const TextStyle(color: AppColors.primaryText, fontSize: 18),
          onChanged: (val) {
            Provider.of<NewsProvider>(context, listen: false).search(val);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
              Provider.of<NewsProvider>(context, listen: false).clearSearch();
            },
          )
        ],
      ),
      body: Consumer<NewsProvider>(
        builder: (context, provider, child) {
          if (provider.status == NewsStatus.loading) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => const ShimmerCard(),
            );
          }

          if (provider.status == NewsStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 54, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage.isEmpty
                          ? 'Search failed to complete.'
                          : provider.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.primaryText, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        provider.retrySearch();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry Search'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.isSearchActive && provider.articles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off_rounded,
                        size: 54, color: AppColors.mutedText),
                    const SizedBox(height: 16),
                    const Text(
                      'No search results found.',
                      style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try searching for different keywords or check your spelling.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: AppColors.mutedText, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!provider.isSearchActive) {
            return const Center(
              child: Text(
                'Type a query above to search news.',
                style: TextStyle(color: AppColors.mutedText),
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: provider.articles.length + 1,
            itemBuilder: (context, index) {
              if (index == provider.articles.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      if (provider.searchLoadingMore)
                        const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.onboardingSecondary),
                        )
                      else if (!provider.searchHasMore &&
                          provider.articles.isNotEmpty)
                        Center(
                          child: Text(
                            "You've reached the end",
                            style: TextStyle(
                                color: AppColors.mutedText.withOpacity(0.6),
                                fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              }
              final art = provider.articles[index];
              return ArticleCard(
                article: art,
                onTap: () {
                  context.push('/detail', extra: art);
                },
              );
            },
          );
        },
      ),
    );
  }
}
