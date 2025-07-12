import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../menu/data/models/product.dart' as product_model;
import '../../../../menu/data/models/customization_template.dart';
import '../../../../menu/presentation/providers/customization_template_providers.dart';

/// Enhanced widget for selecting customizations including template-based ones
class EnhancedCustomizationSelectionWidget extends ConsumerStatefulWidget {
  final String menuItemId;
  final List<product_model.MenuItemCustomization> directCustomizations;
  final Map<String, dynamic> selectedCustomizations;
  final Function(Map<String, dynamic>, double) onSelectionChanged;

  const EnhancedCustomizationSelectionWidget({
    super.key,
    required this.menuItemId,
    required this.directCustomizations,
    required this.selectedCustomizations,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<EnhancedCustomizationSelectionWidget> createState() => 
      _EnhancedCustomizationSelectionWidgetState();
}

class _EnhancedCustomizationSelectionWidgetState 
    extends ConsumerState<EnhancedCustomizationSelectionWidget> {
  
  late Map<String, dynamic> _selections;

  @override
  void initState() {
    super.initState();
    _selections = Map.from(widget.selectedCustomizations);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get linked templates for this menu item
    final templatesAsync = ref.watch(menuItemTemplatesProvider(widget.menuItemId));

    return templatesAsync.when(
      data: (templates) {
        return _buildCustomizationSections(templates, theme);
      },
      loading: () {
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stack) {
        return _buildErrorState(error.toString(), theme);
      },
    );
  }

  Widget _buildCustomizationSections(List<CustomizationTemplate> templates, ThemeData theme) {
    final allCustomizations = <Widget>[];

    // Prioritize template-based customizations over direct customizations
    // to avoid duplication since templates get converted to direct customizations
    if (templates.isNotEmpty) {
      allCustomizations.add(_buildTemplateSection(templates, theme));
    } else if (widget.directCustomizations.isNotEmpty) {
      // Only show direct customizations if there are no templates
      allCustomizations.add(_buildDirectCustomizationsSection(theme));
    }

    if (allCustomizations.isEmpty) {
      return _buildNoCustomizationsState(theme);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: allCustomizations,
    );
  }

  Widget _buildTemplateSection(List<CustomizationTemplate> templates, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.directCustomizations.isNotEmpty) ...[
          Text(
            'Template Options',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        ...templates.map((template) => _buildTemplateCustomization(template, theme)),
        
        if (widget.directCustomizations.isNotEmpty) const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTemplateCustomization(CustomizationTemplate template, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template header
            Row(
              children: [
                Icon(
                  template.isSingleSelection ? Icons.radio_button_checked : Icons.check_box,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    template.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (template.isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Required',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
              ],
            ),
            
            if (template.description != null && template.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                template.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Template options
            if (template.isSingleSelection)
              _buildSingleSelectionOptions(template, theme)
            else
              _buildMultipleSelectionOptions(template, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleSelectionOptions(CustomizationTemplate template, ThemeData theme) {
    final selectedOptionId = _getSelectedOptionId(template.id);

    return Column(
      children: template.options.map((option) {
        return RadioListTile<String>(
          value: option.id,
          groupValue: selectedOptionId,
          onChanged: (value) {
            setState(() {
              _selections[template.id] = {
                'id': option.id,
                'name': option.name,
                'price': option.additionalPrice,
                'template_id': template.id,
                'template_name': template.name,
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

  Widget _buildMultipleSelectionOptions(CustomizationTemplate template, ThemeData theme) {
    final selectedOptions = _getSelectedOptions(template.id);

    return Column(
      children: template.options.map((option) {
        final isSelected = selectedOptions.any((selected) => selected['id'] == option.id);

        return CheckboxListTile(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              final currentSelections = List<Map<String, dynamic>>.from(selectedOptions);

              if (value == true) {
                currentSelections.add({
                  'id': option.id,
                  'name': option.name,
                  'price': option.additionalPrice,
                  'template_id': template.id,
                  'template_name': template.name,
                });
              } else {
                currentSelections.removeWhere((item) => item['id'] == option.id);
              }
              
              _selections[template.id] = currentSelections;
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

  Widget _buildDirectCustomizationsSection(ThemeData theme) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Options',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8),

        ...widget.directCustomizations.map((customization) =>
          _buildDirectCustomization(customization, theme)),
      ],
    );
  }

  Widget _buildDirectCustomization(product_model.MenuItemCustomization customization, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customization header
            Row(
              children: [
                Expanded(
                  child: Text(
                    customization.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (customization.isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Required',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Customization options
            Builder(
              builder: (context) {
                // Handle different type formats: 'single', 'single_select', 'radio'
                if (customization.type == 'single' ||
                    customization.type == 'single_select' ||
                    customization.type == 'radio') {
                  return _buildDirectSingleSelection(customization, theme);
                } else if (customization.type == 'multiple' ||
                           customization.type == 'multi_select' ||
                           customization.type == 'checkbox') {
                  return _buildDirectMultipleSelection(customization, theme);
                } else if (customization.type == 'text' ||
                           customization.type == 'text_input') {
                  return _buildDirectTextInput(customization, theme);
                } else {
                  // Default to single selection for unknown types
                  return _buildDirectSingleSelection(customization, theme);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectSingleSelection(product_model.MenuItemCustomization customization, ThemeData theme) {
    final customizationId = customization.id;
    if (customizationId == null) return const SizedBox.shrink();

    final selectedOptionId = _getSelectedOptionId(customizationId);

    return Column(
      children: customization.options.map((option) {
        return RadioListTile<String>(
          value: option.id!,
          groupValue: selectedOptionId,
          onChanged: (value) {
            setState(() {
              _selections[customizationId] = {
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

  Widget _buildDirectMultipleSelection(product_model.MenuItemCustomization customization, ThemeData theme) {
    final customizationId = customization.id;
    if (customizationId == null) return const SizedBox.shrink();

    final selectedOptions = _getSelectedOptions(customizationId);

    return Column(
      children: customization.options.map((option) {
        final isSelected = selectedOptions.any((selected) => selected['id'] == option.id);

        return CheckboxListTile(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              final currentSelections = List<Map<String, dynamic>>.from(selectedOptions);

              if (value == true) {
                currentSelections.add({
                  'id': option.id!,
                  'name': option.name,
                  'price': option.additionalPrice,
                });
              } else {
                currentSelections.removeWhere((item) => item['id'] == option.id);
              }

              _selections[customizationId] = currentSelections;
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

  Widget _buildDirectTextInput(product_model.MenuItemCustomization customization, ThemeData theme) {
    final customizationId = customization.id;
    if (customizationId == null) return const SizedBox.shrink();

    return TextField(
      decoration: InputDecoration(
        hintText: 'Enter ${customization.name.toLowerCase()}...',
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          _selections[customizationId] = value;
        });
        _notifyChanges();
      },
    );
  }

  Widget _buildNoCustomizationsState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.tune_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No Customizations Available',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Error Loading Customizations',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getSelectedOptionId(String customizationId) {
    final selection = _selections[customizationId];
    if (selection is Map<String, dynamic>) {
      return selection['id']?.toString();
    }
    return null;
  }

  List<Map<String, dynamic>> _getSelectedOptions(String customizationId) {
    final selection = _selections[customizationId];
    if (selection is List) {
      return selection.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  void _notifyChanges() {
    final totalAdditionalCost = _calculateTotalAdditionalCost();
    print('📢 [CUSTOMIZATION-WIDGET] Notifying parent of changes:');
    print('📢 [CUSTOMIZATION-WIDGET] Selections: $_selections');
    print('📢 [CUSTOMIZATION-WIDGET] Total additional cost: RM${totalAdditionalCost.toStringAsFixed(2)}');
    widget.onSelectionChanged(_selections, totalAdditionalCost);
  }

  double _calculateTotalAdditionalCost() {
    double total = 0.0;

    print('🧮 [CUSTOMIZATION-WIDGET] Calculating total additional cost...');
    print('🧮 [CUSTOMIZATION-WIDGET] Current selections: $_selections');

    for (final entry in _selections.entries) {
      final key = entry.key;
      final selection = entry.value;

      if (selection is Map<String, dynamic>) {
        final price = selection['price'];
        if (price is num) {
          final priceValue = price.toDouble();
          total += priceValue;
          print('🧮 [CUSTOMIZATION-WIDGET] Single selection "$key": ${selection['name']} (+RM${priceValue.toStringAsFixed(2)})');
        }
      } else if (selection is List) {
        double listTotal = 0.0;
        for (final item in selection) {
          if (item is Map<String, dynamic>) {
            final price = item['price'];
            if (price is num) {
              final priceValue = price.toDouble();
              total += priceValue;
              listTotal += priceValue;
              print('🧮 [CUSTOMIZATION-WIDGET] Multi selection "$key": ${item['name']} (+RM${priceValue.toStringAsFixed(2)})');
            }
          }
        }
        if (listTotal > 0) {
          print('🧮 [CUSTOMIZATION-WIDGET] Total for "$key": +RM${listTotal.toStringAsFixed(2)}');
        }
      }
    }

    print('🧮 [CUSTOMIZATION-WIDGET] Total additional cost: RM${total.toStringAsFixed(2)}');
    return total;
  }
}
