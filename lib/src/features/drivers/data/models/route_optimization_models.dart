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

/// Phase 3.3: Route reoptimization state tracking
class RouteReoptimizationState extends Equatable {
  final String routeId;
  final String driverId;
  final OptimizedRoute currentRoute;
  final DateTime lastReoptimization;
  final int reoptimizationCount;
  final bool isMonitoring;
  final List<String> recentEventIds;
  final Map<String, dynamic>? metadata;

  const RouteReoptimizationState({
    required this.routeId,
    required this.driverId,
    required this.currentRoute,
    required this.lastReoptimization,
    required this.reoptimizationCount,
    required this.isMonitoring,
    this.recentEventIds = const [],
    this.metadata,
  });



  RouteReoptimizationState copyWith({
    String? routeId,
    String? driverId,
    OptimizedRoute? currentRoute,
    DateTime? lastReoptimization,
    int? reoptimizationCount,
    bool? isMonitoring,
    List<String>? recentEventIds,
    Map<String, dynamic>? metadata,
  }) {
    return RouteReoptimizationState(
      routeId: routeId ?? this.routeId,
      driverId: driverId ?? this.driverId,
      currentRoute: currentRoute ?? this.currentRoute,
      lastReoptimization: lastReoptimization ?? this.lastReoptimization,
      reoptimizationCount: reoptimizationCount ?? this.reoptimizationCount,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      recentEventIds: recentEventIds ?? this.recentEventIds,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        routeId,
        driverId,
        currentRoute,
        lastReoptimization,
        reoptimizationCount,
        isMonitoring,
        recentEventIds,
        metadata,
      ];
}

/// Phase 3.3: Reoptimization analysis result
class ReoptimizationAnalysis extends Equatable {
  final bool isRecommended;
  final String reason;
  final double confidence; // 0.0 to 1.0
  final Duration estimatedTimeSaving;
  final ReoptimizationPriority priority;
  final Map<String, dynamic>? metadata;

  const ReoptimizationAnalysis({
    required this.isRecommended,
    required this.reason,
    required this.confidence,
    required this.estimatedTimeSaving,
    required this.priority,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        isRecommended,
        reason,
        confidence,
        estimatedTimeSaving,
        priority,
        metadata,
      ];
}

/// Reoptimization priority levels
enum ReoptimizationPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical;

  String get displayName {
    switch (this) {
      case ReoptimizationPriority.low:
        return 'Low';
      case ReoptimizationPriority.medium:
        return 'Medium';
      case ReoptimizationPriority.high:
        return 'High';
      case ReoptimizationPriority.critical:
        return 'Critical';
    }
  }
}

/// Phase 3.3: Route reoptimization event for monitoring
class RouteReoptimizationEvent extends Equatable {
  final String routeId;
  final RouteEvent triggerEvent;
  final ReoptimizationAnalysis analysis;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const RouteReoptimizationEvent({
    required this.routeId,
    required this.triggerEvent,
    required this.analysis,
    required this.timestamp,
    this.metadata,
  });

  @override
  List<Object?> get props => [routeId, triggerEvent, analysis, timestamp, metadata];
}

/// Phase 3.3: Driver notification for route changes
class DriverNotification extends Equatable {
  final String id;
  final String driverId;
  final String routeId;
  final DriverNotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isUrgent;
  final Map<String, dynamic>? data;

  const DriverNotification({
    required this.id,
    required this.driverId,
    required this.routeId,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isUrgent = false,
    this.data,
  });

  @override
  List<Object?> get props => [id, driverId, routeId, type, title, message, timestamp, isUrgent, data];
}

/// Driver notification types
enum DriverNotificationType {
  @JsonValue('route_reoptimized')
  routeReoptimized,
  @JsonValue('traffic_incident')
  trafficIncident,
  @JsonValue('preparation_delay')
  preparationDelay,
  @JsonValue('order_ready')
  orderReady,
  @JsonValue('customer_request')
  customerRequest,
  @JsonValue('system_alert')
  systemAlert;

  String get displayName {
    switch (this) {
      case DriverNotificationType.routeReoptimized:
        return 'Route Reoptimized';
      case DriverNotificationType.trafficIncident:
        return 'Traffic Incident';
      case DriverNotificationType.preparationDelay:
        return 'Preparation Delay';
      case DriverNotificationType.orderReady:
        return 'Order Ready';
      case DriverNotificationType.customerRequest:
        return 'Customer Request';
      case DriverNotificationType.systemAlert:
        return 'System Alert';
    }
  }
}

/// Phase 3.3: Route improvement metrics
class RouteImprovement extends Equatable {
  final Duration timeSaving;
  final double distanceSaving; // in kilometers
  final double scoreImprovement;
  final bool isSignificant;

