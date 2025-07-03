import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/loading_widget.dart';
// TODO: Restore when driver widgets and providers are implemented
// import '../widgets/driver_order_card.dart';
// import '../providers/driver_realtime_providers.dart';
// import '../providers/driver_profile_provider.dart';
// import '../../data/models/driver_order.dart';
// import '../../../vendors/data/models/driver.dart';

/// Driver orders screen with tabs for different order states
class DriverOrdersScreen extends ConsumerWidget {
  const DriverOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                debugPrint('🚗 Refreshing driver orders');
                // TODO: Restore when driver providers are implemented
                // Invalidate realtime providers to force refresh
                // ref.invalidate(statusAwareAvailableOrdersProvider);
                // ref.invalidate(realtimeDriverOrdersProvider);
                // ref.invalidate(driverProfileStreamProvider);
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Available'),
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Container(
              key: const ValueKey('available_orders_tab'),
              child: _buildAvailableOrdersTab(context, ref),
            ),
            Container(
              key: const ValueKey('active_orders_tab'),
              child: _buildActiveOrdersTab(context, ref),
            ),
            Container(
              key: const ValueKey('history_orders_tab'),
              child: _buildHistoryTab(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableOrdersTab(BuildContext context, WidgetRef ref) {
    // TODO: Restore when driver providers are implemented
    // final availableOrders = ref.watch(statusAwareAvailableOrdersProvider);
    // final activeOrders = ref.watch(realtimeActiveDriverOrdersProvider);
    // final driverProfileAsync = ref.watch(driverProfileStreamProvider);
    final availableOrders = <dynamic>[];
    final activeOrders = <dynamic>[];
    final driverProfileAsync = null;

    return driverProfileAsync.when(
      data: (driver) {
        if (driver == null) {
          return const Center(
            child: Text(
              'Driver profile not found',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        // TODO: Restore when DriverStatus is implemented
        // Show different UI based on driver status
        // if (driver.status != DriverStatus.online) {
        // TODO: Restore when DriverStatus is implemented
        // if (false) { // TODO: Replace with proper driver status check
        //   return Center(
        //     child: Column(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: [
        //         Icon(
        //           Icons.offline_bolt,
        //           size: 64,
        //           color: Colors.grey[400],
        //         ),
        //         const SizedBox(height: 16),
        //         Text(
        //           'You are ${driver.status.displayName}',
        //           style: const TextStyle(
        //             fontSize: 18,
        //             fontWeight: FontWeight.bold,
        //           ),
        //         ),
        //         const SizedBox(height: 8),
        //         const Text(
        //           'Go online to see available orders',
        //           style: TextStyle(
        //             fontSize: 14,
        //             color: Colors.grey,
        //           ),
        //         ),
        //       ],
        //     ),
        //   );
        // }

        // Driver is online, show available orders
        debugPrint('🚗 DriverOrdersScreen: Driver is online, showing ${availableOrders.length} available orders');
        debugPrint('🚗 DriverOrdersScreen: Active orders count - ${activeOrders.length}');

        // Filter out orders that are already assigned to this driver
        final filteredOrders = availableOrders.where((order) {
          final isAlreadyAssigned = activeOrders.any((activeOrder) => activeOrder.id == order.id);
          if (isAlreadyAssigned) {
            debugPrint('🚗 DriverOrdersScreen: Filtering out order ${order.orderNumber} - already assigned');
          }
          return !isAlreadyAssigned;
        }).toList();

        debugPrint('🚗 DriverOrdersScreen: Filtered available orders - ${filteredOrders.length} orders');

        return _buildOrdersList(
          context,
          ref,
          filteredOrders,
          isAvailable: true,
        );
      },
      loading: () {
        debugPrint('🚗 DriverOrdersScreen: Loading driver profile...');
        return const Center(child: LoadingWidget());
      },
      error: (error, stack) {
        debugPrint('🚗 DriverOrdersScreen: Error loading driver profile: $error');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load driver profile'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  debugPrint('🚗 DriverOrdersScreen: Retrying driver profile...');
                  // TODO: Restore when driverProfileStreamProvider is implemented
                  // ref.invalidate(driverProfileStreamProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveOrdersTab(BuildContext context, WidgetRef ref) {
    // TODO: Restore when realtimeActiveDriverOrdersProvider is implemented
    // final activeOrders = ref.watch(realtimeActiveDriverOrdersProvider);
    final activeOrders = <dynamic>[];
    return _buildOrdersList(context, ref, activeOrders, isActive: true);
  }

  Widget _buildHistoryTab(BuildContext context, WidgetRef ref) {
    // TODO: Restore when realtimeCompletedDriverOrdersProvider is implemented
    // final completedOrdersAsync = ref.watch(realtimeCompletedDriverOrdersProvider);
    final completedOrdersAsync = <dynamic>[];

    // TODO: Restore when realtimeCompletedDriverOrdersProvider is implemented
    return _buildOrdersList(context, ref, completedOrdersAsync, isHistory: true);
    // return completedOrdersAsync.when(
    //   data: (completedOrders) => _buildOrdersList(context, ref, completedOrders, isHistory: true),
    //   loading: () => const Center(child: CircularProgressIndicator()),
    //   error: (error, stack) {
    //     debugPrint('🚗 DriverOrdersScreen: History tab error: $error');
    //     return Center(
    //       child: Column(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: [
    //           const Icon(Icons.error_outline, size: 64, color: Colors.red),
    //           const SizedBox(height: 16),
    //           Text('Error loading order history: $error'),
    //           const SizedBox(height: 16),
    //           ElevatedButton(
    //             onPressed: () => ref.invalidate(realtimeCompletedDriverOrdersProvider),
    //             child: const Text('Retry'),
    //           ),
    //         ],
    //       ),
    //     );
    //   },
    // );
  }

  // TODO: Restore when DriverOrder is implemented
  Widget _buildOrdersList(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> orders, {
    bool isAvailable = false,
    bool isActive = false,
    bool isHistory = false,
  }) {
    if (orders.isEmpty) {
      return _buildEmptyState(context, isAvailable, isActive, isHistory);
    }

    return RefreshIndicator(
      onRefresh: () async {
        debugPrint('🚗 Refreshing orders list');
        // TODO: Restore when driver providers are implemented
        // if (isAvailable) {
        //   ref.invalidate(statusAwareAvailableOrdersProvider);
        //   ref.invalidate(driverProfileStreamProvider);
        // } else {
        //   ref.invalidate(realtimeDriverOrdersProvider);
        // }
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = orders[index];

          // TODO: Restore when DriverOrderCard is implemented
          // return DriverOrderCard(
          return Card( // Placeholder card
            key: ValueKey('order_${order.id}'),
            child: ListTile(
              title: Text('Order #${order.id}'),
              subtitle: Text('Driver order details coming soon'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAvailable) ...[
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _acceptOrder(context, ref, order.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectOrder(context, ref, order.id),
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.info),
                    onPressed: () => _viewOrderDetails(context, order.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isAvailable, bool isActive, bool isHistory) {
    String title;
    String subtitle;
    IconData icon;

    if (isAvailable) {
      title = 'No Available Orders';
      subtitle = 'New delivery requests will appear here';
      icon = Icons.assignment_outlined;
    } else if (isActive) {
      title = 'No Active Deliveries';
      subtitle = 'Your ongoing deliveries will appear here';
      icon = Icons.local_shipping_outlined;
    } else {
      title = 'No Delivery History';
      subtitle = 'Your completed deliveries will appear here';
      icon = Icons.history;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  Future<void> _acceptOrder(BuildContext context, WidgetRef ref, String orderId) async {
    debugPrint('🚗 Accepting order: $orderId');
    // TODO: Restore when realtimeDriverOrderActionsProvider is implemented
    // final actions = ref.read(realtimeDriverOrderActionsProvider);
    // final result = await actions.acceptOrder(orderId);
    final result = null; // Placeholder

    result.when(
      success: (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      },
      error: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.userFriendlyMessage),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<void> _rejectOrder(BuildContext context, WidgetRef ref, String orderId) async {
    debugPrint('🚗 Rejecting order: $orderId');
    // TODO: Restore when realtimeDriverOrderActionsProvider is implemented
    // final actions = ref.read(realtimeDriverOrderActionsProvider);
    // final result = await actions.rejectOrder(orderId);
    final result = null; // Placeholder

    result.when(
      success: (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      },
      error: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.userFriendlyMessage),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  void _viewOrderDetails(BuildContext context, String orderId) {
    debugPrint('🚗 Viewing order details: $orderId');
    context.push('/driver/order/$orderId');
  }

  // TODO: Restore unused method _startDelivery when needed
  // void _startDelivery(BuildContext context, String orderId) {
  //   debugPrint('🚗 Starting delivery: $orderId');
  //   context.push('/driver/delivery/$orderId');
  // }

  // TODO: Restore unused method _viewReceipt when DriverOrder is implemented
  // void _viewReceipt(BuildContext context, dynamic order) {
  //   debugPrint('🚗 Viewing receipt for order: ${order.id}');
  //   _showReceiptDialog(context, order);
  // }



  // TODO: Restore unused method _showReceiptDialog when DriverOrder is implemented
  // void _showReceiptDialog(BuildContext context, dynamic order) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Row(
  //         children: [
  //           const Icon(Icons.receipt_long, color: Colors.green),
  //           const SizedBox(width: 8),
  //           Text('Order Receipt'),
  //         ],
  //       ),
  //       content: SingleChildScrollView(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             // Order Information
  //             _buildReceiptSection('Order Details', [
  //               _buildReceiptRow('Order Number', order.orderNumber),
  //               _buildReceiptRow('Status', order.status.displayName),
  //               _buildReceiptRow('Date', _formatDate(order.createdAt)),
  //               if (order.deliveredAt != null)
  //                 _buildReceiptRow('Delivered', _formatDate(order.deliveredAt!)),
  //             ]),
  //
  //             const SizedBox(height: 16),
  //
  //             // Vendor Information
  //             _buildReceiptSection('Pickup Details', [
  //               _buildReceiptRow('Vendor', order.vendorName),
  //               if (order.vendorAddress != null)
  //                 _buildReceiptRow('Address', order.vendorAddress!),
  //             ]),
  //
  //             const SizedBox(height: 16),
  //
  //             // Customer Information
  //             _buildReceiptSection('Delivery Details', [
  //               _buildReceiptRow('Customer', order.customerName),
  //               _buildReceiptRow('Address', order.deliveryAddress),
  //               if (order.customerPhone != null)
  //                 _buildReceiptRow('Phone', order.customerPhone!),
  //             ]),
  //
  //             const SizedBox(height: 16),
  //
  //             // Payment Information
  //             _buildReceiptSection('Payment Summary', [
  //               _buildReceiptRow('Order Total', 'RM ${order.totalAmount.toStringAsFixed(2)}'),
  //               _buildReceiptRow('Delivery Fee', 'RM ${order.deliveryFee.toStringAsFixed(2)}', isHighlighted: true),
  //             ]),
  //
  //             if (order.specialInstructions != null) ...[
  //               const SizedBox(height: 16),
  //               _buildReceiptSection('Special Instructions', [
  //                 Text(
  //                   order.specialInstructions!,
  //                   style: const TextStyle(fontStyle: FontStyle.italic),
  //                 ),
  //               ]),
  //             ],
  //           ],
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: const Text('Close'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // TODO: Restore unused helper methods when DriverOrder receipt functionality is implemented
  // Widget _buildReceiptSection(String title, List<Widget> children) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         title,
  //         style: const TextStyle(
  //           fontWeight: FontWeight.bold,
  //           fontSize: 16,
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       ...children,
  //     ],
  //   );
  // }

  // Widget _buildReceiptRow(String label, String value, {bool isHighlighted = false}) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 2),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Expanded(
  //           flex: 2,
  //           child: Text(
  //             label,
  //             style: TextStyle(
  //               color: Colors.grey[600],
  //               fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
  //             ),
  //           ),
  //         ),
  //         Expanded(
  //           flex: 1,
  //           child: Text(
  //             value,
  //             textAlign: TextAlign.right,
  //             style: TextStyle(
  //               fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
  //               color: isHighlighted ? Colors.green : null,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // String _formatDate(DateTime date) {
  //   return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  // }
}
