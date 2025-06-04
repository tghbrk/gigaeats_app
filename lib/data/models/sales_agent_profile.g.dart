// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_agent_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SalesAgentProfile _$SalesAgentProfileFromJson(Map<String, dynamic> json) =>
    SalesAgentProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      role: _roleFromJson(json['role'] as String),
      profileImageUrl: json['profile_image_url'] as String?,
      isVerified: json['is_verified'] as bool,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      profileId: json['profile_id'] as String?,
      userId: json['user_id'] as String?,
      companyName: json['company_name'] as String?,
      businessRegistrationNumber:
          json['business_registration_number'] as String?,
      businessAddress: json['business_address'] as String?,
      businessType: json['business_type'] as String?,
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0.07,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      assignedRegions:
          (json['assigned_regions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      preferences: json['preferences'] as Map<String, dynamic>?,
      kycDocuments: json['kyc_documents'] as Map<String, dynamic>?,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
    );

Map<String, dynamic> _$SalesAgentProfileToJson(SalesAgentProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.fullName,
      'phone_number': instance.phoneNumber,
      'role': _roleToJson(instance.role),
      'profile_image_url': instance.profileImageUrl,
      'is_verified': instance.isVerified,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'metadata': instance.metadata,
      'profile_id': instance.profileId,
      'user_id': instance.userId,
      'company_name': instance.companyName,
      'business_registration_number': instance.businessRegistrationNumber,
      'business_address': instance.businessAddress,
      'business_type': instance.businessType,
      'commission_rate': instance.commissionRate,
      'total_earnings': instance.totalEarnings,
      'total_orders': instance.totalOrders,
      'assigned_regions': instance.assignedRegions,
      'preferences': instance.preferences,
      'kyc_documents': instance.kycDocuments,
      'verification_status': instance.verificationStatus,
    };
