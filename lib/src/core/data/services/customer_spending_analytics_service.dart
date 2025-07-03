import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/analytics/customer_spending_analytics.dart';
import '../models/analytics/customer_budget.dart';

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
      debugPrint('🔍 [SPENDING-ANALYTICS] Response data type: ${data.runtimeType}');
      debugPrint('🔍 [SPENDING-ANALYTICS] Response data: ${data.toString().substring(0, data.toString().length > 200 ? 200 : data.toString().length)}...');

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

      // Check if the response has the expected structure
      Map<String, dynamic> rawData;
      if (analyticsData['data'] != null) {
        // Edge Function returns { success: true, data: {...} }
        rawData = analyticsData['data'] as Map<String, dynamic>;
      } else if (analyticsData['analytics'] != null) {
        // Alternative structure { analytics: {...} }
        rawData = analyticsData['analytics'] as Map<String, dynamic>;
      } else {
        // Direct analytics data
        rawData = analyticsData;
      }

      // Map the Edge Function response to the expected model structure
      final now = DateTime.now();
      final periodStart = startDate ?? (period == 'monthly'
          ? DateTime(now.year, now.month, 1)
          : now.subtract(const Duration(days: 30)));
      final periodEnd = endDate ?? now;

      final analyticsJson = {
        'user_id': userId,
        'period_start': periodStart.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
        'total_spent': rawData['total_spent'] ?? 0.0,
        'average_spending': rawData['avg_transaction_amount'] ?? 0.0,
        'transaction_count': rawData['total_transactions'] ?? 0,
        'category_breakdown': <Map<String, dynamic>>[], // Empty for now
        'daily_trends': <Map<String, dynamic>>[], // Empty for now
        'weekly_trends': <Map<String, dynamic>>[], // Empty for now
        'monthly_trends': <Map<String, dynamic>>[], // Empty for now
        'top_merchants': <Map<String, dynamic>>[], // Empty for now
        'insights': <Map<String, dynamic>>[], // Empty for now
        'comparison': null,
        'metadata': {'source': 'edge_function', 'period': period},
      };

      return CustomerSpendingAnalytics.fromJson(analyticsJson);
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
      debugPrint('🔍 [SPENDING-TRENDS] Fetching trends for user: $userId, period: $period');

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
      debugPrint('🔍 [SPENDING-TRENDS] Raw response data: $data');

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

      // Check if response indicates success
      if (trendsData['success'] != true) {
        debugPrint('❌ [SPENDING-TRENDS] Response indicates failure: ${trendsData['success']}');
        return <SpendingTrend>[];
      }

      // Extract the data array from the response
      final trendsArray = trendsData['data'];
      if (trendsArray == null || trendsArray is! List) {
        debugPrint('❌ [SPENDING-TRENDS] No data array found in response');
        return <SpendingTrend>[];
      }

      debugPrint('🔍 [SPENDING-TRENDS] Processing ${trendsArray.length} trend data points');

      // Map Edge Function response to SpendingTrend models
      final trends = <SpendingTrend>[];
      for (final item in trendsArray) {
        if (item is! Map<String, dynamic>) {
          debugPrint('⚠️ [SPENDING-TRENDS] Skipping invalid trend item: ${item.runtimeType}');
          continue;
        }

        try {
          // Map TrendDataPoint fields to SpendingTrend fields
          final trendData = item;

          final trend = SpendingTrend(
            date: DateTime.parse(trendData['date_period'] as String),
            amount: (trendData['daily_spent'] as num?)?.toDouble() ?? 0.0,
            transactionCount: trendData['daily_transactions'] as int? ?? 0,
            period: period, // Use the period parameter passed to the function
          );

          trends.add(trend);
          debugPrint('✅ [SPENDING-TRENDS] Mapped trend: ${trend.date} - RM${trend.amount.toStringAsFixed(2)} (${trend.transactionCount} txns)');
        } catch (e) {
          debugPrint('⚠️ [SPENDING-TRENDS] Error mapping trend item: $e');
          debugPrint('⚠️ [SPENDING-TRENDS] Item data: $item');
          continue;
        }
      }

      debugPrint('✅ [SPENDING-TRENDS] Successfully mapped ${trends.length} spending trends');
      return trends;
    } on FunctionException catch (e) {
      debugPrint('❌ [SPENDING-TRENDS] Function exception: ${e.details}');
      throw Exception('Failed to load spending trends: ${e.details}');
    } catch (e) {
      debugPrint('❌ [SPENDING-TRENDS] General exception: $e');
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
      debugPrint('🔍 [SPENDING-CATEGORIES] Fetching categories for user: $userId');

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
      debugPrint('🔍 [SPENDING-CATEGORIES] Raw response data: $data');

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

      // Check if response indicates success
      if (categoriesData['success'] != true) {
        debugPrint('❌ [SPENDING-CATEGORIES] Response indicates failure: ${categoriesData['success']}');
        return <SpendingCategory>[];
      }

      // Extract the data array from the response
      final categoriesArray = categoriesData['data'];
      if (categoriesArray == null || categoriesArray is! List) {
        debugPrint('❌ [SPENDING-CATEGORIES] No data array found in response');
        return <SpendingCategory>[];
      }

      debugPrint('🔍 [SPENDING-CATEGORIES] Processing ${categoriesArray.length} category data points');

      // Map Edge Function response to SpendingCategory models
      final categories = <SpendingCategory>[];
      for (final item in categoriesArray) {
        if (item is! Map<String, dynamic>) {
          debugPrint('⚠️ [SPENDING-CATEGORIES] Skipping invalid category item: ${item.runtimeType}');
          continue;
        }

        try {
          // Map CategorySpending fields to SpendingCategory fields
          final categoryData = item;

          final category = SpendingCategory(
            categoryId: categoryData['category'] as String? ?? 'unknown',
            categoryName: categoryData['category_name'] as String? ?? 'Unknown',
            categoryIcon: _getCategoryIcon(categoryData['category'] as String? ?? 'unknown'),
            amount: (categoryData['total_amount'] as num?)?.toDouble() ?? 0.0,
            transactionCount: categoryData['transaction_count'] as int? ?? 0,
            percentage: (categoryData['percentage_of_total'] as num?)?.toDouble() ?? 0.0,
            color: categoryData['color'] as String? ?? _getCategoryColor(categoryData['category'] as String? ?? 'unknown'),
          );

          categories.add(category);
          debugPrint('✅ [SPENDING-CATEGORIES] Mapped category: ${category.categoryName} - RM${category.amount.toStringAsFixed(2)} (${category.percentage.toStringAsFixed(1)}%)');
        } catch (e) {
          debugPrint('⚠️ [SPENDING-CATEGORIES] Error mapping category item: $e');
          debugPrint('⚠️ [SPENDING-CATEGORIES] Item data: $item');
          continue;
        }
      }

      debugPrint('✅ [SPENDING-CATEGORIES] Successfully mapped ${categories.length} spending categories');
      return categories;
    } on FunctionException catch (e) {
      debugPrint('❌ [SPENDING-CATEGORIES] Function exception: ${e.details}');
      throw Exception('Failed to load category spending: ${e.details}');
    } catch (e) {
      debugPrint('❌ [SPENDING-CATEGORIES] General exception: $e');
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
    final now = DateTime.now();
    final startDate = period == 'monthly'
        ? DateTime(now.year, now.month, 1)
        : now.subtract(const Duration(days: 30));

    return CustomerSpendingAnalytics(
      userId: userId,
      periodStart: startDate,
      periodEnd: now,
      totalSpent: 0.0,
      averageSpending: 0.0,
      transactionCount: 0,
      categoryBreakdown: [],
      dailyTrends: [],
      weeklyTrends: [],
      monthlyTrends: [],
      topMerchants: [],
      insights: [],
      comparison: null,
      metadata: {'source': 'default_fallback'},
    );
  }

  /// Get category icon based on category key
  String _getCategoryIcon(String categoryKey) {
    switch (categoryKey) {
      case 'food_orders':
        return 'restaurant';
      case 'transfers':
        return 'swap_horiz';
      case 'delivery_fees':
        return 'local_shipping';
      case 'service_fees':
        return 'build';
      case 'tips':
        return 'star';
      case 'payments':
        return 'payment';
      case 'other':
      default:
        return 'category';
    }
  }

  /// Get category color based on category key
  String _getCategoryColor(String categoryKey) {
    switch (categoryKey) {
      case 'food_orders':
        return '#FF6B6B';
      case 'transfers':
        return '#4ECDC4';
      case 'delivery_fees':
        return '#45B7D1';
      case 'service_fees':
        return '#96CEB4';
      case 'tips':
        return '#FFEAA7';
      case 'payments':
        return '#DDA0DD';
      case 'other':
      default:
        return '#95A5A6';
    }
  }
}
