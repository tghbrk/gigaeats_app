import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../data/models/driver_order.dart';
import '../../data/models/driver_error.dart';

import '../providers/driver_realtime_providers.dart';

class DriverOrderDetailsScreen extends ConsumerWidget {
  final String orderId;

  const DriverOrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(realtimeOrderDetailsProvider(orderId));

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
            onPressed: () => ref.invalidate(realtimeOrderDetailsProvider(orderId)),
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
                  ref.invalidate(realtimeOrderDetailsProvider(orderId));
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
                      if (order.specialInstructions != null)
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
          final driverError = error is DriverException
              ? error
              : DriverException.fromException(error);

          return CustomErrorWidget(
            message: driverError.userFriendlyMessage,
            onRetry: () => ref.invalidate(realtimeOrderDetailsProvider(orderId)),
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
                  'RM ${order.deliveryFee.toStringAsFixed(2)}',
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
            if (order.estimatedDeliveryTime != null) ...[
              const SizedBox(height: 4),
              Text(
                'Estimated Delivery: ${_formatDateTime(order.estimatedDeliveryTime!)}',
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
            if (order.vendorAddress != null)
              _buildDetailRow(context, 'Address', order.vendorAddress!),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openMaps(context, order.vendorAddress ?? order.vendorName),
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
            
            _buildDetailRow(context, 'Order Total', 'RM ${order.totalAmount.toStringAsFixed(2)}'),
            _buildDetailRow(context, 'Delivery Fee', 'RM ${order.deliveryFee.toStringAsFixed(2)}'),
            
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
                order.specialInstructions!,
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

            // Available order actions (Accept/Reject)
            if (order.status == DriverOrderStatus.available) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptOrder(context, ref, order),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Accept Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectOrder(context, ref, order),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Additional info for available orders
              Container(
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
                        'Review the order details carefully before accepting. Once accepted, you\'ll be responsible for completing the delivery.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]

            // Assigned order actions
            else if (order.status == DriverOrderStatus.assigned) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startDelivery(context, order),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Delivery'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ]

            // Active delivery actions
            else if (order.status == DriverOrderStatus.pickedUp ||
                     order.status == DriverOrderStatus.onRouteToCustomer ||
                     order.status == DriverOrderStatus.arrivedAtCustomer) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _continueDelivery(context, order),
                  icon: const Icon(Icons.navigation),
                  label: const Text('Continue Delivery'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],

            // Common actions for non-available orders
            if (order.status != DriverOrderStatus.available && order.status != DriverOrderStatus.delivered && order.status != DriverOrderStatus.cancelled) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateOrderStatus(context, ref, order),
                      icon: const Icon(Icons.update),
                      label: const Text('Update Status'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reportIssue(context, order),
                      icon: const Icon(Icons.report_problem),
                      label: const Text('Report Issue'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
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
    switch (status) {
      case DriverOrderStatus.available:
        return Colors.blue;
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
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  Future<void> _openMaps(BuildContext context, String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    } catch (e) {
      debugPrint('Error opening maps: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening maps')),
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

  void _startDelivery(BuildContext context, DriverOrder order) {
    debugPrint('🚗 Starting delivery for order: ${order.id}');
    // Navigate to delivery workflow screen
    context.push('/driver/delivery/${order.id}');
  }

  void _continueDelivery(BuildContext context, DriverOrder order) {
    debugPrint('🚗 Continuing delivery for order: ${order.id}');
    // Navigate to delivery workflow screen
    context.push('/driver/delivery/${order.id}');
  }

  void _updateOrderStatus(BuildContext context, WidgetRef ref, DriverOrder order) {
    debugPrint('🚗 Updating status for order: ${order.id}');
    _showStatusUpdateDialog(context, ref, order);
  }

  void _reportIssue(BuildContext context, DriverOrder order) {
    debugPrint('🚗 Reporting issue for order: ${order.id}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Issue reporting - Coming soon!')),
    );
  }

  Future<void> _acceptOrder(BuildContext context, WidgetRef ref, DriverOrder order) async {
    debugPrint('🚗 Accepting order: ${order.id}');

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Accept Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to accept this order?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Delivery Fee: RM ${order.deliveryFee.toStringAsFixed(2)}'),
                  Text('Pickup: ${order.vendorName}'),
                  Text('Delivery: ${order.deliveryAddress}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final actions = ref.read(realtimeDriverOrderActionsProvider);
      final result = await actions.acceptOrder(order.id);

      result.when(
        success: (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order accepted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back to orders list
          context.pop();
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
  }

  Future<void> _rejectOrder(BuildContext context, WidgetRef ref, DriverOrder order) async {
    debugPrint('🚗 Rejecting order: ${order.id}');

    // Show confirmation dialog with reason
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        String? selectedReason;
        final reasons = [
          'Too far from my location',
          'Already have another delivery',
          'Restaurant is closed',
          'Traffic/road conditions',
          'Other',
        ];

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Reject Order'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Why are you rejecting this order?'),
                const SizedBox(height: 16),
                ...reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setState(() {
                      selectedReason = value;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedReason != null
                    ? () => Navigator.of(dialogContext).pop({
                          'confirmed': true,
                          'reason': selectedReason,
                        })
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
        );
      },
    );

    if (result?['confirmed'] == true) {
      final actions = ref.read(realtimeDriverOrderActionsProvider);
      final rejectResult = await actions.rejectOrder(order.id);

      rejectResult.when(
        success: (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order rejected'),
              backgroundColor: Colors.orange,
            ),
          );
          // Navigate back to orders list
          context.pop();
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
  }

  void _showStatusUpdateDialog(BuildContext context, WidgetRef ref, DriverOrder order) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (order.status == DriverOrderStatus.assigned) ...[
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('Picked up from restaurant'),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _updateStatus(context, ref, order.id, DriverOrderStatus.pickedUp);
                },
              ),
            ],
            if (order.status == DriverOrderStatus.pickedUp) ...[
              ListTile(
                leading: const Icon(Icons.local_shipping),
                title: const Text('En route to customer'),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _updateStatus(context, ref, order.id, DriverOrderStatus.onRouteToCustomer);
                },
              ),
            ],
            if (order.status == DriverOrderStatus.onRouteToCustomer) ...[
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Delivered'),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _updateStatus(context, ref, order.id, DriverOrderStatus.delivered);
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String orderId, DriverOrderStatus status) async {
    try {
      final actions = ref.read(realtimeDriverOrderActionsProvider);
      final result = await actions.updateOrderStatus(orderId, status);

      result.when(
        success: (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order status updated to ${status.displayName}'),
              backgroundColor: Colors.green,
            ),
          );
          // No need to manually reload - realtime subscriptions will handle it
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
    } catch (e) {
      debugPrint('Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
