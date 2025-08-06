import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/logger.dart';
import '../../../../core/utils/image_compression_utils.dart';
import '../../../../data/models/wallet_verification_document.dart';

/// Service for handling customer document AI verification
/// Provides image processing, upload, and AI vision integration for customer wallet verification
class CustomerDocumentAIVerificationService {
  final _logger = AppLogger();
  final _supabase = Supabase.instance.client;

  /// Upload customer verification document with AI processing
  Future<CustomerDocumentUploadResult> uploadVerificationDocument({
    required String customerId,
    required String userId,
    required String verificationId,
    required DocumentType documentType,
    required XFile documentFile,
    String? documentSide, // 'front', 'back' for cards
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.info('📄 Starting customer document upload: $customerId, type: $documentType');

      // Validate file
      final validationResult = await _validateDocumentFile(documentFile);
      if (!validationResult.isValid) {
        return CustomerDocumentUploadResult.failure(validationResult.errorMessage!);
      }

      // Process and compress image if needed
      final processedFile = await _processDocumentFile(documentFile, documentType);

      // Generate secure file path
      final filePath = _generateSecureFilePath(
        userId: userId,
        customerId: customerId,
        documentType: documentType,
        documentSide: documentSide,
        originalFileName: documentFile.name,
      );

      // Calculate file hash for integrity
      final fileHash = await _calculateFileHash(processedFile.bytes);

      // Upload to Supabase Storage
      final uploadResult = await _uploadToStorage(
        filePath: filePath,
        fileBytes: processedFile.bytes,
        mimeType: processedFile.mimeType,
      );

      if (!uploadResult.success) {
        return CustomerDocumentUploadResult.failure(uploadResult.errorMessage!);
      }

      // Create document record in database
      final documentRecord = await _createDocumentRecord(
        verificationId: verificationId,
        userId: userId,
        documentType: documentType,
        documentSide: documentSide,
        fileName: documentFile.name,
        filePath: filePath,
        mimeType: processedFile.mimeType,
        fileSize: processedFile.bytes.length,
        fileHash: fileHash,
        metadata: metadata,
      );

      _logger.info('✅ Customer document uploaded successfully: ${documentRecord.id}');

      return CustomerDocumentUploadResult.success(
        documentId: documentRecord.id,
        filePath: filePath,
        fileHash: fileHash,
        documentRecord: documentRecord,
      );

    } catch (e, stackTrace) {
      _logger.error('❌ Customer document upload failed', e, stackTrace);
      return CustomerDocumentUploadResult.failure('Upload failed: $e');
    }
  }

  /// Process document with AI vision extraction
  Future<CustomerAIExtractionResult> processDocumentWithAI({
    required String documentId,
    required String verificationId,
    required DocumentType documentType,
    String? documentSide,
  }) async {
    try {
      _logger.info('🤖 Starting AI processing for customer document: $documentId');

      // Call Edge Function for AI processing
      final response = await _supabase.functions.invoke(
        'customer-document-ai-verification',
        body: {
          'action': 'process_document',
          'document_id': documentId,
          'verification_id': verificationId,
          'document_type': documentType.name,
          'document_side': documentSide,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'AI processing failed');
      }

      final extractedData = response.data['data'];
      _logger.info('✅ AI processing completed for document: $documentId');

      return CustomerAIExtractionResult.success(
        documentId: documentId,
        extractedFields: Map<String, dynamic>.from(extractedData['extracted_fields'] ?? {}),
        confidenceScore: (extractedData['confidence_score'] ?? 0).toDouble(),
        validationResults: Map<String, dynamic>.from(extractedData['validation_results'] ?? {}),
        qualityAssessment: Map<String, dynamic>.from(extractedData['quality_assessment'] ?? {}),
      );

    } catch (e, stackTrace) {
      _logger.error('❌ AI processing failed for document: $documentId', e, stackTrace);
      return CustomerAIExtractionResult.failure('AI processing failed: $e');
    }
  }

