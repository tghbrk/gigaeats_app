import 'package:equatable/equatable.dart';

/// Comprehensive driver performance statistics model
/// Contains all performance metrics displayed in the driver profile
class DriverPerformanceStats extends Equatable {
  final int totalDeliveries;
  final int successfulDeliveries;
  final double averageDeliveryTimeMinutes;
  final double customerRating;
  final int totalRatings;
  final double onTimeDeliveryRate;
  final double totalDistanceKm;
  final double totalEarningsToday;
  final double totalEarningsWeek;
  final double totalEarningsMonth;
  final double averageEarningsPerDelivery;
  final int deliveriesToday;
  final int deliveriesWeek;
  final int deliveriesMonth;
  final DateTime lastUpdated;
  final Map<String, dynamic>? additionalMetrics;

  const DriverPerformanceStats({
    required this.totalDeliveries,
    required this.successfulDeliveries,
    required this.averageDeliveryTimeMinutes,
    required this.customerRating,
    required this.totalRatings,
    required this.onTimeDeliveryRate,
    required this.totalDistanceKm,
    required this.totalEarningsToday,
    required this.totalEarningsWeek,
    required this.totalEarningsMonth,
    required this.averageEarningsPerDelivery,
    required this.deliveriesToday,
    required this.deliveriesWeek,
    required this.deliveriesMonth,
    required this.lastUpdated,
    this.additionalMetrics,
  });

  factory DriverPerformanceStats.fromJson(Map<String, dynamic> json) {
    return DriverPerformanceStats(
      totalDeliveries: (json['total_deliveries'] as num?)?.toInt() ?? 0,
      successfulDeliveries: (json['successful_deliveries'] as num?)?.toInt() ?? 0,
      averageDeliveryTimeMinutes: (json['average_delivery_time_minutes'] as num?)?.toDouble() ?? 0.0,
      customerRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (json['rating_count'] as num?)?.toInt() ?? 0,
      onTimeDeliveryRate: (json['success_rate'] as num?)?.toDouble() ?? 0.0,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0.0,
      totalEarningsToday: (json['earnings_today'] as num?)?.toDouble() ?? 0.0,
      totalEarningsWeek: (json['earnings_week'] as num?)?.toDouble() ?? 0.0,
      totalEarningsMonth: (json['earnings_month'] as num?)?.toDouble() ?? 0.0,
      averageEarningsPerDelivery: (json['average_earnings_per_delivery'] as num?)?.toDouble() ?? 0.0,
      deliveriesToday: (json['deliveries_today'] as num?)?.toInt() ?? 0,
      deliveriesWeek: (json['deliveries_week'] as num?)?.toInt() ?? 0,
      deliveriesMonth: (json['deliveries_month'] as num?)?.toInt() ?? 0,
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
      additionalMetrics: json['additional_metrics'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_deliveries': totalDeliveries,
      'successful_deliveries': successfulDeliveries,
      'average_delivery_time_minutes': averageDeliveryTimeMinutes,
      'average_rating': customerRating,
      'rating_count': totalRatings,
      'success_rate': onTimeDeliveryRate,
      'total_distance_km': totalDistanceKm,
      'earnings_today': totalEarningsToday,
      'earnings_week': totalEarningsWeek,
      'earnings_month': totalEarningsMonth,
      'average_earnings_per_delivery': averageEarningsPerDelivery,
      'deliveries_today': deliveriesToday,
      'deliveries_week': deliveriesWeek,
      'deliveries_month': deliveriesMonth,
      'last_updated': lastUpdated.toIso8601String(),
      'additional_metrics': additionalMetrics,
    };
  }

  /// Create empty stats for loading/error states
  factory DriverPerformanceStats.empty() {
    return DriverPerformanceStats(
      totalDeliveries: 0,
      successfulDeliveries: 0,
      averageDeliveryTimeMinutes: 0.0,
      customerRating: 0.0,
      totalRatings: 0,
      onTimeDeliveryRate: 0.0,
      totalDistanceKm: 0.0,
      totalEarningsToday: 0.0,
      totalEarningsWeek: 0.0,
      totalEarningsMonth: 0.0,
      averageEarningsPerDelivery: 0.0,
      deliveriesToday: 0,
      deliveriesWeek: 0,
      deliveriesMonth: 0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get success rate as percentage
  double get successRatePercentage => 
      totalDeliveries > 0 ? (successfulDeliveries / totalDeliveries) * 100 : 0.0;

  /// Get formatted average delivery time
  String get formattedAverageDeliveryTime {
    if (averageDeliveryTimeMinutes < 60) {
      return '${averageDeliveryTimeMinutes.round()} min';
    } else {
      final hours = (averageDeliveryTimeMinutes / 60).floor();
      final minutes = (averageDeliveryTimeMinutes % 60).round();
      return '${hours}h ${minutes}m';
    }
  }

  /// Get formatted distance
  String get formattedDistance {
    if (totalDistanceKm < 1) {
      return '${(totalDistanceKm * 1000).round()} m';
    } else {
      return '${totalDistanceKm.toStringAsFixed(1)} km';
    }
  }

  DriverPerformanceStats copyWith({
    int? totalDeliveries,
    int? successfulDeliveries,
    double? averageDeliveryTimeMinutes,
    double? customerRating,
    int? totalRatings,
    double? onTimeDeliveryRate,
    double? totalDistanceKm,
    double? totalEarningsToday,
    double? totalEarningsWeek,
    double? totalEarningsMonth,
    double? averageEarningsPerDelivery,
    int? deliveriesToday,
    int? deliveriesWeek,
    int? deliveriesMonth,
    DateTime? lastUpdated,
    Map<String, dynamic>? additionalMetrics,
  }) {
    return DriverPerformanceStats(
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      successfulDeliveries: successfulDeliveries ?? this.successfulDeliveries,
      averageDeliveryTimeMinutes: averageDeliveryTimeMinutes ?? this.averageDeliveryTimeMinutes,
      customerRating: customerRating ?? this.customerRating,
      totalRatings: totalRatings ?? this.totalRatings,
      onTimeDeliveryRate: onTimeDeliveryRate ?? this.onTimeDeliveryRate,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      totalEarningsToday: totalEarningsToday ?? this.totalEarningsToday,
      totalEarningsWeek: totalEarningsWeek ?? this.totalEarningsWeek,
      totalEarningsMonth: totalEarningsMonth ?? this.totalEarningsMonth,
      averageEarningsPerDelivery: averageEarningsPerDelivery ?? this.averageEarningsPerDelivery,
      deliveriesToday: deliveriesToday ?? this.deliveriesToday,
      deliveriesWeek: deliveriesWeek ?? this.deliveriesWeek,
      deliveriesMonth: deliveriesMonth ?? this.deliveriesMonth,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      additionalMetrics: additionalMetrics ?? this.additionalMetrics,
    );
  }

  @override
  List<Object?> get props => [
        totalDeliveries,
        successfulDeliveries,
        averageDeliveryTimeMinutes,
        customerRating,
        totalRatings,
        onTimeDeliveryRate,
        totalDistanceKm,
        totalEarningsToday,
        totalEarningsWeek,
        totalEarningsMonth,
        averageEarningsPerDelivery,
        deliveriesToday,
        deliveriesWeek,
        deliveriesMonth,
        lastUpdated,
        additionalMetrics,
      ];
}
