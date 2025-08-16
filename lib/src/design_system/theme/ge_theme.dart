import 'package:flutter/material.dart';
import '../tokens/tokens.dart';
import '../../data/models/user_role.dart';
import 'ge_theme_extension.dart';
import 'role_theme_extension.dart';

/// GigaEats Theme Builder
/// 
/// Creates consistent Material Design 3 themes with GigaEats design tokens
/// and role-specific customizations.
class GETheme {
  // Prevent instantiation
  GETheme._();
  
  /// Build light theme with optional role customization
  static ThemeData light({UserRole? userRole}) {
    final colorScheme = buildLightColorScheme();
    final roleTheme = userRole != null 
        ? GERoleThemeExtension.fromUserRole(userRole)
        : null;
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: GEPalette.neutral50,
      
      // Extensions
      extensions: [
        GEThemeExtension.light,
        if (roleTheme != null) roleTheme,
      ],
      
      // Typography
      textTheme: _buildTextTheme(colorScheme),
      
      // Component themes
      appBarTheme: _buildAppBarTheme(colorScheme, roleTheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme, roleTheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme, roleTheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme, roleTheme),
      filledButtonTheme: _buildFilledButtonTheme(colorScheme, roleTheme),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      cardTheme: _buildCardTheme(colorScheme),
      navigationBarTheme: _buildNavigationBarTheme(colorScheme, roleTheme),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(colorScheme, roleTheme),
      tabBarTheme: _buildTabBarTheme(colorScheme, roleTheme),
      chipTheme: _buildChipTheme(colorScheme, roleTheme),
      dialogTheme: _buildDialogTheme(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
      
      // Page transitions
      pageTransitionsTheme: GEPageTransitions.theme,
    );
  }
  
  /// Build dark theme with optional role customization
  static ThemeData dark({UserRole? userRole}) {
    final colorScheme = buildDarkColorScheme();
    final roleTheme = userRole != null 
        ? GERoleThemeExtension.fromUserRole(userRole)
        : null;
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      
      // Extensions
      extensions: [
        GEThemeExtension.dark,
        if (roleTheme != null) roleTheme,
      ],
      
      // Typography
      textTheme: _buildTextTheme(colorScheme),
      
      // Component themes
      appBarTheme: _buildAppBarTheme(colorScheme, roleTheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme, roleTheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme, roleTheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme, roleTheme),
      filledButtonTheme: _buildFilledButtonTheme(colorScheme, roleTheme),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      cardTheme: _buildCardTheme(colorScheme),
      navigationBarTheme: _buildNavigationBarTheme(colorScheme, roleTheme),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(colorScheme, roleTheme),
      tabBarTheme: _buildTabBarTheme(colorScheme, roleTheme),
      chipTheme: _buildChipTheme(colorScheme, roleTheme),
      dialogTheme: _buildDialogTheme(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
      
      // Page transitions
      pageTransitionsTheme: GEPageTransitions.theme,
    );
  }
  
