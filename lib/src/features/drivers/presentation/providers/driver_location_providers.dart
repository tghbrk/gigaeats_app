import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/services/location_tracking_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/logger.dart';


/// Location Tracking Status Provider
final locationTrackingStatusProvider = StateProvider<bool>((ref) => false);

/// Location Permissions Provider
final locationPermissionsProvider = FutureProvider<LocationPermission>((ref) async {
  return await Geolocator.checkPermission();
});

/// Driver Current Location Provider
final driverCurrentLocationProvider = StateProvider<Position?>((ref) => null);

/// Location Tracking Service Provider
final locationTrackingServiceProvider = Provider<LocationTrackingService>((ref) {
  return LocationTrackingService();
});

/// Driver Location Actions Provider
final driverLocationActionsProvider = Provider<DriverLocationActionsService>((ref) {
  return DriverLocationActionsService(ref);
});

/// Driver Location History Provider
final driverLocationHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.read(authStateProvider);
  if (authState.user == null) return [];

  // Return empty list for now - this would need to be implemented in the service
  return <Map<String, dynamic>>[];
});

/// Location Permission Status Provider
final locationPermissionStatusProvider = FutureProvider<PermissionStatus>((ref) async {
  return await Permission.location.status;
});

/// Location Service Enabled Provider
final locationServiceEnabledProvider = FutureProvider<bool>((ref) async {
  return await Geolocator.isLocationServiceEnabled();
});

/// Current Location Stream Provider
final currentLocationStreamProvider = StreamProvider<Position>((ref) {
  const locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Update every 10 meters
  );

  return Geolocator.getPositionStream(locationSettings: locationSettings);
});

/// Driver Location Actions Service Class
class DriverLocationActionsService {
  final Ref _ref;
  final AppLogger _logger = AppLogger();

  DriverLocationActionsService(this._ref);

  /// Start location tracking
  Future<bool> startLocationTracking({String? orderId, String? driverId}) async {
    try {
      _logger.info('📍 [LOCATION-ACTIONS] Starting location tracking');

      // Check permissions first
      final permission = await _ref.read(locationPermissionsProvider.future);
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _logger.warning('📍 [LOCATION-ACTIONS] Location permission denied');
        return false;
      }

      // Check if location service is enabled
      final serviceEnabled = await _ref.read(locationServiceEnabledProvider.future);
      if (!serviceEnabled) {
        _logger.warning('📍 [LOCATION-ACTIONS] Location service not enabled');
        return false;
      }

      // Start tracking if orderId and driverId are provided
      if (orderId != null && driverId != null) {
        final trackingService = _ref.read(locationTrackingServiceProvider);
        await trackingService.startTracking(orderId: orderId, driverId: driverId);
      }

      // Update status
      _ref.read(locationTrackingStatusProvider.notifier).state = true;

      _logger.info('✅ [LOCATION-ACTIONS] Location tracking started successfully');
      return true;
    } catch (e) {
      _logger.error('❌ [LOCATION-ACTIONS] Failed to start location tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  Future<bool> stopLocationTracking() async {
    try {
      _logger.info('📍 [LOCATION-ACTIONS] Stopping location tracking');

      final trackingService = _ref.read(locationTrackingServiceProvider);
      await trackingService.stopTracking();

      // Update status
      _ref.read(locationTrackingStatusProvider.notifier).state = false;

      _logger.info('✅ [LOCATION-ACTIONS] Location tracking stopped successfully');
      return true;
    } catch (e) {
      _logger.error('❌ [LOCATION-ACTIONS] Failed to stop location tracking: $e');
      return false;
    }
  }

  /// Request location permissions
  Future<bool> requestLocationPermissions() async {
    try {
      _logger.info('📍 [LOCATION-ACTIONS] Requesting location permissions');

      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.warning('📍 [LOCATION-ACTIONS] Location permission denied forever');
        return false;
      }

      final granted = permission == LocationPermission.whileInUse || 
                     permission == LocationPermission.always;

      if (granted) {
        _logger.info('✅ [LOCATION-ACTIONS] Location permissions granted');
        // Invalidate the permission provider to refresh UI
        _ref.invalidate(locationPermissionsProvider);
      } else {
        _logger.warning('📍 [LOCATION-ACTIONS] Location permissions not granted');
      }

      return granted;
    } catch (e) {
      _logger.error('❌ [LOCATION-ACTIONS] Failed to request location permissions: $e');
      return false;
    }
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      _logger.info('📍 [LOCATION-ACTIONS] Getting current location');

      // Check permissions
      final permission = await _ref.read(locationPermissionsProvider.future);
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _logger.warning('📍 [LOCATION-ACTIONS] Location permission denied');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Update current location state
      _ref.read(driverCurrentLocationProvider.notifier).state = position;

      _logger.info('✅ [LOCATION-ACTIONS] Current location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      _logger.error('❌ [LOCATION-ACTIONS] Failed to get current location: $e');
      return null;
    }
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    try {
      _logger.info('📍 [LOCATION-ACTIONS] Opening location settings');
      await Geolocator.openLocationSettings();
    } catch (e) {
      _logger.error('❌ [LOCATION-ACTIONS] Failed to open location settings: $e');
    }
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    try {
      _logger.info('📍 [LOCATION-ACTIONS] Opening app settings');
      await Geolocator.openAppSettings();
    } catch (e) {
      _logger.error('❌ [LOCATION-ACTIONS] Failed to open app settings: $e');
    }
  }

  /// Check if location tracking is available
  Future<bool> isLocationTrackingAvailable() async {
    try {
      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      // Check permissions
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      _logger.error('❌ [LOCATION-ACTIONS] Failed to check location tracking availability: $e');
      return false;
    }
  }

  /// Update location in real-time
  void startLocationUpdates() {
    _ref.listen(currentLocationStreamProvider, (previous, next) {
      next.when(
        data: (position) {
          _ref.read(driverCurrentLocationProvider.notifier).state = position;
          _logger.debug('📍 [LOCATION-ACTIONS] Location updated: ${position.latitude}, ${position.longitude}');
        },
        loading: () {
          _logger.debug('📍 [LOCATION-ACTIONS] Getting location update...');
        },
        error: (error, stack) {
          _logger.error('❌ [LOCATION-ACTIONS] Location update error: $error');
        },
      );
    });
  }

  /// Check permissions (alias for requestLocationPermissions for compatibility)
  Future<bool> checkPermissions() async {
    return await requestLocationPermissions();
  }

  /// Start tracking for a specific order
  Future<bool> startTrackingForOrder(String orderId) async {
    return await startLocationTracking(orderId: orderId);
  }

  /// Update current location (alias for getCurrentLocation for compatibility)
  Future<bool> updateCurrentLocation() async {
    final position = await getCurrentLocation();
    return position != null;
  }

  /// Stop tracking (alias for stopLocationTracking for compatibility)
  Future<void> stopTracking() async {
    await stopLocationTracking();
  }
}
