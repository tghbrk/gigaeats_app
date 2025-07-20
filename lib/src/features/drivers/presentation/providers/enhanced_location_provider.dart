import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/driver_order.dart';
import '../../data/models/geofence.dart';
import '../../data/models/geofence_event.dart';
import '../../data/services/enhanced_location_service.dart';
// import 'driver_workflow_provider.dart'; // TODO: Import when available

/// Enhanced location state
@immutable
class EnhancedLocationState {
  final bool isTracking;
  final bool isEnhancedMode;
  final Position? currentPosition;
  final List<Geofence> activeGeofences;
  final List<GeofenceEvent> recentEvents;
  final int batteryLevel;
  final bool isLowBattery;
  final bool isCharging;
  final String? currentDriverId;
  final String? currentOrderId;
  final String? currentBatchId;
  final Map<String, dynamic>? batteryOptimizationSettings;
  final String? error;

  const EnhancedLocationState({
    this.isTracking = false,
    this.isEnhancedMode = false,
    this.currentPosition,
    this.activeGeofences = const [],
    this.recentEvents = const [],
    this.batteryLevel = 100,
    this.isLowBattery = false,
    this.isCharging = false,
    this.currentDriverId,
    this.currentOrderId,
    this.currentBatchId,
    this.batteryOptimizationSettings,
    this.error,
  });

  EnhancedLocationState copyWith({
    bool? isTracking,
    bool? isEnhancedMode,
    Position? currentPosition,
    List<Geofence>? activeGeofences,
    List<GeofenceEvent>? recentEvents,
    int? batteryLevel,
    bool? isLowBattery,
    bool? isCharging,
    String? currentDriverId,
    String? currentOrderId,
    String? currentBatchId,
    Map<String, dynamic>? batteryOptimizationSettings,
    String? error,
  }) {
    return EnhancedLocationState(
      isTracking: isTracking ?? this.isTracking,
      isEnhancedMode: isEnhancedMode ?? this.isEnhancedMode,
      currentPosition: currentPosition ?? this.currentPosition,
      activeGeofences: activeGeofences ?? this.activeGeofences,
      recentEvents: recentEvents ?? this.recentEvents,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isLowBattery: isLowBattery ?? this.isLowBattery,
      isCharging: isCharging ?? this.isCharging,
      currentDriverId: currentDriverId ?? this.currentDriverId,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      currentBatchId: currentBatchId ?? this.currentBatchId,
      batteryOptimizationSettings: batteryOptimizationSettings ?? this.batteryOptimizationSettings,
      error: error,
    );
  }
}

/// Enhanced location provider with geofencing and battery optimization
class EnhancedLocationNotifier extends StateNotifier<EnhancedLocationState> {
  final EnhancedLocationService _locationService = EnhancedLocationService();
  
  StreamSubscription<GeofenceEvent>? _geofenceSubscription;
  StreamSubscription<int>? _batterySubscription;
  Timer? _positionUpdateTimer;

  EnhancedLocationNotifier() : super(const EnhancedLocationState()) {
    _initialize();
  }

