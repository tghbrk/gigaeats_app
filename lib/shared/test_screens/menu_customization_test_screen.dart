import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/menu/data/models/product.dart';
import '../../features/vendors/data/models/vendor.dart';
import '../../features/sales_agent/presentation/providers/cart_provider.dart';

class MenuCustomizationTestScreen extends ConsumerStatefulWidget {
  const MenuCustomizationTestScreen({super.key});

  @override
  ConsumerState<MenuCustomizationTestScreen> createState() => _MenuCustomizationTestScreenState();
}

class _MenuCustomizationTestScreenState extends ConsumerState<MenuCustomizationTestScreen> {
  late Product testProduct;
  late Vendor testVendor;

  @override
  void initState() {
    super.initState();
    _createTestData();
  }

  void _createTestData() {
    // Create test customizations
    final sizeCustomization = MenuItemCustomization(
      id: 'size-group',
      name: 'Size',
      type: 'single',
      isRequired: true,
      options: [
        CustomizationOption(
          id: 'size-small',
          name: 'Small',
          additionalPrice: 0.0,
          isDefault: true,
        ),
        CustomizationOption(
          id: 'size-medium',
          name: 'Medium',
          additionalPrice: 2.0,
        ),
        CustomizationOption(
          id: 'size-large',
          name: 'Large',
          additionalPrice: 4.0,
        ),
      ],
    );

    final spiceCustomization = MenuItemCustomization(
      id: 'spice-group',
      name: 'Spice Level',
      type: 'single',
      isRequired: false,
      options: [
        CustomizationOption(
          id: 'spice-mild',
          name: 'Mild',
          additionalPrice: 0.0,
          isDefault: true,
        ),
        CustomizationOption(
          id: 'spice-medium',
          name: 'Medium',
          additionalPrice: 0.0,
        ),
        CustomizationOption(
          id: 'spice-hot',
          name: 'Hot',
          additionalPrice: 0.0,
        ),
      ],
    );

    final addonsCustomization = MenuItemCustomization(
      id: 'addons-group',
      name: 'Add-ons',
      type: 'multiple',
      isRequired: false,
      options: [
        CustomizationOption(
          id: 'addon-cheese',
          name: 'Extra Cheese',
          additionalPrice: 1.5,
        ),
        CustomizationOption(
          id: 'addon-bacon',
          name: 'Bacon',
          additionalPrice: 3.0,
        ),
        CustomizationOption(
          id: 'addon-mushroom',
          name: 'Mushrooms',
          additionalPrice: 2.0,
        ),
      ],
    );

    // Create test product with customizations
    testProduct = Product(
      id: 'test-product-1',
      vendorId: 'test-vendor-1',
      name: 'Customizable Burger',
      description: 'A delicious burger with customizable options',
      category: 'Main Course',
      basePrice: 15.0,
      imageUrl: null,
      isAvailable: true,
      isVegetarian: false,
      isHalal: true,
      tags: ['burger', 'customizable'],
      rating: 4.5,
      totalReviews: 100,
      customizations: [sizeCustomization, spiceCustomization, addonsCustomization],
    );

    // Create test vendor
    testVendor = Vendor(
      id: 'test-vendor-1',
      businessName: 'Test Burger Joint',
      userId: 'test-user-1',
      businessRegistrationNumber: 'TEST-001',
      businessAddress: 'Test Address',
      businessType: 'Restaurant',
      cuisineTypes: ['Western'],
      isActive: true,
      isVerified: true,
      rating: 4.5,
      totalReviews: 50,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Customization Test'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testProduct.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(testProduct.description ?? 'No description available'),
                    const SizedBox(height: 8),
                    Text(
                      'Base Price: RM ${testProduct.basePrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Customizations Display
            Text(
              'Available Customizations:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            ...testProduct.customizations.map((customization) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          customization.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (customization.isRequired) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '*',
                            style: TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${customization.type} choice${customization.isRequired ? " (Required)" : " (Optional)"}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...customization.options.map((option) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            customization.type == 'single' 
                              ? Icons.radio_button_unchecked 
                              : Icons.check_box_outline_blank,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${option.name} ${option.additionalPrice > 0 ? "(+RM ${option.additionalPrice.toStringAsFixed(2)})" : ""}',
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            )),

            const SizedBox(height: 16),

            // Test Buttons
            Text(
              'Test Actions:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () => _addTestItemToCart(),
              child: const Text('Add Test Item to Cart'),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () => _addCustomizedItemToCart(),
              child: const Text('Add Customized Item to Cart'),
            ),

            const SizedBox(height: 16),

            // Cart Display
            Text(
              'Current Cart (${cart.items.length} items):',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            if (cart.items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Cart is empty'),
                ),
              )
            else
              ...cart.items.map((item) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.name}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            'RM ${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      if (item.customizations != null && item.customizations!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Customizations: ${_formatCustomizations(item.customizations!)}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                      Text(
                        'Unit Price: RM ${item.unitPrice.toStringAsFixed(2)} | Total: RM ${item.singleItemPrice.toStringAsFixed(2)} each',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )),

            const SizedBox(height: 16),

            if (cart.items.isNotEmpty)
              ElevatedButton(
                onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Clear Cart'),
              ),
          ],
        ),
      ),
    );
  }

  void _addTestItemToCart() {
    ref.read(cartProvider.notifier).addItem(
      product: testProduct,
      vendor: testVendor,
      quantity: 1,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Basic item added to cart')),
    );
  }

  void _addCustomizedItemToCart() {
    final customizations = {
      'size-group': {'id': 'size-large', 'name': 'Large', 'price': 4.0},
      'spice-group': {'id': 'spice-hot', 'name': 'Hot', 'price': 0.0},
      'addons-group': [
        {'id': 'addon-cheese', 'name': 'Extra Cheese', 'price': 1.5},
        {'id': 'addon-bacon', 'name': 'Bacon', 'price': 3.0},
      ],
    };

    ref.read(cartProvider.notifier).addItem(
      product: testProduct,
      vendor: testVendor,
      quantity: 1,
      customizations: customizations,
      notes: 'Test customized order',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customized item added to cart')),
    );
  }

  String _formatCustomizations(Map<String, dynamic> customizations) {
    final parts = <String>[];
    customizations.forEach((key, value) {
      if (value is Map && value.containsKey('name')) {
        parts.add(value['name']);
      } else if (value is List) {
        for (var option in value) {
          if (option is Map && option.containsKey('name')) {
            parts.add(option['name']);
          }
        }
      }
    });
    return parts.join(', ');
  }
}
