import 'package:flutter/foundation.dart';

/// Comprehensive batch performance metrics for Phase 4.2 analytics
@immutable
class BatchPerformanceMetrics {
  final int totalBatches;
  final int completedBatches;
  final double completionRate;
  final double averageOrdersPerBatch;
  final double averageDistance;
  final Duration averageDuration;
  final double averageEfficiencyScore;
  final int totalOrders;
  final int successfulDeliveries;
  final double deliverySuccessRate;
  final DateTime? lastUpdated;

  const BatchPerformanceMetrics({
    required this.totalBatches,
    required this.completedBatches,
    required this.completionRate,
    required this.averageOrdersPerBatch,
    required this.averageDistance,
    required this.averageDuration,
    required this.averageEfficiencyScore,
    required this.totalOrders,
    required this.successfulDeliveries,
    this.lastUpdated,
  }) : deliverySuccessRate = totalOrders > 0 ? successfulDeliveries / totalOrders : 0.0;

  factory BatchPerformanceMetrics.empty() {
    return BatchPerformanceMetrics(
      totalBatches: 0,
      completedBatches: 0,
      completionRate: 0.0,
      averageOrdersPerBatch: 0.0,
      averageDistance: 0.0,
      averageDuration: Duration.zero,
      averageEfficiencyScore: 0.0,
      totalOrders: 0,
      successfulDeliveries: 0,
      lastUpdated: DateTime.now(),
    );
  }

