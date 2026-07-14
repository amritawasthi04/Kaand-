import 'dart:math' as math;
import 'package:flutter/material.dart';

class ParticleOverlay extends StatefulWidget {
  final Animation<double> introFade;

  const ParticleOverlay({
    super.key,
    required this.introFade,
  });

  @override
  State<ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<ParticleOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _driftController;
  final List<_Particle> _particles = [];
  final int _particleCount = 15;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    // Continuous drifting animation
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    // Initialize custom glowing particles
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          radius: _random.nextDouble() * 1.5 + 0.5,
          speed: _random.nextDouble() * 0.02 + 0.005,
          baseOpacity: _random.nextDouble() * 0.3 + 0.1,
          phase: _random.nextDouble() * 2 * math.pi,
        ),
      );
    }
  }

  @override
  void dispose() {
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.introFade,
      child: Stack(
        children: [
          // 1. Drifting image asset background
          AnimatedBuilder(
            animation: _driftController,
            builder: (context, child) {
              final angle = _driftController.value * 2 * math.pi;
              final dx = 12 * math.sin(angle);
              final dy = 8 * math.cos(angle);
              return Transform.translate(
                offset: Offset(dx, dy),
                child: SizedBox.expand(
                  child: Image.asset(
                    'assets/splash/particle_overlay.png',
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.20),
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              );
            },
          ),

          // 2. Custom drawn organic floating particle canvas layer
          AnimatedBuilder(
            animation: _driftController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _driftController.value,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  final double radius;
  final double speed;
  final double baseOpacity;
  final double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.baseOpacity,
    required this.phase,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (final particle in particles) {
      // Calculate dynamic positions drifting upwards
      double currentY = particle.y - (progress * particle.speed);
      if (currentY < 0) currentY += 1.0;

      final xOffset = 0.015 * math.sin(progress * 2 * math.pi + particle.phase);
      double currentX = particle.x + xOffset;
      if (currentX < 0) currentX += 1.0;
      if (currentX > 1) currentX -= 1.0;

      final pixelX = currentX * size.width;
      final pixelY = currentY * size.height;

      // Pulse opacity slightly
      final opacityPulse = 0.15 * math.sin(progress * 4 * math.pi + particle.phase);
      final currentOpacity = (particle.baseOpacity + opacityPulse).clamp(0.02, 0.5);

      paint.color = Colors.white.withOpacity(currentOpacity);
      
      // Draw subtle glow radial particles
      canvas.drawCircle(Offset(pixelX, pixelY), particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
