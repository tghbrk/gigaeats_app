import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/customer_wallet.dart';
import '../../data/models/customer_wallet_error.dart';
import '../../data/repositories/customer_wallet_repository.dart';
import '../../data/services/enhanced_customer_wallet_service.dart';

/// Provider for customer wallet repository
final customerWalletRepositoryProvider = Provider<CustomerWalletRepository>((ref) {
  return CustomerWalletRepository();
});

/// Provider for enhanced customer wallet service (with auto-creation)
final enhancedCustomerWalletServiceProvider = Provider<EnhancedCustomerWalletService>((ref) {
  return EnhancedCustomerWalletService();
});

/// Customer wallet state
class CustomerWalletState {
  final CustomerWallet? wallet;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final CustomerWalletError? error;
  final DateTime? lastUpdated;
  final int retryCount;

  const CustomerWalletState({
    this.wallet,
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.error,
    this.lastUpdated,
    this.retryCount = 0,
  });

  CustomerWalletState copyWith({
    CustomerWallet? wallet,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    CustomerWalletError? error,
    DateTime? lastUpdated,
    int? retryCount,
  }) {
    return CustomerWalletState(
      wallet: wallet ?? this.wallet,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  /// Clear error state
  CustomerWalletState clearError() {
    return copyWith(
      errorMessage: null,
      error: null,
    );
  }

  /// Increment retry count
  CustomerWalletState incrementRetry() {
    return copyWith(retryCount: retryCount + 1);
  }

  /// Reset retry count
  CustomerWalletState resetRetry() {
    return copyWith(retryCount: 0);
  }

  bool get hasWallet => wallet != null;
  bool get hasError => errorMessage != null || error != null;
  bool get canRetry => error?.isRetryable ?? true;
  double get availableBalance => wallet?.availableBalance ?? 0.0;
  String get formattedBalance => wallet?.formattedAvailableBalance ?? 'RM 0.00';
  String get displayErrorMessage => error?.userFriendlyMessage ?? errorMessage ?? 'Unknown error occurred';
}

/// Customer wallet state notifier
class CustomerWalletNotifier extends StateNotifier<CustomerWalletState> {
  final CustomerWalletRepository _repository;
  final Ref _ref;

  CustomerWalletNotifier(this._repository, this._ref) : super(const CustomerWalletState());

  /// Load customer wallet data
  Future<void> loadWallet({bool forceRefresh = false}) async {
    if (state.isLoading && !forceRefresh) return;

    // Clear previous errors and set loading state
    state = state.copyWith(
      isLoading: true,
      isRefreshing: forceRefresh,
      errorMessage: null,
      error: null,
    );

    try {
      final authState = _ref.read(authStateProvider);
      if (authState.user == null) {
        final error = CustomerWalletError.authenticationError('User session expired');
        debugPrint('❌ [CUSTOMER-WALLET-PROVIDER] Authentication error: ${error.message}');
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: error,
          errorMessage: error.userFriendlyMessage,
        );
        return;
      }

      debugPrint('🔍 [CUSTOMER-WALLET-PROVIDER] Loading customer wallet (retry: ${state.retryCount})');

      // Try to get existing wallet first
      final existingWalletResult = await _repository.getCustomerWallet();

      final result = await existingWalletResult.fold(
        (failure) async {
          // If there's an error getting the wallet, return the failure
          return existingWalletResult;
        },
        (existingWallet) async {
          if (existingWallet != null) {
            // Wallet exists, return it
            debugPrint('✅ [CUSTOMER-WALLET-PROVIDER] Found existing wallet: ${existingWallet.formattedAvailableBalance}');
            return existingWalletResult;
          } else {
            // Wallet doesn't exist, create it using enhanced service
            debugPrint('🔧 [CUSTOMER-WALLET-PROVIDER] No wallet found, creating new wallet...');
            final enhancedService = _ref.read(enhancedCustomerWalletServiceProvider);
            return await enhancedService.getOrCreateCustomerWallet();
          }
        },
      );

      result.fold(
        (failure) {
          final error = CustomerWalletError.fromMessage(failure.message);
          debugPrint('❌ [CUSTOMER-WALLET-PROVIDER] Failed to load wallet: ${error.message}');

          // Check if this is a retryable error
          if (failure.message.contains('Query timeout') ||
              failure.message.contains('TimeoutException') ||
              failure.message.contains('Session') ||
              failure.message.contains('expired') ||
              failure.message.contains('unauthorized')) {
            debugPrint('🔄 [CUSTOMER-WALLET-PROVIDER] Detected retryable error: ${failure.message}');

            // Set error state with retry capability
            state = state.copyWith(
              isLoading: false,
              isRefreshing: false,
              error: CustomerWalletError.networkError(
                'Connection issue: ${failure.message}. Tap to retry.'
              ),
              errorMessage: 'Connection issue. Tap to retry.',
              retryCount: state.retryCount + 1,
            );
            return;
          }

          state = state.copyWith(
            isLoading: false,
            isRefreshing: false,
            error: error,
            errorMessage: error.userFriendlyMessage,
          ).incrementRetry();
        },
        (wallet) {
          debugPrint('✅ [CUSTOMER-WALLET-PROVIDER] Wallet loaded: ${wallet?.formattedAvailableBalance ?? 'null'}');
          state = state.copyWith(
            wallet: wallet,
            isLoading: false,
            isRefreshing: false,
            lastUpdated: DateTime.now(),
          ).resetRetry();
        },
      );
    } catch (e) {
      final error = CustomerWalletError.fromException(Exception(e.toString()));
      debugPrint('❌ [CUSTOMER-WALLET-PROVIDER] Exception loading wallet: ${error.message}');

      // Check if this is a retryable error
      if (e.toString().contains('Query timeout') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('Session') ||
          e.toString().contains('expired') ||
          e.toString().contains('unauthorized')) {
        debugPrint('🔄 [CUSTOMER-WALLET-PROVIDER] Detected retryable error: ${e.toString()}');

        // Set error state with retry capability
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: CustomerWalletError.networkError(
            'Connection issue: ${e.toString()}. Tap to retry.'
          ),
          errorMessage: 'Connection issue. Tap to retry.',
          retryCount: state.retryCount + 1,
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: error,
        errorMessage: error.userFriendlyMessage,
      ).incrementRetry();
    }
  }

  /// Refresh wallet data
  Future<void> refreshWallet() async {
    await loadWallet(forceRefresh: true);
  }

  /// Retry loading wallet with exponential backoff
  Future<void> retryLoadWallet() async {
    if (!state.canRetry) return;

    // Exponential backoff: wait longer for each retry
    final delaySeconds = [1, 2, 5, 10, 30][state.retryCount.clamp(0, 4)];
    debugPrint('🔄 [CUSTOMER-WALLET-PROVIDER] Retrying in ${delaySeconds}s (attempt ${state.retryCount + 1})');

    await Future.delayed(Duration(seconds: delaySeconds));
    await loadWallet(forceRefresh: true);
  }

  /// Check if customer has sufficient balance
  Future<bool> hasSufficientBalance(double amount) async {
    try {
      final result = await _repository.hasSufficientBalance(amount);
      return result.fold(
        (failure) {
          final error = CustomerWalletError.fromMessage(failure.message);
          debugPrint('❌ [CUSTOMER-WALLET-PROVIDER] Balance check failed: ${error.message}');
          return false;
        },
        (hasSufficient) {
          if (!hasSufficient && state.wallet != null) {
            final error = CustomerWalletError.insufficientBalance(amount, state.wallet!.availableBalance);
            state = state.copyWith(
              error: error,
              errorMessage: error.userFriendlyMessage,
            );
          }
          return hasSufficient;
        },
      );
    } catch (e) {
      final error = CustomerWalletError.fromException(Exception(e.toString()));
      debugPrint('❌ [CUSTOMER-WALLET-PROVIDER] Error checking balance: ${error.message}');
      state = state.copyWith(
        error: error,
        errorMessage: error.userFriendlyMessage,
      );
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.clearError();
  }

  /// Force reload wallet (bypass cache)
  Future<void> forceReload() async {
    state = state.copyWith(wallet: null).resetRetry();
    await loadWallet(forceRefresh: true);
  }

  /// Check wallet health (connectivity test)
  Future<bool> checkWalletHealth() async {
    try {
      debugPrint('🔍 [CUSTOMER-WALLET-PROVIDER] Checking wallet health');
      final result = await _repository.getCustomerWallet();
      return result.fold(
        (failure) => false,
        (wallet) => true,
      );
    } catch (e) {
      debugPrint('❌ [CUSTOMER-WALLET-PROVIDER] Health check failed: $e');
      return false;
    }
  }
}

/// Customer wallet provider
final customerWalletProvider = StateNotifierProvider<CustomerWalletNotifier, CustomerWalletState>((ref) {
  final repository = ref.watch(customerWalletRepositoryProvider);
  return CustomerWalletNotifier(repository, ref);
});

/// Customer wallet stream provider for real-time updates
final customerWalletStreamProvider = StreamProvider<CustomerWallet?>((ref) {
  final repository = ref.watch(customerWalletRepositoryProvider);
  return repository.getCustomerWalletStream();
});

/// Customer wallet balance provider (for quick access)
final customerWalletBalanceProvider = Provider<double>((ref) {
  final walletState = ref.watch(customerWalletProvider);
  return walletState.availableBalance;
});

/// Customer wallet transactions state
class CustomerWalletTransactionsState {
  final List<CustomerWalletTransaction> transactions;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;
  final int currentPage;

  const CustomerWalletTransactionsState({
    this.transactions = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
    this.currentPage = 0,
  });

  CustomerWalletTransactionsState copyWith({
    List<CustomerWalletTransaction>? transactions,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    int? currentPage,
  }) {
    return CustomerWalletTransactionsState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Customer wallet transactions notifier
class CustomerWalletTransactionsNotifier extends StateNotifier<CustomerWalletTransactionsState> {
  final CustomerWalletRepository _repository;
  static const int _pageSize = 50; // Increased to include older credit transactions

  CustomerWalletTransactionsNotifier(this._repository) : super(const CustomerWalletTransactionsState());

  /// Load transactions
  Future<void> loadTransactions({
    bool refresh = false,
    CustomerTransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (state.isLoading) return;

    final isFirstLoad = refresh || state.transactions.isEmpty;
    final offset = isFirstLoad ? 0 : state.transactions.length;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      currentPage: isFirstLoad ? 0 : state.currentPage,
    );

    try {
      debugPrint('🔍 [CUSTOMER-WALLET-TRANSACTIONS] Loading transactions, offset: $offset');

      final result = await _repository.getCustomerTransactions(
        limit: _pageSize,
        offset: offset,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );

      result.fold(
        (failure) {
          debugPrint('❌ [CUSTOMER-WALLET-TRANSACTIONS] Failed to load: ${failure.message}');
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
        },
        (newTransactions) {
          debugPrint('✅ [CUSTOMER-WALLET-TRANSACTIONS] Loaded ${newTransactions.length} transactions');

          // Debug: Count transaction types
          final topUpCount = newTransactions.where((t) => t.type == CustomerTransactionType.topUp).length;
          final orderPaymentCount = newTransactions.where((t) => t.type == CustomerTransactionType.orderPayment).length;
          final transferCount = newTransactions.where((t) => t.type == CustomerTransactionType.transfer).length;
          final refundCount = newTransactions.where((t) => t.type == CustomerTransactionType.refund).length;
          final adjustmentCount = newTransactions.where((t) => t.type == CustomerTransactionType.adjustment).length;

          debugPrint('📊 [CUSTOMER-WALLET-TRANSACTIONS] Transaction breakdown:');
          debugPrint('   - Top-ups: $topUpCount');
          debugPrint('   - Order payments: $orderPaymentCount');
          debugPrint('   - Transfers: $transferCount');
          debugPrint('   - Refunds: $refundCount');
          debugPrint('   - Adjustments: $adjustmentCount');

          final updatedTransactions = isFirstLoad
              ? newTransactions
              : [...state.transactions, ...newTransactions];

          state = state.copyWith(
            transactions: updatedTransactions,
            isLoading: false,
            hasMore: newTransactions.length == _pageSize,
            currentPage: state.currentPage + 1,
          );

          debugPrint('✅ [CUSTOMER-WALLET-TRANSACTIONS] Total transactions in state: ${updatedTransactions.length}');
        },
      );
    } catch (e) {
      debugPrint('❌ [CUSTOMER-WALLET-TRANSACTIONS] Exception: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
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

  /// Filter transactions by type
  Future<void> filterByType(CustomerTransactionType? type) async {
    await loadTransactions(refresh: true, type: type);
  }

  /// Filter transactions by date range
  Future<void> filterByDateRange(DateTime? startDate, DateTime? endDate) async {
    await loadTransactions(refresh: true, startDate: startDate, endDate: endDate);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Customer wallet transactions provider
final customerWalletTransactionsProvider = StateNotifierProvider<CustomerWalletTransactionsNotifier, CustomerWalletTransactionsState>((ref) {
  final repository = ref.watch(customerWalletRepositoryProvider);
  return CustomerWalletTransactionsNotifier(repository);
});

/// Customer wallet transactions stream provider for real-time updates
final customerWalletTransactionsStreamProvider = StreamProvider<List<CustomerWalletTransaction>>((ref) {
  final repository = ref.watch(customerWalletRepositoryProvider);
  return repository.getCustomerTransactionsStream(limit: 10);
});

/// Customer wallet error provider (for quick access to current error)
final customerWalletErrorProvider = Provider<CustomerWalletError?>((ref) {
  final walletState = ref.watch(customerWalletProvider);
  return walletState.error;
});

/// Customer wallet loading state provider
final customerWalletLoadingProvider = Provider<bool>((ref) {
  final walletState = ref.watch(customerWalletProvider);
  return walletState.isLoading;
});

/// Customer wallet retry count provider
final customerWalletRetryCountProvider = Provider<int>((ref) {
  final walletState = ref.watch(customerWalletProvider);
  return walletState.retryCount;
});

/// Customer wallet health check provider
final customerWalletHealthProvider = FutureProvider<bool>((ref) async {
  final notifier = ref.read(customerWalletProvider.notifier);
  return await notifier.checkWalletHealth();
});

/// Customer wallet can retry provider
final customerWalletCanRetryProvider = Provider<bool>((ref) {
  final walletState = ref.watch(customerWalletProvider);
  return walletState.canRetry && walletState.retryCount < 5;
});
