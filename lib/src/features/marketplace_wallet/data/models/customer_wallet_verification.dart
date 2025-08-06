/// Model for customer wallet verification status and data
class CustomerWalletVerification {
  final String status; // 'unverified', 'pending', 'verified', 'failed'
  final int? currentStep;
  final int totalSteps;
  final DateTime? lastUpdated;
  final bool canRetry;
  final Map<String, dynamic>? data;

  const CustomerWalletVerification({
    required this.status,
    this.currentStep,
    this.totalSteps = 3,
    this.lastUpdated,
    this.canRetry = false,
    this.data,
  });

  /// Check if verification is complete
  bool get isVerified => status == 'verified';

  /// Check if verification is in progress
  bool get isPending => status == 'pending';

  /// Check if verification has failed
  bool get hasFailed => status == 'failed';

  /// Check if verification is unstarted
  bool get isUnverified => status == 'unverified';

  /// Get progress percentage (0-100)
  double get progressPercentage {
    if (currentStep == null) return 0.0;
    return (currentStep! / totalSteps) * 100;
  }

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case 'verified':
        return 'Verified';
      case 'pending':
        return 'Verification Pending';
      case 'failed':
        return 'Verification Failed';
      case 'unverified':
      default:
        return 'Not Verified';
    }
  }

  /// Get status description
  String get statusDescription {
    switch (status) {
      case 'verified':
        return 'Your wallet is verified and ready for withdrawals.';
      case 'pending':
        return 'Your verification is being processed. This may take 1-3 business days.';
      case 'failed':
        return 'Verification failed. Please try again or contact support.';
      case 'unverified':
      default:
        return 'Complete verification to enable wallet withdrawals.';
    }
  }

  /// Get current step description
  String get currentStepDescription {
    if (currentStep == null) return 'Not started';
    
    switch (currentStep!) {
      case 1:
        return 'Verification details submitted';
      case 2:
        return 'Verification in progress';
      case 3:
        return 'Verification complete';
      default:
        return 'Step $currentStep of $totalSteps';
    }
  }

  /// Create from JSON
  factory CustomerWalletVerification.fromJson(Map<String, dynamic> json) {
    return CustomerWalletVerification(
      status: json['status'] ?? 'unverified',
      currentStep: json['current_step'],
      totalSteps: json['total_steps'] ?? 3,
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated'])
          : null,
      canRetry: json['can_retry'] ?? false,
      data: json['data'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'current_step': currentStep,
      'total_steps': totalSteps,
      'last_updated': lastUpdated?.toIso8601String(),
      'can_retry': canRetry,
      'data': data,
    };
  }

  /// Create copy with updated fields
  CustomerWalletVerification copyWith({
    String? status,
    int? currentStep,
    int? totalSteps,
    DateTime? lastUpdated,
    bool? canRetry,
    Map<String, dynamic>? data,
  }) {
    return CustomerWalletVerification(
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      canRetry: canRetry ?? this.canRetry,
      data: data ?? this.data,
    );
  }

  @override
  String toString() {
    return 'CustomerWalletVerification('
        'status: $status, '
        'currentStep: $currentStep, '
        'totalSteps: $totalSteps, '
        'lastUpdated: $lastUpdated, '
        'canRetry: $canRetry'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is CustomerWalletVerification &&
        other.status == status &&
        other.currentStep == currentStep &&
        other.totalSteps == totalSteps &&
        other.lastUpdated == lastUpdated &&
        other.canRetry == canRetry;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        currentStep.hashCode ^
        totalSteps.hashCode ^
        lastUpdated.hashCode ^
        canRetry.hashCode;
  }
}

/// Customer verification method options (includes instant verification)
enum CustomerVerificationMethod {
  bankAccount('bank_account', 'Bank Account', 'Verify using bank account details'),
  document('document', 'Document Upload', 'Upload IC and selfie for verification'),
  instant('instant', 'Instant Verification', 'Quick verification with IC number'),
  unified('unified_verification', 'Complete Verification', 'Verify bank account, identity, and instant verification in one secure process');

  const CustomerVerificationMethod(this.value, this.title, this.description);

