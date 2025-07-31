import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_verification_request.freezed.dart';
part 'wallet_verification_request.g.dart';

/// Enum for wallet verification status
enum WalletVerificationStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('manual_review')
  manualReview,
  @JsonValue('verified')
  verified,
  @JsonValue('failed')
  failed,
  @JsonValue('expired')
  expired,
}

/// Extension for wallet verification status display
extension WalletVerificationStatusExtension on WalletVerificationStatus {
  String get displayName {
    switch (this) {
      case WalletVerificationStatus.pending:
        return 'Pending';
      case WalletVerificationStatus.processing:
        return 'Processing';
      case WalletVerificationStatus.manualReview:
        return 'Manual Review';
      case WalletVerificationStatus.verified:
        return 'Verified';
      case WalletVerificationStatus.failed:
        return 'Failed';
      case WalletVerificationStatus.expired:
        return 'Expired';
    }
  }

  String get description {
    switch (this) {
      case WalletVerificationStatus.pending:
        return 'Your verification request is waiting to be processed';
      case WalletVerificationStatus.processing:
        return 'We are currently reviewing your documents';
      case WalletVerificationStatus.manualReview:
        return 'Your documents require manual review by our team';
      case WalletVerificationStatus.verified:
        return 'Your wallet has been successfully verified';
      case WalletVerificationStatus.failed:
        return 'Verification failed. Please check the details and try again';
      case WalletVerificationStatus.expired:
        return 'Your verification request has expired. Please submit a new request';
    }
  }

  bool get isCompleted {
    return this == WalletVerificationStatus.verified || 
           this == WalletVerificationStatus.failed || 
           this == WalletVerificationStatus.expired;
  }

  bool get canRetry {
    return this == WalletVerificationStatus.failed || 
           this == WalletVerificationStatus.expired;
  }
}

/// Enum for wallet verification method
enum WalletVerificationMethod {
  @JsonValue('bank_account')
  bankAccount,
  @JsonValue('document_upload')
  documentUpload,
  @JsonValue('instant_verification')
  instantVerification,
}

/// Extension for wallet verification method display
extension WalletVerificationMethodExtension on WalletVerificationMethod {
  String get displayName {
    switch (this) {
      case WalletVerificationMethod.bankAccount:
        return 'Bank Account';
      case WalletVerificationMethod.documentUpload:
        return 'Document Upload';
      case WalletVerificationMethod.instantVerification:
        return 'Instant Verification';
    }
  }

  String get description {
    switch (this) {
      case WalletVerificationMethod.bankAccount:
        return 'Verify using your bank account details';
      case WalletVerificationMethod.documentUpload:
        return 'Upload identity documents for verification';
      case WalletVerificationMethod.instantVerification:
        return 'Quick verification using your IC number';
    }
  }

  String get icon {
    switch (this) {
      case WalletVerificationMethod.bankAccount:
        return 'account_balance';
      case WalletVerificationMethod.documentUpload:
        return 'upload_file';
      case WalletVerificationMethod.instantVerification:
        return 'flash_on';
    }
  }
}

/// Model for wallet verification request
@freezed
class WalletVerificationRequest with _$WalletVerificationRequest {
  const factory WalletVerificationRequest({
    required String id,
    required String userId,
    required String walletId,
    required WalletVerificationMethod method,
    required WalletVerificationStatus status,
    String? failureReason,
    Map<String, dynamic>? metadata,
    DateTime? submittedAt,
    DateTime? processedAt,
    DateTime? expiresAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _WalletVerificationRequest;

  factory WalletVerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$WalletVerificationRequestFromJson(json);
}

/// Extension for wallet verification request
extension WalletVerificationRequestExtension on WalletVerificationRequest {
  /// Check if the request is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if the request is still processing
  bool get isProcessing {
    return status == WalletVerificationStatus.processing ||
           status == WalletVerificationStatus.manualReview;
  }

  /// Check if the request can be cancelled
  bool get canCancel {
    return status == WalletVerificationStatus.pending ||
           status == WalletVerificationStatus.processing;
  }

  /// Get the time remaining until expiration
  Duration? get timeUntilExpiration {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    return expiresAt!.difference(now);
  }

  /// Get formatted time remaining
  String? get formattedTimeRemaining {
    final duration = timeUntilExpiration;
    if (duration == null) return null;
    
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Less than a minute';
    }
  }

  /// Get processing time if completed
  Duration? get processingTime {
    if (submittedAt == null || processedAt == null) return null;
    return processedAt!.difference(submittedAt!);
  }

  /// Get formatted processing time
  String? get formattedProcessingTime {
    final duration = processingTime;
    if (duration == null) return null;
    
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Less than a minute';
    }
  }
}

/// Model for creating a new wallet verification request
@freezed
class CreateWalletVerificationRequest with _$CreateWalletVerificationRequest {
  const factory CreateWalletVerificationRequest({
    required String walletId,
    required WalletVerificationMethod method,
    Map<String, dynamic>? metadata,
  }) = _CreateWalletVerificationRequest;

  factory CreateWalletVerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateWalletVerificationRequestFromJson(json);
}

/// Model for updating wallet verification request
@freezed
class UpdateWalletVerificationRequest with _$UpdateWalletVerificationRequest {
  const factory UpdateWalletVerificationRequest({
    WalletVerificationStatus? status,
    String? failureReason,
    Map<String, dynamic>? metadata,
    DateTime? processedAt,
  }) = _UpdateWalletVerificationRequest;

  factory UpdateWalletVerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateWalletVerificationRequestFromJson(json);
}
