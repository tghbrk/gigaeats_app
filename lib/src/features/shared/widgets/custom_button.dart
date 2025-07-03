import 'package:flutter/material.dart';

/// Button size enumeration
enum ButtonSize {
  small,
  medium,
  large,
}

/// Button variant enumeration
enum ButtonVariant {
  primary,
  secondary,
  outline,
  outlined, // Alias for outline for backward compatibility
  text,
  danger,
  success,
}

/// A highly customizable button widget for the GigaEats app
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool iconOnRight;
  final bool isLoading;
  final bool isFullWidth;
  final Color? customColor;
  final Color? customTextColor;
  final double? customBorderRadius;
  final EdgeInsetsGeometry? customPadding;
  final double? elevation;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.iconOnRight = false,
    this.isLoading = false,
    this.isFullWidth = false,
    this.customColor,
    this.customTextColor,
    this.customBorderRadius,
    this.customPadding,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null && !isLoading;

    final buttonStyle = _getButtonStyle(context, theme, isEnabled);
    final textStyle = _getTextStyle(context, theme, isEnabled);
    // TODO: Remove unused variables when styling is restored
    // ignore: unused_local_variable
    final padding = _getPadding();
    // ignore: unused_local_variable
    final borderRadius = customBorderRadius ?? _getBorderRadius();

    Widget buttonChild = _buildButtonContent(context, theme, textStyle);

    Widget button;
    
    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
      case ButtonVariant.danger:
      case ButtonVariant.success:
        button = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
      case ButtonVariant.outline:
      case ButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
      case ButtonVariant.text:
        button = TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButtonContent(BuildContext context, ThemeData theme, TextStyle textStyle) {
    if (isLoading) {
      return SizedBox(
        height: _getIconSize(),
        width: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            customTextColor ?? _getDefaultTextColor(theme),
          ),
        ),
      );
    }

    final textWidget = Text(
      text,
      style: textStyle,
      textAlign: TextAlign.center,
    );

    if (icon == null) {
      return textWidget;
    }

    final iconWidget = Icon(
      icon,
      size: _getIconSize(),
      color: customTextColor ?? _getDefaultTextColor(theme),
    );

    if (iconOnRight) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          textWidget,
          const SizedBox(width: 8),
          iconWidget,
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: 8),
          textWidget,
        ],
      );
    }
  }

  ButtonStyle _getButtonStyle(BuildContext context, ThemeData theme, bool isEnabled) {
    final backgroundColor = _getBackgroundColor(theme);
    final foregroundColor = customTextColor ?? _getDefaultTextColor(theme);
    final borderColor = _getBorderColor(theme);
    final padding = _getPadding();
    final borderRadius = customBorderRadius ?? _getBorderRadius();

    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return theme.colorScheme.onSurface.withValues(alpha: 0.12);
        }
        return backgroundColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return theme.colorScheme.onSurface.withValues(alpha: 0.38);
        }
        return foregroundColor;
      }),
      side: variant == ButtonVariant.outline
          ? WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                );
              }
              return BorderSide(color: borderColor);
            })
          : null,
      padding: WidgetStateProperty.all(padding),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      elevation: WidgetStateProperty.all(elevation ?? _getDefaultElevation()),
    );
  }

  TextStyle _getTextStyle(BuildContext context, ThemeData theme, bool isEnabled) {
    final baseStyle = switch (size) {
      ButtonSize.small => theme.textTheme.bodySmall,
      ButtonSize.medium => theme.textTheme.bodyMedium,
      ButtonSize.large => theme.textTheme.bodyLarge,
    };

    return baseStyle?.copyWith(
      fontWeight: FontWeight.w600,
      color: isEnabled 
          ? (customTextColor ?? _getDefaultTextColor(theme))
          : theme.colorScheme.onSurface.withValues(alpha: 0.38),
    ) ?? const TextStyle();
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (customColor != null) return customColor!;

    return switch (variant) {
      ButtonVariant.primary => theme.colorScheme.primary,
      ButtonVariant.secondary => theme.colorScheme.secondary,
      ButtonVariant.outline => Colors.transparent,
      ButtonVariant.outlined => Colors.transparent,
      ButtonVariant.text => Colors.transparent,
      ButtonVariant.danger => Colors.red,
      ButtonVariant.success => Colors.green,
    };
  }

  Color _getDefaultTextColor(ThemeData theme) {
    return switch (variant) {
      ButtonVariant.primary => theme.colorScheme.onPrimary,
      ButtonVariant.secondary => theme.colorScheme.onSecondary,
      ButtonVariant.outline => customColor ?? theme.colorScheme.primary,
      ButtonVariant.outlined => customColor ?? theme.colorScheme.primary,
      ButtonVariant.text => customColor ?? theme.colorScheme.primary,
      ButtonVariant.danger => Colors.white,
      ButtonVariant.success => Colors.white,
    };
  }

  Color _getBorderColor(ThemeData theme) {
    if (customColor != null) return customColor!;

    return switch (variant) {
      ButtonVariant.outline => theme.colorScheme.primary,
      _ => Colors.transparent,
    };
  }

  EdgeInsetsGeometry _getPadding() {
    if (customPadding != null) return customPadding!;

    return switch (size) {
      ButtonSize.small => const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ButtonSize.medium => const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ButtonSize.large => const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    };
  }

  double _getBorderRadius() {
    return switch (size) {
      ButtonSize.small => 6,
      ButtonSize.medium => 8,
      ButtonSize.large => 10,
    };
  }

  double _getIconSize() {
    return switch (size) {
      ButtonSize.small => 16,
      ButtonSize.medium => 18,
      ButtonSize.large => 20,
    };
  }

  double _getDefaultElevation() {
    return switch (variant) {
      ButtonVariant.primary => 2,
      ButtonVariant.secondary => 1,
      ButtonVariant.outline => 0,
      ButtonVariant.outlined => 0,
      ButtonVariant.text => 0,
      ButtonVariant.danger => 2,
      ButtonVariant.success => 2,
    };
  }
}

/// Predefined button variants for common use cases
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final ButtonSize size;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.primary,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final ButtonSize size;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.secondary,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }
}

class OutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final ButtonSize size;

  const OutlineButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.outline,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }
}

class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final ButtonSize size;

  const DangerButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.danger,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }
}
