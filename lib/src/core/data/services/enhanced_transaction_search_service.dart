import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/analytics/transaction_search_filter.dart';
import '../models/analytics/transaction_export.dart';
import '../../../features/marketplace_wallet/data/models/wallet_transaction.dart';

/// Enhanced service for transaction search, filtering, and export
class EnhancedTransactionSearchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Search transactions with advanced filtering
  Future<TransactionSearchResult> searchTransactions({
    required String walletId,
    required TransactionSearchFilter filter,
  }) async {
    try {
      debugPrint('🔍 [ENHANCED-SEARCH] Searching transactions with filter: ${filter.toJson()}');

      final params = {
        'action': 'search',
        'wallet_id': walletId,
        ...filter.toApiParams(),
      };

      final response = await _supabase.functions.invoke(
        'transaction-search',
        body: params,
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to search transactions');
      }

      final data = response.data['data'] as Map<String, dynamic>;
      
      // Parse transactions
      final transactionsData = data['transactions'] as List<dynamic>;
      final transactions = transactionsData
          .map((json) => WalletTransaction.fromJson(json as Map<String, dynamic>))
          .toList();

      // Parse pagination
      final paginationData = data['pagination'] as Map<String, dynamic>;
      final pagination = TransactionSearchPagination.fromJson(paginationData);

      // Parse applied filters
      final filtersData = data['filters_applied'] as Map<String, dynamic>;
      final appliedFilter = TransactionSearchFilter.fromJson(filtersData);

      final result = TransactionSearchResult(
        transactions: transactions,
        pagination: pagination,
        filtersApplied: appliedFilter,
      );

      debugPrint('✅ [ENHANCED-SEARCH] Found ${transactions.length} transactions');
      return result;
    } catch (e) {
      debugPrint('❌ [ENHANCED-SEARCH] Error searching transactions: $e');
      throw Exception('Failed to search transactions: $e');
    }
  }

  /// Export transactions with applied filters
  Future<TransactionExport> exportTransactions({
    required String walletId,
    required TransactionSearchFilter filter,
    ExportFormat format = ExportFormat.csv,
  }) async {
    try {
      debugPrint('🔍 [ENHANCED-SEARCH] Exporting transactions in ${format.name} format');

      final params = {
        'action': 'export',
        'wallet_id': walletId,
        'export_format': format.name,
        ...filter.toApiParams(),
      };

      final response = await _supabase.functions.invoke(
        'transaction-search',
        body: params,
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to export transactions');
      }

      final exportData = response.data['data'] as Map<String, dynamic>;
      final export = TransactionExport.fromJson(exportData);

      debugPrint('✅ [ENHANCED-SEARCH] Exported ${export.recordCount} transactions');
      return export;
    } catch (e) {
      debugPrint('❌ [ENHANCED-SEARCH] Error exporting transactions: $e');
      throw Exception('Failed to export transactions: $e');
    }
  }

  /// Get search suggestions based on query
  Future<TransactionSearchSuggestionsResponse> getSearchSuggestions({
    required String walletId,
    required String query,
  }) async {
    try {
      if (query.length < 2) {
        return const TransactionSearchSuggestionsResponse(
          suggestions: [],
          query: '',
        );
      }

      debugPrint('🔍 [ENHANCED-SEARCH] Getting suggestions for: "$query"');

      final response = await _supabase.functions.invoke(
        'transaction-search',
        body: {
          'action': 'suggestions',
          'wallet_id': walletId,
          'search_query': query,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to get suggestions');
      }

      final data = response.data['data'] as Map<String, dynamic>;
      final suggestionsData = data['suggestions'] as List<dynamic>;
      
      final suggestions = suggestionsData
          .map((json) => TransactionSearchSuggestion.fromJson(json as Map<String, dynamic>))
          .toList();

      final result = TransactionSearchSuggestionsResponse(
        suggestions: suggestions,
        query: data['query'] as String,
      );

      debugPrint('✅ [ENHANCED-SEARCH] Found ${suggestions.length} suggestions');
      return result;
    } catch (e) {
      debugPrint('❌ [ENHANCED-SEARCH] Error getting suggestions: $e');
      return TransactionSearchSuggestionsResponse(
        suggestions: const [],
        query: query,
      );
    }
  }

  /// Get transaction statistics for a date range
  Future<TransactionStatisticsResponse> getTransactionStatistics({
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('🔍 [ENHANCED-SEARCH] Getting statistics for date range');

      final params = {
        'action': 'statistics',
        'wallet_id': walletId,
      };

      if (startDate != null) {
        params['start_date'] = startDate.toIso8601String();
      }

      if (endDate != null) {
        params['end_date'] = endDate.toIso8601String();
      }

      final response = await _supabase.functions.invoke(
        'transaction-search',
        body: params,
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to get statistics');
      }

      final data = response.data['data'] as Map<String, dynamic>;
      final statistics = TransactionStatistics.fromJson(
        data['statistics'] as Map<String, dynamic>,
      );

      final result = TransactionStatisticsResponse(
        statistics: statistics,
        dateRange: data['date_range'] as Map<String, String>?,
        generatedAt: DateTime.parse(data['generated_at'] as String),
      );

      debugPrint('✅ [ENHANCED-SEARCH] Generated statistics: ${statistics.totalTransactions} transactions');
      return result;
    } catch (e) {
      debugPrint('❌ [ENHANCED-SEARCH] Error getting statistics: $e');
      throw Exception('Failed to get statistics: $e');
    }
  }

  /// Quick search by text query
  Future<TransactionSearchResult> quickSearch({
    required String walletId,
    required String query,
    int limit = 10,
  }) async {
    final filter = TransactionSearchFilter(
      searchQuery: query,
      limit: limit,
    );

    return searchTransactions(walletId: walletId, filter: filter);
  }

  /// Search by transaction type
  Future<TransactionSearchResult> searchByType({
    required String walletId,
    required WalletTransactionType type,
    int limit = 20,
  }) async {
    final filter = TransactionSearchFilter(
      transactionTypes: [type],
      limit: limit,
    );

    return searchTransactions(walletId: walletId, filter: filter);
  }

  /// Search by amount range
  Future<TransactionSearchResult> searchByAmountRange({
    required String walletId,
    required double minAmount,
    required double maxAmount,
    int limit = 20,
  }) async {
    final filter = TransactionSearchFilter(
      amountMin: minAmount,
      amountMax: maxAmount,
      limit: limit,
    );

    return searchTransactions(walletId: walletId, filter: filter);
  }

  /// Search by date range
  Future<TransactionSearchResult> searchByDateRange({
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 20,
  }) async {
    final filter = TransactionSearchFilter(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );

    return searchTransactions(walletId: walletId, filter: filter);
  }

  /// Get today's transactions
  Future<TransactionSearchResult> getTodaysTransactions({
    required String walletId,
    int limit = 20,
  }) async {
    return searchTransactions(
      walletId: walletId,
      filter: TransactionSearchFilter.today().copyWith(limit: limit),
    );
  }

  /// Get this week's transactions
  Future<TransactionSearchResult> getThisWeeksTransactions({
    required String walletId,
    int limit = 50,
  }) async {
    return searchTransactions(
      walletId: walletId,
      filter: TransactionSearchFilter.thisWeek().copyWith(limit: limit),
    );
  }

  /// Get this month's transactions
  Future<TransactionSearchResult> getThisMonthsTransactions({
    required String walletId,
    int limit = 100,
  }) async {
    return searchTransactions(
      walletId: walletId,
      filter: TransactionSearchFilter.thisMonth().copyWith(limit: limit),
    );
  }

  /// Validate search filter
  String? validateSearchFilter(TransactionSearchFilter filter) {
    // Check amount range
    if (filter.amountMin != null && filter.amountMax != null) {
      if (filter.amountMin! > filter.amountMax!) {
        return 'Minimum amount cannot be greater than maximum amount';
      }
    }

    // Check date range
    if (filter.startDate != null && filter.endDate != null) {
      if (filter.startDate!.isAfter(filter.endDate!)) {
        return 'Start date cannot be after end date';
      }
    }

    // Check search query length
    if (filter.searchQuery != null && filter.searchQuery!.length > 100) {
      return 'Search query is too long (maximum 100 characters)';
    }

    // Check pagination
    if (filter.limit <= 0 || filter.limit > 100) {
      return 'Limit must be between 1 and 100';
    }

    if (filter.offset < 0) {
      return 'Offset cannot be negative';
    }

    return null; // Valid
  }

  /// Get user-friendly error message
  String getErrorMessage(String error) {
    if (error.contains('Wallet not found')) {
      return 'Wallet not found. Please try again.';
    } else if (error.contains('access denied')) {
      return 'You do not have permission to access this wallet.';
    } else if (error.contains('Search failed')) {
      return 'Search failed. Please try again with different criteria.';
    } else if (error.contains('Export failed')) {
      return 'Export failed. Please try again later.';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    } else if (error.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Format search result summary
  String formatSearchResultSummary(TransactionSearchResult result) {
    final total = result.totalCount;
    final current = result.currentPageCount;
    final hasFilters = result.filtersApplied.hasFilters;

    if (total == 0) {
      return hasFilters ? 'No transactions found matching your criteria' : 'No transactions found';
    }

    if (total == current) {
      return hasFilters 
          ? 'Found $total transactions matching your criteria'
          : 'Showing all $total transactions';
    }

    return hasFilters
        ? 'Showing $current of $total transactions matching your criteria'
        : 'Showing $current of $total transactions';
  }

  /// Get quick filter suggestions
  List<TransactionSearchFilter> getQuickFilterSuggestions() {
    return [
      TransactionSearchFilter.today(),
      TransactionSearchFilter.thisWeek(),
      TransactionSearchFilter.thisMonth(),
      TransactionSearchFilter.last30Days(),
      TransactionSearchFilter.byType(WalletTransactionType.credit),
      TransactionSearchFilter.byType(WalletTransactionType.debit),
    ];
  }
}
