import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

import 'delivery_method.dart';

part 'order.g.dart';

enum PaymentStatus {
  pending('pending', 'Pending'),
  paid('paid', 'Paid'),
  failed('failed', 'Failed'),
  refunded('refunded', 'Refunded');

  const PaymentStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }

  bool get isPending => this == PaymentStatus.pending;
  bool get isPaid => this == PaymentStatus.paid;
  bool get isFailed => this == PaymentStatus.failed;
  bool get isRefunded => this == PaymentStatus.refunded;
}

enum PaymentMethod {
  fpx('fpx', 'FPX'),
  grabpay('grabpay', 'GrabPay'),
  touchngo('touchngo', 'Touch \'n Go'),
  creditCard('credit_card', 'Credit Card');

  const PaymentMethod(this.value, this.displayName);

  final String value;
  final String displayName;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PaymentMethod.fpx,
    );
  }

  @override
  String toString() => value;
}

enum OrderStatus {
  pending('pending', 'Pending'),
  confirmed('confirmed', 'Confirmed'),
  preparing('preparing', 'Preparing'),
  ready('ready', 'Ready'),
  outForDelivery('out_for_delivery', 'Out for Delivery'),
  delivered('delivered', 'Delivered'),
  cancelled('cancelled', 'Cancelled');

  const OrderStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.pending,
    );
  }

  bool get isPending => this == OrderStatus.pending;
  bool get isConfirmed => this == OrderStatus.confirmed;
  bool get isPreparing => this == OrderStatus.preparing;
  bool get isReady => this == OrderStatus.ready;
  bool get isOutForDelivery => this == OrderStatus.outForDelivery;
  bool get isDelivered => this == OrderStatus.delivered;
  bool get isCancelled => this == OrderStatus.cancelled;
  bool get isActive => !isCancelled && !isDelivered;
}

@JsonSerializable()
class Address extends Equatable {
  final String street;
  final String city;
  final String state;
  @JsonKey(name: 'postal_code')
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
    required this.country,
    this.latitude,
    this.longitude,
    this.notes,
  });

  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);

  Map<String, dynamic> toJson() => _$AddressToJson(this);

  @override
  List<Object?> get props => [
        street,
        city,
        state,
        postalCode,
        country,
        latitude,
        longitude,
        notes,
      ];

  String get fullAddress => '$street, $city, $state $postalCode, $country';
}

// Helper functions for OrderStatus JSON serialization
OrderStatus _orderStatusFromJson(String value) => OrderStatus.fromString(value);
String _orderStatusToJson(OrderStatus status) => status.value;

@JsonSerializable()
class OrderItem extends Equatable {
  final String id;
  @JsonKey(name: 'menu_item_id')
  final String menuItemId;
  final String name;
  final String description;
  @JsonKey(name: 'unit_price')
  final double unitPrice;
  final int quantity;
  @JsonKey(name: 'total_price')
  final double totalPrice;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final Map<String, dynamic>? customizations;
  final String? notes;

