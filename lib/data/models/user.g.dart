// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['full_name'] as String,
  phoneNumber: json['phone_number'] as String,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  profileImageUrl: json['profile_image_url'] as String?,
  isVerified: json['is_verified'] as bool,
  isActive: json['is_active'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'full_name': instance.fullName,
  'phone_number': instance.phoneNumber,
  'role': _$UserRoleEnumMap[instance.role]!,
  'profile_image_url': instance.profileImageUrl,
  'is_verified': instance.isVerified,
  'is_active': instance.isActive,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'metadata': instance.metadata,
};

const _$UserRoleEnumMap = {
  UserRole.salesAgent: 'salesAgent',
  UserRole.vendor: 'vendor',
  UserRole.admin: 'admin',
  UserRole.customer: 'customer',
};

SalesAgent _$SalesAgentFromJson(Map<String, dynamic> json) => SalesAgent(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['full_name'] as String,
  phoneNumber: json['phone_number'] as String,
  profileImageUrl: json['profile_image_url'] as String?,
  isVerified: json['is_verified'] as bool,
  isActive: json['is_active'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
  companyName: json['company_name'] as String?,
  businessRegistrationNumber: json['business_registration_number'] as String?,
  commissionRate: (json['commission_rate'] as num).toDouble(),
  totalEarnings: (json['total_earnings'] as num).toDouble(),
  totalOrders: (json['total_orders'] as num).toInt(),
  assignedRegions: (json['assigned_regions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$SalesAgentToJson(SalesAgent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.fullName,
      'phone_number': instance.phoneNumber,
      'profile_image_url': instance.profileImageUrl,
      'is_verified': instance.isVerified,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'metadata': instance.metadata,
      'company_name': instance.companyName,
      'business_registration_number': instance.businessRegistrationNumber,
      'commission_rate': instance.commissionRate,
      'total_earnings': instance.totalEarnings,
      'total_orders': instance.totalOrders,
      'assigned_regions': instance.assignedRegions,
    };

Vendor _$VendorFromJson(Map<String, dynamic> json) => Vendor(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['full_name'] as String,
  phoneNumber: json['phone_number'] as String,
  profileImageUrl: json['profile_image_url'] as String?,
  isVerified: json['is_verified'] as bool,
  isActive: json['is_active'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
  businessName: json['business_name'] as String,
  businessRegistrationNumber: json['business_registration_number'] as String,
  businessAddress: json['business_address'] as String,
  businessType: json['business_type'] as String,
  cuisineTypes: (json['cuisine_types'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  isHalalCertified: json['is_halal_certified'] as bool,
  halalCertificationNumber: json['halal_certification_number'] as String?,
  rating: (json['rating'] as num).toDouble(),
  totalOrders: (json['total_orders'] as num).toInt(),
  businessHours: json['business_hours'] as Map<String, dynamic>,
);

Map<String, dynamic> _$VendorToJson(Vendor instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'full_name': instance.fullName,
  'phone_number': instance.phoneNumber,
  'profile_image_url': instance.profileImageUrl,
  'is_verified': instance.isVerified,
  'is_active': instance.isActive,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'metadata': instance.metadata,
  'business_name': instance.businessName,
  'business_registration_number': instance.businessRegistrationNumber,
  'business_address': instance.businessAddress,
  'business_type': instance.businessType,
  'cuisine_types': instance.cuisineTypes,
  'is_halal_certified': instance.isHalalCertified,
  'halal_certification_number': instance.halalCertificationNumber,
  'rating': instance.rating,
  'total_orders': instance.totalOrders,
  'business_hours': instance.businessHours,
};
