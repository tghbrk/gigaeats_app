import 'package:equatable/equatable.dart';

/// Model representing a customer budget with tracking and goals
class CustomerBudget extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final double budgetAmount;
  final String period; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final DateTime endDate;
  final List<String> categoryIds; // Empty list means all categories
  final double spentAmount;
  final double remainingAmount;
  final double percentageUsed;
  final BudgetStatus status;
  final List<BudgetAlert> alerts;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerBudget({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.budgetAmount,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.categoryIds,
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentageUsed,
    required this.status,
    required this.alerts,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerBudget.fromJson(Map<String, dynamic> json) {
    return CustomerBudget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      budgetAmount: (json['budget_amount'] as num).toDouble(),
      period: json['period'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      categoryIds: List<String>.from(json['category_ids'] ?? []),
      spentAmount: (json['spent_amount'] as num).toDouble(),
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      percentageUsed: (json['percentage_used'] as num).toDouble(),
      status: BudgetStatus.fromString(json['status'] as String),
      alerts: (json['alerts'] as List<dynamic>?)
              ?.map((item) => BudgetAlert.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'budget_amount': budgetAmount,
      'period': period,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'category_ids': categoryIds,
      'spent_amount': spentAmount,
      'remaining_amount': remainingAmount,
      'percentage_used': percentageUsed,
      'status': status.value,
      'alerts': alerts.map((alert) => alert.toJson()).toList(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CustomerBudget copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    double? budgetAmount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    double? spentAmount,
    double? remainingAmount,
    double? percentageUsed,
    BudgetStatus? status,
    List<BudgetAlert>? alerts,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerBudget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryIds: categoryIds ?? this.categoryIds,
      spentAmount: spentAmount ?? this.spentAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      percentageUsed: percentageUsed ?? this.percentageUsed,
      status: status ?? this.status,
      alerts: alerts ?? this.alerts,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        budgetAmount,
        period,
        startDate,
        endDate,
        categoryIds,
        spentAmount,
        remainingAmount,
        percentageUsed,
        status,
        alerts,
        isActive,
        createdAt,
        updatedAt,
      ];

  /// Get formatted budget amount
  String get formattedBudgetAmount => 'RM ${budgetAmount.toStringAsFixed(2)}';

  /// Get formatted spent amount
  String get formattedSpentAmount => 'RM ${spentAmount.toStringAsFixed(2)}';

  /// Get formatted remaining amount
  String get formattedRemainingAmount => 'RM ${remainingAmount.toStringAsFixed(2)}';

  /// Get formatted percentage used
  String get formattedPercentageUsed => '${percentageUsed.toStringAsFixed(1)}%';

  /// Check if budget is over limit
  bool get isOverBudget => spentAmount > budgetAmount;

  /// Check if budget is near limit (80% or more)
  bool get isNearLimit => percentageUsed >= 80.0;

  /// Get days remaining in budget period
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Get daily spending allowance based on remaining budget and days
  double get dailyAllowance {
    if (daysRemaining <= 0) return 0.0;
    return remainingAmount / daysRemaining;
  }

  /// Get formatted daily allowance
  String get formattedDailyAllowance => 'RM ${dailyAllowance.toStringAsFixed(2)}';

  /// Check if budget covers all categories
  bool get coversAllCategories => categoryIds.isEmpty;

  /// Get budget progress color based on percentage used
  String get progressColor {
    if (percentageUsed >= 100) return 'error';
    if (percentageUsed >= 80) return 'warning';
    if (percentageUsed >= 60) return 'info';
    return 'success';
  }
}

/// Budget status enumeration
enum BudgetStatus {
  active('active'),
  paused('paused'),
  completed('completed'),
  exceeded('exceeded');

  const BudgetStatus(this.value);
  final String value;

  static BudgetStatus fromString(String value) {
    return BudgetStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BudgetStatus.active,
    );
  }

  String get displayName {
    switch (this) {
      case BudgetStatus.active:
        return 'Active';
      case BudgetStatus.paused:
        return 'Paused';
      case BudgetStatus.completed:
        return 'Completed';
      case BudgetStatus.exceeded:
        return 'Exceeded';
    }
  }
}

/// Budget alert model
class BudgetAlert extends Equatable {
  final String id;
  final String budgetId;
  final String type; // 'threshold', 'exceeded', 'near_end'
  final String title;
  final String message;
  final double? thresholdPercentage;
  final bool isTriggered;
  final DateTime? triggeredAt;
  final DateTime createdAt;

  const BudgetAlert({
    required this.id,
    required this.budgetId,
    required this.type,
    required this.title,
    required this.message,
    this.thresholdPercentage,
    required this.isTriggered,
    this.triggeredAt,
    required this.createdAt,
  });

  factory BudgetAlert.fromJson(Map<String, dynamic> json) {
    return BudgetAlert(
      id: json['id'] as String,
      budgetId: json['budget_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      thresholdPercentage: (json['threshold_percentage'] as num?)?.toDouble(),
      isTriggered: json['is_triggered'] as bool,
      triggeredAt: json['triggered_at'] != null
          ? DateTime.parse(json['triggered_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'budget_id': budgetId,
      'type': type,
      'title': title,
      'message': message,
      'threshold_percentage': thresholdPercentage,
      'is_triggered': isTriggered,
      'triggered_at': triggeredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        budgetId,
        type,
        title,
        message,
        thresholdPercentage,
        isTriggered,
        triggeredAt,
        createdAt,
      ];
}

/// Financial goal model
class FinancialGoal extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String type; // 'savings', 'spending_reduction', 'budget_adherence'
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String status; // 'active', 'completed', 'paused', 'failed'
  final double progressPercentage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FinancialGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.type,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.status,
    required this.progressPercentage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FinancialGoal.fromJson(Map<String, dynamic> json) {
    return FinancialGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num).toDouble(),
      targetDate: DateTime.parse(json['target_date'] as String),
      status: json['status'] as String,
      progressPercentage: (json['progress_percentage'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'type': type,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate.toIso8601String(),
      'status': status,
      'progress_percentage': progressPercentage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        type,
        targetAmount,
        currentAmount,
        targetDate,
        status,
        progressPercentage,
        createdAt,
        updatedAt,
      ];

  /// Get formatted target amount
  String get formattedTargetAmount => 'RM ${targetAmount.toStringAsFixed(2)}';

  /// Get formatted current amount
  String get formattedCurrentAmount => 'RM ${currentAmount.toStringAsFixed(2)}';

  /// Get formatted progress percentage
  String get formattedProgressPercentage => '${progressPercentage.toStringAsFixed(1)}%';

  /// Get remaining amount to reach goal
  double get remainingAmount => targetAmount - currentAmount;

  /// Get formatted remaining amount
  String get formattedRemainingAmount => 'RM ${remainingAmount.toStringAsFixed(2)}';

  /// Get days remaining to reach target date
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(targetDate)) return 0;
    return targetDate.difference(now).inDays;
  }

  /// Check if goal is completed
  bool get isCompleted => status == 'completed' || progressPercentage >= 100.0;

  /// Check if goal is on track
  bool get isOnTrack {
    if (daysRemaining <= 0) return isCompleted;
    final expectedProgress = (DateTime.now().difference(createdAt).inDays / 
                            targetDate.difference(createdAt).inDays) * 100;
    return progressPercentage >= expectedProgress * 0.8; // 80% of expected progress
  }
}