  const OrderItem({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.description,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    this.imageUrl,
    this.customizations,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemToJson(this);

  @override
  List<Object?> get props => [
        id,
        menuItemId,
        name,
        description,
        unitPrice,
        quantity,
        totalPrice,
        imageUrl,
        customizations,
        notes,
      ];
}

@JsonSerializable()
class PaymentInfo extends Equatable {
  final String method;
  @JsonKey(name: 'transaction_id')
  final String? transactionId;
  @JsonKey(name: 'reference_number')
  final String? referenceNumber;
  final double amount;
  final String currency;
  final String status;
  @JsonKey(name: 'paid_at')
  final DateTime? paidAt;
  final Map<String, dynamic>? metadata;

  const PaymentInfo({
    required this.method,
    this.transactionId,
    this.referenceNumber,
    required this.amount,
    required this.currency,
    required this.status,
    this.paidAt,
    this.metadata,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) =>
      _$PaymentInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentInfoToJson(this);

  @override
  List<Object?> get props => [
        method,
        transactionId,
        referenceNumber,
        amount,
        currency,
        status,
        paidAt,
        metadata,
      ];
}

@JsonSerializable()
class Order extends Equatable {
  final String id;
  @JsonKey(name: 'order_number')
  final String orderNumber;
  @JsonKey(fromJson: _orderStatusFromJson, toJson: _orderStatusToJson)
  final OrderStatus status;
  @JsonKey(name: 'order_items', defaultValue: <OrderItem>[])
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

  // Individual payment fields (replaces nested PaymentInfo object)
  @JsonKey(name: 'payment_method')
  final String? paymentMethod;
  @JsonKey(name: 'payment_status')
  final String? paymentStatus;
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

  Order copyWith({
    String? id,
    String? orderNumber,
    OrderStatus? status,
    List<OrderItem>? items,
    String? vendorId,
    String? vendorName,
    String? customerId,
    String? customerName,
    String? salesAgentId,
    String? salesAgentName,
    String? assignedDriverId,
    DateTime? deliveryDate,
    Address? deliveryAddress,
    String? paymentMethod,
    String? paymentStatus,
    String? paymentReference,
    double? subtotal,
    double? deliveryFee,
    double? sstAmount,
    double? totalAmount,
    double? commissionAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    // Enhanced tracking fields
    DateTime? estimatedDeliveryTime,
    DateTime? actualDeliveryTime,
    DateTime? preparationStartedAt,
    DateTime? readyAt,
    DateTime? outForDeliveryAt,
    // Malaysian specific fields
    String? deliveryZone,
    String? specialInstructions,
    String? contactPhone,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      items: items ?? this.items,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      salesAgentId: salesAgentId ?? this.salesAgentId,
      salesAgentName: salesAgentName ?? this.salesAgentName,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentReference: paymentReference ?? this.paymentReference,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      sstAmount: sstAmount ?? this.sstAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      // Enhanced tracking fields
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      preparationStartedAt: preparationStartedAt ?? this.preparationStartedAt,
      readyAt: readyAt ?? this.readyAt,
      outForDeliveryAt: outForDeliveryAt ?? this.outForDeliveryAt,
      // Malaysian specific fields
      deliveryZone: deliveryZone ?? this.deliveryZone,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      contactPhone: contactPhone ?? this.contactPhone,
    );
  }

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
        // Enhanced tracking fields
        estimatedDeliveryTime,
        actualDeliveryTime,
        preparationStartedAt,
        readyAt,
        outForDeliveryAt,
        // Malaysian specific fields
        deliveryZone,
        specialInstructions,
        contactPhone,
      ];

  /// Get delivery method from metadata
  DeliveryMethod get deliveryMethod {
    if (metadata == null) return DeliveryMethod.customerPickup;

    final deliveryMethodValue = metadata!['delivery_method'] as String?;
    if (deliveryMethodValue == null) return DeliveryMethod.customerPickup;

    return DeliveryMethod.fromString(deliveryMethodValue);
  }

  /// Check if this order uses customer pickup
  bool get isCustomerPickup => deliveryMethod.isCustomerPickup;

  /// Check if this order uses sales agent pickup
  bool get isSalesAgentPickup => deliveryMethod.isSalesAgentPickup;

  /// Check if this order uses own fleet delivery
  bool get isOwnFleetDelivery => deliveryMethod.isOwnFleet;

  /// Check if this order uses Lalamove delivery
  bool get isLalamoveDelivery => deliveryMethod.isLalamove;

  /// Check if this order is a pickup order (customer or sales agent)
  bool get isPickupOrder => deliveryMethod.isPickup;

  /// Check if this order requires driver assignment
  bool get requiresDriverAssignment => deliveryMethod.requiresDriver;

  /// Check if vendor should handle delivery actions for this order
  bool get vendorCanHandleDelivery {
    // Vendors can only handle delivery actions for their own fleet
    return isOwnFleetDelivery;
  }

  /// Check if sales agent can mark this order as delivered
  bool get salesAgentCanMarkDelivered {
    // Sales agents can only mark delivered for sales agent pickup orders
    return isSalesAgentPickup;
  }

  @override
  String toString() {
    return 'Order(id: $id, orderNumber: $orderNumber, status: $status, totalAmount: $totalAmount, deliveryMethod: ${deliveryMethod.displayName})';
  }
}
