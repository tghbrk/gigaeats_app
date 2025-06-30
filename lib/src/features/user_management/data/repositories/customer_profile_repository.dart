import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../user_management/domain/customer_profile.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/profile_validators.dart';

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
        'total_orders': profile.totalOrders,
        'total_spent': profile.totalSpent,
        'loyalty_points': profile.loyaltyPoints,
        'is_verified': profile.isVerified,
        'is_active': profile.isActive,
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

      // Validate address data
      _validateAddress(address);

      // Add address to the saved_addresses JSON array
      final updatedAddresses = List<CustomerAddress>.from(profile.addresses);

      // If this is set as default, unset other default addresses
      if (address.isDefault) {
        for (int i = 0; i < updatedAddresses.length; i++) {
          updatedAddresses[i] = updatedAddresses[i].copyWith(isDefault: false);
        }
      }

      // If this is the first address, make it default
      final isFirstAddress = updatedAddresses.isEmpty;

      // Generate a unique ID for the new address
      final newAddress = address.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isDefault: address.isDefault || isFirstAddress,
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

      if (address.id == null || address.id!.trim().isEmpty) {
        throw ArgumentError('Address ID is required for update');
      }

      _logger.info('Updating address: ${address.id}');

      // Validate address data
      _validateAddress(address);

      // Check if address exists
      final addressIndex = profile.addresses.indexWhere((addr) => addr.id == address.id);
      if (addressIndex == -1) {
        throw ArgumentError('Address not found');
      }

      // If this address is being set as default, unset other defaults
      List<CustomerAddress> updatedAddresses = List<CustomerAddress>.from(profile.addresses);

      if (address.isDefault) {
        for (int i = 0; i < updatedAddresses.length; i++) {
          if (i != addressIndex) {
            updatedAddresses[i] = updatedAddresses[i].copyWith(isDefault: false);
          }
        }
      }

      // Update the specific address
      updatedAddresses[addressIndex] = address;

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

      if (addressId.trim().isEmpty) {
        throw ArgumentError('Address ID is required');
      }

      _logger.info('Removing address: $addressId');

      // Find the address to remove
      final addressToRemove = profile.addresses.where((addr) => addr.id == addressId).firstOrNull;
      if (addressToRemove == null) {
        throw ArgumentError('Address not found');
      }

      // Check if this is the default address and there are other addresses
      if (addressToRemove.isDefault && profile.addresses.length > 1) {
        throw ArgumentError('Cannot delete default address. Please set another address as default first.');
      }

      // Remove address from the saved_addresses JSON array
      final updatedAddresses = profile.addresses
          .where((addr) => addr.id != addressId)
          .toList();

      // If we removed the only address, the list will be empty
      // If we removed a non-default address and there are still addresses,
      // make sure we have a default address
      if (updatedAddresses.isNotEmpty && !updatedAddresses.any((addr) => addr.isDefault)) {
        // Set the first address as default
        updatedAddresses[0] = updatedAddresses[0].copyWith(isDefault: true);
      }

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

  /// Validate address data before saving
  void _validateAddress(CustomerAddress address) {
    // Use ProfileValidators for comprehensive validation
    String? error;

    // Validate label
    if (address.label.trim().isEmpty) {
      throw ArgumentError('Address label is required');
    }

    // Validate address line 1
    error = ProfileValidators.validateAddress(address.addressLine1);
    if (error != null) {
      throw ArgumentError('Address line 1: $error');
    }

    // Validate city
    error = ProfileValidators.validateCity(address.city);
    if (error != null) {
      throw ArgumentError('City: $error');
    }

    // Validate state
    error = ProfileValidators.validateState(address.state);
    if (error != null) {
      throw ArgumentError('State: $error');
    }

    // Validate postal code
    error = ProfileValidators.validateMalaysianPostcode(address.postalCode);
    if (error != null) {
      throw ArgumentError('Postal code: $error');
    }

    // Validate optional address line 2
    if (address.addressLine2 != null && address.addressLine2!.isNotEmpty) {
      error = ProfileValidators.validateAddress(address.addressLine2!, required: false);
      if (error != null) {
        throw ArgumentError('Address line 2: $error');
      }
    }

    // Validate delivery instructions length
    if (address.deliveryInstructions != null && address.deliveryInstructions!.length > 500) {
      throw ArgumentError('Delivery instructions must be less than 500 characters');
    }

    // Validate label length
    if (address.label.length > 50) {
      throw ArgumentError('Address label must be less than 50 characters');
    }
  }

  /// Set an address as default (unsets all other defaults)
  Future<CustomerProfile> setDefaultAddress(String addressId) async {
    try {
      final profile = await getCurrentProfile();
      if (profile == null) {
        throw Exception('Customer profile not found');
      }

      _logger.info('Setting default address: $addressId for profile: ${profile.id}');

      // Find the address to set as default
      final addressIndex = profile.addresses.indexWhere((addr) => addr.id == addressId);
      if (addressIndex == -1) {
        throw ArgumentError('Address not found');
      }

      // Update addresses: set target as default, others as non-default
      final updatedAddresses = profile.addresses.asMap().entries.map((entry) {
        final index = entry.key;
        final address = entry.value;
        return address.copyWith(isDefault: index == addressIndex);
      }).toList();

      // Update the customer profile with updated addresses
      await _supabase
          .from('customer_profiles')
          .update({
            'saved_addresses': updatedAddresses.map((addr) => addr.toJson()).toList(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', profile.id);

      _logger.info('Default address set successfully');

      // Return updated profile
      return await getCurrentProfile() ?? profile;
    } catch (e) {
      _logger.error('Error setting default address', e);
      rethrow;
    }
  }

  /// Get addresses count for the current profile
  Future<int> getAddressCount() async {
    try {
      final profile = await getCurrentProfile();
      return profile?.addresses.length ?? 0;
    } catch (e) {
      _logger.error('Error getting address count', e);
      return 0;
    }
  }

  /// Check if profile has any addresses
  Future<bool> hasAddresses() async {
    try {
      final count = await getAddressCount();
      return count > 0;
    } catch (e) {
      _logger.error('Error checking if profile has addresses', e);
      return false;
    }
  }

  /// Get default address for the current profile
  Future<CustomerAddress?> getDefaultAddress() async {
    try {
      final profile = await getCurrentProfile();
      if (profile == null) return null;

      return profile.addresses.where((addr) => addr.isDefault).firstOrNull;
    } catch (e) {
      _logger.error('Error getting default address', e);
      return null;
    }
  }

  /// Find address by ID
  Future<CustomerAddress?> findAddressById(String addressId) async {
    try {
      final profile = await getCurrentProfile();
      if (profile == null) return null;

      return profile.addresses.where((addr) => addr.id == addressId).firstOrNull;
    } catch (e) {
      _logger.error('Error finding address by ID', e);
      return null;
    }
  }

  /// Find addresses by label (case-insensitive)
  Future<List<CustomerAddress>> findAddressesByLabel(String label) async {
    try {
      final profile = await getCurrentProfile();
      if (profile == null) return [];

      return profile.addresses
          .where((addr) => addr.label.toLowerCase().contains(label.toLowerCase()))
          .toList();
    } catch (e) {
      _logger.error('Error finding addresses by label', e);
      return [];
    }
  }

  /// Validate if an address can be deleted
  Future<bool> canDeleteAddress(String addressId) async {
    try {
      final profile = await getCurrentProfile();
      if (profile == null) return false;

      final address = profile.addresses.where((addr) => addr.id == addressId).firstOrNull;
      if (address == null) return false;

      // Can delete if it's not the default address, or if it's the only address
      return !address.isDefault || profile.addresses.length == 1;
    } catch (e) {
      _logger.error('Error checking if address can be deleted', e);
      return false;
    }
  }

  /// Bulk update multiple addresses
  Future<CustomerProfile> bulkUpdateAddresses(List<CustomerAddress> addresses) async {
    try {
      final profile = await getCurrentProfile();
      if (profile == null) {
        throw Exception('Customer profile not found');
      }

      _logger.info('Bulk updating ${addresses.length} addresses for profile: ${profile.id}');

      // Validate all addresses
      for (final address in addresses) {
        _validateAddress(address);
        if (address.id == null || address.id!.trim().isEmpty) {
          throw ArgumentError('All addresses must have valid IDs for bulk update');
        }
      }

      // Create a map for quick lookup
      final addressMap = {for (var addr in addresses) addr.id!: addr};

      // Update addresses in the profile
      final updatedAddresses = profile.addresses.map((existingAddr) {
        return addressMap.containsKey(existingAddr.id)
            ? addressMap[existingAddr.id]!
            : existingAddr;
      }).toList();

      // Ensure only one default address
      final defaultAddresses = updatedAddresses.where((addr) => addr.isDefault).toList();
      if (defaultAddresses.length > 1) {
        // Keep only the first default, unset others
        for (int i = 0; i < updatedAddresses.length; i++) {
          if (updatedAddresses[i].isDefault && updatedAddresses[i].id != defaultAddresses.first.id) {
            updatedAddresses[i] = updatedAddresses[i].copyWith(isDefault: false);
          }
        }
      }

      // Update the customer profile with updated addresses
      await _supabase
          .from('customer_profiles')
          .update({
            'saved_addresses': updatedAddresses.map((addr) => addr.toJson()).toList(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', profile.id);

      _logger.info('Bulk address update completed successfully');

      // Return updated profile
      return await getCurrentProfile() ?? profile;
    } catch (e) {
      _logger.error('Error in bulk address update', e);
      rethrow;
    }
  }

  /// Get address statistics for the current profile
  Future<Map<String, dynamic>> getAddressStatistics() async {
    try {
      final profile = await getCurrentProfile();
      if (profile == null) {
        return {
          'total': 0,
          'hasDefault': false,
          'defaultAddress': null,
        };
      }

      final addresses = profile.addresses;
      final defaultAddress = addresses.where((addr) => addr.isDefault).firstOrNull;

      return {
        'total': addresses.length,
        'hasDefault': defaultAddress != null,
        'defaultAddress': defaultAddress?.toJson(),
        'addressTypes': addresses.map((addr) => addr.label).toSet().toList(),
      };
    } catch (e) {
      _logger.error('Error getting address statistics', e);
      return {
        'total': 0,
        'hasDefault': false,
        'defaultAddress': null,
        'error': e.toString(),
      };
    }
  }
}
