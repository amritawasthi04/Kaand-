import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AnimatedLogo extends StatelessWidget {
  final Animation<double> introFade;
  final Animation<double> introScale;
  final Animation<double> logoPulse;

  const AnimatedLogo({
    super.key,
    required this.introFade,
    required this.introScale,
    required this.logoPulse,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: logoPulse,
      builder: (context, child) {
        // Compound scaling: intro entrance scale * logo glow pulse scale
        final scale = introScale.value * logoPulse.value;

        return Transform.scale(
          scale: scale,
          child: FadeTransition(
            opacity: introFade,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAccent.withOpacity(0.20 * logoPulse.value),
                    blurRadius: 30 + (10 * (logoPulse.value - 1.0) / 0.03),
                    spreadRadius: 2 + (2 * (logoPulse.value - 1.0) / 0.03),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/logo/Kaand_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Modern placeholder if image fails to load
                    return Container(
                      color: AppColors.elevatedCard,
                      child: const Icon(
                        Icons.newspaper_rounded,
                        size: 56,
                        color: AppColors.highlight,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
