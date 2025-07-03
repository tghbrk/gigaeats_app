import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../user_management/domain/customer_profile.dart';
import '../../data/repositories/customer_profile_repository.dart';
import '../../../../core/utils/logger.dart';

// Repository provider
final customerProfileRepositoryProvider = Provider<CustomerProfileRepository>((ref) {
  return CustomerProfileRepository();
});

// Customer profile state
class CustomerProfileState {
  final CustomerProfile? profile;
  final bool isLoading;
  final String? error;

  const CustomerProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  CustomerProfileState copyWith({
    CustomerProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return CustomerProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Customer profile notifier
class CustomerProfileNotifier extends StateNotifier<CustomerProfileState> {
  final CustomerProfileRepository _repository;
  final AppLogger _logger = AppLogger();

  CustomerProfileNotifier(this._repository) : super(const CustomerProfileState());

  /// Load current customer profile
  Future<void> loadProfile() async {
    try {
      _logger.info('CustomerProfileNotifier: Starting to load profile...');
      state = state.copyWith(isLoading: true, error: null);

      final profile = await _repository.getCurrentProfile();
      _logger.info('CustomerProfileNotifier: Profile loaded: ${profile?.id ?? 'null'}');

      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      _logger.error('Error loading customer profile', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create new customer profile
  Future<bool> createProfile(CustomerProfile profile) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final createdProfile = await _repository.createProfile(profile);
      
      state = state.copyWith(
        profile: createdProfile,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      _logger.error('Error creating customer profile', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Update customer profile
  Future<bool> updateProfile(CustomerProfile profile) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final updatedProfile = await _repository.updateProfile(profile);
      
      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      _logger.error('Error updating customer profile', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Add new address
  Future<bool> addAddress(CustomerAddress address) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final updatedProfile = await _repository.addAddress(address);
      
      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      _logger.error('Error adding address', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Update existing address
  Future<bool> updateAddress(CustomerAddress address) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final updatedProfile = await _repository.updateAddress(address);
      
      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      _logger.error('Error updating address', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Remove address
  Future<bool> removeAddress(String addressId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final updatedProfile = await _repository.removeAddress(addressId);
      
      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      _logger.error('Error removing address', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Update preferences
  Future<bool> updatePreferences(CustomerPreferences preferences) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final updatedProfile = await _repository.updatePreferences(preferences);
      
      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      _logger.error('Error updating preferences', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Upload profile image
  Future<bool> uploadProfileImage(String filePath, Uint8List fileBytes) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final imageUrl = await _repository.uploadProfileImage(filePath, fileBytes);
      
      if (state.profile != null) {
        final updatedProfile = state.profile!.copyWith(profileImageUrl: imageUrl);
        await updateProfile(updatedProfile);
      }
      
      return true;
    } catch (e) {
      _logger.error('Error uploading profile image', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Check if profile exists
  Future<bool> checkProfileExists() async {
    try {
      return await _repository.profileExists();
    } catch (e) {
      _logger.error('Error checking profile existence', e);
      return false;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh profile data
  Future<void> refresh() async {
    await loadProfile();
  }
}

// Customer profile provider
final customerProfileProvider = StateNotifierProvider<CustomerProfileNotifier, CustomerProfileState>((ref) {
  final repository = ref.watch(customerProfileRepositoryProvider);
  return CustomerProfileNotifier(repository);
});

// Convenience providers for specific data
final currentCustomerProfileProvider = Provider<CustomerProfile?>((ref) {
  final profile = ref.watch(customerProfileProvider).profile;
  debugPrint('🔍 CurrentCustomerProfileProvider: Profile: ${profile?.id} (${profile?.fullName})');
  return profile;
});

final customerAddressesProvider = Provider<List<CustomerAddress>>((ref) {
  final profile = ref.watch(currentCustomerProfileProvider);
  return profile?.addresses ?? [];
});

final defaultCustomerAddressProvider = Provider<CustomerAddress?>((ref) {
  final profile = ref.watch(currentCustomerProfileProvider);
  final addresses = profile?.addresses ?? [];

  // First try to find an explicitly marked default address
  final explicitDefault = addresses.where((addr) => addr.isDefault).firstOrNull;
  if (explicitDefault != null) {
    return explicitDefault;
  }

  // If no explicit default, return the first address as fallback
  return addresses.isNotEmpty ? addresses.first : null;
});

final customerPreferencesProvider = Provider<CustomerPreferences?>((ref) {
  final profile = ref.watch(currentCustomerProfileProvider);
  return profile?.preferences;
});

final customerStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final profile = ref.watch(currentCustomerProfileProvider);
  if (profile == null) return {};
  
  return {
    'totalOrders': profile.totalOrders,
    'totalSpent': profile.totalSpent,
    'loyaltyPoints': profile.loyaltyPoints,
    'averageOrderValue': profile.totalOrders > 0 ? profile.totalSpent / profile.totalOrders : 0.0,
  };
});
