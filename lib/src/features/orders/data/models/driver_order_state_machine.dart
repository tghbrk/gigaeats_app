import '../../data/models/driver_order.dart';
// TODO: Create driver_error.dart file with DriverResult, DriverException, DriverErrorType classes
// import 'driver_error.dart';

/// State machine for driver order status transitions
class DriverOrderStateMachine {
  /// Valid status transitions map
  static const Map<DriverOrderStatus, List<DriverOrderStatus>> _validTransitions = {
    DriverOrderStatus.available: [
      DriverOrderStatus.assigned,
    ],
    DriverOrderStatus.assigned: [
      DriverOrderStatus.onRouteToVendor,
      DriverOrderStatus.cancelled,
    ],
    DriverOrderStatus.onRouteToVendor: [
      DriverOrderStatus.arrivedAtVendor,
      DriverOrderStatus.cancelled,
    ],
    DriverOrderStatus.arrivedAtVendor: [
      DriverOrderStatus.pickedUp,
      DriverOrderStatus.cancelled,
    ],
    DriverOrderStatus.pickedUp: [
      DriverOrderStatus.onRouteToCustomer,
      DriverOrderStatus.cancelled,
    ],
    DriverOrderStatus.onRouteToCustomer: [
      DriverOrderStatus.arrivedAtCustomer,
      DriverOrderStatus.cancelled,
    ],
    DriverOrderStatus.arrivedAtCustomer: [
      DriverOrderStatus.delivered,
      DriverOrderStatus.cancelled,
    ],
    DriverOrderStatus.delivered: [
      // Terminal state - no transitions allowed
    ],
    DriverOrderStatus.cancelled: [
      // Terminal state - no transitions allowed
    ],
  };

  /// Check if a status transition is valid
  static bool isValidTransition(
    DriverOrderStatus from,
    DriverOrderStatus to,
  ) {
    final allowedTransitions = _validTransitions[from] ?? [];
    return allowedTransitions.contains(to);
  }

  /// Get all valid next statuses for a given status
  static List<DriverOrderStatus> getValidNextStatuses(DriverOrderStatus current) {
    return _validTransitions[current] ?? [];
  }

  /// Validate and perform status transition
  /// TODO: Restore when DriverResult, DriverException, DriverErrorType are implemented
  static bool validateTransition(
    DriverOrderStatus from,
    DriverOrderStatus to,
  ) {
    return isValidTransition(from, to);
    // if (!isValidTransition(from, to)) {
    //   return DriverResult.error(
    //     DriverException(
    //       'Invalid status transition from ${from.displayName} to ${to.displayName}',
    //       DriverErrorType.invalidStatus,
    //     ),
    //   );
    // }
    // return DriverResult.success(to);
  }

  /// Get user-friendly description of status transition
  static String getTransitionDescription(
    DriverOrderStatus from,
    DriverOrderStatus to,
  ) {
    switch (to) {
      case DriverOrderStatus.assigned:
        return 'Order assigned to driver';
      case DriverOrderStatus.ready:
        return 'Order ready for pickup';
      case DriverOrderStatus.onRouteToVendor:
        return 'Driver en route to pickup location';
      case DriverOrderStatus.arrivedAtVendor:
        return 'Driver arrived at pickup location';
      case DriverOrderStatus.pickedUp:
        return 'Order picked up from vendor';
      case DriverOrderStatus.onRouteToCustomer:
        return 'Driver en route to customer';
      case DriverOrderStatus.arrivedAtCustomer:
        return 'Driver arrived at customer location';
      case DriverOrderStatus.delivered:
        return 'Order delivered to customer';
      case DriverOrderStatus.cancelled:
        return 'Order cancelled';
      case DriverOrderStatus.available:
        return 'Order available for pickup';
    }
  }

  /// Check if status is terminal (no further transitions allowed)
  static bool isTerminalStatus(DriverOrderStatus status) {
    return status == DriverOrderStatus.delivered || 
           status == DriverOrderStatus.cancelled;
  }

  /// Check if status allows driver actions
  static bool allowsDriverActions(DriverOrderStatus status) {
    switch (status) {
      case DriverOrderStatus.available:
        return true; // Can accept/reject
      case DriverOrderStatus.assigned:
        return true; // Can start navigation to vendor
      case DriverOrderStatus.ready:
        return true; // Can accept order for pickup
      case DriverOrderStatus.onRouteToVendor:
        return true; // Can mark arrived at vendor
      case DriverOrderStatus.arrivedAtVendor:
        return true; // Can pick up
      case DriverOrderStatus.pickedUp:
        return true; // Can start navigation to customer
      case DriverOrderStatus.onRouteToCustomer:
        return true; // Can mark arrived at customer
      case DriverOrderStatus.arrivedAtCustomer:
        return true; // Can mark delivered
      case DriverOrderStatus.delivered:
      case DriverOrderStatus.cancelled:
        return false; // No actions allowed
    }
  }

