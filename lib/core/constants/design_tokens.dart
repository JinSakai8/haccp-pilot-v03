import 'package:flutter/material.dart';

class HaccpDesignTokens {
  // Colors (Dark Mode)
  static const Color background = Color(0xFF121212); // Onyx/Charcoal
  static const Color surface = Color(0xFF1E1E1E);
  static const Color primary = Color(0xFFD2661E); // Copper/Orange
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFF9A825);
  static const Color onBackground = Colors.white;
  static const Color onSurface = Colors.white70;
  static const Color textPrimary = onBackground;

  // Dimensions (Glove-Friendly)
  static const double minTouchTarget = 60.0; 
  static const double standardPadding = 16.0;
  static const double cardRadius = 8.0;

  // Typography
  static const String fontFamily = 'Work Sans';
}

/// Compatibility layer for legacy DesignTokens usage
class DesignTokens {
  static const Color background = HaccpDesignTokens.background;
  static const Color backgroundColor = HaccpDesignTokens.background;
  static const Color surface = HaccpDesignTokens.surface;
  static const Color primaryColor = HaccpDesignTokens.primary;
  static const Color successColor = HaccpDesignTokens.success;
  static const Color errorColor = HaccpDesignTokens.error;
  static const Color warningColor = HaccpDesignTokens.warning;
  static const Color accentColor = HaccpDesignTokens.primary; // Map accent to primary or separate color
  static const Color onBackground = HaccpDesignTokens.onBackground;
  static const Color onSurface = HaccpDesignTokens.onSurface;
  
  static const double minTouchTarget = HaccpDesignTokens.minTouchTarget;
  static const double standardPadding = HaccpDesignTokens.standardPadding;
  static const double cardRadius = HaccpDesignTokens.cardRadius;
}
