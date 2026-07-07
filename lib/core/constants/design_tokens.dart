import 'package:flutter/material.dart';

class DesignTokens {
  DesignTokens._();

  // Spacing & Grid (8pt Grid System)
  static const double spaceXXS = 4.0;
  static const double spaceXS = 8.0;
  static const double spaceS = 12.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // Border Radii
  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;
  static const double radiusCircular = 999.0;

  // Backdrop Blurs
  static const double blurGlass = 16.0;
  static const double blurGlow = 24.0;

  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 400);
  static const Duration durationSlow = Duration(milliseconds: 800);

  // Animation Curves
  static const Curve curveDefault = Curves.easeInOutCubic;
  static const Curve curveSpring = Curves.easeOutBack;

  // Shadows and Glows
  static const List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: Color(0x3D8B2FC9), // 24% opacity primary
      blurRadius: 16.0,
      spreadRadius: 2.0,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> accentGlow = [
    BoxShadow(
      color: Color(0x3D06B6D4), // 24% opacity accent
      blurRadius: 16.0,
      spreadRadius: 2.0,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1F000000), // Very subtle black shadow
      blurRadius: 10.0,
      spreadRadius: 0.0,
      offset: Offset(0, 4),
    ),
  ];

  // Elevation
  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 6.0;
  static const double elevationHigh = 12.0;
}
