import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'user_role.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final UserRole role;
  final String? profileImageUrl;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.profileImageUrl,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
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
  }) {
    return User(
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
    );
  }

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
      ];

  @override
  String toString() {
    return 'User(id: $id, email: $email, fullName: $fullName, role: $role)';
  }
}

@JsonSerializable()
class SalesAgent extends User {
  final String? companyName;
  final String? businessRegistrationNumber;
  final double commissionRate;
  final double totalEarnings;
  final int totalOrders;
  final List<String> assignedRegions;

  const SalesAgent({
    required super.id,
    required super.email,
    required super.fullName,
    required super.phoneNumber,
    super.profileImageUrl,
    required super.isVerified,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.metadata,
    this.companyName,
    this.businessRegistrationNumber,
    required this.commissionRate,
    required this.totalEarnings,
    required this.totalOrders,
    required this.assignedRegions,
  }) : super(role: UserRole.salesAgent);

  factory SalesAgent.fromJson(Map<String, dynamic> json) =>
      _$SalesAgentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SalesAgentToJson(this);

  SalesAgent copyWithSalesAgent({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? companyName,
    String? businessRegistrationNumber,
    double? commissionRate,
    double? totalEarnings,
    int? totalOrders,
    List<String>? assignedRegions,
  }) {
    return SalesAgent(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      companyName: companyName ?? this.companyName,
      businessRegistrationNumber:
          businessRegistrationNumber ?? this.businessRegistrationNumber,
      commissionRate: commissionRate ?? this.commissionRate,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalOrders: totalOrders ?? this.totalOrders,
      assignedRegions: assignedRegions ?? this.assignedRegions,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        companyName,
        businessRegistrationNumber,
        commissionRate,
        totalEarnings,
        totalOrders,
        assignedRegions,
      ];
}

@JsonSerializable()
class Vendor extends User {
  final String businessName;
  final String businessRegistrationNumber;
  final String businessAddress;
  final String businessType;
  final List<String> cuisineTypes;
  final bool isHalalCertified;
  final String? halalCertificationNumber;
  final double rating;
  final int totalOrders;
  final Map<String, dynamic> businessHours;

  const Vendor({
    required super.id,
    required super.email,
    required super.fullName,
    required super.phoneNumber,
    super.profileImageUrl,
    required super.isVerified,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.metadata,
    required this.businessName,
    required this.businessRegistrationNumber,
    required this.businessAddress,
    required this.businessType,
    required this.cuisineTypes,
    required this.isHalalCertified,
    this.halalCertificationNumber,
    required this.rating,
    required this.totalOrders,
    required this.businessHours,
  }) : super(role: UserRole.vendor);

  factory Vendor.fromJson(Map<String, dynamic> json) => _$VendorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$VendorToJson(this);

  @override
  List<Object?> get props => [
        ...super.props,
        businessName,
        businessRegistrationNumber,
        businessAddress,
        businessType,
        cuisineTypes,
        isHalalCertified,
        halalCertificationNumber,
        rating,
        totalOrders,
        businessHours,
      ];
}
