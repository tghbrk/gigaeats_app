import 'package:equatable/equatable.dart';

import '../../../vendors/data/models/driver.dart';
import 'driver_order.dart';

/// Dashboard data model for driver interface
class DriverDashboardData extends Equatable {
  final DriverStatus driverStatus;
  final bool isOnline;
  final List<DriverOrder> activeOrders;
  final DriverTodaySummary todaySummary;
  final DriverPerformanceMetrics? performanceMetrics;
  final DateTime lastUpdated;

  const DriverDashboardData({
    required this.driverStatus,
    required this.isOnline,
    required this.activeOrders,
    required this.todaySummary,
    this.performanceMetrics,
    required this.lastUpdated,
  });

  factory DriverDashboardData.empty() {
    return DriverDashboardData(
      driverStatus: DriverStatus.offline,
      isOnline: false,
      activeOrders: [],
      todaySummary: DriverTodaySummary.empty(),
      performanceMetrics: null,
      lastUpdated: DateTime.now(),
    );
  }

  DriverDashboardData copyWith({
    DriverStatus? driverStatus,
    bool? isOnline,
    List<DriverOrder>? activeOrders,
    DriverTodaySummary? todaySummary,
    DriverPerformanceMetrics? performanceMetrics,
    DateTime? lastUpdated,
  }) {
    return DriverDashboardData(
      driverStatus: driverStatus ?? this.driverStatus,
      isOnline: isOnline ?? this.isOnline,
      activeOrders: activeOrders ?? this.activeOrders,
      todaySummary: todaySummary ?? this.todaySummary,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        driverStatus,
        isOnline,
        activeOrders,
        todaySummary,
        performanceMetrics,
        lastUpdated,
      ];
}

/// Today's summary data for driver
class DriverTodaySummary extends Equatable {
  final int deliveriesCompleted;
  final double earningsToday;
  final double successRate;
  final double averageRating;
  final int totalOrders;

  const DriverTodaySummary({
    required this.deliveriesCompleted,
    required this.earningsToday,
    required this.successRate,
    required this.averageRating,
    required this.totalOrders,
  });

  factory DriverTodaySummary.empty() {
    return const DriverTodaySummary(
      deliveriesCompleted: 0,
      earningsToday: 0.0,
      successRate: 0.0,
      averageRating: 0.0,
      totalOrders: 0,
    );
  }

  factory DriverTodaySummary.fromPerformanceData(Map<String, dynamic> data) {
    return DriverTodaySummary(
      deliveriesCompleted: (data['today_successful_deliveries'] as num?)?.toInt() ?? 0,
      earningsToday: (data['today_earnings'] as num?)?.toDouble() ?? 0.0,
      successRate: (data['today_success_rate'] as num?)?.toDouble() ?? 0.0,
      averageRating: (data['today_rating'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (data['today_total_deliveries'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        deliveriesCompleted,
        earningsToday,
        successRate,
        averageRating,
        totalOrders,
      ];
}

/// Driver performance metrics
class DriverPerformanceMetrics extends Equatable {
  final int weeklyDeliveries;
  final double weeklyEarnings;
  final int monthlyDeliveries;
  final double monthlyEarnings;
  final double overallRating;
  final double overallSuccessRate;

  const DriverPerformanceMetrics({
    required this.weeklyDeliveries,
    required this.weeklyEarnings,
    required this.monthlyDeliveries,
    required this.monthlyEarnings,
    required this.overallRating,
    required this.overallSuccessRate,
  });

  factory DriverPerformanceMetrics.fromPerformanceData(Map<String, dynamic> data) {
    return DriverPerformanceMetrics(
      weeklyDeliveries: (data['week_successful_deliveries'] as num?)?.toInt() ?? 0,
      weeklyEarnings: (data['week_earnings'] as num?)?.toDouble() ?? 0.0,
      monthlyDeliveries: (data['month_successful_deliveries'] as num?)?.toInt() ?? 0,
      monthlyEarnings: (data['month_earnings'] as num?)?.toDouble() ?? 0.0,
      overallRating: (data['overall_rating'] as num?)?.toDouble() ?? 0.0,
      overallSuccessRate: (data['overall_success_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        weeklyDeliveries,
        weeklyEarnings,
        monthlyDeliveries,
        monthlyEarnings,
        overallRating,
        overallSuccessRate,
      ];
}
