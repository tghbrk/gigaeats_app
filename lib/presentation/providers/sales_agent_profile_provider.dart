import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/sales_agent_profile.dart';
import '../../data/repositories/sales_agent_repository.dart';
import 'repository_providers.dart';
import 'auth_provider.dart';

// Current Sales Agent Profile Provider
final currentSalesAgentProfileProvider = FutureProvider<SalesAgentProfile?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    debugPrint('SalesAgentProfileProvider: No authenticated user');
    return null;
  }

  final salesAgentRepository = ref.watch(salesAgentRepositoryProvider);
  return await salesAgentRepository.getCurrentSalesAgentProfile();
});

// Sales Agent Profile by ID Provider
final salesAgentProfileProvider = FutureProvider.family<SalesAgentProfile?, String>((ref, userId) async {
  final salesAgentRepository = ref.watch(salesAgentRepositoryProvider);
  return await salesAgentRepository.getSalesAgentProfile(userId);
});

// Sales Agent Statistics Provider
final salesAgentStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    return {
      'total_customers': 0,
      'total_orders': 0,
      'completed_orders': 0,
      'total_revenue': 0.0,
      'success_rate': 0.0,
    };
  }

  final salesAgentRepository = ref.watch(salesAgentRepositoryProvider);
  return await salesAgentRepository.getSalesAgentStatistics(userId);
});

// Sales Agent Statistics by ID Provider
final salesAgentStatisticsByIdProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final salesAgentRepository = ref.watch(salesAgentRepositoryProvider);
  return await salesAgentRepository.getSalesAgentStatistics(userId);
});

// Sales Agent Profile State Management
class SalesAgentProfileState {
  final SalesAgentProfile? profile;
  final Map<String, dynamic>? statistics;
  final bool isLoading;
  final String? errorMessage;
  final bool isUpdating;

  const SalesAgentProfileState({
    this.profile,
    this.statistics,
    this.isLoading = false,
    this.errorMessage,
    this.isUpdating = false,
  });

