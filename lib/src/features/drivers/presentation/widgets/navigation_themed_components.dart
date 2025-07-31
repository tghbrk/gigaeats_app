import 'package:flutter/material.dart';

import '../theming/navigation_theme_service.dart';

/// Material Design 3 themed components for the Enhanced In-App Navigation System
/// Provides consistent styling and behavior across all navigation UI elements

/// Navigation-themed elevated button with consistent styling
class NavigationElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final NavigationButtonStyle style;
  final bool isLoading;
  final IconData? icon;

  const NavigationElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style = NavigationButtonStyle.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = NavigationTheme.of(context);
    
    final buttonStyle = _getButtonStyle(theme, navTheme, style);
    
    Widget buttonChild = child;
    
    if (isLoading) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: buttonStyle.foregroundColor?.resolve({}) ?? theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 8),
          child,
        ],
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          child,
        ],
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: buttonChild,
    );
  }

  ButtonStyle _getButtonStyle(ThemeData theme, NavigationThemeData? navTheme, NavigationButtonStyle style) {
    switch (style) {
      case NavigationButtonStyle.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: navTheme?.colors.navigationPrimary ?? theme.colorScheme.primary,
          foregroundColor: navTheme?.colors.navigationOnPrimary ?? theme.colorScheme.onPrimary,
          elevation: navTheme?.elevationTheme.cardElevation ?? 4.0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(navTheme?.borderRadius.medium ?? 12),
          ),
        );
      
      case NavigationButtonStyle.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
          elevation: navTheme?.elevationTheme.cardElevation ?? 4.0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(navTheme?.borderRadius.medium ?? 12),
          ),
        );
      
      case NavigationButtonStyle.success:
        return ElevatedButton.styleFrom(
          backgroundColor: navTheme?.colors.successColor ?? Colors.green.shade700,
          foregroundColor: Colors.white,
          elevation: navTheme?.elevationTheme.cardElevation ?? 4.0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(navTheme?.borderRadius.medium ?? 12),
          ),
        );
      
      case NavigationButtonStyle.warning:
        return ElevatedButton.styleFrom(
          backgroundColor: navTheme?.colors.warningColor ?? Colors.orange.shade700,
          foregroundColor: Colors.white,
          elevation: navTheme?.elevationTheme.cardElevation ?? 4.0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(navTheme?.borderRadius.medium ?? 12),
          ),
        );
      
      case NavigationButtonStyle.error:
        return ElevatedButton.styleFrom(
          backgroundColor: navTheme?.colors.errorColor ?? theme.colorScheme.error,
          foregroundColor: theme.colorScheme.onError,
          elevation: navTheme?.elevationTheme.cardElevation ?? 4.0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(navTheme?.borderRadius.medium ?? 12),
          ),
        );
    }
  }
}

/// Navigation-themed outlined button
class NavigationOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final NavigationButtonStyle style;
  final bool isLoading;
  final IconData? icon;

  const NavigationOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style = NavigationButtonStyle.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = NavigationTheme.of(context);
    
    final buttonStyle = _getButtonStyle(theme, navTheme, style);
    
    Widget buttonChild = child;
    
    if (isLoading) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: buttonStyle.foregroundColor?.resolve({}) ?? theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          child,
        ],
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          child,
        ],
      );
    }

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: buttonChild,
    );
  }

  ButtonStyle _getButtonStyle(ThemeData theme, NavigationThemeData? navTheme, NavigationButtonStyle style) {
    Color borderColor;
    Color foregroundColor;
    
    switch (style) {
      case NavigationButtonStyle.primary:
        borderColor = navTheme?.colors.navigationPrimary ?? theme.colorScheme.primary;
        foregroundColor = navTheme?.colors.navigationPrimary ?? theme.colorScheme.primary;
        break;
      case NavigationButtonStyle.secondary:
        borderColor = theme.colorScheme.secondary;
        foregroundColor = theme.colorScheme.secondary;
        break;
      case NavigationButtonStyle.success:
        borderColor = navTheme?.colors.successColor ?? Colors.green.shade700;
        foregroundColor = navTheme?.colors.successColor ?? Colors.green.shade700;
        break;
      case NavigationButtonStyle.warning:
        borderColor = navTheme?.colors.warningColor ?? Colors.orange.shade700;
        foregroundColor = navTheme?.colors.warningColor ?? Colors.orange.shade700;
        break;
      case NavigationButtonStyle.error:
        borderColor = navTheme?.colors.errorColor ?? theme.colorScheme.error;
        foregroundColor = navTheme?.colors.errorColor ?? theme.colorScheme.error;
        break;
    }
    
    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor,
      side: BorderSide(color: borderColor, width: 2),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(navTheme?.borderRadius.medium ?? 12),
      ),
    );
  }
}

