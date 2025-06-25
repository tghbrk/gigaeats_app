import 'package:flutter/foundation.dart';
import '../models/driver_order.dart';
import '../models/driver_error.dart';
import '../models/driver_order_state_machine.dart';
import '../repositories/driver_order_repository.dart';

/// Centralized service for driver order business logic
class DriverOrderService {
  final DriverOrderRepository _repository;

  DriverOrderService(this._repository);

  /// Update driver status (online, offline, on_delivery, etc.)
  Future<DriverResult<bool>> updateDriverStatus(String driverId, String status) async {
    try {
      debugPrint('DriverOrderService: Updating driver $driverId status to $status');

      final success = await _repository.updateDriverStatus(driverId, status);

      if (success) {
        debugPrint('DriverOrderService: Driver status updated successfully');
        return DriverResult.success(true);
      } else {
        return DriverResult.error(
          DriverException(
            'Failed to update driver status',
            DriverErrorType.unknown,
          ),
        );
      }
    } catch (e) {
      debugPrint('DriverOrderService: Error updating driver status: $e');
      return DriverResult.fromException(e);
    }
  }

  /// Accept an order with validation
  Future<DriverResult<bool>> acceptOrder(String orderId, String driverId) async {
    try {
      debugPrint('DriverOrderService: Accepting order $orderId for driver $driverId');

      // Check if driver has active orders (business rule)
      final activeOrders = await _repository.getDriverOrders(driverId);
      final hasActiveOrders = activeOrders.any((order) =>
        order.status == DriverOrderStatus.assigned ||
        order.status == DriverOrderStatus.onRouteToVendor ||
        order.status == DriverOrderStatus.arrivedAtVendor ||
        order.status == DriverOrderStatus.pickedUp ||
        order.status == DriverOrderStatus.onRouteToCustomer ||
        order.status == DriverOrderStatus.arrivedAtCustomer
      );

      if (hasActiveOrders) {
        return DriverResult.error(
          DriverException(
            'Cannot accept order: You have active orders in progress',
            DriverErrorType.validationError,
          ),
        );
      }

      // Get order details to validate current status
      final order = await _repository.getOrderDetails(orderId);
      if (order == null) {
        return DriverResult.error(
          DriverException(
            'Order not found',
            DriverErrorType.orderNotFound,
          ),
        );
      }

      // Validate status transition
      final transitionResult = DriverOrderStateMachine.validateTransition(
        order.status,
        DriverOrderStatus.assigned,
      );

      if (!transitionResult.isSuccess) {
        return DriverResult.error(transitionResult.error!);
      }

      // Perform the acceptance
      final success = await _repository.acceptOrder(orderId, driverId);
      
      if (!success) {
        return DriverResult.error(
          DriverException(
            'Failed to accept order. It may have been assigned to another driver.',
            DriverErrorType.unknown,
          ),
        );
      }

      debugPrint('DriverOrderService: Order accepted successfully');
      return DriverResult.success(true);

    } catch (e) {
      debugPrint('DriverOrderService: Error accepting order: $e');
      return DriverResult.fromException(e);
    }
  }

  /// Update order status with validation
  Future<DriverResult<bool>> updateOrderStatus(
    String orderId,
    DriverOrderStatus newStatus,
    String driverId,
  ) async {
    try {
      debugPrint('DriverOrderService: Updating order $orderId to status ${newStatus.displayName}');

      // Get current order details
      final order = await _repository.getOrderDetails(orderId);
      if (order == null) {
        return DriverResult.error(
          DriverException(
            'Order not found',
            DriverErrorType.orderNotFound,
          ),
        );
      }

      // Validate status transition
      final transitionResult = DriverOrderStateMachine.validateTransition(
        order.status,
        newStatus,
      );

      if (!transitionResult.isSuccess) {
        return DriverResult.error(transitionResult.error!);
      }

      // Perform the status update
      final success = await _repository.updateOrderStatus(
        orderId,
        newStatus,
        driverId: driverId,
      );

      if (!success) {
        return DriverResult.error(
          DriverException(
            'Failed to update order status',
            DriverErrorType.unknown,
          ),
        );
      }

      debugPrint('DriverOrderService: Order status updated successfully');
      return DriverResult.success(true);

    } catch (e) {
      debugPrint('DriverOrderService: Error updating order status: $e');
      return DriverResult.fromException(e);
    }
  }

  /// Get available actions for an order
  List<DriverOrderAction> getAvailableActions(DriverOrder order) {
    return DriverOrderStateMachine.getAvailableActions(order.status);
  }

  /// Check if driver can perform action on order
  bool canPerformAction(DriverOrder order, DriverOrderAction action) {
    final availableActions = getAvailableActions(order);
    return availableActions.contains(action);
  }

  /// Get orders by status with business logic
  List<DriverOrder> filterOrdersByStatus(
    List<DriverOrder> orders,
    List<DriverOrderStatus> statuses,
  ) {
    return orders.where((order) => statuses.contains(order.status)).toList();
  }

  /// Get active orders (business logic)
  List<DriverOrder> getActiveOrders(List<DriverOrder> orders) {
    return filterOrdersByStatus(orders, [
      DriverOrderStatus.assigned,
      DriverOrderStatus.onRouteToVendor,
      DriverOrderStatus.arrivedAtVendor,
      DriverOrderStatus.pickedUp,
      DriverOrderStatus.onRouteToCustomer,
      DriverOrderStatus.arrivedAtCustomer,
    ]);
  }

  /// Get completed orders (business logic)
  List<DriverOrder> getCompletedOrders(List<DriverOrder> orders) {
    return filterOrdersByStatus(orders, [
      DriverOrderStatus.delivered,
      DriverOrderStatus.cancelled,
    ]);
  }

  /// Check if driver has active orders
  bool hasActiveOrders(List<DriverOrder> orders) {
    return getActiveOrders(orders).isNotEmpty;
  }

  /// Get order priority score for sorting
  int getOrderPriorityScore(DriverOrder order) {
    // Higher score = higher priority
    int score = 0;

    // Time-based priority (older orders get higher priority)
    final hoursSinceCreated = DateTime.now().difference(order.createdAt).inHours;
    score += hoursSinceCreated * 10;

    // Distance-based priority (closer orders get higher priority)
    // This would require location data - placeholder for now
    score += 50;

    // Amount-based priority (higher value orders get slight boost)
    score += (order.totalAmount / 10).round();

    return score;
  }

  /// Sort orders by priority
  List<DriverOrder> sortOrdersByPriority(List<DriverOrder> orders) {
    final sortedOrders = List<DriverOrder>.from(orders);
    sortedOrders.sort((a, b) => 
      getOrderPriorityScore(b).compareTo(getOrderPriorityScore(a))
    );
    return sortedOrders;
  }

  /// Validate order assignment business rules
  DriverResult<bool> validateOrderAssignment(String driverId, DriverOrder order) {
    // Check if order is still available
    if (order.status != DriverOrderStatus.available) {
      return DriverResult.error(
        DriverException(
          'Order is no longer available',
          DriverErrorType.orderNotFound,
        ),
      );
    }

    // Add more business rules as needed
    // e.g., driver location, vehicle type, etc.

    return DriverResult.success(true);
  }
}
