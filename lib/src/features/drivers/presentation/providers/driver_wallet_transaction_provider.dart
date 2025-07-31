import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../data/models/user_role.dart';
import '../../data/models/driver_wallet_transaction.dart';
import '../../data/repositories/driver_wallet_repository.dart';
import 'driver_wallet_provider.dart';

/// Driver wallet transaction filter class
class DriverWalletTransactionFilter {
  final DriverWalletTransactionType? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  final double? minAmount;
  final double? maxAmount;
  final String sortBy;
  final bool ascending;

  const DriverWalletTransactionFilter({
    this.type,
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.minAmount,
    this.maxAmount,
    this.sortBy = 'created_at',
    this.ascending = false,
  });

  DriverWalletTransactionFilter copyWith({
    DriverWalletTransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    double? minAmount,
    double? maxAmount,
    String? sortBy,
    bool? ascending,
  }) {
    return DriverWalletTransactionFilter(
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

  Map<String, dynamic> toJson() {
    return {
      'type': type?.value,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'searchQuery': searchQuery,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'sortBy': sortBy,
      'ascending': ascending,
    };
  }
}

/// Driver wallet transaction state class
class DriverWalletTransactionState {
  final List<DriverWalletTransaction> transactions;
  final bool isLoading;
  final String? errorMessage;
  final bool hasMore;
  final int currentPage;
  final DriverWalletTransactionFilter filter;
  final bool isRefreshing;

  const DriverWalletTransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hasMore = true,
    this.currentPage = 0,
    this.filter = const DriverWalletTransactionFilter(),
    this.isRefreshing = false,
  });

  DriverWalletTransactionState copyWith({
    List<DriverWalletTransaction>? transactions,
    bool? isLoading,
    String? errorMessage,
    bool? hasMore,
    int? currentPage,
    DriverWalletTransactionFilter? filter,
    bool? isRefreshing,
  }) {
    return DriverWalletTransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      filter: filter ?? this.filter,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  String toString() {
    return 'DriverWalletTransactionState(transactions: ${transactions.length}, isLoading: $isLoading, hasMore: $hasMore, page: $currentPage)';
  }
}

/// Driver wallet transaction notifier
class DriverWalletTransactionNotifier extends StateNotifier<DriverWalletTransactionState> {
  final DriverWalletRepository _repository;
  final Ref _ref;
  static const int _pageSize = 20;

  DriverWalletTransactionNotifier(this._repository, this._ref) : super(const DriverWalletTransactionState());

  /// Load transactions with optional filtering
  Future<void> loadTransactions({
    bool refresh = false,
    DriverWalletTransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    double? minAmount,
    double? maxAmount,
  }) async {
    if (state.isLoading && !refresh) return;

    final authState = _ref.read(authStateProvider);
    if (authState.user?.role != UserRole.driver) {
      debugPrint('❌ [DRIVER-WALLET-TRANSACTIONS] User is not a driver');
      return;
    }

    final isFirstLoad = refresh || state.transactions.isEmpty;
    final offset = isFirstLoad ? 0 : state.transactions.length;

    // Update filter if parameters provided
    final newFilter = state.filter.copyWith(
      type: type,
      startDate: startDate,
      endDate: endDate,
      searchQuery: searchQuery,
      minAmount: minAmount,
      maxAmount: maxAmount,
    );

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      currentPage: isFirstLoad ? 0 : state.currentPage,
      filter: newFilter,
      isRefreshing: refresh,
    );

    try {
      debugPrint('🔍 [DRIVER-WALLET-TRANSACTIONS] Loading transactions, offset: $offset');

      final result = await _repository.getDriverWalletTransactions(
        limit: _pageSize,
        offset: offset,
        type: newFilter.type,
        startDate: newFilter.startDate,
        endDate: newFilter.endDate,
        searchQuery: newFilter.searchQuery,
        minAmount: newFilter.minAmount,
        maxAmount: newFilter.maxAmount,
        sortBy: newFilter.sortBy,
        ascending: newFilter.ascending,
      );

      final newTransactions = isFirstLoad ? result : [...state.transactions, ...result];
      final hasMore = result.length == _pageSize;

      state = state.copyWith(
        transactions: newTransactions,
        isLoading: false,
        hasMore: hasMore,
        currentPage: isFirstLoad ? 1 : state.currentPage + 1,
        isRefreshing: false,
      );

      debugPrint('✅ [DRIVER-WALLET-TRANSACTIONS] Loaded ${result.length} transactions, total: ${newTransactions.length}');
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-TRANSACTIONS] Error loading transactions: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        isRefreshing: false,
      );
    }
  }

  /// Load more transactions (pagination)
  Future<void> loadMoreTransactions() async {
    if (!state.hasMore || state.isLoading) return;
    await loadTransactions();
  }

  /// Refresh transactions
  Future<void> refreshTransactions() async {
    await loadTransactions(refresh: true);
  }

  /// Apply filter
  Future<void> applyFilter(DriverWalletTransactionFilter filter) async {
    state = state.copyWith(filter: filter);
    await loadTransactions(
      refresh: true,
      type: filter.type,
      startDate: filter.startDate,
      endDate: filter.endDate,
      searchQuery: filter.searchQuery,
      minAmount: filter.minAmount,
      maxAmount: filter.maxAmount,
    );
  }

  /// Clear filter
  Future<void> clearFilter() async {
    await applyFilter(const DriverWalletTransactionFilter());
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    debugPrint('🔍 [DRIVER-WALLET-TRANSACTIONS] Disposing transaction notifier');
    super.dispose();
  }
}

/// Main driver wallet transaction provider
final driverWalletTransactionProvider = StateNotifierProvider<DriverWalletTransactionNotifier, DriverWalletTransactionState>((ref) {
  final repository = ref.watch(driverWalletRepositoryProvider);
  return DriverWalletTransactionNotifier(repository, ref);
});

/// Driver wallet transactions stream provider for real-time updates
final driverWalletTransactionsStreamProvider = StreamProvider<List<DriverWalletTransaction>>((ref) {
  final authState = ref.watch(authStateProvider);
  
  if (authState.user?.role != UserRole.driver) {
    return Stream.value(<DriverWalletTransaction>[]);
  }

  final repository = ref.watch(driverWalletRepositoryProvider);
  return repository.streamDriverWalletTransactions(limit: 10);
});

/// Driver wallet transaction loading provider
final driverWalletTransactionLoadingProvider = Provider<bool>((ref) {
  final transactionState = ref.watch(driverWalletTransactionProvider);
  return transactionState.isLoading;
});

/// Driver wallet transaction error provider
final driverWalletTransactionErrorProvider = Provider<String?>((ref) {
  final transactionState = ref.watch(driverWalletTransactionProvider);
  return transactionState.errorMessage;
});

/// Driver wallet transaction count provider
final driverWalletTransactionCountProvider = Provider<int>((ref) {
  final transactionState = ref.watch(driverWalletTransactionProvider);
  return transactionState.transactions.length;
});

/// Driver wallet transaction filter provider
final driverWalletTransactionFilterProvider = Provider<DriverWalletTransactionFilter>((ref) {
  final transactionState = ref.watch(driverWalletTransactionProvider);
  return transactionState.filter;
});
