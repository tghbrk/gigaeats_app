import 'package:flutter/material.dart';

/// Navigation theme service for consistent Material Design 3 theming
/// across all Enhanced In-App Navigation System components
class NavigationThemeService {
  // ignore: unused_field
  static const String _tag = 'NAV-THEME';

  /// Get navigation-specific color scheme extensions
  static NavigationColorScheme getNavigationColors(ColorScheme colorScheme) {
    return NavigationColorScheme(
      // Primary navigation colors
      navigationPrimary: colorScheme.primary,
      navigationOnPrimary: colorScheme.onPrimary,
      navigationPrimaryContainer: colorScheme.primaryContainer,
      navigationOnPrimaryContainer: colorScheme.onPrimaryContainer,
      
      // Status colors
      successColor: Colors.green.shade700,
      warningColor: Colors.orange.shade700,
      errorColor: colorScheme.error,
      infoColor: Colors.blue.shade700,
      
      // Traffic condition colors
      trafficLight: Colors.green.shade600,
      trafficModerate: Colors.orange.shade600,
      trafficHeavy: Colors.red.shade600,
      trafficSevere: Colors.red.shade800,
      
      // Battery optimization colors
      batteryGood: Colors.green.shade700,
      batteryLow: Colors.orange.shade700,
      batteryCritical: Colors.red.shade700,
      batteryCharging: Colors.blue.shade700,
      
      // Map overlay colors
      routeColor: Colors.blue.shade600,
      routeAlternativeColor: Colors.grey.shade600,
      currentLocationColor: colorScheme.primary,
      destinationColor: Colors.red.shade600,
      waypointColor: Colors.orange.shade600,
      
      // Surface variations for navigation
      navigationSurface: colorScheme.surface,
      navigationSurfaceContainer: colorScheme.surfaceContainer,
      navigationSurfaceContainerHigh: colorScheme.surfaceContainerHigh,
      navigationSurfaceContainerHighest: colorScheme.surfaceContainerHighest,
    );
  }

  /// Get navigation-specific text theme extensions
  static NavigationTextTheme getNavigationTextTheme(TextTheme textTheme) {
    return NavigationTextTheme(
      // Instruction text styles
      instructionTitle: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      instructionSubtitle: textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      instructionDistance: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        height: 1.1,
      ),
      
      // Stats text styles
      statsValue: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        height: 1.0,
      ),
      statsLabel: textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      statsUnit: textTheme.bodySmall?.copyWith(
        height: 1.0,
      ),
      
      // Status text styles
      statusTitle: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      statusMessage: textTheme.bodyMedium?.copyWith(
        height: 1.4,
      ),
      
      // Button text styles
      buttonPrimary: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.0,
      ),
      buttonSecondary: textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.0,
      ),
    );
  }

  /// Get loading state theme
  static LoadingStateTheme getLoadingStateTheme(ColorScheme colorScheme) {
    return LoadingStateTheme(
      shimmerBaseColor: colorScheme.surfaceContainer,
      shimmerHighlightColor: colorScheme.surfaceContainerHighest,
      progressIndicatorColor: colorScheme.primary,
      loadingOverlayColor: colorScheme.surface.withValues(alpha: 0.8),
      loadingTextColor: colorScheme.onSurface,
    );
  }

  /// Get elevation and shadow theme
  static ElevationTheme getElevationTheme(ColorScheme colorScheme) {
    return ElevationTheme(
      cardElevation: 4.0,
      overlayElevation: 8.0,
      dialogElevation: 12.0,
      bottomSheetElevation: 16.0,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
    );
  }

  /// Get animation durations
  static AnimationDurations getAnimationDurations() {
    return const AnimationDurations(
      fast: Duration(milliseconds: 150),
      medium: Duration(milliseconds: 300),
      slow: Duration(milliseconds: 500),
      instructionTransition: Duration(milliseconds: 400),
      cameraTransition: Duration(milliseconds: 600),
      loadingFade: Duration(milliseconds: 200),
    );
  }

  /// Get border radius values
  static BorderRadiusTheme getBorderRadiusTheme() {
    return const BorderRadiusTheme(
      small: 8.0,
      medium: 12.0,
      large: 16.0,
      extraLarge: 20.0,
      circular: 28.0,
    );
  }

  /// Get spacing values
  static SpacingTheme getSpacingTheme() {
    return const SpacingTheme(
      xs: 4.0,
      sm: 8.0,
      md: 12.0,
      lg: 16.0,
      xl: 20.0,
      xxl: 24.0,
      xxxl: 32.0,
    );
  }

  /// Create a complete navigation theme data
  static NavigationThemeData createNavigationTheme(ThemeData baseTheme) {
    final colorScheme = baseTheme.colorScheme;
    final textTheme = baseTheme.textTheme;

    return NavigationThemeData(
      colors: getNavigationColors(colorScheme),
      textTheme: getNavigationTextTheme(textTheme),
      loadingTheme: getLoadingStateTheme(colorScheme),
      elevationTheme: getElevationTheme(colorScheme),
      animationDurations: getAnimationDurations(),
      borderRadius: getBorderRadiusTheme(),
      spacing: getSpacingTheme(),
    );
  }

  /// Apply navigation theme to a widget
  static Widget applyNavigationTheme({
    required Widget child,
    required BuildContext context,
  }) {
    final baseTheme = Theme.of(context);
    final navigationTheme = createNavigationTheme(baseTheme);

    return NavigationTheme(
      data: navigationTheme,
      child: child,
    );
  }
}

