import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
import '../providers/news_provider.dart';
import '../theme/app_colors.dart';

class DetailSheet extends StatefulWidget {
  final Article article;

  const DetailSheet({
    super.key,
    required this.article,
  });

  @override
  State<DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<DetailSheet> {
  late Article _currentArticle;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentArticle = widget.article;
    _loadArticleDetails();
  }

  Future<void> _loadArticleDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      final updated = await newsProvider.loadDetails(_currentArticle);
      if (mounted) {
        setState(() {
          _currentArticle = updated;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Indicator handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentArticle.sourceName ?? 'News',
                  style: const TextStyle(
                    color: AppColors.highlight,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: AppColors.primaryText, size: 22),
                      onPressed: () {
                        Share.share('${_currentArticle.title}\n\nRead more: ${_currentArticle.url}');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_browser_outlined, color: AppColors.primaryText, size: 22),
                      onPressed: () async {
                        final uri = Uri.parse(_currentArticle.url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
          const Divider(),
          
          // Article Content Scroll Area
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _currentArticle.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                      height: 1.3,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Author & Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentArticle.author != null && _currentArticle.author!.isNotEmpty)
                        Expanded(
                          child: Text(
                            'By ${_currentArticle.author}',
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Text(
                        _currentArticle.publishedAt != null && _currentArticle.publishedAt!.length >= 10
                            ? _currentArticle.publishedAt!.substring(0, 10)
                            : '',
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Description / Body
                  if (_isLoading && (_currentArticle.description == null || _currentArticle.description!.isEmpty))
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(color: AppColors.primaryAccent),
                      ),
                    )
                  else ...[
                    Text(
                      _currentArticle.description ?? 'No content available.',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.secondaryText,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(_currentArticle.url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.arrow_outward, size: 16),
                        label: const Text('Read Full Article'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
