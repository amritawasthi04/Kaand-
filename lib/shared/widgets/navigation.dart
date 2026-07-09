import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/design_tokens.dart';
import 'cards.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? titleText;
  final Widget? leading;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleText,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: BorderRadius.zero,
      padding: EdgeInsets.zero,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: preferredSize.height,
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Leading
              SizedBox(
                width: 48,
                child: leading ??
                    (Navigator.canPop(context)
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: AppColors.textPrimary),
                            onPressed: () => Navigator.pop(context),
                          )
                        : null),
              ),
              // Title
              Expanded(
                child: Center(
                  child: title ??
                      Text(
                        titleText ?? '',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                ),
              ),
              // Actions
              SizedBox(
                width: 48,
                child: actions != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: actions!,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60.0);
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceXS),
      margin: const EdgeInsets.only(
        left: DesignTokens.spaceM,
        right: DesignTokens.spaceM,
        bottom: DesignTokens.spaceM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = index == currentIndex;
          final item = items[index];
          return InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceM,
                vertical: DesignTokens.spaceXS,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected
                        ? _getSelectedIcon(index)
                        : _getUnselectedIcon(index),
                    color: isSelected ? AppColors.accent : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label ?? '',
                    style: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  IconData _getSelectedIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.search_rounded;
      case 2:
        return Icons.bookmark_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  IconData _getUnselectedIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home_outlined;
      case 1:
        return Icons.search_outlined;
      case 2:
        return Icons.bookmark_outline_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionPressed;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (actionText != null && onActionPressed != null)
            TextButton(
              onPressed: onActionPressed,
              child: Text(
                actionText!,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
