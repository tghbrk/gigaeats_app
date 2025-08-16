import 'package:flutter/material.dart';
import '../tokens/tokens.dart';
import '../../data/models/user_role.dart';

/// Role-specific theme extension for GigaEats
/// 
/// Provides role-specific accent colors and customizations while
/// maintaining overall design consistency across the application.
@immutable
class GERoleThemeExtension extends ThemeExtension<GERoleThemeExtension> {
  final Color accentColor;
  final Color accentOnColor;
  final Color accentContainer;
  final Color onAccentContainer;
  final String roleLabel;
  final IconData roleIcon;
  final UserRole userRole;
  
  const GERoleThemeExtension({
    required this.accentColor,
    required this.accentOnColor,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.roleLabel,
    required this.roleIcon,
    required this.userRole,
  });
  
  /// Customer theme
  static const GERoleThemeExtension customer = GERoleThemeExtension(
    accentColor: GEPalette.customerAccent,
    accentOnColor: Colors.white,
    accentContainer: Color(0xFFE0F7FA),
    onAccentContainer: Color(0xFF006064),
    roleLabel: 'Customer',
    roleIcon: Icons.person,
    userRole: UserRole.customer,
  );
  
  /// Vendor theme
  static const GERoleThemeExtension vendor = GERoleThemeExtension(
    accentColor: GEPalette.vendorAccent,
    accentOnColor: Colors.white,
    accentContainer: Color(0xFFF3E5F5),
    onAccentContainer: Color(0xFF4A148C),
    roleLabel: 'Vendor',
    roleIcon: Icons.store,
    userRole: UserRole.vendor,
  );
  
  /// Driver theme
  static const GERoleThemeExtension driver = GERoleThemeExtension(
    accentColor: GEPalette.driverAccent,
    accentOnColor: Colors.white,
    accentContainer: Color(0xFFE3F2FD),
    onAccentContainer: Color(0xFF0D47A1),
    roleLabel: 'Driver',
    roleIcon: Icons.delivery_dining,
    userRole: UserRole.driver,
  );
  
  /// Sales Agent theme
  static const GERoleThemeExtension salesAgent = GERoleThemeExtension(
    accentColor: GEPalette.salesAgentAccent,
    accentOnColor: Colors.black,
    accentContainer: Color(0xFFFFF8E1),
    onAccentContainer: Color(0xFFE65100),
    roleLabel: 'Sales Agent',
    roleIcon: Icons.support_agent,
    userRole: UserRole.salesAgent,
  );
  
  /// Admin theme
  static const GERoleThemeExtension admin = GERoleThemeExtension(
    accentColor: GEPalette.adminAccent,
    accentOnColor: Colors.white,
    accentContainer: Color(0xFFFFEBEE),
    onAccentContainer: Color(0xFFB71C1C),
    roleLabel: 'Admin',
    roleIcon: Icons.admin_panel_settings,
    userRole: UserRole.admin,
  );
  
  /// Factory method to get role theme by UserRole
  static GERoleThemeExtension fromUserRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return customer;
      case UserRole.vendor:
        return vendor;
      case UserRole.driver:
        return driver;
      case UserRole.salesAgent:
        return salesAgent;
      case UserRole.admin:
        return admin;
    }
  }
  
  /// Get role theme from context
  static GERoleThemeExtension? of(BuildContext context) {
    return Theme.of(context).extension<GERoleThemeExtension>();
  }
  
  @override
  GERoleThemeExtension copyWith({
    Color? accentColor,
    Color? accentOnColor,
    Color? accentContainer,
    Color? onAccentContainer,
    String? roleLabel,
    IconData? roleIcon,
    UserRole? userRole,
  }) {
    return GERoleThemeExtension(
      accentColor: accentColor ?? this.accentColor,
      accentOnColor: accentOnColor ?? this.accentOnColor,
      accentContainer: accentContainer ?? this.accentContainer,
      onAccentContainer: onAccentContainer ?? this.onAccentContainer,
      roleLabel: roleLabel ?? this.roleLabel,
      roleIcon: roleIcon ?? this.roleIcon,
      userRole: userRole ?? this.userRole,
    );
  }
  
  @override
  GERoleThemeExtension lerp(ThemeExtension<GERoleThemeExtension>? other, double t) {
    if (other is! GERoleThemeExtension) {
      return this;
    }
    
    return GERoleThemeExtension(
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
      accentOnColor: Color.lerp(accentOnColor, other.accentOnColor, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      onAccentContainer: Color.lerp(onAccentContainer, other.onAccentContainer, t)!,
      roleLabel: roleLabel,
      roleIcon: roleIcon,
      userRole: userRole,
    );
  }
  
  /// Helper method to get accent color with opacity
  Color accentWithOpacity(double opacity) {
    return accentColor.withValues(alpha: opacity);
  }
  
  /// Helper method to get accent container color with opacity
  Color accentContainerWithOpacity(double opacity) {
    return accentContainer.withValues(alpha: opacity);
  }
}

/// Helper extension for easy access to role theme
extension BuildContextRoleTheme on BuildContext {
  GERoleThemeExtension? get roleTheme => GERoleThemeExtension.of(this);
}
