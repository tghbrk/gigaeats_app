import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer_wallet.dart';
import '../models/loyalty_account.dart';
import '../models/loyalty_transaction.dart';
import '../models/reward_program.dart';
import '../models/promotional_credit.dart';

/// Optimized query service for batch operations and performance
class OptimizedWalletQueryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get comprehensive wallet dashboard data in a single optimized call
  Future<WalletDashboardData> getWalletDashboardData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🚀 [OPTIMIZED-QUERY] Loading comprehensive wallet dashboard data');
      final stopwatch = Stopwatch()..start();

      // Single Edge Function call for all dashboard data
      final response = await _supabase.functions.invoke(
        'wallet-dashboard-optimized',
        body: {
          'user_id': user.id,
          'include_transactions': true,
          'include_loyalty': true,
          'include_rewards': true,
          'include_credits': true,
          'transaction_limit': 10,
          'rewards_limit': 5,
        },
      );

      stopwatch.stop();
      debugPrint('🚀 [OPTIMIZED-QUERY] Dashboard data loaded in ${stopwatch.elapsedMilliseconds}ms');

      if (response.data == null) {
        throw Exception('Failed to load dashboard data');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to load dashboard data: ${data['error']}');
      }

      return WalletDashboardData.fromJson(data);
    } catch (e) {
      debugPrint('❌ [OPTIMIZED-QUERY] Error loading dashboard data: $e');
      rethrow;
    }
  }

  /// Get paginated transactions with optimized queries
  Future<PaginatedTransactions> getTransactionsPaginated({
    required int page,
    required int limit,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🚀 [OPTIMIZED-QUERY] Loading paginated transactions (page: $page, limit: $limit)');

      final response = await _supabase.functions.invoke(
        'wallet-transactions-paginated',
        body: {
          'user_id': user.id,
          'page': page,
          'limit': limit,
          if (type != null) 'transaction_type': type,
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      );

      if (response.data == null) {
        throw Exception('Failed to load transactions');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to load transactions: ${data['error']}');
      }

      return PaginatedTransactions.fromJson(data);
    } catch (e) {
      debugPrint('❌ [OPTIMIZED-QUERY] Error loading transactions: $e');
      rethrow;
    }
  }

  /// Batch update multiple wallet operations
  Future<BatchOperationResult> executeBatchOperations({
    required List<WalletOperation> operations,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🚀 [OPTIMIZED-QUERY] Executing ${operations.length} batch operations');

      final response = await _supabase.functions.invoke(
        'wallet-batch-operations',
        body: {
          'user_id': user.id,
          'operations': operations.map((op) => op.toJson()).toList(),
        },
      );

      if (response.data == null) {
        throw Exception('Failed to execute batch operations');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to execute batch operations: ${data['error']}');
      }

      return BatchOperationResult.fromJson(data);
    } catch (e) {
      debugPrint('❌ [OPTIMIZED-QUERY] Error executing batch operations: $e');
      rethrow;
    }
  }

  /// Get wallet analytics with caching
  Future<WalletAnalytics> getWalletAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    bool useCache = true,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🚀 [OPTIMIZED-QUERY] Loading wallet analytics');

      final response = await _supabase.functions.invoke(
        'wallet-analytics-optimized',
        body: {
          'user_id': user.id,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'use_cache': useCache,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to load analytics');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to load analytics: ${data['error']}');
      }

      return WalletAnalytics.fromJson(data);
    } catch (e) {
      debugPrint('❌ [OPTIMIZED-QUERY] Error loading analytics: $e');
      rethrow;
    }
  }

  /// Preload critical data for faster access
  Future<void> preloadCriticalData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      debugPrint('🚀 [OPTIMIZED-QUERY] Preloading critical data');

      // Preload in background without blocking UI
      _supabase.functions.invoke(
        'wallet-preload-data',
        body: {
          'user_id': user.id,
          'preload_types': ['wallet', 'recent_transactions', 'loyalty_summary'],
        },
      );
    } catch (e) {
      debugPrint('❌ [OPTIMIZED-QUERY] Error preloading data: $e');
      // Don't throw - this is background operation
    }
  }
}

/// Comprehensive wallet dashboard data model
class WalletDashboardData {
  final CustomerWallet? wallet;
  final LoyaltyAccount? loyaltyAccount;
  final List<CustomerWalletTransaction> recentTransactions;
  final List<LoyaltyTransaction> recentLoyaltyTransactions;
  final List<RewardProgram> featuredRewards;
  final List<PromotionalCredit> activeCredits;
  final WalletSummary summary;
  final DateTime loadedAt;

  const WalletDashboardData({
    this.wallet,
    this.loyaltyAccount,
    required this.recentTransactions,
    required this.recentLoyaltyTransactions,
    required this.featuredRewards,
    required this.activeCredits,
    required this.summary,
    required this.loadedAt,
  });

