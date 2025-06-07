import 'package:flutter/material.dart';

class FilterChips extends StatelessWidget {
  final List<FilterChipData> chips;
  final EdgeInsetsGeometry? padding;
  final double spacing;
  final double runSpacing;

  const FilterChips({
    super.key,
    required this.chips,
    this.padding,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: chips.map((chipData) {
          return FilterChip(
            label: Text(chipData.label),
            selected: chipData.isSelected,
            onSelected: chipData.onSelected,
            deleteIcon: chipData.showDelete ? const Icon(Icons.close, size: 16) : null,
            onDeleted: chipData.onDeleted,
            backgroundColor: chipData.backgroundColor,
            selectedColor: chipData.selectedColor,
            checkmarkColor: chipData.checkmarkColor,
            labelStyle: chipData.labelStyle,
            side: chipData.borderSide,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        }).toList(),
      ),
    );
  }
}

class FilterChipData {
  final String label;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onDeleted;
  final bool showDelete;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? checkmarkColor;
  final TextStyle? labelStyle;
  final BorderSide? borderSide;

  const FilterChipData({
    required this.label,
    this.isSelected = false,
    this.onSelected,
    this.onDeleted,
    this.showDelete = false,
    this.backgroundColor,
    this.selectedColor,
    this.checkmarkColor,
    this.labelStyle,
    this.borderSide,
  });
}

class CuisineFilterChips extends StatelessWidget {
  final List<String> availableCuisines;
  final List<String> selectedCuisines;
  final ValueChanged<String>? onCuisineToggle;
  final EdgeInsetsGeometry? padding;

  const CuisineFilterChips({
    super.key,
    required this.availableCuisines,
    required this.selectedCuisines,
    this.onCuisineToggle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final chips = availableCuisines.map((cuisine) {
      final isSelected = selectedCuisines.contains(cuisine);
      
      return FilterChipData(
        label: cuisine,
        isSelected: isSelected,
        onSelected: (_) => onCuisineToggle?.call(cuisine),
        selectedColor: theme.colorScheme.primaryContainer,
        checkmarkColor: theme.colorScheme.primary,
      );
    }).toList();

    return FilterChips(
      chips: chips,
      padding: padding,
    );
  }
}

class RatingFilterChips extends StatelessWidget {
  final double? selectedRating;
  final ValueChanged<double?>? onRatingSelected;
  final EdgeInsetsGeometry? padding;

  const RatingFilterChips({
    super.key,
    this.selectedRating,
    this.onRatingSelected,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratings = [4.0, 4.5, 5.0];

    final chips = ratings.map((rating) {
      final isSelected = selectedRating == rating;
      
      return FilterChipData(
        label: '$rating+ ⭐',
        isSelected: isSelected,
        onSelected: (_) => onRatingSelected?.call(isSelected ? null : rating),
        selectedColor: theme.colorScheme.primaryContainer,
        checkmarkColor: theme.colorScheme.primary,
      );
    }).toList();

    return FilterChips(
      chips: chips,
      padding: padding,
    );
  }
}

class PriceRangeFilterChips extends StatelessWidget {
  final String? selectedPriceRange;
  final ValueChanged<String?>? onPriceRangeSelected;
  final EdgeInsetsGeometry? padding;

  const PriceRangeFilterChips({
    super.key,
    this.selectedPriceRange,
    this.onPriceRangeSelected,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceRanges = [
      'Under RM 10',
      'RM 10 - 20',
      'RM 20 - 30',
      'Above RM 30',
    ];

    final chips = priceRanges.map((range) {
      final isSelected = selectedPriceRange == range;
      
      return FilterChipData(
        label: range,
        isSelected: isSelected,
        onSelected: (_) => onPriceRangeSelected?.call(isSelected ? null : range),
        selectedColor: theme.colorScheme.primaryContainer,
        checkmarkColor: theme.colorScheme.primary,
      );
    }).toList();

    return FilterChips(
      chips: chips,
      padding: padding,
    );
  }
}

class DietaryFilterChips extends StatelessWidget {
  final List<String> selectedDietaryOptions;
  final ValueChanged<String>? onDietaryToggle;
  final EdgeInsetsGeometry? padding;

  const DietaryFilterChips({
    super.key,
    required this.selectedDietaryOptions,
    this.onDietaryToggle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dietaryOptions = [
      'Halal',
      'Vegetarian',
      'Vegan',
      'Gluten-Free',
      'Dairy-Free',
    ];

    final chips = dietaryOptions.map((option) {
      final isSelected = selectedDietaryOptions.contains(option);
      
      return FilterChipData(
        label: option,
        isSelected: isSelected,
        onSelected: (_) => onDietaryToggle?.call(option),
        selectedColor: theme.colorScheme.primaryContainer,
        checkmarkColor: theme.colorScheme.primary,
      );
    }).toList();

    return FilterChips(
      chips: chips,
      padding: padding,
    );
  }
}

class ActiveFilterChips extends StatelessWidget {
  final List<ActiveFilter> activeFilters;
  final EdgeInsetsGeometry? padding;

  const ActiveFilterChips({
    super.key,
    required this.activeFilters,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final chips = activeFilters.map((filter) {
      return FilterChipData(
        label: filter.label,
        isSelected: true,
        showDelete: true,
        onDeleted: filter.onRemove,
        selectedColor: theme.colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      );
    }).toList();

    return FilterChips(
      chips: chips,
      padding: padding,
    );
  }
}

class ActiveFilter {
  final String label;
  final VoidCallback? onRemove;

  const ActiveFilter({
    required this.label,
    this.onRemove,
  });
}

class QuickFilterChips extends StatelessWidget {
  final List<QuickFilter> quickFilters;
  final EdgeInsetsGeometry? padding;

  const QuickFilterChips({
    super.key,
    required this.quickFilters,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final chips = quickFilters.map((filter) {
      return FilterChipData(
        label: filter.label,
        isSelected: filter.isActive,
        onSelected: (_) => filter.onTap?.call(),
        selectedColor: theme.colorScheme.primaryContainer,
        checkmarkColor: theme.colorScheme.primary,
        backgroundColor: filter.backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
      );
    }).toList();

    return FilterChips(
      chips: chips,
      padding: padding,
    );
  }
}

class QuickFilter {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const QuickFilter({
    required this.label,
    this.isActive = false,
    this.onTap,
    this.backgroundColor,
  });
}
