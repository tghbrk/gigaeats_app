import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'navigation_models.dart';

/// Traffic incident types
enum TrafficIncidentType {
  accident,
  construction,
  roadClosure,
  heavyTraffic,
  weather,
  event,
  other,
}

/// Traffic severity levels
enum TrafficSeverity {
  low,
  medium,
  high,
  critical,
}

/// Traffic incident model
class TrafficIncident extends Equatable {
  final String id;
  final TrafficIncidentType type;
  final LatLng location;
  final TrafficSeverity severity;
  final String description;
  final DateTime reportedAt;
  final bool isActive;
  final DateTime? estimatedClearanceTime;
  final Map<String, dynamic>? metadata;

  const TrafficIncident({
    required this.id,
    required this.type,
    required this.location,
    required this.severity,
    required this.description,
    required this.reportedAt,
    this.isActive = true,
    this.estimatedClearanceTime,
    this.metadata,
  });

  /// Get incident type display name
  String get typeDisplayName {
    switch (type) {
      case TrafficIncidentType.accident:
        return 'Accident';
      case TrafficIncidentType.construction:
        return 'Construction';
      case TrafficIncidentType.roadClosure:
        return 'Road Closure';
      case TrafficIncidentType.heavyTraffic:
        return 'Heavy Traffic';
      case TrafficIncidentType.weather:
        return 'Weather';
      case TrafficIncidentType.event:
        return 'Event';
      case TrafficIncidentType.other:
        return 'Other';
    }
  }

  /// Get severity display name
  String get severityDisplayName {
    switch (severity) {
      case TrafficSeverity.low:
        return 'Low';
      case TrafficSeverity.medium:
        return 'Medium';
      case TrafficSeverity.high:
        return 'High';
      case TrafficSeverity.critical:
        return 'Critical';
    }
  }

  /// Check if incident is still active
  bool get isCurrentlyActive {
    if (!isActive) return false;
    if (estimatedClearanceTime == null) return true;
    return DateTime.now().isBefore(estimatedClearanceTime!);
  }

  @override
  List<Object?> get props => [
        id,
        type,
        location,
        severity,
        description,
        reportedAt,
        isActive,
        estimatedClearanceTime,
        metadata,
      ];
}

/// Traffic segment with condition information
class TrafficSegment extends Equatable {
  final LatLng startLocation;
  final LatLng endLocation;
  final TrafficCondition condition;
  final double speedKmh;
  final int delaySeconds;
  final DateTime? lastUpdated;

  const TrafficSegment({
    required this.startLocation,
    required this.endLocation,
    required this.condition,
    required this.speedKmh,
    required this.delaySeconds,
    this.lastUpdated,
  });

  /// Get delay duration
  Duration get delay => Duration(seconds: delaySeconds);

  /// Get segment distance using Geolocator
  double get distanceMeters {
    return Geolocator.distanceBetween(
      startLocation.latitude,
      startLocation.longitude,
      endLocation.latitude,
      endLocation.longitude,
    );
  }

  @override
  List<Object?> get props => [
        startLocation,
        endLocation,
        condition,
        speedKmh,
        delaySeconds,
        lastUpdated,
      ];
}

/// Traffic data container
class TrafficData extends Equatable {
  final TrafficCondition overallCondition;
  final List<TrafficSegment> affectedSegments;
  final DateTime lastUpdated;
  final Map<String, dynamic>? metadata;

  const TrafficData({
    required this.overallCondition,
    required this.affectedSegments,
    required this.lastUpdated,
    this.metadata,
  });

  /// Get total delay from all segments
  Duration get totalDelay {
    int totalSeconds = 0;
    for (final segment in affectedSegments) {
      totalSeconds += segment.delaySeconds;
    }
    return Duration(seconds: totalSeconds);
  }

  /// Check if data is recent
  bool get isRecent {
    return DateTime.now().difference(lastUpdated).inMinutes < 10;
  }

  @override
  List<Object?> get props => [
        overallCondition,
        affectedSegments,
        lastUpdated,
        metadata,
      ];
}

/// Traffic update with comprehensive information
class TrafficUpdate extends Equatable {
  final String routeId;
  final DateTime timestamp;
  final TrafficCondition overallCondition;
  final List<TrafficIncident> incidents;
  final Duration estimatedDelay;
  final bool requiresRerouting;
  final List<TrafficSegment> affectedSegments;
  final NavigationRoute? alternativeRouteSuggestion;
  final Map<String, dynamic>? metadata;

  const TrafficUpdate({
    required this.routeId,
    required this.timestamp,
    required this.overallCondition,
    required this.incidents,
    required this.estimatedDelay,
    required this.requiresRerouting,
    required this.affectedSegments,
    this.alternativeRouteSuggestion,
    this.metadata,
  });

  /// Get high-priority incidents
  List<TrafficIncident> get highPriorityIncidents {
    return incidents.where((incident) => 
      incident.severity == TrafficSeverity.high || 
      incident.severity == TrafficSeverity.critical
    ).toList();
  }

  /// Get estimated delay text
  String get estimatedDelayText {
    if (estimatedDelay.inMinutes < 1) {
      return 'No significant delay';
    } else if (estimatedDelay.inMinutes < 60) {
      return '${estimatedDelay.inMinutes} min delay';
    } else {
      final hours = estimatedDelay.inHours;
      final minutes = estimatedDelay.inMinutes % 60;
      return '${hours}h ${minutes}min delay';
    }
  }

  @override
  List<Object?> get props => [
        routeId,
        timestamp,
        overallCondition,
        incidents,
        estimatedDelay,
        requiresRerouting,
        affectedSegments,
        alternativeRouteSuggestion,
        metadata,
      ];
}

/// Reroute recommendation
class RerouteRecommendation extends Equatable {
  final NavigationRoute originalRoute;
  final NavigationRoute alternativeRoute;
  final String reason;
  final Duration estimatedTimeSaving;
  final double confidence; // 0.0 to 1.0
  final List<TrafficIncident> incidents;
  final DateTime recommendedAt;

  RerouteRecommendation({
    required this.originalRoute,
    required this.alternativeRoute,
    required this.reason,
    required this.estimatedTimeSaving,
    required this.confidence,
    required this.incidents,
    DateTime? recommendedAt,
  }) : recommendedAt = recommendedAt ?? DateTime.now();

  /// Get confidence percentage
  int get confidencePercentage => (confidence * 100).round();

  /// Get time saving text
  String get timeSavingText {
    if (estimatedTimeSaving.inMinutes < 1) {
      return 'Less than 1 minute';
    } else if (estimatedTimeSaving.inMinutes < 60) {
      return '${estimatedTimeSaving.inMinutes} minutes';
    } else {
      final hours = estimatedTimeSaving.inHours;
      final minutes = estimatedTimeSaving.inMinutes % 60;
      return '${hours}h ${minutes}min';
    }
  }

  @override
  List<Object?> get props => [
        originalRoute,
        alternativeRoute,
        reason,
        estimatedTimeSaving,
        confidence,
        incidents,
        recommendedAt,
      ];
}
