import 'package:flutter/material.dart';
import '../widgets/widgets.dart';
import '../../shared/widgets/custom_button.dart' as legacy;

/// Compatibility Layer for GigaEats Design System Migration
/// 
/// This file provides wrapper components that maintain the old API
/// while using new GE components underneath. This allows for gradual
/// migration without breaking existing code.

/// Legacy DashboardCard wrapper that uses GEDashboardCard
/// 
/// This maintains the exact same API as the original DashboardCard
/// but uses the new GEDashboardCard implementation underneath.
class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GEDashboardCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      iconColor: color,
      onTap: onTap,
    );
  }
}

/// Legacy StatCard wrapper that uses GEDashboardCard
/// 
/// Maps the StatCard API to GEDashboardCard with loading support.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final bool isLoading;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GEDashboardCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      iconColor: color,
      onTap: onTap,
      isLoading: isLoading,
    );
  }
}

/// Legacy MetricCard wrapper that uses GEDashboardCard
/// 
/// Maps the MetricCard API to GEDashboardCard with trend support.
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? change;
  final bool isPositive;
  final IconData icon;
  final Color? color;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.change,
    this.isPositive = true,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GEDashboardCard(
      title: title,
      value: value,
      icon: icon,
      iconColor: color,
      trend: change,
      isPositiveTrend: isPositive,
    );
  }
}

/// Legacy CustomButton wrapper that uses GEButton
/// 
/// Maps the old ButtonType enum to GEButtonVariant and maintains
/// the same API for backward compatibility.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final legacy.ButtonType type;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final double elevation;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = legacy.ButtonType.primary,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
    this.width,
    this.height,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 12,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    // Map legacy ButtonType to GEButtonVariant
    GEButtonVariant variant;
    switch (type) {
      case legacy.ButtonType.primary:
        variant = GEButtonVariant.primary;
        break;
      case legacy.ButtonType.secondary:
        variant = GEButtonVariant.secondary;
        break;
      case legacy.ButtonType.outline:
        variant = GEButtonVariant.outline;
        break;
      case legacy.ButtonType.text:
        variant = GEButtonVariant.ghost;
        break;
    }

    // Map size based on height
    GEButtonSize size = GEButtonSize.medium;
    if (height != null) {
      if (height! < 40) {
        size = GEButtonSize.small;
      } else if (height! > 50) {
        size = GEButtonSize.large;
      }
    }

    Widget button = GEButton(
      text: text,
      onPressed: onPressed,
      variant: variant,
      size: size,
      isLoading: isLoading,
      isExpanded: isExpanded && width == null,
      icon: icon,
      customColor: backgroundColor,
    );

    // Apply custom width if specified
    if (width != null) {
      button = SizedBox(
        width: width,
        child: button,
      );
    }

    return button;
  }
}

/// Legacy button variants for backward compatibility
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GEButton.primary(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: isExpanded,
      icon: icon,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GEButton.secondary(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: isExpanded,
      icon: icon,
    );
  }
}

class OutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;

  const OutlineButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GEButton.outline(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: isExpanded,
      icon: icon,
    );
  }
}

/// Migration utilities
class GEMigrationUtils {
  /// Check if a screen is using legacy components
  static bool hasLegacyComponents(Widget widget) {
    // This would be used for automated migration detection
    // Implementation would scan widget tree for legacy components
    return false;
  }

  /// Get migration recommendations for a screen
  static List<String> getMigrationRecommendations(Widget widget) {
    final recommendations = <String>[];
    
    // This would analyze the widget tree and provide specific
    // migration recommendations
    
    return recommendations;
  }
}

/// Migration status tracking
enum MigrationStatus {
  notStarted,
  inProgress,
  completed,
  verified,
}

class MigrationTracker {
  static final Map<String, MigrationStatus> _screenStatus = {};
  
  static void updateStatus(String screenName, MigrationStatus status) {
    _screenStatus[screenName] = status;
  }
  
  static MigrationStatus getStatus(String screenName) {
    return _screenStatus[screenName] ?? MigrationStatus.notStarted;
  }
  
  static Map<String, MigrationStatus> getAllStatus() {
    return Map.from(_screenStatus);
  }
  
  static double getOverallProgress() {
    if (_screenStatus.isEmpty) return 0.0;
    
    final completed = _screenStatus.values
        .where((status) => status == MigrationStatus.completed || status == MigrationStatus.verified)
        .length;
    
    return completed / _screenStatus.length;
  }
}
