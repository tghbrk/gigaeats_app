
import '../../../drivers/data/models/driver_order.dart';

/// Enhanced state machine for driver order status transitions with validation and mandatory confirmations
class DriverOrderStateMachine {
  /// Valid status transitions map with granular workflow support
  static const Map<DriverOrderStatus, List<DriverOrderStatus>> _validTransitions = {
    // Initial state when order is ready for driver assignment
    DriverOrderStatus.assigned: [
      DriverOrderStatus.onRouteToVendor,
      DriverOrderStatus.cancelled,
    ],
    // Driver is navigating to vendor location
    DriverOrderStatus.onRouteToVendor: [
      DriverOrderStatus.arrivedAtVendor,
      DriverOrderStatus.cancelled,
    ],
    // Driver has arrived at vendor location
    DriverOrderStatus.arrivedAtVendor: [
      DriverOrderStatus.pickedUp, // Only after mandatory pickup confirmation
      DriverOrderStatus.cancelled,
    ],
    // Driver has picked up the order from vendor
    DriverOrderStatus.pickedUp: [
      DriverOrderStatus.onRouteToCustomer,
      DriverOrderStatus.cancelled,
    ],
    // Driver is navigating to customer location
    DriverOrderStatus.onRouteToCustomer: [
      DriverOrderStatus.arrivedAtCustomer,
      DriverOrderStatus.cancelled,
    ],
    // Driver has arrived at customer location
    DriverOrderStatus.arrivedAtCustomer: [
      DriverOrderStatus.delivered, // Only after mandatory delivery confirmation with photo
      DriverOrderStatus.cancelled,
    ],
    // Terminal states - no further transitions allowed
    DriverOrderStatus.delivered: [],
    DriverOrderStatus.cancelled: [],
    DriverOrderStatus.failed: [],
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

  /// Validate status transition with detailed error information
  static ValidationResult validateTransition(
    DriverOrderStatus from,
    DriverOrderStatus to,
  ) {
    if (!isValidTransition(from, to)) {
      return ValidationResult.invalid(
        'Invalid status transition from ${from.displayName} to ${to.displayName}. '
        'Valid transitions from ${from.displayName}: ${getValidNextStatuses(from).map((s) => s.displayName).join(', ')}',
      );
    }
    return ValidationResult.valid();
  }

  /// Check if a status requires mandatory confirmation before proceeding
  static bool requiresMandatoryConfirmation(DriverOrderStatus status) {
    switch (status) {
      case DriverOrderStatus.arrivedAtVendor:
        return true; // Must confirm pickup before proceeding
      case DriverOrderStatus.arrivedAtCustomer:
        return true; // Must capture delivery photo before completing
      default:
        return false;
    }
  }

  /// Get the type of confirmation required for a status
  static ConfirmationType? getRequiredConfirmationType(DriverOrderStatus status) {
    switch (status) {
      case DriverOrderStatus.arrivedAtVendor:
        return ConfirmationType.pickupConfirmation;
      case DriverOrderStatus.arrivedAtCustomer:
        return ConfirmationType.deliveryWithPhoto;
      default:
        return null;
    }
  }

  /// Get user-friendly description of status transition
  static String getTransitionDescription(
    DriverOrderStatus from,
    DriverOrderStatus to,
  ) {
    switch (to) {
      case DriverOrderStatus.assigned:
        return 'Order assigned to driver';
      case DriverOrderStatus.onRouteToVendor:
        return 'Driver started navigation to restaurant';
      case DriverOrderStatus.arrivedAtVendor:
        return 'Driver arrived at restaurant';
      case DriverOrderStatus.pickedUp:
        return 'Order picked up from restaurant';
      case DriverOrderStatus.onRouteToCustomer:
        return 'Driver started delivery to customer';
      case DriverOrderStatus.arrivedAtCustomer:
        return 'Driver arrived at customer location';
      case DriverOrderStatus.delivered:
        return 'Order delivered to customer';
      case DriverOrderStatus.cancelled:
        return 'Order cancelled';
      case DriverOrderStatus.failed:
        return 'Order delivery failed';
    }
  }

  /// Get detailed instructions for the driver at each status
  static String getDriverInstructions(DriverOrderStatus status) {
    switch (status) {
      case DriverOrderStatus.assigned:
        return 'Start navigation to the restaurant to pick up the order';
      case DriverOrderStatus.onRouteToVendor:
        return 'Navigate to the restaurant. Mark "Arrived" when you reach the location';
      case DriverOrderStatus.arrivedAtVendor:
        return 'Confirm pickup with the restaurant staff. You must verify the order before proceeding';
      case DriverOrderStatus.pickedUp:
        return 'Start navigation to the customer delivery address';
      case DriverOrderStatus.onRouteToCustomer:
        return 'Navigate to customer. Mark "Arrived" when you reach the delivery location';
      case DriverOrderStatus.arrivedAtCustomer:
        return 'Complete delivery by taking a photo of the delivered order. This is mandatory';
      case DriverOrderStatus.delivered:
        return 'Order completed successfully. You can now accept new orders';
      case DriverOrderStatus.cancelled:
        return 'Order was cancelled. You can now accept new orders';
      case DriverOrderStatus.failed:
        return 'Order delivery failed. Please contact support if needed';
    }
  }

  /// Check if status is terminal (no further transitions allowed)
  static bool isTerminalStatus(DriverOrderStatus status) {
    return status == DriverOrderStatus.delivered ||
           status == DriverOrderStatus.cancelled ||
           status == DriverOrderStatus.failed;
  }

  /// Check if status allows driver actions
  static bool allowsDriverActions(DriverOrderStatus status) {
    switch (status) {
      case DriverOrderStatus.assigned:
        return true; // Can start navigation to vendor
      case DriverOrderStatus.onRouteToVendor:
        return true; // Can mark arrived at vendor
      case DriverOrderStatus.arrivedAtVendor:
        return true; // Can confirm pickup (mandatory)
      case DriverOrderStatus.pickedUp:
        return true; // Can start navigation to customer
      case DriverOrderStatus.onRouteToCustomer:
        return true; // Can mark arrived at customer
      case DriverOrderStatus.arrivedAtCustomer:
        return true; // Can confirm delivery with photo (mandatory)
      case DriverOrderStatus.delivered:
      case DriverOrderStatus.cancelled:
      case DriverOrderStatus.failed:
        return false; // No actions allowed
    }
  }

  /// Check if the current status can be cancelled by the driver
  static bool canBeCancelledByDriver(DriverOrderStatus status) {
    switch (status) {
      case DriverOrderStatus.assigned:
      case DriverOrderStatus.onRouteToVendor:
      case DriverOrderStatus.arrivedAtVendor:
      case DriverOrderStatus.pickedUp:
      case DriverOrderStatus.onRouteToCustomer:
      case DriverOrderStatus.arrivedAtCustomer:
        return true;
      case DriverOrderStatus.delivered:
      case DriverOrderStatus.cancelled:
      case DriverOrderStatus.failed:
        return false;
    }
  }

  /// Get available actions for a status
  static List<DriverOrderAction> getAvailableActions(DriverOrderStatus status) {
    switch (status) {
      case DriverOrderStatus.assigned:
        return [DriverOrderAction.navigateToVendor, DriverOrderAction.cancel];
      case DriverOrderStatus.onRouteToVendor:
        return [DriverOrderAction.arrivedAtVendor, DriverOrderAction.cancel];
      case DriverOrderStatus.arrivedAtVendor:
        return [DriverOrderAction.confirmPickup, DriverOrderAction.cancel]; // Mandatory confirmation
      case DriverOrderStatus.pickedUp:
        return [DriverOrderAction.navigateToCustomer, DriverOrderAction.cancel];
      case DriverOrderStatus.onRouteToCustomer:
        return [DriverOrderAction.arrivedAtCustomer, DriverOrderAction.cancel];
      case DriverOrderStatus.arrivedAtCustomer:
        return [DriverOrderAction.confirmDeliveryWithPhoto, DriverOrderAction.cancel]; // Mandatory photo
      case DriverOrderStatus.delivered:
      case DriverOrderStatus.cancelled:
      case DriverOrderStatus.failed:
        return []; // No actions available
    }
  }

  /// Get the primary action for a status (the main action driver should take)
  static DriverOrderAction? getPrimaryAction(DriverOrderStatus status) {
    final actions = getAvailableActions(status);
    if (actions.isEmpty) return null;

    // Return the first non-cancel action as primary
    return actions.firstWhere(
      (action) => action != DriverOrderAction.cancel,
      orElse: () => actions.first,
    );
  }

  /// Check if an action requires special confirmation or validation
  static bool actionRequiresConfirmation(DriverOrderAction action) {
    switch (action) {
      case DriverOrderAction.confirmPickup:
      case DriverOrderAction.confirmDeliveryWithPhoto:
      case DriverOrderAction.cancel:
        return true;
      default:
        return false;
    }
  }
}

/// Enhanced driver order actions with mandatory confirmation support
enum DriverOrderAction {
  // Navigation actions
  navigateToVendor,
  arrivedAtVendor,
  navigateToCustomer,
  arrivedAtCustomer,

