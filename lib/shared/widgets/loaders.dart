import 'package:flutter/material.dart';
import '../../core/constants/design_tokens.dart';
import '../../core/theme/app_colors.dart';

import 'kaand_lottie.dart';

class LottieLoader extends StatelessWidget {
  final String assetPath;
  final double size;
  final bool repeat;

  const LottieLoader({
    super.key,
    required this.assetPath,
    this.size = 120.0,
    this.repeat = true,
  });

  @override
  Widget build(BuildContext context) {
    return KaandLottie(
      assetPath: assetPath,
      width: size,
      height: size,
      loop: repeat,
    );
  }
}

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 20.0,
    this.borderRadius = DesignTokens.radiusS,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacityAnimation = Tween<double>(begin: 0.15, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.textSecondary,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        ),
      ),
    );
  }
}
