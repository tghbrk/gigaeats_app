import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'delivery_batch.g.dart';

/// Batch status enumeration
enum BatchStatus {
  @JsonValue('planned')
  planned,
  @JsonValue('active')
  active,
  @JsonValue('paused')
  paused,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled;

  const BatchStatus();

  String get displayName {
    switch (this) {
      case BatchStatus.planned:
        return 'Planned';
      case BatchStatus.active:
        return 'Active';
      case BatchStatus.paused:
        return 'Paused';
      case BatchStatus.completed:
        return 'Completed';
      case BatchStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive => this == BatchStatus.active;
  bool get isCompleted => this == BatchStatus.completed;
  bool get canBeStarted => this == BatchStatus.planned;
  bool get canBePaused => this == BatchStatus.active;
  bool get canBeResumed => this == BatchStatus.paused;
}

/// Batch order pickup status
enum BatchOrderPickupStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed;

  const BatchOrderPickupStatus();

  String get displayName {
    switch (this) {
      case BatchOrderPickupStatus.pending:
        return 'Pending';
      case BatchOrderPickupStatus.inProgress:
        return 'In Progress';
      case BatchOrderPickupStatus.completed:
        return 'Completed';
      case BatchOrderPickupStatus.failed:
        return 'Failed';
    }
  }
}

/// Batch order delivery status
enum BatchOrderDeliveryStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed;

  const BatchOrderDeliveryStatus();

  String get displayName {
    switch (this) {
      case BatchOrderDeliveryStatus.pending:
        return 'Pending';
      case BatchOrderDeliveryStatus.inProgress:
        return 'In Progress';
      case BatchOrderDeliveryStatus.completed:
        return 'Completed';
      case BatchOrderDeliveryStatus.failed:
        return 'Failed';
    }
  }
}

/// Delivery batch model for multi-order management
@JsonSerializable()
class DeliveryBatch extends Equatable {
  final String id;
  @JsonKey(name: 'driver_id')
  final String driverId;
  @JsonKey(name: 'batch_number')
  final String batchNumber;
  final BatchStatus status;

  // Route optimization data
  @JsonKey(name: 'total_distance_km')
  final double? totalDistanceKm;
  @JsonKey(name: 'estimated_duration_minutes')
  final int? estimatedDurationMinutes;
  @JsonKey(name: 'optimization_score')
  final double? optimizationScore;

  // Batch constraints
  @JsonKey(name: 'max_orders')
  final int maxOrders;
  @JsonKey(name: 'max_deviation_km', fromJson: _doubleFromJson)
  final double maxDeviationKm;

  // Timing
  @JsonKey(name: 'planned_start_time')
  final DateTime? plannedStartTime;
  @JsonKey(name: 'actual_start_time')
  final DateTime? actualStartTime;
  @JsonKey(name: 'estimated_completion_time')
  final DateTime? estimatedCompletionTime;
  @JsonKey(name: 'actual_completion_time')
  final DateTime? actualCompletionTime;

