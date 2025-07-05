import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../providers/vendor_profile_edit_providers.dart';

/// A multi-select widget for choosing cuisine types
/// Follows Material Design 3 patterns with FilterChip components
class CuisineTypesSelector extends ConsumerWidget {
  const CuisineTypesSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final editState = ref.watch(vendorProfileEditProvider);
    final hasError = ref.watch(fieldErrorProvider('cuisineTypes')) != null;
    final errorMessage = ref.watch(fieldErrorProvider('cuisineTypes'));

    // Debug logging
    debugPrint('🍽️ [CUISINE-SELECTOR] Building with ${editState.cuisineTypes.length} selected cuisines: ${editState.cuisineTypes}');
    debugPrint('🍽️ [CUISINE-SELECTOR] Has error: $hasError, Error message: $errorMessage');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with required indicator
        Row(
          children: [
            Text(
              'Cuisine Types',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Helper text
        Text(
          'Select the cuisine types that best describe your food offerings',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        
        // Cuisine type chips
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError 
                  ? theme.colorScheme.error 
                  : theme.colorScheme.outline,
              width: hasError ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: hasError 
                ? theme.colorScheme.errorContainer.withValues(alpha: 0.1)
                : null,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.availableCuisineTypes.map((cuisine) {
              final isSelected = editState.cuisineTypes.contains(cuisine);
              
              return FilterChip(
                label: Text(cuisine),
                selected: isSelected,
                onSelected: (selected) {
                  _handleCuisineSelection(ref, cuisine, selected, editState.cuisineTypes);
                },
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                selectedColor: theme.colorScheme.primaryContainer,
                checkmarkColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected 
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: isSelected ? 1.5 : 1,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ),
        
        // Error message display
        if (hasError) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
        
        // Selection count indicator
        if (editState.cuisineTypes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${editState.cuisineTypes.length} cuisine type${editState.cuisineTypes.length == 1 ? '' : 's'} selected',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Handle cuisine type selection/deselection
  void _handleCuisineSelection(
    WidgetRef ref,
    String cuisine,
    bool selected,
    List<String> currentCuisines,
  ) {
    debugPrint('🍽️ [CUISINE-SELECTOR] Handling selection: $cuisine, selected: $selected');
    debugPrint('🍽️ [CUISINE-SELECTOR] Current cuisines: $currentCuisines');

    final updatedCuisines = List<String>.from(currentCuisines);

    if (selected) {
      if (!updatedCuisines.contains(cuisine)) {
        updatedCuisines.add(cuisine);
      }
    } else {
      updatedCuisines.remove(cuisine);
    }

    debugPrint('🍽️ [CUISINE-SELECTOR] Updated cuisines: $updatedCuisines');

    // Update the provider state
    ref.read(vendorProfileEditProvider.notifier).updateCuisineTypes(updatedCuisines);
  }
}
