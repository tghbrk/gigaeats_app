// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Customer _$CustomerFromJson(Map<String, dynamic> json) => Customer(
  id: json['id'] as String,
  salesAgentId: json['salesAgentId'] as String,
  type: $enumDecode(_$CustomerTypeEnumMap, json['type']),
  organizationName: json['organizationName'] as String,
  contactPersonName: json['contactPersonName'] as String,
  email: json['email'] as String,
  phoneNumber: json['phoneNumber'] as String,
  alternatePhoneNumber: json['alternatePhoneNumber'] as String?,
  address: CustomerAddress.fromJson(json['address'] as Map<String, dynamic>),
  businessInfo: json['businessInfo'] == null
      ? null
      : CustomerBusinessInfo.fromJson(
          json['businessInfo'] as Map<String, dynamic>,
        ),
  preferences: CustomerPreferences.fromJson(
    json['preferences'] as Map<String, dynamic>,
  ),
  totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
  totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
  averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
  lastOrderDate: DateTime.parse(json['lastOrderDate'] as String),
  isActive: json['isActive'] as bool? ?? true,
  isVerified: json['isVerified'] as bool? ?? false,
  notes: json['notes'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CustomerToJson(Customer instance) => <String, dynamic>{
  'id': instance.id,
  'salesAgentId': instance.salesAgentId,
  'type': _$CustomerTypeEnumMap[instance.type]!,
  'organizationName': instance.organizationName,
  'contactPersonName': instance.contactPersonName,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'alternatePhoneNumber': instance.alternatePhoneNumber,
  'address': instance.address,
  'businessInfo': instance.businessInfo,
  'preferences': instance.preferences,
  'totalSpent': instance.totalSpent,
  'totalOrders': instance.totalOrders,
  'averageOrderValue': instance.averageOrderValue,
  'lastOrderDate': instance.lastOrderDate.toIso8601String(),
  'isActive': instance.isActive,
  'isVerified': instance.isVerified,
  'notes': instance.notes,
  'tags': instance.tags,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$CustomerTypeEnumMap = {
  CustomerType.corporate: 'corporate',
  CustomerType.school: 'school',
  CustomerType.hospital: 'hospital',
  CustomerType.government: 'government',
  CustomerType.event: 'event',
  CustomerType.catering: 'catering',
  CustomerType.other: 'other',
};

CustomerAddress _$CustomerAddressFromJson(Map<String, dynamic> json) =>
    CustomerAddress(
      street: json['street'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      postcode: json['postcode'] as String,
      country: json['country'] as String? ?? 'Malaysia',
      buildingName: json['buildingName'] as String?,
      floor: json['floor'] as String?,
      unit: json['unit'] as String?,
      deliveryInstructions: json['deliveryInstructions'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$CustomerAddressToJson(CustomerAddress instance) =>
    <String, dynamic>{
      'street': instance.street,
      'city': instance.city,
      'state': instance.state,
      'postcode': instance.postcode,
      'country': instance.country,
      'buildingName': instance.buildingName,
      'floor': instance.floor,
      'unit': instance.unit,
      'deliveryInstructions': instance.deliveryInstructions,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

CustomerBusinessInfo _$CustomerBusinessInfoFromJson(
  Map<String, dynamic> json,
) => CustomerBusinessInfo(
  companyRegistrationNumber: json['companyRegistrationNumber'] as String?,
  taxId: json['taxId'] as String?,
  industry: json['industry'] as String,
  employeeCount: (json['employeeCount'] as num).toInt(),
  website: json['website'] as String?,
  businessHours:
      (json['businessHours'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  requiresInvoice: json['requiresInvoice'] as bool? ?? false,
  billingEmail: json['billingEmail'] as String?,
);

Map<String, dynamic> _$CustomerBusinessInfoToJson(
  CustomerBusinessInfo instance,
) => <String, dynamic>{
  'companyRegistrationNumber': instance.companyRegistrationNumber,
  'taxId': instance.taxId,
  'industry': instance.industry,
  'employeeCount': instance.employeeCount,
  'website': instance.website,
  'businessHours': instance.businessHours,
  'requiresInvoice': instance.requiresInvoice,
  'billingEmail': instance.billingEmail,
};

CustomerPreferences _$CustomerPreferencesFromJson(Map<String, dynamic> json) =>
    CustomerPreferences(
      preferredCuisines:
          (json['preferredCuisines'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      dietaryRestrictions:
          (json['dietaryRestrictions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      halalOnly: json['halalOnly'] as bool? ?? false,
      vegetarianOptions: json['vegetarianOptions'] as bool? ?? false,
      veganOptions: json['veganOptions'] as bool? ?? false,
      spiceToleranceLevel: (json['spiceToleranceLevel'] as num?)?.toInt() ?? 2,
      budgetRangeMin: (json['budgetRangeMin'] as num?)?.toDouble() ?? 0.0,
      budgetRangeMax: (json['budgetRangeMax'] as num?)?.toDouble() ?? 1000.0,
      preferredDeliveryTimes:
          (json['preferredDeliveryTimes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      advanceOrderDays: (json['advanceOrderDays'] as num?)?.toInt() ?? 1,
      allowSubstitutions: json['allowSubstitutions'] as bool? ?? true,
      specialInstructions: json['specialInstructions'] as String?,
    );

Map<String, dynamic> _$CustomerPreferencesToJson(
  CustomerPreferences instance,
) => <String, dynamic>{
  'preferredCuisines': instance.preferredCuisines,
  'dietaryRestrictions': instance.dietaryRestrictions,
  'halalOnly': instance.halalOnly,
  'vegetarianOptions': instance.vegetarianOptions,
  'veganOptions': instance.veganOptions,
  'spiceToleranceLevel': instance.spiceToleranceLevel,
  'budgetRangeMin': instance.budgetRangeMin,
  'budgetRangeMax': instance.budgetRangeMax,
  'preferredDeliveryTimes': instance.preferredDeliveryTimes,
  'advanceOrderDays': instance.advanceOrderDays,
  'allowSubstitutions': instance.allowSubstitutions,
  'specialInstructions': instance.specialInstructions,
};
