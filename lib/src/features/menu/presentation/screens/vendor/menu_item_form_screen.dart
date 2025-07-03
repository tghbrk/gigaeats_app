import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/menu_item.dart';
import '../../../data/models/product.dart' as product_model;
import '../../../data/services/menu_service.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../presentation/providers/repository_providers.dart';
import 'package:uuid/uuid.dart';

class MenuItemFormScreen extends ConsumerStatefulWidget {
  final String? menuItemId; // null for create, non-null for edit

  const MenuItemFormScreen({
    super.key,
    this.menuItemId,
  });

  @override
  ConsumerState<MenuItemFormScreen> createState() => _MenuItemFormScreenState();
}

class _MenuItemFormScreenState extends ConsumerState<MenuItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final _maxQuantityController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _availableQuantityController = TextEditingController();
  final _tagsController = TextEditingController();
  
  // Form state
  String? _selectedCategory;
  String _selectedUnit = 'pax';
  bool _isHalalCertified = false;
  MenuItemStatus _status = MenuItemStatus.available;
  List<DietaryType> _selectedDietaryTypes = [];
  List<String> _allergens = [];
  List<BulkPricingTier> _bulkPricingTiers = [];
  List<String> _imageUrls = [];
  final List<product_model.MenuItemCustomization> _customizations = []; // Add state for customizations

  // Loading states
  bool _isLoading = false;
  bool _isSaving = false;

  // Data
  List<MenuCategory> _categories = [];
  MenuItem? _existingItem;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _minQuantityController.dispose();
    _maxQuantityController.dispose();
    _prepTimeController.dispose();
    _availableQuantityController.dispose();
    _tagsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final authState = ref.read(authStateProvider);
      final vendorId = authState.user?.id ?? 'vendor_001';
      
      final menuService = MenuService();
      _categories = await menuService.getVendorCategories(vendorId);
      
      if (widget.menuItemId != null) {
        _existingItem = await menuService.getMenuItem(widget.menuItemId!);
        if (_existingItem != null) {
          _populateFormWithExistingData();
        }
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _populateFormWithExistingData() {
    final item = _existingItem!;
    _nameController.text = item.name;
    _descriptionController.text = item.description;
    _basePriceController.text = item.basePrice.toString();
    _minQuantityController.text = item.minimumOrderQuantity.toString();
    _maxQuantityController.text = item.maximumOrderQuantity?.toString() ?? '';
    _prepTimeController.text = item.preparationTimeMinutes.toString();
    _availableQuantityController.text = item.availableQuantity?.toString() ?? '';
    _tagsController.text = item.tags.join(', ');
    
    _selectedCategory = item.category;
    _selectedUnit = item.unit ?? 'pax';
    _isHalalCertified = item.isHalalCertified;
    _status = item.status;
    _selectedDietaryTypes = List.from(item.dietaryTypes);
    _allergens = List.from(item.allergens);
    _bulkPricingTiers = List.from(item.bulkPricingTiers);
    _imageUrls = List.from(item.imageUrls);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.menuItemId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Menu Item' : 'Add Menu Item'),
        elevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              onPressed: () => _showDeleteConfirmation(),
              icon: const Icon(Icons.delete),
              tooltip: 'Delete item',
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading menu data...')
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBasicInfoSection(),
                          const SizedBox(height: 24),
                          _buildPricingSection(),
                          const SizedBox(height: 24),
                          _buildQuantitySection(),
                          const SizedBox(height: 24),
                          _buildDietarySection(),
                          const SizedBox(height: 24),
                          // New section for customizations
                          _buildCustomizationSection(),
                          const SizedBox(height: 24),
                          _buildAdditionalInfoSection(),
                          const SizedBox(height: 24),
                          _buildBulkPricingSection(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                hintText: 'e.g., Nasi Lemak Set',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter item name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe your menu item...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing & Unit',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Base Price
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _basePriceController,
                    decoration: const InputDecoration(
                      labelText: 'Base Price (RM) *',
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                      prefixText: 'RM ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Invalid price';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Unit
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pax', child: Text('Per Pax')),
                      DropdownMenuItem(value: 'kg', child: Text('Per KG')),
                      DropdownMenuItem(value: 'pieces', child: Text('Pieces')),
                      DropdownMenuItem(value: 'portion', child: Text('Portion')),
                      DropdownMenuItem(value: 'set', child: Text('Set')),
                      DropdownMenuItem(value: 'box', child: Text('Box')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedUnit = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quantity & Availability',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Minimum Order Quantity
                Expanded(
                  child: TextFormField(
                    controller: _minQuantityController,
                    decoration: const InputDecoration(
                      labelText: 'Min Order Qty *',
                      hintText: '1',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final qty = int.tryParse(value);
                      if (qty == null || qty <= 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Maximum Order Quantity
                Expanded(
                  child: TextFormField(
                    controller: _maxQuantityController,
                    decoration: const InputDecoration(
                      labelText: 'Max Order Qty',
                      hintText: 'Optional',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final maxQty = int.tryParse(value);
                        final minQty = int.tryParse(_minQuantityController.text);
                        if (maxQty == null || maxQty <= 0) {
                          return 'Invalid';
                        }
                        if (minQty != null && maxQty < minQty) {
                          return 'Must be ≥ min';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                // Preparation Time
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Prep Time (min) *',
                      hintText: '30',
                      border: OutlineInputBorder(),
                      suffixText: 'minutes',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final time = int.tryParse(value);
                      if (time == null || time <= 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Available Quantity
                Expanded(
                  child: TextFormField(
                    controller: _availableQuantityController,
                    decoration: const InputDecoration(
                      labelText: 'Available Qty',
                      hintText: 'Optional',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final qty = int.tryParse(value);
                        if (qty == null || qty < 0) {
                          return 'Invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status
            DropdownButtonFormField<MenuItemStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: MenuItemStatus.available,
                  child: Text('Available'),
                ),
                DropdownMenuItem(
                  value: MenuItemStatus.unavailable,
                  child: Text('Unavailable'),
                ),
                DropdownMenuItem(
                  value: MenuItemStatus.outOfStock,
                  child: Text('Out of Stock'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _status = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietarySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dietary Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Halal Certification
            SwitchListTile(
              title: const Text('Halal Certified'),
              subtitle: const Text('This item is certified Halal'),
              value: _isHalalCertified,
              onChanged: (value) {
                setState(() {
                  _isHalalCertified = value;
                  if (value && !_selectedDietaryTypes.contains(DietaryType.halal)) {
                    _selectedDietaryTypes.add(DietaryType.halal);
                  } else if (!value) {
                    _selectedDietaryTypes.remove(DietaryType.halal);
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 16),

            // Dietary Types
            Text(
              'Dietary Types',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DietaryType.values.map((type) {
                final isSelected = _selectedDietaryTypes.contains(type);
                return FilterChip(
                  label: Text(_getDietaryTypeLabel(type)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDietaryTypes.add(type);
                      } else {
                        _selectedDietaryTypes.remove(type);
                        // If removing halal, also uncheck halal certification
                        if (type == DietaryType.halal) {
                          _isHalalCertified = false;
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Allergens
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Allergens',
                hintText: 'e.g., Nuts, Dairy, Gluten (comma separated)',
                border: OutlineInputBorder(),
                helperText: 'List any allergens present in this item',
              ),
              onChanged: (value) {
                _allergens = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              },
              initialValue: _allergens.join(', '),
            ),
          ],
        ),
      ),
    );
  }

  // New method to build the customization section
  Widget _buildCustomizationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customizations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addCustomizationGroup,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Group'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_customizations.isEmpty)
              const Text(
                'No customization options added yet.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _customizations.length,
                itemBuilder: (context, index) {
                  return _buildCustomizationGroupCard(_customizations[index] as MenuItemCustomization, index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomizationGroupCard(MenuItemCustomization customization, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(customization.name),
        subtitle: Text('${customization.type}, ${customization.isRequired ? "Required" : "Optional"}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _editCustomizationGroup(index),
              icon: const Icon(Icons.edit),
              tooltip: 'Edit group',
            ),
            IconButton(
              onPressed: () => _deleteCustomizationGroup(index),
              icon: const Icon(Icons.delete),
              tooltip: 'Delete group',
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          ...customization.options.map((opt) => ListTile(
            title: Text(opt.name),
            trailing: Text('+ RM ${(opt as dynamic).additionalCost?.toStringAsFixed(2) ?? (opt as dynamic).additionalPrice?.toStringAsFixed(2) ?? "0.00"}'),
          )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton.icon(
              onPressed: () => _addOptionToGroup(index),
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
            ),
          ),
        ],
      ),
    );
  }

  void _addOptionToGroup(int groupIndex) {
    showDialog(
      context: context,
      builder: (context) => _CustomizationOptionDialog(
        onSave: (option) {
          setState(() {
            final updatedOptions = List<product_model.CustomizationOption>.from(_customizations[groupIndex].options);
            updatedOptions.add(option);
            _customizations[groupIndex] = _customizations[groupIndex].copyWith(options: updatedOptions);
          });
        },
      ),
    );
  }

  void _addCustomizationGroup() {
    showDialog(
      context: context,
      builder: (context) => _CustomizationGroupDialog(
        onSave: (customization) {
          setState(() {
            _customizations.add(customization);
          });
        },
      ),
    );
  }

  void _editCustomizationGroup(int index) {
    showDialog(
      context: context,
      builder: (context) => _CustomizationGroupDialog(
        customization: _customizations[index],
        onSave: (customization) {
          setState(() {
            _customizations[index] = customization;
          });
        },
      ),
    );
  }

  void _deleteCustomizationGroup(int index) {
    setState(() {
      _customizations.removeAt(index);
    });
  }

  Widget _buildAdditionalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Tags
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'e.g., spicy, popular, new (comma separated)',
                border: OutlineInputBorder(),
                helperText: 'Add tags to help customers find this item',
              ),
            ),

            const SizedBox(height: 16),

            // Image URLs (simplified for demo)
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Image URL',
                hintText: 'https://example.com/image.jpg',
                border: OutlineInputBorder(),
                helperText: 'Add a photo URL for this menu item',
              ),
              onChanged: (value) {
                if (value.trim().isNotEmpty) {
                  _imageUrls = [value.trim()];
                } else {
                  _imageUrls = [];
                }
              },
              initialValue: _imageUrls.isNotEmpty ? _imageUrls.first : '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkPricingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bulk Pricing Tiers',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addBulkPricingTier(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Tier'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Offer discounted prices for larger quantities',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            if (_bulkPricingTiers.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Text(
                    'No bulk pricing tiers added yet.\nTap "Add Tier" to create volume discounts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: _bulkPricingTiers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tier = entry.value;
                  return _buildBulkPricingTierCard(tier, index);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkPricingTierCard(BulkPricingTier tier, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Min Qty: ${tier.minimumQuantity}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text('Price: RM ${tier.pricePerUnit.toStringAsFixed(2)}'),
                  if (tier.discountPercentage != null)
                    Text(
                      '${tier.discountPercentage!.toStringAsFixed(1)}% discount',
                      style: const TextStyle(color: Colors.green),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _editBulkPricingTier(index),
              icon: const Icon(Icons.edit),
              tooltip: 'Edit tier',
            ),
            IconButton(
              onPressed: () => _removeBulkPricingTier(index),
              icon: const Icon(Icons.delete),
              tooltip: 'Remove tier',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: widget.menuItemId != null ? 'Update Item' : 'Add Item',
              onPressed: _isSaving ? null : _saveMenuItem,
              isLoading: _isSaving,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getDietaryTypeLabel(DietaryType type) {
    switch (type) {
      case DietaryType.halal:
        return 'Halal';
      case DietaryType.vegetarian:
        return 'Vegetarian';
      case DietaryType.vegan:
        return 'Vegan';
      case DietaryType.glutenFree:
        return 'Gluten Free';
      case DietaryType.dairyFree:
        return 'Dairy Free';
      case DietaryType.nutFree:
        return 'Nut Free';
    }
  }

  void _addBulkPricingTier() {
    showDialog(
      context: context,
      builder: (context) => _BulkPricingTierDialog(
        onSave: (tier) {
          setState(() {
            _bulkPricingTiers.add(tier);
            // Sort tiers by minimum quantity
            _bulkPricingTiers.sort((a, b) => a.minimumQuantity.compareTo(b.minimumQuantity));
          });
        },
        basePrice: double.tryParse(_basePriceController.text) ?? 0.0,
      ),
    );
  }

  void _editBulkPricingTier(int index) {
    showDialog(
      context: context,
      builder: (context) => _BulkPricingTierDialog(
        tier: _bulkPricingTiers[index],
        onSave: (tier) {
          setState(() {
            _bulkPricingTiers[index] = tier;
            // Sort tiers by minimum quantity
            _bulkPricingTiers.sort((a, b) => a.minimumQuantity.compareTo(b.minimumQuantity));
          });
        },
        basePrice: double.tryParse(_basePriceController.text) ?? 0.0,
      ),
    );
  }

  void _removeBulkPricingTier(int index) {
    setState(() {
      _bulkPricingTiers.removeAt(index);
    });
  }

  Future<void> _saveMenuItem() async {
    print('🍽️ [MENU-FORM-DEBUG] Starting menu item save...');
    if (!_formKey.currentState!.validate()) {
      print('🍽️ [MENU-FORM-DEBUG] Form validation failed');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      print('🍽️ [MENU-FORM-DEBUG] Current user ID: $userId');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get vendor ID from user ID
      final vendorRepository = ref.read(vendorRepositoryProvider);
      final vendor = await vendorRepository.getVendorByUserId(userId);

      if (vendor == null) {
        throw Exception('Vendor not found for user');
      }

      print('🍽️ [MENU-FORM-DEBUG] Vendor found: ${vendor.id}');
      print('🍽️ [MENU-FORM-DEBUG] Vendor object: ${vendor.toJson()}');

      final menuItemRepository = ref.read(menuItemRepositoryProvider);

      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (widget.menuItemId != null) {
        print('🍽️ [MENU-FORM-DEBUG] Updating existing menu item: ${widget.menuItemId}');

        // Create updated product using existing ID and available form fields
        final updatedProduct = product_model.Product(
          id: widget.menuItemId!, // Use existing ID
          vendorId: vendor.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory!,
          basePrice: double.parse(_basePriceController.text),
          currency: 'MYR', // Default currency
          includesSst: false, // Default value
          isAvailable: _status == MenuItemStatus.available,
          minOrderQuantity: _minQuantityController.text.isNotEmpty ? int.parse(_minQuantityController.text) : 1,
          maxOrderQuantity: _maxQuantityController.text.isNotEmpty ? int.parse(_maxQuantityController.text) : null,
          preparationTimeMinutes: _prepTimeController.text.isNotEmpty ? int.parse(_prepTimeController.text) : 30,
          allergens: _allergens,
          isHalal: _isHalalCertified,
          isVegetarian: _selectedDietaryTypes.contains(DietaryType.vegetarian),
          isVegan: _selectedDietaryTypes.contains(DietaryType.vegan),
          isSpicy: false, // Default value
          spicyLevel: 0, // Default value
          imageUrl: _imageUrls.isNotEmpty ? _imageUrls.first : null,
          galleryImages: _imageUrls.length > 1 ? _imageUrls.sublist(1) : [],
          isFeatured: false, // Default value
          tags: _tagsController.text.isNotEmpty ? _tagsController.text.split(',').map((e) => e.trim()).toList() : [],
          rating: 0.0,
          totalReviews: 0,
          customizations: _customizations, // Add customizations to the updated product
        );

        print('🍽️ [MENU-FORM-DEBUG] Updated product data: ${updatedProduct.toJson()}');
        final result = await menuItemRepository.updateMenuItem(updatedProduct);
        print('🍽️ [MENU-FORM-DEBUG] Menu item updated successfully: ${result.id}');
      } else {
        print('🍽️ [MENU-FORM-DEBUG] Creating new menu item...');
        // Create new item using Product model
        const uuid = Uuid();
        final newProduct = product_model.Product(
          id: uuid.v4(), // Temporary ID, will be replaced by database
          vendorId: vendor.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory!,
          basePrice: double.parse(_basePriceController.text),
          imageUrl: _imageUrls.isNotEmpty ? _imageUrls.first : null,
          isAvailable: _status == MenuItemStatus.available,
          isVegetarian: _selectedDietaryTypes.contains(DietaryType.vegetarian),
          isHalal: _isHalalCertified,
          tags: tags,
          rating: 0.0,
          totalReviews: 0,
          customizations: _customizations, // Add customizations to the new product
        );

        print('🍽️ [MENU-FORM-DEBUG] Product data: ${newProduct.toJson()}');
        final createdProduct = await menuItemRepository.createMenuItem(newProduct);
        print('🍽️ [MENU-FORM-DEBUG] Menu item created successfully: ${createdProduct.id}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.menuItemId != null
                ? 'Menu item updated successfully!'
                : 'Menu item added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save menu item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text('Are you sure you want to delete "${_nameController.text}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteMenuItem();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMenuItem() async {
    if (widget.menuItemId == null) return;

    setState(() => _isSaving = true);

    try {
      final menuService = MenuService();
      await menuService.deleteMenuItem(widget.menuItemId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu item deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete menu item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

// Bulk Pricing Tier Dialog Widget
class _BulkPricingTierDialog extends StatefulWidget {
  final BulkPricingTier? tier;
  final Function(BulkPricingTier) onSave;
  final double basePrice;

  const _BulkPricingTierDialog({
    this.tier,
    required this.onSave,
    required this.basePrice,
  });

  @override
  State<_BulkPricingTierDialog> createState() => _BulkPricingTierDialogState();
}

class _BulkPricingTierDialogState extends State<_BulkPricingTierDialog> {
  final _formKey = GlobalKey<FormState>();
  final _minQuantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.tier != null) {
      _minQuantityController.text = widget.tier!.minimumQuantity.toString();
      _priceController.text = widget.tier!.pricePerUnit.toString();
      _descriptionController.text = widget.tier!.description ?? '';
    }
  }

  @override
  void dispose() {
    _minQuantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tier != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Bulk Pricing Tier' : 'Add Bulk Pricing Tier'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _minQuantityController,
              decoration: const InputDecoration(
                labelText: 'Minimum Quantity *',
                hintText: 'e.g., 50',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter minimum quantity';
                }
                final qty = int.tryParse(value);
                if (qty == null || qty <= 1) {
                  return 'Must be greater than 1';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price per Unit (RM) *',
                hintText: 'e.g., ${(widget.basePrice * 0.9).toStringAsFixed(2)}',
                border: const OutlineInputBorder(),
                prefixText: 'RM ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter price';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Invalid price';
                }
                if (price >= widget.basePrice) {
                  return 'Must be less than base price (RM ${widget.basePrice.toStringAsFixed(2)})';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g., Corporate discount',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Show calculated discount percentage
            if (_priceController.text.isNotEmpty && widget.basePrice > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Discount: ${_calculateDiscountPercentage().toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveTier,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  double _calculateDiscountPercentage() {
    final price = double.tryParse(_priceController.text) ?? 0.0;
    if (price <= 0 || widget.basePrice <= 0) return 0.0;
    return ((widget.basePrice - price) / widget.basePrice) * 100;
  }

  void _saveTier() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final tier = BulkPricingTier(
      minimumQuantity: int.parse(_minQuantityController.text),
      pricePerUnit: double.parse(_priceController.text),
      discountPercentage: _calculateDiscountPercentage(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    );

    widget.onSave(tier);
    Navigator.of(context).pop();
  }
}

// Customization Group Dialog Widget
class _CustomizationGroupDialog extends StatefulWidget {
  final product_model.MenuItemCustomization? customization;
  final Function(product_model.MenuItemCustomization) onSave;

  const _CustomizationGroupDialog({
    this.customization,
    required this.onSave,
  });

  @override
  State<_CustomizationGroupDialog> createState() => _CustomizationGroupDialogState();
}

class _CustomizationGroupDialogState extends State<_CustomizationGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedType = 'single';
  bool _isRequired = false;

  @override
  void initState() {
    super.initState();
    if (widget.customization != null) {
      _nameController.text = widget.customization!.name;
      _selectedType = widget.customization!.type;
      _isRequired = widget.customization!.isRequired;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customization != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Customization Group' : 'Add Customization Group'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name *',
                hintText: 'e.g., Size, Spice Level',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter group name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Selection Type *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'single', child: Text('Single Choice (Radio)')),
                DropdownMenuItem(value: 'multiple', child: Text('Multiple Choice (Checkbox)')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Required'),
              subtitle: const Text('Customers must make a selection'),
              value: _isRequired,
              onChanged: (value) {
                setState(() {
                  _isRequired = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveGroup,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  void _saveGroup() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final group = product_model.MenuItemCustomization(
      id: widget.customization?.id, // Use null for new customizations
      name: _nameController.text.trim(),
      type: _selectedType,
      isRequired: _isRequired,
      options: widget.customization?.options.cast<product_model.CustomizationOption>() ?? [],
    );

    widget.onSave(group);
    Navigator.of(context).pop();
  }
}

// Customization Option Dialog Widget
class _CustomizationOptionDialog extends StatefulWidget {
  final product_model.CustomizationOption? option;
  final Function(product_model.CustomizationOption) onSave;

  const _CustomizationOptionDialog({
    // ignore: unused_element_parameter
    this.option,
    required this.onSave,
  });

  @override
  State<_CustomizationOptionDialog> createState() => _CustomizationOptionDialogState();
}

class _CustomizationOptionDialogState extends State<_CustomizationOptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    if (widget.option != null) {
      _nameController.text = widget.option!.name;
      _priceController.text = widget.option!.additionalPrice.toString();
      _isDefault = widget.option!.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.option != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Option' : 'Add Option'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Option Name *',
                hintText: 'e.g., Large, Extra Spicy',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter option name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Additional Price (RM)',
                hintText: '0.00',
                border: OutlineInputBorder(),
                prefixText: 'RM ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter price (use 0 for no additional cost)';
                }
                final price = double.tryParse(value);
                if (price == null || price < 0) {
                  return 'Invalid price';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Default Selection'),
              subtitle: const Text('Pre-select this option'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveOption,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  void _saveOption() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final option = product_model.CustomizationOption(
      id: widget.option?.id, // Use null for new options
      name: _nameController.text.trim(),
      additionalPrice: double.parse(_priceController.text),
      isDefault: _isDefault,
    );

    widget.onSave(option);
    Navigator.of(context).pop();
  }
}
