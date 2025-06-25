import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/wallet_transaction.dart';
import '../../data/providers/marketplace_wallet_providers.dart';
import '../../data/repositories/marketplace_wallet_repository.dart';
import '../../data/services/wallet_cache_service.dart';
import 'wallet_state_provider.dart';

/// Transaction history state for managing transaction data
class TransactionHistoryState {
  final List<WalletTransaction> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final bool hasMore;
  final int currentPage;
  final WalletTransactionType? filterType;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? lastUpdated;

  const TransactionHistoryState({
    this.transactions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.hasMore = true,
    this.currentPage = 0,
    this.filterType,
    this.startDate,
    this.endDate,
    this.lastUpdated,
  });

  TransactionHistoryState copyWith({
    List<WalletTransaction>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool? hasMore,
    int? currentPage,
    WalletTransactionType? filterType,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastUpdated,
  }) {
    return TransactionHistoryState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      filterType: filterType ?? this.filterType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get isEmpty => transactions.isEmpty && !isLoading;
  bool get hasTransactions => transactions.isNotEmpty;
  bool get canLoadMore => hasMore && !isLoading && !isLoadingMore;
}

/// Transaction history notifier for managing transaction operations
class TransactionHistoryNotifier extends StateNotifier<TransactionHistoryState> {
  final MarketplaceWalletRepository _repository;
  final WalletCacheService _cacheService;
  final Ref _ref;
  final String _walletId;

  static const int _pageSize = 20;

  TransactionHistoryNotifier(
    this._repository,
    this._cacheService,
    this._ref,
    this._walletId,
  ) : super(const TransactionHistoryState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    debugPrint('🔍 [TRANSACTIONS] Initializing transaction history for wallet: $_walletId');
    await loadTransactions();
  }

