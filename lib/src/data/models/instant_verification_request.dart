import 'package:freezed_annotation/freezed_annotation.dart';

part 'instant_verification_request.freezed.dart';
part 'instant_verification_request.g.dart';

/// Enum for instant verification status
enum InstantVerificationStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('verified')
  verified,
  @JsonValue('failed')
  failed,
  @JsonValue('manual_review')
  manualReview,
}

/// Extension for instant verification status display
extension InstantVerificationStatusExtension on InstantVerificationStatus {
  String get displayName {
    switch (this) {
      case InstantVerificationStatus.pending:
        return 'Pending';
      case InstantVerificationStatus.processing:
        return 'Processing';
      case InstantVerificationStatus.verified:
        return 'Verified';
      case InstantVerificationStatus.failed:
        return 'Failed';
      case InstantVerificationStatus.manualReview:
        return 'Manual Review';
    }
  }

  String get description {
    switch (this) {
      case InstantVerificationStatus.pending:
        return 'Your verification request is waiting to be processed';
      case InstantVerificationStatus.processing:
        return 'We are verifying your information against official databases';
      case InstantVerificationStatus.verified:
        return 'Your identity has been successfully verified';
      case InstantVerificationStatus.failed:
        return 'Verification failed. Please check your information and try again';
      case InstantVerificationStatus.manualReview:
        return 'Your information requires manual review by our team';
    }
  }

  bool get isCompleted {
    return this == InstantVerificationStatus.verified ||
           this == InstantVerificationStatus.failed;
  }

  bool get canRetry {
    return this == InstantVerificationStatus.failed;
  }

  bool get isProcessing {
    return this == InstantVerificationStatus.processing ||
           this == InstantVerificationStatus.manualReview;
  }
}

/// Model for instant verification request
@freezed
class InstantVerificationRequest with _$InstantVerificationRequest {
  const factory InstantVerificationRequest({
    required String id,
    required String verificationRequestId,
    required String userId,
    required String icNumber,
    required String fullName,
    required String phoneNumber,
    required InstantVerificationStatus status,
    double? confidenceScore,
    Map<String, dynamic>? verificationData,
    String? failureReason,
    Map<String, dynamic>? metadata,
    DateTime? submittedAt,
    DateTime? processedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _InstantVerificationRequest;

  factory InstantVerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$InstantVerificationRequestFromJson(json);
}

/// Extension for instant verification request
extension InstantVerificationRequestExtension on InstantVerificationRequest {
  /// Get masked IC number for display
  String get maskedIcNumber {
    if (icNumber.length < 6) return icNumber;
    return '${icNumber.substring(0, 6)}******';
  }

  /// Get masked phone number for display
  String get maskedPhoneNumber {
    if (phoneNumber.length < 4) return phoneNumber;
    return '${phoneNumber.substring(0, phoneNumber.length - 4)}****';
  }

  /// Get confidence percentage
  int? get confidencePercentage {
    if (confidenceScore == null) return null;
    return (confidenceScore! * 100).round().clamp(0, 100);
  }

  /// Get formatted confidence score
  String? get formattedConfidenceScore {
    final percentage = confidencePercentage;
    if (percentage == null) return null;
    return '$percentage%';
  }

  /// Check if confidence is high enough for automatic verification
  bool get hasHighConfidence {
    return confidenceScore != null && confidenceScore! >= 0.9;
  }

  /// Check if confidence is medium (requires manual review)
  bool get hasMediumConfidence {
    return confidenceScore != null && 
           confidenceScore! >= 0.7 && 
           confidenceScore! < 0.9;
  }

  /// Check if confidence is low (likely to fail)
  bool get hasLowConfidence {
    return confidenceScore != null && confidenceScore! < 0.7;
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
    
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'}';
    } else {
      return '${duration.inSeconds} second${duration.inSeconds == 1 ? '' : 's'}';
    }
  }

  /// Get verification data field
  T? getVerificationData<T>(String key) {
    return verificationData?[key] as T?;
  }

  /// Check if name matches verification data
  bool get nameMatches {
    final verifiedName = getVerificationData<String>('name');
    if (verifiedName == null) return false;
    return fullName.toLowerCase().trim() == verifiedName.toLowerCase().trim();
  }

  /// Check if IC number matches verification data
  bool get icNumberMatches {
    final verifiedIc = getVerificationData<String>('ic_number');
    if (verifiedIc == null) return false;
    return icNumber == verifiedIc;
  }

  /// Get address from verification data
  String? get verifiedAddress {
    return getVerificationData<String>('address');
  }

  /// Get date of birth from verification data
  DateTime? get verifiedDateOfBirth {
    final dobString = getVerificationData<String>('date_of_birth');
    if (dobString == null) return null;
    return DateTime.tryParse(dobString);
  }

  /// Get gender from verification data
  String? get verifiedGender {
    return getVerificationData<String>('gender');
  }
}

/// Model for creating instant verification request
@freezed
class CreateInstantVerificationRequest with _$CreateInstantVerificationRequest {
  const factory CreateInstantVerificationRequest({
    required String verificationRequestId,
    required String icNumber,
    required String fullName,
    required String phoneNumber,
    Map<String, dynamic>? metadata,
  }) = _CreateInstantVerificationRequest;

