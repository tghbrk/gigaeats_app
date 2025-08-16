import 'package:flutter/material.dart';

/// GigaEats Design System Elevation Tokens
/// 
/// Provides consistent elevation values and shadow styles
/// following Material Design 3 elevation guidelines.
class GEElevation {
  // Elevation levels (dp)
  static const double level0 = 0.0;   // Surface level
  static const double level1 = 1.0;   // Raised elements
  static const double level2 = 3.0;   // Cards, buttons
  static const double level3 = 6.0;   // FAB, snackbar
  static const double level4 = 8.0;   // Navigation drawer
  static const double level5 = 12.0;  // Modal bottom sheet
  static const double level6 = 16.0;  // Navigation rail
  static const double level7 = 24.0;  // Dialog, menu
  
  // Shadow colors
  static const Color shadowColor = Color(0x1A000000);
  static const Color shadowColorDark = Color(0x3D000000);
  
  // Box shadows for different elevation levels
  static const List<BoxShadow> shadow1 = [
    BoxShadow(
      color: shadowColor,
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> shadow2 = [
    BoxShadow(
      color: shadowColor,
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowColor,
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> shadow3 = [
    BoxShadow(
      color: shadowColor,
      offset: Offset(0, 3),
      blurRadius: 6,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowColor,
      offset: Offset(0, 6),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> shadow4 = [
    BoxShadow(
      color: shadowColor,
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowColor,
      offset: Offset(0, 8),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> shadow5 = [
    BoxShadow(
      color: shadowColor,
      offset: Offset(0, 6),
      blurRadius: 12,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowColor,
      offset: Offset(0, 12),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> shadow6 = [
    BoxShadow(
      color: shadowColor,
      offset: Offset(0, 8),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowColor,
      offset: Offset(0, 16),
      blurRadius: 32,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> shadow7 = [
    BoxShadow(
      color: shadowColor,
      offset: Offset(0, 12),
      blurRadius: 24,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowColor,
      offset: Offset(0, 24),
      blurRadius: 48,
      spreadRadius: 0,
    ),
  ];
  
  // Dark theme shadows
  static const List<BoxShadow> shadowDark1 = [
    BoxShadow(
      color: shadowColorDark,
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> shadowDark2 = [
    BoxShadow(
      color: shadowColorDark,
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowColorDark,
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> shadowDark3 = [
    BoxShadow(
      color: shadowColorDark,
      offset: Offset(0, 3),
      blurRadius: 6,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowColorDark,
      offset: Offset(0, 6),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];
  
  // Helper method to get shadows based on elevation level
  static List<BoxShadow> getShadow(double elevation, {bool isDark = false}) {
    if (isDark) {
      switch (elevation) {
        case level1:
          return shadowDark1;
        case level2:
          return shadowDark2;
        case level3:
          return shadowDark3;
        default:
          return shadowDark2;
      }
    }
    
    switch (elevation) {
      case level0:
        return [];
      case level1:
        return shadow1;
      case level2:
        return shadow2;
      case level3:
        return shadow3;
      case level4:
        return shadow4;
      case level5:
        return shadow5;
      case level6:
        return shadow6;
      case level7:
        return shadow7;
      default:
        return shadow2;
    }
  }
  
  // Semantic elevation mappings
  static const double card = level2;
  static const double button = level2;
  static const double fab = level3;
  static const double appBar = level0;
  static const double bottomNavigation = level3;
  static const double drawer = level4;
  static const double modal = level5;
  static const double dialog = level7;
  static const double snackbar = level3;
  static const double tooltip = level7;
}

/// Elevation helper for creating elevated containers
class GEElevatedContainer extends StatelessWidget {
  final Widget child;
  final double elevation;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  
  const GEElevatedContainer({
    super.key,
    required this.child,
    this.elevation = GEElevation.level2,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: GEElevation.getShadow(elevation, isDark: isDark),
      ),
      child: child,
    );
  }
}
