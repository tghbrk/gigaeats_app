import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;

import '../../../../core/config/supabase_config.dart';

/// Enhanced photo storage service for driver workflow with optimized upload and metadata
class EnhancedPhotoStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload delivery proof photo with enhanced metadata and optimization
  Future<PhotoUploadResult> uploadDeliveryProofPhoto({
    required XFile photo,
    required String orderId,
    required String driverId,
    required double latitude,
    required double longitude,
    double? accuracy,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      debugPrint('📸 [PHOTO-STORAGE] Uploading delivery proof photo for order: $orderId');

      // Optimize photo for delivery proof
      final optimizedPhoto = await _optimizeDeliveryPhoto(photo);
      
      // Generate unique filename with metadata
      final fileName = _generateDeliveryProofFileName(orderId, driverId);
      
      // Prepare metadata
      final metadata = _buildPhotoMetadata(
        orderId: orderId,
        driverId: driverId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        additionalMetadata: additionalMetadata,
      );

      // Upload to delivery-proofs bucket
      final photoUrl = await _uploadToStorage(
        bucketName: SupabaseConfig.deliveryProofsBucket,
        fileName: fileName,
        fileBytes: optimizedPhoto,
        metadata: metadata,
      );

      // Store photo record in database
      await _storePhotoRecord(
        orderId: orderId,
        driverId: driverId,
        photoUrl: photoUrl,
        fileName: fileName,
        metadata: metadata,
      );

      debugPrint('✅ [PHOTO-STORAGE] Delivery proof photo uploaded successfully');
      return PhotoUploadResult.success(photoUrl, fileName);

    } catch (e) {
      debugPrint('❌ [PHOTO-STORAGE] Failed to upload delivery proof photo: $e');
      return PhotoUploadResult.failure(e.toString());
    }
  }

  /// Upload pickup verification photo with vendor-specific metadata
  Future<PhotoUploadResult> uploadPickupVerificationPhoto({
    required XFile photo,
    required String orderId,
    required String driverId,
    required String vendorId,
    Map<String, dynamic>? verificationData,
  }) async {
    try {
      debugPrint('📸 [PHOTO-STORAGE] Uploading pickup verification photo for order: $orderId');

      // Optimize photo for pickup verification
      final optimizedPhoto = await _optimizePickupPhoto(photo);
      
      // Generate unique filename
      final fileName = _generatePickupVerificationFileName(orderId, driverId);
      
      // Prepare metadata
      final metadata = _buildPickupPhotoMetadata(
        orderId: orderId,
        driverId: driverId,
        vendorId: vendorId,
        verificationData: verificationData,
      );

      // Upload to pickup-verifications bucket
      final photoUrl = await _uploadToStorage(
        bucketName: SupabaseConfig.pickupVerificationsBucket,
        fileName: fileName,
        fileBytes: optimizedPhoto,
        metadata: metadata,
      );

      // Store photo record in database
      await _storePickupPhotoRecord(
        orderId: orderId,
        driverId: driverId,
        vendorId: vendorId,
        photoUrl: photoUrl,
        fileName: fileName,
        metadata: metadata,
      );

      debugPrint('✅ [PHOTO-STORAGE] Pickup verification photo uploaded successfully');
      return PhotoUploadResult.success(photoUrl, fileName);

    } catch (e) {
      debugPrint('❌ [PHOTO-STORAGE] Failed to upload pickup verification photo: $e');
      return PhotoUploadResult.failure(e.toString());
    }
  }

  /// Optimize photo for delivery proof (balance quality and file size)
  Future<Uint8List> _optimizeDeliveryPhoto(XFile photo) async {
    final bytes = await photo.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize if too large (max 1920x1080 for delivery proofs)
    img.Image resized = image;
    if (image.width > 1920 || image.height > 1080) {
      resized = img.copyResize(
        image,
        width: image.width > image.height ? 1920 : null,
        height: image.height > image.width ? 1080 : null,
        interpolation: img.Interpolation.linear,
      );
    }

    // Compress with good quality for delivery proof
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  /// Optimize photo for pickup verification (smaller size for faster upload)
  Future<Uint8List> _optimizePickupPhoto(XFile photo) async {
    final bytes = await photo.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize for pickup verification (max 1280x720)
    img.Image resized = image;
    if (image.width > 1280 || image.height > 720) {
      resized = img.copyResize(
        image,
        width: image.width > image.height ? 1280 : null,
        height: image.height > image.width ? 720 : null,
        interpolation: img.Interpolation.linear,
      );
    }

    // Compress with moderate quality for pickup verification
    return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
  }

  /// Generate unique filename for delivery proof
  String _generateDeliveryProofFileName(String orderId, String driverId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'delivery_proof_${orderId}_${driverId}_$timestamp.jpg';
  }

  /// Generate unique filename for pickup verification
  String _generatePickupVerificationFileName(String orderId, String driverId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'pickup_verification_${orderId}_${driverId}_$timestamp.jpg';
  }

  /// Build metadata for delivery proof photos
  Map<String, String> _buildPhotoMetadata({
    required String orderId,
    required String driverId,
    required double latitude,
    required double longitude,
    double? accuracy,
    Map<String, dynamic>? additionalMetadata,
  }) {
    final metadata = <String, String>{
      'order_id': orderId,
      'driver_id': driverId,
      'photo_type': 'delivery_proof',
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'captured_at': DateTime.now().toIso8601String(),
    };

    if (accuracy != null) {
      metadata['gps_accuracy'] = accuracy.toString();
    }

    if (additionalMetadata != null) {
      additionalMetadata.forEach((key, value) {
        metadata[key] = value.toString();
      });
    }

    return metadata;
  }

  /// Build metadata for pickup verification photos
  Map<String, String> _buildPickupPhotoMetadata({
    required String orderId,
    required String driverId,
    required String vendorId,
    Map<String, dynamic>? verificationData,
  }) {
    final metadata = <String, String>{
      'order_id': orderId,
      'driver_id': driverId,
      'vendor_id': vendorId,
      'photo_type': 'pickup_verification',
      'captured_at': DateTime.now().toIso8601String(),
    };

    if (verificationData != null) {
      verificationData.forEach((key, value) {
        metadata[key] = value.toString();
      });
    }

    return metadata;
  }

  /// Upload file to Supabase storage
  Future<String> _uploadToStorage({
    required String bucketName,
    required String fileName,
    required Uint8List fileBytes,
    required Map<String, String> metadata,
  }) async {
    await _supabase.storage.from(bucketName).uploadBinary(
      fileName,
      fileBytes,
      fileOptions: FileOptions(
        metadata: metadata,
        contentType: 'image/jpeg',
      ),
    );

    return _supabase.storage.from(bucketName).getPublicUrl(fileName);
  }

  /// Store delivery photo record in database
  Future<void> _storePhotoRecord({
    required String orderId,
    required String driverId,
    required String photoUrl,
    required String fileName,
    required Map<String, String> metadata,
  }) async {
    await _supabase.from('delivery_photos').insert({
      'order_id': orderId,
      'driver_id': driverId,
      'photo_url': photoUrl,
      'file_name': fileName,
      'photo_type': 'delivery_proof',
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Store pickup photo record in database
  Future<void> _storePickupPhotoRecord({
    required String orderId,
    required String driverId,
    required String vendorId,
    required String photoUrl,
    required String fileName,
    required Map<String, String> metadata,
  }) async {
    await _supabase.from('pickup_photos').insert({
      'order_id': orderId,
      'driver_id': driverId,
      'vendor_id': vendorId,
      'photo_url': photoUrl,
      'file_name': fileName,
      'photo_type': 'pickup_verification',
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get delivery proof photos for an order
  Future<List<String>> getDeliveryProofPhotos(String orderId) async {
    try {
      final response = await _supabase
          .from('delivery_photos')
          .select('photo_url')
          .eq('order_id', orderId)
          .eq('photo_type', 'delivery_proof')
          .order('created_at', ascending: false);

      return response.map((record) => record['photo_url'] as String).toList();
    } catch (e) {
      debugPrint('❌ [PHOTO-STORAGE] Failed to get delivery proof photos: $e');
      return [];
    }
  }

  /// Get pickup verification photos for an order
  Future<List<String>> getPickupVerificationPhotos(String orderId) async {
    try {
      final response = await _supabase
          .from('pickup_photos')
          .select('photo_url')
          .eq('order_id', orderId)
          .eq('photo_type', 'pickup_verification')
          .order('created_at', ascending: false);

      return response.map((record) => record['photo_url'] as String).toList();
    } catch (e) {
      debugPrint('❌ [PHOTO-STORAGE] Failed to get pickup verification photos: $e');
      return [];
    }
  }

  /// Delete photo from storage and database
  Future<bool> deletePhoto(String photoUrl, String orderId, String photoType) async {
    try {
      // Extract file name from URL
      final uri = Uri.parse(photoUrl);
      final fileName = uri.pathSegments.last;
      
      // Determine bucket based on photo type
      final bucketName = photoType == 'delivery_proof' 
          ? SupabaseConfig.deliveryProofsBucket
          : SupabaseConfig.pickupVerificationsBucket;

      // Delete from storage
      await _supabase.storage.from(bucketName).remove([fileName]);

      // Delete from database
      final tableName = photoType == 'delivery_proof' ? 'delivery_photos' : 'pickup_photos';
      await _supabase
          .from(tableName)
          .delete()
          .eq('order_id', orderId)
          .eq('photo_url', photoUrl);

      return true;
    } catch (e) {
      debugPrint('❌ [PHOTO-STORAGE] Failed to delete photo: $e');
      return false;
    }
  }
}

/// Result of photo upload operations
class PhotoUploadResult {
  final bool isSuccess;
  final String? photoUrl;
  final String? fileName;
  final String? errorMessage;

  const PhotoUploadResult._(this.isSuccess, this.photoUrl, this.fileName, this.errorMessage);

  factory PhotoUploadResult.success(String photoUrl, String fileName) => 
      PhotoUploadResult._(true, photoUrl, fileName, null);

  factory PhotoUploadResult.failure(String message) => 
      PhotoUploadResult._(false, null, null, message);
}

/// Provider for enhanced photo storage service
final enhancedPhotoStorageServiceProvider = Provider<EnhancedPhotoStorageService>((ref) {
  return EnhancedPhotoStorageService();
});
