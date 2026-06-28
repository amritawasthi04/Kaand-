import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/news_provider.dart';
import '../theme/app_colors.dart';

class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({super.key});

  static final Map<String, IconData> _categoryIcons = {
    'general': Icons.public_rounded,
    'business': Icons.business_center_rounded,
    'entertainment': Icons.movie_rounded,
    'health': Icons.favorite_rounded,
    'science': Icons.science_rounded,
    'sports': Icons.sports_soccer_rounded,
    'technology': Icons.computer_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: AppColors.glassBorder,
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 40,
            offset: Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: AppColors.highlight,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Filter by Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Category grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.8,
            children: NewsProvider.categories.map((cat) {
              final isSelected = provider.selectedCategory == cat;
              return GestureDetector(
                onTap: () {
                  provider.setCategory(cat);
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [
                              AppColors.primaryAccent,
                              AppColors.interactive,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryAccent
                          : AppColors.divider,
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primaryAccent.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _categoryIcons[cat] ?? Icons.article_rounded,
                        size: 18,
                        color: isSelected
                            ? AppColors.primaryText
                            : AppColors.secondaryText,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cat[0].toUpperCase() + cat.substring(1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primaryText
                              : AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
