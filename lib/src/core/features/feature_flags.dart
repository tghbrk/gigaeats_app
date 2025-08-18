import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Feature flags for controlling app features
/// 
/// This system allows for gradual rollout of new features and A/B testing.
/// Features can be controlled via:
/// 1. Local preferences (user settings)
/// 2. Remote config (future implementation)
/// 3. Build configuration
class FeatureFlags {
  static const String _enhancedDriverInterface = 'enhanced_driver_interface';
  static const String _newPaymentFlow = 'new_payment_flow';
  static const String _advancedAnalytics = 'advanced_analytics';

  // Default feature states
  static const Map<String, bool> _defaultFlags = {
    _enhancedDriverInterface: false,
    _newPaymentFlow: false,
    _advancedAnalytics: false,
  };

  /// Enhanced Driver Interface Feature Flag
  static const String enhancedDriverInterface = _enhancedDriverInterface;
  
  /// New Payment Flow Feature Flag
  static const String newPaymentFlow = _newPaymentFlow;
  
  /// Advanced Analytics Feature Flag
  static const String advancedAnalytics = _advancedAnalytics;
  
  /// Get all available feature flags
  static List<String> get allFlags => _defaultFlags.keys.toList();
  
  /// Get default state for a feature flag
  static bool getDefaultState(String flag) => _defaultFlags[flag] ?? false;
}

/// Feature Flag Service for managing feature states
class FeatureFlagService {
  final SharedPreferences _prefs;
  
  FeatureFlagService(this._prefs);
  
  /// Check if a feature is enabled
  Future<bool> isEnabled(String flag) async {
    final key = 'feature_flag_$flag';
    return _prefs.getBool(key) ?? FeatureFlags.getDefaultState(flag);
  }
  
  /// Enable a feature flag
  Future<void> enable(String flag) async {
    final key = 'feature_flag_$flag';
    await _prefs.setBool(key, true);
  }
  
  /// Disable a feature flag
  Future<void> disable(String flag) async {
    final key = 'feature_flag_$flag';
    await _prefs.setBool(key, false);
  }
  
  /// Toggle a feature flag
  Future<bool> toggle(String flag) async {
    final currentState = await isEnabled(flag);
    final newState = !currentState;
    
    if (newState) {
      await enable(flag);
    } else {
      await disable(flag);
    }
    
    return newState;
  }
  
  /// Reset a feature flag to default state
  Future<void> reset(String flag) async {
    final key = 'feature_flag_$flag';
    await _prefs.remove(key);
  }
  
  /// Reset all feature flags to default states
  Future<void> resetAll() async {
    for (final flag in FeatureFlags.allFlags) {
      await reset(flag);
    }
  }
  
  /// Get all feature flag states
  Future<Map<String, bool>> getAllStates() async {
    final states = <String, bool>{};
    
    for (final flag in FeatureFlags.allFlags) {
      states[flag] = await isEnabled(flag);
    }
    
    return states;
  }
  
  /// Bulk update feature flags
  Future<void> updateFlags(Map<String, bool> flags) async {
    for (final entry in flags.entries) {
      if (entry.value) {
        await enable(entry.key);
      } else {
        await disable(entry.key);
      }
    }
  }
}

/// Provider for FeatureFlagService
final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  throw UnimplementedError('FeatureFlagService must be overridden');
});

/// Provider for checking if enhanced driver interface is enabled
final enhancedDriverInterfaceEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(featureFlagServiceProvider);
  return service.isEnabled(FeatureFlags.enhancedDriverInterface);
});

/// Provider for checking if new payment flow is enabled
final newPaymentFlowEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(featureFlagServiceProvider);
  return service.isEnabled(FeatureFlags.newPaymentFlow);
});

/// Provider for checking if advanced analytics is enabled
final advancedAnalyticsEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(featureFlagServiceProvider);
  return service.isEnabled(FeatureFlags.advancedAnalytics);
});

/// Provider for getting all feature flag states
final allFeatureFlagsProvider = FutureProvider<Map<String, bool>>((ref) async {
  final service = ref.read(featureFlagServiceProvider);
  return service.getAllStates();
});

/// Notifier for managing feature flag states with real-time updates
class FeatureFlagNotifier extends StateNotifier<AsyncValue<Map<String, bool>>> {
  final FeatureFlagService _service;
  
  FeatureFlagNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadFlags();
  }
  
  /// Load all feature flags
  Future<void> _loadFlags() async {
    try {
      final flags = await _service.getAllStates();
      state = AsyncValue.data(flags);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  /// Toggle a feature flag and refresh state
  Future<void> toggleFlag(String flag) async {
    try {
      await _service.toggle(flag);
      await _loadFlags(); // Refresh state
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  /// Enable a feature flag and refresh state
  Future<void> enableFlag(String flag) async {
    try {
      await _service.enable(flag);
      await _loadFlags(); // Refresh state
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  /// Disable a feature flag and refresh state
  Future<void> disableFlag(String flag) async {
    try {
      await _service.disable(flag);
      await _loadFlags(); // Refresh state
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  /// Reset all flags to defaults and refresh state
  Future<void> resetAllFlags() async {
    try {
      await _service.resetAll();
      await _loadFlags(); // Refresh state
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  /// Refresh feature flags from storage
  Future<void> refresh() async {
    await _loadFlags();
  }
}

/// Provider for FeatureFlagNotifier
final featureFlagNotifierProvider = StateNotifierProvider<FeatureFlagNotifier, AsyncValue<Map<String, bool>>>((ref) {
  final service = ref.read(featureFlagServiceProvider);
  return FeatureFlagNotifier(service);
});
