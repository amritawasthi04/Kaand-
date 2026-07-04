import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LoadingFlow extends StatefulWidget {
  final Animation<double> introFade;

  const LoadingFlow({
    super.key,
    required this.introFade,
  });

  @override
  State<LoadingFlow> createState() => _LoadingFlowState();
}

class _LoadingFlowState extends State<LoadingFlow> with SingleTickerProviderStateMixin {
  late AnimationController _indicatorController;

  @override
  void initState() {
    super.initState();
    // 1 second infinite loop for gradient flow and spinner
    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    return FadeTransition(
      opacity: widget.introFade,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Interactive Horizon Arch with Vertical Light Rays rising up
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // PNG loading flow asset if available
              SizedBox(
                width: width,
                height: 120,
                child: Image.asset(
                  'assets/splash/loading_flow.png',
                  fit: BoxFit.fitWidth,
                  opacity: const AlwaysStoppedAnimation(0.40),
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),

              // Canvas-drawn glowing vector rays and curved horizon to ensure high-res responsive fidelity
              AnimatedBuilder(
                animation: _indicatorController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(width, 100),
                    painter: _HorizonRaysPainter(
                      pulseValue: _indicatorController.value,
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 2. Circular Glowing Spinner
          AnimatedBuilder(
            animation: _indicatorController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _indicatorController.value * 2 * math.pi,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.transparent,
                    ),
                  ),
                  child: CustomPaint(
                    painter: _CircularSpinnerPainter(),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // 3. Loading Caption
          const Text(
            'Loading Kaand...',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 13.0,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryText,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 28),

          // 4. Muted bottom brand values
          Text(
            'Smart. Immersive. AI Ready.',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 10.0,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedText.withOpacity(0.5),
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizonRaysPainter extends CustomPainter {
  final double pulseValue;

  _HorizonRaysPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Draw vertical glowing neon lines (rays)
    final int rayCount = 14;
    final double step = width / (rayCount + 1);

    for (int i = 1; i <= rayCount; i++) {
      final double x = i * step;

      // Base heights with random weighting and dynamic pulsing
      final double centerFactor = 1.0 - ((x - width / 2).abs() / (width / 2));
      final double baseHeight = 45 * centerFactor;
      final double pulse = 8 * math.sin(pulseValue * 2 * math.pi + (i * 0.5));
      final double rayHeight = (baseHeight + pulse).clamp(5.0, 75.0);

      // Curved horizon Y offset
      final double horizonY = height - (20 * math.sin(math.pi * (x / width)));

      // Gradient color (Cyan on right, Violet on left, fading to transparent)
      final isRightSide = x > width / 2;
      final rayColor = isRightSide ? AppColors.highlight : AppColors.primaryAccent;

      final Paint rayPaint = Paint()
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            rayColor.withOpacity(0.7),
            rayColor.withOpacity(0.2),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTRB(x, horizonY - rayHeight, x, horizonY));

      canvas.drawLine(
        Offset(x, horizonY),
        Offset(x, horizonY - rayHeight),
        rayPaint,
      );
    }

    // Draw the curved horizon arc line
    final Path path = Path()
      ..moveTo(0, height)
      ..quadraticBezierTo(width / 2, height - 24, width, height);

    final Paint horizonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = const LinearGradient(
        colors: [
          AppColors.primaryAccent,
          AppColors.highlight,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, height - 24, width, 24));

    // Outer glow for the horizon arc
    final Paint glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
      ..shader = LinearGradient(
        colors: [
          AppColors.primaryAccent.withOpacity(0.4),
          AppColors.highlight.withOpacity(0.4),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, height - 24, width, 24));

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, horizonPaint);
  }

  @override
  bool shouldRepaint(covariant _HorizonRaysPainter oldDelegate) =>
      oldDelegate.pulseValue != pulseValue;
}

class _CircularSpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Gradient arc matching logo colors
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          Colors.transparent,
          AppColors.primaryAccent,
          AppColors.highlight,
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(rect);

    // Glowing blur effect background spinner
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          AppColors.primaryAccent.withOpacity(0.3),
          AppColors.highlight.withOpacity(0.5),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);

    canvas.drawArc(rect, 0, 1.5 * math.pi, false, glowPaint);
    canvas.drawArc(rect, 0, 1.5 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
