import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../providers/news_provider.dart';
import '../../models/article.dart';
import 'widgets.dart';

class PublishersPage extends StatefulWidget {
  final String publisherName;

  const PublishersPage({
    super.key,
    required this.publisherName,
  });

  @override
  State<PublishersPage> createState() => _PublishersPageState();
}

class _PublishersPageState extends State<PublishersPage> {
  late String _currentPublisher;

  final Map<String, Map<String, dynamic>> _publisherData = {
    'BBC': {
      'bio': 'The British Broadcasting Corporation is a public service broadcaster, headquartered at Broadcasting House in London.',
      'color': 0xFFE50914,
      'stats': '1.2M stories • UK'
    },
    'Reuters': {
      'bio': 'Reuters is an international news agency owned by Thomson Reuters. It employs around 2,500 journalists worldwide.',
      'color': 0xFFFF9900,
      'stats': '3.4M stories • Global'
    },
    'NDTV': {
      'bio': 'New Delhi Television Ltd is an Indian news media company focusing on broadcast and digital news publications.',
      'color': 0xFF3B5998,
      'stats': '850k stories • India'
    },
    'The Hindu': {
      'bio': 'The Hindu is an English-language daily newspaper owned by The Hindu Group, headquartered in Chennai, Tamil Nadu.',
      'color': 0xFF0F172A,
      'stats': '620k stories • India'
    },
    'Indian Express': {
      'bio': 'The Indian Express is an English-language daily newspaper founded in 1932, known for investigative journalism.',
      'color': 0xFF0284C7,
      'stats': '500k stories • India'
    },
    'Bloomberg': {
      'bio': 'Bloomberg L.P. is a privately held financial, software, data, and media company headquartered in Midtown Manhattan.',
      'color': 0xFF2563EB,
      'stats': '900k stories • USA'
    },
    'CNN': {
      'bio': 'Cable News Network is a multinational news-based television channel headquartered in Atlanta, Georgia.',
      'color': 0xFFCC0000,
      'stats': '1.1M stories • USA'
    },
    'The Guardian': {
      'bio': 'The Guardian is a British daily newspaper with global readership, known for independent investigative journalism.',
      'color': 0xFF005689,
      'stats': '780k stories • UK'
    },
    'TechCrunch': {
      'bio': 'TechCrunch is a leading technology media property, dedicated to obsessively profiling startups and reviewing new products.',
      'color': 0xFF00A389,
      'stats': '180k stories • USA'
    },
    'Wired': {
      'bio': 'Wired is a monthly magazine focusing on how emerging technologies affect culture, the economy, and politics.',
      'color': 0xFF1E293B,
      'stats': '220k stories • USA'
    },
  };

  @override
  void initState() {
    super.initState();
    _currentPublisher = widget.publisherName;
  }

  Color _getPublisherColor(String name) {
    final pData = _publisherData[name];
    if (pData != null && pData['color'] != null) {
      return Color(pData['color'] as int);
    }
    return AppColors.primaryAccent;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final allArticles = provider.articles;

    if (_currentPublisher.isEmpty) {
      return _buildBrowsePublishersScreen(context, allArticles);
    } else {
      return _buildSinglePublisherScreen(context, allArticles, provider.trendingArticles);
    }
  }

  // 1. Browse Publishers List View
  Widget _buildBrowsePublishersScreen(BuildContext context, List<Article> allArticles) {
    final publishersKeys = _publisherData.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0010),
      appBar: AppBar(
        title: const Text(
          'TRUSTED PUBLISHERS',
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
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceM, vertical: DesignTokens.spaceM),
        itemCount: publishersKeys.length,
        itemBuilder: (context, index) {
          final pubName = publishersKeys[index];
          final pubInfo = _publisherData[pubName]!;
          final pubColor = _getPublisherColor(pubName);

          // Get 2 latest preview stories
          final previewStories = allArticles
              .where((art) => (art.sourceName ?? '').toLowerCase().contains(pubName.toLowerCase()))
              .take(2)
              .toList();

          return GlassCard(
            margin: const EdgeInsets.only(bottom: DesignTokens.spaceM),
            padding: const EdgeInsets.all(DesignTokens.spaceM),
            showGlow: true,
            glowColor: pubColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Logo + Name + Stats)
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pubColor.withOpacity(0.15),
                        border: Border.all(color: pubColor.withOpacity(0.4), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          pubName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pubName,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pubInfo['stats'] as String,
                            style: const TextStyle(color: AppColors.secondaryText, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  pubInfo['bio'] as String,
                  style: const TextStyle(color: AppColors.primaryText, fontSize: 11.5, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                // Preview of latest stories
                if (previewStories.isNotEmpty) ...[
                  const Text(
                    'LATEST STORIES',
                    style: TextStyle(color: AppColors.highlight, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  ...previewStories.map((story) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppColors.highlight, fontSize: 11)),
                          Expanded(
                            child: Text(
                              story.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],

                // Action button to open publisher feed
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        backgroundColor: pubColor.withOpacity(0.15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        setState(() {
                          _currentPublisher = pubName;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Open Publisher Feed',
                            style: TextStyle(color: pubColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, color: pubColor, size: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 2. Single Publisher Feed View
  Widget _buildSinglePublisherScreen(BuildContext context, List<Article> allArticles, List<Article> trendingFallback) {
    final pubArticles = allArticles.where((art) => (art.sourceName ?? '').toLowerCase().contains(_currentPublisher.toLowerCase())).toList();
    final displayList = pubArticles.isNotEmpty ? pubArticles : trendingFallback;

    final pData = _publisherData[_currentPublisher] ?? {
      'bio': 'A trusted regional news publisher delivering breaking events.',
      'stats': '120k stories • Global'
    };

    final pubColor = _getPublisherColor(_currentPublisher);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0010),
      appBar: AppBar(
        title: Text(
          _currentPublisher.toUpperCase(),
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
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (widget.publisherName.isEmpty) {
              setState(() {
                _currentPublisher = '';
              });
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: DesignTokens.spaceM),

            // Publisher Header Card
            GlassCard(
              showGlow: true,
              glowColor: pubColor.withOpacity(0.15),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pubColor.withOpacity(0.15),
                      border: Border.all(color: pubColor.withOpacity(0.4), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        _currentPublisher.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentPublisher,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pData['stats'] as String,
                    style: const TextStyle(color: AppColors.secondaryText, fontSize: 10),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pData['bio'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.primaryText, fontSize: 12, height: 1.45),
                  ),
                ],
              ),
            ),

            const SizedBox(height: DesignTokens.spaceL),

            // Feed Title
            const SectionHeader(title: 'Latest Feed'),
            const SizedBox(height: DesignTokens.spaceS),

            // Articles Feed
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final article = displayList[index];
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
                                style: TextStyle(color: pubColor, fontSize: 9, fontWeight: FontWeight.bold),
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
                                '${article.readTime ?? 5} min read',
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
    );
  }
}
