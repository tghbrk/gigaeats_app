import 'package:flutter/material.dart';
import '../widgets/buttons/ge_button.dart';

/// Migration compatibility layer for CustomButton implementations
///
/// This file provides compatibility wrappers to ease migration from
/// the old CustomButton implementations to the new GEButton design system.
///
/// DEPRECATED: Use GEButton directly instead of these compatibility wrappers.
/// This file will be removed in a future version.

// Legacy ButtonType enum mapping
enum ButtonType { primary, secondary, outline, text }

// Legacy ButtonSize enum mapping
enum ButtonSize { small, medium, large }

// Legacy ButtonVariant enum mapping
enum ButtonVariant { primary, secondary, outline, outlined, text, danger, success }

/// Compatibility wrapper for the old CustomButton from lib/src/shared/widgets/custom_button.dart
@Deprecated('Use GEButton instead')
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
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
    this.type = ButtonType.primary,
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
    // Map old ButtonType to new GEButtonVariant
    final variant = _mapButtonTypeToVariant(type);

    return GEButton(
      text: text,
      onPressed: onPressed,
      variant: variant,
      size: GEButtonSize.medium,
      isLoading: isLoading,
      isExpanded: isExpanded,
      icon: icon,
      customColor: backgroundColor,
    );
  }

  GEButtonVariant _mapButtonTypeToVariant(ButtonType type) {
    switch (type) {
      case ButtonType.primary:
        return GEButtonVariant.primary;
      case ButtonType.secondary:
        return GEButtonVariant.secondary;
      case ButtonType.outline:
        return GEButtonVariant.outline;
      case ButtonType.text:
        return GEButtonVariant.ghost;
    }
  }
}

/// Compatibility wrapper for the enhanced CustomButton from lib/src/features/shared/widgets/custom_button.dart
@Deprecated('Use GEButton instead')
class EnhancedCustomButton extends StatelessWidget {
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

  const EnhancedCustomButton({
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
    // Map old enums to new GE enums
    final geVariant = _mapButtonVariantToGEVariant(variant);
    final geSize = _mapButtonSizeToGESize(size);

    return GEButton(
      text: text,
      onPressed: onPressed,
      variant: geVariant,
      size: geSize,
      isLoading: isLoading,
      isExpanded: isFullWidth,
      icon: icon,
      trailingIcon: iconOnRight ? icon : null,
      customColor: customColor,
    );
  }

  GEButtonVariant _mapButtonVariantToGEVariant(ButtonVariant variant) {
    switch (variant) {
      case ButtonVariant.primary:
        return GEButtonVariant.primary;
      case ButtonVariant.secondary:
        return GEButtonVariant.secondary;
      case ButtonVariant.outline:
      case ButtonVariant.outlined:
        return GEButtonVariant.outline;
      case ButtonVariant.text:
        return GEButtonVariant.ghost;
      case ButtonVariant.danger:
        return GEButtonVariant.danger;
      case ButtonVariant.success:
        return GEButtonVariant.primary; // Map success to primary with green color
    }
  }

  GEButtonSize _mapButtonSizeToGESize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return GEButtonSize.small;
      case ButtonSize.medium:
        return GEButtonSize.medium;
      case ButtonSize.large:
        return GEButtonSize.large;
    }
  }
}

/// Compatibility wrappers for specialized button variants
@Deprecated('Use GEButton.primary() instead')
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final ButtonSize size;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return GEButton.primary(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      isExpanded: isExpanded,
      size: _mapButtonSizeToGESize(size),
    );
  }

  GEButtonSize _mapButtonSizeToGESize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return GEButtonSize.small;
      case ButtonSize.medium:
        return GEButtonSize.medium;
      case ButtonSize.large:
        return GEButtonSize.large;
    }
  }
}

@Deprecated('Use GEButton.secondary() instead')
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final ButtonSize size;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return GEButton.secondary(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      isExpanded: isExpanded,
      size: _mapButtonSizeToGESize(size),
    );
  }

  GEButtonSize _mapButtonSizeToGESize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return GEButtonSize.small;
      case ButtonSize.medium:
        return GEButtonSize.medium;
      case ButtonSize.large:
        return GEButtonSize.large;
    }
  }
}

@Deprecated('Use GEButton.outline() instead')
class OutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final ButtonSize size;

  const OutlineButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return GEButton.outline(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      isExpanded: isExpanded,
      size: _mapButtonSizeToGESize(size),
    );
  }

  GEButtonSize _mapButtonSizeToGESize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return GEButtonSize.small;
      case ButtonSize.medium:
        return GEButtonSize.medium;
      case ButtonSize.large:
        return GEButtonSize.large;
    }
  }
}

@Deprecated('Use GEButton.danger() instead')
class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final ButtonSize size;

  const DangerButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return GEButton.danger(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      isExpanded: isExpanded,
      size: _mapButtonSizeToGESize(size),
    );
  }

  GEButtonSize _mapButtonSizeToGESize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return GEButtonSize.small;
      case ButtonSize.medium:
        return GEButtonSize.medium;
      case ButtonSize.large:
        return GEButtonSize.large;
    }
  }
}
