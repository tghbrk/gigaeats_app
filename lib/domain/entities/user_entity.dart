import 'package:equatable/equatable.dart';

/// User entity representing the core user data
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final UserRoleEntity role;
  final bool isVerified;
  final bool isActive;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.isVerified,
    required this.isActive,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of the user entity with updated fields
  UserEntity copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    UserRoleEntity? role,
    bool? isVerified,
    bool? isActive,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        phoneNumber,
        role,
        isVerified,
        isActive,
        profileImageUrl,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'UserEntity(id: $id, email: $email, fullName: $fullName, role: $role)';
  }
}

/// User role entity
enum UserRoleEntity {
  customer,
  vendor,
  salesAgent,
  admin;

  /// Get display name for the role
  String get displayName {
    switch (this) {
      case UserRoleEntity.customer:
        return 'Customer';
      case UserRoleEntity.vendor:
        return 'Vendor';
      case UserRoleEntity.salesAgent:
        return 'Sales Agent';
      case UserRoleEntity.admin:
        return 'Administrator';
    }
  }

  /// Get role value as string
  String get value {
    switch (this) {
      case UserRoleEntity.customer:
        return 'customer';
      case UserRoleEntity.vendor:
        return 'vendor';
      case UserRoleEntity.salesAgent:
        return 'sales_agent';
      case UserRoleEntity.admin:
        return 'admin';
    }
  }

  /// Create role from string value
  static UserRoleEntity fromString(String value) {
    switch (value.toLowerCase()) {
      case 'customer':
        return UserRoleEntity.customer;
      case 'vendor':
        return UserRoleEntity.vendor;
      case 'sales_agent':
      case 'salesagent':
        return UserRoleEntity.salesAgent;
      case 'admin':
      case 'administrator':
        return UserRoleEntity.admin;
      default:
        throw ArgumentError('Invalid user role: $value');
    }
  }

  /// Check if role has specific permission
  bool hasPermission(String permission) {
    final permissions = _rolePermissions[this] ?? <String>{};
    return permissions.contains(permission);
  }

  /// Get all permissions for this role
  Set<String> get permissions => _rolePermissions[this] ?? <String>{};

  /// Role permissions mapping
  static const Map<UserRoleEntity, Set<String>> _rolePermissions = {
    UserRoleEntity.customer: {
      'place_order',
      'view_orders',
      'update_profile',
      'view_vendors',
      'view_menu_items',
    },
    UserRoleEntity.vendor: {
      'manage_menu',
      'view_orders',
      'update_order_status',
      'view_analytics',
      'manage_profile',
      'view_customers',
    },
    UserRoleEntity.salesAgent: {
      'view_all_vendors',
      'manage_vendor_status',
      'view_reports',
      'create_orders',
      'manage_customers',
      'view_analytics',
    },
    UserRoleEntity.admin: {
      'manage_users',
      'manage_vendors',
      'view_all_data',
      'system_settings',
      'manage_roles',
      'view_analytics',
      'manage_orders',
    },
  };
}

/// User profile entity for detailed user information
class UserProfileEntity extends Equatable {
  final String userId;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final DateTime? dateOfBirth;
  final String? gender;
  final Map<String, dynamic>? preferences;
  final DateTime? lastLoginAt;
  final DateTime updatedAt;

  const UserProfileEntity({
    required this.userId,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.dateOfBirth,
    this.gender,
    this.preferences,
    this.lastLoginAt,
    required this.updatedAt,
  });

  /// Create a copy of the user profile entity with updated fields
  UserProfileEntity copyWith({
    String? userId,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    DateTime? dateOfBirth,
    String? gender,
    Map<String, dynamic>? preferences,
    DateTime? lastLoginAt,
    DateTime? updatedAt,
  }) {
    return UserProfileEntity(
      userId: userId ?? this.userId,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      preferences: preferences ?? this.preferences,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        address,
        city,
        state,
        postalCode,
        country,
        dateOfBirth,
        gender,
        preferences,
        lastLoginAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'UserProfileEntity(userId: $userId, city: $city, state: $state)';
  }
}