  /// Get available actions for a status
  static List<DriverOrderAction> getAvailableActions(DriverOrderStatus status) {
    switch (status) {
      case DriverOrderStatus.available:
        return [DriverOrderAction.accept, DriverOrderAction.reject];
      case DriverOrderStatus.assigned:
        return [DriverOrderAction.navigateToVendor, DriverOrderAction.cancel];
      case DriverOrderStatus.ready:
        return [DriverOrderAction.accept, DriverOrderAction.reject];
      case DriverOrderStatus.onRouteToVendor:
        return [DriverOrderAction.arrivedAtVendor, DriverOrderAction.cancel];
      case DriverOrderStatus.arrivedAtVendor:
        return [DriverOrderAction.pickUp, DriverOrderAction.cancel];
      case DriverOrderStatus.pickedUp:
        return [DriverOrderAction.navigateToCustomer, DriverOrderAction.cancel];
      case DriverOrderStatus.onRouteToCustomer:
        return [DriverOrderAction.arrivedAtCustomer, DriverOrderAction.cancel];
      case DriverOrderStatus.arrivedAtCustomer:
        return [DriverOrderAction.markDelivered, DriverOrderAction.cancel];
      case DriverOrderStatus.delivered:
      case DriverOrderStatus.cancelled:
        return []; // No actions available
    }
  }
}

/// Available actions for driver orders
enum DriverOrderAction {
  accept,
  reject,
  navigateToVendor,
  arrivedAtVendor,
  pickUp,
  navigateToCustomer,
  arrivedAtCustomer,
  markDelivered,
  cancel,
  // Legacy actions for backward compatibility
  startDelivery,
}

/// Extension for driver order action display names
extension DriverOrderActionExtension on DriverOrderAction {
  String get displayName {
    switch (this) {
      case DriverOrderAction.accept:
        return 'Accept Order';
      case DriverOrderAction.reject:
        return 'Reject Order';
      case DriverOrderAction.navigateToVendor:
        return 'Navigate to Pickup';
      case DriverOrderAction.arrivedAtVendor:
        return 'Arrived at Pickup';
      case DriverOrderAction.pickUp:
        return 'Pick Up Order';
      case DriverOrderAction.navigateToCustomer:
        return 'Navigate to Customer';
      case DriverOrderAction.arrivedAtCustomer:
        return 'Arrived at Customer';
      case DriverOrderAction.markDelivered:
        return 'Mark Delivered';
      case DriverOrderAction.cancel:
        return 'Cancel Order';
      case DriverOrderAction.startDelivery:
        return 'Start Delivery'; // Legacy
    }
  }

  String get description {
    switch (this) {
      case DriverOrderAction.accept:
        return 'Accept this order for delivery';
      case DriverOrderAction.reject:
        return 'Reject this order';
      case DriverOrderAction.navigateToVendor:
        return 'Start navigation to pickup location';
      case DriverOrderAction.arrivedAtVendor:
        return 'Mark as arrived at pickup location';
      case DriverOrderAction.pickUp:
        return 'Mark order as picked up from vendor';
      case DriverOrderAction.navigateToCustomer:
        return 'Start navigation to customer location';
      case DriverOrderAction.arrivedAtCustomer:
        return 'Mark as arrived at customer location';
      case DriverOrderAction.markDelivered:
        return 'Mark order as delivered to customer';
      case DriverOrderAction.cancel:
        return 'Cancel this order';
      case DriverOrderAction.startDelivery:
        return 'Start delivery to customer'; // Legacy
    }
  }

  DriverOrderStatus get targetStatus {
    switch (this) {
      case DriverOrderAction.accept:
        return DriverOrderStatus.assigned;
      case DriverOrderAction.reject:
        return DriverOrderStatus.cancelled;
      case DriverOrderAction.navigateToVendor:
        return DriverOrderStatus.onRouteToVendor;
      case DriverOrderAction.arrivedAtVendor:
        return DriverOrderStatus.arrivedAtVendor;
      case DriverOrderAction.pickUp:
        return DriverOrderStatus.pickedUp;
      case DriverOrderAction.navigateToCustomer:
        return DriverOrderStatus.onRouteToCustomer;
      case DriverOrderAction.arrivedAtCustomer:
        return DriverOrderStatus.arrivedAtCustomer;
      case DriverOrderAction.markDelivered:
        return DriverOrderStatus.delivered;
      case DriverOrderAction.cancel:
        return DriverOrderStatus.cancelled;
      case DriverOrderAction.startDelivery:
        return DriverOrderStatus.onRouteToCustomer; // Legacy - maps to new status
    }
  }
}
