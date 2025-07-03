import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'transfer_limits.g.dart';

/// Transfer limits model for wallet transfers
@JsonSerializable()
class TransferLimits extends Equatable {
  final String id;
  @JsonKey(name: 'customer_id')
  final String customerId;
  @JsonKey(name: 'daily_limit')
  final double dailyLimit;
  @JsonKey(name: 'monthly_limit')
  final double monthlyLimit;
  @JsonKey(name: 'per_transaction_limit')
  final double perTransactionLimit;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const TransferLimits({
    required this.id,
    required this.customerId,
    required this.dailyLimit,
    required this.monthlyLimit,
    required this.perTransactionLimit,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransferLimits.fromJson(Map<String, dynamic> json) =>
      _$TransferLimitsFromJson(json);

  Map<String, dynamic> toJson() => _$TransferLimitsToJson(this);

  TransferLimits copyWith({
    String? id,
    String? customerId,
    double? dailyLimit,
    double? monthlyLimit,
    double? perTransactionLimit,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransferLimits(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      perTransactionLimit: perTransactionLimit ?? this.perTransactionLimit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        dailyLimit,
        monthlyLimit,
        perTransactionLimit,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Transfer usage tracking model
@JsonSerializable()
class TransferUsage extends Equatable {
  final String id;
  @JsonKey(name: 'customer_id')
  final String customerId;
  @JsonKey(name: 'daily_used')
  final double dailyUsed;
  @JsonKey(name: 'monthly_used')
  final double monthlyUsed;
  @JsonKey(name: 'last_reset_date')
  final DateTime lastResetDate;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const TransferUsage({
    required this.id,
    required this.customerId,
    required this.dailyUsed,
    required this.monthlyUsed,
    required this.lastResetDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransferUsage.fromJson(Map<String, dynamic> json) =>
      _$TransferUsageFromJson(json);

  Map<String, dynamic> toJson() => _$TransferUsageToJson(this);

  TransferUsage copyWith({
    String? id,
    String? customerId,
    double? dailyUsed,
    double? monthlyUsed,
    DateTime? lastResetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransferUsage(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      dailyUsed: dailyUsed ?? this.dailyUsed,
      monthlyUsed: monthlyUsed ?? this.monthlyUsed,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        dailyUsed,
        monthlyUsed,
        lastResetDate,
        createdAt,
        updatedAt,
      ];
}

/// Combined transfer limits with usage information
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

  // Calculated properties
  double get dailyRemaining => limits.dailyLimit - usage.dailyUsed;
  double get monthlyRemaining => limits.monthlyLimit - usage.monthlyUsed;
  
  double get dailyUsagePercentage => 
      limits.dailyLimit > 0 ? (usage.dailyUsed / limits.dailyLimit) * 100 : 0;
  
  double get monthlyUsagePercentage => 
      limits.monthlyLimit > 0 ? (usage.monthlyUsed / limits.monthlyLimit) * 100 : 0;

  bool get isDailyLimitReached => usage.dailyUsed >= limits.dailyLimit;
  bool get isMonthlyLimitReached => usage.monthlyUsed >= limits.monthlyLimit;

  bool canTransfer(double amount) {
    if (!limits.isActive) return false;
    if (amount > limits.perTransactionLimit) return false;
    if (amount > dailyRemaining) return false;
    if (amount > monthlyRemaining) return false;
    return true;
  }

  String? getTransferLimitationReason(double amount) {
    if (!limits.isActive) return 'Transfer limits are not active';
    if (amount > limits.perTransactionLimit) {
      return 'Amount exceeds per-transaction limit of RM ${limits.perTransactionLimit.toStringAsFixed(2)}';
    }
    if (amount > dailyRemaining) {
      return 'Amount exceeds daily remaining limit of RM ${dailyRemaining.toStringAsFixed(2)}';
    }
    if (amount > monthlyRemaining) {
      return 'Amount exceeds monthly remaining limit of RM ${monthlyRemaining.toStringAsFixed(2)}';
    }
    return null;
  }

  @override
  List<Object?> get props => [limits, usage];
}
