import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'spending_limits.g.dart';

/// Enum for spending limit periods
enum SpendingLimitPeriod {
  @JsonValue('daily')
  daily,
  @JsonValue('weekly')
  weekly,
  @JsonValue('monthly')
  monthly,
}

/// Spending limit model
@JsonSerializable()
class SpendingLimit extends Equatable {
  final String id;
  final String userId;
  final String walletId;
  final SpendingLimitPeriod period;
  final double limitAmount;
  final bool isActive;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final double currentPeriodSpent;
  final int alertAtPercentage;
  final bool alertSent;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastResetAt;

  const SpendingLimit({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.period,
    required this.limitAmount,
    required this.isActive,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.currentPeriodSpent,
    required this.alertAtPercentage,
    required this.alertSent,
    this.description,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.lastResetAt,
  });

  factory SpendingLimit.fromJson(Map<String, dynamic> json) =>
      _$SpendingLimitFromJson(json);

  Map<String, dynamic> toJson() => _$SpendingLimitToJson(this);

  SpendingLimit copyWith({
    String? id,
    String? userId,
    String? walletId,
    SpendingLimitPeriod? period,
    double? limitAmount,
    bool? isActive,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    double? currentPeriodSpent,
    int? alertAtPercentage,
    bool? alertSent,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastResetAt,
  }) {
    return SpendingLimit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      period: period ?? this.period,
      limitAmount: limitAmount ?? this.limitAmount,
      isActive: isActive ?? this.isActive,
      currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      currentPeriodSpent: currentPeriodSpent ?? this.currentPeriodSpent,
      alertAtPercentage: alertAtPercentage ?? this.alertAtPercentage,
      alertSent: alertSent ?? this.alertSent,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastResetAt: lastResetAt ?? this.lastResetAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        period,
        limitAmount,
        isActive,
        currentPeriodStart,
        currentPeriodEnd,
        currentPeriodSpent,
        alertAtPercentage,
        alertSent,
        description,
        metadata,
        createdAt,
        updatedAt,
        lastResetAt,
      ];

  /// Get formatted limit amount
  String get formattedLimitAmount => 'RM ${limitAmount.toStringAsFixed(2)}';

  /// Get formatted current spent amount
  String get formattedCurrentSpent => 'RM ${currentPeriodSpent.toStringAsFixed(2)}';

  /// Get remaining amount
  double get remainingAmount => (limitAmount - currentPeriodSpent).clamp(0.0, double.infinity);

  /// Get formatted remaining amount
  String get formattedRemainingAmount => 'RM ${remainingAmount.toStringAsFixed(2)}';

  /// Get spending percentage
  double get spendingPercentage => limitAmount > 0 ? (currentPeriodSpent / limitAmount).clamp(0.0, 1.0) : 0.0;

  /// Get spending percentage as integer
  int get spendingPercentageInt => (spendingPercentage * 100).round();

  /// Check if limit is exceeded
  bool get isExceeded => currentPeriodSpent >= limitAmount;

  /// Check if alert threshold is reached
  bool get isAlertThresholdReached => spendingPercentage >= (alertAtPercentage / 100);

  /// Check if limit is close to being exceeded (within 10%)
  bool get isCloseToLimit => spendingPercentage >= 0.9;

  /// Get period display name
  String get periodDisplayName {
    switch (period) {
      case SpendingLimitPeriod.daily:
        return 'Daily';
      case SpendingLimitPeriod.weekly:
        return 'Weekly';
      case SpendingLimitPeriod.monthly:
        return 'Monthly';
    }
  }

  /// Get period description
  String get periodDescription {
    final start = currentPeriodStart;
    final end = currentPeriodEnd;
    
    switch (period) {
      case SpendingLimitPeriod.daily:
        return '${start.day}/${start.month}/${start.year}';
      case SpendingLimitPeriod.weekly:
        return '${start.day}/${start.month} - ${end.day}/${end.month}';
      case SpendingLimitPeriod.monthly:
        return '${_getMonthName(start.month)} ${start.year}';
    }
  }

  /// Get status color for UI
  String get statusColor {
    if (isExceeded) return 'red';
    if (isCloseToLimit) return 'orange';
    if (isAlertThresholdReached) return 'yellow';
    return 'green';
  }

