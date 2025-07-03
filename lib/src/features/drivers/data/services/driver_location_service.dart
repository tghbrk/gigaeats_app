import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

/// Service for driver location tracking and management
/// Handles GPS tracking, location updates, and location history
class DriverLocationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  StreamSubscription<Position>? _locationSubscription;
  Timer? _locationUpdateTimer;
  String? _currentDriverId;
  String? _currentOrderId;
  bool _isTracking = false;

  /// Check if location services are enabled and permissions are granted
  Future<bool> checkLocationPermissions() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('DriverLocationService: Location services are disabled');
        return false;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('DriverLocationService: Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('DriverLocationService: Location permissions are permanently denied');
        return false;
      }

      debugPrint('DriverLocationService: Location permissions granted');
      return true;
    } catch (e) {
      debugPrint('DriverLocationService: Error checking location permissions: $e');
      return false;
    }
  }

  /// Start tracking driver location for a specific order
  Future<bool> startLocationTracking(String driverId, String orderId, {int intervalSeconds = 30}) async {
    try {
      debugPrint('DriverLocationService: Starting location tracking for driver: $driverId, order: $orderId');

      // Check permissions first
      if (!await checkLocationPermissions()) {
        throw Exception('Location permissions not granted');
      }

      // Stop any existing tracking
      await stopLocationTracking();

      _currentDriverId = driverId;
      _currentOrderId = orderId;
      _isTracking = true;

      // Start periodic location updates
      _locationUpdateTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
        await _updateCurrentLocation();
      });

      // Also start continuous location stream for more accurate tracking
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(
        (Position position) async {
          await _handleLocationUpdate(position);
        },
        onError: (error) {
          debugPrint('DriverLocationService: Location stream error: $error');
        },
      );

      debugPrint('DriverLocationService: Location tracking started successfully');
      return true;
    } catch (e) {
      debugPrint('DriverLocationService: Error starting location tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    try {
      debugPrint('DriverLocationService: Stopping location tracking');

      _isTracking = false;
      _currentDriverId = null;
      _currentOrderId = null;

      // Cancel location subscription
      await _locationSubscription?.cancel();
      _locationSubscription = null;

      // Cancel timer
      _locationUpdateTimer?.cancel();
      _locationUpdateTimer = null;

      debugPrint('DriverLocationService: Location tracking stopped');
    } catch (e) {
      debugPrint('DriverLocationService: Error stopping location tracking: $e');
    }
  }

  /// Update current location manually
  Future<bool> updateCurrentLocation(String driverId, {String? orderId}) async {
    try {
      debugPrint('DriverLocationService: Manual location update for driver: $driverId');

      if (!await checkLocationPermissions()) {
        throw Exception('Location permissions not granted');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return await _saveLocationToDatabase(
        driverId: driverId,
        orderId: orderId,
        position: position,
      );
    } catch (e) {
      debugPrint('DriverLocationService: Error updating current location: $e');
      return false;
    }
  }

  /// Handle location update from stream
  Future<void> _handleLocationUpdate(Position position) async {
    if (!_isTracking || _currentDriverId == null) return;

    await _saveLocationToDatabase(
      driverId: _currentDriverId!,
      orderId: _currentOrderId,
      position: position,
    );
  }

  /// Update current location using timer
  Future<void> _updateCurrentLocation() async {
    if (!_isTracking || _currentDriverId == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _saveLocationToDatabase(
        driverId: _currentDriverId!,
        orderId: _currentOrderId,
        position: position,
      );
    } catch (e) {
      debugPrint('DriverLocationService: Error in timer location update: $e');
    }
  }

  /// Save location data to database
  Future<bool> _saveLocationToDatabase({
    required String driverId,
    String? orderId,
    required Position position,
  }) async {
    try {
      // Insert into delivery_tracking table if order is specified
      if (orderId != null) {
        await _supabase.from('delivery_tracking').insert({
          'driver_id': driverId,
          'order_id': orderId,
          'location': 'POINT(${position.longitude} ${position.latitude})',
          'speed': position.speed,
          'heading': position.heading,
          'accuracy': position.accuracy,
          'recorded_at': DateTime.now().toIso8601String(),
        });
      }

      // Update driver's last known location
      await _supabase.from('drivers').update({
        'last_location': 'POINT(${position.longitude} ${position.latitude})',
        'last_seen': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', driverId);

      debugPrint('DriverLocationService: Location saved successfully - Lat: ${position.latitude}, Lng: ${position.longitude}');
      return true;
    } catch (e) {
      debugPrint('DriverLocationService: Error saving location to database: $e');
      return false;
    }
  }

  /// Get driver's location history for a specific order
  Future<List<Map<String, dynamic>>> getOrderLocationHistory(String orderId) async {
    try {
      debugPrint('DriverLocationService: Getting location history for order: $orderId');

      final response = await _supabase
          .from('delivery_tracking')
          .select('''
            id,
            driver_id,
            location,
            speed,
            heading,
            accuracy,
            recorded_at
          ''')
          .eq('order_id', orderId)
          .order('recorded_at', ascending: true);

      debugPrint('DriverLocationService: Found ${response.length} location records');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('DriverLocationService: Error getting location history: $e');
      return [];
    }
  }

  /// Get driver's location history for a specific time period
  Future<List<Map<String, dynamic>>> getDriverLocationHistory(
    String driverId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      debugPrint('DriverLocationService: Getting location history for driver: $driverId');

      var query = _supabase
          .from('delivery_tracking')
          .select('''
            id,
            order_id,
            location,
            speed,
            heading,
            accuracy,
            recorded_at
          ''')
          .eq('driver_id', driverId);

      if (startDate != null) {
        query = query.gte('recorded_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('recorded_at', endDate.toIso8601String());
      }

      final response = await query
          .order('recorded_at', ascending: false)
          .limit(limit);

      debugPrint('DriverLocationService: Found ${response.length} location records for driver');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('DriverLocationService: Error getting driver location history: $e');
      return [];
    }
  }

  /// Get driver's current location
  Future<Map<String, dynamic>?> getDriverCurrentLocation(String driverId) async {
    try {
      debugPrint('DriverLocationService: Getting current location for driver: $driverId');

      final response = await _supabase
          .from('drivers')
          .select('last_location, last_seen')
          .eq('id', driverId)
          .single();

      if (response['last_location'] != null) {
        return {
          'location': response['last_location'],
          'last_seen': response['last_seen'],
        };
      }

      return null;
    } catch (e) {
      debugPrint('DriverLocationService: Error getting current location: $e');
      return null;
    }
  }

  /// Calculate distance between two points
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Calculate estimated arrival time based on current location and destination
  Future<Duration?> calculateEstimatedArrival(
    String driverId,
    double destinationLat,
    double destinationLng, {
    double averageSpeedKmh = 30.0,
  }) async {
    try {
      final currentLocation = await getDriverCurrentLocation(driverId);
      if (currentLocation == null) return null;

      // Parse location from PostGIS format (simplified)
      // In a real implementation, you'd properly parse the POINT geometry
      // For now, we'll use a placeholder calculation

      // Get recent location data to calculate average speed
      final recentLocations = await getDriverLocationHistory(
        driverId,
        startDate: DateTime.now().subtract(const Duration(minutes: 10)),
        limit: 10,
      );

      if (recentLocations.length >= 2) {
        // Calculate actual average speed from recent locations
        double totalDistance = 0;
        Duration totalTime = Duration.zero;

        for (int i = 1; i < recentLocations.length; i++) {
          final prev = recentLocations[i - 1];
          final curr = recentLocations[i];

          // Parse timestamps
          final prevTime = DateTime.parse(prev['recorded_at']);
          final currTime = DateTime.parse(curr['recorded_at']);
          final timeDiff = currTime.difference(prevTime);

          if (timeDiff.inSeconds > 0) {
            totalTime += timeDiff;
            // Add distance calculation here when location parsing is implemented
          }
        }

        if (totalTime.inSeconds > 0) {
          // Use calculated speed if available
          averageSpeedKmh = (totalDistance / 1000) / (totalTime.inHours);
        }
      }

      // For now, use a simplified distance calculation
      // In production, integrate with a routing service like Google Maps
      const double estimatedDistanceKm = 5.0; // Placeholder
      final estimatedHours = estimatedDistanceKm / averageSpeedKmh;
      
      return Duration(minutes: (estimatedHours * 60).round());
    } catch (e) {
      debugPrint('DriverLocationService: Error calculating estimated arrival: $e');
      return null;
    }
  }

  /// Check if driver is currently tracking location
  bool get isTracking => _isTracking;

  /// Get current tracking driver ID
  String? get currentDriverId => _currentDriverId;

  /// Get current tracking order ID
  String? get currentOrderId => _currentOrderId;

  /// Dispose the service and clean up resources
  Future<void> dispose() async {
    await stopLocationTracking();
  }
}
