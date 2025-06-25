import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service for calculating routes and directions
class RouteService {
  /// Calculate route between two points
  /// Returns route information including distance, duration, and polyline points
  static Future<RouteInfo?> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    String? apiKey,
    String mode = 'driving',
  }) async {
    try {
      // For now, we'll use a simple calculation without Google Directions API
      // In production, you would use the actual Google Directions API with your API key
      
      final distance = _calculateDistance(origin, destination);
      final duration = _estimateDuration(distance, mode);
      final polylinePoints = _createSimplePolyline(origin, destination);
      
      return RouteInfo(
        distance: distance,
        duration: duration,
        polylinePoints: polylinePoints,
        distanceText: _formatDistance(distance),
        durationText: _formatDuration(duration),
      );
    } catch (e) {
      debugPrint('RouteService: Error calculating route: $e');
      return null;
    }
  }
  
  /// Calculate route with multiple waypoints
  static Future<RouteInfo?> calculateRouteWithWaypoints({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    String? apiKey,
    String mode = 'driving',
  }) async {
    try {
      // Simple implementation for multiple waypoints
      final allPoints = [origin, ...?waypoints, destination];
      double totalDistance = 0;
      int totalDuration = 0;
      List<LatLng> allPolylinePoints = [];
      
      for (int i = 0; i < allPoints.length - 1; i++) {
        final segmentDistance = _calculateDistance(allPoints[i], allPoints[i + 1]);
        final segmentDuration = _estimateDuration(segmentDistance, mode);
        final segmentPoints = _createSimplePolyline(allPoints[i], allPoints[i + 1]);
        
        totalDistance += segmentDistance;
        totalDuration += segmentDuration;
        allPolylinePoints.addAll(segmentPoints);
      }
      
      return RouteInfo(
        distance: totalDistance,
        duration: totalDuration,
        polylinePoints: allPolylinePoints,
        distanceText: _formatDistance(totalDistance),
        durationText: _formatDuration(totalDuration),
      );
    } catch (e) {
      debugPrint('RouteService: Error calculating route with waypoints: $e');
      return null;
    }
  }
  
  /// Calculate distance between two points using Haversine formula
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double lat1Rad = point1.latitude * (pi / 180);
    final double lat2Rad = point2.latitude * (pi / 180);
    final double deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    final double deltaLngRad = (point2.longitude - point1.longitude) * (pi / 180);
    
    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Estimate duration based on distance and mode of transport
  static int _estimateDuration(double distanceKm, String mode) {
    double speedKmh;
    
    switch (mode) {
      case 'walking':
        speedKmh = 5.0;
        break;
      case 'bicycling':
        speedKmh = 15.0;
        break;
      case 'driving':
      default:
        speedKmh = 40.0; // Average city driving speed
        break;
    }
    
    final double durationHours = distanceKm / speedKmh;
    return (durationHours * 60).round(); // Convert to minutes
  }
  
  /// Create a simple polyline between two points
  static List<LatLng> _createSimplePolyline(LatLng start, LatLng end) {
    // For a more realistic route, you would use Google Directions API
    // This creates a simple straight line with some intermediate points
    const int segments = 10;
    final List<LatLng> points = [];
    
    for (int i = 0; i <= segments; i++) {
      final double ratio = i / segments;
      final double lat = start.latitude + (end.latitude - start.latitude) * ratio;
      final double lng = start.longitude + (end.longitude - start.longitude) * ratio;
      points.add(LatLng(lat, lng));
    }
    
    return points;
  }
  
  /// Format distance for display
  static String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }
  
  /// Format duration for display
  static String _formatDuration(int durationMinutes) {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    } else {
      final int hours = durationMinutes ~/ 60;
      final int minutes = durationMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}min';
      }
    }
  }
  
  /// Get optimized route for multiple deliveries
  static Future<List<LatLng>> optimizeDeliveryRoute({
    required LatLng startLocation,
    required List<LatLng> deliveryLocations,
    LatLng? endLocation,
  }) async {
    try {
      // Simple nearest neighbor algorithm for route optimization
      // In production, you might want to use a more sophisticated algorithm
      
      final List<LatLng> optimizedRoute = [startLocation];
      final List<LatLng> remainingLocations = List.from(deliveryLocations);
      LatLng currentLocation = startLocation;
      
      while (remainingLocations.isNotEmpty) {
        // Find the nearest unvisited location
        LatLng nearestLocation = remainingLocations.first;
        double nearestDistance = _calculateDistance(currentLocation, nearestLocation);
        
        for (final location in remainingLocations) {
          final distance = _calculateDistance(currentLocation, location);
          if (distance < nearestDistance) {
            nearestDistance = distance;
            nearestLocation = location;
          }
        }
        
        optimizedRoute.add(nearestLocation);
        remainingLocations.remove(nearestLocation);
        currentLocation = nearestLocation;
      }
      
      if (endLocation != null) {
        optimizedRoute.add(endLocation);
      }
      
      return optimizedRoute;
    } catch (e) {
      debugPrint('RouteService: Error optimizing route: $e');
      return [startLocation, ...deliveryLocations, if (endLocation != null) endLocation];
    }
  }
}

/// Route information model
class RouteInfo {
  final double distance; // in kilometers
  final int duration; // in minutes
  final List<LatLng> polylinePoints;
  final String distanceText;
  final String durationText;
  
  const RouteInfo({
    required this.distance,
    required this.duration,
    required this.polylinePoints,
    required this.distanceText,
    required this.durationText,
  });
  
  @override
  String toString() {
    return 'RouteInfo(distance: $distanceText, duration: $durationText, points: ${polylinePoints.length})';
  }
}

/// Traffic conditions enum
enum TrafficCondition {
  light,
  moderate,
  heavy,
  severe,
}

/// Route optimization preferences
class RoutePreferences {
  final bool avoidTolls;
  final bool avoidHighways;
  final bool avoidFerries;
  final TrafficCondition trafficModel;
  
  const RoutePreferences({
    this.avoidTolls = false,
    this.avoidHighways = false,
    this.avoidFerries = false,
    this.trafficModel = TrafficCondition.moderate,
  });
}
