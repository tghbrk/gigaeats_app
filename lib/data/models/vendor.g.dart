// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vendor _$VendorFromJson(Map<String, dynamic> json) => Vendor(
  id: json['id'] as String,
  businessName: json['business_name'] as String,
  firebaseUid: json['firebase_uid'] as String,
  businessRegistrationNumber: json['business_registration_number'] as String,
  businessAddress: json['business_address'] as String,
  businessType: json['business_type'] as String,
  cuisineTypes: (json['cuisine_types'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  isHalalCertified: json['is_halal_certified'] as bool? ?? false,
  halalCertificationNumber: json['halal_certification_number'] as String?,
  description: json['description'] as String?,
  rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
  totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
  totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
  isActive: json['is_active'] as bool? ?? true,
  isVerified: json['is_verified'] as bool? ?? false,
  coverImageUrl: json['cover_image_url'] as String?,
  galleryImages:
      (json['gallery_images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  businessHours: json['business_hours'] as Map<String, dynamic>?,
  serviceAreas: (json['service_areas'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  minimumOrderAmount: (json['minimum_order_amount'] as num?)?.toDouble(),
  deliveryFee: (json['delivery_fee'] as num?)?.toDouble(),
  freeDeliveryThreshold: (json['free_delivery_threshold'] as num?)?.toDouble(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$VendorToJson(Vendor instance) => <String, dynamic>{
  'id': instance.id,
  'business_name': instance.businessName,
  'firebase_uid': instance.firebaseUid,
  'business_registration_number': instance.businessRegistrationNumber,
  'business_address': instance.businessAddress,
  'business_type': instance.businessType,
  'cuisine_types': instance.cuisineTypes,
  'is_halal_certified': instance.isHalalCertified,
  'halal_certification_number': instance.halalCertificationNumber,
  'description': instance.description,
  'rating': instance.rating,
  'total_reviews': instance.totalReviews,
  'total_orders': instance.totalOrders,
  'is_active': instance.isActive,
  'is_verified': instance.isVerified,
  'cover_image_url': instance.coverImageUrl,
  'gallery_images': instance.galleryImages,
  'business_hours': instance.businessHours,
  'service_areas': instance.serviceAreas,
  'minimum_order_amount': instance.minimumOrderAmount,
  'delivery_fee': instance.deliveryFee,
  'free_delivery_threshold': instance.freeDeliveryThreshold,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

VendorAddress _$VendorAddressFromJson(Map<String, dynamic> json) =>
    VendorAddress(
      street: json['street'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      postcode: json['postcode'] as String,
      country: json['country'] as String? ?? 'Malaysia',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$VendorAddressToJson(VendorAddress instance) =>
    <String, dynamic>{
      'street': instance.street,
      'city': instance.city,
      'state': instance.state,
      'postcode': instance.postcode,
      'country': instance.country,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

VendorBusinessInfo _$VendorBusinessInfoFromJson(Map<String, dynamic> json) =>
    VendorBusinessInfo(
      ssmNumber: json['ssmNumber'] as String,
      halalCertNumber: json['halalCertNumber'] as String?,
      businessLicense: json['businessLicense'] as String?,
      minimumOrderAmount: (json['minimumOrderAmount'] as num).toDouble(),
      deliveryRadius: (json['deliveryRadius'] as num).toDouble(),
      paymentMethods: (json['paymentMethods'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      operatingHours: VendorOperatingHours.fromJson(
        json['operatingHours'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$VendorBusinessInfoToJson(VendorBusinessInfo instance) =>
    <String, dynamic>{
      'ssmNumber': instance.ssmNumber,
      'halalCertNumber': instance.halalCertNumber,
      'businessLicense': instance.businessLicense,
      'minimumOrderAmount': instance.minimumOrderAmount,
      'deliveryRadius': instance.deliveryRadius,
      'paymentMethods': instance.paymentMethods,
      'operatingHours': instance.operatingHours,
    };

VendorOperatingHours _$VendorOperatingHoursFromJson(
  Map<String, dynamic> json,
) => VendorOperatingHours(
  schedule: (json['schedule'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, DaySchedule.fromJson(e as Map<String, dynamic>)),
  ),
  isOpen24Hours: json['isOpen24Hours'] as bool? ?? false,
  holidays:
      (json['holidays'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$VendorOperatingHoursToJson(
  VendorOperatingHours instance,
) => <String, dynamic>{
  'schedule': instance.schedule,
  'isOpen24Hours': instance.isOpen24Hours,
  'holidays': instance.holidays,
};

DaySchedule _$DayScheduleFromJson(Map<String, dynamic> json) => DaySchedule(
  isOpen: json['isOpen'] as bool? ?? false,
  openTime: json['openTime'] as String?,
  closeTime: json['closeTime'] as String?,
  breakStart: json['breakStart'] as String?,
  breakEnd: json['breakEnd'] as String?,
);

Map<String, dynamic> _$DayScheduleToJson(DaySchedule instance) =>
    <String, dynamic>{
      'isOpen': instance.isOpen,
      'openTime': instance.openTime,
      'closeTime': instance.closeTime,
      'breakStart': instance.breakStart,
      'breakEnd': instance.breakEnd,
    };

VendorSettings _$VendorSettingsFromJson(Map<String, dynamic> json) =>
    VendorSettings(
      acceptsPreOrders: json['acceptsPreOrders'] as bool? ?? true,
      maxPreOrderDays: (json['maxPreOrderDays'] as num?)?.toInt() ?? 7,
      autoAcceptOrders: json['autoAcceptOrders'] as bool? ?? false,
      preparationTimeMinutes:
          (json['preparationTimeMinutes'] as num?)?.toInt() ?? 60,
      commissionRate: (json['commissionRate'] as num?)?.toDouble() ?? 0.07,
      isAvailableForDelivery: json['isAvailableForDelivery'] as bool? ?? true,
      isAvailableForPickup: json['isAvailableForPickup'] as bool? ?? false,
    );

Map<String, dynamic> _$VendorSettingsToJson(VendorSettings instance) =>
    <String, dynamic>{
      'acceptsPreOrders': instance.acceptsPreOrders,
      'maxPreOrderDays': instance.maxPreOrderDays,
      'autoAcceptOrders': instance.autoAcceptOrders,
      'preparationTimeMinutes': instance.preparationTimeMinutes,
      'commissionRate': instance.commissionRate,
      'isAvailableForDelivery': instance.isAvailableForDelivery,
      'isAvailableForPickup': instance.isAvailableForPickup,
    };
