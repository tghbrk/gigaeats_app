import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/customer_budget.dart';
import '../../data/services/customer_spending_analytics_service.dart';
import 'customer_spending_analytics_provider.dart';

/// State class for budget management
class CustomerBudgetState {
  final bool isLoading;
  final String? errorMessage;
  final List<CustomerBudget> budgets;
  final List<FinancialGoal> financialGoals;
  final CustomerBudget? selectedBudget;

  const CustomerBudgetState({
    this.isLoading = false,
    this.errorMessage,
    this.budgets = const [],
    this.financialGoals = const [],
    this.selectedBudget,
  });

  CustomerBudgetState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CustomerBudget>? budgets,
    List<FinancialGoal>? financialGoals,
    CustomerBudget? selectedBudget,
  }) {
    return CustomerBudgetState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      budgets: budgets ?? this.budgets,
      financialGoals: financialGoals ?? this.financialGoals,
      selectedBudget: selectedBudget ?? this.selectedBudget,
    );
  }
}

/// Notifier for budget management
class CustomerBudgetNotifier extends StateNotifier<CustomerBudgetState> {
  final CustomerSpendingAnalyticsService _analyticsService;
  final Ref _ref;

  CustomerBudgetNotifier(this._analyticsService, this._ref) 
      : super(const CustomerBudgetState());

