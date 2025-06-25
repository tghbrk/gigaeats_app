import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../data/models/user.dart';

part 'customer_account_models.g.dart';

/// Result class for customer invitation creation
class CustomerInvitationResult extends Equatable {
  final bool success;
  final String? token;
  final DateTime? expiresAt;
  final String message;

  const CustomerInvitationResult._({
    required this.success,
    this.token,
    this.expiresAt,
    required this.message,
  });

  factory CustomerInvitationResult.success({
    required String token,
    required DateTime expiresAt,
    required String message,
  }) {
    return CustomerInvitationResult._(
      success: true,
      token: token,
      expiresAt: expiresAt,
      message: message,
    );
  }

  factory CustomerInvitationResult.failure(String message) {
    return CustomerInvitationResult._(
      success: false,
      message: message,
    );
  }

  @override
  List<Object?> get props => [success, token, expiresAt, message];
}

/// Result class for invitation token validation
class InvitationValidationResult extends Equatable {
  final bool success;
  final String? customerId;
  final String? customerEmail;
  final String? customerName;
  final DateTime? expiresAt;
  final String message;

  const InvitationValidationResult._({
    required this.success,
    this.customerId,
    this.customerEmail,
    this.customerName,
    this.expiresAt,
    required this.message,
  });

  factory InvitationValidationResult.success({
    required String customerId,
    required String customerEmail,
    required String customerName,
    required DateTime expiresAt,
  }) {
    return InvitationValidationResult._(
      success: true,
      customerId: customerId,
      customerEmail: customerEmail,
      customerName: customerName,
      expiresAt: expiresAt,
      message: 'Valid invitation token',
    );
  }

  factory InvitationValidationResult.failure(String message) {
    return InvitationValidationResult._(
      success: false,
      message: message,
    );
  }

  @override
  List<Object?> get props => [success, customerId, customerEmail, customerName, expiresAt, message];
}

/// Result class for customer account creation
class CustomerAccountCreationResult extends Equatable {
  final bool success;
  final User? user;
  final String? customerProfileId;
  final String message;

  const CustomerAccountCreationResult._({
    required this.success,
    this.user,
    this.customerProfileId,
    required this.message,
  });

  factory CustomerAccountCreationResult.success({
    required User user,
    required String customerProfileId,
    required String message,
  }) {
    return CustomerAccountCreationResult._(
      success: true,
      user: user,
      customerProfileId: customerProfileId,
      message: message,
    );
  }

  factory CustomerAccountCreationResult.failure(String message) {
    return CustomerAccountCreationResult._(
      success: false,
      message: message,
    );
  }

  @override
  List<Object?> get props => [success, user, customerProfileId, message];
}

/// Result class for customer linking
class CustomerLinkingResult extends Equatable {
  final bool success;
  final String? customerProfileId;
  final String message;

  const CustomerLinkingResult._({
    required this.success,
    this.customerProfileId,
    required this.message,
  });

  factory CustomerLinkingResult.success({
    required String customerProfileId,
    required String message,
  }) {
    return CustomerLinkingResult._(
      success: true,
      customerProfileId: customerProfileId,
      message: message,
    );
  }

  factory CustomerLinkingResult.failure(String message) {
    return CustomerLinkingResult._(
      success: false,
      message: message,
    );
  }

  @override
  List<Object?> get props => [success, customerProfileId, message];
}

/// Model for customer invitation
@JsonSerializable()
class CustomerInvitation extends Equatable {
  final String id;
  @JsonKey(name: 'customer_id')
  final String customerId;
  final String token;
  final String email;
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;
  @JsonKey(name: 'used_at')
  final DateTime? usedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  // Customer details from join
  @JsonKey(name: 'organization_name')
  final String? organizationName;
  @JsonKey(name: 'contact_person_name')
  final String? contactPersonName;

  const CustomerInvitation({
    required this.id,
    required this.customerId,
    required this.token,
    required this.email,
    required this.expiresAt,
    this.usedAt,
    required this.createdAt,
    this.organizationName,
    this.contactPersonName,
  });

  factory CustomerInvitation.fromJson(Map<String, dynamic> json) {
    // Handle nested customer data
    final customerData = json['customers'] as Map<String, dynamic>?;
    
    return CustomerInvitation(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      token: json['token'] as String,
      email: json['email'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      usedAt: json['used_at'] != null ? DateTime.parse(json['used_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      organizationName: customerData?['organization_name'] as String?,
      contactPersonName: customerData?['contact_person_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$CustomerInvitationToJson(this);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isUsed => usedAt != null;
  bool get isActive => !isExpired && !isUsed;

  String get customerDisplayName => contactPersonName ?? organizationName ?? email;

  @override
  List<Object?> get props => [
        id,
        customerId,
        token,
        email,
        expiresAt,
        usedAt,
        createdAt,
        organizationName,
        contactPersonName,
      ];
}