  const RouteImprovement({
    required this.timeSaving,
    required this.distanceSaving,
    required this.scoreImprovement,
    required this.isSignificant,
  });

  @override
  List<Object?> get props => [timeSaving, distanceSaving, scoreImprovement, isSignificant];
}

// TSP Performance Monitoring Models

/// Optimization Algorithm Types
enum OptimizationAlgorithm {
  @JsonValue('nearest_neighbor')
  nearestNeighbor,
  @JsonValue('genetic_algorithm')
  geneticAlgorithm,
  @JsonValue('simulated_annealing')
  simulatedAnnealing,
  @JsonValue('hybrid_multi')
  hybridMulti,
  @JsonValue('enhanced_nearest')
  enhancedNearest;

  String get displayName {
    switch (this) {
      case OptimizationAlgorithm.nearestNeighbor:
        return 'Nearest Neighbor';
      case OptimizationAlgorithm.geneticAlgorithm:
        return 'Genetic Algorithm';
      case OptimizationAlgorithm.simulatedAnnealing:
        return 'Simulated Annealing';
      case OptimizationAlgorithm.hybridMulti:
        return 'Hybrid Multi-Algorithm';
      case OptimizationAlgorithm.enhancedNearest:
        return 'Enhanced Nearest Neighbor';
    }
  }
}

/// TSP Performance Alert Types
enum AlertType {
  @JsonValue('slow_calculation')
  slowCalculation,
  @JsonValue('low_optimization_score')
  lowOptimizationScore,
  @JsonValue('high_memory_usage')
  highMemoryUsage,
  @JsonValue('algorithm_failure')
  algorithmFailure,
  @JsonValue('system_overload')
  systemOverload;

  String get displayName {
    switch (this) {
      case AlertType.slowCalculation:
        return 'Slow Calculation';
      case AlertType.lowOptimizationScore:
        return 'Low Optimization Score';
      case AlertType.highMemoryUsage:
        return 'High Memory Usage';
      case AlertType.algorithmFailure:
        return 'Algorithm Failure';
      case AlertType.systemOverload:
        return 'System Overload';
    }
  }
}

/// Alert Severity Levels
enum AlertSeverity {
  @JsonValue('info')
  info,
  @JsonValue('warning')
  warning,
  @JsonValue('critical')
  critical;

  String get displayName {
    switch (this) {
      case AlertSeverity.info:
        return 'Info';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }
}

/// TSP Performance Alert
@JsonSerializable()
class TSPPerformanceAlert extends Equatable {
  final AlertType type;
  final OptimizationAlgorithm algorithm;
  final String message;
  final AlertSeverity severity;
  final String batchId;
  final double value;
  final double threshold;
  final DateTime? timestamp;

  const TSPPerformanceAlert({
    required this.type,
    required this.algorithm,
    required this.message,
    required this.severity,
    required this.batchId,
    required this.value,
    required this.threshold,
    this.timestamp,
  });

  factory TSPPerformanceAlert.fromJson(Map<String, dynamic> json) =>
      _$TSPPerformanceAlertFromJson(json);
  Map<String, dynamic> toJson() => _$TSPPerformanceAlertToJson(this);

  @override
  List<Object?> get props => [type, algorithm, message, severity, batchId, value, threshold, timestamp];
}

/// TSP Algorithm Statistics
@JsonSerializable()
class TSPAlgorithmStats extends Equatable {
  final OptimizationAlgorithm algorithm;
  final int totalExecutions;
  final double averageCalculationTimeMs;
  final double medianCalculationTimeMs;
  final double averageOptimizationScore;
  final double averageRouteQualityScore;
  final double successRate;
  final double overallScore;

  const TSPAlgorithmStats({
    required this.algorithm,
    required this.totalExecutions,
    required this.averageCalculationTimeMs,
    required this.medianCalculationTimeMs,
    required this.averageOptimizationScore,
    required this.averageRouteQualityScore,
    required this.successRate,
    required this.overallScore,
  });

  factory TSPAlgorithmStats.fromJson(Map<String, dynamic> json) =>
      _$TSPAlgorithmStatsFromJson(json);
  Map<String, dynamic> toJson() => _$TSPAlgorithmStatsToJson(this);

