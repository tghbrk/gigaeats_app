import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'navigation_models.dart';

part 'route_optimization_models.g.dart';

/// Optimization criteria with weighted factors
@JsonSerializable()
class OptimizationCriteria extends Equatable {
  final double distanceWeight;
  final double preparationTimeWeight;
  final double trafficWeight;
  final double deliveryWindowWeight;

  const OptimizationCriteria({
    required this.distanceWeight,
    required this.preparationTimeWeight,
    required this.trafficWeight,
    required this.deliveryWindowWeight,
  });

  factory OptimizationCriteria.fromJson(Map<String, dynamic> json) => _$OptimizationCriteriaFromJson(json);
  Map<String, dynamic> toJson() => _$OptimizationCriteriaToJson(this);

  /// Balanced optimization criteria (40% distance, 30% prep time, 20% traffic, 10% delivery window)
  factory OptimizationCriteria.balanced() {
    return const OptimizationCriteria(
      distanceWeight: 0.4,
      preparationTimeWeight: 0.3,
      trafficWeight: 0.2,
      deliveryWindowWeight: 0.1,
    );
  }

  /// Distance-focused optimization
  factory OptimizationCriteria.distanceFocused() {
    return const OptimizationCriteria(
      distanceWeight: 0.6,
      preparationTimeWeight: 0.2,
      trafficWeight: 0.15,
      deliveryWindowWeight: 0.05,
    );
  }

  /// Time-focused optimization
  factory OptimizationCriteria.timeFocused() {
    return const OptimizationCriteria(
      distanceWeight: 0.2,
      preparationTimeWeight: 0.4,
      trafficWeight: 0.3,
      deliveryWindowWeight: 0.1,
    );
  }

  /// Validate weights sum to 1.0
  bool get isValid {
    final sum = distanceWeight + preparationTimeWeight + trafficWeight + deliveryWindowWeight;
    return (sum - 1.0).abs() < 0.001; // Allow small floating point errors
  }

  @override
  List<Object?> get props => [distanceWeight, preparationTimeWeight, trafficWeight, deliveryWindowWeight];
}

/// Preparation time window for vendor readiness prediction
@JsonSerializable()
class PreparationWindow extends Equatable {
  final String orderId;
  final String vendorId;
  final DateTime estimatedStartTime;
  final DateTime estimatedCompletionTime;
  final Duration estimatedDuration;
  final double confidenceScore; // 0.0 to 1.0
  final Map<String, dynamic>? metadata;

  const PreparationWindow({
    required this.orderId,
    required this.vendorId,
    required this.estimatedStartTime,
    required this.estimatedCompletionTime,
    required this.estimatedDuration,
    this.confidenceScore = 0.8,
    this.metadata,
  });

  factory PreparationWindow.fromJson(Map<String, dynamic> json) => _$PreparationWindowFromJson(json);
  Map<String, dynamic> toJson() => _$PreparationWindowToJson(this);

  /// Check if order will be ready by a specific time
  bool isReadyBy(DateTime time) {
    return estimatedCompletionTime.isBefore(time) || estimatedCompletionTime.isAtSameMomentAs(time);
  }

  /// Get remaining preparation time from now
  Duration get remainingPreparationTime {
    final now = DateTime.now();
    if (estimatedCompletionTime.isBefore(now)) {
      return Duration.zero;
    }
    return estimatedCompletionTime.difference(now);
  }

  /// Get preparation status
  PreparationStatus get status {
    final now = DateTime.now();
    if (now.isBefore(estimatedStartTime)) {
      return PreparationStatus.notStarted;
    } else if (now.isBefore(estimatedCompletionTime)) {
      return PreparationStatus.inProgress;
    } else {
      return PreparationStatus.ready;
    }
  }

  @override
  List<Object?> get props => [
        orderId,
        vendorId,
        estimatedStartTime,
        estimatedCompletionTime,
        estimatedDuration,
        confidenceScore,
        metadata,
      ];
}

/// Preparation status enumeration
enum PreparationStatus {
  @JsonValue('not_started')
  notStarted,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('ready')
  ready;

  String get displayName {
    switch (this) {
      case PreparationStatus.notStarted:
        return 'Not Started';
      case PreparationStatus.inProgress:
        return 'In Progress';
      case PreparationStatus.ready:
        return 'Ready';
    }
  }
}

