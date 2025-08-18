/// GigaEats Design System
///
/// This file exports all design system components for easy importing
/// throughout the application.
library;

// Design tokens
export 'tokens/tokens.dart';
export 'tokens/ge_vendor_colors.dart';
export 'tokens/ge_gradients.dart';

// Theme system
export 'theme/theme.dart';

// Layout components
export 'layout/layout.dart';

// Navigation components
export 'navigation/navigation.dart';

// Widget components
export 'widgets/widgets.dart';

/// GigaEats Design System
/// 
/// A comprehensive design system that provides:
/// - Design tokens for consistent styling
/// - Theme system with role-based customization
/// - Reusable UI components
/// - Layout and navigation patterns
/// - Animation and interaction guidelines
class GEDesignSystem {
  // Prevent instantiation
  GEDesignSystem._();
  
  /// Current design system version
  static const String version = '1.0.0';
  
  /// Design system components are available through their respective exports:
  /// 
  /// **Tokens:**
  /// - GEPalette & GEColorScheme (colors)
  /// - GESpacing (spacing)
  /// - GETypography (typography)
  /// - GEElevation (elevation)
  /// - GEBorderRadius (border radius)
  /// - GEAnimation (animation)
  /// 
  /// **Theme:**
  /// - GETheme (theme builder)
  /// - GEThemeExtension (core theme extension)
  /// - GERoleThemeExtension (role-specific theme extension)
  ///
  /// **Layout:**
  /// - GEScreen (screen layout)
  /// - GESection (section layout)
  /// - GEContainer (container layout)
  /// - GEGrid (grid layout)
  ///
  /// **Navigation:**
  /// - GEBottomNavigation (bottom navigation)
  /// - GEAppBar (app bar)
  /// - GERoleNavigationConfig (role navigation configs)
  ///
  /// **Widgets:**
  /// - GEButton (button component)
  /// - GECard (card component)
  /// - GETextField (text field component)
  ///
  /// **Usage Examples:**
  /// ```dart
  /// // Using design tokens
  /// Container(
  ///   padding: EdgeInsets.all(GESpacing.lg),
  ///   decoration: BoxDecoration(
  ///     color: GEPalette.gigaGreen,
  ///     borderRadius: GEBorderRadius.card,
  ///   ),
  /// )
  /// 
  /// // Using theme system
  /// MaterialApp(
  ///   theme: GETheme.light(userRole: UserRole.customer),
  ///   darkTheme: GETheme.dark(userRole: UserRole.customer),
  /// )
  /// 
  /// // Accessing theme extensions
  /// final roleTheme = context.roleTheme;
  /// final geTheme = Theme.of(context).extension<GEThemeExtension>();
  /// ```
}
