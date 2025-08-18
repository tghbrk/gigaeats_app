import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/vendor_repository.dart';
import '../../../../presentation/providers/repository_providers.dart';

/// Vendor Analytics Parameters for date filtering
@immutable
class VendorAnalyticsParams {
  final String vendorId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String period; // 'today', 'week', 'month', 'year', 'custom'

  const VendorAnalyticsParams({
    required this.vendorId,
    this.startDate,
    this.endDate,
    this.period = 'month',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorAnalyticsParams &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          period == other.period;

  @override
  int get hashCode =>
      vendorId.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      period.hashCode;

  VendorAnalyticsParams copyWith({
    String? vendorId,
    DateTime? startDate,
    DateTime? endDate,
    String? period,
  }) {
    return VendorAnalyticsParams(
      vendorId: vendorId ?? this.vendorId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      period: period ?? this.period,
    );
  }

  /// Get date range for predefined periods
  Map<String, DateTime?> getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (period) {
      case 'today':
        return {
          'startDate': today,
          'endDate': today.add(const Duration(days: 1)),
        };
      case 'week':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return {
          'startDate': weekStart,
          'endDate': weekStart.add(const Duration(days: 7)),
        };
      case 'month':
        final monthStart = DateTime(now.year, now.month, 1);
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        return {
          'startDate': monthStart,
          'endDate': nextMonth,
        };
      case 'year':
        final yearStart = DateTime(now.year, 1, 1);
        final nextYear = DateTime(now.year + 1, 1, 1);
        return {
          'startDate': yearStart,
          'endDate': nextYear,
        };
      case 'custom':
        return {
          'startDate': startDate,
          'endDate': endDate,
        };
      default:
        return {
          'startDate': DateTime(now.year, now.month, 1),
          'endDate': DateTime(now.year, now.month + 1, 1),
        };
    }
  }
}

/// Enhanced Vendor Analytics Provider with date filtering
final vendorAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, VendorAnalyticsParams>((ref, params) async {
  debugPrint('📊 [VENDOR-ANALYTICS] Loading analytics for vendor: ${params.vendorId}, period: ${params.period}');
  
  final vendorRepository = ref.watch(vendorRepositoryProvider);
  final dateRange = params.getDateRange();
  
  try {
    // Get filtered metrics based on date range
    final metrics = await vendorRepository.getVendorFilteredMetrics(
      params.vendorId,
      startDate: dateRange['startDate'],
      endDate: dateRange['endDate'],
    );
    
    debugPrint('📊 [VENDOR-ANALYTICS] Loaded metrics: $metrics');
    return metrics;
  } catch (e) {
    debugPrint('⚠️ [VENDOR-ANALYTICS] Error loading analytics: $e');
    rethrow;
  }
});

/// Vendor Analytics Summary Provider for overview cards
final vendorAnalyticsSummaryProvider = FutureProvider.family<Map<String, dynamic>, VendorAnalyticsParams>((ref, params) async {
  debugPrint('📊 [VENDOR-ANALYTICS-SUMMARY] Loading summary for vendor: ${params.vendorId}');
  
  final vendorRepository = ref.watch(vendorRepositoryProvider);
  final dateRange = params.getDateRange();
  
  try {
    // Get comprehensive analytics data
    final analytics = await vendorRepository.getVendorAnalytics(
      params.vendorId,
      startDate: dateRange['startDate'],
      endDate: dateRange['endDate'],
    );
    
    // Calculate summary metrics from analytics list
    final analyticsList = analytics as List<Map<String, dynamic>>;
    final totalRevenue = analyticsList.fold<double>(0, (sum, item) => sum + (item['revenue'] as num? ?? 0).toDouble());
    final totalOrders = analyticsList.fold<int>(0, (sum, item) => sum + (item['orders'] as int? ?? 0));
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    
    final summary = {
      'total_revenue': totalRevenue,
      'total_orders': totalOrders,
      'avg_order_value': avgOrderValue,
      'period': params.period,
      'start_date': dateRange['startDate']?.toIso8601String(),
      'end_date': dateRange['endDate']?.toIso8601String(),
      'analytics_data': analyticsList,
    };
    
    debugPrint('📊 [VENDOR-ANALYTICS-SUMMARY] Summary: revenue=$totalRevenue, orders=$totalOrders');
    return summary;
  } catch (e) {
    debugPrint('⚠️ [VENDOR-ANALYTICS-SUMMARY] Error loading summary: $e');
    // Return empty summary on error
    return {
      'total_revenue': 0.0,
      'total_orders': 0,
      'avg_order_value': 0.0,
      'period': params.period,
      'start_date': dateRange['startDate']?.toIso8601String(),
      'end_date': dateRange['endDate']?.toIso8601String(),
      'analytics_data': <Map<String, dynamic>>[],
    };
  }
});

/// Vendor Performance Metrics Provider for recent performance section
final vendorPerformanceMetricsProvider = FutureProvider.family<Map<String, dynamic>, VendorAnalyticsParams>((ref, params) async {
  debugPrint('📊 [VENDOR-PERFORMANCE] Loading performance metrics for vendor: ${params.vendorId}');
  
  final vendorRepository = ref.watch(vendorRepositoryProvider);
  final dateRange = params.getDateRange();
  
  try {
    // Get current period metrics
    final currentMetrics = await vendorRepository.getVendorFilteredMetrics(
      params.vendorId,
      startDate: dateRange['startDate'],
      endDate: dateRange['endDate'],
    );
    
    // Get total metrics (all time)
    final totalMetrics = await vendorRepository.getVendorDashboardMetrics(params.vendorId);
    
    final performance = {
      'current_period': {
        'orders': currentMetrics['total_orders'] ?? 0,
        'revenue': currentMetrics['total_revenue'] ?? 0.0,
        'avg_order_value': currentMetrics['avg_order_value'] ?? 0.0,
      },
      'total': {
        'orders': totalMetrics['total_orders'] ?? 0,
        'revenue': totalMetrics['total_revenue'] ?? 0.0,
        'pending_orders': totalMetrics['pending_orders'] ?? 0,
        'rating': totalMetrics['rating'] ?? 0.0,
        'total_reviews': totalMetrics['total_reviews'] ?? 0,
      },
      'period': params.period,
    };
    
    debugPrint('📊 [VENDOR-PERFORMANCE] Performance loaded successfully');
    return performance;
  } catch (e) {
    debugPrint('⚠️ [VENDOR-PERFORMANCE] Error loading performance: $e');
    rethrow;
  }
});

/// Current Vendor Analytics Params Provider
final currentVendorAnalyticsParamsProvider = StateProvider<VendorAnalyticsParams?>((ref) => null);

/// Helper provider to get current vendor analytics
final currentVendorAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final params = ref.watch(currentVendorAnalyticsParamsProvider);
  if (params == null) {
    return {};
  }
  
  return await ref.watch(vendorAnalyticsProvider(params).future);
});