/// Waypoint in optimized route
@JsonSerializable()
class RouteWaypoint extends Equatable {
  final String id;
  final String orderId;
  final WaypointType type;
  @LatLngConverter()
  final LatLng location;
  final String? address;
  final int sequence;
  final DateTime? estimatedArrivalTime;
  final Duration? estimatedDuration;
  final double? distanceFromPrevious;
  final Map<String, dynamic>? metadata;

  const RouteWaypoint({
    required this.id,
    required this.orderId,
    required this.type,
    required this.location,
    this.address,
    required this.sequence,
    this.estimatedArrivalTime,
    this.estimatedDuration,
    this.distanceFromPrevious,
    this.metadata,
  });

  factory RouteWaypoint.fromJson(Map<String, dynamic> json) => _$RouteWaypointFromJson(json);
  Map<String, dynamic> toJson() => _$RouteWaypointToJson(this);

  /// Create pickup waypoint
  factory RouteWaypoint.pickup({
    required String orderId,
    required LatLng location,
    required int sequence,
    String? address,
    DateTime? estimatedArrivalTime,
    Duration? estimatedDuration,
    double? distanceFromPrevious,
  }) {
    return RouteWaypoint(
      id: 'pickup_${orderId}_$sequence',
      orderId: orderId,
      type: WaypointType.pickup,
      location: location,
      address: address,
      sequence: sequence,
      estimatedArrivalTime: estimatedArrivalTime,
      estimatedDuration: estimatedDuration,
      distanceFromPrevious: distanceFromPrevious,
    );
  }

  /// Create delivery waypoint
  factory RouteWaypoint.delivery({
    required String orderId,
    required LatLng location,
    required int sequence,
    String? address,
    DateTime? estimatedArrivalTime,
    Duration? estimatedDuration,
    double? distanceFromPrevious,
  }) {
    return RouteWaypoint(
      id: 'delivery_${orderId}_$sequence',
      orderId: orderId,
      type: WaypointType.delivery,
      location: location,
      address: address,
      sequence: sequence,
      estimatedArrivalTime: estimatedArrivalTime,
      estimatedDuration: estimatedDuration,
      distanceFromPrevious: distanceFromPrevious,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        type,
        location,
        address,
        sequence,
        estimatedArrivalTime,
        estimatedDuration,
        distanceFromPrevious,
        metadata,
      ];
}

/// Waypoint type enumeration
enum WaypointType {
  @JsonValue('pickup')
  pickup,
  @JsonValue('delivery')
  delivery;

  String get displayName {
    switch (this) {
      case WaypointType.pickup:
        return 'Pickup';
      case WaypointType.delivery:
        return 'Delivery';
    }
  }
}

/// Optimized route with TSP solution
@JsonSerializable()
class OptimizedRoute extends Equatable {
  final String id;
  final String batchId;
  final List<RouteWaypoint> waypoints;
  final double totalDistanceKm;
  final Duration totalDuration;
  final Duration durationInTraffic;
  final double optimizationScore;
  final OptimizationCriteria criteria;
  final DateTime calculatedAt;
  final TrafficCondition overallTrafficCondition;
  final Map<String, dynamic>? metadata;

  const OptimizedRoute({
    required this.id,
    required this.batchId,
    required this.waypoints,
    required this.totalDistanceKm,
    required this.totalDuration,
    required this.durationInTraffic,
    required this.optimizationScore,
    required this.criteria,
    required this.calculatedAt,
    this.overallTrafficCondition = TrafficCondition.unknown,
    this.metadata,
  });

  factory OptimizedRoute.fromJson(Map<String, dynamic> json) => _$OptimizedRouteFromJson(json);
  Map<String, dynamic> toJson() => _$OptimizedRouteToJson(this);

  /// Get pickup waypoints only
  List<RouteWaypoint> get pickupWaypoints {
    return waypoints.where((w) => w.type == WaypointType.pickup).toList();
  }

  /// Get delivery waypoints only
  List<RouteWaypoint> get deliveryWaypoints {
    return waypoints.where((w) => w.type == WaypointType.delivery).toList();
  }

  /// Get waypoints for specific order
  List<RouteWaypoint> getWaypointsForOrder(String orderId) {
    return waypoints.where((w) => w.orderId == orderId).toList();
  }

  /// Get next waypoint after current sequence
  RouteWaypoint? getNextWaypoint(int currentSequence) {
    final nextWaypoints = waypoints.where((w) => w.sequence > currentSequence).toList();
    if (nextWaypoints.isEmpty) return null;
    
    nextWaypoints.sort((a, b) => a.sequence.compareTo(b.sequence));
    return nextWaypoints.first;
  }

