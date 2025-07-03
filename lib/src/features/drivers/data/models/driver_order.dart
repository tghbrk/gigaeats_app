import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'driver_order.g.dart';

/// Driver order status enumeration with granular tracking
enum DriverOrderStatus {
  @JsonValue('assigned')
  assigned,
  @JsonValue('on_route_to_vendor')
  onRouteToVendor,
  @JsonValue('arrived_at_vendor')
  arrivedAtVendor,
  @JsonValue('picked_up')
  pickedUp,
  @JsonValue('on_route_to_customer')
  onRouteToCustomer,
  @JsonValue('arrived_at_customer')
  arrivedAtCustomer,
  @JsonValue('delivered')
  delivered,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('failed')
  failed;

  /// Get display name for the status
  String get displayName {
    switch (this) {
      case DriverOrderStatus.assigned:
        return 'Assigned';
      case DriverOrderStatus.onRouteToVendor:
        return 'On Route to Restaurant';
      case DriverOrderStatus.arrivedAtVendor:
        return 'Arrived at Restaurant';
      case DriverOrderStatus.pickedUp:
        return 'Order Picked Up';
      case DriverOrderStatus.onRouteToCustomer:
        return 'On Route to Customer';
      case DriverOrderStatus.arrivedAtCustomer:
        return 'Arrived at Customer';
      case DriverOrderStatus.delivered:
        return 'Delivered';
      case DriverOrderStatus.cancelled:
        return 'Cancelled';
      case DriverOrderStatus.failed:
        return 'Failed';
    }
  }

  /// Get string value for the status
  String get value {
    switch (this) {
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
        return 'failed';
    }
  }
}

/// Driver order action enumeration
enum DriverOrderAction {
  accept,
  reject,
  startRoute,
  arriveAtVendor,
  pickupOrder,
  startDelivery,
  arriveAtCustomer,
  completeDelivery,
  reportIssue,
  cancel,
}

/// Driver order priority enumeration
enum DriverOrderPriority {
  @JsonValue('low')
  low,
  @JsonValue('normal')
  normal,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

/// Location tracking model
@JsonSerializable()
class LocationPoint extends Equatable {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy; // in meters
  final double? speed; // in m/s
  final double? heading; // in degrees

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.speed,
    this.heading,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) => _$LocationPointFromJson(json);
  Map<String, dynamic> toJson() => _$LocationPointToJson(this);

  @override
  List<Object?> get props => [latitude, longitude, timestamp, accuracy, speed, heading];
}

/// Driver order delivery details
@JsonSerializable()
class DeliveryDetails extends Equatable {
  @JsonKey(name: 'pickup_address')
  final String pickupAddress;
  @JsonKey(name: 'pickup_latitude')
  final double? pickupLatitude;
  @JsonKey(name: 'pickup_longitude')
  final double? pickupLongitude;
  @JsonKey(name: 'delivery_address')
  final String deliveryAddress;
  @JsonKey(name: 'delivery_latitude')
  final double? deliveryLatitude;
  @JsonKey(name: 'delivery_longitude')
  final double? deliveryLongitude;
  @JsonKey(name: 'estimated_distance')
  final double? estimatedDistance; // in kilometers
  @JsonKey(name: 'estimated_duration')
  final int? estimatedDuration; // in minutes
  @JsonKey(name: 'special_instructions')
  final String? specialInstructions;
  @JsonKey(name: 'contact_phone')
  final String? contactPhone;

  const DeliveryDetails({
    required this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    required this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.estimatedDistance,
    this.estimatedDuration,
    this.specialInstructions,
    this.contactPhone,
  });

  factory DeliveryDetails.fromJson(Map<String, dynamic> json) => _$DeliveryDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$DeliveryDetailsToJson(this);

  @override
  List<Object?> get props => [
        pickupAddress,
        pickupLatitude,
        pickupLongitude,
        deliveryAddress,
        deliveryLatitude,
        deliveryLongitude,
        estimatedDistance,
        estimatedDuration,
        specialInstructions,
        contactPhone,
      ];
}

/// Driver order earnings breakdown
@JsonSerializable()
class OrderEarnings extends Equatable {
  @JsonKey(name: 'base_fee')
  final double baseFee;
  @JsonKey(name: 'distance_fee')
  final double distanceFee;
  @JsonKey(name: 'time_bonus')
  final double timeBonus;
  @JsonKey(name: 'peak_hour_bonus')
  final double peakHourBonus;
  @JsonKey(name: 'tip_amount')
  final double tipAmount;
  @JsonKey(name: 'total_earnings')
  final double totalEarnings;

