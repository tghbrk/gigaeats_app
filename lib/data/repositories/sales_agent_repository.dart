import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/sales_agent_profile.dart';
import '../models/user.dart' as app_models;
import 'base_repository.dart';

class SalesAgentRepository extends BaseRepository {
  SalesAgentRepository({
    super.client,
  });

  /// Get sales agent profile by Supabase UID
  Future<SalesAgentProfile?> getSalesAgentProfile(String supabaseUid) async {
    return executeQuery(() async {
      debugPrint('SalesAgentRepository: Getting profile for UID: $supabaseUid');

      final authenticatedClient = await getAuthenticatedClient();

      // Get user data first
      final userResponse = await authenticatedClient
          .from('users')
          .select('*')
          .eq('supabase_user_id', supabaseUid)
          .eq('role', 'sales_agent')
          .maybeSingle();

      if (userResponse == null) {
        debugPrint('SalesAgentRepository: No sales agent found for UID: $supabaseUid');
        return null;
      }

      // Clean up any duplicate profile records first
      await _cleanupDuplicateProfiles(authenticatedClient, userResponse['id']);

      // Get profile data - should be clean now
      final profileResponse = await authenticatedClient
          .from('user_profiles')
          .select('*')
          .eq('user_id', userResponse['id'])
          .maybeSingle();

      debugPrint('SalesAgentRepository: Found sales agent data: ${userResponse.keys}');

      // Use the profile data from the separate query
      final profileData = profileResponse;

      // Create User object from response
      final user = app_models.User.fromJson(userResponse);

      // Create SalesAgentProfile from user and profile data
      return SalesAgentProfile.fromUserAndProfile(
        user: user,
        profileData: profileData,
      );
    });
  }

  /// Get current sales agent profile
  Future<SalesAgentProfile?> getCurrentSalesAgentProfile() async {
    final supabaseUid = currentUserUid;
    if (supabaseUid == null) {
      debugPrint('SalesAgentRepository: No current user UID');
      return null;
    }

    return getSalesAgentProfile(supabaseUid);
  }