/// Navigation color scheme extension
class NavigationColorScheme {
  final Color navigationPrimary;
  final Color navigationOnPrimary;
  final Color navigationPrimaryContainer;
  final Color navigationOnPrimaryContainer;
  
  final Color successColor;
  final Color warningColor;
  final Color errorColor;
  final Color infoColor;
  
  final Color trafficLight;
  final Color trafficModerate;
  final Color trafficHeavy;
  final Color trafficSevere;
  
  final Color batteryGood;
  final Color batteryLow;
  final Color batteryCritical;
  final Color batteryCharging;
  
  final Color routeColor;
  final Color routeAlternativeColor;
  final Color currentLocationColor;
  final Color destinationColor;
  final Color waypointColor;
  
  final Color navigationSurface;
  final Color navigationSurfaceContainer;
  final Color navigationSurfaceContainerHigh;
  final Color navigationSurfaceContainerHighest;

  const NavigationColorScheme({
    required this.navigationPrimary,
    required this.navigationOnPrimary,
    required this.navigationPrimaryContainer,
    required this.navigationOnPrimaryContainer,
    required this.successColor,
    required this.warningColor,
    required this.errorColor,
    required this.infoColor,
    required this.trafficLight,
    required this.trafficModerate,
    required this.trafficHeavy,
    required this.trafficSevere,
    required this.batteryGood,
    required this.batteryLow,
    required this.batteryCritical,
    required this.batteryCharging,
    required this.routeColor,
    required this.routeAlternativeColor,
    required this.currentLocationColor,
    required this.destinationColor,
    required this.waypointColor,
    required this.navigationSurface,
    required this.navigationSurfaceContainer,
    required this.navigationSurfaceContainerHigh,
    required this.navigationSurfaceContainerHighest,
  });
}

/// Navigation text theme extension
class NavigationTextTheme {
  final TextStyle? instructionTitle;
  final TextStyle? instructionSubtitle;
  final TextStyle? instructionDistance;
  final TextStyle? statsValue;
  final TextStyle? statsLabel;
  final TextStyle? statsUnit;
  final TextStyle? statusTitle;
  final TextStyle? statusMessage;
  final TextStyle? buttonPrimary;
  final TextStyle? buttonSecondary;

  const NavigationTextTheme({
    this.instructionTitle,
    this.instructionSubtitle,
    this.instructionDistance,
    this.statsValue,
    this.statsLabel,
    this.statsUnit,
    this.statusTitle,
    this.statusMessage,
    this.buttonPrimary,
    this.buttonSecondary,
  });
}

/// Loading state theme
class LoadingStateTheme {
  final Color shimmerBaseColor;
  final Color shimmerHighlightColor;
  final Color progressIndicatorColor;
  final Color loadingOverlayColor;
  final Color loadingTextColor;

  const LoadingStateTheme({
    required this.shimmerBaseColor,
    required this.shimmerHighlightColor,
    required this.progressIndicatorColor,
    required this.loadingOverlayColor,
    required this.loadingTextColor,
  });
}

/// Elevation theme
class ElevationTheme {
  final double cardElevation;
  final double overlayElevation;
  final double dialogElevation;
  final double bottomSheetElevation;
  final Color shadowColor;

  const ElevationTheme({
    required this.cardElevation,
    required this.overlayElevation,
    required this.dialogElevation,
    required this.bottomSheetElevation,
    required this.shadowColor,
  });
}

/// Animation durations
class AnimationDurations {
  final Duration fast;
  final Duration medium;
  final Duration slow;
  final Duration instructionTransition;
  final Duration cameraTransition;
  final Duration loadingFade;

  const AnimationDurations({
    required this.fast,
    required this.medium,
    required this.slow,
    required this.instructionTransition,
    required this.cameraTransition,
    required this.loadingFade,
  });
}

/// Border radius theme
class BorderRadiusTheme {
  final double small;
  final double medium;
  final double large;
  final double extraLarge;
  final double circular;

  const BorderRadiusTheme({
    required this.small,
    required this.medium,
    required this.large,
    required this.extraLarge,
    required this.circular,
  });
}

/// Spacing theme
class SpacingTheme {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;

  const SpacingTheme({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.xxxl,
  });
}

/// Complete navigation theme data
class NavigationThemeData {
  final NavigationColorScheme colors;
  final NavigationTextTheme textTheme;
  final LoadingStateTheme loadingTheme;
  final ElevationTheme elevationTheme;
  final AnimationDurations animationDurations;
  final BorderRadiusTheme borderRadius;
  final SpacingTheme spacing;

  const NavigationThemeData({
    required this.colors,
    required this.textTheme,
    required this.loadingTheme,
    required this.elevationTheme,
    required this.animationDurations,
    required this.borderRadius,
    required this.spacing,
  });
}

/// Navigation theme inherited widget
class NavigationTheme extends InheritedWidget {
  final NavigationThemeData data;

  const NavigationTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static NavigationThemeData? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NavigationTheme>()?.data;
  }

  @override
  bool updateShouldNotify(NavigationTheme oldWidget) {
    return data != oldWidget.data;
  }
}
