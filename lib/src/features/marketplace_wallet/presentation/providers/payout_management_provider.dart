import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/payout_request.dart';
import '../../data/providers/marketplace_wallet_providers.dart';
import '../../data/repositories/marketplace_wallet_repository.dart';
import '../../data/services/wallet_cache_service.dart';
import 'wallet_state_provider.dart';

/// Payout management state for managing payout requests
class PayoutManagementState {
  final List<PayoutRequest> payoutRequests;
  final bool isLoading;
  final bool isCreatingPayout;
  final String? errorMessage;
  final PayoutStatus? filterStatus;
  final bool hasMore;
  final int currentPage;
  final DateTime? lastUpdated;

  const PayoutManagementState({
    this.payoutRequests = const [],
    this.isLoading = false,
    this.isCreatingPayout = false,
    this.errorMessage,
    this.filterStatus,
    this.hasMore = true,
    this.currentPage = 0,
    this.lastUpdated,
  });

  PayoutManagementState copyWith({
    List<PayoutRequest>? payoutRequests,
    bool? isLoading,
    bool? isCreatingPayout,
    String? errorMessage,
    PayoutStatus? filterStatus,
    bool? hasMore,
    int? currentPage,
    DateTime? lastUpdated,
  }) {
    return PayoutManagementState(
      payoutRequests: payoutRequests ?? this.payoutRequests,
      isLoading: isLoading ?? this.isLoading,
      isCreatingPayout: isCreatingPayout ?? this.isCreatingPayout,
      errorMessage: errorMessage,
      filterStatus: filterStatus ?? this.filterStatus,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get isEmpty => payoutRequests.isEmpty && !isLoading;
  bool get hasPayouts => payoutRequests.isNotEmpty;
  bool get canLoadMore => hasMore && !isLoading;
  bool get hasPendingPayouts => payoutRequests.any((p) => p.status == PayoutStatus.pending);
  bool get hasActivePayouts => payoutRequests.any((p) => p.status.isActive);
}

/// Payout management notifier for managing payout operations
class PayoutManagementNotifier extends StateNotifier<PayoutManagementState> {
  final MarketplaceWalletRepository _repository;
  final WalletCacheService _cacheService;
  final Ref _ref;
  final String _walletId;

  static const int _pageSize = 20;

  PayoutManagementNotifier(
    this._repository,
    this._cacheService,
    this._ref,
    this._walletId,
  ) : super(const PayoutManagementState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    debugPrint('🔍 [PAYOUTS] Initializing payout management for wallet: $_walletId');
    await loadPayoutRequests();
  }

  /// Load payout requests with cache-first strategy
  Future<void> loadPayoutRequests({bool forceRefresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      List<PayoutRequest>? payoutRequests;

      // Try cache first unless force refresh
      if (!forceRefresh && state.currentPage == 0) {
        payoutRequests = await _cacheService.getCachedPayoutRequests(_walletId);
        if (payoutRequests != null) {
          debugPrint('🔍 [PAYOUTS] Loaded ${payoutRequests.length} payout requests from cache');
          state = state.copyWith(
            payoutRequests: payoutRequests,
            isLoading: false,
            hasMore: payoutRequests.length >= _pageSize,
            lastUpdated: DateTime.now(),
          );
          return;
        }
      }

      // Load from repository
      final result = await _repository.getPayoutRequests(
        walletId: _walletId,
        limit: _pageSize,
        offset: state.currentPage * _pageSize,
        status: state.filterStatus,
      );

      result.fold(
        (failure) {
          debugPrint('🔍 [PAYOUTS] Failed to load payout requests: ${failure.message}');
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
        },
        (loadedPayouts) {
          debugPrint('🔍 [PAYOUTS] Loaded ${loadedPayouts.length} payout requests from repository');
          
          // Cache payout requests if this is the first page
          if (state.currentPage == 0) {
            _cacheService.cachePayoutRequests(_walletId, loadedPayouts);
          }

          final allPayouts = state.currentPage == 0
              ? loadedPayouts
              : [...state.payoutRequests, ...loadedPayouts];

          state = state.copyWith(
            payoutRequests: allPayouts,
            isLoading: false,
            hasMore: loadedPayouts.length >= _pageSize,
            lastUpdated: DateTime.now(),
          );
        },
      );
    } catch (e) {
      debugPrint('🔍 [PAYOUTS] Error loading payout requests: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Create new payout request
  Future<bool> createPayoutRequest({
    required double amount,
    required String bankAccountNumber,
    required String bankName,
    required String accountHolderName,
    String? swiftCode,
  }) async {
    if (state.isCreatingPayout) return false;

    state = state.copyWith(isCreatingPayout: true, errorMessage: null);

    try {
      debugPrint('🔍 [PAYOUTS] Creating payout request for amount: $amount');
      
      final result = await _repository.createPayoutRequest(
        amount: amount,
        bankAccountNumber: bankAccountNumber,
        bankName: bankName,
        accountHolderName: accountHolderName,
        swiftCode: swiftCode,
      );

      return result.fold(
        (failure) {
          debugPrint('🔍 [PAYOUTS] Failed to create payout request: ${failure.message}');
          state = state.copyWith(
            isCreatingPayout: false,
            errorMessage: failure.message,
          );
          return false;
        },
        (newPayout) {
          debugPrint('🔍 [PAYOUTS] Payout request created successfully: ${newPayout.id}');
          
          // Add new payout to the beginning of the list
          final updatedPayouts = [newPayout, ...state.payoutRequests];
          
          // Update cache
          _cacheService.cachePayoutRequests(_walletId, updatedPayouts.take(20).toList());
          
          state = state.copyWith(
            payoutRequests: updatedPayouts,
            isCreatingPayout: false,
            lastUpdated: DateTime.now(),
          );
          
          // Refresh wallet to update balance
          _ref.read(walletActionsProvider).refreshCurrentUserWallet();
          
          return true;
        },
      );
    } catch (e) {
      debugPrint('🔍 [PAYOUTS] Error creating payout request: $e');
      state = state.copyWith(
        isCreatingPayout: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Load more payout requests (pagination)
  Future<void> loadMorePayoutRequests() async {
    if (!state.canLoadMore) return;

    try {
      final result = await _repository.getPayoutRequests(
        walletId: _walletId,
        limit: _pageSize,
        offset: (state.currentPage + 1) * _pageSize,
        status: state.filterStatus,
      );

      result.fold(
        (failure) {
          debugPrint('🔍 [PAYOUTS] Failed to load more payout requests: ${failure.message}');
          state = state.copyWith(errorMessage: failure.message);
        },
        (loadedPayouts) {
          debugPrint('🔍 [PAYOUTS] Loaded ${loadedPayouts.length} more payout requests');
          
          state = state.copyWith(
            payoutRequests: [...state.payoutRequests, ...loadedPayouts],
            currentPage: state.currentPage + 1,
            hasMore: loadedPayouts.length >= _pageSize,
            lastUpdated: DateTime.now(),
          );
        },
      );
    } catch (e) {
      debugPrint('🔍 [PAYOUTS] Error loading more payout requests: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Refresh payout requests
  Future<void> refresh() async {
    debugPrint('🔍 [PAYOUTS] Refreshing payout requests');
    state = state.copyWith(currentPage: 0);
    await loadPayoutRequests(forceRefresh: true);
  }

  /// Apply status filter
  Future<void> applyStatusFilter(PayoutStatus? status) async {
    debugPrint('🔍 [PAYOUTS] Applying status filter: $status');
    
    state = state.copyWith(
      filterStatus: status,
      currentPage: 0,
      payoutRequests: [],
    );
    
    await loadPayoutRequests(forceRefresh: true);
  }

  /// Clear filters
  Future<void> clearFilters() async {
    debugPrint('🔍 [PAYOUTS] Clearing filters');
    
    state = state.copyWith(
      filterStatus: null,
      currentPage: 0,
      payoutRequests: [],
    );
    
    await loadPayoutRequests(forceRefresh: true);
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _cacheService.clearPayoutRequestsCache(_walletId);
    debugPrint('🔍 [PAYOUTS] Payout requests cache cleared');
  }

  /// Handle real-time payout updates
  void handleRealtimeUpdate(PayoutRequest updatedPayout) {
    debugPrint('🔍 [PAYOUTS] Real-time payout update: ${updatedPayout.id} - ${updatedPayout.status.displayName}');
    
    // Update existing payout or add new one
    final updatedPayouts = state.payoutRequests.map((payout) {
      return payout.id == updatedPayout.id ? updatedPayout : payout;
    }).toList();
    
    // If payout not found, add it to the beginning
    if (!updatedPayouts.any((p) => p.id == updatedPayout.id)) {
      updatedPayouts.insert(0, updatedPayout);
    }
    
    // Update cache
    _cacheService.cachePayoutRequests(_walletId, updatedPayouts.take(20).toList());
    
    state = state.copyWith(
      payoutRequests: updatedPayouts,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  void dispose() {
    debugPrint('🔍 [PAYOUTS] Disposing payout management notifier');
    super.dispose();
  }
}

/// Payout management provider factory for different wallets
final payoutManagementProvider = StateNotifierProvider.family<PayoutManagementNotifier, PayoutManagementState, String>((ref, walletId) {
  final repository = ref.watch(walletRepositoryProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  
  return PayoutManagementNotifier(repository, cacheService, ref, walletId);
});

/// Current user payout management provider
final currentUserPayoutManagementProvider = StateNotifierProvider<PayoutManagementNotifier, PayoutManagementState>((ref) {
  final walletState = ref.watch(currentUserWalletProvider);
  final walletId = walletState.wallet?.id ?? '';
  
  if (walletId.isEmpty) {
    throw Exception('No wallet found for current user');
  }
  
  final repository = ref.watch(walletRepositoryProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  
  return PayoutManagementNotifier(repository, cacheService, ref, walletId);
});

/// Payout summary provider
final payoutSummaryProvider = Provider.family<PayoutSummary, String>((ref, walletId) {
  final payoutState = ref.watch(payoutManagementProvider(walletId));
  
  double totalRequested = 0;
  double totalCompleted = 0;
  double totalPending = 0;
  double totalFees = 0;
  
  int pendingCount = 0;
  int completedCount = 0;
  int failedCount = 0;
  
  for (final payout in payoutState.payoutRequests) {
    totalRequested += payout.amount;
    totalFees += payout.processingFee;
    
    switch (payout.status) {
      case PayoutStatus.pending:
      case PayoutStatus.processing:
        totalPending += payout.amount;
        pendingCount++;
        break;
      case PayoutStatus.completed:
        totalCompleted += payout.netAmount;
        completedCount++;
        break;
      case PayoutStatus.failed:
      case PayoutStatus.cancelled:
        failedCount++;
        break;
    }
  }
  
  return PayoutSummary(
    totalRequested: totalRequested,
    totalCompleted: totalCompleted,
    totalPending: totalPending,
    totalFees: totalFees,
    pendingCount: pendingCount,
    completedCount: completedCount,
    failedCount: failedCount,
    totalPayouts: payoutState.payoutRequests.length,
  );
});

/// Payout actions provider for UI operations
final payoutActionsProvider = Provider<PayoutActions>((ref) {
  return PayoutActions(ref);
});

/// Payout actions class for centralized payout operations
class PayoutActions {
  final Ref _ref;

  PayoutActions(this._ref);

  /// Create payout request
  Future<bool> createPayoutRequest({
    required String walletId,
    required double amount,
    required String bankAccountNumber,
    required String bankName,
    required String accountHolderName,
    String? swiftCode,
  }) async {
    final notifier = _ref.read(payoutManagementProvider(walletId).notifier);
    return await notifier.createPayoutRequest(
      amount: amount,
      bankAccountNumber: bankAccountNumber,
      bankName: bankName,
      accountHolderName: accountHolderName,
      swiftCode: swiftCode,
    );
  }

  /// Refresh payout requests
  Future<void> refreshPayoutRequests(String walletId) async {
    final notifier = _ref.read(payoutManagementProvider(walletId).notifier);
    await notifier.refresh();
  }

  /// Load more payout requests
  Future<void> loadMorePayoutRequests(String walletId) async {
    final notifier = _ref.read(payoutManagementProvider(walletId).notifier);
    await notifier.loadMorePayoutRequests();
  }

  /// Apply status filter
  Future<void> applyStatusFilter(String walletId, PayoutStatus? status) async {
    final notifier = _ref.read(payoutManagementProvider(walletId).notifier);
    await notifier.applyStatusFilter(status);
  }

  /// Get payout state
  PayoutManagementState getPayoutState(String walletId) {
    return _ref.read(payoutManagementProvider(walletId));
  }

  /// Check if user can create payout
  bool canCreatePayout(String walletId) {
    final payoutState = _ref.read(payoutManagementProvider(walletId));
    return !payoutState.hasPendingPayouts && !payoutState.isCreatingPayout;
  }
}

/// Payout summary data class
class PayoutSummary {
  final double totalRequested;
  final double totalCompleted;
  final double totalPending;
  final double totalFees;
  final int pendingCount;
  final int completedCount;
  final int failedCount;
  final int totalPayouts;

  const PayoutSummary({
    required this.totalRequested,
    required this.totalCompleted,
    required this.totalPending,
    required this.totalFees,
    required this.pendingCount,
    required this.completedCount,
    required this.failedCount,
    required this.totalPayouts,
  });

  String get formattedTotalRequested => 'MYR ${totalRequested.toStringAsFixed(2)}';
  String get formattedTotalCompleted => 'MYR ${totalCompleted.toStringAsFixed(2)}';
  String get formattedTotalPending => 'MYR ${totalPending.toStringAsFixed(2)}';
  String get formattedTotalFees => 'MYR ${totalFees.toStringAsFixed(2)}';
  
  double get successRate => totalPayouts > 0 ? (completedCount / totalPayouts) * 100 : 0;
  String get formattedSuccessRate => '${successRate.toStringAsFixed(1)}%';
}
