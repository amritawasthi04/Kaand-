import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../providers/news_provider.dart';
import 'widgets.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  final List<String> _trendingTopics = [
    '#SensexRecord',
    '#ISRO',
    '#CricketChampionship',
    '#ClimateSummit2026',
    '#StartupsFunding',
    '#BilateralTrade'
  ];

  final List<Map<String, String>> _publishers = [
    {'name': 'BBC', 'logoText': 'BBC', 'colorText': '0xFFE50914'},
    {'name': 'Reuters', 'logoText': 'R', 'colorText': '0xFFFF9900'},
    {'name': 'NDTV', 'logoText': 'NDTV', 'colorText': '0xFF3B5998'},
    {'name': 'The Hindu', 'logoText': 'TH', 'colorText': '0xFF0F172A'},
    {'name': 'Indian Express', 'logoText': 'IE', 'colorText': '0xFF0284C7'},
    {'name': 'Bloomberg', 'logoText': 'BB', 'colorText': '0xFF2563EB'},
    {'name': 'CNN', 'logoText': 'CNN', 'colorText': '0xFFCC0000'},
    {'name': 'The Guardian', 'logoText': 'TG', 'colorText': '0xFF005689'},
    {'name': 'TechCrunch', 'logoText': 'TC', 'colorText': '0xFF00A389'},
    {'name': 'Wired', 'logoText': 'W', 'colorText': '0xFF000000'},
  ];

  final List<Map<String, dynamic>> _discoveryCategories = [
    {'name': 'India', 'icon': Icons.temple_hindu_rounded, 'count': 5},
    {'name': 'World', 'icon': Icons.public_rounded, 'count': 4},
    {'name': 'Technology', 'icon': Icons.memory_rounded, 'count': 8},
    {'name': 'Business', 'icon': Icons.trending_up_rounded, 'count': 6},
    {'name': 'Sports', 'icon': Icons.sports_cricket_rounded, 'count': 5},
    {'name': 'Entertainment', 'icon': Icons.movie_filter_rounded, 'count': 4},
    {'name': 'Science', 'icon': Icons.biotech_rounded, 'count': 3},
    {'name': 'Health', 'icon': Icons.health_and_safety_rounded, 'count': 2},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NewsProvider>();
      provider.loadHeadlines();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = context.watch<NewsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0010),
      appBar: AppBar(
        title: const Text(
          'KAAND DISCOVER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.trending_up_rounded,
              color: AppColors.highlight,
            ),
            onPressed: () => context.push('/trending'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await newsProvider.loadHeadlines();
        },
        color: AppColors.primaryAccent,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DesignTokens.spaceM),

              // 1. Search Bar Trigger
              GestureDetector(
                onTap: () => context.push('/search'),
                child: const AbsorbPointer(
                  child: SearchField(
                    hintText: 'Search articles, topics, publishers...',
                  ),
                ),
              ),

              const SizedBox(height: DesignTokens.spaceM),

              // 2. Breaking live telemetry ticker
              _buildBreakingNewsTicker(context),

              const SizedBox(height: DesignTokens.spaceL),

              // 4. Trending Hashtags explore
              _buildTrendingHashtags(context),

              const SizedBox(height: DesignTokens.spaceL),

              // 5. Editors' Picks Editorial Slider
              _buildEditorsPicks(context, newsProvider),

              const SizedBox(height: DesignTokens.spaceL),

              // 6. Categories Grid
              const SectionHeader(title: 'Browse Categories'),
              const SizedBox(height: DesignTokens.spaceS),
              _buildCategoriesGrid(context),

              const SizedBox(height: DesignTokens.spaceL),

              // 7. Today's Highlight Parallax Card
              _buildTodayHighlight(context, newsProvider),

              const SizedBox(height: DesignTokens.spaceL),

              // 8. Popular Publishers Grid
              _buildPublishersSection(context),

              const SizedBox(height: DesignTokens.spaceL),

              // 9. Continue Reading Card
              _buildContinueReadingSection(context, newsProvider),

              // Spacer buffer for bottom nav
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakingNewsTicker(BuildContext context) {
    return GlassCard(
      showGlow: true,
      glowColor: AppColors.error.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Opacity(
                opacity: _pulseController.value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          const Text(
            'BREAKING LIVE: ',
            style: TextStyle(
              color: Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                'ISRO begins payload testing for Lunar Polar Exploration mission...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingHashtags(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Trending Hashtags'),
        const SizedBox(height: DesignTokens.spaceS),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _trendingTopics.map((tag) {
              return GestureDetector(
                onTap: () => context.push('/topics', extra: tag),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF160824),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryAccent.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tag_rounded, color: AppColors.primaryAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        tag.replaceAll('#', ''),
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEditorsPicks(BuildContext context, NewsProvider provider) {
    final list = provider.trendingArticles;
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(title: 'Editors\' Picks'),
            TextButton(
              onPressed: () => context.push('/trending'),
              child: const Text('View All', style: TextStyle(color: AppColors.highlight, fontSize: 12)),
            ),
          ],
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final article = list[index];
              return GestureDetector(
                onTap: () => context.push('/detail', extra: article),
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 12),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    borderRadius: DesignTokens.radiusL,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusL)),
                          child: CachedNetworkImage(
                            imageUrl: article.urlToImage ?? '',
                            height: 110,
                            fit: BoxFit.cover,
                            placeholder: (c, u) => Container(color: AppColors.surface, height: 110),
                            errorWidget: (c, u, e) => Container(color: AppColors.surface, height: 110),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (article.sectionName ?? 'General').toUpperCase(),
                                style: const TextStyle(color: AppColors.primaryAccent, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                article.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                              ),
                            ],
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

  Widget _buildCategoriesGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemCount: _discoveryCategories.length,
      itemBuilder: (context, index) {
        final cat = _discoveryCategories[index];
        return GestureDetector(
          onTap: () => context.push('/category-detail', extra: cat['name']),
          child: GlassCard(
            padding: const EdgeInsets.all(8),
            borderRadius: DesignTokens.radiusM,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cat['icon'] as IconData,
                  color: AppColors.highlight,
                  size: 20,
                ),
                const SizedBox(height: 6),
                Text(
                  cat['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${cat['count']} stories',
                  style: TextStyle(
                    color: AppColors.secondaryText.withOpacity(0.5),
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayHighlight(BuildContext context, NewsProvider provider) {
    final article = provider.heroArticle;
    if (article == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Today\'s Highlights'),
        const SizedBox(height: DesignTokens.spaceS),
        GestureDetector(
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
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (c, u) => Container(color: AppColors.surface, height: 180),
                        errorWidget: (c, u, e) => Container(color: AppColors.surface, height: 180),
                      ),
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.highlight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'MUST READ',
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
                            style: const TextStyle(color: AppColors.primaryAccent, fontSize: 10, fontWeight: FontWeight.bold),
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
                      const SizedBox(height: 8),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPublishersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(title: 'Popular Publishers'),
            TextButton(
              onPressed: () => context.push('/publishers', extra: ''),
              child: const Text('View All', style: TextStyle(color: AppColors.highlight, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceS),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _publishers.length,
            itemBuilder: (context, index) {
              final pub = _publishers[index];
              final col = Color(int.parse(pub['colorText']!));
              return GestureDetector(
                onTap: () => context.push('/publishers', extra: pub['name']),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: col.withOpacity(0.15),
                          border: Border.all(color: col.withOpacity(0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: col.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            pub['logoText']!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: pub['logoText']!.length > 2 ? 11 : 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pub['name']!,
                        style: const TextStyle(color: AppColors.secondaryText, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContinueReadingSection(BuildContext context, NewsProvider provider) {
    final list = provider.articles;
    if (list.isEmpty) return const SizedBox.shrink();
    final article = list.last; // use last article as last read mock item

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Continue Reading'),
        const SizedBox(height: DesignTokens.spaceS),
        GestureDetector(
          onTap: () => context.push('/detail', extra: article),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  child: CachedNetworkImage(
                    imageUrl: article.urlToImage ?? '',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (c, u) => Container(color: AppColors.surface, width: 60, height: 60),
                    errorWidget: (c, u, e) => Container(color: AppColors.surface, width: 60, height: 60),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PROGRESS: 60% READ',
                        style: TextStyle(color: AppColors.highlight, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${article.author ?? 'Staff'}',
                        style: const TextStyle(color: AppColors.secondaryText, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.play_circle_fill_rounded, color: AppColors.highlight, size: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
