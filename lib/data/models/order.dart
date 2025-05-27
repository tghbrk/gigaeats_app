import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'order.g.dart';

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

@JsonSerializable()
class OrderItem extends Equatable {
  final String id;
  final String menuItemId;
  final String name;
  final String description;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
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
  final String? transactionId;
  final String? referenceNumber;
  final double amount;
  final String currency;
  final String status;
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
  final String orderNumber;
  final OrderStatus status;
  final List<OrderItem> items;
  final String vendorId;
  final String vendorName;
  final String customerId;
  final String customerName;
  final String? salesAgentId;
  final String? salesAgentName;
  final DateTime deliveryDate;
  final Address deliveryAddress;
  final PaymentInfo? payment;
  final double subtotal;
  final double deliveryFee;
  final double sstAmount;
  final double totalAmount;
  final double? commissionAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

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
    required this.deliveryDate,
    required this.deliveryAddress,
    this.payment,
    required this.subtotal,
    required this.deliveryFee,
    required this.sstAmount,
    required this.totalAmount,
    this.commissionAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
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
    DateTime? deliveryDate,
    Address? deliveryAddress,
    PaymentInfo? payment,
    double? subtotal,
    double? deliveryFee,
    double? sstAmount,
    double? totalAmount,
    double? commissionAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
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
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      payment: payment ?? this.payment,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      sstAmount: sstAmount ?? this.sstAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
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
        deliveryDate,
        deliveryAddress,
        payment,
        subtotal,
        deliveryFee,
        sstAmount,
        totalAmount,
        commissionAmount,
        notes,
        createdAt,
        updatedAt,
        metadata,
      ];

  @override
  String toString() {
    return 'Order(id: $id, orderNumber: $orderNumber, status: $status, totalAmount: $totalAmount)';
  }
}
