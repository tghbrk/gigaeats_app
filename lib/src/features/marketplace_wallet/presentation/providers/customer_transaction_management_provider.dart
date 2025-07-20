import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/customer_wallet.dart';
import '../../data/services/enhanced_transaction_service.dart';
import '../../../core/utils/logger.dart';

/// Transaction filter options for customer transactions
class CustomerTransactionFilter {
  final CustomerTransactionType? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String? searchQuery;
  final String sortBy;
  final bool ascending;

  const CustomerTransactionFilter({
    this.type,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.searchQuery,
    this.sortBy = 'created_at',
    this.ascending = false,
  });

  CustomerTransactionFilter copyWith({
    CustomerTransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String? searchQuery,
    String? sortBy,
    bool? ascending,
  }) {
    return CustomerTransactionFilter(
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }

  bool get hasActiveFilters {
    return type != null ||
           startDate != null ||
           endDate != null ||
           minAmount != null ||
           maxAmount != null ||
           (searchQuery != null && searchQuery!.isNotEmpty);
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type?.value,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'min_amount': minAmount,
      'max_amount': maxAmount,
      'search_query': searchQuery,
      'sort_by': sortBy,
      'ascending': ascending,
    };
  }
}

/// Customer transaction management state
class CustomerTransactionManagementState {
  final List<CustomerWalletTransaction> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final CustomerTransactionFilter filter;
  final int currentPage;
  final DateTime lastUpdated;

  const CustomerTransactionManagementState({
    this.transactions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.filter = const CustomerTransactionFilter(),
    this.currentPage = 0,
    required this.lastUpdated,
  });

  CustomerTransactionManagementState copyWith({
    List<CustomerWalletTransaction>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    CustomerTransactionFilter? filter,
    int? currentPage,
    DateTime? lastUpdated,
  }) {
    return CustomerTransactionManagementState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      filter: filter ?? this.filter,
      currentPage: currentPage ?? this.currentPage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get hasError => errorMessage != null;
  bool get isEmpty => transactions.isEmpty && !isLoading;
  int get totalTransactions => transactions.length;

  // Group transactions by date
  Map<DateTime, List<CustomerWalletTransaction>> get transactionsByDate {
    final Map<DateTime, List<CustomerWalletTransaction>> grouped = {};
    for (final transaction in transactions) {
      final date = DateTime(
        transaction.createdAt.year,
        transaction.createdAt.month,
        transaction.createdAt.day,
      );
      grouped.putIfAbsent(date, () => []).add(transaction);
    }
    return grouped;
  }

  // Get transactions by type
  Map<CustomerTransactionType, List<CustomerWalletTransaction>> get transactionsByType {
    final Map<CustomerTransactionType, List<CustomerWalletTransaction>> grouped = {};
    for (final transaction in transactions) {
      grouped.putIfAbsent(transaction.type, () => []).add(transaction);
    }
    return grouped;
  }

  // Calculate total amounts by type
  Map<CustomerTransactionType, double> get totalAmountsByType {
    final Map<CustomerTransactionType, double> totals = {};
    for (final transaction in transactions) {
      totals[transaction.type] = (totals[transaction.type] ?? 0.0) + transaction.amount.abs();
    }
    return totals;
  }
}

/// Customer transaction management notifier
class CustomerTransactionManagementNotifier extends StateNotifier<CustomerTransactionManagementState> {
  final EnhancedTransactionService _transactionService;
  final AppLogger _logger = AppLogger();

  static const int _pageSize = 50; // Increased to include older credit transactions

  CustomerTransactionManagementNotifier(this._transactionService)
      : super(CustomerTransactionManagementState(lastUpdated: DateTime.now()));

