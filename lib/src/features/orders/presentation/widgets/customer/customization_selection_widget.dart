import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../menu/data/models/product.dart';

/// Widget for selecting customization options for a menu item
class CustomizationSelectionWidget extends ConsumerStatefulWidget {
  final List<MenuItemCustomization> customizations;
  final Map<String, dynamic> selectedCustomizations;
  final Function(Map<String, dynamic>, double) onSelectionChanged;

  const CustomizationSelectionWidget({
    super.key,
    required this.customizations,
    required this.selectedCustomizations,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<CustomizationSelectionWidget> createState() => _CustomizationSelectionWidgetState();
}

class _CustomizationSelectionWidgetState extends ConsumerState<CustomizationSelectionWidget> {
  late Map<String, dynamic> _selections;

  @override
  void initState() {
    super.initState();
    _selections = Map<String, dynamic>.from(widget.selectedCustomizations);
    _initializeDefaultSelectionsWithoutCallback();
  }

  void _initializeDefaultSelectionsWithoutCallback() {
    for (final customization in widget.customizations) {
      if (!_selections.containsKey(customization.id)) {
        if (customization.type == 'single_select') {
          // For single-select, find default option or select first if required
          final defaultOption = customization.options.where((opt) => opt.isDefault).firstOrNull;
          if (defaultOption != null) {
            _selections[customization.id!] = {
              'id': defaultOption.id!,
              'name': defaultOption.name,
              'price': defaultOption.additionalPrice,
            };
          } else if (customization.isRequired && customization.options.isNotEmpty) {
            final firstOption = customization.options.first;
            _selections[customization.id!] = {
              'id': firstOption.id!,
              'name': firstOption.name,
              'price': firstOption.additionalPrice,
            };
          }
        } else if (customization.type == 'multi_select') {
          // For multi-select, select default options
          final defaultOptions = customization.options
              .where((opt) => opt.isDefault && opt.id != null)
              .map((opt) => {
                'id': opt.id!,
                'name': opt.name,
                'price': opt.additionalPrice,
              })
              .toList();
          _selections[customization.id!] = defaultOptions;
        }
      }
    }
    // Don't call _notifyChanges() during initialization to avoid setState during build
  }



  void _notifyChanges() {
    final additionalPrice = _calculateAdditionalPrice();
    widget.onSelectionChanged(_selections, additionalPrice);
  }

  double _calculateAdditionalPrice() {
    double additionalPrice = 0.0;

    for (final customization in widget.customizations) {
      final customizationId = customization.id!;
      final selection = _selections[customizationId];

      if (selection != null) {
        if (customization.type == 'single' || customization.type == 'single_select') {
          // Handle new format (Map with price) and old format (String ID)
          if (selection is Map<String, dynamic> && selection.containsKey('price')) {
            additionalPrice += (selection['price'] as num).toDouble();
          } else if (selection is String) {
            // Backward compatibility: look up option by ID
            final option = customization.options.where((opt) => opt.id == selection).firstOrNull;
            if (option != null) {
              additionalPrice += option.additionalPrice;
            }
          }
        } else if (customization.type == 'multiple' || customization.type == 'multi_select') {
          if (selection is List) {
            for (final item in selection) {
              // Handle new format (Map with price) and old format (String ID)
              if (item is Map<String, dynamic> && item.containsKey('price')) {
                additionalPrice += (item['price'] as num).toDouble();
              } else if (item is String) {
                // Backward compatibility: look up option by ID
                final option = customization.options.where((opt) => opt.id == item).firstOrNull;
                if (option != null) {
                  additionalPrice += option.additionalPrice;
                }
              }
            }
          }
        }
      }
    }

    return additionalPrice;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.customizations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Customize Your Order',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...widget.customizations.map((customization) => _buildCustomizationSection(customization)),
      ],
    );
  }

  Widget _buildCustomizationSection(MenuItemCustomization customization) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    customization.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (customization.isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Required',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (customization.type == 'single' || customization.type == 'single_select')
              _buildSingleSelectOptions(customization)
            else if (customization.type == 'multiple' || customization.type == 'multi_select')
              _buildMultiSelectOptions(customization),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleSelectOptions(MenuItemCustomization customization) {
    final selectedValue = _selections[customization.id];
    // Extract the selected option ID for comparison
    final selectedOptionId = selectedValue is Map<String, dynamic>
        ? selectedValue['id'] as String?
        : selectedValue as String?;

    return Column(
      children: customization.options.map((option) {
        return RadioListTile<String>(
          value: option.id!,
          groupValue: selectedOptionId,
          onChanged: (value) {
            setState(() {
              _selections[customization.id!] = {
                'id': option.id!,
                'name': option.name,
                'price': option.additionalPrice,
              };
            });
            _notifyChanges();
          },
          title: Text(option.name),
          subtitle: option.additionalPrice > 0
              ? Text('+ RM ${option.additionalPrice.toStringAsFixed(2)}')
              : null,
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      }).toList(),
    );
  }

  Widget _buildMultiSelectOptions(MenuItemCustomization customization) {
    final selectedValues = _selections[customization.id] as List? ?? [];

    // Extract selected option IDs for comparison
    final selectedOptionIds = selectedValues.map((item) {
      if (item is Map<String, dynamic>) {
        return item['id'] as String?;
      } else if (item is String) {
        return item;
      }
      return null;
    }).where((id) => id != null).cast<String>().toList();

    return Column(
      children: customization.options.map((option) {
        final isSelected = selectedOptionIds.contains(option.id);

        return CheckboxListTile(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              final currentSelections = List<Map<String, dynamic>>.from(
                selectedValues.whereType<Map<String, dynamic>>()
              );

              if (value == true) {
                // Add the option data
                currentSelections.add({
                  'id': option.id!,
                  'name': option.name,
                  'price': option.additionalPrice,
                });
              } else {
                // Remove the option data
                currentSelections.removeWhere((item) => item['id'] == option.id);
              }
              _selections[customization.id!] = currentSelections;
            });
            _notifyChanges();
          },
          title: Text(option.name),
          subtitle: option.additionalPrice > 0
              ? Text('+ RM ${option.additionalPrice.toStringAsFixed(2)}')
              : null,
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      }).toList(),
    );
  }
}

/// Widget for displaying special instructions input
class SpecialInstructionsWidget extends StatefulWidget {
  final String? initialInstructions;
  final Function(String?) onInstructionsChanged;

  const SpecialInstructionsWidget({
    super.key,
    this.initialInstructions,
    required this.onInstructionsChanged,
  });

  @override
  State<SpecialInstructionsWidget> createState() => _SpecialInstructionsWidgetState();
}

class _SpecialInstructionsWidgetState extends State<SpecialInstructionsWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialInstructions);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Special Instructions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any special requests or dietary requirements?',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              onChanged: widget.onInstructionsChanged,
            ),
          ],
        ),
      ),
    );
  }
}
