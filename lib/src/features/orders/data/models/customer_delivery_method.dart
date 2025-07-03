import 'package:json_annotation/json_annotation.dart';

/// Customer delivery method enumeration for GigaEats orders
enum CustomerDeliveryMethod {
  @JsonValue('customer_pickup')
  customerPickup,
  @JsonValue('sales_agent_pickup')
  salesAgentPickup,
  @JsonValue('own_fleet')
  ownFleet,
  @JsonValue('lalamove')
  lalamove,
  @JsonValue('third_party')
  thirdParty,
  @JsonValue('pickup')
  pickup,
  @JsonValue('delivery')
  delivery,
  @JsonValue('scheduled')
  scheduled,
}

/// Extension methods for CustomerDeliveryMethod enum
extension CustomerDeliveryMethodExtension on CustomerDeliveryMethod {
  /// Get the string value of the delivery method
  String get value {
    switch (this) {
      case CustomerDeliveryMethod.customerPickup:
        return 'customer_pickup';
      case CustomerDeliveryMethod.salesAgentPickup:
        return 'sales_agent_pickup';
      case CustomerDeliveryMethod.ownFleet:
        return 'own_fleet';
      case CustomerDeliveryMethod.lalamove:
        return 'lalamove';
      case CustomerDeliveryMethod.thirdParty:
        return 'third_party';
      case CustomerDeliveryMethod.pickup:
        return 'pickup';
      case CustomerDeliveryMethod.delivery:
        return 'delivery';
      case CustomerDeliveryMethod.scheduled:
        return 'scheduled';
    }
  }

  /// Get the display name of the delivery method
  String get displayName {
    switch (this) {
      case CustomerDeliveryMethod.customerPickup:
        return 'Customer Pickup';
      case CustomerDeliveryMethod.salesAgentPickup:
        return 'Sales Agent Pickup';
      case CustomerDeliveryMethod.ownFleet:
        return 'Own Fleet Delivery';
      case CustomerDeliveryMethod.lalamove:
        return 'Lalamove Delivery';
      case CustomerDeliveryMethod.thirdParty:
        return 'Third Party Delivery';
      case CustomerDeliveryMethod.pickup:
        return 'Pickup';
      case CustomerDeliveryMethod.delivery:
        return 'Delivery';
      case CustomerDeliveryMethod.scheduled:
        return 'Scheduled Delivery';
    }
  }

  /// Get the description of the delivery method
  String get description {
    switch (this) {
      case CustomerDeliveryMethod.customerPickup:
        return 'Customer will pick up the order from the vendor';
      case CustomerDeliveryMethod.salesAgentPickup:
        return 'Sales agent will pick up and deliver the order';
      case CustomerDeliveryMethod.ownFleet:
        return 'Delivered by our own delivery fleet';
      case CustomerDeliveryMethod.lalamove:
        return 'Delivered by Lalamove service';
      case CustomerDeliveryMethod.thirdParty:
        return 'Delivered by third-party service';
      case CustomerDeliveryMethod.pickup:
        return 'Pickup order';
      case CustomerDeliveryMethod.delivery:
        return 'Delivery order';
      case CustomerDeliveryMethod.scheduled:
        return 'Scheduled delivery';
    }
  }

  /// Get the icon name for the delivery method
  String get iconName {
    switch (this) {
      case CustomerDeliveryMethod.customerPickup:
        return 'store';
      case CustomerDeliveryMethod.salesAgentPickup:
        return 'person';
      case CustomerDeliveryMethod.ownFleet:
        return 'local_shipping';
      case CustomerDeliveryMethod.lalamove:
        return 'delivery_dining';
      case CustomerDeliveryMethod.thirdParty:
        return 'local_shipping';
      case CustomerDeliveryMethod.pickup:
        return 'store';
      case CustomerDeliveryMethod.delivery:
        return 'local_shipping';
      case CustomerDeliveryMethod.scheduled:
        return 'schedule';
    }
  }

  /// Check if delivery method requires driver assignment
  bool get requiresDriver {
    switch (this) {
      case CustomerDeliveryMethod.customerPickup:
      case CustomerDeliveryMethod.salesAgentPickup:
      case CustomerDeliveryMethod.pickup:
        return false;
      case CustomerDeliveryMethod.ownFleet:
      case CustomerDeliveryMethod.lalamove:
      case CustomerDeliveryMethod.thirdParty:
      case CustomerDeliveryMethod.delivery:
      case CustomerDeliveryMethod.scheduled:
        return true;
    }
  }

  /// Check if delivery method supports real-time tracking
  bool get supportsTracking {
    switch (this) {
      case CustomerDeliveryMethod.customerPickup:
      case CustomerDeliveryMethod.pickup:
        return false;
      case CustomerDeliveryMethod.salesAgentPickup:
      case CustomerDeliveryMethod.ownFleet:
      case CustomerDeliveryMethod.lalamove:
      case CustomerDeliveryMethod.thirdParty:
      case CustomerDeliveryMethod.delivery:
      case CustomerDeliveryMethod.scheduled:
        return true;
    }
  }