  /// Load user budgets
  Future<void> loadBudgets({bool activeOnly = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final budgets = await _analyticsService.getUserBudgets(
        userId: user.id,
        activeOnly: activeOnly,
      );

      state = state.copyWith(
        isLoading: false,
        budgets: budgets,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Create a new budget
  Future<void> createBudget({
    required String name,
    String? description,
    required double budgetAmount,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? categoryIds,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final newBudget = await _analyticsService.createBudget(
        userId: user.id,
        name: name,
        description: description,
        budgetAmount: budgetAmount,
        period: period,
        startDate: startDate,
        endDate: endDate,
        categoryIds: categoryIds,
      );

      // Add the new budget to the list
      final updatedBudgets = [newBudget, ...state.budgets];

      state = state.copyWith(
        isLoading: false,
        budgets: updatedBudgets,
        selectedBudget: newBudget,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Update an existing budget
  Future<void> updateBudget({
    required String budgetId,
    String? name,
    String? description,
    double? budgetAmount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final updatedBudget = await _analyticsService.updateBudget(
        budgetId: budgetId,
        userId: user.id,
        name: name,
        description: description,
        budgetAmount: budgetAmount,
        period: period,
        startDate: startDate,
        endDate: endDate,
        categoryIds: categoryIds,
        isActive: isActive,
      );

      // Update the budget in the list
      final updatedBudgets = state.budgets.map((budget) {
        return budget.id == budgetId ? updatedBudget : budget;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        budgets: updatedBudgets,
        selectedBudget: state.selectedBudget?.id == budgetId ? updatedBudget : state.selectedBudget,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Delete a budget
  Future<void> deleteBudget(String budgetId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _analyticsService.deleteBudget(
        budgetId: budgetId,
        userId: user.id,
      );

      // Remove the budget from the list
      final updatedBudgets = state.budgets.where((budget) => budget.id != budgetId).toList();

      state = state.copyWith(
        isLoading: false,
        budgets: updatedBudgets,
        selectedBudget: state.selectedBudget?.id == budgetId ? null : state.selectedBudget,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Load financial goals
  Future<void> loadFinancialGoals({String? status}) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final goals = await _analyticsService.getFinancialGoals(
        userId: user.id,
        status: status,
      );

      state = state.copyWith(financialGoals: goals);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Create a financial goal
  Future<void> createFinancialGoal({
    required String name,
    required String description,
    required String type,
    required double targetAmount,
    required DateTime targetDate,
  }) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final newGoal = await _analyticsService.createFinancialGoal(
        userId: user.id,
        name: name,
        description: description,
        type: type,
        targetAmount: targetAmount,
        targetDate: targetDate,
      );

      // Add the new goal to the list
      final updatedGoals = [newGoal, ...state.financialGoals];

      state = state.copyWith(financialGoals: updatedGoals);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Select a budget for detailed view
  void selectBudget(CustomerBudget budget) {
    state = state.copyWith(selectedBudget: budget);
  }

  /// Clear selected budget
  void clearSelectedBudget() {
    state = state.copyWith(selectedBudget: null);
  }

  /// Get active budgets
  List<CustomerBudget> get activeBudgets {
    return state.budgets.where((budget) => budget.isActive).toList();
  }

  /// Get budgets that are over limit
  List<CustomerBudget> get overBudgetBudgets {
    return state.budgets.where((budget) => budget.isOverBudget).toList();
  }

  /// Get budgets near limit (80% or more)
  List<CustomerBudget> get nearLimitBudgets {
    return state.budgets.where((budget) => budget.isNearLimit && !budget.isOverBudget).toList();
  }

  /// Get total budget amount for active budgets
  double get totalActiveBudgetAmount {
    return activeBudgets.fold(0.0, (sum, budget) => sum + budget.budgetAmount);
  }

  /// Get total spent amount for active budgets
  double get totalActiveSpentAmount {
    return activeBudgets.fold(0.0, (sum, budget) => sum + budget.spentAmount);
  }

  /// Get overall budget utilization percentage
  double get overallBudgetUtilization {
    final totalBudget = totalActiveBudgetAmount;
    if (totalBudget == 0) return 0.0;
    return (totalActiveSpentAmount / totalBudget) * 100;
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Refresh all budget data
  Future<void> refreshAll() async {
    await loadBudgets();
    await loadFinancialGoals();
  }
}

/// Provider for budget state management
final customerBudgetProvider = StateNotifierProvider<CustomerBudgetNotifier, CustomerBudgetState>((ref) {
  final analyticsService = ref.watch(customerSpendingAnalyticsServiceProvider);
  return CustomerBudgetNotifier(analyticsService, ref);
});

/// Provider for user budgets as AsyncValue
final userBudgetsProvider = FutureProvider.family<List<CustomerBudget>, bool>((ref, activeOnly) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  if (user == null) {
    return [];
  }

  final analyticsService = ref.watch(customerSpendingAnalyticsServiceProvider);
  return analyticsService.getUserBudgets(
    userId: user.id,
    activeOnly: activeOnly,
  );
});

/// Provider for financial goals as AsyncValue
final financialGoalsProvider = FutureProvider.family<List<FinancialGoal>, String?>((ref, status) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  if (user == null) {
    return [];
  }

  final analyticsService = ref.watch(customerSpendingAnalyticsServiceProvider);
  return analyticsService.getFinancialGoals(
    userId: user.id,
    status: status,
  );
});

/// Provider for active budgets
final activeBudgetsProvider = Provider<List<CustomerBudget>>((ref) {
  final budgetState = ref.watch(customerBudgetProvider);
  return budgetState.budgets.where((budget) => budget.isActive).toList();
});

/// Provider for budget alerts (budgets over or near limit)
final budgetAlertsProvider = Provider<List<CustomerBudget>>((ref) {
  final budgetState = ref.watch(customerBudgetProvider);
  return budgetState.budgets.where((budget) => 
    budget.isActive && (budget.isOverBudget || budget.isNearLimit)
  ).toList();
});

/// Provider for budget statistics
final budgetStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final budgetNotifier = ref.watch(customerBudgetProvider.notifier);
  final budgetState = ref.watch(customerBudgetProvider);
  
  return {
    'total_budgets': budgetState.budgets.length,
    'active_budgets': budgetNotifier.activeBudgets.length,
    'over_budget_count': budgetNotifier.overBudgetBudgets.length,
    'near_limit_count': budgetNotifier.nearLimitBudgets.length,
    'total_budget_amount': budgetNotifier.totalActiveBudgetAmount,
    'total_spent_amount': budgetNotifier.totalActiveSpentAmount,
    'overall_utilization': budgetNotifier.overallBudgetUtilization,
  };
});