  BatchPerformanceMetrics copyWith({
    int? totalBatches,
    int? completedBatches,
    double? completionRate,
    double? averageOrdersPerBatch,
    double? averageDistance,
    Duration? averageDuration,
    double? averageEfficiencyScore,
    int? totalOrders,
    int? successfulDeliveries,
    DateTime? lastUpdated,
  }) {
    return BatchPerformanceMetrics(
      totalBatches: totalBatches ?? this.totalBatches,
      completedBatches: completedBatches ?? this.completedBatches,
      completionRate: completionRate ?? this.completionRate,
      averageOrdersPerBatch: averageOrdersPerBatch ?? this.averageOrdersPerBatch,
      averageDistance: averageDistance ?? this.averageDistance,
      averageDuration: averageDuration ?? this.averageDuration,
      averageEfficiencyScore: averageEfficiencyScore ?? this.averageEfficiencyScore,
      totalOrders: totalOrders ?? this.totalOrders,
      successfulDeliveries: successfulDeliveries ?? this.successfulDeliveries,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Driver performance insights for comprehensive analytics
@immutable
class DriverPerformanceInsights {
  final String driverId;
  final String driverName;
  final double overallRating;
  final double efficiencyScore;
  final double punctualityScore;
  final double customerSatisfactionScore;
  final int totalDeliveries;
  final int onTimeDeliveries;
  final double onTimeRate;
  final Duration averageDeliveryTime;
  final double averageDistancePerDelivery;
  final int totalBatchesCompleted;
  final double averageBatchEfficiency;
  final List<PerformanceTrend> trends;
  final List<PerformanceInsight> insights;
  final DateTime? lastUpdated;

  const DriverPerformanceInsights({
    required this.driverId,
    required this.driverName,
    required this.overallRating,
    required this.efficiencyScore,
    required this.punctualityScore,
    required this.customerSatisfactionScore,
    required this.totalDeliveries,
    required this.onTimeDeliveries,
    required this.averageDeliveryTime,
    required this.averageDistancePerDelivery,
    required this.totalBatchesCompleted,
    required this.averageBatchEfficiency,
    required this.trends,
    required this.insights,
    this.lastUpdated,
  }) : onTimeRate = totalDeliveries > 0 ? onTimeDeliveries / totalDeliveries : 0.0;

  factory DriverPerformanceInsights.empty() {
    return DriverPerformanceInsights(
      driverId: '',
      driverName: '',
      overallRating: 0.0,
      efficiencyScore: 0.0,
      punctualityScore: 0.0,
      customerSatisfactionScore: 0.0,
      totalDeliveries: 0,
      onTimeDeliveries: 0,
      averageDeliveryTime: Duration.zero,
      averageDistancePerDelivery: 0.0,
      totalBatchesCompleted: 0,
      averageBatchEfficiency: 0.0,
      trends: [],
      insights: [],
      lastUpdated: DateTime.now(),
    );
  }

  DriverPerformanceInsights copyWith({
    String? driverId,
    String? driverName,
    double? overallRating,
    double? efficiencyScore,
    double? punctualityScore,
    double? customerSatisfactionScore,
    int? totalDeliveries,
    int? onTimeDeliveries,
    Duration? averageDeliveryTime,
    double? averageDistancePerDelivery,
    int? totalBatchesCompleted,
    double? averageBatchEfficiency,
    List<PerformanceTrend>? trends,
    List<PerformanceInsight>? insights,
    DateTime? lastUpdated,
  }) {
    return DriverPerformanceInsights(
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      overallRating: overallRating ?? this.overallRating,
      efficiencyScore: efficiencyScore ?? this.efficiencyScore,
      punctualityScore: punctualityScore ?? this.punctualityScore,
      customerSatisfactionScore: customerSatisfactionScore ?? this.customerSatisfactionScore,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      onTimeDeliveries: onTimeDeliveries ?? this.onTimeDeliveries,
      averageDeliveryTime: averageDeliveryTime ?? this.averageDeliveryTime,
      averageDistancePerDelivery: averageDistancePerDelivery ?? this.averageDistancePerDelivery,
      totalBatchesCompleted: totalBatchesCompleted ?? this.totalBatchesCompleted,
      averageBatchEfficiency: averageBatchEfficiency ?? this.averageBatchEfficiency,
      trends: trends ?? this.trends,
      insights: insights ?? this.insights,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Performance trend data for analytics visualization
@immutable
class PerformanceTrend {
  final String metric;
  final String period;
  final double value;
  final double previousValue;
  final double changePercentage;
  final TrendDirection direction;
  final DateTime timestamp;

  const PerformanceTrend({
    required this.metric,
    required this.period,
    required this.value,
    required this.previousValue,
    required this.changePercentage,
    required this.direction,
    required this.timestamp,
  });

  factory PerformanceTrend.fromValues({
    required String metric,
    required String period,
    required double current,
    required double previous,
    required DateTime timestamp,
  }) {
    final change = previous > 0 ? ((current - previous) / previous) * 100 : 0.0;
    final direction = change > 0 
        ? TrendDirection.up 
        : change < 0 
            ? TrendDirection.down 
            : TrendDirection.stable;

    return PerformanceTrend(
      metric: metric,
      period: period,
      value: current,
      previousValue: previous,
      changePercentage: change,
      direction: direction,
      timestamp: timestamp,
    );
  }
}

/// Performance insight for actionable recommendations
@immutable
class PerformanceInsight {
  final String id;
  final String title;
  final String description;
  final InsightType type;
  final InsightPriority priority;
  final String recommendation;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const PerformanceInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.recommendation,
    required this.data,
    required this.timestamp,
  });

  factory PerformanceInsight.efficiency({
    required String title,
    required String description,
    required String recommendation,
    required Map<String, dynamic> data,
  }) {
    return PerformanceInsight(
      id: 'efficiency_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      type: InsightType.efficiency,
      priority: InsightPriority.medium,
      recommendation: recommendation,
      data: data,
      timestamp: DateTime.now(),
    );
  }

  factory PerformanceInsight.punctuality({
    required String title,
    required String description,
    required String recommendation,
    required Map<String, dynamic> data,
  }) {
    return PerformanceInsight(
      id: 'punctuality_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      type: InsightType.punctuality,
      priority: InsightPriority.high,
      recommendation: recommendation,
      data: data,
      timestamp: DateTime.now(),
    );
  }

  factory PerformanceInsight.customerSatisfaction({
    required String title,
    required String description,
    required String recommendation,
    required Map<String, dynamic> data,
  }) {
    return PerformanceInsight(
      id: 'satisfaction_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      type: InsightType.customerSatisfaction,
      priority: InsightPriority.high,
      recommendation: recommendation,
      data: data,
      timestamp: DateTime.now(),
    );
  }
}

/// Batch delivery report for comprehensive reporting
@immutable
class BatchDeliveryReport {
  final String reportId;
  final String driverId;
  final String batchId;
  final DateTime reportDate;
  final BatchPerformanceMetrics metrics;
  final List<OrderDeliveryDetail> orderDetails;
  final Map<String, dynamic> summary;
  final List<String> issues;
  final List<String> achievements;

  const BatchDeliveryReport({
    required this.reportId,
    required this.driverId,
    required this.batchId,
    required this.reportDate,
    required this.metrics,
    required this.orderDetails,
    required this.summary,
    required this.issues,
    required this.achievements,
  });
}

/// Order delivery detail for reporting
@immutable
class OrderDeliveryDetail {
  final String orderId;
  final String customerName;
  final String vendorName;
  final DateTime scheduledTime;
  final DateTime? actualDeliveryTime;
  final Duration? deliveryDuration;
  final String status;
  final double? customerRating;
  final String? customerFeedback;
  final bool wasOnTime;

  const OrderDeliveryDetail({
    required this.orderId,
    required this.customerName,
    required this.vendorName,
    required this.scheduledTime,
    this.actualDeliveryTime,
    this.deliveryDuration,
    required this.status,
    this.customerRating,
    this.customerFeedback,
    required this.wasOnTime,
  });
}

/// Enums for analytics
enum TrendDirection { up, down, stable }

enum InsightType {
  efficiency,
  punctuality,
  customerSatisfaction,
  routeOptimization,
  batchManagement,
}

enum InsightPriority { low, medium, high, critical }

/// Analytics event for tracking
@immutable
class AnalyticsEvent {
  final String eventId;
  final String eventType;
  final String driverId;
  final String? batchId;
  final String? orderId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const AnalyticsEvent({
    required this.eventId,
    required this.eventType,
    required this.driverId,
    this.batchId,
    this.orderId,
    required this.data,
    required this.timestamp,
  });

  factory AnalyticsEvent.batchCreated({
    required String driverId,
    required String batchId,
    required Map<String, dynamic> data,
  }) {
    return AnalyticsEvent(
      eventId: 'batch_created_${DateTime.now().millisecondsSinceEpoch}',
      eventType: 'batch_created',
      driverId: driverId,
      batchId: batchId,
      data: data,
      timestamp: DateTime.now(),
    );
  }

  factory AnalyticsEvent.orderCompleted({
    required String driverId,
    required String batchId,
    required String orderId,
    required Map<String, dynamic> data,
  }) {
    return AnalyticsEvent(
      eventId: 'order_completed_${DateTime.now().millisecondsSinceEpoch}',
      eventType: 'order_completed',
      driverId: driverId,
      batchId: batchId,
      orderId: orderId,
      data: data,
      timestamp: DateTime.now(),
    );
  }
}
