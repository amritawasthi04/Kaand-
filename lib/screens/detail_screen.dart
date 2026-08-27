import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/detail_sheet.dart';

class DetailScreen extends StatefulWidget {
  final Article article;

  const DetailScreen({
    super.key,
    required this.article,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<UserProvider>().recordReadingDay();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Header Image Background with Hero Morphing Transition
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Hero(
              tag: 'article-image-${widget.article.title}',
              child: widget.article.urlToImage != null && widget.article.urlToImage!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.article.urlToImage!,
                      fit: BoxFit.cover,
                      memCacheWidth: 1080,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: AppColors.surface,
                        highlightColor: Colors.white10,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.surface,
                        child: const Center(
                          child: Icon(Icons.image_not_supported_outlined, size: 48, color: AppColors.mutedText),
                        ),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppColors.primaryGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.newspaper_rounded, size: 72, color: AppColors.primaryText),
                      ),
                    ),
            ),
          ),
            
          // Back Button Overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          
          // Draggable Bottom Sheet containing the body content
          Positioned.fill(
            top: MediaQuery.of(context).size.height * 0.38,
            child: DetailSheet(article: widget.article),
          ),
        ],
      ),
    );
  }
}
