import 'package:equatable/equatable.dart';

/// Model representing comprehensive spending analytics for a customer
class CustomerSpendingAnalytics extends Equatable {
  final String userId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalSpent;
  final double averageSpending;
  final int transactionCount;
  final List<SpendingCategory> categoryBreakdown;
  final List<SpendingTrend> dailyTrends;
  final List<SpendingTrend> weeklyTrends;
  final List<SpendingTrend> monthlyTrends;
  final List<MerchantSpending> topMerchants;
  final List<SpendingInsight> insights;
  final SpendingComparison? comparison;
  final Map<String, dynamic>? metadata;

  const CustomerSpendingAnalytics({
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalSpent,
    required this.averageSpending,
    required this.transactionCount,
    required this.categoryBreakdown,
    required this.dailyTrends,
    required this.weeklyTrends,
    required this.monthlyTrends,
    required this.topMerchants,
    required this.insights,
    this.comparison,
    this.metadata,
  });

  factory CustomerSpendingAnalytics.fromJson(Map<String, dynamic> json) {
    return CustomerSpendingAnalytics(
      userId: json['user_id'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      totalSpent: (json['total_spent'] as num).toDouble(),
      averageSpending: (json['average_spending'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int,
      categoryBreakdown: (json['category_breakdown'] as List<dynamic>)
          .map((item) => SpendingCategory.fromJson(item as Map<String, dynamic>))
          .toList(),
      dailyTrends: (json['daily_trends'] as List<dynamic>)
          .map((item) => SpendingTrend.fromJson(item as Map<String, dynamic>))
          .toList(),
      weeklyTrends: (json['weekly_trends'] as List<dynamic>)
          .map((item) => SpendingTrend.fromJson(item as Map<String, dynamic>))
          .toList(),
      monthlyTrends: (json['monthly_trends'] as List<dynamic>)
          .map((item) => SpendingTrend.fromJson(item as Map<String, dynamic>))
          .toList(),
      topMerchants: (json['top_merchants'] as List<dynamic>)
          .map((item) => MerchantSpending.fromJson(item as Map<String, dynamic>))
          .toList(),
      insights: (json['insights'] as List<dynamic>)
          .map((item) => SpendingInsight.fromJson(item as Map<String, dynamic>))
          .toList(),
      comparison: json['comparison'] != null
          ? SpendingComparison.fromJson(json['comparison'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'total_spent': totalSpent,
      'average_spending': averageSpending,
      'transaction_count': transactionCount,
      'category_breakdown': categoryBreakdown.map((item) => item.toJson()).toList(),
      'daily_trends': dailyTrends.map((item) => item.toJson()).toList(),
      'weekly_trends': weeklyTrends.map((item) => item.toJson()).toList(),
      'monthly_trends': monthlyTrends.map((item) => item.toJson()).toList(),
      'top_merchants': topMerchants.map((item) => item.toJson()).toList(),
      'insights': insights.map((item) => item.toJson()).toList(),
      'comparison': comparison?.toJson(),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        userId,
        periodStart,
        periodEnd,
        totalSpent,
        averageSpending,
        transactionCount,
        categoryBreakdown,
        dailyTrends,
        weeklyTrends,
        monthlyTrends,
        topMerchants,
        insights,
        comparison,
        metadata,
      ];

  /// Get formatted total spent
  String get formattedTotalSpent => 'RM ${totalSpent.toStringAsFixed(2)}';

  /// Get formatted average spending
  String get formattedAverageSpending => 'RM ${averageSpending.toStringAsFixed(2)}';

  /// Get spending frequency (transactions per day)
  double get spendingFrequency {
    final days = periodEnd.difference(periodStart).inDays;
    return days > 0 ? transactionCount / days : 0.0;
  }

  /// Get top spending category
  SpendingCategory? get topSpendingCategory {
    if (categoryBreakdown.isEmpty) return null;
    return categoryBreakdown.reduce((a, b) => a.amount > b.amount ? a : b);
  }

  /// Get spending growth compared to previous period
  double? get spendingGrowth {
    return comparison?.growthPercentage;
  }
}

/// Model representing spending by category
class SpendingCategory extends Equatable {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final double amount;
  final int transactionCount;
  final double percentage;
  final String color;

  const SpendingCategory({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.amount,
    required this.transactionCount,
    required this.percentage,
    required this.color,
  });

  factory SpendingCategory.fromJson(Map<String, dynamic> json) {
    return SpendingCategory(
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      categoryIcon: json['category_icon'] as String,
      amount: (json['amount'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      color: json['color'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'category_icon': categoryIcon,
      'amount': amount,
      'transaction_count': transactionCount,
      'percentage': percentage,
      'color': color,
    };
  }

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        categoryIcon,
        amount,
        transactionCount,
        percentage,
        color,
      ];

  /// Get formatted amount
  String get formattedAmount => 'RM ${amount.toStringAsFixed(2)}';

  /// Get formatted percentage
  String get formattedPercentage => '${percentage.toStringAsFixed(1)}%';
}

/// Model representing spending trends over time
class SpendingTrend extends Equatable {
  final DateTime date;
  final double amount;
  final int transactionCount;
  final String period; // 'daily', 'weekly', 'monthly'

  const SpendingTrend({
    required this.date,
    required this.amount,
    required this.transactionCount,
    required this.period,
  });

  factory SpendingTrend.fromJson(Map<String, dynamic> json) {
    return SpendingTrend(
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int,
      period: json['period'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'amount': amount,
      'transaction_count': transactionCount,
      'period': period,
    };
  }

  @override
  List<Object?> get props => [date, amount, transactionCount, period];

  /// Get formatted amount
  String get formattedAmount => 'RM ${amount.toStringAsFixed(2)}';
}

/// Model representing spending by merchant/vendor
class MerchantSpending extends Equatable {
  final String merchantId;
  final String merchantName;
  final String? merchantLogo;
  final double amount;
  final int orderCount;
  final double averageOrderValue;
  final DateTime lastOrderDate;

  const MerchantSpending({
    required this.merchantId,
    required this.merchantName,
    this.merchantLogo,
    required this.amount,
    required this.orderCount,
    required this.averageOrderValue,
    required this.lastOrderDate,
  });

  factory MerchantSpending.fromJson(Map<String, dynamic> json) {
    return MerchantSpending(
      merchantId: json['merchant_id'] as String,
      merchantName: json['merchant_name'] as String,
      merchantLogo: json['merchant_logo'] as String?,
      amount: (json['amount'] as num).toDouble(),
      orderCount: json['order_count'] as int,
      averageOrderValue: (json['average_order_value'] as num).toDouble(),
      lastOrderDate: DateTime.parse(json['last_order_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant_id': merchantId,
      'merchant_name': merchantName,
      'merchant_logo': merchantLogo,
      'amount': amount,
      'order_count': orderCount,
      'average_order_value': averageOrderValue,
      'last_order_date': lastOrderDate.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        merchantId,
        merchantName,
        merchantLogo,
        amount,
        orderCount,
        averageOrderValue,
        lastOrderDate,
      ];

  /// Get formatted amount
  String get formattedAmount => 'RM ${amount.toStringAsFixed(2)}';

  /// Get formatted average order value
  String get formattedAverageOrderValue => 'RM ${averageOrderValue.toStringAsFixed(2)}';
}

/// Model representing spending insights and recommendations
class SpendingInsight extends Equatable {
  final String id;
  final String type; // 'tip', 'warning', 'achievement', 'recommendation'
  final String title;
  final String description;
  final String? actionText;
  final String? actionRoute;
  final String icon;
  final String priority; // 'high', 'medium', 'low'
  final DateTime createdAt;

  const SpendingInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.actionText,
    this.actionRoute,
    required this.icon,
    required this.priority,
    required this.createdAt,
  });

  factory SpendingInsight.fromJson(Map<String, dynamic> json) {
    return SpendingInsight(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      actionText: json['action_text'] as String?,
      actionRoute: json['action_route'] as String?,
      icon: json['icon'] as String,
      priority: json['priority'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'action_text': actionText,
      'action_route': actionRoute,
      'icon': icon,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        description,
        actionText,
        actionRoute,
        icon,
        priority,
        createdAt,
      ];
}

/// Model representing spending comparison with previous periods
class SpendingComparison extends Equatable {
  final double previousPeriodSpending;
  final double currentPeriodSpending;
  final double growthPercentage;
  final String trend; // 'increasing', 'decreasing', 'stable'

  const SpendingComparison({
    required this.previousPeriodSpending,
    required this.currentPeriodSpending,
    required this.growthPercentage,
    required this.trend,
  });

  factory SpendingComparison.fromJson(Map<String, dynamic> json) {
    return SpendingComparison(
      previousPeriodSpending: (json['previous_period_spending'] as num).toDouble(),
      currentPeriodSpending: (json['current_period_spending'] as num).toDouble(),
      growthPercentage: (json['growth_percentage'] as num).toDouble(),
      trend: json['trend'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'previous_period_spending': previousPeriodSpending,
      'current_period_spending': currentPeriodSpending,
      'growth_percentage': growthPercentage,
      'trend': trend,
    };
  }

  @override
  List<Object?> get props => [
        previousPeriodSpending,
        currentPeriodSpending,
        growthPercentage,
        trend,
      ];

  /// Get formatted growth percentage
  String get formattedGrowthPercentage {
    final sign = growthPercentage >= 0 ? '+' : '';
    return '$sign${growthPercentage.toStringAsFixed(1)}%';
  }

  /// Check if spending is increasing
  bool get isIncreasing => trend == 'increasing';

  /// Check if spending is decreasing
  bool get isDecreasing => trend == 'decreasing';

  /// Check if spending is stable
  bool get isStable => trend == 'stable';
}
