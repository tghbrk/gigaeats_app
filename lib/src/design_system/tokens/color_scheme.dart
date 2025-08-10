import 'package:flutter/material.dart';

/// GigaEats Design System Color Palette
/// 
/// Provides Material Design 3 color schemes with seed-based generation
/// and semantic color definitions for consistent theming across the app.
class GEPalette {
  // Brand Colors - Malaysian-inspired green palette
  static const Color seed = Color(0xFF1B5E20); // Deep Green (GigaEats primary)
  static const Color gigaGreen = Color(0xFF1B5E20);
  static const Color gigaGreenLight = Color(0xFF2E7D32);
  static const Color gigaOrange = Color(0xFFFF6F00);
  
  // Semantic Colors
  static const Color success = Color(0xFF1DB954); // Spotify green
  static const Color warning = Color(0xFFFFA000); // Amber
  static const Color danger = Color(0xFFD32F2F); // Red
  static const Color info = Color(0xFF1976D2); // Blue
  
  // Neutral Colors
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);
  
  // Role-specific accent colors
  static const Color customerAccent = Color(0xFF00BCD4); // Cyan
  static const Color vendorAccent = Color(0xFF9C27B0); // Purple
  static const Color driverAccent = Color(0xFF2196F3); // Blue
  static const Color salesAgentAccent = Color(0xFFFFC107); // Amber
  static const Color adminAccent = Color(0xFFF44336); // Red
}

/// Builds Material Design 3 light color scheme from seed color
ColorScheme buildLightColorScheme({Color seed = GEPalette.seed}) {
  return ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );
}

/// Builds Material Design 3 dark color scheme from seed color
ColorScheme buildDarkColorScheme({Color seed = GEPalette.seed}) {
  return ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );
}

/// Extended color scheme with semantic colors
class GEColorScheme {
  final ColorScheme base;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  
  const GEColorScheme({
    required this.base,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });
  
  /// Creates light extended color scheme
  factory GEColorScheme.light() {
    return GEColorScheme(
      base: buildLightColorScheme(),
      success: GEPalette.success,
      warning: GEPalette.warning,
      danger: GEPalette.danger,
      info: GEPalette.info,
    );
  }
  
  /// Creates dark extended color scheme
  factory GEColorScheme.dark() {
    return GEColorScheme(
      base: buildDarkColorScheme(),
      success: GEPalette.success,
      warning: GEPalette.warning,
      danger: GEPalette.danger,
      info: GEPalette.info,
    );
  }
}
