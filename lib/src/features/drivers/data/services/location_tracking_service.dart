import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';


import '../repositories/delivery_tracking_repository.dart';
import '../repositories/driver_repository.dart';

/// Service for handling real-time GPS tracking during deliveries
class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  final DeliveryTrackingRepository _trackingRepository = DeliveryTrackingRepository();
  final DriverRepository _driverRepository = DriverRepository();

  StreamSubscription<Position>? _positionSubscription;
  String? _currentOrderId;
  String? _currentDriverId;
  bool _isTracking = false;

  /// Check if location services are available and permissions are granted
  Future<bool> checkLocationPermissions() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationTrackingService: Location services are disabled');
        return false;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('LocationTrackingService: Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationTrackingService: Location permissions are permanently denied');
        return false;
      }

      debugPrint('LocationTrackingService: Location permissions granted');
      return true;
    } catch (e) {
      debugPrint('LocationTrackingService: Error checking permissions: $e');
      return false;
    }
  }

  /// Start tracking location for a delivery
  Future<bool> startTracking({
    required String orderId,
    required String driverId,
  }) async {
    try {
      debugPrint('LocationTrackingService: Starting tracking for order $orderId, driver $driverId');

      // Check permissions first
      if (!await checkLocationPermissions()) {
        throw Exception('Location permissions not granted');
      }

      // Stop any existing tracking
      await stopTracking();

      _currentOrderId = orderId;
      _currentDriverId = driverId;
      _isTracking = true;

      // Configure location settings for delivery tracking
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
        timeLimit: Duration(minutes: 5), // Timeout after 5 minutes
      );

      // Start position stream
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onLocationUpdate,
        onError: _onLocationError,
        onDone: () {
          debugPrint('LocationTrackingService: Position stream completed');
        },
      );

      debugPrint('LocationTrackingService: Tracking started successfully');
      return true;
    } catch (e) {
      debugPrint('LocationTrackingService: Error starting tracking: $e');
      _isTracking = false;
      return false;
    }
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    try {
      debugPrint('LocationTrackingService: Stopping tracking');

      await _positionSubscription?.cancel();
      _positionSubscription = null;
      _currentOrderId = null;
      _currentDriverId = null;
      _isTracking = false;

      debugPrint('LocationTrackingService: Tracking stopped');
    } catch (e) {
      debugPrint('LocationTrackingService: Error stopping tracking: $e');
    }
  }

  /// Handle location updates
  Future<void> _onLocationUpdate(Position position) async {
    if (!_isTracking || _currentOrderId == null || _currentDriverId == null) {
      return;
    }

    try {
      debugPrint('LocationTrackingService: Location update - Lat: ${position.latitude}, Lng: ${position.longitude}');

      // Record tracking point
      await _trackingRepository.recordTrackingPoint(
        orderId: _currentOrderId!,
        driverId: _currentDriverId!,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed * 3.6, // Convert m/s to km/h
        heading: position.heading,
        accuracy: position.accuracy,
        metadata: {
          'altitude': position.altitude,
          'timestamp': position.timestamp.toIso8601String(),
          'speed_accuracy': position.speedAccuracy,
          'heading_accuracy': position.headingAccuracy,
        },
      );

      // Update driver's last known location
      await _driverRepository.updateDriverLocation(
        driverId: _currentDriverId!,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed * 3.6,
        heading: position.heading,
      );

      debugPrint('LocationTrackingService: Location recorded successfully');
    } catch (e) {
      debugPrint('LocationTrackingService: Error recording location: $e');
    }
  }

  /// Handle location errors
  void _onLocationError(dynamic error) {
    debugPrint('LocationTrackingService: Location error: $error');
    
    // Don't stop tracking on temporary errors, but log them
    if (error is LocationServiceDisabledException) {
      debugPrint('LocationTrackingService: Location services disabled');
    } else if (error is PermissionDeniedException) {
      debugPrint('LocationTrackingService: Location permission denied');
      stopTracking(); // Stop tracking if permissions are revoked
    } else {
      debugPrint('LocationTrackingService: Unknown location error: $error');
    }
  }

  /// Get current location once
  Future<Position?> getCurrentLocation() async {
    try {
      if (!await checkLocationPermissions()) {
        return null;
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 30),
      );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      debugPrint('LocationTrackingService: Current location - Lat: ${position.latitude}, Lng: ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('LocationTrackingService: Error getting current location: $e');
      return null;
    }
  }

  /// Calculate distance between two points
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate bearing between two points
  double calculateBearing({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if currently tracking
  bool get isTracking => _isTracking;

  /// Get current tracking info
  Map<String, String?> get currentTrackingInfo => {
    'orderId': _currentOrderId,
    'driverId': _currentDriverId,
  };

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('LocationTrackingService: Error opening location settings: $e');
      return false;
    }
  }

  /// Open app settings for location permissions
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('LocationTrackingService: Error opening app settings: $e');
      return false;
    }
  }

  /// Get location accuracy description
  String getAccuracyDescription(double accuracy) {
    if (accuracy <= 5) {
      return 'Excellent (±${accuracy.toStringAsFixed(1)}m)';
    } else if (accuracy <= 10) {
      return 'Good (±${accuracy.toStringAsFixed(1)}m)';
    } else if (accuracy <= 20) {
      return 'Fair (±${accuracy.toStringAsFixed(1)}m)';
    } else {
      return 'Poor (±${accuracy.toStringAsFixed(1)}m)';
    }
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}