  // Mandatory confirmation actions
  confirmPickup,              // Mandatory pickup confirmation at vendor
  confirmDeliveryWithPhoto,   // Mandatory delivery confirmation with photo

  // Order management actions
  cancel,
  reportIssue,

  // Legacy actions for backward compatibility
  accept,
  reject,
  pickUp,
  markDelivered,
  startDelivery,
}

/// Types of confirmation required for certain actions
enum ConfirmationType {
  pickupConfirmation,     // Vendor pickup confirmation
  deliveryWithPhoto,      // Delivery confirmation with mandatory photo
  cancellation,           // Order cancellation confirmation
}

/// Validation result for status transitions
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._(this.isValid, this.errorMessage);

  factory ValidationResult.valid() => const ValidationResult._(true, null);
  factory ValidationResult.invalid(String message) => ValidationResult._(false, message);
}

/// Extension for driver order action display names and properties
extension DriverOrderActionExtension on DriverOrderAction {
  String get displayName {
    switch (this) {
      case DriverOrderAction.navigateToVendor:
        return 'Navigate to Restaurant';
      case DriverOrderAction.arrivedAtVendor:
        return 'Mark Arrived';
      case DriverOrderAction.confirmPickup:
        return 'Confirm Pickup';
      case DriverOrderAction.navigateToCustomer:
        return 'Navigate to Customer';
      case DriverOrderAction.arrivedAtCustomer:
        return 'Mark Arrived';
      case DriverOrderAction.confirmDeliveryWithPhoto:
        return 'Complete Delivery';
      case DriverOrderAction.cancel:
        return 'Cancel Order';
      case DriverOrderAction.reportIssue:
        return 'Report Issue';
      // Legacy actions
      case DriverOrderAction.accept:
        return 'Accept Order';
      case DriverOrderAction.reject:
        return 'Reject Order';
      case DriverOrderAction.pickUp:
        return 'Pick Up Order';
      case DriverOrderAction.markDelivered:
        return 'Mark Delivered';
      case DriverOrderAction.startDelivery:
        return 'Start Delivery';
    }
  }

