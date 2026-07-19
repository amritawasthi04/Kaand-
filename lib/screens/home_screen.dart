import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../providers/news_provider.dart';
import '../providers/user_provider.dart';
import '../models/article.dart';
import '../theme/app_colors.dart';
import '../services/hive_cache.dart';
import '../widgets/shimmer_card.dart';

// --- CUSTOM PAINTER FOR BACKGROUND GLOBE ---
class HeaderGlobePainter extends CustomPainter {
  final double rotationValue;
  HeaderGlobePainter(this.rotationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onboardingAccent.withOpacity(0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width * 0.85, size.height * 0.2);
    final radius = size.width * 0.45;

    // Draw main globe boundary
    canvas.drawCircle(center, radius, paint);

    // Draw rotated latitudes/longitudes
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationValue * 2 * math.pi);

    for (var i = 1; i <= 6; i++) {
      final latRadius = radius * (i / 6);
      canvas.drawCircle(Offset.zero, latRadius, paint);
    }

    final longPaint = Paint()
      ..color = AppColors.onboardingAccent.withOpacity(0.04)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi) / 4;
      canvas.drawLine(
        Offset(radius * math.cos(angle), radius * math.sin(angle)),
        Offset(-radius * math.cos(angle), -radius * math.sin(angle)),
        longPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HeaderGlobePainter oldDelegate) {
    return oldDelegate.rotationValue != rotationValue;
  }
}

// --- GLASS CARD COMPONENT ---
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color bgColor;
  final Color borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

// --- MAIN NAVIGATION SHELL ---
class HomeScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const HomeScreen({super.key, required this.navigationShell});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      drawer: _buildDrawer(context, userProvider),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.onboardingBg,
        ),
        child: Stack(
          children: [
            // Active route tab viewport
            Positioned.fill(
              child: widget.navigationShell,
            ),

            // Sliding indicator bottom nav bar overlay
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

  // --- FLOATING BOTTOM NAVIGATION BAR ---
  Widget _buildFloatingBottomNavBar(BuildContext context) {
    final shell = widget.navigationShell;
    const tabsCount = 4;
    return GlassCard(
      borderRadius: 30,
      bgColor: AppColors.onboardingSurface.withOpacity(0.75),
      borderColor: Colors.white.withOpacity(0.12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth - 32; // subtracting horizontal padding (16 * 2)
          final itemWidth = barWidth / tabsCount;
          final activeIndex = shell.currentIndex;

          return Container(
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Stack(
              children: [
                // Sliding Pill Indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  left: activeIndex * itemWidth,
                  top: 8,
                  bottom: 8,
                  width: itemWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.onboardingAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.onboardingAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                // Icons Row
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavItem(0, Icons.home_rounded, 'Home'),
                      _buildNavItem(1, Icons.grid_view_rounded, 'Categories'),
                      _buildNavItem(2, Icons.bookmark_rounded, 'Bookmarks'),
                      _buildNavItem(3, Icons.person_rounded, 'Profile'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final shell = widget.navigationShell;
    final isActive = shell.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          shell.goBranch(index, initialLocation: index == shell.currentIndex);
        },
        child: AnimatedScale(
          scale: isActive ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: Icon(
                  icon,
                  color: isActive ? AppColors.onboardingAccent : Colors.white60,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? AppColors.onboardingAccent : Colors.white60,
                ),
                child: Text(label),
              ),
            ],
          ),
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
                widget.navigationShell.goBranch(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_outlined, color: Colors.white),
              title: const Text('Guardian Editorial', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.push('/blogs');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Colors.white),
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
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
                color: isSelected
                    ? AppColors.onboardingAccent
                    : AppColors.onboardingTextSecondary,
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
                color: isSelected
                    ? AppColors.onboardingTextPrimary
                    : AppColors.onboardingTextSecondary,
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

  static const List<
      ({
        String label,
        String emoji,
        String? category,
        String? query,
        IconData? icon
      })> items = [
    (
      label: 'All',
      emoji: '⚙',
      category: 'general',
      query: null,
      icon: Icons.grid_view_rounded
    ),
    (
      label: 'India',
      emoji: '🇮🇳',
      category: 'NATION',
      query: null,
      icon: null
    ),
    (label: 'World', emoji: '🌎', category: 'WORLD', query: null, icon: null),
    (
      label: 'Tech',
      emoji: '💻',
      category: 'TECHNOLOGY',
      query: null,
      icon: null
    ),
    (
      label: 'Business',
      emoji: '📈',
      category: 'BUSINESS',
      query: null,
      icon: null
    ),
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
          final isSelected =
              (item.query != null && activeCategory == item.query) ||
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
                        child: Hero(
                          tag: 'article-image-${art.title}',
                          child: art.urlToImage != null && art.urlToImage!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: art.urlToImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                    baseColor: AppColors.onboardingSurface,
                                    highlightColor: Colors.white10,
                                    child: Container(color: Colors.white),
                                  ),
                                  errorWidget: (c, u, e) => Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.onboardingBg,
                                          Color(0xFF1D1B26)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.onboardingBg,
                                        Color(0xFF1D1B26)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.onboardingSecondary
                                      .withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.onboardingSecondary
                                        .withOpacity(0.5),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 8,
                                          backgroundColor: AppColors
                                              .onboardingAccent
                                              .withOpacity(0.2),
                                          child: const Icon(Icons.newspaper,
                                              size: 8, color: Colors.white),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.onboardingPrimary,
                                          AppColors.onboardingSecondary
                                        ],
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
                color: isActive
                    ? AppColors.onboardingSecondary
                    : Colors.white.withOpacity(0.2),
              ),
            );
          }),
        ),
      ],
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
                  child: Hero(
                    tag: 'article-image-${article.title}',
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
                      child: article.urlToImage != null &&
                              article.urlToImage!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: article.urlToImage!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: AppColors.onboardingSurface,
                                highlightColor: Colors.white10,
                                child: Container(color: Colors.white),
                              ),
                              errorWidget: (c, u, e) =>
                                  const Icon(Icons.image, color: Colors.white24),
                            )
                          : const Center(
                              child: Icon(Icons.newspaper_rounded,
                                  color: Colors.white24, size: 28),
                            ),
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
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        size: 14,
                        color: isBookmarked
                            ? AppColors.onboardingAccent
                            : Colors.white,
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
              child: Hero(
                tag: 'article-image-${article.title}',
                child: Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    color: AppColors.onboardingSurface,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                      width: 0.8,
                    ),
                  ),
                  child: article.urlToImage != null &&
                          article.urlToImage!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: article.urlToImage!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: AppColors.onboardingSurface,
                            highlightColor: Colors.white10,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (c, u, e) =>
                              const Icon(Icons.image, color: Colors.white24),
                        )
                      : const Center(
                          child: Icon(Icons.newspaper_rounded,
                              color: Colors.white24, size: 24),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${article.sourceName ?? 'News'} • ${article.relativeTime} ago',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: AppColors.onboardingTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onBookmarkToggle,
                        child: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          size: 16,
                          color: isBookmarked
                              ? AppColors.onboardingAccent
                              : Colors.white60,
                        ),
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

