import 'package:flutter/material.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/kaand_lottie.dart';
import 'username_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Staggered Animations
  late final Animation<double> _backgroundOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  
  late final Animation<double> _headlineOpacity;
  late final Animation<double> _headlineTranslation;
  
  late final Animation<double> _descOpacity;
  
  late final Animation<double> _card1Opacity;
  late final Animation<double> _card1Translation;
  late final Animation<double> _card2Opacity;
  late final Animation<double> _card2Translation;
  late final Animation<double> _card3Opacity;
  late final Animation<double> _card3Translation;
  
  late final Animation<double> _buttonOpacity;
  late final Animation<double> _buttonTranslation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // 0-500ms: Background ambient particles begin (0.0 to 0.208 relative)
    _backgroundOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.208, curve: Curves.easeOut),
      ),
    );

    // 300-900ms: Logo Intro scales and fades in (0.125 to 0.375 relative)
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.125, 0.375, curve: Curves.easeOutCubic),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.125, 0.375, curve: Curves.easeOut),
      ),
    );

    // 700-1300ms: Headline slides upward & fades (0.292 to 0.542 relative)
    _headlineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.292, 0.542, curve: Curves.easeOut),
      ),
    );
    _headlineTranslation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.292, 0.542, curve: Curves.easeOutCubic),
      ),
    );

    // 1000-1600ms: Description appears (0.417 to 0.667 relative)
    _descOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.417, 0.667, curve: Curves.easeOut),
      ),
    );

    // 1400-2100ms: Cards cascade animation
    // Card 1: 1400ms - 1900ms (0.583 to 0.792 relative)
    _card1Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.583, 0.792, curve: Curves.easeOut),
      ),
    );
    _card1Translation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.583, 0.792, curve: Curves.easeOutCubic),
      ),
    );

    // Card 2: 1500ms - 2000ms (0.625 to 0.833 relative)
    _card2Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.625, 0.833, curve: Curves.easeOut),
      ),
    );
    _card2Translation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.625, 0.833, curve: Curves.easeOutCubic),
      ),
    );

    // Card 3: 1600ms - 2100ms (0.667 to 0.875 relative)
    _card3Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.667, 0.875, curve: Curves.easeOut),
      ),
    );
    _card3Translation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.667, 0.875, curve: Curves.easeOutCubic),
      ),
    );

    // 2000-2400ms: Get Started button slides up and fades (0.833 to 1.0 relative)
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.833, 1.0, curve: Curves.easeOut),
      ),
    );
    _buttonTranslation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.833, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Start sequence
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Animated Ambient Particles Background Layer
          FadeTransition(
            opacity: _backgroundOpacity,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A0010), Color(0xFF0D0025)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Opacity(
                opacity: 0.4,
                child: KaandLottie(
                  assetPath: 'assets/animations/ambient_particles.json',
                  loop: true,
                ),
              ),
            ),
          ),

          // 2. Scrollable Onboarding Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // A. Centered Header (Animated Logo & Text)
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Column(
                        children: [
                          const KaandLottie(
                            assetPath: 'assets/animations/logo_intro.json',
                            width: 85,
                            height: 85,
                            loop: false,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'KAAND',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE2D9F3),
                              letterSpacing: 4.0,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF8B2FC9).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // B. Headline
                  AnimatedBuilder(
                    animation: _headlineTranslation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _headlineTranslation.value),
                        child: FadeTransition(
                          opacity: _headlineOpacity,
                          child: child,
                        ),
                      );
                    },
                    child: const Text(
                      'The Future of News Starts Here',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // C. Description Text
                  FadeTransition(
                    opacity: _descOpacity,
                    child: const Text(
                      'Discover breaking news, personalized updates, and AI-powered insights from trusted sources around the world.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFB8B3C7),
                        height: 1.45,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // D. Feature Highlights (Cascading Glass Cards arranged horizontally)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildCascadingCard(
                          opacity: _card1Opacity,
                          translation: _card1Translation,
                          icon: '📰',
                          title: 'Breaking News',
                          description: 'Stay updated with real-time headlines.',
                          indicatorColor: const Color(0xFF8B2FC9),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCascadingCard(
                          opacity: _card2Opacity,
                          translation: _card2Translation,
                          icon: '🤖',
                          title: 'AI Insights',
                          description: 'Get concise AI summaries and takeaways.',
                          indicatorColor: const Color(0xFF8B2FC9),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCascadingCard(
                          opacity: _card3Opacity,
                          translation: _card3Translation,
                          icon: '🌍',
                          title: 'Global Coverage',
                          description: 'Follow trusted news from the world.',
                          indicatorColor: const Color(0xFF06B6D4),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // E. Bottom CTA Action
                  AnimatedBuilder(
                    animation: _buttonTranslation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _buttonTranslation.value),
                        child: FadeTransition(
                          opacity: _buttonOpacity,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Pill-shaped gradient action button
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B2FC9), Color(0xFF06B6D4)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B2FC9).withValues(alpha: 0.3),
                                blurRadius: 16,
                                spreadRadius: 1,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _navigateToUsernamePage,
                              borderRadius: BorderRadius.circular(28),
                              child: const Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Positioned(
                                    right: 24,
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Secondary Text
                        const Text(
                          'Your news. Your perspective.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xB29B8BB4), // Hex with 70% opacity
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCascadingCard({
    required Animation<double> opacity,
    required Animation<double> translation,
    required String icon,
    required String title,
    required String description,
    required Color indicatorColor,
  }) {
    return AnimatedBuilder(
      animation: translation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, translation.value),
          child: FadeTransition(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: GlassCard(
        enableBlur: true,
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
        glowColor: const Color(0xFF8B2FC9).withValues(alpha: 0.08),
        child: SizedBox(
          height: 215, // Uniform height across horizontal columns
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Icon Circle container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827).withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF8B2FC9).withValues(alpha: 0.25),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              // 2. Text elements
              Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9B8BB4),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
              // 3. Colored accent bottom bar
              Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: indicatorColor.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToUsernamePage() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const UsernamePage(),
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
}