  /// Initialize the enhanced location service
  Future<void> _initialize() async {
    try {
      debugPrint('🚗 [ENHANCED-LOCATION-PROVIDER] Initializing enhanced location provider');
      
      await _locationService.initialize();
      
      // Set up callbacks
      _locationService.setStatusTransitionCallback(_handleStatusTransition);
      _locationService.setLocationUpdateCallback(_handleLocationUpdate);
      
      // Note: We'll need to expose these streams through the location service
      // For now, we'll handle events through the callbacks

      // Get initial battery optimization settings
      // This will be handled through the location service callbacks
      
      // Initial state will be updated through callbacks
      state = state.copyWith(
        batteryLevel: 100,
        isLowBattery: false,
        isCharging: false,
      );
      
      debugPrint('🚗 [ENHANCED-LOCATION-PROVIDER] Enhanced location provider initialized');
    } catch (e) {
      debugPrint('❌ [ENHANCED-LOCATION-PROVIDER] Error initializing: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Start enhanced location tracking
  Future<bool> startEnhancedTracking({
    required String driverId,
    String? orderId,
    String? batchId,
    List<Geofence>? geofences,
    int intervalSeconds = 15,
    bool enableGeofencing = true,
    bool enableBatteryOptimization = true,
  }) async {
    try {
      debugPrint('🚗 [ENHANCED-LOCATION-PROVIDER] Starting enhanced tracking for driver: $driverId');
      
      final success = await _locationService.startEnhancedLocationTracking(
        driverId: driverId,
        orderId: orderId,
        batchId: batchId,
        geofences: geofences,
        intervalSeconds: intervalSeconds,
        enableGeofencing: enableGeofencing,
        enableBatteryOptimization: enableBatteryOptimization,
      );
      
      if (success) {
        state = state.copyWith(
          isTracking: true,
          isEnhancedMode: true,
          currentDriverId: driverId,
          currentOrderId: orderId,
          currentBatchId: batchId,
          activeGeofences: geofences ?? [],
          error: null,
        );
        
        // Start periodic position updates
        _startPositionUpdates();
      } else {
        state = state.copyWith(error: 'Failed to start enhanced tracking');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ [ENHANCED-LOCATION-PROVIDER] Error starting enhanced tracking: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Start basic location tracking (backward compatibility)
  Future<bool> startLocationTracking(String driverId, String orderId, {int intervalSeconds = 30}) async {
    return startEnhancedTracking(
      driverId: driverId,
      orderId: orderId,
      intervalSeconds: intervalSeconds,
      enableGeofencing: false,
      enableBatteryOptimization: false,
    );
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    try {
      debugPrint('🚗 [ENHANCED-LOCATION-PROVIDER] Stopping location tracking');
      
      await _locationService.stopLocationTracking();
      _positionUpdateTimer?.cancel();
      
      state = state.copyWith(
        isTracking: false,
        isEnhancedMode: false,
        currentDriverId: null,
        currentOrderId: null,
        currentBatchId: null,
        activeGeofences: [],
        error: null,
      );
    } catch (e) {
      debugPrint('❌ [ENHANCED-LOCATION-PROVIDER] Error stopping tracking: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Add geofence
  Future<void> addGeofence(Geofence geofence) async {
    try {
      await _locationService.addGeofence(geofence);
      
      final updatedGeofences = List<Geofence>.from(state.activeGeofences);
      updatedGeofences.removeWhere((g) => g.id == geofence.id);
      updatedGeofences.add(geofence);
      
      state = state.copyWith(activeGeofences: updatedGeofences);
    } catch (e) {
      debugPrint('❌ [ENHANCED-LOCATION-PROVIDER] Error adding geofence: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Remove geofence
  Future<void> removeGeofence(String geofenceId) async {
    try {
      await _locationService.removeGeofence(geofenceId);
      
      final updatedGeofences = state.activeGeofences.where((g) => g.id != geofenceId).toList();
      state = state.copyWith(activeGeofences: updatedGeofences);
    } catch (e) {
      debugPrint('❌ [ENHANCED-LOCATION-PROVIDER] Error removing geofence: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update driver status and adjust tracking
  Future<void> updateDriverStatus(DriverOrderStatus newStatus) async {
    try {
      await _locationService.updateDriverStatus(newStatus);

      // Battery optimization settings will be updated through callbacks
      debugPrint('🚗 [ENHANCED-LOCATION-PROVIDER] Driver status updated to: ${newStatus.displayName}');
    } catch (e) {
      debugPrint('❌ [ENHANCED-LOCATION-PROVIDER] Error updating driver status: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        state = state.copyWith(currentPosition: position);
      }
      return position;
    } catch (e) {
      debugPrint('❌ [ENHANCED-LOCATION-PROVIDER] Error getting current location: $e');
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Handle status transition from geofencing
  void _handleStatusTransition(String orderId, DriverOrderStatus newStatus) {
    debugPrint('🎯 [ENHANCED-LOCATION-PROVIDER] Auto status transition: ${newStatus.displayName} for order: $orderId');
    
    // Trigger status update in driver workflow provider
    try {
      // TODO: Integrate with driver workflow provider when available
      // _ref.read(driverWorkflowProvider.notifier).updateOrderStatus(orderId, newStatus);
      debugPrint('🎯 [ENHANCED-LOCATION-PROVIDER] Status transition triggered: ${newStatus.displayName}');
    } catch (e) {
      debugPrint('❌ [ENHANCED-LOCATION-PROVIDER] Error triggering status transition: $e');
    }
  }

  /// Handle location update
  void _handleLocationUpdate(String driverId, Map<String, dynamic> locationData) {
    debugPrint('🚗 [ENHANCED-LOCATION-PROVIDER] Location update for driver: $driverId');
    
    // Update battery information from location data
    final batteryLevel = locationData['battery_level'] as int? ?? state.batteryLevel;
    final isLowBattery = locationData['is_low_battery'] as bool? ?? state.isLowBattery;
    
    state = state.copyWith(
      batteryLevel: batteryLevel,
      isLowBattery: isLowBattery,
    );
  }



  /// Start periodic position updates
  void _startPositionUpdates() {
    _positionUpdateTimer?.cancel();
    _positionUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (state.isTracking) {
        await getCurrentLocation();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    debugPrint('🚗 [ENHANCED-LOCATION-PROVIDER] Disposing enhanced location provider');
    
    _geofenceSubscription?.cancel();
    _batterySubscription?.cancel();
    _positionUpdateTimer?.cancel();
    _locationService.dispose();
    
    super.dispose();
  }
}

/// Enhanced location provider
final enhancedLocationProvider = StateNotifierProvider<EnhancedLocationNotifier, EnhancedLocationState>((ref) {
  return EnhancedLocationNotifier();
});

/// Current position provider
final currentPositionProvider = Provider<Position?>((ref) {
  return ref.watch(enhancedLocationProvider).currentPosition;
});

/// Active geofences provider
final activeGeofencesProvider = Provider<List<Geofence>>((ref) {
  return ref.watch(enhancedLocationProvider).activeGeofences;
});

/// Recent geofence events provider
final recentGeofenceEventsProvider = Provider<List<GeofenceEvent>>((ref) {
  return ref.watch(enhancedLocationProvider).recentEvents;
});

/// Battery optimization settings provider
final batteryOptimizationProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(enhancedLocationProvider).batteryOptimizationSettings;
});