  /// Build text theme using design tokens
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: GETypography.displayLarge.copyWith(color: colorScheme.onSurface),
      displayMedium: GETypography.displayMedium.copyWith(color: colorScheme.onSurface),
      displaySmall: GETypography.displaySmall.copyWith(color: colorScheme.onSurface),
      headlineLarge: GETypography.headlineLarge.copyWith(color: colorScheme.onSurface),
      headlineMedium: GETypography.headlineMedium.copyWith(color: colorScheme.onSurface),
      headlineSmall: GETypography.headlineSmall.copyWith(color: colorScheme.onSurface),
      titleLarge: GETypography.titleLarge.copyWith(color: colorScheme.onSurface),
      titleMedium: GETypography.titleMedium.copyWith(color: colorScheme.onSurface),
      titleSmall: GETypography.titleSmall.copyWith(color: colorScheme.onSurface),
      bodyLarge: GETypography.bodyLarge.copyWith(color: colorScheme.onSurface),
      bodyMedium: GETypography.bodyMedium.copyWith(color: colorScheme.onSurface),
      bodySmall: GETypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
      labelLarge: GETypography.labelLarge.copyWith(color: colorScheme.onSurface),
      labelMedium: GETypography.labelMedium.copyWith(color: colorScheme.onSurfaceVariant),
      labelSmall: GETypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
    );
  }
  
  /// Build app bar theme
  static AppBarTheme _buildAppBarTheme(
    ColorScheme colorScheme, 
    GERoleThemeExtension? roleTheme,
  ) {
    return AppBarTheme(
      backgroundColor: roleTheme?.accentColor ?? colorScheme.primary,
      foregroundColor: roleTheme?.accentOnColor ?? colorScheme.onPrimary,
      elevation: GEElevation.appBar,
      centerTitle: true,
      titleTextStyle: GETypography.headlineSmall.copyWith(
        color: roleTheme?.accentOnColor ?? colorScheme.onPrimary,
        fontWeight: GETypography.semiBold,
      ),
      iconTheme: IconThemeData(
        color: roleTheme?.accentOnColor ?? colorScheme.onPrimary,
      ),
      actionsIconTheme: IconThemeData(
        color: roleTheme?.accentOnColor ?? colorScheme.onPrimary,
      ),
    );
  }
  
  /// Build elevated button theme
  static ElevatedButtonThemeData _buildElevatedButtonTheme(
    ColorScheme colorScheme,
    GERoleThemeExtension? roleTheme,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: roleTheme?.accentColor ?? colorScheme.primary,
        foregroundColor: roleTheme?.accentOnColor ?? colorScheme.onPrimary,
        elevation: GEElevation.button,
        padding: const EdgeInsets.symmetric(
          horizontal: GESpacing.lg,
          vertical: GESpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: GEBorderRadius.button,
        ),
        textStyle: GETypography.button,
        animationDuration: GEAnimation.buttonPress,
      ),
    );
  }
  
  /// Build outlined button theme
  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
    ColorScheme colorScheme,
    GERoleThemeExtension? roleTheme,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: roleTheme?.accentColor ?? colorScheme.primary,
        side: BorderSide(
          color: roleTheme?.accentColor ?? colorScheme.primary,
          width: GEBorder.medium,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: GESpacing.lg,
          vertical: GESpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: GEBorderRadius.button,
        ),
        textStyle: GETypography.button,
        animationDuration: GEAnimation.buttonPress,
      ),
    );
  }
  
  /// Build text button theme
  static TextButtonThemeData _buildTextButtonTheme(
    ColorScheme colorScheme,
    GERoleThemeExtension? roleTheme,
  ) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: roleTheme?.accentColor ?? colorScheme.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: GESpacing.lg,
          vertical: GESpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: GEBorderRadius.button,
        ),
        textStyle: GETypography.button,
        animationDuration: GEAnimation.buttonPress,
      ),
    );
  }
  
  /// Build filled button theme
  static FilledButtonThemeData _buildFilledButtonTheme(
    ColorScheme colorScheme,
    GERoleThemeExtension? roleTheme,
  ) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: roleTheme?.accentContainer ?? colorScheme.primaryContainer,
        foregroundColor: roleTheme?.onAccentContainer ?? colorScheme.onPrimaryContainer,
        elevation: GEElevation.level0,
        padding: const EdgeInsets.symmetric(
          horizontal: GESpacing.lg,
          vertical: GESpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: GEBorderRadius.button,
        ),
        textStyle: GETypography.button,
        animationDuration: GEAnimation.buttonPress,
      ),
    );
  }

  /// Build input decoration theme
  static InputDecorationTheme _buildInputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: GEBorderRadius.input,
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: GEBorderRadius.input,
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: GEBorderRadius.input,
        borderSide: BorderSide(color: colorScheme.primary, width: GEBorder.thick),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: GEBorderRadius.input,
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: GEBorderRadius.input,
        borderSide: BorderSide(color: colorScheme.error, width: GEBorder.thick),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: GESpacing.lg,
        vertical: GESpacing.md,
      ),
      hintStyle: GETypography.bodyMedium.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      labelStyle: GETypography.bodyMedium.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Build card theme
  static CardThemeData _buildCardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      color: colorScheme.surface,
      elevation: GEElevation.card,
      shape: RoundedRectangleBorder(
        borderRadius: GEBorderRadius.card,
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: GESpacing.lg,
        vertical: GESpacing.sm,
      ),
    );
  }

  /// Build navigation bar theme
  static NavigationBarThemeData _buildNavigationBarTheme(
    ColorScheme colorScheme,
    GERoleThemeExtension? roleTheme,
  ) {
    return NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      elevation: GEElevation.bottomNavigation,
      indicatorColor: (roleTheme?.accentColor ?? colorScheme.primary).withValues(alpha: 0.1),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GETypography.labelMedium.copyWith(
            color: roleTheme?.accentColor ?? colorScheme.primary,
            fontWeight: GETypography.medium,
          );
        }
        return GETypography.labelMedium.copyWith(
          color: colorScheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: roleTheme?.accentColor ?? colorScheme.primary,
          );
        }
        return IconThemeData(
          color: colorScheme.onSurfaceVariant,
        );
      }),
    );
  }

  /// Build bottom navigation bar theme (legacy)
  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme(
    ColorScheme colorScheme,
    GERoleThemeExtension? roleTheme,
  ) {
    return BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      selectedItemColor: roleTheme?.accentColor ?? colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: GEElevation.bottomNavigation,
      selectedLabelStyle: GETypography.labelMedium.copyWith(
        fontWeight: GETypography.medium,
      ),
      unselectedLabelStyle: GETypography.labelMedium,
    );
  }

  /// Build tab bar theme
  static TabBarThemeData _buildTabBarTheme(
    ColorScheme colorScheme,
    GERoleThemeExtension? roleTheme,
  ) {
    return TabBarThemeData(
      labelColor: roleTheme?.accentColor ?? colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorColor: roleTheme?.accentColor ?? colorScheme.primary,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: GETypography.titleMedium.copyWith(
        fontWeight: GETypography.medium,
      ),
      unselectedLabelStyle: GETypography.titleMedium,
      overlayColor: WidgetStateProperty.all(
        (roleTheme?.accentColor ?? colorScheme.primary).withValues(alpha: 0.1),
      ),
    );
  }

  /// Build chip theme
  static ChipThemeData _buildChipTheme(
    ColorScheme colorScheme,
    GERoleThemeExtension? roleTheme,
  ) {
    return ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedColor: roleTheme?.accentContainer ?? colorScheme.primaryContainer,
      disabledColor: colorScheme.onSurface.withValues(alpha: 0.12),
      deleteIconColor: colorScheme.onSurfaceVariant,
      labelStyle: GETypography.labelLarge,
      secondaryLabelStyle: GETypography.labelMedium,
      padding: const EdgeInsets.symmetric(
        horizontal: GESpacing.md,
        vertical: GESpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: GEBorderRadius.chip,
      ),
      elevation: GEElevation.level0,
      pressElevation: GEElevation.level1,
    );
  }

  /// Build dialog theme
  static DialogThemeData _buildDialogTheme(ColorScheme colorScheme) {
    return DialogThemeData(
      backgroundColor: colorScheme.surface,
      elevation: GEElevation.dialog,
      shape: RoundedRectangleBorder(
        borderRadius: GEBorderRadius.dialog,
      ),
      titleTextStyle: GETypography.headlineSmall.copyWith(
        color: colorScheme.onSurface,
      ),
      contentTextStyle: GETypography.bodyMedium.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Build snackbar theme
  static SnackBarThemeData _buildSnackBarTheme(ColorScheme colorScheme) {
    return SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: GETypography.bodyMedium.copyWith(
        color: colorScheme.onInverseSurface,
      ),
      actionTextColor: colorScheme.inversePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: GEBorderRadius.mdRadius,
      ),
      elevation: GEElevation.snackbar,
      behavior: SnackBarBehavior.floating,
    );
  }
}
