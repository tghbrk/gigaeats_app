import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'route_cache_service.dart';

/// Enhanced route information model with detailed navigation data
class DetailedRouteInfo {
  final double distance; // in kilometers
  final int duration; // in minutes
  final List<LatLng> polylinePoints;
  final String distanceText;
  final String durationText;
  final List<RouteStep> steps;
  final List<ElevationPoint> elevationProfile;
  final String? trafficCondition;
  final DateTime? estimatedArrival;
  final String? warnings;
  final LatLng origin;
  final LatLng destination;

  const DetailedRouteInfo({
    required this.distance,
    required this.duration,
    required this.polylinePoints,
    required this.distanceText,
    required this.durationText,
    required this.steps,
    required this.elevationProfile,
    this.trafficCondition,
    this.estimatedArrival,
    this.warnings,
    required this.origin,
    required this.destination,
  });

  /// Get summary of first few key turns for preview
  List<RouteStep> get keyTurns {
    return steps.where((step) => 
      step.maneuver != 'straight' && 
      step.maneuver != 'continue'
    ).take(4).toList();
  }

  /// Check if route has significant elevation changes
  bool get hasElevationChanges {
    if (elevationProfile.length < 2) return false;
    final minElevation = elevationProfile.map((p) => p.elevation).reduce(min);
    final maxElevation = elevationProfile.map((p) => p.elevation).reduce(max);
    return (maxElevation - minElevation) > 50; // 50 meters threshold
  }

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'duration': duration,
      'polylinePoints': polylinePoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'distanceText': distanceText,
      'durationText': durationText,
      'steps': steps.map((s) => s.toJson()).toList(),
      'elevationProfile': elevationProfile.map((e) => e.toJson()).toList(),
      'trafficCondition': trafficCondition,
      'estimatedArrival': estimatedArrival?.toIso8601String(),
      'warnings': warnings,
      'origin': {'lat': origin.latitude, 'lng': origin.longitude},
      'destination': {'lat': destination.latitude, 'lng': destination.longitude},
    };
  }

  /// Create from JSON for caching
  factory DetailedRouteInfo.fromJson(Map<String, dynamic> json) {
    return DetailedRouteInfo(
      distance: (json['distance'] as num).toDouble(),
      duration: json['duration'] as int,
      polylinePoints: (json['polylinePoints'] as List<dynamic>)
          .map((p) => LatLng(p['lat'] as double, p['lng'] as double))
          .toList(),
      distanceText: json['distanceText'] as String,
      durationText: json['durationText'] as String,
      steps: (json['steps'] as List<dynamic>)
          .map((s) => RouteStep.fromJson(s as Map<String, dynamic>))
          .toList(),
      elevationProfile: (json['elevationProfile'] as List<dynamic>)
          .map((e) => ElevationPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      trafficCondition: json['trafficCondition'] as String?,
      estimatedArrival: json['estimatedArrival'] != null
          ? DateTime.parse(json['estimatedArrival'] as String)
          : null,
      warnings: json['warnings'] as String?,
      origin: LatLng(
        json['origin']['lat'] as double,
        json['origin']['lng'] as double,
      ),
      destination: LatLng(
        json['destination']['lat'] as double,
        json['destination']['lng'] as double,
      ),
    );
  }
}

/// Individual route step for turn-by-turn directions
class RouteStep {
  final String instruction;
  final double distance; // in kilometers
  final int duration; // in minutes
  final LatLng startLocation;
  final LatLng endLocation;
  final String maneuver; // turn-left, turn-right, straight, etc.
  final String? roadName;

