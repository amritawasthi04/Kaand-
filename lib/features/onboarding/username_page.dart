import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/routes/app_routes.dart';
import '../../shared/widgets/kaand_lottie.dart';

class UsernamePage extends StatefulWidget {
  const UsernamePage({super.key});

  @override
  State<UsernamePage> createState() => _UsernamePageState();
}

class _UsernamePageState extends State<UsernamePage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Inputs & Validation States
  bool _isFocused = false;
  bool _isValid = false;
  bool _showError = false;

  // Staggered Animations
  late final Animation<double> _backgroundOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  
  late final Animation<double> _titleOpacity;
  
  late final Animation<double> _descOpacity;
  late final Animation<double> _descTranslation;
  
  late final Animation<double> _inputOpacity;
  late final Animation<double> _inputTranslation;
  
  late final Animation<double> _actionsOpacity;
  late final Animation<double> _actionsTranslation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );

    // Focus listener to handle glassmorphism outline glow animation dynamically
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        if (!_isFocused) {
          _validateName(showErrorOnFail: true);
        }
      });
    });

    // 0-500ms: Background ambient particles (0.0 to 0.217 relative)
    _backgroundOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.217, curve: Curves.easeOut),
      ),
    );

    // 300-900ms: Logo Intro fades and scales in (0.130 to 0.391 relative)
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.130, 0.391, curve: Curves.easeOutCubic),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.130, 0.391, curve: Curves.easeOut),
      ),
    );

    // 700-1200ms: Title appears (0.304 to 0.522 relative)
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.304, 0.522, curve: Curves.easeOut),
      ),
    );

    // 1000-1500ms: Description fades upward (0.435 to 0.652 relative)
    _descOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.435, 0.652, curve: Curves.easeOut),
      ),
    );
    _descTranslation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.435, 0.652, curve: Curves.easeOutCubic),
      ),
    );

    // 1400-1900ms: Name input slides upward (0.609 to 0.826 relative)
    _inputOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.609, 0.826, curve: Curves.easeOut),
      ),
    );
    _inputTranslation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.609, 0.826, curve: Curves.easeOutCubic),
      ),
    );

    // 1800-2300ms: Continue CTA and Skip option fade in (0.783 to 1.0 relative)
    _actionsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.783, 1.0, curve: Curves.easeOut),
      ),
    );
    _actionsTranslation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.783, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _validateName({required bool showErrorOnFail}) {
    final text = _nameController.text.trim();
    setState(() {
      _isValid = text.isNotEmpty && text.length >= 2 && text.length <= 30;
      if (showErrorOnFail) {
        _showError = !_isValid && text.isNotEmpty;
      } else {
        _showError = false;
      }
    });
  }

  Future<void> _submitName() async {
    if (!_isValid) return;

    // Trigger soft haptic feedback on successful submit
    await HapticFeedback.lightImpact();

    final name = _nameController.text.trim();
    final box = Hive.box('settings');
    await box.put('userName', name);
    await box.put('hasCompletedOnboarding', true);
    await box.put('firstLaunch', false);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  Future<void> _skipOnboarding() async {
    await HapticFeedback.lightImpact();

    final box = Hive.box('settings');
    await box.put('userName', 'Reader');
    await box.put('hasCompletedOnboarding', true);
    await box.put('firstLaunch', false);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
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

          // 2. Scrollable content to handle keyboard transitions safely
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // A. Centered Logo Header
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

                  const SizedBox(height: 32),

                  // B. Title Block
                  FadeTransition(
                    opacity: _titleOpacity,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(text: 'Welcome to '),
                          TextSpan(
                            text: 'KAAND',
                            style: TextStyle(
                              color: Color(0xFFE2D9F3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // C. Description Block
                  AnimatedBuilder(
                    animation: _descTranslation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _descTranslation.value),
                        child: FadeTransition(
                          opacity: _descOpacity,
                          child: child,
                        ),
                      );
                    },
                    child: const Text(
                      "Let's personalize your experience.\nTell us what you'd like us to call you.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9B8BB4),
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // D. Decorative Sparkling Divider
                  FadeTransition(
                    opacity: _descOpacity,
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: const Color(0xFF8B2FC9).withValues(alpha: 0.25),
                            endIndent: 12,
                            thickness: 1,
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFF8B2FC9),
                          size: 16,
                        ),
                        Expanded(
                          child: Divider(
                            color: const Color(0xFF8B2FC9).withValues(alpha: 0.25),
                            indent: 12,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // E. Name Input Box (Slide & Fade)
                  AnimatedBuilder(
                    animation: _inputTranslation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _inputTranslation.value),
                        child: FadeTransition(
                          opacity: _inputOpacity,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                          child: Text(
                            'Your Name',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE2D9F3),
                            ),
                          ),
                        ),

                        // Premium Glassmorphic input field container
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827).withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isFocused
                                  ? const Color(0xFF8B2FC9)
                                  : const Color(0xFFA855F7).withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                            boxShadow: _isFocused
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF8B2FC9).withValues(alpha: 0.25),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: TextFormField(
                            controller: _nameController,
                            focusNode: _focusNode,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            maxLength: 30,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(30),
                              // Prevent emojis and special characters, keep alphabetical and whitespace characters
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                            ],
                            onChanged: (text) => _validateName(showErrorOnFail: false),
                            decoration: const InputDecoration(
                              counterText: '',
                              hintText: 'Enter your name',
                              hintStyle: TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0x669B8BB4),
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: Color(0xFF9B8BB4),
                                size: 24,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),

                        // Real-time validation warning message
                        if (_showError)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0, left: 4.0),
                            child: Text(
                              'Preferred name must be between 2 and 30 characters.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0),
                          child: Text(
                            'This will help us personalize your news experience.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: Color(0xFF9B8BB4),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // F. Bottom Action Items (Submit/Skip)
                  AnimatedBuilder(
                    animation: _actionsTranslation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _actionsTranslation.value),
                        child: FadeTransition(
                          opacity: _actionsOpacity,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Dynamic Gradient Continue Button
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: _isValid ? 1.0 : 0.4,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B2FC9), Color(0xFF06B6D4)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: _isValid
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF8B2FC9).withValues(alpha: 0.3),
                                        blurRadius: 16,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isValid ? _submitName : null,
                                borderRadius: BorderRadius.circular(28),
                                child: const Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text(
                                      'Continue',
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
                        ),

                        const SizedBox(height: 24),

                        // OR divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: const Color(0xFF9B8BB4).withValues(alpha: 0.15),
                                endIndent: 12,
                              ),
                            ),
                            const Text(
                              'or',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Color(0x779B8BB4),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: const Color(0xFF9B8BB4).withValues(alpha: 0.15),
                                indent: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Skip option
                        Center(
                          child: InkWell(
                            onTap: _skipOnboarding,
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Text(
                                'Skip for now',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF9B8BB4),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Footer Privacy Info Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF111827).withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                color: Color(0xFF9B8BB4),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'Your data stays private and is stored securely\non your device.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xCC9B8BB4),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
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
}
