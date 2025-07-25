import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../drivers/data/models/driver_order.dart';
import '../../../../drivers/presentation/providers/driver_realtime_providers.dart';
import '../../../../drivers/data/models/delivery_confirmation.dart';
import '../../../../drivers/data/services/delivery_confirmation_service.dart';
import '../../../../drivers/presentation/widgets/driver_delivery_confirmation_dialog.dart';

import '../../../data/models/driver_order_state_machine.dart';

class DriverOrderDetailsScreen extends ConsumerWidget {
  final String orderId;

  const DriverOrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the realtime order details provider for proper driver order data
    final orderAsync = ref.watch(realtimeOrderDetailsProvider(orderId));

    // Comprehensive debug logging to track data flow
    debugPrint('🚗 [ORDER-DETAILS] ═══════════════════════════════════════');
    debugPrint('🚗 [ORDER-DETAILS] Building order details screen for order: $orderId');
    debugPrint('🚗 [ORDER-DETAILS] Provider state: ${orderAsync.runtimeType}');

    orderAsync.when(
      data: (order) {
        if (order != null) {
          debugPrint('🚗 [ORDER-DETAILS] ✅ Order data loaded successfully');
          debugPrint('🚗 [ORDER-DETAILS] Order Number: ${order.orderNumber}');
          debugPrint('🚗 [ORDER-DETAILS] Current Status: ${order.status.displayName} (${order.status.name})');
          debugPrint('🚗 [ORDER-DETAILS] Available Actions: ${order.availableActions.map((a) => a.displayName).join(', ')}');
          debugPrint('🚗 [ORDER-DETAILS] Driver ID: ${order.driverId}');
          debugPrint('🚗 [ORDER-DETAILS] Vendor: ${order.vendorName}');
          debugPrint('🚗 [ORDER-DETAILS] Customer: ${order.customerName}');
          debugPrint('🚗 [ORDER-DETAILS] Total Earnings: RM ${order.orderEarnings.totalEarnings.toStringAsFixed(2)}');
          debugPrint('🚗 [ORDER-DETAILS] Pickup Address: ${order.deliveryDetails.pickupAddress}');
          debugPrint('🚗 [ORDER-DETAILS] Delivery Address: ${order.deliveryDetails.deliveryAddress}');
          debugPrint('🚗 [ORDER-DETAILS] Special Instructions: ${order.deliveryDetails.specialInstructions ?? 'None'}');
          debugPrint('🚗 [ORDER-DETAILS] Created At: ${order.createdAt}');
          debugPrint('🚗 [ORDER-DETAILS] Updated At: ${order.updatedAt}');
        } else {
          debugPrint('🚗 [ORDER-DETAILS] ❌ Order data is null');
        }
      },
      loading: () {
        debugPrint('🚗 [ORDER-DETAILS] ⏳ Loading order data...');
      },
      error: (error, stack) {
        debugPrint('🚗 [ORDER-DETAILS] ❌ Error loading order data: $error');
        debugPrint('🚗 [ORDER-DETAILS] Stack trace: $stack');
      },
    );
    debugPrint('🚗 [ORDER-DETAILS] ═══════════════════════════════════════');