  const RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.maneuver,
    this.roadName,
  });

  String get formattedInstruction {
    final distanceStr = distance < 1
        ? '${(distance * 1000).round()}m'
        : '${distance.toStringAsFixed(1)}km';
    return '$instruction ($distanceStr)';
  }

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'instruction': instruction,
      'distance': distance,
      'duration': duration,
      'startLocation': {'lat': startLocation.latitude, 'lng': startLocation.longitude},
      'endLocation': {'lat': endLocation.latitude, 'lng': endLocation.longitude},
      'maneuver': maneuver,
      'roadName': roadName,
    };
  }

  /// Create from JSON for caching
  factory RouteStep.fromJson(Map<String, dynamic> json) {
    return RouteStep(
      instruction: json['instruction'] as String,
      distance: (json['distance'] as num).toDouble(),
      duration: json['duration'] as int,
      startLocation: LatLng(
        json['startLocation']['lat'] as double,
        json['startLocation']['lng'] as double,
      ),
      endLocation: LatLng(
        json['endLocation']['lat'] as double,
        json['endLocation']['lng'] as double,
      ),
      maneuver: json['maneuver'] as String,
      roadName: json['roadName'] as String?,
    );
  }
}

/// Elevation point for route profile
class ElevationPoint {
  final double distance; // distance from start in kilometers
  final double elevation; // elevation in meters
  final LatLng location;

  const ElevationPoint({
    required this.distance,
    required this.elevation,
    required this.location,
  });

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'elevation': elevation,
      'location': {'lat': location.latitude, 'lng': location.longitude},
    };
  }

  /// Create from JSON for caching
  factory ElevationPoint.fromJson(Map<String, dynamic> json) {
    return ElevationPoint(
      distance: (json['distance'] as num).toDouble(),
      elevation: (json['elevation'] as num).toDouble(),
      location: LatLng(
        json['location']['lat'] as double,
        json['location']['lng'] as double,
      ),
    );
  }
}

/// Enhanced service for calculating detailed routes and directions
class EnhancedRouteService {
  static const String _googleDirectionsBaseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String _googleElevationBaseUrl = 'https://maps.googleapis.com/maps/api/elevation/json';

  /// Calculate route with automatic caching integration
  static Future<DetailedRouteInfo?> calculateRouteWithCache({
    required LatLng origin,
    required LatLng destination,
    String? googleApiKey,
    String mode = 'driving',
    bool includeTraffic = true,
    bool includeElevation = true,
    bool useCache = true,
    String? routeId,
  }) async {
    try {
      // Check cache first if enabled
      if (useCache) {
        final cachedRoute = await RouteCacheService.getCachedRoute(
          origin: origin,
          destination: destination,
          routeId: routeId,
        );

        if (cachedRoute != null) {
          debugPrint('🗺️ EnhancedRouteService: Using cached route');
          return cachedRoute;
        }
      }

      // Calculate new route
      final routeInfo = await calculateDetailedRoute(
        origin: origin,
        destination: destination,
        googleApiKey: googleApiKey,
        mode: mode,
        includeTraffic: includeTraffic,
        includeElevation: includeElevation,
      );

      // Cache the result if successful and caching is enabled
      if (routeInfo != null && useCache) {
        await RouteCacheService.cacheRoute(
          origin: origin,
          destination: destination,
          routeInfo: routeInfo,
          routeId: routeId,
        );
      }

      return routeInfo;
    } catch (e) {
      debugPrint('🗺️ EnhancedRouteService: Error in calculateRouteWithCache: $e');
      return null;
    }
  }
  
