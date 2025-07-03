import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

import '../../domain/customer_account_settings.dart';
import '../../data/repositories/customer_account_settings_repository.dart';

part 'customer_account_settings_provider.freezed.dart';

/// State for customer account settings
@freezed
class CustomerAccountSettingsState with _$CustomerAccountSettingsState {
  const factory CustomerAccountSettingsState({
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,
    String? error,
    CustomerAccountSettings? settings,
    CustomerAccountSettings? originalSettings,
    @Default(false) bool hasUnsavedChanges,
  }) = _CustomerAccountSettingsState;
}

/// Customer account settings state notifier
class CustomerAccountSettingsNotifier extends StateNotifier<CustomerAccountSettingsState> {
  CustomerAccountSettingsNotifier({
    required CustomerAccountSettingsRepository repository,
  }) : _repository = repository,
       super(const CustomerAccountSettingsState());

  final CustomerAccountSettingsRepository _repository;

  /// Load account settings
  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final settings = await _repository.getCurrentSettings();
      
      state = state.copyWith(
        isLoading: false,
        settings: settings,
        originalSettings: settings,
        hasUnsavedChanges: false,
      );
    } catch (e) {
      debugPrint('Error loading account settings: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update notification preferences
  void updateNotificationPreferences(CustomerNotificationPreferences preferences) {
    final currentSettings = state.settings;
    if (currentSettings == null) return;

    final updatedSettings = currentSettings.copyWith(
      notificationPreferences: preferences,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      settings: updatedSettings,
      hasUnsavedChanges: _hasChanges(updatedSettings),
    );
  }

  /// Update privacy settings
  void updatePrivacySettings(CustomerPrivacySettings privacy) {
    final currentSettings = state.settings;
    if (currentSettings == null) return;

    final updatedSettings = currentSettings.copyWith(
      privacySettings: privacy,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      settings: updatedSettings,
      hasUnsavedChanges: _hasChanges(updatedSettings),
    );
  }

  /// Update app preferences
  void updateAppPreferences(CustomerAppPreferences app) {
    final currentSettings = state.settings;
    if (currentSettings == null) return;

    final updatedSettings = currentSettings.copyWith(
      appPreferences: app,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      settings: updatedSettings,
      hasUnsavedChanges: _hasChanges(updatedSettings),
    );
  }

  /// Update security settings
  void updateSecuritySettings(CustomerSecuritySettings security) {
    final currentSettings = state.settings;
    if (currentSettings == null) return;

    final updatedSettings = currentSettings.copyWith(
      securitySettings: security,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      settings: updatedSettings,
      hasUnsavedChanges: _hasChanges(updatedSettings),
    );
  }

  /// Save settings
  Future<bool> saveSettings() async {
    final currentSettings = state.settings;
    if (currentSettings == null) return false;

    state = state.copyWith(isSaving: true, error: null);
    
    try {
      await _repository.updateSettings(currentSettings);
      
      state = state.copyWith(
        isSaving: false,
        originalSettings: currentSettings,
        hasUnsavedChanges: false,
      );
      
      debugPrint('Account settings saved successfully');
      return true;
    } catch (e) {
      debugPrint('Error saving account settings: $e');
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save settings: $e',
      );
      return false;
    }
  }

  /// Reset settings to original values
  void resetSettings() {
    final original = state.originalSettings;
    if (original != null) {
      state = state.copyWith(
        settings: original,
        hasUnsavedChanges: false,
        error: null,
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Check if settings have changes compared to original
  bool _hasChanges(CustomerAccountSettings current) {
    final original = state.originalSettings;
    if (original == null) return false;
    
    return current.notificationPreferences != original.notificationPreferences ||
           current.privacySettings != original.privacySettings ||
           current.appPreferences != original.appPreferences ||
           current.securitySettings != original.securitySettings;
  }

  /// Refresh settings
  Future<void> refresh() async {
    await loadSettings();
  }
}

/// Provider for customer account settings
final customerAccountSettingsProvider = StateNotifierProvider<CustomerAccountSettingsNotifier, CustomerAccountSettingsState>((ref) {
  final repository = ref.watch(customerAccountSettingsRepositoryProvider);
  
  return CustomerAccountSettingsNotifier(
    repository: repository,
  );
});

/// Provider for customer account settings repository
final customerAccountSettingsRepositoryProvider = Provider<CustomerAccountSettingsRepository>((ref) {
  return CustomerAccountSettingsRepository();
});
