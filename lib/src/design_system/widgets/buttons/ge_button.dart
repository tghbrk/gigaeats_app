import 'package:flutter/material.dart';
import '../../tokens/tokens.dart';
import '../../theme/theme.dart';

/// GigaEats Design System Button Component
/// 
/// A comprehensive button component that supports multiple variants,
/// sizes, states, and role-specific theming.
class GEButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final GEButtonVariant variant;
  final GEButtonSize size;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final IconData? trailingIcon;
  final Color? customColor;
  final String? tooltip;

  const GEButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = GEButtonVariant.primary,
    this.size = GEButtonSize.medium,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.trailingIcon,
    this.customColor,
    this.tooltip,
  });

  /// Primary button constructor
  const GEButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.size = GEButtonSize.medium,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.trailingIcon,
    this.customColor,
    this.tooltip,
  }) : variant = GEButtonVariant.primary;

  /// Secondary button constructor
  const GEButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.size = GEButtonSize.medium,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.trailingIcon,
    this.customColor,
    this.tooltip,
  }) : variant = GEButtonVariant.secondary;

  /// Outline button constructor
  const GEButton.outline({
    super.key,
    required this.text,
    this.onPressed,
    this.size = GEButtonSize.medium,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.trailingIcon,
    this.customColor,
    this.tooltip,
  }) : variant = GEButtonVariant.outline;

  /// Ghost button constructor
  const GEButton.ghost({
    super.key,
    required this.text,
    this.onPressed,
    this.size = GEButtonSize.medium,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.trailingIcon,
    this.customColor,
    this.tooltip,
  }) : variant = GEButtonVariant.ghost;

  /// Danger button constructor
  const GEButton.danger({
    super.key,
    required this.text,
    this.onPressed,
    this.size = GEButtonSize.medium,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.trailingIcon,
    this.customColor,
    this.tooltip,
  }) : variant = GEButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final geTheme = theme.extension<GEThemeExtension>();
    final roleTheme = theme.extension<GERoleThemeExtension>();
    
    Widget button = _buildButton(context, theme, geTheme, roleTheme);
    
    if (isExpanded) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    
    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }
    
    return button;
  }

  Widget _buildButton(
    BuildContext context,
    ThemeData theme,
    GEThemeExtension? geTheme,
    GERoleThemeExtension? roleTheme,
  ) {
    final isDisabled = onPressed == null || isLoading;
    final buttonStyle = _getButtonStyle(theme, geTheme, roleTheme);
    
    switch (variant) {
      case GEButtonVariant.primary:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: _buildButtonContent(theme),
        );
      
      case GEButtonVariant.secondary:
        return FilledButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: _buildButtonContent(theme),
        );
      
      case GEButtonVariant.outline:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: _buildButtonContent(theme),
        );
      
      case GEButtonVariant.ghost:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: _buildButtonContent(theme),
        );
      
      case GEButtonVariant.danger:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: _buildButtonContent(theme),
        );
    }
  }

  ButtonStyle _getButtonStyle(
    ThemeData theme,
    GEThemeExtension? geTheme,
    GERoleThemeExtension? roleTheme,
  ) {
    final colors = _getButtonColors(theme, geTheme, roleTheme);
    final padding = _getButtonPadding();
    final textStyle = _getButtonTextStyle();
    
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.disabledBackground;
        }
        if (states.contains(WidgetState.pressed)) {
          return colors.pressedBackground;
        }
        if (states.contains(WidgetState.hovered)) {
          return colors.hoveredBackground;
        }
        return colors.backgroundColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.disabledForeground;
        }
        return colors.foregroundColor;
      }),
      overlayColor: WidgetStateProperty.all(colors.overlayColor),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (variant == GEButtonVariant.outline || variant == GEButtonVariant.ghost) {
          return GEElevation.level0;
        }
        if (states.contains(WidgetState.pressed)) {
          return GEElevation.level1;
        }
        return GEElevation.button;
      }),
      padding: WidgetStateProperty.all(padding),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: GEBorderRadius.button,
        ),
      ),
      side: variant == GEButtonVariant.outline
          ? WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return BorderSide(color: colors.disabledForeground ?? Colors.grey);
              }
              return BorderSide(
                color: colors.foregroundColor ?? theme.colorScheme.primary,
                width: GEBorder.medium,
              );
            })
          : null,
      textStyle: WidgetStateProperty.all(textStyle),
      animationDuration: GEAnimation.buttonPress,
    );
  }

  _ButtonColors _getButtonColors(
    ThemeData theme,
    GEThemeExtension? geTheme,
    GERoleThemeExtension? roleTheme,
  ) {
    final colorScheme = theme.colorScheme;
    
    switch (variant) {
      case GEButtonVariant.primary:
        final primaryColor = customColor ?? roleTheme?.accentColor ?? colorScheme.primary;
        return _ButtonColors(
          backgroundColor: primaryColor,
          foregroundColor: roleTheme?.accentOnColor ?? colorScheme.onPrimary,
          hoveredBackground: primaryColor.withValues(alpha: 0.8),
          pressedBackground: primaryColor.withValues(alpha: 0.9),
          disabledBackground: colorScheme.onSurface.withValues(alpha: 0.12),
          disabledForeground: colorScheme.onSurface.withValues(alpha: 0.38),
          overlayColor: (roleTheme?.accentOnColor ?? colorScheme.onPrimary).withValues(alpha: 0.1),
        );
      
      case GEButtonVariant.secondary:
        return _ButtonColors(
          backgroundColor: roleTheme?.accentContainer ?? colorScheme.primaryContainer,
          foregroundColor: roleTheme?.onAccentContainer ?? colorScheme.onPrimaryContainer,
          hoveredBackground: (roleTheme?.accentContainer ?? colorScheme.primaryContainer).withValues(alpha: 0.8),
          pressedBackground: (roleTheme?.accentContainer ?? colorScheme.primaryContainer).withValues(alpha: 0.9),
          disabledBackground: colorScheme.onSurface.withValues(alpha: 0.12),
          disabledForeground: colorScheme.onSurface.withValues(alpha: 0.38),
          overlayColor: (roleTheme?.onAccentContainer ?? colorScheme.onPrimaryContainer).withValues(alpha: 0.1),
        );
      
      case GEButtonVariant.outline:
        final primaryColor = customColor ?? roleTheme?.accentColor ?? colorScheme.primary;
        return _ButtonColors(
          backgroundColor: Colors.transparent,
          foregroundColor: primaryColor,
          hoveredBackground: primaryColor.withValues(alpha: 0.04),
          pressedBackground: primaryColor.withValues(alpha: 0.08),
          disabledBackground: Colors.transparent,
          disabledForeground: colorScheme.onSurface.withValues(alpha: 0.38),
          overlayColor: primaryColor.withValues(alpha: 0.1),
        );
      
      case GEButtonVariant.ghost:
        final primaryColor = customColor ?? roleTheme?.accentColor ?? colorScheme.primary;
        return _ButtonColors(
          backgroundColor: Colors.transparent,
          foregroundColor: primaryColor,
          hoveredBackground: primaryColor.withValues(alpha: 0.04),
          pressedBackground: primaryColor.withValues(alpha: 0.08),
          disabledBackground: Colors.transparent,
          disabledForeground: colorScheme.onSurface.withValues(alpha: 0.38),
          overlayColor: primaryColor.withValues(alpha: 0.1),
        );
      
      case GEButtonVariant.danger:
        final dangerColor = geTheme?.danger ?? Colors.red;
        return _ButtonColors(
          backgroundColor: dangerColor,
          foregroundColor: geTheme?.onDanger ?? Colors.white,
          hoveredBackground: dangerColor.withValues(alpha: 0.8),
          pressedBackground: dangerColor.withValues(alpha: 0.9),
          disabledBackground: colorScheme.onSurface.withValues(alpha: 0.12),
          disabledForeground: colorScheme.onSurface.withValues(alpha: 0.38),
          overlayColor: (geTheme?.onDanger ?? Colors.white).withValues(alpha: 0.1),
        );
    }
  }

  EdgeInsetsGeometry _getButtonPadding() {
    switch (size) {
      case GEButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: GESpacing.md,
          vertical: GESpacing.sm,
        );
      case GEButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: GESpacing.lg,
          vertical: GESpacing.md,
        );
      case GEButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: GESpacing.xl,
          vertical: GESpacing.lg,
        );
    }
  }

  TextStyle _getButtonTextStyle() {
    switch (size) {
      case GEButtonSize.small:
        return GETypography.labelMedium;
      case GEButtonSize.medium:
        return GETypography.labelLarge;
      case GEButtonSize.large:
        return GETypography.titleMedium;
    }
  }

  Widget _buildButtonContent(ThemeData theme) {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _getIconSize(),
            height: _getIconSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getLoadingIndicatorColor(theme),
              ),
            ),
          ),
          const SizedBox(width: GESpacing.sm),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    final children = <Widget>[];
    
    if (icon != null) {
      children.add(Icon(icon, size: _getIconSize()));
      children.add(const SizedBox(width: GESpacing.sm));
    }
    
    children.add(
      Flexible(
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
      ),
    );
    
    if (trailingIcon != null) {
      children.add(const SizedBox(width: GESpacing.sm));
      children.add(Icon(trailingIcon, size: _getIconSize()));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  double _getIconSize() {
    switch (size) {
      case GEButtonSize.small:
        return 16.0;
      case GEButtonSize.medium:
        return 18.0;
      case GEButtonSize.large:
        return 20.0;
    }
  }

  Color _getLoadingIndicatorColor(ThemeData theme) {
    switch (variant) {
      case GEButtonVariant.outline:
      case GEButtonVariant.ghost:
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.onPrimary;
    }
  }
}

/// Button variant enumeration
enum GEButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  danger,
}

/// Button size enumeration
enum GEButtonSize {
  small,
  medium,
  large,
}

/// Internal class for button colors
class _ButtonColors {
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? hoveredBackground;
  final Color? pressedBackground;
  final Color? disabledBackground;
  final Color? disabledForeground;
  final Color? overlayColor;

  const _ButtonColors({
    this.backgroundColor,
    this.foregroundColor,
    this.hoveredBackground,
    this.pressedBackground,
    this.disabledBackground,
    this.disabledForeground,
    this.overlayColor,
  });
}
