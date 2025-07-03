import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/customer_wallet.dart';
import '../../data/services/enhanced_transaction_service.dart';

/// Provider for enhanced transaction service
final enhancedTransactionServiceProvider = Provider<EnhancedTransactionService>((ref) {
  return EnhancedTransactionService();
});

/// Transaction filter model
class TransactionFilter {
  final CustomerTransactionType? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  final double? minAmount;
  final double? maxAmount;
  final String sortBy;
  final bool ascending;

  const TransactionFilter({
    this.type,
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.minAmount,
    this.maxAmount,
    this.sortBy = 'created_at',
    this.ascending = false,
  });

  TransactionFilter copyWith({
    CustomerTransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    double? minAmount,
    double? maxAmount,
    String? sortBy,
    bool? ascending,
  }) {
    return TransactionFilter(
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }

  bool get hasFilters => 
      type != null || 
      startDate != null || 
      endDate != null || 
      (searchQuery?.isNotEmpty ?? false) ||
      minAmount != null ||
      maxAmount != null;

  TransactionFilter clearFilters() {
    return const TransactionFilter();
  }
}

/// Enhanced transaction state
class EnhancedTransactionState {
  final List<CustomerWalletTransaction> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Failure? failure;
  final TransactionFilter filter;
  final int currentPage;
  final TransactionStatistics? statistics;
  final bool isExporting;

  const EnhancedTransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.failure,
    this.filter = const TransactionFilter(),
    this.currentPage = 0,
    this.statistics,
    this.isExporting = false,
  });

  EnhancedTransactionState copyWith({
    List<CustomerWalletTransaction>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Failure? failure,
    TransactionFilter? filter,
    int? currentPage,
    TransactionStatistics? statistics,
    bool? isExporting,
  }) {
    return EnhancedTransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      failure: failure,
      filter: filter ?? this.filter,
      currentPage: currentPage ?? this.currentPage,
      statistics: statistics ?? this.statistics,
      isExporting: isExporting ?? this.isExporting,
    );
  }

  EnhancedTransactionState clearError() {
    return copyWith(failure: null);
  }

  bool get hasError => failure != null;
  String get errorMessage => failure?.message ?? '';
  bool get isEmpty => transactions.isEmpty && !isLoading;
  bool get hasTransactions => transactions.isNotEmpty;
}

/// Enhanced transaction notifier
class EnhancedTransactionNotifier extends StateNotifier<EnhancedTransactionState> {
  final EnhancedTransactionService _service;
  static const int _pageSize = 20;

  EnhancedTransactionNotifier(this._service) : super(const EnhancedTransactionState());

  /// Load transactions with current filter
  Future<void> loadTransactions({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    final isFirstLoad = refresh || state.transactions.isEmpty;
    final offset = isFirstLoad ? 0 : state.transactions.length;

    state = state.copyWith(
      isLoading: isFirstLoad,
      isLoadingMore: !isFirstLoad,
      failure: null,
    );

    try {
      debugPrint('🔍 [ENHANCED-TRANSACTION-PROVIDER] Loading transactions, offset: $offset');

      final result = await _service.getCustomerTransactions(
        limit: _pageSize,
        offset: offset,
        type: state.filter.type,
        startDate: state.filter.startDate,
        endDate: state.filter.endDate,
        searchQuery: state.filter.searchQuery,
        minAmount: state.filter.minAmount,
        maxAmount: state.filter.maxAmount,
        sortBy: state.filter.sortBy,
        ascending: state.filter.ascending,
      );

      result.fold(
        (failure) {
          debugPrint('❌ [ENHANCED-TRANSACTION-PROVIDER] Failed to load: ${failure.message}');
          state = state.copyWith(
            isLoading: false,
            isLoadingMore: false,
            failure: failure,
          );
        },
        (newTransactions) {
          debugPrint('✅ [ENHANCED-TRANSACTION-PROVIDER] Loaded ${newTransactions.length} transactions');
          
          final updatedTransactions = isFirstLoad 
              ? newTransactions 
              : [...state.transactions, ...newTransactions];

          state = state.copyWith(
            transactions: updatedTransactions,
            isLoading: false,
            isLoadingMore: false,
            hasMore: newTransactions.length == _pageSize,
            currentPage: isFirstLoad ? 1 : state.currentPage + 1,
          );
        },
      );
    } catch (e) {
      debugPrint('❌ [ENHANCED-TRANSACTION-PROVIDER] Exception: $e');
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        failure: UnexpectedFailure(message: e.toString()),
      );
    }
  }

  /// Load more transactions (pagination)
  Future<void> loadMoreTransactions() async {
    if (!state.hasMore || state.isLoadingMore) return;
    await loadTransactions();
  }

  /// Refresh transactions
  Future<void> refreshTransactions() async {
    await loadTransactions(refresh: true);
  }

  /// Apply filter and reload
  Future<void> applyFilter(TransactionFilter filter) async {
    state = state.copyWith(filter: filter, currentPage: 0);
    await loadTransactions(refresh: true);
  }