  String get description {
    switch (this) {
      case DriverOrderAction.navigateToVendor:
        return 'Start GPS navigation to the restaurant';
      case DriverOrderAction.arrivedAtVendor:
        return 'Mark as arrived at the restaurant';
      case DriverOrderAction.confirmPickup:
        return 'Confirm order pickup with restaurant staff (mandatory)';
      case DriverOrderAction.navigateToCustomer:
        return 'Start GPS navigation to customer location';
      case DriverOrderAction.arrivedAtCustomer:
        return 'Mark as arrived at customer location';
      case DriverOrderAction.confirmDeliveryWithPhoto:
        return 'Complete delivery with photo proof (mandatory)';
      case DriverOrderAction.cancel:
        return 'Cancel this order';
      case DriverOrderAction.reportIssue:
        return 'Report an issue with this order';
      // Legacy actions
      case DriverOrderAction.accept:
        return 'Accept this order for delivery';
      case DriverOrderAction.reject:
        return 'Reject this order';
      case DriverOrderAction.pickUp:
        return 'Mark order as picked up from vendor';
      case DriverOrderAction.markDelivered:
        return 'Mark order as delivered to customer';
      case DriverOrderAction.startDelivery:
        return 'Start delivery to customer';
    }
  }

  DriverOrderStatus get targetStatus {
    switch (this) {
      case DriverOrderAction.navigateToVendor:
        return DriverOrderStatus.onRouteToVendor;
      case DriverOrderAction.arrivedAtVendor:
        return DriverOrderStatus.arrivedAtVendor;
      case DriverOrderAction.confirmPickup:
        return DriverOrderStatus.pickedUp;
      case DriverOrderAction.navigateToCustomer:
        return DriverOrderStatus.onRouteToCustomer;
      case DriverOrderAction.arrivedAtCustomer:
        return DriverOrderStatus.arrivedAtCustomer;
      case DriverOrderAction.confirmDeliveryWithPhoto:
        return DriverOrderStatus.delivered;
      case DriverOrderAction.cancel:
        return DriverOrderStatus.cancelled;
      case DriverOrderAction.reportIssue:
        return DriverOrderStatus.failed;
      // Legacy actions
      case DriverOrderAction.accept:
        return DriverOrderStatus.assigned;
      case DriverOrderAction.reject:
        return DriverOrderStatus.cancelled;
      case DriverOrderAction.pickUp:
        return DriverOrderStatus.pickedUp;
      case DriverOrderAction.markDelivered:
        return DriverOrderStatus.delivered;
      case DriverOrderAction.startDelivery:
        return DriverOrderStatus.onRouteToCustomer;
    }
  }

  /// Get the icon for this action
  String get iconName {
    switch (this) {
      case DriverOrderAction.navigateToVendor:
        return 'navigation';
      case DriverOrderAction.arrivedAtVendor:
        return 'location_on';
      case DriverOrderAction.confirmPickup:
        return 'check_circle';
      case DriverOrderAction.navigateToCustomer:
        return 'navigation';
      case DriverOrderAction.arrivedAtCustomer:
        return 'location_on';
      case DriverOrderAction.confirmDeliveryWithPhoto:
        return 'camera_alt';
      case DriverOrderAction.cancel:
        return 'cancel';
      case DriverOrderAction.reportIssue:
        return 'report_problem';
      // Legacy actions
      case DriverOrderAction.accept:
        return 'check';
      case DriverOrderAction.reject:
        return 'close';
      case DriverOrderAction.pickUp:
        return 'shopping_bag';
      case DriverOrderAction.markDelivered:
        return 'done';
      case DriverOrderAction.startDelivery:
        return 'local_shipping';
    }
  }

  /// Check if this action is considered dangerous and needs extra confirmation
  bool get isDangerous {
    switch (this) {
      case DriverOrderAction.cancel:
      case DriverOrderAction.reportIssue:
        return true;
      default:
        return false;
    }
  }
}
