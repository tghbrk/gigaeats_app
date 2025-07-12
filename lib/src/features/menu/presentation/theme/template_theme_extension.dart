import 'package:flutter/material.dart';

/// Material Design 3 theme extension for template-only customization interface
class TemplateThemeExtension extends ThemeExtension<TemplateThemeExtension> {
  // Template Card Colors
  final Color templateCardBackground;
  final Color templateCardSelectedBackground;
  final Color templateCardBorder;
  final Color templateCardSelectedBorder;
  final Color templateCardShadow;

  // Template Status Colors
  final Color templateActiveColor;
  final Color templateInactiveColor;
  final Color templateRequiredColor;
  final Color templateOptionalColor;

  // Category Colors
  final Color sizeOptionsColor;
  final Color addOnsColor;
  final Color spiceLevelColor;
  final Color cookingStyleColor;
  final Color dietaryColor;
  final Color otherCategoryColor;

  // Preview Colors
  final Color previewBackgroundColor;
  final Color previewBorderColor;
  final Color previewHighlightColor;

  // Interactive Colors
  final Color selectionIndicatorColor;
  final Color dragHandleColor;
  final Color reorderIndicatorColor;

  // Surface Variants
  final Color surfaceContainerLow;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;

  const TemplateThemeExtension({
    required this.templateCardBackground,
    required this.templateCardSelectedBackground,
    required this.templateCardBorder,
    required this.templateCardSelectedBorder,
    required this.templateCardShadow,
    required this.templateActiveColor,
    required this.templateInactiveColor,
    required this.templateRequiredColor,
    required this.templateOptionalColor,
    required this.sizeOptionsColor,
    required this.addOnsColor,
    required this.spiceLevelColor,
    required this.cookingStyleColor,
    required this.dietaryColor,
    required this.otherCategoryColor,
    required this.previewBackgroundColor,
    required this.previewBorderColor,
    required this.previewHighlightColor,
    required this.selectionIndicatorColor,
    required this.dragHandleColor,
    required this.reorderIndicatorColor,
    required this.surfaceContainerLow,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
  });

  /// Light theme configuration
  static const TemplateThemeExtension light = TemplateThemeExtension(
    // Template Card Colors
    templateCardBackground: Color(0xFFFFFFFF),
    templateCardSelectedBackground: Color(0xFFF3E5F5),
    templateCardBorder: Color(0xFFE0E0E0),
    templateCardSelectedBorder: Color(0xFF9C27B0),
    templateCardShadow: Color(0x1A000000),

    // Template Status Colors
    templateActiveColor: Color(0xFF4CAF50),
    templateInactiveColor: Color(0xFF9E9E9E),
    templateRequiredColor: Color(0xFFFF5722),
    templateOptionalColor: Color(0xFF2196F3),

    // Category Colors
    sizeOptionsColor: Color(0xFF3F51B5),
    addOnsColor: Color(0xFFFF9800),
    spiceLevelColor: Color(0xFFF44336),
    cookingStyleColor: Color(0xFF795548),
    dietaryColor: Color(0xFF4CAF50),
    otherCategoryColor: Color(0xFF607D8B),

    // Preview Colors
    previewBackgroundColor: Color(0xFFF8F9FA),
    previewBorderColor: Color(0xFFDEE2E6),
    previewHighlightColor: Color(0xFFE3F2FD),

    // Interactive Colors
    selectionIndicatorColor: Color(0xFF1976D2),
    dragHandleColor: Color(0xFF757575),
    reorderIndicatorColor: Color(0xFF2196F3),

    // Surface Variants
    surfaceContainerLow: Color(0xFFF7F2FA),
    surfaceContainerHigh: Color(0xFFECE6F0),
    surfaceContainerHighest: Color(0xFFE6E0E9),
  );

