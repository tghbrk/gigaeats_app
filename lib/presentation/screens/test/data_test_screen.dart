import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/repository_providers.dart';

class DataTestScreen extends ConsumerWidget {
  const DataTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(featuredVendorsProvider);
    final recentOrdersAsync = ref.watch(recentOrdersProvider);
    final customerStatsAsync = ref.watch(customerStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Integration Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(featuredVendorsProvider);
              ref.invalidate(recentOrdersProvider);
              ref.invalidate(customerStatisticsProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      error: (error, stack) => Text(
                        '❌ Error loading vendors: $error',
                        style: const TextStyle(color: Colors.red),
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
                      error: (error, stack) => Text(
                        '❌ Error loading orders: $error',
                        style: const TextStyle(color: Colors.red),
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
                        final currentUserAsync = ref.watch(currentUserProvider);
                        return currentUserAsync.when(
                          data: (user) {
                            if (user == null) {
                              return const Text(
                                '❌ No authenticated user found. Please login first.',
                                style: TextStyle(color: Colors.orange),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '✅ User authenticated:',
                                  style: TextStyle(color: Colors.green),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Name: ${user.fullName}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  'Email: ${user.email}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  'Role: ${user.role.displayName}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  'Verified: ${user.isVerified ? "Yes" : "No"}',
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
                              Text('Loading user...'),
                            ],
                          ),
                          error: (error, stack) => Text(
                            '❌ Error loading user: $error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      },
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
                      '2. Make sure you are logged in with Firebase Auth\n'
                      '3. Check that your Supabase configuration is correct\n'
                      '4. Tap the refresh button to reload data',
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
}
