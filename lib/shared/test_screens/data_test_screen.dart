import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../presentation/providers/repository_providers.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/customers/presentation/providers/customer_provider.dart' as customer_prov;
import '../../features/customers/data/models/customer.dart';

class DataTestScreen extends ConsumerWidget {
  const DataTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(featuredVendorsProvider);
    final recentOrdersAsync = ref.watch(recentOrdersProvider);
    final customerStatsAsync = ref.watch(customerStatisticsProvider);

    // Also watch the raw web providers for debugging
    final webVendorsAsync = kIsWeb ? ref.watch(webVendorsProvider) : null;
    final webOrdersAsync = kIsWeb ? ref.watch(webOrdersProvider) : null;
    final orderSummariesAsync = kIsWeb ? ref.watch(orderSummariesProvider) : null;

    // Test menu items with a sample vendor ID (if vendors are available)
    final sampleVendorId = vendorsAsync.when(
      data: (vendors) => vendors.isNotEmpty ? vendors.first.id : null,
      loading: () => null,
      error: (_, _) => null,
    );

    final menuItemsAsync = sampleVendorId != null
        ? ref.watch(platformMenuItemsProvider({
            'vendorId': sampleVendorId,
            'isAvailable': true,
            'useStream': !kIsWeb,
          }))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Data Integration Test ${kIsWeb ? "(Web)" : "(Mobile)"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(featuredVendorsProvider);
              ref.invalidate(recentOrdersProvider);
              ref.invalidate(customerStatisticsProvider);
              if (kIsWeb) {
                ref.invalidate(webOrdersProvider);
                ref.invalidate(webVendorsProvider);
                ref.invalidate(webConnectionTestProvider);
                if (sampleVendorId != null) {
                  ref.invalidate(platformMenuItemsProvider({
                    'vendorId': sampleVendorId,
                    'isAvailable': true,
                    'useStream': !kIsWeb,
                  }));
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Web Connection Test (only show on web)
            if (kIsWeb) ...[
              Card(
                color: Colors.purple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Web Connection Test',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.purple.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Consumer(
                        builder: (context, ref, child) {
                          final connectionTestAsync = ref.watch(webConnectionTestProvider);
                          return connectionTestAsync.when(
                            data: (isConnected) {
                              return Text(
                                isConnected
                                  ? '✅ Web authentication and Supabase connection working'
                                  : '❌ Web authentication or Supabase connection failed',
                                style: TextStyle(
                                  color: isConnected ? Colors.green : Colors.red,
                                ),
                              );
                            },
                            loading: () => const Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Testing web connection...'),
                              ],
                            ),
                            error: (error, stack) => Text(
                              '❌ Web connection test failed: $error',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Raw Web Data Debug (only show on web)
            if (kIsWeb) ...[
              Card(
                color: Colors.yellow.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Raw Web Data Debug',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Raw Vendors Data
                      Text(
                        'Raw Vendors Data:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      if (webVendorsAsync != null)
                        webVendorsAsync.when(
                          data: (vendors) => Text(
                            'Raw vendors count: ${vendors.length}\n'
                            'Sample: ${vendors.isNotEmpty ? vendors.first.toString() : "No data"}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          loading: () => const Text('Loading raw vendors...'),
                          error: (error, stack) => Text(
                            'Raw vendors error: $error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Raw Orders Data
                      Text(
                        'Current User Debug:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Consumer(
                        builder: (context, ref, child) {
                          final authState = ref.watch(authStateProvider);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auth Status: ${authState.status}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'User ID: ${authState.user?.id ?? "null"}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Email: ${authState.user?.email ?? "null"}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Role: ${authState.user?.role ?? "unknown"}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (authState.errorMessage != null)
                                Text(
                                  'Error: ${authState.errorMessage}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Raw Orders Data:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      if (webOrdersAsync != null)
                        webOrdersAsync.when(
                          data: (orders) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Raw orders count: ${orders.length}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (orders.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Sample order: ${orders.first['order_number']} - ${orders.first['status']} - RM ${orders.first['total_amount']}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Has vendor_name: ${orders.first.containsKey('vendor_name')}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  'Has customer_name: ${orders.first.containsKey('customer_name')}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  'Has order_items: ${orders.first.containsKey('order_items')}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ] else
                                Text(
                                  'No raw orders data',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                          loading: () => const Text('Loading raw orders...'),
                          error: (error, stack) => Text(
                            'Raw orders error: $error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Order Summaries Test
                      Text(
                        'Order Summaries (Simplified):',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      if (orderSummariesAsync != null)
                        orderSummariesAsync.when(
                          data: (summaries) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order summaries count: ${summaries.length}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (summaries.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                ...summaries.take(3).map((summary) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '• ${summary.orderNumber} - ${summary.status} - RM ${summary.totalAmount.toStringAsFixed(2)} (${summary.vendorName ?? "Unknown Vendor"})',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                )),
                              ] else
                                Text(
                                  'No order summaries',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                          loading: () => const Text('Loading order summaries...'),
                          error: (error, stack) => Text(
                            'Order summaries error: $error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Direct API Test Button
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final orderRepository = ref.read(orderRepositoryProvider);
                            final client = await orderRepository.getAuthenticatedClient();

                            // First, check current user
                            final currentUser = client.auth.currentUser;
                            debugPrint('Direct API Test: Current user ID: ${currentUser?.id}');
                            debugPrint('Direct API Test: Current user email: ${currentUser?.email}');

                            final response = await client
                                .from('orders')
                                .select('id, order_number, status')
                                .limit(3);

                            debugPrint('Direct API Test: Response: $response');

                            // Note: Using context across async gap - acceptable for test screen
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Direct API: Found ${response.length} orders (User: ${currentUser?.email})'),
                                backgroundColor: response.isNotEmpty ? Colors.green : Colors.orange,
                              ),
                            );
                          } catch (e) {
                            debugPrint('Direct API Test Error: $e');
                            // Note: Using context across async gap - acceptable for test screen
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Direct API Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text('Direct API Test'),
                      ),

                      const SizedBox(height: 8),

                      // Check User Role Button
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final orderRepository = ref.read(orderRepositoryProvider);
                            final client = await orderRepository.getAuthenticatedClient();

                            final currentUser = client.auth.currentUser;
                            if (currentUser == null) {
                              // Note: Using context across async gap - acceptable for test screen
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No user logged in'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Check user role in database
                            final response = await client
                                .from('users')
                                .select('id, email, role')
                                .eq('supabase_user_id', currentUser.id)
                                .single();

                            debugPrint('User Role Check: $response');

                            // Note: Using context across async gap - acceptable for test screen
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('DB Role: ${response['role']} for ${response['email']}'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          } catch (e) {
                            debugPrint('User Role Check Error: $e');
                            // Note: Using context across async gap - acceptable for test screen
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Role Check Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text('Check User Role'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Test Vendors Data
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Featured Vendors Test',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    vendorsAsync.when(
                      data: (vendors) {
                        if (vendors.isEmpty) {
                          return const Text(
                            '❌ No vendors found. Please run the seed.sql script in Supabase.',
                            style: TextStyle(color: Colors.orange),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '✅ Found ${vendors.length} vendors:',
                              style: const TextStyle(color: Colors.green),
                            ),
                            const SizedBox(height: 8),
                            ...vendors.map((vendor) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• ${vendor.businessName} (Rating: ${vendor.rating})',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )),
                          ],
                        );
                      },
                      loading: () => const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Loading vendors...'),
                        ],
                      ),
                      error: (error, stack) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '❌ Error loading vendors: ${_getErrorMessage(error)}',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          if (error.toString().contains('not authenticated'))
                            const Text(
                              '💡 Please make sure you are logged in with Supabase Auth',
                              style: TextStyle(color: Colors.orange),
                            ),
                          if (error.toString().contains('operator does not exist'))
                            const Text(
                              '💡 Database schema issue detected. Check RLS policies and enum types.',
                              style: TextStyle(color: Colors.orange),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Orders Data
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Orders Test',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    recentOrdersAsync.when(
                      data: (orders) {
                        if (orders.isEmpty) {
                          return const Text(
                            '❌ No orders found. Please run the seed.sql script in Supabase.',
                            style: TextStyle(color: Colors.orange),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '✅ Found ${orders.length} recent orders:',
                              style: const TextStyle(color: Colors.green),
                            ),
                            const SizedBox(height: 8),
                            ...orders.map((order) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• ${order.orderNumber} - ${order.customerName} (RM ${order.totalAmount.toStringAsFixed(2)})',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )),
                          ],
                        );
                      },
                      loading: () => const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Loading orders...'),
                        ],
                      ),
                      error: (error, stack) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '❌ Error loading orders: ${_getErrorMessage(error)}',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          if (error.toString().contains('not authenticated'))
                            const Text(
                              '💡 Please make sure you are logged in with Supabase Auth',
                              style: TextStyle(color: Colors.orange),
                            ),
                          if (error.toString().contains('operator does not exist'))
                            const Text(
                              '💡 Database schema issue detected. Check RLS policies and enum types.',
                              style: TextStyle(color: Colors.orange),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Customer Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Statistics Test',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    customerStatsAsync.when(
                      data: (stats) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '✅ Customer statistics loaded:',
                              style: TextStyle(color: Colors.green),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total Customers: ${stats['total_customers'] ?? 0}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              'Active Customers: ${stats['active_customers'] ?? 0}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              'Total Revenue: RM ${stats['total_revenue'] ?? 0}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        );
                      },
                      loading: () => const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Loading customer stats...'),
                        ],
                      ),
                      error: (error, stack) => Text(
                        '❌ Error loading customer stats: $error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Menu Items
            if (menuItemsAsync != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menu Items Test (Platform-Aware)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Testing vendor: ${sampleVendorId ?? "None"}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      menuItemsAsync.when(
                        data: (menuItems) {
                          if (menuItems.isEmpty) {
                            return const Text(
                              '❌ No menu items found for this vendor.',
                              style: TextStyle(color: Colors.orange),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '✅ Found ${menuItems.length} menu items:',
                                style: const TextStyle(color: Colors.green),
                              ),
                              const SizedBox(height: 8),
                              ...menuItems.take(3).map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '• ${item.name} - RM ${item.basePrice.toStringAsFixed(2)} (${item.category})',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              )),
                              if (menuItems.length > 3)
                                Text(
                                  '... and ${menuItems.length - 3} more items',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          );
                        },
                        loading: () => const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Loading menu items...'),
                          ],
                        ),
                        error: (error, stack) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '❌ Error loading menu items: ${_getErrorMessage(error)}',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            if (error.toString().contains('not authenticated'))
                              const Text(
                                '💡 Please make sure you are logged in with Supabase Auth',
                                style: TextStyle(color: Colors.orange),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Test Authentication
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authentication Test',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (context, ref, child) {
                        // Check Supabase Auth status
                        final supabaseUser = ref.watch(supabaseClientProvider).auth.currentUser;

                        // Check app auth state
                        final authState = ref.watch(authStateProvider);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Supabase Auth Status
                            Text(
                              'Supabase Auth Status:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              supabaseUser != null
                                ? '✅ Supabase user logged in: ${supabaseUser.email}'
                                : '❌ No Supabase user logged in',
                              style: TextStyle(
                                color: supabaseUser != null ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // App Auth State
                            Text(
                              'App Auth State:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            if (authState.status == AuthStatus.loading)
                              const Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Loading authentication state...'),
                                ],
                              )
                            else if (authState.status == AuthStatus.authenticated && authState.user != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '✅ App user authenticated:',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Name: ${authState.user!.fullName}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    'Email: ${authState.user!.email}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    'Role: ${authState.user!.role.displayName}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    'Verified: ${authState.user!.isVerified ? "Yes" : "No"}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              )
                            else if (supabaseUser != null)
                              // Supabase user exists but app user not loaded
                              const Text(
                                '⚠️ Supabase authenticated but app user not loaded',
                                style: TextStyle(color: Colors.orange),
                              )
                            else
                              const Text(
                                '❌ No authenticated user found. Please login first.',
                                style: TextStyle(color: Colors.red),
                              ),

                            if (authState.errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Error: ${authState.errorMessage}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Customer Creation Test
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Creation Test',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        debugPrint('DataTestScreen: ===== STARTING CUSTOMER CREATION TEST =====');
                        try {
                          // Create a simple customer object
                          final customer = Customer(
                            id: '', // Will be generated by the backend
                            salesAgentId: '', // Will be set by the repository
                            type: CustomerType.corporate,
                            organizationName: 'Test Company Ltd',
                            contactPersonName: 'John Smith',
                            email: 'john@testcompany.com',
                            phoneNumber: '+60123456789',
                            address: const CustomerAddress(
                              street: '123 Test Street',
                              city: 'Kuala Lumpur',
                              state: 'Selangor',
                              postcode: '50000',
                            ),
                            preferences: const CustomerPreferences(),
                            lastOrderDate: DateTime.now(),
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          debugPrint('DataTestScreen: Customer object created successfully');
                          debugPrint('DataTestScreen: Customer JSON: ${customer.toJson()}');

                          // Get the customer provider
                          final customerNotifier = ref.read(customer_prov.customerProvider.notifier);
                          debugPrint('DataTestScreen: Got customer provider, calling createCustomer...');

                          // Call the create customer method
                          final result = await customerNotifier.createCustomer(customer);

                          if (result != null) {
                            debugPrint('DataTestScreen: ✅ Customer created successfully!');
                            debugPrint('DataTestScreen: Created customer: ${result.toJson()}');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Test customer created successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else {
                            debugPrint('DataTestScreen: ❌ Customer creation failed - result is null');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('❌ Test customer creation failed - no result'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e, stackTrace) {
                          debugPrint('DataTestScreen: ❌ Customer creation error: $e');
                          debugPrint('DataTestScreen: Stack trace: $stackTrace');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Customer creation error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                        debugPrint('DataTestScreen: ===== CUSTOMER CREATION TEST COMPLETED =====');
                      },
                      child: const Text('🧪 Test Customer Creation'),
                    ),
                    const SizedBox(height: 16),

                    // Direct API Test Button
                    ElevatedButton(
                      onPressed: () async {
                        debugPrint('DataTestScreen: ===== STARTING DIRECT API TEST =====');
                        try {
                          final supabase = ref.read(supabaseClientProvider);
                          debugPrint('DataTestScreen: Got Supabase client');
                          debugPrint('DataTestScreen: Current user: ${supabase.auth.currentUser?.email}');

                          // Test vendors query directly
                          debugPrint('DataTestScreen: Testing vendors query...');
                          final vendorsResponse = await supabase
                              .from('vendors')
                              .select('id, business_name, rating, is_active, is_verified')
                              .eq('is_active', true)
                              .eq('is_verified', true)
                              .limit(5);

                          debugPrint('DataTestScreen: Vendors response: $vendorsResponse');
                          debugPrint('DataTestScreen: Vendors count: ${vendorsResponse.length}');

                          // Test orders query directly
                          debugPrint('DataTestScreen: Testing orders query...');
                          final ordersResponse = await supabase
                              .from('orders')
                              .select('id, order_number, status, total_amount')
                              .limit(5);

                          debugPrint('DataTestScreen: Orders response: $ordersResponse');
                          debugPrint('DataTestScreen: Orders count: ${ordersResponse.length}');

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Direct API test completed! Vendors: ${vendorsResponse.length}, Orders: ${ordersResponse.length}'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e, stackTrace) {
                          debugPrint('DataTestScreen: ❌ Direct API test error: $e');
                          debugPrint('DataTestScreen: Stack trace: $stackTrace');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Direct API test error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                        debugPrint('DataTestScreen: ===== DIRECT API TEST COMPLETED =====');
                      },
                      child: const Text('🔧 Test Direct API Calls'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Run the seed.sql script in your Supabase dashboard\n'
                      '2. Make sure you are logged in with Supabase Auth\n'
                      '3. Check that your Supabase configuration is correct\n'
                      '4. Verify RLS policies are properly configured\n'
                      '5. Tap the refresh button to reload data',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to extract user-friendly error messages
  String _getErrorMessage(Object error) {
    final errorString = error.toString();

    // Handle common PostgreSQL errors
    if (errorString.contains('operator does not exist: user_role_enum')) {
      return 'Database schema error: user_role_enum type issue';
    }

    if (errorString.contains('PGRST116')) {
      return 'No data found (empty result)';
    }

    if (errorString.contains('not authenticated')) {
      return 'Authentication required';
    }

    if (errorString.contains('Session expired')) {
      return 'Session expired - please log in again';
    }

    if (errorString.contains('permission')) {
      return 'Permission denied - check user role';
    }

    // Return first line of error for brevity
    final lines = errorString.split('\n');
    return lines.isNotEmpty ? lines.first : errorString;
  }
}
