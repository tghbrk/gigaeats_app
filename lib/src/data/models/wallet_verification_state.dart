import 'package:freezed_annotation/freezed_annotation.dart';
import 'wallet_verification_request.dart';
import 'wallet_verification_document.dart';
import 'document_upload_progress.dart';
import 'instant_verification_request.dart';

part 'wallet_verification_state.freezed.dart';
part 'wallet_verification_state.g.dart';

/// Model for comprehensive wallet verification state
@freezed
class WalletVerificationState with _$WalletVerificationState {
  const factory WalletVerificationState({
    // Current verification request
    WalletVerificationRequest? currentRequest,
    
    // Documents
    @Default([]) List<WalletVerificationDocument> documents,
    
    // Upload progress
    @Default([]) List<DocumentUploadProgress> uploadProgress,
    BatchUploadProgress? batchProgress,
    
    // Instant verification
    InstantVerificationRequest? instantVerification,
    
    // UI state
    @Default(false) bool isLoading,
    @Default(false) bool isUploading,
    @Default(false) bool isSubmitting,
    String? errorMessage,
    
    // Form state
    @Default({}) Map<DocumentType, bool> requiredDocuments,
    @Default({}) Map<DocumentType, bool> completedDocuments,
    
    // Settings
    @Default(true) bool autoRetryFailedUploads,
    @Default(true) bool compressImages,
    @Default(0.8) double imageCompressionQuality,
    
    // Metadata
    DateTime? lastUpdated,
    DateTime? lastSynced,
  }) = _WalletVerificationState;

  factory WalletVerificationState.fromJson(Map<String, dynamic> json) =>
      _$WalletVerificationStateFromJson(json);
}

/// Extension for wallet verification state
extension WalletVerificationStateExtension on WalletVerificationState {
  /// Check if there's an active verification request
  bool get hasActiveRequest {
    return currentRequest != null && !currentRequest!.status.isCompleted;
  }

  /// Check if verification is completed
  bool get isVerificationCompleted {
    return currentRequest?.status == WalletVerificationStatus.verified;
  }

  /// Check if verification failed
  bool get isVerificationFailed {
    return currentRequest?.status == WalletVerificationStatus.failed;
  }

  /// Check if verification is pending
  bool get isVerificationPending {
    return currentRequest?.status == WalletVerificationStatus.pending ||
           currentRequest?.status == WalletVerificationStatus.processing ||
           currentRequest?.status == WalletVerificationStatus.manualReview;
  }

  /// Check if can start new verification
  bool get canStartNewVerification {
    return currentRequest == null || currentRequest!.status.canRetry;
  }

  /// Get verification method being used
  WalletVerificationMethod? get currentMethod {
    return currentRequest?.method;
  }

  /// Check if using document upload method
  bool get isUsingDocumentUpload {
    return currentMethod == WalletVerificationMethod.documentUpload;
  }

  /// Check if using instant verification method
  bool get isUsingInstantVerification {
    return currentMethod == WalletVerificationMethod.instantVerification;
  }

  /// Check if using bank account method
  bool get isUsingBankAccount {
    return currentMethod == WalletVerificationMethod.bankAccount;
  }

  /// Get total number of required documents
  int get totalRequiredDocuments {
    return requiredDocuments.values.where((required) => required).length;
  }

  /// Get number of completed documents
  int get totalCompletedDocuments {
    return completedDocuments.values.where((completed) => completed).length;
  }

  /// Get document completion progress (0.0 to 1.0)
  double get documentCompletionProgress {
    if (totalRequiredDocuments == 0) return 0.0;
    return totalCompletedDocuments / totalRequiredDocuments;
  }

  /// Get document completion percentage
  int get documentCompletionPercentage {
    return (documentCompletionProgress * 100).round().clamp(0, 100);
  }

  /// Check if all required documents are completed
  bool get allRequiredDocumentsCompleted {
    return totalRequiredDocuments > 0 && 
           totalCompletedDocuments == totalRequiredDocuments;
  }

  /// Get documents by type
  List<WalletVerificationDocument> getDocumentsByType(DocumentType type) {
    return documents.where((doc) => doc.documentType == type).toList();
  }

  /// Check if document type is completed
  bool isDocumentTypeCompleted(DocumentType type) {
    return completedDocuments[type] == true;
  }

  /// Check if document type is required
  bool isDocumentTypeRequired(DocumentType type) {
    return requiredDocuments[type] == true;
  }

  /// Get upload progress for document type
  List<DocumentUploadProgress> getUploadProgressByType(DocumentType type) {
    return uploadProgress.where((progress) => progress.documentType == type).toList();
  }