  /// Calculate detailed route with turn-by-turn directions and elevation
  static Future<DetailedRouteInfo?> calculateDetailedRoute({
    required LatLng origin,
    required LatLng destination,
    String? googleApiKey,
    String mode = 'driving',
    bool includeTraffic = true,
    bool includeElevation = true,
  }) async {
    try {
      debugPrint('🗺️ EnhancedRouteService: Calculating detailed route from ${origin.latitude},${origin.longitude} to ${destination.latitude},${destination.longitude}');
      
      // If no API key provided, use simplified calculation
      if (googleApiKey == null || googleApiKey.isEmpty) {
        return await _calculateSimplifiedRoute(origin, destination, mode);
      }
      
      // Use Google Directions API for detailed route
      final directionsData = await _getDirectionsFromGoogle(
        origin, destination, googleApiKey, mode, includeTraffic
      );
      
      if (directionsData == null) {
        return await _calculateSimplifiedRoute(origin, destination, mode);
      }
      
      // Parse route data
      final route = directionsData['routes'][0];
      final leg = route['legs'][0];
      
      final distance = (leg['distance']['value'] as int) / 1000.0; // Convert to km
      final duration = (leg['duration']['value'] as int) ~/ 60; // Convert to minutes
      
      // Parse steps
      final steps = await _parseRouteSteps(leg['steps']);
      
      // Decode polyline
      final polylinePoints = _decodePolyline(route['overview_polyline']['points']);
      
      // Get elevation profile if requested
      List<ElevationPoint> elevationProfile = [];
      if (includeElevation && polylinePoints.isNotEmpty) {
        elevationProfile = await _getElevationProfile(polylinePoints, googleApiKey);
      }
      
      // Calculate ETA
      final estimatedArrival = DateTime.now().add(Duration(minutes: duration));
      
      // Check for traffic conditions
      String? trafficCondition;
      if (includeTraffic && leg.containsKey('duration_in_traffic')) {
        final trafficDuration = (leg['duration_in_traffic']['value'] as int) ~/ 60;
        if (trafficDuration > duration * 1.2) {
          trafficCondition = 'Heavy traffic';
        } else if (trafficDuration > duration * 1.1) {
          trafficCondition = 'Moderate traffic';
        } else {
          trafficCondition = 'Light traffic';
        }
      }
      
      return DetailedRouteInfo(
        distance: distance,
        duration: duration,
        polylinePoints: polylinePoints,
        distanceText: _formatDistance(distance),
        durationText: _formatDuration(duration),
        steps: steps,
        elevationProfile: elevationProfile,
        trafficCondition: trafficCondition,
        estimatedArrival: estimatedArrival,
        origin: origin,
        destination: destination,
      );
      
    } catch (e) {
      debugPrint('🗺️ EnhancedRouteService: Error calculating detailed route: $e');
      return await _calculateSimplifiedRoute(origin, destination, mode);
    }
  }
  
  /// Get directions from Google Directions API
  static Future<Map<String, dynamic>?> _getDirectionsFromGoogle(
    LatLng origin, 
    LatLng destination, 
    String apiKey, 
    String mode,
    bool includeTraffic,
  ) async {
    try {
      final url = Uri.parse('$_googleDirectionsBaseUrl?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'mode=$mode&'
          'key=$apiKey&'
          '${includeTraffic ? 'departure_time=now&' : ''}'
          'language=en');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          return data;
        }
      }
      