  const OrderEarnings({
    required this.baseFee,
    this.distanceFee = 0.0,
    this.timeBonus = 0.0,
    this.peakHourBonus = 0.0,
    this.tipAmount = 0.0,
    required this.totalEarnings,
  });

  factory OrderEarnings.fromJson(Map<String, dynamic> json) => _$OrderEarningsFromJson(json);
  Map<String, dynamic> toJson() => _$OrderEarningsToJson(this);

  @override
  List<Object?> get props => [baseFee, distanceFee, timeBonus, peakHourBonus, tipAmount, totalEarnings];
}

/// Main Driver Order model
@JsonSerializable()
class DriverOrder extends Equatable {
  final String id;
  @JsonKey(name: 'order_id')
  final String orderId;
  @JsonKey(name: 'driver_id')
  final String driverId;
  @JsonKey(name: 'vendor_id')
  final String vendorId;
  @JsonKey(name: 'vendor_name')
  final String vendorName;
  @JsonKey(name: 'customer_id')
  final String customerId;
  @JsonKey(name: 'customer_name')
  final String customerName;
  final DriverOrderStatus status;
  final DriverOrderPriority priority;
  @JsonKey(name: 'delivery_details')
  final DeliveryDetails deliveryDetails;
  @JsonKey(name: 'order_earnings')
  final OrderEarnings orderEarnings;
  @JsonKey(name: 'order_items_count')
  final int orderItemsCount;
  @JsonKey(name: 'order_total')
  final double orderTotal;
  @JsonKey(name: 'payment_method')
  final String? paymentMethod;
  @JsonKey(name: 'requires_cash_collection')
  final bool requiresCashCollection;

  // Timing fields
  @JsonKey(name: 'assigned_at')
  final DateTime assignedAt;
  @JsonKey(name: 'accepted_at')
  final DateTime? acceptedAt;
  @JsonKey(name: 'started_route_at')
  final DateTime? startedRouteAt;
  @JsonKey(name: 'arrived_at_vendor_at')
  final DateTime? arrivedAtVendorAt;
  @JsonKey(name: 'picked_up_at')
  final DateTime? pickedUpAt;
  @JsonKey(name: 'started_delivery_at')
  final DateTime? startedDeliveryAt;
  @JsonKey(name: 'arrived_at_customer_at')
  final DateTime? arrivedAtCustomerAt;
  @JsonKey(name: 'delivered_at')
  final DateTime? deliveredAt;
  @JsonKey(name: 'cancelled_at')
  final DateTime? cancelledAt;

  // Tracking
  @JsonKey(name: 'current_location')
  final LocationPoint? currentLocation;
  @JsonKey(name: 'tracking_points')
  final List<LocationPoint> trackingPoints;

