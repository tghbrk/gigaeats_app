import 'dart:io';
import 'package:path/path.dart' as path;

import 'wallet_verification_document.dart';
import 'document_upload_progress.dart';

/// Validation result for wallet verification
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  /// Create a valid result
  factory ValidationResult.valid({List<String> warnings = const []}) {
    return ValidationResult(
      isValid: true,
      warnings: warnings,
    );
  }

  /// Create an invalid result
  factory ValidationResult.invalid({
    required List<String> errors,
    List<String> warnings = const [],
  }) {
    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Combine multiple validation results
  factory ValidationResult.combine(List<ValidationResult> results) {
    final allErrors = <String>[];
    final allWarnings = <String>[];
    bool isValid = true;

    for (final result in results) {
      if (!result.isValid) {
        isValid = false;
      }
      allErrors.addAll(result.errors);
      allWarnings.addAll(result.warnings);
    }

    return ValidationResult(
      isValid: isValid,
      errors: allErrors,
      warnings: allWarnings,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('ValidationResult(isValid: $isValid)');
    
    if (errors.isNotEmpty) {
      buffer.writeln('Errors:');
      for (final error in errors) {
        buffer.writeln('  - $error');
      }
    }
    
    if (warnings.isNotEmpty) {
      buffer.writeln('Warnings:');
      for (final warning in warnings) {
        buffer.writeln('  - $warning');
      }
    }
    
    return buffer.toString();
  }
}

/// Validator for wallet verification documents
class WalletVerificationValidator {
  /// Validate document file
  static ValidationResult validateDocumentFile({
    required File file,
    required DocumentType documentType,
    int? maxFileSizeBytes,
    List<String>? allowedMimeTypes,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check if file exists
    if (!file.existsSync()) {
      errors.add('File does not exist');
      return ValidationResult.invalid(errors: errors);
    }

    // Get file info
    final fileName = path.basename(file.path);
    final fileExtension = path.extension(fileName).toLowerCase();
    final fileSize = file.lengthSync();

    // Validate file name
    if (fileName.isEmpty) {
      errors.add('File name is empty');
    } else if (fileName.length > 255) {
      errors.add('File name is too long (max 255 characters)');
    } else if (fileName.contains(RegExp(r'[<>:"/\\|?*]'))) {
      errors.add('File name contains invalid characters');
    }

    // Validate file extension
    final supportedExtensions = _getSupportedExtensions(documentType);
    if (!supportedExtensions.contains(fileExtension)) {
      errors.add('File type $fileExtension is not supported for ${documentType.displayName}. '
          'Supported types: ${supportedExtensions.join(', ')}');
    }

    // Validate file size
    final maxSize = maxFileSizeBytes ?? (documentType.maxFileSizeMB * 1024 * 1024);
    if (fileSize > maxSize) {
      errors.add('File size (${_formatFileSize(fileSize)}) exceeds maximum allowed size '
          '(${_formatFileSize(maxSize)}) for ${documentType.displayName}');
    }

    // Minimum file size check
    final minSize = _getMinimumFileSize(documentType);
    if (fileSize < minSize) {
      warnings.add('File size (${_formatFileSize(fileSize)}) is very small. '
          'Please ensure the document is clearly readable.');
    }

    // Additional validations based on document type
    final typeSpecificResult = _validateDocumentTypeSpecific(
      file: file,
      documentType: documentType,
      fileSize: fileSize,
    );
    
    errors.addAll(typeSpecificResult.errors);
    warnings.addAll(typeSpecificResult.warnings);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate instant verification form data
  static ValidationResult validateInstantVerificationForm({
    required String icNumber,
    required String fullName,
    required String phoneNumber,
    required bool agreedToTerms,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate IC number
    if (icNumber.isEmpty) {
      errors.add('IC number is required');
    } else if (icNumber.length != 12) {
      errors.add('IC number must be exactly 12 digits');
    } else if (!RegExp(r'^\d{12}$').hasMatch(icNumber)) {
      errors.add('IC number must contain only digits');
    }

    // Validate full name
    if (fullName.isEmpty) {
      errors.add('Full name is required');
    } else if (fullName.trim().length < 2) {
      errors.add('Full name must be at least 2 characters');
    } else if (fullName.trim().length > 100) {
      errors.add('Full name is too long (max 100 characters)');
    }

    // Validate phone number
    if (phoneNumber.isEmpty) {
      errors.add('Phone number is required');
    } else if (phoneNumber.length < 9 || phoneNumber.length > 11) {
      errors.add('Phone number must be between 9 and 11 digits');
    } else if (!RegExp(r'^\d+$').hasMatch(phoneNumber)) {
      errors.add('Phone number must contain only digits');
    }

    // Validate terms agreement
    if (!agreedToTerms) {
      errors.add('You must agree to the terms and conditions');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate document upload progress
  static ValidationResult validateUploadProgress({
    required DocumentUploadProgress progress,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate progress value
    if (progress.progress < 0.0 || progress.progress > 1.0) {
      errors.add('Progress value must be between 0.0 and 1.0');
    }

    // Validate file paths
    if (progress.localFilePath.isEmpty) {
      errors.add('Local file path is required');
    } else if (!File(progress.localFilePath).existsSync()) {
      errors.add('Local file does not exist');
    }

    // Validate bytes if provided
    if (progress.totalBytes != null && progress.uploadedBytes != null) {
      if (progress.uploadedBytes! > progress.totalBytes!) {
        errors.add('Uploaded bytes cannot exceed total bytes');
      }
    }

    // Status-specific validations
    switch (progress.status) {
      case DocumentUploadStatus.completed:
        if (progress.progress < 1.0) {
          warnings.add('Upload marked as completed but progress is not 100%');
        }
        if (progress.remoteFilePath == null || progress.remoteFilePath!.isEmpty) {
          errors.add('Remote file path is required for completed uploads');
        }
        break;
      case DocumentUploadStatus.failed:
        if (progress.errorMessage == null || progress.errorMessage!.isEmpty) {
          warnings.add('Failed upload should have an error message');
        }
        break;
      case DocumentUploadStatus.uploading:
        if (progress.startedAt == null) {
          warnings.add('Upload start time should be set for active uploads');
        }
        break;
      default:
        break;
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // Private helper methods

  static List<String> _getSupportedExtensions(DocumentType documentType) {
    switch (documentType) {
      case DocumentType.icCard:
      case DocumentType.passport:
      case DocumentType.driverLicense:
      case DocumentType.selfie:
        return ['.jpg', '.jpeg', '.png'];
      case DocumentType.utilityBill:
      case DocumentType.bankStatement:
        return ['.jpg', '.jpeg', '.png', '.pdf'];
    }
  }

  static int _getMinimumFileSize(DocumentType documentType) {
    switch (documentType) {
      case DocumentType.selfie:
        return 50 * 1024; // 50KB
      case DocumentType.icCard:
      case DocumentType.passport:
      case DocumentType.driverLicense:
        return 100 * 1024; // 100KB
      case DocumentType.utilityBill:
      case DocumentType.bankStatement:
        return 200 * 1024; // 200KB
    }
  }

  static ValidationResult _validateDocumentTypeSpecific({
    required File file,
    required DocumentType documentType,
    required int fileSize,
  }) {
    final warnings = <String>[];

    // Document-specific validations
    switch (documentType) {
      case DocumentType.selfie:
        if (fileSize < 50 * 1024) {
          warnings.add('Selfie file size is very small. Please ensure good image quality.');
        }
        break;
      case DocumentType.icCard:
      case DocumentType.passport:
      case DocumentType.driverLicense:
        if (fileSize < 100 * 1024) {
          warnings.add('Document image is very small. Please ensure all text is clearly readable.');
        }
        break;
      default:
        break;
    }

    return ValidationResult.valid(warnings: warnings);
  }



  static String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
