import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/product.dart';
import '../../../../user_management/domain/vendor.dart';
import '../../providers/customer/customer_product_provider.dart';
import '../../../../orders/presentation/providers/customer/customer_cart_provider.dart';
import '../../../../orders/presentation/widgets/customer/enhanced_customization_selection_widget.dart';
import '../../../../vendors/presentation/providers/vendor_provider.dart';
import '../../widgets/customer/feature_chip.dart';

import '../../../../../design_system/widgets/buttons/ge_button.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../../../../shared/widgets/custom_error_widget.dart';
import '../../../../../core/utils/logger.dart';

class CustomerMenuItemDetailsScreen extends ConsumerStatefulWidget {
  final String menuItemId;

  const CustomerMenuItemDetailsScreen({
    super.key,
    required this.menuItemId,
  });

  @override
  ConsumerState<CustomerMenuItemDetailsScreen> createState() => _CustomerMenuItemDetailsScreenState();
}

class _CustomerMenuItemDetailsScreenState extends ConsumerState<CustomerMenuItemDetailsScreen> {
  static final _logger = AppLogger();

  int _quantity = 1;
  final Map<String, dynamic> _selectedCustomizations = {};
  double _additionalPrice = 0.0; // Made mutable to update with customization prices
  String? _specialInstructions;

  @override
  Widget build(BuildContext context) {
    _logger.info('🍽️ [MENU-ITEM-DETAILS] Building screen for product: ${widget.menuItemId}');
    final theme = Theme.of(context);
    final productAsync = ref.watch(productByIdProvider(widget.menuItemId));

    return productAsync.when(
      data: (product) {
        if (product == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Item Not Found'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fastfood,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Menu item not found',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This item may have been removed or is no longer available.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Get vendor information
        final vendorAsync = ref.watch(vendorDetailsProvider(product.vendorId));

        return vendorAsync.when(
          data: (vendor) => _buildProductDetails(context, theme, product, vendor),
          loading: () => _buildLoadingScreen(theme),
          error: (error, stack) => _buildErrorScreen(theme, error),
        );
      },
      loading: () => _buildLoadingScreen(theme),
      error: (error, stack) => _buildErrorScreen(theme, error),
    );
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading...'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: const LoadingWidget(message: 'Loading menu item...'),
    );
  }

