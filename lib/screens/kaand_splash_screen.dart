import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

const int _kGlobePoints = 420;
const int _kStarCount = 40;
const String _kLogoAsset = 'assets/logo/Kaand_logo.png';

class KaandSplashScreen extends StatefulWidget {
  const KaandSplashScreen({super.key});

  @override
  State<KaandSplashScreen> createState() => _KaandSplashScreenState();
}

class _KaandSplashScreenState extends State<KaandSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _ambient;

  late final Float64List _px, _py, _pz, _latT;
  late final Float64List _starX, _starY, _starPhase;

  bool _finished = false;
  bool _started = false;
  bool _precached = false;
  Timer? _liteTimer;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: AppDurations.splashIntro,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
    _ambient = AnimationController(
      vsync: this,
      duration: AppDurations.ambientLoop,
    );
    _buildGeometry();
  }

  void _buildGeometry() {
    _px = Float64List(_kGlobePoints);
    _py = Float64List(_kGlobePoints);
    _pz = Float64List(_kGlobePoints);
    _latT = Float64List(_kGlobePoints);
    final golden = math.pi * (3 - math.sqrt(5));
    for (var i = 0; i < _kGlobePoints; i++) {
      final y = 1 - (2 * (i + 0.5)) / _kGlobePoints;
      final r = math.sqrt(math.max(0.0, 1 - y * y));
      final theta = golden * i;
      _px[i] = math.cos(theta) * r;
      _py[i] = y;
      _pz[i] = math.sin(theta) * r;
      _latT[i] = (1 - y) / 2;
    }
    _starX = Float64List(_kStarCount);
    _starY = Float64List(_kStarCount);
    _starPhase = Float64List(_kStarCount);
    final rng = math.Random(7);
    for (var i = 0; i < _kStarCount; i++) {
      _starX[i] = rng.nextDouble();
      _starY[i] = rng.nextDouble();
      _starPhase[i] = rng.nextDouble() * 2 * math.pi;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      precacheImage(const AssetImage(_kLogoAsset), context);
    }
    if (_started || _finished) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _intro.value = 0.88;
      _liteTimer = Timer(AppDurations.liteSplashHold, _finish);
    } else {
      _intro.forward();
      _ambient.repeat();
    }
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    _liteTimer?.cancel();
    _intro.stop();
    _ambient.stop();
    context.go('/home');
  }

  @override
  void dispose() {
    _liteTimer?.cancel();
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onboardingBg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: AnimatedBuilder(
          animation: _intro,
          builder: (context, child) {
            final outro = Interval(0.90, 1.0, curve: Curves.easeIn)
                .transform(_intro.value);
            return Opacity(
              opacity: 1 - outro,
              child: Transform.scale(
                scale: 1 + 0.16 * outro,
                alignment: Alignment.topCenter,
                child: child,
              ),
            );
          },
          child: _buildScene(),
        ),
      ),
    );
  }

  Widget _buildScene() {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_intro, _ambient]),
            builder: (_, __) => CustomPaint(
              painter: _ScenePainter(
                intro: _intro.value,
                ambient: _ambient.value,
                px: _px,
                py: _py,
                pz: _pz,
                latT: _latT,
                starX: _starX,
                starY: _starY,
                starPhase: _starPhase,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogo(),
                const SizedBox(height: 26),
                _buildWordmark(),
                const SizedBox(height: 18),
                _buildWire(),
                const SizedBox(height: 16),
                _buildStatus(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 140,
      height: 140,
      child: Center(
        child: SizedBox(
          width: 116,
          height: 116,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  _kLogoAsset,
                  width: 116,
                  height: 116,
                  fit: BoxFit.cover,
                  cacheWidth: 512,
                  filterQuality: FilterQuality.medium,
                ),
              )
                  .animate(controller: _intro, delay: 1050.ms)
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1, 1),
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _intro,
                  builder: (context, _) {
                    final t =
                        Interval(0.55, 0.70, curve: Curves.easeInOutCubic)
                            .transform(_intro.value);
                    if (t <= 0 || t >= 1) return const SizedBox.shrink();
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Align(
                        alignment: Alignment(-1.4 + 2.8 * t, 0),
                        child: Transform.rotate(
                          angle: 0.22,
                          child: Container(
                            width: 46,
                            height: 240,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0),
                                  Colors.white.withOpacity(0.24),
                                  Colors.white.withOpacity(0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordmark() {
    const letters = ['K', 'A', 'A', 'N', 'D'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < letters.length; i++)
          SizedBox(
            width: 30,
            height: 46,
            child: Center(
              child: Text(
                letters[i],
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                  color: AppColors.wordmark,
                ),
              ),
            ),
          )
              .animate(
                controller: _intro,
                delay: Duration(milliseconds: 1450 + i * 60),
              )
              .fadeIn(duration: 350.ms, curve: Curves.easeOut)
              .slideY(
                begin: 0.3,
                end: 0,
                duration: 380.ms,
                curve: Curves.easeOutCubic,
              ),
        const SizedBox(width: 7),
        _buildLiveDot(),
      ],
    );
  }

  Widget _buildLiveDot() {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, child) {
        final breath = 0.5 + 0.5 * math.sin(_ambient.value * 2 * math.pi);
        return Transform.scale(
          scale: 1 + 0.14 * breath,
          child: Opacity(
            opacity: 0.65 + 0.35 * breath,
            child: child,
          ),
        );
      },
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.live,
          shape: BoxShape.circle,
        ),
      )
          .animate(controller: _intro, delay: 1350.ms)
          .fadeIn(duration: 120.ms)
          .scale(
            begin: Offset.zero,
            end: const Offset(1, 1),
            duration: 550.ms,
            curve: Curves.elasticOut,
          ),
    );
  }

  Widget _buildWire() {
    return SizedBox(
      width: 230,
      height: 14,
      child: AnimatedBuilder(
        animation: _intro,
        builder: (context, _) => CustomPaint(
          painter: _WirePainter(
            progress: Interval(0.75, 0.90, curve: Curves.easeInOutCubic)
                .transform(_intro.value),
          ),
        ),
      ),
    );
  }

  Widget _buildStatus() {
    return Text(
      'THE WORLD, IN MOTION',
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.8,
        color: AppColors.tagline,
      ),
    )
        .animate(controller: _intro, delay: 1950.ms)
        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.6,
          end: 0,
          duration: 380.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.intro,
    required this.ambient,
    required this.px,
    required this.py,
    required this.pz,
    required this.latT,
    required this.starX,
    required this.starY,
    required this.starPhase,
  });

  final double intro;
  final double ambient;
  final Float64List px, py, pz, latT;
  final Float64List starX, starY, starPhase;

  @override
  void paint(Canvas canvas, Size size) {
    final global = Curves.easeOut.transform(_interval(0.0, 0.15, intro));
    if (global <= 0) return;

    final breath = 0.5 + 0.5 * math.sin(ambient * 2 * math.pi);
    final cx = size.width / 2;
    final cy = size.height * 0.40;
    final radius =
        (math.min(size.width, size.height) * 0.30).clamp(110.0, 175.0);

    _paintGlow(canvas, cx, cy, radius, breath, global);
    _paintStars(canvas, size, global);
    _paintGlobe(canvas, cx, cy, radius, global);
    _paintRings(canvas, cx, cy, radius, global);
  }

  void _paintGlow(
      Canvas canvas, double cx, double cy, double r, double breath,
      double global) {
    final glow = (0.10 + 0.08 * breath) * global;
    final center = Offset(cx, cy);
    canvas.drawCircle(
      center,
      r * 2.0,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          r * 2.0,
          [
            AppColors.brand.withOpacity(glow),
            AppColors.brand.withOpacity(0),
          ],
          [0, 1],
        ),
    );
    final cyanCenter = Offset(cx + r * 0.55, cy - r * 0.45);
    canvas.drawCircle(
      cyanCenter,
      r * 1.1,
      Paint()
        ..shader = ui.Gradient.radial(
          cyanCenter,
          r * 1.1,
          [
            AppColors.live.withOpacity(glow * 0.55),
            AppColors.live.withOpacity(0),
          ],
          [0, 1],
        ),
    );
  }

  void _paintStars(Canvas canvas, Size size, double global) {
    final baseAlpha = 0.55 * global;
    final bright = <Offset>[];
    final dim = <Offset>[];
    for (var i = 0; i < _kStarCount; i++) {
      final tw = 0.5 + 0.5 * math.sin(ambient * 2 * math.pi + starPhase[i]);
      (tw > 0.5 ? bright : dim)
          .add(Offset(starX[i] * size.width, starY[i] * size.height));
    }
    final p = Paint()
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(baseAlpha)
      ..strokeWidth = 1.6;
    canvas.drawPoints(ui.PointMode.points, bright, p);
    p
      ..strokeWidth = 1.1
      ..color = Colors.white.withOpacity(baseAlpha * 0.55);
    canvas.drawPoints(ui.PointMode.points, dim, p);
  }

  void _paintGlobe(
      Canvas canvas, double cx, double cy, double radius, double global) {
    final reveal = Curves.easeOut.transform(_interval(0.05, 0.40, intro));
    if (reveal <= 0) return;

    final angle = ambient * 2 * math.pi;
    final ca = math.cos(angle);
    final sa = math.sin(angle);
    const tilt = 0.42;
    final ct = math.cos(tilt);
    final st = math.sin(tilt);

    final buckets = List.generate(4, (_) => <Offset>[]);
    for (var i = 0; i < _kGlobePoints; i++) {
      final x1 = px[i] * ca + pz[i] * sa;
      final z1 = -px[i] * sa + pz[i] * ca;
      final y1 = py[i] * ct - z1 * st;
      final z2 = py[i] * st + z1 * ct;
      final local = ((reveal * 1.15 - latT[i] * 0.9) / 0.12).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final depth = (z2 + 1) / 2;
      buckets[(depth * 3.999).floor()]
          .add(Offset(cx + radius * x1, cy - radius * y1));
    }

    const colors = [
      Color(0xFF7C3AED),
      Color(0xFF8B5CF6),
      Color(0xFF67E8F9),
      Color(0xFF22D3EE),
    ];
    const alphas = [0.14, 0.30, 0.55, 0.85];
    const sizes = [1.0, 1.4, 1.9, 2.5];
    for (var b = 0; b < 4; b++) {
      if (buckets[b].isEmpty) continue;
      canvas.drawPoints(
        ui.PointMode.points,
        buckets[b],
        Paint()
          ..color = colors[b]
              .withOpacity((alphas[b] * global * reveal).clamp(0.0, 1.0))
          ..strokeWidth = sizes[b]
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintRings(
      Canvas canvas, double cx, double cy, double radius, double global) {
    final ringT = Curves.easeOut.transform(_interval(0.15, 0.35, intro));
    if (ringT <= 0) return;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withOpacity(0.10 * global);
    final sweep = ringT * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -math.pi / 2,
      sweep,
      false,
      p,
    );
    for (final w in [0.35, 0.75]) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: 2 * radius * w,
          height: 2 * radius,
        ),
        -math.pi / 2,
        sweep,
        false,
        p,
      );
    }
    for (final lat in [0.0, 0.5, -0.5]) {
      final ry = radius * math.sin(lat * 1.2);
      final rw = radius * math.cos(lat * 1.2);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx, cy - ry),
          width: 2 * rw,
          height: 2 * rw * 0.28,
        ),
        0,
        ringT * 2 * math.pi,
        false,
        p,
      );
    }
  }

  static double _interval(double begin, double end, double t) {
    if (t <= begin) return 0;
    if (t >= end) return 1;
    return (t - begin) / (end - begin);
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) =>
      oldDelegate.intro != intro || oldDelegate.ambient != ambient;
}

class _WirePainter extends CustomPainter {
  _WirePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.5;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..strokeWidth = 1.5
        ..color = AppColors.live.withOpacity(0.16),
    );
    if (progress <= 0) return;
    final path = Path()
      ..moveTo(0, y)
      ..lineTo(size.width, y);
    final metric = path.computeMetrics(forceClosed: false).first;
    final partial = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(
      partial,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.live.withOpacity(0.9),
    );
    final tip =
        metric.getTangentForOffset(metric.length * progress)?.position;
    if (tip != null) {
      canvas.drawCircle(tip, 2.2, Paint()..color = AppColors.live);
    }
  }

  @override
  bool shouldRepaint(_WirePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
