import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../providers/news_provider.dart';
import '../../models/article.dart';
import 'widgets.dart';

class TrendingPage extends StatefulWidget {
  const TrendingPage({super.key});

  @override
  State<TrendingPage> createState() => _TrendingPageState();
}

class _TrendingPageState extends State<TrendingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final list = provider.trendingArticles;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0010),
      appBar: AppBar(
        title: const Text(
          'TRENDING PULSE',
          style: TextStyle(
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
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppColors.highlight,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.secondaryText,
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'TRENDING TODAY'),
              Tab(text: 'MOST READ'),
              Tab(text: 'BREAKING NEWS'),
              Tab(text: 'POPULAR STORIES'),
              Tab(text: 'LIVE UPDATES'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTrendingList(context, list, 'Trending Today'),
                _buildTrendingList(context, list, 'Most Read'),
                _buildTrendingList(context, list, 'Breaking News'),
                _buildTrendingList(context, list, 'Popular Stories'),
                _buildTrendingList(context, list, 'Live Updates'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingList(BuildContext context, List<Article> list, String filterType) {
    if (list.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: DesignTokens.spaceM),

          // 1. Trending Heat Chart Analytics
          _buildTrendAnalyticsCard(filterType),

          const SizedBox(height: DesignTokens.spaceL),

          // 2. Rankings Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Stories ($filterType)',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 16),
                  SizedBox(width: 4),
                  Text('98.4 Index Value', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceM),

          // 3. Ranked Articles
          ...List.generate(list.length, (index) {
            final article = list[index];
            final rank = index + 1;

            return GestureDetector(
              onTap: () => context.push('/detail', extra: article),
              child: Container(
                margin: const EdgeInsets.only(bottom: DesignTokens.spaceM),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rank Badge
                    _buildRankBadge(rank),
                    const SizedBox(width: 12),

                    // Content details
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(DesignTokens.spaceS),
                        borderRadius: DesignTokens.radiusM,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                              child: CachedNetworkImage(
                                imageUrl: article.urlToImage ?? '',
                                width: 75,
                                height: 75,
                                memCacheWidth: 250,
                                fit: BoxFit.cover,
                                placeholder: (c, u) => Container(color: AppColors.surface, width: 75, height: 75),
                                errorWidget: (c, u, e) => Container(color: AppColors.surface, width: 75, height: 75),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        (article.sectionName ?? 'General').toUpperCase(),
                                        style: const TextStyle(color: AppColors.highlight, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.share_rounded, color: AppColors.secondaryText, size: 10),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${(200 - rank * 35)}k',
                                            style: const TextStyle(color: AppColors.secondaryText, fontSize: 8.5),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    article.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${article.sourceName ?? 'News'} • ${article.relativeTime}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.secondaryText, fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Spacing buffer for bottom nav
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color startColor = AppColors.surface;
    Color endColor = AppColors.divider;
    String label = '#$rank';

    if (rank == 1) {
      startColor = const Color(0xFFFFD700); // Gold
      endColor = const Color(0xFFFFA500);
    } else if (rank == 2) {
      startColor = const Color(0xFFC0C0C0); // Silver
      endColor = const Color(0xFF808080);
    } else if (rank == 3) {
      startColor = const Color(0xFFCD7F32); // Bronze
      endColor = const Color(0xFF8B4513);
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [startColor, endColor]),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTrendAnalyticsCard(String type) {
    return GlassCard(
      showGlow: true,
      glowColor: AppColors.glassGlowCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: AppColors.highlight, size: 18),
              const SizedBox(width: 8),
              Text(
                'Velocity Index Trend ($type)',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Custom Painted Linear Chart
          SizedBox(
            height: 90,
            child: CustomPaint(
              painter: _TrendingWavePainter(type: type),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('09:00 AM', style: TextStyle(color: AppColors.secondaryText, fontSize: 8)),
              Text('12:00 PM', style: TextStyle(color: AppColors.secondaryText, fontSize: 8)),
              Text('03:00 PM', style: TextStyle(color: AppColors.secondaryText, fontSize: 8)),
              Text('06:00 PM', style: TextStyle(color: AppColors.secondaryText, fontSize: 8)),
              Text('09:00 PM', style: TextStyle(color: AppColors.secondaryText, fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendingWavePainter extends CustomPainter {
  final String type;

  _TrendingWavePainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = AppColors.highlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [AppColors.highlight.withOpacity(0.35), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final path = Path();
    double seedMultiplier = type == 'Today' ? 1.0 : type == 'Most Read' ? 1.4 : type == 'Viral' ? 0.7 : 1.2;

    path.moveTo(0, size.height * 0.7);
    path.cubicTo(
      size.width * 0.25,
      size.height * (0.8 - 0.5 * seedMultiplier),
      size.width * 0.5,
      size.height * (0.2 + 0.3 * seedMultiplier),
      size.width * 0.75,
      size.height * 0.1,
    );
    path.quadraticBezierTo(
      size.width * 0.88,
      size.height * 0.05,
      size.width,
      size.height * 0.35,
    );

    // Draw area fill
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    // Draw hot points
    final paintNode = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final paintRing = Paint()
      ..color = AppColors.highlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.1), 4, paintNode);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.1), 6, paintRing);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