  /// Dark theme configuration
  static const TemplateThemeExtension dark = TemplateThemeExtension(
    // Template Card Colors
    templateCardBackground: Color(0xFF1E1E1E),
    templateCardSelectedBackground: Color(0xFF2D1B2E),
    templateCardBorder: Color(0xFF424242),
    templateCardSelectedBorder: Color(0xFFBA68C8),
    templateCardShadow: Color(0x33000000),

    // Template Status Colors
    templateActiveColor: Color(0xFF66BB6A),
    templateInactiveColor: Color(0xFF757575),
    templateRequiredColor: Color(0xFFFF7043),
    templateOptionalColor: Color(0xFF42A5F5),

    // Category Colors
    sizeOptionsColor: Color(0xFF5C6BC0),
    addOnsColor: Color(0xFFFFB74D),
    spiceLevelColor: Color(0xFFEF5350),
    cookingStyleColor: Color(0xFFA1887F),
    dietaryColor: Color(0xFF66BB6A),
    otherCategoryColor: Color(0xFF78909C),

    // Preview Colors
    previewBackgroundColor: Color(0xFF121212),
    previewBorderColor: Color(0xFF424242),
    previewHighlightColor: Color(0xFF1E3A8A),

    // Interactive Colors
    selectionIndicatorColor: Color(0xFF1E88E5),
    dragHandleColor: Color(0xFF9E9E9E),
    reorderIndicatorColor: Color(0xFF42A5F5),

    // Surface Variants
    surfaceContainerLow: Color(0xFF1A1A1A),
    surfaceContainerHigh: Color(0xFF2A2A2A),
    surfaceContainerHighest: Color(0xFF333333),
  );

  @override
  TemplateThemeExtension copyWith({
    Color? templateCardBackground,
    Color? templateCardSelectedBackground,
    Color? templateCardBorder,
    Color? templateCardSelectedBorder,
    Color? templateCardShadow,
    Color? templateActiveColor,
    Color? templateInactiveColor,
    Color? templateRequiredColor,
    Color? templateOptionalColor,
    Color? sizeOptionsColor,
    Color? addOnsColor,
    Color? spiceLevelColor,
    Color? cookingStyleColor,
    Color? dietaryColor,
    Color? otherCategoryColor,
    Color? previewBackgroundColor,
    Color? previewBorderColor,
    Color? previewHighlightColor,
    Color? selectionIndicatorColor,
    Color? dragHandleColor,
    Color? reorderIndicatorColor,
    Color? surfaceContainerLow,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
  }) {
    return TemplateThemeExtension(
      templateCardBackground: templateCardBackground ?? this.templateCardBackground,
      templateCardSelectedBackground: templateCardSelectedBackground ?? this.templateCardSelectedBackground,
      templateCardBorder: templateCardBorder ?? this.templateCardBorder,
      templateCardSelectedBorder: templateCardSelectedBorder ?? this.templateCardSelectedBorder,
      templateCardShadow: templateCardShadow ?? this.templateCardShadow,
      templateActiveColor: templateActiveColor ?? this.templateActiveColor,
      templateInactiveColor: templateInactiveColor ?? this.templateInactiveColor,
      templateRequiredColor: templateRequiredColor ?? this.templateRequiredColor,
      templateOptionalColor: templateOptionalColor ?? this.templateOptionalColor,
      sizeOptionsColor: sizeOptionsColor ?? this.sizeOptionsColor,
      addOnsColor: addOnsColor ?? this.addOnsColor,
      spiceLevelColor: spiceLevelColor ?? this.spiceLevelColor,
      cookingStyleColor: cookingStyleColor ?? this.cookingStyleColor,
      dietaryColor: dietaryColor ?? this.dietaryColor,
      otherCategoryColor: otherCategoryColor ?? this.otherCategoryColor,
      previewBackgroundColor: previewBackgroundColor ?? this.previewBackgroundColor,
      previewBorderColor: previewBorderColor ?? this.previewBorderColor,
      previewHighlightColor: previewHighlightColor ?? this.previewHighlightColor,
      selectionIndicatorColor: selectionIndicatorColor ?? this.selectionIndicatorColor,
      dragHandleColor: dragHandleColor ?? this.dragHandleColor,
      reorderIndicatorColor: reorderIndicatorColor ?? this.reorderIndicatorColor,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest ?? this.surfaceContainerHighest,
    );
  }