  /// Extract IC data from both front and back images
  Future<CustomerICExtractionResult> extractICData({
    required String frontDocumentId,
    required String backDocumentId,
    required String verificationId,
  }) async {
    try {
      _logger.info('🆔 Extracting IC data from front and back images');

      // Process front image
      final frontResult = await processDocumentWithAI(
        documentId: frontDocumentId,
        verificationId: verificationId,
        documentType: DocumentType.icCard,
        documentSide: 'front',
      );

      if (!frontResult.isSuccess) {
        return CustomerICExtractionResult.failure('Front IC processing failed: ${frontResult.errorMessage}');
      }

      // Process back image
      final backResult = await processDocumentWithAI(
        documentId: backDocumentId,
        verificationId: verificationId,
        documentType: DocumentType.icCard,
        documentSide: 'back',
      );

      if (!backResult.isSuccess) {
        return CustomerICExtractionResult.failure('Back IC processing failed: ${backResult.errorMessage}');
      }

      // Extract key fields from front image
      final frontFields = frontResult.extractedFields!;
      final icNumber = frontFields['ic_number'] as String?;
      final fullName = frontFields['full_name'] as String?;

      // Validate extracted data
      if (icNumber == null || icNumber.isEmpty) {
        return CustomerICExtractionResult.failure('IC number could not be extracted from front image');
      }

      if (fullName == null || fullName.isEmpty) {
        return CustomerICExtractionResult.failure('Full name could not be extracted from front image');
      }

      // Calculate overall confidence
      final overallConfidence = (frontResult.confidenceScore! + backResult.confidenceScore!) / 2;

      _logger.info('✅ IC data extraction completed - IC: ${icNumber.replaceAll(RegExp(r'\d'), '*')}, Name: [EXTRACTED]');

      return CustomerICExtractionResult.success(
        icNumber: icNumber,
        fullName: fullName,
        frontExtraction: frontResult,
        backExtraction: backResult,
        overallConfidence: overallConfidence,
      );

    } catch (e, stackTrace) {
      _logger.error('❌ IC data extraction failed', e, stackTrace);
      return CustomerICExtractionResult.failure('IC extraction failed: $e');
    }
  }

  /// Validate document file before upload
  Future<DocumentValidationResult> _validateDocumentFile(XFile file) async {
    try {
      // Check file size (20MB limit)
      final fileSize = await file.length();
      if (fileSize > 20 * 1024 * 1024) {
        return DocumentValidationResult.invalid('File size exceeds 20MB limit');
      }

      // Check file type
      final mimeType = file.mimeType ?? _getMimeTypeFromExtension(file.name);
      const allowedTypes = [
        'image/jpeg',
        'image/jpg',
        'image/png',
        'image/webp',
      ];

      if (!allowedTypes.contains(mimeType)) {
        return DocumentValidationResult.invalid('Unsupported file type: $mimeType');
      }

      // Additional validation for images
      if (mimeType.startsWith('image/')) {
        final imageValidation = await _validateImageFile(file);
        if (!imageValidation.isValid) {
          return imageValidation;
        }
      }

      return DocumentValidationResult.valid();
    } catch (e) {
      return DocumentValidationResult.invalid('File validation failed: $e');
    }
  }

  /// Validate image file quality and dimensions
  Future<DocumentValidationResult> _validateImageFile(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      // Check minimum file size (avoid empty or corrupted files)
      if (bytes.length < 1024) {
        return DocumentValidationResult.invalid('Image file is too small or corrupted');
      }

      return DocumentValidationResult.valid();
    } catch (e) {
      return DocumentValidationResult.invalid('Image validation failed: $e');
    }
  }

  /// Process document file (compression, format conversion)
  Future<ProcessedDocumentFile> _processDocumentFile(XFile file, DocumentType documentType) async {
    final mimeType = file.mimeType ?? _getMimeTypeFromExtension(file.name);
    
    if (mimeType.startsWith('image/')) {
      // Compress image while maintaining quality for OCR
      final compressedBytes = await ImageCompressionUtils.compressForDocumentVerification(
        file,
        maxWidth: 2048,
        maxHeight: 2048,
        quality: 90, // High quality for OCR
        maxSizeKB: 5000, // 5MB max after compression
      );
      
      return ProcessedDocumentFile(
        bytes: compressedBytes,
        mimeType: 'image/jpeg', // Standardize to JPEG
      );
    } else {
      // For other files, use as-is
      final bytes = await file.readAsBytes();
      return ProcessedDocumentFile(
        bytes: bytes,
        mimeType: mimeType,
      );
    }
  }

  /// Generate secure file path for storage
  String _generateSecureFilePath({
    required String userId,
    required String customerId,
    required DocumentType documentType,
    String? documentSide,
    required String originalFileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalFileName.split('.').last.toLowerCase();
    final sidePrefix = documentSide != null ? '${documentSide}_' : '';
    
    return 'customer-verification-documents/$userId/$customerId/${documentType.name}/$sidePrefix$timestamp.$extension';
  }

  /// Calculate file hash for integrity verification
  Future<String> _calculateFileHash(Uint8List bytes) async {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Upload file to Supabase Storage
  Future<StorageUploadResult> _uploadToStorage({
    required String filePath,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    try {
      await _supabase.storage
          .from('customer-verification-documents')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: false,
            ),
          );

      return StorageUploadResult.success(filePath);
    } catch (e) {
      return StorageUploadResult.failure('Storage upload failed: $e');
    }
  }

  /// Create document record in database
  Future<WalletVerificationDocument> _createDocumentRecord({
    required String verificationId,
    required String userId,
    required DocumentType documentType,
    String? documentSide,
    required String fileName,
    required String filePath,
    required String mimeType,
    required int fileSize,
    required String fileHash,
    Map<String, dynamic>? metadata,
  }) async {
    final documentData = {
      'verification_request_id': verificationId,
      'user_id': userId,
      'document_type': documentType.name,
      'document_side': documentSide,
      'file_name': fileName,
      'file_path': filePath,
      'mime_type': mimeType,
      'file_size': fileSize,
      'metadata': {
        'file_hash': fileHash,
        'upload_timestamp': DateTime.now().toIso8601String(),
        'client_info': 'flutter_app',
        ...?metadata,
      },
    };

    final response = await _supabase
        .from('wallet_verification_documents')
        .insert(documentData)
        .select()
        .single();

    return WalletVerificationDocument.fromJson(response);
  }

  /// Get MIME type from file extension
  String _getMimeTypeFromExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}

