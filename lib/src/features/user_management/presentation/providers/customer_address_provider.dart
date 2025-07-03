import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/customer_profile.dart';
import '../../data/repositories/customer_profile_repository.dart';
import 'customer_profile_provider.dart';
import '../../../../core/utils/logger.dart';

// Repository providers
final customerProfileRepositoryProvider = Provider<CustomerProfileRepository>((ref) {
  return CustomerProfileRepository();
});

// Customer addresses state
class CustomerAddressesState {
  final List<CustomerAddress> addresses;
  final bool isLoading;
  final String? error;
  final CustomerAddress? selectedAddress;

  const CustomerAddressesState({
    this.addresses = const [],
    this.isLoading = false,
    this.error,
    this.selectedAddress,
  });

  CustomerAddressesState copyWith({
    List<CustomerAddress>? addresses,
    bool? isLoading,
    String? error,
    CustomerAddress? selectedAddress,
  }) {
    return CustomerAddressesState(
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedAddress: selectedAddress ?? this.selectedAddress,
    );
  }
}

// Customer addresses notifier
class CustomerAddressesNotifier extends StateNotifier<CustomerAddressesState> {
  final CustomerProfileRepository _repository;
  final Ref _ref;
  final AppLogger _logger = AppLogger();

  CustomerAddressesNotifier(this._repository, this._ref)
      : super(const CustomerAddressesState());

  /// Load customer addresses
  Future<void> loadAddresses() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _logger.info('🏠 [ADDRESS-PROVIDER] Loading addresses for current user');

      final profile = await _repository.getCurrentProfile();
      if (profile == null) {
        throw Exception('Customer profile not found');
      }

      final addresses = profile.addresses;

      _logger.info('✅ [ADDRESS-PROVIDER] Loaded ${addresses.length} addresses');

