import 'package:flutter/material.dart';
import '../tokens/tokens.dart';

/// GigaEats Theme Extension
/// 
/// Extends Material Design 3 theme with GigaEats-specific design tokens
/// and semantic color mappings.
@immutable
class GEThemeExtension extends ThemeExtension<GEThemeExtension> {
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color successContainer;
  final Color warningContainer;
  final Color dangerContainer;
  final Color infoContainer;
  final Color onSuccess;
  final Color onWarning;
  final Color onDanger;
  final Color onInfo;
  final Color onSuccessContainer;
  final Color onWarningContainer;
  final Color onDangerContainer;
  final Color onInfoContainer;
  
  // Neutral colors
  final Color neutral50;
  final Color neutral100;
  final Color neutral200;
  final Color neutral300;
  final Color neutral400;
  final Color neutral500;
  final Color neutral600;
  final Color neutral700;
  final Color neutral800;
  final Color neutral900;
  
  const GEThemeExtension({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.successContainer,
    required this.warningContainer,
    required this.dangerContainer,
    required this.infoContainer,
    required this.onSuccess,
    required this.onWarning,
    required this.onDanger,
    required this.onInfo,
    required this.onSuccessContainer,
    required this.onWarningContainer,
    required this.onDangerContainer,
    required this.onInfoContainer,
    required this.neutral50,
    required this.neutral100,
    required this.neutral200,
    required this.neutral300,
    required this.neutral400,
    required this.neutral500,
    required this.neutral600,
    required this.neutral700,
    required this.neutral800,
    required this.neutral900,
  });
  
  /// Light theme extension
  static const GEThemeExtension light = GEThemeExtension(
    success: GEPalette.success,
    warning: GEPalette.warning,
    danger: GEPalette.danger,
    info: GEPalette.info,
    successContainer: Color(0xFFE8F5E8),
    warningContainer: Color(0xFFFFF3E0),
    dangerContainer: Color(0xFFFFEBEE),
    infoContainer: Color(0xFFE3F2FD),
    onSuccess: Colors.white,
    onWarning: Colors.white,
    onDanger: Colors.white,
    onInfo: Colors.white,
    onSuccessContainer: Color(0xFF1B5E20),
    onWarningContainer: Color(0xFFE65100),
    onDangerContainer: Color(0xFFB71C1C),
    onInfoContainer: Color(0xFF0D47A1),
    neutral50: GEPalette.neutral50,
    neutral100: GEPalette.neutral100,
    neutral200: GEPalette.neutral200,
    neutral300: GEPalette.neutral300,
    neutral400: GEPalette.neutral400,
    neutral500: GEPalette.neutral500,
    neutral600: GEPalette.neutral600,
    neutral700: GEPalette.neutral700,
    neutral800: GEPalette.neutral800,
    neutral900: GEPalette.neutral900,
  );
  
  /// Dark theme extension
  static const GEThemeExtension dark = GEThemeExtension(
    success: Color(0xFF4CAF50),
    warning: Color(0xFFFF9800),
    danger: Color(0xFFF44336),
    info: Color(0xFF2196F3),
    successContainer: Color(0xFF2E7D32),
    warningContainer: Color(0xFFE65100),
    dangerContainer: Color(0xFFD32F2F),
    infoContainer: Color(0xFF1565C0),
    onSuccess: Colors.black,
    onWarning: Colors.black,
    onDanger: Colors.white,
    onInfo: Colors.white,
    onSuccessContainer: Color(0xFFE8F5E8),
    onWarningContainer: Color(0xFFFFF3E0),
    onDangerContainer: Color(0xFFFFEBEE),
    onInfoContainer: Color(0xFFE3F2FD),
    neutral50: Color(0xFF1E1E1E),
    neutral100: Color(0xFF2D2D2D),
    neutral200: Color(0xFF3D3D3D),
    neutral300: Color(0xFF4D4D4D),
    neutral400: Color(0xFF6D6D6D),
    neutral500: Color(0xFF8D8D8D),
    neutral600: Color(0xFFADADAD),
    neutral700: Color(0xFFCDCDCD),
    neutral800: Color(0xFFE0E0E0),
    neutral900: Color(0xFFF5F5F5),
  );
  
  @override
  GEThemeExtension copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? successContainer,
    Color? warningContainer,
    Color? dangerContainer,
    Color? infoContainer,
    Color? onSuccess,
    Color? onWarning,
    Color? onDanger,
    Color? onInfo,
    Color? onSuccessContainer,
    Color? onWarningContainer,
    Color? onDangerContainer,
    Color? onInfoContainer,
    Color? neutral50,
    Color? neutral100,
    Color? neutral200,
    Color? neutral300,
    Color? neutral400,
    Color? neutral500,
    Color? neutral600,
    Color? neutral700,
    Color? neutral800,
    Color? neutral900,
  }) {
    return GEThemeExtension(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      successContainer: successContainer ?? this.successContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      infoContainer: infoContainer ?? this.infoContainer,
      onSuccess: onSuccess ?? this.onSuccess,
      onWarning: onWarning ?? this.onWarning,
      onDanger: onDanger ?? this.onDanger,
      onInfo: onInfo ?? this.onInfo,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      neutral50: neutral50 ?? this.neutral50,
      neutral100: neutral100 ?? this.neutral100,
      neutral200: neutral200 ?? this.neutral200,
      neutral300: neutral300 ?? this.neutral300,
      neutral400: neutral400 ?? this.neutral400,
      neutral500: neutral500 ?? this.neutral500,
      neutral600: neutral600 ?? this.neutral600,
      neutral700: neutral700 ?? this.neutral700,
      neutral800: neutral800 ?? this.neutral800,
      neutral900: neutral900 ?? this.neutral900,
    );
  }
  
  @override
  GEThemeExtension lerp(ThemeExtension<GEThemeExtension>? other, double t) {
    if (other is! GEThemeExtension) {
      return this;
    }
    
    return GEThemeExtension(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      onDangerContainer: Color.lerp(onDangerContainer, other.onDangerContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      neutral50: Color.lerp(neutral50, other.neutral50, t)!,
      neutral100: Color.lerp(neutral100, other.neutral100, t)!,
      neutral200: Color.lerp(neutral200, other.neutral200, t)!,
      neutral300: Color.lerp(neutral300, other.neutral300, t)!,
      neutral400: Color.lerp(neutral400, other.neutral400, t)!,
      neutral500: Color.lerp(neutral500, other.neutral500, t)!,
      neutral600: Color.lerp(neutral600, other.neutral600, t)!,
      neutral700: Color.lerp(neutral700, other.neutral700, t)!,
      neutral800: Color.lerp(neutral800, other.neutral800, t)!,
      neutral900: Color.lerp(neutral900, other.neutral900, t)!,
    );
  }
}
