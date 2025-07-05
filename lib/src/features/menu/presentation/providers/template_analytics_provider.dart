import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/template_usage_analytics.dart';
import '../../data/repositories/customization_template_repository.dart';
import '../../../../presentation/providers/repository_providers.dart';

/// State for template analytics
class TemplateAnalyticsState {
  final TemplateAnalyticsSummary? summary;
  final List<TemplateUsageAnalytics> usageAnalytics;
  final List<TemplatePerformanceMetrics> performanceMetrics;
  final Map<String, List<TemplateUsageAnalytics>> trendData;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final DateTime periodStart;
  final DateTime periodEnd;

  const TemplateAnalyticsState({
    this.summary,
    this.usageAnalytics = const [],
    this.performanceMetrics = const [],
    this.trendData = const {},
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdated,
    required this.periodStart,
    required this.periodEnd,
  });

  TemplateAnalyticsState copyWith({
    TemplateAnalyticsSummary? summary,
    List<TemplateUsageAnalytics>? usageAnalytics,
    List<TemplatePerformanceMetrics>? performanceMetrics,
    Map<String, List<TemplateUsageAnalytics>>? trendData,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdated,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    return TemplateAnalyticsState(
      summary: summary ?? this.summary,
      usageAnalytics: usageAnalytics ?? this.usageAnalytics,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      trendData: trendData ?? this.trendData,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
    );
  }
}

/// Template analytics notifier
class TemplateAnalyticsNotifier extends StateNotifier<TemplateAnalyticsState> {
  final CustomizationTemplateRepository _repository;

  TemplateAnalyticsNotifier(this._repository)
      : super(TemplateAnalyticsState(
          periodStart: DateTime.now().subtract(const Duration(days: 30)),
          periodEnd: DateTime.now(),
        ));

  /// Load analytics data for a vendor
  Future<void> loadAnalytics({
    required String vendorId,
    DateTime? startDate,
    DateTime? endDate,
    bool refresh = false,
  }) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      periodStart: startDate,
      periodEnd: endDate,
    );

