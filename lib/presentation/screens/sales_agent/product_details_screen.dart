import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../data/models/product.dart';
import '../../../data/models/vendor.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/custom_button.dart';

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
  String? _selectedNotes;
  final TextEditingController _notesController = TextEditingController();

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
                  if (product.rating > 0)
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.totalReviews} reviews)',
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
                      if (product.isHalal)
                        _buildBadge('HALAL', Colors.green, Colors.white),
                      if (product.isVegetarian)
                        _buildBadge('VEGETARIAN', Colors.orange, Colors.white),
                      if (product.isVegan)
                        _buildBadge('VEGAN', Colors.teal, Colors.white),
                      if (product.isSpicy)
                        _buildBadge('SPICY ${product.spicyLevel}/5', Colors.red, Colors.white),
                      if (product.isFeatured)
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
                    product.description,
                    style: theme.textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 16),

                  // Pricing Information
                  _buildPricingCard(),

                  const SizedBox(height: 16),

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
                      _selectedNotes = value.isNotEmpty ? value : null;
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
          child: CustomButton(
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

  double _calculateTotalPrice() {
    final product = widget.product;
    final pricing = product.pricing;

    // Use bulk price if quantity meets minimum
    final unitPrice = (pricing.bulkPrice != null &&
                      pricing.bulkMinQuantity != null &&
                      _quantity >= pricing.bulkMinQuantity!)
        ? pricing.bulkPrice!
        : pricing.effectivePrice;

    return unitPrice * _quantity;
  }

  void _addToCart() {
    final product = widget.product;

    // Create a temporary vendor object for the cart
    // In a real app, you would fetch the vendor details
    final tempVendor = Vendor(
      id: product.vendorId,
      businessName: 'Vendor ${product.vendorId}', // TODO: Get actual vendor name
      ownerName: '',
      email: '',
      phoneNumber: '',
      description: '',
      address: VendorAddress(
        street: '',
        city: '',
        state: '',
        postcode: '',
        latitude: 0.0,
        longitude: 0.0,
      ),
      cuisineTypes: [],
      businessInfo: VendorBusinessInfo(
        ssmNumber: '',
        minimumOrderAmount: 0.0,
        deliveryRadius: 0.0,
        paymentMethods: [],
        operatingHours: VendorOperatingHours(schedule: {}),
      ),
      settings: VendorSettings(),
      rating: 0.0,
      totalReviews: 0,
      isActive: true,
      isVerified: false,
      isHalalCertified: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ref.read(cartProvider.notifier).addItem(
      product: product,
      vendor: tempVendor,
      quantity: _quantity,
      notes: _selectedNotes,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} (x$_quantity) added to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            Navigator.pop(context);
            // TODO: Navigate to cart
          },
        ),
      ),
    );

    Navigator.pop(context);
  }
}
