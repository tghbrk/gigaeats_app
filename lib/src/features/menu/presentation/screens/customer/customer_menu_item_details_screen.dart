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

import '../../../../../shared/widgets/custom_button.dart';
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
  final double _additionalPrice = 0.0;
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
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
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
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: const LoadingWidget(message: 'Loading menu item...'),
    );
  }

  Widget _buildErrorScreen(ThemeData theme, Object error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
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
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedCustomizations.clear();
                _selectedCustomizations.addAll(customizations);
              });
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
                    ? () => setState(() => _quantity--)
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
                    ? () => setState(() => _quantity++)
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

            CustomButton(
              text: 'Add to Cart - RM ${totalPrice.toStringAsFixed(2)}',
              onPressed: () => _addToCart(product, vendor),
              type: ButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(Product product, Vendor? vendor) {
    _logger.info('🛒 [MENU-ITEM-DETAILS] Adding ${product.name} to cart');

    // Validate required customizations
    if (!_validateRequiredCustomizations(product)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select all required customizations'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

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
    for (final customization in product.customizations) {
      if (customization.isRequired) {
        final selection = _selectedCustomizations[customization.id];
        if (selection == null) return false;

        if (customization.type == 'single' && (selection as String).isEmpty) {
          return false;
        }

        if (customization.type == 'multiple' && (selection as List).isEmpty) {
          return false;
        }
      }
    }
    return true;
  }


}
