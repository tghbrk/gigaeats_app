enum DeliveryMethod {
  lalamove('lalamove', 'Lalamove Delivery'),
  ownFleet('own_fleet', 'Own Delivery Fleet'),
  customerPickup('customer_pickup', 'Customer Pickup'),
  salesAgentPickup('sales_agent_pickup', 'Sales Agent Pickup');

  const DeliveryMethod(this.value, this.displayName);

  final String value;
  final String displayName;

  static DeliveryMethod fromString(String value) {
    return DeliveryMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => DeliveryMethod.customerPickup,
    );
  }

  bool get isLalamove => this == DeliveryMethod.lalamove;
  bool get isOwnFleet => this == DeliveryMethod.ownFleet;
  bool get isCustomerPickup => this == DeliveryMethod.customerPickup;
  bool get isSalesAgentPickup => this == DeliveryMethod.salesAgentPickup;
  bool get requiresDriver => isLalamove || isOwnFleet;
  bool get isPickup => isCustomerPickup || isSalesAgentPickup;
}

class DeliveryInfo {
  final DeliveryMethod method;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleInfo;
  final String? trackingId;
  final String? estimatedArrival;
  final String? specialInstructions;
  final Map<String, dynamic>? metadata;

  const DeliveryInfo({
    required this.method,
    this.driverName,
    this.driverPhone,
    this.vehicleInfo,
    this.trackingId,
    this.estimatedArrival,
    this.specialInstructions,
    this.metadata,
  });

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryInfo(
      method: DeliveryMethod.fromString(json['method'] ?? 'customer_pickup'),
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],
      vehicleInfo: json['vehicle_info'],
      trackingId: json['tracking_id'],
      estimatedArrival: json['estimated_arrival'],
      specialInstructions: json['special_instructions'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method.value,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'vehicle_info': vehicleInfo,
      'tracking_id': trackingId,
      'estimated_arrival': estimatedArrival,
      'special_instructions': specialInstructions,
      'metadata': metadata,
    };
  }

  DeliveryInfo copyWith({
    DeliveryMethod? method,
    String? driverName,
    String? driverPhone,
    String? vehicleInfo,
    String? trackingId,
    String? estimatedArrival,
    String? specialInstructions,
    Map<String, dynamic>? metadata,
  }) {
    return DeliveryInfo(
      method: method ?? this.method,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      trackingId: trackingId ?? this.trackingId,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ProofOfDelivery {
  final String? photoUrl;
  final String? signatureUrl;
  final String? recipientName;
  final String? notes;
  final DateTime deliveredAt;
  final String deliveredBy;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracy;
  final String? deliveryAddress;

  const ProofOfDelivery({
    this.photoUrl,
    this.signatureUrl,
    this.recipientName,
    this.notes,
    required this.deliveredAt,
    required this.deliveredBy,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.deliveryAddress,
  });

  factory ProofOfDelivery.fromJson(Map<String, dynamic> json) {
    return ProofOfDelivery(
      photoUrl: json['photo_url'],
      signatureUrl: json['signature_url'],
      recipientName: json['recipient_name'],
      notes: json['notes'],
      deliveredAt: DateTime.parse(json['delivered_at']),
      deliveredBy: json['delivered_by'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      locationAccuracy: json['location_accuracy']?.toDouble(),
      deliveryAddress: json['delivery_address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photo_url': photoUrl,
      'signature_url': signatureUrl,
      'recipient_name': recipientName,
      'notes': notes,
      'delivered_at': deliveredAt.toIso8601String(),
      'delivered_by': deliveredBy,
      'latitude': latitude,
      'longitude': longitude,
      'location_accuracy': locationAccuracy,
      'delivery_address': deliveryAddress,
    };
  }
}
