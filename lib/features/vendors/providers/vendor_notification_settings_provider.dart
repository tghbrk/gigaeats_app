import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Temporary stub for vendor notification settings provider
class VendorNotificationSettingsState {
  final bool isLoading;
  final String? error;
  final Map<String, bool> settings;

  const VendorNotificationSettingsState({
    this.isLoading = false,
    this.error,
    this.settings = const {},
  });

  VendorNotificationSettingsState copyWith({
    bool? isLoading,
    String? error,
    Map<String, bool>? settings,
  }) {
    return VendorNotificationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      settings: settings ?? this.settings,
    );
  }
}

class VendorNotificationSettingsNotifier extends StateNotifier<VendorNotificationSettingsState> {
  VendorNotificationSettingsNotifier() : super(const VendorNotificationSettingsState());

  void refresh() {
    // Stub implementation
  }

  void clearMessages() {
    // Stub implementation
  }

  Future<void> updateSetting(String key, bool value) async {
    // Stub implementation
  }
}

/// Provider for vendor notification settings
final vendorNotificationSettingsProvider = StateNotifierProvider.family<
    VendorNotificationSettingsNotifier,
    VendorNotificationSettingsState,
    String>((ref, vendorId) {
  return VendorNotificationSettingsNotifier();
});

/// Provider for notification categories
final notificationCategoriesProvider = Provider<List<String>>((ref) {
  return ['orders', 'business', 'marketing', 'payments'];
});
