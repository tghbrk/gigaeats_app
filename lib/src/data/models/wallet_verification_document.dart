import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_verification_document.freezed.dart';
part 'wallet_verification_document.g.dart';

/// Enum for document types
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

/// Extension for document type display
extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
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

  String get description {
    switch (this) {
      case DocumentType.icCard:
        return 'Malaysian Identity Card (front and back)';
      case DocumentType.passport:
        return 'Malaysian or international passport (photo page)';
      case DocumentType.driverLicense:
        return 'Malaysian driving license (front and back)';
      case DocumentType.utilityBill:
        return 'Recent utility bill (electricity, water, gas, or internet)';
      case DocumentType.bankStatement:
        return 'Recent bank statement showing your name and address';
      case DocumentType.selfie:
        return 'Clear selfie photo for identity verification';
    }
  }

  List<String> get requiredSides {
    switch (this) {
      case DocumentType.icCard:
        return ['front', 'back'];
      case DocumentType.passport:
        return ['photo_page'];
      case DocumentType.driverLicense:
        return ['front', 'back'];
      case DocumentType.utilityBill:
        return ['full_document'];
      case DocumentType.bankStatement:
        return ['full_document'];
      case DocumentType.selfie:
        return ['face'];
    }
  }

  List<String> get guidelines {
    switch (this) {
      case DocumentType.icCard:
        return [
          'Ensure all text is clearly readable',
          'No glare or shadows on the card',
          'Card should fill most of the frame',
          'Take photos in good lighting'
        ];
      case DocumentType.passport:
        return [
          'Photo page must be clearly visible',
          'All text should be readable',
          'No glare on the passport page',
          'Ensure passport is not expired'
        ];
      case DocumentType.driverLicense:
        return [
          'License must be valid and not expired',
          'All text should be clearly readable',
          'No glare or shadows',
          'Take photos in good lighting'
        ];
      case DocumentType.utilityBill:
        return [
          'Bill must be dated within the last 3 months',
          'Your name and address must be clearly visible',
          'All text should be readable',
          'Can be PDF or image format'
        ];
      case DocumentType.bankStatement:
        return [
          'Statement must be dated within the last 3 months',
          'Your name and address must be clearly visible',
          'Can hide account numbers for privacy',
          'Can be PDF or image format'
        ];
      case DocumentType.selfie:
        return [
          'Face should be clearly visible',
          'Good lighting with no shadows',
          'Look directly at the camera',
          'No sunglasses or face coverings',
          'Plain background preferred'
        ];
    }
  }

  int get maxFileSizeMB {
    switch (this) {
      case DocumentType.icCard:
      case DocumentType.passport:
      case DocumentType.driverLicense:
        return 5;
      case DocumentType.utilityBill:
      case DocumentType.bankStatement:
        return 10;
      case DocumentType.selfie:
        return 3;
    }
  }

  List<String> get supportedFormats {
    switch (this) {
      case DocumentType.icCard:
      case DocumentType.passport:
      case DocumentType.driverLicense:
      case DocumentType.selfie:
        return ['JPEG', 'PNG'];
      case DocumentType.utilityBill:
      case DocumentType.bankStatement:
        return ['JPEG', 'PNG', 'PDF'];
    }
  }

  String get icon {
    switch (this) {
      case DocumentType.icCard:
        return 'credit_card';
      case DocumentType.passport:
        return 'book';
      case DocumentType.driverLicense:
        return 'drive_eta';
      case DocumentType.utilityBill:
        return 'receipt_long';
      case DocumentType.bankStatement:
        return 'account_balance';
      case DocumentType.selfie:
        return 'face';
    }
  }
}

/// Enum for document side/page
enum DocumentSide {
  @JsonValue('front')
  front,
  @JsonValue('back')
  back,
  @JsonValue('photo_page')
  photoPage,
  @JsonValue('full_document')
  fullDocument,
  @JsonValue('face')
  face,
}

/// Extension for document side display
extension DocumentSideExtension on DocumentSide {
  String get displayName {
    switch (this) {
      case DocumentSide.front:
        return 'Front';
      case DocumentSide.back:
        return 'Back';
      case DocumentSide.photoPage:
        return 'Photo Page';
      case DocumentSide.fullDocument:
        return 'Full Document';
      case DocumentSide.face:
        return 'Face';
    }
  }
}

/// Model for wallet verification document
@freezed
class WalletVerificationDocument with _$WalletVerificationDocument {
  const factory WalletVerificationDocument({
    required String id,
    required String verificationRequestId,
    required String userId,
    required DocumentType documentType,
    DocumentSide? documentSide,
    required String fileName,
    required String filePath,
    required String mimeType,
    required int fileSize,
    String? thumbnailPath,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? ocrData,
    bool? isProcessed,
    String? processingError,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _WalletVerificationDocument;

  factory WalletVerificationDocument.fromJson(Map<String, dynamic> json) =>
      _$WalletVerificationDocumentFromJson(json);
}

/// Extension for wallet verification document
extension WalletVerificationDocumentExtension on WalletVerificationDocument {
  /// Get formatted file size
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Check if file is an image
  bool get isImage {
    return mimeType.startsWith('image/');
  }

  /// Check if file is a PDF
  bool get isPdf {
    return mimeType == 'application/pdf';
  }

  /// Get file extension
  String get fileExtension {
    return fileName.split('.').last.toLowerCase();
  }

  /// Check if document has been processed
  bool get hasBeenProcessed {
    return isProcessed == true;
  }

  /// Check if processing failed
  bool get hasProcessingError {
    return processingError != null && processingError!.isNotEmpty;
  }

  /// Get OCR extracted text if available
  String? get extractedText {
    return ocrData?['text'] as String?;
  }

  /// Get OCR confidence score if available
  double? get ocrConfidence {
    final confidence = ocrData?['confidence'];
    if (confidence is num) {
      return confidence.toDouble();
    }
    return null;
  }

  /// Check if OCR confidence is high enough
  bool get hasHighConfidenceOcr {
    final confidence = ocrConfidence;
    return confidence != null && confidence >= 0.8;
  }
}

/// Model for creating a new wallet verification document
@freezed
class CreateWalletVerificationDocument with _$CreateWalletVerificationDocument {
  const factory CreateWalletVerificationDocument({
    required String verificationRequestId,
    required DocumentType documentType,
    DocumentSide? documentSide,
    required String fileName,
    required String filePath,
    required String mimeType,
    required int fileSize,
    String? thumbnailPath,
    Map<String, dynamic>? metadata,
  }) = _CreateWalletVerificationDocument;

  factory CreateWalletVerificationDocument.fromJson(Map<String, dynamic> json) =>
      _$CreateWalletVerificationDocumentFromJson(json);
}

/// Model for updating wallet verification document
@freezed
class UpdateWalletVerificationDocument with _$UpdateWalletVerificationDocument {
  const factory UpdateWalletVerificationDocument({
    String? thumbnailPath,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? ocrData,
    bool? isProcessed,
    String? processingError,
  }) = _UpdateWalletVerificationDocument;

  factory UpdateWalletVerificationDocument.fromJson(Map<String, dynamic> json) =>
      _$UpdateWalletVerificationDocumentFromJson(json);
}