  /// Update sales agent profile
  Future<SalesAgentProfile> updateSalesAgentProfile(SalesAgentProfile profile) async {
    return executeQuery(() async {
      debugPrint('SalesAgentRepository: Updating profile for: ${profile.id}');

      final authenticatedClient = await getAuthenticatedClient();

      // FIRST: Clean up any duplicate profile records before doing anything else
      await _cleanupDuplicateProfiles(authenticatedClient, profile.id);

      // Update main user record
      await authenticatedClient
          .from('users')
          .update({
            'full_name': profile.fullName,
            'phone_number': profile.phoneNumber,
            'profile_image_url': profile.profileImageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('supabase_user_id', profile.id);

      // Update profile record
      final profileData = {
        'company_name': profile.companyName,
        'business_registration_number': profile.businessRegistrationNumber,
        'business_address': profile.businessAddress,
        'business_type': profile.businessType,
        'commission_rate': profile.commissionRate,
        'assigned_regions': profile.assignedRegions,
        'preferences': profile.preferences ?? {},
        'kyc_documents': profile.kycDocuments ?? {},
        'verification_status': profile.verificationStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Update the profile record (should be only one now)
      await authenticatedClient
          .from('user_profiles')
          .update(profileData)
          .eq('user_id', profile.id);

      // Get updated profile - should be clean now
      final updatedProfile = await getSalesAgentProfile(profile.id);
      if (updatedProfile == null) {
        throw Exception('Failed to retrieve updated profile');
      }

      debugPrint('SalesAgentRepository: Profile updated successfully');
      return updatedProfile;
    });
  }

  /// Helper method to clean up duplicate profile records
  Future<void> _cleanupDuplicateProfiles(SupabaseClient client, String userId) async {
    try {
      // Get all profile records for this user
      final existingProfiles = await client
          .from('user_profiles')
          .select('id, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      debugPrint('SalesAgentRepository: Found ${existingProfiles.length} profile records for user $userId');

      // If there are multiple records, delete the older ones and keep the most recent
      if (existingProfiles.length > 1) {
        debugPrint('SalesAgentRepository: Cleaning up ${existingProfiles.length - 1} duplicate profile records');

        // Keep the most recent record (first in the ordered list)
        final recordsToDelete = existingProfiles.skip(1).toList();

        for (final record in recordsToDelete) {
          await client
              .from('user_profiles')
              .delete()
              .eq('id', record['id']);
          debugPrint('SalesAgentRepository: Deleted duplicate profile record: ${record['id']}');
        }

        debugPrint('SalesAgentRepository: Cleanup completed. Remaining records: 1');
      }
    } catch (e) {
      debugPrint('SalesAgentRepository: Error during cleanup: $e');
      // Don't rethrow - continue with the update process
    }
  }

  /// Create sales agent profile
  Future<SalesAgentProfile> createSalesAgentProfile({
    required String supabaseUid,
    required String email,
    required String fullName,
    String? phoneNumber,
    String? companyName,
    String? businessRegistrationNumber,
    String? businessAddress,
    String? businessType,
    double commissionRate = 0.07,
    List<String> assignedRegions = const [],
    Map<String, dynamic>? preferences,
  }) async {
    return executeQuery(() async {
      debugPrint('SalesAgentRepository: Creating profile for: $supabaseUid');

      final authenticatedClient = await getAuthenticatedClient();

      // Create user record if it doesn't exist
      await authenticatedClient
          .from('users')
          .upsert({
            'supabase_user_id': supabaseUid,
            'id': supabaseUid,
            'email': email,
            'full_name': fullName,
            'phone_number': phoneNumber,
            'role': 'sales_agent',
            'is_verified': false,
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

      // Create profile record
      await authenticatedClient
          .from('user_profiles')
          .upsert({
            'user_id': supabaseUid,
            'company_name': companyName,
            'business_registration_number': businessRegistrationNumber,
            'business_address': businessAddress,
            'business_type': businessType,
            'commission_rate': commissionRate,
            'total_earnings': 0.0,
            'total_orders': 0,
            'assigned_regions': assignedRegions,
            'preferences': preferences ?? {},
            'kyc_documents': {},
            'verification_status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

      // Get created profile
      final createdProfile = await getSalesAgentProfile(supabaseUid);
      if (createdProfile == null) {
        throw Exception('Failed to create sales agent profile');
      }

      debugPrint('SalesAgentRepository: Profile created successfully');
      return createdProfile;
    });
  }

  /// Update sales agent performance metrics
  Future<void> updatePerformanceMetrics({
    required String supabaseUid,
    required double totalEarnings,
    required int totalOrders,
  }) async {
    return executeQuery(() async {
      debugPrint('SalesAgentRepository: Updating performance metrics for: $supabaseUid');

      final authenticatedClient = await getAuthenticatedClient();

      await authenticatedClient
          .from('user_profiles')
          .update({
            'total_earnings': totalEarnings,
            'total_orders': totalOrders,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', supabaseUid);

      debugPrint('SalesAgentRepository: Performance metrics updated successfully');
    });
  }

  /// Update KYC documents
  Future<void> updateKycDocuments({
    required String supabaseUid,
    required Map<String, dynamic> kycDocuments,
  }) async {
    return executeQuery(() async {
      debugPrint('SalesAgentRepository: Updating KYC documents for: $supabaseUid');

      final authenticatedClient = await getAuthenticatedClient();

      await authenticatedClient
          .from('user_profiles')
          .update({
            'kyc_documents': kycDocuments,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', supabaseUid);

      debugPrint('SalesAgentRepository: KYC documents updated successfully');
    });
  }

  /// Update verification status
  Future<void> updateVerificationStatus({
    required String supabaseUid,
    required String status,
  }) async {
    return executeQuery(() async {
      debugPrint('SalesAgentRepository: Updating verification status for: $supabaseUid to: $status');

      final authenticatedClient = await getAuthenticatedClient();

      await authenticatedClient
          .from('user_profiles')
          .update({
            'verification_status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', supabaseUid);

      debugPrint('SalesAgentRepository: Verification status updated successfully');
    });
  }

  /// Get sales agent statistics
  Future<Map<String, dynamic>> getSalesAgentStatistics(String supabaseUid) async {
    return executeQuery(() async {
      debugPrint('SalesAgentRepository: Getting statistics for: $supabaseUid');

      final authenticatedClient = await getAuthenticatedClient();

      // Get user ID first
      final userResponse = await authenticatedClient
          .from('users')
          .select('id')
          .eq('supabase_user_id', supabaseUid)
          .single();

      final userId = userResponse['id'];

      // Get customer count
      final customerCount = await authenticatedClient
          .from('customers')
          .select('id')
          .eq('sales_agent_id', userId)
          .count(CountOption.exact);

      // Get order statistics
      final orderStats = await authenticatedClient
          .from('orders')
          .select('status, total_amount')
          .eq('sales_agent_id', userId);

      // Calculate statistics
      final totalOrders = orderStats.length;
      final completedOrders = orderStats.where((order) => order['status'] == 'delivered').length;
      final totalRevenue = orderStats.fold<double>(
        0.0,
        (sum, order) => sum + (order['total_amount'] as num).toDouble(),
      );

      return {
        'total_customers': customerCount.count,
        'total_orders': totalOrders,
        'completed_orders': completedOrders,
        'total_revenue': totalRevenue,
        'success_rate': totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0.0,
      };
    });
  }

  /// Check if sales agent profile exists
  Future<bool> profileExists(String supabaseUid) async {
    return executeQuery(() async {
      final profile = await getSalesAgentProfile(supabaseUid);
      return profile != null;
    });
  }
}
