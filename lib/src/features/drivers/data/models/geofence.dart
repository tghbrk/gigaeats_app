import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'geofence.g.dart';

/// Geofence location coordinates
@JsonSerializable()
class GeofenceLocation extends Equatable {
  final double latitude;
  final double longitude;

  const GeofenceLocation({
    required this.latitude,
    required this.longitude,
  });

  factory GeofenceLocation.fromJson(Map<String, dynamic> json) => _$GeofenceLocationFromJson(json);
  Map<String, dynamic> toJson() => _$GeofenceLocationToJson(this);

  @override
  List<Object?> get props => [latitude, longitude];

  @override
  String toString() => 'GeofenceLocation(lat: $latitude, lng: $longitude)';
}

/// Geofence event types
enum GeofenceEventType {
  @JsonValue('enter')
  enter,
  @JsonValue('exit')
  exit,
  @JsonValue('dwell')
  dwell,
}

/// Geofence trigger conditions
enum GeofenceTrigger {
  @JsonValue('on_enter')
  onEnter,
  @JsonValue('on_exit')
  onExit,
  @JsonValue('on_dwell')
  onDwell,
}

/// Geofence model for location-based automatic status transitions
@JsonSerializable()
class Geofence extends Equatable {
  final String id;
  final GeofenceLocation center;
  final double radius; // in meters
  final List<GeofenceEventType> events;
  final String? orderId;
  final String? batchId;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime? expiresAt;
  final bool isActive;

  const Geofence({
    required this.id,
    required this.center,
    required this.radius,
    required this.events,
    this.orderId,
    this.batchId,
    this.description,
    this.metadata,
    this.expiresAt,
    this.isActive = true,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) => _$GeofenceFromJson(json);
  Map<String, dynamic> toJson() => _$GeofenceToJson(this);

  /// Create a vendor pickup geofence
  factory Geofence.vendorPickup({
    required String orderId,
    required GeofenceLocation location,
    double radius = 100,
    String? description,
  }) {
    return Geofence(
      id: 'vendor_$orderId',
      center: location,
      radius: radius,
      events: [GeofenceEventType.enter, GeofenceEventType.exit],
      orderId: orderId,
      description: description ?? 'Vendor pickup location',
      metadata: {
        'type': 'vendor_pickup',
        'auto_transition': 'arrived_at_vendor',
      },
    );
  }

  /// Create a customer delivery geofence
  factory Geofence.customerDelivery({
    required String orderId,
    required GeofenceLocation location,
    double radius = 100,
    String? description,
  }) {
    return Geofence(
      id: 'customer_$orderId',
      center: location,
      radius: radius,
      events: [GeofenceEventType.enter, GeofenceEventType.exit],
      orderId: orderId,
      description: description ?? 'Customer delivery location',
      metadata: {
        'type': 'customer_delivery',
        'auto_transition': 'arrived_at_customer',
      },
    );
  }

  /// Create a batch waypoint geofence
  factory Geofence.batchWaypoint({
    required String waypointId,
    required String batchId,
    required GeofenceLocation location,
    required String waypointType, // 'pickup' or 'delivery'
    double radius = 100,
    String? description,
  }) {
    return Geofence(
      id: 'waypoint_$waypointId',
      center: location,
      radius: radius,
      events: [GeofenceEventType.enter, GeofenceEventType.exit],
      batchId: batchId,
      description: description ?? '$waypointType waypoint',
      metadata: {
        'type': 'batch_waypoint',
        'waypoint_type': waypointType,
        'waypoint_id': waypointId,
      },
    );
  }

  /// Check if geofence is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Get the auto-transition status if configured
  String? get autoTransitionStatus {
    return metadata?['auto_transition'] as String?;
  }

  /// Get the geofence type
  String? get type {
    return metadata?['type'] as String?;
  }

  /// Check if this is a vendor pickup geofence
  bool get isVendorPickup => type == 'vendor_pickup';

  /// Check if this is a customer delivery geofence
  bool get isCustomerDelivery => type == 'customer_delivery';

  /// Check if this is a batch waypoint geofence
  bool get isBatchWaypoint => type == 'batch_waypoint';

  /// Copy with new values
  Geofence copyWith({
    String? id,
    GeofenceLocation? center,
    double? radius,
    List<GeofenceEventType>? events,
    String? orderId,
    String? batchId,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? expiresAt,
    bool? isActive,
  }) {
    return Geofence(
      id: id ?? this.id,
      center: center ?? this.center,
      radius: radius ?? this.radius,
      events: events ?? this.events,
      orderId: orderId ?? this.orderId,
      batchId: batchId ?? this.batchId,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        center,
        radius,
        events,
        orderId,
        batchId,
        description,
        metadata,
        expiresAt,
        isActive,
      ];

  @override
  String toString() => 'Geofence(id: $id, center: $center, radius: ${radius}m, events: $events)';
}
