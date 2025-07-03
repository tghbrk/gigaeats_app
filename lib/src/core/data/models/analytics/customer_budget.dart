import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'customer_budget.g.dart';

/// Enum for budget period types
enum BudgetPeriod {
  @JsonValue('daily')
  daily,
  @JsonValue('weekly')
  weekly,
  @JsonValue('monthly')
  monthly,
  @JsonValue('yearly')
  yearly,
}

/// Enum for budget status
enum BudgetStatus {
  @JsonValue('active')
  active,
  @JsonValue('exceeded')
  exceeded,
  @JsonValue('paused')
  paused,
  @JsonValue('expired')
  expired,
}

/// Model for customer budget management
@JsonSerializable()
class CustomerBudget extends Equatable {
  const CustomerBudget({
    required this.id,
    required this.customerId,
    required this.budgetAmount,
    required this.spentAmount,
    required this.period,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.categoryLimits = const {},
    this.alertThreshold = 0.8,
    this.isActive = true,
  });

  final String id;
  final String customerId;
  final double budgetAmount;
  final double spentAmount;
  final BudgetPeriod period;
  final BudgetStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, double> categoryLimits;
  final double alertThreshold;
  final bool isActive;

  /// Calculate remaining budget amount
  double get remainingAmount => budgetAmount - spentAmount;

  /// Calculate budget utilization percentage
  double get utilizationPercentage => 
      budgetAmount > 0 ? (spentAmount / budgetAmount) * 100 : 0;

  /// Check if budget is exceeded
  bool get isExceeded => spentAmount > budgetAmount;

  /// Check if alert threshold is reached
  bool get isAlertThresholdReached => 
      utilizationPercentage >= (alertThreshold * 100);

  factory CustomerBudget.fromJson(Map<String, dynamic> json) =>
      _$CustomerBudgetFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerBudgetToJson(this);

  CustomerBudget copyWith({
    String? id,
    String? customerId,
    double? budgetAmount,
    double? spentAmount,
    BudgetPeriod? period,
    BudgetStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, double>? categoryLimits,
    double? alertThreshold,
    bool? isActive,
  }) {
    return CustomerBudget(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      period: period ?? this.period,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryLimits: categoryLimits ?? this.categoryLimits,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        budgetAmount,
        spentAmount,
        period,
        status,
        startDate,
        endDate,
        createdAt,
        updatedAt,
        categoryLimits,
        alertThreshold,
        isActive,
      ];
}

/// Model for financial goals
@JsonSerializable()
class FinancialGoal extends Equatable {
  const FinancialGoal({
    required this.id,
    required this.customerId,
    required this.goalType,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.isActive = true,
  });

  final String id;
  final String customerId;
  final String goalType;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final bool isActive;

  /// Calculate progress percentage
  double get progressPercentage => 
      targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0;

  /// Check if goal is achieved
  bool get isAchieved => currentAmount >= targetAmount;

  /// Calculate remaining amount to reach goal
  double get remainingAmount => targetAmount - currentAmount;

  factory FinancialGoal.fromJson(Map<String, dynamic> json) =>
      _$FinancialGoalFromJson(json);

  Map<String, dynamic> toJson() => _$FinancialGoalToJson(this);

  FinancialGoal copyWith({
    String? id,
    String? customerId,
    String? goalType,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    bool? isActive,
  }) {
    return FinancialGoal(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      goalType: goalType ?? this.goalType,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        goalType,
        targetAmount,
        currentAmount,
        targetDate,
        createdAt,
        updatedAt,
        description,
        isActive,
      ];
}
