import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../data/models/driver_notification_preferences.dart';
import '../../data/repositories/driver_notification_settings_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Driver Notification Settings State
class DriverNotificationSettingsState {
  final DriverNotificationPreferences preferences;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const DriverNotificationSettingsState({
    this.preferences = const DriverNotificationPreferences(),
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  DriverNotificationSettingsState copyWith({
    DriverNotificationPreferences? preferences,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
  }) {
    return DriverNotificationSettingsState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// Driver Notification Settings Provider
final driverNotificationSettingsProvider = StateNotifierProvider.family<
    DriverNotificationSettingsNotifier,
    DriverNotificationSettingsState,
    String>((ref, driverId) {
  final repository = ref.watch(driverNotificationSettingsRepositoryProvider);
  return DriverNotificationSettingsNotifier(repository, driverId);
});

class DriverNotificationSettingsNotifier extends StateNotifier<DriverNotificationSettingsState> {
  final DriverNotificationSettingsRepository _repository;
  final String _driverId;

  DriverNotificationSettingsNotifier(this._repository, this._driverId)
      : super(const DriverNotificationSettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      debugPrint('🔔 DriverNotificationSettings: Loading settings for driver: $_driverId');
      
      final preferences = await _repository.getDriverNotificationPreferences(_driverId);
      
      debugPrint('🔔 DriverNotificationSettings: Loaded preferences successfully');
      
      state = state.copyWith(
        preferences: preferences,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('🔔 DriverNotificationSettings: Error loading settings: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notification settings: $e',
      );
    }
  }

  Future<void> updatePreferences(DriverNotificationPreferences newPreferences) async {
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);

    try {
      debugPrint('🔔 DriverNotificationSettings: Updating preferences for driver: $_driverId');
      
      // Validate preferences before saving
      if (!_repository.validateDriverNotificationPreferences(newPreferences)) {
        throw Exception('Invalid notification preferences: At least one delivery method and critical notifications must be enabled');
      }

      final success = await _repository.updateDriverNotificationPreferences(_driverId, newPreferences);
      
      if (success) {
        debugPrint('🔔 DriverNotificationSettings: Preferences updated successfully');
        
        state = state.copyWith(
          preferences: newPreferences,
          isSaving: false,
          successMessage: 'Notification settings updated successfully',
        );

        // Clear success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            state = state.copyWith(successMessage: null);
          }
        });
      } else {
        throw Exception('Failed to update preferences');
      }
    } catch (e) {
      debugPrint('🔔 DriverNotificationSettings: Error updating settings: $e');
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to update notification settings: $e',
      );
    }
  }

  void updateSinglePreference(String key, bool value) {
    final currentPrefs = state.preferences;
    DriverNotificationPreferences newPrefs;

    switch (key) {
      // Order notifications
      case 'orderAssignments':
        newPrefs = currentPrefs.copyWith(orderAssignments: value);
        break;
      case 'statusReminders':
        newPrefs = currentPrefs.copyWith(statusReminders: value);
        break;
      case 'orderCancellations':
        newPrefs = currentPrefs.copyWith(orderCancellations: value);
        break;
      case 'orderUpdates':
        newPrefs = currentPrefs.copyWith(orderUpdates: value);
        break;
      
      // Earnings notifications
      case 'earningsUpdates':
        newPrefs = currentPrefs.copyWith(earningsUpdates: value);
        break;
      case 'payoutNotifications':
        newPrefs = currentPrefs.copyWith(payoutNotifications: value);
        break;
      case 'bonusAlerts':
        newPrefs = currentPrefs.copyWith(bonusAlerts: value);
        break;
      case 'commissionUpdates':
        newPrefs = currentPrefs.copyWith(commissionUpdates: value);
        break;
      
      // Performance notifications
      case 'performanceAlerts':
        newPrefs = currentPrefs.copyWith(performanceAlerts: value);
        break;
      case 'ratingUpdates':
        newPrefs = currentPrefs.copyWith(ratingUpdates: value);
        break;
      case 'targetAchievements':
        newPrefs = currentPrefs.copyWith(targetAchievements: value);
        break;
      case 'deliveryMetrics':
        newPrefs = currentPrefs.copyWith(deliveryMetrics: value);
        break;
      
      // Fleet notifications
      case 'fleetAnnouncements':
        newPrefs = currentPrefs.copyWith(fleetAnnouncements: value);
        break;
      case 'systemAnnouncements':
        newPrefs = currentPrefs.copyWith(systemAnnouncements: value);
        break;
      case 'accountUpdates':
        newPrefs = currentPrefs.copyWith(accountUpdates: value);
        break;
      case 'policyChanges':
        newPrefs = currentPrefs.copyWith(policyChanges: value);
        break;
      
      // Location & tracking notifications
      case 'locationReminders':
        newPrefs = currentPrefs.copyWith(locationReminders: value);
        break;
      case 'routeOptimizations':
        newPrefs = currentPrefs.copyWith(routeOptimizations: value);
        break;
      case 'trafficAlerts':
        newPrefs = currentPrefs.copyWith(trafficAlerts: value);
        break;
      case 'deliveryZoneUpdates':
        newPrefs = currentPrefs.copyWith(deliveryZoneUpdates: value);
        break;
      
      // Customer notifications
      case 'customerMessages':
        newPrefs = currentPrefs.copyWith(customerMessages: value);
        break;
      case 'customerFeedback':
        newPrefs = currentPrefs.copyWith(customerFeedback: value);
        break;
      case 'specialInstructions':
        newPrefs = currentPrefs.copyWith(specialInstructions: value);
        break;
      case 'contactUpdates':
        newPrefs = currentPrefs.copyWith(contactUpdates: value);
        break;
      
      // Delivery methods
      case 'emailNotifications':
        newPrefs = currentPrefs.copyWith(emailNotifications: value);
        break;
      case 'pushNotifications':
        newPrefs = currentPrefs.copyWith(pushNotifications: value);
        break;
      case 'smsNotifications':
        newPrefs = currentPrefs.copyWith(smsNotifications: value);
        break;
      
      default:
        debugPrint('🔔 DriverNotificationSettings: Unknown preference key: $key');
        return; // Unknown key, do nothing
    }

    // Update state immediately for UI responsiveness
    debugPrint('🔔 DriverNotificationSettings: Updating state with new preferences for key: $key');
    state = state.copyWith(preferences: newPrefs);

    // Save to backend
    debugPrint('🔔 DriverNotificationSettings: Saving to backend');
    updatePreferences(newPrefs);
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  void refresh() {
    _loadSettings();
  }
}

// Driver Notification categories for UI organization
final driverNotificationCategoriesProvider = Provider<List<DriverNotificationCategory>>((ref) {
  final repository = ref.watch(driverNotificationSettingsRepositoryProvider);
  return repository.getDriverNotificationCategories();
});

// Current driver notification settings provider (uses auth state)
final currentDriverNotificationSettingsProvider = StateNotifierProvider<
    DriverNotificationSettingsNotifier,
    DriverNotificationSettingsState>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id ?? '';

  if (userId.isEmpty) {
    throw Exception('User not authenticated');
  }

  final repository = ref.watch(driverNotificationSettingsRepositoryProvider);
  return DriverNotificationSettingsNotifier(repository, userId);
});

// Helper provider to get current driver ID
final currentDriverIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user?.id;
});

// Provider for checking if driver notification settings are valid
final driverNotificationSettingsValidationProvider = Provider.family<bool, DriverNotificationPreferences>((ref, preferences) {
  final repository = ref.watch(driverNotificationSettingsRepositoryProvider);
  return repository.validateDriverNotificationPreferences(preferences);
});