/// Result classes for customer document operations

/// Result of document upload operation
class CustomerDocumentUploadResult {
  final bool isSuccess;
  final String? documentId;
  final String? filePath;
  final String? fileHash;
  final WalletVerificationDocument? documentRecord;
  final String? errorMessage;

  CustomerDocumentUploadResult._({
    required this.isSuccess,
    this.documentId,
    this.filePath,
    this.fileHash,
    this.documentRecord,
    this.errorMessage,
  });

  factory CustomerDocumentUploadResult.success({
    required String documentId,
    required String filePath,
    required String fileHash,
    required WalletVerificationDocument documentRecord,
  }) {
    return CustomerDocumentUploadResult._(
      isSuccess: true,
      documentId: documentId,
      filePath: filePath,
      fileHash: fileHash,
      documentRecord: documentRecord,
    );
  }

  factory CustomerDocumentUploadResult.failure(String errorMessage) {
    return CustomerDocumentUploadResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

/// Result of AI extraction operation
class CustomerAIExtractionResult {
  final bool isSuccess;
  final String? documentId;
  final Map<String, dynamic>? extractedFields;
  final double? confidenceScore;
  final Map<String, dynamic>? validationResults;
  final Map<String, dynamic>? qualityAssessment;
  final String? errorMessage;

  CustomerAIExtractionResult._({
    required this.isSuccess,
    this.documentId,
    this.extractedFields,
    this.confidenceScore,
    this.validationResults,
    this.qualityAssessment,
    this.errorMessage,
  });

  factory CustomerAIExtractionResult.success({
    required String documentId,
    required Map<String, dynamic> extractedFields,
    required double confidenceScore,
    required Map<String, dynamic> validationResults,
    required Map<String, dynamic> qualityAssessment,
  }) {
    return CustomerAIExtractionResult._(
      isSuccess: true,
      documentId: documentId,
      extractedFields: extractedFields,
      confidenceScore: confidenceScore,
      validationResults: validationResults,
      qualityAssessment: qualityAssessment,
    );
  }

  factory CustomerAIExtractionResult.failure(String errorMessage) {
    return CustomerAIExtractionResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

/// Result of IC data extraction from both front and back images
class CustomerICExtractionResult {
  final bool isSuccess;
  final String? icNumber;
  final String? fullName;
  final CustomerAIExtractionResult? frontExtraction;
  final CustomerAIExtractionResult? backExtraction;
  final double? overallConfidence;
  final String? errorMessage;

  CustomerICExtractionResult._({
    required this.isSuccess,
    this.icNumber,
    this.fullName,
    this.frontExtraction,
    this.backExtraction,
    this.overallConfidence,
    this.errorMessage,
  });

  factory CustomerICExtractionResult.success({
    required String icNumber,
    required String fullName,
    required CustomerAIExtractionResult frontExtraction,
    required CustomerAIExtractionResult backExtraction,
    required double overallConfidence,
  }) {
    return CustomerICExtractionResult._(
      isSuccess: true,
      icNumber: icNumber,
      fullName: fullName,
      frontExtraction: frontExtraction,
      backExtraction: backExtraction,
      overallConfidence: overallConfidence,
    );
  }

  factory CustomerICExtractionResult.failure(String errorMessage) {
    return CustomerICExtractionResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

/// Result of storage upload operation
class StorageUploadResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;

  StorageUploadResult._({
    required this.success,
    this.filePath,
    this.errorMessage,
  });

  factory StorageUploadResult.success(String filePath) {
    return StorageUploadResult._(
      success: true,
      filePath: filePath,
    );
  }

  factory StorageUploadResult.failure(String errorMessage) {
    return StorageUploadResult._(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// Result of document validation
class DocumentValidationResult {
  final bool isValid;
  final String? errorMessage;

  DocumentValidationResult._({
    required this.isValid,
    this.errorMessage,
  });

  factory DocumentValidationResult.valid() {
    return DocumentValidationResult._(isValid: true);
  }

  factory DocumentValidationResult.invalid(String errorMessage) {
    return DocumentValidationResult._(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}

/// Processed document file data
class ProcessedDocumentFile {
  final Uint8List bytes;
  final String mimeType;

  ProcessedDocumentFile({
    required this.bytes,
    required this.mimeType,
  });
}
