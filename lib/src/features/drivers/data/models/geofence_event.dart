import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:geolocator/geolocator.dart';

import 'geofence.dart';

part 'geofence_event.g.dart';

/// Geofence event model for tracking geofence entry/exit events
@JsonSerializable()
class GeofenceEvent extends Equatable {
  final String id;
  final String geofenceId;
  final GeofenceEventType type;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final String? driverId;
  final String? orderId;
  final String? batchId;
  final double? speed;
  final double? heading;
  final Map<String, dynamic>? metadata;

  const GeofenceEvent({
    required this.id,
    required this.geofenceId,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.driverId,
    this.orderId,
    this.batchId,
    this.speed,
    this.heading,
    this.metadata,
  });

  /// Create from Position and Geofence
  factory GeofenceEvent.fromPosition({
    required String geofenceId,
    required GeofenceEventType type,
    required Position position,
    String? driverId,
    String? orderId,
    String? batchId,
    Map<String, dynamic>? metadata,
  }) {
    return GeofenceEvent(
      id: _generateEventId(),
      geofenceId: geofenceId,
      type: type,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
      driverId: driverId,
      orderId: orderId,
      batchId: batchId,
      speed: position.speed,
      heading: position.heading,
      metadata: metadata,
    );
  }

  factory GeofenceEvent.fromJson(Map<String, dynamic> json) => _$GeofenceEventFromJson(json);
  Map<String, dynamic> toJson() => _$GeofenceEventToJson(this);

  /// Generate unique event ID
  static String _generateEventId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'geofence_event_${timestamp}_$random';
  }

  /// Get position from event
  Position get position {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      accuracy: accuracy,
      altitude: 0.0,
      heading: heading ?? 0.0,
      speed: speed ?? 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  /// Get location as GeofenceLocation
  GeofenceLocation get location {
    return GeofenceLocation(
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Check if this is an entry event
  bool get isEntry => type == GeofenceEventType.enter;

  /// Check if this is an exit event
  bool get isExit => type == GeofenceEventType.exit;

  /// Check if this is a dwell event
  bool get isDwell => type == GeofenceEventType.dwell;

  /// Get event type display name
  String get typeDisplayName {
    switch (type) {
      case GeofenceEventType.enter:
        return 'Entered';
      case GeofenceEventType.exit:
        return 'Exited';
      case GeofenceEventType.dwell:
        return 'Dwelling';
    }
  }

  /// Get time since event
  Duration get timeSinceEvent {
    return DateTime.now().difference(timestamp);
  }

  /// Check if event is recent (within specified duration)
  bool isRecent(Duration threshold) {
    return timeSinceEvent <= threshold;
  }

  /// Copy with new values
  GeofenceEvent copyWith({
    String? id,
    String? geofenceId,
    GeofenceEventType? type,
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? timestamp,
    String? driverId,
    String? orderId,
    String? batchId,
    double? speed,
    double? heading,
    Map<String, dynamic>? metadata,
  }) {
    return GeofenceEvent(
      id: id ?? this.id,
      geofenceId: geofenceId ?? this.geofenceId,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      driverId: driverId ?? this.driverId,
      orderId: orderId ?? this.orderId,
      batchId: batchId ?? this.batchId,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        geofenceId,
        type,
        latitude,
        longitude,
        accuracy,
        timestamp,
        driverId,
        orderId,
        batchId,
        speed,
        heading,
        metadata,
      ];

  @override
  String toString() => 'GeofenceEvent(id: $id, geofence: $geofenceId, type: $typeDisplayName, time: $timestamp)';
}

/// Geofence event statistics for analytics
@JsonSerializable()
class GeofenceEventStats extends Equatable {
  final String geofenceId;
  final int totalEvents;
  final int enterEvents;
  final int exitEvents;
  final int dwellEvents;
  final DateTime? firstEvent;
  final DateTime? lastEvent;
  final Duration? averageDwellTime;
  final Map<String, int> eventsByHour;

  const GeofenceEventStats({
    required this.geofenceId,
    required this.totalEvents,
    required this.enterEvents,
    required this.exitEvents,
    required this.dwellEvents,
    this.firstEvent,
    this.lastEvent,
    this.averageDwellTime,
    required this.eventsByHour,
  });

  factory GeofenceEventStats.fromJson(Map<String, dynamic> json) => _$GeofenceEventStatsFromJson(json);
  Map<String, dynamic> toJson() => _$GeofenceEventStatsToJson(this);

  /// Calculate from list of events
  factory GeofenceEventStats.fromEvents(String geofenceId, List<GeofenceEvent> events) {
    if (events.isEmpty) {
      return GeofenceEventStats(
        geofenceId: geofenceId,
        totalEvents: 0,
        enterEvents: 0,
        exitEvents: 0,
        dwellEvents: 0,
        eventsByHour: {},
      );
    }

    final enterEvents = events.where((e) => e.type == GeofenceEventType.enter).length;
    final exitEvents = events.where((e) => e.type == GeofenceEventType.exit).length;
    final dwellEvents = events.where((e) => e.type == GeofenceEventType.dwell).length;

    final sortedEvents = List<GeofenceEvent>.from(events)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final firstEvent = sortedEvents.first.timestamp;
    final lastEvent = sortedEvents.last.timestamp;

    // Calculate events by hour
    final eventsByHour = <String, int>{};
    for (final event in events) {
      final hour = event.timestamp.hour.toString().padLeft(2, '0');
      eventsByHour[hour] = (eventsByHour[hour] ?? 0) + 1;
    }

    return GeofenceEventStats(
      geofenceId: geofenceId,
      totalEvents: events.length,
      enterEvents: enterEvents,
      exitEvents: exitEvents,
      dwellEvents: dwellEvents,
      firstEvent: firstEvent,
      lastEvent: lastEvent,
      eventsByHour: eventsByHour,
    );
  }

  @override
  List<Object?> get props => [
        geofenceId,
        totalEvents,
        enterEvents,
        exitEvents,
        dwellEvents,
        firstEvent,
        lastEvent,
        averageDwellTime,
        eventsByHour,
      ];

  @override
  String toString() => 'GeofenceEventStats(geofence: $geofenceId, total: $totalEvents, enter: $enterEvents, exit: $exitEvents)';
}
