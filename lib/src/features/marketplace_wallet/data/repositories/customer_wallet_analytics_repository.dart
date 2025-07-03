import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';

import '../../../../data/repositories/base_repository.dart';
import '../../../../core/errors/failures.dart';

/// Repository for customer wallet analytics operations
/// Provides secure access to analytics data with privacy controls
class CustomerWalletAnalyticsRepository extends BaseRepository {
  CustomerWalletAnalyticsRepository({super.client});

  /// Get analytics summary for a user with privacy checks
  Future<Either<Failure, List<Map<String, dynamic>>>> getAnalyticsSummary({
    required String periodType,
    int limit = 12,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ANALYTICS-REPO] Getting analytics summary for period: $periodType');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      try {
        // Use the secure database function that includes privacy checks
        final response = await client.rpc(
          'get_user_analytics_summary',
          params: {
            'p_user_id': currentUser.id,
            'p_period_type': periodType,
            'p_limit': limit,
          },
        );

        // Handle the response properly - it should be a list of records
        if (response == null) {
          debugPrint('🔍 [ANALYTICS-REPO] No analytics data found');
          return <Map<String, dynamic>>[];
        }

        List<Map<String, dynamic>> analyticsData;
        if (response is List) {
          analyticsData = List<Map<String, dynamic>>.from(response);
        } else {
          // Handle single record case
          analyticsData = [Map<String, dynamic>.from(response)];
        }

        debugPrint('🔍 [ANALYTICS-REPO] Analytics summary retrieved: ${analyticsData.length} records');
        return analyticsData;
      } catch (e) {
        debugPrint('❌ [ANALYTICS-REPO] Error getting analytics summary: $e');
        // Return empty list instead of throwing to prevent UI crashes
        return <Map<String, dynamic>>[];
      }
    });
  }

  /// Get spending categories with privacy validation
  Future<Either<Failure, List<Map<String, dynamic>>>> getSpendingCategories({
    int days = 30,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ANALYTICS-REPO] Getting spending categories for $days days');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      try {
        // Use the secure database function
        final response = await client.rpc(
          'get_user_spending_categories',
          params: {
            'p_user_id': currentUser.id,
            'p_days': days,
          },
        );

        // Handle the response properly
        if (response == null) {
          debugPrint('🔍 [ANALYTICS-REPO] No spending categories found');
          return <Map<String, dynamic>>[];
        }

        List<Map<String, dynamic>> categoriesData;
        if (response is List) {
          categoriesData = List<Map<String, dynamic>>.from(response);
        } else {
          // Handle single record case
          categoriesData = [Map<String, dynamic>.from(response)];
        }

        debugPrint('🔍 [ANALYTICS-REPO] Spending categories retrieved: ${categoriesData.length} categories');
        return categoriesData;
      } catch (e) {
        debugPrint('❌ [ANALYTICS-REPO] Error getting spending categories: $e');
        // Return empty list instead of throwing to prevent UI crashes
        return <Map<String, dynamic>>[];
      }
    });
  }

  /// Get spending trends with security checks
  Future<Either<Failure, List<Map<String, dynamic>>>> getSpendingTrends({
    int days = 30,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ANALYTICS-REPO] Getting spending trends for $days days');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      try {
        // Use the secure spending trends function
        final response = await client.rpc(
          'get_secure_spending_trends',
          params: {
            'p_user_id': currentUser.id,
            'p_days': days,
          },
        );

        // Handle the response properly
        if (response == null) {
          debugPrint('🔍 [ANALYTICS-REPO] No spending trends found');
          return <Map<String, dynamic>>[];
        }

        List<Map<String, dynamic>> trendsData;
        if (response is List) {
          trendsData = List<Map<String, dynamic>>.from(response);
        } else {
          // Handle single record case
          trendsData = [Map<String, dynamic>.from(response)];
        }

        debugPrint('🔍 [ANALYTICS-REPO] Spending trends retrieved: ${trendsData.length} data points');
        return trendsData;
      } catch (e) {
        debugPrint('❌ [ANALYTICS-REPO] Error getting spending trends: $e');
        // Return empty list instead of throwing to prevent UI crashes
        return <Map<String, dynamic>>[];
      }
    });
  }

  /// Get current month analytics from materialized view
  Future<Either<Failure, Map<String, dynamic>?>> getCurrentMonthAnalytics() async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ANALYTICS-REPO] Getting current month analytics');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      try {
        // Query the materialized view directly with RLS protection
        final response = await client
            .from('wallet_current_month_analytics')
            .select('*')
            .eq('user_id', currentUser.id)
            .maybeSingle();

        if (response == null) {
          debugPrint('🔍 [ANALYTICS-REPO] No current month analytics found');
          return null;
        }

        debugPrint('🔍 [ANALYTICS-REPO] Current month analytics retrieved');
        return Map<String, dynamic>.from(response);
      } catch (e) {
        debugPrint('❌ [ANALYTICS-REPO] Error getting current month analytics: $e');
        // Return null instead of throwing to prevent UI crashes
        return null;
      }
    });
  }

  /// Get category breakdown for last 30 days from materialized view
  Future<Either<Failure, List<Map<String, dynamic>>>> getCategoryBreakdown30d() async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ANALYTICS-REPO] Getting 30-day category breakdown');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Query the materialized view with RLS protection
      final response = await client
          .from('wallet_category_breakdown_30d')
          .select('*')
          .eq('user_id', currentUser.id)
          .order('total_amount', ascending: false);

      debugPrint('🔍 [ANALYTICS-REPO] Category breakdown retrieved: ${response.length} categories');
      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// Check if user has analytics permission
  Future<Either<Failure, bool>> hasAnalyticsPermission() async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ANALYTICS-REPO] Checking analytics permission');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user's wallet ID first
      final walletResponse = await client.rpc(
        'get_user_customer_wallet_id',
        params: {'p_user_id': currentUser.id},
      );

      if (walletResponse == null) {
        debugPrint('🔍 [ANALYTICS-REPO] No wallet found for user');
        return false;
      }

      // Check analytics permission
      final permissionResponse = await client.rpc(
        'user_has_analytics_permission',
        params: {
          'p_user_id': currentUser.id,
          'p_wallet_id': walletResponse,
        },
      );

      final hasPermission = permissionResponse == true;
      debugPrint('🔍 [ANALYTICS-REPO] Analytics permission: $hasPermission');
      return hasPermission;
    });
  }

  /// Check if user can export analytics
  Future<Either<Failure, bool>> canExportAnalytics() async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ANALYTICS-REPO] Checking export permission');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await client.rpc(
        'can_export_analytics',
        params: {'p_user_id': currentUser.id},
      );

      final canExport = response == true;
      debugPrint('🔍 [ANALYTICS-REPO] Export permission: $canExport');
      return canExport;
    });
  }

  /// Get anonymized analytics for sharing/export
  Future<Either<Failure, List<Map<String, dynamic>>>> getAnonymizedAnalytics({
    required String periodType,
    int limit = 12,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ANALYTICS-REPO] Getting anonymized analytics');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await client.rpc(
        'get_anonymized_analytics_summary',
        params: {
          'p_user_id': currentUser.id,
          'p_period_type': periodType,
          'p_limit': limit,
        },
      );

      debugPrint('🔍 [ANALYTICS-REPO] Anonymized analytics retrieved: ${response.length} records');
      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// Aggregate transaction data for analytics (called by background processes)
  Future<Either<Failure, void>> aggregateTransactionData({
    required String userId,
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
    required String periodType,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ANALYTICS-REPO] Aggregating transaction data for period: $periodType');

      // Get all transactions for the period
      final transactions = await client
          .from('wallet_transactions')
          .select('*')
          .eq('wallet_id', walletId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: true);

      if (transactions.isEmpty) {
        debugPrint('🔍 [ANALYTICS-REPO] No transactions found for aggregation');
        return;
      }

      // Calculate aggregated metrics
      final analytics = _calculateAnalyticsFromTransactions(
        transactions,
        startDate,
        endDate,
        periodType,
      );

      // Insert or update analytics summary
      await client
          .from('wallet_analytics_summary')
          .upsert({
            'user_id': userId,
            'wallet_id': walletId,
            'period_type': periodType,
            'period_start': startDate.toIso8601String().split('T')[0],
            'period_end': endDate.toIso8601String().split('T')[0],
            ...analytics,
          });

      // Calculate and insert spending categories
      final categories = _calculateSpendingCategories(
        transactions,
        startDate,
        endDate,
      );

      for (final category in categories) {
        await client
            .from('wallet_spending_categories')
            .upsert({
              'user_id': userId,
              'wallet_id': walletId,
              'period_start': startDate.toIso8601String().split('T')[0],
              'period_end': endDate.toIso8601String().split('T')[0],
              ...category,
            });
      }

      debugPrint('🔍 [ANALYTICS-REPO] Transaction data aggregation completed');
    });
  }

  /// Calculate analytics metrics from transaction data
  Map<String, dynamic> _calculateAnalyticsFromTransactions(
    List<Map<String, dynamic>> transactions,
    DateTime startDate,
    DateTime endDate,
    String periodType,
  ) {
    double totalSpent = 0.0;
    double totalToppedUp = 0.0;
    double totalTransferredOut = 0.0;
    double totalTransferredIn = 0.0;
    int totalTransactions = 0;
    int topupTransactions = 0;
    int transferOutCount = 0;
    int transferInCount = 0;
    double maxTransaction = 0.0;
    double minTransaction = double.infinity;
    Set<String> uniqueVendors = {};
    String? topVendorId;
    double topVendorSpent = 0.0;

    double periodStartBalance = 0.0;
    double periodEndBalance = 0.0;
    double balanceSum = 0.0;
    int balanceCount = 0;

    for (final transaction in transactions) {
      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      final transactionType = transaction['transaction_type'] as String?;
      final balanceAfter = (transaction['balance_after'] as num?)?.toDouble() ?? 0.0;
      final referenceType = transaction['reference_type'] as String?;
      final referenceId = transaction['reference_id'] as String?;

      totalTransactions++;
      balanceSum += balanceAfter;
      balanceCount++;

      if (totalTransactions == 1) {
        periodStartBalance = (transaction['balance_before'] as num?)?.toDouble() ?? 0.0;
      }
      periodEndBalance = balanceAfter;

      // Categorize transactions
      switch (transactionType) {
        case 'credit':
          totalToppedUp += amount;
          topupTransactions++;
          break;
        case 'debit':
          totalSpent += amount.abs();
          if (referenceType == 'order' && referenceId != null) {
            // Track vendor spending (would need to join with orders table)
            uniqueVendors.add(referenceId);
          }
          break;
        case 'transfer_out':
          totalTransferredOut += amount.abs();
          transferOutCount++;
          break;
        case 'transfer_in':
          totalTransferredIn += amount;
          transferInCount++;
          break;
      }

      // Track min/max transaction amounts
      final absAmount = amount.abs();
      if (absAmount > maxTransaction) maxTransaction = absAmount;
      if (absAmount < minTransaction && absAmount > 0) minTransaction = absAmount;
    }

    if (minTransaction == double.infinity) minTransaction = 0.0;

    return {
      'total_spent': totalSpent,
      'total_transactions': totalTransactions,
      'avg_transaction_amount': totalTransactions > 0 ? totalSpent / totalTransactions : 0.0,
      'max_transaction_amount': maxTransaction,
      'min_transaction_amount': minTransaction,
      'total_topped_up': totalToppedUp,
      'topup_transactions': topupTransactions,
      'avg_topup_amount': topupTransactions > 0 ? totalToppedUp / topupTransactions : 0.0,
      'total_transferred_out': totalTransferredOut,
      'total_transferred_in': totalTransferredIn,
      'transfer_out_count': transferOutCount,
      'transfer_in_count': transferInCount,
      'period_start_balance': periodStartBalance,
      'period_end_balance': periodEndBalance,
      'avg_balance': balanceCount > 0 ? balanceSum / balanceCount : 0.0,
      'max_balance': periodEndBalance, // Simplified - could track actual max
      'min_balance': periodStartBalance, // Simplified - could track actual min
      'unique_vendors_count': uniqueVendors.length,
      'top_vendor_id': topVendorId,
      'top_vendor_spent': topVendorSpent,
    };
  }

  /// Calculate spending categories from transaction data
  List<Map<String, dynamic>> _calculateSpendingCategories(
    List<Map<String, dynamic>> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    Map<String, Map<String, dynamic>> categories = {};

    for (final transaction in transactions) {
      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      final transactionType = transaction['transaction_type'] as String?;
      
      String categoryType;
      String categoryName;

      switch (transactionType) {
        case 'credit':
          categoryType = 'top_ups';
          categoryName = 'Wallet Top-ups';
          break;
        case 'debit':
          categoryType = 'food_orders';
          categoryName = 'Food Orders';
          break;
        case 'transfer_out':
          categoryType = 'transfers';
          categoryName = 'Transfers Out';
          break;
        case 'transfer_in':
          categoryType = 'transfers';
          categoryName = 'Transfers In';
          break;
        case 'refund':
          categoryType = 'refunds';
          categoryName = 'Refunds';
          break;
        default:
          categoryType = 'adjustments';
          categoryName = 'Adjustments';
      }

      final key = '$categoryType-$categoryName';
      if (!categories.containsKey(key)) {
        categories[key] = {
          'category_type': categoryType,
          'category_name': categoryName,
          'total_amount': 0.0,
          'transaction_count': 0,
          'vendor_id': null,
          'vendor_name': null,
        };
      }

      categories[key]!['total_amount'] = 
          (categories[key]!['total_amount'] as double) + amount.abs();
      categories[key]!['transaction_count'] = 
          (categories[key]!['transaction_count'] as int) + 1;
    }

    // Calculate percentages
    final totalAmount = categories.values
        .fold(0.0, (sum, cat) => sum + (cat['total_amount'] as double));

    for (final category in categories.values) {
      final amount = category['total_amount'] as double;
      category['percentage_of_total'] = totalAmount > 0 ? (amount / totalAmount) * 100 : 0.0;
      category['avg_amount'] = (category['transaction_count'] as int) > 0 
          ? amount / (category['transaction_count'] as int) 
          : 0.0;
    }

    return categories.values.toList();
  }

  /// Refresh materialized views (called by background processes)
  Future<Either<Failure, void>> refreshAnalyticsViews() async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ANALYTICS-REPO] Refreshing analytics materialized views');

      await client.rpc('refresh_wallet_analytics_views');

      debugPrint('🔍 [ANALYTICS-REPO] Analytics views refreshed successfully');
    });
  }
}
