import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../shared/widgets/kaand_lottie.dart';
import '../onboarding/onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  
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
      duration: const Duration(milliseconds: 2800),
    );

    // 0-300ms: Fade in background (0.0 to 0.107 relative time)
    _backgroundOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.107, curve: Curves.easeOut),
      ),
    );

    // 300-1200ms: Logo Scale & Opacity (0.107 to 0.428 relative time)
    _logoScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.107, 0.428, curve: Curves.easeOutCubic),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.107, 0.428, curve: Curves.easeOut),
      ),
    );

    // 1200-1800ms: Ambient glow expands (0.428 to 0.643 relative time)
    _glowScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.428, 0.643, curve: Curves.easeOutBack),
      ),
    );
    _glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.428, 0.643, curve: Curves.easeOut),
      ),
    );

    // 1800-2300ms: Small floating particles appear (0.643 to 0.821 relative time)
    _particlesOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.643, 0.821, curve: Curves.easeOut),
      ),
    );
    
    // Animate a subtle float translation for particles (from 1800ms to 2800ms)
    _particlesTranslation = Tween<double>(begin: 10.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.643, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // 2300-2800ms: Loading animation plays (0.821 to 1.0 relative time)
    _loadingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.821, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start the animation sequence
    _controller.forward();

    // Trigger transition when completed
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToWelcome();
      }
    });
  }

  void _navigateToWelcome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const OnboardingPage(),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: SafeArea(
          child: Stack(
            children: [
              // Cinematic Branding Section in the Center
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Staggered Ambient Glow and Logo
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft Ambient Glow behind the logo
                        FadeTransition(
                          opacity: _glowOpacity,
                          child: ScaleTransition(
                            scale: _glowScale,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF8B2FC9).withValues(alpha: 0.35),
                                    const Color(0xFF06B6D4).withValues(alpha: 0.15),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Floating Particles (Rendered in logo area)
                        FadeTransition(
                          opacity: _particlesOpacity,
                          child: AnimatedBuilder(
                            animation: _particlesTranslation,
                            builder: (context, child) {
                              final offset = _particlesTranslation.value;
                              return SizedBox(
                                width: 220,
                                height: 220,
                                child: Stack(
                                  children: [
                                    // Top Left Particle
                                    Positioned(
                                      left: 30 - offset,
                                      top: 30 - offset,
                                      child: _buildParticle(4.0, const Color(0xFF06B6D4)),
                                    ),
                                    // Top Right Particle
                                    Positioned(
                                      right: 35 - offset,
                                      top: 50 + offset,
                                      child: _buildParticle(3.0, const Color(0xFF8B2FC9)),
                                    ),
                                    // Bottom Left Particle
                                    Positioned(
                                      left: 45 + offset,
                                      bottom: 40 - offset,
                                      child: _buildParticle(5.0, const Color(0xFF8B2FC9)),
                                    ),
                                    // Bottom Right Particle
                                    Positioned(
                                      right: 40 - offset,
                                      bottom: 30 + offset,
                                      child: _buildParticle(3.5, const Color(0xFF06B6D4)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        // Logo (SVG) and Scale Animation
                        FadeTransition(
                          opacity: _logoOpacity,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: SvgPicture.asset(
                              'assets/logo/kaand_logo.svg',
                              width: 100,
                              height: 100,
                              semanticsLabel: 'KAAND Logo',
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
                        textAlign: TextAlign.center,
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
              // Bottom Loading animation (Powered by Lottie)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _loadingOpacity,
                  child: const Column(
                    children: [
                      KaandLottie(
                        assetPath: 'assets/animations/loading.json',
                        width: 45,
                        height: 45,
                        loop: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
