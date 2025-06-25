import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';

import '../models/driver_order.dart';

/// Adaptive location service that optimizes GPS usage for battery efficiency
/// Adjusts location update frequency based on driver status, movement, and battery level
class AdaptiveLocationService {
  static const Duration _highFrequencyInterval = Duration(seconds: 5);
  static const Duration _mediumFrequencyInterval = Duration(seconds: 15);
  static const Duration _lowFrequencyInterval = Duration(seconds: 30);
  static const Duration _idleFrequencyInterval = Duration(minutes: 2);
  
  static const double _movementThreshold = 5.0; // meters
  static const double _stationaryThreshold = 10.0; // meters
  static const int _stationaryTimeThreshold = 60; // seconds
  static const int _lowBatteryThreshold = 20; // percentage
  
  final Battery _battery = Battery();
  
  StreamSubscription<Position>? _locationSubscription;
  Timer? _adaptiveTimer;
  
  Position? _lastPosition;
  DateTime? _lastMovementTime;
  DateTime? _lastLocationUpdate;
  
  bool _isMonitoring = false;
  String? _currentOrderId;
  DriverOrderStatus? _currentStatus;
  
  // Movement tracking
  final List<Position> _recentPositions = [];
  static const int _maxRecentPositions = 10;
  
  // Battery optimization
  int _currentBatteryLevel = 100;
  bool _isLowBattery = false;
  
  // Adaptive frequency
  Duration _currentUpdateInterval = _mediumFrequencyInterval;
  LocationAccuracy _currentAccuracy = LocationAccuracy.high;
  
  /// Start adaptive location monitoring
  Future<bool> startAdaptiveMonitoring(String orderId, DriverOrderStatus status) async {
    try {
      debugPrint('AdaptiveLocationService: Starting adaptive monitoring for order: $orderId, status: ${status.displayName}');
      
      // Stop any existing monitoring
      await stopMonitoring();
      
      _currentOrderId = orderId;
      _currentStatus = status;
      _isMonitoring = true;
      _lastMovementTime = DateTime.now();
      
      // Check initial battery level
      await _updateBatteryLevel();
      
      // Set initial monitoring parameters based on status
      _updateMonitoringParameters();
      
      // Start location monitoring
      await _startLocationStream();
      
      // Start adaptive timer for periodic adjustments
      _startAdaptiveTimer();
      
      debugPrint('AdaptiveLocationService: Adaptive monitoring started successfully');
      return true;
    } catch (e) {
      debugPrint('AdaptiveLocationService: Error starting adaptive monitoring: $e');
      return false;
    }
  }
  
  /// Stop location monitoring
  Future<void> stopMonitoring() async {
    debugPrint('AdaptiveLocationService: Stopping adaptive monitoring');
    
    _locationSubscription?.cancel();
    _adaptiveTimer?.cancel();
    
    _locationSubscription = null;
    _adaptiveTimer = null;
    _currentOrderId = null;
    _currentStatus = null;
    _isMonitoring = false;
    _lastPosition = null;
    _lastMovementTime = null;
    _lastLocationUpdate = null;
    _recentPositions.clear();
  }
  
  /// Update driver status and adjust monitoring accordingly
  Future<void> updateDriverStatus(DriverOrderStatus newStatus) async {
    if (!_isMonitoring) return;
    
    debugPrint('AdaptiveLocationService: Updating driver status to ${newStatus.displayName}');
    
    _currentStatus = newStatus;
    _updateMonitoringParameters();
    
    // Restart location stream with new parameters
    await _restartLocationStream();
  }
  