  final String value;
  final String title;
  final String description;

  /// Check if this is the unified verification method
  bool get isUnified => this == CustomerVerificationMethod.unified;

  /// Check if this method requires document upload
  bool get requiresDocuments => this == CustomerVerificationMethod.document || this == CustomerVerificationMethod.unified;

  /// Check if this method requires bank account details
  bool get requiresBankAccount => this == CustomerVerificationMethod.bankAccount || this == CustomerVerificationMethod.unified;

  /// Check if this method supports instant verification
  bool get supportsInstantVerification => this == CustomerVerificationMethod.instant || this == CustomerVerificationMethod.unified;

  /// Get the expected processing time in days
  int get expectedProcessingDays {
    switch (this) {
      case CustomerVerificationMethod.instant:
        return 0; // Instant
      case CustomerVerificationMethod.bankAccount:
        return 2; // 1-2 days
      case CustomerVerificationMethod.document:
        return 3; // 2-3 days
      case CustomerVerificationMethod.unified:
        return 2; // 1-2 days (optimized unified process)
    }
  }

  /// Get the security level (1-5, where 5 is most secure)
  int get securityLevel {
    switch (this) {
      case CustomerVerificationMethod.instant:
        return 3;
      case CustomerVerificationMethod.document:
        return 4;
      case CustomerVerificationMethod.bankAccount:
        return 4;
      case CustomerVerificationMethod.unified:
        return 5; // Highest security - combines all methods
    }
  }

  /// Create from string value
  static CustomerVerificationMethod? fromValue(String value) {
    for (final method in CustomerVerificationMethod.values) {
      if (method.value == value) return method;
    }
    return null;
  }

  /// Get all available methods
  static List<CustomerVerificationMethod> get availableMethods => [
    CustomerVerificationMethod.unified, // Primary method
    // Legacy methods kept for backward compatibility
    CustomerVerificationMethod.bankAccount,
    CustomerVerificationMethod.document,
    CustomerVerificationMethod.instant,
  ];

  /// Get recommended method (unified verification)
  static CustomerVerificationMethod get recommended => CustomerVerificationMethod.unified;
}

/// Customer verification status options
enum CustomerVerificationStatus {
  unverified('unverified', 'Not Verified', 'Verification has not been started'),
  pending('pending', 'Verification Pending', 'Verification has been submitted and is waiting to be processed'),
  processing('processing', 'Processing', 'Verification is currently being processed'),
  verified('verified', 'Verified', 'Verification has been completed successfully'),
  failed('failed', 'Verification Failed', 'Verification has failed and needs to be retried'),
  expired('expired', 'Expired', 'Verification has expired and needs to be resubmitted');

  const CustomerVerificationStatus(this.value, this.title, this.description);

  final String value;
  final String title;
  final String description;

  /// Check if verification is complete and successful
  bool get isVerified => this == CustomerVerificationStatus.verified;

  /// Check if verification is in progress
  bool get isInProgress => this == CustomerVerificationStatus.pending || this == CustomerVerificationStatus.processing;

  /// Check if verification has failed
  bool get hasFailed => this == CustomerVerificationStatus.failed;

  /// Check if verification can be retried
  bool get canRetry => this == CustomerVerificationStatus.failed || this == CustomerVerificationStatus.expired;

  /// Check if verification is actionable (user can do something)
  bool get isActionable => this == CustomerVerificationStatus.unverified || canRetry;

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    switch (this) {
      case CustomerVerificationStatus.unverified:
        return 0.0;
      case CustomerVerificationStatus.pending:
        return 0.3;
      case CustomerVerificationStatus.processing:
        return 0.7;
      case CustomerVerificationStatus.verified:
        return 1.0;
      case CustomerVerificationStatus.failed:
      case CustomerVerificationStatus.expired:
        return 0.0;
    }
  }

  /// Create from string value
  static CustomerVerificationStatus? fromValue(String value) {
    for (final status in CustomerVerificationStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }

  /// Get default status
  static CustomerVerificationStatus get defaultStatus => CustomerVerificationStatus.unverified;
}
