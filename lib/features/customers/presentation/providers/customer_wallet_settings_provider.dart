import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:async';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/customer_wallet_settings.dart';
import '../../data/services/customer_wallet_settings_service.dart';
import '../../data/repositories/customer_wallet_settings_repository.dart';

/// Provider for customer wallet settings service
final customerWalletSettingsServiceProvider = Provider<CustomerWalletSettingsService>((ref) {
  return CustomerWalletSettingsService();
});

/// Provider for customer wallet settings repository
final customerWalletSettingsRepositoryProvider = Provider<CustomerWalletSettingsRepository>((ref) {
  return CustomerWalletSettingsRepository();
});

/// State class for wallet settings
class CustomerWalletSettingsState {
  final bool isLoading;
  final String? errorMessage;
  final CustomerWalletSettings? settings;

  const CustomerWalletSettingsState({
    this.isLoading = false,
    this.errorMessage,
    this.settings,
  });

  CustomerWalletSettingsState copyWith({
    bool? isLoading,
    String? errorMessage,
    CustomerWalletSettings? settings,
  }) {
    return CustomerWalletSettingsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      settings: settings ?? this.settings,
    );
  }
}

/// Notifier for managing wallet settings with real-time synchronization
class CustomerWalletSettingsNotifier extends StateNotifier<CustomerWalletSettingsState> {
  final CustomerWalletSettingsService _settingsService;
  final Ref _ref;
  Timer? _syncTimer;

  static const String _cacheKey = 'customer_wallet_settings';
  static const Duration _syncInterval = Duration(minutes: 5);

  CustomerWalletSettingsNotifier(this._settingsService, this._ref)
      : super(const CustomerWalletSettingsState()) {
    _initializeRealTimeSync();
  }

  /// Initialize real-time synchronization
  void _initializeRealTimeSync() {
    // Start periodic sync timer
    _syncTimer = Timer.periodic(_syncInterval, (_) => _syncWithServer());

    // Load cached settings first for immediate display
    _loadCachedSettings();

    // Then load from server
    loadSettings();
  }

  /// Load cached settings from local storage
  Future<void> _loadCachedSettings() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        final settingsJson = json.decode(cachedData) as Map<String, dynamic>;
        final settings = CustomerWalletSettings.fromJson(settingsJson);

