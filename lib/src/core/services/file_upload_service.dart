import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../utils/image_compression_utils.dart';

class FileUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();

  /// Upload profile image with compression and progress tracking
  Future<String> uploadProfileImage(String userId, XFile imageFile) async {
    try {
      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'profiles/$fileName';

      // Compress image for profile picture
      final compressedBytes = await ImageCompressionUtils.optimizeForProfile(imageFile);

      await _supabase.storage
          .from('user-uploads')
          .uploadBinary(filePath, compressedBytes);

      return _supabase.storage
          .from('user-uploads')
          .getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Upload profile image with custom compression settings
  Future<String> uploadProfileImageWithCompression(
    String userId,
    XFile imageFile, {
    int maxWidth = 512,
    int maxHeight = 512,
    int quality = 90,
    int maxSizeKB = 300,
  }) async {
    try {
      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'profiles/$fileName';

      // Compress image with custom settings
      final compressedBytes = await ImageCompressionUtils.compressImage(
        imageFile,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
        maxSizeKB: maxSizeKB,
      );

      await _supabase.storage
          .from('user-uploads')
          .uploadBinary(filePath, compressedBytes);

      return _supabase.storage
          .from('user-uploads')
          .getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Upload menu item image
  Future<String> uploadMenuItemImage(String vendorId, String menuItemId, XFile imageFile) async {
    try {
      final fileName = 'menu_${vendorId}_${menuItemId}_${DateTime.now().millisecondsSinceEpoch}.${path.extension(imageFile.path).substring(1)}';
      final filePath = 'menu-items/$fileName';

      Uint8List fileBytes;
      if (kIsWeb) {
        fileBytes = await imageFile.readAsBytes();
      } else {
        fileBytes = await File(imageFile.path).readAsBytes();
      }

      await _supabase.storage
          .from('user-uploads')
          .uploadBinary(filePath, fileBytes);

      return _supabase.storage
          .from('user-uploads')
          .getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Failed to upload menu item image: $e');
    }
  }

  /// Upload vendor cover image
  Future<String> uploadVendorCoverImage(String vendorId, XFile imageFile) async {
    try {
      final fileName = 'vendor_cover_${vendorId}_${DateTime.now().millisecondsSinceEpoch}.${path.extension(imageFile.path).substring(1)}';
      final filePath = 'vendor-covers/$fileName';

      Uint8List fileBytes;
      if (kIsWeb) {
        fileBytes = await imageFile.readAsBytes();
      } else {
        fileBytes = await File(imageFile.path).readAsBytes();
      }

      await _supabase.storage
          .from('user-uploads')
          .uploadBinary(filePath, fileBytes);

      return _supabase.storage
          .from('user-uploads')
          .getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Failed to upload vendor cover image: $e');
    }
  }

  /// Upload KYC document
  Future<String> uploadKYCDocument(String userId, String documentType, PlatformFile file) async {
    try {
      final fileName = 'kyc_${userId}_${documentType}_${DateTime.now().millisecondsSinceEpoch}.${path.extension(file.name)}';
      final filePath = 'kyc-documents/$fileName';

      Uint8List fileBytes;
      if (kIsWeb) {
        fileBytes = file.bytes!;
      } else {
        fileBytes = await File(file.path!).readAsBytes();
      }

      await _supabase.storage
          .from('user-uploads')
          .uploadBinary(filePath, fileBytes);

      return _supabase.storage
          .from('user-uploads')
          .getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Failed to upload KYC document: $e');
    }
  }

  /// Generic file upload method
  Future<String> uploadFile(
    XFile file, {
    required String bucketName,
    required String fileName,
    String? folderPath,
  }) async {
    try {
      final filePath = folderPath != null ? '$folderPath/$fileName' : fileName;

      Uint8List fileBytes;
      if (kIsWeb) {
        fileBytes = await file.readAsBytes();
      } else {
        fileBytes = await File(file.path).readAsBytes();
      }

      await _supabase.storage
          .from(bucketName)
          .uploadBinary(filePath, fileBytes);

      return _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Pick image from gallery or camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      return await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Pick multiple images
  Future<List<XFile>> pickMultipleImages() async {
    try {
      return await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      throw Exception('Failed to pick images: $e');
    }
  }

  /// Pick document file
  Future<PlatformFile?> pickDocument({
    List<String> allowedExtensions = const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      return result?.files.first;
    } catch (e) {
      throw Exception('Failed to pick document: $e');
    }
  }

  /// Delete file from storage
  Future<void> deleteFile(String filePath) async {
    try {
      await _supabase.storage
          .from('user-uploads')
          .remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Get file URL from path
  String getFileUrl(String filePath) {
    return _supabase.storage
        .from('user-uploads')
        .getPublicUrl(filePath);
  }

  /// Validate image file
  bool isValidImageFile(XFile file) {
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    final extension = path.extension(file.path).toLowerCase().substring(1);
    return allowedExtensions.contains(extension);
  }

  /// Validate document file
  bool isValidDocumentFile(PlatformFile file) {
    final allowedExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];
    final extension = path.extension(file.name).toLowerCase().substring(1);
    return allowedExtensions.contains(extension);
  }

  /// Get file size in MB
  double getFileSizeInMB(int bytes) {
    return bytes / (1024 * 1024);
  }

  /// Check if file size is within limit
  bool isFileSizeValid(int bytes, {double maxSizeMB = 5.0}) {
    return getFileSizeInMB(bytes) <= maxSizeMB;
  }

  /// Compress image if needed
  Future<XFile?> compressImageIfNeeded(XFile imageFile, {double maxSizeMB = 2.0}) async {
    try {
      Uint8List bytes;
      if (kIsWeb) {
        bytes = await imageFile.readAsBytes();
      } else {
        bytes = await File(imageFile.path).readAsBytes();
      }

      if (isFileSizeValid(bytes.length, maxSizeMB: maxSizeMB)) {
        return imageFile;
      }

      // If file is too large, pick with lower quality
      return await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 70,
      );
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  /// Create storage bucket if it doesn't exist
  Future<void> ensureStorageBucketExists() async {
    try {
      // Check if bucket exists
      final buckets = await _supabase.storage.listBuckets();
      final bucketExists = buckets.any((bucket) => bucket.name == 'user-uploads');

      if (!bucketExists) {
        // Create bucket
        await _supabase.storage.createBucket(
          'user-uploads',
          BucketOptions(
            public: true,
            allowedMimeTypes: [
              'image/jpeg',
              'image/png',
              'image/gif',
              'image/webp',
              'application/pdf',
              'application/msword',
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            ],
            fileSizeLimit: '5MB',
          ),
        );
      }
    } catch (e) {
      // Bucket might already exist or we might not have permission to create it
      // This is fine for most use cases
      if (kDebugMode) {
        print('Storage bucket check/creation failed: $e');
      }
    }
  }
}
