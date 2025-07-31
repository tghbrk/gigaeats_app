import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wallet_verification_models.g.dart';

/// Document types supported for verification
enum DocumentType {
  @JsonValue('ic_card')
  icCard,
  @JsonValue('passport')
  passport,
  @JsonValue('driver_license')
  driverLicense,
  @JsonValue('utility_bill')
  utilityBill,
  @JsonValue('bank_statement')
  bankStatement,
  @JsonValue('selfie')
  selfie,
}

/// Verification status enum
enum VerificationStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('verified')
  verified,
  @JsonValue('failed')
  failed,
  @JsonValue('expired')
  expired,
  @JsonValue('manual_review')
  manualReview,
}

/// Verification method enum
enum VerificationMethod {
  @JsonValue('document_upload')
  documentUpload,
  @JsonValue('instant_verification')
  instantVerification,
  @JsonValue('bank_account')
  bankAccount,
  @JsonValue('manual_verification')
  manualVerification,
}

/// Document upload progress state
@JsonSerializable()
class DocumentUploadProgress extends Equatable {
  final String documentId;
  final DocumentType documentType;
  final double progress; // 0.0 to 1.0
  final bool isUploading;
  final bool isCompleted;
  final String? error;
  final String? filePath;
  final int? fileSize;

  const DocumentUploadProgress({
    required this.documentId,
    required this.documentType,
    required this.progress,
    this.isUploading = false,
    this.isCompleted = false,
    this.error,
    this.filePath,
    this.fileSize,
  });

  factory DocumentUploadProgress.fromJson(Map<String, dynamic> json) =>
      _$DocumentUploadProgressFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentUploadProgressToJson(this);