  /// Get traffic delay
  Duration get trafficDelay {
    return durationInTraffic - totalDuration;
  }

  /// Get formatted total distance
  String get totalDistanceText {
    if (totalDistanceKm < 1) {
      return '${(totalDistanceKm * 1000).round()}m';
    } else {
      return '${totalDistanceKm.toStringAsFixed(1)}km';
    }
  }

  /// Get formatted total duration
  String get totalDurationText {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  /// Get formatted optimization score
  String get optimizationScoreText {
    return '${optimizationScore.toStringAsFixed(1)}%';
  }

  @override
  List<Object?> get props => [
        id,
        batchId,
        waypoints,
        totalDistanceKm,
        totalDuration,
        durationInTraffic,
        optimizationScore,
        criteria,
        calculatedAt,
        overallTrafficCondition,
        metadata,
      ];
}

/// Route update for dynamic reoptimization
@JsonSerializable()
class RouteUpdate extends Equatable {
  final String routeId;
  final List<RouteWaypoint> updatedWaypoints;
  final double newOptimizationScore;
  final RouteUpdateReason reason;
  final DateTime updatedAt;
  final Map<String, dynamic>? changes;

  const RouteUpdate({
    required this.routeId,
    required this.updatedWaypoints,
    required this.newOptimizationScore,
    required this.reason,
    required this.updatedAt,
    this.changes,
  });

  factory RouteUpdate.fromJson(Map<String, dynamic> json) => _$RouteUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$RouteUpdateToJson(this);

  @override
  List<Object?> get props => [routeId, updatedWaypoints, newOptimizationScore, reason, updatedAt, changes];
}

/// Route update reason enumeration
enum RouteUpdateReason {
  @JsonValue('traffic_change')
  trafficChange,
  @JsonValue('preparation_delay')
  preparationDelay,
  @JsonValue('order_cancellation')
  orderCancellation,
  @JsonValue('driver_request')
  driverRequest,
  @JsonValue('system_optimization')
  systemOptimization;

  String get displayName {
    switch (this) {
      case RouteUpdateReason.trafficChange:
        return 'Traffic Change';
      case RouteUpdateReason.preparationDelay:
        return 'Preparation Delay';
      case RouteUpdateReason.orderCancellation:
        return 'Order Cancellation';
      case RouteUpdateReason.driverRequest:
        return 'Driver Request';
      case RouteUpdateReason.systemOptimization:
        return 'System Optimization';
    }
  }
}

/// Route progress tracking
@JsonSerializable()
class RouteProgress extends Equatable {
  final String routeId;
  final int currentWaypointSequence;
  final List<String> completedWaypoints;
  final double progressPercentage;
  final DateTime lastUpdated;

  const RouteProgress({
    required this.routeId,
    required this.currentWaypointSequence,
    required this.completedWaypoints,
    required this.progressPercentage,
    required this.lastUpdated,
  });

  factory RouteProgress.fromJson(Map<String, dynamic> json) => _$RouteProgressFromJson(json);
  Map<String, dynamic> toJson() => _$RouteProgressToJson(this);

  @override
  List<Object?> get props => [routeId, currentWaypointSequence, completedWaypoints, progressPercentage, lastUpdated];
}

/// Route event for triggering reoptimization
@JsonSerializable()
class RouteEvent extends Equatable {
  final String id;
  final String routeId;
  final RouteEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const RouteEvent({
    required this.id,
    required this.routeId,
    required this.type,
    required this.timestamp,
    required this.data,
  });

  factory RouteEvent.fromJson(Map<String, dynamic> json) => _$RouteEventFromJson(json);
  Map<String, dynamic> toJson() => _$RouteEventToJson(this);

  @override
  List<Object?> get props => [id, routeId, type, timestamp, data];
}

/// Route event type enumeration
enum RouteEventType {
  @JsonValue('traffic_incident')
  trafficIncident,
  @JsonValue('preparation_delay')
  preparationDelay,
  @JsonValue('order_ready')
  orderReady,
  @JsonValue('waypoint_completed')
  waypointCompleted,
  @JsonValue('driver_location_update')
  driverLocationUpdate;

  String get displayName {
    switch (this) {
      case RouteEventType.trafficIncident:
        return 'Traffic Incident';
      case RouteEventType.preparationDelay:
        return 'Preparation Delay';
      case RouteEventType.orderReady:
        return 'Order Ready';
      case RouteEventType.waypointCompleted:
        return 'Waypoint Completed';
      case RouteEventType.driverLocationUpdate:
        return 'Driver Location Update';
    }
  }
}