  /// Check if document type is currently uploading
  bool isDocumentTypeUploading(DocumentType type) {
    return getUploadProgressByType(type).any((progress) => progress.status.isActive);
  }

  /// Get overall upload progress (0.0 to 1.0)
  double get overallUploadProgress {
    if (uploadProgress.isEmpty) return 0.0;
    
    final totalProgress = uploadProgress.fold<double>(
      0.0, 
      (sum, progress) => sum + progress.progress,
    );
    
    return totalProgress / uploadProgress.length;
  }

  /// Get overall upload percentage
  int get overallUploadPercentage {
    return (overallUploadProgress * 100).round().clamp(0, 100);
  }

  /// Check if any uploads are active
  bool get hasActiveUploads {
    return uploadProgress.any((progress) => progress.status.isActive);
  }

  /// Check if any uploads failed
  bool get hasFailedUploads {
    return uploadProgress.any((progress) => progress.status == DocumentUploadStatus.failed);
  }

  /// Get failed upload count
  int get failedUploadCount {
    return uploadProgress.where((progress) => progress.status == DocumentUploadStatus.failed).length;
  }

  /// Get completed upload count
  int get completedUploadCount {
    return uploadProgress.where((progress) => progress.status == DocumentUploadStatus.completed).length;
  }

  /// Check if instant verification is active
  bool get hasActiveInstantVerification {
    return instantVerification != null && instantVerification!.status.isProcessing;
  }

  /// Check if instant verification is completed
  bool get isInstantVerificationCompleted {
    return instantVerification?.status == InstantVerificationStatus.verified;
  }

  /// Check if instant verification failed
  bool get isInstantVerificationFailed {
    return instantVerification?.status == InstantVerificationStatus.failed;
  }

  /// Get verification status summary
  String get statusSummary {
    if (currentRequest == null) {
      return 'No verification request';
    }
    
    switch (currentRequest!.status) {
      case WalletVerificationStatus.pending:
        if (isUsingDocumentUpload) {
          return 'Documents: $totalCompletedDocuments/$totalRequiredDocuments completed';
        } else if (isUsingInstantVerification) {
          return 'Instant verification submitted';
        } else {
          return 'Verification pending';
        }
      case WalletVerificationStatus.processing:
        return 'Under review';
      case WalletVerificationStatus.manualReview:
        return 'Manual review required';
      case WalletVerificationStatus.verified:
        return 'Verification successful';
      case WalletVerificationStatus.failed:
        return 'Verification failed';
      case WalletVerificationStatus.expired:
        return 'Verification expired';
    }
  }

  /// Check if state needs sync with server
  bool get needsSync {
    if (lastSynced == null) return true;
    if (lastUpdated == null) return false;
    return lastUpdated!.isAfter(lastSynced!);
  }

  /// Get time since last sync
  Duration? get timeSinceLastSync {
    if (lastSynced == null) return null;
    return DateTime.now().difference(lastSynced!);
  }

  /// Check if sync is stale (older than 5 minutes)
  bool get isSyncStale {
    final timeSince = timeSinceLastSync;
    return timeSince != null && timeSince.inMinutes > 5;
  }
}

/// Model for wallet verification summary
@freezed
class WalletVerificationSummary with _$WalletVerificationSummary {
  const factory WalletVerificationSummary({
    required WalletVerificationStatus status,
    required WalletVerificationMethod method,
    required int totalDocuments,
    required int completedDocuments,
    required int failedDocuments,
    double? overallProgress,
    String? errorMessage,
    DateTime? lastUpdated,
    DateTime? completedAt,
  }) = _WalletVerificationSummary;

  factory WalletVerificationSummary.fromJson(Map<String, dynamic> json) =>
      _$WalletVerificationSummaryFromJson(json);
}

/// Extension for wallet verification summary
extension WalletVerificationSummaryExtension on WalletVerificationSummary {
  /// Get progress percentage
  int get progressPercentage {
    if (overallProgress == null) return 0;
    return (overallProgress! * 100).round().clamp(0, 100);
  }

  /// Check if verification is completed
  bool get isCompleted {
    return status.isCompleted;
  }

  /// Check if verification can be retried
  bool get canRetry {
    return status.canRetry;
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case WalletVerificationStatus.pending:
      case WalletVerificationStatus.processing:
      case WalletVerificationStatus.manualReview:
        return 'orange';
      case WalletVerificationStatus.verified:
        return 'green';
      case WalletVerificationStatus.failed:
      case WalletVerificationStatus.expired:
        return 'red';
    }
  }
}