    return Scaffold(
      appBar: AppBar(
        title: orderAsync.when(
          data: (order) => Text(order != null ? 'Order #${order.orderNumber}' : 'Order Details'),
          loading: () => const Text('Order Details'),
          error: (_, _) => const Text('Order Details'),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              debugPrint('🚗 [ORDER-DETAILS] ═══ REFRESH TRIGGERED ═══');
              debugPrint('🚗 [ORDER-DETAILS] Manually refreshing order details for: $orderId');
              debugPrint('🚗 [ORDER-DETAILS] Invalidating realtimeOrderDetailsProvider...');
              ref.invalidate(realtimeOrderDetailsProvider(orderId));
              debugPrint('🚗 [ORDER-DETAILS] Provider invalidated, rebuild should trigger');
              debugPrint('🚗 [ORDER-DETAILS] ═══════════════════════════');
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) => order == null
            ? _buildOrderNotFound(context)
            : RefreshIndicator(
                onRefresh: () async {
                  debugPrint('🚗 [ORDER-DETAILS] ═══ PULL-TO-REFRESH ═══');
                  debugPrint('🚗 [ORDER-DETAILS] Pull-to-refresh triggered for order: $orderId');
                  debugPrint('🚗 [ORDER-DETAILS] Invalidating realtimeOrderDetailsProvider...');
                  ref.invalidate(realtimeOrderDetailsProvider(orderId));
                  debugPrint('🚗 [ORDER-DETAILS] Provider invalidated, waiting for rebuild...');
                  debugPrint('🚗 [ORDER-DETAILS] ═══════════════════════════');
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Status Header
                      _buildStatusHeader(context, order),

                      const SizedBox(height: 24),

                      // Pickup Information
                      _buildPickupInfo(context, order),

                      const SizedBox(height: 24),

                      // Delivery Information
                      _buildDeliveryInfo(context, order),

                      const SizedBox(height: 24),

                      // Order Summary
                      _buildOrderSummary(context, order),

                      const SizedBox(height: 24),

                      // Special Instructions
                      if (order.deliveryDetails.specialInstructions != null)
                        _buildSpecialInstructions(context, order),

                      const SizedBox(height: 24),

                      // Driver Actions
                      _buildDriverActions(context, ref, order),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
        loading: () => const LoadingWidget(message: 'Loading order details...'),
        error: (error, stack) {
          debugPrint('🚗 [ORDER-DETAILS] Error loading order details: $error');

          return CustomErrorWidget(
            message: 'Failed to load order details: ${error.toString()}',
            onRetry: () {
              debugPrint('🚗 [ORDER-DETAILS] Retrying order details load for: $orderId');
              ref.invalidate(realtimeOrderDetailsProvider(orderId));
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderNotFound(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Order not found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, DriverOrder order) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(order.status);

    debugPrint('🚗 [ORDER-DETAILS] Building status header - Order: ${order.orderNumber}, Status: ${order.status.displayName}');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'RM ${order.orderEarnings.totalEarnings.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Order #${order.orderNumber}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${_formatDateTime(order.createdAt)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (order.requestedDeliveryTime != null) ...[
              const SizedBox(height: 4),
              Text(
                'Requested Delivery: ${_formatDateTime(order.requestedDeliveryTime!)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPickupInfo(BuildContext context, DriverOrder order) {
    final theme = Theme.of(context);

    debugPrint('🚗 [ORDER-DETAILS] Building pickup info for vendor: ${order.vendorName}');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Pickup Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow(context, 'Vendor', order.vendorName),
            _buildDetailRow(context, 'Address', order.deliveryDetails.pickupAddress),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openMaps(context, order.deliveryDetails.pickupAddress),
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callVendor(context),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Vendor'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo(BuildContext context, DriverOrder order) {
    final theme = Theme.of(context);

    debugPrint('🚗 [ORDER-DETAILS] Building delivery info for customer: ${order.customerName}');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Delivery Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow(context, 'Customer', order.customerName),
            if (order.customerPhone != null)
              _buildDetailRow(context, 'Phone', order.customerPhone!),
            _buildDetailRow(context, 'Address', order.deliveryAddress),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openMaps(context, order.deliveryAddress),
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: order.customerPhone != null ? () => _callCustomer(context, order.customerPhone!) : null,
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Customer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, DriverOrder order) {
    final theme = Theme.of(context);

    debugPrint('🚗 [ORDER-DETAILS] Building order summary - Items: ${order.orderItemsCount}, Total: RM ${order.orderTotal.toStringAsFixed(2)}');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow(context, 'Order Total', 'RM ${order.orderTotal.toStringAsFixed(2)}'),
            _buildDetailRow(context, 'Driver Earnings', 'RM ${order.orderEarnings.totalEarnings.toStringAsFixed(2)}'),
            
            const Divider(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Earnings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'RM ${order.deliveryFee.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialInstructions(BuildContext context, DriverOrder order) {
    final theme = Theme.of(context);

    debugPrint('🚗 [ORDER-DETAILS] Building special instructions: ${order.deliveryDetails.specialInstructions}');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Special Instructions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Text(
                order.deliveryDetails.specialInstructions!,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverActions(BuildContext context, WidgetRef ref, DriverOrder order) {
    final theme = Theme.of(context);
    final availableActions = order.availableActions;

    debugPrint('🚗 [ORDER-DETAILS] Building driver actions for status: ${order.status.displayName}');
    debugPrint('🚗 [ORDER-DETAILS] Available actions: ${availableActions.map((a) => a.displayName).join(', ')}');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic action buttons based on current status
            if (availableActions.isNotEmpty) ...[
              ...availableActions.map((action) => _buildActionButton(context, ref, order, action)),
              const SizedBox(height: 16),

              // Status-specific instructions
              _buildStatusInstructions(context, order),
            ] else ...[
              // No actions available (terminal status)
              _buildNoActionsMessage(context, order),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref, DriverOrder order, DriverOrderAction action) {
    debugPrint('🚗 [ORDER-DETAILS] Building action button: ${action.displayName}');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _handleDriverAction(context, ref, order, action),
          icon: _getActionIcon(action),
          label: Text(action.displayName),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getActionColor(action),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusInstructions(BuildContext context, DriverOrder order) {
    final theme = Theme.of(context);
    final instructions = DriverOrderStateMachine.getDriverInstructions(order.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              instructions,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoActionsMessage(BuildContext context, DriverOrder order) {
    final theme = Theme.of(context);
    String message;

    switch (order.status) {
      case DriverOrderStatus.delivered:
        message = 'Order completed successfully. You can now accept new orders.';
        break;
      case DriverOrderStatus.cancelled:
        message = 'Order was cancelled. You can now accept new orders.';
        break;
      case DriverOrderStatus.failed:
        message = 'Order delivery failed. Please contact support if needed.';
        break;
      default:
        message = 'No actions available for this order status.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.grey[600],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _handleDriverAction(BuildContext context, WidgetRef ref, DriverOrder order, DriverOrderAction action) async {
    debugPrint('🎯 [ORDER-DETAILS-ACTION] ═══ DRIVER ACTION INITIATED ═══');
    debugPrint('🎯 [ORDER-DETAILS-ACTION] Action: ${action.displayName}');
    debugPrint('🎯 [ORDER-DETAILS-ACTION] Order ID: ${order.id}');
    debugPrint('🎯 [ORDER-DETAILS-ACTION] Order Number: ${order.orderNumber}');
    debugPrint('🎯 [ORDER-DETAILS-ACTION] Current Status: ${order.status.displayName}');
    debugPrint('🎯 [ORDER-DETAILS-ACTION] Driver ID: ${order.assignedDriverId}');
    debugPrint('🎯 [ORDER-DETAILS-ACTION] Action Source: Order Details Screen');

    try {
      switch (action) {
        case DriverOrderAction.navigateToVendor:
          debugPrint('🧭 [NAVIGATE-TO-VENDOR] ═══ STARTING NAVIGATION TO RESTAURANT ═══');
          debugPrint('🧭 [NAVIGATE-TO-VENDOR] Order: ${order.orderNumber} (${order.id})');
          debugPrint('🧭 [NAVIGATE-TO-VENDOR] Current Status: ${order.status.displayName}');
          debugPrint('🧭 [NAVIGATE-TO-VENDOR] Target Address: ${order.deliveryDetails.pickupAddress}');
          debugPrint('🧭 [NAVIGATE-TO-VENDOR] Step 1: Updating status to on_route_to_vendor...');

          // CRITICAL FIX: Update status first, then open navigation
          // This matches the behavior of order cards for consistency
          await _updateOrderStatus(context, ref, order, DriverOrderStatus.onRouteToVendor);
          debugPrint('✅ [NAVIGATE-TO-VENDOR] Status update completed');

          debugPrint('🧭 [NAVIGATE-TO-VENDOR] Step 2: Opening maps application...');
          await _openMaps(context, order.deliveryDetails.pickupAddress);
          debugPrint('✅ [NAVIGATE-TO-VENDOR] Navigation to restaurant completed successfully');
          break;
        case DriverOrderAction.arrivedAtVendor:
          await _updateOrderStatus(context, ref, order, DriverOrderStatus.arrivedAtVendor);
          break;
        case DriverOrderAction.confirmPickup:
          await _confirmPickup(context, ref, order);
          break;
        case DriverOrderAction.navigateToCustomer:
          debugPrint('🚚 [NAVIGATE-TO-CUSTOMER] ═══ STARTING NAVIGATION TO CUSTOMER ═══');
          debugPrint('🚚 [NAVIGATE-TO-CUSTOMER] Order: ${order.orderNumber} (${order.id})');
          debugPrint('🚚 [NAVIGATE-TO-CUSTOMER] Current Status: ${order.status.displayName}');
          debugPrint('🚚 [NAVIGATE-TO-CUSTOMER] Target Address: ${order.deliveryDetails.deliveryAddress}');
          debugPrint('🚚 [NAVIGATE-TO-CUSTOMER] Step 1: Updating status to on_route_to_customer...');

          // CONSISTENCY FIX: Update status first, then open navigation
          // This matches the behavior of order cards and navigateToVendor
          await _updateOrderStatus(context, ref, order, DriverOrderStatus.onRouteToCustomer);
          debugPrint('✅ [NAVIGATE-TO-CUSTOMER] Status update completed');

          debugPrint('🚚 [NAVIGATE-TO-CUSTOMER] Step 2: Opening maps application...');
          await _openMaps(context, order.deliveryDetails.deliveryAddress);
          debugPrint('✅ [NAVIGATE-TO-CUSTOMER] Navigation to customer completed successfully');
          break;
        case DriverOrderAction.arrivedAtCustomer:
          await _updateOrderStatus(context, ref, order, DriverOrderStatus.arrivedAtCustomer);
          break;
        case DriverOrderAction.confirmDeliveryWithPhoto:
          await _confirmDeliveryWithPhoto(context, ref, order);
          break;
        case DriverOrderAction.cancel:
          await _cancelOrder(context, ref, order);
          break;
        case DriverOrderAction.reportIssue:
          await _reportIssue(context, order);
          break;
        default:
          debugPrint('⚠️ [ORDER-DETAILS-ACTION] Unhandled action: ${action.displayName}');
          debugPrint('⚠️ [ORDER-DETAILS-ACTION] This action is not implemented in Order Details Screen');
      }

      debugPrint('✅ [ORDER-DETAILS-ACTION] Driver action ${action.displayName} completed successfully');
      debugPrint('✅ [ORDER-DETAILS-ACTION] ═══ ACTION COMPLETED ═══');

    } catch (e) {
      debugPrint('❌ [ORDER-DETAILS-ACTION] ═══ ACTION FAILED ═══');
      debugPrint('❌ [ORDER-DETAILS-ACTION] Action: ${action.displayName}');
      debugPrint('❌ [ORDER-DETAILS-ACTION] Order: ${order.orderNumber}');
      debugPrint('❌ [ORDER-DETAILS-ACTION] Error: $e');
      debugPrint('❌ [ORDER-DETAILS-ACTION] Stack trace: ${StackTrace.current}');

      if (context.mounted) {
        // Provide specific error messages for navigation actions
        String errorMessage;
        if (action == DriverOrderAction.navigateToVendor) {
          errorMessage = 'Failed to start navigation to restaurant. Please try again.';
          debugPrint('❌ [ORDER-DETAILS-ACTION] Navigation to vendor failed - status update or maps error');
        } else if (action == DriverOrderAction.navigateToCustomer) {
          errorMessage = 'Failed to start navigation to customer. Please try again.';
          debugPrint('❌ [ORDER-DETAILS-ACTION] Navigation to customer failed - status update or maps error');
        } else {
          errorMessage = 'Error performing ${action.displayName}: ${e.toString()}';
          debugPrint('❌ [ORDER-DETAILS-ACTION] General action error: ${action.displayName}');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Icon _getActionIcon(DriverOrderAction action) {
    switch (action) {
      case DriverOrderAction.navigateToVendor:
      case DriverOrderAction.navigateToCustomer:
        return const Icon(Icons.navigation);
      case DriverOrderAction.arrivedAtVendor:
      case DriverOrderAction.arrivedAtCustomer:
        return const Icon(Icons.location_on);
      case DriverOrderAction.confirmPickup:
        return const Icon(Icons.shopping_bag);
      case DriverOrderAction.confirmDeliveryWithPhoto:
        return const Icon(Icons.camera_alt);
      case DriverOrderAction.cancel:
        return const Icon(Icons.cancel);
      case DriverOrderAction.reportIssue:
        return const Icon(Icons.report_problem);
      default:
        return const Icon(Icons.touch_app);
    }
  }

  Color _getActionColor(DriverOrderAction action) {
    switch (action) {
      case DriverOrderAction.navigateToVendor:
      case DriverOrderAction.navigateToCustomer:
        return Colors.blue;
      case DriverOrderAction.arrivedAtVendor:
      case DriverOrderAction.arrivedAtCustomer:
        return Colors.orange;
      case DriverOrderAction.confirmPickup:
        return Colors.green;
      case DriverOrderAction.confirmDeliveryWithPhoto:
        return Colors.purple;
      case DriverOrderAction.cancel:
        return Colors.red;
      case DriverOrderAction.reportIssue:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateOrderStatus(BuildContext context, WidgetRef ref, DriverOrder order, DriverOrderStatus newStatus) async {
    debugPrint('🔄 [ORDER-DETAILS-STATUS] ═══ STATUS UPDATE INITIATED ═══');
    debugPrint('🔄 [ORDER-DETAILS-STATUS] Order ID: ${order.id}');
    debugPrint('🔄 [ORDER-DETAILS-STATUS] Order Number: ${order.orderNumber}');
    debugPrint('🔄 [ORDER-DETAILS-STATUS] Driver ID: ${order.assignedDriverId}');
    debugPrint('🔄 [ORDER-DETAILS-STATUS] Current Status: ${order.status.displayName} (${order.status.name})');
    debugPrint('🔄 [ORDER-DETAILS-STATUS] Target Status: ${newStatus.displayName} (${newStatus.name})');
    debugPrint('🔄 [ORDER-DETAILS-STATUS] Update Source: Order Details Screen');
    debugPrint('🔄 [ORDER-DETAILS-STATUS] Calling realtimeDriverOrderActionsProvider.updateOrderStatus...');

    try {
      // Use the enhanced driver workflow provider to update status
      final result = await ref.read(realtimeDriverOrderActionsProvider).updateOrderStatus(
        order.id,
        newStatus,
      );

      debugPrint('🚗 [ORDER-DETAILS] Status update result received');

      result.when(
        success: (success) {
          debugPrint('✅ [ORDER-DETAILS-STATUS] Status update successful');
          debugPrint('✅ [ORDER-DETAILS-STATUS] Order ${order.orderNumber} status changed to ${newStatus.displayName}');
          debugPrint('✅ [ORDER-DETAILS-STATUS] Provider auto-invalidation should trigger UI refresh');
          debugPrint('✅ [ORDER-DETAILS-STATUS] Real-time updates should propagate to all screens');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Status updated to ${newStatus.displayName}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        error: (error) {
          debugPrint('❌ [ORDER-DETAILS-STATUS] Status update failed');
          debugPrint('❌ [ORDER-DETAILS-STATUS] Error message: ${error.message}');
          debugPrint('❌ [ORDER-DETAILS-STATUS] Error type: ${error.type}');
          debugPrint('❌ [ORDER-DETAILS-STATUS] Order: ${order.orderNumber}');
          debugPrint('❌ [ORDER-DETAILS-STATUS] Attempted transition: ${order.status.displayName} → ${newStatus.displayName}');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update status: ${error.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('🚗 [ORDER-DETAILS] ❌ Exception during status update: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: ${e.toString()}')),
        );
      }
    }

    debugPrint('🚗 [ORDER-DETAILS] ═══════════════════════════');
  }

  Future<void> _confirmPickup(BuildContext context, WidgetRef ref, DriverOrder order) async {
    debugPrint('🚗 [ORDER-DETAILS] Confirming pickup for order: ${order.orderNumber}');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Pickup'),
        content: const Text('Have you received the complete order from the restaurant?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm Pickup'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateOrderStatus(context, ref, order, DriverOrderStatus.pickedUp);
    }
  }

  Future<void> _confirmDeliveryWithPhoto(BuildContext context, WidgetRef ref, DriverOrder order) async {
    debugPrint('🚗 [ORDER-DETAILS] Confirming delivery with photo for order: ${order.orderNumber}');

    // Show mandatory delivery confirmation dialog with photo capture
    // This dialog cannot be dismissed without completing all requirements
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // Cannot be dismissed by tapping outside
      builder: (context) => DriverDeliveryConfirmationDialog(
        order: order,
        onConfirmed: (confirmation) async {
          await _processDeliveryConfirmation(context, ref, confirmation);
        },
        onCancelled: () {
          // User cancelled delivery confirmation - no action taken
          debugPrint('🚗 [ORDER-DETAILS] Delivery confirmation cancelled by user');
        },
      ),
    );
  }

  /// Process the delivery confirmation after photo capture and GPS verification
  Future<void> _processDeliveryConfirmation(
    BuildContext context,
    WidgetRef ref,
    DeliveryConfirmation confirmation
  ) async {
    try {
      debugPrint('🚗 [ORDER-DETAILS] Processing delivery confirmation for order ${confirmation.orderId}');
      debugPrint('🚗 [ORDER-DETAILS] Photo URL: ${confirmation.photoUrl}');
      debugPrint('🚗 [ORDER-DETAILS] GPS Location: ${confirmation.location.latitude}, ${confirmation.location.longitude}');

      // Submit delivery confirmation through the service
      // NOTE: This service handles both delivery proof creation AND order status update
      // The database trigger automatically updates order status when proof is created
      final deliveryService = ref.read(deliveryConfirmationServiceProvider);
      final result = await deliveryService.submitDeliveryConfirmation(confirmation);

      if (result.isSuccess) {
        debugPrint('🚗 [ORDER-DETAILS] Delivery confirmation submitted successfully');
        debugPrint('🔧 [ORDER-DETAILS] Database trigger has automatically updated order status to delivered');

        // Refresh order data to reflect the updated status from database trigger
        ref.invalidate(realtimeOrderDetailsProvider(confirmation.orderId));
        debugPrint('🔄 [ORDER-DETAILS] Order data refreshed to show updated status');

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery completed successfully with photo proof!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Delivery confirmation failed: ${result.errorMessage}');
      }
    } catch (e) {
      debugPrint('🚗 [ORDER-DETAILS] Error processing delivery confirmation: $e');

      // Enhanced error handling for duplicate delivery scenarios
      String userFriendlyMessage;
      Color snackBarColor = Colors.red;

      if (e.toString().contains('already been completed') ||
          e.toString().contains('duplicate key value') ||
          e.toString().contains('unique_order_proof')) {
        debugPrint('🔍 [ORDER-DETAILS] Detected duplicate delivery completion attempt');
        userFriendlyMessage = 'This delivery has already been completed. Please refresh to see the updated status.';
        snackBarColor = Colors.orange;

        // Refresh the order data to show current status
        try {
          ref.invalidate(realtimeOrderDetailsProvider(confirmation.orderId));
          debugPrint('🔄 [ORDER-DETAILS] Order data refreshed after duplicate detection');
        } catch (refreshError) {
          debugPrint('⚠️ [ORDER-DETAILS] Failed to refresh order data: $refreshError');
        }
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        debugPrint('🌐 [ORDER-DETAILS] Network error detected');
        userFriendlyMessage = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('permission') || e.toString().contains('unauthorized')) {
        debugPrint('🔒 [ORDER-DETAILS] Permission error detected');
        userFriendlyMessage = 'You don\'t have permission to complete this delivery. Please contact support.';
      } else {
        debugPrint('❌ [ORDER-DETAILS] Unknown error type');
        userFriendlyMessage = 'Failed to complete delivery. Please try again or contact support.';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyMessage),
            backgroundColor: snackBarColor,
            duration: const Duration(seconds: 5),
            action: snackBarColor == Colors.orange ? SnackBarAction(
              label: 'Refresh',
              textColor: Colors.white,
              onPressed: () {
                ref.invalidate(realtimeOrderDetailsProvider(confirmation.orderId));
              },
            ) : null,
          ),
        );
      }
    }
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref, DriverOrder order) async {
    debugPrint('🚗 [ORDER-DETAILS] Cancelling order: ${order.orderNumber}');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateOrderStatus(context, ref, order, DriverOrderStatus.cancelled);
    }
  }

  Future<void> _reportIssue(BuildContext context, DriverOrder order) async {
    debugPrint('🚗 [ORDER-DETAILS] Reporting issue for order: ${order.orderNumber}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Issue reporting feature coming soon')),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(DriverOrderStatus status) {
    debugPrint('🚗 [ORDER-DETAILS] Getting status color for: ${status.displayName}');

    switch (status) {
      case DriverOrderStatus.assigned:
        return Colors.orange;
      case DriverOrderStatus.onRouteToVendor:
        return Colors.orange;
      case DriverOrderStatus.arrivedAtVendor:
        return Colors.blue;
      case DriverOrderStatus.pickedUp:
        return Colors.purple;
      case DriverOrderStatus.onRouteToCustomer:
        return Colors.indigo;
      case DriverOrderStatus.arrivedAtCustomer:
        return Colors.indigo;
      case DriverOrderStatus.delivered:
        return Colors.green;
      case DriverOrderStatus.cancelled:
        return Colors.red;
      case DriverOrderStatus.failed:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  Future<void> _openMaps(BuildContext context, String address) async {
    debugPrint('🗺️ [ORDER-DETAILS-MAPS] Opening navigation to address: $address');

    final encodedAddress = Uri.encodeComponent(address);
    final url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';

    debugPrint('🗺️ [ORDER-DETAILS-MAPS] Generated maps URL: $url');

    try {
      debugPrint('🗺️ [ORDER-DETAILS-MAPS] Checking if URL can be launched...');
      if (await canLaunchUrl(Uri.parse(url))) {
        debugPrint('🗺️ [ORDER-DETAILS-MAPS] Launching external maps application...');
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        debugPrint('✅ [ORDER-DETAILS-MAPS] Maps application launched successfully');
      } else {
        debugPrint('❌ [ORDER-DETAILS-MAPS] Cannot launch maps URL');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps application'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [ORDER-DETAILS-MAPS] Error opening maps: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening maps: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _callCustomer(BuildContext context, String phoneNumber) async {
    final url = 'tel:$phoneNumber';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make phone call')),
        );
      }
    } catch (e) {
      debugPrint('Error making phone call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error making phone call')),
      );
    }
  }

  void _callVendor(BuildContext context) {
    // TODO: Implement vendor phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vendor contact information not available')),
    );
  }

  // TODO: Restore unused methods when DriverOrder is implemented
  // void _startDelivery(BuildContext context, dynamic order) { // was: DriverOrder
  //   debugPrint('🚗 Starting delivery for order: ${order.id}');
  //   // Navigate to delivery workflow screen
  //   context.push('/driver/delivery/${order.id}');
  // }

  // void _continueDelivery(BuildContext context, dynamic order) { // was: DriverOrder
  //   debugPrint('🚗 Continuing delivery for order: ${order.id}');
  //   // Navigate to delivery workflow screen
  //   context.push('/driver/delivery/${order.id}');
  // }

  // void _updateOrderStatus(BuildContext context, WidgetRef ref, dynamic order) { // was: DriverOrder
  //   debugPrint('🚗 Updating status for order: ${order.id}');
  //   _showStatusUpdateDialog(context, ref, order);
  // }

  // void _reportIssue(BuildContext context, dynamic order) { // was: DriverOrder
  //   debugPrint('🚗 Reporting issue for order: ${order.id}');
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Issue reporting - Coming soon!')),
  //   );
  // }

  // TODO: Restore when DriverOrder is implemented - method removed to fix analyzer warnings
  // Future<void> _acceptOrder(BuildContext context, WidgetRef ref, dynamic order) async { ... }

  // TODO: Restore when DriverOrder is implemented - method removed to fix analyzer warnings


  // TODO: Restore unused method _showStatusUpdateDialog when DriverOrder is implemented
  // void _showStatusUpdateDialog(BuildContext context, WidgetRef ref, dynamic order) { // was: DriverOrder
  //   showDialog(
  //     context: context,
  //     builder: (dialogContext) => AlertDialog(
  //       title: const Text('Update Order Status'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           // TODO: Restore when DriverOrderStatus is implemented
  //           // if (order.status == DriverOrderStatus.assigned) ...[
  //           if (order.status == 'assigned') ...[
  //             ListTile(
  //               leading: const Icon(Icons.restaurant),
  //               title: const Text('Picked up from restaurant'),
  //               onTap: () {
  //                 Navigator.of(dialogContext).pop();
  //                 // TODO: Restore when DriverOrderStatus is implemented
  //                 // _updateStatus(context, ref, order.id, DriverOrderStatus.pickedUp);
  //                 _updateStatus(context, ref, order.id, 'picked_up');
  //               },
  //             ),
  //           ],
  //           // TODO: Restore when DriverOrderStatus is implemented
  //           // if (order.status == DriverOrderStatus.pickedUp) ...[
  //           if (order.status == 'picked_up') ...[
  //             ListTile(
  //               leading: const Icon(Icons.local_shipping),
  //               title: const Text('En route to customer'),
  //               onTap: () {
  //                 Navigator.of(dialogContext).pop();
  //                 // TODO: Restore when DriverOrderStatus is implemented
  //                 // _updateStatus(context, ref, order.id, DriverOrderStatus.onRouteToCustomer);
  //                 _updateStatus(context, ref, order.id, 'on_route_to_customer');
  //               },
  //             ),
  //           ],
  //           // TODO: Restore when DriverOrderStatus is implemented
  //           // if (order.status == DriverOrderStatus.onRouteToCustomer) ...[
  //           if (order.status == 'on_route_to_customer') ...[
  //             ListTile(
  //               leading: const Icon(Icons.check_circle),
  //               title: const Text('Delivered'),
  //               onTap: () {
  //                 Navigator.of(dialogContext).pop();
  //                 // TODO: Restore when DriverOrderStatus is implemented
  //                 // _updateStatus(context, ref, order.id, DriverOrderStatus.delivered);
  //                 _updateStatus(context, ref, order.id, 'delivered');
  //               },
  //             ),
  //           ],
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(dialogContext).pop(),
  //           child: const Text('Cancel'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // TODO: Restore unused method _updateStatus when DriverOrderStatus is implemented
  // Future<void> _updateStatus(BuildContext context, WidgetRef ref, String orderId, dynamic status) async { // was: DriverOrderStatus
  //   try {
  //     // TODO: Restore when realtimeDriverOrderActionsProvider is implemented
  //     // final actions = ref.read(realtimeDriverOrderActionsProvider);
  //     // final result = await actions.updateOrderStatus(orderId, status);
  //     final result = null; // Placeholder

  //     result.when(
  //       success: (success) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text('Order status updated to ${status.displayName}'),
  //             backgroundColor: Colors.green,
  //           ),
  //         );
  //         // No need to manually reload - realtime subscriptions will handle it
  //       },
  //       error: (error) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(error.userFriendlyMessage),
  //             backgroundColor: Colors.red,
  //           ),
  //         );
  //       },
  //     );
  //   } catch (e) {
  //     debugPrint('Error updating order status: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error updating status: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }
}