  // Metadata
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const DeliveryBatch({
    required this.id,
    required this.driverId,
    required this.batchNumber,
    required this.status,
    this.totalDistanceKm,
    this.estimatedDurationMinutes,
    this.optimizationScore,
    this.maxOrders = 3,
    this.maxDeviationKm = 5.0,
    this.plannedStartTime,
    this.actualStartTime,
    this.estimatedCompletionTime,
    this.actualCompletionTime,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory DeliveryBatch.fromJson(Map<String, dynamic> json) => _$DeliveryBatchFromJson(json);
  Map<String, dynamic> toJson() => _$DeliveryBatchToJson(this);

  /// Get batch duration
  Duration? get duration {
    if (actualStartTime == null) return null;
    final endTime = actualCompletionTime ?? DateTime.now();
    return endTime.difference(actualStartTime!);
  }

  /// Get estimated duration text
  String get estimatedDurationText {
    if (estimatedDurationMinutes == null) return 'Unknown';
    
    if (estimatedDurationMinutes! < 60) {
      return '${estimatedDurationMinutes}min';
    } else {
      final hours = (estimatedDurationMinutes! / 60).floor();
      final minutes = estimatedDurationMinutes! % 60;
      return '${hours}h ${minutes}min';
    }
  }

  /// Get total distance text
  String get totalDistanceText {
    if (totalDistanceKm == null) return 'Unknown';
    return '${totalDistanceKm!.toStringAsFixed(1)}km';
  }

  /// Get optimization score text
  String get optimizationScoreText {
    if (optimizationScore == null) return 'Unknown';
    return '${optimizationScore!.toStringAsFixed(1)}%';
  }

  /// Check if batch is active
  bool get isActive => status == BatchStatus.active;

  DeliveryBatch copyWith({
    String? id,
    String? driverId,
    String? batchNumber,
    BatchStatus? status,
    double? totalDistanceKm,
    int? estimatedDurationMinutes,
    double? optimizationScore,
    int? maxOrders,
    double? maxDeviationKm,
    DateTime? plannedStartTime,
    DateTime? actualStartTime,
    DateTime? estimatedCompletionTime,
    DateTime? actualCompletionTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return DeliveryBatch(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      batchNumber: batchNumber ?? this.batchNumber,
      status: status ?? this.status,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      optimizationScore: optimizationScore ?? this.optimizationScore,
      maxOrders: maxOrders ?? this.maxOrders,
      maxDeviationKm: maxDeviationKm ?? this.maxDeviationKm,
      plannedStartTime: plannedStartTime ?? this.plannedStartTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      estimatedCompletionTime: estimatedCompletionTime ?? this.estimatedCompletionTime,
      actualCompletionTime: actualCompletionTime ?? this.actualCompletionTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        driverId,
        batchNumber,
        status,
        totalDistanceKm,
        estimatedDurationMinutes,
        optimizationScore,
        maxOrders,
        maxDeviationKm,
        plannedStartTime,
        actualStartTime,
        estimatedCompletionTime,
        actualCompletionTime,
        createdAt,
        updatedAt,
        metadata,
      ];

  @override
  String toString() => 'DeliveryBatch(id: $id, batchNumber: $batchNumber, status: ${status.displayName})';
}

/// Batch order model for tracking orders within a batch
@JsonSerializable()
class BatchOrder extends Equatable {
  final String id;
  @JsonKey(name: 'batch_id')
  final String batchId;
  @JsonKey(name: 'order_id')
  final String orderId;

  // Sequence and routing
  @JsonKey(name: 'pickup_sequence')
  final int pickupSequence;
  @JsonKey(name: 'delivery_sequence')
  final int deliverySequence;

  // Timing estimates
  @JsonKey(name: 'estimated_pickup_time')
  final DateTime? estimatedPickupTime;
  @JsonKey(name: 'estimated_delivery_time')
  final DateTime? estimatedDeliveryTime;
  @JsonKey(name: 'actual_pickup_time')
  final DateTime? actualPickupTime;
  @JsonKey(name: 'actual_delivery_time')
  final DateTime? actualDeliveryTime;

  // Route optimization data
  @JsonKey(name: 'distance_from_previous_km')
  final double? distanceFromPreviousKm;
  @JsonKey(name: 'travel_time_from_previous_minutes')
  final int? travelTimeFromPreviousMinutes;

  // Status tracking
  @JsonKey(name: 'pickup_status')
  final BatchOrderPickupStatus pickupStatus;
  @JsonKey(name: 'delivery_status')
  final BatchOrderDeliveryStatus deliveryStatus;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const BatchOrder({
    required this.id,
    required this.batchId,
    required this.orderId,
    required this.pickupSequence,
    required this.deliverySequence,
    this.estimatedPickupTime,
    this.estimatedDeliveryTime,
    this.actualPickupTime,
    this.actualDeliveryTime,
    this.distanceFromPreviousKm,
    this.travelTimeFromPreviousMinutes,
    this.pickupStatus = BatchOrderPickupStatus.pending,
    this.deliveryStatus = BatchOrderDeliveryStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BatchOrder.fromJson(Map<String, dynamic> json) => _$BatchOrderFromJson(json);
  Map<String, dynamic> toJson() => _$BatchOrderToJson(this);

  /// Check if pickup is completed
  bool get isPickupCompleted => pickupStatus == BatchOrderPickupStatus.completed;

  /// Check if delivery is completed
  bool get isDeliveryCompleted => deliveryStatus == BatchOrderDeliveryStatus.completed;

  /// Check if order is fully completed
  bool get isCompleted => isPickupCompleted && isDeliveryCompleted;

  /// Get pickup duration
  Duration? get pickupDuration {
    if (actualPickupTime == null || estimatedPickupTime == null) return null;
    return actualPickupTime!.difference(estimatedPickupTime!);
  }

  /// Get delivery duration
  Duration? get deliveryDuration {
    if (actualDeliveryTime == null || estimatedDeliveryTime == null) return null;
    return actualDeliveryTime!.difference(estimatedDeliveryTime!);
  }

  BatchOrder copyWith({
    String? id,
    String? batchId,
    String? orderId,
    int? pickupSequence,
    int? deliverySequence,
    DateTime? estimatedPickupTime,
    DateTime? estimatedDeliveryTime,
    DateTime? actualPickupTime,
    DateTime? actualDeliveryTime,
    double? distanceFromPreviousKm,
    int? travelTimeFromPreviousMinutes,
    BatchOrderPickupStatus? pickupStatus,
    BatchOrderDeliveryStatus? deliveryStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BatchOrder(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      orderId: orderId ?? this.orderId,
      pickupSequence: pickupSequence ?? this.pickupSequence,
      deliverySequence: deliverySequence ?? this.deliverySequence,
      estimatedPickupTime: estimatedPickupTime ?? this.estimatedPickupTime,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualPickupTime: actualPickupTime ?? this.actualPickupTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      distanceFromPreviousKm: distanceFromPreviousKm ?? this.distanceFromPreviousKm,
      travelTimeFromPreviousMinutes: travelTimeFromPreviousMinutes ?? this.travelTimeFromPreviousMinutes,
      pickupStatus: pickupStatus ?? this.pickupStatus,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        batchId,
        orderId,
        pickupSequence,
        deliverySequence,
        estimatedPickupTime,
        estimatedDeliveryTime,
        actualPickupTime,
        actualDeliveryTime,
        distanceFromPreviousKm,
        travelTimeFromPreviousMinutes,
        pickupStatus,
        deliveryStatus,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() => 'BatchOrder(id: $id, orderId: $orderId, pickup: $pickupSequence, delivery: $deliverySequence)';
}

/// Helper function to convert string or number to double
/// This handles cases where PostgreSQL DECIMAL/NUMERIC fields come as strings
double _doubleFromJson(dynamic value) {
  if (value == null) return 5.0; // Default value
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.parse(value);
  throw ArgumentError('Cannot convert $value to double');
}
