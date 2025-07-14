import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/customization_template.dart';

/// Component that shows vendors how selected templates will appear to customers
class CustomerPreviewComponent extends ConsumerStatefulWidget {
  final List<CustomizationTemplate> selectedTemplates;
  final String menuItemName;
  final double basePrice;
  final bool showInteractive;

  const CustomerPreviewComponent({
    super.key,
    required this.selectedTemplates,
    required this.menuItemName,
    required this.basePrice,
    this.showInteractive = true,
  });

  @override
  ConsumerState<CustomerPreviewComponent> createState() => _CustomerPreviewComponentState();
}

class _CustomerPreviewComponentState extends ConsumerState<CustomerPreviewComponent> {
  final Map<String, dynamic> _previewSelections = {};
  double _additionalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeDefaultSelections();
  }

  @override
  void didUpdateWidget(CustomerPreviewComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTemplates != widget.selectedTemplates) {
      _initializeDefaultSelections();
    }
  }

  void _initializeDefaultSelections() {
    debugPrint('🔍 [CUSTOMER-PREVIEW] Initializing default selections for ${widget.selectedTemplates.length} templates');
    _previewSelections.clear();
    _additionalPrice = 0.0;

    for (final template in widget.selectedTemplates) {
      if (template.isRequired && template.options.isNotEmpty) {
        final defaultOption = template.options.firstWhere(
          (option) => option.isDefault,
          orElse: () => template.options.first,
        );

        if (template.isSingleSelection) {
          _previewSelections[template.id] = {
            'id': defaultOption.id,
            'name': defaultOption.name,
            'price': defaultOption.additionalPrice,
          };
          _additionalPrice += defaultOption.additionalPrice;
        }
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.selectedTemplates.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(theme),
          
          // Preview Content
          Container(
            constraints: const BoxConstraints(maxHeight: 500),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Menu Item Info
                  _buildMenuItemInfo(theme),
                  
                  // Customizations Preview
                  _buildCustomizationsPreview(theme),
                  
                  // Price Summary
                  _buildPriceSummary(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.preview,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Customer Preview',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select templates to see how they will appear to customers',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.preview,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Preview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'How customers will see your customizations',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.selectedTemplates.length} template${widget.selectedTemplates.length == 1 ? '' : 's'}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.menuItemName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Base Price: RM ${widget.basePrice.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationsPreview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Customize Your Order',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...widget.selectedTemplates.map((template) => _buildTemplatePreview(template, theme)),
      ],
    );
  }

  Widget _buildTemplatePreview(CustomizationTemplate template, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template Header
            Row(
              children: [
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
              const SizedBox(height: 4),
              Text(
                template.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Options
            if (template.isSingleSelection)
              _buildSingleSelectionPreview(template, theme)
            else
              _buildMultipleSelectionPreview(template, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleSelectionPreview(CustomizationTemplate template, ThemeData theme) {
    final selectedOptionId = _previewSelections[template.id]?['id'] as String?;

    return Column(
      children: template.options.map((option) {
        final isSelected = selectedOptionId == option.id;

        return RadioListTile<String>(
          value: option.id,
          groupValue: selectedOptionId,
          onChanged: widget.showInteractive ? (value) {
            debugPrint('🔍 [CUSTOMER-PREVIEW] Single selection changed: ${template.name} -> ${option.name}');
            setState(() {
              // Remove previous selection price
              final previousSelection = _previewSelections[template.id];
              if (previousSelection != null) {
                _additionalPrice -= (previousSelection['price'] as double? ?? 0.0);
              }

              // Add new selection
              _previewSelections[template.id] = {
                'id': option.id,
                'name': option.name,
                'price': option.additionalPrice,
              };
              _additionalPrice += option.additionalPrice;
            });
          } : null,
          title: Text(
            option.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          subtitle: option.additionalPrice > 0
              ? Text(
                  '+ RM ${option.additionalPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : null,
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeColor: theme.colorScheme.primary,
        );
      }).toList(),
    );
  }

  Widget _buildMultipleSelectionPreview(CustomizationTemplate template, ThemeData theme) {
    final selectedOptions = _previewSelections[template.id] as List<Map<String, dynamic>>? ?? [];

    return Column(
      children: template.options.map((option) {
        final isSelected = selectedOptions.any((selected) => selected['id'] == option.id);

        return CheckboxListTile(
          value: isSelected,
          onChanged: widget.showInteractive ? (value) {
            debugPrint('🔍 [CUSTOMER-PREVIEW] Multiple selection changed: ${template.name} -> ${option.name} ($value)');
            setState(() {
              final currentSelections = List<Map<String, dynamic>>.from(selectedOptions);

              if (value == true) {
                currentSelections.add({
                  'id': option.id,
                  'name': option.name,
                  'price': option.additionalPrice,
                });
                _additionalPrice += option.additionalPrice;
              } else {
                currentSelections.removeWhere((item) => item['id'] == option.id);
                _additionalPrice -= option.additionalPrice;
              }

              _previewSelections[template.id] = currentSelections;
            });
          } : null,
          title: Text(
            option.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          subtitle: option.additionalPrice > 0
              ? Text(
                  '+ RM ${option.additionalPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : null,
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeColor: theme.colorScheme.primary,
        );
      }).toList(),
    );
  }

  Widget _buildPriceSummary(ThemeData theme) {
    final totalPrice = widget.basePrice + _additionalPrice;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Summary',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Base Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Base price:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'RM ${widget.basePrice.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          // Customizations Price
          if (_additionalPrice > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customizations:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '+ RM ${_additionalPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
          ],

          // Total Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'RM ${totalPrice.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),

          // Interactive Note
          if (widget.showInteractive) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Try selecting options to see how pricing changes',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
