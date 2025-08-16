/// GigaEats Design System Tokens
///
/// This file exports all design tokens for easy importing
/// throughout the application.
library;

// Core design tokens
export 'color_scheme.dart';
export 'spacing.dart';
export 'typography.dart';
export 'elevation.dart';
export 'border_radius.dart';
export 'animation.dart';

/// Design tokens collection for easy access
class GETokens {
  // Prevent instantiation
  GETokens._();
  
  // Token categories are available through their respective classes:
  // - GEPalette & GEColorScheme (colors)
  // - GESpacing (spacing)
  // - GETypography (typography)
  // - GEElevation (elevation)
  // - GEBorderRadius (border radius)
  // - GEAnimation (animation)
}