  factory TSPAlgorithmStats.empty(OptimizationAlgorithm algorithm) =>
      TSPAlgorithmStats(
        algorithm: algorithm,
        totalExecutions: 0,
        averageCalculationTimeMs: 0.0,
        medianCalculationTimeMs: 0.0,
        averageOptimizationScore: 0.0,
        averageRouteQualityScore: 0.0,
        successRate: 0.0,
        overallScore: 0.0,
      );

  @override
  List<Object?> get props => [
        algorithm,
        totalExecutions,
        averageCalculationTimeMs,
        medianCalculationTimeMs,
        averageOptimizationScore,
        averageRouteQualityScore,
        successRate,
        overallScore,
      ];
}

/// TSP Algorithm Comparison
@JsonSerializable()
class TSPAlgorithmComparison extends Equatable {
  final OptimizationAlgorithm algorithm;
  final TSPAlgorithmStats stats;
  final int rank;

  const TSPAlgorithmComparison({
    required this.algorithm,
    required this.stats,
    required this.rank,
  });

  factory TSPAlgorithmComparison.fromJson(Map<String, dynamic> json) =>
      _$TSPAlgorithmComparisonFromJson(json);
  Map<String, dynamic> toJson() => _$TSPAlgorithmComparisonToJson(this);

  TSPAlgorithmComparison copyWith({
    OptimizationAlgorithm? algorithm,
    TSPAlgorithmStats? stats,
    int? rank,
  }) {
    return TSPAlgorithmComparison(
      algorithm: algorithm ?? this.algorithm,
      stats: stats ?? this.stats,
      rank: rank ?? this.rank,
    );
  }

  @override
  List<Object?> get props => [algorithm, stats, rank];
}

/// Date Range for analytics
@JsonSerializable()
class DateRange extends Equatable {
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) =>
      _$DateRangeFromJson(json);
  Map<String, dynamic> toJson() => _$DateRangeToJson(this);

  Duration get duration => end.difference(start);

  @override
  List<Object?> get props => [start, end];
}

/// TSP Performance Dashboard Data
@JsonSerializable()
class TSPPerformanceDashboard extends Equatable {
  final int totalOptimizations;
  final double averageCalculationTime;
  final double averageOptimizationScore;
  final int alertCount;
  final DateRange period;

  const TSPPerformanceDashboard({
    required this.totalOptimizations,
    required this.averageCalculationTime,
    required this.averageOptimizationScore,
    required this.alertCount,
    required this.period,
  });

  factory TSPPerformanceDashboard.fromJson(Map<String, dynamic> json) =>
      _$TSPPerformanceDashboardFromJson(json);
  Map<String, dynamic> toJson() => _$TSPPerformanceDashboardToJson(this);

  @override
  List<Object?> get props => [totalOptimizations, averageCalculationTime, averageOptimizationScore, alertCount, period];
}

/// Route Optimization Result
@JsonSerializable()
class RouteOptimizationResult extends Equatable {
  final String id;
  final String batchId;
  final OptimizedRoute optimizedRoute;
  final double optimizationScore;
  final OptimizationAlgorithm algorithm;
  final int calculationTimeMs;
  final DateTime createdAt;

  const RouteOptimizationResult({
    required this.id,
    required this.batchId,
    required this.optimizedRoute,
    required this.optimizationScore,
    required this.algorithm,
    required this.calculationTimeMs,
    required this.createdAt,
  });

  factory RouteOptimizationResult.fromJson(Map<String, dynamic> json) =>
      _$RouteOptimizationResultFromJson(json);
  Map<String, dynamic> toJson() => _$RouteOptimizationResultToJson(this);

  @override
  List<Object?> get props => [id, batchId, optimizedRoute, optimizationScore, algorithm, calculationTimeMs, createdAt];
}

// Dashboard Models

/// Route Optimization Dashboard Data
@JsonSerializable()
class RouteOptimizationDashboardData extends Equatable {
  final BatchStatistics batchStatistics;
  final RouteEfficiencyMetrics routeEfficiencyMetrics;
  final DriverUtilizationRates driverUtilizationRates;
  final SystemPerformanceIndicators systemPerformanceIndicators;
  final List<TSPAlgorithmComparison> algorithmPerformanceComparison;
  final RealtimeMetrics realtimeMetrics;
  final DateRange period;
  final DateTime lastUpdated;

  const RouteOptimizationDashboardData({
    required this.batchStatistics,
    required this.routeEfficiencyMetrics,
    required this.driverUtilizationRates,
    required this.systemPerformanceIndicators,
    required this.algorithmPerformanceComparison,
    required this.realtimeMetrics,
    required this.period,
    required this.lastUpdated,
  });

