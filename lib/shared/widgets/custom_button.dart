import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum ButtonType { primary, secondary, outline, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 54.0,
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color? buttonColor;
    Color textColor = AppColors.text;
    BorderSide borderSide = BorderSide.none;
    List<BoxShadow>? shadows;

    switch (type) {
      case ButtonType.primary:
        buttonColor = AppColors.primary;
        textColor = Colors.white;
        shadows = onPressed != null
            ? const [
                BoxShadow(
                  color: AppColors.primaryGlow,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                )
              ]
            : null;
        break;
      case ButtonType.secondary:
        buttonColor = AppColors.accent;
        textColor = AppColors.background;
        shadows = onPressed != null
            ? const [
                BoxShadow(
                  color: AppColors.accentGlow,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                )
              ]
            : null;
        break;
      case ButtonType.outline:
        buttonColor = Colors.transparent;
        textColor = AppColors.accent;
        borderSide = const BorderSide(color: AppColors.accent, width: 1.5);
        break;
      case ButtonType.text:
        buttonColor = Colors.transparent;
        textColor = AppColors.textSecondary;
        break;
    }

    Widget content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );

    return Opacity(
      opacity: onPressed == null || isLoading ? 0.6 : 1.0,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadows,
        ),
        child: Material(
          color: buttonColor,
          borderRadius: BorderRadius.circular(borderRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: (onPressed == null || isLoading) ? null : onPressed,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: borderSide != BorderSide.none
                    ? Border.fromBorderSide(borderSide)
                    : null,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
