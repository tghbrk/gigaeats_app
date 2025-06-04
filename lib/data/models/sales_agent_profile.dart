import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'user.dart';
import 'user_role.dart';

part 'sales_agent_profile.g.dart';

@JsonSerializable()
class SalesAgentProfile extends Equatable {
  // User basic information
  final String id;
  final String email;
  @JsonKey(name: 'full_name')
  final String fullName;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  @JsonKey(fromJson: _roleFromJson, toJson: _roleToJson)
  final UserRole role;
  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  // Profile specific information from user_profiles table
  @JsonKey(name: 'profile_id')
  final String? profileId;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'company_name')
  final String? companyName;
  @JsonKey(name: 'business_registration_number')
  final String? businessRegistrationNumber;
  @JsonKey(name: 'business_address')
  final String? businessAddress;
  @JsonKey(name: 'business_type')
  final String? businessType;
  @JsonKey(name: 'commission_rate')
  final double commissionRate;
  @JsonKey(name: 'total_earnings')
  final double totalEarnings;
  @JsonKey(name: 'total_orders')
  final int totalOrders;
  @JsonKey(name: 'assigned_regions')
  final List<String> assignedRegions;
  final Map<String, dynamic>? preferences;
  @JsonKey(name: 'kyc_documents')
  final Map<String, dynamic>? kycDocuments;
  @JsonKey(name: 'verification_status')
  final String verificationStatus;

  const SalesAgentProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    this.profileImageUrl,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.profileId,
    this.userId,
    this.companyName,
    this.businessRegistrationNumber,
    this.businessAddress,
    this.businessType,
    this.commissionRate = 0.07,
    this.totalEarnings = 0.0,
    this.totalOrders = 0,
    this.assignedRegions = const [],
    this.preferences,
    this.kycDocuments,
    this.verificationStatus = 'pending',
  });

  factory SalesAgentProfile.fromJson(Map<String, dynamic> json) =>
      _$SalesAgentProfileFromJson(json);

  Map<String, dynamic> toJson() => _$SalesAgentProfileToJson(this);

  // Create from User and profile data
  factory SalesAgentProfile.fromUserAndProfile({
    required User user,
    Map<String, dynamic>? profileData,
  }) {
    return SalesAgentProfile(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      phoneNumber: user.phoneNumber,
      role: user.role,
      profileImageUrl: user.profileImageUrl,
      isVerified: user.isVerified,
      isActive: user.isActive,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      metadata: user.metadata,
      profileId: profileData?['id'],
      userId: profileData?['user_id'],
      companyName: profileData?['company_name'],
      businessRegistrationNumber: profileData?['business_registration_number'],
      businessAddress: profileData?['business_address'],
      businessType: profileData?['business_type'],
      commissionRate: (profileData?['commission_rate'] as num?)?.toDouble() ?? 0.07,
      totalEarnings: (profileData?['total_earnings'] as num?)?.toDouble() ?? 0.0,
      totalOrders: profileData?['total_orders'] ?? 0,
      assignedRegions: List<String>.from(profileData?['assigned_regions'] ?? []),
      preferences: profileData?['preferences'],
      kycDocuments: profileData?['kyc_documents'],
      verificationStatus: profileData?['verification_status'] ?? 'pending',
    );
  }

  // Convert to User object
  User toUser() {
    return User(
      id: id,
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber,
      role: role,
      profileImageUrl: profileImageUrl,
      isVerified: isVerified,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: metadata,
    );
  }

  SalesAgentProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    UserRole? role,
    String? profileImageUrl,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? profileId,
    String? userId,
    String? companyName,
    String? businessRegistrationNumber,
    String? businessAddress,
    String? businessType,
    double? commissionRate,
    double? totalEarnings,
    int? totalOrders,
    List<String>? assignedRegions,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? kycDocuments,
    String? verificationStatus,
  }) {
    return SalesAgentProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      profileId: profileId ?? this.profileId,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      businessRegistrationNumber: businessRegistrationNumber ?? this.businessRegistrationNumber,
      businessAddress: businessAddress ?? this.businessAddress,
      businessType: businessType ?? this.businessType,
      commissionRate: commissionRate ?? this.commissionRate,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalOrders: totalOrders ?? this.totalOrders,
      assignedRegions: assignedRegions ?? this.assignedRegions,
      preferences: preferences ?? this.preferences,
      kycDocuments: kycDocuments ?? this.kycDocuments,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  // Convenience getters
  String get displayName => fullName.isNotEmpty ? fullName : email;
  String get initials => fullName.isNotEmpty 
      ? fullName.split(' ').map((name) => name.substring(0, 1)).take(2).join().toUpperCase()
      : email.substring(0, 1).toUpperCase();
  
  double get averageOrderValue => totalOrders > 0 ? totalEarnings / totalOrders : 0.0;
  
  bool get isProfileComplete => 
      companyName != null && 
      businessRegistrationNumber != null && 
      businessAddress != null && 
      businessType != null;

  bool get isKycVerified => verificationStatus == 'verified';

  String get formattedCommissionRate => '${(commissionRate * 100).toStringAsFixed(1)}%';

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        phoneNumber,
        role,
        profileImageUrl,
        isVerified,
        isActive,
        createdAt,
        updatedAt,
        metadata,
        profileId,
        userId,
        companyName,
        businessRegistrationNumber,
        businessAddress,
        businessType,
        commissionRate,
        totalEarnings,
        totalOrders,
        assignedRegions,
        preferences,
        kycDocuments,
        verificationStatus,
      ];

  @override
  String toString() {
    return 'SalesAgentProfile(id: $id, email: $email, fullName: $fullName, companyName: $companyName)';
  }
}

// Helper functions for JSON serialization
UserRole _roleFromJson(String role) => UserRole.fromString(role);
String _roleToJson(UserRole role) => role.value;
