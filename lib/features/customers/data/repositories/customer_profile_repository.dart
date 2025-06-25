import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/customer_profile.dart';
import '../../../../core/utils/logger.dart';

/// Repository for managing customer profiles (direct customer app usage)
class CustomerProfileRepository {
  final supabase.SupabaseClient _supabase;
  final AppLogger _logger = AppLogger();

  CustomerProfileRepository({supabase.SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase.Supabase.instance.client;

  /// Get current user's customer profile with addresses and preferences
  Future<CustomerProfile?> getCurrentProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found');
        return null;
      }

      _logger.info('Fetching customer profile for user: ${user.id}');

      // Check current session status with detailed logging
      final session = _supabase.auth.currentSession;
      _logger.info('Current session status: ${session != null ? 'exists' : 'null'}');
      if (session != null) {
        _logger.info('Session expires at: ${session.expiresAt}');
        _logger.info('Session is expired: ${session.isExpired}');
      }

      // Try to fetch the actual customer profile from database first
      try {
        _logger.info('🔍 Attempting to fetch customer profile from database...');

        final response = await _supabase
            .from('customer_profiles')
            .select('*')
            .eq('user_id', user.id)
            .single()
            .timeout(const Duration(seconds: 10));

        _logger.info('✅ Successfully fetched customer profile from database');
        return CustomerProfile.fromJson(response);
      } catch (e) {
        _logger.warning('⚠️ Failed to fetch from database, using fallback: $e');
        _logger.info('🔄 Creating fallback profile directly from user metadata...');
        return await _createBasicProfile(user);
      }
    } catch (e) {
      _logger.error('Error fetching customer profile', e);
      // Return a basic fallback profile instead of throwing
      final user = _supabase.auth.currentUser;
      if (user != null) {
        return await _createBasicProfile(user);
      }
      return null;
    }
  }

  /// Create a basic customer profile for users without one
  Future<CustomerProfile?> _createBasicProfile(supabase.User user) async {
    try {
      _logger.info('🔧 Creating basic customer profile for user: ${user.id}');
      _logger.info('🔧 User email: ${user.email}');
      _logger.info('🔧 User metadata: ${user.userMetadata}');
      _logger.info('🔧 User phone: ${user.phone}');
      _logger.info('🔧 Email confirmed at: ${user.emailConfirmedAt}');

      // Try to get the actual customer profile ID from database first
      String profileId = user.id; // Default fallback
      try {
        final profileResponse = await _supabase
            .from('customer_profiles')
            .select('id')
            .eq('user_id', user.id)
            .single()
            .timeout(const Duration(seconds: 5));

        profileId = profileResponse['id'] as String;
        _logger.info('🔧 Found actual customer profile ID: $profileId');
      } catch (e) {
        _logger.warning('🔧 Could not fetch customer profile ID, using user ID as fallback: $e');
      }

      // Create a basic profile without database insertion (to avoid RLS issues)
      final basicProfile = CustomerProfile(
        id: profileId, // Use actual profile ID if found, otherwise user ID
        userId: user.id,
        fullName: user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'Customer',
        phoneNumber: user.phone,
        profileImageUrl: user.userMetadata?['profile_image_url'],
        addresses: const [], // Empty addresses list
        preferences: null, // No preferences
        loyaltyPoints: 0,
        totalOrders: 0,
        totalSpent: 0.0,
        isVerified: user.emailConfirmedAt != null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _logger.info('✅ Basic customer profile created successfully');
      _logger.info('✅ Profile ID: ${basicProfile.id}');
      _logger.info('✅ Profile name: ${basicProfile.fullName}');
      _logger.info('✅ Profile verified: ${basicProfile.isVerified}');

      return basicProfile;
    } catch (e, stackTrace) {
      _logger.error('❌ Error creating basic customer profile: $e');
      _logger.error('❌ Stack trace: $stackTrace');

      // Return a minimal profile as last resort
      try {
        // Try to get the actual customer profile ID one more time
        String profileId = user.id; // Default fallback
        try {
          final profileResponse = await _supabase
              .from('customer_profiles')
              .select('id')
              .eq('user_id', user.id)
              .single()
              .timeout(const Duration(seconds: 3));

          profileId = profileResponse['id'] as String;
          _logger.info('🆘 Found actual customer profile ID for minimal profile: $profileId');
        } catch (e) {
          _logger.warning('🆘 Could not fetch customer profile ID for minimal profile, using user ID: $e');
        }

        final minimalProfile = CustomerProfile(
          id: profileId, // Use actual profile ID if found
          userId: user.id,
          fullName: user.email?.split('@').first ?? 'Customer',
          phoneNumber: null,
          profileImageUrl: null,
          addresses: const [],
          preferences: null,
          loyaltyPoints: 0,
          totalOrders: 0,
          totalSpent: 0.0,
          isVerified: user.emailConfirmedAt != null,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        _logger.info('🆘 Created minimal fallback profile as last resort');
        return minimalProfile;
      } catch (e2) {
        _logger.error('💥 Failed to create even minimal profile: $e2');
        return null;
      }
    }
  }

  /// Create a new customer profile
  Future<CustomerProfile> createProfile(CustomerProfile profile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      _logger.info('Creating customer profile for user: ${user.id}');

      // Create profile data (excluding addresses and preferences)
      final profileData = {
        'user_id': user.id,
        'full_name': profile.fullName,
        'phone_number': profile.phoneNumber,
        'profile_image_url': profile.profileImageUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final profileResponse = await _supabase
          .from('customer_profiles')
          .insert(profileData)
          .select()
          .single();

      final profileId = profileResponse['id'] as String;

      // Create addresses if provided
      if (profile.addresses.isNotEmpty) {
        final addressesData = profile.addresses.map((address) {
          final data = address.toJson();

          // Remove null id field to allow database auto-generation
          if (data['id'] == null) {
            data.remove('id');
          }

          data['customer_profile_id'] = profileId;
          data['created_at'] = DateTime.now().toIso8601String();
          data['updated_at'] = DateTime.now().toIso8601String();
          return data;
        }).toList();

        await _supabase
            .from('customer_addresses')
            .insert(addressesData);
      }

      // Update preferences if provided (preferences are created automatically by trigger)
      if (profile.preferences != null) {
        final preferencesData = profile.preferences!.toJson();
        preferencesData['customer_profile_id'] = profileId;
        preferencesData['updated_at'] = DateTime.now().toIso8601String();

        await _supabase
            .from('customer_preferences')
            .update(preferencesData)
            .eq('customer_profile_id', profileId);
      }

      _logger.info('Customer profile created successfully');

      // Return the complete profile with related data
      return await getCurrentProfile() ?? CustomerProfile.fromJson(profileResponse);
    } catch (e) {
      _logger.error('Error creating customer profile', e);
      rethrow;
    }
  }

  /// Update customer profile
  Future<CustomerProfile> updateProfile(CustomerProfile profile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      _logger.info('Updating customer profile for user: ${user.id}');

      // Update only profile fields (not addresses or preferences)
      final profileData = {
        'full_name': profile.fullName,
        'phone_number': profile.phoneNumber,
        'profile_image_url': profile.profileImageUrl,
        'total_orders': profile.totalOrders,
        'total_spent': profile.totalSpent,
        'loyalty_points': profile.loyaltyPoints,
        'is_verified': profile.isVerified,
        'is_active': profile.isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('customer_profiles')
          .update(profileData)
          .eq('user_id', user.id);

      _logger.info('Customer profile updated successfully');

      // Return updated profile with related data
      return await getCurrentProfile() ?? profile;
    } catch (e) {
      _logger.error('Error updating customer profile', e);
      rethrow;
    }
  }

  /// Add a new address to customer's saved addresses
  Future<CustomerProfile> addAddress(CustomerAddress address) async {
    try {
      final profile = await getCurrentProfile();
      if (profile == null) {
        throw Exception('Customer profile not found');
      }

      _logger.info('Adding address for customer profile: ${profile.id}');

      // Add address to the saved_addresses JSON array
      final updatedAddresses = List<CustomerAddress>.from(profile.addresses);

      // Generate a unique ID for the new address
      final newAddress = address.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      updatedAddresses.add(newAddress);

      // Update the customer profile with new addresses
      await _supabase
          .from('customer_profiles')
          .update({
            'saved_addresses': updatedAddresses.map((addr) => addr.toJson()).toList(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', profile.id);

      _logger.info('Address added successfully');

      // Return updated profile
      return await getCurrentProfile() ?? profile;
    } catch (e) {
      _logger.error('Error adding address', e);
      rethrow;
    }
  }

  /// Update an existing address
  Future<CustomerProfile> updateAddress(CustomerAddress address) async {
    try {
      final profile = await getCurrentProfile();
      if (profile == null) {
        throw Exception('Customer profile not found');
      }

      if (address.id == null) {
        throw Exception('Address ID is required for update');
      }

      _logger.info('Updating address: ${address.id}');

      // Update address in the saved_addresses JSON array
      final updatedAddresses = profile.addresses.map((addr) {
        return addr.id == address.id ? address : addr;
      }).toList();

      // Update the customer profile with updated addresses
      await _supabase
          .from('customer_profiles')
          .update({
            'saved_addresses': updatedAddresses.map((addr) => addr.toJson()).toList(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', profile.id);

      _logger.info('Address updated successfully');

      // Return updated profile
      return await getCurrentProfile() ?? profile;
    } catch (e) {
      _logger.error('Error updating address', e);
      rethrow;
    }
  }

  /// Remove an address from customer's saved addresses
  Future<CustomerProfile> removeAddress(String addressId) async {
    try {
      final profile = await getCurrentProfile();
      if (profile == null) {
        throw Exception('Customer profile not found');
      }

      _logger.info('Removing address: $addressId');

      // Remove address from the saved_addresses JSON array
      final updatedAddresses = profile.addresses
          .where((addr) => addr.id != addressId)
          .toList();

      // Update the customer profile with updated addresses
      await _supabase
          .from('customer_profiles')
          .update({
            'saved_addresses': updatedAddresses.map((addr) => addr.toJson()).toList(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', profile.id);

      _logger.info('Address removed successfully');

      // Return updated profile
      return await getCurrentProfile() ?? profile;
    } catch (e) {
      _logger.error('Error removing address', e);
      rethrow;
    }
  }

  /// Update customer preferences
  Future<CustomerProfile> updatePreferences(CustomerPreferences preferences) async {
    try {
      final profile = await getCurrentProfile();
      if (profile == null) {
        throw Exception('Customer profile not found');
      }

      _logger.info('Updating preferences for customer profile: ${profile.id}');

      // Update preferences in the customer_profiles table JSON columns
      await _supabase
          .from('customer_profiles')
          .update({
            'notification_preferences': preferences.notificationPreferences.toJson(),
            'dietary_preferences': preferences.dietaryRestrictions,
            'preferred_cuisines': preferences.preferredCuisines,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', profile.id);

      _logger.info('Preferences updated successfully');

      // Return updated profile
      return await getCurrentProfile() ?? profile;
    } catch (e) {
      _logger.error('Error updating preferences', e);
      rethrow;
    }
  }

  /// Upload profile image
  Future<String> uploadProfileImage(String filePath, Uint8List fileBytes) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'customer_profiles/$fileName';

      _logger.info('Uploading profile image: $storagePath');

      await _supabase.storage
          .from('customer_assets')
          .uploadBinary(storagePath, fileBytes);

      final imageUrl = _supabase.storage
          .from('customer_assets')
          .getPublicUrl(storagePath);

      _logger.info('Profile image uploaded successfully');
      return imageUrl;
    } catch (e) {
      _logger.error('Error uploading profile image', e);
      rethrow;
    }
  }

  /// Delete customer profile
  Future<void> deleteProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      _logger.info('Deleting customer profile for user: ${user.id}');

      await _supabase
          .from('customer_profiles')
          .delete()
          .eq('user_id', user.id);

      _logger.info('Customer profile deleted successfully');
    } catch (e) {
      _logger.error('Error deleting customer profile', e);
      rethrow;
    }
  }

  /// Check if customer profile exists
  Future<bool> profileExists() async {
    try {
      final profile = await getCurrentProfile();
      return profile != null;
    } catch (e) {
      _logger.error('Error checking profile existence', e);
      return false;
    }
  }




}
