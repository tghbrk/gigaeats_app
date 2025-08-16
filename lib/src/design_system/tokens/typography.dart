import 'package:flutter/material.dart';

/// GigaEats Design System Typography Tokens
/// 
/// Provides consistent typography scales, font weights, and text styles
/// following Material Design 3 typography guidelines with GigaEats branding.
class GETypography {
  // Font families
  static const String primaryFont = 'Inter';
  static const String displayFont = 'Inter';
  static const String monoFont = 'JetBrains Mono';
  
  // Font weights
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
  
  // Font sizes - following 8pt grid system
  static const double xs = 10.0;    // Extra small
  static const double sm = 12.0;    // Small
  static const double base = 14.0;  // Base size
  static const double lg = 16.0;    // Large
  static const double xl = 18.0;    // Extra large
  static const double xxl = 20.0;   // 2X large
  static const double xxxl = 24.0;  // 3X large
  static const double xxxxl = 28.0; // 4X large
  static const double xxxxxl = 32.0; // 5X large
  static const double xxxxxxl = 36.0; // 6X large
  
  // Line heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;
  static const double lineHeightLoose = 1.8;
  
  // Letter spacing
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;
  static const double letterSpacingWider = 1.0;
  
  // Text styles for common use cases
  static const TextStyle displayLarge = TextStyle(
    fontFamily: displayFont,
    fontSize: xxxxxxl,
    fontWeight: bold,
    letterSpacing: letterSpacingTight,
    height: lineHeightTight,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontFamily: displayFont,
    fontSize: xxxxxl,
    fontWeight: bold,
    letterSpacing: letterSpacingTight,
    height: lineHeightTight,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontFamily: displayFont,
    fontSize: xxxxl,
    fontWeight: bold,
    letterSpacing: letterSpacingNormal,
    height: lineHeightTight,
  );
  
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: xxxl,
    fontWeight: semiBold,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: xxl,
    fontWeight: semiBold,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: xl,
    fontWeight: semiBold,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: lg,
    fontWeight: medium,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: base,
    fontWeight: medium,
    letterSpacing: letterSpacingWide,
    height: lineHeightNormal,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: sm,
    fontWeight: medium,
    letterSpacing: letterSpacingWide,
    height: lineHeightNormal,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: lg,
    fontWeight: regular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightRelaxed,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: base,
    fontWeight: regular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightRelaxed,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: sm,
    fontWeight: regular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightRelaxed,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: base,
    fontWeight: medium,
    letterSpacing: letterSpacingWide,
    height: lineHeightNormal,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: sm,
    fontWeight: medium,
    letterSpacing: letterSpacingWide,
    height: lineHeightNormal,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: xs,
    fontWeight: medium,
    letterSpacing: letterSpacingWider,
    height: lineHeightNormal,
  );
  
  // Specialized text styles
  static const TextStyle caption = TextStyle(
    fontFamily: primaryFont,
    fontSize: xs,
    fontWeight: regular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );
  
  static const TextStyle overline = TextStyle(
    fontFamily: primaryFont,
    fontSize: xs,
    fontWeight: medium,
    letterSpacing: letterSpacingWider,
    height: lineHeightNormal,
  );
  
  static const TextStyle button = TextStyle(
    fontFamily: primaryFont,
    fontSize: base,
    fontWeight: medium,
    letterSpacing: letterSpacingWide,
    height: lineHeightNormal,
  );
  
  static const TextStyle code = TextStyle(
    fontFamily: monoFont,
    fontSize: sm,
    fontWeight: regular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightRelaxed,
  );
}

/// Typography scale helper for responsive text sizing
class GETypographyScale {
  static double getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Mobile: base size
    if (screenWidth < 600) return baseSize;
    
    // Tablet: slightly larger
    if (screenWidth < 1200) return baseSize * 1.1;
    
    // Desktop: larger
    return baseSize * 1.2;
  }
  
  static TextStyle responsive(BuildContext context, TextStyle baseStyle) {
    final responsiveSize = getResponsiveSize(
      context, 
      baseStyle.fontSize ?? GETypography.base,
    );
    
    return baseStyle.copyWith(fontSize: responsiveSize);
  }
}
