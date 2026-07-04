import 'package:flutter/material.dart';

class AnimatedGlobe extends StatefulWidget {
  final Animation<double> introFade;

  const AnimatedGlobe({
    super.key,
    required this.introFade,
  });

  @override
  State<AnimatedGlobe> createState() => _AnimatedGlobeState();
}

class _AnimatedGlobeState extends State<AnimatedGlobe> with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    // 28 seconds slow continuous linear rotation
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: widget.introFade,
        child: RotationTransition(
          turns: _spinController,
          child: Image.asset(
            'assets/splash/dotted_globe.png',
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              // Transparent fallback if file fails to load
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
