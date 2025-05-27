// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['fullName'] as String,
  phoneNumber: json['phoneNumber'] as String,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  profileImageUrl: json['profileImageUrl'] as String?,
  isVerified: json['isVerified'] as bool,
  isActive: json['isActive'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'fullName': instance.fullName,
  'phoneNumber': instance.phoneNumber,
  'role': _$UserRoleEnumMap[instance.role]!,
  'profileImageUrl': instance.profileImageUrl,
  'isVerified': instance.isVerified,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
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
  fullName: json['fullName'] as String,
  phoneNumber: json['phoneNumber'] as String,
  profileImageUrl: json['profileImageUrl'] as String?,
  isVerified: json['isVerified'] as bool,
  isActive: json['isActive'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
  companyName: json['companyName'] as String?,
  businessRegistrationNumber: json['businessRegistrationNumber'] as String?,
  commissionRate: (json['commissionRate'] as num).toDouble(),
  totalEarnings: (json['totalEarnings'] as num).toDouble(),
  totalOrders: (json['totalOrders'] as num).toInt(),
  assignedRegions: (json['assignedRegions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$SalesAgentToJson(SalesAgent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'fullName': instance.fullName,
      'phoneNumber': instance.phoneNumber,
      'profileImageUrl': instance.profileImageUrl,
      'isVerified': instance.isVerified,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'metadata': instance.metadata,
      'companyName': instance.companyName,
      'businessRegistrationNumber': instance.businessRegistrationNumber,
      'commissionRate': instance.commissionRate,
      'totalEarnings': instance.totalEarnings,
      'totalOrders': instance.totalOrders,
      'assignedRegions': instance.assignedRegions,
    };

Vendor _$VendorFromJson(Map<String, dynamic> json) => Vendor(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['fullName'] as String,
  phoneNumber: json['phoneNumber'] as String,
  profileImageUrl: json['profileImageUrl'] as String?,
  isVerified: json['isVerified'] as bool,
  isActive: json['isActive'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
  businessName: json['businessName'] as String,
  businessRegistrationNumber: json['businessRegistrationNumber'] as String,
  businessAddress: json['businessAddress'] as String,
  businessType: json['businessType'] as String,
  cuisineTypes: (json['cuisineTypes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  isHalalCertified: json['isHalalCertified'] as bool,
  halalCertificationNumber: json['halalCertificationNumber'] as String?,
  rating: (json['rating'] as num).toDouble(),
  totalOrders: (json['totalOrders'] as num).toInt(),
  businessHours: json['businessHours'] as Map<String, dynamic>,
);

Map<String, dynamic> _$VendorToJson(Vendor instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'fullName': instance.fullName,
  'phoneNumber': instance.phoneNumber,
  'profileImageUrl': instance.profileImageUrl,
  'isVerified': instance.isVerified,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'metadata': instance.metadata,
  'businessName': instance.businessName,
  'businessRegistrationNumber': instance.businessRegistrationNumber,
  'businessAddress': instance.businessAddress,
  'businessType': instance.businessType,
  'cuisineTypes': instance.cuisineTypes,
  'isHalalCertified': instance.isHalalCertified,
  'halalCertificationNumber': instance.halalCertificationNumber,
  'rating': instance.rating,
  'totalOrders': instance.totalOrders,
  'businessHours': instance.businessHours,
};
