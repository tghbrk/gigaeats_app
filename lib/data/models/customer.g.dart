// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Customer _$CustomerFromJson(Map<String, dynamic> json) => Customer(
  id: json['id'] as String,
  salesAgentId: json['sales_agent_id'] as String,
  type: $enumDecode(_$CustomerTypeEnumMap, json['customer_type']),
  organizationName: json['organization_name'] as String,
  contactPersonName: json['contact_person_name'] as String,
  email: json['email'] as String,
  phoneNumber: json['phone_number'] as String,
  alternatePhoneNumber: json['alternate_phone_number'] as String?,
  address: CustomerAddress.fromJson(json['address'] as Map<String, dynamic>),
  businessInfo: json['business_info'] == null
      ? null
      : CustomerBusinessInfo.fromJson(
          json['business_info'] as Map<String, dynamic>,
        ),
  preferences: CustomerPreferences.fromJson(
    json['preferences'] as Map<String, dynamic>,
  ),
  totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
  totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
  averageOrderValue: (json['average_order_value'] as num?)?.toDouble() ?? 0.0,
  lastOrderDate: json['last_order_date'] == null
      ? null
      : DateTime.parse(json['last_order_date'] as String),
  isActive: json['is_active'] as bool? ?? true,
  isVerified: json['is_verified'] as bool? ?? false,
  notes: json['notes'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$CustomerToJson(Customer instance) => <String, dynamic>{
  'id': instance.id,
  'sales_agent_id': instance.salesAgentId,
  'customer_type': _$CustomerTypeEnumMap[instance.type]!,
  'organization_name': instance.organizationName,
  'contact_person_name': instance.contactPersonName,
  'email': instance.email,
  'phone_number': instance.phoneNumber,
  'alternate_phone_number': instance.alternatePhoneNumber,
  'address': instance.address,
  'business_info': instance.businessInfo,
  'preferences': instance.preferences,
  'total_spent': instance.totalSpent,
  'total_orders': instance.totalOrders,
  'average_order_value': instance.averageOrderValue,
  'last_order_date': instance.lastOrderDate?.toIso8601String(),
  'is_active': instance.isActive,
  'is_verified': instance.isVerified,
  'notes': instance.notes,
  'tags': instance.tags,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
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
      buildingName: json['building_name'] as String?,
      floor: json['floor'] as String?,
      unit: json['unit'] as String?,
      deliveryInstructions: json['delivery_instructions'] as String?,
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
      'building_name': instance.buildingName,
      'floor': instance.floor,
      'unit': instance.unit,
      'delivery_instructions': instance.deliveryInstructions,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

CustomerBusinessInfo _$CustomerBusinessInfoFromJson(
  Map<String, dynamic> json,
) => CustomerBusinessInfo(
  companyRegistrationNumber: json['company_registration_number'] as String?,
  taxId: json['tax_id'] as String?,
  industry: json['industry'] as String,
  employeeCount: (json['employee_count'] as num).toInt(),
  website: json['website'] as String?,
  businessHours:
      (json['business_hours'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  requiresInvoice: json['requires_invoice'] as bool? ?? false,
  billingEmail: json['billing_email'] as String?,
);

Map<String, dynamic> _$CustomerBusinessInfoToJson(
  CustomerBusinessInfo instance,
) => <String, dynamic>{
  'company_registration_number': instance.companyRegistrationNumber,
  'tax_id': instance.taxId,
  'industry': instance.industry,
  'employee_count': instance.employeeCount,
  'website': instance.website,
  'business_hours': instance.businessHours,
  'requires_invoice': instance.requiresInvoice,
  'billing_email': instance.billingEmail,
};

CustomerPreferences _$CustomerPreferencesFromJson(Map<String, dynamic> json) =>
    CustomerPreferences(
      preferredCuisines:
          (json['preferred_cuisines'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      dietaryRestrictions:
          (json['dietary_restrictions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      halalOnly: json['halal_only'] as bool? ?? false,
      vegetarianOptions: json['vegetarian_options'] as bool? ?? false,
      veganOptions: json['vegan_options'] as bool? ?? false,
      spiceToleranceLevel:
          (json['spice_tolerance_level'] as num?)?.toInt() ?? 2,
      budgetRangeMin: (json['budget_range_min'] as num?)?.toDouble() ?? 0.0,
      budgetRangeMax: (json['budget_range_max'] as num?)?.toDouble() ?? 1000.0,
      preferredDeliveryTimes:
          (json['preferred_delivery_times'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      advanceOrderDays: (json['advance_order_days'] as num?)?.toInt() ?? 1,
      allowSubstitutions: json['allow_substitutions'] as bool? ?? true,
      specialInstructions: json['special_instructions'] as String?,
    );

Map<String, dynamic> _$CustomerPreferencesToJson(
  CustomerPreferences instance,
) => <String, dynamic>{
  'preferred_cuisines': instance.preferredCuisines,
  'dietary_restrictions': instance.dietaryRestrictions,
  'halal_only': instance.halalOnly,
  'vegetarian_options': instance.vegetarianOptions,
  'vegan_options': instance.veganOptions,
  'spice_tolerance_level': instance.spiceToleranceLevel,
  'budget_range_min': instance.budgetRangeMin,
  'budget_range_max': instance.budgetRangeMax,
  'preferred_delivery_times': instance.preferredDeliveryTimes,
  'advance_order_days': instance.advanceOrderDays,
  'allow_substitutions': instance.allowSubstitutions,
  'special_instructions': instance.specialInstructions,
};
