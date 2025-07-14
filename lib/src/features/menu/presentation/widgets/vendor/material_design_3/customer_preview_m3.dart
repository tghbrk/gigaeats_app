import 'package:flutter/material.dart';

import '../../../../data/models/customization_template.dart';
import '../../../theme/template_theme_extension.dart';

/// Material Design 3 enhanced customer preview component
class CustomerPreviewM3 extends StatefulWidget {
  final List<CustomizationTemplate> templates;
  final String menuItemName;
  final double basePrice;
  final bool showPriceRange;
  final bool showInteractiveDemo;

  const CustomerPreviewM3({
    super.key,
    required this.templates,
    required this.menuItemName,
    required this.basePrice,
    this.showPriceRange = true,
    this.showInteractiveDemo = true,
  });

  @override
  State<CustomerPreviewM3> createState() => _CustomerPreviewM3State();
}

class _CustomerPreviewM3State extends State<CustomerPreviewM3>
    with TickerProviderStateMixin {
  late AnimationController _previewAnimationController;
  late Animation<double> _fadeAnimation;
  final Map<String, dynamic> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    _previewAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _previewAnimationController,
      curve: Curves.easeInOut,
    );

    _previewAnimationController.forward();
    _initializeDefaultSelections();
  }

  @override
  void dispose() {
    _previewAnimationController.dispose();
    super.dispose();
  }

  void _initializeDefaultSelections() {
    for (final template in widget.templates) {
      if (template.isRequired && template.options.isNotEmpty) {
        final defaultOption = template.options.firstWhere(
          (option) => option.isDefault,
          orElse: () => template.options.first,
        );
        
        if (template.isSingleSelection) {
          _selectedOptions[template.id] = defaultOption.id;
        } else {
          _selectedOptions[template.id] = [defaultOption.id];
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templateTheme = context.templateTheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: templateTheme.previewBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview Header
              _buildPreviewHeader(theme, templateTheme),
              
              const SizedBox(height: 20),
              
              // Menu Item Info
              _buildMenuItemInfo(theme, templateTheme),
              
              const SizedBox(height: 24),
              
              // Customization Options
              if (widget.templates.isNotEmpty) ...[
                Text(
                  'Customize Your Order',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                
                ...widget.templates.map((template) => 
                  _buildTemplateSection(template, theme, templateTheme),
                ),
              ] else ...[
                _buildEmptyState(theme, templateTheme),
              ],
              
              const SizedBox(height: 24),
              
              // Price Summary and Add to Cart
              _buildPriceSummaryAndActions(theme, templateTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewHeader(ThemeData theme, TemplateThemeExtension templateTheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.preview,
            color: theme.colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer View Preview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                'How customers will see this item',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: templateTheme.previewHighlightColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'PREVIEW',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItemInfo(ThemeData theme, TemplateThemeExtension templateTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: templateTheme.previewBorderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Placeholder Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: templateTheme.previewBorderColor,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.restaurant,
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.menuItemName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.showPriceRange) ...[
                  Text(
                    _getPriceRangeText(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else ...[
                  Text(
                    'RM${widget.basePrice.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection(
    CustomizationTemplate template,
    ThemeData theme,
    TemplateThemeExtension templateTheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: templateTheme.previewBorderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template Header
          Row(
            children: [
              Text(
                template.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (template.isRequired) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: templateTheme.templateRequiredColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Required',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: templateTheme.templateRequiredColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          if (template.description != null && template.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              template.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Options
          ...template.options.map((option) {
            final isSelected = _isOptionSelected(template, option.id);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: widget.showInteractiveDemo 
                    ? () => _toggleOption(template, option.id)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                        : templateTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? theme.colorScheme.primary
                          : templateTheme.previewBorderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Selection Indicator
                      Icon(
                        template.isSingleSelection 
                            ? (isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked)
                            : (isSelected ? Icons.check_box : Icons.check_box_outline_blank),
                        color: isSelected 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Option Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected 
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            // Note: TemplateOption doesn't have description field
                          ],
                        ),
                      ),
                      
                      // Price
                      if (option.additionalPrice > 0)
                        Text(
                          '+RM${option.additionalPrice.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, TemplateThemeExtension templateTheme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: templateTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: templateTheme.previewBorderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.tune_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Customization Options',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add templates to see how customers will customize this item',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummaryAndActions(ThemeData theme, TemplateThemeExtension templateTheme) {
    final totalPrice = _calculateTotalPrice();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Price',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'RM${totalPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          FilledButton.icon(
            onPressed: () {
              // Demo action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This is a preview - customers would add to cart here'),
                ),
              );
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Add to Cart'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  bool _isOptionSelected(CustomizationTemplate template, String optionId) {
    final selection = _selectedOptions[template.id];
    if (selection == null) return false;
    
    if (template.isSingleSelection) {
      return selection == optionId;
    } else {
      return (selection as List).contains(optionId);
    }
  }

  void _toggleOption(CustomizationTemplate template, String optionId) {
    setState(() {
      if (template.isSingleSelection) {
        _selectedOptions[template.id] = optionId;
      } else {
        final currentSelection = _selectedOptions[template.id] as List? ?? [];
        if (currentSelection.contains(optionId)) {
          currentSelection.remove(optionId);
        } else {
          currentSelection.add(optionId);
        }
        _selectedOptions[template.id] = currentSelection;
      }
    });
  }

  double _calculateTotalPrice() {
    double total = widget.basePrice;
    
    for (final template in widget.templates) {
      final selection = _selectedOptions[template.id];
      if (selection != null) {
        if (template.isSingleSelection) {
          final option = template.options.firstWhere(
            (opt) => opt.id == selection,
            orElse: () => template.options.first,
          );
          total += option.additionalPrice;
        } else {
          final selectedIds = selection as List;
          for (final optionId in selectedIds) {
            final option = template.options.firstWhere(
              (opt) => opt.id == optionId,
              orElse: () => template.options.first,
            );
            total += option.additionalPrice;
          }
        }
      }
    }
    
    return total;
  }

  String _getPriceRangeText() {
    if (widget.templates.isEmpty) {
      return 'RM${widget.basePrice.toStringAsFixed(2)}';
    }

    double minPrice = widget.basePrice;
    double maxPrice = widget.basePrice;

    for (final template in widget.templates) {
      if (template.options.isNotEmpty) {
        final minOptionPrice = template.options
            .map((opt) => opt.additionalPrice)
            .reduce((min, price) => price < min ? price : min);
        final maxOptionPrice = template.options
            .map((opt) => opt.additionalPrice)
            .reduce((max, price) => price > max ? price : max);
        
        if (template.isRequired) {
          minPrice += minOptionPrice;
        }
        
        if (template.isSingleSelection) {
          maxPrice += maxOptionPrice;
        } else {
          maxPrice += template.options
              .map((opt) => opt.additionalPrice)
              .fold(0.0, (sum, price) => sum + price);
        }
      }
    }

    if (minPrice == maxPrice) {
      return 'RM${minPrice.toStringAsFixed(2)}';
    } else {
      return 'RM${minPrice.toStringAsFixed(2)} - RM${maxPrice.toStringAsFixed(2)}';
    }
  }
}
