import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../core/responsive.dart';
import '../models/article.dart';

class BreakingNewsPill extends StatefulWidget {
  final List<Article> breakingArticles;
  final VoidCallback? onDismiss;
  final VoidCallback? onTapArticle;
  final Duration autoDismissDuration;

  const BreakingNewsPill({
    super.key,
    required this.breakingArticles,
    this.onDismiss,
    this.onTapArticle,
    this.autoDismissDuration = const Duration(seconds: 8),
  });

  @override
  State<BreakingNewsPill> createState() => _BreakingNewsPillState();
}

class _BreakingNewsPillState extends State<BreakingNewsPill> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  int _currentIndex = 0;
  Timer? _rotationTimer;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
    _startRotation();
    _startAutoDismiss();
  }

  void _startRotation() {
    if (widget.breakingArticles.length <= 1) return;
    
    _rotationTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.breakingArticles.length;
      });
    });
  }

  void _startAutoDismiss() {
    _autoDismissTimer = Timer(widget.autoDismissDuration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _rotationTimer?.cancel();
    _autoDismissTimer?.cancel();
    _slideController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _autoDismissTimer?.cancel();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.breakingArticles.isEmpty) return const SizedBox.shrink();

    final article = widget.breakingArticles[_currentIndex];

    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _dismiss();
            widget.onTapArticle?.call();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.brand.withOpacity(0.95),
                  AppColors.brand.withOpacity(0.8),
                  AppColors.onboardingPrimary.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.live.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breaking Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.live,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) => Opacity(
                          opacity: 0.5 + (_pulseController.value * 0.5),
                          child: const Icon(
                            Icons.fiber_manual_record_rounded,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'BREAKING',
                        style: AppFonts.sg(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Article Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        article.title,
                        style: AppFonts.sg(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (article.sourceName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          article.sourceName!,
                          style: AppFonts.sg(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Dismiss Button
                IconButton(
                  onPressed: _dismiss,
                  icon: Icon(Icons.close_rounded, size: 20, color: Colors.white70),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Overlay manager for showing breaking news pills
class BreakingNewsOverlay {
  static OverlayEntry? _currentEntry;
  static final List<Article> _pendingArticles = [];
  static bool _isShowing = false;

  static void show({
    required BuildContext context,
    required List<Article> articles,
    Duration duration = const Duration(seconds: 8),
    VoidCallback? onTapArticle,
  }) {
    _pendingArticles.addAll(articles);
    _showNext(context, duration: duration, onTapArticle: onTapArticle);
  }

  static void _showNext(BuildContext context, {required Duration duration, VoidCallback? onTapArticle}) {
    if (_pendingArticles.isEmpty || _isShowing) return;
    
    _isShowing = true;
    final article = _pendingArticles.removeAt(0);
    
    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        child: SafeArea(
          bottom: false,
          child: BreakingNewsPill(
            breakingArticles: [article],
            autoDismissDuration: duration,
            onDismiss: () {
              _isShowing = false;
              _currentEntry?.remove();
              _currentEntry = null;
              _showNext(context, duration: duration, onTapArticle: onTapArticle);
            },
            onTapArticle: onTapArticle,
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_currentEntry!);
  }

  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
    _isShowing = false;
    _pendingArticles.clear();
  }
}