import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? glowColor;
  final double glowRadius;
  final bool showGlow;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.blur = 15.0,
    this.glowColor,
    this.glowRadius = 10.0,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: glowColor ?? AppColors.primaryGlow,
                  blurRadius: glowRadius,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: AppColors.cardBg.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
