import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../orders/data/models/order.dart';
import '../../../orders/data/models/driver_order_state_machine.dart';
import '../../data/models/driver_order.dart';
import '../../data/models/delivery_confirmation.dart';
import '../providers/driver_orders_management_providers.dart';
import '../providers/driver_realtime_providers.dart';
import '../providers/enhanced_driver_workflow_providers.dart';
import '../providers/enhanced_navigation_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'driver_order_details_dialog.dart';
import 'driver_delivery_confirmation_dialog.dart';
import 'navigation_method_selection_dialog.dart';

/// Order card widget for driver order management with context-specific actions
class DriverOrderManagementCard extends ConsumerStatefulWidget {
  final Order order;
  final OrderCardType type;
  final VoidCallback? onTap;

  const DriverOrderManagementCard({
    super.key,
    required this.order,
    required this.type,
    this.onTap,
  });

  @override
  ConsumerState<DriverOrderManagementCard> createState() => _DriverOrderManagementCardState();
}

class _DriverOrderManagementCardState extends ConsumerState<DriverOrderManagementCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Enhanced driver workflow is watched in _getCurrentDriverStatus() for real-time updates

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onTap ?? () => _showOrderDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 12),
              _buildVendorInfo(theme),
              const SizedBox(height: 8),
              _buildCustomerInfo(theme),
              const SizedBox(height: 12),
              _buildOrderDetails(theme),
              const SizedBox(height: 16),
              _buildActionButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Order #${widget.order.orderNumber}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildStatusChip(theme),
      ],
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    final status = widget.order.status;
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status) {
      case OrderStatus.ready:
        // Use primary container colors for better contrast
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        displayText = 'Ready';
        break;
      case OrderStatus.confirmed:
        // Use tertiary container for confirmed status
        backgroundColor = theme.colorScheme.tertiaryContainer;
        textColor = theme.colorScheme.onTertiaryContainer;
        displayText = 'Confirmed';
        break;
      case OrderStatus.outForDelivery:
        // Use secondary container for in-progress status
        backgroundColor = theme.colorScheme.secondaryContainer;
        textColor = theme.colorScheme.onSecondaryContainer;
        displayText = 'Out for Delivery';
        break;
      case OrderStatus.delivered:
        // Use a custom success color with proper contrast
        backgroundColor = const Color(0xFF1DB954).withValues(alpha: 0.15); // Success green background
        textColor = const Color(0xFF0D5D2A); // Dark green text for contrast
        displayText = 'Delivered';
        break;
      case OrderStatus.cancelled:
        // Use error container colors for cancelled status
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        displayText = 'Cancelled';
        break;
      default:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        displayText = status.value;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildVendorInfo(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.restaurant,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.order.vendorName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.order.deliveryAddress.fullAddress,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails(ThemeData theme) {
    final formatter = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    final timeFormatter = DateFormat('HH:mm');
    
    return Row(
      children: [
        _buildInfoChip(
          theme,
          icon: Icons.schedule,
          label: timeFormatter.format(widget.order.createdAt),
        ),
        const SizedBox(width: 8),
        _buildInfoChip(
          theme,
          icon: Icons.shopping_bag,
          label: '${_getTotalItemsCount()} items',
        ),
        const SizedBox(width: 8),
        _buildInfoChip(
          theme,
          icon: Icons.attach_money,
          label: formatter.format(widget.order.totalAmount),
        ),
      ],
    );
  }

  Widget _buildInfoChip(ThemeData theme, {required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    switch (widget.type) {
      case OrderCardType.incoming:
        return _buildIncomingActions(theme);
      case OrderCardType.active:
        return _buildActiveActions(theme);
      case OrderCardType.history:
        return _buildHistoryActions(theme);
    }
  }

  Widget _buildIncomingActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _acceptOrder,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Accept Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: widget.onTap,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Details'),
        ),
      ],
    );
  }

  Widget _buildActiveActions(ThemeData theme) {
    final nextAction = _getNextAction();
    if (nextAction == null) {
      return OutlinedButton(
        onPressed: widget.onTap,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('View Details'),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _updateStatus(nextAction.status),
            icon: Icon(nextAction.icon, size: 18),
            label: Text(nextAction.label),
            style: ElevatedButton.styleFrom(
              backgroundColor: nextAction.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: widget.onTap,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Details'),
        ),
      ],
    );
  }

  Widget _buildHistoryActions(ThemeData theme) {
    return OutlinedButton(
      onPressed: widget.onTap,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text('View Details'),
    );
  }

  _NextAction? _getNextAction() {
    debugPrint('🚗 [DRIVER-CARD] Getting next action for order ${widget.order.id}, status: ${widget.order.status}');

    // For active orders, use driver-specific workflow
    if (widget.type == OrderCardType.active) {
      return _getDriverWorkflowAction();
    }

    // For incoming orders, show accept action
    if (widget.type == OrderCardType.incoming) {
      return _NextAction(
        label: 'Accept Order',
        icon: Icons.check_circle,
        color: Colors.green,
        status: 'assigned', // This will trigger driver workflow
        isDriverAction: true,
      );
    }

    // Fallback to basic order status workflow for other cases
    return _getBasicOrderAction();
  }

  _NextAction? _getDriverWorkflowAction() {
    // Determine current driver status from order
    final driverStatus = _getCurrentDriverStatus();
    debugPrint('🚗 [DRIVER-CARD] Current driver status: $driverStatus');

    if (driverStatus == null) {
      debugPrint('🚗 [DRIVER-CARD] No driver status found, using basic workflow');
      return _getBasicOrderAction();
    }

    // Get available actions from state machine
    final availableActions = DriverOrderStateMachine.getAvailableActions(driverStatus);
    debugPrint('🚗 [DRIVER-CARD] Available actions: ${availableActions.map((a) => a.displayName).join(', ')}');

    if (availableActions.isEmpty) {
      debugPrint('🚗 [DRIVER-CARD] No available actions for status: $driverStatus');
      return null;
    }

    // Get the primary action (first non-cancel action)
    final primaryAction = availableActions.firstWhere(
      (action) => action != DriverOrderAction.cancel && action != DriverOrderAction.reportIssue,
      orElse: () => availableActions.first,
    );

    return _NextAction(
      label: primaryAction.displayName,
      icon: _getIconFromName(primaryAction.iconName),
      color: _getActionColor(primaryAction),
      status: primaryAction.targetStatus.value,
      isDriverAction: true,
    );
  }

  _NextAction? _getBasicOrderAction() {
    switch (widget.order.status) {
      case OrderStatus.confirmed:
        return _NextAction(
          label: 'Mark Preparing',
          icon: Icons.kitchen,
          color: Colors.orange,
          status: 'preparing',
          isDriverAction: false,
        );
      case OrderStatus.preparing:
        return _NextAction(
          label: 'Mark Ready',
          icon: Icons.done_all,
          color: Colors.green,
          status: 'ready',
          isDriverAction: false,
        );
      case OrderStatus.ready:
        return _NextAction(
          label: 'Start Delivery',
          icon: Icons.local_shipping,
          color: Colors.blue,
          status: 'out_for_delivery',
          isDriverAction: false,
        );
      case OrderStatus.outForDelivery:
        return _NextAction(
          label: 'Complete Delivery',
          icon: Icons.camera_alt,
          color: Colors.green,
          status: 'delivered',
          isDriverAction: true, // ✅ CRITICAL FIX: Use driver workflow for photo capture
        );
      default:
        return null;
    }
  }

  DriverOrderStatus? _getCurrentDriverStatus() {
    debugPrint('🚗 [DRIVER-CARD] _getCurrentDriverStatus called for order: ${widget.order.id}');

    // Check authentication state first
    final authState = ref.read(authStateProvider);
    debugPrint('🚗 [DRIVER-CARD] Auth state - user: ${authState.user?.id}, role: ${authState.user?.role}');

    // Get enhanced order from provider for real-time status
    try {
      debugPrint('🚗 [DRIVER-CARD] About to watch enhancedCurrentDriverOrderProvider...');

      // Force refresh the provider to ensure it executes after status updates
      // Use read to check if provider needs refresh
      final currentState = ref.read(enhancedCurrentDriverOrderProvider);
      debugPrint('🚗 [DRIVER-CARD] Current provider state before watch: ${currentState.runtimeType}');

      final enhancedOrderAsync = ref.watch(enhancedCurrentDriverOrderProvider);

      debugPrint('🚗 [DRIVER-CARD] Enhanced provider state: ${enhancedOrderAsync.runtimeType}');
      debugPrint('🚗 [DRIVER-CARD] Enhanced provider hasValue: ${enhancedOrderAsync.hasValue}');
      debugPrint('🚗 [DRIVER-CARD] Enhanced provider isLoading: ${enhancedOrderAsync.isLoading}');
      debugPrint('🚗 [DRIVER-CARD] Enhanced provider hasError: ${enhancedOrderAsync.hasError}');

      final enhancedOrder = enhancedOrderAsync.when(
        data: (order) {
          debugPrint('🚗 [DRIVER-CARD] Enhanced provider data: order=${order?.id}, looking for=${widget.order.id}');
          if (order != null) {
            debugPrint('🚗 [DRIVER-CARD] Enhanced order details: status=${order.status.value}, orderNumber=${order.orderNumber}');
          }
          return order?.id == widget.order.id ? order : null;
        },
        loading: () {
          debugPrint('🚗 [DRIVER-CARD] Enhanced provider loading...');
          return null;
        },
        error: (error, stack) {
          debugPrint('🚗 [DRIVER-CARD] Enhanced provider error: $error');
          debugPrint('🚗 [DRIVER-CARD] Enhanced provider stack: $stack');
          return null;
        },
      );

      // Use enhanced order status if available (real-time)
      if (enhancedOrder != null) {
        debugPrint('🚗 [DRIVER-CARD] Using enhanced order status: ${enhancedOrder.status.value}');
        return enhancedOrder.status;
      }
    } catch (e, stack) {
      debugPrint('🚗 [DRIVER-CARD] Exception watching enhanced provider: $e');
      debugPrint('🚗 [DRIVER-CARD] Exception stack: $stack');
    }

    // Fallback to basic order status mapping
    debugPrint('🚗 [DRIVER-CARD] Using basic order status mapping for: ${widget.order.status}');

    if (widget.order.assignedDriverId == null) {
      return null; // No driver assigned
    }

    switch (widget.order.status) {
      case OrderStatus.ready:
        // If driver is assigned but status is still ready, they haven't started yet
        return DriverOrderStatus.assigned;
      case OrderStatus.outForDelivery:
        // Map legacy status to picked up so driver can navigate to customer
        return DriverOrderStatus.pickedUp;
      case OrderStatus.delivered:
        return DriverOrderStatus.delivered;
      case OrderStatus.cancelled:
        return DriverOrderStatus.cancelled;
      default:
        return null;
    }
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'navigation':
        return Icons.navigation;
      case 'location_on':
        return Icons.location_on;
      case 'check_circle':
        return Icons.check_circle;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'cancel':
        return Icons.cancel;
      case 'report_problem':
        return Icons.report_problem;
      case 'check':
        return Icons.check;
      case 'close':
        return Icons.close;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'done':
        return Icons.done;
      case 'local_shipping':
        return Icons.local_shipping;
      default:
        return Icons.play_arrow; // Default icon
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
      case DriverOrderAction.confirmDeliveryWithPhoto:
        return Colors.green;
      case DriverOrderAction.cancel:
        return Colors.red;
      case DriverOrderAction.reportIssue:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Future<void> _acceptOrder() async {
    debugPrint('🚗 [DRIVER-CARD] Starting order acceptance for ${widget.order.orderNumber} (ID: ${widget.order.id.substring(0, 8)}...)');
    debugPrint('🚗 [DRIVER-CARD] Current order status: ${widget.order.status.value}');
    debugPrint('🚗 [DRIVER-CARD] Order type: ${widget.type}');

    setState(() => _isProcessing = true);

    try {
      debugPrint('🚗 [DRIVER-CARD] Calling acceptOrderProvider...');
      await ref.read(acceptOrderProvider(widget.order.id).future);

      debugPrint('✅ [DRIVER-CARD] Order accepted successfully');
      debugPrint('🚗 [DRIVER-CARD] Order should now transition from incoming to active');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [DRIVER-CARD] Error accepting order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    debugPrint('🚗 [DRIVER-CARD] Updating order ${widget.order.id} status to: $status');
    setState(() => _isProcessing = true);

    try {
      // Determine if this is a driver-specific action
      final nextAction = _getNextAction();
      final isDriverAction = nextAction?.isDriverAction ?? false;

      if (isDriverAction && widget.type == OrderCardType.active) {
        debugPrint('🚗 [DRIVER-CARD] Using driver workflow status update');
        await _updateDriverWorkflowStatus(status);
      } else if (widget.type == OrderCardType.incoming && status == 'assigned') {
        debugPrint('🚗 [DRIVER-CARD] Accepting incoming order');
        await _acceptOrder();
      } else {
        debugPrint('🚗 [DRIVER-CARD] Using basic order status update');
        await ref.read(updateOrderStatusProvider((orderId: widget.order.id, status: status)).future);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order status updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('🚗 [DRIVER-CARD] Error updating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _updateDriverWorkflowStatus(String status) async {
    debugPrint('🚗 [DRIVER-CARD] Updating driver workflow status to: $status');

    try {
      // Handle navigation actions before status update using Enhanced In-App Navigation
      if (status == 'on_route_to_customer') {
        debugPrint('🚗 [DRIVER-CARD] Starting Enhanced In-App Navigation to customer');
        await _startEnhancedNavigationToCustomer();
      } else if (status == 'on_route_to_vendor') {
        debugPrint('🚗 [DRIVER-CARD] Starting Enhanced In-App Navigation to vendor');
        await _startEnhancedNavigationToVendor();
      }

      // ✅ CRITICAL FIX: Handle delivery completion with photo capture
      if (status == 'delivered') {
        debugPrint('🚗 [DRIVER-CARD] Handling delivery completion with photo capture');
        await _handleDeliveryCompletionWithPhoto();
        return;
      }

      // Use enhanced driver workflow provider for status update
      final driverOrderStatus = DriverOrderStatus.fromString(status);
      final result = await ref.read(realtimeDriverOrderActionsProvider).updateOrderStatus(
        widget.order.id,
        driverOrderStatus,
      );

      result.when(
        success: (success) {
          debugPrint('🚗 [DRIVER-CARD] Driver workflow status updated successfully');

          // Refresh enhanced provider after successful status update
          debugPrint('🚗 [DRIVER-CARD] Status update successful, refreshing enhanced provider');
          ref.invalidate(enhancedCurrentDriverOrderProvider);

          // Show success feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_getStatusUpdateMessage(status)),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        error: (error) {
          debugPrint('🚗 [DRIVER-CARD] Error updating driver workflow status: ${error.userFriendlyMessage}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${error.userFriendlyMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('🚗 [DRIVER-CARD] Exception updating driver workflow status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle delivery completion with mandatory photo capture
  Future<void> _handleDeliveryCompletionWithPhoto() async {
    debugPrint('🚗 [DRIVER-CARD] Starting delivery completion with photo capture');

    try {
      // Show delivery confirmation dialog with photo capture
      await showDialog<void>(
        context: context,
        barrierDismissible: false, // Cannot be dismissed without completing
        builder: (context) => DriverDeliveryConfirmationDialog(
          order: _convertOrderToDriverOrder(widget.order),
          onConfirmed: (confirmation) async {
            await _processDeliveryConfirmation(confirmation);
          },
          onCancelled: () {
            debugPrint('🚗 [DRIVER-CARD] Delivery confirmation cancelled by user');
          },
        ),
      );
    } catch (e) {
      debugPrint('🚗 [DRIVER-CARD] Error in delivery completion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete delivery: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Process delivery confirmation after photo capture
  Future<void> _processDeliveryConfirmation(DeliveryConfirmation confirmation) async {
    try {
      debugPrint('🚗 [DRIVER-CARD] Processing delivery confirmation');
      debugPrint('🚗 [DRIVER-CARD] Photo URL: ${confirmation.photoUrl}');

      // Submit delivery confirmation
      final deliveryService = ref.read(deliveryConfirmationServiceProvider);
      final result = await deliveryService.submitDeliveryConfirmation(confirmation);

      if (result.isSuccess) {
        debugPrint('🚗 [DRIVER-CARD] Delivery confirmation submitted successfully');
        debugPrint('🔧 [DRIVER-CARD] Database trigger has automatically updated order status to delivered');

        // Refresh provider to show updated status from database trigger
        ref.invalidate(enhancedCurrentDriverOrderProvider);
        debugPrint('🔄 [DRIVER-CARD] Order data refreshed to show updated status');

        // Show success message
        if (mounted) {
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
      debugPrint('🚗 [DRIVER-CARD] Error processing delivery confirmation: $e');

      // Enhanced error handling for duplicate delivery scenarios
      String userFriendlyMessage;
      Color snackBarColor = Colors.red;

      if (e.toString().contains('already been completed') ||
          e.toString().contains('duplicate key value') ||
          e.toString().contains('unique_order_proof')) {
        debugPrint('🔍 [DRIVER-CARD] Detected duplicate delivery completion attempt');
        userFriendlyMessage = 'This delivery has already been completed. Refreshing order status.';
        snackBarColor = Colors.orange;

        // Refresh the order data to show current status
        try {
          ref.invalidate(enhancedCurrentDriverOrderProvider);
          debugPrint('🔄 [DRIVER-CARD] Order data refreshed after duplicate detection');
        } catch (refreshError) {
          debugPrint('⚠️ [DRIVER-CARD] Failed to refresh order data: $refreshError');
        }
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        debugPrint('🌐 [DRIVER-CARD] Network error detected');
        userFriendlyMessage = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('permission') || e.toString().contains('unauthorized')) {
        debugPrint('🔒 [DRIVER-CARD] Permission error detected');
        userFriendlyMessage = 'You don\'t have permission to complete this delivery. Please contact support.';
      } else {
        debugPrint('❌ [DRIVER-CARD] Unknown error type');
        userFriendlyMessage = 'Failed to complete delivery. Please try again or contact support.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyMessage),
            backgroundColor: snackBarColor,
            duration: const Duration(seconds: 5),
            action: snackBarColor == Colors.orange ? SnackBarAction(
              label: 'Refresh',
              textColor: Colors.white,
              onPressed: () {
                ref.invalidate(enhancedCurrentDriverOrderProvider);
              },
            ) : null,
          ),
        );
      }
    }
  }

  /// Convert Order to DriverOrder for delivery confirmation dialog
  DriverOrder _convertOrderToDriverOrder(Order order) {
    return DriverOrder.fromJson({
      'id': order.id,
      'order_id': order.id,
      'order_number': order.orderNumber,
      'driver_id': order.assignedDriverId ?? '',
      'vendor_id': order.vendorId,
      'vendor_name': order.vendorName,
      'customer_id': order.customerId,
      'customer_name': order.customerName,
      'status': _mapOrderStatusToDriverStatus(order.status),
      'priority': 'normal',
      'delivery_details': {
        'pickup_address': '', // Not available in Order model
        'delivery_address': order.deliveryAddress.fullAddress,
        'contact_phone': order.contactPhone,
      },
      'order_earnings': {
        'base_fee': 5.0,
        'total_earnings': 8.50,
      },
      'order_items_count': order.items.length,
      'order_total': order.totalAmount,
      'payment_method': null,
      'requires_cash_collection': false,
      'assigned_at': DateTime.now().toIso8601String(),
      'accepted_at': null,
      'started_route_at': null,
      'arrived_at_vendor_at': null,
      'picked_up_at': null,
      'arrived_at_customer_at': null,
      'delivered_at': null,
      'created_at': order.createdAt.toIso8601String(),
      'updated_at': order.updatedAt.toIso8601String(),
    });
  }

  /// Map Order status to valid DriverOrderStatus values
  String _mapOrderStatusToDriverStatus(OrderStatus orderStatus) {
    switch (orderStatus) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
      case OrderStatus.ready:
        // For orders that haven't been assigned to driver yet, default to assigned
        return 'assigned';
      case OrderStatus.outForDelivery:
        // Legacy status - map to picked_up for driver workflow
        return 'picked_up';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  void _showOrderDetails(BuildContext context) {
    debugPrint('🚗 Showing order details for: ${widget.order.id}');
    showDialog(
      context: context,
      builder: (context) => DriverOrderDetailsDialog(order: widget.order),
    );
  }

  int _getTotalItemsCount() {
    return widget.order.items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  /// Show navigation method selection for customer
  Future<void> _startEnhancedNavigationToCustomer() async {
    try {
      debugPrint('🧭 [DRIVER-CARD] ═══ NAVIGATION TO CUSTOMER START ═══');
      debugPrint('🧭 [DRIVER-CARD] Order ID: ${widget.order.id}');
      debugPrint('🧭 [DRIVER-CARD] Customer address: ${widget.order.deliveryAddress.fullAddress}');

      // TODO: Convert address to coordinates using geocoding service
      // For now, use a placeholder coordinate
      const destination = LatLng(3.1390, 101.6869); // Kuala Lumpur placeholder
      const destinationName = 'Customer Location';

      debugPrint('🧭 [DRIVER-CARD] Showing navigation method selection dialog');

      // Show navigation method selection dialog
      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => NavigationMethodSelectionDialog(
            destinationName: destinationName,
            destinationLat: destination.latitude,
            destinationLng: destination.longitude,
            onInAppNavigationSelected: () async {
              debugPrint('🧭 [DRIVER-CARD] User selected Enhanced In-App Navigation to customer');
              await _startEnhancedInAppNavigationToCustomer();
            },
            onExternalNavigationSelected: () {
              debugPrint('🧭 [DRIVER-CARD] User selected external navigation to customer');
              // External navigation is handled by the dialog itself
            },
          ),
        );
      }

      debugPrint('🧭 [DRIVER-CARD] ═══ NAVIGATION TO CUSTOMER END ═══');
    } catch (e) {
      debugPrint('❌ [DRIVER-CARD] Error showing navigation selection for customer: $e');

      // Fallback to external Google Maps
      await _fallbackToExternalMaps(widget.order.deliveryAddress.fullAddress, 'Customer');
    }
  }

  /// Start Enhanced In-App Navigation to customer (called after user selection)
  Future<void> _startEnhancedInAppNavigationToCustomer() async {
    try {
      debugPrint('🧭 [DRIVER-CARD] ═══ ENHANCED IN-APP NAVIGATION TO CUSTOMER START ═══');

      // TODO: Convert address to coordinates using geocoding service
      const destination = LatLng(3.1390, 101.6869); // Kuala Lumpur placeholder
      const origin = LatLng(3.1390, 101.6869); // Placeholder current location
      const destinationName = 'Customer Location';

      debugPrint('🧭 [DRIVER-CARD] Destination: ${destination.latitude}, ${destination.longitude}');

      // Get the navigation provider
      final navigationProvider = ref.read(enhancedNavigationProvider.notifier);
      debugPrint('🧭 [DRIVER-CARD] Navigation provider obtained');

      // Clear any previous navigation state
      debugPrint('🧭 [DRIVER-CARD] Clearing previous navigation state');
      await navigationProvider.stopNavigation();

      // Start Enhanced In-App Navigation with comprehensive error handling
      debugPrint('🧭 [DRIVER-CARD] Starting navigation session...');
      final success = await navigationProvider.startNavigation(
        origin: origin,
        destination: destination,
        orderId: widget.order.id,
        destinationName: destinationName,
      );

      if (success) {
        debugPrint('✅ [DRIVER-CARD] Enhanced In-App Navigation to customer started successfully');

        // Wait longer to ensure state is properly set before navigation
        debugPrint('🧭 [DRIVER-CARD] Waiting for navigation state to stabilize...');
        await Future.delayed(const Duration(milliseconds: 500));

        // Verify navigation state multiple times with retries
        bool navigationReady = false;
        for (int attempt = 1; attempt <= 3; attempt++) {
          final navState = ref.read(enhancedNavigationProvider);
          debugPrint('🧭 [DRIVER-CARD] Navigation state check $attempt/3: isNavigating=${navState.isNavigating}, session=${navState.currentSession?.id}, error=${navState.error}');

          if (navState.isNavigating && navState.currentSession != null && navState.error == null) {
            navigationReady = true;
            break;
          }

          if (attempt < 3) {
            debugPrint('🧭 [DRIVER-CARD] Navigation state not ready, waiting 200ms before retry...');
            await Future.delayed(const Duration(milliseconds: 200));
          }
        }

        // Navigate to the in-app navigation screen
        if (mounted && navigationReady) {
          debugPrint('🧭 [DRIVER-CARD] Navigation state verified, navigating to /driver/dashboard/navigation screen');
          context.go('/driver/dashboard/navigation');
        } else {
          final navState = ref.read(enhancedNavigationProvider);
          debugPrint('❌ [DRIVER-CARD] Navigation state not ready after retries: mounted=$mounted, isNavigating=${navState.isNavigating}, session=${navState.currentSession?.id}, error=${navState.error}');

          // Show error to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Navigation setup failed: ${navState.error ?? "Unknown error"}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }

          // Fallback to external Google Maps
          await _fallbackToExternalMaps(widget.order.deliveryAddress.fullAddress, 'Customer');
        }
      } else {
        debugPrint('❌ [DRIVER-CARD] Failed to start Enhanced In-App Navigation to customer');

        // Get error details from provider
        final navState = ref.read(enhancedNavigationProvider);
        debugPrint('❌ [DRIVER-CARD] Navigation error: ${navState.error}');

        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigation failed: ${navState.error ?? "Unknown error"}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Fallback to external Google Maps
        await _fallbackToExternalMaps(widget.order.deliveryAddress.fullAddress, 'Customer');
      }

      debugPrint('🧭 [DRIVER-CARD] ═══ ENHANCED IN-APP NAVIGATION TO CUSTOMER END ═══');
    } catch (e, stackTrace) {
      debugPrint('❌ [DRIVER-CARD] Error starting Enhanced In-App Navigation to customer: $e');
      debugPrint('❌ [DRIVER-CARD] Stack trace: $stackTrace');

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Fallback to external Google Maps
      await _fallbackToExternalMaps(widget.order.deliveryAddress.fullAddress, 'Customer');
    }
  }

  /// Show navigation method selection for vendor
  Future<void> _startEnhancedNavigationToVendor() async {
    try {
      debugPrint('🧭 [DRIVER-CARD] ═══ NAVIGATION TO VENDOR START ═══');
      debugPrint('🧭 [DRIVER-CARD] Order ID: ${widget.order.id}');
      debugPrint('🧭 [DRIVER-CARD] Vendor name: ${widget.order.vendorName}');

      // TODO: Convert address to coordinates using geocoding service
      // For now, use a placeholder coordinate
      const destination = LatLng(3.139, 101.6869); // Kuala Lumpur placeholder
      final destinationName = widget.order.vendorName;

      debugPrint('🧭 [DRIVER-CARD] Showing navigation method selection dialog');

      // Show navigation method selection dialog
      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => NavigationMethodSelectionDialog(
            destinationName: destinationName,
            destinationLat: destination.latitude,
            destinationLng: destination.longitude,
            onInAppNavigationSelected: () async {
              debugPrint('🧭 [DRIVER-CARD] User selected Enhanced In-App Navigation to vendor');
              await _startEnhancedInAppNavigationToVendor();
            },
            onExternalNavigationSelected: () {
              debugPrint('🧭 [DRIVER-CARD] User selected external navigation to vendor');
              // External navigation is handled by the dialog itself
            },
          ),
        );
      }

      debugPrint('🧭 [DRIVER-CARD] ═══ NAVIGATION TO VENDOR END ═══');
    } catch (e) {
      debugPrint('❌ [DRIVER-CARD] Error showing navigation selection for vendor: $e');

      // Fallback to external Google Maps
      await _fallbackToExternalMaps(widget.order.vendorName, 'Vendor');
    }
  }

  /// Start Enhanced In-App Navigation to vendor (called after user selection)
  Future<void> _startEnhancedInAppNavigationToVendor() async {
    try {
      debugPrint('🧭 [DRIVER-CARD] ═══ ENHANCED IN-APP NAVIGATION TO VENDOR START ═══');

      // TODO: Convert address to coordinates using geocoding service
      const destination = LatLng(3.139, 101.6869); // Kuala Lumpur placeholder
      const origin = LatLng(3.1390, 101.6869); // Placeholder current location
      final destinationName = widget.order.vendorName;

      // Get the navigation provider
      final navigationProvider = ref.read(enhancedNavigationProvider.notifier);
      debugPrint('🧭 [DRIVER-CARD] Navigation provider obtained');

      // Clear any previous navigation state
      debugPrint('🧭 [DRIVER-CARD] Clearing previous navigation state');
      await navigationProvider.stopNavigation();

      // Start Enhanced In-App Navigation with comprehensive error handling
      debugPrint('🧭 [DRIVER-CARD] Starting navigation session...');
      final success = await navigationProvider.startNavigation(
        origin: origin,
        destination: destination,
        orderId: widget.order.id,
        destinationName: destinationName,
      );

      if (success) {
        debugPrint('✅ [DRIVER-CARD] Enhanced In-App Navigation to vendor started successfully');

        // Wait longer to ensure state is properly set before navigation
        debugPrint('🧭 [DRIVER-CARD] Waiting for navigation state to stabilize...');
        await Future.delayed(const Duration(milliseconds: 500));

        // Verify navigation state multiple times with retries
        bool navigationReady = false;
        for (int attempt = 1; attempt <= 3; attempt++) {
          final navState = ref.read(enhancedNavigationProvider);
          debugPrint('🧭 [DRIVER-CARD] Navigation state check $attempt/3: isNavigating=${navState.isNavigating}, session=${navState.currentSession?.id}, error=${navState.error}');

          if (navState.isNavigating && navState.currentSession != null && navState.error == null) {
            navigationReady = true;
            break;
          }

          if (attempt < 3) {
            debugPrint('🧭 [DRIVER-CARD] Navigation state not ready, waiting 200ms before retry...');
            await Future.delayed(const Duration(milliseconds: 200));
          }
        }

        // Navigate to the in-app navigation screen
        if (mounted && navigationReady) {
          debugPrint('🧭 [DRIVER-CARD] Navigation state verified, navigating to /driver/dashboard/navigation screen');
          context.go('/driver/dashboard/navigation');
        } else {
          final navState = ref.read(enhancedNavigationProvider);
          debugPrint('❌ [DRIVER-CARD] Navigation state not ready after retries: mounted=$mounted, isNavigating=${navState.isNavigating}, session=${navState.currentSession?.id}, error=${navState.error}');

          // Show error to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Navigation setup failed: ${navState.error ?? "Unknown error"}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }

          // Fallback to external Google Maps
          await _fallbackToExternalMaps(widget.order.vendorName, 'Vendor');
        }
      } else {
        debugPrint('❌ [DRIVER-CARD] Failed to start Enhanced In-App Navigation to vendor');

        // Get error details from provider
        final navState = ref.read(enhancedNavigationProvider);
        debugPrint('❌ [DRIVER-CARD] Navigation error: ${navState.error}');

        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigation failed: ${navState.error ?? "Unknown error"}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Fallback to external Google Maps
        await _fallbackToExternalMaps(widget.order.vendorName, 'Vendor');
      }

      debugPrint('🧭 [DRIVER-CARD] ═══ ENHANCED IN-APP NAVIGATION TO VENDOR END ═══');
    } catch (e, stackTrace) {
      debugPrint('❌ [DRIVER-CARD] Error starting Enhanced In-App Navigation to vendor: $e');
      debugPrint('❌ [DRIVER-CARD] Stack trace: $stackTrace');

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Fallback to external Google Maps
      await _fallbackToExternalMaps(widget.order.vendorName, 'Vendor');
    }
  }

  /// Fallback to external Google Maps when Enhanced In-App Navigation fails
  Future<void> _fallbackToExternalMaps(String address, String locationType) async {
    try {
      debugPrint('🧭 [DRIVER-CARD] Falling back to external Google Maps for $locationType');

      final encodedAddress = Uri.encodeComponent(address);
      final url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';

      debugPrint('🧭 [DRIVER-CARD] Opening external maps to $locationType: $address');

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        debugPrint('❌ [DRIVER-CARD] Could not launch external maps URL: $url');
      }
    } catch (e) {
      debugPrint('❌ [DRIVER-CARD] Error opening external maps to $locationType: $e');
    }
  }

  /// Get status update success message
  String _getStatusUpdateMessage(String status) {
    switch (status) {
      case 'on_route_to_vendor':
        return 'Navigation started to restaurant';
      case 'on_route_to_customer':
        return 'Navigation started to customer';
      case 'arrived_at_vendor':
        return 'Arrived at restaurant';
      case 'arrived_at_customer':
        return 'Arrived at customer';
      case 'picked_up':
        return 'Order picked up successfully';
      case 'delivered':
        return 'Order delivered successfully';
      default:
        return 'Status updated successfully';
    }
  }
}

enum OrderCardType {
  incoming,
  active,
  history,
}

class _NextAction {
  final String label;
  final IconData icon;
  final Color color;
  final String status;
  final bool isDriverAction;

  const _NextAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.status,
    required this.isDriverAction,
  });
}
