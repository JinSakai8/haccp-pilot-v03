import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/design_tokens.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: HaccpDesignTokens.primary,
        surface: HaccpDesignTokens.surface,
        error: HaccpDesignTokens.error,
        onPrimary: Colors.white,
        onSurface: HaccpDesignTokens.onSurface,
      ),
      scaffoldBackgroundColor: HaccpDesignTokens.background,
      fontFamily: GoogleFonts.workSans().fontFamily,
      
      // Button Theme for Glove-Friendly targets
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(HaccpDesignTokens.minTouchTarget),
          padding: const EdgeInsets.all(HaccpDesignTokens.standardPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HaccpDesignTokens.cardRadius),
          ),
          backgroundColor: HaccpDesignTokens.primary,
          foregroundColor: Colors.white,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HaccpDesignTokens.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HaccpDesignTokens.cardRadius),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(HaccpDesignTokens.standardPadding),
      ),
    );
  }

  // Static colors for direct usage
  static const Color primary = HaccpDesignTokens.primary;
  static const Color surface = HaccpDesignTokens.surface;
  static const Color background = HaccpDesignTokens.background;
  static const Color error = HaccpDesignTokens.error;
  static const Color onPrimary = Colors.white;
  static const Color onSurface = HaccpDesignTokens.onSurface;
  // onSurfaceVariant often used for secondary text, map to onSurface with opacity or create tokens
  static const Color onSurfaceVariant = Colors.white60;
  static const Color secondary = HaccpDesignTokens.primary; // Mapped to primary for now
  static const Color onSecondary = Colors.white;
  static const Color outline = Colors.white24;
  static const Color success = HaccpDesignTokens.success;
  static const Color warning = HaccpDesignTokens.warning;
}
