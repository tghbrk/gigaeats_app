import 'package:json_annotation/json_annotation.dart';

/// Delivery method enumeration for GigaEats orders
enum DeliveryMethod {
  @JsonValue('customer_pickup')
  customerPickup,
  @JsonValue('sales_agent_pickup')
  salesAgentPickup,
  @JsonValue('own_fleet')
  ownFleet,
}

/// Extension methods for DeliveryMethod enum
extension DeliveryMethodExtension on DeliveryMethod {
  /// Get the string value of the delivery method
  String get value {
    switch (this) {
      case DeliveryMethod.customerPickup:
        return 'customer_pickup';
      case DeliveryMethod.salesAgentPickup:
        return 'sales_agent_pickup';
      case DeliveryMethod.ownFleet:
        return 'own_fleet';
    }
  }

  /// Get the display name of the delivery method
  String get displayName {
    switch (this) {
      case DeliveryMethod.customerPickup:
        return 'Customer Pickup';
      case DeliveryMethod.salesAgentPickup:
        return 'Sales Agent Pickup';
      case DeliveryMethod.ownFleet:
        return 'Own Fleet Delivery';
    }
  }

  /// Get the description of the delivery method
  String get description {
    switch (this) {
      case DeliveryMethod.customerPickup:
        return 'Customer will pick up the order from the vendor';
      case DeliveryMethod.salesAgentPickup:
        return 'Sales agent will pick up and deliver the order';
      case DeliveryMethod.ownFleet:
        return 'Delivered by our own delivery fleet';
    }
  }

  /// Get the icon name for the delivery method
  String get iconName {
    switch (this) {
      case DeliveryMethod.customerPickup:
        return 'store';
      case DeliveryMethod.salesAgentPickup:
        return 'person';
      case DeliveryMethod.ownFleet:
        return 'local_shipping';
    }
  }

  /// Check if delivery method requires driver assignment
  bool get requiresDriver {
    switch (this) {
      case DeliveryMethod.customerPickup:
        return false;
      case DeliveryMethod.salesAgentPickup:
        return false;
      case DeliveryMethod.ownFleet:
        return true;
    }
  }

  /// Check if delivery method has delivery fee
  bool get hasDeliveryFee {
    switch (this) {
      case DeliveryMethod.customerPickup:
        return false;
      case DeliveryMethod.salesAgentPickup:
        return false;
      case DeliveryMethod.ownFleet:
        return true;
    }
  }

  /// Check if delivery method supports tracking
  bool get supportsTracking {
    switch (this) {
      case DeliveryMethod.customerPickup:
        return false;
      case DeliveryMethod.salesAgentPickup:
        return true;
      case DeliveryMethod.ownFleet:
        return true;
    }
  }

  /// Get estimated delivery time in minutes
  int get estimatedDeliveryTimeMinutes {
    switch (this) {
      case DeliveryMethod.customerPickup:
        return 0; // No delivery time for pickup
      case DeliveryMethod.salesAgentPickup:
        return 45; // 45 minutes for sales agent pickup
      case DeliveryMethod.ownFleet:
        return 60; // 1 hour for own fleet delivery
    }
  }

  /// Get the priority level (lower number = higher priority)
  int get priority {
    switch (this) {
      case DeliveryMethod.ownFleet:
        return 1; // Highest priority
      case DeliveryMethod.salesAgentPickup:
        return 2; // Medium priority
      case DeliveryMethod.customerPickup:
        return 3; // Lowest priority
    }
  }
}

/// Helper class for delivery method operations
class DeliveryMethodHelper {
  /// Parse delivery method from string
  static DeliveryMethod? fromString(String? value) {
    if (value == null) return null;
    
    switch (value.toLowerCase()) {
      case 'customer_pickup':
        return DeliveryMethod.customerPickup;
      case 'sales_agent_pickup':
        return DeliveryMethod.salesAgentPickup;
      case 'own_fleet':
        return DeliveryMethod.ownFleet;
      default:
        return null;
    }
  }

  /// Get all available delivery methods
  static List<DeliveryMethod> get allMethods => DeliveryMethod.values;

  /// Get delivery methods that require driver assignment
  static List<DeliveryMethod> get methodsRequiringDriver =>
      DeliveryMethod.values.where((method) => method.requiresDriver).toList();

  /// Get delivery methods with delivery fee
  static List<DeliveryMethod> get methodsWithDeliveryFee =>
      DeliveryMethod.values.where((method) => method.hasDeliveryFee).toList();

  /// Get delivery methods that support tracking
  static List<DeliveryMethod> get methodsWithTracking =>
      DeliveryMethod.values.where((method) => method.supportsTracking).toList();

  /// Get delivery methods sorted by priority
  static List<DeliveryMethod> get methodsByPriority {
    final methods = List<DeliveryMethod>.from(DeliveryMethod.values);
    methods.sort((a, b) => a.priority.compareTo(b.priority));
    return methods;
  }

  /// Calculate delivery fee based on method and distance
  static double calculateDeliveryFee(DeliveryMethod method, {double? distanceKm}) {
    if (!method.hasDeliveryFee) return 0.0;

    switch (method) {
      case DeliveryMethod.ownFleet:
        // Base fee + distance-based fee
        const baseFee = 15.0; // RM 15 base fee
        const perKmFee = 2.0; // RM 2 per km
        final distance = distanceKm ?? 5.0; // Default 5km if not provided
        return baseFee + (distance * perKmFee);
      case DeliveryMethod.salesAgentPickup:
      case DeliveryMethod.customerPickup:
        return 0.0;
    }
  }

  /// Get available delivery methods for a vendor
  static List<DeliveryMethod> getAvailableMethodsForVendor({
    required bool hasOwnFleet,
    required bool allowsCustomerPickup,
    required bool allowsSalesAgentPickup,
  }) {
    final methods = <DeliveryMethod>[];

    if (allowsCustomerPickup) {
      methods.add(DeliveryMethod.customerPickup);
    }

    if (allowsSalesAgentPickup) {
      methods.add(DeliveryMethod.salesAgentPickup);
    }

    if (hasOwnFleet) {
      methods.add(DeliveryMethod.ownFleet);
    }

    return methods;
  }

  /// Check if delivery method is available for a specific order
  static bool isMethodAvailableForOrder({
    required DeliveryMethod method,
    required double orderAmount,
    required double? distanceKm,
    required bool vendorSupportsMethod,
  }) {
    if (!vendorSupportsMethod) return false;

    switch (method) {
      case DeliveryMethod.customerPickup:
        return true; // Always available if vendor supports it
      case DeliveryMethod.salesAgentPickup:
        return orderAmount >= 50.0; // Minimum order amount for sales agent pickup
      case DeliveryMethod.ownFleet:
        final distance = distanceKm ?? 0.0;
        return distance <= 50.0; // Maximum 50km for own fleet delivery
    }
  }
}
