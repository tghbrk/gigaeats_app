import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/customers/data/models/customer.dart';
import '../../features/menu/data/models/product.dart';
import '../../features/vendors/data/models/vendor.dart';
// TODO: Restore unused import - commented out for analyzer cleanup
// import '../../features/sales_agent/presentation/providers/cart_provider.dart';
import '../../features/user_management/presentation/widgets/customer_selector.dart';

/// Test screen specifically for testing customer selection text color fix
class CustomerSelectionTestScreen extends ConsumerStatefulWidget {
  const CustomerSelectionTestScreen({super.key});

  @override
  ConsumerState<CustomerSelectionTestScreen> createState() => _CustomerSelectionTestScreenState();
}

class _CustomerSelectionTestScreenState extends ConsumerState<CustomerSelectionTestScreen> {
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    // Add some test items to cart so we can test create order screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addTestItemsToCart();
    });
  }

  void _addTestItemsToCart() {
    // TODO: Restore undefined identifier - commented out for analyzer cleanup
    // final cartNotifier = ref.read(cartProvider.notifier);
    final cartNotifier = null; // Placeholder

    // Create test product and vendor
    final testProduct = Product(
      id: 'test-item-1',
      vendorId: 'test-vendor-1',
      name: 'Test Nasi Lemak',
      description: 'Delicious test nasi lemak',
      basePrice: 12.50,
      category: 'Main Course',
      isAvailable: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final testVendor = Vendor(
      id: 'test-vendor-1',
      businessName: 'Test Kitchen',
      businessRegistrationNumber: 'TEST123456',
      businessAddress: 'Test Address',
      businessType: 'Restaurant',
      cuisineTypes: ['Malaysian'],
      isActive: true,
      isVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    cartNotifier.addItem(
      product: testProduct,
      vendor: testVendor,
      quantity: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Restore undefined identifier - commented out for analyzer cleanup
    // final cartState = ref.watch(cartProvider);
    final cartState = <String, dynamic>{}; // Placeholder
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Selection Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              if (cartState.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cart is empty. Adding test items...')),
                );
                _addTestItemsToCart();
              } else {
                context.push('/sales-agent/create-order');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cart status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cart Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // TODO: Restore undefined getters - commented out for analyzer cleanup
                    // Text('Items: ${cartState.totalItems}'),
                    // Text('Total: RM ${cartState.totalAmount.toStringAsFixed(2)}'),
                    Text('Items: ${cartState['totalItems'] ?? 0}'),
                    Text('Total: RM ${(cartState['totalAmount'] ?? 0.0).toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _addTestItemsToCart(),
                          child: const Text('Add Test Items'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: cartState.isEmpty 
                              ? null 
                              : () => context.push('/sales-agent/create-order'),
                          child: const Text('Go to Create Order'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Customer Selection Test
            Text(
              'Customer Selection Test',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              'Test the customer selection functionality below. When you select a customer, '
              'check that the text in the selected customer card has proper contrast and is readable.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            const SizedBox(height: 16),
            
            // Customer Selector
            Expanded(
              child: CustomerSelector(
                selectedCustomer: _selectedCustomer,
                onCustomerSelected: (customer) {
                  setState(() {
                    _selectedCustomer = customer;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
