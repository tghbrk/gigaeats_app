/// Model for driver wallet verification status and data
class DriverWalletVerification {
  final String status; // 'unverified', 'pending', 'verified', 'failed'
  final int? currentStep;
  final int totalSteps;
  final DateTime? lastUpdated;
  final bool canRetry;
  final Map<String, dynamic>? data;

  const DriverWalletVerification({
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
        return 'Bank account details submitted';
      case 2:
        return 'Verification in progress';
      case 3:
        return 'Verification complete';
      default:
        return 'Step $currentStep of $totalSteps';
    }
  }

  /// Create from JSON
  factory DriverWalletVerification.fromJson(Map<String, dynamic> json) {
    return DriverWalletVerification(
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
  DriverWalletVerification copyWith({
    String? status,
    int? currentStep,
    int? totalSteps,
    DateTime? lastUpdated,
    bool? canRetry,
    Map<String, dynamic>? data,
  }) {
    return DriverWalletVerification(
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
    return 'DriverWalletVerification('
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
    
    return other is DriverWalletVerification &&
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

/// Verification method options
enum VerificationMethod {
  bankAccount('bank_account', 'Bank Account', 'Verify using bank account details'),
  document('document', 'Document Upload', 'Upload IC and selfie for verification'),
  instant('instant', 'Instant Verification', 'Quick verification with IC number'),
  unified('unified_verification', 'Complete Verification', 'Verify bank account and identity in one secure process');

  const VerificationMethod(this.value, this.title, this.description);

  final String value;
  final String title;
  final String description;

  /// Check if this is the unified verification method
  bool get isUnified => this == VerificationMethod.unified;

  /// Check if this method requires document upload
  bool get requiresDocuments => this == VerificationMethod.document || this == VerificationMethod.unified;

  /// Check if this method requires bank account details
  bool get requiresBankAccount => this == VerificationMethod.bankAccount || this == VerificationMethod.unified;

  /// Get the expected processing time in days
  int get expectedProcessingDays {
    switch (this) {
      case VerificationMethod.instant:
        return 0; // Instant
      case VerificationMethod.bankAccount:
      case VerificationMethod.unified:
        return 2; // 1-2 days
      case VerificationMethod.document:
        return 3; // 2-3 days
    }
  }

  /// Get the security level (1-5, where 5 is most secure)
  int get securityLevel {
    switch (this) {
      case VerificationMethod.instant:
        return 3;
      case VerificationMethod.document:
        return 4;
      case VerificationMethod.bankAccount:
        return 4;
      case VerificationMethod.unified:
        return 5; // Highest security
    }
  }

  /// Create from string value
  static VerificationMethod? fromValue(String value) {
    for (final method in VerificationMethod.values) {
      if (method.value == value) return method;
    }
    return null;
  }

  /// Get all available methods (excluding deprecated ones if needed)
  static List<VerificationMethod> get availableMethods => [
    VerificationMethod.unified, // Primary method
    // Legacy methods kept for backward compatibility
    VerificationMethod.bankAccount,
    VerificationMethod.document,
    VerificationMethod.instant,
  ];

  /// Get recommended method (unified verification)
  static VerificationMethod get recommended => VerificationMethod.unified;
}

/// Verification status options
enum VerificationStatus {
  unverified('unverified', 'Not Verified', 'Verification has not been started'),
  pending('pending', 'Verification Pending', 'Verification has been submitted and is waiting to be processed'),
  processing('processing', 'Processing', 'Verification is currently being processed'),
  verified('verified', 'Verified', 'Verification has been completed successfully'),
  failed('failed', 'Verification Failed', 'Verification has failed and needs to be retried'),
  expired('expired', 'Expired', 'Verification has expired and needs to be resubmitted');

  const VerificationStatus(this.value, this.title, this.description);

  final String value;
  final String title;
  final String description;

  /// Check if verification is complete and successful
  bool get isVerified => this == VerificationStatus.verified;

  /// Check if verification is in progress
  bool get isInProgress => this == VerificationStatus.pending || this == VerificationStatus.processing;

  /// Check if verification has failed
  bool get hasFailed => this == VerificationStatus.failed;

  /// Check if verification can be retried
  bool get canRetry => this == VerificationStatus.failed || this == VerificationStatus.expired;

  /// Check if verification is actionable (user can do something)
  bool get isActionable => this == VerificationStatus.unverified || canRetry;

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    switch (this) {
      case VerificationStatus.unverified:
        return 0.0;
      case VerificationStatus.pending:
        return 0.3;
      case VerificationStatus.processing:
        return 0.7;
      case VerificationStatus.verified:
        return 1.0;
      case VerificationStatus.failed:
      case VerificationStatus.expired:
        return 0.0;
    }
  }

  /// Create from string value
  static VerificationStatus? fromValue(String value) {
    for (final status in VerificationStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }

  /// Get default status
  static VerificationStatus get defaultStatus => VerificationStatus.unverified;
}

/// Bank account verification data
class BankAccountVerificationData {
  final String accountId;
  final String bankCode;
  final String accountNumber;
  final String accountHolderName;
  final String verificationMethod;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const BankAccountVerificationData({
    required this.accountId,
    required this.bankCode,
    required this.accountNumber,
    required this.accountHolderName,
    required this.verificationMethod,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory BankAccountVerificationData.fromJson(Map<String, dynamic> json) {
    return BankAccountVerificationData(
      accountId: json['id'] ?? json['account_id'],
      bankCode: json['bank_code'],
      accountNumber: json['account_number'],
      accountHolderName: json['account_holder_name'],
      verificationMethod: json['verification_method'],
      status: json['verification_status'] ?? json['status'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      'bank_code': bankCode,
      'account_number': accountNumber,
      'account_holder_name': accountHolderName,
      'verification_method': verificationMethod,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Bank account details for unified verification
class BankAccountDetails {
  final String bankCode;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final String accountType;

  const BankAccountDetails({
    required this.bankCode,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    this.accountType = 'savings',
  });

  factory BankAccountDetails.fromJson(Map<String, dynamic> json) {
    return BankAccountDetails(
      bankCode: json['bank_code'] ?? '',
      bankName: json['bank_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      accountType: json['account_type'] ?? 'savings',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bank_code': bankCode,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_holder_name': accountHolderName,
      'account_type': accountType,
    };
  }
}

/// Document verification details for unified verification
class DocumentVerificationDetails {
  final bool icFrontSubmitted;
  final bool icBackSubmitted;
  final String? icFrontUrl;
  final String? icBackUrl;
  final String? extractedIcNumber;
  final String? extractedName;
  final Map<String, dynamic>? ocrResults;
  final DateTime? submittedAt;

  const DocumentVerificationDetails({
    this.icFrontSubmitted = false,
    this.icBackSubmitted = false,
    this.icFrontUrl,
    this.icBackUrl,
    this.extractedIcNumber,
    this.extractedName,
    this.ocrResults,
    this.submittedAt,
  });

  factory DocumentVerificationDetails.fromJson(Map<String, dynamic> json) {
    return DocumentVerificationDetails(
      icFrontSubmitted: json['ic_front_submitted'] ?? false,
      icBackSubmitted: json['ic_back_submitted'] ?? false,
      icFrontUrl: json['ic_front_url'],
      icBackUrl: json['ic_back_url'],
      extractedIcNumber: json['extracted_ic_number'],
      extractedName: json['extracted_name'],
      ocrResults: json['ocr_results'],
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ic_front_submitted': icFrontSubmitted,
      'ic_back_submitted': icBackSubmitted,
      'ic_front_url': icFrontUrl,
      'ic_back_url': icBackUrl,
      'extracted_ic_number': extractedIcNumber,
      'extracted_name': extractedName,
      'ocr_results': ocrResults,
      'submitted_at': submittedAt?.toIso8601String(),
    };
  }

  /// Check if both IC documents are submitted
  bool get bothDocumentsSubmitted => icFrontSubmitted && icBackSubmitted;

  /// Check if OCR processing is complete
  bool get ocrComplete => extractedIcNumber != null && extractedName != null;
}

/// Unified verification data that combines bank account and document verification
class UnifiedVerificationData {
  final String verificationId;
  final BankAccountDetails bankAccount;
  final DocumentVerificationDetails documents;
  final String overallStatus; // 'pending', 'processing', 'verified', 'failed'
  final String? bankVerificationStatus;
  final String? documentVerificationStatus;
  final double progressPercentage; // 0.0 to 1.0
  final List<String> completedSteps;
  final String? nextStep;
  final DateTime? submittedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? processingDetails;
  final String? errorMessage;

  const UnifiedVerificationData({
    required this.verificationId,
    required this.bankAccount,
    required this.documents,
    required this.overallStatus,
    this.bankVerificationStatus,
    this.documentVerificationStatus,
    this.progressPercentage = 0.0,
    this.completedSteps = const [],
    this.nextStep,
    this.submittedAt,
    this.completedAt,
    this.processingDetails,
    this.errorMessage,
  });

  /// Check if both bank account and documents are verified
  bool get isFullyVerified =>
      bankVerificationStatus == 'verified' && documentVerificationStatus == 'verified';

  /// Check if verification is in progress
  bool get isInProgress =>
      overallStatus == 'processing' || overallStatus == 'pending';

  /// Check if verification has failed
  bool get hasFailed => overallStatus == 'failed';

  /// Get human-readable status message
  String get statusMessage {
    if (isFullyVerified) return 'Verification completed successfully';
    if (hasFailed) return errorMessage ?? 'Verification failed';
    if (overallStatus == 'pending') return 'Verification submitted, processing will begin shortly';
    if (overallStatus == 'processing') return 'Verification in progress';
    return 'Verification status unknown';
  }

  factory UnifiedVerificationData.fromJson(Map<String, dynamic> json) {
    return UnifiedVerificationData(
      verificationId: json['verification_id'] ?? json['id'],
      bankAccount: BankAccountDetails.fromJson(json['bank_account'] ?? {}),
      documents: DocumentVerificationDetails.fromJson(json['documents'] ?? {}),
      overallStatus: json['overall_status'] ?? json['status'],
      bankVerificationStatus: json['bank_verification_status'],
      documentVerificationStatus: json['document_verification_status'],
      progressPercentage: (json['progress_percentage'] ?? 0.0).toDouble(),
      completedSteps: List<String>.from(json['completed_steps'] ?? []),
      nextStep: json['next_step'],
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      processingDetails: json['processing_details'],
      errorMessage: json['error_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verification_id': verificationId,
      'bank_account': bankAccount.toJson(),
      'documents': documents.toJson(),
      'overall_status': overallStatus,
      'bank_verification_status': bankVerificationStatus,
      'document_verification_status': documentVerificationStatus,
      'progress_percentage': progressPercentage,
      'completed_steps': completedSteps,
      'next_step': nextStep,
      'submitted_at': submittedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'processing_details': processingDetails,
      'error_message': errorMessage,
    };
  }

  UnifiedVerificationData copyWith({
    String? verificationId,
    BankAccountDetails? bankAccount,
    DocumentVerificationDetails? documents,
    String? overallStatus,
    String? bankVerificationStatus,
    String? documentVerificationStatus,
    double? progressPercentage,
    List<String>? completedSteps,
    String? nextStep,
    DateTime? submittedAt,
    DateTime? completedAt,
    Map<String, dynamic>? processingDetails,
    String? errorMessage,
  }) {
    return UnifiedVerificationData(
      verificationId: verificationId ?? this.verificationId,
      bankAccount: bankAccount ?? this.bankAccount,
      documents: documents ?? this.documents,
      overallStatus: overallStatus ?? this.overallStatus,
      bankVerificationStatus: bankVerificationStatus ?? this.bankVerificationStatus,
      documentVerificationStatus: documentVerificationStatus ?? this.documentVerificationStatus,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      completedSteps: completedSteps ?? this.completedSteps,
      nextStep: nextStep ?? this.nextStep,
      submittedAt: submittedAt ?? this.submittedAt,
      completedAt: completedAt ?? this.completedAt,
      processingDetails: processingDetails ?? this.processingDetails,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
