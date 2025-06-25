import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wallet_analytics.g.dart';

/// Comprehensive wallet analytics model for aggregated data
@JsonSerializable()
class WalletAnalytics extends Equatable {
  final String id;
  final String userId;
  final String walletId;
  final String periodType;
  final DateTime periodStart;
  final DateTime periodEnd;
  
  // Spending analytics
  final double totalSpent;
  final int totalTransactions;
  final double avgTransactionAmount;
  final double maxTransactionAmount;
  final double minTransactionAmount;
  
  // Top-up analytics
  final double totalToppedUp;
  final int topupTransactions;
  final double avgTopupAmount;
  
  // Transfer analytics
  final double totalTransferredOut;
  final double totalTransferredIn;
  final int transferOutCount;
  final int transferInCount;
  
  // Balance analytics
  final double periodStartBalance;
  final double periodEndBalance;
  final double avgBalance;
  final double maxBalance;
  final double minBalance;
  
  // Vendor analytics
  final int uniqueVendorsCount;
  final String? topVendorId;
  final double topVendorSpent;
  
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletAnalytics({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.totalSpent,
    required this.totalTransactions,
    required this.avgTransactionAmount,
    required this.maxTransactionAmount,
    required this.minTransactionAmount,
    required this.totalToppedUp,
    required this.topupTransactions,
    required this.avgTopupAmount,
    required this.totalTransferredOut,
    required this.totalTransferredIn,
    required this.transferOutCount,
    required this.transferInCount,
    required this.periodStartBalance,
    required this.periodEndBalance,
    required this.avgBalance,
    required this.maxBalance,
    required this.minBalance,
    required this.uniqueVendorsCount,
    this.topVendorId,
    required this.topVendorSpent,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletAnalytics.fromJson(Map<String, dynamic> json) =>
      _$WalletAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$WalletAnalyticsToJson(this);

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        periodType,
        periodStart,
        periodEnd,
        totalSpent,
        totalTransactions,
        avgTransactionAmount,
        maxTransactionAmount,
        minTransactionAmount,
        totalToppedUp,
        topupTransactions,
        avgTopupAmount,
        totalTransferredOut,
        totalTransferredIn,
        transferOutCount,
        transferInCount,
        periodStartBalance,
        periodEndBalance,
        avgBalance,
        maxBalance,
        minBalance,
        uniqueVendorsCount,
        topVendorId,
        topVendorSpent,
        currency,
        createdAt,
        updatedAt,
      ];

  /// Formatted display values
  String get formattedTotalSpent => 'RM ${totalSpent.toStringAsFixed(2)}';
  String get formattedTotalToppedUp => 'RM ${totalToppedUp.toStringAsFixed(2)}';
  String get formattedAvgTransactionAmount => 'RM ${avgTransactionAmount.toStringAsFixed(2)}';
  String get formattedPeriodEndBalance => 'RM ${periodEndBalance.toStringAsFixed(2)}';
  String get formattedTopVendorSpent => 'RM ${topVendorSpent.toStringAsFixed(2)}';

  /// Calculate balance change for the period
  double get balanceChange => periodEndBalance - periodStartBalance;
  String get formattedBalanceChange {
    final change = balanceChange;
    final sign = change >= 0 ? '+' : '';
    return '$sign RM ${change.abs().toStringAsFixed(2)}';
  }

  /// Calculate spending frequency (transactions per day)
  double get spendingFrequency {
    final days = periodEnd.difference(periodStart).inDays;
    return days > 0 ? totalTransactions / days : 0.0;
  }

  /// Get period display name
  String get periodDisplayName {
    switch (periodType) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      default:
        return periodType;
    }
  }

