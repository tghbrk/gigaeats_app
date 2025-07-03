import 'package:freezed_annotation/freezed_annotation.dart';

part 'cross_role_provisioning_models.freezed.dart';
part 'cross_role_provisioning_models.g.dart';

@freezed
class DriverInvitationResult with _$DriverInvitationResult {
  const factory DriverInvitationResult({
    required bool success,
    String? token,
    DateTime? expiresAt,
    required String message,
    Map<String, dynamic>? errorDetails,
  }) = _DriverInvitationResult;

  factory DriverInvitationResult.fromJson(Map<String, dynamic> json) =>
      _$DriverInvitationResultFromJson(json);
}

@freezed
class DriverInvitationValidation with _$DriverInvitationValidation {
  const factory DriverInvitationValidation({
    required bool valid,
    String? vendorId,
    required String email,
    required String driverName,
    required Map<String, dynamic> vehicleDetails,
    DateTime? expiresAt,
    required String message,
  }) = _DriverInvitationValidation;

  factory DriverInvitationValidation.fromJson(Map<String, dynamic> json) =>
      _$DriverInvitationValidationFromJson(json);
}

@freezed
class DriverAccountCreationResult with _$DriverAccountCreationResult {
  const factory DriverAccountCreationResult({
    required bool success,
    String? driverId,
    required String message,
    Map<String, dynamic>? errorDetails,
  }) = _DriverAccountCreationResult;

  factory DriverAccountCreationResult.fromJson(Map<String, dynamic> json) =>
      _$DriverAccountCreationResultFromJson(json);
}

