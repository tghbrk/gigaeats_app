import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

/// Model for location data with accuracy information
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final String? address;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.address,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'timestamp': timestamp.toIso8601String(),
    'address': address,
  };

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
    latitude: json['latitude']?.toDouble() ?? 0.0,
    longitude: json['longitude']?.toDouble() ?? 0.0,
    accuracy: json['accuracy']?.toDouble() ?? 0.0,
    timestamp: DateTime.parse(json['timestamp']),
    address: json['address'],
  );

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, accuracy: ${accuracy}m, address: $address)';
  }
}

/// Service for handling GPS location tracking for delivery proof
class LocationService {
  static const double _requiredAccuracy = 50.0; // meters
  static const Duration _locationTimeout = Duration(seconds: 30);

  /// Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Check if precise location permission is granted
  static Future<bool> isPreciseLocationPermissionGranted() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  /// Request location permissions
  static Future<bool> requestLocationPermission() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.location,
    ].request();

    return statuses[Permission.locationWhenInUse]?.isGranted == true ||
           statuses[Permission.location]?.isGranted == true;
  }

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current location with high accuracy for delivery proof
  static Future<LocationData?> getCurrentLocation({
    bool includeAddress = true,
  }) async {
    try {
      // Check if location services are enabled
      if (!await isLocationServiceEnabled()) {
        throw LocationServiceDisabledException();
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationPermissionDeniedException('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionDeniedException('Location permissions are permanently denied');
      }

      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: _locationTimeout,
      );

      // Get address if requested
      String? address;
      if (includeAddress) {
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            address = _formatAddress(placemark);
          }
        } catch (e) {
          // Address lookup failed, but location is still valid
          debugPrint('Address lookup failed: $e');
        }
      }

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
        address: address,
      );
    } catch (e) {
      debugPrint('Failed to get current location: $e');
      return null;
    }
  }

  /// Validate location accuracy for delivery proof
  static bool isLocationAccurate(LocationData location) {
    return location.accuracy <= _requiredAccuracy;
  }

  /// Get location with accuracy validation
  static Future<LocationData?> getAccurateLocation({
    int maxRetries = 3,
    bool includeAddress = true,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final location = await getCurrentLocation(includeAddress: includeAddress);
      
      if (location != null && isLocationAccurate(location)) {
        return location;
      }
      
      if (attempt < maxRetries) {
        // Wait before retry
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    
    return null;
  }

  /// Format placemark into readable address
  static String _formatAddress(Placemark placemark) {
    final parts = <String>[];
    
    if (placemark.street?.isNotEmpty == true) {
      parts.add(placemark.street!);
    }
    if (placemark.locality?.isNotEmpty == true) {
      parts.add(placemark.locality!);
    }
    if (placemark.administrativeArea?.isNotEmpty == true) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.postalCode?.isNotEmpty == true) {
      parts.add(placemark.postalCode!);
    }
    if (placemark.country?.isNotEmpty == true) {
      parts.add(placemark.country!);
    }
    
    return parts.join(', ');
  }

  /// Show location permission denied dialog
  static void showLocationPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to capture delivery proof with GPS coordinates. '
          'Please grant location permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  /// Show location services disabled dialog
  static void showLocationServicesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Please enable location services in your device settings to capture delivery proof with GPS coordinates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openLocationSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  /// Handle location permission request with user feedback
  static Future<bool> handleLocationPermissionRequest(BuildContext context) async {
    // Check if location services are enabled
    if (!await isLocationServiceEnabled()) {
      showLocationServicesDialog(context);
      return false;
    }

    // Check if permissions are already granted
    if (await isLocationPermissionGranted()) {
      return true;
    }

    // Request permissions
    final granted = await requestLocationPermission();
    
    if (!granted) {
      showLocationPermissionDialog(context);
      return false;
    }

    return true;
  }

  /// Calculate distance between two points in meters
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Get location status text for debugging
  static Future<String> getLocationStatusText() async {
    final serviceEnabled = await isLocationServiceEnabled();
    final permissionGranted = await isLocationPermissionGranted();
    final precisePermissionGranted = await isPreciseLocationPermissionGranted();
    
    return 'Services: $serviceEnabled, Permission: $permissionGranted, Precise: $precisePermissionGranted';
  }
}

/// Custom exceptions for location service
class LocationServiceDisabledException implements Exception {
  final String message;
  LocationServiceDisabledException([this.message = 'Location services are disabled']);
  
  @override
  String toString() => 'LocationServiceDisabledException: $message';
}

class LocationPermissionDeniedException implements Exception {
  final String message;
  LocationPermissionDeniedException([this.message = 'Location permission denied']);
  
  @override
  String toString() => 'LocationPermissionDeniedException: $message';
}
