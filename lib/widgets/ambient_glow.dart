import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AmbientGlow extends StatefulWidget {
  final Animation<double> introFade;

  const AmbientGlow({
    super.key,
    required this.introFade,
  });

  @override
  State<AmbientGlow> createState() => _AmbientGlowState();
}

class _AmbientGlowState extends State<AmbientGlow> with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    // 4 seconds infinite loop breathing animation
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _breathingAnimation = Tween<double>(begin: 0.50, end: 0.85).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );

    _breathingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.introFade,
      child: AnimatedBuilder(
        animation: _breathingAnimation,
        builder: (context, child) {
          return SizedBox.expand(
            child: Opacity(
              opacity: _breathingAnimation.value,
              child: Image.asset(
                'assets/splash/ambient_glow.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Premium gradient fallback if image fails to load
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppColors.glassGlowViolet,
                          AppColors.glassGlowCyan,
                          Colors.transparent,
                        ],
                        radius: 0.9,
                        center: Alignment.center,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