      debugPrint('🗺️ EnhancedRouteService: Google Directions API error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('🗺️ EnhancedRouteService: Error calling Google Directions API: $e');
      return null;
    }
  }
  
  /// Parse route steps from Google Directions response
  static Future<List<RouteStep>> _parseRouteSteps(List<dynamic> stepsData) async {
    final steps = <RouteStep>[];
    
    for (final stepData in stepsData) {
      final instruction = _stripHtmlTags(stepData['html_instructions']);
      final distance = (stepData['distance']['value'] as int) / 1000.0;
      final duration = (stepData['duration']['value'] as int) ~/ 60;
      
      final startLat = stepData['start_location']['lat'].toDouble();
      final startLng = stepData['start_location']['lng'].toDouble();
      final endLat = stepData['end_location']['lat'].toDouble();
      final endLng = stepData['end_location']['lng'].toDouble();
      
      final maneuver = stepData['maneuver'] ?? 'straight';
      
      steps.add(RouteStep(
        instruction: instruction,
        distance: distance,
        duration: duration,
        startLocation: LatLng(startLat, startLng),
        endLocation: LatLng(endLat, endLng),
        maneuver: maneuver,
      ));
    }
    
    return steps;
  }
  
  /// Get elevation profile for route points
  static Future<List<ElevationPoint>> _getElevationProfile(
    List<LatLng> routePoints, 
    String apiKey,
  ) async {
    try {
      // Sample points along the route (max 512 points for Google API)
      final sampledPoints = _sampleRoutePoints(routePoints, 50);
      
      final locations = sampledPoints
          .map((point) => '${point.latitude},${point.longitude}')
          .join('|');
      
      final url = Uri.parse('$_googleElevationBaseUrl?'
          'locations=$locations&'
          'key=$apiKey');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final elevationPoints = <ElevationPoint>[];
          double cumulativeDistance = 0;
          
          for (int i = 0; i < data['results'].length; i++) {
            final result = data['results'][i];
            final elevation = result['elevation'].toDouble();
            final location = LatLng(
              result['location']['lat'].toDouble(),
              result['location']['lng'].toDouble(),
            );
            
            if (i > 0) {
              cumulativeDistance += _calculateDistance(
                elevationPoints[i - 1].location,
                location,
              );
            }
            
            elevationPoints.add(ElevationPoint(
              distance: cumulativeDistance,
              elevation: elevation,
              location: location,
            ));
          }
          
          return elevationPoints;
        }
      }
    } catch (e) {
      debugPrint('🗺️ EnhancedRouteService: Error getting elevation profile: $e');
    }
    
    return [];
  }

  /// Calculate simplified route when Google API is not available
  static Future<DetailedRouteInfo> _calculateSimplifiedRoute(
    LatLng origin,
    LatLng destination,
    String mode,
  ) async {
    final distance = _calculateDistance(origin, destination);
    final duration = _estimateDuration(distance, mode);
    final polylinePoints = _createSimplePolyline(origin, destination);

    // Create simplified steps
    final steps = [
      RouteStep(
        instruction: 'Head towards destination',
        distance: distance * 0.8,
        duration: (duration * 0.8).round(),
        startLocation: origin,
        endLocation: LatLng(
          origin.latitude + (destination.latitude - origin.latitude) * 0.8,
          origin.longitude + (destination.longitude - origin.longitude) * 0.8,
        ),
        maneuver: 'straight',
      ),
      RouteStep(
        instruction: 'Arrive at destination',
        distance: distance * 0.2,
        duration: (duration * 0.2).round(),
        startLocation: LatLng(
          origin.latitude + (destination.latitude - origin.latitude) * 0.8,
          origin.longitude + (destination.longitude - origin.longitude) * 0.8,
        ),
        endLocation: destination,
        maneuver: 'straight',
      ),
    ];

    return DetailedRouteInfo(
      distance: distance,
      duration: duration,
      polylinePoints: polylinePoints,
      distanceText: _formatDistance(distance),
      durationText: _formatDuration(duration),
      steps: steps,
      elevationProfile: [],
      estimatedArrival: DateTime.now().add(Duration(minutes: duration)),
      origin: origin,
      destination: destination,
    );
  }

  /// Sample points along route for elevation profile
  static List<LatLng> _sampleRoutePoints(List<LatLng> points, int maxSamples) {
    if (points.length <= maxSamples) return points;

    final sampledPoints = <LatLng>[];
    final step = points.length / maxSamples;

    for (int i = 0; i < maxSamples; i++) {
      final index = (i * step).round();
      if (index < points.length) {
        sampledPoints.add(points[index]);
      }
    }

    return sampledPoints;
  }

  /// Strip HTML tags from instruction text
  static String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Decode Google polyline string to LatLng points
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  /// Calculate distance between two points using Haversine formula
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double lat1Rad = point1.latitude * pi / 180;
    final double lat2Rad = point2.latitude * pi / 180;
    final double deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final double deltaLngRad = (point2.longitude - point1.longitude) * pi / 180;

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Create simple polyline between two points
  static List<LatLng> _createSimplePolyline(LatLng origin, LatLng destination) {
    return [origin, destination];
  }

  /// Estimate duration based on distance and mode
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
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      return '${hours}h ${minutes}m';
    }
  }
}
