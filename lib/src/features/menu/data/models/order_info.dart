import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_info.g.dart';

/// Order information model for vendor review service
@JsonSerializable()
class OrderInfo extends Equatable {
  /// Order ID
  final String id;
  
  /// Order number
  final String orderNumber;
  
  /// Customer ID
  final String customerId;
  
  /// Customer name
  final String customerName;
  
  /// Vendor ID
  final String vendorId;
  
  /// Vendor name
  final String vendorName;
  
  /// Order status
  final String status;
  
  /// Total amount
  final double totalAmount;
  
  /// Order date
  final DateTime orderDate;
  
  /// Delivery date
  final DateTime? deliveryDate;
  
  /// Payment status
  final String? paymentStatus;
  
  /// Payment method
  final String? paymentMethod;
  
  /// Delivery address
  final String? deliveryAddress;
  
  /// Special instructions
  final String? specialInstructions;
  
  /// Order items count
  final int itemsCount;
  
  /// Order metadata
  final Map<String, dynamic>? metadata;

  const OrderInfo({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.vendorId,
    required this.vendorName,
    required this.status,
    required this.totalAmount,
    required this.orderDate,
    this.deliveryDate,
    this.paymentStatus,
    this.paymentMethod,
    this.deliveryAddress,
    this.specialInstructions,
    required this.itemsCount,
    this.metadata,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) =>
      _$OrderInfoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderInfoToJson(this);

  OrderInfo copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    String? customerName,
    String? vendorId,
    String? vendorName,
    String? status,
    double? totalAmount,
    DateTime? orderDate,
    DateTime? deliveryDate,
    String? paymentStatus,
    String? paymentMethod,
    String? deliveryAddress,
    String? specialInstructions,
    int? itemsCount,
    Map<String, dynamic>? metadata,
  }) {
    return OrderInfo(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      itemsCount: itemsCount ?? this.itemsCount,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if order is completed
  bool get isCompleted => status == 'delivered' || status == 'completed';

  /// Check if order is active
  bool get isActive => 
      status == 'pending' || 
      status == 'confirmed' || 
      status == 'preparing' || 
      status == 'ready' || 
      status == 'out_for_delivery';

  /// Check if order is cancelled
  bool get isCancelled => status == 'cancelled';

  /// Check if order is paid
  bool get isPaid => paymentStatus == 'paid' || paymentStatus == 'completed';

  /// Get order status display name
  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Get payment status display name
  String get paymentStatusDisplayName {
    switch (paymentStatus?.toLowerCase()) {
      case 'pending':
        return 'Pending Payment';
      case 'paid':
        return 'Paid';
      case 'completed':
        return 'Payment Completed';
      case 'failed':
        return 'Payment Failed';
      case 'refunded':
        return 'Refunded';
      default:
        return paymentStatus ?? 'Unknown';
    }
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        customerId,
        customerName,
        vendorId,
        vendorName,
        status,
        totalAmount,
        orderDate,
        deliveryDate,
        paymentStatus,
        paymentMethod,
        deliveryAddress,
        specialInstructions,
        itemsCount,
        metadata,
      ];
}

/// Order status enumeration
enum OrderInfoStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('preparing')
  preparing,
  @JsonValue('ready')
  ready,
  @JsonValue('out_for_delivery')
  outForDelivery,
  @JsonValue('delivered')
  delivered,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

/// Extension for OrderInfoStatus
extension OrderInfoStatusExtension on OrderInfoStatus {
  String get value {
    switch (this) {
      case OrderInfoStatus.pending:
        return 'pending';
      case OrderInfoStatus.confirmed:
        return 'confirmed';
      case OrderInfoStatus.preparing:
        return 'preparing';
      case OrderInfoStatus.ready:
        return 'ready';
      case OrderInfoStatus.outForDelivery:
        return 'out_for_delivery';
      case OrderInfoStatus.delivered:
        return 'delivered';
      case OrderInfoStatus.completed:
        return 'completed';
      case OrderInfoStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case OrderInfoStatus.pending:
        return 'Pending';
      case OrderInfoStatus.confirmed:
        return 'Confirmed';
      case OrderInfoStatus.preparing:
        return 'Preparing';
      case OrderInfoStatus.ready:
        return 'Ready';
      case OrderInfoStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderInfoStatus.delivered:
        return 'Delivered';
      case OrderInfoStatus.completed:
        return 'Completed';
      case OrderInfoStatus.cancelled:
        return 'Cancelled';
    }
  }
}
