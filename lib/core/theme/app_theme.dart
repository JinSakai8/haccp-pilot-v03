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
}
