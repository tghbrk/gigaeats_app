import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'template_usage_analytics.g.dart';

/// Represents analytics data for customization template usage
@JsonSerializable()
class TemplateUsageAnalytics extends Equatable {
  final String id;
  @JsonKey(name: 'template_id')
  final String templateId;
  @JsonKey(name: 'vendor_id')
  final String vendorId;
  @JsonKey(name: 'menu_items_count')
  final int menuItemsCount;
  @JsonKey(name: 'orders_count')
  final int ordersCount;
  @JsonKey(name: 'revenue_generated')
  final double revenueGenerated;
  @JsonKey(name: 'last_used_at')
  final DateTime? lastUsedAt;
  @JsonKey(name: 'analytics_date')
  final DateTime analyticsDate;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const TemplateUsageAnalytics({
    required this.id,
    required this.templateId,
    required this.vendorId,
    this.menuItemsCount = 0,
    this.ordersCount = 0,
    this.revenueGenerated = 0.0,
    this.lastUsedAt,
    required this.analyticsDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TemplateUsageAnalytics.fromJson(Map<String, dynamic> json) =>
      _$TemplateUsageAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateUsageAnalyticsToJson(this);

  /// Creates a copy with updated fields
  TemplateUsageAnalytics copyWith({
    String? id,
    String? templateId,
    String? vendorId,
    int? menuItemsCount,
    int? ordersCount,
    double? revenueGenerated,
    DateTime? lastUsedAt,
    DateTime? analyticsDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TemplateUsageAnalytics(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      vendorId: vendorId ?? this.vendorId,
      menuItemsCount: menuItemsCount ?? this.menuItemsCount,
      ordersCount: ordersCount ?? this.ordersCount,
      revenueGenerated: revenueGenerated ?? this.revenueGenerated,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      analyticsDate: analyticsDate ?? this.analyticsDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculates average revenue per order
  double get averageRevenuePerOrder {
    if (ordersCount == 0) return 0.0;
    return revenueGenerated / ordersCount;
  }

  /// Calculates average revenue per menu item
  double get averageRevenuePerMenuItem {
    if (menuItemsCount == 0) return 0.0;
    return revenueGenerated / menuItemsCount;
  }

  /// Checks if the template was used recently (within last 7 days)
  bool get isRecentlyUsed {
    if (lastUsedAt == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastUsedAt!);
    return difference.inDays <= 7;
  }

  /// Gets a formatted revenue string for display
  String get formattedRevenue => 'RM ${revenueGenerated.toStringAsFixed(2)}';

  /// Gets a formatted average revenue per order string
  String get formattedAverageRevenuePerOrder => 
      'RM ${averageRevenuePerOrder.toStringAsFixed(2)}';

  /// Gets usage frequency category
  String get usageFrequency {
    if (ordersCount == 0) return 'Unused';
    if (ordersCount < 5) return 'Low';
    if (ordersCount < 20) return 'Medium';
    if (ordersCount < 50) return 'High';
    return 'Very High';
  }

  /// Gets performance rating based on revenue and usage
  String get performanceRating {
    if (ordersCount == 0 || revenueGenerated == 0) return 'No Data';
    
    final avgRevenue = averageRevenuePerOrder;
    if (avgRevenue >= 10.0 && ordersCount >= 20) return 'Excellent';
    if (avgRevenue >= 5.0 && ordersCount >= 10) return 'Good';
    if (avgRevenue >= 2.0 && ordersCount >= 5) return 'Fair';
    return 'Poor';
  }

  @override
  List<Object?> get props => [
        id,
        templateId,
        vendorId,
        menuItemsCount,
        ordersCount,
        revenueGenerated,
        lastUsedAt,
        analyticsDate,
        createdAt,
        updatedAt,
      ];
}

/// Aggregated analytics data for multiple templates
@JsonSerializable()
class TemplateAnalyticsSummary extends Equatable {
  @JsonKey(name: 'vendor_id')
  final String vendorId;
  @JsonKey(name: 'total_templates')
  final int totalTemplates;
  @JsonKey(name: 'active_templates')
  final int activeTemplates;
  @JsonKey(name: 'total_menu_items_using_templates')
  final int totalMenuItemsUsingTemplates;
  @JsonKey(name: 'total_orders_with_templates')
  final int totalOrdersWithTemplates;
  @JsonKey(name: 'total_revenue_from_templates')
  final double totalRevenueFromTemplates;
  @JsonKey(name: 'period_start')
  final DateTime periodStart;
  @JsonKey(name: 'period_end')
  final DateTime periodEnd;
  @JsonKey(name: 'top_performing_templates')
  final List<TemplateUsageAnalytics> topPerformingTemplates;

  const TemplateAnalyticsSummary({
    required this.vendorId,
    this.totalTemplates = 0,
    this.activeTemplates = 0,
    this.totalMenuItemsUsingTemplates = 0,
    this.totalOrdersWithTemplates = 0,
    this.totalRevenueFromTemplates = 0.0,
    required this.periodStart,
    required this.periodEnd,
    this.topPerformingTemplates = const [],
  });

  factory TemplateAnalyticsSummary.fromJson(Map<String, dynamic> json) =>
      _$TemplateAnalyticsSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateAnalyticsSummaryToJson(this);

  /// Calculates template adoption rate (percentage of menu items using templates)
  double calculateAdoptionRate(int totalMenuItems) {
    if (totalMenuItems == 0) return 0.0;
    return (totalMenuItemsUsingTemplates / totalMenuItems) * 100;
  }

  /// Calculates average revenue per template
  double get averageRevenuePerTemplate {
    if (activeTemplates == 0) return 0.0;
    return totalRevenueFromTemplates / activeTemplates;
  }

  /// Calculates average revenue per order with templates
  double get averageRevenuePerOrder {
    if (totalOrdersWithTemplates == 0) return 0.0;
    return totalRevenueFromTemplates / totalOrdersWithTemplates;
  }

  /// Gets formatted total revenue string
  String get formattedTotalRevenue => 
      'RM ${totalRevenueFromTemplates.toStringAsFixed(2)}';

  /// Gets formatted average revenue per template string
  String get formattedAverageRevenuePerTemplate => 
      'RM ${averageRevenuePerTemplate.toStringAsFixed(2)}';

  /// Gets the period duration in days
  int get periodDurationDays => periodEnd.difference(periodStart).inDays + 1;

  /// Calculates daily average revenue
  double get dailyAverageRevenue {
    final days = periodDurationDays;
    if (days == 0) return 0.0;
    return totalRevenueFromTemplates / days;
  }

  /// Gets template utilization percentage
  double get templateUtilizationRate {
    if (totalTemplates == 0) return 0.0;
    return (activeTemplates / totalTemplates) * 100;
  }

  @override
  List<Object?> get props => [
        vendorId,
        totalTemplates,
        activeTemplates,
        totalMenuItemsUsingTemplates,
        totalOrdersWithTemplates,
        totalRevenueFromTemplates,
        periodStart,
        periodEnd,
        topPerformingTemplates,
      ];
}

/// Template performance metrics for comparison
@JsonSerializable()
class TemplatePerformanceMetrics extends Equatable {
  @JsonKey(name: 'template_id')
  final String templateId;
  @JsonKey(name: 'template_name')
  final String templateName;
  @JsonKey(name: 'usage_count')
  final int usageCount;
  @JsonKey(name: 'orders_count')
  final int ordersCount;
  @JsonKey(name: 'revenue_generated')
  final double revenueGenerated;
  @JsonKey(name: 'conversion_rate')
  final double conversionRate; // Orders / Menu items using template
  @JsonKey(name: 'average_order_value')
  final double averageOrderValue;
  @JsonKey(name: 'last_used')
  final DateTime lastUsed;

  const TemplatePerformanceMetrics({
    required this.templateId,
    required this.templateName,
    this.usageCount = 0,
    this.ordersCount = 0,
    this.revenueGenerated = 0.0,
    this.conversionRate = 0.0,
    this.averageOrderValue = 0.0,
    required this.lastUsed,
  });

  factory TemplatePerformanceMetrics.fromJson(Map<String, dynamic> json) =>
      _$TemplatePerformanceMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$TemplatePerformanceMetricsToJson(this);

  /// Gets performance score (0-100) based on multiple factors
  double get performanceScore {
    double score = 0.0;
    
    // Usage count factor (0-30 points)
    score += (usageCount * 2).clamp(0, 30).toDouble();
    
    // Orders count factor (0-25 points)
    score += (ordersCount * 1.5).clamp(0, 25).toDouble();
    
    // Revenue factor (0-25 points)
    score += (revenueGenerated / 10).clamp(0, 25).toDouble();
    
    // Conversion rate factor (0-20 points)
    score += (conversionRate * 20).clamp(0, 20).toDouble();
    
    return score.clamp(0, 100);
  }

  /// Gets performance grade based on score
  String get performanceGrade {
    final score = performanceScore;
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    if (score >= 50) return 'D';
    return 'F';
  }

  @override
  List<Object?> get props => [
        templateId,
        templateName,
        usageCount,
        ordersCount,
        revenueGenerated,
        conversionRate,
        averageOrderValue,
        lastUsed,
      ];
}