  Widget _buildErrorScreen(ThemeData theme, Object error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: CustomErrorWidget(
        message: 'Failed to load menu item: $error',
        onRetry: () => ref.refresh(productByIdProvider(widget.menuItemId)),
      ),
    );
  }

  Widget _buildProductDetails(BuildContext context, ThemeData theme, Product product, Vendor? vendor) {
    _logger.info('🍽️ [MENU-ITEM-DETAILS] Building product details for ${product.name}');

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(product),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductInfo(product, theme),
                        const SizedBox(height: 16),
                        _buildDietaryFeatures(product, theme),
                        const SizedBox(height: 16),

                        // Customizations section
                        if (product.customizations.isNotEmpty) ...[
                          _buildCustomizationsSection(product, theme),
                          const SizedBox(height: 16),
                        ],

                        // Special instructions
                        _buildSpecialInstructionsSection(theme),
                        const SizedBox(height: 16),

                        // Nutritional information
                        if (product.nutritionInfo != null) ...[
                          _buildNutritionalInfo(product, theme),
                          const SizedBox(height: 16),
                        ],

                        _buildQuantitySelector(product, theme),
                        const SizedBox(height: 100), // Space for bottom bar
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildAddToCartBar(product, vendor, theme),
    );
  }

  Widget _buildProductImage(Product product) {
    return Container(
      height: 250,
      width: double.infinity,
      color: Colors.grey[200],
      child: product.imageUrl != null
          ? Image.network(
              product.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
            )
          : _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Icon(
        Icons.fastfood,
        size: 64,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildProductInfo(Product product, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'RM ${product.basePrice.toStringAsFixed(2)}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          if (product.description?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              product.description!,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Tags and features
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (product.isHalal == true)
                _buildFeatureChip('Halal', Colors.green, Icons.verified),
              if (product.isVegetarian == true)
                _buildFeatureChip('Vegetarian', Colors.orange, Icons.eco),
              if (product.isVegan == true)
                _buildFeatureChip('Vegan', Colors.green, Icons.eco),
              if (product.isSpicy == true)
                _buildFeatureChip('Spicy', Colors.red, Icons.local_fire_department),
              if (product.preparationTimeMinutes != null)
                _buildFeatureChip(
                  '${product.preparationTimeMinutes} min',
                  Colors.blue,
                  Icons.access_time,
                ),
            ],
          ),
          
          if (product.allergens.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Allergens: ${product.allergens.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, Color color, IconData icon) {
    return FeatureChip(
      label: label,
      color: color,
      icon: icon,
    );
  }

  Widget _buildDietaryFeatures(Product product, ThemeData theme) {
    final features = <Widget>[];

    if (product.isHalal == true) {
      features.add(FeatureChip.halal());
    }
    if (product.isVegetarian == true) {
      features.add(FeatureChip.vegetarian());
    }
    if (product.isSpicy == true) {
      features.add(FeatureChip.spicy());
    }
    if (!(product.isAvailable ?? true)) {
      features.add(FeatureChip.unavailable());
    }

    if (features.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: features,
        ),
      ],
    );
  }

  Widget _buildCustomizationsSection(Product product, ThemeData theme) {
    _logger.info('🔧 [MENU-ITEM-DETAILS] Building customizations section for product: ${product.name}');
    _logger.info('🔧 [MENU-ITEM-DETAILS] Product has ${product.customizations.length} direct customizations');

    // Log each customization for debugging
    for (int i = 0; i < product.customizations.length; i++) {
      final customization = product.customizations[i];
      _logger.info('🔧 [MENU-ITEM-DETAILS] Customization $i: ${customization.name} (type: ${customization.type}, required: ${customization.isRequired}, options: ${customization.options.length})');

      for (int j = 0; j < customization.options.length; j++) {
        final option = customization.options[j];
        _logger.info('🔧 [MENU-ITEM-DETAILS]   Option $j: ${option.name} (+RM${option.additionalPrice})');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customizations',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        EnhancedCustomizationSelectionWidget(
          key: ValueKey(product.id),
          menuItemId: product.id,
          directCustomizations: product.customizations,
          selectedCustomizations: _selectedCustomizations,
          onSelectionChanged: (customizations, additionalPrice) {
            _logger.info('🔧 [MENU-ITEM-DETAILS] Customization selection changed: $customizations');
            _logger.info('🔧 [MENU-ITEM-DETAILS] Additional price: RM$additionalPrice');
            _logger.info('🔧 [MENU-ITEM-DETAILS] Previous additional price: RM$_additionalPrice');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedCustomizations.clear();
                _selectedCustomizations.addAll(customizations);
                _additionalPrice = additionalPrice; // Update the additional price
              });
              _logger.info('🔧 [MENU-ITEM-DETAILS] Updated additional price to: RM$_additionalPrice');
              _logger.info('🔧 [MENU-ITEM-DETAILS] New total price: RM${(_quantity * (product.basePrice + _additionalPrice)).toStringAsFixed(2)}');
            });
          },
        ),
      ],
    );
  }

  Widget _buildSpecialInstructionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special Instructions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Any special requests? (Optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: 3,
          onChanged: (value) {
            _specialInstructions = value.isNotEmpty ? value : null;
          },
        ),
      ],
    );
  }

  Widget _buildNutritionalInfo(Product product, ThemeData theme) {
    final nutritionInfo = product.nutritionInfo;
    if (nutritionInfo == null || nutritionInfo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutritional Information',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: nutritionInfo.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      entry.value.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(Product product, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Quantity',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _quantity > (product.minOrderQuantity ?? 1)
                    ? () {
                        setState(() => _quantity--);
                        _logger.info('🔢 [MENU-ITEM-DETAILS] Quantity decreased to: $_quantity');
                        _logger.info('🔢 [MENU-ITEM-DETAILS] New total: RM${(_quantity * (product.basePrice + _additionalPrice)).toStringAsFixed(2)}');
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_quantity',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: (product.maxOrderQuantity == null || _quantity < product.maxOrderQuantity!)
                    ? () {
                        setState(() => _quantity++);
                        _logger.info('🔢 [MENU-ITEM-DETAILS] Quantity increased to: $_quantity');
                        _logger.info('🔢 [MENU-ITEM-DETAILS] New total: RM${(_quantity * (product.basePrice + _additionalPrice)).toStringAsFixed(2)}');
                      }
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartBar(Product product, Vendor? vendor, ThemeData theme) {
    final itemPrice = product.basePrice + _additionalPrice;
    final totalPrice = itemPrice * _quantity;

    // Debug logging for price calculation
    _logger.info('💰 [MENU-ITEM-DETAILS] Price calculation:');
    _logger.info('💰 [MENU-ITEM-DETAILS]   Base price: RM${product.basePrice.toStringAsFixed(2)}');
    _logger.info('💰 [MENU-ITEM-DETAILS]   Additional price: RM${_additionalPrice.toStringAsFixed(2)}');
    _logger.info('💰 [MENU-ITEM-DETAILS]   Item price: RM${itemPrice.toStringAsFixed(2)}');
    _logger.info('💰 [MENU-ITEM-DETAILS]   Quantity: $_quantity');
    _logger.info('💰 [MENU-ITEM-DETAILS]   Total price: RM${totalPrice.toStringAsFixed(2)}');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price breakdown if there are customizations
            if (_additionalPrice > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Base price:',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    Text(
                      'RM ${product.basePrice.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customizations:',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    Text(
                      '+ RM ${_additionalPrice.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
            ],

            GEButton.primary(
              text: 'Add to Cart - RM ${totalPrice.toStringAsFixed(2)}',
              onPressed: () => _addToCart(product, vendor),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(Product product, Vendor? vendor) {
    _logger.info('🛒 [MENU-ITEM-DETAILS] Adding ${product.name} to cart');
    _logger.info('🛒 [MENU-ITEM-DETAILS] Current customizations: $_selectedCustomizations');
    _logger.info('🛒 [MENU-ITEM-DETAILS] Quantity: $_quantity');
    _logger.info('🛒 [MENU-ITEM-DETAILS] Special instructions: $_specialInstructions');

    // Validate required customizations
    if (!_validateRequiredCustomizations(product)) {
      _logger.warning('🛒 [MENU-ITEM-DETAILS] Validation failed for required customizations');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select all required customizations'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    _logger.info('🛒 [MENU-ITEM-DETAILS] Validation passed, proceeding to add to cart');

    // Validate vendor information
    if (vendor == null) {
      _logger.error('❌ [MENU-ITEM-DETAILS] Vendor information not available');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Restaurant information not available'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {

      ref.read(customerCartProvider.notifier).addItem(
        product: product,
        vendor: vendor,
        quantity: _quantity,
        customizations: _selectedCustomizations.isNotEmpty ? _selectedCustomizations : null,
        notes: _specialInstructions,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () => context.push('/customer/cart'),
          ),
        ),
      );

      // Navigate back
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add item to cart: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  bool _validateRequiredCustomizations(Product product) {
    _logger.info('🔍 [MENU-ITEM-DETAILS] Validating required customizations');

    for (final customization in product.customizations) {
      if (customization.isRequired) {
        final selection = _selectedCustomizations[customization.id];
        _logger.info('🔍 [MENU-ITEM-DETAILS] Checking customization ${customization.id} (${customization.name}): required=${customization.isRequired}, type=${customization.type}, selection=$selection');

        if (selection == null) {
          _logger.warning('🔍 [MENU-ITEM-DETAILS] Required customization ${customization.name} has no selection');
          return false;
        }

        // Handle different customization types and their data structures
        if (customization.type == 'single' || customization.type == 'single_select' || customization.type == 'radio') {
          // For single selections, expect a Map with 'id' key
          if (selection is Map<String, dynamic>) {
            final selectedId = selection['id']?.toString();
            if (selectedId == null || selectedId.isEmpty) {
              _logger.warning('🔍 [MENU-ITEM-DETAILS] Required single customization ${customization.name} has empty selection');
              return false;
            }
          } else if (selection is String) {
            // Backward compatibility: handle old string format
            if (selection.isEmpty) {
              _logger.warning('🔍 [MENU-ITEM-DETAILS] Required single customization ${customization.name} has empty string selection');
              return false;
            }
          } else {
            _logger.warning('🔍 [MENU-ITEM-DETAILS] Required single customization ${customization.name} has invalid selection type: ${selection.runtimeType}');
            return false;
          }
        }

        if (customization.type == 'multiple' || customization.type == 'multi_select' || customization.type == 'checkbox') {
          // For multiple selections, expect a List of Maps
          if (selection is List) {
            if (selection.isEmpty) {
              _logger.warning('🔍 [MENU-ITEM-DETAILS] Required multiple customization ${customization.name} has empty list selection');
              return false;
            }
          } else {
            _logger.warning('🔍 [MENU-ITEM-DETAILS] Required multiple customization ${customization.name} has invalid selection type: ${selection.runtimeType}');
            return false;
          }
        }
      }
    }

    _logger.info('🔍 [MENU-ITEM-DETAILS] All required customizations validated successfully');
    return true;
  }


}
