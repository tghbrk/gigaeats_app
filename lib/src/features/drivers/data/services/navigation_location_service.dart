import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/services/location_service.dart';

/// Specialized location service for navigation with enhanced accuracy and validation
class NavigationLocationService {
  static const double _navigationAccuracyThreshold = 20.0; // meters
  static const Duration _locationTimeout = Duration(seconds: 45);
  static const int _maxRetryAttempts = 5;
  
  /// Get current location optimized for navigation with enhanced accuracy
  static Future<NavigationLocationResult> getCurrentLocationForNavigation({
    bool requireHighAccuracy = true,
    int maxRetries = _maxRetryAttempts,
  }) async {
    try {
      debugPrint('🗺️ NavigationLocationService: Getting current location for navigation');
      
      // Check location services and permissions
      final permissionResult = await _checkLocationRequirements();
      if (!permissionResult.isSuccess) {
        return NavigationLocationResult.error(permissionResult.errorMessage!);
      }
      
      // Attempt to get accurate location with retries
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        debugPrint('🗺️ NavigationLocationService: Location attempt $attempt/$maxRetries');
        
        final locationResult = await _getLocationWithTimeout();
        
        if (locationResult.isSuccess) {
          final location = locationResult.location!;
          
          // Validate accuracy for navigation
          if (!requireHighAccuracy || _isAccurateEnoughForNavigation(location)) {
            debugPrint('🗺️ NavigationLocationService: Got accurate location - Lat: ${location.latitude}, Lng: ${location.longitude}, Accuracy: ${location.accuracy}m');
            return NavigationLocationResult.success(location);
          } else {
            debugPrint('🗺️ NavigationLocationService: Location accuracy insufficient (${location.accuracy}m), retrying...');
          }
        } else {
          debugPrint('🗺️ NavigationLocationService: Location attempt failed: ${locationResult.errorMessage}');
        }
        
        // Wait before retry (exponential backoff)
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
      
      return NavigationLocationResult.error('Unable to get accurate location after $maxRetries attempts');
      
    } catch (e) {
      debugPrint('🗺️ NavigationLocationService: Error getting navigation location: $e');
      return NavigationLocationResult.error('Location service error: ${e.toString()}');
    }
  }
  
  /// Check location requirements (services enabled, permissions granted)
  static Future<NavigationLocationResult> _checkLocationRequirements() async {
    try {
      // Check if location services are enabled
      if (!await LocationService.isLocationServiceEnabled()) {
        return NavigationLocationResult.error(
          'Location services are disabled. Please enable location services in your device settings.',
          errorType: NavigationLocationErrorType.serviceDisabled,
        );
      }
      
      // Check location permissions
      if (!await LocationService.isLocationPermissionGranted()) {
        final granted = await LocationService.requestLocationPermission();
        if (!granted) {
          return NavigationLocationResult.error(
            'Location permission is required for navigation. Please grant location permission in app settings.',
            errorType: NavigationLocationErrorType.permissionDenied,
          );
        }
      }
      
      return NavigationLocationResult.success(null);
    } catch (e) {
      return NavigationLocationResult.error('Error checking location requirements: ${e.toString()}');
    }
  }
  
