import 'package:freezed_annotation/freezed_annotation.dart';
import 'wallet_verification_document.dart';

part 'document_upload_progress.freezed.dart';
part 'document_upload_progress.g.dart';

/// Enum for document upload status
enum DocumentUploadStatus {
  @JsonValue('idle')
  idle,
  @JsonValue('preparing')
  preparing,
  @JsonValue('compressing')
  compressing,
  @JsonValue('uploading')
  uploading,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled,
}

/// Extension for document upload status display
extension DocumentUploadStatusExtension on DocumentUploadStatus {
  String get displayName {
    switch (this) {
      case DocumentUploadStatus.idle:
        return 'Ready';
      case DocumentUploadStatus.preparing:
        return 'Preparing';
      case DocumentUploadStatus.compressing:
        return 'Compressing';
      case DocumentUploadStatus.uploading:
        return 'Uploading';
      case DocumentUploadStatus.processing:
        return 'Processing';
      case DocumentUploadStatus.completed:
        return 'Completed';
      case DocumentUploadStatus.failed:
        return 'Failed';
      case DocumentUploadStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get description {
    switch (this) {
      case DocumentUploadStatus.idle:
        return 'Ready to upload';
      case DocumentUploadStatus.preparing:
        return 'Preparing file for upload';
      case DocumentUploadStatus.compressing:
        return 'Compressing image to reduce file size';
      case DocumentUploadStatus.uploading:
        return 'Uploading file to server';
      case DocumentUploadStatus.processing:
        return 'Processing uploaded document';
      case DocumentUploadStatus.completed:
        return 'Upload completed successfully';
      case DocumentUploadStatus.failed:
        return 'Upload failed';
      case DocumentUploadStatus.cancelled:
        return 'Upload was cancelled';
    }
  }

  bool get isActive {
    return this == DocumentUploadStatus.preparing ||
           this == DocumentUploadStatus.compressing ||
           this == DocumentUploadStatus.uploading ||
           this == DocumentUploadStatus.processing;
  }

  bool get isCompleted {
    return this == DocumentUploadStatus.completed ||
           this == DocumentUploadStatus.failed ||
           this == DocumentUploadStatus.cancelled;
  }

  bool get canRetry {
    return this == DocumentUploadStatus.failed;
  }

  bool get canCancel {
    return this == DocumentUploadStatus.preparing ||
           this == DocumentUploadStatus.compressing ||
           this == DocumentUploadStatus.uploading;
  }
}

/// Model for document upload progress
@freezed
class DocumentUploadProgress with _$DocumentUploadProgress {
  const factory DocumentUploadProgress({
    required String id,
    required String verificationRequestId,
    required DocumentType documentType,
    DocumentSide? documentSide,
    required String fileName,
    required String localFilePath,
    String? remoteFilePath,
    required DocumentUploadStatus status,
    @Default(0.0) double progress,
    int? totalBytes,
    int? uploadedBytes,
    String? errorMessage,
    Map<String, dynamic>? metadata,
    DateTime? startedAt,
    DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DocumentUploadProgress;

  factory DocumentUploadProgress.fromJson(Map<String, dynamic> json) =>
      _$DocumentUploadProgressFromJson(json);
}

/// Extension for document upload progress
extension DocumentUploadProgressExtension on DocumentUploadProgress {
  /// Get progress percentage (0-100)
  int get progressPercentage {
    return (progress * 100).round().clamp(0, 100);
  }

  /// Get formatted progress text
  String get progressText {
    return '$progressPercentage%';
  }

  /// Get upload speed if available
  double? get uploadSpeedBytesPerSecond {
    if (startedAt == null || uploadedBytes == null || uploadedBytes == 0) {
      return null;
    }
    
    final elapsed = DateTime.now().difference(startedAt!);
    if (elapsed.inSeconds == 0) return null;
    
    return uploadedBytes! / elapsed.inSeconds;
  }

  /// Get formatted upload speed
  String? get formattedUploadSpeed {
    final speed = uploadSpeedBytesPerSecond;
    if (speed == null) return null;
    
    if (speed < 1024) {
      return '${speed.toStringAsFixed(0)} B/s';
    } else if (speed < 1024 * 1024) {
      return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  /// Get estimated time remaining
  Duration? get estimatedTimeRemaining {
    final speed = uploadSpeedBytesPerSecond;
    if (speed == null || totalBytes == null || uploadedBytes == null) {
      return null;
    }
    
    final remainingBytes = totalBytes! - uploadedBytes!;
    if (remainingBytes <= 0) return Duration.zero;
    
    final secondsRemaining = remainingBytes / speed;
    return Duration(seconds: secondsRemaining.round());
  }

  /// Get formatted time remaining
  String? get formattedTimeRemaining {
    final duration = estimatedTimeRemaining;
    if (duration == null) return null;
    
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Get upload duration if completed
  Duration? get uploadDuration {
    if (startedAt == null || completedAt == null) return null;
    return completedAt!.difference(startedAt!);
  }

  /// Get formatted upload duration
  String? get formattedUploadDuration {
    final duration = uploadDuration;
    if (duration == null) return null;
    
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Get formatted file size
  String? get formattedTotalSize {
    if (totalBytes == null) return null;
    
    if (totalBytes! < 1024) {
      return '$totalBytes B';
    } else if (totalBytes! < 1024 * 1024) {
      return '${(totalBytes! / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get formatted uploaded size
  String? get formattedUploadedSize {
    if (uploadedBytes == null) return null;
    
    if (uploadedBytes! < 1024) {
      return '$uploadedBytes B';
    } else if (uploadedBytes! < 1024 * 1024) {
      return '${(uploadedBytes! / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(uploadedBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get progress summary text
  String get progressSummary {
    if (totalBytes != null && uploadedBytes != null) {
      return '$formattedUploadedSize / $formattedTotalSize';
    } else {
      return progressText;
    }
  }
}

/// Model for creating document upload progress
@freezed
class CreateDocumentUploadProgress with _$CreateDocumentUploadProgress {
  const factory CreateDocumentUploadProgress({
    required String verificationRequestId,
    required DocumentType documentType,
    DocumentSide? documentSide,
    required String fileName,
    required String localFilePath,
    int? totalBytes,
    Map<String, dynamic>? metadata,
  }) = _CreateDocumentUploadProgress;

  factory CreateDocumentUploadProgress.fromJson(Map<String, dynamic> json) =>
      _$CreateDocumentUploadProgressFromJson(json);
}

/// Model for updating document upload progress
@freezed
class UpdateDocumentUploadProgress with _$UpdateDocumentUploadProgress {
  const factory UpdateDocumentUploadProgress({
    String? remoteFilePath,
    DocumentUploadStatus? status,
    double? progress,
    int? uploadedBytes,
    String? errorMessage,
    Map<String, dynamic>? metadata,
    DateTime? startedAt,
    DateTime? completedAt,
  }) = _UpdateDocumentUploadProgress;

  factory UpdateDocumentUploadProgress.fromJson(Map<String, dynamic> json) =>
      _$UpdateDocumentUploadProgressFromJson(json);
}

/// Model for batch upload progress
@freezed
class BatchUploadProgress with _$BatchUploadProgress {
  const factory BatchUploadProgress({
    required String verificationRequestId,
    required List<DocumentUploadProgress> documents,
    @Default(0.0) double overallProgress,
    required int totalDocuments,
    required int completedDocuments,
    required int failedDocuments,
    bool? isCompleted,
    String? errorMessage,
    DateTime? startedAt,
    DateTime? completedAt,
  }) = _BatchUploadProgress;

  factory BatchUploadProgress.fromJson(Map<String, dynamic> json) =>
      _$BatchUploadProgressFromJson(json);
}

/// Extension for batch upload progress
extension BatchUploadProgressExtension on BatchUploadProgress {
  /// Get overall progress percentage (0-100)
  int get overallProgressPercentage {
    return (overallProgress * 100).round().clamp(0, 100);
  }

  /// Get number of documents currently uploading
  int get uploadingDocuments {
    return documents.where((doc) => doc.status.isActive).length;
  }

  /// Get number of pending documents
  int get pendingDocuments {
    return documents.where((doc) => doc.status == DocumentUploadStatus.idle).length;
  }

  /// Check if all uploads are completed (successfully or failed)
  bool get allUploadsCompleted {
    return documents.every((doc) => doc.status.isCompleted);
  }

  /// Check if any uploads failed
  bool get hasFailedUploads {
    return failedDocuments > 0;
  }

  /// Check if all uploads succeeded
  bool get allUploadsSucceeded {
    return allUploadsCompleted && failedDocuments == 0;
  }

  /// Get batch upload summary
  String get uploadSummary {
    return '$completedDocuments/$totalDocuments completed';
  }

  /// Get batch upload duration if completed
  Duration? get batchUploadDuration {
    if (startedAt == null || completedAt == null) return null;
    return completedAt!.difference(startedAt!);
  }
}
