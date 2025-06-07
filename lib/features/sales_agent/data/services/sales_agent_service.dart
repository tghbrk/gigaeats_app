import '../repositories/sales_agent_repository.dart';
import '../models/sales_agent_profile.dart';

class SalesAgentService {
  final SalesAgentRepository _salesAgentRepository;

  SalesAgentService({SalesAgentRepository? salesAgentRepository})
      : _salesAgentRepository = salesAgentRepository ?? SalesAgentRepository();

  Future<SalesAgentProfile?> getSalesAgentProfile(String salesAgentId) async {
    return await _salesAgentRepository.getSalesAgentProfile(salesAgentId);
  }

  Future<SalesAgentProfile?> getCurrentSalesAgentProfile() async {
    return await _salesAgentRepository.getCurrentSalesAgentProfile();
  }

  Future<SalesAgentProfile> updateSalesAgentProfile(SalesAgentProfile profile) async {
    return await _salesAgentRepository.updateSalesAgentProfile(profile);
  }

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
    return await _salesAgentRepository.createSalesAgentProfile(
      supabaseUid: supabaseUid,
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber,
      companyName: companyName,
      businessRegistrationNumber: businessRegistrationNumber,
      businessAddress: businessAddress,
      businessType: businessType,
      commissionRate: commissionRate,
      assignedRegions: assignedRegions,
      preferences: preferences,
    );
  }

  Future<Map<String, dynamic>> getSalesAgentStatistics(String salesAgentId) async {
    return await _salesAgentRepository.getSalesAgentStatistics(salesAgentId);
  }

  Future<void> updatePerformanceMetrics({
    required String supabaseUid,
    required double totalEarnings,
    required int totalOrders,
  }) async {
    return await _salesAgentRepository.updatePerformanceMetrics(
      supabaseUid: supabaseUid,
      totalEarnings: totalEarnings,
      totalOrders: totalOrders,
    );
  }

  Future<bool> profileExists(String userId) async {
    return await _salesAgentRepository.profileExists(userId);
  }

  /// Get sales agent settings (including notification preferences)
  Future<Map<String, dynamic>?> getSalesAgentSettings(String salesAgentId) async {
    try {
      final profile = await _salesAgentRepository.getSalesAgentProfile(salesAgentId);
      if (profile == null) {
        return null;
      }

      // Return the preferences from the profile
      // The preferences field in the profile contains various settings including notifications
      return profile.preferences;
    } catch (e) {
      throw Exception('Failed to get sales agent settings: $e');
    }
  }

  /// Update sales agent settings (including notification preferences)
  Future<void> updateSalesAgentSettings(String salesAgentId, Map<String, dynamic> settings) async {
    try {
      final profile = await _salesAgentRepository.getSalesAgentProfile(salesAgentId);
      if (profile == null) {
        throw Exception('Sales agent profile not found');
      }

      // Merge the new settings with existing preferences
      final updatedPreferences = Map<String, dynamic>.from(profile.preferences ?? {});
      updatedPreferences.addAll(settings);

      // Update the profile with new preferences
      final updatedProfile = profile.copyWith(preferences: updatedPreferences);
      await _salesAgentRepository.updateSalesAgentProfile(updatedProfile);
    } catch (e) {
      throw Exception('Failed to update sales agent settings: $e');
    }
  }
}