  /// Create test analytics for development
  factory WalletAnalytics.test({
    String? periodType,
    DateTime? periodStart,
    double? totalSpent,
    int? totalTransactions,
  }) {
    final now = DateTime.now();
    final start = periodStart ?? DateTime(now.year, now.month, 1);
    final end = DateTime(start.year, start.month + 1, 0);
    
    return WalletAnalytics(
      id: 'test-analytics-id',
      userId: 'test-user-id',
      walletId: 'test-wallet-id',
      periodType: periodType ?? 'monthly',
      periodStart: start,
      periodEnd: end,
      totalSpent: totalSpent ?? 450.00,
      totalTransactions: totalTransactions ?? 15,
      avgTransactionAmount: 30.00,
      maxTransactionAmount: 85.00,
      minTransactionAmount: 12.50,
      totalToppedUp: 500.00,
      topupTransactions: 2,
      avgTopupAmount: 250.00,
      totalTransferredOut: 0.00,
      totalTransferredIn: 0.00,
      transferOutCount: 0,
      transferInCount: 0,
      periodStartBalance: 100.00,
      periodEndBalance: 150.00,
      avgBalance: 125.00,
      maxBalance: 200.00,
      minBalance: 50.00,
      uniqueVendorsCount: 8,
      topVendorId: 'vendor-123',
      topVendorSpent: 120.00,
      currency: 'MYR',
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Model for spending trends over time
@JsonSerializable()
class SpendingTrendData extends Equatable {
  final DateTime datePeriod;
  final double dailySpent;
  final int dailyTransactions;
  final double runningBalance;
  final Map<String, double>? categoryBreakdown;

  const SpendingTrendData({
    required this.datePeriod,
    required this.dailySpent,
    required this.dailyTransactions,
    required this.runningBalance,
    this.categoryBreakdown,
  });

  factory SpendingTrendData.fromJson(Map<String, dynamic> json) =>
      _$SpendingTrendDataFromJson(json);

  Map<String, dynamic> toJson() => _$SpendingTrendDataToJson(this);

  @override
  List<Object?> get props => [
        datePeriod,
        dailySpent,
        dailyTransactions,
        runningBalance,
        categoryBreakdown,
      ];

  /// Formatted display values
  String get formattedDailySpent => 'RM ${dailySpent.toStringAsFixed(2)}';
  String get formattedRunningBalance => 'RM ${runningBalance.toStringAsFixed(2)}';

  /// Get date label for charts
  String get dateLabel {
    return '${datePeriod.day}/${datePeriod.month}';
  }

  /// Create test trend data
  factory SpendingTrendData.test({
    DateTime? date,
    double? spent,
    int? transactions,
  }) {
    return SpendingTrendData(
      datePeriod: date ?? DateTime.now(),
      dailySpent: spent ?? 25.50,
      dailyTransactions: transactions ?? 2,
      runningBalance: 150.00,
      categoryBreakdown: {
        'food_orders': 20.00,
        'top_ups': 0.00,
        'transfers': 5.50,
      },
    );
  }
}

/// Model for transaction categories
@JsonSerializable()
class TransactionCategoryData extends Equatable {
  final String categoryType;
  final String categoryName;
  final double totalAmount;
  final int transactionCount;
  final double avgAmount;
  final double percentageOfTotal;
  final String? vendorId;
  final String? vendorName;

  const TransactionCategoryData({
    required this.categoryType,
    required this.categoryName,
    required this.totalAmount,
    required this.transactionCount,
    required this.avgAmount,
    required this.percentageOfTotal,
    this.vendorId,
    this.vendorName,
  });

  factory TransactionCategoryData.fromJson(Map<String, dynamic> json) =>
      _$TransactionCategoryDataFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionCategoryDataToJson(this);

  @override
  List<Object?> get props => [
        categoryType,
        categoryName,
        totalAmount,
        transactionCount,
        avgAmount,
        percentageOfTotal,
        vendorId,
        vendorName,
      ];

  /// Formatted display values
  String get formattedTotalAmount => 'RM ${totalAmount.toStringAsFixed(2)}';
  String get formattedAvgAmount => 'RM ${avgAmount.toStringAsFixed(2)}';
  String get formattedPercentage => '${percentageOfTotal.toStringAsFixed(1)}%';

  /// Get category icon
  String get categoryIcon {
    switch (categoryType) {
      case 'food_orders':
        return 'restaurant';
      case 'top_ups':
        return 'add_circle';
      case 'transfers':
        return 'send';
      case 'refunds':
        return 'undo';
      default:
        return 'category';
    }
  }

  /// Get category color for charts
  String get categoryColor {
    switch (categoryType) {
      case 'food_orders':
        return '#FF6B6B';
      case 'top_ups':
        return '#4ECDC4';
      case 'transfers':
        return '#45B7D1';
      case 'refunds':
        return '#96CEB4';
      default:
        return '#FECA57';
    }
  }

  /// Create test category data
  factory TransactionCategoryData.test({
    String? categoryType,
    double? amount,
    int? count,
  }) {
    return TransactionCategoryData(
      categoryType: categoryType ?? 'food_orders',
      categoryName: 'Food Orders',
      totalAmount: amount ?? 320.00,
      transactionCount: count ?? 12,
      avgAmount: 26.67,
      percentageOfTotal: 71.1,
      vendorId: 'vendor-123',
      vendorName: 'Delicious Restaurant',
    );
  }
}

/// Model for analytics filters and date ranges
@JsonSerializable()
class AnalyticsFilter extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final String periodType;
  final List<String>? categoryTypes;
  final List<String>? vendorIds;
  final double? minAmount;
  final double? maxAmount;
  final bool includeTopUps;
  final bool includeTransfers;
  final bool includeRefunds;

  const AnalyticsFilter({
    required this.startDate,
    required this.endDate,
    required this.periodType,
    this.categoryTypes,
    this.vendorIds,
    this.minAmount,
    this.maxAmount,
    this.includeTopUps = true,
    this.includeTransfers = true,
    this.includeRefunds = true,
  });

  factory AnalyticsFilter.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsFilterFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsFilterToJson(this);

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        periodType,
        categoryTypes,
        vendorIds,
        minAmount,
        maxAmount,
        includeTopUps,
        includeTransfers,
        includeRefunds,
      ];

  /// Get number of days in the filter range
  int get dayCount => endDate.difference(startDate).inDays + 1;

  /// Get formatted date range
  String get formattedDateRange {
    final start = '${startDate.day}/${startDate.month}/${startDate.year}';
    final end = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$start - $end';
  }

  /// Create common filter presets
  factory AnalyticsFilter.last30Days() {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    return AnalyticsFilter(
      startDate: startDate,
      endDate: now,
      periodType: 'daily',
    );
  }

  factory AnalyticsFilter.currentMonth() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);
    return AnalyticsFilter(
      startDate: startDate,
      endDate: endDate,
      periodType: 'monthly',
    );
  }

  factory AnalyticsFilter.last12Months() {
    final now = DateTime.now();
    final startDate = DateTime(now.year - 1, now.month, 1);
    return AnalyticsFilter(
      startDate: startDate,
      endDate: now,
      periodType: 'monthly',
    );
  }

  /// Create test filter
  factory AnalyticsFilter.test() {
    final now = DateTime.now();
    return AnalyticsFilter(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
      periodType: 'daily',
      includeTopUps: true,
      includeTransfers: true,
      includeRefunds: true,
    );
  }
}
