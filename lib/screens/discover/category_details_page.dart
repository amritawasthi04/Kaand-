import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../providers/news_provider.dart';
import '../../models/article.dart';
import 'widgets.dart';

class CategoryDetailsPage extends StatefulWidget {
  final String categoryName;

  const CategoryDetailsPage({
    super.key,
    required this.categoryName,
  });

  @override
  State<CategoryDetailsPage> createState() => _CategoryDetailsPageState();
}

class _CategoryDetailsPageState extends State<CategoryDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().setCategory(widget.categoryName.toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final articles = provider.articles;

    final featuredArticle = articles.isNotEmpty ? articles.first : null;
    final trendingArticles = articles.length > 1 ? articles.skip(1).take(3).toList() : <Article>[];
    final latestArticles = articles.length > 1 ? articles.skip(1).toList() : <Article>[];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0010),
      appBar: AppBar(
        title: Text(
          widget.categoryName.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: provider.status == NewsStatus.loading && articles.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
          : RefreshIndicator(
              onRefresh: () => provider.loadHeadlines(),
              color: AppColors.primaryAccent,
              backgroundColor: AppColors.surface,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: DesignTokens.spaceM),

                    // 1. Editorial Category Banner
                    _buildCategoryBanner(widget.categoryName, articles.length),
                    const SizedBox(height: DesignTokens.spaceL),

                    // 2. Featured Story
                    if (featuredArticle != null) ...[
                      const SectionHeader(title: 'Featured Story'),
                      const SizedBox(height: DesignTokens.spaceS),
                      _buildFeaturedCard(context, featuredArticle),
                      const SizedBox(height: DesignTokens.spaceL),
                    ],

                    // 3. Trending Stories
                    if (trendingArticles.isNotEmpty) ...[
                      _buildTrendingStories(context, trendingArticles),
                      const SizedBox(height: DesignTokens.spaceL),
                    ],

                    // 4. Latest Stories
                    const SectionHeader(title: 'Latest Stories'),
                    const SizedBox(height: DesignTokens.spaceS),
                    if (latestArticles.isEmpty)
                      const EmptyState(
                        title: 'No stories available',
                        description: 'We couldn\'t find any articles under this category right now.',
                        icon: Icons.article_outlined,
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: latestArticles.length,
                        itemBuilder: (context, index) {
                          final article = latestArticles[index];
                          return GestureDetector(
                            onTap: () => context.push('/detail', extra: article),
                            child: GlassCard(
                              margin: const EdgeInsets.only(bottom: DesignTokens.spaceM),
                              padding: const EdgeInsets.all(DesignTokens.spaceS),
                              borderRadius: DesignTokens.radiusM,
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                                    child: CachedNetworkImage(
                                      imageUrl: article.urlToImage ?? '',
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      placeholder: (c, u) => Container(color: AppColors.surface, width: 90, height: 90),
                                      errorWidget: (c, u, e) => Container(color: AppColors.surface, width: 90, height: 90),
                                    ),
                                  ),
                                  const SizedBox(width: DesignTokens.spaceM),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              (article.sourceName ?? 'News').toUpperCase(),
                                              style: const TextStyle(
                                                color: AppColors.highlight,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              article.relativeTime,
                                              style: const TextStyle(color: AppColors.secondaryText, fontSize: 9),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          article.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.primaryText,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'By ${article.author ?? 'Staff'} • ${article.readTime ?? 5} min read',
                                          style: const TextStyle(color: AppColors.secondaryText, fontSize: 9),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // Spacing buffer for bottom nav
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategoryBanner(String name, int count) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      showGlow: true,
      glowColor: AppColors.glassGlowViolet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'BROWSE TELEMETRY • $count STORIES',
            style: const TextStyle(
              color: AppColors.highlight,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingStories(BuildContext context, List<Article> trending) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Trending Stories'),
        const SizedBox(height: DesignTokens.spaceS),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: trending.length,
            itemBuilder: (context, index) {
              final article = trending[index];
              return GestureDetector(
                onTap: () => context.push('/detail', extra: article),
                child: Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 12),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    borderRadius: DesignTokens.radiusM,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusM)),
                          child: CachedNetworkImage(
                            imageUrl: article.urlToImage ?? '',
                            height: 90,
                            fit: BoxFit.cover,
                            placeholder: (c, u) => Container(color: AppColors.surface, height: 90),
                            errorWidget: (c, u, e) => Container(color: AppColors.surface, height: 90),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            article.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(BuildContext context, Article article) {
    return GestureDetector(
      onTap: () => context.push('/detail', extra: article),
      child: GlassCard(
        padding: EdgeInsets.zero,
        showGlow: true,
        glowColor: AppColors.glassGlowViolet,
        borderRadius: DesignTokens.radiusL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusL)),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  CachedNetworkImage(
                    imageUrl: article.urlToImage ?? '',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (c, u) => Container(color: AppColors.surface, height: 200),
                    errorWidget: (c, u, e) => Container(color: AppColors.surface, height: 200),
                  ),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'FEATURED STORY',
                        style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (article.sectionName ?? 'General').toUpperCase(),
                        style: const TextStyle(color: AppColors.highlight, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${article.readTime ?? 5} min read',
                        style: const TextStyle(color: AppColors.secondaryText, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.highlight,
                        child: Text(
                          (article.author ?? 'Staff').substring(0, 1),
                          style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'By ${article.author ?? 'Staff'} • ${article.sourceName ?? 'News'}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