/// Navigation-themed icon button
class NavigationIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final NavigationButtonStyle style;
  final bool isLoading;
  final String? tooltip;
  final double? size;

  const NavigationIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.style = NavigationButtonStyle.primary,
    this.isLoading = false,
    this.tooltip,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = NavigationTheme.of(context);
    
    Color backgroundColor;
    Color foregroundColor;
    
    switch (style) {
      case NavigationButtonStyle.primary:
        backgroundColor = navTheme?.colors.navigationPrimary.withValues(alpha: 0.15) ?? 
                         theme.colorScheme.primary.withValues(alpha: 0.15);
        foregroundColor = navTheme?.colors.navigationPrimary ?? theme.colorScheme.primary;
        break;
      case NavigationButtonStyle.secondary:
        backgroundColor = theme.colorScheme.secondary.withValues(alpha: 0.15);
        foregroundColor = theme.colorScheme.secondary;
        break;
      case NavigationButtonStyle.success:
        backgroundColor = (navTheme?.colors.successColor ?? Colors.green.shade700).withValues(alpha: 0.15);
        foregroundColor = navTheme?.colors.successColor ?? Colors.green.shade700;
        break;
      case NavigationButtonStyle.warning:
        backgroundColor = (navTheme?.colors.warningColor ?? Colors.orange.shade700).withValues(alpha: 0.15);
        foregroundColor = navTheme?.colors.warningColor ?? Colors.orange.shade700;
        break;
      case NavigationButtonStyle.error:
        backgroundColor = (navTheme?.colors.errorColor ?? theme.colorScheme.error).withValues(alpha: 0.15);
        foregroundColor = navTheme?.colors.errorColor ?? theme.colorScheme.error;
        break;
    }

    Widget iconWidget = isLoading
        ? SizedBox(
            width: size ?? 24,
            height: size ?? 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor,
            ),
          )
        : Icon(
            icon,
            color: foregroundColor,
            size: size ?? 24,
          );

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(navTheme?.borderRadius.medium ?? 12),
      ),
      child: IconButton(
        onPressed: isLoading ? null : onPressed,
        icon: iconWidget,
        tooltip: tooltip,
      ),
    );
  }
}

/// Navigation-themed status chip
class NavigationStatusChip extends StatelessWidget {
  final String label;
  final NavigationChipStyle style;
  final IconData? icon;
  final VoidCallback? onTap;

  const NavigationStatusChip({
    super.key,
    required this.label,
    this.style = NavigationChipStyle.info,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = NavigationTheme.of(context);
    
    Color backgroundColor;
    Color foregroundColor;
    
    switch (style) {
      case NavigationChipStyle.success:
        backgroundColor = (navTheme?.colors.successColor ?? Colors.green.shade700).withValues(alpha: 0.15);
        foregroundColor = navTheme?.colors.successColor ?? Colors.green.shade700;
        break;
      case NavigationChipStyle.warning:
        backgroundColor = (navTheme?.colors.warningColor ?? Colors.orange.shade700).withValues(alpha: 0.15);
        foregroundColor = navTheme?.colors.warningColor ?? Colors.orange.shade700;
        break;
      case NavigationChipStyle.error:
        backgroundColor = (navTheme?.colors.errorColor ?? theme.colorScheme.error).withValues(alpha: 0.15);
        foregroundColor = navTheme?.colors.errorColor ?? theme.colorScheme.error;
        break;
      case NavigationChipStyle.info:
        backgroundColor = (navTheme?.colors.infoColor ?? Colors.blue.shade700).withValues(alpha: 0.15);
        foregroundColor = navTheme?.colors.infoColor ?? Colors.blue.shade700;
        break;
      case NavigationChipStyle.neutral:
        backgroundColor = theme.colorScheme.outline.withValues(alpha: 0.15);
        foregroundColor = theme.colorScheme.outline;
        break;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(navTheme?.borderRadius.large ?? 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(navTheme?.borderRadius.large ?? 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: foregroundColor,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navigation-themed card container
class NavigationCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool elevated;

  const NavigationCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = NavigationTheme.of(context);
    
    return Container(
      margin: margin,
      child: Material(
        elevation: elevated ? (navTheme?.elevationTheme.cardElevation ?? 4.0) : 0,
        borderRadius: BorderRadius.circular(navTheme?.borderRadius.large ?? 16),
        shadowColor: navTheme?.elevationTheme.shadowColor ?? 
                    theme.colorScheme.shadow.withValues(alpha: 0.3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(navTheme?.borderRadius.large ?? 16),
          child: Container(
            padding: padding ?? EdgeInsets.all(navTheme?.spacing.lg ?? 16),
            decoration: BoxDecoration(
              color: navTheme?.colors.navigationSurface ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(navTheme?.borderRadius.large ?? 16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Button style enumeration
enum NavigationButtonStyle {
  primary,
  secondary,
  success,
  warning,
  error,
}

/// Chip style enumeration
enum NavigationChipStyle {
  success,
  warning,
  error,
  info,
  neutral,
}
