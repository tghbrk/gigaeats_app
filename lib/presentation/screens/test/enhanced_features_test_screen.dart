import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/enhanced_order_provider.dart';
import '../../providers/enhanced_payment_provider.dart';
import '../../providers/enhanced_commission_provider.dart';
import '../../providers/enhanced_vendor_menu_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/services/supabase_auth_service.dart';
import '../../../core/utils/debug_logger.dart';

class EnhancedFeaturesTestScreen extends ConsumerStatefulWidget {
  const EnhancedFeaturesTestScreen({super.key});

  @override
  ConsumerState<EnhancedFeaturesTestScreen> createState() => _EnhancedFeaturesTestScreenState();
}

class _EnhancedFeaturesTestScreenState extends ConsumerState<EnhancedFeaturesTestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Features Test'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          // Authentication Status and Login Button
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: authState.user != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        authState.user!.email,
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ],
                  )
                : ElevatedButton.icon(
                    onPressed: _loginTestUser,
                    icon: const Icon(Icons.login, size: 16),
                    label: const Text('Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Orders'),
            Tab(text: 'Payments'),
            Tab(text: 'Commission'),
            Tab(text: 'Menu'),
          ],
        ),
      ),
      body: authState.user != null
          ? TabBarView(
              controller: _tabController,
              children: const [
                _EnhancedOrderTestTab(),
                _EnhancedPaymentTestTab(),
                _EnhancedCommissionTestTab(),
                _EnhancedMenuTestTab(),
              ],
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Authentication Required',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please login to access enhanced features',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _loginTestUser() async {
    try {
      DebugLogger.info('🔐 Attempting to login test user for enhanced features...', tag: 'EnhancedFeaturesTest');

      final authService = ref.read(supabaseAuthServiceProvider);
      final result = await authService.signInWithEmailAndPassword(
        email: 'test@gigaeats.com', // Use existing test user
        password: 'Test123!',
      );

      if (result.isSuccess) {
        DebugLogger.success('✅ Login successful! User: ${result.user?.email}, Role: ${result.user?.role.displayName}', tag: 'EnhancedFeaturesTest');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logged in as ${result.user?.email} (${result.user?.role.displayName})'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        DebugLogger.error('❌ Login failed: ${result.errorMessage}', tag: 'EnhancedFeaturesTest');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${result.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      DebugLogger.error('💥 Login error: $e', tag: 'EnhancedFeaturesTest');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Enhanced Order Management Test Tab
class _EnhancedOrderTestTab extends ConsumerWidget {
  const _EnhancedOrderTestTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(enhancedOrdersProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Real-time Connection Status
          Card(
            child: ListTile(
              leading: Icon(
                ordersState.hasRealtimeConnection ? Icons.wifi : Icons.wifi_off,
                color: ordersState.hasRealtimeConnection ? Colors.green : Colors.red,
              ),
              title: Text(
                ordersState.hasRealtimeConnection 
                    ? 'Real-time Connected' 
                    : 'Real-time Disconnected'
              ),
              subtitle: ordersState.lastUpdated != null
                  ? Text('Last updated: ${ordersState.lastUpdated!.toLocal()}')
                  : const Text('No updates yet'),
            ),
          ),
          const SizedBox(height: 16),

          // Order Statistics
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Orders',
                  value: ordersState.orders.length.toString(),
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  title: 'Pending',
                  value: ordersState.orders.where((o) => o.status.value == 'pending').length.toString(),
                  icon: Icons.pending,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Test Actions
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _testCreateOrderWithEdgeFunction(ref),
                icon: const Icon(Icons.add),
                label: const Text('Test Edge Function Order'),
              ),
              ElevatedButton.icon(
                onPressed: () => ref.read(enhancedOrdersProvider.notifier).loadOrders(),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Orders'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Orders List
          Expanded(
            child: ordersState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ordersState.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${ordersState.errorMessage}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: ordersState.orders.length,
                        itemBuilder: (context, index) {
                          final order = ordersState.orders[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(order.status.value),
                                child: Text(
                                  order.orderNumber.substring(0, 2).toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                              title: Text('Order ${order.orderNumber}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Status: ${order.status.value}'),
                                  Text('Total: RM${order.totalAmount.toStringAsFixed(2)}'),
                                  Text('Customer: ${order.customerName}'),
                                ],
                              ),
                              trailing: Text(
                                '${order.createdAt.day}/${order.createdAt.month}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'preparing': return Colors.purple;
      case 'ready': return Colors.green;
      case 'delivered': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _testCreateOrderWithEdgeFunction(WidgetRef ref) async {
    try {
      DebugLogger.info('Testing Edge Function order creation', tag: 'EnhancedFeaturesTest');

      // Get current authenticated user
      final authState = ref.read(authStateProvider);
      final currentUserId = authState.user?.id;

      if (currentUserId == null) {
        DebugLogger.error('No authenticated user found', tag: 'EnhancedFeaturesTest');
        return;
      }

      DebugLogger.info('Creating order for current user: ${authState.user?.email} (${authState.user?.role.displayName})', tag: 'EnhancedFeaturesTest');

      final request = CreateOrderRequest(
        vendorId: '550e8400-e29b-41d4-a716-446655440101', // Nasi Lemak Delicious (actual existing vendor)
        customerId: '550e8400-e29b-41d4-a716-446655440301', // Tech Solutions Sdn Bhd (actual existing customer)
        salesAgentId: currentUserId, // Use current authenticated user's ID
        deliveryDate: DateTime.now().add(const Duration(days: 1)),
        deliveryAddress: {
          'street': '123 Test Street',
          'city': 'Kuala Lumpur',
          'state': 'Selangor',
          'postal_code': '50000',
          'country': 'Malaysia',
        },
        items: [
          OrderItemRequest(
            menuItemId: '550e8400-e29b-41d4-a716-446655440201', // Nasi Lemak Special (valid menu item UUID)
            quantity: 2,
            unitPrice: 15.50,
            notes: 'Extra spicy',
          ),
          OrderItemRequest(
            menuItemId: '550e8400-e29b-41d4-a716-446655440202', // Mee Goreng Mamak (valid menu item UUID)
            quantity: 1,
            unitPrice: 8.90,
          ),
        ],
        specialInstructions: 'Test order created via Enhanced Features Test',
        contactPhone: '+60123456789',
      );

      final order = await ref.read(enhancedOrdersProvider.notifier).createOrderWithEdgeFunction(request);
      
      if (order != null) {
        DebugLogger.success('Edge Function order created successfully: ${order.id}', tag: 'EnhancedFeaturesTest');
      } else {
        DebugLogger.error('Failed to create order via Edge Function', tag: 'EnhancedFeaturesTest');
      }
    } catch (e) {
      DebugLogger.error('Error testing Edge Function: $e', tag: 'EnhancedFeaturesTest');
    }
  }
}

// Enhanced Payment Test Tab
class _EnhancedPaymentTestTab extends ConsumerWidget {
  const _EnhancedPaymentTestTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(enhancedPaymentProvider);
    final paymentMethods = ref.watch(availablePaymentMethodsProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Status
          Card(
            child: ListTile(
              leading: Icon(
                paymentState.isProcessing ? Icons.payment : Icons.payment_outlined,
                color: paymentState.isProcessing ? Colors.blue : Colors.green,
              ),
              title: Text(
                paymentState.isProcessing ? 'Processing Payment...' : 'Payment Ready'
              ),
              subtitle: paymentState.lastResult != null
                  ? Text('Last result: ${paymentState.lastResult!.status}')
                  : const Text('No recent payments'),
            ),
          ),
          const SizedBox(height: 16),

          // Test Payment Methods
          const Text('Test Payment Methods:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: paymentMethods.length,
              itemBuilder: (context, index) {
                final method = paymentMethods[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      _getPaymentIcon(method['id']),
                      color: method['enabled'] ? Colors.green : Colors.grey,
                    ),
                    title: Text(method['name']),
                    subtitle: Text(method['description']),
                    trailing: ElevatedButton(
                      onPressed: method['enabled'] 
                          ? () => _testPayment(ref, method['id'])
                          : null,
                      child: const Text('Test'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String methodId) {
    switch (methodId) {
      case 'fpx': return Icons.account_balance;
      case 'credit_card': return Icons.credit_card;
      case 'grabpay': return Icons.local_taxi;
      case 'tng': return Icons.touch_app;
      case 'boost': return Icons.rocket_launch;
      case 'shopeepay': return Icons.shopping_bag;
      default: return Icons.payment;
    }
  }

  void _testPayment(WidgetRef ref, String methodId) async {
    try {
      DebugLogger.info('Testing payment method: $methodId', tag: 'EnhancedFeaturesTest');
      
      PaymentResult? result;
      
      switch (methodId) {
        case 'fpx':
          result = await ref.read(enhancedPaymentProvider.notifier).processFPXPayment(
            orderId: 'test-order-${DateTime.now().millisecondsSinceEpoch}',
            amount: 50.00,
            bankCode: 'MAYBANK',
          );
          break;
        case 'credit_card':
          result = await ref.read(enhancedPaymentProvider.notifier).processCreditCardPayment(
            orderId: 'test-order-${DateTime.now().millisecondsSinceEpoch}',
            amount: 50.00,
            paymentMethodId: 'pm_test_card',
          );
          break;
        default:
          result = await ref.read(enhancedPaymentProvider.notifier).processEWalletPayment(
            orderId: 'test-order-${DateTime.now().millisecondsSinceEpoch}',
            amount: 50.00,
            walletType: methodId,
          );
      }
      
      if (result != null && result.success) {
        DebugLogger.success('Payment test successful: ${result.transactionId}', tag: 'EnhancedFeaturesTest');
      } else {
        DebugLogger.error('Payment test failed: ${result?.errorMessage}', tag: 'EnhancedFeaturesTest');
      }
    } catch (e) {
      DebugLogger.error('Error testing payment: $e', tag: 'EnhancedFeaturesTest');
    }
  }
}

// Enhanced Commission Test Tab
class _EnhancedCommissionTestTab extends ConsumerWidget {
  const _EnhancedCommissionTestTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commissionState = ref.watch(enhancedCommissionProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Commission Statistics
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Earnings',
                  value: 'RM${commissionState.totalEarnings.toStringAsFixed(2)}',
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  title: 'Pending',
                  value: 'RM${commissionState.pendingCommissions.toStringAsFixed(2)}',
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Test Actions
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _testLoadCommissionData(ref),
                icon: const Icon(Icons.refresh),
                label: const Text('Load Commission Data'),
              ),
              ElevatedButton.icon(
                onPressed: () => _testCreateCommissionTier(ref),
                icon: const Icon(Icons.add),
                label: const Text('Create Test Tier'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Commission Transactions
          Expanded(
            child: commissionState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: commissionState.transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = commissionState.transactions[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getCommissionStatusColor(transaction.status),
                            child: const Icon(Icons.monetization_on, color: Colors.white),
                          ),
                          title: Text('RM${transaction.netCommission.toStringAsFixed(2)}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order: ${transaction.orderId}'),
                              Text('Rate: ${(transaction.commissionRate * 100).toStringAsFixed(1)}%'),
                              Text('Status: ${transaction.status}'),
                            ],
                          ),
                          trailing: Text(
                            '${transaction.createdAt.day}/${transaction.createdAt.month}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getCommissionStatusColor(String status) {
    switch (status) {
      case 'earned': return Colors.green;
      case 'pending': return Colors.orange;
      case 'paid': return Colors.blue;
      default: return Colors.grey;
    }
  }

  void _testLoadCommissionData(WidgetRef ref) async {
    const testSalesAgentId = '550e8400-e29b-41d4-a716-446655440001'; // John Doe - Sales Agent (valid UUID)
    await ref.read(enhancedCommissionProvider.notifier).loadCommissionData(testSalesAgentId);
  }

  void _testCreateCommissionTier(WidgetRef ref) async {
    await ref.read(enhancedCommissionProvider.notifier).createCommissionTier(
      salesAgentId: '550e8400-e29b-41d4-a716-446655440001', // John Doe - Sales Agent (valid UUID)
      tierName: 'Test Tier',
      minOrders: 10,
      maxOrders: 50,
      commissionRate: 0.08, // 8%
    );
  }
}

// Enhanced Menu Management Test Tab
class _EnhancedMenuTestTab extends ConsumerWidget {
  const _EnhancedMenuTestTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(enhancedMenuManagementProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menu Version Info
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.blue),
              title: Text(
                menuState.activeVersion?.name ?? 'No Active Version'
              ),
              subtitle: Text(
                'Version ${menuState.activeVersion?.versionNumber ?? 0} • ${menuState.currentMenuItems.length} items'
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Test Actions
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _testLoadMenuVersions(ref),
                icon: const Icon(Icons.refresh),
                label: const Text('Load Menu'),
              ),
              ElevatedButton.icon(
                onPressed: () => _testCreateMenuVersion(ref),
                icon: const Icon(Icons.add),
                label: const Text('Create Version'),
              ),
              ElevatedButton.icon(
                onPressed: () => _testBulkOperation(ref),
                icon: const Icon(Icons.batch_prediction),
                label: const Text('Bulk Update'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Menu Items by Category
          Expanded(
            child: menuState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: menuState.itemsByCategory.keys.length,
                    itemBuilder: (context, index) {
                      final category = menuState.itemsByCategory.keys.elementAt(index);
                      final items = menuState.itemsByCategory[category]!;
                      
                      return ExpansionTile(
                        title: Text(category),
                        subtitle: Text('${items.length} items'),
                        children: items.map((item) => ListTile(
                          leading: CircleAvatar(
                            child: Text('RM'),
                          ),
                          title: Text(item.name),
                          subtitle: Text(item.description ?? 'No description'),
                          trailing: Text('RM${item.price.toStringAsFixed(2)}'),
                        )).toList(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _testLoadMenuVersions(WidgetRef ref) async {
    const testVendorId = '550e8400-e29b-41d4-a716-446655440101'; // Nasi Lemak Delicious (valid UUID)
    await ref.read(enhancedMenuManagementProvider.notifier).loadMenuVersions(testVendorId);
  }

  void _testCreateMenuVersion(WidgetRef ref) async {
    await ref.read(enhancedMenuManagementProvider.notifier).createMenuVersion(
      vendorId: '550e8400-e29b-41d4-a716-446655440101', // Nasi Lemak Delicious (valid UUID)
      name: 'Test Menu Version ${DateTime.now().millisecondsSinceEpoch}',
      description: 'Test menu version created from enhanced features test',
      createdBy: '550e8400-e29b-41d4-a716-446655440001', // John Doe - Sales Agent (valid UUID)
    );
  }

  void _testBulkOperation(WidgetRef ref) async {
    final operation = BulkMenuOperation(
      operation: 'price_update',
      items: [
        {'id': '2fde631a-35b1-4d6a-90c8-5fec9df90e1b', 'price': 15.50}, // Nasi Lemak Special (valid UUID)
        {'id': 'da416fc5-b329-4aaf-be22-922cb60aec7d', 'price': 10.90}, // Mee Goreng Mamak (valid UUID)
      ],
    );

    await ref.read(enhancedMenuManagementProvider.notifier).performBulkOperation(operation);
  }
}

// Reusable Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
