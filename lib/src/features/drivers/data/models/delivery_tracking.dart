import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'delivery_tracking.g.dart';

/// Delivery tracking model for real-time GPS tracking during deliveries
@JsonSerializable()
class DeliveryTracking extends Equatable {
  final int id;
  @JsonKey(name: 'order_id')
  final String orderId;
  @JsonKey(name: 'driver_id')
  final String driverId;
  @JsonKey(fromJson: _locationFromJson, toJson: _locationToJson)
  final TrackingLocation location;
  final double? speed; // Speed in km/h
  final double? heading; // Direction in degrees (0-360)
  final double? accuracy; // GPS accuracy in meters
  @JsonKey(name: 'recorded_at')
  final DateTime recordedAt;
  final Map<String, dynamic>? metadata; // Additional tracking data

  const DeliveryTracking({
    required this.id,
    required this.orderId,
    required this.driverId,
    required this.location,
    this.speed,
    this.heading,
    this.accuracy,
    required this.recordedAt,
    this.metadata,
  });

  factory DeliveryTracking.fromJson(Map<String, dynamic> json) => _$DeliveryTrackingFromJson(json);
  Map<String, dynamic> toJson() => _$DeliveryTrackingToJson(this);

  /// Create a new tracking point
  factory DeliveryTracking.create({
    required String orderId,
    required String driverId,
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    double? accuracy,
    Map<String, dynamic>? metadata,
  }) {
    return DeliveryTracking(
      id: 0, // Will be set by database
      orderId: orderId,
      driverId: driverId,
      location: TrackingLocation(
        latitude: latitude,
        longitude: longitude,
      ),
      speed: speed,
      heading: heading,
      accuracy: accuracy,
      recordedAt: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Distance from another tracking point in meters
  double distanceFrom(DeliveryTracking other) {
    return location.distanceFrom(other.location);
  }

  /// Speed display string
  String get speedDisplay {
    if (speed == null) return 'Unknown';
    return '${speed!.toStringAsFixed(1)} km/h';
  }

  /// Accuracy display string
  String get accuracyDisplay {
    if (accuracy == null) return 'Unknown';
    return '±${accuracy!.toStringAsFixed(1)}m';
  }

  /// Heading display string
  String get headingDisplay {
    if (heading == null) return 'Unknown';
    return '${heading!.toStringAsFixed(0)}°';
  }

  /// Cardinal direction from heading
  String get cardinalDirection {
    if (heading == null) return 'Unknown';
    
    final directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((heading! + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        driverId,
        location,
        speed,
        heading,
        accuracy,
        recordedAt,
        metadata,
      ];

  DeliveryTracking copyWith({
    int? id,
    String? orderId,
    String? driverId,
    TrackingLocation? location,
    double? speed,
    double? heading,
    double? accuracy,
    DateTime? recordedAt,
    Map<String, dynamic>? metadata,
  }) {
    return DeliveryTracking(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      driverId: driverId ?? this.driverId,
      location: location ?? this.location,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      accuracy: accuracy ?? this.accuracy,
      recordedAt: recordedAt ?? this.recordedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Location model for tracking points
@JsonSerializable()
class TrackingLocation extends Equatable {
  final double latitude;
  final double longitude;

  const TrackingLocation({
    required this.latitude,
    required this.longitude,
  });

  factory TrackingLocation.fromJson(Map<String, dynamic> json) => _$TrackingLocationFromJson(json);
  Map<String, dynamic> toJson() => _$TrackingLocationToJson(this);

  /// Create from PostGIS geometry data
  factory TrackingLocation.fromPostGIS(Map<String, dynamic> data) {
    if (data['type'] == 'Point' && data['coordinates'] is List) {
      final coordinates = data['coordinates'] as List<dynamic>;
      return TrackingLocation(
        longitude: coordinates[0].toDouble(),
        latitude: coordinates[1].toDouble(),
      );
    }
    throw ArgumentError('Invalid PostGIS Point data: $data');
  }

  /// Convert to PostGIS format
  Map<String, dynamic> toPostGIS() {
    return {
      'type': 'Point',
      'coordinates': [longitude, latitude],
    };
  }

  /// Calculate distance to another location using Haversine formula
  double distanceFrom(TrackingLocation other) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final double lat1Rad = latitude * (math.pi / 180);
    final double lat2Rad = other.latitude * (math.pi / 180);
    final double deltaLatRad = (other.latitude - latitude) * (math.pi / 180);
    final double deltaLngRad = (other.longitude - longitude) * (math.pi / 180);

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  /// Format coordinates for display
  String get displayString {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Check if location is valid (within reasonable bounds)
  bool get isValid {
    return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
  }

  /// Check if location is in Malaysia (approximate bounds)
  bool get isInMalaysia {
    return latitude >= 0.8 && latitude <= 7.4 && longitude >= 99.6 && longitude <= 119.3;
  }

  @override
  List<Object?> get props => [latitude, longitude];

  TrackingLocation copyWith({
    double? latitude,
    double? longitude,
  }) {
    return TrackingLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

/// Delivery route model for complete tracking history
@JsonSerializable()
class DeliveryRoute extends Equatable {
  @JsonKey(name: 'order_id')
  final String orderId;
  @JsonKey(name: 'driver_id')
  final String driverId;
  final List<DeliveryTracking> trackingPoints;
  @JsonKey(name: 'start_time')
  final DateTime? startTime;
  @JsonKey(name: 'end_time')
  final DateTime? endTime;
  @JsonKey(name: 'total_distance')
  final double? totalDistance; // in meters
  @JsonKey(name: 'average_speed')
  final double? averageSpeed; // in km/h

  const DeliveryRoute({
    required this.orderId,
    required this.driverId,
    required this.trackingPoints,
    this.startTime,
    this.endTime,
    this.totalDistance,
    this.averageSpeed,
  });

  factory DeliveryRoute.fromJson(Map<String, dynamic> json) => _$DeliveryRouteFromJson(json);
  Map<String, dynamic> toJson() => _$DeliveryRouteToJson(this);

  /// Create from tracking points
  factory DeliveryRoute.fromTrackingPoints({
    required String orderId,
    required String driverId,
    required List<DeliveryTracking> trackingPoints,
  }) {
    if (trackingPoints.isEmpty) {
      return DeliveryRoute(
        orderId: orderId,
        driverId: driverId,
        trackingPoints: trackingPoints,
      );
    }

    // Sort by recorded time
    final sortedPoints = List<DeliveryTracking>.from(trackingPoints)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    // Calculate total distance
    double totalDistance = 0;
    for (int i = 1; i < sortedPoints.length; i++) {
      totalDistance += sortedPoints[i].distanceFrom(sortedPoints[i - 1]);
    }

    // Calculate average speed
    final duration = sortedPoints.last.recordedAt.difference(sortedPoints.first.recordedAt);
    final averageSpeed = duration.inSeconds > 0 
        ? (totalDistance / 1000) / (duration.inSeconds / 3600) // km/h
        : 0.0;

    return DeliveryRoute(
      orderId: orderId,
      driverId: driverId,
      trackingPoints: sortedPoints,
      startTime: sortedPoints.first.recordedAt,
      endTime: sortedPoints.last.recordedAt,
      totalDistance: totalDistance,
      averageSpeed: averageSpeed,
    );
  }

  /// Duration of the delivery
  Duration? get duration {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }

  /// Total distance in kilometers
  double? get totalDistanceKm {
    if (totalDistance == null) return null;
    return totalDistance! / 1000;
  }

  /// Latest tracking point
  DeliveryTracking? get latestPoint {
    if (trackingPoints.isEmpty) return null;
    return trackingPoints.last;
  }

  /// Check if delivery is currently active
  bool get isActive {
    if (trackingPoints.isEmpty) return false;
    final latest = latestPoint!;
    final timeSinceLastUpdate = DateTime.now().difference(latest.recordedAt);
    return timeSinceLastUpdate.inMinutes <= 10; // Active if updated within 10 minutes
  }

  @override
  List<Object?> get props => [
        orderId,
        driverId,
        trackingPoints,
        startTime,
        endTime,
        totalDistance,
        averageSpeed,
      ];
}

// JSON conversion helper functions
TrackingLocation _locationFromJson(Map<String, dynamic> json) {
  return TrackingLocation.fromPostGIS(json);
}

Map<String, dynamic> _locationToJson(TrackingLocation location) {
  return location.toPostGIS();
}
