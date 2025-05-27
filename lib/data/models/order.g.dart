// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Address _$AddressFromJson(Map<String, dynamic> json) => Address(
  street: json['street'] as String,
  city: json['city'] as String,
  state: json['state'] as String,
  postalCode: json['postalCode'] as String,
  country: json['country'] as String,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
  'street': instance.street,
  'city': instance.city,
  'state': instance.state,
  'postalCode': instance.postalCode,
  'country': instance.country,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'notes': instance.notes,
};

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
  id: json['id'] as String,
  menuItemId: json['menuItemId'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  unitPrice: (json['unitPrice'] as num).toDouble(),
  quantity: (json['quantity'] as num).toInt(),
  totalPrice: (json['totalPrice'] as num).toDouble(),
  imageUrl: json['imageUrl'] as String?,
  customizations: json['customizations'] as Map<String, dynamic>?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'id': instance.id,
  'menuItemId': instance.menuItemId,
  'name': instance.name,
  'description': instance.description,
  'unitPrice': instance.unitPrice,
  'quantity': instance.quantity,
  'totalPrice': instance.totalPrice,
  'imageUrl': instance.imageUrl,
  'customizations': instance.customizations,
  'notes': instance.notes,
};

PaymentInfo _$PaymentInfoFromJson(Map<String, dynamic> json) => PaymentInfo(
  method: json['method'] as String,
  transactionId: json['transactionId'] as String?,
  referenceNumber: json['referenceNumber'] as String?,
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String,
  status: json['status'] as String,
  paidAt: json['paidAt'] == null
      ? null
      : DateTime.parse(json['paidAt'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$PaymentInfoToJson(PaymentInfo instance) =>
    <String, dynamic>{
      'method': instance.method,
      'transactionId': instance.transactionId,
      'referenceNumber': instance.referenceNumber,
      'amount': instance.amount,
      'currency': instance.currency,
      'status': instance.status,
      'paidAt': instance.paidAt?.toIso8601String(),
      'metadata': instance.metadata,
    };

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  id: json['id'] as String,
  orderNumber: json['orderNumber'] as String,
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  items: (json['items'] as List<dynamic>)
      .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  vendorId: json['vendorId'] as String,
  vendorName: json['vendorName'] as String,
  customerId: json['customerId'] as String,
  customerName: json['customerName'] as String,
  salesAgentId: json['salesAgentId'] as String?,
  salesAgentName: json['salesAgentName'] as String?,
  deliveryDate: DateTime.parse(json['deliveryDate'] as String),
  deliveryAddress: Address.fromJson(
    json['deliveryAddress'] as Map<String, dynamic>,
  ),
  payment: json['payment'] == null
      ? null
      : PaymentInfo.fromJson(json['payment'] as Map<String, dynamic>),
  subtotal: (json['subtotal'] as num).toDouble(),
  deliveryFee: (json['deliveryFee'] as num).toDouble(),
  sstAmount: (json['sstAmount'] as num).toDouble(),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  commissionAmount: (json['commissionAmount'] as num?)?.toDouble(),
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'orderNumber': instance.orderNumber,
  'status': _$OrderStatusEnumMap[instance.status]!,
  'items': instance.items,
  'vendorId': instance.vendorId,
  'vendorName': instance.vendorName,
  'customerId': instance.customerId,
  'customerName': instance.customerName,
  'salesAgentId': instance.salesAgentId,
  'salesAgentName': instance.salesAgentName,
  'deliveryDate': instance.deliveryDate.toIso8601String(),
  'deliveryAddress': instance.deliveryAddress,
  'payment': instance.payment,
  'subtotal': instance.subtotal,
  'deliveryFee': instance.deliveryFee,
  'sstAmount': instance.sstAmount,
  'totalAmount': instance.totalAmount,
  'commissionAmount': instance.commissionAmount,
  'notes': instance.notes,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'metadata': instance.metadata,
};

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.confirmed: 'confirmed',
  OrderStatus.preparing: 'preparing',
  OrderStatus.ready: 'ready',
  OrderStatus.outForDelivery: 'outForDelivery',
  OrderStatus.delivered: 'delivered',
  OrderStatus.cancelled: 'cancelled',
};
