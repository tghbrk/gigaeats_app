import 'package:equatable/equatable.dart';

/// Driver-specific order model with delivery information
class DriverOrder extends Equatable {
  final String id;
  final String orderNumber;
  final String vendorName;
  final String? vendorAddress;
  final String customerName;
  final String deliveryAddress;
  final String? customerPhone;
  final double totalAmount;
  final double deliveryFee;
  final DriverOrderStatus status;
  final DateTime? estimatedDeliveryTime;
  final String? specialInstructions;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  const DriverOrder({
    required this.id,
    required this.orderNumber,
    required this.vendorName,
    this.vendorAddress,
    required this.customerName,
    required this.deliveryAddress,
    this.customerPhone,
    required this.totalAmount,
    required this.deliveryFee,
    required this.status,
    this.estimatedDeliveryTime,
    this.specialInstructions,
    required this.createdAt,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  factory DriverOrder.fromJson(Map<String, dynamic> json) {
    return DriverOrder(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      vendorName: json['vendor_name'] as String? ?? 'Unknown Vendor',
      vendorAddress: json['vendor_address'] as String?,
      customerName: json['customer_name'] as String? ?? 'Unknown Customer',
      deliveryAddress: _parseDeliveryAddress(json['delivery_address']),
      customerPhone: json['contact_phone'] as String?,
      totalAmount: (json['total_amount'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      status: DriverOrderStatus.fromString(json['status'] as String),
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? DateTime.parse(json['estimated_delivery_time'] as String)
          : null,
      specialInstructions: json['special_instructions'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.parse(json['picked_up_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
    );
  }

  /// Helper method to parse delivery address from JSON
  static String _parseDeliveryAddress(dynamic deliveryAddress) {
    if (deliveryAddress == null) {
      return 'Address not provided';
    }

    if (deliveryAddress is String) {
      return deliveryAddress;
    }

    if (deliveryAddress is Map<String, dynamic>) {
      // Extract address components and format them
      final street = deliveryAddress['street'] as String? ?? '';
      final city = deliveryAddress['city'] as String? ?? '';
      final state = deliveryAddress['state'] as String? ?? '';
      final postalCode = deliveryAddress['postal_code'] as String? ?? '';
      final country = deliveryAddress['country'] as String? ?? '';

      final addressParts = <String>[];
      if (street.isNotEmpty) addressParts.add(street);
      if (city.isNotEmpty) addressParts.add(city);
      if (state.isNotEmpty) addressParts.add(state);
      if (postalCode.isNotEmpty) addressParts.add(postalCode);
      if (country.isNotEmpty) addressParts.add(country);

      return addressParts.isNotEmpty ? addressParts.join(', ') : 'Address not provided';
    }

    return deliveryAddress.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'vendor_name': vendorName,
      'vendor_address': vendorAddress,
      'customer_name': customerName,
      'delivery_address': deliveryAddress,
      'customer_phone': customerPhone,
      'total_amount': totalAmount,
      'delivery_fee': deliveryFee,
      'status': status.value,
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
      'special_instructions': specialInstructions,
      'created_at': createdAt.toIso8601String(),
      'assigned_at': assignedAt?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }

  DriverOrder copyWith({
    String? id,
    String? orderNumber,
    String? vendorName,
    String? vendorAddress,
    String? customerName,
    String? deliveryAddress,
    String? customerPhone,
    double? totalAmount,
    double? deliveryFee,
    DriverOrderStatus? status,
    DateTime? estimatedDeliveryTime,
    String? specialInstructions,
    DateTime? createdAt,
    DateTime? assignedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
  }) {
    return DriverOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      vendorName: vendorName ?? this.vendorName,
      vendorAddress: vendorAddress ?? this.vendorAddress,
      customerName: customerName ?? this.customerName,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      customerPhone: customerPhone ?? this.customerPhone,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      status: status ?? this.status,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      createdAt: createdAt ?? this.createdAt,
      assignedAt: assignedAt ?? this.assignedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        vendorName,
        vendorAddress,
        customerName,
        deliveryAddress,
        customerPhone,
        totalAmount,
        deliveryFee,
        status,
        estimatedDeliveryTime,
        specialInstructions,
        createdAt,
        assignedAt,
        pickedUpAt,
        deliveredAt,
      ];
}

/// Driver order status enum
enum DriverOrderStatus {
  available,
  assigned,
  ready,
  onRouteToVendor,
  arrivedAtVendor,
  pickedUp,
  onRouteToCustomer,
  arrivedAtCustomer,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case DriverOrderStatus.available:
        return 'Available';
      case DriverOrderStatus.assigned:
        return 'Assigned';
      case DriverOrderStatus.ready:
        return 'Ready for Pickup';
      case DriverOrderStatus.onRouteToVendor:
        return 'On Route to Pickup';
      case DriverOrderStatus.arrivedAtVendor:
        return 'Arrived at Pickup';
      case DriverOrderStatus.pickedUp:
        return 'Picked Up';
      case DriverOrderStatus.onRouteToCustomer:
        return 'On Route to Customer';
      case DriverOrderStatus.arrivedAtCustomer:
        return 'Arrived at Customer';
      case DriverOrderStatus.delivered:
        return 'Delivered';
      case DriverOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get value {
    switch (this) {
      case DriverOrderStatus.available:
        return 'available';
      case DriverOrderStatus.assigned:
        return 'assigned';
      case DriverOrderStatus.ready:
        return 'ready';
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
    }
  }

  static DriverOrderStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'available':
        return DriverOrderStatus.available;
      case 'assigned':
        return DriverOrderStatus.assigned;
      case 'ready':
        return DriverOrderStatus.ready;
      case 'on_route_to_vendor':
        return DriverOrderStatus.onRouteToVendor;
      case 'arrived_at_vendor':
        return DriverOrderStatus.arrivedAtVendor;
      case 'picked_up':
        return DriverOrderStatus.pickedUp;
      case 'on_route_to_customer':
        return DriverOrderStatus.onRouteToCustomer;
      case 'arrived_at_customer':
        return DriverOrderStatus.arrivedAtCustomer;
      case 'en_route': // Legacy support
      case 'out_for_delivery': // Legacy support
        return DriverOrderStatus.onRouteToCustomer;
      case 'delivered':
        return DriverOrderStatus.delivered;
      case 'cancelled':
        return DriverOrderStatus.cancelled;
      default:
        throw ArgumentError('Invalid driver order status: $value');
    }
  }
}

/// Extension to add missing getters for compatibility
extension DriverOrderExtension on DriverOrder {
  /// Get assigned driver ID (placeholder - would need actual driver assignment logic)
  String get assignedDriverId => 'driver-${id.substring(0, 8)}';

  /// Get driver earnings (placeholder - would need actual earnings calculation)
  double get driverEarnings => deliveryFee * 0.8; // 80% of delivery fee as example

  /// Get driver rating (placeholder - would need actual rating system)
  double? get driverRating => null; // No rating available yet
}