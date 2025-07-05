import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product.dart' as product_model;
import 'enhanced_customization_dialogs.dart';

/// Enhanced customization management widget with drag-and-drop, visual pricing, and better UX
class EnhancedCustomizationManagement extends ConsumerStatefulWidget {
  final List<product_model.MenuItemCustomization> customizations;
  final Function(List<product_model.MenuItemCustomization>) onCustomizationsChanged;
  final double basePrice;
  final bool showPricingPreview;

  const EnhancedCustomizationManagement({
    super.key,
    required this.customizations,
    required this.onCustomizationsChanged,
    this.basePrice = 0.0,
    this.showPricingPreview = true,
  });

  @override
  ConsumerState<EnhancedCustomizationManagement> createState() => _EnhancedCustomizationManagementState();
}

class _EnhancedCustomizationManagementState extends ConsumerState<EnhancedCustomizationManagement> {
  late List<product_model.MenuItemCustomization> _customizations;

  @override
  void initState() {
    super.initState();
    _customizations = List.from(widget.customizations);
  }

  @override
  void didUpdateWidget(EnhancedCustomizationManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customizations != widget.customizations) {
      _customizations = List.from(widget.customizations);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        if (widget.showPricingPreview) ...[
          _buildPricingPreview(),
          const SizedBox(height: 16),
        ],
        _buildCustomizationsList(),
        const SizedBox(height: 16),
        _buildQuickTemplates(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customizations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_customizations.length} groups configured',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _addCustomizationGroup,
          icon: const Icon(Icons.add),
          label: const Text('Add Group'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingPreview() {
    final minPrice = _calculateMinPrice();
    final maxPrice = _calculateMaxPrice();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pricing Impact Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Base Price:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'RM ${widget.basePrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'With Customizations:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  minPrice == maxPrice 
                      ? 'RM ${maxPrice.toStringAsFixed(2)}'
                      : 'RM ${minPrice.toStringAsFixed(2)} - ${maxPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (_customizations.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              ..._customizations.map((customization) => 
                _buildCustomizationPricingRow(customization)
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomizationPricingRow(product_model.MenuItemCustomization customization) {
    final minPrice = customization.options.isEmpty ? 0.0 :
        customization.options
            .map((opt) => opt.additionalPrice)
            .reduce((min, price) => price < min ? price : min);
    final maxPrice = customization.options.isEmpty ? 0.0 :
        customization.options
            .map((opt) => opt.additionalPrice)
            .reduce((max, price) => price > max ? price : max);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              customization.name,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            minPrice == maxPrice 
                ? (minPrice == 0 ? 'Free' : '+RM ${maxPrice.toStringAsFixed(2)}')
                : '+RM ${minPrice.toStringAsFixed(2)} - ${maxPrice.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: minPrice == 0 && maxPrice == 0 ? Colors.grey[600] : Colors.green[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationsList() {
    if (_customizations.isEmpty) {
      return _buildEmptyState();
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _customizations.length,
      onReorder: _onReorderCustomizations,
      itemBuilder: (context, index) {
        final customization = _customizations[index];
        return EnhancedCustomizationGroupCard(
          key: ValueKey(customization.id ?? index),
          customization: customization,
          index: index,
          basePrice: widget.basePrice,
          onEdit: () => _editCustomizationGroup(index),
          onDelete: () => _deleteCustomizationGroup(index),
          onAddOption: (option) => _addOptionToGroup(index, option),
          onEditOption: (optionIndex, option) => _editOptionInGroup(index, optionIndex, option),
          onDeleteOption: (optionIndex) => _deleteOptionFromGroup(index, optionIndex),
          onReorderOptions: (oldIndex, newIndex) => _reorderOptionsInGroup(index, oldIndex, newIndex),
          showPricingPreview: widget.showPricingPreview,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 1,
      child: Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        child: Column(
          children: [
            Icon(
              Icons.tune,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Customizations Yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add customization groups to let customers personalize their orders',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addCustomizationGroup,
              icon: const Icon(Icons.add),
              label: const Text('Add First Group'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTemplates() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard_customize_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Templates',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTemplateChip('Size Options', Icons.straighten, _addSizeTemplate),
                _buildTemplateChip('Spice Level', Icons.local_fire_department, _addSpiceTemplate),
                _buildTemplateChip('Add-ons', Icons.add_circle_outline, _addAddonsTemplate),
                _buildTemplateChip('Cooking Style', Icons.restaurant, _addCookingStyleTemplate),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      side: BorderSide(color: Theme.of(context).colorScheme.outline),
    );
  }

  // Calculation methods
  double _calculateMinPrice() {
    double total = widget.basePrice;
    for (final customization in _customizations) {
      if (customization.options.isNotEmpty) {
        final minOptionPrice = customization.options
            .map((opt) => opt.additionalPrice)
            .reduce((min, price) => price < min ? price : min);
        total += minOptionPrice;
      }
    }
    return total;
  }

  double _calculateMaxPrice() {
    double total = widget.basePrice;
    for (final customization in _customizations) {
      if (customization.options.isNotEmpty) {
        if (customization.type == 'multiple') {
          // For multiple choice, sum all options
          total += customization.options
              .map((opt) => opt.additionalPrice)
              .fold(0.0, (sum, price) => sum + price);
        } else {
          // For single choice, take the maximum
          final maxOptionPrice = customization.options
              .map((opt) => opt.additionalPrice)
              .reduce((max, price) => price > max ? price : max);
          total += maxOptionPrice;
        }
      }
    }
    return total;
  }

  // Event handlers
  void _onReorderCustomizations(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _customizations.removeAt(oldIndex);
      _customizations.insert(newIndex, item);
      widget.onCustomizationsChanged(_customizations);
    });
  }

  void _addCustomizationGroup() {
    showDialog(
      context: context,
      builder: (context) => EnhancedCustomizationGroupDialog(
        onSave: (customization) {
          setState(() {
            _customizations.add(customization);
            widget.onCustomizationsChanged(_customizations);
          });
        },
      ),
    );
  }

  void _editCustomizationGroup(int index) {
    showDialog(
      context: context,
      builder: (context) => EnhancedCustomizationGroupDialog(
        customization: _customizations[index],
        onSave: (customization) {
          setState(() {
            _customizations[index] = customization;
            widget.onCustomizationsChanged(_customizations);
          });
        },
      ),
    );
  }

  void _deleteCustomizationGroup(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customization Group'),
        content: Text('Are you sure you want to delete "${_customizations[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _customizations.removeAt(index);
                widget.onCustomizationsChanged(_customizations);
              });
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addOptionToGroup(int groupIndex, product_model.CustomizationOption option) {
    setState(() {
      final updatedOptions = List<product_model.CustomizationOption>.from(_customizations[groupIndex].options);
      updatedOptions.add(option);
      _customizations[groupIndex] = _customizations[groupIndex].copyWith(options: updatedOptions);
      widget.onCustomizationsChanged(_customizations);
    });
  }

  void _editOptionInGroup(int groupIndex, int optionIndex, product_model.CustomizationOption option) {
    setState(() {
      final updatedOptions = List<product_model.CustomizationOption>.from(_customizations[groupIndex].options);
      updatedOptions[optionIndex] = option;
      _customizations[groupIndex] = _customizations[groupIndex].copyWith(options: updatedOptions);
      widget.onCustomizationsChanged(_customizations);
    });
  }

  void _deleteOptionFromGroup(int groupIndex, int optionIndex) {
    setState(() {
      final updatedOptions = List<product_model.CustomizationOption>.from(_customizations[groupIndex].options);
      updatedOptions.removeAt(optionIndex);
      _customizations[groupIndex] = _customizations[groupIndex].copyWith(options: updatedOptions);
      widget.onCustomizationsChanged(_customizations);
    });
  }

  void _reorderOptionsInGroup(int groupIndex, int oldIndex, int newIndex) {
    setState(() {
      final updatedOptions = List<product_model.CustomizationOption>.from(_customizations[groupIndex].options);
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = updatedOptions.removeAt(oldIndex);
      updatedOptions.insert(newIndex, item);
      _customizations[groupIndex] = _customizations[groupIndex].copyWith(options: updatedOptions);
      widget.onCustomizationsChanged(_customizations);
    });
  }

  // Template methods
  void _addSizeTemplate() {
    final sizeTemplate = product_model.MenuItemCustomization(
      name: 'Size Options',
      type: 'single',
      isRequired: true,
      options: [
        const product_model.CustomizationOption(name: 'Regular', additionalPrice: 0.0, isDefault: true),
        const product_model.CustomizationOption(name: 'Large', additionalPrice: 3.0),
        const product_model.CustomizationOption(name: 'Extra Large', additionalPrice: 5.0),
      ],
    );
    setState(() {
      _customizations.add(sizeTemplate);
      widget.onCustomizationsChanged(_customizations);
    });
  }

  void _addSpiceTemplate() {
    final spiceTemplate = product_model.MenuItemCustomization(
      name: 'Spice Level',
      type: 'single',
      isRequired: true,
      options: [
        const product_model.CustomizationOption(name: 'Mild', additionalPrice: 0.0, isDefault: true),
        const product_model.CustomizationOption(name: 'Medium', additionalPrice: 0.0),
        const product_model.CustomizationOption(name: 'Spicy', additionalPrice: 0.0),
        const product_model.CustomizationOption(name: 'Extra Spicy', additionalPrice: 0.0),
      ],
    );
    setState(() {
      _customizations.add(spiceTemplate);
      widget.onCustomizationsChanged(_customizations);
    });
  }

  void _addAddonsTemplate() {
    final addonsTemplate = product_model.MenuItemCustomization(
      name: 'Add-ons',
      type: 'multiple',
      isRequired: false,
      options: [
        const product_model.CustomizationOption(name: 'Extra Egg', additionalPrice: 2.0),
        const product_model.CustomizationOption(name: 'Extra Rice', additionalPrice: 1.5),
        const product_model.CustomizationOption(name: 'Extra Vegetables', additionalPrice: 2.5),
      ],
    );
    setState(() {
      _customizations.add(addonsTemplate);
      widget.onCustomizationsChanged(_customizations);
    });
  }

  void _addCookingStyleTemplate() {
    final cookingTemplate = product_model.MenuItemCustomization(
      name: 'Cooking Style',
      type: 'single',
      isRequired: false,
      options: [
        const product_model.CustomizationOption(name: 'Regular', additionalPrice: 0.0, isDefault: true),
        const product_model.CustomizationOption(name: 'Well Done', additionalPrice: 0.0),
        const product_model.CustomizationOption(name: 'Less Oil', additionalPrice: 0.0),
      ],
    );
    setState(() {
      _customizations.add(cookingTemplate);
      widget.onCustomizationsChanged(_customizations);
    });
  }
}

/// Enhanced customization group card with drag-and-drop and visual enhancements
class EnhancedCustomizationGroupCard extends StatefulWidget {
  final product_model.MenuItemCustomization customization;
  final int index;
  final double basePrice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(product_model.CustomizationOption) onAddOption;
  final Function(int, product_model.CustomizationOption) onEditOption;
  final Function(int) onDeleteOption;
  final Function(int, int) onReorderOptions;
  final bool showPricingPreview;

  const EnhancedCustomizationGroupCard({
    super.key,
    required this.customization,
    required this.index,
    required this.basePrice,
    required this.onEdit,
    required this.onDelete,
    required this.onAddOption,
    required this.onEditOption,
    required this.onDeleteOption,
    required this.onReorderOptions,
    this.showPricingPreview = true,
  });

  @override
  State<EnhancedCustomizationGroupCard> createState() => _EnhancedCustomizationGroupCardState();
}

class _EnhancedCustomizationGroupCardState extends State<EnhancedCustomizationGroupCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Column(
        children: [
          _buildHeader(),
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _expandAnimation.value,
                  child: child,
                ),
              );
            },
            child: _buildExpandableContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: _toggleExpansion,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Drag handle
            Icon(
              Icons.drag_handle,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),

            // Group info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.customization.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildTypeChip(),
                      const SizedBox(width: 8),
                      _buildRequiredChip(),
                      if (widget.showPricingPreview) ...[
                        const SizedBox(width: 8),
                        _buildPricingPreview(),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            _buildActionButtons(),

            // Expand/collapse icon
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.expand_more),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip() {
    final isMultiple = widget.customization.type == 'multiple';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMultiple ? Colors.green[100] : Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMultiple ? Icons.check_box : Icons.radio_button_checked,
            size: 14,
            color: isMultiple ? Colors.green[800] : Colors.blue[800],
          ),
          const SizedBox(width: 4),
          Text(
            isMultiple ? 'Multiple' : 'Single',
            style: TextStyle(
              fontSize: 12,
              color: isMultiple ? Colors.green[800] : Colors.blue[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.customization.isRequired ? Colors.orange[100] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.customization.isRequired ? Icons.star : Icons.star_border,
            size: 14,
            color: widget.customization.isRequired ? Colors.orange[800] : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            widget.customization.isRequired ? 'Required' : 'Optional',
            style: TextStyle(
              fontSize: 12,
              color: widget.customization.isRequired ? Colors.orange[800] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingPreview() {
    final options = widget.customization.options;
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    final minPrice = options.map((opt) => opt.additionalPrice).reduce((min, price) => price < min ? price : min);
    final maxPrice = options.map((opt) => opt.additionalPrice).reduce((max, price) => price > max ? price : max);

    if (minPrice == 0 && maxPrice == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Free',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        minPrice == maxPrice
            ? '+RM ${maxPrice.toStringAsFixed(2)}'
            : '+RM ${minPrice.toStringAsFixed(2)} - ${maxPrice.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.purple[800],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: widget.onEdit,
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit group',
          iconSize: 20,
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          onPressed: widget.onDelete,
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete group',
          iconSize: 20,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildExpandableContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),

          // Options header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Options (${widget.customization.options.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Option'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Options list with drag-and-drop
          if (widget.customization.options.isEmpty)
            _buildEmptyOptionsState()
          else
            _buildOptionsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyOptionsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(
              'No options added yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "Add Option" to create choices',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.customization.options.length,
      onReorder: widget.onReorderOptions,
      itemBuilder: (context, index) {
        final option = widget.customization.options[index];
        return _buildOptionTile(option, index);
      },
    );
  }

  Widget _buildOptionTile(product_model.CustomizationOption option, int index) {
    return Card(
      key: ValueKey(option.id ?? index),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drag_handle, color: Colors.grey[400], size: 16),
            const SizedBox(width: 8),
            Icon(
              option.isDefault ? Icons.star : Icons.star_border,
              color: option.isDefault ? Colors.amber[600] : Colors.grey[400],
              size: 20,
            ),
          ],
        ),
        title: Text(
          option.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: option.additionalPrice > 0
            ? Text(
                '+RM ${option.additionalPrice.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.green[600]),
              )
            : const Text('Free'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _editOption(index),
              icon: const Icon(Icons.edit_outlined),
              iconSize: 16,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: () => widget.onDeleteOption(index),
              icon: const Icon(Icons.delete_outline),
              iconSize: 16,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _addOption() {
    showDialog(
      context: context,
      builder: (context) => EnhancedCustomizationOptionDialog(
        onSave: widget.onAddOption,
      ),
    );
  }

  void _editOption(int index) {
    showDialog(
      context: context,
      builder: (context) => EnhancedCustomizationOptionDialog(
        option: widget.customization.options[index],
        onSave: (option) => widget.onEditOption(index, option),
      ),
    );
  }
}
