import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer_spending_analytics.dart';
import '../models/customer_budget.dart';

/// Service for customer spending analytics and insights
class CustomerSpendingAnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get comprehensive spending analytics for a user
  Future<CustomerSpendingAnalytics> getSpendingAnalytics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String period = 'monthly', // 'daily', 'weekly', 'monthly', 'yearly'
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'spending-analytics',
        body: {
          'user_id': userId,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'period': period,
        },
      );

      if (response.data == null) {
        debugPrint('❌ [SPENDING-ANALYTICS] Response data is null, returning default analytics');
        return _getDefaultAnalytics(userId, period);
      }

      final data = response.data;

      // Handle different response formats
      Map<String, dynamic> analyticsData;
      if (data is Map<String, dynamic>) {
        analyticsData = data;
      } else {
        debugPrint('❌ [SPENDING-ANALYTICS] Unexpected response format: ${data.runtimeType}');
        return _getDefaultAnalytics(userId, period);
      }

      if (analyticsData['error'] != null) {
        throw Exception('Failed to load spending analytics: ${analyticsData['error']}');
      }

      return CustomerSpendingAnalytics.fromJson(data['analytics'] as Map<String, dynamic>);
    } on FunctionException catch (e) {
      throw Exception('Failed to load spending analytics: ${e.details}');
    } catch (e) {
      throw Exception('Failed to load spending analytics: ${e.toString()}');
    }
  }

  /// Get spending trends for charts
  Future<List<SpendingTrend>> getSpendingTrends({
    required String userId,
    required String period, // 'daily', 'weekly', 'monthly'
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'spending-trends',
        body: {
          'user_id': userId,
          'period': period,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'limit': limit,
        },
      );

      if (response.data == null) {
        debugPrint('❌ [SPENDING-TRENDS] Response data is null, returning empty list');
        return <SpendingTrend>[];
      }

      final data = response.data;

      // Handle different response formats
      Map<String, dynamic> trendsData;
      if (data is Map<String, dynamic>) {
        trendsData = data;
      } else {
        debugPrint('❌ [SPENDING-TRENDS] Unexpected response format: ${data.runtimeType}');
        return <SpendingTrend>[];
      }

      if (trendsData['error'] != null) {
        debugPrint('❌ [SPENDING-TRENDS] Error in response: ${trendsData['error']}');
        return <SpendingTrend>[];
      }

      // Return empty list for now since the models might not match
      debugPrint('⚠️ [SPENDING-TRENDS] Returning empty list - Edge Function integration needs fixing');
      return <SpendingTrend>[];
    } on FunctionException catch (e) {
      throw Exception('Failed to load spending trends: ${e.details}');
    } catch (e) {
      throw Exception('Failed to load spending trends: ${e.toString()}');
    }
  }

  /// Get spending by category
  Future<List<SpendingCategory>> getSpendingByCategory({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'spending-by-category',
        body: {
          'user_id': userId,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'limit': limit,
        },
      );

      if (response.data == null) {
        debugPrint('❌ [SPENDING-CATEGORIES] Response data is null, returning empty list');
        return <SpendingCategory>[];
      }

      final data = response.data;

      // Handle different response formats
      Map<String, dynamic> categoriesData;
      if (data is Map<String, dynamic>) {
        categoriesData = data;
      } else {
        debugPrint('❌ [SPENDING-CATEGORIES] Unexpected response format: ${data.runtimeType}');
        return <SpendingCategory>[];
      }

      if (categoriesData['error'] != null) {
        debugPrint('❌ [SPENDING-CATEGORIES] Error in response: ${categoriesData['error']}');
        return <SpendingCategory>[];
      }

      // Return empty list for now since the models might not match
      debugPrint('⚠️ [SPENDING-CATEGORIES] Returning empty list - Edge Function integration needs fixing');
      return <SpendingCategory>[];
    } on FunctionException catch (e) {
      throw Exception('Failed to load category spending: ${e.details}');
    } catch (e) {
      throw Exception('Failed to load category spending: ${e.toString()}');
    }
  }

  /// Get top merchants by spending
  Future<List<MerchantSpending>> getTopMerchants({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'top-merchants',
        body: {
          'user_id': userId,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'limit': limit,
        },
      );

      if (response.data == null) {
        debugPrint('❌ [TOP-MERCHANTS] Response data is null, returning empty list');
        return <MerchantSpending>[];
      }

      final data = response.data;

      // Handle different response formats
      Map<String, dynamic> merchantsData;
      if (data is Map<String, dynamic>) {
        merchantsData = data;
      } else {
        debugPrint('❌ [TOP-MERCHANTS] Unexpected response format: ${data.runtimeType}');
        return <MerchantSpending>[];
      }

      if (merchantsData['error'] != null) {
        debugPrint('❌ [TOP-MERCHANTS] Error in response: ${merchantsData['error']}');
        return <MerchantSpending>[];
      }

      // Return empty list for now since the models might not match
      debugPrint('⚠️ [TOP-MERCHANTS] Returning empty list - Edge Function integration needs fixing');
      return <MerchantSpending>[];
    } on FunctionException catch (e) {
      throw Exception('Failed to load top merchants: ${e.details}');
    } catch (e) {
      throw Exception('Failed to load top merchants: ${e.toString()}');
    }
  }

  /// Get personalized spending insights
  Future<List<SpendingInsight>> getSpendingInsights({
    required String userId,
    int limit = 5,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'spending-insights',
        body: {
          'user_id': userId,
          'limit': limit,
        },
      );

      if (response.data == null) {
        debugPrint('❌ [SPENDING-INSIGHTS] Response data is null, returning empty list');
        return <SpendingInsight>[];
      }

      final data = response.data;

      // Handle different response formats
      Map<String, dynamic> insightsData;
      if (data is Map<String, dynamic>) {
        insightsData = data;
      } else {
        debugPrint('❌ [SPENDING-INSIGHTS] Unexpected response format: ${data.runtimeType}');
        return <SpendingInsight>[];
      }

      if (insightsData['error'] != null) {
        debugPrint('❌ [SPENDING-INSIGHTS] Error in response: ${insightsData['error']}');
        return <SpendingInsight>[];
      }

      // Return empty list for now since the models might not match
      debugPrint('⚠️ [SPENDING-INSIGHTS] Returning empty list - Edge Function integration needs fixing');
      return <SpendingInsight>[];
    } on FunctionException catch (e) {
      throw Exception('Failed to load spending insights: ${e.details}');
    } catch (e) {
      throw Exception('Failed to load spending insights: ${e.toString()}');
    }
  }

  /// Export spending data
  Future<Map<String, dynamic>> exportSpendingData({
    required String userId,
    required String format, // 'csv', 'pdf', 'json'
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'export-spending-data',
        body: {
          'user_id': userId,
          'format': format,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'categories': categories,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to export spending data');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to export spending data: ${data['error']}');
      }

      return {
        'download_url': data['download_url'] as String,
        'file_name': data['file_name'] as String,
        'file_size': data['file_size'] as int,
        'expires_at': data['expires_at'] as String,
      };
    } on FunctionException catch (e) {
      throw Exception('Failed to export spending data: ${e.details}');
    } catch (e) {
      throw Exception('Failed to export spending data: ${e.toString()}');
    }
  }

  /// Get user budgets
  Future<List<CustomerBudget>> getUserBudgets({
    required String userId,
    bool activeOnly = false,
  }) async {
    try {
      var query = _supabase
          .from('customer_budgets')
          .select('*')
          .eq('user_id', userId);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final orderedQuery = query.order('created_at', ascending: false);

      final response = await orderedQuery;

      return (response as List<dynamic>)
          .map((item) => CustomerBudget.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to load budgets: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load budgets: ${e.toString()}');
    }
  }

  /// Create a new budget
  Future<CustomerBudget> createBudget({
    required String userId,
    required String name,
    String? description,
    required double budgetAmount,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? categoryIds,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-budget',
        body: {
          'user_id': userId,
          'name': name,
          'description': description,
          'budget_amount': budgetAmount,
          'period': period,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'category_ids': categoryIds ?? [],
        },
      );

      if (response.data == null) {
        throw Exception('Failed to create budget');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to create budget: ${data['error']}');
      }

      return CustomerBudget.fromJson(data['budget'] as Map<String, dynamic>);
    } on FunctionException catch (e) {
      throw Exception('Failed to create budget: ${e.details}');
    } catch (e) {
      throw Exception('Failed to create budget: ${e.toString()}');
    }
  }

  /// Update budget
  Future<CustomerBudget> updateBudget({
    required String budgetId,
    required String userId,
    String? name,
    String? description,
    double? budgetAmount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    bool? isActive,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'update-budget',
        body: {
          'budget_id': budgetId,
          'user_id': userId,
          'name': name,
          'description': description,
          'budget_amount': budgetAmount,
          'period': period,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'category_ids': categoryIds,
          'is_active': isActive,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to update budget');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to update budget: ${data['error']}');
      }

      return CustomerBudget.fromJson(data['budget'] as Map<String, dynamic>);
    } on FunctionException catch (e) {
      throw Exception('Failed to update budget: ${e.details}');
    } catch (e) {
      throw Exception('Failed to update budget: ${e.toString()}');
    }
  }

  /// Delete budget
  Future<void> deleteBudget({
    required String budgetId,
    required String userId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'delete-budget',
        body: {
          'budget_id': budgetId,
          'user_id': userId,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to delete budget');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to delete budget: ${data['error']}');
      }
    } on FunctionException catch (e) {
      throw Exception('Failed to delete budget: ${e.details}');
    } catch (e) {
      throw Exception('Failed to delete budget: ${e.toString()}');
    }
  }

  /// Get financial goals
  Future<List<FinancialGoal>> getFinancialGoals({
    required String userId,
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('financial_goals')
          .select('*')
          .eq('user_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final orderedQuery = query.order('created_at', ascending: false);

      final response = await orderedQuery;

      return (response as List<dynamic>)
          .map((item) => FinancialGoal.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to load financial goals: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load financial goals: ${e.toString()}');
    }
  }

  /// Create financial goal
  Future<FinancialGoal> createFinancialGoal({
    required String userId,
    required String name,
    required String description,
    required String type,
    required double targetAmount,
    required DateTime targetDate,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-financial-goal',
        body: {
          'user_id': userId,
          'name': name,
          'description': description,
          'type': type,
          'target_amount': targetAmount,
          'target_date': targetDate.toIso8601String(),
        },
      );

      if (response.data == null) {
        throw Exception('Failed to create financial goal');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to create financial goal: ${data['error']}');
      }

      return FinancialGoal.fromJson(data['goal'] as Map<String, dynamic>);
    } on FunctionException catch (e) {
      throw Exception('Failed to create financial goal: ${e.details}');
    } catch (e) {
      throw Exception('Failed to create financial goal: ${e.toString()}');
    }
  }

  /// Get default analytics when Edge Function fails
  CustomerSpendingAnalytics _getDefaultAnalytics(String userId, String period) {
    // Return a simple default analytics object
    // This will be replaced with proper data once Edge Functions are working
    throw Exception('Analytics service temporarily unavailable');
  }
}
