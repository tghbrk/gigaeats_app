// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Address _$AddressFromJson(Map<String, dynamic> json) => Address(
  street: json['street'] as String,
  city: json['city'] as String,
  state: json['state'] as String,
  postalCode: json['postal_code'] as String,
  country: json['country'] as String,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
  'street': instance.street,
  'city': instance.city,
  'state': instance.state,
  'postal_code': instance.postalCode,
  'country': instance.country,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'notes': instance.notes,
};

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
  id: json['id'] as String,
  menuItemId: json['menu_item_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  unitPrice: (json['unit_price'] as num).toDouble(),
  quantity: (json['quantity'] as num).toInt(),
  totalPrice: (json['total_price'] as num).toDouble(),
  imageUrl: json['image_url'] as String?,
  customizations: json['customizations'] as Map<String, dynamic>?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'id': instance.id,
  'menu_item_id': instance.menuItemId,
  'name': instance.name,
  'description': instance.description,
  'unit_price': instance.unitPrice,
  'quantity': instance.quantity,
  'total_price': instance.totalPrice,
  'image_url': instance.imageUrl,
  'customizations': instance.customizations,
  'notes': instance.notes,
};

PaymentInfo _$PaymentInfoFromJson(Map<String, dynamic> json) => PaymentInfo(
  method: json['method'] as String,
  transactionId: json['transaction_id'] as String?,
  referenceNumber: json['reference_number'] as String?,
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String,
  status: json['status'] as String,
  paidAt: json['paid_at'] == null
      ? null
      : DateTime.parse(json['paid_at'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$PaymentInfoToJson(PaymentInfo instance) =>
    <String, dynamic>{
      'method': instance.method,
      'transaction_id': instance.transactionId,
      'reference_number': instance.referenceNumber,
      'amount': instance.amount,
      'currency': instance.currency,
      'status': instance.status,
      'paid_at': instance.paidAt?.toIso8601String(),
      'metadata': instance.metadata,
    };

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  id: json['id'] as String,
  orderNumber: json['order_number'] as String,
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  items:
      (json['order_items'] as List<dynamic>?)
          ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  vendorId: json['vendor_id'] as String,
  vendorName: json['vendor_name'] as String,
  customerId: json['customer_id'] as String,
  customerName: json['customer_name'] as String,
  salesAgentId: json['sales_agent_id'] as String?,
  salesAgentName: json['sales_agent_name'] as String?,
  deliveryDate: DateTime.parse(json['delivery_date'] as String),
  deliveryAddress: Address.fromJson(
    json['delivery_address'] as Map<String, dynamic>,
  ),
  payment: json['payment'] == null
      ? null
      : PaymentInfo.fromJson(json['payment'] as Map<String, dynamic>),
  subtotal: (json['subtotal'] as num).toDouble(),
  deliveryFee: (json['delivery_fee'] as num).toDouble(),
  sstAmount: (json['sst_amount'] as num).toDouble(),
  totalAmount: (json['total_amount'] as num).toDouble(),
  commissionAmount: (json['commission_amount'] as num?)?.toDouble(),
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
  estimatedDeliveryTime: json['estimated_delivery_time'] == null
      ? null
      : DateTime.parse(json['estimated_delivery_time'] as String),
  actualDeliveryTime: json['actual_delivery_time'] == null
      ? null
      : DateTime.parse(json['actual_delivery_time'] as String),
  preparationStartedAt: json['preparation_started_at'] == null
      ? null
      : DateTime.parse(json['preparation_started_at'] as String),
  readyAt: json['ready_at'] == null
      ? null
      : DateTime.parse(json['ready_at'] as String),
  outForDeliveryAt: json['out_for_delivery_at'] == null
      ? null
      : DateTime.parse(json['out_for_delivery_at'] as String),
  deliveryZone: json['delivery_zone'] as String?,
  specialInstructions: json['special_instructions'] as String?,
  contactPhone: json['contact_phone'] as String?,
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'order_number': instance.orderNumber,
  'status': _$OrderStatusEnumMap[instance.status]!,
  'order_items': instance.items,
  'vendor_id': instance.vendorId,
  'vendor_name': instance.vendorName,
  'customer_id': instance.customerId,
  'customer_name': instance.customerName,
  'sales_agent_id': instance.salesAgentId,
  'sales_agent_name': instance.salesAgentName,
  'delivery_date': instance.deliveryDate.toIso8601String(),
  'delivery_address': instance.deliveryAddress,
  'payment': instance.payment,
  'subtotal': instance.subtotal,
  'delivery_fee': instance.deliveryFee,
  'sst_amount': instance.sstAmount,
  'total_amount': instance.totalAmount,
  'commission_amount': instance.commissionAmount,
  'notes': instance.notes,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'metadata': instance.metadata,
  'estimated_delivery_time': instance.estimatedDeliveryTime?.toIso8601String(),
  'actual_delivery_time': instance.actualDeliveryTime?.toIso8601String(),
  'preparation_started_at': instance.preparationStartedAt?.toIso8601String(),
  'ready_at': instance.readyAt?.toIso8601String(),
  'out_for_delivery_at': instance.outForDeliveryAt?.toIso8601String(),
  'delivery_zone': instance.deliveryZone,
  'special_instructions': instance.specialInstructions,
  'contact_phone': instance.contactPhone,
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