  /// Load transactions with current filter
  Future<void> loadTransactions({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        currentPage: 0,
        transactions: [],
        hasMore: true,
      );
    } else if (state.isLoading || state.isLoadingMore) {
      return; // Prevent concurrent loads
    } else {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      _logger.info('📊 [TRANSACTION-MGMT] Loading transactions with filter: ${state.filter.toJson()}');

      final result = await _transactionService.getCustomerTransactions(
        limit: _pageSize,
        offset: refresh ? 0 : state.currentPage * _pageSize,
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
          _logger.error('❌ [TRANSACTION-MGMT] Failed to load transactions: ${failure.message}');

          // Check if this is a timeout error due to connectivity/session issues
          if (failure.message.contains('Query timeout') || failure.message.contains('TimeoutException')) {
            _logger.info('🔧 [TRANSACTION-MGMT] Detected timeout error in failure, providing empty transaction list for development');

            // Provide empty transaction list as fallback
            state = state.copyWith(
              transactions: [], // Empty list for development mode
              isLoading: false,
              isLoadingMore: false,
              hasMore: false,
              currentPage: 1,
              lastUpdated: DateTime.now(),
              errorMessage: 'Offline mode - no transaction history available',
            );
            return;
          }

          state = state.copyWith(
            isLoading: false,
            isLoadingMore: false,
            errorMessage: failure.message,
          );
        },
        (newTransactions) {
          _logger.info('✅ [TRANSACTION-MGMT] Loaded ${newTransactions.length} transactions');

          // Debug: Count transaction types
          final topUpCount = newTransactions.where((t) => t.type == CustomerTransactionType.topUp).length;
          final orderPaymentCount = newTransactions.where((t) => t.type == CustomerTransactionType.orderPayment).length;
          final transferCount = newTransactions.where((t) => t.type == CustomerTransactionType.transfer).length;
          final refundCount = newTransactions.where((t) => t.type == CustomerTransactionType.refund).length;
          final adjustmentCount = newTransactions.where((t) => t.type == CustomerTransactionType.adjustment).length;

          _logger.info('📊 [TRANSACTION-MGMT] Transaction breakdown:');
          _logger.info('   - Top-ups: $topUpCount');
          _logger.info('   - Order payments: $orderPaymentCount');
          _logger.info('   - Transfers: $transferCount');
          _logger.info('   - Refunds: $refundCount');
          _logger.info('   - Adjustments: $adjustmentCount');

          final allTransactions = refresh
              ? newTransactions
              : [...state.transactions, ...newTransactions];

          state = state.copyWith(
            transactions: allTransactions,
            isLoading: false,
            isLoadingMore: false,
            hasMore: newTransactions.length == _pageSize,
            currentPage: refresh ? 1 : state.currentPage + 1,
            lastUpdated: DateTime.now(),
          );
        },
      );
    } catch (e) {
      _logger.error('❌ [TRANSACTION-MGMT] Error loading transactions: $e');

      // Check if this is a timeout error due to connectivity/session issues
      if (e.toString().contains('Query timeout') || e.toString().contains('TimeoutException')) {
        _logger.info('🔧 [TRANSACTION-MGMT] Detected timeout error, providing empty transaction list for development');

        // Provide empty transaction list as fallback
        state = state.copyWith(
          transactions: [], // Empty list for development mode
          isLoading: false,
          isLoadingMore: false,
          hasMore: false,
          currentPage: 1,
          lastUpdated: DateTime.now(),
          errorMessage: 'Offline mode - no transaction history available',
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load more transactions (pagination)
  Future<void> loadMoreTransactions() async {
    if (!state.hasMore || state.isLoading || state.isLoadingMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    await loadTransactions();
  }

  /// Apply filter and reload transactions
  Future<void> applyFilter(CustomerTransactionFilter filter) async {
    _logger.info('🔍 [TRANSACTION-MGMT] Applying filter: ${filter.toJson()}');
    
    state = state.copyWith(filter: filter);
    await loadTransactions(refresh: true);
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    _logger.info('🧹 [TRANSACTION-MGMT] Clearing all filters');
    
    const defaultFilter = CustomerTransactionFilter();
    state = state.copyWith(filter: defaultFilter);
    await loadTransactions(refresh: true);
  }

  /// Search transactions
  Future<void> searchTransactions(String query) async {
    _logger.info('🔍 [TRANSACTION-MGMT] Searching transactions: $query');
    
    final newFilter = state.filter.copyWith(searchQuery: query);
    await applyFilter(newFilter);
  }

  /// Filter by transaction type
  Future<void> filterByType(CustomerTransactionType? type) async {
    _logger.info('🏷️ [TRANSACTION-MGMT] Filtering by type: ${type?.displayName ?? 'All'}');
    
    final newFilter = state.filter.copyWith(type: type);
    await applyFilter(newFilter);
  }

  /// Filter by date range
  Future<void> filterByDateRange(DateTime? startDate, DateTime? endDate) async {
    _logger.info('📅 [TRANSACTION-MGMT] Filtering by date range: $startDate to $endDate');
    
    final newFilter = state.filter.copyWith(
      startDate: startDate,
      endDate: endDate,
    );
    await applyFilter(newFilter);
  }

  /// Filter by amount range
  Future<void> filterByAmountRange(double? minAmount, double? maxAmount) async {
    _logger.info('💰 [TRANSACTION-MGMT] Filtering by amount range: $minAmount to $maxAmount');
    
    final newFilter = state.filter.copyWith(
      minAmount: minAmount,
      maxAmount: maxAmount,
    );
    await applyFilter(newFilter);
  }

  /// Export transactions to CSV
  Future<String?> exportTransactions() async {
    try {
      _logger.info('📤 [TRANSACTION-MGMT] Exporting transactions to CSV');

      final result = await _transactionService.exportTransactionsToCSV(
        startDate: state.filter.startDate,
        endDate: state.filter.endDate,
        type: state.filter.type,
      );

      return result.fold(
        (failure) {
          _logger.error('❌ [TRANSACTION-MGMT] Export failed: ${failure.message}');
          state = state.copyWith(errorMessage: 'Export failed: ${failure.message}');
          return null;
        },
        (csvData) {
          _logger.info('✅ [TRANSACTION-MGMT] Export successful');
          return csvData;
        },
      );
    } catch (e) {
      _logger.error('❌ [TRANSACTION-MGMT] Export error: $e');
      state = state.copyWith(errorMessage: 'Export error: $e');
      return null;
    }
  }

  /// Refresh transactions
  Future<void> refresh() async {
    await loadTransactions(refresh: true);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Customer transaction management provider
final customerTransactionManagementProvider = StateNotifierProvider<CustomerTransactionManagementNotifier, CustomerTransactionManagementState>((ref) {
  final transactionService = ref.watch(enhancedTransactionServiceProvider);
  return CustomerTransactionManagementNotifier(transactionService);
});

/// Provider for transaction statistics
final customerTransactionStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final state = ref.watch(customerTransactionManagementProvider);
  
  if (state.transactions.isEmpty) {
    return {
      'total_transactions': 0,
      'total_spent': 0.0,
      'total_received': 0.0,
      'average_transaction': 0.0,
      'by_type': <String, int>{},
    };
  }

  double totalSpent = 0.0;
  double totalReceived = 0.0;
  final Map<String, int> byType = {};

  for (final transaction in state.transactions) {
    if (transaction.isDebit) {
      totalSpent += transaction.amount.abs();
    } else {
      totalReceived += transaction.amount.abs();
    }

    final typeName = transaction.type.displayName;
    byType[typeName] = (byType[typeName] ?? 0) + 1;
  }

  return {
    'total_transactions': state.transactions.length,
    'total_spent': totalSpent,
    'total_received': totalReceived,
    'average_transaction': state.transactions.isNotEmpty 
        ? (totalSpent + totalReceived) / state.transactions.length 
        : 0.0,
    'by_type': byType,
  };
});

/// Enhanced transaction service provider
final enhancedTransactionServiceProvider = Provider<EnhancedTransactionService>((ref) {
  return EnhancedTransactionService();
});
