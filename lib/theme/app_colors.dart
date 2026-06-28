import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color background = Color(0xFF09090B); // Obsidian Black
  static const Color surface = Color(0xFF111218); // Graphite
  static const Color secondarySurface = Color(0xFF171923); // Dark Slate
  static const Color elevatedCard = Color(0xFF1D2030); // Glass Black
  static const Color divider = Color(0xFF2A2E3D); // Soft Border

  // Accent Colors
  static const Color primaryAccent = Color(0xFF7C3AED); // Electric Violet
  static const Color secondaryAccent = Color(0xFF8B5CF6); // Royal Purple
  static const Color highlight = Color(0xFF22D3EE); // Neon Cyan
  static const Color interactive = Color(0xFF4F46E5); // Indigo Blue
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Rose Red
  static const Color info = Color(0xFF3B82F6); // Info Blue

  // Typography
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFC7CDD8);
  static const Color mutedText = Color(0xFF9CA3AF);
  static const Color disabledText = Color(0xFF6B7280);

  // Category glow colors
  static const Color catWorld = Color(0xFF22D3EE); // Cyan
  static const Color catIndia = Color(0xFFF59E0B); // Orange/Amber
  static const Color catTech = Color(0xFF34D399); // Teal
  static const Color catBusiness = Color(0xFFA78BFA); // Lavender/Purple
  static const Color catSports = Color(0xFF3B82F6); // Blue
  static const Color catEntertainment = Color(0xFFF472B6); // Pink
  static const Color catScience = Color(0xFF6EE7B7); // Light Green
  static const Color catHealth = Color(0xFFF87171); // Rose/Red

  // Gradient System
  static const List<Color> primaryGradient = [
    Color(0xFF7C3AED),
    Color(0xFF4F46E5),
    Color(0xFF22D3EE),
  ];

  static const List<Color> heroGradient = [
    Color(0xFF9333EA),
    Color(0xFF7C3AED),
    Color(0xFF3B82F6),
  ];

  // Glass Glow Colors
  static const Color glassGlowViolet = Color(0x597C3AED); // rgba(124,58,237,0.35)
  static const Color glassGlowCyan = Color(0x3322D3EE); // rgba(34,211,238,0.20)

  // Glass Effects
  static const Color glassBackground = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const Color glassBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const double glassBlur = 24.0;
  static const BoxShadow glassShadow = BoxShadow(
    color: Color(0x73000000), // rgba(0,0,0,0.45)
    offset: Offset(0, 20),
    blurRadius: 60,
  );

  // Button Colors
  static const Color btnPrimaryBackground = Color(0xFF7C3AED);
  static const Color btnPrimaryHover = Color(0xFF8B5CF6);
  static const Color btnSecondaryBackground = Color(0xFF1D2030);
  static const Color btnSecondaryBorder = Color(0xFF2A2E3D);
  static const Color btnGhostHover = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
}