  /// Get status description
  String get statusDescription {
    if (!isActive) return 'Inactive';
    if (isExceeded) return 'Limit Exceeded';
    if (isCloseToLimit) return 'Close to Limit';
    if (isAlertThresholdReached) return 'Alert Threshold Reached';
    return 'Within Limit';
  }

  /// Get days remaining in current period
  int get daysRemainingInPeriod {
    final now = DateTime.now();
    if (now.isAfter(currentPeriodEnd)) return 0;
    return currentPeriodEnd.difference(now).inDays + 1;
  }

  /// Get progress summary
  String get progressSummary {
    return '$formattedCurrentSpent of $formattedLimitAmount spent ($spendingPercentageInt%)';
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Create test spending limit for development
  factory SpendingLimit.test({
    SpendingLimitPeriod? period,
    double? limitAmount,
    double? currentSpent,
    bool? isActive,
  }) {
    final now = DateTime.now();
    final limitPeriod = period ?? SpendingLimitPeriod.monthly;
    final limit = limitAmount ?? 1000.00;
    final spent = currentSpent ?? 250.00;

    DateTime periodStart;
    DateTime periodEnd;

    switch (limitPeriod) {
      case SpendingLimitPeriod.daily:
        periodStart = DateTime(now.year, now.month, now.day);
        periodEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case SpendingLimitPeriod.weekly:
        final dayOfWeek = now.weekday;
        periodStart = now.subtract(Duration(days: dayOfWeek - 1));
        periodStart = DateTime(periodStart.year, periodStart.month, periodStart.day);
        periodEnd = periodStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case SpendingLimitPeriod.monthly:
        periodStart = DateTime(now.year, now.month, 1);
        periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
    }

    return SpendingLimit(
      id: 'test-spending-limit-id',
      userId: 'test-user-id',
      walletId: 'test-wallet-id',
      period: limitPeriod,
      limitAmount: limit,
      isActive: isActive ?? true,
      currentPeriodStart: periodStart,
      currentPeriodEnd: periodEnd,
      currentPeriodSpent: spent,
      alertAtPercentage: 80,
      alertSent: spent >= (limit * 0.8),
      description: '${limitPeriod.name} spending limit',
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
    );
  }

  /// Create multiple test spending limits
  static List<SpendingLimit> testList({
    String? userId,
    String? walletId,
  }) {
    return [
      SpendingLimit.test(
        period: SpendingLimitPeriod.daily,
        limitAmount: 200.00,
        currentSpent: 50.00,
      ),
      SpendingLimit.test(
        period: SpendingLimitPeriod.weekly,
        limitAmount: 1000.00,
        currentSpent: 750.00,
      ),
      SpendingLimit.test(
        period: SpendingLimitPeriod.monthly,
        limitAmount: 3000.00,
        currentSpent: 2800.00,
      ),
    ];
  }
}

/// Spending limit check result
@JsonSerializable()
class SpendingLimitCheckResult extends Equatable {
  final bool limitExceeded;
  final SpendingLimitPeriod limitType;
  final double limitAmount;
  final double currentSpent;
  final double remainingAmount;

  const SpendingLimitCheckResult({
    required this.limitExceeded,
    required this.limitType,
    required this.limitAmount,
    required this.currentSpent,
    required this.remainingAmount,
  });

  factory SpendingLimitCheckResult.fromJson(Map<String, dynamic> json) =>
      _$SpendingLimitCheckResultFromJson(json);

  Map<String, dynamic> toJson() => _$SpendingLimitCheckResultToJson(this);

  @override
  List<Object?> get props => [
        limitExceeded,
        limitType,
        limitAmount,
        currentSpent,
        remainingAmount,
      ];

  /// Get formatted amounts
  String get formattedLimitAmount => 'RM ${limitAmount.toStringAsFixed(2)}';
  String get formattedCurrentSpent => 'RM ${currentSpent.toStringAsFixed(2)}';
  String get formattedRemainingAmount => 'RM ${remainingAmount.toStringAsFixed(2)}';

  /// Get limit type display name
  String get limitTypeDisplayName {
    switch (limitType) {
      case SpendingLimitPeriod.daily:
        return 'Daily';
      case SpendingLimitPeriod.weekly:
        return 'Weekly';
      case SpendingLimitPeriod.monthly:
        return 'Monthly';
    }
  }

  /// Get error message for exceeded limit
  String get errorMessage {
    return 'Transaction would exceed your $limitTypeDisplayName spending limit of $formattedLimitAmount. You have $formattedRemainingAmount remaining.';
  }
}
