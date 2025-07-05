import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/template_usage_analytics.dart';

/// Service for tracking template usage and generating analytics
class TemplateUsageTrackingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Track template usage when an order is created
  Future<void> trackTemplateUsage({
    required String orderId,
    required String templateId,
    required String vendorId,
    required double revenueAmount,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('📊 [USAGE-TRACKING] Tracking template usage: $templateId for order: $orderId');

      // Record the usage event
      await _supabase.from('template_usage_events').insert({
        'order_id': orderId,
        'template_id': templateId,
        'vendor_id': vendorId,
        'revenue_amount': revenueAmount,
        'metadata': metadata,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update daily analytics
      await _updateDailyAnalytics(templateId, vendorId, revenueAmount);

      debugPrint('✅ [USAGE-TRACKING] Template usage tracked successfully');
    } catch (e) {
      debugPrint('❌ [USAGE-TRACKING] Error tracking template usage: $e');
      // Don't throw here as this is a background operation
    }
  }

  /// Track multiple template usages for an order
  Future<void> trackMultipleTemplateUsage({
    required String orderId,
    required List<Map<String, dynamic>> templateUsages,
  }) async {
    try {
      debugPrint('📊 [USAGE-TRACKING] Tracking multiple template usages for order: $orderId');

      for (final usage in templateUsages) {
        await trackTemplateUsage(
          orderId: orderId,
          templateId: usage['template_id'],
          vendorId: usage['vendor_id'],
          revenueAmount: usage['revenue_amount'],
          metadata: usage['metadata'],
        );
      }

      debugPrint('✅ [USAGE-TRACKING] Multiple template usages tracked successfully');
    } catch (e) {
      debugPrint('❌ [USAGE-TRACKING] Error tracking multiple template usages: $e');
    }
  }

  /// Update daily analytics aggregation
  Future<void> _updateDailyAnalytics(String templateId, String vendorId, double revenueAmount) async {
    try {
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Use upsert to update or create daily analytics
      await _supabase.rpc('upsert_template_daily_analytics', params: {
        'p_template_id': templateId,
        'p_vendor_id': vendorId,
        'p_analytics_date': dateString,
        'p_revenue_amount': revenueAmount,
      });
    } catch (e) {
      debugPrint('❌ [USAGE-TRACKING] Error updating daily analytics: $e');
    }
  }

  /// Generate analytics summary for a vendor
  Future<TemplateAnalyticsSummary> generateAnalyticsSummary({
    required String vendorId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      debugPrint('📊 [USAGE-TRACKING] Generating analytics summary for vendor: $vendorId');

      final response = await _supabase.rpc('get_template_analytics_summary', params: {
        'p_vendor_id': vendorId,
        'p_start_date': startDate.toIso8601String().split('T')[0],
        'p_end_date': endDate.toIso8601String().split('T')[0],
      });

      if (response == null || response.isEmpty) {
        return TemplateAnalyticsSummary(
          vendorId: vendorId,
          periodStart: startDate,
          periodEnd: endDate,
        );
      }

      final data = response[0];
      return TemplateAnalyticsSummary.fromJson({
        'vendor_id': vendorId,
        'total_templates': data['total_templates'] ?? 0,
        'active_templates': data['active_templates'] ?? 0,
        'total_menu_items_using_templates': data['total_menu_items_using_templates'] ?? 0,
        'total_orders_with_templates': data['total_orders_with_templates'] ?? 0,
        'total_revenue_from_templates': data['total_revenue_from_templates'] ?? 0.0,
        'period_start': startDate.toIso8601String(),
        'period_end': endDate.toIso8601String(),
        'top_performing_templates': [], // Will be populated separately
      });
    } catch (e) {
      debugPrint('❌ [USAGE-TRACKING] Error generating analytics summary: $e');
      return TemplateAnalyticsSummary(
        vendorId: vendorId,
        periodStart: startDate,
        periodEnd: endDate,
      );
    }
  }

  /// Get real-time template usage statistics
  Future<Map<String, dynamic>> getRealtimeUsageStats(String vendorId) async {
    try {
      debugPrint('📊 [USAGE-TRACKING] Getting real-time usage stats for vendor: $vendorId');

      final response = await _supabase.rpc('get_realtime_template_stats', params: {
        'p_vendor_id': vendorId,
      });

      if (response == null || response.isEmpty) {
        return {
          'total_templates': 0,
          'active_templates': 0,
          'today_orders': 0,
          'today_revenue': 0.0,
          'this_week_orders': 0,
          'this_week_revenue': 0.0,
        };
      }

      return response[0];
    } catch (e) {
      debugPrint('❌ [USAGE-TRACKING] Error getting real-time stats: $e');
      return {
        'total_templates': 0,
        'active_templates': 0,
        'today_orders': 0,
        'today_revenue': 0.0,
        'this_week_orders': 0,
        'this_week_revenue': 0.0,
      };
    }
  }

  /// Track template performance metrics
  Future<void> updateTemplatePerformanceMetrics({
    required String templateId,
    required String vendorId,
  }) async {
    try {
      debugPrint('📊 [USAGE-TRACKING] Updating performance metrics for template: $templateId');

      await _supabase.rpc('update_template_performance_metrics', params: {
        'p_template_id': templateId,
        'p_vendor_id': vendorId,
      });

      debugPrint('✅ [USAGE-TRACKING] Performance metrics updated successfully');
    } catch (e) {
      debugPrint('❌ [USAGE-TRACKING] Error updating performance metrics: $e');
    }
  }

  /// Get template usage trends for charts
  Future<List<Map<String, dynamic>>> getUsageTrends({
    required String vendorId,
    required DateTime startDate,
    required DateTime endDate,
    String granularity = 'daily', // 'daily', 'weekly', 'monthly'
  }) async {
    try {
      debugPrint('📊 [USAGE-TRACKING] Getting usage trends for vendor: $vendorId');

      final response = await _supabase.rpc('get_template_usage_trends', params: {
        'p_vendor_id': vendorId,
        'p_start_date': startDate.toIso8601String().split('T')[0],
        'p_end_date': endDate.toIso8601String().split('T')[0],
        'p_granularity': granularity,
      });

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('❌ [USAGE-TRACKING] Error getting usage trends: $e');
      return [];
    }
  }

  /// Get template comparison data
  Future<List<Map<String, dynamic>>> getTemplateComparison({
    required String vendorId,
    required List<String> templateIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      debugPrint('📊 [USAGE-TRACKING] Getting template comparison data');

      final response = await _supabase.rpc('compare_template_performance', params: {
        'p_vendor_id': vendorId,
        'p_template_ids': templateIds,
        'p_start_date': startDate.toIso8601String().split('T')[0],
        'p_end_date': endDate.toIso8601String().split('T')[0],
      });

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('❌ [USAGE-TRACKING] Error getting template comparison: $e');
      return [];
    }
  }

  /// Export analytics data for reporting
  Future<Map<String, dynamic>> exportAnalyticsData({
    required String vendorId,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? templateIds,
  }) async {
    try {
      debugPrint('📊 [USAGE-TRACKING] Exporting analytics data for vendor: $vendorId');

      final response = await _supabase.rpc('export_template_analytics', params: {
        'p_vendor_id': vendorId,
        'p_start_date': startDate.toIso8601String().split('T')[0],
        'p_end_date': endDate.toIso8601String().split('T')[0],
        'p_template_ids': templateIds,
      });

      return response ?? {};
    } catch (e) {
      debugPrint('❌ [USAGE-TRACKING] Error exporting analytics data: $e');
      return {};
    }
  }

  /// Clean up old analytics data
  Future<void> cleanupOldAnalytics({
    int retentionDays = 365,
  }) async {
    try {
      debugPrint('🧹 [USAGE-TRACKING] Cleaning up analytics data older than $retentionDays days');

      await _supabase.rpc('cleanup_old_template_analytics', params: {
        'p_retention_days': retentionDays,
      });

      debugPrint('✅ [USAGE-TRACKING] Old analytics data cleaned up successfully');
    } catch (e) {
      debugPrint('❌ [USAGE-TRACKING] Error cleaning up old analytics: $e');
    }
  }

  /// Get template usage insights
  Future<List<Map<String, dynamic>>> getUsageInsights({
    required String vendorId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      debugPrint('💡 [USAGE-TRACKING] Getting usage insights for vendor: $vendorId');

      final response = await _supabase.rpc('get_template_usage_insights', params: {
        'p_vendor_id': vendorId,
        'p_start_date': startDate.toIso8601String().split('T')[0],
        'p_end_date': endDate.toIso8601String().split('T')[0],
      });

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('❌ [USAGE-TRACKING] Error getting usage insights: $e');
      return [];
    }
  }
}
