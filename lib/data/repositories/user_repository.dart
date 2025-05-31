import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart' as app_models;
import '../models/user_role.dart';
import '../../core/config/supabase_config.dart';
import 'base_repository.dart';

class UserRepository extends BaseRepository {
  UserRepository({
    SupabaseClient? client,
  }) : super(client: client);

  /// Get user profile by Supabase UID
  Future<app_models.User?> getUserProfile(String supabaseUid) async {
    return executeQuery(() async {
      final response = await client
          .from('users')
          .select('*')
          .eq('supabase_user_id', supabaseUid)
          .maybeSingle();

      return response != null ? app_models.User.fromJson(response) : null;
    });
  }

  /// Get current user profile
  Future<app_models.User?> getCurrentUserProfile() async {
    final supabaseUid = currentUserUid;
    if (supabaseUid == null) return null;

    return getUserProfile(supabaseUid);
  }

  /// Update user profile
  Future<app_models.User> updateUserProfile(app_models.User user) async {
    return executeQuery(() async {
      final userData = user.toJson();
      
      // Update main user record
      await client
          .from('users')
          .update({
            'full_name': userData['full_name'],
            'phone_number': userData['phone_number'],
            'profile_image_url': userData['profile_image_url'],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('supabase_user_id', user.id);

      // Get updated user
      final response = await client
          .from('users')
          .select('''
            *,
            profile:user_profiles!user_profiles_supabase_user_id_fkey(*)
          ''')
          .eq('supabase_user_id', user.id)
          .single();

      return app_models.User.fromJson(response);
    });
  }

  /// Update user profile details (extended information)
  Future<void> updateUserProfileDetails({
    required String firebaseUid,
    String? companyName,
    String? businessRegistrationNumber,
    String? businessAddress,
    String? businessType,
    List<String>? assignedRegions,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? kycDocuments,
  }) async {
    return executeQuery(() async {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (companyName != null) updateData['company_name'] = companyName;
      if (businessRegistrationNumber != null) {
        updateData['business_registration_number'] = businessRegistrationNumber;
      }
      if (businessAddress != null) updateData['business_address'] = businessAddress;
      if (businessType != null) updateData['business_type'] = businessType;
      if (assignedRegions != null) updateData['assigned_regions'] = assignedRegions;
      if (preferences != null) updateData['preferences'] = preferences;
      if (kycDocuments != null) updateData['kyc_documents'] = kycDocuments;

      await client
          .from('user_profiles')
          .update(updateData)
          .eq('supabase_user_id', firebaseUid);
    });
  }

  /// Upload profile image
  Future<String> uploadProfileImage(File image, String firebaseUid) async {
    return executeQuery(() async {
      final fileName = '${firebaseUid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'profiles/$fileName';

      await client.storage
          .from(SupabaseConfig.profileImagesBucket)
          .upload(filePath, image);

      final publicUrl = client.storage
          .from(SupabaseConfig.profileImagesBucket)
          .getPublicUrl(filePath);

      // Update user profile with new image URL
      await client
          .from('users')
          .update({
            'profile_image_url': publicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('supabase_user_id', firebaseUid);

      return publicUrl;
    });
  }

  /// Upload KYC document
  Future<String> uploadKycDocument(File document, String firebaseUid, String documentType) async {
    return executeQuery(() async {
      final fileName = '${firebaseUid}_${documentType}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = 'kyc/$fileName';

      await client.storage
          .from(SupabaseConfig.kycDocumentsBucket)
          .upload(filePath, document);

      final publicUrl = client.storage
          .from(SupabaseConfig.kycDocumentsBucket)
          .getPublicUrl(filePath);

      // Update user profile with KYC document
      final currentProfile = await client
          .from('user_profiles')
          .select('kyc_documents')
          .eq('supabase_user_id', firebaseUid)
          .single();

      final kycDocuments = Map<String, dynamic>.from(
        currentProfile['kyc_documents'] as Map<String, dynamic>? ?? {}
      );
      kycDocuments[documentType] = {
        'url': publicUrl,
        'uploaded_at': DateTime.now().toIso8601String(),
        'status': 'pending_review',
      };

      await client
          .from('user_profiles')
          .update({
            'kyc_documents': kycDocuments,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('supabase_user_id', firebaseUid);

      return publicUrl;
    });
  }

  /// Update user role (admin only)
  Future<void> updateUserRole(String firebaseUid, UserRole role) async {
    return executeQuery(() async {
      await client
          .from('users')
          .update({
            'role': role.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('supabase_user_id', firebaseUid);
    });
  }

  /// Get users by role (admin only)
  Future<List<app_models.User>> getUsersByRole(UserRole role, {
    int limit = 50,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      final response = await client
          .from('users')
          .select('''
            *,
            profile:user_profiles!user_profiles_supabase_user_id_fkey(*)
          ''')
          .eq('role', role.value)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => app_models.User.fromJson(json)).toList();
    });
  }

  /// Search users (admin only)
  Future<List<app_models.User>> searchUsers(String query, {
    UserRole? role,
    int limit = 20,
  }) async {
    return executeQuery(() async {
      var supabaseQuery = client
          .from('users')
          .select('''
            *,
            profile:user_profiles!user_profiles_supabase_user_id_fkey(*)
          ''')
          .or('full_name.ilike.%$query%,email.ilike.%$query%');

      if (role != null) {
        supabaseQuery = supabaseQuery.eq('role', role.value);
      }

      final response = await supabaseQuery
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) => app_models.User.fromJson(json)).toList();
    });
  }

  /// Update user verification status (admin only)
  Future<void> updateUserVerificationStatus(String firebaseUid, bool isVerified) async {
    return executeQuery(() async {
      await client
          .from('users')
          .update({
            'is_verified': isVerified,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('supabase_user_id', firebaseUid);
    });
  }

  /// Update user active status (admin only)
  Future<void> updateUserActiveStatus(String firebaseUid, bool isActive) async {
    return executeQuery(() async {
      await client
          .from('users')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('supabase_user_id', firebaseUid);
    });
  }

  /// Get user statistics (admin only)
  Future<Map<String, dynamic>> getUserStatistics() async {
    return executeQuery(() async {
      final response = await client.rpc('get_user_statistics');
      return response as Map<String, dynamic>;
    });
  }

  /// Store FCM token for push notifications
  Future<void> storeFcmToken(String firebaseUid, String fcmToken, String deviceType) async {
    return executeQuery(() async {
      await client
          .from('user_fcm_tokens')
          .upsert({
            'supabase_user_id': firebaseUid,
            'fcm_token': fcmToken,
            'device_type': deviceType,
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          });
    });
  }

  /// Remove FCM token
  Future<void> removeFcmToken(String firebaseUid, String fcmToken) async {
    return executeQuery(() async {
      await client
          .from('user_fcm_tokens')
          .delete()
          .eq('supabase_user_id', firebaseUid)
          .eq('fcm_token', fcmToken);
    });
  }
}
