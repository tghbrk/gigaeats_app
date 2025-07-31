import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/route_optimization_models.dart';
import 'route_optimization_engine.dart';

/// Real-time route adjustment service for Phase 3 multi-order management
/// Handles dynamic route recalculation based on real-time conditions and events
class RealTimeRouteAdjustmentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final RouteOptimizationEngine _optimizationEngine = RouteOptimizationEngine();
  
  // Real-time subscriptions
  RealtimeChannel? _batchMonitoringChannel;
  RealtimeChannel? _trafficConditionsChannel;
  RealtimeChannel? _weatherConditionsChannel;
  
  // Timers for periodic updates
  Timer? _routeAdjustmentTimer;
  Timer? _conditionsUpdateTimer;
  
  // Current state
  String? _activeBatchId;
  final Map<String, dynamic> _currentConditions = {};
  OptimizedRoute? _currentRoute;
  LatLng? _currentDriverLocation;
  
  // Configuration
  static const Duration _adjustmentCheckInterval = Duration(seconds: 30);
  static const Duration _conditionsUpdateInterval = Duration(minutes: 2);
  static const double _significantChangeThreshold = 0.15; // 15% change threshold

  /// Initialize real-time route adjustment monitoring
  Future<void> initializeMonitoring({
    required String batchId,
    required OptimizedRoute initialRoute,
    required LatLng driverLocation,
  }) async {
    try {
      debugPrint('🔄 [REAL-TIME-ADJUSTMENT] Initializing monitoring for batch: $batchId');
      
      _activeBatchId = batchId;
      _currentRoute = initialRoute;
      _currentDriverLocation = driverLocation;
      
      // Set up real-time subscriptions
      await _setupBatchMonitoring(batchId);
      await _setupConditionsMonitoring();
      
      // Start periodic adjustment checks
      _startPeriodicAdjustmentChecks();
      
      // Start conditions updates
      _startConditionsUpdates();
      
      debugPrint('✅ [REAL-TIME-ADJUSTMENT] Monitoring initialized successfully');
      
    } catch (e) {
      debugPrint('❌ [REAL-TIME-ADJUSTMENT] Error initializing monitoring: $e');
      rethrow;
    }
  }

  /// Set up batch monitoring subscription
  Future<void> _setupBatchMonitoring(String batchId) async {
    debugPrint('📡 [REAL-TIME-ADJUSTMENT] Setting up batch monitoring');
    
    _batchMonitoringChannel = _supabase
        .channel('batch_monitoring_$batchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'batch_monitoring_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'batch_id',
            value: batchId,
          ),
          callback: _handleBatchMonitoringEvent,
        )
        .subscribe();
  }

  /// Set up conditions monitoring subscriptions
  Future<void> _setupConditionsMonitoring() async {
    debugPrint('📡 [REAL-TIME-ADJUSTMENT] Setting up conditions monitoring');
    
    // Traffic conditions monitoring
    _trafficConditionsChannel = _supabase
        .channel('traffic_conditions')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'traffic_conditions',
          callback: _handleTrafficConditionsUpdate,
        )
        .subscribe();
    
    // Weather conditions monitoring
    _weatherConditionsChannel = _supabase
        .channel('weather_conditions')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'weather_conditions',
          callback: _handleWeatherConditionsUpdate,
        )
        .subscribe();
  }

  /// Handle batch monitoring events
  void _handleBatchMonitoringEvent(PostgresChangePayload payload) {
    debugPrint('📡 [REAL-TIME-ADJUSTMENT] Batch monitoring event: ${payload.eventType}');
    
    try {
      final eventData = payload.newRecord;
      final eventType = eventData['event_type'] as String?;
      
      switch (eventType) {
        case 'order_added':
        case 'order_removed':
        case 'order_status_changed':
          _triggerRouteAdjustmentCheck('Batch order changes detected');
          break;
        case 'driver_location_updated':
          _updateDriverLocation(eventData);
          break;
        case 'route_deviation_detected':
          _handleRouteDeviation(eventData);
          break;
        default:
          debugPrint('📡 [REAL-TIME-ADJUSTMENT] Unhandled event type: $eventType');
      }
      
    } catch (e) {
      debugPrint('❌ [REAL-TIME-ADJUSTMENT] Error handling batch monitoring event: $e');
    }
  }

  /// Handle traffic conditions updates
  void _handleTrafficConditionsUpdate(PostgresChangePayload payload) {
    debugPrint('📡 [REAL-TIME-ADJUSTMENT] Traffic conditions updated');
    
    try {
      final trafficData = payload.newRecord;
      _currentConditions['traffic'] = trafficData;
      
      final congestionLevel = trafficData['congestion_level'] as String?;
      if (congestionLevel == 'severe' || congestionLevel == 'heavy') {
        _triggerRouteAdjustmentCheck('Severe traffic conditions detected');
      }
      
    } catch (e) {
      debugPrint('❌ [REAL-TIME-ADJUSTMENT] Error handling traffic conditions: $e');
    }
  }

  /// Handle weather conditions updates
  void _handleWeatherConditionsUpdate(PostgresChangePayload payload) {
    debugPrint('📡 [REAL-TIME-ADJUSTMENT] Weather conditions updated');
    
    try {
      final weatherData = payload.newRecord;
      _currentConditions['weather'] = weatherData;
      
      final condition = weatherData['condition'] as String?;
      if (condition == 'thunderstorm' || condition == 'heavy_rain') {
        _triggerRouteAdjustmentCheck('Adverse weather conditions detected');
      }
      
    } catch (e) {
      debugPrint('❌ [REAL-TIME-ADJUSTMENT] Error handling weather conditions: $e');
    }
  }

  /// Update driver location
  void _updateDriverLocation(Map<String, dynamic> eventData) {
    try {
      final locationData = eventData['event_data'] as Map<String, dynamic>?;
      if (locationData != null) {
        final lat = locationData['latitude'] as double?;
        final lng = locationData['longitude'] as double?;
        
        if (lat != null && lng != null) {
          _currentDriverLocation = LatLng(lat, lng);
          debugPrint('📍 [REAL-TIME-ADJUSTMENT] Driver location updated: $lat, $lng');
        }
      }
    } catch (e) {
      debugPrint('❌ [REAL-TIME-ADJUSTMENT] Error updating driver location: $e');
    }
  }

  /// Handle route deviation
  void _handleRouteDeviation(Map<String, dynamic> eventData) {
    debugPrint('⚠️ [REAL-TIME-ADJUSTMENT] Route deviation detected');
    
    try {
      final deviationData = eventData['event_data'] as Map<String, dynamic>?;
      final deviationKm = deviationData?['deviation_km'] as double? ?? 0.0;
      
      if (deviationKm > 2.0) { // Significant deviation threshold
        _triggerRouteAdjustmentCheck('Significant route deviation: ${deviationKm.toStringAsFixed(1)} km');
      }
      
    } catch (e) {
      debugPrint('❌ [REAL-TIME-ADJUSTMENT] Error handling route deviation: $e');
    }
  }

  /// Start periodic adjustment checks
  void _startPeriodicAdjustmentChecks() {
    debugPrint('⏰ [REAL-TIME-ADJUSTMENT] Starting periodic adjustment checks');
    
    _routeAdjustmentTimer = Timer.periodic(_adjustmentCheckInterval, (timer) {
      _performPeriodicAdjustmentCheck();
    });
  }

  /// Start conditions updates
  void _startConditionsUpdates() {
    debugPrint('⏰ [REAL-TIME-ADJUSTMENT] Starting conditions updates');
    
    _conditionsUpdateTimer = Timer.periodic(_conditionsUpdateInterval, (timer) {
      _updateRealTimeConditions();
    });
  }

  /// Perform periodic adjustment check
  Future<void> _performPeriodicAdjustmentCheck() async {
    if (_currentRoute == null || _currentDriverLocation == null || _activeBatchId == null) {
      return;
    }
    
    try {
      debugPrint('🔄 [REAL-TIME-ADJUSTMENT] Performing periodic adjustment check');
      
      // Get completed waypoints
      final completedWaypoints = await _getCompletedWaypoints(_activeBatchId!);
      
      // Calculate route adjustment
      final adjustmentResult = await _optimizationEngine.calculateDynamicRouteAdjustment(
        currentRoute: _currentRoute!,
        currentDriverLocation: _currentDriverLocation!,
        completedWaypointIds: completedWaypoints,
        realTimeConditions: _currentConditions,
      );
      
      // Check if adjustment is significant enough to apply
      if (adjustmentResult.isSuccess && _isSignificantAdjustment(adjustmentResult)) {
        await _applyRouteAdjustment(adjustmentResult);
      }
      
    } catch (e) {
      debugPrint('❌ [REAL-TIME-ADJUSTMENT] Error in periodic adjustment check: $e');
    }
  }

  /// Update real-time conditions
  Future<void> _updateRealTimeConditions() async {
    try {
      debugPrint('📊 [REAL-TIME-ADJUSTMENT] Updating real-time conditions');
      
      // Fetch latest traffic conditions
      final trafficResponse = await _supabase
          .from('traffic_conditions')
          .select()
          .order('created_at', ascending: false)
          .limit(1);
      
      if (trafficResponse.isNotEmpty) {
        _currentConditions['traffic'] = trafficResponse.first;
      }
      
      // Fetch latest weather conditions
      final weatherResponse = await _supabase
          .from('weather_conditions')
          .select()
          .order('created_at', ascending: false)
          .limit(1);
      
      if (weatherResponse.isNotEmpty) {
        _currentConditions['weather'] = weatherResponse.first;
      }
      
      debugPrint('✅ [REAL-TIME-ADJUSTMENT] Conditions updated successfully');
      
    } catch (e) {
      debugPrint('❌ [REAL-TIME-ADJUSTMENT] Error updating conditions: $e');
    }
  }

  /// Get completed waypoints for a batch
  Future<List<String>> _getCompletedWaypoints(String batchId) async {
    try {
      final response = await _supabase
          .from('batch_orders')
          .select('order_id, pickup_status, delivery_status')
          .eq('batch_id', batchId);
      
      final completedWaypoints = <String>[];
      
      for (final order in response) {
        final orderId = order['order_id'] as String;
        final pickupStatus = order['pickup_status'] as String;
        final deliveryStatus = order['delivery_status'] as String;
        
        if (pickupStatus == 'completed') {
          completedWaypoints.add('${orderId}_pickup');
        }
        if (deliveryStatus == 'completed') {
          completedWaypoints.add('${orderId}_delivery');
        }
      }
      
      return completedWaypoints;
      
    } catch (e) {
      debugPrint('❌ [REAL-TIME-ADJUSTMENT] Error getting completed waypoints: $e');
      return [];
    }
  }

  /// Check if adjustment is significant enough to apply
  bool _isSignificantAdjustment(RouteAdjustmentResult adjustmentResult) {
    final improvementScore = adjustmentResult.improvementScore ?? 0.0;
    return improvementScore >= (_significantChangeThreshold * 100);
  }

  /// Apply route adjustment
  Future<void> _applyRouteAdjustment(RouteAdjustmentResult adjustmentResult) async {
    try {
      debugPrint('✅ [REAL-TIME-ADJUSTMENT] Applying route adjustment');
      
      if (adjustmentResult.adjustedRoute != null) {
        _currentRoute = adjustmentResult.adjustedRoute;
        
        // Update batch with new route
        await _supabase
            .from('delivery_batches')
            .update({
              'total_distance_km': _currentRoute!.totalDistanceKm,
              'estimated_duration_minutes': _currentRoute!.totalDuration.inMinutes,
              'optimization_score': _currentRoute!.optimizationScore,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', _activeBatchId!);
        
        // Create adjustment event
        await _supabase.from('batch_monitoring_events').insert({
          'batch_id': _activeBatchId,
          'event_type': 'route_adjusted',
          'event_severity': 'info',
          'event_message': 'Route automatically adjusted based on real-time conditions',
          'event_data': {
            'adjustment_reason': adjustmentResult.adjustmentReason,
            'improvement_score': adjustmentResult.improvementScore,
            'new_distance_km': _currentRoute!.totalDistanceKm,
            'new_duration_minutes': _currentRoute!.totalDuration.inMinutes,
          },
          'created_at': DateTime.now().toIso8601String(),
        });
        
        debugPrint('✅ [REAL-TIME-ADJUSTMENT] Route adjustment applied successfully');
      }
      
    } catch (e) {
      debugPrint('❌ [REAL-TIME-ADJUSTMENT] Error applying route adjustment: $e');
    }
  }

  /// Trigger route adjustment check
  void _triggerRouteAdjustmentCheck(String reason) {
    debugPrint('🔔 [REAL-TIME-ADJUSTMENT] Triggering adjustment check: $reason');
    
    // Perform immediate adjustment check
    _performPeriodicAdjustmentCheck();
  }

  /// Update current route
  void updateCurrentRoute(OptimizedRoute route) {
    _currentRoute = route;
    debugPrint('🔄 [REAL-TIME-ADJUSTMENT] Current route updated');
  }

  /// Update driver location
  void updateDriverLocation(LatLng location) {
    _currentDriverLocation = location;
    debugPrint('📍 [REAL-TIME-ADJUSTMENT] Driver location updated');
  }

  /// Get current conditions
  Map<String, dynamic> getCurrentConditions() {
    return Map<String, dynamic>.from(_currentConditions);
  }

  /// Stop monitoring
  Future<void> stopMonitoring() async {
    debugPrint('🛑 [REAL-TIME-ADJUSTMENT] Stopping monitoring');
    
    // Cancel timers
    _routeAdjustmentTimer?.cancel();
    _conditionsUpdateTimer?.cancel();
    
    // Unsubscribe from channels
    await _batchMonitoringChannel?.unsubscribe();
    await _trafficConditionsChannel?.unsubscribe();
    await _weatherConditionsChannel?.unsubscribe();
    
    // Clear state
    _activeBatchId = null;
    _currentRoute = null;
    _currentDriverLocation = null;
    _currentConditions.clear();
    
    debugPrint('✅ [REAL-TIME-ADJUSTMENT] Monitoring stopped');
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}