  factory CreateInstantVerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateInstantVerificationRequestFromJson(json);
}

/// Model for updating instant verification request
@freezed
class UpdateInstantVerificationRequest with _$UpdateInstantVerificationRequest {
  const factory UpdateInstantVerificationRequest({
    InstantVerificationStatus? status,
    double? confidenceScore,
    Map<String, dynamic>? verificationData,
    String? failureReason,
    Map<String, dynamic>? metadata,
    DateTime? processedAt,
  }) = _UpdateInstantVerificationRequest;

  factory UpdateInstantVerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateInstantVerificationRequestFromJson(json);
}

/// Model for instant verification form data
@freezed
class InstantVerificationFormData with _$InstantVerificationFormData {
  const factory InstantVerificationFormData({
    @Default('') String icNumber,
    @Default('') String fullName,
    @Default('') String phoneNumber,
    @Default(false) bool agreedToTerms,
  }) = _InstantVerificationFormData;

  factory InstantVerificationFormData.fromJson(Map<String, dynamic> json) =>
      _$InstantVerificationFormDataFromJson(json);
}

/// Extension for instant verification form data
extension InstantVerificationFormDataExtension on InstantVerificationFormData {
  /// Check if form is valid
  bool get isValid {
    return icNumber.isNotEmpty &&
           icNumber.length == 12 &&
           RegExp(r'^\d{12}$').hasMatch(icNumber) &&
           fullName.isNotEmpty &&
           fullName.length >= 2 &&
           phoneNumber.isNotEmpty &&
           phoneNumber.length >= 9 &&
           phoneNumber.length <= 11 &&
           agreedToTerms;
  }

  /// Get validation errors
  List<String> get validationErrors {
    final errors = <String>[];
    
    if (icNumber.isEmpty) {
      errors.add('IC number is required');
    } else if (icNumber.length != 12) {
      errors.add('IC number must be 12 digits');
    } else if (!RegExp(r'^\d{12}$').hasMatch(icNumber)) {
      errors.add('IC number must contain only digits');
    }
    
    if (fullName.isEmpty) {
      errors.add('Full name is required');
    } else if (fullName.length < 2) {
      errors.add('Full name must be at least 2 characters');
    }
    
    if (phoneNumber.isEmpty) {
      errors.add('Phone number is required');
    } else if (phoneNumber.length < 9 || phoneNumber.length > 11) {
      errors.add('Please enter a valid phone number');
    }
    
    if (!agreedToTerms) {
      errors.add('You must agree to the terms and conditions');
    }
    
    return errors;
  }

  /// Get formatted phone number with country code
  String get formattedPhoneNumber {
    if (phoneNumber.isEmpty) return '';
    return '+60 $phoneNumber';
  }

  /// Get formatted IC number with dashes
  String get formattedIcNumber {
    if (icNumber.length != 12) return icNumber;
    return '${icNumber.substring(0, 6)}-${icNumber.substring(6, 8)}-${icNumber.substring(8)}';
  }
}