@freezed
class DriverInvitation with _$DriverInvitation {
  const factory DriverInvitation({
    required String id,
    required String vendorId,
    required String token,
    required String email,
    String? phoneNumber,
    required String driverName,
    @Default({}) Map<String, dynamic> vehicleDetails,
    required String invitedBy,
    required DateTime expiresAt,
    DateTime? usedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DriverInvitation;

  factory DriverInvitation.fromJson(Map<String, dynamic> json) =>
      _$DriverInvitationFromJson(json);
}

@freezed
class RoleTransitionResult with _$RoleTransitionResult {
  const factory RoleTransitionResult({
    required bool success,
    String? requestId,
    required String message,
    Map<String, dynamic>? errorDetails,
  }) = _RoleTransitionResult;

  factory RoleTransitionResult.fromJson(Map<String, dynamic> json) =>
      _$RoleTransitionResultFromJson(json);
}

@freezed
class RoleTransitionRequest with _$RoleTransitionRequest {
  const factory RoleTransitionRequest({
    required String id,
    required String userId,
    required String currentUserRole,
    required String requestedUserRole,
    String? reason,
    @Default({}) Map<String, dynamic> additionalData,
    @Default('pending') String status,
    required String requestedBy,
    String? reviewedBy,
    String? reviewNotes,
    DateTime? approvedAt,
    DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _RoleTransitionRequest;

  factory RoleTransitionRequest.fromJson(Map<String, dynamic> json) =>
      _$RoleTransitionRequestFromJson(json);
}

@freezed
class AccountProvisioningAudit with _$AccountProvisioningAudit {
  const factory AccountProvisioningAudit({
    required String id,
    required String operationType,
    required String entityType,
    String? entityId,
    String? userId,
    String? performedBy,
    @Default({}) Map<String, dynamic> operationData,
    String? ipAddress,
    String? userAgent,
    required bool success,
    String? errorMessage,
    required DateTime createdAt,
  }) = _AccountProvisioningAudit;

  factory AccountProvisioningAudit.fromJson(Map<String, dynamic> json) =>
      _$AccountProvisioningAuditFromJson(json);
}

@freezed
class AccountProvisioningStats with _$AccountProvisioningStats {
  const factory AccountProvisioningStats({
    required int totalCustomerInvitations,
    required int totalDriverInvitations,
    required int totalRoleTransitions,
    required int pendingRoleTransitions,
    required int totalAuditEntries,
    required Map<String, int> statsByOperation,
  }) = _AccountProvisioningStats;

  factory AccountProvisioningStats.fromJson(Map<String, dynamic> json) =>
      _$AccountProvisioningStatsFromJson(json);
}

// Extension methods for DriverInvitation
extension DriverInvitationExtensions on DriverInvitation {
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  bool get isUsed => usedAt != null;
  
  bool get isActive => !isExpired && !isUsed;
  
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());
  
  String get statusText {
    if (isUsed) return 'Used';
    if (isExpired) return 'Expired';
    return 'Active';
  }
  
  String get vehicleType => vehicleDetails['type'] ?? 'Unknown';
  
  String get vehiclePlateNumber => vehicleDetails['plateNumber'] ?? '';
  
  String get vehicleDescription {
    final type = vehicleDetails['type'] ?? '';
    final brand = vehicleDetails['brand'] ?? '';
    final model = vehicleDetails['model'] ?? '';
    final year = vehicleDetails['year'] ?? '';
    
    final parts = [type, brand, model, year].where((part) => part.isNotEmpty);
    return parts.join(' ');
  }
}

// Extension methods for RoleTransitionRequest
extension RoleTransitionRequestExtensions on RoleTransitionRequest {
  bool get isPending => status == 'pending';
  
  bool get isApproved => status == 'approved';
  
  bool get isRejected => status == 'rejected';
  
  bool get isCompleted => status == 'completed';
  
  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      default:
        return status.toUpperCase();
    }
  }
  
  String get roleTransitionText => '$currentUserRole → $requestedUserRole';
  
  Duration get requestAge => DateTime.now().difference(createdAt);
  
  String get requestAgeText {
    final days = requestAge.inDays;
    if (days > 0) return '$days day${days == 1 ? '' : 's'} ago';
    
    final hours = requestAge.inHours;
    if (hours > 0) return '$hours hour${hours == 1 ? '' : 's'} ago';
    
    final minutes = requestAge.inMinutes;
    return '$minutes minute${minutes == 1 ? '' : 's'} ago';
  }
}

// Extension methods for AccountProvisioningAudit
extension AccountProvisioningAuditExtensions on AccountProvisioningAudit {
  String get operationDisplayText {
    switch (operationType) {
      case 'invitation_created':
        return 'Invitation Created';
      case 'invitation_used':
        return 'Invitation Used';
      case 'account_created':
        return 'Account Created';
      case 'account_linked':
        return 'Account Linked';
      case 'role_changed':
        return 'Role Changed';
      case 'role_transition_requested':
        return 'Role Transition Requested';
      case 'role_transition_approved':
        return 'Role Transition Approved';
      case 'profile_created':
        return 'Profile Created';
      case 'profile_updated':
        return 'Profile Updated';
      case 'account_deactivated':
        return 'Account Deactivated';
      default:
        return operationType.replaceAll('_', ' ').toUpperCase();
    }
  }
  
  String get entityDisplayText {
    switch (entityType) {
      case 'customer':
        return 'Customer';
      case 'driver':
        return 'Driver';
      case 'vendor':
        return 'Vendor';
      case 'sales_agent':
        return 'Sales Agent';
      case 'admin':
        return 'Admin';
      case 'user':
        return 'User';
      default:
        return entityType.toUpperCase();
    }
  }
  
  String get statusIcon => success ? '✅' : '❌';
  
  Duration get operationAge => DateTime.now().difference(createdAt);
  
  String get operationAgeText {
    final days = operationAge.inDays;
    if (days > 0) return '$days day${days == 1 ? '' : 's'} ago';
    
    final hours = operationAge.inHours;
    if (hours > 0) return '$hours hour${hours == 1 ? '' : 's'} ago';
    
    final minutes = operationAge.inMinutes;
    return '$minutes minute${minutes == 1 ? '' : 's'} ago';
  }
}
