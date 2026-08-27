import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../providers/news_provider.dart';
import '../../models/article.dart';
import 'widgets.dart';

class TopicsPage extends StatefulWidget {
  final String topicTag;

  const TopicsPage({
    super.key,
    required this.topicTag,
  });

  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  bool _isFollowing = false;
  int _followersCount = 1420;

  final List<String> _relatedTags = [
    '#TechRevolution',
    '#Decentralized',
    '#ExploreOuterSpace',
    '#VentureCapital',
    '#GreenEnergy',
  ];

  @override
  void initState() {
    super.initState();
    _followersCount = 1200 + widget.topicTag.length * 77; // semi-random seed
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final articles = provider.trendingArticles; // Mocking topic feeds with trending articles

    return Scaffold(
      backgroundColor: const Color(0xFF0A0010),
      appBar: AppBar(
        title: Text(
          widget.topicTag,
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: DesignTokens.spaceM),

            // 1. Topic Profile Banner Card
            _buildTopicHeaderCard(),

            const SizedBox(height: DesignTokens.spaceL),

            // 2. Feed Header
            const SectionHeader(title: 'Recent Stories'),
            const SizedBox(height: DesignTokens.spaceS),

            // 3. Articles feed list
            _buildStoriesList(context, articles),

            const SizedBox(height: DesignTokens.spaceL),

            // 4. Related topics
            _buildRelatedTopicsSection(context),

            // Spacing buffer for bottom nav
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicHeaderCard() {
    return GlassCard(
      showGlow: true,
      glowColor: AppColors.glassGlowViolet,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryAccent.withOpacity(0.4), width: 1.5),
            ),
            child: const Icon(Icons.tag_rounded, color: AppColors.primaryAccent, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            widget.topicTag,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${_followersCount.toString()} followers • 42 stories published this week',
            style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
          ),
          const SizedBox(height: 16),
          // Follow Button Toggle
          InkWell(
            onTap: () {
              setState(() {
                _isFollowing = !_isFollowing;
                if (_isFollowing) {
                  _followersCount++;
                  SnackBarFeedback.showSuccess(context, 'Following ${widget.topicTag}');
                } else {
                  _followersCount--;
                  SnackBarFeedback.showSuccess(context, 'Unfollowed ${widget.topicTag}');
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: _isFollowing ? Colors.transparent : AppColors.primaryAccent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryAccent),
              ),
              child: Text(
                _isFollowing ? 'FOLLOWING' : 'FOLLOW TOPIC',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesList(BuildContext context, List<Article> list) {
    if (list.isEmpty) {
      return const EmptyState(
        title: 'No recent stories',
        description: 'Check back later for stories in this topic.',
        icon: Icons.tag_faces_rounded,
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final article = list[index];
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
                    width: 80,
                    height: 80,
                    memCacheWidth: 260,
                    fit: BoxFit.cover,
                    placeholder: (c, u) => Container(color: AppColors.surface, width: 80, height: 80),
                    errorWidget: (c, u, e) => Container(color: AppColors.surface, width: 80, height: 80),
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (article.sectionName ?? 'General').toUpperCase(),
                        style: const TextStyle(color: AppColors.highlight, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          height: 1.25,
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRelatedTopicsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Related Topics'),
        const SizedBox(height: DesignTokens.spaceS),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _relatedTags.map((tag) {
            return ActionChip(
              label: Text(tag, style: const TextStyle(color: AppColors.primaryText, fontSize: 11)),
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
              onPressed: () {
                context.pushReplacement('/topics', extra: tag);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
