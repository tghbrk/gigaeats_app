import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../models/navigation_models.dart';

/// Enhanced 3D navigation camera service with smooth transitions, bearing-based rotation,
/// and optimized zoom levels for the GigaEats Enhanced In-App Navigation System
class Enhanced3DNavigationCameraService {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _locationSubscription;
  Timer? _smoothingTimer;
  
  // Camera state
  CameraPosition? _lastCameraPosition;
  double _currentBearing = 0.0;
  double _targetBearing = 0.0;
  double _currentZoom = 18.0;
  double _targetZoom = 18.0;
  bool _isAnimating = false;
  bool _isFollowingLocation = true;
  
  // Smoothing parameters
  static const Duration _smoothingInterval = Duration(milliseconds: 50);
  static const double _bearingSmoothing = 0.15; // Lower = smoother
  static const double _zoomSmoothing = 0.1;
  // ignore: unused_field
  static const double _positionSmoothing = 0.2;

  // Navigation-optimized camera settings
  static const double _navigationTilt = 65.0; // Optimal 3D perspective
  // ignore: unused_field
  static const double _minNavigationZoom = 16.0;
  // ignore: unused_field
  static const double _maxNavigationZoom = 20.0;
  static const double _defaultNavigationZoom = 18.0;

  // Bearing calculation parameters
  static const double _bearingThreshold = 5.0; // Minimum bearing change to trigger update
  // ignore: unused_field
  static const double _speedBasedZoomThreshold = 10.0; // km/h threshold for zoom adjustment
  
  bool _isInitialized = false;
  NavigationSession? _currentSession;
  
  /// Initialize the enhanced 3D camera service
  Future<void> initialize(GoogleMapController mapController) async {
    if (_isInitialized) return;
    
    debugPrint('📹 [3D-CAMERA] Initializing enhanced 3D navigation camera service');
    
    _mapController = mapController;
    _isInitialized = true;
    
    // Start smooth camera updates
    _startSmoothCameraUpdates();
    
    debugPrint('📹 [3D-CAMERA] Enhanced 3D camera service initialized');
  }
  
  /// Start navigation with enhanced 3D camera following
  Future<void> startNavigationCamera(NavigationSession session) async {
    if (!_isInitialized || _mapController == null) {
      debugPrint('⚠️ [3D-CAMERA] Camera service not initialized, cannot start 3D navigation camera');
      debugPrint('⚠️ [3D-CAMERA] Initialized: $_isInitialized, Map Controller: ${_mapController != null}');
      throw Exception('Camera service not initialized');
    }
    
    debugPrint('📹 [3D-CAMERA] Starting enhanced navigation camera for session: ${session.id}');
    
    _currentSession = session;
    _isFollowingLocation = true;
    
    // Set initial camera position with 3D perspective
    await _setInitialCameraPosition(session.origin);
    
    // Start location-based camera following
    await _startLocationBasedCameraFollowing();
  }
  
  /// Stop navigation camera
  Future<void> stopNavigationCamera() async {
    debugPrint('📹 [3D-CAMERA] Stopping enhanced navigation camera');
    
    _locationSubscription?.cancel();
    _smoothingTimer?.cancel();
    _currentSession = null;
    _isFollowingLocation = false;
    _isAnimating = false;
  }
  
  /// Update camera for navigation instruction with smooth transitions
  Future<void> updateCameraForInstruction(NavigationInstruction instruction) async {
    if (!_isInitialized || _mapController == null || !_isFollowingLocation) return;
    
    debugPrint('📹 [3D-CAMERA] Updating camera for instruction: ${instruction.text}');
    
    // Calculate optimal bearing for instruction
    final bearing = await _calculateOptimalBearing(instruction);
    
    // Calculate speed-based zoom level
    final zoom = _calculateSpeedBasedZoom(instruction);
    
    // Update target values for smooth interpolation
    _targetBearing = bearing;
    _targetZoom = zoom;
    
    debugPrint('📹 [3D-CAMERA] Target bearing: ${bearing.toStringAsFixed(1)}°, zoom: ${zoom.toStringAsFixed(1)}');
  }
  
