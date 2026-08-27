import 'package:flutter/material.dart';

/// Device tier derived from logical width.
enum ScreenTier { compact, standard, wide }

/// Uniform screen-size helpers. Used instead of sprinkling MediaQuery
/// arithmetic through widgets.
class ScreenSize {
  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double heightOf(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static ScreenTier tierOf(BuildContext context) {
    final w = widthOf(context);
    if (w < 360) return ScreenTier.compact;
    if (w >= 600) return ScreenTier.wide;
    return ScreenTier.standard;
  }

  static bool isCompactWidth(BuildContext context) =>
      tierOf(context) == ScreenTier.compact;

  /// Hero carousel height: a share of screen height, bounded.
  static double heroHeight(BuildContext context) =>
      (heightOf(context) * 0.28).clamp(200.0, 260.0).toDouble();

  /// Trending rail card width: a share of screen width, bounded.
  static double trendingCardWidth(BuildContext context) =>
      (widthOf(context) * 0.46).clamp(146.0, 190.0).toDouble();

  /// Trending rail total height, derived from card width so the whole
  /// section scales as one unit.
  static double trendingRowHeight(BuildContext context) =>
      trendingCardWidth(context) * 0.64 + 118;

  /// Category square chip side length.
  static double chipSide(BuildContext context) =>
      (widthOf(context) * 0.19).clamp(56.0, 68.0).toDouble();

  /// Headline tile thumbnail size.
  static double tileThumb(BuildContext context) =>
      (widthOf(context) * 0.24).clamp(78.0, 90.0).toDouble();

  /// Clamps a logical dimension so it never collapses on small devices
  /// and never balloons on tablets.
  static double clamped(double value, {double min = 0, double max = 1e9}) =>
      value.clamp(min, max);
}

/// Global spacing metrics that depend on device chrome (notches etc.).
class AppSpacing {
  /// Bottom clearance so content never hides behind the floating nav bar.
  static double navClearance(BuildContext context) =>
      110 + MediaQuery.of(context).viewPadding.bottom;

  static const double horizontal = 16.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

/// Brand typography: Space Grotesk only, no runtime font fetches.
/// Drop-in replacement for the old `GoogleFonts.inter(...)` call-sites.
class AppFonts {
  static TextStyle sg({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontStyle: fontStyle,
    );
  }
}
