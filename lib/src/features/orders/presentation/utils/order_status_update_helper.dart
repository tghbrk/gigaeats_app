import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/order.dart';
import '../../data/utils/order_validation_utils.dart';
import '../widgets/order_validation_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../presentation/providers/repository_providers.dart';

/// Helper class for handling order status updates with validation and user feedback
class OrderStatusUpdateHelper {
  /// Safely update order status with frontend validation and user feedback
  static Future<bool> updateOrderStatus(
    BuildContext context,
    WidgetRef ref, {
    required Order order,
    required OrderStatus newStatus,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get current user information
      final authState = ref.read(authStateProvider);
      final currentUser = authState.user;
      
      if (currentUser == null) {
        Navigator.of(context).pop(); // Close loading dialog
        await OrderValidationDialog.showSimpleError(
          context,
          title: 'Authentication Error',
          message: 'You must be logged in to update order status.',
        );
        onError?.call();
        return false;
      }

      // Perform frontend validation before attempting update
      final validationResult = await _validateStatusUpdate(
        ref,
        order: order,
        newStatus: newStatus,
        userRole: currentUser.role.value,
      );

      if (!validationResult.isValid) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show detailed validation error
        await OrderValidationDialog.showValidationError(
          context,
          currentStatus: order.status,
          attemptedStatus: newStatus,
          userRole: currentUser.role.value,
          validationResult: validationResult,
        );
        
        onError?.call();
        return false;
      }

      // Attempt the status update
      final orderRepository = ref.read(orderRepositoryProvider);
      await orderRepository.updateOrderStatus(order.id, newStatus);

      Navigator.of(context).pop(); // Close loading dialog

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order #${order.orderNumber} updated to ${newStatus.displayName}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      onSuccess?.call();
      return true;

    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );

      onError?.call();
      return false;
    }
  }

  /// Validate status update with user context
  static Future<OrderValidationResult> _validateStatusUpdate(
    WidgetRef ref, {
    required Order order,
    required OrderStatus newStatus,
    required String userRole,
  }) async {
    try {
      // Determine order ownership
      bool isVendorOrder = false;
      bool isSalesAgentOrder = false;

      final authState = ref.read(authStateProvider);
      final currentUser = authState.user;

      if (currentUser == null) {
        return OrderValidationResult(
          isValid: false,
          errorMessage: 'User not authenticated',
          errorType: OrderValidationErrorType.insufficientPermissions,
        );
      }

      if (userRole == 'vendor') {
        // For vendors, check if they own this order's vendor
        // This would require checking the vendor association
        // For now, we'll assume they can only see their own orders
        isVendorOrder = true;
      } else if (userRole == 'sales_agent') {
        // Check if this is the sales agent's order
        isSalesAgentOrder = order.salesAgentId == currentUser.id;
      }

      // Perform validation
      return OrderValidationUtils.validateOrderStatusUpdate(
        currentStatus: order.status,
        newStatus: newStatus,
        userRole: userRole,
        isOrderOwner: isVendorOrder || isSalesAgentOrder,
        isVendorOrder: isVendorOrder,
        isSalesAgentOrder: isSalesAgentOrder,
      );

    } catch (e) {
      return OrderValidationResult(
        isValid: false,
        errorMessage: 'Error validating status update: $e',
        errorType: OrderValidationErrorType.networkError,
      );
    }
  }

  /// Get available status update actions for a given order and user role
  static List<OrderStatusAction> getAvailableActions(
    Order order,
    String userRole,
  ) {
    final validNextStatuses = OrderValidationUtils.getValidNextStatuses(order.status);
    final actions = <OrderStatusAction>[];

    for (final status in validNextStatuses) {
      // Check if user role can perform this status update
      final canUpdate = OrderValidationUtils.canUserRoleUpdateToStatus(
        userRole,
        status,
        isOrderOwner: true, // Assume they can see it, so they can update it
        isVendorOrder: userRole == 'vendor',
        isSalesAgentOrder: userRole == 'sales_agent',
      );

      if (canUpdate) {
        actions.add(OrderStatusAction(
          status: status,
          label: _getActionLabel(order.status, status),
          icon: _getActionIcon(status),
          color: _getStatusColor(status),
        ));
      }
    }

    return actions;
  }

  static String _getActionLabel(OrderStatus currentStatus, OrderStatus newStatus) {
    switch (newStatus) {
      case OrderStatus.confirmed:
        return 'Accept Order';
      case OrderStatus.preparing:
        return 'Start Preparing';
      case OrderStatus.ready:
        return 'Mark as Ready';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Mark as Delivered';
      case OrderStatus.cancelled:
        return 'Cancel Order';
      default:
        return newStatus.displayName;
    }
  }

  static IconData _getActionIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.preparing:
        return Icons.kitchen;
      case OrderStatus.ready:
        return Icons.done_all;
      case OrderStatus.outForDelivery:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.update;
    }
  }

  static Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.teal;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}

/// Represents an available status update action
class OrderStatusAction {
  final OrderStatus status;
  final String label;
  final IconData icon;
  final Color color;

  const OrderStatusAction({
    required this.status,
    required this.label,
    required this.icon,
    required this.color,
  });
}