      state = state.copyWith(
        addresses: addresses,
        isLoading: false,
      );
    } catch (e) {
      _logger.error('❌ [ADDRESS-PROVIDER] Error loading addresses', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add new address
  Future<bool> addAddress(CustomerAddress address) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _logger.info('🏠 [ADDRESS-PROVIDER] Adding address: ${address.label}');

      // If this is the first address or marked as default, make it default
      final isFirstAddress = state.addresses.isEmpty;
      final addressToAdd = address.copyWith(
        isDefault: address.isDefault || isFirstAddress,
      );

      await _repository.addAddress(addressToAdd);

      // Reload addresses to get updated list
      await loadAddresses();

      // Refresh profile to update address count in other screens
      _refreshProfile();

      _logger.info('✅ [ADDRESS-PROVIDER] Address added successfully');
      return true;
    } catch (e) {
      _logger.error('❌ [ADDRESS-PROVIDER] Error adding address', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Update existing address
  Future<bool> updateAddress(String addressId, CustomerAddress updatedAddress) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _logger.info('🏠 [ADDRESS-PROVIDER] Updating address: $addressId');

      await _repository.updateAddress(updatedAddress);

      // Reload addresses to get updated list
      await loadAddresses();

      // Refresh profile to update address count in other screens
      _refreshProfile();

      _logger.info('✅ [ADDRESS-PROVIDER] Address updated successfully');
      return true;
    } catch (e) {
      _logger.error('❌ [ADDRESS-PROVIDER] Error updating address', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Delete address
  Future<bool> deleteAddress(String addressId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _logger.info('🏠 [ADDRESS-PROVIDER] Deleting address: $addressId');

      // Check if this is the default address
      final addressToDelete = state.addresses.firstWhere(
        (addr) => addr.id == addressId,
        orElse: () => throw Exception('Address not found'),
      );

      if (addressToDelete.isDefault && state.addresses.length > 1) {
        throw Exception('Cannot delete default address. Please set another address as default first.');
      }

      await _repository.removeAddress(addressId);

      // Reload addresses to get updated list
      await loadAddresses();

      // Refresh profile to update address count in other screens
      _refreshProfile();

      _logger.info('✅ [ADDRESS-PROVIDER] Address deleted successfully');
      return true;
    } catch (e) {
      _logger.error('❌ [ADDRESS-PROVIDER] Error deleting address', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Set default address
  Future<bool> setDefaultAddress(String addressId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _logger.info('🏠 [ADDRESS-PROVIDER] Setting default address: $addressId');

      // Find the address to set as default
      final addressToSetDefault = state.addresses.firstWhere(
        (addr) => addr.id == addressId,
        orElse: () => throw Exception('Address not found'),
      );

      // Update the address to be default
      final updatedAddress = addressToSetDefault.copyWith(isDefault: true);
      await _repository.updateAddress(updatedAddress);

      // Update all other addresses to not be default
      for (final address in state.addresses) {
        if (address.id != addressId && address.isDefault) {
          final nonDefaultAddress = address.copyWith(isDefault: false);
          await _repository.updateAddress(nonDefaultAddress);
        }
      }

      // Reload addresses to get updated list
      await loadAddresses();

      // Refresh profile to update address count in other screens
      _refreshProfile();

      _logger.info('✅ [ADDRESS-PROVIDER] Default address set successfully');
      return true;
    } catch (e) {
      _logger.error('❌ [ADDRESS-PROVIDER] Error setting default address', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Select address for use in other parts of the app
  void selectAddress(CustomerAddress address) {
    state = state.copyWith(selectedAddress: address);
    _logger.info('🏠 [ADDRESS-PROVIDER] Address selected: ${address.label}');
  }

  /// Clear selected address
  void clearSelectedAddress() {
    state = state.copyWith(selectedAddress: null);
    _logger.info('🏠 [ADDRESS-PROVIDER] Address selection cleared');
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh addresses
  Future<void> refresh() async {
    await loadAddresses();
  }

  /// Refresh profile provider to update address-related data in other screens
  void _refreshProfile() {
    try {
      // Trigger profile refresh to update address count and other address-related data
      _ref.read(customerProfileProvider.notifier).refresh();
      _logger.info('🔄 [ADDRESS-PROVIDER] Profile refreshed after address change');
    } catch (e) {
      _logger.error('❌ [ADDRESS-PROVIDER] Error refreshing profile', e);
    }
  }
}

// Customer addresses provider
final customerAddressesProvider = StateNotifierProvider<CustomerAddressesNotifier, CustomerAddressesState>((ref) {
  final repository = ref.watch(customerProfileRepositoryProvider);
  return CustomerAddressesNotifier(repository, ref);
});

// Convenience providers for specific data
final customerAddressListProvider = Provider<List<CustomerAddress>>((ref) {
  return ref.watch(customerAddressesProvider).addresses;
});

final defaultCustomerAddressProvider = Provider<CustomerAddress?>((ref) {
  // Watch the addresses state to get updates when addresses are loaded
  final addressesState = ref.watch(customerAddressesProvider);
  final addresses = addressesState.addresses;

  debugPrint('🔍 [DEFAULT-ADDRESS-PROVIDER] === PROVIDER ACCESSED ===');
  debugPrint('🔍 [DEFAULT-ADDRESS-PROVIDER] Checking ${addresses.length} addresses');
  debugPrint('🔍 [DEFAULT-ADDRESS-PROVIDER] State loading: ${addressesState.isLoading}');
  debugPrint('🔍 [DEFAULT-ADDRESS-PROVIDER] State error: ${addressesState.error}');
  debugPrint('🔍 [DEFAULT-ADDRESS-PROVIDER] Provider hash: ${addressesState.hashCode}');
  debugPrint('🔍 [DEFAULT-ADDRESS-PROVIDER] Addresses hash: ${addresses.hashCode}');

  // Don't trigger loading during provider initialization to avoid circular dependency
  // The addresses should be loaded by the UI components that need them

  if (addresses.isEmpty) {
    debugPrint('❌ [DEFAULT-ADDRESS-PROVIDER] No addresses available');
    debugPrint('❌ [DEFAULT-ADDRESS-PROVIDER] === PROVIDER RETURNING NULL ===');
    return null;
  }

  for (int i = 0; i < addresses.length; i++) {
    debugPrint('🔍 [DEFAULT-ADDRESS-PROVIDER] Address $i: ${addresses[i].label} (isDefault: ${addresses[i].isDefault})');
  }

  // First try to find an explicitly marked default address
  final explicitDefault = addresses.where((addr) => addr.isDefault).firstOrNull;
  if (explicitDefault != null) {
    debugPrint('✅ [DEFAULT-ADDRESS-PROVIDER] Found explicit default: ${explicitDefault.label}');
    return explicitDefault;
  }

  // If no explicit default, return the first address as fallback
  debugPrint('⚠️ [DEFAULT-ADDRESS-PROVIDER] No explicit default, using first address: ${addresses.first.label}');
  return addresses.first;
});

final selectedCustomerAddressProvider = Provider<CustomerAddress?>((ref) {
  return ref.watch(customerAddressesProvider).selectedAddress;
});

final customerAddressesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(customerAddressesProvider).isLoading;
});

final customerAddressesErrorProvider = Provider<String?>((ref) {
  return ref.watch(customerAddressesProvider).error;
});

// Helper provider to check if addresses are empty
final hasCustomerAddressesProvider = Provider<bool>((ref) {
  final addresses = ref.watch(customerAddressListProvider);
  return addresses.isNotEmpty;
});

// Provider for address by ID
final customerAddressByIdProvider = Provider.family<CustomerAddress?, String>((ref, addressId) {
  final addresses = ref.watch(customerAddressListProvider);
  return addresses.where((addr) => addr.id == addressId).firstOrNull;
});
