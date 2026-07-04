import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/news_provider.dart';
import '../providers/user_provider.dart';
import '../models/article.dart';
import '../theme/app_colors.dart';
import '../services/hive_cache.dart';
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  late final AnimationController _rotationController;
  final TextEditingController _profileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Rotation for background glowing globe constellation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    Future.microtask(() {
      Provider.of<NewsProvider>(context, listen: false).loadHeadlines();
    });

    final name = Provider.of<UserProvider>(context, listen: false).name;
    _profileNameController.text = name;
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _profileNameController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _onCategoryChipSelected(String? category, String? query) {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    if (query != null) {
      newsProvider.search(query);
    } else if (category != null) {
      newsProvider.setCategory(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final newsProvider = Provider.of<NewsProvider>(context);

    return Scaffold(
      drawer: _buildDrawer(context, userProvider),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.onboardingBg,
        ),
        child: Stack(
          children: [
            // 1. Dotted Globe Constellation Background (Tab 0 only)
            if (_currentTab == 0)
              Positioned(
                top: 0,
                right: 0,
                width: MediaQuery.of(context).size.width,
                height: 350,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: HeaderGlobePainter(_rotationController.value),
                        size: const Size(200, 350),
                      );
                    },
                  ),
                ),
              ),

            // 2. Tab Contents
            Positioned.fill(
              child: IndexedStack(
                index: _currentTab,
                children: [
                  _buildHomeTab(context, newsProvider, userProvider),
                  _buildCategoriesTab(context, newsProvider),
                  _buildAITab(context, newsProvider),
                  _buildBookmarksTab(context, userProvider),
                  _buildProfileTab(context, userProvider),
                ],
              ),
            ),

            // 3. Floating Bottom Navigation Bar Overlay
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _buildFloatingBottomNavBar(context),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 0: HOME TAB ---
  Widget _buildHomeTab(BuildContext context, NewsProvider newsProvider, UserProvider userProvider) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => newsProvider.loadHeadlines(),
        color: AppColors.onboardingAccent,
        backgroundColor: AppColors.onboardingSurface,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Custom Header App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.search, color: Colors.white, size: 24),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                                );
                              },
                            ),
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                                  onPressed: () {},
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.onboardingSecondary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_getGreeting()},',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onboardingTextSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userProvider.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '👋',
                          style: TextStyle(fontSize: 26),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Here's what's happening in the world today.",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onboardingTextSecondary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Loading feeds
            if (newsProvider.status == NewsStatus.loading && newsProvider.articles.isEmpty)
              SliverFillRemaining(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 4,
                  itemBuilder: (context, index) => const ShimmerCard(),
                ),
              )
            else if (newsProvider.status == NewsStatus.error && newsProvider.articles.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load news.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.secondaryText),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => newsProvider.loadHeadlines(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (newsProvider.articles.isEmpty && newsProvider.status != NewsStatus.loading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No News Available',
                        style: TextStyle(color: AppColors.mutedText, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pull to Refresh',
                        style: TextStyle(color: AppColors.mutedText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // 3. Breaking News Carousel (Top article)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: HeroNewsCarousel(
                    articles: newsProvider.guardianArticles,
                    onTap: (art) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DetailScreen(article: art)),
                      );
                    },
                  ),
                ),
              ),

              // 4. Category Square Chips row
              SliverToBoxAdapter(
                child: CategoriesRow(
                  activeCategory: newsProvider.selectedCategory,
                  onCategorySelected: _onCategoryChipSelected,
                ),
              ),

              // 5. AI Insight Banner
              SliverToBoxAdapter(
                child: AIInsightBanner(
                  onViewInsight: () {
                    setState(() {
                      _currentTab = 2; // Jump to AI Insight Tab
                    });
                  },
                ),
              ),

              // 6. Trending Now Section
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.trending_up, color: AppColors.onboardingAccent, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Trending Now',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'See All',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onboardingSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 195,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: newsProvider.trendingArticles.length,
                        itemBuilder: (context, index) {
                          final art = newsProvider.trendingArticles[index];
                          return TrendingCard(
                            article: art,
                            onTap: () {
                              Navigator.push(
                                context,
                                  MaterialPageRoute(builder: (_) => DetailScreen(article: art)),
                              );
                            },
                            isBookmarked: userProvider.isBookmarked(art),
                            onBookmarkToggle: () => userProvider.toggleBookmark(art),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 7. Latest Headlines Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.onboardingSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Latest Headlines',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune_rounded, color: AppColors.onboardingTextSecondary, size: 18),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),

              // Vertical items feed
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final art = newsProvider.latestArticles[index];
                      return HeadlineTile(
                        article: art,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DetailScreen(article: art)),
                          );
                        },
                        isBookmarked: userProvider.isBookmarked(art),
                        onBookmarkToggle: () => userProvider.toggleBookmark(art),
                      );
                    },
                    childCount: newsProvider.latestArticles.length,
                  ),
                ),
              ),

              // Bottom Spacer to prevent floating bottom nav overlap
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- TAB 1: CATEGORIES GRID TAB ---
  Widget _buildCategoriesTab(BuildContext context, NewsProvider newsProvider) {
    final categories = CategoriesRow.items;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Explore Categories',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return GestureDetector(
                  onTap: () {
                    _onCategoryChipSelected(cat.category, cat.query);
                    setState(() {
                      _currentTab = 0; // Return to feed
                    });
                  },
                  child: GlassCard(
                    borderRadius: 20,
                    bgColor: AppColors.onboardingSurface.withOpacity(0.4),
                    borderColor: Colors.white.withOpacity(0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (cat.icon != null)
                            Icon(cat.icon, size: 36, color: AppColors.onboardingAccent)
                          else
                            Text(cat.emoji, style: const TextStyle(fontSize: 36)),
                          const SizedBox(height: 12),
                          Text(
                            cat.label,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Click to discover',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.onboardingTextSecondary,
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
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // --- TAB 2: AI SUMMARY TAB ---
  Widget _buildAITab(BuildContext context, NewsProvider newsProvider) {
    // Collect some sample headings to parse into AI Bullet briefs
    final titles = newsProvider.articles.take(5).map((e) => e.title).toList();
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'AI Daily Briefs',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.auto_awesome_rounded, color: AppColors.onboardingAccent, size: 24),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Instantly synthesized reports summarizing raw global feeds.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onboardingTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Insight card 1: Markets
                    _buildAIReportCard(
                      'Markets & Economy',
                      'High surge observed in global indices following major announcements.',
                      '• Tech stocks are driving major indexes upward.\n• Regulatory updates in Asian markets suggest stability.\n• Yield curve indices indicate mild economic correction.',
                      Icons.trending_up_rounded,
                      AppColors.onboardingSecondary,
                    ),
                    const SizedBox(height: 16),
                    // Insight card 2: AI Breakthroughs
                    _buildAIReportCard(
                      'AI Breakthroughs',
                      'New foundation models and developer tools accelerate workspace automation.',
                      '• Large-scale model launches report significant benchmarks in logic reasoning.\n• Major investments set base infrastructure requirements into next gear.\n• Open-source AI projects gain traction in parsing complex files.',
                      Icons.auto_awesome_rounded,
                      AppColors.onboardingAccent,
                    ),
                    const SizedBox(height: 16),
                    // Insight card 3: Climate change
                    _buildAIReportCard(
                      'Climate & Science',
                      'Urgent warnings and technology innovations highlight recent reports.',
                      '• Research alerts detail iceberg melts exceeding decade expectations.\n• New solar storage arrays double retrieval capabilities.\n• Regional environmental protocols enter trial phase.',
                      Icons.biotech_outlined,
                      Colors.greenAccent,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIReportCard(String topic, String overview, String bulletPoints, IconData icon, Color highlightColor) {
    return GlassCard(
      borderRadius: 24,
      bgColor: AppColors.onboardingSurface.withOpacity(0.4),
      borderColor: highlightColor.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: highlightColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: highlightColor),
                ),
                const SizedBox(width: 12),
                Text(
                  topic,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              overview,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              bulletPoints,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.onboardingTextSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 3: BOOKMARKS TAB ---
  Widget _buildBookmarksTab(BuildContext context, UserProvider userProvider) {
    final bookmarks = userProvider.bookmarks;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Bookmarks',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: bookmarks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bookmark_border_rounded, size: 48, color: Colors.white24),
                        const SizedBox(height: 12),
                        Text(
                          'No bookmarked articles yet.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.onboardingTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final art = bookmarks[index];
                      return HeadlineTile(
                        article: art,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DetailScreen(article: art)),
                          );
                        },
                        isBookmarked: true,
                        onBookmarkToggle: () => userProvider.toggleBookmark(art),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // --- TAB 4: PROFILE / SETTINGS TAB ---
  Widget _buildProfileTab(BuildContext context, UserProvider userProvider) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Settings',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // Profile Card Header
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.onboardingPrimary, AppColors.onboardingSecondary],
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.onboardingSurface,
                      child: Icon(Icons.person_rounded, size: 48, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    userProvider.name,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Solo News Reader',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onboardingTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Name editing panel
            Text(
              'Personal Details',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.onboardingAccent,
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              borderRadius: 20,
              bgColor: AppColors.onboardingSurface.withOpacity(0.4),
              borderColor: Colors.white.withOpacity(0.08),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _profileNameController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        labelStyle: GoogleFonts.inter(color: AppColors.onboardingTextSecondary),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.onboardingAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_profileNameController.text.trim().isNotEmpty) {
                            await userProvider.saveName(_profileNameController.text);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Name updated successfully!')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.onboardingPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save Changes',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // System controls
            Text(
              'System Cache',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.onboardingAccent,
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              borderRadius: 20,
              bgColor: AppColors.onboardingSurface.withOpacity(0.4),
              borderColor: Colors.white.withOpacity(0.08),
              child: ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                title: Text(
                  'Clear Offline Cache',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Delete local article cache database',
                  style: GoogleFonts.inter(color: AppColors.onboardingTextSecondary, fontSize: 11),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white30),
                onTap: () async {
                  final hive = HiveCache();
                  await hive.clearAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Offline database cleared!')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // --- FLOATING BOTTOM NAVIGATION BAR ---
  Widget _buildFloatingBottomNavBar(BuildContext context) {
    return GlassCard(
      borderRadius: 30,
      bgColor: AppColors.onboardingSurface.withOpacity(0.75),
      borderColor: Colors.white.withOpacity(0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Home'),
            _buildNavItem(1, Icons.grid_view_rounded, 'Categories'),
            _buildSpecialFABItem(2),
            _buildNavItem(3, Icons.bookmark_rounded, 'Bookmarks'),
            _buildNavItem(4, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.onboardingAccent : Colors.white60,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppColors.onboardingAccent : Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialFABItem(int index) {
    final isActive = _currentTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = index;
        });
      },
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.onboardingPrimary, AppColors.onboardingSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.onboardingPrimary.withOpacity(0.35),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          Icons.auto_awesome_rounded,
          color: isActive ? Colors.white : Colors.white.withOpacity(0.85),
          size: 20,
        ),
      ),
    );
  }

  // --- DRAWER SIDE BAR ---
  Widget _buildDrawer(BuildContext context, UserProvider userProvider) {
    return Drawer(
      backgroundColor: AppColors.onboardingSurface,
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
                    backgroundColor: AppColors.onboardingPrimary,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userProvider.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Solo News Reader',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.onboardingTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.home_outlined, color: Colors.white),
              title: const Text('Home Feed', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentTab = 0;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_outlined, color: Colors.white),
              title: const Text('Guardian Editorial', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlogsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Colors.white),
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentTab = 4;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET HELPER CARDS ---

class CategorySquareChip extends StatelessWidget {
  final String label;
  final String emoji;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const CategorySquareChip({
    super.key,
    required this.label,
    required this.emoji,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 12),
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.onboardingAccent.withOpacity(0.12)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.onboardingAccent.withOpacity(0.4)
                : Colors.white.withOpacity(0.06),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.onboardingAccent.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.onboardingAccent : AppColors.onboardingTextSecondary,
              )
            else
              Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.onboardingTextPrimary : AppColors.onboardingTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoriesRow extends StatelessWidget {
  final String activeCategory;
  final Function(String?, String?) onCategorySelected;

  const CategoriesRow({
    super.key,
    required this.activeCategory,
    required this.onCategorySelected,
  });

  static const List<({String label, String emoji, String? category, String? query, IconData? icon})> items = [
    (label: 'All', emoji: '⚙', category: 'general', query: null, icon: Icons.grid_view_rounded),
    (label: 'India', emoji: '🇮🇳', category: 'NATION', query: null, icon: null),
    (label: 'World', emoji: '🌎', category: 'WORLD', query: null, icon: null),
    (label: 'Tech', emoji: '💻', category: 'TECHNOLOGY', query: null, icon: null),
    (label: 'Business', emoji: '📈', category: 'BUSINESS', query: null, icon: null),
    (label: 'AI', emoji: '🤖', category: null, query: 'AI', icon: null),
    (label: 'Sports', emoji: '⚽', category: 'SPORTS', query: null, icon: null),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = (item.query != null && activeCategory == item.query) ||
              (item.category != null && activeCategory == item.category);

          return CategorySquareChip(
            label: item.label,
            emoji: item.emoji,
            icon: item.icon,
            isSelected: isSelected,
            onTap: () => onCategorySelected(item.category, item.query),
          );
        },
      ),
    );
  }
}

class HeroNewsCarousel extends StatefulWidget {
  final List<Article> articles;
  final Function(Article) onTap;

  const HeroNewsCarousel({
    super.key,
    required this.articles,
    required this.onTap,
  });

  @override
  State<HeroNewsCarousel> createState() => _HeroNewsCarouselState();
}

class _HeroNewsCarouselState extends State<HeroNewsCarousel> {
  int _activePage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.articles.isEmpty) return const SizedBox.shrink();

    final carouselArticles = widget.articles.take(4).toList();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: carouselArticles.length,
            onPageChanged: (page) {
              setState(() {
                _activePage = page;
              });
            },
            itemBuilder: (context, index) {
              final art = carouselArticles[index];
              return GestureDetector(
                onTap: () => widget.onTap(art),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: art.urlToImage != null && art.urlToImage!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: art.urlToImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) => Shimmer.fromColors(
                                  baseColor: AppColors.onboardingSurface,
                                  highlightColor: Colors.white10,
                                  child: Container(color: Colors.white),
                                ),
                                errorWidget: (c, u, e) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.onboardingBg, Color(0xFF1D1B26)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.onboardingBg, Color(0xFF1D1B26)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                      ),
                      Positioned.fill(
                        child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.85),
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 0.8,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Tag: BREAKING NEWS
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.onboardingSecondary.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.onboardingSecondary.withOpacity(0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                size: 12,
                                color: AppColors.onboardingSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'BREAKING NEWS',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Title
                        Text(
                          art.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Bottom row: source & CTA
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 8,
                                    backgroundColor: AppColors.onboardingAccent.withOpacity(0.2),
                                    child: const Icon(Icons.newspaper, size: 8, color: Colors.white),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      art.sourceName ?? 'News',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [AppColors.onboardingPrimary, AppColors.onboardingSecondary],
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Read Full Story',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(carouselArticles.length, (index) {
            final isActive = index == _activePage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 5,
              width: isActive ? 15 : 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: isActive ? AppColors.onboardingSecondary : Colors.white.withOpacity(0.2),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class AIInsightBanner extends StatelessWidget {
  final VoidCallback onViewInsight;

  const AIInsightBanner({super.key, required this.onViewInsight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GlassCard(
        borderRadius: 20,
        bgColor: AppColors.onboardingSurface.withOpacity(0.4),
        borderColor: AppColors.onboardingPrimary.withOpacity(0.15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [AppColors.onboardingSecondary, Colors.transparent],
                    radius: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onboardingSecondary.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.psychology_outlined,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AI Insight',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 12,
                          color: AppColors.onboardingAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Today's top stories are focused on Markets, AI breakthroughs and Climate Change.",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.onboardingTextSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onViewInsight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.onboardingAccent.withOpacity(0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View Insight',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrendingCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;

  const TrendingCard({
    super.key,
    required this.article,
    required this.onTap,
    required this.isBookmarked,
    required this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        width: 170,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 110,
                    width: 170,
                    decoration: BoxDecoration(
                      color: AppColors.onboardingSurface,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                        width: 0.8,
                      ),
                    ),
                    child: article.urlToImage != null && article.urlToImage!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: article.urlToImage!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: AppColors.onboardingSurface,
                              highlightColor: Colors.white10,
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (c, u, e) => const Icon(Icons.image, color: Colors.white24),
                          )
                        : const Center(
                            child: Icon(Icons.newspaper_rounded, color: Colors.white24, size: 28),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onBookmarkToggle,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.black.withOpacity(0.55),
                      child: Icon(
                        isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                        size: 14,
                        color: isBookmarked ? AppColors.onboardingAccent : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              (article.sectionName ?? 'General').toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.onboardingAccent,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              article.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.onboardingTextPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${article.sourceName ?? 'News'} • ${article.relativeTime} ago',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: AppColors.onboardingTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeadlineTile extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;

  const HeadlineTile({
    super.key,
    required this.article,
    required this.onTap,
    required this.isBookmarked,
    required this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 96,
                height: 96,
                color: AppColors.onboardingSurface,
                child: article.urlToImage != null && article.urlToImage!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: article.urlToImage!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: AppColors.onboardingSurface,
                          highlightColor: Colors.white10,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (c, u, e) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.onboardingBg, Color(0xFF1D1B26)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.newspaper_rounded, color: Colors.white24, size: 28),
                          ),
                        ),
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.onboardingBg, Color(0xFF1D1B26)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.newspaper_rounded, color: Colors.white24, size: 28),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onboardingTextPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        article.sourceName ?? 'News',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.onboardingTextSecondary),
                      ),
                      Text(
                        '• ${article.relativeTime} ago',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.onboardingTextSecondary),
                      ),
                      const Icon(Icons.access_time_filled_rounded, size: 10, color: AppColors.onboardingTextSecondary),
                      Text(
                        '${article.readTime ?? 3} min read',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.onboardingTextSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onBookmarkToggle,
                    child: Icon(
                      isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                      size: 18,
                      color: isBookmarked ? AppColors.onboardingAccent : AppColors.onboardingTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Share.share('${article.title}\n\nRead more: ${article.url}');
                    },
                    child: const Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: AppColors.onboardingTextSecondary,
                    ),
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

// --- CUSTOM PAINTERS ---

class HeaderGlobePainter extends CustomPainter {
  final double animationValue;

  HeaderGlobePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.85, size.height * 0.12);
    final radius = size.width * 0.42;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.onboardingAccent.withOpacity(0.08),
          AppColors.onboardingPrimary.withOpacity(0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.4));
    canvas.drawCircle(center, radius * 1.4, glowPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = AppColors.onboardingAccent.withOpacity(0.06);

    for (int i = 0; i < 4; i++) {
      final double width = radius * math.cos(animationValue * 0.2 + i * math.pi / 4);
      canvas.drawOval(
        Rect.fromCenter(center: center, width: width.abs() * 2, height: radius * 2),
        linePaint,
      );
    }

    for (int i = 1; i < 5; i++) {
      final double y = center.dy - radius + radius * 2 * (i / 5);
      final double w = radius * math.sin(math.acos(1.0 - 2 * (i / 5)).abs());
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, y), width: w * 2, height: radius * 0.2),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HeaderGlobePainter oldDelegate) => true;
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color bgColor;
  final Color borderColor;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    required this.bgColor,
    required this.borderColor,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor,
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