  factory RouteOptimizationDashboardData.fromJson(Map<String, dynamic> json) =>
      _$RouteOptimizationDashboardDataFromJson(json);
  Map<String, dynamic> toJson() => _$RouteOptimizationDashboardDataToJson(this);

  @override
  List<Object?> get props => [
        batchStatistics,
        routeEfficiencyMetrics,
        driverUtilizationRates,
        systemPerformanceIndicators,
        algorithmPerformanceComparison,
        realtimeMetrics,
        period,
        lastUpdated,
      ];
}

/// Batch Statistics
@JsonSerializable()
class BatchStatistics extends Equatable {
  final int totalBatches;
  final int completedBatches;
  final int activeBatches;
  final int cancelledBatches;
  final double completionRate;
  final double averageOrdersPerBatch;
  final double averageOptimizationScore;

  const BatchStatistics({
    required this.totalBatches,
    required this.completedBatches,
    required this.activeBatches,
    required this.cancelledBatches,
    required this.completionRate,
    required this.averageOrdersPerBatch,
    required this.averageOptimizationScore,
  });

  factory BatchStatistics.fromJson(Map<String, dynamic> json) =>
      _$BatchStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$BatchStatisticsToJson(this);

  @override
  List<Object?> get props => [
        totalBatches,
        completedBatches,
        activeBatches,
        cancelledBatches,
        completionRate,
        averageOrdersPerBatch,
        averageOptimizationScore,
      ];
}

/// Route Efficiency Metrics
@JsonSerializable()
class RouteEfficiencyMetrics extends Equatable {
  final int totalOptimizations;
  final double averageDistanceKm;
  final double averageDurationHours;
  final double averageOptimizationScore;
  final double averageImprovementPercent;
  final double totalDistanceSavedKm;
  final double totalTimeSavedHours;

  const RouteEfficiencyMetrics({
    required this.totalOptimizations,
    required this.averageDistanceKm,
    required this.averageDurationHours,
    required this.averageOptimizationScore,
    required this.averageImprovementPercent,
    required this.totalDistanceSavedKm,
    required this.totalTimeSavedHours,
  });

  factory RouteEfficiencyMetrics.fromJson(Map<String, dynamic> json) =>
      _$RouteEfficiencyMetricsFromJson(json);
  Map<String, dynamic> toJson() => _$RouteEfficiencyMetricsToJson(this);

  factory RouteEfficiencyMetrics.empty() => const RouteEfficiencyMetrics(
        totalOptimizations: 0,
        averageDistanceKm: 0.0,
        averageDurationHours: 0.0,
        averageOptimizationScore: 0.0,
        averageImprovementPercent: 0.0,
        totalDistanceSavedKm: 0.0,
        totalTimeSavedHours: 0.0,
      );

  @override
  List<Object?> get props => [
        totalOptimizations,
        averageDistanceKm,
        averageDurationHours,
        averageOptimizationScore,
        averageImprovementPercent,
        totalDistanceSavedKm,
        totalTimeSavedHours,
      ];
}

/// Driver Utilization Rates
@JsonSerializable()
class DriverUtilizationRates extends Equatable {
  final int totalDrivers;
  final int activeDrivers;
  final double utilizationRate;
  final double averageBatchesPerDriver;
  final double averageCompletionTimeHours;

  const DriverUtilizationRates({
    required this.totalDrivers,
    required this.activeDrivers,
    required this.utilizationRate,
    required this.averageBatchesPerDriver,
    required this.averageCompletionTimeHours,
  });

  factory DriverUtilizationRates.fromJson(Map<String, dynamic> json) =>
      _$DriverUtilizationRatesFromJson(json);
  Map<String, dynamic> toJson() => _$DriverUtilizationRatesToJson(this);

  factory DriverUtilizationRates.empty() => const DriverUtilizationRates(
        totalDrivers: 0,
        activeDrivers: 0,
        utilizationRate: 0.0,
        averageBatchesPerDriver: 0.0,
        averageCompletionTimeHours: 0.0,
      );

  @override
  List<Object?> get props => [
        totalDrivers,
        activeDrivers,
        utilizationRate,
        averageBatchesPerDriver,
        averageCompletionTimeHours,
      ];
}

/// System Performance Indicators
@JsonSerializable()
class SystemPerformanceIndicators extends Equatable {
  final int totalOptimizations;
  final double averageCalculationTimeMs;
  final int slowCalculationCount;
  final double successRate;
  final double averageMemoryUsageMb;
  final double systemHealthScore;

