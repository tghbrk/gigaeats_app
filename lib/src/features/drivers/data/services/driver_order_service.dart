

import '../../../orders/data/models/driver_order.dart';
import '../../../orders/data/repositories/driver_order_repository.dart';
import '../models/driver_error.dart';
import '../../../../core/utils/logger.dart';

/// Service for managing driver order operations
/// Provides business logic for driver order management
class DriverOrderService {
  final DriverOrderRepository repository;
  final AppLogger _logger = AppLogger();

  DriverOrderService({required this.repository});

  /// Get active orders for a driver
  List<DriverOrder> getActiveOrders(List<DriverOrder> orders) {
    return orders.where((order) => 
      order.status == DriverOrderStatus.assigned ||
      order.status == DriverOrderStatus.onRouteToVendor ||
      order.status == DriverOrderStatus.arrivedAtVendor ||
      order.status == DriverOrderStatus.pickedUp ||
      order.status == DriverOrderStatus.onRouteToCustomer ||
      order.status == DriverOrderStatus.arrivedAtCustomer
    ).toList();
  }

  /// Get completed orders for a driver
  List<DriverOrder> getCompletedOrders(List<DriverOrder> orders) {
    return orders.where((order) => 
      order.status == DriverOrderStatus.delivered ||
      order.status == DriverOrderStatus.cancelled
    ).toList();
  }

  /// Get available orders for pickup
  List<DriverOrder> getAvailableOrders(List<DriverOrder> orders) {
    return orders.where((order) =>
      order.status == DriverOrderStatus.ready
      // Note: DriverOrder.assignedDriverId is never null as it's a getter for driverId
      // Available orders should be filtered at the data source level
    ).toList();
  }

