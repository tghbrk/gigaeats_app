import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/logger.dart';

/// Route Optimization Feature Flag System
/// Manages gradual rollout of multi-order route optimization features
/// with driver-specific targeting, A/B testing, and emergency rollback capabilities
class RouteOptimizationFeatureFlags {
  static final RouteOptimizationFeatureFlags _instance = RouteOptimizationFeatureFlags._internal();
  factory RouteOptimizationFeatureFlags() => _instance;
  RouteOptimizationFeatureFlags._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AppLogger _logger = AppLogger();

  // Feature flag cache
  Map<String, dynamic> _flagCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Default feature flag values (fallback)
  static const Map<String, dynamic> _defaultFlags = {
    // Core feature toggles
    'enable_multi_order_batching': false,
    'enable_advanced_tsp': false,
    'enable_real_time_optimization': false,
    'enable_route_optimization_dashboard': false,
    
    // Rollout percentages (0-100)
    'batching_rollout_percentage': 0.0,
    'tsp_algorithm_rollout_percentage': 0.0,
    'dashboard_rollout_percentage': 0.0,
    
    // Algorithm selection
    'default_tsp_algorithm': 'nearest_neighbor',
    'enable_genetic_algorithm': false,
    'enable_simulated_annealing': false,
    'enable_hybrid_multi_algorithm': false,
    
    // Performance thresholds
    'max_calculation_time_ms': 5000,
    'min_optimization_score': 70.0,
    'max_batch_orders': 3,
    'max_deviation_km': 5.0,
    
    // Beta testing
    'enable_beta_testing_program': false,
    'beta_driver_list': <String>[],
    'beta_feedback_collection': false,
    
    // Emergency controls
    'emergency_disable_all': false,
    'emergency_rollback_mode': false,
    'maintenance_mode': false,
  };

  /// Initialize feature flags system
  Future<void> initialize() async {
    try {
      await _loadFeatureFlags();
      _logger.info('Route optimization feature flags initialized');
    } catch (e) {
      _logger.error('Failed to initialize feature flags: $e');
      // Use default flags as fallback
      _flagCache = Map.from(_defaultFlags);
    }
  }

  /// Load feature flags from remote configuration
  Future<void> _loadFeatureFlags() async {
    try {
      final response = await _supabase
          .from('feature_flags')
          .select('*')
          .eq('feature_group', 'route_optimization')
          .eq('is_active', true);

      final flags = <String, dynamic>{};
      for (final flag in response) {
        final key = flag['flag_key'] as String;
        final value = _parseValue(flag['flag_value'], flag['value_type']);
        flags[key] = value;
      }

      // Merge with defaults
      _flagCache = {..._defaultFlags, ...flags};
      _lastCacheUpdate = DateTime.now();

      _logger.info('Feature flags loaded: ${flags.keys.length} flags');
    } catch (e) {
      _logger.error('Failed to load feature flags from remote: $e');
      // Keep existing cache or use defaults
      if (_flagCache.isEmpty) {
        _flagCache = Map.from(_defaultFlags);
      }
    }
  }

  /// Parse flag value based on type
  dynamic _parseValue(String value, String type) {
    switch (type) {
      case 'boolean':
        return value.toLowerCase() == 'true';
      case 'integer':
        return int.tryParse(value) ?? 0;
      case 'double':
        return double.tryParse(value) ?? 0.0;
      case 'string':
        return value;
      case 'json':
        try {
          return jsonDecode(value);
        } catch (e) {
          return value;
        }
      default:
        return value;
    }
  }

  /// Check if cache needs refresh
  bool _needsCacheRefresh() {
    if (_lastCacheUpdate == null) return true;
    return DateTime.now().difference(_lastCacheUpdate!) > _cacheExpiry;
  }

  /// Get feature flag value with automatic cache refresh
  Future<T> getFlag<T>(String key, T defaultValue) async {
    if (_needsCacheRefresh()) {
      await _loadFeatureFlags();
    }
    
    return _flagCache[key] as T? ?? defaultValue;
  }

  /// Get feature flag value synchronously (uses cache)
  T getFlagSync<T>(String key, T defaultValue) {
    return _flagCache[key] as T? ?? defaultValue;
  }

  /// Check if multi-order batching is enabled for a specific driver
  Future<bool> isMultiOrderBatchingEnabled(String driverId) async {
    // Check emergency disable
    if (await getFlag('emergency_disable_all', false)) {
      return false;
    }

    // Check maintenance mode
    if (await getFlag('maintenance_mode', false)) {
      return false;
    }

    // Check if feature is globally enabled
    if (!await getFlag('enable_multi_order_batching', false)) {
      return false;
    }

    // Check if driver is in beta program
    final betaDrivers = await getFlag<List<dynamic>>('beta_driver_list', <String>[]);
    if (betaDrivers.contains(driverId)) {
      return true;
    }

    // Check rollout percentage
    final rolloutPercentage = await getFlag('batching_rollout_percentage', 0.0);
    return _isDriverInRollout(driverId, rolloutPercentage);
  }

  /// Check if advanced TSP algorithms are enabled for a driver
  Future<bool> isAdvancedTSPEnabled(String driverId) async {
    if (await getFlag('emergency_disable_all', false)) {
      return false;
    }

    if (!await getFlag('enable_advanced_tsp', false)) {
      return false;
    }

    final rolloutPercentage = await getFlag('tsp_algorithm_rollout_percentage', 0.0);
    return _isDriverInRollout(driverId, rolloutPercentage);
  }