  factory WalletDashboardData.fromJson(Map<String, dynamic> json) {
    return WalletDashboardData(
      wallet: json['wallet'] != null
          ? CustomerWallet.fromJson(json['wallet'])
          : null,
      loyaltyAccount: json['loyalty_account'] != null
          ? LoyaltyAccount.fromJson(json['loyalty_account'])
          : null,
      recentTransactions: (json['recent_transactions'] as List<dynamic>? ?? [])
          .map((item) => CustomerWalletTransaction.fromJson(item))
          .toList(),
      recentLoyaltyTransactions: (json['recent_loyalty_transactions'] as List<dynamic>? ?? [])
          .map((item) => LoyaltyTransaction.fromJson(item))
          .toList(),
      featuredRewards: (json['featured_rewards'] as List<dynamic>? ?? [])
          .map((item) => RewardProgram.fromJson(item))
          .toList(),
      activeCredits: (json['active_credits'] as List<dynamic>? ?? [])
          .map((item) => PromotionalCredit.fromJson(item))
          .toList(),
      summary: WalletSummary.fromJson(json['summary']),
      loadedAt: DateTime.parse(json['loaded_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'wallet': wallet?.toJson(),
    'loyalty_account': loyaltyAccount?.toJson(),
    'recent_transactions': recentTransactions.map((t) => t.toJson()).toList(),
    'recent_loyalty_transactions': recentLoyaltyTransactions.map((t) => t.toJson()).toList(),
    'featured_rewards': featuredRewards.map((r) => r.toJson()).toList(),
    'active_credits': activeCredits.map((c) => c.toJson()).toList(),
    'summary': summary.toJson(),
    'loaded_at': loadedAt.toIso8601String(),
  };
}

/// Paginated transactions result
class PaginatedTransactions {
  final List<CustomerWalletTransaction> transactions;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  const PaginatedTransactions({
    required this.transactions,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
  });

  factory PaginatedTransactions.fromJson(Map<String, dynamic> json) {
    return PaginatedTransactions(
      transactions: (json['transactions'] as List<dynamic>)
          .map((item) => CustomerWalletTransaction.fromJson(item))
          .toList(),
      totalCount: json['total_count'],
      currentPage: json['current_page'],
      totalPages: json['total_pages'],
      hasMore: json['has_more'],
    );
  }
}

/// Wallet operation for batch processing
class WalletOperation {
  final String type;
  final Map<String, dynamic> data;

  const WalletOperation({
    required this.type,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'data': data,
  };
}

/// Batch operation result
class BatchOperationResult {
  final List<String> successfulOperations;
  final List<String> failedOperations;
  final Map<String, String> errors;
  final bool allSuccessful;

  const BatchOperationResult({
    required this.successfulOperations,
    required this.failedOperations,
    required this.errors,
    required this.allSuccessful,
  });

  factory BatchOperationResult.fromJson(Map<String, dynamic> json) {
    return BatchOperationResult(
      successfulOperations: List<String>.from(json['successful_operations'] ?? []),
      failedOperations: List<String>.from(json['failed_operations'] ?? []),
      errors: Map<String, String>.from(json['errors'] ?? {}),
      allSuccessful: json['all_successful'] ?? false,
    );
  }
}

/// Wallet analytics data
class WalletAnalytics {
  final double totalSpent;
  final double totalReceived;
  final int transactionCount;
  final Map<String, double> spendingByCategory;
  final Map<String, int> transactionsByType;
  final List<DailySpending> dailySpending;

  const WalletAnalytics({
    required this.totalSpent,
    required this.totalReceived,
    required this.transactionCount,
    required this.spendingByCategory,
    required this.transactionsByType,
    required this.dailySpending,
  });

  factory WalletAnalytics.fromJson(Map<String, dynamic> json) {
    return WalletAnalytics(
      totalSpent: (json['total_spent'] as num).toDouble(),
      totalReceived: (json['total_received'] as num).toDouble(),
      transactionCount: json['transaction_count'],
      spendingByCategory: Map<String, double>.from(json['spending_by_category'] ?? {}),
      transactionsByType: Map<String, int>.from(json['transactions_by_type'] ?? {}),
      dailySpending: (json['daily_spending'] as List<dynamic>? ?? [])
          .map((item) => DailySpending.fromJson(item))
          .toList(),
    );
  }
}

/// Daily spending data
class DailySpending {
  final DateTime date;
  final double amount;
  final int transactionCount;

  const DailySpending({
    required this.date,
    required this.amount,
    required this.transactionCount,
  });

  factory DailySpending.fromJson(Map<String, dynamic> json) {
    return DailySpending(
      date: DateTime.parse(json['date']),
      amount: (json['amount'] as num).toDouble(),
      transactionCount: json['transaction_count'],
    );
  }
}

/// Wallet summary data
class WalletSummary {
  final double availableBalance;
  final double pendingBalance;
  final int loyaltyPoints;
  final double activeCredits;
  final int pendingTransactions;

  const WalletSummary({
    required this.availableBalance,
    required this.pendingBalance,
    required this.loyaltyPoints,
    required this.activeCredits,
    required this.pendingTransactions,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      availableBalance: (json['available_balance'] as num).toDouble(),
      pendingBalance: (json['pending_balance'] as num).toDouble(),
      loyaltyPoints: json['loyalty_points'] ?? 0,
      activeCredits: (json['active_credits'] as num?)?.toDouble() ?? 0.0,
      pendingTransactions: json['pending_transactions'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'available_balance': availableBalance,
    'pending_balance': pendingBalance,
    'loyalty_points': loyaltyPoints,
    'active_credits': activeCredits,
    'pending_transactions': pendingTransactions,
  };
}