  /// Get estimated delivery time in minutes
  int get estimatedDeliveryTimeMinutes {
    switch (this) {
      case CustomerDeliveryMethod.customerPickup:
      case CustomerDeliveryMethod.pickup:
        return 0; // No delivery time for pickup
      case CustomerDeliveryMethod.salesAgentPickup:
        return 45; // Sales agent pickup and delivery
      case CustomerDeliveryMethod.ownFleet:
        return 30; // Own fleet delivery
      case CustomerDeliveryMethod.lalamove:
        return 60; // Lalamove delivery
      case CustomerDeliveryMethod.thirdParty:
        return 45; // Third party delivery
      case CustomerDeliveryMethod.delivery:
        return 35; // Standard delivery
      case CustomerDeliveryMethod.scheduled:
        return 0; // Scheduled delivery time varies
    }
  }

  /// Get delivery fee multiplier (base fee * multiplier)
  double get feeMultiplier {
    switch (this) {
      case CustomerDeliveryMethod.customerPickup:
      case CustomerDeliveryMethod.pickup:
        return 0.0; // No delivery fee for pickup
      case CustomerDeliveryMethod.salesAgentPickup:
        return 0.8; // Reduced fee for sales agent
      case CustomerDeliveryMethod.ownFleet:
        return 1.0; // Standard fee
      case CustomerDeliveryMethod.lalamove:
        return 1.5; // Higher fee for Lalamove
      case CustomerDeliveryMethod.thirdParty:
        return 1.2; // Slightly higher fee for third party
      case CustomerDeliveryMethod.delivery:
        return 1.0; // Standard delivery fee
      case CustomerDeliveryMethod.scheduled:
        return 1.1; // Slightly higher for scheduled delivery
    }
  }

  /// Check if delivery method is available for customer orders
  bool get isAvailableForCustomers => true;

  /// Check if delivery method is available for sales agent orders
  bool get isAvailableForSalesAgents {
    switch (this) {
      case CustomerDeliveryMethod.customerPickup:
      case CustomerDeliveryMethod.salesAgentPickup:
      case CustomerDeliveryMethod.ownFleet:
      case CustomerDeliveryMethod.pickup:
      case CustomerDeliveryMethod.delivery:
      case CustomerDeliveryMethod.scheduled:
        return true;
      case CustomerDeliveryMethod.lalamove:
      case CustomerDeliveryMethod.thirdParty:
        return false; // Sales agents typically don't use external services
    }
  }

  /// Get color for UI representation
  String get colorHex {
    switch (this) {
      case CustomerDeliveryMethod.customerPickup:
      case CustomerDeliveryMethod.pickup:
        return '#4CAF50'; // Green
      case CustomerDeliveryMethod.salesAgentPickup:
        return '#2196F3'; // Blue
      case CustomerDeliveryMethod.ownFleet:
        return '#FF9800'; // Orange
      case CustomerDeliveryMethod.lalamove:
        return '#E91E63'; // Pink
      case CustomerDeliveryMethod.thirdParty:
        return '#9C27B0'; // Purple
      case CustomerDeliveryMethod.delivery:
        return '#607D8B'; // Blue Grey
      case CustomerDeliveryMethod.scheduled:
        return '#795548'; // Brown
    }
  }
}

/// Helper class for CustomerDeliveryMethod operations
class CustomerDeliveryMethodHelper {
  /// Parse delivery method from string
  static CustomerDeliveryMethod fromString(String value) {
    return CustomerDeliveryMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => CustomerDeliveryMethod.customerPickup,
    );
  }

  /// Get all available delivery methods for customers
  static List<CustomerDeliveryMethod> getAvailableForCustomers() {
    return CustomerDeliveryMethod.values
        .where((method) => method.isAvailableForCustomers)
        .toList();
  }

  /// Get all available delivery methods for sales agents
  static List<CustomerDeliveryMethod> getAvailableForSalesAgents() {
    return CustomerDeliveryMethod.values
        .where((method) => method.isAvailableForSalesAgents)
        .toList();
  }

  /// Get delivery methods that require driver assignment
  static List<CustomerDeliveryMethod> getMethodsRequiringDriver() {
    return CustomerDeliveryMethod.values
        .where((method) => method.requiresDriver)
        .toList();
  }

  /// Get delivery methods that support tracking
  static List<CustomerDeliveryMethod> getMethodsWithTracking() {
    return CustomerDeliveryMethod.values
        .where((method) => method.supportsTracking)
        .toList();
  }

  /// Calculate delivery fee based on method and base fee
  static double calculateDeliveryFee(
    CustomerDeliveryMethod method,
    double baseFee,
  ) {
    return baseFee * method.feeMultiplier;
  }

  /// Get estimated delivery time for method
  static Duration getEstimatedDeliveryTime(CustomerDeliveryMethod method) {
    return Duration(minutes: method.estimatedDeliveryTimeMinutes);
  }
}