  /// Set initial camera position with optimal 3D perspective
  Future<void> _setInitialCameraPosition(LatLng origin) async {
    if (_mapController == null) return;
    
    final initialPosition = CameraPosition(
      target: origin,
      zoom: _defaultNavigationZoom,
      bearing: 0.0,
      tilt: _navigationTilt,
    );
    
    _lastCameraPosition = initialPosition;
    _currentBearing = 0.0;
    _targetBearing = 0.0;
    _currentZoom = _defaultNavigationZoom;
    _targetZoom = _defaultNavigationZoom;
    
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(initialPosition),
    );
    
    debugPrint('📹 [3D-CAMERA] Set initial camera position at ${origin.latitude.toStringAsFixed(6)}, ${origin.longitude.toStringAsFixed(6)}');
  }
  
  /// Start location-based camera following with smooth updates
  Future<void> _startLocationBasedCameraFollowing() async {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // Update every 3 meters for smooth following
      ),
    ).listen(
      _handleLocationUpdate,
      onError: (error) {
        debugPrint('❌ [3D-CAMERA] Location stream error: $error');
      },
    );
  }
  
  /// Handle location updates for camera following
  Future<void> _handleLocationUpdate(Position position) async {
    if (!_isFollowingLocation || _mapController == null || _currentSession == null) return;
    
    final currentLocation = LatLng(position.latitude, position.longitude);
    
    // Calculate bearing to next navigation point
    final bearing = await _calculateNavigationBearing(currentLocation, position);
    
    // Calculate speed-based zoom
    final zoom = _calculateSpeedBasedZoomFromPosition(position);
    
    // Update target values for smooth interpolation
    _targetBearing = bearing;
    _targetZoom = zoom;
    
    // Update target position (will be smoothly interpolated)
    _updateTargetPosition(currentLocation);
  }
  
  /// Start smooth camera updates with interpolation
  void _startSmoothCameraUpdates() {
    _smoothingTimer = Timer.periodic(_smoothingInterval, (_) {
      _updateCameraSmooth();
    });
  }
  
  /// Update camera with smooth interpolation
  Future<void> _updateCameraSmooth() async {
    if (!_isFollowingLocation || _mapController == null || _isAnimating) return;
    
    // Smooth bearing interpolation
    final bearingDiff = _calculateBearingDifference(_currentBearing, _targetBearing);
    if (bearingDiff.abs() > _bearingThreshold) {
      _currentBearing = _interpolateBearing(_currentBearing, _targetBearing, _bearingSmoothing);
    }
    
    // Smooth zoom interpolation
    final zoomDiff = (_targetZoom - _currentZoom).abs();
    if (zoomDiff > 0.1) {
      _currentZoom = _interpolateValue(_currentZoom, _targetZoom, _zoomSmoothing);
    }
    
    // Update camera if significant changes
    if (bearingDiff.abs() > _bearingThreshold || zoomDiff > 0.1) {
      await _applySmoothCameraUpdate();
    }
  }
  
  /// Apply smooth camera update
  Future<void> _applySmoothCameraUpdate() async {
    if (_mapController == null || _lastCameraPosition == null) return;
    
    final newPosition = CameraPosition(
      target: _lastCameraPosition!.target,
      zoom: _currentZoom,
      bearing: _currentBearing,
      tilt: _navigationTilt,
    );
    
    _isAnimating = true;
    
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(newPosition),
      );
      _lastCameraPosition = newPosition;
    } catch (e) {
      debugPrint('❌ [3D-CAMERA] Error updating camera: $e');
    } finally {
      _isAnimating = false;
    }
  }
  
  /// Calculate optimal bearing for navigation instruction
  Future<double> _calculateOptimalBearing(NavigationInstruction instruction) async {
    if (_currentSession == null) return 0.0;

    try {
      final route = _currentSession!.route;
      final instructions = route.instructions;
      final currentIndex = instructions.indexOf(instruction);

      // Calculate bearing to next instruction
      if (currentIndex >= 0 && currentIndex < instructions.length - 1) {
        final nextInstruction = instructions[currentIndex + 1];
        return _calculateBearing(instruction.location, nextInstruction.location);
      }

      // Calculate bearing to destination
      return _calculateBearing(instruction.location, _currentSession!.destination);
    } catch (e) {
      debugPrint('❌ [3D-CAMERA] Error calculating optimal bearing: $e');
      return 0.0;
    }
  }
  
  /// Calculate navigation bearing from current location
  Future<double> _calculateNavigationBearing(LatLng currentLocation, Position position) async {
    if (_currentSession == null) return 0.0;
    
    try {
      // Use GPS heading if available and reliable
      if (position.heading >= 0 && position.speed > 2.0) { // 2 m/s minimum for reliable heading
        return position.heading;
      }
      
      // Calculate bearing to next navigation point
      final route = _currentSession!.route;
      final instructions = route.instructions;
      
      if (_currentSession!.currentInstructionIndex < instructions.length) {
        final nextInstruction = instructions[_currentSession!.currentInstructionIndex];
        return _calculateBearing(currentLocation, nextInstruction.location);
      }
      
      // Calculate bearing to destination
      return _calculateBearing(currentLocation, _currentSession!.destination);
    } catch (e) {
      debugPrint('❌ [3D-CAMERA] Error calculating navigation bearing: $e');
      return _currentBearing; // Keep current bearing on error
    }
  }
  
  /// Calculate speed-based zoom level for instruction
  double _calculateSpeedBasedZoom(NavigationInstruction instruction) {
    // Default navigation zoom
    return _defaultNavigationZoom;
  }
  
  /// Calculate speed-based zoom level from position
  double _calculateSpeedBasedZoomFromPosition(Position position) {
    final speedKmh = position.speed * 3.6; // Convert m/s to km/h
    
    // Adjust zoom based on speed for better navigation experience
    if (speedKmh < 10) {
      return 19.0; // Closer zoom for slow speeds (walking/parking)
    } else if (speedKmh < 30) {
      return 18.5; // Medium zoom for city driving
    } else if (speedKmh < 60) {
      return 18.0; // Standard zoom for normal driving
    } else {
      return 17.5; // Wider zoom for highway driving
    }
  }
  
  /// Calculate bearing between two points
  double _calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * (pi / 180);
    final startLng = start.longitude * (pi / 180);
    final endLat = end.latitude * (pi / 180);
    final endLng = end.longitude * (pi / 180);
    
    final dLng = endLng - startLng;
    
    final y = sin(dLng) * cos(endLat);
    final x = cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);
    
    final bearing = atan2(y, x) * (180 / pi);
    return (bearing + 360) % 360;
  }
  
  /// Calculate bearing difference considering circular nature
  double _calculateBearingDifference(double current, double target) {
    double diff = target - current;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }
  
  /// Interpolate bearing values considering circular nature
  double _interpolateBearing(double current, double target, double factor) {
    final diff = _calculateBearingDifference(current, target);
    final newBearing = current + (diff * factor);
    return (newBearing + 360) % 360;
  }
  
  /// Interpolate numeric values
  double _interpolateValue(double current, double target, double factor) {
    return current + ((target - current) * factor);
  }
  
  /// Update target position for smooth following
  void _updateTargetPosition(LatLng newTarget) {
    if (_lastCameraPosition != null) {
      _lastCameraPosition = CameraPosition(
        target: newTarget,
        zoom: _lastCameraPosition!.zoom,
        bearing: _lastCameraPosition!.bearing,
        tilt: _lastCameraPosition!.tilt,
      );
    }
  }
  
  /// Enable/disable location following
  void setLocationFollowing(bool enabled) {
    _isFollowingLocation = enabled;
    debugPrint('📹 [3D-CAMERA] Location following ${enabled ? 'enabled' : 'disabled'}');
  }
  
  /// Check if camera is following location
  bool get isFollowingLocation => _isFollowingLocation;
  
  /// Get current camera bearing
  double get currentBearing => _currentBearing;
  
  /// Get current camera zoom
  double get currentZoom => _currentZoom;
  
  /// Dispose resources
  Future<void> dispose() async {
    debugPrint('📹 [3D-CAMERA] Disposing enhanced 3D navigation camera service');
    
    await stopNavigationCamera();
    _smoothingTimer?.cancel();
    _mapController = null;
    _isInitialized = false;
  }
}
