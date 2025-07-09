import 'package:equatable/equatable.dart';

import '../../../drivers/data/models/driver_order.dart' show DriverOrderStatus;

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
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '',
      vendorName: json['vendor_name']?.toString() ?? 'Unknown Vendor',
      vendorAddress: json['vendor_address']?.toString(),
      customerName: json['customer_name']?.toString() ?? 'Unknown Customer',
      deliveryAddress: _parseDeliveryAddress(json['delivery_address']),
      customerPhone: json['contact_phone']?.toString(),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      status: DriverOrderStatus.fromString(json['status']?.toString() ?? 'assigned'),
      estimatedDeliveryTime: json['estimated_delivery_time'] != null && json['estimated_delivery_time'].toString().isNotEmpty
          ? DateTime.tryParse(json['estimated_delivery_time'].toString())
          : null,
      specialInstructions: json['special_instructions']?.toString(),
      createdAt: json['created_at'] != null && json['created_at'].toString().isNotEmpty
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      assignedAt: json['assigned_at'] != null && json['assigned_at'].toString().isNotEmpty
          ? DateTime.tryParse(json['assigned_at'].toString())
          : null,
      pickedUpAt: json['picked_up_at'] != null && json['picked_up_at'].toString().isNotEmpty
          ? DateTime.tryParse(json['picked_up_at'].toString())
          : null,
      deliveredAt: json['delivered_at'] != null && json['delivered_at'].toString().isNotEmpty
          ? DateTime.tryParse(json['delivered_at'].toString())
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

// DriverOrderStatus enum moved to lib/src/features/drivers/data/models/driver_order.dart
// Import that file to use the comprehensive DriverOrderStatus enum

/// Extension to add missing getters for compatibility
extension DriverOrderExtension on DriverOrder {
  /// Get assigned driver ID (placeholder - would need actual driver assignment logic)
  String get assignedDriverId => 'driver-${id.substring(0, 8)}';

  /// Get driver earnings (placeholder - would need actual earnings calculation)
  double get driverEarnings => deliveryFee * 0.8; // 80% of delivery fee as example

  /// Get driver rating (placeholder - would need actual rating system)
  double? get driverRating => null; // No rating available yet
}