        state = state.copyWith(
          settings: settings,
          isLoading: false,
        );
      }
    } catch (e) {
      // Ignore cache errors, will load from server
      debugPrint('Failed to load cached settings: $e');
    }
  }

  /// Cache settings to local storage
  Future<void> _cacheSettings(CustomerWalletSettings settings) async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final settingsJson = json.encode(settings.toJson());
      await prefs.setString(_cacheKey, settingsJson);
    } catch (e) {
      debugPrint('Failed to cache settings: $e');
    }
  }

  /// Sync with server periodically
  Future<void> _syncWithServer() async {
    if (state.isLoading) return; // Don't sync if already loading

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) return;

      final serverSettings = await _settingsService.getSettings(user.id);

      // Only update if settings have changed
      if (serverSettings != state.settings) {
        state = state.copyWith(settings: serverSettings);
        await _cacheSettings(serverSettings);
      }
    } catch (e) {
      // Silently handle sync errors to avoid disrupting user experience
      debugPrint('Background sync failed: $e');
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  /// Load wallet settings for the current user
  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final settings = await _settingsService.getSettings(user.id);
      
      state = state.copyWith(
        isLoading: false,
        settings: settings,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update display settings
  Future<void> updateDisplaySettings(Map<String, dynamic> updates) async {
    if (state.settings == null) return;

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Optimistically update local state
      final updatedSettings = state.settings!.copyWith(
        showBalanceOnDashboard: updates['showBalanceOnDashboard'] ?? state.settings!.showBalanceOnDashboard,
        currencyFormat: updates['currencyFormat'] ?? state.settings!.currencyFormat,
        transactionHistoryLimit: updates['transactionHistoryLimit'] ?? state.settings!.transactionHistoryLimit,
      );

      state = state.copyWith(settings: updatedSettings);

      // Update on server
      await _settingsService.updateDisplaySettings(user.id, updates);
      
    } catch (e) {
      // Revert optimistic update on error
      await loadSettings();
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Update security settings
  Future<void> updateSecuritySettings(Map<String, dynamic> updates) async {
    if (state.settings == null) return;

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Optimistically update local state
      final updatedSettings = state.settings!.copyWith(
        requirePinForTransactions: updates['requirePinForTransactions'] ?? state.settings!.requirePinForTransactions,
        enableBiometricAuth: updates['enableBiometricAuth'] ?? state.settings!.enableBiometricAuth,
        largeAmountThreshold: updates['largeAmountThreshold'] ?? state.settings!.largeAmountThreshold,
        autoLockWallet: updates['autoLockWallet'] ?? state.settings!.autoLockWallet,
      );

      state = state.copyWith(settings: updatedSettings);

      // Update on server
      await _settingsService.updateSecuritySettings(user.id, updates);
      
    } catch (e) {
      // Revert optimistic update on error
      await loadSettings();
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(Map<String, dynamic> updates) async {
    if (state.settings == null) return;

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Optimistically update local state
      final updatedSettings = state.settings!.copyWith(
        transactionNotifications: updates['transactionNotifications'] ?? state.settings!.transactionNotifications,
        lowBalanceAlerts: updates['lowBalanceAlerts'] ?? state.settings!.lowBalanceAlerts,
        spendingLimitAlerts: updates['spendingLimitAlerts'] ?? state.settings!.spendingLimitAlerts,
        promotionalNotifications: updates['promotionalNotifications'] ?? state.settings!.promotionalNotifications,
      );

      state = state.copyWith(settings: updatedSettings);

      // Update on server
      await _settingsService.updateNotificationSettings(user.id, updates);
      
    } catch (e) {
      // Revert optimistic update on error
      await loadSettings();
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Update auto-reload settings
  Future<void> updateAutoReloadSettings(Map<String, dynamic> updates) async {
    if (state.settings == null) return;

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Optimistically update local state
      final updatedSettings = state.settings!.copyWith(
        enableAutoReload: updates['enableAutoReload'] ?? state.settings!.enableAutoReload,
        autoReloadThreshold: updates['autoReloadThreshold'] ?? state.settings!.autoReloadThreshold,
        autoReloadAmount: updates['autoReloadAmount'] ?? state.settings!.autoReloadAmount,
      );

      state = state.copyWith(settings: updatedSettings);

      // Update on server
      await _settingsService.updateAutoReloadSettings(user.id, updates);
      
    } catch (e) {
      // Revert optimistic update on error
      await loadSettings();
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Update spending limits
  Future<void> updateSpendingLimits(Map<String, dynamic> updates) async {
    if (state.settings == null) return;

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Optimistically update local state
      final updatedSettings = state.settings!.copyWith(
        dailySpendingLimit: updates['dailySpendingLimit'] ?? state.settings!.dailySpendingLimit,
        weeklySpendingLimit: updates['weeklySpendingLimit'] ?? state.settings!.weeklySpendingLimit,
        monthlySpendingLimit: updates['monthlySpendingLimit'] ?? state.settings!.monthlySpendingLimit,
      );

      state = state.copyWith(settings: updatedSettings);

      // Update on server
      await _settingsService.updateSpendingLimits(user.id, updates);
      
    } catch (e) {
      // Revert optimistic update on error
      await loadSettings();
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Reset settings to defaults
  Future<void> resetToDefaults() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _settingsService.resetToDefaults(user.id);
      await loadSettings(); // Reload settings after reset
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Refresh settings
  Future<void> refresh() async {
    await loadSettings();
  }
}

/// Provider for wallet settings state management
final customerWalletSettingsProvider = StateNotifierProvider<CustomerWalletSettingsNotifier, CustomerWalletSettingsState>((ref) {
  final settingsService = ref.watch(customerWalletSettingsServiceProvider);
  return CustomerWalletSettingsNotifier(settingsService, ref);
});

/// Provider for wallet settings as AsyncValue
final customerWalletSettingsAsyncProvider = FutureProvider<CustomerWalletSettings?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  if (user == null) {
    return null;
  }

  final settingsService = ref.watch(customerWalletSettingsServiceProvider);
  return settingsService.getSettings(user.id);
});

/// Provider for specific setting values
final walletSettingProvider = Provider.family<dynamic, String>((ref, settingKey) {
  final settingsState = ref.watch(customerWalletSettingsProvider);
  final settings = settingsState.settings;
  
  if (settings == null) return null;
  
  switch (settingKey) {
    case 'showBalanceOnDashboard':
      return settings.showBalanceOnDashboard;
    case 'currencyFormat':
      return settings.currencyFormat;
    case 'transactionHistoryLimit':
      return settings.transactionHistoryLimit;
    case 'requirePinForTransactions':
      return settings.requirePinForTransactions;
    case 'enableBiometricAuth':
      return settings.enableBiometricAuth;
    case 'largeAmountThreshold':
      return settings.largeAmountThreshold;
    case 'autoLockWallet':
      return settings.autoLockWallet;
    case 'transactionNotifications':
      return settings.transactionNotifications;
    case 'lowBalanceAlerts':
      return settings.lowBalanceAlerts;
    case 'spendingLimitAlerts':
      return settings.spendingLimitAlerts;
    case 'promotionalNotifications':
      return settings.promotionalNotifications;
    case 'enableAutoReload':
      return settings.enableAutoReload;
    case 'autoReloadThreshold':
      return settings.autoReloadThreshold;
    case 'autoReloadAmount':
      return settings.autoReloadAmount;
    case 'dailySpendingLimit':
      return settings.dailySpendingLimit;
    case 'weeklySpendingLimit':
      return settings.weeklySpendingLimit;
    case 'monthlySpendingLimit':
      return settings.monthlySpendingLimit;
    default:
      return null;
  }
});

/// Provider for checking if settings are loading
final walletSettingsLoadingProvider = Provider<bool>((ref) {
  final settingsState = ref.watch(customerWalletSettingsProvider);
  return settingsState.isLoading;
});

/// Provider for settings error message
final walletSettingsErrorProvider = Provider<String?>((ref) {
  final settingsState = ref.watch(customerWalletSettingsProvider);
  return settingsState.errorMessage;
});