  /// Load transactions with cache-first strategy
  Future<void> loadTransactions({bool forceRefresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      List<WalletTransaction>? transactions;

      // Try cache first unless force refresh
      if (!forceRefresh && state.currentPage == 0) {
        transactions = await _cacheService.getCachedTransactions(_walletId);
        if (transactions != null) {
          debugPrint('🔍 [TRANSACTIONS] Loaded ${transactions.length} transactions from cache');
          state = state.copyWith(
            transactions: transactions,
            isLoading: false,
            hasMore: transactions.length >= _pageSize,
            lastUpdated: DateTime.now(),
          );
          return;
        }
      }

      // Load from repository
      final result = await _repository.getWalletTransactions(
        walletId: _walletId,
        limit: _pageSize,
        offset: state.currentPage * _pageSize,
        type: state.filterType,
        startDate: state.startDate,
        endDate: state.endDate,
      );

      result.fold(
        (failure) {
          debugPrint('🔍 [TRANSACTIONS] Failed to load transactions: ${failure.message}');
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
        },
        (loadedTransactions) {
          debugPrint('🔍 [TRANSACTIONS] Loaded ${loadedTransactions.length} transactions from repository');
          
          // Cache transactions if this is the first page
          if (state.currentPage == 0) {
            _cacheService.cacheTransactions(_walletId, loadedTransactions);
          }

          final allTransactions = state.currentPage == 0
              ? loadedTransactions
              : [...state.transactions, ...loadedTransactions];

          state = state.copyWith(
            transactions: allTransactions,
            isLoading: false,
            hasMore: loadedTransactions.length >= _pageSize,
            lastUpdated: DateTime.now(),
          );
        },
      );
    } catch (e) {
      debugPrint('🔍 [TRANSACTIONS] Error loading transactions: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load more transactions (pagination)
  Future<void> loadMoreTransactions() async {
    if (!state.canLoadMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    try {
      final result = await _repository.getWalletTransactions(
        walletId: _walletId,
        limit: _pageSize,
        offset: (state.currentPage + 1) * _pageSize,
        type: state.filterType,
        startDate: state.startDate,
        endDate: state.endDate,
      );

      result.fold(
        (failure) {
          debugPrint('🔍 [TRANSACTIONS] Failed to load more transactions: ${failure.message}');
          state = state.copyWith(
            isLoadingMore: false,
            errorMessage: failure.message,
          );
        },
        (loadedTransactions) {
          debugPrint('🔍 [TRANSACTIONS] Loaded ${loadedTransactions.length} more transactions');
          
          state = state.copyWith(
            transactions: [...state.transactions, ...loadedTransactions],
            isLoadingMore: false,
            currentPage: state.currentPage + 1,
            hasMore: loadedTransactions.length >= _pageSize,
            lastUpdated: DateTime.now(),
          );
        },
      );
    } catch (e) {
      debugPrint('🔍 [TRANSACTIONS] Error loading more transactions: $e');
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Refresh transactions
  Future<void> refresh() async {
    debugPrint('🔍 [TRANSACTIONS] Refreshing transaction history');
    state = state.copyWith(currentPage: 0);
    await loadTransactions(forceRefresh: true);
  }

  /// Apply filters
  Future<void> applyFilters({
    WalletTransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    debugPrint('🔍 [TRANSACTIONS] Applying filters: type=$type, start=$startDate, end=$endDate');
    
    state = state.copyWith(
      filterType: type,
      startDate: startDate,
      endDate: endDate,
      currentPage: 0,
      transactions: [],
    );
    
    await loadTransactions(forceRefresh: true);
  }

  /// Clear filters
  Future<void> clearFilters() async {
    debugPrint('🔍 [TRANSACTIONS] Clearing filters');
    
    state = state.copyWith(
      filterType: null,
      startDate: null,
      endDate: null,
      currentPage: 0,
      transactions: [],
    );
    
    await loadTransactions(forceRefresh: true);
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _cacheService.clearTransactionsCache(_walletId);
    debugPrint('🔍 [TRANSACTIONS] Transaction cache cleared');
  }

  /// Handle real-time transaction updates
  void handleRealtimeUpdate(WalletTransaction newTransaction) {
    debugPrint('🔍 [TRANSACTIONS] Real-time transaction update: ${newTransaction.formattedAmount}');
    
    // Add new transaction to the beginning of the list
    final updatedTransactions = [newTransaction, ...state.transactions];
    
    // Update cache
    _cacheService.cacheTransactions(_walletId, updatedTransactions.take(20).toList());
    
    state = state.copyWith(
      transactions: updatedTransactions,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  void dispose() {
    debugPrint('🔍 [TRANSACTIONS] Disposing transaction history notifier');
    super.dispose();
  }
}

/// Transaction history provider factory for different wallets
final transactionHistoryProvider = StateNotifierProvider.family<TransactionHistoryNotifier, TransactionHistoryState, String>((ref, walletId) {
  final repository = ref.watch(walletRepositoryProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  
  return TransactionHistoryNotifier(repository, cacheService, ref, walletId);
});

/// Current user transaction history provider
final currentUserTransactionHistoryProvider = StateNotifierProvider<TransactionHistoryNotifier, TransactionHistoryState>((ref) {
  final walletState = ref.watch(currentUserWalletProvider);
  final walletId = walletState.wallet?.id ?? '';
  
  if (walletId.isEmpty) {
    throw Exception('No wallet found for current user');
  }
  
  final repository = ref.watch(walletRepositoryProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  
  return TransactionHistoryNotifier(repository, cacheService, ref, walletId);
});

/// Transaction stream provider for real-time updates
final transactionStreamProvider = StreamProvider.family<List<WalletTransaction>, String>((ref, walletId) {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getWalletTransactionsStream(walletId: walletId, limit: 20);
});

/// Current user transaction stream provider
final currentUserTransactionStreamProvider = StreamProvider<List<WalletTransaction>>((ref) {
  final walletState = ref.watch(currentUserWalletProvider);
  final walletId = walletState.wallet?.id ?? '';
  
  if (walletId.isEmpty) {
    return Stream.value([]);
  }
  
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getWalletTransactionsStream(walletId: walletId, limit: 20);
});

/// Transaction summary provider
final transactionSummaryProvider = Provider.family<TransactionSummary, String>((ref, walletId) {
  final transactionState = ref.watch(transactionHistoryProvider(walletId));
  
  double totalCredits = 0;
  double totalDebits = 0;
  int creditCount = 0;
  int debitCount = 0;
  
  for (final transaction in transactionState.transactions) {
    if (transaction.isCredit) {
      totalCredits += transaction.amount;
      creditCount++;
    } else {
      totalDebits += transaction.amount.abs();
      debitCount++;
    }
  }
  
  return TransactionSummary(
    totalCredits: totalCredits,
    totalDebits: totalDebits,
    creditCount: creditCount,
    debitCount: debitCount,
    totalTransactions: transactionState.transactions.length,
  );
});

/// Transaction actions provider for UI operations
final transactionActionsProvider = Provider<TransactionActions>((ref) {
  return TransactionActions(ref);
});

/// Transaction actions class for centralized transaction operations
class TransactionActions {
  final Ref _ref;

  TransactionActions(this._ref);

  /// Refresh transactions for wallet
  Future<void> refreshTransactions(String walletId) async {
    final notifier = _ref.read(transactionHistoryProvider(walletId).notifier);
    await notifier.refresh();
  }

  /// Load more transactions
  Future<void> loadMoreTransactions(String walletId) async {
    final notifier = _ref.read(transactionHistoryProvider(walletId).notifier);
    await notifier.loadMoreTransactions();
  }

  /// Apply transaction filters
  Future<void> applyFilters(
    String walletId, {
    WalletTransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final notifier = _ref.read(transactionHistoryProvider(walletId).notifier);
    await notifier.applyFilters(
      type: type,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Clear transaction filters
  Future<void> clearFilters(String walletId) async {
    final notifier = _ref.read(transactionHistoryProvider(walletId).notifier);
    await notifier.clearFilters();
  }

  /// Get transaction state
  TransactionHistoryState getTransactionState(String walletId) {
    return _ref.read(transactionHistoryProvider(walletId));
  }
}

/// Transaction summary data class
class TransactionSummary {
  final double totalCredits;
  final double totalDebits;
  final int creditCount;
  final int debitCount;
  final int totalTransactions;

  const TransactionSummary({
    required this.totalCredits,
    required this.totalDebits,
    required this.creditCount,
    required this.debitCount,
    required this.totalTransactions,
  });

  double get netAmount => totalCredits - totalDebits;
  String get formattedTotalCredits => 'MYR ${totalCredits.toStringAsFixed(2)}';
  String get formattedTotalDebits => 'MYR ${totalDebits.toStringAsFixed(2)}';
  String get formattedNetAmount => 'MYR ${netAmount.toStringAsFixed(2)}';
}
