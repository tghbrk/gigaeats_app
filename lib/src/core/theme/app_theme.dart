import 'package:flutter/material.dart';

import '../../features/menu/presentation/theme/template_theme_extension.dart';
import '../../design_system/theme/theme.dart';
import '../../design_system/tokens/tokens.dart';
import '../../data/models/user_role.dart';

class AppTheme {
  // Legacy color constants for backward compatibility
  // These are now mapped to design tokens
  static const Color primaryColor = GEPalette.gigaGreen;
  static const Color primaryVariant = GEPalette.gigaGreenLight;
  static const Color secondaryColor = GEPalette.gigaOrange;
  static const Color secondaryVariant = GEPalette.gigaOrange;

  static const Color backgroundColor = GEPalette.neutral50;
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = GEPalette.danger;
  static const Color warningColor = GEPalette.warning;
  static const Color successColor = GEPalette.success;
  static const Color infoColor = GEPalette.info;

  // Text Colors
  static const Color textPrimary = GEPalette.neutral900;
  static const Color textSecondary = GEPalette.neutral600;
  static const Color textHint = GEPalette.neutral400;
  static const Color textOnPrimary = Colors.white;

  // Border Colors
  static const Color borderColor = GEPalette.neutral300;
  static const Color dividerColor = GEPalette.neutral200;

  // Shadow Colors
  static const Color shadowColor = Color(0x1A000000);

  /// Get light theme with optional role customization
  ///
  /// This method now uses the new GETheme system while maintaining
  /// backward compatibility with existing code.
  static ThemeData lightTheme({UserRole? userRole}) => GETheme.light(userRole: userRole);

  /// Get dark theme with optional role customization
  ///
  /// This method now uses the new GETheme system while maintaining
  /// backward compatibility with existing code.
  static ThemeData darkTheme({UserRole? userRole}) => GETheme.dark(userRole: userRole);

  // Legacy light theme for backward compatibility
  static ThemeData get legacyLightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: MaterialColor(
      0xFF4CAF50,
      <int, Color>{
        50: const Color(0xFFE8F5E8),
        100: const Color(0xFFC8E6C9),
        200: const Color(0xFFA5D6A7),
        300: const Color(0xFF81C784),
        400: const Color(0xFF66BB6A),
        500: primaryColor,
        600: const Color(0xFF43A047),
        700: const Color(0xFF388E3C),
        800: const Color(0xFF2E7D32),
        900: const Color(0xFF1B5E20),
      },
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: textOnPrimary,
      onSecondary: textOnPrimary,
      onSurface: textPrimary,
      onError: textOnPrimary,
    ),
    scaffoldBackgroundColor: backgroundColor,
    extensions: const [
      TemplateThemeExtension.light,
    ],
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: textOnPrimary,
      elevation: 2,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textOnPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: const TextStyle(color: textHint),
    ),
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: textOnPrimary, // White text for selected tab
      unselectedLabelColor: Color(0xFFB0BEC5), // Light gray for unselected tabs
      indicatorColor: textOnPrimary, // White indicator
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
    ),
  );

  // Legacy dark theme for backward compatibility
  static ThemeData get legacyDarkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Color(0xFF1E1E1E),
      error: errorColor,
      onPrimary: textOnPrimary,
      onSecondary: textOnPrimary,
      onSurface: Color(0xFFE0E0E0),
      onError: textOnPrimary,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    extensions: const [
      TemplateThemeExtension.dark,
    ],
  );
}
