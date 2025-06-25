import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../vendors/data/models/driver.dart';
import '../../data/models/driver_error.dart';
import '../providers/driver_dashboard_provider.dart';

/// Example showing how to use the driver dashboard providers
/// This demonstrates the integration between UI and backend services
class DriverDashboardIntegrationExample extends ConsumerWidget {
  const DriverDashboardIntegrationExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard Integration Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Example 1: Using individual providers
            _buildIndividualProvidersExample(ref),
            
            const SizedBox(height: 24),
            
            // Example 2: Using the main dashboard data provider
            _buildMainProviderExample(ref),
            
            const SizedBox(height: 24),
            
            // Example 3: Driver status toggle
            _buildStatusToggleExample(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualProvidersExample(WidgetRef ref) {
    final activeOrdersCount = ref.watch(activeOrdersCountProvider);
    final todaysEarnings = ref.watch(todaysEarningsProvider);
    final todaysDeliveries = ref.watch(todaysDeliveriesProvider);
    final driverStatus = ref.watch(driverStatusDisplayProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Individual Providers Example',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Active Orders: $activeOrdersCount'),
            Text('Today\'s Earnings: RM ${todaysEarnings.toStringAsFixed(2)}'),
            Text('Today\'s Deliveries: $todaysDeliveries'),
            Text('Driver Status: $driverStatus'),
          ],
        ),
      ),
    );
  }

  Widget _buildMainProviderExample(WidgetRef ref) {
    final dashboardDataAsync = ref.watch(realtimeDashboardDataProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Realtime Dashboard Example',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => ref.invalidate(realtimeDashboardDataProvider),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 12),
            dashboardDataAsync.when(
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${data.driverStatus.displayName}'),
                  Text('Online: ${data.isOnline}'),
                  Text('Active Orders: ${data.activeOrders.length}'),
                  Text('Today\'s Earnings: RM ${data.todaySummary.earningsToday.toStringAsFixed(2)}'),
                  Text('Success Rate: ${data.todaySummary.successRate.toStringAsFixed(1)}%'),
                  Text('Rating: ${data.todaySummary.averageRating.toStringAsFixed(1)} ⭐'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text('Real-time updates enabled', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) {
                final driverError = error is DriverException
                    ? error
                    : DriverException.fromException(error);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Error: ${driverError.userFriendlyMessage}'),
                    if (driverError.shouldRetry)
                      ElevatedButton(
                        onPressed: () => ref.invalidate(realtimeDashboardDataProvider),
                        child: const Text('Retry'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggleExample(WidgetRef ref) {
    final dashboardActions = ref.read(realtimeDashboardActionsProvider);
    final dashboardDataAsync = ref.watch(realtimeDashboardDataProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enhanced Status Toggle Example',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            dashboardDataAsync.when(
              data: (data) => Row(
                children: [
                  Text('Driver Status: ${data.driverStatus.displayName}'),
                  const Spacer(),
                  Switch(
                    value: data.isOnline,
                    onChanged: (value) async {
                      final newStatus = value
                        ? DriverStatus.online
                        : DriverStatus.offline;

                      final result = await dashboardActions.updateDriverStatus(newStatus);

                      result.when(
                        success: (success) {
                          // Status updated successfully - realtime providers will handle UI updates
                          ScaffoldMessenger.of(ref.context).showSnackBar(
                            SnackBar(
                              content: Text('Status updated to ${newStatus.displayName}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        error: (error) {
                          // Show user-friendly error message
                          ScaffoldMessenger.of(ref.context).showSnackBar(
                            SnackBar(
                              content: Text(error.userFriendlyMessage),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              loading: () => const Text('Loading...'),
              error: (error, stack) {
                final driverError = error is DriverException
                    ? error
                    : DriverException.fromException(error);
                return Text('Error: ${driverError.userFriendlyMessage}');
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final result = await dashboardActions.refreshDashboard();
                    result.when(
                      success: (_) => ScaffoldMessenger.of(ref.context).showSnackBar(
                        const SnackBar(content: Text('Dashboard refreshed')),
                      ),
                      error: (error) => ScaffoldMessenger.of(ref.context).showSnackBar(
                        SnackBar(content: Text('Refresh failed: ${error.userFriendlyMessage}')),
                      ),
                    );
                  },
                  child: const Text('Refresh Dashboard'),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blue, size: 16),
                      SizedBox(width: 4),
                      Text('Enhanced', style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced Usage Instructions with Optimizations:
///
/// 1. Import the necessary providers:
///    ```dart
///    import '../providers/driver_dashboard_provider.dart';
///    import '../../data/models/driver_error.dart';
///    ```
///
/// 2. Use individual providers for specific data:
///    ```dart
///    final activeOrdersCount = ref.watch(activeOrdersCountProvider);
///    final todaysEarnings = ref.watch(todaysEarningsProvider);
///    ```
///
/// 3. Use the REALTIME provider for comprehensive data with automatic updates:
///    ```dart
///    final dashboardDataAsync = ref.watch(realtimeDashboardDataProvider);
///    ```
///
/// 4. Handle loading and error states with enhanced error handling:
///    ```dart
///    dashboardDataAsync.when(
///      data: (data) => YourWidget(data),
///      loading: () => CircularProgressIndicator(),
///      error: (error, stack) {
///        final driverError = error is DriverException
///            ? error
///            : DriverException.fromException(error);
///        return ErrorWidget(driverError.userFriendlyMessage);
///      },
///    );
///    ```
///
/// 5. Use ENHANCED actions for user interactions with proper error handling:
///    ```dart
///    final dashboardActions = ref.read(realtimeDashboardActionsProvider);
///    final result = await dashboardActions.updateDriverStatus(DriverStatus.online);
///    result.when(
///      success: (success) => showSuccessMessage(),
///      error: (error) => showErrorMessage(error.userFriendlyMessage),
///    );
///    ```
///
/// 6. Implement refresh functionality with enhanced error handling:
///    ```dart
///    RefreshIndicator(
///      onRefresh: () async {
///        final result = await dashboardActions.refreshDashboard();
///        result.when(
///          success: (_) => {},
///          error: (error) => showError(error.userFriendlyMessage),
///        );
///      },
///      child: YourScrollableWidget(),
///    );
///    ```
///
/// 7. Benefits of the optimized providers:
///    - Real-time updates: Dashboard automatically refreshes when data changes
///    - Enhanced error handling: User-friendly error messages with retry options
///    - Cached driver ID: Eliminates redundant database lookups
///    - Performance optimized: Reduced rebuilds and better state management
