import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/orders/data/models/order.dart';
import '../../features/menu/data/models/product.dart';
import '../../features/vendors/data/models/vendor.dart';
import '../../features/sales_agent/presentation/providers/cart_provider.dart';
import '../../features/orders/presentation/providers/order_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/custom_button.dart';

class OrderCreationTestScreen extends ConsumerStatefulWidget {
  const OrderCreationTestScreen({super.key});

  @override
  ConsumerState<OrderCreationTestScreen> createState() => _OrderCreationTestScreenState();
}

class _OrderCreationTestScreenState extends ConsumerState<OrderCreationTestScreen> {
  final List<String> _logs = [];
  bool _isCreatingOrder = false;

  // Test data with valid UUIDs from the database
  static const String validVendorId = '550e8400-e29b-41d4-a716-446655440101';

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toIso8601String().substring(11, 19)}: $message');
      if (_logs.length > 20) _logs.removeLast();
    });
  }

  Future<void> _loginTestUser() async {
    try {
      _addLog('🔐 Attempting to login test user...');

      final authService = ref.read(supabaseAuthServiceProvider);
      final result = await authService.signInWithEmailAndPassword(
        email: 'test6@gigaeats.com',
        password: 'testpass123', // Test password
      );

      if (result.isSuccess) {
        _addLog('✅ Login successful!');
        _addLog('   User: ${result.user?.email}');
        _addLog('   Role: ${result.user?.role.displayName}');
      } else {
        _addLog('❌ Login failed: ${result.errorMessage}');
      }
    } catch (e) {
      _addLog('💥 Login error: $e');
    }
  }

  Future<void> _setupTestCart() async {
    try {
      _addLog('🛒 Setting up test cart...');
      
      final cartNotifier = ref.read(cartProvider.notifier);
      cartNotifier.clearCart();

      // Create test vendor with valid UUID
      final testVendor = Vendor(
        id: validVendorId,
        businessName: 'Nasi Lemak Delicious',
        userId: 'test_user_id',
        businessRegistrationNumber: 'SSM123456789',
        businessAddress: '123 Jalan Bukit Bintang, Kuala Lumpur, Selangor',
        businessType: 'Restaurant',
        cuisineTypes: ['Malaysian', 'Chinese'],
        isHalalCertified: true,
        description: 'Authentic Malaysian cuisine',
        rating: 4.5,
        totalReviews: 150,
        isActive: true,
        isVerified: true,
        serviceAreas: ['Kuala Lumpur', 'Selangor'],
        minimumOrderAmount: 20.0,
        deliveryFee: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create test products with valid UUIDs
      final testProducts = [
        Product(
          id: '550e8400-e29b-41d4-a716-446655440201',
          vendorId: validVendorId,
          name: 'Nasi Lemak Special',
          description: 'Traditional Malaysian coconut rice with sambal, anchovies, peanuts, and egg',
          category: 'Rice Dishes',
          basePrice: 15.50,
          isAvailable: true,
          minOrderQuantity: 1,
          maxOrderQuantity: 10,
          isHalal: true,
          isVegetarian: false,
          isSpicy: true,
          spicyLevel: 2,
          isFeatured: true,
          tags: const ['Malaysian', 'Rice', 'Spicy'],
          preparationTimeMinutes: 20,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          id: '550e8400-e29b-41d4-a716-446655440202',
          vendorId: validVendorId,
          name: 'Teh Tarik',
          description: 'Traditional Malaysian pulled tea with condensed milk',
          category: 'Beverages',
          basePrice: 4.50,
          isAvailable: true,
          minOrderQuantity: 1,
          maxOrderQuantity: 20,
          isHalal: true,
          isVegetarian: true,
          isSpicy: false,
          spicyLevel: 0,
          isFeatured: false,
          tags: const ['Beverages', 'Tea', 'Malaysian'],
          preparationTimeMinutes: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Add items to cart
      for (final product in testProducts) {
        cartNotifier.addItem(
          product: product,
          vendor: testVendor,
          quantity: product.name == 'Teh Tarik' ? 2 : 1,
          notes: product.name == 'Nasi Lemak Special' ? 'Extra spicy please' : null,
        );
      }

      _addLog('✅ Test cart setup complete with ${testProducts.length} items');
    } catch (e) {
      _addLog('❌ Error setting up test cart: $e');
    }
  }

  Future<void> _createTestOrder({
    required String scenario,
    required String customerName,
    required String phone,
    required Address address,
    String? notes,
  }) async {
    if (_isCreatingOrder) return;

    setState(() {
      _isCreatingOrder = true;
    });

    try {
      _addLog('🚀 Starting $scenario order creation...');

      // Check authentication
      final authState = ref.read(authStateProvider);
      if (authState.user == null) {
        _addLog('❌ Not authenticated');
        return;
      }

      // Check cart
      final cartState = ref.read(cartProvider);
      if (cartState.isEmpty) {
        _addLog('❌ Cart is empty - setting up test cart first...');
        await _setupTestCart();
      }

      _addLog('📋 Order details:');
      _addLog('   Customer: $customerName');
      _addLog('   Phone: $phone');
      _addLog('   Address: ${address.street}, ${address.city}');
      _addLog('   Cart items: ${cartState.totalItems}');

      final deliveryDate = DateTime.now().add(const Duration(hours: 2));

      final order = await ref.read(ordersProvider.notifier).createOrder(
        customerId: null, // Will be generated
        customerName: customerName,
        deliveryDate: deliveryDate,
        deliveryAddress: address,
        notes: notes,
        contactPhone: phone,
      );

      if (order != null) {
        _addLog('🎉 SUCCESS! Order created:');
        _addLog('   Order ID: ${order.id}');
        _addLog('   Order Number: ${order.orderNumber}');
        _addLog('   Total: RM ${order.totalAmount.toStringAsFixed(2)}');
        _addLog('   Status: ${order.status.displayName}');
        
        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('✅ Order Created Successfully!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Number: ${order.orderNumber}'),
                  Text('Customer: ${order.customerName}'),
                  Text('Total: RM ${order.totalAmount.toStringAsFixed(2)}'),
                  Text('Status: ${order.status.displayName}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        _addLog('❌ Order creation returned null');
      }
    } catch (e) {
      _addLog('💥 ERROR: $e');
      
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('❌ Order Creation Failed'),
            content: Text('Error: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        _isCreatingOrder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Creation Test'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                _logs.clear();
              });
            },
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          authState.user != null ? Icons.check_circle : Icons.error,
                          color: authState.user != null ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text('Authentication: ${authState.user != null ? "✅ Logged in" : "❌ Not logged in"}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          cartState.isEmpty ? Icons.shopping_cart_outlined : Icons.shopping_cart,
                          color: cartState.isEmpty ? Colors.orange : Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text('Cart: ${cartState.isEmpty ? "Empty" : "${cartState.totalItems} items"}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Actions Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Login Test User Button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Login as Test User (test6@gigaeats.com)',
                        onPressed: _loginTestUser,
                        backgroundColor: Colors.indigo,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Logout',
                        onPressed: () async {
                          try {
                            _addLog('🚪 Logging out...');
                            await ref.read(authStateProvider.notifier).signOut();
                            _addLog('✅ Logout successful');
                          } catch (e) {
                            _addLog('❌ Logout error: $e');
                          }
                        },
                        backgroundColor: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Debug Auth Status Button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Debug Auth Status',
                        onPressed: () async {
                          try {
                            _addLog('🔍 Checking auth status...');
                            final authState = ref.read(authStateProvider);
                            _addLog('   Status: ${authState.status}');
                            _addLog('   User: ${authState.user?.email ?? 'null'}');
                            _addLog('   Role: ${authState.user?.role.displayName ?? 'null'}');

                            // Check Supabase client directly
                            final supabase = Supabase.instance.client;
                            final currentUser = supabase.auth.currentUser;
                            _addLog('   Supabase User: ${currentUser?.email ?? 'null'}');
                            _addLog('   Supabase ID: ${currentUser?.id ?? 'null'}');
                          } catch (e) {
                            _addLog('❌ Debug error: $e');
                          }
                        },
                        backgroundColor: Colors.teal,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Setup Cart Button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Setup Test Cart',
                        onPressed: _setupTestCart,
                        backgroundColor: Colors.blue,
                      ),
                    ),
                    
                    const SizedBox(height: 12),

                    // Test Order Scenarios
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: _isCreatingOrder ? 'Creating Order...' : 'Create KL Corporate Order',
                        onPressed: _isCreatingOrder ? null : () => _createTestOrder(
                          scenario: 'KL Corporate',
                          customerName: 'Tech Solutions Sdn Bhd',
                          phone: '+60123456789',
                          address: const Address(
                            street: '50 Jalan Bukit Bintang',
                            city: 'Kuala Lumpur',
                            state: 'Wilayah Persekutuan',
                            postalCode: '55100',
                            country: 'Malaysia',
                          ),
                          notes: 'Corporate lunch order for 10 people',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: _isCreatingOrder ? 'Creating Order...' : 'Create Selangor Residential Order',
                        onPressed: _isCreatingOrder ? null : () => _createTestOrder(
                          scenario: 'Selangor Residential',
                          customerName: 'Ahmad bin Abdullah',
                          phone: '+60198765432',
                          address: const Address(
                            street: '123 Jalan SS2/24, Taman Bahagia',
                            city: 'Petaling Jaya',
                            state: 'Selangor',
                            postalCode: '47300',
                            country: 'Malaysia',
                          ),
                          notes: 'Family dinner order - please call upon arrival',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: _isCreatingOrder ? 'Creating Order...' : 'Create Johor Order',
                        onPressed: _isCreatingOrder ? null : () => _createTestOrder(
                          scenario: 'Johor',
                          customerName: 'Siti Nurhaliza Enterprise',
                          phone: '+60177654321',
                          address: const Address(
                            street: '88 Jalan Molek 1/30, Taman Molek',
                            city: 'Johor Bahru',
                            state: 'Johor',
                            postalCode: '81100',
                            country: 'Malaysia',
                          ),
                          notes: 'Office catering - vegetarian options preferred',
                        ),
                        backgroundColor: Colors.purple,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Clear Cart Button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Clear Cart',
                        onPressed: () {
                          ref.read(cartProvider.notifier).clearCart();
                          _addLog('🗑️ Cart cleared');
                        },
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Logs Section
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Logs',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _logs.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No logs yet. Start testing to see logs here.',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  reverse: true,
                                  itemCount: _logs.length,
                                  itemBuilder: (context, index) {
                                    final log = _logs[index];
                                    Color textColor = Colors.black87;
                                    if (log.contains('❌') || log.contains('ERROR')) {
                                      textColor = Colors.red;
                                    } else if (log.contains('✅') || log.contains('SUCCESS')) {
                                      textColor = Colors.green;
                                    } else if (log.contains('🚀') || log.contains('📋')) {
                                      textColor = Colors.blue;
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        log,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          color: textColor,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
