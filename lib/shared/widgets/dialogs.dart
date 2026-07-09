import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/design_tokens.dart';
import 'cards.dart';
import 'buttons.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmText,
    required this.onConfirm,
    this.cancelText,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceL),
      child: GlassCard(
        showGlow: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spaceM),
            Text(
              content,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spaceXL),
            Row(
              children: [
                if (cancelText != null) ...[
                  Expanded(
                    child: GhostButton(
                      text: cancelText!,
                      onPressed: onCancel ?? () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceM),
                ],
                Expanded(
                  child: PrimaryButton(
                    text: confirmText,
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    height: 48.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CustomBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const CustomBottomSheet({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(DesignTokens.radiusL),
        topRight: Radius.circular(DesignTokens.radiusL),
      ),
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: DesignTokens.spaceS),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceL,
                vertical: DesignTokens.spaceS,
              ),
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: AppColors.border),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DesignTokens.spaceL),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
