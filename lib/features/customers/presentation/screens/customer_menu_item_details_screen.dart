import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/menu/data/models/product.dart';
import '../../../../features/vendors/data/models/vendor.dart';
import '../providers/customer_product_provider.dart';
import '../providers/customer_cart_provider.dart';
import '../widgets/customization_selection_widget.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/custom_error_widget.dart';

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
  int _quantity = 1;
  Map<String, dynamic> _selectedCustomizations = {};
  double _additionalPrice = 0.0;
  String? _specialInstructions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productAsync = ref.watch(productByIdProvider(widget.menuItemId));

    return productAsync.when(
      data: (product) {
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Item Not Found')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fastfood, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Menu item not found'),
                  SizedBox(height: 8),
                  Text('This item may have been removed or is no longer available.'),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(product.name),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductImage(product),
                      _buildProductInfo(product, theme),
                      const SizedBox(height: 24),

                      // Customizations section
                      if (product.customizations.isNotEmpty) ...[
                        CustomizationSelectionWidget(
                          key: ValueKey(product.id), // Add key to prevent rebuild issues
                          customizations: product.customizations,
                          selectedCustomizations: _selectedCustomizations,
                          onSelectionChanged: (customizations, additionalPrice) {
                            // Use post-frame callback to avoid setState during build
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                _selectedCustomizations = customizations;
                                _additionalPrice = additionalPrice;
                              });
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Special instructions
                      SpecialInstructionsWidget(
                        initialInstructions: _specialInstructions,
                        onInstructionsChanged: (instructions) {
                          setState(() {
                            _specialInstructions = instructions?.isNotEmpty == true ? instructions : null;
                          });
                        },
                      ),

                      const SizedBox(height: 24),
                      _buildQuantitySelector(product, theme),
                      const SizedBox(height: 100), // Space for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildAddToCartBar(product, theme),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const LoadingWidget(message: 'Loading menu item...'),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: CustomErrorWidget(
          message: 'Failed to load menu item: $error',
          onRetry: () => ref.refresh(productByIdProvider(widget.menuItemId)),
        ),
      ),
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
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: color),
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

  Widget _buildAddToCartBar(Product product, ThemeData theme) {
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
              onPressed: () => _addToCart(product),
              type: ButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(Product product) {
    // Validate required customizations
    if (!_validateRequiredCustomizations(product)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all required customizations'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      // Get vendor information - we need this for the cart
      // For now, we'll create a mock vendor object
      // In a real implementation, you'd get this from the product or a separate provider
      final mockVendor = _createMockVendorFromProduct(product);

      // Add item to cart with customizations
      ref.read(customerCartProvider.notifier).addItem(
        product: product,
        vendor: mockVendor,
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

  // Helper method to create a mock vendor object
  // In a real implementation, this would come from a proper vendor provider
  Vendor _createMockVendorFromProduct(Product product) {
    // This is a temporary solution - in production you'd get the actual vendor
    return Vendor(
      id: product.vendorId,
      businessName: 'Restaurant', // You'd get this from a vendor provider
      businessRegistrationNumber: 'TEMP-001',
      businessAddress: 'Restaurant Address',
      businessType: 'restaurant',
      cuisineTypes: const ['General'],
      isActive: true,
      isVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