  /// Get location with timeout handling
  static Future<NavigationLocationResult> _getLocationWithTimeout() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _locationTimeout,
        ),
      ).timeout(_locationTimeout);
      
      final location = NavigationLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
        speed: position.speed,
        heading: position.heading,
        altitude: position.altitude,
      );
      
      return NavigationLocationResult.success(location);
    } on TimeoutException {
      return NavigationLocationResult.error(
        'Location request timed out. Please ensure you have a clear view of the sky.',
        errorType: NavigationLocationErrorType.timeout,
      );
    } catch (e) {
      return NavigationLocationResult.error('Failed to get location: ${e.toString()}');
    }
  }
  
  /// Check if location accuracy is sufficient for navigation
  static bool _isAccurateEnoughForNavigation(NavigationLocation location) {
    return location.accuracy <= _navigationAccuracyThreshold;
  }
  
  /// Get location accuracy status for UI feedback
  static NavigationLocationAccuracy getLocationAccuracyStatus(double accuracy) {
    if (accuracy <= 5) {
      return NavigationLocationAccuracy.excellent;
    } else if (accuracy <= 10) {
      return NavigationLocationAccuracy.good;
    } else if (accuracy <= 20) {
      return NavigationLocationAccuracy.fair;
    } else {
      return NavigationLocationAccuracy.poor;
    }
  }
  
  /// Calculate distance between two locations in meters
  static double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }
  
  /// Calculate bearing from one location to another in degrees
  static double calculateBearing(LatLng from, LatLng to) {
    return Geolocator.bearingBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }
  
  /// Validate if current location is reasonable for starting navigation
  static Future<NavigationLocationValidation> validateLocationForNavigation(
    LatLng currentLocation,
    LatLng destination,
  ) async {
    try {
      final distance = calculateDistance(currentLocation, destination);
      
      // Check if distance is reasonable (not too far, not too close)
      if (distance > 500000) { // 500km
        return NavigationLocationValidation(
          isValid: false,
          message: 'Destination is very far (${(distance / 1000).toStringAsFixed(1)}km). Please verify the destination.',
          warningType: NavigationLocationWarningType.distanceTooFar,
        );
      }
      
      if (distance < 10) { // 10 meters
        return NavigationLocationValidation(
          isValid: true,
          message: 'You are already very close to the destination (${distance.toStringAsFixed(0)}m).',
          warningType: NavigationLocationWarningType.alreadyAtDestination,
        );
      }
      
      return NavigationLocationValidation(
        isValid: true,
        message: 'Location validated successfully. Distance to destination: ${(distance / 1000).toStringAsFixed(1)}km',
      );
      
    } catch (e) {
      return NavigationLocationValidation(
        isValid: false,
        message: 'Error validating location: ${e.toString()}',
      );
    }
  }
  
  /// Open device location settings
  static Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('🗺️ NavigationLocationService: Error opening location settings: $e');
      return false;
    }
  }
  
  /// Open app settings for location permissions
  static Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('🗺️ NavigationLocationService: Error opening app settings: $e');
      return false;
    }
  }
}

/// Enhanced location data for navigation
class NavigationLocation {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final double? speed;
  final double? heading;
  final double? altitude;

  const NavigationLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.speed,
    this.heading,
    this.altitude,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'heading': heading,
      'altitude': altitude,
    };
  }
}

/// Result wrapper for navigation location operations
class NavigationLocationResult {
  final bool isSuccess;
  final NavigationLocation? location;
  final String? errorMessage;
  final NavigationLocationErrorType? errorType;

  const NavigationLocationResult._({
    required this.isSuccess,
    this.location,
    this.errorMessage,
    this.errorType,
  });

  factory NavigationLocationResult.success(NavigationLocation? location) {
    return NavigationLocationResult._(
      isSuccess: true,
      location: location,
    );
  }

  factory NavigationLocationResult.error(
    String message, {
    NavigationLocationErrorType? errorType,
  }) {
    return NavigationLocationResult._(
      isSuccess: false,
      errorMessage: message,
      errorType: errorType,
    );
  }
}

/// Location accuracy levels for navigation
enum NavigationLocationAccuracy {
  excellent, // <= 5m
  good,      // <= 10m
  fair,      // <= 20m
  poor,      // > 20m
}

/// Error types for navigation location
enum NavigationLocationErrorType {
  serviceDisabled,
  permissionDenied,
  timeout,
  networkError,
  unknown,
}

/// Location validation result
class NavigationLocationValidation {
  final bool isValid;
  final String message;
  final NavigationLocationWarningType? warningType;

  const NavigationLocationValidation({
    required this.isValid,
    required this.message,
    this.warningType,
  });
}

/// Warning types for location validation
enum NavigationLocationWarningType {
  distanceTooFar,
  alreadyAtDestination,
  lowAccuracy,
  staleLocation,
}