// --- TABS DEFINITIONS ---

// 1. HomeTab
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final ScrollController _homeScrollController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _homeScrollController = ScrollController();
    _homeScrollController.addListener(() {
      final pos = _homeScrollController.position;
      if (pos.pixels >= pos.maxScrollExtent * 0.8) {
        Provider.of<NewsProvider>(context, listen: false)
            .loadNextHeadlinesPage();
      }
    });

    Future.microtask(() {
      if (!mounted) return;
      Provider.of<NewsProvider>(context, listen: false).loadHeadlines();
    });
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    _rotationController.dispose();
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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Globe background constellation
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

          // Main Feed Scroll View
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: () => newsProvider.loadHeadlines(),
              color: AppColors.onboardingAccent,
              backgroundColor: AppColors.onboardingSurface,
              child: CustomScrollView(
                controller: _homeScrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
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
                                      context.push('/search');
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
                              const Text('👋', style: TextStyle(fontSize: 26)),
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

                  // Feed States
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
                            const Text('Unable to load news.', style: TextStyle(color: AppColors.secondaryText)),
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
                            const Text('Pull to Refresh', style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Breaking News Carousel
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: HeroNewsCarousel(
                          articles: newsProvider.guardianArticles,
                          onTap: (art) {
                            context.push('/detail', extra: art);
                          },
                        ),
                      ),
                    ),

                    // Categories Selector Row
                    SliverToBoxAdapter(
                      child: CategoriesRow(
                        activeCategory: newsProvider.selectedCategory,
                        onCategorySelected: _onCategoryChipSelected,
                      ),
                    ),

                    // Trending Now Section
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
                                    context.push('/detail', extra: art);
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

                    // Latest Headlines Header
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

                    // Latest Headlines Tiles List
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final art = newsProvider.latestArticles[index];
                            return HeadlineTile(
                              article: art,
                              onTap: () {
                                context.push('/detail', extra: art);
                              },
                              isBookmarked: userProvider.isBookmarked(art),
                              onBookmarkToggle: () => userProvider.toggleBookmark(art),
                            );
                          },
                          childCount: newsProvider.latestArticles.length,
                        ),
                      ),
                    ),

                    // Loader or footer offset
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Column(
                          children: [
                            if (newsProvider.homeLoadingMore)
                              const Center(
                                child: CircularProgressIndicator(color: AppColors.onboardingSecondary),
                              )
                            else if (!newsProvider.homeHasMore)
                              Center(
                                child: Text(
                                  "You've reached the end",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.onboardingTextSecondary.withOpacity(0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. CategoriesTab
class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    final categories = CategoriesRow.items;

    void onCategoryChipSelected(String? category, String? query) {
      if (query != null) {
        newsProvider.search(query);
      } else if (category != null) {
        newsProvider.setCategory(category);
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
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
                      onCategoryChipSelected(cat.category, cat.query);
                      // Navigate back to home branch dynamically
                      HomeScreenStateHelper.goToHomeBranch(context);
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
      ),
    );
  }
}

// 3. BookmarksTab
class BookmarksTab extends StatelessWidget {
  const BookmarksTab({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final bookmarks = userProvider.bookmarks;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
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
                            context.push('/detail', extra: art);
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
      ),
    );
  }
}

// 4. ProfileTab
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final TextEditingController _profileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final name = Provider.of<UserProvider>(context, listen: false).name;
    _profileNameController.text = name;
  }

  @override
  void dispose() {
    _profileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
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
      ),
    );
  }
}

// Helper class to navigate to home branch from anywhere
class HomeScreenStateHelper {
  static void goToHomeBranch(BuildContext context) {
    final rootState = context.findAncestorStateOfType<_HomeScreenState>();
    if (rootState != null) {
      rootState.widget.navigationShell.goBranch(0);
    }
  }
}
