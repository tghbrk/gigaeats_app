import 'package:equatable/equatable.dart';

/// Customer profile model for user management
class CustomerProfile extends Equatable {
  final String id;
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? preferredLanguage;
  final String? organizationName;
  final String? organizationType;
  final String? businessRegistrationNumber;
  final bool isBusinessAccount;
  final bool isVerified;
  final bool isActive;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerProfile({
    required this.id,
    required this.userId,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.preferredLanguage,
    this.organizationName,
    this.organizationType,
    this.businessRegistrationNumber,
    this.isBusinessAccount = false,
    this.isVerified = false,
    this.isActive = true,
    this.preferences = const {},
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create CustomerProfile from JSON
  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      preferredLanguage: json['preferred_language'] as String?,
      organizationName: json['organization_name'] as String?,
      organizationType: json['organization_type'] as String?,
      businessRegistrationNumber: json['business_registration_number'] as String?,
      isBusinessAccount: json['is_business_account'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert CustomerProfile to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'preferred_language': preferredLanguage,
      'organization_name': organizationName,
      'organization_type': organizationType,
      'business_registration_number': businessRegistrationNumber,
      'is_business_account': isBusinessAccount,
      'is_verified': isVerified,
      'is_active': isActive,
      'preferences': preferences,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of CustomerProfile with updated fields
  CustomerProfile copyWith({
    String? id,
    String? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? preferredLanguage,
    String? organizationName,
    String? organizationType,
    String? businessRegistrationNumber,
    bool? isBusinessAccount,
    bool? isVerified,
    bool? isActive,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      organizationName: organizationName ?? this.organizationName,
      organizationType: organizationType ?? this.organizationType,
      businessRegistrationNumber: businessRegistrationNumber ?? this.businessRegistrationNumber,
      isBusinessAccount: isBusinessAccount ?? this.isBusinessAccount,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    } else if (organizationName != null) {
      return organizationName!;
    } else {
      return 'Customer';
    }
  }

  /// Get display name (organization name for business accounts, full name for personal)
  String get displayName {
    if (isBusinessAccount && organizationName != null) {
      return organizationName!;
    }
    return fullName;
  }

  /// Check if profile is complete
  bool get isComplete {
    if (isBusinessAccount) {
      return organizationName != null && 
             organizationType != null &&
             phoneNumber != null &&
             email != null;
    } else {
      return firstName != null && 
             lastName != null &&
             phoneNumber != null &&
             email != null;
    }
  }

  /// Get completion percentage
  double get completionPercentage {
    int totalFields = isBusinessAccount ? 6 : 6;
    int completedFields = 0;

    if (isBusinessAccount) {
      if (organizationName != null) completedFields++;
      if (organizationType != null) completedFields++;
      if (businessRegistrationNumber != null) completedFields++;
    } else {
      if (firstName != null) completedFields++;
      if (lastName != null) completedFields++;
    }

    if (email != null) completedFields++;
    if (phoneNumber != null) completedFields++;
    if (profileImageUrl != null) completedFields++;

    return completedFields / totalFields;
  }

  /// Create a test customer profile for development
  factory CustomerProfile.test({
    String? id,
    String? userId,
    bool isBusinessAccount = false,
  }) {
    final now = DateTime.now();
    
    if (isBusinessAccount) {
      return CustomerProfile(
        id: id ?? 'customer-profile-1',
        userId: userId ?? 'user-1',
        email: 'business@example.com',
        phoneNumber: '+60123456789',
        organizationName: 'Test Business Sdn Bhd',
        organizationType: 'Restaurant',
        businessRegistrationNumber: 'ROC123456789',
        isBusinessAccount: true,
        isVerified: true,
        isActive: true,
        preferences: {
          'notifications': true,
          'marketing_emails': false,
        },
        createdAt: now,
        updatedAt: now,
      );
    } else {
      return CustomerProfile(
        id: id ?? 'customer-profile-1',
        userId: userId ?? 'user-1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        phoneNumber: '+60123456789',
        preferredLanguage: 'en',
        isBusinessAccount: false,
        isVerified: true,
        isActive: true,
        preferences: {
          'notifications': true,
          'marketing_emails': true,
        },
        createdAt: now,
        updatedAt: now,
      );
    }
  }

  /// Create an empty customer profile for forms
  factory CustomerProfile.empty({
    required String userId,
    bool isBusinessAccount = false,
  }) {
    final now = DateTime.now();
    return CustomerProfile(
      id: '',
      userId: userId,
      isBusinessAccount: isBusinessAccount,
      isVerified: false,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        firstName,
        lastName,
        email,
        phoneNumber,
        profileImageUrl,
        preferredLanguage,
        organizationName,
        organizationType,
        businessRegistrationNumber,
        isBusinessAccount,
        isVerified,
        isActive,
        preferences,
        metadata,
        createdAt,
        updatedAt,
      ];
}