  /// Start location stream with current parameters
  Future<void> _startLocationStream() async {
    try {
      final locationSettings = LocationSettings(
        accuracy: _currentAccuracy,
        distanceFilter: _getDistanceFilter(),
      );
      
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _handleLocationUpdate,
        onError: (error) {
          debugPrint('AdaptiveLocationService: Location stream error: $error');
        },
      );
      
      debugPrint('AdaptiveLocationService: Location stream started with accuracy: $_currentAccuracy, interval: $_currentUpdateInterval');
    } catch (e) {
      debugPrint('AdaptiveLocationService: Error starting location stream: $e');
    }
  }
  
  /// Restart location stream with updated parameters
  Future<void> _restartLocationStream() async {
    _locationSubscription?.cancel();
    await _startLocationStream();
  }
  
  /// Handle location updates
  void _handleLocationUpdate(Position position) {
    _lastLocationUpdate = DateTime.now();
    
    // Track movement
    _trackMovement(position);
    
    // Update recent positions
    _recentPositions.add(position);
    if (_recentPositions.length > _maxRecentPositions) {
      _recentPositions.removeAt(0);
    }
    
    _lastPosition = position;
    
    debugPrint('AdaptiveLocationService: Location updated: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)');
  }
  
  /// Track movement and detect stationary periods
  void _trackMovement(Position position) {
    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      
      if (distance > _movementThreshold) {
        _lastMovementTime = DateTime.now();
        debugPrint('AdaptiveLocationService: Movement detected: ${distance.toStringAsFixed(1)}m');
      }
    }
  }
  
  /// Start adaptive timer for periodic adjustments
  void _startAdaptiveTimer() {
    _adaptiveTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _performAdaptiveAdjustments();
    });
  }
  
  /// Perform adaptive adjustments based on current conditions
  Future<void> _performAdaptiveAdjustments() async {
    if (!_isMonitoring) return;
    
    // Update battery level
    await _updateBatteryLevel();
    
    // Check if driver is stationary
    final isStationary = _isDriverStationary();
    
    // Determine optimal monitoring parameters
    final oldInterval = _currentUpdateInterval;
    final oldAccuracy = _currentAccuracy;
    
    _updateMonitoringParameters(isStationary: isStationary);
    
    // Restart location stream if parameters changed significantly
    if (_currentUpdateInterval != oldInterval || _currentAccuracy != oldAccuracy) {
      debugPrint('AdaptiveLocationService: Adjusting monitoring - Interval: $_currentUpdateInterval, Accuracy: $_currentAccuracy, Stationary: $isStationary, Battery: $_currentBatteryLevel%');
      await _restartLocationStream();
    }
  }
  
  /// Update monitoring parameters based on current conditions
  void _updateMonitoringParameters({bool? isStationary}) {
    isStationary ??= _isDriverStationary();
    
    // Base parameters on driver status
    switch (_currentStatus) {
      case DriverOrderStatus.onRouteToVendor:
      case DriverOrderStatus.onRouteToCustomer:
        // High frequency when actively traveling
        _currentUpdateInterval = _isLowBattery ? _mediumFrequencyInterval : _highFrequencyInterval;
        _currentAccuracy = _isLowBattery ? LocationAccuracy.medium : LocationAccuracy.high;
        break;

      case DriverOrderStatus.arrivedAtVendor:
      case DriverOrderStatus.arrivedAtCustomer:
        // Medium frequency when at destination
        _currentUpdateInterval = _mediumFrequencyInterval;
        _currentAccuracy = LocationAccuracy.medium;
        break;

      case DriverOrderStatus.assigned:
      case DriverOrderStatus.pickedUp:
        // Medium frequency for other active statuses
        _currentUpdateInterval = _mediumFrequencyInterval;
        _currentAccuracy = LocationAccuracy.medium;
        break;
        
      default:
        // Low frequency for inactive statuses
        _currentUpdateInterval = _lowFrequencyInterval;
        _currentAccuracy = LocationAccuracy.low;
        break;
    }
    
    // Adjust for stationary periods
    if (isStationary) {
      _currentUpdateInterval = _idleFrequencyInterval;
      _currentAccuracy = LocationAccuracy.low;
    }
    
    // Adjust for low battery
    if (_isLowBattery) {
      _currentUpdateInterval = Duration(
        milliseconds: (_currentUpdateInterval.inMilliseconds * 1.5).round(),
      );
      if (_currentAccuracy == LocationAccuracy.high) {
        _currentAccuracy = LocationAccuracy.medium;
      } else if (_currentAccuracy == LocationAccuracy.medium) {
        _currentAccuracy = LocationAccuracy.low;
      }
    }
  }
  
  /// Check if driver is stationary
  bool _isDriverStationary() {
    if (_lastMovementTime == null || _recentPositions.length < 3) {
      return false;
    }
    
    final timeSinceMovement = DateTime.now().difference(_lastMovementTime!);
    if (timeSinceMovement.inSeconds < _stationaryTimeThreshold) {
      return false;
    }
    
    // Check if recent positions are within stationary threshold
    final recentPositions = _recentPositions.take(5).toList();
    if (recentPositions.length < 3) return false;
    
    double maxDistance = 0;
    for (int i = 0; i < recentPositions.length - 1; i++) {
      for (int j = i + 1; j < recentPositions.length; j++) {
        final distance = Geolocator.distanceBetween(
          recentPositions[i].latitude,
          recentPositions[i].longitude,
          recentPositions[j].latitude,
          recentPositions[j].longitude,
        );
        maxDistance = max(maxDistance, distance);
      }
    }
    
    return maxDistance <= _stationaryThreshold;
  }
  
  /// Update battery level
  Future<void> _updateBatteryLevel() async {
    try {
      _currentBatteryLevel = await _battery.batteryLevel;
      _isLowBattery = _currentBatteryLevel <= _lowBatteryThreshold;
      
      if (_isLowBattery) {
        debugPrint('AdaptiveLocationService: Low battery detected: $_currentBatteryLevel%');
      }
    } catch (e) {
      debugPrint('AdaptiveLocationService: Error getting battery level: $e');
    }
  }
  
  /// Get distance filter based on current parameters
  int _getDistanceFilter() {
    switch (_currentAccuracy) {
      case LocationAccuracy.high:
        return 3;
      case LocationAccuracy.medium:
        return 5;
      case LocationAccuracy.low:
        return 10;
      default:
        return 5;
    }
  }
  
  /// Get current monitoring statistics
  Map<String, dynamic> getMonitoringStats() {
    return {
      'is_monitoring': _isMonitoring,
      'current_order_id': _currentOrderId,
      'current_status': _currentStatus?.displayName,
      'update_interval_seconds': _currentUpdateInterval.inSeconds,
      'accuracy': _currentAccuracy.name,
      'battery_level': _currentBatteryLevel,
      'is_low_battery': _isLowBattery,
      'is_stationary': _isDriverStationary(),
      'last_movement': _lastMovementTime?.toIso8601String(),
      'last_update': _lastLocationUpdate?.toIso8601String(),
      'recent_positions_count': _recentPositions.length,
    };
  }
  
  /// Get current position
  Position? get currentPosition => _lastPosition;
  
  /// Check if monitoring is active
  bool get isMonitoring => _isMonitoring;
}