  /// Accept an order
  Future<bool> acceptOrder(String orderId, String driverId) async {
    try {
      _logger.info('🚗 [DRIVER-ORDER-SERVICE] Accepting order $orderId for driver $driverId');
      
      await repository.acceptOrder(orderId, driverId);
      
      _logger.info('✅ [DRIVER-ORDER-SERVICE] Order $orderId accepted successfully');
      return true;
    } catch (e) {
      _logger.error('❌ [DRIVER-ORDER-SERVICE] Failed to accept order $orderId: $e');
      throw DriverException('Failed to accept order: ${e.toString()}', DriverErrorType.orderAcceptance);
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, DriverOrderStatus status) async {
    try {
      _logger.info('🚗 [DRIVER-ORDER-SERVICE] Updating order $orderId status to ${status.name}');
      
      await repository.updateOrderStatus(orderId, status);
      
      _logger.info('✅ [DRIVER-ORDER-SERVICE] Order $orderId status updated to ${status.name}');
      return true;
    } catch (e) {
      _logger.error('❌ [DRIVER-ORDER-SERVICE] Failed to update order $orderId status: $e');
      throw DriverException('Failed to update order status: ${e.toString()}', DriverErrorType.statusUpdate);
    }
  }

  /// Mark order as picked up
  Future<bool> markOrderPickedUp(String orderId) async {
    return updateOrderStatus(orderId, DriverOrderStatus.pickedUp);
  }

  /// Mark order as delivered
  Future<bool> markOrderDelivered(String orderId) async {
    return updateOrderStatus(orderId, DriverOrderStatus.delivered);
  }

  /// Cancel order
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      _logger.info('🚗 [DRIVER-ORDER-SERVICE] Cancelling order $orderId with reason: $reason');
      
      await repository.cancelOrder(orderId, reason);
      
      _logger.info('✅ [DRIVER-ORDER-SERVICE] Order $orderId cancelled successfully');
      return true;
    } catch (e) {
      _logger.error('❌ [DRIVER-ORDER-SERVICE] Failed to cancel order $orderId: $e');
      throw DriverException('Failed to cancel order: ${e.toString()}', DriverErrorType.orderCancellation);
    }
  }

  /// Get order details
  Future<DriverOrder?> getOrderDetails(String orderId) async {
    try {
      _logger.info('🚗 [DRIVER-ORDER-SERVICE] Getting order details for $orderId');
      
      final order = await repository.getOrderDetails(orderId);
      
      _logger.info('✅ [DRIVER-ORDER-SERVICE] Order details retrieved for $orderId');
      return order;
    } catch (e) {
      _logger.error('❌ [DRIVER-ORDER-SERVICE] Failed to get order details for $orderId: $e');
      throw DriverException('Failed to get order details: ${e.toString()}', DriverErrorType.dataFetch);
    }
  }

  /// Get driver's order history
  Future<List<DriverOrder>> getOrderHistory(String driverId, {int limit = 50}) async {
    try {
      _logger.info('🚗 [DRIVER-ORDER-SERVICE] Getting order history for driver $driverId');
      
      final orders = await repository.getDriverOrderHistory(driverId, limit: limit);
      
      _logger.info('✅ [DRIVER-ORDER-SERVICE] Retrieved ${orders.length} orders for driver $driverId');
      return orders;
    } catch (e) {
      _logger.error('❌ [DRIVER-ORDER-SERVICE] Failed to get order history for driver $driverId: $e');
      throw DriverException('Failed to get order history: ${e.toString()}', DriverErrorType.dataFetch);
    }
  }

  /// Get driver's earnings from orders
  Future<double> getDriverEarnings(String driverId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      _logger.info('🚗 [DRIVER-ORDER-SERVICE] Getting earnings for driver $driverId');
      
      final orders = await repository.getDriverOrderHistory(driverId);
      final completedOrders = orders.where((order) => order.status == DriverOrderStatus.delivered);
      
      double totalEarnings = 0.0;
      for (final order in completedOrders) {
        if (startDate != null && order.createdAt.isBefore(startDate)) continue;
        if (endDate != null && order.createdAt.isAfter(endDate)) continue;
        
        // Calculate earnings based on order value and commission
        totalEarnings += order.driverEarnings;
      }
      
      _logger.info('✅ [DRIVER-ORDER-SERVICE] Total earnings for driver $driverId: RM$totalEarnings');
      return totalEarnings;
    } catch (e) {
      _logger.error('❌ [DRIVER-ORDER-SERVICE] Failed to get earnings for driver $driverId: $e');
      throw DriverException('Failed to get driver earnings: ${e.toString()}', DriverErrorType.dataFetch);
    }
  }

  /// Validate order for acceptance
  bool canAcceptOrder(DriverOrder order, String driverId) {
    // Check if order is available
    if (order.status != DriverOrderStatus.ready) {
      return false;
    }

    // Check if order is already assigned to a different driver
    if (order.assignedDriverId != driverId) {
      return false;
    }

    // Additional business logic can be added here
    return true;
  }

  /// Get order statistics for driver
  Future<Map<String, dynamic>> getOrderStatistics(String driverId) async {
    try {
      _logger.info('🚗 [DRIVER-ORDER-SERVICE] Getting order statistics for driver $driverId');
      
      final orders = await repository.getDriverOrderHistory(driverId);
      
      final stats = {
        'total_orders': orders.length,
        'completed_orders': orders.where((o) => o.status == DriverOrderStatus.delivered).length,
        'cancelled_orders': orders.where((o) => o.status == DriverOrderStatus.cancelled).length,
        'total_earnings': orders
            .where((o) => o.status == DriverOrderStatus.delivered)
            .fold(0.0, (sum, order) => sum + order.driverEarnings),
        'average_rating': _calculateAverageRating(orders),
      };
      
      _logger.info('✅ [DRIVER-ORDER-SERVICE] Order statistics calculated for driver $driverId');
      return stats;
    } catch (e) {
      _logger.error('❌ [DRIVER-ORDER-SERVICE] Failed to get order statistics for driver $driverId: $e');
      throw DriverException('Failed to get order statistics: ${e.toString()}', DriverErrorType.dataFetch);
    }
  }

  /// Calculate average rating from completed orders
  double _calculateAverageRating(List<DriverOrder> orders) {
    final ratedOrders = orders.where((order) => 
      order.status == DriverOrderStatus.delivered && 
      order.driverRating != null
    ).toList();

    if (ratedOrders.isEmpty) return 0.0;

    final totalRating = ratedOrders.fold(0.0, (sum, order) => sum + (order.driverRating ?? 0.0));
    return totalRating / ratedOrders.length;
  }
}
