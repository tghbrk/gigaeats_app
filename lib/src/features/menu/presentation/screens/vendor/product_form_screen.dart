import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/product.dart';
import '../../../../../presentation/providers/repository_providers.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
// TODO: Fix missing camera_permission_service import
// import '../../../../core/services/camera_permission_service.dart';
import '../../widgets/customization_dialog.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId; // null for create, non-null for edit

  const ProductFormScreen({
    super.key,
    this.productId,
  });

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  _ProductFormScreenState() {
    print('🔧 [PRODUCT-FORM-DEBUG] _ProductFormScreenState constructor called');
  }
  
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _bulkPriceController = TextEditingController();
  final _bulkMinQuantityController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final _maxQuantityController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _tagsController = TextEditingController();
  
  // Form state
  String? _selectedCategory;
  String _currency = 'MYR';
  bool _includesSst = false;
  bool _isAvailable = true;
  bool _isHalal = false;
  bool _isVegetarian = false;
  bool _isVegan = false;
  bool _isSpicy = false;
  int _spicyLevel = 0;
  bool _isFeatured = false;
  List<String> _allergens = [];
  // TODO: Restore _tags when tagging functionality is implemented
  // List<String> _tags = [];
  List<MenuItemCustomization> _customizations = [];
  String? _imageUrl;
  List<String> _galleryImages = [];

  // Loading states
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Data
  Product? _existingProduct;

  @override
  void initState() {
    print('🔧 [PRODUCT-FORM-DEBUG] initState called');
    print('🔧 [PRODUCT-FORM-DEBUG] Widget product ID: ${widget.productId}');
    print('🔧 [PRODUCT-FORM-DEBUG] Is editing mode: ${widget.productId != null}');
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _bulkPriceController.dispose();
    _bulkMinQuantityController.dispose();
    _minQuantityController.dispose();
    _maxQuantityController.dispose();
    _prepTimeController.dispose();
    _tagsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    print('🔧 [PRODUCT-FORM-DEBUG] Starting _loadData...');
    print('🔧 [PRODUCT-FORM-DEBUG] Product ID: ${widget.productId}');
    print('🔧 [PRODUCT-FORM-DEBUG] Is editing: ${widget.productId != null}');

    setState(() => _isLoading = true);

    try {
      if (widget.productId != null) {
        print('🔧 [PRODUCT-FORM-DEBUG] Loading existing product data...');
        final menuItemRepository = ref.read(menuItemRepositoryProvider);
        print('🔧 [PRODUCT-FORM-DEBUG] Repository obtained: $menuItemRepository');

        _existingProduct = await menuItemRepository.getMenuItemById(widget.productId!);
        print('🔧 [PRODUCT-FORM-DEBUG] Product loaded: ${_existingProduct?.name ?? 'NULL'}');

        if (_existingProduct != null) {
          print('🔧 [PRODUCT-FORM-DEBUG] Populating form with existing data...');
          _populateFormWithExistingData();
          print('🔧 [PRODUCT-FORM-DEBUG] Form populated successfully');
        } else {
          print('🔧 [PRODUCT-FORM-DEBUG] ❌ No product found with ID: ${widget.productId}');
        }
      } else {
        print('🔧 [PRODUCT-FORM-DEBUG] Creating new product (no ID provided)');
      }

      setState(() => _isLoading = false);
      print('🔧 [PRODUCT-FORM-DEBUG] _loadData completed successfully');
    } catch (e, stackTrace) {
      print('🔧 [PRODUCT-FORM-DEBUG] ❌ Error in _loadData: $e');
      print('🔧 [PRODUCT-FORM-DEBUG] ❌ Stack trace: $stackTrace');
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
    final product = _existingProduct!;
    print('🔧 [PRODUCT-FORM-DEBUG] Populating form with product: ${product.name}');
    print('🔧 [PRODUCT-FORM-DEBUG] Product ID: ${product.id}');
    print('🔧 [PRODUCT-FORM-DEBUG] Product description: ${product.description}');
    print('🔧 [PRODUCT-FORM-DEBUG] Product price: ${product.basePrice}');
    print('🔧 [PRODUCT-FORM-DEBUG] Product category: ${product.category}');

    _nameController.text = product.name;
    _descriptionController.text = product.description ?? '';
    _basePriceController.text = product.basePrice.toString();
    _bulkPriceController.text = product.bulkPrice?.toString() ?? '';
    _bulkMinQuantityController.text = product.bulkMinQuantity?.toString() ?? '';
    _minQuantityController.text = product.minOrderQuantity?.toString() ?? '1';
    _maxQuantityController.text = product.maxOrderQuantity?.toString() ?? '';
    _prepTimeController.text = product.preparationTimeMinutes?.toString() ?? '30';
    _tagsController.text = product.tags.join(', ');

    _selectedCategory = product.category;
    _currency = product.currency ?? 'MYR';
    _includesSst = product.includesSst ?? false;
    _isAvailable = product.isAvailable ?? true;
    _isHalal = product.isHalal ?? false;
    _isVegetarian = product.isVegetarian ?? false;
    _isVegan = product.isVegan ?? false;
    _isSpicy = product.isSpicy ?? false;
    _spicyLevel = product.spicyLevel ?? 0;
    _isFeatured = product.isFeatured ?? false;
    _allergens = List.from(product.allergens);
    // TODO: Restore when _tags is implemented
    // _tags = List.from(product.tags);
    _customizations = List.from(product.customizations);
    _imageUrl = product.imageUrl;
    _galleryImages = List.from(product.galleryImages);

    print('🔧 [PRODUCT-FORM-DEBUG] Form controllers populated:');
    print('🔧 [PRODUCT-FORM-DEBUG] - Name: ${_nameController.text}');
    print('🔧 [PRODUCT-FORM-DEBUG] - Description: ${_descriptionController.text}');
    print('🔧 [PRODUCT-FORM-DEBUG] - Price: ${_basePriceController.text}');
    print('🔧 [PRODUCT-FORM-DEBUG] - Category: $_selectedCategory');
    print('🔧 [PRODUCT-FORM-DEBUG] - Available: $_isAvailable');
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productId != null;

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
                          _buildImageSection(),
                          const SizedBox(height: 24),
                          _buildCustomizationSection(),
                          const SizedBox(height: 24),
                          _buildAdditionalInfoSection(),
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
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Item Name *',
                hintText: 'e.g., Nasi Lemak Set',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                prefixIcon: Icon(
                  Icons.restaurant_menu,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter item name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your menu item...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                prefixIcon: Icon(
                  Icons.description,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 20),

            // Category
            DropdownButtonFormField<String>(
              value: ProductCategories.all.contains(_selectedCategory) ? _selectedCategory : null,
              decoration: InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                prefixIcon: Icon(
                  Icons.category,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              items: ProductCategories.all.where((category) => category.isNotEmpty).map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
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
              'Pricing',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Base Price
            TextFormField(
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

            const SizedBox(height: 16),

            // Bulk Pricing
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bulkPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Bulk Price (RM)',
                      hintText: 'Optional',
                      border: OutlineInputBorder(),
                      prefixText: 'RM ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _bulkMinQuantityController,
                    decoration: const InputDecoration(
                      labelText: 'Min Bulk Qty',
                      hintText: 'Optional',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // SST and Currency
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: ['MYR', 'USD', 'SGD'].contains(_currency) ? _currency : 'MYR',
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'MYR', child: Text('MYR')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'SGD', child: Text('SGD')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _currency = value ?? 'MYR';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Includes SST'),
                    value: _includesSst,
                    onChanged: (value) {
                      setState(() {
                        _includesSst = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
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

            // Preparation Time
            TextFormField(
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

            const SizedBox(height: 16),

            // Availability
            CheckboxListTile(
              title: const Text('Available for Order'),
              value: _isAvailable,
              onChanged: (value) {
                setState(() {
                  _isAvailable = value ?? true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
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

            // Dietary checkboxes
            CheckboxListTile(
              title: const Text('Halal Certified'),
              value: _isHalal,
              onChanged: (value) {
                setState(() {
                  _isHalal = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),

            CheckboxListTile(
              title: const Text('Vegetarian'),
              value: _isVegetarian,
              onChanged: (value) {
                setState(() {
                  _isVegetarian = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),

            CheckboxListTile(
              title: const Text('Vegan'),
              value: _isVegan,
              onChanged: (value) {
                setState(() {
                  _isVegan = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),

            CheckboxListTile(
              title: const Text('Spicy'),
              value: _isSpicy,
              onChanged: (value) {
                setState(() {
                  _isSpicy = value ?? false;
                  if (!_isSpicy) _spicyLevel = 0;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),

            if (_isSpicy) ...[
              const SizedBox(height: 8),
              Text('Spicy Level: $_spicyLevel'),
              Slider(
                value: _spicyLevel.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _spicyLevel.toString(),
                onChanged: (value) {
                  setState(() {
                    _spicyLevel = value.round();
                  });
                },
              ),
            ],

            const SizedBox(height: 16),

            // Allergens
            _buildAllergensSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergensSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Allergens:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: CommonAllergens.all.map((allergen) {
            final isSelected = _allergens.contains(allergen);
            return FilterChip(
              label: Text(allergen),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _allergens.add(allergen);
                  } else {
                    _allergens.remove(allergen);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Images',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Main Image
            if (_imageUrl != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(_imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Image upload button
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: Text(_imageUrl == null ? 'Add Main Image' : 'Change Image'),
            ),

            if (_imageUrl != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _imageUrl = null;
                  });
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Remove Image', style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomizationSection() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.tune,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Customizations',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _addCustomization,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_customizations.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.tune,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No customizations added yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add customizations like size options, add-ons, or spice levels',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._customizations.asMap().entries.map((entry) {
                final index = entry.key;
                final customization = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      customization.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${customization.type} • ${customization.options.length} options',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _editCustomization(index),
                          icon: Icon(
                            Icons.edit,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _removeCustomization(index),
                          icon: Icon(
                            Icons.delete,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
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
              ),
              onChanged: (value) {
                // TODO: Restore when _tags is implemented
                // _tags = value.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
              },
            ),

            const SizedBox(height: 16),

            // Featured
            CheckboxListTile(
              title: const Text('Featured Item'),
              subtitle: const Text('Show this item prominently'),
              value: _isFeatured,
              onChanged: (value) {
                setState(() {
                  _isFeatured = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSaving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Saving...',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        widget.productId == null ? 'Create Item' : 'Update Item',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      // Check permissions
      // TODO: Fix CameraPermissionService import
      // final hasPermission = await CameraPermissionService.handlePhotoPermissionRequest(context);
      // final hasPermission = true; // Temporary placeholder
      // if (!hasPermission) return;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && widget.productId != null) {
        setState(() => _isSaving = true);

        try {
          final menuItemRepository = ref.read(menuItemRepositoryProvider);
          final imageUrl = await menuItemRepository.uploadMenuItemImage(image, widget.productId!);

          setState(() {
            _imageUrl = imageUrl;
            _isSaving = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploaded successfully')),
            );
          }
        } catch (e) {
          setState(() => _isSaving = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload image: $e')),
            );
          }
        }
      } else if (image != null) {
        // For new items, store the image temporarily
        setState(() {
          _imageUrl = image.path; // Temporary local path
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _addCustomization() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomizationDialog(
          onSave: (customization) {
            setState(() {
              _customizations.add(customization);
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _editCustomization(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomizationDialog(
          customization: _customizations[index],
          onSave: (customization) {
            setState(() {
              _customizations[index] = customization;
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _removeCustomization(int index) {
    setState(() {
      _customizations.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final menuItemRepository = ref.read(menuItemRepositoryProvider);

      // Get current vendor
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get vendor ID from user ID
      final vendorRepository = ref.read(vendorRepositoryProvider);
      final vendor = await vendorRepository.getVendorByUserId(userId);

      if (vendor == null) {
        throw Exception('Vendor not found for current user');
      }

      // Parse tags from controller
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final product = Product(
        id: widget.productId ?? '',
        vendorId: vendor.id, // Use actual vendor ID
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        category: _selectedCategory!,
        tags: tags,
        basePrice: double.parse(_basePriceController.text),
        bulkPrice: _bulkPriceController.text.isEmpty ? null : double.parse(_bulkPriceController.text),
        bulkMinQuantity: _bulkMinQuantityController.text.isEmpty ? null : int.parse(_bulkMinQuantityController.text),
        currency: _currency,
        includesSst: _includesSst,
        isAvailable: _isAvailable,
        minOrderQuantity: int.parse(_minQuantityController.text),
        maxOrderQuantity: _maxQuantityController.text.isEmpty ? null : int.parse(_maxQuantityController.text),
        preparationTimeMinutes: int.parse(_prepTimeController.text),
        allergens: _allergens,
        isHalal: _isHalal,
        isVegetarian: _isVegetarian,
        isVegan: _isVegan,
        isSpicy: _isSpicy,
        spicyLevel: _spicyLevel,
        imageUrl: _imageUrl,
        galleryImages: _galleryImages,
        isFeatured: _isFeatured,
        customizations: _customizations,
        createdAt: _existingProduct?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.productId == null) {
        // Create new product
        await menuItemRepository.createMenuItem(product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item created successfully')),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // Update existing product
        await menuItemRepository.updateMenuItem(product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item updated successfully')),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save menu item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: const Text('Are you sure you want to delete this menu item? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteProduct();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct() async {
    if (widget.productId == null) return;

    setState(() => _isSaving = true);

    try {
      final menuItemRepository = ref.read(menuItemRepositoryProvider);
      await menuItemRepository.deleteMenuItem(widget.productId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu item deleted successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete menu item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
