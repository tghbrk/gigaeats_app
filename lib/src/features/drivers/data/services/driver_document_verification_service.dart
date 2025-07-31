import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/utils/image_compression_utils.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/models/driver_document_verification.dart';

/// Service for handling driver document verification uploads and processing
class DriverDocumentVerificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppLogger _logger = AppLogger();

  /// Upload driver verification document with security and validation
  Future<DriverDocumentUploadResult> uploadVerificationDocument({
    required String driverId,
    required String userId,
    required String verificationId,
    required DocumentType documentType,
    required XFile documentFile,
    String? documentSide, // 'front', 'back' for cards
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.info('📄 Starting document upload for driver: $driverId, type: $documentType');

      // Validate file
      final validationResult = await _validateDocumentFile(documentFile);
      if (!validationResult.isValid) {
        return DriverDocumentUploadResult.failure(validationResult.errorMessage!);
      }

      // Process and compress image if needed
      final processedFile = await _processDocumentFile(documentFile, documentType);

      // Generate secure file path
      final filePath = _generateSecureFilePath(
        userId: userId,
        driverId: driverId,
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
        return DriverDocumentUploadResult.failure(uploadResult.errorMessage!);
      }

      // Create database record
      final documentRecord = await _createDocumentRecord(
        verificationId: verificationId,
        driverId: driverId,
        userId: userId,
        documentType: documentType,
        documentSide: documentSide,
        fileName: documentFile.name,
        filePath: filePath,
        fileSize: processedFile.bytes.length,
        mimeType: processedFile.mimeType,
        fileHash: fileHash,
        metadata: metadata,
      );

      _logger.info('✅ Document uploaded successfully: ${documentRecord.id}');

      return DriverDocumentUploadResult.success(
        documentId: documentRecord.id,
        filePath: filePath,
        fileUrl: uploadResult.fileUrl!,
        fileSize: processedFile.bytes.length,
        mimeType: processedFile.mimeType,
        fileHash: fileHash,
      );
    } catch (e, stackTrace) {
      _logger.error('❌ Document upload failed', e, stackTrace);
      return DriverDocumentUploadResult.failure('Upload failed: $e');
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
        'application/pdf',
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

      // For document verification, we want reasonable quality
      // Minimum dimensions check could be added here if needed
      
      return DocumentValidationResult.valid();
    } catch (e) {
      return DocumentValidationResult.invalid('Image validation failed: $e');
    }
  }

  /// Process document file (compression for images, validation for PDFs)
  Future<ProcessedDocumentFile> _processDocumentFile(
    XFile file,
    DocumentType documentType,
  ) async {
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
      // For PDFs, use as-is
      final bytes = await file.readAsBytes();
      return ProcessedDocumentFile(
        bytes: bytes,
        mimeType: mimeType,
      );
    }
  }

  /// Generate secure file path with user isolation
  String _generateSecureFilePath({
    required String userId,
    required String driverId,
    required DocumentType documentType,
    String? documentSide,
    required String originalFileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalFileName.split('.').last.toLowerCase();
    
    final sidePrefix = documentSide != null ? '${documentSide}_' : '';
    final fileName = 'driver_${driverId}_${documentType.name}_$sidePrefix$timestamp.$extension';
    
    // User-isolated path structure
    return '$userId/driver_verification/$fileName';
  }

  /// Calculate SHA-256 hash for file integrity
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
          .from(SupabaseConfig.driverVerificationDocumentsBucket)
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: false, // Prevent overwriting
            ),
          );

      // Generate signed URL for private bucket
      final signedUrl = await _supabase.storage
          .from(SupabaseConfig.driverVerificationDocumentsBucket)
          .createSignedUrl(filePath, 86400); // 24 hours

      return StorageUploadResult.success(signedUrl);
    } catch (e) {
      return StorageUploadResult.failure('Storage upload failed: $e');
    }
  }

  /// Create document record in database
  Future<DriverVerificationDocument> _createDocumentRecord({
    required String verificationId,
    required String driverId,
    required String userId,
    required DocumentType documentType,
    String? documentSide,
    required String fileName,
    required String filePath,
    required int fileSize,
    required String mimeType,
    required String fileHash,
    Map<String, dynamic>? metadata,
  }) async {
    final documentData = {
      'verification_id': verificationId,
      'driver_id': driverId,
      'user_id': userId,
      'document_type': documentType.name,
      'document_side': documentSide,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'mime_type': mimeType,
      'hash_checksum': fileHash,
      'upload_metadata': {
        'original_filename': fileName,
        'upload_timestamp': DateTime.now().toIso8601String(),
        'client_info': 'flutter_app',
        ...?metadata,
      },
    };

    final response = await _supabase
        .from('driver_verification_documents')
        .insert(documentData)
        .select()
        .single();

    return DriverVerificationDocument.fromJson(response);
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
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Delete document file and database record
  Future<bool> deleteDocument(String documentId) async {
    try {
      // Get document record
      final response = await _supabase
          .from('driver_verification_documents')
          .select('file_path, processing_status')
          .eq('id', documentId)
          .single();

      // Only allow deletion of pending documents
      if (response['processing_status'] != 'pending') {
        throw Exception('Cannot delete document that is being processed or completed');
      }

      // Delete from storage
      await _supabase.storage
          .from(SupabaseConfig.driverVerificationDocumentsBucket)
          .remove([response['file_path']]);

      // Delete database record
      await _supabase
          .from('driver_verification_documents')
          .delete()
          .eq('id', documentId);

      return true;
    } catch (e) {
      _logger.error('Failed to delete document: $documentId', e);
      return false;
    }
  }

  /// Get signed URL for document access
  Future<String?> getDocumentUrl(String filePath) async {
    try {
      return await _supabase.storage
          .from(SupabaseConfig.driverVerificationDocumentsBucket)
          .createSignedUrl(filePath, 3600); // 1 hour
    } catch (e) {
      _logger.error('Failed to get document URL: $filePath', e);
      return null;
    }
  }
}