  DocumentUploadProgress copyWith({
    String? documentId,
    DocumentType? documentType,
    double? progress,
    bool? isUploading,
    bool? isCompleted,
    String? error,
    String? filePath,
    int? fileSize,
  }) {
    return DocumentUploadProgress(
      documentId: documentId ?? this.documentId,
      documentType: documentType ?? this.documentType,
      progress: progress ?? this.progress,
      isUploading: isUploading ?? this.isUploading,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error ?? this.error,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  @override
  List<Object?> get props => [
        documentId,
        documentType,
        progress,
        isUploading,
        isCompleted,
        error,
        filePath,
        fileSize,
      ];
}

/// Wallet verification request model
@JsonSerializable()
class WalletVerificationRequest extends Equatable {
  final String id;
  final String userId;
  final String userRole;
  final String walletId;
  final VerificationMethod verificationMethod;
  final VerificationStatus status;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final String? processedBy;
  final String? verificationReference;
  final String? externalVerificationId;
  final double? verificationScore;
  final String? verificationConfidence;
  final String? failureReason;
  final String? manualReviewNotes;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletVerificationRequest({
    required this.id,
    required this.userId,
    required this.userRole,
    required this.walletId,
    required this.verificationMethod,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.completedAt,
    this.expiresAt,
    this.processedBy,
    this.verificationReference,
    this.externalVerificationId,
    this.verificationScore,
    this.verificationConfidence,
    this.failureReason,
    this.manualReviewNotes,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletVerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$WalletVerificationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$WalletVerificationRequestToJson(this);

  WalletVerificationRequest copyWith({
    String? id,
    String? userId,
    String? userRole,
    String? walletId,
    VerificationMethod? verificationMethod,
    VerificationStatus? status,
    DateTime? requestedAt,
    DateTime? processedAt,
    DateTime? completedAt,
    DateTime? expiresAt,
    String? processedBy,
    String? verificationReference,
    String? externalVerificationId,
    double? verificationScore,
    String? verificationConfidence,
    String? failureReason,
    String? manualReviewNotes,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletVerificationRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      walletId: walletId ?? this.walletId,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      processedBy: processedBy ?? this.processedBy,
      verificationReference: verificationReference ?? this.verificationReference,
      externalVerificationId: externalVerificationId ?? this.externalVerificationId,
      verificationScore: verificationScore ?? this.verificationScore,
      verificationConfidence: verificationConfidence ?? this.verificationConfidence,
      failureReason: failureReason ?? this.failureReason,
      manualReviewNotes: manualReviewNotes ?? this.manualReviewNotes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userRole,
        walletId,
        verificationMethod,
        status,
        requestedAt,
        processedAt,
        completedAt,
        expiresAt,
        processedBy,
        verificationReference,
        externalVerificationId,
        verificationScore,
        verificationConfidence,
        failureReason,
        manualReviewNotes,
        metadata,
        createdAt,
        updatedAt,
      ];

  /// Check if verification is in progress
  bool get isInProgress => status == VerificationStatus.processing || status == VerificationStatus.pending;

  /// Check if verification is completed (success or failure)
  bool get isCompleted => status == VerificationStatus.verified || 
                         status == VerificationStatus.failed || 
                         status == VerificationStatus.expired;

  /// Check if verification was successful
  bool get isVerified => status == VerificationStatus.verified;

  /// Check if verification can be retried
  bool get canRetry => status == VerificationStatus.failed || status == VerificationStatus.expired;

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case VerificationStatus.pending:
        return 'Pending Review';
      case VerificationStatus.processing:
        return 'Processing';
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.failed:
        return 'Failed';
      case VerificationStatus.expired:
        return 'Expired';
      case VerificationStatus.manualReview:
        return 'Manual Review';
    }
  }

  /// Get method display text
  String get methodDisplayText {
    switch (verificationMethod) {
      case VerificationMethod.documentUpload:
        return 'Document Upload';
      case VerificationMethod.instantVerification:
        return 'Instant Verification';
      case VerificationMethod.bankAccount:
        return 'Bank Account';
      case VerificationMethod.manualVerification:
        return 'Manual Verification';
    }
  }
}

/// Wallet verification document model
@JsonSerializable()
class WalletVerificationDocument extends Equatable {
  final String id;
  final String verificationRequestId;
  final String userId;
  final DocumentType documentType;
  final String documentName;
  final String filePath;
  final int fileSize;
  final String fileMimeType;
  final DateTime uploadedAt;
  final String? uploadIpAddress;
  final String? uploadUserAgent;
  final VerificationStatus processingStatus;
  final DateTime? processedAt;
  final Map<String, dynamic>? extractedData;
  final Map<String, dynamic>? verificationResults;
  final bool isEncrypted;
  final String? encryptionKeyId;
  final DateTime? retentionExpiresAt;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletVerificationDocument({
    required this.id,
    required this.verificationRequestId,
    required this.userId,
    required this.documentType,
    required this.documentName,
    required this.filePath,
    required this.fileSize,
    required this.fileMimeType,
    required this.uploadedAt,
    this.uploadIpAddress,
    this.uploadUserAgent,
    required this.processingStatus,
    this.processedAt,
    this.extractedData,
    this.verificationResults,
    this.isEncrypted = false,
    this.encryptionKeyId,
    this.retentionExpiresAt,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletVerificationDocument.fromJson(Map<String, dynamic> json) =>
      _$WalletVerificationDocumentFromJson(json);

  Map<String, dynamic> toJson() => _$WalletVerificationDocumentToJson(this);

  WalletVerificationDocument copyWith({
    String? id,
    String? verificationRequestId,
    String? userId,
    DocumentType? documentType,
    String? documentName,
    String? filePath,
    int? fileSize,
    String? fileMimeType,
    DateTime? uploadedAt,
    String? uploadIpAddress,
    String? uploadUserAgent,
    VerificationStatus? processingStatus,
    DateTime? processedAt,
    Map<String, dynamic>? extractedData,
    Map<String, dynamic>? verificationResults,
    bool? isEncrypted,
    String? encryptionKeyId,
    DateTime? retentionExpiresAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletVerificationDocument(
      id: id ?? this.id,
      verificationRequestId: verificationRequestId ?? this.verificationRequestId,
      userId: userId ?? this.userId,
      documentType: documentType ?? this.documentType,
      documentName: documentName ?? this.documentName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      fileMimeType: fileMimeType ?? this.fileMimeType,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploadIpAddress: uploadIpAddress ?? this.uploadIpAddress,
      uploadUserAgent: uploadUserAgent ?? this.uploadUserAgent,
      processingStatus: processingStatus ?? this.processingStatus,
      processedAt: processedAt ?? this.processedAt,
      extractedData: extractedData ?? this.extractedData,
      verificationResults: verificationResults ?? this.verificationResults,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      encryptionKeyId: encryptionKeyId ?? this.encryptionKeyId,
      retentionExpiresAt: retentionExpiresAt ?? this.retentionExpiresAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        verificationRequestId,
        userId,
        documentType,
        documentName,
        filePath,
        fileSize,
        fileMimeType,
        uploadedAt,
        uploadIpAddress,
        uploadUserAgent,
        processingStatus,
        processedAt,
        extractedData,
        verificationResults,
        isEncrypted,
        encryptionKeyId,
        retentionExpiresAt,
        metadata,
        createdAt,
        updatedAt,
      ];

  /// Get document type display text
  String get documentTypeDisplayText {
    switch (documentType) {
      case DocumentType.icCard:
        return 'IC Card';
      case DocumentType.passport:
        return 'Passport';
      case DocumentType.driverLicense:
        return 'Driver License';
      case DocumentType.utilityBill:
        return 'Utility Bill';
      case DocumentType.bankStatement:
        return 'Bank Statement';
      case DocumentType.selfie:
        return 'Selfie';
    }
  }

  /// Get file size in human readable format
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if document is processed
  bool get isProcessed => processingStatus == VerificationStatus.verified ||
                         processingStatus == VerificationStatus.failed;

  /// Check if document processing is in progress
  bool get isProcessing => processingStatus == VerificationStatus.processing ||
                          processingStatus == VerificationStatus.pending;
}
