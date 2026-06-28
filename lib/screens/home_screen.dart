import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/article_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/shimmer_card.dart';
import 'blogs_screen.dart';
import 'detail_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<NewsProvider>(context, listen: false).loadHeadlines();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final newsProvider = Provider.of<NewsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_getGreeting()}, ${userProvider.name}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryText,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.primaryText),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primaryAccent,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userProvider.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const Text(
                      'Solo News Reader',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.home_outlined, color: AppColors.primaryText),
                title: const Text('Home Feed', style: TextStyle(color: AppColors.primaryText)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.book_outlined, color: AppColors.primaryText),
                title: const Text('Guardian Editorial', style: TextStyle(color: AppColors.primaryText)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BlogsScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: AppColors.primaryText),
                title: const Text('Settings', style: TextStyle(color: AppColors.primaryText)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Horizontal Category Chip Scroll
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: NewsProvider.categories.length,
              itemBuilder: (context, index) {
                final cat = NewsProvider.categories[index];
                final isSelected = newsProvider.selectedCategory == cat;
                return CategoryChip(
                  category: cat,
                  isSelected: isSelected,
                  onTap: () => newsProvider.setCategory(cat),
                );
              },
            ),
          ),
          
          // Articles Listing Feed
          Expanded(
            child: Consumer<NewsProvider>(
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading articles:\n${provider.errorMessage}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.secondaryText),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadHeadlines(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final articles = provider.articles;
                if (articles.isEmpty) {
                  return const Center(
                    child: Text(
                      'No articles found.',
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadHeadlines(),
                  color: AppColors.primaryAccent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final art = articles[index];
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
