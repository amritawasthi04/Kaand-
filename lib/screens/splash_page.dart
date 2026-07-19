import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import '../../shared/widgets/kaand_lottie.dart';
import '../home/main_shell.dart';
import '../onboarding/onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _pulseController;
  bool _isNavigating = false;

  late final Animation<double> _pulseGlowScale;
  late final Animation<double> _pulseLogoScale;
  late final Animation<double> _pulseGlowOpacity;

  // Staggered animation properties
  late final Animation<double> _backgroundOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _glowScale;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _particlesOpacity;
  late final Animation<double> _particlesTranslation;
  late final Animation<double> _loadingOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _pulseGlowScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseLogoScale = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseGlowOpacity = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // 0-300ms: Fade in background (0.0 to 0.06 relative time)
    _backgroundOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.06, curve: Curves.easeOut),
      ),
    );

    // 300-1200ms: Logo Scale & Opacity (0.06 to 0.24 relative time)
    _logoScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.06, 0.24, curve: Curves.easeOutCubic),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.06, 0.24, curve: Curves.easeOut),
      ),
    );

    // 1200-1800ms: Ambient glow expands (0.24 to 0.36 relative time)
    _glowScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.24, 0.36, curve: Curves.easeOutBack),
      ),
    );
    _glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.24, 0.36, curve: Curves.easeOut),
      ),
    );

    // 1800-2300ms: Small floating particles appear (0.36 to 0.46 relative time)
    _particlesOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.36, 0.46, curve: Curves.easeOut),
      ),
    );

    // Animate a subtle float translation for particles (from 1800ms to 5000ms)
    _particlesTranslation = Tween<double>(begin: 10.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.36, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // 800-1600ms: Loading animation plays (0.1 to 0.2 relative time)
    _loadingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.2, curve: Curves.easeIn),
      ),
    );

    // Start the animation sequence
    _controller.forward();

    // Trigger transition when completed (fallback)
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToWelcome();
      }
    });
  }

  void _navigateToWelcome() {
    if (_isNavigating) return;
    _isNavigating = true;

    final box = Hive.box('settings');
    final bool completedOnboarding =
        box.get('hasCompletedOnboarding', defaultValue: false);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            completedOnboarding
                ? const MainShellPage()
                : const OnboardingPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double lottieSize = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _backgroundOpacity.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF140024),
                    Color(0xFF0A0010),
                    Color(0xFF0D0025),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: child,
            ),
          );
        },
        child: Stack(
          children: [
            // Bottom Loading animation (Powered by Lottie) - placed at bottom, edge-to-edge
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _loadingOpacity,
                child: Column(
                  children: [
                    KaandLottie(
                      assetPath: 'assets/animations/Server.json',
                      width: lottieSize,
                      height: lottieSize,
                      loop: false,
                      onComplete: _navigateToWelcome,
                    ),
                  ],
                ),
              ),
            ),
            // Cinematic Branding Section inside SafeArea, shifted to top Center
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 60.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Staggered Ambient Glow and Logo with soft pulsing animation
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft Ambient Glow behind the logo
                          FadeTransition(
                            opacity: _glowOpacity,
                            child: ScaleTransition(
                              scale: _glowScale,
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseGlowScale.value,
                                    child: Opacity(
                                      opacity: _pulseGlowOpacity.value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 240,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFFC084FC)
                                            .withValues(alpha: 0.45),
                                        const Color(0xFF06B6D4)
                                            .withValues(alpha: 0.20),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Floating Particles (Rendered in logo area with continuous floating animation)
                          FadeTransition(
                            opacity: _particlesOpacity,
                            child: AnimatedBuilder(
                              animation: Listenable.merge(
                                  [_particlesTranslation, _pulseController]),
                              builder: (context, child) {
                                final entranceOffset =
                                    _particlesTranslation.value;
                                final double pulseOffset = math.sin(
                                        _pulseController.value *
                                            2 *
                                            math.pi) *
                                    4.0;
                                return SizedBox(
                                  width: 220,
                                  height: 220,
                                  child: Stack(
                                    children: [
                                      // Top Left Particle
                                      Positioned(
                                        left: 30 -
                                            entranceOffset +
                                            pulseOffset * 0.5,
                                        top: 30 -
                                            entranceOffset -
                                            pulseOffset * 0.5,
                                        child: _buildParticle(
                                            4.0, const Color(0xFF06B6D4)),
                                      ),
                                      // Top Right Particle
                                      Positioned(
                                        right: 35 -
                                            entranceOffset -
                                            pulseOffset * 0.4,
                                        top: 50 +
                                            entranceOffset +
                                            pulseOffset * 0.6,
                                        child: _buildParticle(
                                            3.0, const Color(0xFF8B2FC9)),
                                      ),
                                      // Bottom Left Particle
                                      Positioned(
                                        left: 45 +
                                            entranceOffset +
                                            pulseOffset * 0.6,
                                        bottom: 40 -
                                            entranceOffset +
                                            pulseOffset * 0.4,
                                        child: _buildParticle(
                                            5.0, const Color(0xFF8B2FC9)),
                                      ),
                                      // Bottom Right Particle
                                      Positioned(
                                        right: 40 -
                                            entranceOffset -
                                            pulseOffset * 0.5,
                                        bottom: 30 +
                                            entranceOffset -
                                            pulseOffset * 0.5,
                                        child: _buildParticle(
                                            3.5, const Color(0xFF06B6D4)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          // Logo (SVG) with entrance Scale and soft breathing pulse
                          FadeTransition(
                            opacity: _logoOpacity,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: ScaleTransition(
                                scale: _pulseLogoScale,
                                child: SvgPicture.asset(
                                  'assets/logo/kaand_logo.svg',
                                  width: 100,
                                  height: 100,
                                  semanticsLabel: 'KAAND Logo',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // App Name
                      FadeTransition(
                        opacity: _logoOpacity,
                        child: const Text(
                          'KAAND',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE2D9F3),
                            letterSpacing: 4.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Tagline
                      FadeTransition(
                        opacity: _logoOpacity,
                        child: const Text(
                          'Stay Connected.\nStay Informed.',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF9B8BB4),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
    );
  }
}
