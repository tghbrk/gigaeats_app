import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

/// Utility class for image compression and processing
class ImageCompressionUtils {
  /// Compress image to reduce file size while maintaining quality
  static Future<Uint8List> compressImage(
    XFile imageFile, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
    int maxSizeKB = 500,
  }) async {
    try {
      // Read image bytes
      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        imageBytes = await File(imageFile.path).readAsBytes();
      }

      // Decode image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image if needed
      if (image.width > maxWidth || image.height > maxHeight) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? maxWidth : null,
          height: image.height > image.width ? maxHeight : null,
          interpolation: img.Interpolation.linear,
        );
      }

      // Compress image
      Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(image, quality: quality),
      );

      // If still too large, reduce quality further
      int currentQuality = quality;
      while (compressedBytes.length > maxSizeKB * 1024 && currentQuality > 20) {
        currentQuality -= 10;
        compressedBytes = Uint8List.fromList(
          img.encodeJpg(image, quality: currentQuality),
        );
      }

      return compressedBytes;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  /// Get image dimensions
  static Future<Map<String, int>> getImageDimensions(XFile imageFile) async {
    try {
      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        imageBytes = await File(imageFile.path).readAsBytes();
      }

      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      return {
        'width': image.width,
        'height': image.height,
      };
    } catch (e) {
      throw Exception('Failed to get image dimensions: $e');
    }
  }

  /// Validate image file
  static Future<bool> isValidImage(XFile imageFile) async {
    try {
      final dimensions = await getImageDimensions(imageFile);
      return dimensions['width']! > 0 && dimensions['height']! > 0;
    } catch (e) {
      return false;
    }
  }

  /// Get file size in bytes
  static Future<int> getFileSize(XFile file) async {
    try {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        return bytes.length;
      } else {
        final fileObj = File(file.path);
        return await fileObj.length();
      }
    } catch (e) {
      return 0;
    }
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Check if image needs compression
  static Future<bool> needsCompression(
    XFile imageFile, {
    int maxSizeKB = 500,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      final fileSize = await getFileSize(imageFile);
      final dimensions = await getImageDimensions(imageFile);

      return fileSize > maxSizeKB * 1024 ||
          dimensions['width']! > maxWidth ||
          dimensions['height']! > maxHeight;
    } catch (e) {
      return true; // Compress by default if we can't determine
    }
  }

  /// Compress image for document verification (high quality for OCR)
  static Future<Uint8List> compressForDocumentVerification(
    XFile imageFile, {
    int maxWidth = 2048,
    int maxHeight = 2048,
    int quality = 90,
    int maxSizeKB = 5000,
  }) async {
    try {
      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        imageBytes = await File(imageFile.path).readAsBytes();
      }

      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if needed while maintaining aspect ratio
      if (image.width > maxWidth || image.height > maxHeight) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? maxWidth : null,
          height: image.height > image.width ? maxHeight : null,
          interpolation: img.Interpolation.cubic,
        );
      }

      // Compress with high quality for OCR readability
      Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(image, quality: quality),
      );

      // If still too large, reduce quality gradually
      int currentQuality = quality;
      while (compressedBytes.length > maxSizeKB * 1024 && currentQuality > 60) {
        currentQuality -= 10;
        compressedBytes = Uint8List.fromList(
          img.encodeJpg(image, quality: currentQuality),
        );
      }

      return compressedBytes;
    } catch (e) {
      throw Exception('Failed to compress image for document verification: $e');
    }
  }

  /// Create thumbnail from image
  static Future<Uint8List> createThumbnail(
    XFile imageFile, {
    int size = 150,
    int quality = 80,
  }) async {
    try {
      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        imageBytes = await File(imageFile.path).readAsBytes();
      }

      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Create square thumbnail
      final thumbnail = img.copyResizeCropSquare(image, size: size);

      return Uint8List.fromList(
        img.encodeJpg(thumbnail, quality: quality),
      );
    } catch (e) {
      throw Exception('Failed to create thumbnail: $e');
    }
  }

  /// Validate image format
  static bool isValidImageFormat(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    const allowedFormats = ['jpg', 'jpeg', 'png', 'webp'];
    return allowedFormats.contains(extension);
  }

  /// Get image format from file
  static String getImageFormat(String fileName) {
    return fileName.toLowerCase().split('.').last;
  }

  /// Convert image to specific format
  static Future<Uint8List> convertImageFormat(
    XFile imageFile,
    String targetFormat, {
    int quality = 85,
  }) async {
    try {
      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        imageBytes = await File(imageFile.path).readAsBytes();
      }

      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      switch (targetFormat.toLowerCase()) {
        case 'jpg':
        case 'jpeg':
          return Uint8List.fromList(img.encodeJpg(image, quality: quality));
        case 'png':
          return Uint8List.fromList(img.encodePng(image));
        case 'webp':
          // WebP encoding might not be available in all versions
          // Fall back to JPEG for compatibility
          return Uint8List.fromList(img.encodeJpg(image, quality: quality));
        default:
          throw Exception('Unsupported format: $targetFormat');
      }
    } catch (e) {
      throw Exception('Failed to convert image format: $e');
    }
  }

  /// Optimize image for profile picture
  static Future<Uint8List> optimizeForProfile(XFile imageFile) async {
    return compressImage(
      imageFile,
      maxWidth: 512,
      maxHeight: 512,
      quality: 90,
      maxSizeKB: 300,
    );
  }

  /// Optimize image for cover photo
  static Future<Uint8List> optimizeForCover(XFile imageFile) async {
    return compressImage(
      imageFile,
      maxWidth: 1200,
      maxHeight: 800,
      quality: 85,
      maxSizeKB: 800,
    );
  }

  /// Optimize image for menu item
  static Future<Uint8List> optimizeForMenuItem(XFile imageFile) async {
    return compressImage(
      imageFile,
      maxWidth: 800,
      maxHeight: 600,
      quality: 85,
      maxSizeKB: 500,
    );
  }
}
