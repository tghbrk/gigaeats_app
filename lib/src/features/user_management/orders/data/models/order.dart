import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order.g.dart';

/// Order status enumeration
enum OrderStatus {
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
  @JsonValue('cancelled')
  cancelled,
}

/// Payment status enumeration
enum PaymentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('refunded')
  refunded,
}

/// Payment method enumeration
enum PaymentMethod {
  @JsonValue('cash')
  cash,
  @JsonValue('card')
  card,
  @JsonValue('wallet')
  wallet,
  @JsonValue('bank_transfer')
  bankTransfer,
  @JsonValue('fpx')
  fpx,
  @JsonValue('grabpay')
  grabpay,
  @JsonValue('touchngo')
  touchngo,
}

/// Address model for delivery
@JsonSerializable()
class Address extends Equatable {
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final double? latitude;
  final double? longitude;
  final String? notes;

  const Address({
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    this.country = 'Malaysia',
    this.latitude,
    this.longitude,
    this.notes,
  });

  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);
  Map<String, dynamic> toJson() => _$AddressToJson(this);

  @override
  List<Object?> get props => [street, city, state, postalCode, country, latitude, longitude, notes];

  String get fullAddress => '$street, $city, $state $postalCode, $country';
}

/// Order item model
@JsonSerializable()
class OrderItem extends Equatable {
  final String id;
  @JsonKey(name: 'menu_item_id')
  final String menuItemId;
  final String name;
  final int quantity;
  @JsonKey(name: 'unit_price')
  final double unitPrice;
  final double subtotal;
  final Map<String, dynamic>? customizations;
  final String? notes;

  const OrderItem({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.customizations,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemToJson(this);

  @override
  List<Object?> get props => [id, menuItemId, name, quantity, unitPrice, subtotal, customizations, notes];

  // Convenience getters for backward compatibility

  /// Get price (same as unitPrice)
  double get price => unitPrice;
}

/// Main Order model
@JsonSerializable()
class Order extends Equatable {
  final String id;
  @JsonKey(name: 'order_number')
  final String orderNumber;
  final OrderStatus status;
  final List<OrderItem> items;
  @JsonKey(name: 'vendor_id')
  final String vendorId;
  @JsonKey(name: 'vendor_name')
  final String vendorName;
  @JsonKey(name: 'customer_id')
  final String customerId;
  @JsonKey(name: 'customer_name')
  final String customerName;
  @JsonKey(name: 'sales_agent_id')
  final String? salesAgentId;
  @JsonKey(name: 'sales_agent_name')
  final String? salesAgentName;
  @JsonKey(name: 'assigned_driver_id')
  final String? assignedDriverId;
  @JsonKey(name: 'delivery_date')
  final DateTime deliveryDate;
  @JsonKey(name: 'delivery_address')
  final Address deliveryAddress;
  @JsonKey(name: 'payment_method')
  final PaymentMethod? paymentMethod;
  @JsonKey(name: 'payment_status')
  final PaymentStatus? paymentStatus;
  @JsonKey(name: 'payment_reference')
  final String? paymentReference;
  final double subtotal;
  @JsonKey(name: 'delivery_fee')
  final double deliveryFee;
  @JsonKey(name: 'sst_amount')
  final double sstAmount;
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @JsonKey(name: 'commission_amount')
  final double? commissionAmount;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  // Enhanced tracking fields
  @JsonKey(name: 'estimated_delivery_time')
  final DateTime? estimatedDeliveryTime;
  @JsonKey(name: 'actual_delivery_time')
  final DateTime? actualDeliveryTime;
  @JsonKey(name: 'preparation_started_at')
  final DateTime? preparationStartedAt;
  @JsonKey(name: 'ready_at')
  final DateTime? readyAt;
  @JsonKey(name: 'out_for_delivery_at')
  final DateTime? outForDeliveryAt;

  // Malaysian specific fields
  @JsonKey(name: 'delivery_zone')
  final String? deliveryZone;
  @JsonKey(name: 'special_instructions')
  final String? specialInstructions;
  @JsonKey(name: 'contact_phone')
  final String? contactPhone;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.items,
    required this.vendorId,
    required this.vendorName,
    required this.customerId,
    required this.customerName,
    this.salesAgentId,
    this.salesAgentName,
    this.assignedDriverId,
    required this.deliveryDate,
    required this.deliveryAddress,
    this.paymentMethod,
    this.paymentStatus,
    this.paymentReference,
    required this.subtotal,
    required this.deliveryFee,
    required this.sstAmount,
    required this.totalAmount,
    this.commissionAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    // Enhanced tracking fields
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.preparationStartedAt,
    this.readyAt,
    this.outForDeliveryAt,
    // Malaysian specific fields
    this.deliveryZone,
    this.specialInstructions,
    this.contactPhone,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        status,
        items,
        vendorId,
        vendorName,
        customerId,
        customerName,
        salesAgentId,
        salesAgentName,
        assignedDriverId,
        deliveryDate,
        deliveryAddress,
        paymentMethod,
        paymentStatus,
        paymentReference,
        subtotal,
        deliveryFee,
        sstAmount,
        totalAmount,
        commissionAmount,
        notes,
        createdAt,
        updatedAt,
        metadata,
        estimatedDeliveryTime,
        actualDeliveryTime,
        preparationStartedAt,
        readyAt,
        outForDeliveryAt,
        deliveryZone,
        specialInstructions,
        contactPhone,
      ];

  /// Check if order can be cancelled
  bool get canBeCancelled => status == OrderStatus.pending || status == OrderStatus.confirmed;

  /// Check if order is in progress
  bool get isInProgress => [
        OrderStatus.confirmed,
        OrderStatus.preparing,
        OrderStatus.ready,
        OrderStatus.outForDelivery,
      ].contains(status);

  /// Check if order is completed
  bool get isCompleted => status == OrderStatus.delivered;

  /// Check if order is cancelled
  bool get isCancelled => status == OrderStatus.cancelled;

  /// Get order status display text
  String get statusDisplayText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Calculate total items count
  int get totalItemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Get estimated delivery time or fallback
  DateTime get estimatedOrScheduledDelivery => estimatedDeliveryTime ?? deliveryDate;
}
