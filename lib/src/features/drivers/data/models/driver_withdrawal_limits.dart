import 'package:freezed_annotation/freezed_annotation.dart';

part 'driver_withdrawal_limits.freezed.dart';
part 'driver_withdrawal_limits.g.dart';

/// Model for driver withdrawal limits
@freezed
class DriverWithdrawalLimits with _$DriverWithdrawalLimits {
  const factory DriverWithdrawalLimits({
    required String id,
    required String driverId,
    required double dailyLimit,
    required double dailyUsed,
    required DateTime dailyResetAt,
    required double weeklyLimit,
    required double weeklyUsed,
    required DateTime weeklyResetAt,
    required double monthlyLimit,
    required double monthlyUsed,
    required DateTime monthlyResetAt,
    required String riskLevel,
    List<String>? fraudFlags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _DriverWithdrawalLimits;

  factory DriverWithdrawalLimits.fromJson(Map<String, dynamic> json) =>
      _$DriverWithdrawalLimitsFromJson(json);
}

/// Extension for withdrawal limits calculations
extension DriverWithdrawalLimitsCalculations on DriverWithdrawalLimits {
  double get dailyRemaining => (dailyLimit - dailyUsed).clamp(0.0, dailyLimit);
  double get weeklyRemaining => (weeklyLimit - weeklyUsed).clamp(0.0, weeklyLimit);
  double get monthlyRemaining => (monthlyLimit - monthlyUsed).clamp(0.0, monthlyLimit);
  
  double get dailyUsagePercentage => dailyLimit > 0 ? (dailyUsed / dailyLimit).clamp(0.0, 1.0) : 0.0;
  double get weeklyUsagePercentage => weeklyLimit > 0 ? (weeklyUsed / weeklyLimit).clamp(0.0, 1.0) : 0.0;
  double get monthlyUsagePercentage => monthlyLimit > 0 ? (monthlyUsed / monthlyLimit).clamp(0.0, 1.0) : 0.0;
  
  bool get isDailyLimitExceeded => dailyUsed >= dailyLimit;
  bool get isWeeklyLimitExceeded => weeklyUsed >= weeklyLimit;
  bool get isMonthlyLimitExceeded => monthlyUsed >= monthlyLimit;
  
  bool get isHighRisk => riskLevel == 'high';
  bool get isMediumRisk => riskLevel == 'medium';
  bool get isLowRisk => riskLevel == 'low';
  
  String get riskLevelDisplayName {
    switch (riskLevel) {
      case 'low':
        return 'Low Risk';
      case 'medium':
        return 'Medium Risk';
      case 'high':
        return 'High Risk';
      default:
        return riskLevel;
    }
  }
  
  bool canWithdraw(double amount) {
    return amount <= dailyRemaining && 
           amount <= weeklyRemaining && 
           amount <= monthlyRemaining;
  }
  
  String? getWithdrawalLimitationReason(double amount) {
    if (amount > dailyRemaining) {
      return 'Amount exceeds daily limit (RM ${dailyRemaining.toStringAsFixed(2)} remaining)';
    }
    if (amount > weeklyRemaining) {
      return 'Amount exceeds weekly limit (RM ${weeklyRemaining.toStringAsFixed(2)} remaining)';
    }
    if (amount > monthlyRemaining) {
      return 'Amount exceeds monthly limit (RM ${monthlyRemaining.toStringAsFixed(2)} remaining)';
    }
    return null;
  }
}