  SalesAgentProfileState copyWith({
    SalesAgentProfile? profile,
    Map<String, dynamic>? statistics,
    bool? isLoading,
    String? errorMessage,
    bool? isUpdating,
  }) {
    return SalesAgentProfileState(
      profile: profile ?? this.profile,
      statistics: statistics ?? this.statistics,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  bool get hasProfile => profile != null;
  bool get hasError => errorMessage != null;
  bool get isProfileComplete => profile?.isProfileComplete ?? false;
  bool get isKycVerified => profile?.isKycVerified ?? false;
}

// Sales Agent Profile Notifier
class SalesAgentProfileNotifier extends StateNotifier<SalesAgentProfileState> {
  final SalesAgentRepository _repository;
  final Ref _ref;

  SalesAgentProfileNotifier(this._repository, this._ref) : super(const SalesAgentProfileState());

  // Load current user's profile
  Future<void> loadCurrentProfile() async {
    final authState = _ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      state = state.copyWith(
        errorMessage: 'User not authenticated',
        isLoading: false,
      );
      return;
    }

    await loadProfile(userId);
  }

  // Load profile by user ID
  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      debugPrint('SalesAgentProfileNotifier: Loading profile for user: $userId');

      // Load profile and statistics concurrently
      final profileFuture = _repository.getSalesAgentProfile(userId);
      final statisticsFuture = _repository.getSalesAgentStatistics(userId);

      final results = await Future.wait([profileFuture, statisticsFuture]);
      final profile = results[0] as SalesAgentProfile?;
      final statistics = results[1] as Map<String, dynamic>;

      if (profile != null) {
        state = state.copyWith(
          profile: profile,
          statistics: statistics,
          isLoading: false,
        );
        debugPrint('SalesAgentProfileNotifier: Profile loaded successfully');
      } else {
        state = state.copyWith(
          errorMessage: 'Sales agent profile not found',
          isLoading: false,
        );
        debugPrint('SalesAgentProfileNotifier: Profile not found');
      }
    } catch (e) {
      debugPrint('SalesAgentProfileNotifier: Error loading profile: $e');
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  // Update profile
  Future<bool> updateProfile(SalesAgentProfile updatedProfile) async {
    state = state.copyWith(isUpdating: true, errorMessage: null);

    try {
      debugPrint('SalesAgentProfileNotifier: Updating profile');

      final updated = await _repository.updateSalesAgentProfile(updatedProfile);
      
      // Reload statistics after profile update
      final statistics = await _repository.getSalesAgentStatistics(updated.id);

      state = state.copyWith(
        profile: updated,
        statistics: statistics,
        isUpdating: false,
      );

      debugPrint('SalesAgentProfileNotifier: Profile updated successfully');
      return true;
    } catch (e) {
      debugPrint('SalesAgentProfileNotifier: Error updating profile: $e');
      state = state.copyWith(
        errorMessage: e.toString(),
        isUpdating: false,
      );
      return false;
    }
  }

  // Update performance metrics
  Future<bool> updatePerformanceMetrics({
    required double totalEarnings,
    required int totalOrders,
  }) async {
    final profile = state.profile;
    if (profile == null) return false;

    try {
      debugPrint('SalesAgentProfileNotifier: Updating performance metrics');

      await _repository.updatePerformanceMetrics(
        supabaseUid: profile.id,
        totalEarnings: totalEarnings,
        totalOrders: totalOrders,
      );

      // Reload profile to get updated metrics
      await loadProfile(profile.id);
      return true;
    } catch (e) {
      debugPrint('SalesAgentProfileNotifier: Error updating performance metrics: $e');
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // Update KYC documents
  Future<bool> updateKycDocuments(Map<String, dynamic> kycDocuments) async {
    final profile = state.profile;
    if (profile == null) return false;

    try {
      debugPrint('SalesAgentProfileNotifier: Updating KYC documents');

      await _repository.updateKycDocuments(
        supabaseUid: profile.id,
        kycDocuments: kycDocuments,
      );

      // Update local state
      final updatedProfile = profile.copyWith(kycDocuments: kycDocuments);
      state = state.copyWith(profile: updatedProfile);
      return true;
    } catch (e) {
      debugPrint('SalesAgentProfileNotifier: Error updating KYC documents: $e');
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // Update verification status
  Future<bool> updateVerificationStatus(String status) async {
    final profile = state.profile;
    if (profile == null) return false;

    try {
      debugPrint('SalesAgentProfileNotifier: Updating verification status to: $status');

      await _repository.updateVerificationStatus(
        supabaseUid: profile.id,
        status: status,
      );

      // Update local state
      final updatedProfile = profile.copyWith(verificationStatus: status);
      state = state.copyWith(profile: updatedProfile);
      return true;
    } catch (e) {
      debugPrint('SalesAgentProfileNotifier: Error updating verification status: $e');
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // Refresh profile and statistics
  Future<void> refresh() async {
    final profile = state.profile;
    if (profile != null) {
      await loadProfile(profile.id);
    } else {
      await loadCurrentProfile();
    }
  }

  // Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  // Check if profile exists
  Future<bool> checkProfileExists(String userId) async {
    try {
      return await _repository.profileExists(userId);
    } catch (e) {
      debugPrint('SalesAgentProfileNotifier: Error checking profile existence: $e');
      return false;
    }
  }
}

// Sales Agent Profile State Provider
final salesAgentProfileStateProvider = StateNotifierProvider<SalesAgentProfileNotifier, SalesAgentProfileState>((ref) {
  final repository = ref.watch(salesAgentRepositoryProvider);
  return SalesAgentProfileNotifier(repository, ref);
});

// Convenience provider for quick profile access
final quickSalesAgentProfileProvider = Provider<SalesAgentProfile?>((ref) {
  final profileState = ref.watch(salesAgentProfileStateProvider);
  return profileState.profile;
});

// Convenience provider for quick statistics access
final quickSalesAgentStatisticsProvider = Provider<Map<String, dynamic>?>((ref) {
  final profileState = ref.watch(salesAgentProfileStateProvider);
  return profileState.statistics;
});

// Profile completion status provider
final profileCompletionStatusProvider = Provider<double>((ref) {
  final profile = ref.watch(quickSalesAgentProfileProvider);
  if (profile == null) return 0.0;

  int completedFields = 0;
  const int totalFields = 6; // fullName, email, phone, company, registration, address

  if (profile.fullName.isNotEmpty) completedFields++;
  if (profile.email.isNotEmpty) completedFields++;
  if (profile.phoneNumber?.isNotEmpty ?? false) completedFields++;
  if (profile.companyName?.isNotEmpty ?? false) completedFields++;
  if (profile.businessRegistrationNumber?.isNotEmpty ?? false) completedFields++;
  if (profile.businessAddress?.isNotEmpty ?? false) completedFields++;

  return completedFields / totalFields;
});

// Auto-load profile when auth state changes
final autoLoadProfileProvider = Provider<void>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileNotifier = ref.read(salesAgentProfileStateProvider.notifier);

  // Auto-load profile when user becomes authenticated
  if (authState.status == AuthStatus.authenticated && authState.user != null) {
    Future.microtask(() => profileNotifier.loadCurrentProfile());
  }
});
