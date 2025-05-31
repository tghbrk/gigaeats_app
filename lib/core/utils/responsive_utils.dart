import 'package:flutter/material.dart';

/// Responsive breakpoints for different screen sizes
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;
}

/// Responsive utility class for handling different screen sizes
class ResponsiveUtils {
  /// Check if the current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;
  }

  /// Check if the current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.mobile && 
           width < ResponsiveBreakpoints.desktop;
  }

  /// Check if the current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;
  }

  /// Check if the current screen is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.largeDesktop;
  }

  /// Get the number of columns for a grid based on screen size
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    if (isLargeDesktop(context)) return 4;
    return 3; // Desktop
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(16);
    if (isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(32);
  }

  /// Get responsive margin based on screen size
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(8);
    if (isTablet(context)) return const EdgeInsets.all(12);
    return const EdgeInsets.all(16);
  }

  /// Get responsive card width
  static double getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) return screenWidth - 32;
    if (isTablet(context)) return (screenWidth - 64) / 2;
    if (isLargeDesktop(context)) return (screenWidth - 128) / 4;
    return (screenWidth - 96) / 3;
  }

  /// Get responsive font size multiplier
  static double getFontSizeMultiplier(BuildContext context) {
    if (isMobile(context)) return 1.0;
    if (isTablet(context)) return 1.1;
    return 1.2;
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context, {double baseSize = 24}) {
    final multiplier = getFontSizeMultiplier(context);
    return baseSize * multiplier;
  }

  /// Get responsive spacing
  static double getSpacing(BuildContext context, {double baseSpacing = 16}) {
    if (isMobile(context)) return baseSpacing;
    if (isTablet(context)) return baseSpacing * 1.25;
    return baseSpacing * 1.5;
  }

  /// Get maximum content width for centering on large screens
  static double getMaxContentWidth(BuildContext context) {
    if (isLargeDesktop(context)) return 1400;
    if (isDesktop(context)) return 1200;
    return double.infinity;
  }

  /// Get responsive dialog width
  static double getDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) return screenWidth * 0.9;
    if (isTablet(context)) return 500;
    return 600;
  }

  /// Get responsive sidebar width
  static double getSidebarWidth(BuildContext context) {
    if (isMobile(context)) return MediaQuery.of(context).size.width * 0.8;
    if (isTablet(context)) return 300;
    return 350;
  }
}

/// Widget that builds different layouts based on screen size
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (ResponsiveUtils.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

/// Widget that provides responsive layout with max width constraint
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? ResponsiveUtils.getMaxContentWidth(context);
    final effectivePadding = padding ?? ResponsiveUtils.getResponsivePadding(context);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        padding: effectivePadding,
        child: child,
      ),
    );
  }
}

/// Extension methods for responsive design
extension ResponsiveExtension on BuildContext {
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  bool get isLargeDesktop => ResponsiveUtils.isLargeDesktop(this);
  
  int get gridColumns => ResponsiveUtils.getGridColumns(this);
  EdgeInsets get responsivePadding => ResponsiveUtils.getResponsivePadding(this);
  EdgeInsets get responsiveMargin => ResponsiveUtils.getResponsiveMargin(this);
  double get fontSizeMultiplier => ResponsiveUtils.getFontSizeMultiplier(this);
  double get maxContentWidth => ResponsiveUtils.getMaxContentWidth(this);
}