  const SystemPerformanceIndicators({
    required this.totalOptimizations,
    required this.averageCalculationTimeMs,
    required this.slowCalculationCount,
    required this.successRate,
    required this.averageMemoryUsageMb,
    required this.systemHealthScore,
  });

  factory SystemPerformanceIndicators.fromJson(Map<String, dynamic> json) =>
      _$SystemPerformanceIndicatorsFromJson(json);
  Map<String, dynamic> toJson() => _$SystemPerformanceIndicatorsToJson(this);

  factory SystemPerformanceIndicators.empty() => const SystemPerformanceIndicators(
        totalOptimizations: 0,
        averageCalculationTimeMs: 0.0,
        slowCalculationCount: 0,
        successRate: 0.0,
        averageMemoryUsageMb: 0.0,
        systemHealthScore: 0.0,
      );

  @override
  List<Object?> get props => [
        totalOptimizations,
        averageCalculationTimeMs,
        slowCalculationCount,
        successRate,
        averageMemoryUsageMb,
        systemHealthScore,
      ];
}

/// Realtime Metrics
@JsonSerializable()
class RealtimeMetrics extends Equatable {
  final int activeBatches;
  final int recentOptimizations;
  final double systemLoad;
  final DateTime lastUpdated;

  const RealtimeMetrics({
    required this.activeBatches,
    required this.recentOptimizations,
    required this.systemLoad,
    required this.lastUpdated,
  });

  factory RealtimeMetrics.fromJson(Map<String, dynamic> json) =>
      _$RealtimeMetricsFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeMetricsToJson(this);

  @override
  List<Object?> get props => [activeBatches, recentOptimizations, systemLoad, lastUpdated];
}

/// Route adjustment result for Phase 3 real-time route optimization
class RouteAdjustmentResult extends Equatable {
  final RouteAdjustmentStatus status;
  final String message;
  final OptimizedRoute? adjustedRoute;
  final String? adjustmentReason;
  final double? improvementScore;
  final DateTime calculatedAt;

  const RouteAdjustmentResult({
    required this.status,
    required this.message,
    this.adjustedRoute,
    this.adjustmentReason,
    this.improvementScore,
    required this.calculatedAt,
  });

  /// No adjustment needed
  factory RouteAdjustmentResult.noAdjustmentNeeded(String reason) {
    return RouteAdjustmentResult(
      status: RouteAdjustmentStatus.noAdjustmentNeeded,
      message: reason,
      calculatedAt: DateTime.now(),
    );
  }

  /// Adjustment calculated successfully
  factory RouteAdjustmentResult.adjustmentCalculated(
    OptimizedRoute adjustedRoute,
    String reason,
    double improvementScore,
  ) {
    return RouteAdjustmentResult(
      status: RouteAdjustmentStatus.adjustmentCalculated,
      message: 'Route adjustment calculated successfully',
      adjustedRoute: adjustedRoute,
      adjustmentReason: reason,
      improvementScore: improvementScore,
      calculatedAt: DateTime.now(),
    );
  }

  /// Error occurred during calculation
  factory RouteAdjustmentResult.error(String errorMessage) {
    return RouteAdjustmentResult(
      status: RouteAdjustmentStatus.error,
      message: errorMessage,
      calculatedAt: DateTime.now(),
    );
  }

  /// Check if adjustment was successful
  bool get isSuccess => status == RouteAdjustmentStatus.adjustmentCalculated;

  /// Check if no adjustment was needed
  bool get noAdjustmentNeeded => status == RouteAdjustmentStatus.noAdjustmentNeeded;

  /// Check if there was an error
  bool get hasError => status == RouteAdjustmentStatus.error;

  @override
  List<Object?> get props => [
        status,
        message,
        adjustedRoute,
        adjustmentReason,
        improvementScore,
        calculatedAt,
      ];

  @override
  String toString() => 'RouteAdjustmentResult(status: $status, message: $message)';
}

/// Route adjustment status enumeration
enum RouteAdjustmentStatus {
  @JsonValue('no_adjustment_needed')
  noAdjustmentNeeded,
  @JsonValue('adjustment_calculated')
  adjustmentCalculated,
  @JsonValue('error')
  error;

  String get displayName {
    switch (this) {
      case RouteAdjustmentStatus.noAdjustmentNeeded:
        return 'No Adjustment Needed';
      case RouteAdjustmentStatus.adjustmentCalculated:
        return 'Adjustment Calculated';
      case RouteAdjustmentStatus.error:
        return 'Error';
    }
  }
}
