import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../models/driver_order.dart';
import '../models/geofence.dart';
import '../models/geofence_event.dart';
import 'geofencing_service.dart';
import 'battery_optimization_service.dart';

/// Enhanced location service with geofencing, automatic status transitions, and battery optimization
/// Integrates with existing driver workflow providers and multi-order batch system
class EnhancedLocationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GeofencingService _geofencingService = GeofencingService();
  final BatteryOptimizationService _batteryService = BatteryOptimizationService();
  
  // Location tracking state
  StreamSubscription<Position>? _locationSubscription;
  Timer? _locationUpdateTimer;
  StreamSubscription<GeofenceEvent>? _geofenceSubscription;
  
  // Current tracking context
  String? _currentDriverId;
  String? _currentOrderId;
  String? _currentBatchId;
  bool _isTracking = false;
  bool _isEnhancedMode = false;
  
  // Battery optimization state
  int _currentBatteryLevel = 100;
  bool _isLowBattery = false;
  LocationAccuracy _currentAccuracy = LocationAccuracy.high;
  Duration _currentUpdateInterval = const Duration(seconds: 15);
  
  // Geofencing state
  final List<Geofence> _activeGeofences = [];
  final Map<String, DateTime> _geofenceEntryTimes = {};
  
  // Status transition callbacks
  Function(String orderId, DriverOrderStatus newStatus)? _onStatusTransition;
  Function(String driverId, Map<String, dynamic> locationData)? _onLocationUpdate;
  
  /// Initialize the enhanced location service
  Future<void> initialize() async {
    debugPrint('🚗 [ENHANCED-LOCATION] Initializing enhanced location service');
    
    await _batteryService.initialize();
    await _geofencingService.initialize();
    
    // Listen to geofence events for automatic status transitions
    _geofenceSubscription = _geofencingService.eventStream.listen(_handleGeofenceEvent);
    
    debugPrint('🚗 [ENHANCED-LOCATION] Enhanced location service initialized');
  }

  /// Start enhanced location tracking with geofencing and battery optimization
  Future<bool> startEnhancedLocationTracking({
    required String driverId,
    String? orderId,
    String? batchId,
    List<Geofence>? geofences,
    int intervalSeconds = 15,
    bool enableGeofencing = true,
    bool enableBatteryOptimization = true,
  }) async {
    try {
      debugPrint('🚗 [ENHANCED-LOCATION] Starting enhanced tracking for driver: $driverId');
      
      // Check permissions
      if (!await _checkLocationPermissions()) {
        throw Exception('Location permissions not granted');
      }
      
      // Stop any existing tracking
      await stopLocationTracking();
      
      // Set tracking context
      _currentDriverId = driverId;
      _currentOrderId = orderId;
      _currentBatchId = batchId;
      _isTracking = true;
      _isEnhancedMode = true;
      
      // Initialize battery optimization if enabled
      if (enableBatteryOptimization) {
        await _initializeBatteryOptimization();
      }
      
      // Set up geofences if provided and enabled
      if (enableGeofencing && geofences != null && geofences.isNotEmpty) {
        await _setupGeofences(geofences);
      }
      
      // Start location tracking with optimized settings
      await _startLocationTracking(intervalSeconds);
      
      debugPrint('🚗 [ENHANCED-LOCATION] Enhanced tracking started successfully');
      return true;
    } catch (e) {
      debugPrint('❌ [ENHANCED-LOCATION] Error starting enhanced tracking: $e');
      return false;
    }
  }

  /// Start basic location tracking (backward compatibility)
  Future<bool> startLocationTracking(String driverId, String orderId, {int intervalSeconds = 30}) async {
    return startEnhancedLocationTracking(
      driverId: driverId,
      orderId: orderId,
      intervalSeconds: intervalSeconds,
      enableGeofencing: false,
      enableBatteryOptimization: false,
    );
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    debugPrint('🚗 [ENHANCED-LOCATION] Stopping location tracking');
    
    _isTracking = false;
    _isEnhancedMode = false;
    
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    
    await _geofencingService.clearGeofences();
    _activeGeofences.clear();
    _geofenceEntryTimes.clear();
    
    _currentDriverId = null;
    _currentOrderId = null;
    _currentBatchId = null;
    
    debugPrint('🚗 [ENHANCED-LOCATION] Location tracking stopped');
  }

  /// Set status transition callback
  void setStatusTransitionCallback(Function(String orderId, DriverOrderStatus newStatus) callback) {
    _onStatusTransition = callback;
  }

  /// Set location update callback
  void setLocationUpdateCallback(Function(String driverId, Map<String, dynamic> locationData) callback) {
    _onLocationUpdate = callback;
  }

  /// Add geofence for automatic status transitions
  Future<void> addGeofence(Geofence geofence) async {
    if (!_isTracking) return;
    
    debugPrint('🎯 [ENHANCED-LOCATION] Adding geofence: ${geofence.id}');
    
    _activeGeofences.add(geofence);
    await _geofencingService.addGeofence(geofence);
  }

  /// Remove geofence
  Future<void> removeGeofence(String geofenceId) async {
    debugPrint('🎯 [ENHANCED-LOCATION] Removing geofence: $geofenceId');
    
    _activeGeofences.removeWhere((g) => g.id == geofenceId);
    _geofenceEntryTimes.remove(geofenceId);
    await _geofencingService.removeGeofence(geofenceId);
  }

  /// Update driver status and adjust tracking parameters
  Future<void> updateDriverStatus(DriverOrderStatus newStatus) async {
    if (!_isTracking) return;
    
    debugPrint('🚗 [ENHANCED-LOCATION] Updating driver status to ${newStatus.displayName}');
    
    // Adjust tracking parameters based on status
    await _adjustTrackingForStatus(newStatus);
    
    // Update geofences based on new status
    await _updateGeofencesForStatus(newStatus);
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      if (!await _checkLocationPermissions()) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: _currentAccuracy,
          timeLimit: const Duration(seconds: 30),
        ),
      );

      debugPrint('🚗 [ENHANCED-LOCATION] Current location - Lat: ${position.latitude}, Lng: ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ [ENHANCED-LOCATION] Error getting current location: $e');
      return null;
    }
  }

  /// Check location permissions
  Future<bool> _checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ [ENHANCED-LOCATION] Location services are disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('❌ [ENHANCED-LOCATION] Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ [ENHANCED-LOCATION] Location permissions are permanently denied');
      return false;
    }

    return true;
  }

  /// Initialize battery optimization
  Future<void> _initializeBatteryOptimization() async {
    debugPrint('🔋 [ENHANCED-LOCATION] Initializing battery optimization');
    
    _currentBatteryLevel = await _batteryService.getBatteryLevel();
    _isLowBattery = _currentBatteryLevel <= 20;
    
    // Adjust initial settings based on battery level
    if (_isLowBattery) {
      _currentAccuracy = LocationAccuracy.medium;
      _currentUpdateInterval = const Duration(seconds: 30);
      debugPrint('🔋 [ENHANCED-LOCATION] Low battery detected, using power-saving mode');
    }
    
    // Start battery monitoring
    _batteryService.batteryLevelStream.listen((level) {
      _currentBatteryLevel = level;
      final wasLowBattery = _isLowBattery;
      _isLowBattery = level <= 20;
      
      if (wasLowBattery != _isLowBattery) {
        debugPrint('🔋 [ENHANCED-LOCATION] Battery status changed: ${_isLowBattery ? "Low" : "Normal"}');
        _adjustTrackingForBattery();
      }
    });
  }

  /// Set up geofences
  Future<void> _setupGeofences(List<Geofence> geofences) async {
    debugPrint('🎯 [ENHANCED-LOCATION] Setting up ${geofences.length} geofences');
    
    _activeGeofences.clear();
    _activeGeofences.addAll(geofences);
    
    await _geofencingService.setupGeofences(geofences);
    
    for (final geofence in geofences) {
      debugPrint('🎯 [ENHANCED-LOCATION] Geofence: ${geofence.id} at ${geofence.center} (${geofence.radius}m)');
    }
  }

  /// Start location tracking with current settings
  Future<void> _startLocationTracking(int intervalSeconds) async {
    debugPrint('🚗 [ENHANCED-LOCATION] Starting location stream with ${_currentUpdateInterval.inSeconds}s interval');
    
    // Start continuous location stream
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: _currentAccuracy,
        distanceFilter: _isLowBattery ? 20 : 10, // Larger distance filter for low battery
      ),
    ).listen(
      _handleLocationUpdate,
      onError: (error) {
        debugPrint('❌ [ENHANCED-LOCATION] Location stream error: $error');
      },
    );
    
    // Start periodic updates as backup
    _locationUpdateTimer = Timer.periodic(_currentUpdateInterval, (timer) async {
      await _performPeriodicLocationUpdate();
    });
  }

  /// Handle location update from stream
  Future<void> _handleLocationUpdate(Position position) async {
    if (!_isTracking || _currentDriverId == null) return;
    
    debugPrint('🚗 [ENHANCED-LOCATION] Location update - Lat: ${position.latitude}, Lng: ${position.longitude}');
    
    // Save to database
    await _saveLocationToDatabase(position);
    
    // Check geofences if enabled
    if (_isEnhancedMode) {
      await _geofencingService.checkGeofences(position);
    }
    
    // Call location update callback
    if (_onLocationUpdate != null) {
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': position.timestamp.toIso8601String(),
        'battery_level': _currentBatteryLevel,
        'is_low_battery': _isLowBattery,
      };
      _onLocationUpdate!(_currentDriverId!, locationData);
    }
  }

  /// Perform periodic location update
  Future<void> _performPeriodicLocationUpdate() async {
    if (!_isTracking || _currentDriverId == null) return;
    
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: _currentAccuracy,
        ),
      );
      
      await _handleLocationUpdate(position);
    } catch (e) {
      debugPrint('❌ [ENHANCED-LOCATION] Error in periodic location update: $e');
    }
  }

  /// Save location to database
  Future<void> _saveLocationToDatabase(Position position) async {
    try {
      final locationData = {
        'driver_id': _currentDriverId,
        'order_id': _currentOrderId,
        'batch_id': _currentBatchId,
        'location': {
          'type': 'Point',
          'coordinates': [position.longitude, position.latitude],
        },
        'speed': position.speed * 3.6, // Convert m/s to km/h
        'heading': position.heading,
        'accuracy': position.accuracy,
        'battery_level': _currentBatteryLevel,
        'network_type': 'mobile', // TODO: Detect actual network type
        'metadata': {
          'altitude': position.altitude,
          'speed_accuracy': position.speedAccuracy,
          'heading_accuracy': position.headingAccuracy,
          'is_enhanced_mode': _isEnhancedMode,
          'tracking_accuracy': _currentAccuracy.name,
          'update_interval_seconds': _currentUpdateInterval.inSeconds,
        },
      };
      
      await _supabase.from('delivery_tracking').insert(locationData);
      
      // Update driver's last known location
      await _supabase.from('drivers').update({
        'current_latitude': position.latitude,
        'current_longitude': position.longitude,
        'last_location_update': DateTime.now().toIso8601String(),
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', _currentDriverId!);
      
    } catch (e) {
      debugPrint('❌ [ENHANCED-LOCATION] Error saving location to database: $e');
    }
  }

  /// Handle geofence events for automatic status transitions
  Future<void> _handleGeofenceEvent(GeofenceEvent event) async {
    debugPrint('🎯 [ENHANCED-LOCATION] Geofence event: ${event.type} for ${event.geofenceId}');

    if (event.type == GeofenceEventType.enter) {
      _geofenceEntryTimes[event.geofenceId] = event.timestamp;

      // Determine status transition based on geofence ID
      DriverOrderStatus? newStatus;
      String? orderId;

      if (event.geofenceId.startsWith('vendor_')) {
        orderId = event.geofenceId.split('_')[1];
        newStatus = DriverOrderStatus.arrivedAtVendor;
      } else if (event.geofenceId.startsWith('customer_')) {
        orderId = event.geofenceId.split('_')[1];
        newStatus = DriverOrderStatus.arrivedAtCustomer;
      }

      // Trigger status transition if valid
      if (newStatus != null && orderId != null && _onStatusTransition != null) {
        debugPrint('🎯 [ENHANCED-LOCATION] Triggering automatic status transition: ${newStatus.displayName}');
        _onStatusTransition!(orderId, newStatus);
      }
    } else if (event.type == GeofenceEventType.exit) {
      _geofenceEntryTimes.remove(event.geofenceId);
    }
  }

  /// Adjust tracking parameters based on driver status
  Future<void> _adjustTrackingForStatus(DriverOrderStatus status) async {
    debugPrint('🚗 [ENHANCED-LOCATION] Adjusting tracking for status: ${status.displayName}');

    Duration newInterval;
    LocationAccuracy newAccuracy;

    switch (status) {
      case DriverOrderStatus.onRouteToVendor:
      case DriverOrderStatus.onRouteToCustomer:
        // High frequency when actively traveling
        newInterval = _isLowBattery ? const Duration(seconds: 20) : const Duration(seconds: 10);
        newAccuracy = _isLowBattery ? LocationAccuracy.medium : LocationAccuracy.high;
        break;

      case DriverOrderStatus.arrivedAtVendor:
      case DriverOrderStatus.arrivedAtCustomer:
        // Medium frequency when at destination
        newInterval = const Duration(seconds: 30);
        newAccuracy = LocationAccuracy.medium;
        break;

      case DriverOrderStatus.assigned:
        // Lower frequency when waiting for pickup
        newInterval = const Duration(seconds: 45);
        newAccuracy = LocationAccuracy.medium;
        break;

      default:
        // Default settings
        newInterval = const Duration(seconds: 15);
        newAccuracy = LocationAccuracy.high;
        break;
    }

    if (newInterval != _currentUpdateInterval || newAccuracy != _currentAccuracy) {
      _currentUpdateInterval = newInterval;
      _currentAccuracy = newAccuracy;

      debugPrint('🚗 [ENHANCED-LOCATION] Updated tracking: ${newInterval.inSeconds}s, ${newAccuracy.name}');

      // Restart location tracking with new settings
      if (_isTracking) {
        await _restartLocationTracking();
      }
    }
  }

  /// Adjust tracking parameters for battery optimization
  Future<void> _adjustTrackingForBattery() async {
    if (!_isTracking) return;

    debugPrint('🔋 [ENHANCED-LOCATION] Adjusting tracking for battery level: $_currentBatteryLevel%');

    if (_isLowBattery) {
      // Power-saving mode
      _currentAccuracy = LocationAccuracy.medium;
      _currentUpdateInterval = Duration(seconds: max(_currentUpdateInterval.inSeconds * 2, 60));
    } else {
      // Normal mode - restore based on current status if available
      _currentAccuracy = LocationAccuracy.high;
      _currentUpdateInterval = const Duration(seconds: 15);
    }

    // Restart tracking with new settings
    await _restartLocationTracking();
  }

  /// Update geofences based on driver status
  Future<void> _updateGeofencesForStatus(DriverOrderStatus status) async {
    if (!_isEnhancedMode || _currentOrderId == null) return;

    debugPrint('🎯 [ENHANCED-LOCATION] Updating geofences for status: ${status.displayName}');

    // Clear existing geofences
    await _geofencingService.clearGeofences();
    _activeGeofences.clear();

    // Add relevant geofences based on status
    switch (status) {
      case DriverOrderStatus.onRouteToVendor:
        // Add vendor arrival geofence
        await _addVendorGeofence(_currentOrderId!);
        break;

      case DriverOrderStatus.onRouteToCustomer:
        // Add customer arrival geofence
        await _addCustomerGeofence(_currentOrderId!);
        break;

      default:
        // No specific geofences needed for other statuses
        break;
    }
  }

  /// Add vendor geofence for automatic arrival detection
  Future<void> _addVendorGeofence(String orderId) async {
    try {
      // Get vendor location from order
      final orderResponse = await _supabase
          .from('orders')
          .select('''
            vendors:vendors!orders_vendor_id_fkey(
              business_address,
              latitude,
              longitude
            )
          ''')
          .eq('id', orderId)
          .single();

      final vendor = orderResponse['vendors'];
      if (vendor != null && vendor['latitude'] != null && vendor['longitude'] != null) {
        final geofence = Geofence(
          id: 'vendor_$orderId',
          center: GeofenceLocation(
            latitude: vendor['latitude'].toDouble(),
            longitude: vendor['longitude'].toDouble(),
          ),
          radius: 100, // 100 meters
          events: [GeofenceEventType.enter, GeofenceEventType.exit],
        );

        await addGeofence(geofence);
        debugPrint('🎯 [ENHANCED-LOCATION] Added vendor geofence for order: $orderId');
      }
    } catch (e) {
      debugPrint('❌ [ENHANCED-LOCATION] Error adding vendor geofence: $e');
    }
  }

  /// Add customer geofence for automatic arrival detection
  Future<void> _addCustomerGeofence(String orderId) async {
    try {
      // Get customer delivery location from order
      final orderResponse = await _supabase
          .from('orders')
          .select('delivery_latitude, delivery_longitude')
          .eq('id', orderId)
          .single();

      if (orderResponse['delivery_latitude'] != null && orderResponse['delivery_longitude'] != null) {
        final geofence = Geofence(
          id: 'customer_$orderId',
          center: GeofenceLocation(
            latitude: orderResponse['delivery_latitude'].toDouble(),
            longitude: orderResponse['delivery_longitude'].toDouble(),
          ),
          radius: 100, // 100 meters
          events: [GeofenceEventType.enter, GeofenceEventType.exit],
        );

        await addGeofence(geofence);
        debugPrint('🎯 [ENHANCED-LOCATION] Added customer geofence for order: $orderId');
      }
    } catch (e) {
      debugPrint('❌ [ENHANCED-LOCATION] Error adding customer geofence: $e');
    }
  }

  /// Restart location tracking with current settings
  Future<void> _restartLocationTracking() async {
    if (!_isTracking) return;

    debugPrint('🚗 [ENHANCED-LOCATION] Restarting location tracking with updated settings');

    // Stop current tracking
    await _locationSubscription?.cancel();
    _locationUpdateTimer?.cancel();

    // Start with new settings
    await _startLocationTracking(_currentUpdateInterval.inSeconds);
  }

  /// Dispose resources
  Future<void> dispose() async {
    debugPrint('🚗 [ENHANCED-LOCATION] Disposing enhanced location service');

    await stopLocationTracking();
    await _geofenceSubscription?.cancel();
    await _geofencingService.dispose();
    await _batteryService.dispose();
  }
}
