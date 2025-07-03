import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigaeats_app/src/features/marketplace_wallet/data/models/customer_wallet_error.dart';

/// Customer wallet settings state
class CustomerWalletSettingsState {
  final bool isLoading;
  final CustomerWalletError? error;
  final Map<String, dynamic> settings;

  const CustomerWalletSettingsState({
    this.isLoading = false,
    this.error,
    this.settings = const {},
  });

  CustomerWalletSettingsState copyWith({
    bool? isLoading,
    CustomerWalletError? error,
    Map<String, dynamic>? settings,
  }) {
    return CustomerWalletSettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      settings: settings ?? this.settings,
    );
  }
}

/// Customer wallet settings provider
final customerWalletSettingsProvider = StateNotifierProvider<CustomerWalletSettingsNotifier, CustomerWalletSettingsState>((ref) {
  return CustomerWalletSettingsNotifier();
});

/// Customer wallet settings notifier
class CustomerWalletSettingsNotifier extends StateNotifier<CustomerWalletSettingsState> {
  CustomerWalletSettingsNotifier() : super(const CustomerWalletSettingsState());

  /// Load wallet settings
  Future<void> loadSettings(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Implement actual settings loading from Supabase
      final settings = <String, dynamic>{
        'notifications_enabled': true,
        'auto_reload_enabled': false,
        'spending_limit': 1000.0,
        'privacy_mode': false,
      };
      
      state = state.copyWith(
        settings: settings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: CustomerWalletError.fromException(e is Exception ? e : Exception(e.toString())),
      );
    }
  }

  /// Update setting
  Future<void> updateSetting(String key, dynamic value) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Implement actual settings update to Supabase
      final updatedSettings = Map<String, dynamic>.from(state.settings);
      updatedSettings[key] = value;
      
      state = state.copyWith(
        settings: updatedSettings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: CustomerWalletError.fromException(e is Exception ? e : Exception(e.toString())),
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