  /// Clear filter and reload
  Future<void> clearFilter() async {
    state = state.copyWith(filter: const TransactionFilter(), currentPage: 0);
    await loadTransactions(refresh: true);
  }

  /// Search transactions
  Future<void> searchTransactions(String query) async {
    if (query.isEmpty) {
      await clearFilter();
      return;
    }

    final filter = state.filter.copyWith(searchQuery: query);
    await applyFilter(filter);
  }

  /// Filter by type
  Future<void> filterByType(CustomerTransactionType? type) async {
    final filter = state.filter.copyWith(type: type);
    await applyFilter(filter);
  }

  /// Filter by date range
  Future<void> filterByDateRange(DateTime? startDate, DateTime? endDate) async {
    final filter = state.filter.copyWith(startDate: startDate, endDate: endDate);
    await applyFilter(filter);
  }

  /// Filter by amount range
  Future<void> filterByAmountRange(double? minAmount, double? maxAmount) async {
    final filter = state.filter.copyWith(minAmount: minAmount, maxAmount: maxAmount);
    await applyFilter(filter);
  }

  /// Change sort order
  Future<void> changeSortOrder(String sortBy, bool ascending) async {
    final filter = state.filter.copyWith(sortBy: sortBy, ascending: ascending);
    await applyFilter(filter);
  }

  /// Load transaction statistics
  Future<void> loadStatistics({DateTime? startDate, DateTime? endDate}) async {
    try {
      debugPrint('🔍 [ENHANCED-TRANSACTION-PROVIDER] Loading statistics');

      final result = await _service.getTransactionStatistics(
        startDate: startDate ?? state.filter.startDate,
        endDate: endDate ?? state.filter.endDate,
      );

      result.fold(
        (failure) {
          debugPrint('❌ [ENHANCED-TRANSACTION-PROVIDER] Failed to load statistics: ${failure.message}');
          state = state.copyWith(failure: failure);
        },
        (statistics) {
          debugPrint('✅ [ENHANCED-TRANSACTION-PROVIDER] Statistics loaded');
          state = state.copyWith(statistics: statistics);
        },
      );
    } catch (e) {
      debugPrint('❌ [ENHANCED-TRANSACTION-PROVIDER] Statistics exception: $e');
      state = state.copyWith(failure: UnexpectedFailure(message: e.toString()));
    }
  }

  /// Export transactions to CSV
  Future<String?> exportTransactionsToCSV() async {
    state = state.copyWith(isExporting: true, failure: null);

    try {
      debugPrint('🔍 [ENHANCED-TRANSACTION-PROVIDER] Exporting transactions');

      final result = await _service.exportTransactionsToCSV(
        startDate: state.filter.startDate,
        endDate: state.filter.endDate,
        type: state.filter.type,
      );

      state = state.copyWith(isExporting: false);

      return result.fold(
        (failure) {
          debugPrint('❌ [ENHANCED-TRANSACTION-PROVIDER] Export failed: ${failure.message}');
          state = state.copyWith(failure: failure);
          return null;
        },
        (csvData) {
          debugPrint('✅ [ENHANCED-TRANSACTION-PROVIDER] Export successful');
          return csvData;
        },
      );
    } catch (e) {
      debugPrint('❌ [ENHANCED-TRANSACTION-PROVIDER] Export exception: $e');
      state = state.copyWith(
        isExporting: false,
        failure: UnexpectedFailure(message: e.toString()),
      );
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.clearError();
  }
}

/// Enhanced transaction provider
final enhancedTransactionProvider = StateNotifierProvider<EnhancedTransactionNotifier, EnhancedTransactionState>((ref) {
  final service = ref.watch(enhancedTransactionServiceProvider);
  return EnhancedTransactionNotifier(service);
});

/// Enhanced transaction stream provider for real-time updates
final enhancedTransactionStreamProvider = StreamProvider<List<CustomerWalletTransaction>>((ref) {
  final service = ref.watch(enhancedTransactionServiceProvider);
  return service.getCustomerTransactionsStream(limit: 10).map((either) {
    return either.fold(
      (failure) {
        debugPrint('❌ [ENHANCED-TRANSACTION-STREAM] Stream error: ${failure.message}');
        return <CustomerWalletTransaction>[];
      },
      (transactions) => transactions,
    );
  });
});

/// Quick access providers
final enhancedTransactionLoadingProvider = Provider<bool>((ref) {
  final transactionState = ref.watch(enhancedTransactionProvider);
  return transactionState.isLoading;
});

final enhancedTransactionErrorProvider = Provider<Failure?>((ref) {
  final transactionState = ref.watch(enhancedTransactionProvider);
  return transactionState.failure;
});

final enhancedTransactionStatisticsProvider = Provider<TransactionStatistics?>((ref) {
  final transactionState = ref.watch(enhancedTransactionProvider);
  return transactionState.statistics;
});