  /// Get the TSP algorithm to use for a driver
  Future<String> getTSPAlgorithm(String driverId) async {
    if (!await isAdvancedTSPEnabled(driverId)) {
      return 'nearest_neighbor';
    }

    // Check which advanced algorithms are enabled
    final enableGenetic = await getFlag('enable_genetic_algorithm', false);
    final enableSimulated = await getFlag('enable_simulated_annealing', false);
    final enableHybrid = await getFlag('enable_hybrid_multi_algorithm', false);

    // Use driver ID to consistently assign algorithm
    final hash = driverId.hashCode.abs();
    final algorithms = <String>[];
    
    if (enableGenetic) algorithms.add('genetic_algorithm');
    if (enableSimulated) algorithms.add('simulated_annealing');
    if (enableHybrid) algorithms.add('hybrid_multi');
    
    if (algorithms.isEmpty) {
      return await getFlag('default_tsp_algorithm', 'nearest_neighbor');
    }

    return algorithms[hash % algorithms.length];
  }

  /// Check if real-time optimization is enabled
  Future<bool> isRealTimeOptimizationEnabled(String driverId) async {
    if (await getFlag('emergency_disable_all', false)) {
      return false;
    }

    return await getFlag('enable_real_time_optimization', false);
  }

  /// Check if route optimization dashboard is enabled
  Future<bool> isDashboardEnabled(String userId) async {
    if (await getFlag('emergency_disable_all', false)) {
      return false;
    }

    if (!await getFlag('enable_route_optimization_dashboard', false)) {
      return false;
    }

    final rolloutPercentage = await getFlag('dashboard_rollout_percentage', 0.0);
    return _isDriverInRollout(userId, rolloutPercentage);
  }

  /// Check if beta testing program is active
  Future<bool> isBetaTestingActive() async {
    return await getFlag('enable_beta_testing_program', false);
  }

  /// Check if a driver is in the beta program
  Future<bool> isDriverInBetaProgram(String driverId) async {
    if (!await isBetaTestingActive()) {
      return false;
    }

    final betaDrivers = await getFlag<List<dynamic>>('beta_driver_list', <String>[]);
    return betaDrivers.contains(driverId);
  }

  /// Get performance thresholds
  Future<Map<String, dynamic>> getPerformanceThresholds() async {
    return {
      'max_calculation_time_ms': await getFlag('max_calculation_time_ms', 5000),
      'min_optimization_score': await getFlag('min_optimization_score', 70.0),
      'max_batch_orders': await getFlag('max_batch_orders', 3),
      'max_deviation_km': await getFlag('max_deviation_km', 5.0),
    };
  }

  /// Check if driver is in rollout based on percentage
  bool _isDriverInRollout(String driverId, double percentage) {
    if (percentage <= 0) return false;
    if (percentage >= 100) return true;

    // Use consistent hash-based assignment
    final hash = driverId.hashCode.abs();
    final driverPercentile = (hash % 100) / 100.0;
    return driverPercentile < (percentage / 100.0);
  }

  /// Emergency disable all route optimization features
  Future<void> emergencyDisableAll() async {
    try {
      await _updateFlag('emergency_disable_all', true);
      _logger.warning('Emergency disable activated for route optimization');
    } catch (e) {
      _logger.error('Failed to activate emergency disable: $e');
    }
  }

  /// Enable rollback mode
  Future<void> enableRollbackMode() async {
    try {
      await _updateFlag('emergency_rollback_mode', true);
      await _updateFlag('enable_multi_order_batching', false);
      _logger.warning('Rollback mode activated for route optimization');
    } catch (e) {
      _logger.error('Failed to activate rollback mode: $e');
    }
  }

  /// Update a feature flag value
  Future<void> _updateFlag(String key, dynamic value) async {
    try {
      await _supabase
          .from('feature_flags')
          .upsert({
            'feature_group': 'route_optimization',
            'flag_key': key,
            'flag_value': value.toString(),
            'value_type': _getValueType(value),
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          });

      // Update cache
      _flagCache[key] = value;
      
    } catch (e) {
      _logger.error('Failed to update feature flag $key: $e');
      rethrow;
    }
  }

  /// Get value type for database storage
  String _getValueType(dynamic value) {
    if (value is bool) return 'boolean';
    if (value is int) return 'integer';
    if (value is double) return 'double';
    if (value is String) return 'string';
    return 'json';
  }

  /// Get current rollout status
  Future<Map<String, dynamic>> getRolloutStatus() async {
    return {
      'multi_order_batching': {
        'enabled': await getFlag('enable_multi_order_batching', false),
        'rollout_percentage': await getFlag('batching_rollout_percentage', 0.0),
      },
      'advanced_tsp': {
        'enabled': await getFlag('enable_advanced_tsp', false),
        'rollout_percentage': await getFlag('tsp_algorithm_rollout_percentage', 0.0),
      },
      'dashboard': {
        'enabled': await getFlag('enable_route_optimization_dashboard', false),
        'rollout_percentage': await getFlag('dashboard_rollout_percentage', 0.0),
      },
      'beta_testing': {
        'active': await getFlag('enable_beta_testing_program', false),
        'driver_count': (await getFlag<List<dynamic>>('beta_driver_list', <String>[])).length,
      },
      'emergency_status': {
        'disabled': await getFlag('emergency_disable_all', false),
        'rollback_mode': await getFlag('emergency_rollback_mode', false),
        'maintenance_mode': await getFlag('maintenance_mode', false),
      },
    };
  }

  /// Refresh feature flags cache
  Future<void> refreshCache() async {
    await _loadFeatureFlags();
  }

  /// Clear cache (for testing)
  @visibleForTesting
  void clearCache() {
    _flagCache.clear();
    _lastCacheUpdate = null;
  }
}
