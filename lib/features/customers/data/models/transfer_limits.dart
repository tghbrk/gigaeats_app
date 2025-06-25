import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transfer_limits.g.dart';

/// Transfer limits model for user-specific and global limits
@JsonSerializable()
class TransferLimits extends Equatable {
  final String id;
  final String? userId;
  final bool isGlobal;
  final String userTier;
  final double dailyLimit;
  final double monthlyLimit;
  final double perTransactionLimit;
  final int dailyTransactionCount;
  final int monthlyTransactionCount;
  final double minimumTransferAmount;
  final bool isActive;
  final DateTime effectiveFrom;
  final DateTime? effectiveUntil;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  const TransferLimits({
    required this.id,
    this.userId,
    required this.isGlobal,
    required this.userTier,
    required this.dailyLimit,
    required this.monthlyLimit,
    required this.perTransactionLimit,
    required this.dailyTransactionCount,
    required this.monthlyTransactionCount,
    required this.minimumTransferAmount,
    required this.isActive,
    required this.effectiveFrom,
    this.effectiveUntil,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory TransferLimits.fromJson(Map<String, dynamic> json) =>
      _$TransferLimitsFromJson(json);

  Map<String, dynamic> toJson() => _$TransferLimitsToJson(this);

  TransferLimits copyWith({
    String? id,
    String? userId,
    bool? isGlobal,
    String? userTier,
    double? dailyLimit,
    double? monthlyLimit,
    double? perTransactionLimit,
    int? dailyTransactionCount,
    int? monthlyTransactionCount,
    double? minimumTransferAmount,
    bool? isActive,
    DateTime? effectiveFrom,
    DateTime? effectiveUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return TransferLimits(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isGlobal: isGlobal ?? this.isGlobal,
      userTier: userTier ?? this.userTier,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      perTransactionLimit: perTransactionLimit ?? this.perTransactionLimit,
      dailyTransactionCount: dailyTransactionCount ?? this.dailyTransactionCount,
      monthlyTransactionCount: monthlyTransactionCount ?? this.monthlyTransactionCount,
      minimumTransferAmount: minimumTransferAmount ?? this.minimumTransferAmount,
      isActive: isActive ?? this.isActive,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveUntil: effectiveUntil ?? this.effectiveUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        isGlobal,
        userTier,
        dailyLimit,
        monthlyLimit,
        perTransactionLimit,
        dailyTransactionCount,
        monthlyTransactionCount,
        minimumTransferAmount,
        isActive,
        effectiveFrom,
        effectiveUntil,
        createdAt,
        updatedAt,
        createdBy,
      ];

  /// Get formatted limit displays
  String get formattedDailyLimit => 'RM ${dailyLimit.toStringAsFixed(2)}';
  String get formattedMonthlyLimit => 'RM ${monthlyLimit.toStringAsFixed(2)}';
  String get formattedPerTransactionLimit => 'RM ${perTransactionLimit.toStringAsFixed(2)}';
  String get formattedMinimumAmount => 'RM ${minimumTransferAmount.toStringAsFixed(2)}';

  /// Get user tier display name
  String get userTierDisplayName {
    switch (userTier.toLowerCase()) {
      case 'standard':
        return 'Standard';
      case 'premium':
        return 'Premium';
      case 'vip':
        return 'VIP';
      default:
        return userTier;
    }
  }

  /// Check if limits are currently effective
  bool get isCurrentlyEffective {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(effectiveFrom) &&
        (effectiveUntil == null || now.isBefore(effectiveUntil!));
  }

  /// Create test limits for development
  factory TransferLimits.test({
    String? id,
    String? userId,
    bool? isGlobal,
    String? userTier,
  }) {
    final now = DateTime.now();
    return TransferLimits(
      id: id ?? 'test-limits-id',
      userId: userId,
      isGlobal: isGlobal ?? false,
      userTier: userTier ?? 'standard',
      dailyLimit: 1000.00,
      monthlyLimit: 10000.00,
      perTransactionLimit: 500.00,
      dailyTransactionCount: 10,
      monthlyTransactionCount: 100,
      minimumTransferAmount: 1.00,
      isActive: true,
      effectiveFrom: now.subtract(const Duration(days: 30)),
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
    );
  }
}

/// Transfer usage model for tracking current usage against limits
@JsonSerializable()
class TransferUsage extends Equatable {
  final double dailyUsed;
  final double monthlyUsed;
  final int dailyCount;
  final int monthlyCount;
  final double dailyRemaining;
  final double monthlyRemaining;
  final int dailyCountRemaining;
  final int monthlyCountRemaining;

  const TransferUsage({
    required this.dailyUsed,
    required this.monthlyUsed,
    required this.dailyCount,
    required this.monthlyCount,
    required this.dailyRemaining,
    required this.monthlyRemaining,
    required this.dailyCountRemaining,
    required this.monthlyCountRemaining,
  });

  factory TransferUsage.fromJson(Map<String, dynamic> json) =>
      _$TransferUsageFromJson(json);

  Map<String, dynamic> toJson() => _$TransferUsageToJson(this);

  @override
  List<Object?> get props => [
        dailyUsed,
        monthlyUsed,
        dailyCount,
        monthlyCount,
        dailyRemaining,
        monthlyRemaining,
        dailyCountRemaining,
        monthlyCountRemaining,
      ];

  /// Get formatted usage displays
  String get formattedDailyUsed => 'RM ${dailyUsed.toStringAsFixed(2)}';
  String get formattedMonthlyUsed => 'RM ${monthlyUsed.toStringAsFixed(2)}';
  String get formattedDailyRemaining => 'RM ${dailyRemaining.toStringAsFixed(2)}';
  String get formattedMonthlyRemaining => 'RM ${monthlyRemaining.toStringAsFixed(2)}';

  /// Calculate usage percentages
  double getDailyUsagePercentage(double dailyLimit) {
    if (dailyLimit <= 0) return 0.0;
    return (dailyUsed / dailyLimit).clamp(0.0, 1.0);
  }

  double getMonthlyUsagePercentage(double monthlyLimit) {
    if (monthlyLimit <= 0) return 0.0;
    return (monthlyUsed / monthlyLimit).clamp(0.0, 1.0);
  }

  /// Check if limits are approaching
  bool isDailyLimitApproaching(double threshold) {
    return dailyRemaining <= threshold;
  }

  bool isMonthlyLimitApproaching(double threshold) {
    return monthlyRemaining <= threshold;
  }

  /// Check if transaction count limits are approaching
  bool isDailyCountLimitApproaching(int threshold) {
    return dailyCountRemaining <= threshold;
  }

  bool isMonthlyCountLimitApproaching(int threshold) {
    return monthlyCountRemaining <= threshold;
  }

  /// Create test usage for development
  factory TransferUsage.test({
    double? dailyUsed,
    double? monthlyUsed,
    int? dailyCount,
    int? monthlyCount,
  }) {
    final dUsed = dailyUsed ?? 250.00;
    final mUsed = monthlyUsed ?? 2500.00;
    final dCount = dailyCount ?? 3;
    final mCount = monthlyCount ?? 25;

    return TransferUsage(
      dailyUsed: dUsed,
      monthlyUsed: mUsed,
      dailyCount: dCount,
      monthlyCount: mCount,
      dailyRemaining: 1000.00 - dUsed,
      monthlyRemaining: 10000.00 - mUsed,
      dailyCountRemaining: 10 - dCount,
      monthlyCountRemaining: 100 - mCount,
    );
  }
}

/// Combined limits and usage model
@JsonSerializable()
class TransferLimitsWithUsage extends Equatable {
  final TransferLimits limits;
  final TransferUsage usage;

  const TransferLimitsWithUsage({
    required this.limits,
    required this.usage,
  });

  factory TransferLimitsWithUsage.fromJson(Map<String, dynamic> json) =>
      _$TransferLimitsWithUsageFromJson(json);

  Map<String, dynamic> toJson() => _$TransferLimitsWithUsageToJson(this);

  @override
  List<Object?> get props => [limits, usage];

  /// Check if a transfer amount is allowed
  bool canTransfer(double amount) {
    return amount >= limits.minimumTransferAmount &&
        amount <= limits.perTransactionLimit &&
        amount <= usage.dailyRemaining &&
        amount <= usage.monthlyRemaining &&
        usage.dailyCountRemaining > 0 &&
        usage.monthlyCountRemaining > 0;
  }

  /// Get transfer validation message
  String? getTransferValidationMessage(double amount) {
    if (amount < limits.minimumTransferAmount) {
      return 'Minimum transfer amount is ${limits.formattedMinimumAmount}';
    }
    if (amount > limits.perTransactionLimit) {
      return 'Maximum transfer amount is ${limits.formattedPerTransactionLimit}';
    }
    if (amount > usage.dailyRemaining) {
      return 'Daily limit exceeded. Remaining: ${usage.formattedDailyRemaining}';
    }
    if (amount > usage.monthlyRemaining) {
      return 'Monthly limit exceeded. Remaining: ${usage.formattedMonthlyRemaining}';
    }
    if (usage.dailyCountRemaining <= 0) {
      return 'Daily transaction count limit exceeded';
    }
    if (usage.monthlyCountRemaining <= 0) {
      return 'Monthly transaction count limit exceeded';
    }
    return null;
  }

  /// Create test combined model for development
  factory TransferLimitsWithUsage.test({
    String? userId,
    String? userTier,
  }) {
    return TransferLimitsWithUsage(
      limits: TransferLimits.test(userId: userId, userTier: userTier),
      usage: TransferUsage.test(),
    );
  }
}
