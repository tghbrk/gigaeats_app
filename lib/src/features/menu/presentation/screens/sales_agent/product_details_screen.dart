import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../data/models/product.dart';

// TODO: Fix cart provider import path - cart provider doesn't exist yet
// import '../../../../sales_agent/presentation/providers/cart_provider.dart';
import '../../../../../design_system/widgets/buttons/ge_button.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _quantity = 1;
  // TODO: Restore _selectedNotes when notes functionality is implemented
  // String? _selectedNotes;
  final TextEditingController _notesController = TextEditingController();
  // New state to hold selected customizations
  final Map<String, dynamic> _selectedCustomizations = {};

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            SizedBox(
              height: 300,
              width: double.infinity,
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.fastfood, size: 64),
                        ),
                      ),
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.fastfood, size: 64),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Category
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.category,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Rating and Reviews
                  if (product.safeRating > 0)
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          product.safeRating.toStringAsFixed(1),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.safeTotalReviews} reviews)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (product.safeIsHalal)
                        _buildBadge('HALAL', Colors.green, Colors.white),
                      if (product.safeIsVegetarian)
                        _buildBadge('VEGETARIAN', Colors.orange, Colors.white),
                      if (product.safeIsVegan)
                        _buildBadge('VEGAN', Colors.teal, Colors.white),
                      if (product.safeIsSpicy)
                        _buildBadge('SPICY ${product.safeSpicyLevel}/5', Colors.red, Colors.white),
                      if (product.safeIsFeatured)
                        _buildBadge('FEATURED', theme.colorScheme.primary, Colors.white),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.safeDescription,
                    style: theme.textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 16),

                  // Pricing Information
                  _buildPricingCard(),

                  const SizedBox(height: 16),

                  // Render customization options
                  _buildCustomizationOptions(),

                  // Availability Information
                  _buildAvailabilityCard(),

                  const SizedBox(height: 16),

                  // Allergens
                  if (product.allergens.isNotEmpty) ...[
                    Text(
                      'Allergens',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: product.allergens.map((allergen) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            allergen,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Nutrition Information
                  if (product.nutrition != null) ...[
                    Text(
                      'Nutrition Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildNutritionCard(),
                    const SizedBox(height: 16),
                  ],

                  // Quantity Selector
                  Text(
                    'Quantity',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildQuantitySelector(),

                  const SizedBox(height: 16),

                  // Special Notes
                  Text(
                    'Special Notes (Optional)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Any special instructions or preferences...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      // TODO: Restore when _selectedNotes is implemented
                      // _selectedNotes = value.isNotEmpty ? value : null;
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: GEButton.primary(
            text: 'Add to Cart - RM ${(_calculateTotalPrice()).toStringAsFixed(2)}',
            onPressed: product.availability.isAvailable ? _addToCart : null,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    final theme = Theme.of(context);
    final product = widget.product;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Unit Price:',
                  style: theme.textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  'RM ${product.pricing.effectivePrice.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (product.pricing.bulkPrice != null && product.pricing.bulkMinQuantity != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Bulk Price (${product.pricing.bulkMinQuantity}+):',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    'RM ${product.pricing.bulkPrice!.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              product.pricing.includesSst ? 'Prices include SST' : 'Prices exclude SST',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New method to build customization options UI
  Widget _buildCustomizationOptions() {
    final product = widget.product;
    if (product.customizations.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customization section title
        Text(
          'Customize Your Order',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your preferences for this item',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),

        // Customization groups
        ...product.customizations.map((group) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (group.isRequired) ...[
                      const SizedBox(width: 4),
                      Text(
                        '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                if (group.isRequired)
                  Text(
                    'Required',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 8),
                if (group.type == 'single')
                  ...group.options.map((option) => RadioListTile<String>(
                    title: Text('${option.name} (+RM ${option.additionalPrice.toStringAsFixed(2)})'),
                    value: option.id ?? option.name, // Use name as fallback for new options
                    groupValue: _selectedCustomizations[group.id ?? group.name]?['id'],
                    onChanged: (value) {
                      setState(() {
                        _selectedCustomizations[group.id ?? group.name] = {'id': value, 'name': option.name, 'price': option.additionalPrice};
                      });
                    },
                  ))
                else // Multiple choice
                  ...group.options.map((option) {
                    final currentSelections = _selectedCustomizations[group.id ?? group.name] as List? ?? [];
                    final optionId = option.id ?? option.name; // Use name as fallback for new options
                    final isSelected = currentSelections.any((e) => e['id'] == optionId);
                    return CheckboxListTile(
                      title: Text('${option.name} (+RM ${option.additionalPrice.toStringAsFixed(2)})'),
                      value: isSelected,
                      onChanged: (selected) {
                        setState(() {
                          final selections = List.from(currentSelections);
                          if (selected == true) {
                            selections.add({'id': optionId, 'name': option.name, 'price': option.additionalPrice});
                          } else {
                            selections.removeWhere((e) => e['id'] == optionId);
                          }
                          _selectedCustomizations[group.id ?? group.name] = selections;
                        });
                      },
                    );
                  }),
              ],
            ),
          ),
        );
      }),
      ],
    );
  }

  Widget _buildAvailabilityCard() {
    final theme = Theme.of(context);
    final availability = widget.product.availability;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Availability',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: availability.isAvailable
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    availability.isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color: availability.isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAvailabilityRow('Min Order Quantity', '${availability.minimumOrderQuantity}'),
            _buildAvailabilityRow('Max Order Quantity', '${availability.maximumOrderQuantity}'),
            _buildAvailabilityRow('Preparation Time', '${availability.preparationTimeMinutes} minutes'),
            if (availability.stockQuantity != null)
              _buildAvailabilityRow('Stock Available', '${availability.stockQuantity}'),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label:',
            style: theme.textTheme.bodySmall,
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard() {
    // final theme = Theme.of(context); // TODO: Use for styling
    final nutrition = widget.product.nutrition!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNutritionRow('Calories', '${nutrition.calories} kcal'),
            _buildNutritionRow('Protein', '${nutrition.protein}g'),
            _buildNutritionRow('Carbohydrates', '${nutrition.carbohydrates}g'),
            _buildNutritionRow('Fat', '${nutrition.fat}g'),
            if (nutrition.fiber != null)
              _buildNutritionRow('Fiber', '${nutrition.fiber}g'),
            if (nutrition.sodium != null)
              _buildNutritionRow('Sodium', '${nutrition.sodium}mg'),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label:',
            style: theme.textTheme.bodySmall,
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    final theme = Theme.of(context);
    final availability = widget.product.availability;

    return Row(
      children: [
        IconButton(
          onPressed: _quantity > availability.minimumOrderQuantity
              ? () => setState(() => _quantity--)
              : null,
          icon: const Icon(Icons.remove),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$_quantity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: _quantity < availability.maximumOrderQuantity
              ? () => setState(() => _quantity++)
              : null,
          icon: const Icon(Icons.add),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Min: ${availability.minimumOrderQuantity}, Max: ${availability.maximumOrderQuantity}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  // Update total price calculation
  double _calculateTotalPrice() {
    final product = widget.product;
    double basePrice = product.pricing.effectivePrice;
    double addonsPrice = 0;

    _selectedCustomizations.forEach((groupId, value) {
      if (value is Map && value.containsKey('price')) {
        addonsPrice += (value['price'] as num).toDouble();
      } else if (value is List) {
        for (var option in value) {
          if (option is Map && option.containsKey('price')) {
            addonsPrice += (option['price'] as num).toDouble();
          }
        }
      }
    });

    return (basePrice + addonsPrice) * _quantity;
  }

  // Validate required customizations
  bool _validateRequiredCustomizations() {
    for (final group in widget.product.customizations) {
      if (group.isRequired) {
        final selection = _selectedCustomizations[group.id ?? group.name];
        if (selection == null ||
            (selection is List && selection.isEmpty) ||
            (selection is Map && selection.isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please select an option for ${group.name}'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _addToCart() async {
    // Validate required customizations first
    if (!_validateRequiredCustomizations()) {
      return;
    }

    final product = widget.product;

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Adding to cart...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    // TODO: Fix provider imports and implement cart functionality
    /*
    try {
      // Get vendor details from provider
      final vendorAsync = ref.read(vendorDetailsProvider(product.vendorId));

      await vendorAsync.when(
        data: (vendor) async {
          if (vendor != null) {
            ref.read(cartProvider.notifier).addItem(
              product: product,
              vendor: vendor,
              quantity: _quantity,
              customizations: _selectedCustomizations, // Pass selected customizations
              notes: _selectedNotes,
            );

            // Clear the loading snackbar and show success only if widget is still mounted
            if (mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} (x$_quantity) added to cart'),
                  backgroundColor: Colors.green,
                  action: SnackBarAction(
                    label: 'View Cart',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to cart screen using go_router
                      Navigator.pushNamed(context, '/sales-agent/cart');
                    },
                  ),
                ),
              );

              Navigator.pop(context);
            }
          } else {
            throw Exception('Vendor information not available');
          }
        },
        loading: () async {
          // Wait a bit for loading
          await Future.delayed(const Duration(milliseconds: 500));
        },
        error: (error, stack) async {
          throw Exception('Failed to load vendor: $error');
        },
      );
    } catch (e) {
      // Clear the loading snackbar and show error only if widget is still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    */

    // Temporary placeholder - show success message
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} (x$_quantity) will be added to cart'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
    }
  }
}
