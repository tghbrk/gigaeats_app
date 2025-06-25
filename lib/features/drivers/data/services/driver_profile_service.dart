import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

import '../../../vendors/data/models/driver.dart';

/// Service for driver profile management operations
/// Handles profile updates, photo uploads, and profile data synchronization
class DriverProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload driver profile photo to Supabase Storage
  Future<String> uploadProfilePhoto({
    required String driverId,
    required XFile imageFile,
  }) async {
    try {
      debugPrint('DriverProfileService: Uploading profile photo for driver: $driverId');

      // Generate unique filename
      final fileName = 'driver_${driverId}_${DateTime.now().millisecondsSinceEpoch}.${path.extension(imageFile.path).substring(1)}';
      final filePath = 'driver-profiles/$fileName';

      // Read file bytes
      Uint8List fileBytes;
      if (kIsWeb) {
        fileBytes = await imageFile.readAsBytes();
      } else {
        fileBytes = await File(imageFile.path).readAsBytes();
      }

      // Validate file size (max 5MB)
      if (fileBytes.length > 5 * 1024 * 1024) {
        throw Exception('Image size must be less than 5MB');
      }

      // Upload to Supabase Storage
      await _supabase.storage
          .from('user-uploads')
          .uploadBinary(filePath, fileBytes);

      // Get public URL
      final publicUrl = _supabase.storage
          .from('user-uploads')
          .getPublicUrl(filePath);

      debugPrint('DriverProfileService: Profile photo uploaded successfully');
      return publicUrl;
    } catch (e) {
      debugPrint('DriverProfileService: Error uploading profile photo: $e');
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  /// Update driver profile with comprehensive validation
  Future<bool> updateDriverProfile({
    required String driverId,
    String? name,
    String? phoneNumber,
    VehicleDetails? vehicleDetails,
    String? profilePhotoUrl,
  }) async {
    try {
      debugPrint('DriverProfileService: Updating driver profile: $driverId');

      // Validate inputs
      if (name != null && name.trim().isEmpty) {
        throw Exception('Name cannot be empty');
      }

      if (phoneNumber != null && phoneNumber.trim().isEmpty) {
        throw Exception('Phone number cannot be empty');
      }

      // Prepare update data
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name.trim();
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber.trim();
      if (vehicleDetails != null) updateData['vehicle_details'] = vehicleDetails.toJsonB();
      if (profilePhotoUrl != null) updateData['profile_photo_url'] = profilePhotoUrl;

      // Update driver record
      await _supabase
          .from('drivers')
          .update(updateData)
          .eq('id', driverId);

      debugPrint('DriverProfileService: Driver profile updated successfully');
      return true;
    } catch (e) {
      debugPrint('DriverProfileService: Error updating driver profile: $e');
      return false;
    }
  }

  /// Get driver profile by driver ID
  Future<Driver?> getDriverProfile(String driverId) async {
    try {
      debugPrint('DriverProfileService: Getting driver profile: $driverId');

      final response = await _supabase
          .from('drivers')
          .select('''
            id,
            user_id,
            vendor_id,
            name,
            phone_number,
            status,
            is_active,
            vehicle_details,
            profile_photo_url,
            last_location,
            last_seen,
            created_at,
            updated_at
          ''')
          .eq('id', driverId)
          .single();

      debugPrint('DriverProfileService: Driver profile retrieved successfully');
      return Driver.fromJson(response);
    } catch (e) {
      debugPrint('DriverProfileService: Error getting driver profile: $e');
      return null;
    }
  }

  /// Get driver profile by user ID
  Future<Driver?> getDriverProfileByUserId(String userId) async {
    try {
      debugPrint('DriverProfileService: Getting driver profile by user ID: $userId');

      final response = await _supabase
          .from('drivers')
          .select('''
            id,
            user_id,
            vendor_id,
            name,
            phone_number,
            status,
            is_active,
            vehicle_details,
            profile_photo_url,
            last_location,
            last_seen,
            created_at,
            updated_at
          ''')
          .eq('user_id', userId)
          .single();

      debugPrint('DriverProfileService: Driver profile retrieved successfully');
      return Driver.fromJson(response);
    } catch (e) {
      debugPrint('DriverProfileService: Error getting driver profile by user ID: $e');
      return null;
    }
  }

  /// Get driver profile stream for real-time updates
  Stream<Driver?> getDriverProfileStream(String userId) {
    try {
      debugPrint('🚗 DriverProfileService: Setting up driver profile stream for user: $userId');

      return _supabase
          .from('drivers')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .map((data) {
            debugPrint('🚗 DriverProfileService: Stream data received: ${data.length} records');
            if (data.isNotEmpty) {
              debugPrint('🚗 DriverProfileService: First record: ${data.first}');
            }

            if (data.isEmpty) {
              debugPrint('🚗 DriverProfileService: No driver record found for user: $userId');
              return null;
            }

            try {
              final driver = Driver.fromJson(data.first);
              debugPrint('🚗 DriverProfileService: Successfully parsed driver: ${driver.name} (${driver.id})');
              return driver;
            } catch (parseError) {
              debugPrint('🚗 DriverProfileService: Error parsing driver data: $parseError');
              debugPrint('🚗 DriverProfileService: Raw data: ${data.first}');
              return null;
            }
          });
    } catch (e) {
      debugPrint('🚗 DriverProfileService: Error setting up driver profile stream: $e');
      return Stream.value(null);
    }
  }

  /// Validate image file for profile photo
  bool isValidImageFile(XFile file) {
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    final extension = path.extension(file.path).toLowerCase().substring(1);
    return allowedExtensions.contains(extension);
  }

  /// Check if file size is within limits
  Future<bool> isFileSizeValid(XFile file, {double maxSizeMB = 5.0}) async {
    try {
      final bytes = await file.readAsBytes();
      final sizeInMB = bytes.length / (1024 * 1024);
      return sizeInMB <= maxSizeMB;
    } catch (e) {
      debugPrint('DriverProfileService: Error checking file size: $e');
      return false;
    }
  }

  /// Delete old profile photo from storage
  Future<bool> deleteProfilePhoto(String photoUrl) async {
    try {
      if (photoUrl.isEmpty) return true;

      // Extract file path from URL
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length < 2) return false;
      
      final filePath = pathSegments.sublist(pathSegments.length - 2).join('/');
      
      await _supabase.storage
          .from('user-uploads')
          .remove([filePath]);

      debugPrint('DriverProfileService: Old profile photo deleted successfully');
      return true;
    } catch (e) {
      debugPrint('DriverProfileService: Error deleting profile photo: $e');
      return false;
    }
  }

  /// Update driver profile photo
  Future<String?> updateProfilePhoto({
    required String driverId,
    required XFile imageFile,
    String? oldPhotoUrl,
  }) async {
    try {
      // Upload new photo
      final newPhotoUrl = await uploadProfilePhoto(
        driverId: driverId,
        imageFile: imageFile,
      );

      // Update driver record with new photo URL
      final success = await updateDriverProfile(
        driverId: driverId,
        profilePhotoUrl: newPhotoUrl,
      );

      if (success) {
        // Delete old photo if exists
        if (oldPhotoUrl != null && oldPhotoUrl.isNotEmpty) {
          await deleteProfilePhoto(oldPhotoUrl);
        }
        return newPhotoUrl;
      }

      return null;
    } catch (e) {
      debugPrint('DriverProfileService: Error updating profile photo: $e');
      return null;
    }
  }
}