  @override
  TemplateThemeExtension lerp(ThemeExtension<TemplateThemeExtension>? other, double t) {
    if (other is! TemplateThemeExtension) {
      return this;
    }

    return TemplateThemeExtension(
      templateCardBackground: Color.lerp(templateCardBackground, other.templateCardBackground, t)!,
      templateCardSelectedBackground: Color.lerp(templateCardSelectedBackground, other.templateCardSelectedBackground, t)!,
      templateCardBorder: Color.lerp(templateCardBorder, other.templateCardBorder, t)!,
      templateCardSelectedBorder: Color.lerp(templateCardSelectedBorder, other.templateCardSelectedBorder, t)!,
      templateCardShadow: Color.lerp(templateCardShadow, other.templateCardShadow, t)!,
      templateActiveColor: Color.lerp(templateActiveColor, other.templateActiveColor, t)!,
      templateInactiveColor: Color.lerp(templateInactiveColor, other.templateInactiveColor, t)!,
      templateRequiredColor: Color.lerp(templateRequiredColor, other.templateRequiredColor, t)!,
      templateOptionalColor: Color.lerp(templateOptionalColor, other.templateOptionalColor, t)!,
      sizeOptionsColor: Color.lerp(sizeOptionsColor, other.sizeOptionsColor, t)!,
      addOnsColor: Color.lerp(addOnsColor, other.addOnsColor, t)!,
      spiceLevelColor: Color.lerp(spiceLevelColor, other.spiceLevelColor, t)!,
      cookingStyleColor: Color.lerp(cookingStyleColor, other.cookingStyleColor, t)!,
      dietaryColor: Color.lerp(dietaryColor, other.dietaryColor, t)!,
      otherCategoryColor: Color.lerp(otherCategoryColor, other.otherCategoryColor, t)!,
      previewBackgroundColor: Color.lerp(previewBackgroundColor, other.previewBackgroundColor, t)!,
      previewBorderColor: Color.lerp(previewBorderColor, other.previewBorderColor, t)!,
      previewHighlightColor: Color.lerp(previewHighlightColor, other.previewHighlightColor, t)!,
      selectionIndicatorColor: Color.lerp(selectionIndicatorColor, other.selectionIndicatorColor, t)!,
      dragHandleColor: Color.lerp(dragHandleColor, other.dragHandleColor, t)!,
      reorderIndicatorColor: Color.lerp(reorderIndicatorColor, other.reorderIndicatorColor, t)!,
      surfaceContainerLow: Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t)!,
      surfaceContainerHigh: Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      surfaceContainerHighest: Color.lerp(surfaceContainerHighest, other.surfaceContainerHighest, t)!,
    );
  }

  /// Get category color by name
  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'size options':
        return sizeOptionsColor;
      case 'add-ons':
        return addOnsColor;
      case 'spice level':
        return spiceLevelColor;
      case 'cooking style':
        return cookingStyleColor;
      case 'dietary':
        return dietaryColor;
      default:
        return otherCategoryColor;
    }
  }

  /// Get category icon by name
  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'size options':
        return Icons.straighten;
      case 'add-ons':
        return Icons.add_circle_outline;
      case 'spice level':
        return Icons.local_fire_department;
      case 'cooking style':
        return Icons.restaurant;
      case 'dietary':
        return Icons.eco;
      default:
        return Icons.category;
    }
  }
}

/// Extension to easily access template theme from BuildContext
extension TemplateThemeExtensionContext on BuildContext {
  TemplateThemeExtension get templateTheme {
    return Theme.of(this).extension<TemplateThemeExtension>() ?? TemplateThemeExtension.light;
  }
}
