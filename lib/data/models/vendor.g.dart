// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vendor _$VendorFromJson(Map<String, dynamic> json) => Vendor(
  id: json['id'] as String,
  businessName: json['businessName'] as String,
  ownerName: json['ownerName'] as String,
  email: json['email'] as String,
  phoneNumber: json['phoneNumber'] as String,
  description: json['description'] as String,
  address: VendorAddress.fromJson(json['address'] as Map<String, dynamic>),
  cuisineTypes: (json['cuisineTypes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  businessInfo: VendorBusinessInfo.fromJson(
    json['businessInfo'] as Map<String, dynamic>,
  ),
  settings: VendorSettings.fromJson(json['settings'] as Map<String, dynamic>),
  rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
  totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
  isActive: json['isActive'] as bool? ?? true,
  isVerified: json['isVerified'] as bool? ?? false,
  isHalalCertified: json['isHalalCertified'] as bool? ?? false,
  profileImageUrl: json['profileImageUrl'] as String?,
  coverImageUrl: json['coverImageUrl'] as String?,
  galleryImages:
      (json['galleryImages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$VendorToJson(Vendor instance) => <String, dynamic>{
  'id': instance.id,
  'businessName': instance.businessName,
  'ownerName': instance.ownerName,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'description': instance.description,
  'address': instance.address,
  'cuisineTypes': instance.cuisineTypes,
  'businessInfo': instance.businessInfo,
  'settings': instance.settings,
  'rating': instance.rating,
  'totalReviews': instance.totalReviews,
  'isActive': instance.isActive,
  'isVerified': instance.isVerified,
  'isHalalCertified': instance.isHalalCertified,
  'profileImageUrl': instance.profileImageUrl,
  'coverImageUrl': instance.coverImageUrl,
  'galleryImages': instance.galleryImages,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
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
  isOpen: json['isOpen'] as bool,
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