    try {
      debugPrint('📊 [TEMPLATE-ANALYTICS] Loading analytics for vendor: $vendorId');

      // Load analytics summary
      final summaryFuture = _repository.getAnalyticsSummary(
        vendorId: vendorId,
        periodStart: startDate ?? state.periodStart,
        periodEnd: endDate ?? state.periodEnd,
      );

      // Load usage analytics
      final usageAnalyticsFuture = _repository.getTemplateAnalytics(
        vendorId: vendorId,
        startDate: startDate ?? state.periodStart,
        endDate: endDate ?? state.periodEnd,
        limit: 100,
      );

      // Load performance metrics
      final performanceMetricsFuture = _repository.getTemplatePerformanceMetrics(
        vendorId: vendorId,
        startDate: startDate ?? state.periodStart,
        endDate: endDate ?? state.periodEnd,
      );

      // Wait for all data
      final results = await Future.wait([
        summaryFuture,
        usageAnalyticsFuture,
        performanceMetricsFuture,
      ]);

      final summary = results[0] as TemplateAnalyticsSummary;
      final usageAnalytics = results[1] as List<TemplateUsageAnalytics>;
      final performanceMetrics = results[2] as List<TemplatePerformanceMetrics>;

      // Generate trend data
      final trendData = _generateTrendData(usageAnalytics);

      state = state.copyWith(
        summary: summary,
        usageAnalytics: usageAnalytics,
        performanceMetrics: performanceMetrics,
        trendData: trendData,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      debugPrint('✅ [TEMPLATE-ANALYTICS] Analytics loaded successfully');
    } catch (e) {
      debugPrint('❌ [TEMPLATE-ANALYTICS] Error loading analytics: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update date range and reload analytics
  Future<void> updateDateRange({
    required String vendorId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await loadAnalytics(
      vendorId: vendorId,
      startDate: startDate,
      endDate: endDate,
      refresh: true,
    );
  }

  /// Get top performing templates
  List<TemplatePerformanceMetrics> getTopPerformingTemplates({int limit = 5}) {
    final sorted = List<TemplatePerformanceMetrics>.from(state.performanceMetrics);
    sorted.sort((a, b) => b.performanceScore.compareTo(a.performanceScore));
    return sorted.take(limit).toList();
  }

  /// Get underperforming templates
  List<TemplatePerformanceMetrics> getUnderperformingTemplates({int limit = 5}) {
    final sorted = List<TemplatePerformanceMetrics>.from(state.performanceMetrics);
    sorted.sort((a, b) => a.performanceScore.compareTo(b.performanceScore));
    return sorted.take(limit).toList();
  }

  /// Get templates by performance grade
  Map<String, List<TemplatePerformanceMetrics>> getTemplatesByGrade() {
    final gradeMap = <String, List<TemplatePerformanceMetrics>>{};
    
    for (final template in state.performanceMetrics) {
      final grade = template.performanceGrade;
      gradeMap[grade] = gradeMap[grade] ?? [];
      gradeMap[grade]!.add(template);
    }
    
    return gradeMap;
  }

  /// Get revenue trend data for charts
  List<Map<String, dynamic>> getRevenueTrendData() {
    final trendData = <Map<String, dynamic>>[];
    
    for (final analytics in state.usageAnalytics) {
      trendData.add({
        'date': analytics.analyticsDate,
        'revenue': analytics.revenueGenerated,
        'orders': analytics.ordersCount,
      });
    }
    
    // Sort by date
    trendData.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    return trendData;
  }

  /// Get usage trend data for charts
  List<Map<String, dynamic>> getUsageTrendData() {
    final trendData = <Map<String, dynamic>>[];
    
    for (final analytics in state.usageAnalytics) {
      trendData.add({
        'date': analytics.analyticsDate,
        'usage': analytics.ordersCount,
        'menu_items': analytics.menuItemsCount,
      });
    }
    
    // Sort by date
    trendData.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    return trendData;
  }

  /// Generate trend data grouped by template
  Map<String, List<TemplateUsageAnalytics>> _generateTrendData(
    List<TemplateUsageAnalytics> analytics,
  ) {
    final trendMap = <String, List<TemplateUsageAnalytics>>{};
    
    for (final analytic in analytics) {
      trendMap[analytic.templateId] = trendMap[analytic.templateId] ?? [];
      trendMap[analytic.templateId]!.add(analytic);
    }
    
    // Sort each template's data by date
    for (final templateId in trendMap.keys) {
      trendMap[templateId]!.sort((a, b) => a.analyticsDate.compareTo(b.analyticsDate));
    }
    
    return trendMap;
  }

  /// Get analytics insights
  List<String> getAnalyticsInsights() {
    final insights = <String>[];
    final summary = state.summary;
    
    if (summary == null) return insights;

    // Template adoption insights
    final adoptionRate = summary.templateUtilizationRate;
    if (adoptionRate < 50) {
      insights.add('Consider promoting template usage - only ${adoptionRate.toStringAsFixed(1)}% of templates are actively used');
    } else if (adoptionRate > 80) {
      insights.add('Excellent template adoption rate of ${adoptionRate.toStringAsFixed(1)}%');
    }

    // Revenue insights
    final avgRevenue = summary.averageRevenuePerTemplate;
    if (avgRevenue > 50) {
      insights.add('Templates are generating strong revenue - RM${avgRevenue.toStringAsFixed(2)} average per template');
    } else if (avgRevenue < 10) {
      insights.add('Template revenue is low - consider optimizing pricing or options');
    }

    // Performance insights
    final topTemplates = getTopPerformingTemplates(limit: 3);
    if (topTemplates.isNotEmpty) {
      insights.add('Top performing template: ${topTemplates.first.templateName} with ${topTemplates.first.performanceGrade} grade');
    }

    return insights;
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Refresh analytics data
  Future<void> refresh(String vendorId) async {
    await loadAnalytics(
      vendorId: vendorId,
      startDate: state.periodStart,
      endDate: state.periodEnd,
      refresh: true,
    );
  }
}

/// Template analytics provider
final templateAnalyticsProvider = StateNotifierProvider.family<TemplateAnalyticsNotifier, TemplateAnalyticsState, String>(
  (ref, vendorId) {
    final repository = ref.watch(customizationTemplateRepositoryProvider);
    final notifier = TemplateAnalyticsNotifier(repository);
    
    // Auto-load analytics when provider is created
    Future.microtask(() => notifier.loadAnalytics(vendorId: vendorId));
    
    return notifier;
  },
);

/// Provider for template analytics summary
final templateAnalyticsSummaryProvider = Provider.family<TemplateAnalyticsSummary?, String>((ref, vendorId) {
  final analyticsState = ref.watch(templateAnalyticsProvider(vendorId));
  return analyticsState.summary;
});

/// Provider for top performing templates
final topPerformingTemplatesProvider = Provider.family<List<TemplatePerformanceMetrics>, String>((ref, vendorId) {
  final notifier = ref.read(templateAnalyticsProvider(vendorId).notifier);
  return notifier.getTopPerformingTemplates();
});

/// Provider for analytics insights
final templateAnalyticsInsightsProvider = Provider.family<List<String>, String>((ref, vendorId) {
  final notifier = ref.read(templateAnalyticsProvider(vendorId).notifier);
  return notifier.getAnalyticsInsights();
});
