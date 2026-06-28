import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/article_card.dart';
import '../widgets/shimmer_card.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

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
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              Provider.of<NewsProvider>(context, listen: false).search(val);
            }
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
              child: Text(
                'Error: ${provider.errorMessage}',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          if (provider.isSearchActive && provider.articles.isEmpty) {
            return const Center(
              child: Text(
                'No search results found.',
                style: TextStyle(color: AppColors.mutedText),
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
            padding: const EdgeInsets.all(16),
            itemCount: provider.articles.length,
            itemBuilder: (context, index) {
              final art = provider.articles[index];
              return ArticleCard(
                article: art,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(article: art),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
