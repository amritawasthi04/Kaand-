import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/article.dart';
import '../theme/app_colors.dart';
import '../widgets/detail_sheet.dart';

class DetailScreen extends StatelessWidget {
  final Article article;

  const DetailScreen({
    super.key,
    required this.article,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Header Image Background
          if (article.urlToImage != null && article.urlToImage!.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.45,
              child: CachedNetworkImage(
                imageUrl: article.urlToImage!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined, size: 48, color: AppColors.mutedText),
                  ),
                ),
              ),
            )
          else
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.45,
              child: Container(
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
            
          // Back Button Overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          
          // Draggable Bottom Sheet containing the body content
          Positioned.fill(
            top: MediaQuery.of(context).size.height * 0.38,
            child: DetailSheet(article: article),
          ),
        ],
      ),
    );
  }
}
