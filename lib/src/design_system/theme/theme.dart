/// GigaEats Design System Theme
///
/// This file exports all theme-related components for easy importing
/// throughout the application.
library;

// Theme components
export 'ge_theme.dart';
export 'ge_theme_extension.dart';
export 'role_theme_extension.dart';

/// Theme collection for easy access
class GEThemes {
  // Prevent instantiation
  GEThemes._();
  
  // Theme builders are available through GETheme class:
  // - GETheme.light() - Light theme
  // - GETheme.dark() - Dark theme
  // - GETheme.light(userRole: UserRole.customer) - Role-specific light theme
  // - GETheme.dark(userRole: UserRole.vendor) - Role-specific dark theme
  
  // Theme extensions are available through their respective classes:
  // - GEThemeExtension - Core GigaEats theme extension
  // - GERoleThemeExtension - Role-specific theme extension
}
