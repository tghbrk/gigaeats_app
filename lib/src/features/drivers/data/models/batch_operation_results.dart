import 'package:equatable/equatable.dart';

import 'delivery_batch.dart';
import '../../../orders/data/models/order.dart';

/// Result class for batch creation operations
class BatchCreationResult extends Equatable {
  final bool isSuccess;
  final DeliveryBatch? batch;
  final String? errorMessage;

  const BatchCreationResult._({
    required this.isSuccess,
    this.batch,
    this.errorMessage,
  });

  factory BatchCreationResult.success(DeliveryBatch batch) {
    return BatchCreationResult._(
      isSuccess: true,
      batch: batch,
    );
  }

  factory BatchCreationResult.failure(String errorMessage) {
    return BatchCreationResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isSuccess, batch, errorMessage];
}

/// Result class for batch operations (start, pause, resume, complete, cancel)
class BatchOperationResult extends Equatable {
  final bool isSuccess;
  final String message;

  const BatchOperationResult._({
    required this.isSuccess,
    required this.message,
  });

  factory BatchOperationResult.success(String message) {
    return BatchOperationResult._(
      isSuccess: true,
      message: message,
    );
  }

  factory BatchOperationResult.failure(String message) {
    return BatchOperationResult._(
      isSuccess: false,
      message: message,
    );
  }

  @override
  List<Object?> get props => [isSuccess, message];
}

/// Result class for validation operations
class ValidationResult extends Equatable {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._({
    required this.isValid,
    this.errorMessage,
  });

  factory ValidationResult.valid() {
    return const ValidationResult._(isValid: true);
  }

  factory ValidationResult.invalid(String errorMessage) {
    return ValidationResult._(
      isValid: false,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isValid, errorMessage];
}

/// Result class for route optimization operations
class RouteOptimizationResult extends Equatable {
  final bool isSuccess;
  final List<String>? pickupSequence;
  final List<String>? deliverySequence;
  final double? totalDistanceKm;
  final int? estimatedDurationMinutes;
  final double? optimizationScore;
  final String? errorMessage;

  const RouteOptimizationResult._({
    required this.isSuccess,
    this.pickupSequence,
    this.deliverySequence,
    this.totalDistanceKm,
    this.estimatedDurationMinutes,
    this.optimizationScore,
    this.errorMessage,
  });

  factory RouteOptimizationResult.success({
    required List<String> pickupSequence,
    required List<String> deliverySequence,
    required double totalDistanceKm,
    required int estimatedDurationMinutes,
    required double optimizationScore,
  }) {
    return RouteOptimizationResult._(
      isSuccess: true,
      pickupSequence: pickupSequence,
      deliverySequence: deliverySequence,
      totalDistanceKm: totalDistanceKm,
      estimatedDurationMinutes: estimatedDurationMinutes,
      optimizationScore: optimizationScore,
    );
  }

  factory RouteOptimizationResult.failure(String errorMessage) {
    return RouteOptimizationResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isSuccess,
        pickupSequence,
        deliverySequence,
        totalDistanceKm,
        estimatedDurationMinutes,
        optimizationScore,
        errorMessage,
      ];
}

/// Route metrics for optimization calculations
class RouteMetrics extends Equatable {
  final double totalDistanceKm;
  final int estimatedDurationMinutes;
  final double optimizationScore;

  const RouteMetrics({
    required this.totalDistanceKm,
    required this.estimatedDurationMinutes,
    required this.optimizationScore,
  });

  @override
  List<Object?> get props => [
        totalDistanceKm,
        estimatedDurationMinutes,
        optimizationScore,
      ];
}

/// Batch order with full order details
class BatchOrderWithDetails extends Equatable {
  final BatchOrder batchOrder;
  final Order order;

  const BatchOrderWithDetails({
    required this.batchOrder,
    required this.order,
  });

  /// Get vendor name
  String get vendorName => order.vendorName;

  /// Get customer name
  String get customerName => order.customerName;

  /// Get order total amount
  double get totalAmount => order.totalAmount;

  /// Get pickup sequence
  int get pickupSequence => batchOrder.pickupSequence;

  /// Get delivery sequence
  int get deliverySequence => batchOrder.deliverySequence;

  /// Get pickup status
  BatchOrderPickupStatus get pickupStatus => batchOrder.pickupStatus;

  /// Get delivery status
  BatchOrderDeliveryStatus get deliveryStatus => batchOrder.deliveryStatus;

  /// Check if pickup is completed
  bool get isPickupCompleted => batchOrder.isPickupCompleted;

  /// Check if delivery is completed
  bool get isDeliveryCompleted => batchOrder.isDeliveryCompleted;

  /// Check if order is fully completed
  bool get isCompleted => batchOrder.isCompleted;

  /// Get estimated pickup time
  DateTime? get estimatedPickupTime => batchOrder.estimatedPickupTime;

  /// Get estimated delivery time
  DateTime? get estimatedDeliveryTime => batchOrder.estimatedDeliveryTime;

  /// Get actual pickup time
  DateTime? get actualPickupTime => batchOrder.actualPickupTime;

  /// Get actual delivery time
  DateTime? get actualDeliveryTime => batchOrder.actualDeliveryTime;

  /// Get distance from previous order
  double? get distanceFromPreviousKm => batchOrder.distanceFromPreviousKm;

  /// Get travel time from previous order
  int? get travelTimeFromPreviousMinutes => batchOrder.travelTimeFromPreviousMinutes;

  @override
  List<Object?> get props => [batchOrder, order];

  @override
  String toString() => 'BatchOrderWithDetails(orderId: ${order.id}, vendor: ${order.vendorName}, customer: ${order.customerName})';
}

/// Batch summary statistics
class BatchSummary extends Equatable {
  final int totalOrders;
  final int completedPickups;
  final int completedDeliveries;
  final double totalDistanceKm;
  final int estimatedDurationMinutes;
  final double optimizationScore;
  final DateTime? startTime;
  final DateTime? estimatedCompletionTime;

  const BatchSummary({
    required this.totalOrders,
    required this.completedPickups,
    required this.completedDeliveries,
    required this.totalDistanceKm,
    required this.estimatedDurationMinutes,
    required this.optimizationScore,
    this.startTime,
    this.estimatedCompletionTime,
  });

  /// Get pickup progress percentage
  double get pickupProgress {
    if (totalOrders == 0) return 0.0;
    return (completedPickups / totalOrders) * 100;
  }

  /// Get delivery progress percentage
  double get deliveryProgress {
    if (totalOrders == 0) return 0.0;
    return (completedDeliveries / totalOrders) * 100;
  }

  /// Get overall progress percentage
  double get overallProgress {
    if (totalOrders == 0) return 0.0;
    final totalSteps = totalOrders * 2; // pickup + delivery for each order
    final completedSteps = completedPickups + completedDeliveries;
    return (completedSteps / totalSteps) * 100;
  }

  /// Check if all pickups are completed
  bool get allPickupsCompleted => completedPickups == totalOrders;

  /// Check if all deliveries are completed
  bool get allDeliveriesCompleted => completedDeliveries == totalOrders;

  /// Check if batch is fully completed
  bool get isCompleted => allPickupsCompleted && allDeliveriesCompleted;

  @override
  List<Object?> get props => [
        totalOrders,
        completedPickups,
        completedDeliveries,
        totalDistanceKm,
        estimatedDurationMinutes,
        optimizationScore,
        startTime,
        estimatedCompletionTime,
      ];

  @override
  String toString() => 'BatchSummary(orders: $totalOrders, pickups: $completedPickups/$totalOrders, deliveries: $completedDeliveries/$totalOrders)';
}