  // Additional fields
  @JsonKey(name: 'delivery_notes')
  final String? deliveryNotes;
  @JsonKey(name: 'customer_rating')
  final double? customerRating;
  @JsonKey(name: 'customer_feedback')
  final String? customerFeedback;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const DriverOrder({
    required this.id,
    required this.orderId,
    required this.driverId,
    required this.vendorId,
    required this.vendorName,
    required this.customerId,
    required this.customerName,
    required this.status,
    this.priority = DriverOrderPriority.normal,
    required this.deliveryDetails,
    required this.orderEarnings,
    required this.orderItemsCount,
    required this.orderTotal,
    this.paymentMethod,
    this.requiresCashCollection = false,
    required this.assignedAt,
    this.acceptedAt,
    this.startedRouteAt,
    this.arrivedAtVendorAt,
    this.pickedUpAt,
    this.startedDeliveryAt,
    this.arrivedAtCustomerAt,
    this.deliveredAt,
    this.cancelledAt,
    this.currentLocation,
    this.trackingPoints = const [],
    this.deliveryNotes,
    this.customerRating,
    this.customerFeedback,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverOrder.fromJson(Map<String, dynamic> json) => _$DriverOrderFromJson(json);
  Map<String, dynamic> toJson() => _$DriverOrderToJson(this);

  @override
  List<Object?> get props => [
        id,
        orderId,
        driverId,
        vendorId,
        vendorName,
        customerId,
        customerName,
        status,
        priority,
        deliveryDetails,
        orderEarnings,
        orderItemsCount,
        orderTotal,
        paymentMethod,
        requiresCashCollection,
        assignedAt,
        acceptedAt,
        startedRouteAt,
        arrivedAtVendorAt,
        pickedUpAt,
        startedDeliveryAt,
        arrivedAtCustomerAt,
        deliveredAt,
        cancelledAt,
        currentLocation,
        trackingPoints,
        deliveryNotes,
        customerRating,
        customerFeedback,
        metadata,
        createdAt,
        updatedAt,
      ];

  /// Check if order is completed
  bool get isCompleted => status == DriverOrderStatus.delivered;

  /// Check if order is cancelled
  bool get isCancelled => status == DriverOrderStatus.cancelled || status == DriverOrderStatus.failed;

  /// Check if order is in progress
  bool get isInProgress => !isCompleted && !isCancelled;

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case DriverOrderStatus.assigned:
        return 'Assigned';
      case DriverOrderStatus.onRouteToVendor:
        return 'On Route to Restaurant';
      case DriverOrderStatus.arrivedAtVendor:
        return 'Arrived at Restaurant';
      case DriverOrderStatus.pickedUp:
        return 'Order Picked Up';
      case DriverOrderStatus.onRouteToCustomer:
        return 'On Route to Customer';
      case DriverOrderStatus.arrivedAtCustomer:
        return 'Arrived at Customer';
      case DriverOrderStatus.delivered:
        return 'Delivered';
      case DriverOrderStatus.cancelled:
        return 'Cancelled';
      case DriverOrderStatus.failed:
        return 'Failed';
    }
  }

  /// Get available actions for current status
  List<DriverOrderAction> get availableActions {
    switch (status) {
      case DriverOrderStatus.assigned:
        return [DriverOrderAction.accept, DriverOrderAction.reject];
      case DriverOrderStatus.onRouteToVendor:
        return [DriverOrderAction.arriveAtVendor, DriverOrderAction.reportIssue];
      case DriverOrderStatus.arrivedAtVendor:
        return [DriverOrderAction.pickupOrder, DriverOrderAction.reportIssue];
      case DriverOrderStatus.pickedUp:
        return [DriverOrderAction.startDelivery, DriverOrderAction.reportIssue];
      case DriverOrderStatus.onRouteToCustomer:
        return [DriverOrderAction.arriveAtCustomer, DriverOrderAction.reportIssue];
      case DriverOrderStatus.arrivedAtCustomer:
        return [DriverOrderAction.completeDelivery, DriverOrderAction.reportIssue];
      case DriverOrderStatus.delivered:
      case DriverOrderStatus.cancelled:
      case DriverOrderStatus.failed:
        return [];
    }
  }

  /// Calculate total delivery time
  Duration? get totalDeliveryTime {
    if (acceptedAt != null && deliveredAt != null) {
      return deliveredAt!.difference(acceptedAt!);
    }
    return null;
  }

  /// Calculate pickup time (time spent at vendor)
  Duration? get pickupTime {
    if (arrivedAtVendorAt != null && pickedUpAt != null) {
      return pickedUpAt!.difference(arrivedAtVendorAt!);
    }
    return null;
  }

  /// Calculate delivery time (time from pickup to delivery)
  Duration? get deliveryTime {
    if (pickedUpAt != null && deliveredAt != null) {
      return deliveredAt!.difference(pickedUpAt!);
    }
    return null;
  }

  // Convenience getters for accessing nested properties

  /// Get assigned driver ID (same as driverId)
  String get assignedDriverId => driverId;

  /// Get driver earnings (total earnings from order)
  double get driverEarnings => orderEarnings.totalEarnings;

  /// Get driver rating (customer rating for this order)
  double? get driverRating => customerRating;

  /// Get order number (formatted order ID)
  String get orderNumber => 'GE${orderId.substring(0, 8).toUpperCase()}';

  /// Get delivery fee (base fee from earnings)
  double get deliveryFee => orderEarnings.baseFee;

  /// Get customer phone number
  String? get customerPhone => deliveryDetails.contactPhone;

  /// Get vendor address (pickup address)
  String get vendorAddress => deliveryDetails.pickupAddress;

  /// Get delivery address
  String get deliveryAddress => deliveryDetails.deliveryAddress;
}
