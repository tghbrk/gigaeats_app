import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'driver_document_verification.g.dart';

/// Document types supported for driver verification (Malaysian KYC compliance)
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

/// Document verification status
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
  @JsonValue('rejected')
  rejected,
}

/// Verification method used
enum VerificationMethod {
  @JsonValue('ocr_ai')
  ocrAi,
  @JsonValue('manual')
  manual,
  @JsonValue('hybrid')
  hybrid,
}

/// Main driver document verification model
@JsonSerializable()
class DriverDocumentVerification extends Equatable {
  final String id;
  final String driverId;
  final String userId;
  final String verificationType;
  final VerificationStatus overallStatus;
  final int currentStep;
  final int totalSteps;
  final double completionPercentage;
  final VerificationMethod verificationMethod;
  final DateTime? processingStartedAt;
  final DateTime? processingCompletedAt;
  final DateTime? verifiedAt;
  final DateTime? expiresAt;
  final double? verificationScore;
  final Map<String, dynamic> extractedData;
  final Map<String, dynamic> verificationResults;
  final List<String> failureReasons;
  final String? manualReviewNotes;
  final String kycComplianceStatus;
  final Map<String, dynamic> complianceChecks;
  final Map<String, dynamic> auditTrail;
  final String? ipAddress;
  final String? userAgent;
  final DateTime retentionExpiresAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DriverDocumentVerification({
    required this.id,
    required this.driverId,
    required this.userId,
    required this.verificationType,
    required this.overallStatus,
    required this.currentStep,
    required this.totalSteps,
    required this.completionPercentage,
    required this.verificationMethod,
    this.processingStartedAt,
    this.processingCompletedAt,
    this.verifiedAt,
    this.expiresAt,
    this.verificationScore,
    required this.extractedData,
    required this.verificationResults,
    required this.failureReasons,
    this.manualReviewNotes,
    required this.kycComplianceStatus,
    required this.complianceChecks,
    required this.auditTrail,
    this.ipAddress,
    this.userAgent,
    required this.retentionExpiresAt,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverDocumentVerification.fromJson(Map<String, dynamic> json) =>
      _$DriverDocumentVerificationFromJson(json);

  Map<String, dynamic> toJson() => _$DriverDocumentVerificationToJson(this);

  @override
  List<Object?> get props => [
        id,
        driverId,
        userId,
        verificationType,
        overallStatus,
        currentStep,
        totalSteps,
        completionPercentage,
        verificationMethod,
        processingStartedAt,
        processingCompletedAt,
        verifiedAt,
        expiresAt,
        verificationScore,
        extractedData,
        verificationResults,
        failureReasons,
        manualReviewNotes,
        kycComplianceStatus,
        complianceChecks,
        auditTrail,
        ipAddress,
        userAgent,
        retentionExpiresAt,
        metadata,
        createdAt,
        updatedAt,
      ];

  /// Check if verification is complete
  bool get isComplete => overallStatus == VerificationStatus.verified;

  /// Check if verification is in progress
  bool get isInProgress => overallStatus == VerificationStatus.processing;

  /// Check if verification failed
  bool get hasFailed => overallStatus == VerificationStatus.failed;

  /// Check if verification requires manual review
  bool get requiresManualReview => overallStatus == VerificationStatus.manualReview;

  /// Get progress as percentage string
  String get progressPercentage => '${completionPercentage.toInt()}%';

  /// Check if verification is expired
  bool get isExpired => 
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Get status display text
  String get statusDisplayText {
    switch (overallStatus) {
      case VerificationStatus.pending:
        return 'Pending Upload';
      case VerificationStatus.processing:
        return 'Processing Documents';
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.failed:
        return 'Verification Failed';
      case VerificationStatus.expired:
        return 'Expired';
      case VerificationStatus.manualReview:
        return 'Under Review';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Individual driver verification document model
@JsonSerializable()
class DriverVerificationDocument extends Equatable {
  final String id;
  final String verificationId;
  final String driverId;
  final String userId;
  final DocumentType documentType;
  final String? documentSide;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String mimeType;
  final VerificationStatus processingStatus;
  final DateTime? processingStartedAt;
  final DateTime? processingCompletedAt;
  final Map<String, dynamic> ocrData;
  final Map<String, dynamic> aiVerificationData;
  final double? confidenceScore;
  final Map<String, dynamic> extractedInfo;
  final Map<String, dynamic> validationResults;
  final bool isEncrypted;
  final String? encryptionKeyId;
  final String? hashChecksum;
  final Map<String, dynamic> uploadMetadata;
  final Map<String, dynamic> processingMetadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DriverVerificationDocument({
    required this.id,
    required this.verificationId,
    required this.driverId,
    required this.userId,
    required this.documentType,
    this.documentSide,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.mimeType,
    required this.processingStatus,
    this.processingStartedAt,
    this.processingCompletedAt,
    required this.ocrData,
    required this.aiVerificationData,
    this.confidenceScore,
    required this.extractedInfo,
    required this.validationResults,
    required this.isEncrypted,
    this.encryptionKeyId,
    this.hashChecksum,
    required this.uploadMetadata,
    required this.processingMetadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverVerificationDocument.fromJson(Map<String, dynamic> json) =>
      _$DriverVerificationDocumentFromJson(json);

  Map<String, dynamic> toJson() => _$DriverVerificationDocumentToJson(this);

  @override
  List<Object?> get props => [
        id,
        verificationId,
        driverId,
        userId,
        documentType,
        documentSide,
        fileName,
        filePath,
        fileSize,
        mimeType,
        processingStatus,
        processingStartedAt,
        processingCompletedAt,
        ocrData,
        aiVerificationData,
        confidenceScore,
        extractedInfo,
        validationResults,
        isEncrypted,
        encryptionKeyId,
        hashChecksum,
        uploadMetadata,
        processingMetadata,
        createdAt,
        updatedAt,
      ];

  /// Get document type display name
  String get documentTypeDisplayName {
    switch (documentType) {
      case DocumentType.icCard:
        return 'Malaysian IC';
      case DocumentType.passport:
        return 'Passport';
      case DocumentType.driverLicense:
        return 'Driver\'s License';
      case DocumentType.utilityBill:
        return 'Utility Bill';
      case DocumentType.bankStatement:
        return 'Bank Statement';
      case DocumentType.selfie:
        return 'Selfie Photo';
    }
  }

  /// Get file size in human readable format
  String get fileSizeFormatted {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Check if document is processed
  bool get isProcessed => processingStatus == VerificationStatus.verified ||
      processingStatus == VerificationStatus.failed;

  /// Check if document is being processed
  bool get isProcessing => processingStatus == VerificationStatus.processing;

  /// Check if document can be deleted
  bool get canBeDeleted => processingStatus == VerificationStatus.pending;
}

/// Result classes for service operations
class DriverDocumentUploadResult {
  final bool success;
  final String? documentId;
  final String? filePath;
  final String? fileUrl;
  final int? fileSize;
  final String? mimeType;
  final String? fileHash;
  final String? errorMessage;

  const DriverDocumentUploadResult._({
    required this.success,
    this.documentId,
    this.filePath,
    this.fileUrl,
    this.fileSize,
    this.mimeType,
    this.fileHash,
    this.errorMessage,
  });

  factory DriverDocumentUploadResult.success({
    required String documentId,
    required String filePath,
    required String fileUrl,
    required int fileSize,
    required String mimeType,
    required String fileHash,
  }) =>
      DriverDocumentUploadResult._(
        success: true,
        documentId: documentId,
        filePath: filePath,
        fileUrl: fileUrl,
        fileSize: fileSize,
        mimeType: mimeType,
        fileHash: fileHash,
      );

  factory DriverDocumentUploadResult.failure(String errorMessage) =>
      DriverDocumentUploadResult._(
        success: false,
        errorMessage: errorMessage,
      );
}

/// Document validation result
class DocumentValidationResult {
  final bool isValid;
  final String? errorMessage;

  const DocumentValidationResult._(this.isValid, this.errorMessage);

  factory DocumentValidationResult.valid() =>
      const DocumentValidationResult._(true, null);

  factory DocumentValidationResult.invalid(String errorMessage) =>
      DocumentValidationResult._(false, errorMessage);
}

/// Processed document file
class ProcessedDocumentFile {
  final Uint8List bytes;
  final String mimeType;

  const ProcessedDocumentFile({
    required this.bytes,
    required this.mimeType,
  });
}

/// Storage upload result
class StorageUploadResult {
  final bool success;
  final String? fileUrl;
  final String? errorMessage;

  const StorageUploadResult._(this.success, this.fileUrl, this.errorMessage);

  factory StorageUploadResult.success(String fileUrl) =>
      StorageUploadResult._(true, fileUrl, null);

  factory StorageUploadResult.failure(String errorMessage) =>
      StorageUploadResult._(false, null, errorMessage);
}
