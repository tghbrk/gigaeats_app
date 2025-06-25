import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'analytics_export.g.dart';

/// Model for analytics export data
@JsonSerializable()
class AnalyticsExport extends Equatable {
  final String id;
  final String userId;
  final String exportType; // 'pdf', 'csv', 'json'
  final String periodType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, dynamic> data;
  final String? filePath;
  final int fileSize;
  final String status; // 'generating', 'completed', 'failed'
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  const AnalyticsExport({
    required this.id,
    required this.userId,
    required this.exportType,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.data,
    this.filePath,
    required this.fileSize,
    required this.status,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  factory AnalyticsExport.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsExportFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsExportToJson(this);

  @override
  List<Object?> get props => [
        id,
        userId,
        exportType,
        periodType,
        periodStart,
        periodEnd,
        data,
        filePath,
        fileSize,
        status,
        errorMessage,
        createdAt,
        completedAt,
      ];

  /// Check if export is completed
  bool get isCompleted => status == 'completed';

  /// Check if export failed
  bool get isFailed => status == 'failed';

  /// Check if export is in progress
  bool get isGenerating => status == 'generating';

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get export type display name
  String get exportTypeDisplayName {
    switch (exportType.toLowerCase()) {
      case 'pdf':
        return 'PDF Report';
      case 'csv':
        return 'CSV Data';
      case 'json':
        return 'JSON Data';
      default:
        return exportType.toUpperCase();
    }
  }

  /// Get period display name
  String get periodDisplayName {
    final start = '${periodStart.day}/${periodStart.month}/${periodStart.year}';
    final end = '${periodEnd.day}/${periodEnd.month}/${periodEnd.year}';
    return '$start - $end';
  }

  /// Create test export
  factory AnalyticsExport.test({
    String? exportType,
    String? status,
  }) {
    final now = DateTime.now();
    return AnalyticsExport(
      id: 'test-export-id',
      userId: 'test-user-id',
      exportType: exportType ?? 'pdf',
      periodType: 'monthly',
      periodStart: DateTime(now.year, now.month, 1),
      periodEnd: DateTime(now.year, now.month + 1, 0),
      data: {
        'total_spent': 450.00,
        'total_transactions': 15,
        'categories': ['food_orders', 'top_ups'],
      },
      filePath: '/exports/analytics_report_${now.millisecondsSinceEpoch}.pdf',
      fileSize: 1024 * 256, // 256 KB
      status: status ?? 'completed',
      createdAt: now.subtract(const Duration(minutes: 5)),
      completedAt: now,
    );
  }
}

/// Model for analytics insights and recommendations
@JsonSerializable()
class AnalyticsInsight extends Equatable {
  final String id;
  final String userId;
  final String type; // 'spending_pattern', 'budget_alert', 'saving_tip', 'vendor_recommendation'
  final String title;
  final String description;
  final String? actionText;
  final String? actionRoute;
  final Map<String, dynamic>? metadata;
  final String priority; // 'high', 'medium', 'low'
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const AnalyticsInsight({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    this.actionText,
    this.actionRoute,
    this.metadata,
    required this.priority,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory AnalyticsInsight.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsInsightFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsInsightToJson(this);

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        description,
        actionText,
        actionRoute,
        metadata,
        priority,
        isRead,
        createdAt,
        readAt,
      ];

  /// Get insight icon based on type
  String get icon {
    switch (type) {
      case 'spending_pattern':
        return 'trending_up';
      case 'budget_alert':
        return 'warning';
      case 'saving_tip':
        return 'lightbulb';
      case 'vendor_recommendation':
        return 'restaurant';
      default:
        return 'info';
    }
  }

  /// Get insight color based on priority
  String get color {
    switch (priority) {
      case 'high':
        return '#FF6B6B';
      case 'medium':
        return '#FFD93D';
      case 'low':
        return '#6BCF7F';
      default:
        return '#74B9FF';
    }
  }

  /// Check if insight is high priority
  bool get isHighPriority => priority == 'high';

  /// Check if insight has action
  bool get hasAction => actionText != null && actionRoute != null;

  /// Create test insight
  factory AnalyticsInsight.test({
    String? type,
    String? priority,
    bool? isRead,
  }) {
    return AnalyticsInsight(
      id: 'test-insight-id',
      userId: 'test-user-id',
      type: type ?? 'spending_pattern',
      title: 'Spending Increase Detected',
      description: 'Your spending has increased by 15% compared to last month. Consider reviewing your budget.',
      actionText: 'View Budget',
      actionRoute: '/wallet/budget',
      metadata: {
        'increase_percentage': 15.0,
        'previous_amount': 400.00,
        'current_amount': 460.00,
      },
      priority: priority ?? 'medium',
      isRead: isRead ?? false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
  }
}

/// Model for analytics summary cards
class AnalyticsSummaryCard extends Equatable {
  final String title;
  final String value;
  final String? subtitle;
  final String? trend;
  final double? trendPercentage;
  final String icon;
  final String color;
  final bool isPositiveTrend;

  const AnalyticsSummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.trend,
    this.trendPercentage,
    required this.icon,
    required this.color,
    this.isPositiveTrend = true,
  });

  @override
  List<Object?> get props => [
        title,
        value,
        subtitle,
        trend,
        trendPercentage,
        icon,
        color,
        isPositiveTrend,
      ];

  /// Get formatted trend percentage
  String? get formattedTrendPercentage {
    if (trendPercentage == null) return null;
    final sign = trendPercentage! >= 0 ? '+' : '';
    return '$sign${trendPercentage!.toStringAsFixed(1)}%';
  }

  /// Get trend icon
  String get trendIcon {
    if (trendPercentage == null) return '';
    if (trendPercentage! > 0) {
      return isPositiveTrend ? 'trending_up' : 'trending_down';
    } else if (trendPercentage! < 0) {
      return isPositiveTrend ? 'trending_down' : 'trending_up';
    } else {
      return 'trending_flat';
    }
  }

  /// Create test summary card
  factory AnalyticsSummaryCard.test({
    String? title,
    String? value,
    double? trendPercentage,
  }) {
    return AnalyticsSummaryCard(
      title: title ?? 'Total Spent',
      value: value ?? 'RM 450.00',
      subtitle: 'This month',
      trend: 'vs last month',
      trendPercentage: trendPercentage ?? 12.5,
      icon: 'account_balance_wallet',
      color: '#FF6B6B',
      isPositiveTrend: false, // Spending increase is negative trend
    );
  }
}

/// Model for chart data points
class ChartDataPoint extends Equatable {
  final DateTime date;
  final double value;
  final String? label;
  final String? category;
  final Map<String, dynamic>? metadata;

  const ChartDataPoint({
    required this.date,
    required this.value,
    this.label,
    this.category,
    this.metadata,
  });

  @override
  List<Object?> get props => [date, value, label, category, metadata];

  /// Get formatted value
  String get formattedValue => 'RM ${value.toStringAsFixed(2)}';

  /// Get date label for charts
  String get dateLabel => '${date.day}/${date.month}';

  /// Create test chart data point
  factory ChartDataPoint.test({
    DateTime? date,
    double? value,
  }) {
    return ChartDataPoint(
      date: date ?? DateTime.now(),
      value: value ?? 25.50,
      label: 'Daily Spending',
      category: 'spending',
    );
  }
}
