import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';


import '../../../../core/utils/driver_workflow_logger.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/data/models/order.dart';
import '../../../orders/data/models/driver_order_state_machine.dart';
import '../../data/models/driver_order.dart';
import '../providers/driver_orders_management_providers.dart';
import '../providers/enhanced_driver_workflow_providers.dart';
import 'driver_delivery_confirmation_dialog.dart';
import '../../data/models/delivery_confirmation.dart';
import '../../data/services/delivery_confirmation_service.dart' as delivery_service;

/// Comprehensive order details dialog for drivers
class DriverOrderDetailsDialog extends ConsumerWidget {
  final Order order;

  const DriverOrderDetailsDialog({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    // Log workflow summary when dialog opens
    _logWorkflowSummary();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.9,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context, theme),
            
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Status
                    _buildOrderStatus(theme),
                    const SizedBox(height: 20),
                    
                    // Vendor Information
                    _buildVendorInfo(theme),
                    const SizedBox(height: 20),
                    
                    // Customer Information
                    _buildCustomerInfo(theme),
                    const SizedBox(height: 20),
                    
                    // Order Items
                    _buildOrderItems(theme),
                    const SizedBox(height: 20),
                    
                    // Order Summary
                    _buildOrderSummary(theme),
                    const SizedBox(height: 20),
                    
                    // Special Instructions
                    if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty)
                      _buildSpecialInstructions(theme),
                  ],
                ),
              ),
            ),
            
            // Action buttons
            _buildActionButtons(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order #${order.orderNumber}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatus(ThemeData theme) {
    return _buildSection(
      theme,
      'Order Status',
      Icons.info_outline,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusChip(theme),
          const SizedBox(height: 8),
          Text(
            'Created: ${_formatDateTime(order.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (order.estimatedDeliveryTime != null) ...[
            const SizedBox(height: 4),
            Text(
              'Estimated Delivery: ${_formatDateTime(order.estimatedDeliveryTime!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        Color backgroundColor;
        Color textColor;
        String displayText;

        // Get the enhanced status from the provider instead of the parsed enum
        final rawStatus = _getEnhancedOrderStatus(ref);
        final driverStatus = _mapStringToDriverStatus(rawStatus);
        displayText = driverStatus.displayName;

    switch (rawStatus) {
      // Granular driver workflow statuses
      case 'assigned':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case 'on_route_to_vendor':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'arrived_at_vendor':
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        break;
      case 'picked_up':
        backgroundColor = Colors.teal.shade100;
        textColor = Colors.teal.shade800;
        break;
      case 'on_route_to_customer':
        backgroundColor = Colors.indigo.shade100;
        textColor = Colors.indigo.shade800;
        break;
      case 'arrived_at_customer':
        backgroundColor = Colors.deepPurple.shade100;
        textColor = Colors.deepPurple.shade800;
        break;
      case 'delivered':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      // Legacy statuses
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        displayText = 'Pending';
        break;
      case 'confirmed':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        displayText = 'Confirmed';
        break;
      case 'preparing':
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        displayText = 'Preparing';
        break;
      case 'ready':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        displayText = 'Ready for Pickup';
        break;
      case 'out_for_delivery':
        backgroundColor = Colors.indigo.shade100;
        textColor = Colors.indigo.shade800;
        displayText = 'Out for Delivery';
        break;
      default:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        displayText = order.status.value.toUpperCase();
    }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            displayText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVendorInfo(ThemeData theme) {
    return _buildSection(
      theme,
      'Pickup Location',
      Icons.restaurant,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.vendorName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            order.deliveryAddress.fullAddress,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openMaps(order.deliveryAddress.fullAddress),
              icon: const Icon(Icons.directions, size: 18),
              label: const Text('Get Directions'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(ThemeData theme) {
    return _buildSection(
      theme,
      'Delivery Information',
      Icons.location_on,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.customerName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            order.deliveryAddress.fullAddress,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (order.contactPhone != null && order.contactPhone!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Phone: ${order.contactPhone}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openMaps(order.deliveryAddress.fullAddress),
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Directions'),
                ),
              ),
              if (order.contactPhone != null && order.contactPhone!.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callCustomer(order.contactPhone!),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(ThemeData theme) {
    final totalItems = order.items.fold<int>(0, (sum, item) => sum + item.quantity);
    
    return _buildSection(
      theme,
      'Order Items ($totalItems items)',
      Icons.shopping_bag,
      Column(
        children: order.items.map((item) => _buildOrderItem(theme, item)).toList(),
      ),
    );
  }

  Widget _buildOrderItem(ThemeData theme, OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${item.quantity}x',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'RM ${item.totalPrice.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          if (item.customizations != null && item.customizations!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Customizations: ${_formatCustomizations(item.customizations!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Notes: ${item.notes}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummary(ThemeData theme) {
    final formatter = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');

    return _buildSection(
      theme,
      'Order Summary',
      Icons.receipt,
      Column(
        children: [
          if (order.deliveryFee > 0)
            _buildSummaryRow(theme, 'Delivery Fee', formatter.format(order.deliveryFee)),
          const Divider(height: 20),
          _buildSummaryRow(
            theme,
            'Total Amount',
            formatter.format(order.totalAmount),
            isTotal: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Earnings',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  formatter.format(order.deliveryFee),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructions(ThemeData theme) {
    return _buildSection(
      theme,
      'Special Instructions',
      Icons.note,
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Text(
          order.specialInstructions!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.amber.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        debugPrint('🚗 [DIALOG] === BUILDING ACTION BUTTONS ===');
        debugPrint('🚗 [DIALOG] Order ID: ${order.id}');
        debugPrint('🚗 [DIALOG] Order status from model: ${order.status.value}');
        debugPrint('🚗 [DIALOG] Order assigned driver ID: ${order.assignedDriverId}');

        // Get the enhanced status from the provider instead of the parsed enum
        final rawStatus = _getEnhancedOrderStatus(ref);
        debugPrint('🚗 [DIALOG] Raw status from enhanced provider: "$rawStatus"');

        // Check if this is an unassigned order that needs to be accepted first
        final isUnassignedOrder = order.assignedDriverId == null && rawStatus == 'ready';
        if (isUnassignedOrder) {
          debugPrint('🚗 [DIALOG] Unassigned order - showing Accept Order button');
          debugPrint('🚗 [DIALOG] === END BUILDING ACTION BUTTONS ===');

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleTakeAction(context, ref),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Accept Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final currentDriverStatus = _mapStringToDriverStatus(rawStatus);
        debugPrint('🚗 [DIALOG] Current driver status: ${currentDriverStatus.name} (${currentDriverStatus.value})');

        final availableActions = DriverOrderStateMachine.getAvailableActions(currentDriverStatus);
        debugPrint('🚗 [DIALOG] Available actions: ${availableActions.map((a) => a.name).join(', ')}');

        final hasActions = availableActions.isNotEmpty;
        debugPrint('🚗 [DIALOG] Has actions: $hasActions');

        final actionText = hasActions ? _getActionButtonText(ref) : 'No Action Available';
        debugPrint('🚗 [DIALOG] Action button text: "$actionText"');

        // Check if any status update is in progress
        final isUpdating = ref.watch(updateDriverWorkflowStatusProvider((
          orderId: order.id,
          fromStatus: rawStatus,
          toStatus: _getNextStatusForOrder(ref),
        ))).isLoading;

        // Get appropriate icon for the action
        IconData actionIcon = Icons.navigation;
        if (hasActions) {
          final primaryAction = availableActions.first;
          switch (primaryAction) {
            case DriverOrderAction.navigateToVendor:
              actionIcon = Icons.restaurant;
              break;
            case DriverOrderAction.arrivedAtVendor:
              actionIcon = Icons.location_on;
              break;
            case DriverOrderAction.confirmPickup:
              actionIcon = Icons.check_circle;
              break;
            case DriverOrderAction.navigateToCustomer:
              actionIcon = Icons.navigation;
              break;
            case DriverOrderAction.arrivedAtCustomer:
              actionIcon = Icons.location_on;
              break;
            case DriverOrderAction.confirmDeliveryWithPhoto:
              actionIcon = Icons.camera_alt;
              break;
            default:
              actionIcon = Icons.navigation;
          }
        }

        debugPrint('🚗 [DIALOG] === END BUILDING ACTION BUTTONS ===');

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Workflow progress indicator
              if (hasActions) _buildWorkflowProgress(theme, currentDriverStatus),

              // Refresh button for troubleshooting
              if (!hasActions || rawStatus == 'assigned')
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextButton.icon(
                    onPressed: () {
                      debugPrint('🚗 [DIALOG] Manual refresh triggered');
                      ref.invalidate(enhancedCurrentDriverOrderProvider);
                      ref.invalidate(activeOrdersStreamProvider);
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh Status'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final isButtonEnabled = hasActions && !isUpdating;
                        return ElevatedButton.icon(
                          onPressed: isButtonEnabled ? () => _handleTakeAction(context, ref) : null,
                          icon: isUpdating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(actionIcon, size: 18),
                          label: Text(isUpdating ? 'Updating...' : actionText),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isButtonEnabled ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                            foregroundColor: isButtonEnabled ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkflowProgress(ThemeData theme, DriverOrderStatus currentStatus) {
    final workflowSteps = [
      DriverOrderStatus.assigned,
      DriverOrderStatus.onRouteToVendor,
      DriverOrderStatus.arrivedAtVendor,
      DriverOrderStatus.pickedUp,
      DriverOrderStatus.onRouteToCustomer,
      DriverOrderStatus.arrivedAtCustomer,
      DriverOrderStatus.delivered,
    ];

    final currentIndex = workflowSteps.indexOf(currentStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Progress',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: workflowSteps.asMap().entries.map((entry) {
              final index = entry.key;
              final isCompleted = index < currentIndex;
              final isCurrent = index == currentIndex;

              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < workflowSteps.length - 1 ? 2 : 0),
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            currentStatus.displayName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Log comprehensive workflow summary for debugging
  void _logWorkflowSummary() {
    final currentDriverStatus = _mapStringToDriverStatus(order.status.value);
    final availableActions = DriverOrderStateMachine.getAvailableActions(currentDriverStatus);

    DriverWorkflowLogger.logWorkflowSummary(
      orderId: order.id,
      currentStatus: order.status.value,
      availableActions: availableActions.map((a) => a.displayName).toList(),
      timestamps: {
        'created_at': order.createdAt,
        'estimated_delivery': order.estimatedDeliveryTime,
        'actual_delivery': order.actualDeliveryTime,
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • HH:mm').format(dateTime);
  }

  String _formatCustomizations(Map<String, dynamic> customizations) {
    return customizations.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
  }

  Future<void> _openMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callCustomer(String phoneNumber) async {
    final url = 'tel:$phoneNumber';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  /// Get the next status for the current order based on driver workflow
  String _getNextStatusForOrder(WidgetRef ref) {
    final rawStatus = _getEnhancedOrderStatus(ref);
    debugPrint('🚗 [DIALOG] Getting next status for order ${order.id} with current status: $rawStatus');

    // Use string-based mapping for more accurate status detection
    final currentDriverStatus = _mapStringToDriverStatus(rawStatus);
    debugPrint('🚗 [DIALOG] Mapped to driver status: ${currentDriverStatus.name}');

    // Get available actions for current status
    final availableActions = DriverOrderStateMachine.getAvailableActions(currentDriverStatus);
    debugPrint('🚗 [DIALOG] Available actions: ${availableActions.map((a) => a.name).join(', ')}');

    if (availableActions.isEmpty) {
      debugPrint('🚗 [DIALOG] No available actions for status: ${currentDriverStatus.name}');
      return order.status.value; // Return current status if no actions available
    }

    // Get the primary action (first in the list)
    final primaryAction = availableActions.first;
    final targetStatus = primaryAction.targetStatus;
    final nextStatus = _mapDriverStatusToOrderStatus(targetStatus);

    debugPrint('🚗 [DIALOG] Primary action: ${primaryAction.name} → target status: ${targetStatus.name} → order status: $nextStatus');
    return nextStatus;
  }

  /// Get the text for the action button based on current order status
  String _getActionButtonText(WidgetRef ref) {
    final rawStatus = _getEnhancedOrderStatus(ref);
    debugPrint('🚗 [DIALOG] === ACTION BUTTON TEXT GENERATION ===');
    debugPrint('🚗 [DIALOG] Raw status from provider: "$rawStatus"');
    debugPrint('🚗 [DIALOG] Order assigned driver ID: ${order.assignedDriverId}');

    // Check if this is an unassigned order that needs to be accepted first
    if (order.assignedDriverId == null && rawStatus == 'ready') {
      debugPrint('🚗 [DIALOG] ✅ Unassigned order with ready status - showing Accept Order');
      debugPrint('🚗 [DIALOG] === END ACTION BUTTON TEXT GENERATION ===');
      return 'Accept Order';
    }

    final currentDriverStatus = _mapStringToDriverStatus(rawStatus);
    debugPrint('🚗 [DIALOG] Mapped driver status: ${currentDriverStatus.name} (${currentDriverStatus.value})');
    debugPrint('🚗 [DIALOG] Driver status display name: ${currentDriverStatus.displayName}');

    final availableActions = DriverOrderStateMachine.getAvailableActions(currentDriverStatus);
    debugPrint('🚗 [DIALOG] Available actions count: ${availableActions.length}');
    debugPrint('🚗 [DIALOG] Available actions: ${availableActions.map((a) => '${a.name}(${a.displayName})').join(', ')}');

    if (availableActions.isEmpty) {
      debugPrint('🚗 [DIALOG] ❌ No actions available for status: ${currentDriverStatus.name}');
      return 'No Action Available';
    }

    final primaryAction = availableActions.first;
    debugPrint('🚗 [DIALOG] ✅ Primary action: ${primaryAction.name}');
    debugPrint('🚗 [DIALOG] ✅ Primary action display name: ${primaryAction.displayName}');
    debugPrint('🚗 [DIALOG] ✅ Primary action target status: ${primaryAction.targetStatus.name}');

    // Log the expected workflow progression for debugging
    _logExpectedWorkflowProgression(currentDriverStatus, primaryAction);

    debugPrint('🚗 [DIALOG] === END ACTION BUTTON TEXT GENERATION ===');
    return primaryAction.displayName;
  }

  /// Log the expected workflow progression for debugging and user understanding
  void _logExpectedWorkflowProgression(DriverOrderStatus currentStatus, DriverOrderAction nextAction) {
    final progressionMap = {
      DriverOrderStatus.assigned: 'assigned → Navigate to Restaurant → onRouteToVendor',
      DriverOrderStatus.onRouteToVendor: 'onRouteToVendor → Mark Arrived → arrivedAtVendor',
      DriverOrderStatus.arrivedAtVendor: 'arrivedAtVendor → Confirm Pickup → pickedUp',
      DriverOrderStatus.pickedUp: 'pickedUp → Navigate to Customer → onRouteToCustomer',
      DriverOrderStatus.onRouteToCustomer: 'onRouteToCustomer → Mark Arrived → arrivedAtCustomer',
      DriverOrderStatus.arrivedAtCustomer: 'arrivedAtCustomer → Complete Delivery → delivered',
      DriverOrderStatus.delivered: 'delivered (workflow complete)',
    };

    final progression = progressionMap[currentStatus] ?? 'Unknown progression';
    debugPrint('🚗 [DIALOG] Expected workflow progression: $progression');
    debugPrint('🚗 [DIALOG] Next action: ${nextAction.displayName} → ${nextAction.targetStatus.displayName}');
  }

  /// Handle the take action button press with enhanced workflow support
  Future<void> _handleTakeAction(BuildContext context, WidgetRef ref) async {
    debugPrint('🚗 [DIALOG] === HANDLE TAKE ACTION STARTED ===');

    // Use enhanced status from provider instead of parsed enum
    final currentStatus = _getEnhancedOrderStatus(ref);
    final actionText = _getActionButtonText(ref);

    debugPrint('🚗 [DIALOG] Button clicked: "$actionText"');
    debugPrint('🚗 [DIALOG] Current status: "$currentStatus"');
    debugPrint('🚗 [DIALOG] Order ID: ${order.id}');
    debugPrint('🚗 [DIALOG] Order assigned driver ID: ${order.assignedDriverId}');

    DriverWorkflowLogger.logButtonInteraction(
      buttonName: actionText,
      orderId: order.id,
      currentStatus: currentStatus,
      context: 'DIALOG',
    );

    try {
      // Handle "Accept Order" action for unassigned orders
      if (order.assignedDriverId == null && currentStatus == 'ready' && actionText == 'Accept Order') {
        debugPrint('🚗 [DIALOG] Handling Accept Order action for unassigned order');
        await _handleAcceptOrder(context, ref);
        return;
      }

      // Get the current driver status and available actions for assigned orders
      final currentDriverStatus = _mapStringToDriverStatus(currentStatus);
      final availableActions = DriverOrderStateMachine.getAvailableActions(currentDriverStatus);

      debugPrint('🚗 [DIALOG] Current driver status: ${currentDriverStatus.name}');
      debugPrint('🚗 [DIALOG] Available actions: ${availableActions.map((a) => a.name).join(', ')}');

      if (availableActions.isEmpty) {
        debugPrint('🚗 [DIALOG] ❌ No available actions for status: ${currentDriverStatus.name}');
        return;
      }

      final primaryAction = availableActions.first;
      debugPrint('🚗 [DIALOG] Primary action: ${primaryAction.name}');
      debugPrint('🚗 [DIALOG] Primary action target status: ${primaryAction.targetStatus.name}');

      // Handle special actions that require confirmation dialogs
      if (primaryAction == DriverOrderAction.confirmDeliveryWithPhoto) {
        debugPrint('🚗 [DIALOG] Handling delivery confirmation with photo');
        await _handleDeliveryConfirmation(context, ref);
        return;
      }

      // For other actions, proceed with direct status update
      final nextStatus = _getNextStatusForOrder(ref);
      debugPrint('🚗 [DIALOG] Next status calculated: "$nextStatus"');

      DriverWorkflowLogger.logStatusTransition(
        orderId: order.id,
        fromStatus: currentStatus,
        toStatus: nextStatus,
        context: 'DIALOG',
      );

      // Show loading feedback with action-specific message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$actionText...'),
          duration: const Duration(seconds: 2),
        ),
      );

      final stopwatch = Stopwatch()..start();

      debugPrint('🚗 [DIALOG] Calling updateDriverWorkflowStatusProvider...');
      debugPrint('🚗 [DIALOG] Parameters: orderId=${order.id}, fromStatus=$currentStatus, toStatus=$nextStatus');

      // Use enhanced workflow provider for better validation and tracking
      await ref.read(updateDriverWorkflowStatusProvider((
        orderId: order.id,
        fromStatus: currentStatus,
        toStatus: nextStatus,
      )).future);

      stopwatch.stop();

      debugPrint('🚗 [DIALOG] ✅ Status update completed successfully!');
      debugPrint('🚗 [DIALOG] Update took: ${stopwatch.elapsed.inMilliseconds}ms');

      DriverWorkflowLogger.logPerformance(
        operation: 'Status Update',
        duration: stopwatch.elapsed,
        orderId: order.id,
        context: 'DIALOG',
      );

      DriverWorkflowLogger.logDatabaseOperation(
        operation: 'UPDATE',
        orderId: order.id,
        data: {'from': currentStatus, 'to': nextStatus},
        context: 'DIALOG',
        isSuccess: true,
      );

      debugPrint('🚗 [DIALOG] Invalidating providers to refresh UI...');
      // Invalidate providers to force UI refresh
      ref.invalidate(enhancedCurrentDriverOrderProvider);
      ref.invalidate(activeOrdersStreamProvider);

      // Close dialog and show success message
      if (context.mounted) {
        debugPrint('🚗 [DIALOG] Closing dialog and showing success message');
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$actionText completed successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      debugPrint('🚗 [DIALOG] === HANDLE TAKE ACTION COMPLETED SUCCESSFULLY ===');

    } catch (e) {
      debugPrint('🚗 [DIALOG] ❌ Error during status update: $e');
      debugPrint('🚗 [DIALOG] Error type: ${e.runtimeType}');

      DriverWorkflowLogger.logError(
        operation: 'Status Update',
        error: e.toString(),
        orderId: order.id,
        context: 'DIALOG',
      );

      if (context.mounted) {
        debugPrint('🚗 [DIALOG] Showing error message to user');

        // Provide more user-friendly error messages based on error type
        String userMessage;
        if (e.toString().contains('permission') || e.toString().contains('not have permission')) {
          userMessage = 'Unable to update order status. Please contact support if this issue persists.';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          userMessage = 'Network error. Please check your connection and try again.';
        } else if (e.toString().contains('Invalid status transition')) {
          userMessage = 'Invalid status update. Please refresh and try again.';
        } else {
          userMessage = 'Failed to update order. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userMessage),
                const SizedBox(height: 4),
                Text(
                  'Error: ${e.toString()}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleTakeAction(context, ref),
            ),
          ),
        );
      }

      debugPrint('🚗 [DIALOG] === HANDLE TAKE ACTION FAILED ===');
    }
  }

  /// Handle accepting an unassigned order
  Future<void> _handleAcceptOrder(BuildContext context, WidgetRef ref) async {
    debugPrint('🚗 [DIALOG] Starting order acceptance process');

    try {
      // Get current user ID
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🚗 [DIALOG] Accepting order ${order.id} for driver $userId');

      // Accept the order using the provider
      await ref.read(acceptOrderProvider(order.id).future);

      debugPrint('🚗 [DIALOG] Order acceptance completed successfully');

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Close the dialog
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('🚗 [DIALOG] Error accepting order: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle delivery confirmation with photo capture
  Future<void> _handleDeliveryConfirmation(BuildContext context, WidgetRef ref) async {
    debugPrint('🚗 [DIALOG] Opening delivery confirmation dialog for order: ${order.id}');

    // Get the enhanced driver order from the provider
    final enhancedOrderAsync = ref.read(enhancedCurrentDriverOrderProvider);

    await enhancedOrderAsync.when(
      data: (enhancedOrder) async {
        if (enhancedOrder == null) {
          debugPrint('🚗 [DIALOG] No enhanced order available for delivery confirmation');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to load order details for delivery confirmation'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Show mandatory delivery confirmation dialog
        await showDialog<void>(
          context: context,
          barrierDismissible: false, // Cannot be dismissed by tapping outside
          builder: (context) => DriverDeliveryConfirmationDialog(
            order: enhancedOrder,
            onConfirmed: (confirmation) async {
              await _processDeliveryConfirmation(context, ref, confirmation);
            },
            onCancelled: () {
              // User cancelled delivery confirmation - no action taken
              debugPrint('🚗 [DIALOG] Delivery confirmation cancelled by user');
            },
          ),
        );
      },
      loading: () {
        debugPrint('🚗 [DIALOG] Enhanced order provider is loading');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Loading order details...'),
            ),
          );
        }
      },
      error: (error, stack) {
        debugPrint('🚗 [DIALOG] Enhanced order provider error: $error');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading order details: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  /// Process the delivery confirmation after photo capture and GPS verification
  Future<void> _processDeliveryConfirmation(
    BuildContext context,
    WidgetRef ref,
    DeliveryConfirmation confirmation
  ) async {
    try {
      debugPrint('🚗 [DIALOG] Processing delivery confirmation for order ${confirmation.orderId}');
      debugPrint('🚗 [DIALOG] Photo URL: ${confirmation.photoUrl}');
      debugPrint('🚗 [DIALOG] GPS Location: ${confirmation.location.latitude}, ${confirmation.location.longitude}');

      // Submit delivery confirmation through the service
      final deliveryService = ref.read(delivery_service.deliveryConfirmationServiceProvider);
      final result = await deliveryService.submitDeliveryConfirmation(confirmation);

      if (result.isSuccess) {
        debugPrint('🚗 [DIALOG] Delivery confirmation submitted successfully');

        // Update order status to delivered using the enhanced workflow provider
        await ref.read(updateDriverWorkflowStatusProvider((
          orderId: order.id,
          fromStatus: 'arrived_at_customer',
          toStatus: 'delivered',
        )).future);

        debugPrint('🚗 [DIALOG] Order status updated to delivered');

        // Close the order details dialog and show success message
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery completed successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Delivery confirmation failed: ${result.errorMessage}');
      }

    } catch (e) {
      debugPrint('🚗 [DIALOG] Failed to process delivery confirmation: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete delivery: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Map string status to driver order status for granular workflow support
  DriverOrderStatus _mapStringToDriverStatus(String statusString) {
    debugPrint('🚗 [DIALOG] Mapping string status "$statusString" to driver status');
    debugPrint('🚗 [DIALOG] Input status (original): "$statusString"');
    debugPrint('🚗 [DIALOG] Input status (lowercase): "${statusString.toLowerCase()}"');

    final mappedStatus = switch (statusString.toLowerCase()) {
      'ready' => DriverOrderStatus.assigned, // Available orders should be treated as assigned
      'assigned' => DriverOrderStatus.assigned,
      'on_route_to_vendor' || 'onroutetovendor' => DriverOrderStatus.onRouteToVendor,
      'arrived_at_vendor' || 'arrivedatvendor' => DriverOrderStatus.arrivedAtVendor,
      'picked_up' || 'pickedup' => DriverOrderStatus.pickedUp,
      'on_route_to_customer' || 'onroutetocustomer' => DriverOrderStatus.onRouteToCustomer,
      'arrived_at_customer' || 'arrivedatcustomer' => DriverOrderStatus.arrivedAtCustomer,
      'out_for_delivery' || 'outfordelivery' => DriverOrderStatus.pickedUp, // Legacy support
      'delivered' => DriverOrderStatus.delivered,
      'cancelled' => DriverOrderStatus.cancelled,
      _ => DriverOrderStatus.pickedUp, // Default fallback
    };

    debugPrint('🚗 [DIALOG] Mapped "$statusString" → ${mappedStatus.name} (${mappedStatus.value})');
    debugPrint('🚗 [DIALOG] Mapped status display name: ${mappedStatus.displayName}');

    if (statusString.toLowerCase() != 'ready' &&
        statusString.toLowerCase() != 'assigned' &&
        statusString.toLowerCase() != 'on_route_to_vendor' &&
        statusString.toLowerCase() != 'arrived_at_vendor' &&
        statusString.toLowerCase() != 'picked_up' &&
        statusString.toLowerCase() != 'on_route_to_customer' &&
        statusString.toLowerCase() != 'arrived_at_customer' &&
        statusString.toLowerCase() != 'delivered' &&
        statusString.toLowerCase() != 'cancelled' &&
        statusString.toLowerCase() != 'out_for_delivery' &&
        statusString.toLowerCase() != 'outfordelivery') {
      debugPrint('🚗 [DIALOG] ⚠️ Unknown status "$statusString" mapped to fallback: ${mappedStatus.name}');
    }

    return mappedStatus;
  }

  /// Map driver order status to order status string
  /// Now uses granular driver workflow statuses supported by the database
  String _mapDriverStatusToOrderStatus(DriverOrderStatus driverStatus) {
    debugPrint('🚗 [DIALOG] Mapping driver status ${driverStatus.name} to order status');

    switch (driverStatus) {
      case DriverOrderStatus.assigned:
        return 'assigned';
      case DriverOrderStatus.onRouteToVendor:
        return 'on_route_to_vendor';
      case DriverOrderStatus.arrivedAtVendor:
        return 'arrived_at_vendor';
      case DriverOrderStatus.pickedUp:
        return 'picked_up';
      case DriverOrderStatus.onRouteToCustomer:
        return 'on_route_to_customer';
      case DriverOrderStatus.arrivedAtCustomer:
        return 'arrived_at_customer';
      case DriverOrderStatus.delivered:
        return 'delivered';
      case DriverOrderStatus.cancelled:
        return 'cancelled';
      case DriverOrderStatus.failed:
        return 'cancelled';
    }
  }



  /// Get the raw order status - uses a cached value or fallback
  String _getRawOrderStatus() {
    // For now, we'll use the order.status.value as fallback
    // In a real implementation, we'd cache the raw status from the database
    // But since this is a dialog that opens quickly, we'll use a simpler approach

    // Check if the order status is 'pending' which likely means it was defaulted
    if (order.status.value == 'pending') {
      // Try to infer the actual status from other order fields or use a reasonable default
      // For active driver orders, if it's assigned to a driver, it's likely at least 'assigned'
      if (order.assignedDriverId != null) {
        debugPrint('🚗 [DIALOG] Order has assigned driver, inferring status as picked_up for workflow');
        return 'picked_up'; // Safe assumption for active driver orders
      }
    }

    return order.status.value;
  }

  /// Get the enhanced order status from the provider
  String _getEnhancedOrderStatus(WidgetRef ref) {
    debugPrint('🚗 [DIALOG] Getting enhanced order status for order: ${order.id}');

    // Watch the enhanced provider to get the real database status
    final enhancedOrderAsync = ref.watch(enhancedCurrentDriverOrderProvider);

    return enhancedOrderAsync.when(
      data: (enhancedOrder) {
        if (enhancedOrder != null && enhancedOrder.id == order.id) {
          // Get the status value from the DriverOrderStatus enum - use .value instead of .name
          final rawStatus = enhancedOrder.status.value;
          debugPrint('🚗 [DIALOG] Enhanced provider returned status: $rawStatus for order: ${order.id}');
          debugPrint('🚗 [DIALOG] Enhanced order status enum name: ${enhancedOrder.status.name}');
          debugPrint('🚗 [DIALOG] Enhanced order status enum value: ${enhancedOrder.status.value}');
          debugPrint('🚗 [DIALOG] Enhanced order full details: id=${enhancedOrder.id}, orderNumber=${enhancedOrder.orderNumber}');
          return rawStatus;
        } else {
          debugPrint('🚗 [DIALOG] Enhanced provider order mismatch or null');
          debugPrint('🚗 [DIALOG] Enhanced order: ${enhancedOrder?.id}, Expected: ${order.id}');
          debugPrint('🚗 [DIALOG] Falling back to raw status inference');
          return _getRawOrderStatus();
        }
      },
      loading: () {
        debugPrint('🚗 [DIALOG] Enhanced provider loading, falling back to raw status inference');
        return _getRawOrderStatus();
      },
      error: (error, stack) {
        debugPrint('🚗 [DIALOG] Enhanced provider error: $error, falling back to raw status inference');
        debugPrint('🚗 [DIALOG] Error details: $error');
        return _getRawOrderStatus();
      },
    );
  }
}
