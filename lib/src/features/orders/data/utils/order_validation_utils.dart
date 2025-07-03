import '../models/order.dart';
import '../models/delivery_method.dart';

/// Utility class for validating order status transitions and permissions
class OrderValidationUtils {
  /// Validates if a status transition is allowed based on business rules
  static bool isValidStatusTransition(OrderStatus currentStatus, OrderStatus newStatus) {
    // Allow same status (no change)
    if (currentStatus == newStatus) {
      return true;
    }
    
    // Define valid transitions based on documented workflow
    switch (currentStatus) {
      case OrderStatus.pending:
        // From pending: can go to confirmed (vendor accepts) or cancelled (vendor rejects)
        return newStatus == OrderStatus.confirmed || newStatus == OrderStatus.cancelled;
        
      case OrderStatus.confirmed:
        // From confirmed: can go to preparing (vendor starts) or cancelled
        return newStatus == OrderStatus.preparing || newStatus == OrderStatus.cancelled;
        
      case OrderStatus.preparing:
        // From preparing: can go to ready (vendor finishes) or cancelled
        return newStatus == OrderStatus.ready || newStatus == OrderStatus.cancelled;
        
      case OrderStatus.ready:
        // From ready: can go to out_for_delivery (dispatch) or delivered (pickup) or cancelled
        return newStatus == OrderStatus.outForDelivery || 
               newStatus == OrderStatus.delivered || 
               newStatus == OrderStatus.cancelled;
        
      case OrderStatus.outForDelivery:
        // From out_for_delivery: can go to delivered or cancelled
        return newStatus == OrderStatus.delivered || newStatus == OrderStatus.cancelled;
        
      case OrderStatus.delivered:
        // From delivered: no further transitions allowed (final state)
        return false;
        
      case OrderStatus.cancelled:
        // From cancelled: no further transitions allowed (final state)
        return false;
    }
  }
  
  /// Gets the list of valid next statuses for a given current status
  static List<OrderStatus> getValidNextStatuses(OrderStatus currentStatus) {
    switch (currentStatus) {
      case OrderStatus.pending:
        return [OrderStatus.confirmed, OrderStatus.cancelled];
        
      case OrderStatus.confirmed:
        return [OrderStatus.preparing, OrderStatus.cancelled];
        
      case OrderStatus.preparing:
        return [OrderStatus.ready, OrderStatus.cancelled];
        
      case OrderStatus.ready:
        return [OrderStatus.outForDelivery, OrderStatus.delivered, OrderStatus.cancelled];
        
      case OrderStatus.outForDelivery:
        return [OrderStatus.delivered, OrderStatus.cancelled];
        
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return []; // Final states - no further transitions
    }
  }
  
  /// Validates if a user role can update to a specific status
  static bool canUserRoleUpdateToStatus(String userRole, OrderStatus newStatus, {
    required bool isOrderOwner,
    required bool isVendorOrder,
    required bool isSalesAgentOrder,
    DeliveryMethod? deliveryMethod,
    OrderStatus? currentStatus,
  }) {
    switch (userRole.toLowerCase()) {
      case 'admin':
        // Admin can update any status
        return true;
        
      case 'vendor':
        // Vendors can only update their own orders to specific statuses
        if (!isVendorOrder) return false;
        return newStatus == OrderStatus.confirmed ||
               newStatus == OrderStatus.preparing ||
               newStatus == OrderStatus.ready ||
               newStatus == OrderStatus.cancelled;
        
      case 'sales_agent':
        // Sales agents can update their assigned orders to specific statuses
        if (!isSalesAgentOrder) return false;
        return newStatus == OrderStatus.outForDelivery ||
               newStatus == OrderStatus.delivered ||
               newStatus == OrderStatus.cancelled;
        
      case 'customer':
        // Customers can only mark pickup orders as delivered when they're ready
        if (newStatus == OrderStatus.delivered &&
            currentStatus == OrderStatus.ready &&
            (deliveryMethod == DeliveryMethod.customerPickup ||
             deliveryMethod == DeliveryMethod.salesAgentPickup)) {
          return true;
        }
        // All other status updates are not allowed for customers
        return false;
        
      default:
        return false;
    }
  }
  
  /// Gets user-friendly error message for invalid status transitions
  static String getStatusTransitionErrorMessage(OrderStatus currentStatus, OrderStatus newStatus) {
    if (currentStatus == OrderStatus.delivered || currentStatus == OrderStatus.cancelled) {
      return 'Cannot change status of ${currentStatus.displayName.toLowerCase()} orders.';
    }
    
    final validStatuses = getValidNextStatuses(currentStatus);
    final validStatusNames = validStatuses.map((s) => s.displayName).join(', ');
    
    return 'Cannot change status from ${currentStatus.displayName} to ${newStatus.displayName}. '
           'Valid next statuses are: $validStatusNames';
  }
  
  /// Gets user-friendly error message for permission issues
  static String getPermissionErrorMessage(String userRole, OrderStatus newStatus) {
    switch (userRole.toLowerCase()) {
      case 'vendor':
        return 'As a vendor, you can only confirm orders, start preparation, mark as ready, or cancel orders for your restaurant.';
        
      case 'sales_agent':
        return 'As a sales agent, you can only mark orders as out for delivery, delivered, or cancel your assigned orders.';
        
      case 'customer':
        return 'Customers cannot update order status. Please contact your sales agent for assistance.';
        
      default:
        return 'You do not have permission to update order status to ${newStatus.displayName}.';
    }
  }
  
  /// Validates complete order status update including transition and permissions
  static OrderValidationResult validateOrderStatusUpdate({
    required OrderStatus currentStatus,
    required OrderStatus newStatus,
    required String userRole,
    required bool isOrderOwner,
    required bool isVendorOrder,
    required bool isSalesAgentOrder,
    DeliveryMethod? deliveryMethod,
  }) {
    // Check if transition is valid
    if (!isValidStatusTransition(currentStatus, newStatus)) {
      return OrderValidationResult(
        isValid: false,
        errorMessage: getStatusTransitionErrorMessage(currentStatus, newStatus),
        errorType: OrderValidationErrorType.invalidTransition,
      );
    }
    
    // Check if user has permission
    if (!canUserRoleUpdateToStatus(
      userRole,
      newStatus,
      isOrderOwner: isOrderOwner,
      isVendorOrder: isVendorOrder,
      isSalesAgentOrder: isSalesAgentOrder,
      deliveryMethod: deliveryMethod,
      currentStatus: currentStatus,
    )) {
      return OrderValidationResult(
        isValid: false,
        errorMessage: getPermissionErrorMessage(userRole, newStatus),
        errorType: OrderValidationErrorType.insufficientPermissions,
      );
    }
    
    return OrderValidationResult(
      isValid: true,
      errorMessage: null,
      errorType: null,
    );
  }
  
  /// Gets the next logical status for a given current status (for UI suggestions)
  static OrderStatus? getNextLogicalStatus(OrderStatus currentStatus) {
    switch (currentStatus) {
      case OrderStatus.pending:
        return OrderStatus.confirmed;
      case OrderStatus.confirmed:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.outForDelivery;
      case OrderStatus.outForDelivery:
        return OrderStatus.delivered;
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return null; // Final states
    }
  }
}

/// Result of order validation
class OrderValidationResult {
  final bool isValid;
  final String? errorMessage;
  final OrderValidationErrorType? errorType;
  
  const OrderValidationResult({
    required this.isValid,
    this.errorMessage,
    this.errorType,
  });
}

/// Types of validation errors
enum OrderValidationErrorType {
  invalidTransition,
  insufficientPermissions,
  orderNotFound,
  networkError,
}
