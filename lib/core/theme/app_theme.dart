import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark(useMaterial3: true);

    return baseTheme.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: AppColors.background,
        onSurface: AppColors.text,
      ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          color: AppColors.text,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        titleLarge: GoogleFonts.inter(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: 0.15,
        ),
        titleMedium: GoogleFonts.inter(
          color: AppColors.text,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.15,
        ),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.text,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.inter(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        iconTheme: IconThemeData(color: AppColors.text),
      ),
    );
  }
}
