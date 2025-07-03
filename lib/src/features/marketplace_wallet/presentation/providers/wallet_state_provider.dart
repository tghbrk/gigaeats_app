import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/models/stakeholder_wallet.dart';
import '../../data/providers/marketplace_wallet_providers.dart';
import '../../data/repositories/marketplace_wallet_repository.dart';
import '../../data/services/wallet_cache_service.dart';

/// Wallet state for managing wallet data and operations
class WalletState {
  final StakeholderWallet? wallet;
  final bool isLoading;
  final String? errorMessage;
  final bool hasRealtimeConnection;
  final DateTime? lastUpdated;

  const WalletState({
    this.wallet,
    this.isLoading = false,
    this.errorMessage,
    this.hasRealtimeConnection = false,
    this.lastUpdated,
  });

  WalletState copyWith({
    StakeholderWallet? wallet,
    bool? isLoading,
    String? errorMessage,
    bool? hasRealtimeConnection,
    DateTime? lastUpdated,
  }) {
    return WalletState(
      wallet: wallet ?? this.wallet,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      hasRealtimeConnection: hasRealtimeConnection ?? this.hasRealtimeConnection,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get hasWallet => wallet != null;
  bool get isHealthy => hasWallet && !isLoading && errorMessage == null;
  bool get canRequestPayout => wallet?.canRequestPayout ?? false;
}

/// Wallet state notifier for managing wallet operations
class WalletStateNotifier extends StateNotifier<WalletState> {
  final MarketplaceWalletRepository _repository;
  final WalletCacheService _cacheService;
  final Ref _ref;
  final String _userRole;

  WalletStateNotifier(
    this._repository,
    this._cacheService,
    this._ref,
    this._userRole,
  ) : super(const WalletState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    debugPrint('🔍 [WALLET-STATE] Initializing wallet for role: $_userRole');
    await loadWallet();
  }

  /// Load wallet data with cache-first strategy
  Future<void> loadWallet({bool forceRefresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authState = _ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      StakeholderWallet? wallet;

      // Try cache first unless force refresh
      if (!forceRefresh) {
        wallet = await _cacheService.getCachedWallet(userId, _userRole);
        if (wallet != null) {
          debugPrint('🔍 [WALLET-STATE] Loaded wallet from cache: ${wallet.formattedAvailableBalance}');
          state = state.copyWith(
            wallet: wallet,
            isLoading: false,
            lastUpdated: DateTime.now(),
          );
          return;
        }
      }

      // Load from repository
      final result = await _repository.getWallet(_userRole);
      result.fold(
        (failure) {
          debugPrint('🔍 [WALLET-STATE] Failed to load wallet: ${failure.message}');
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
        },
        (loadedWallet) {
          debugPrint('🔍 [WALLET-STATE] Loaded wallet from repository: ${loadedWallet?.formattedAvailableBalance ?? 'null'}');
          
          // Cache the wallet if it exists
          if (loadedWallet != null) {
            _cacheService.cacheWallet(loadedWallet);
          }

          state = state.copyWith(
            wallet: loadedWallet,
            isLoading: false,
            lastUpdated: DateTime.now(),
          );
        },
      );
    } catch (e) {
      debugPrint('🔍 [WALLET-STATE] Error loading wallet: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Refresh wallet data
  Future<void> refresh() async {
    debugPrint('🔍 [WALLET-STATE] Refreshing wallet data');
    await loadWallet(forceRefresh: true);
  }

  /// Update wallet settings
  Future<bool> updateWalletSettings({
    bool? autoPayoutEnabled,
    double? autoPayoutThreshold,
    String? payoutSchedule,
    Map<String, dynamic>? bankAccountDetails,
  }) async {
    if (state.wallet == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _repository.updateWalletSettings(
        walletId: state.wallet!.id,
        autoPayoutEnabled: autoPayoutEnabled,
        autoPayoutThreshold: autoPayoutThreshold,
        payoutSchedule: payoutSchedule,
        bankAccountDetails: bankAccountDetails,
      );

      return result.fold(
        (failure) {
          debugPrint('🔍 [WALLET-STATE] Failed to update wallet settings: ${failure.message}');
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
          return false;
        },
        (updatedWallet) {
          debugPrint('🔍 [WALLET-STATE] Wallet settings updated successfully');
          
          // Update cache
          _cacheService.cacheWallet(updatedWallet);
          
          state = state.copyWith(
            wallet: updatedWallet,
            isLoading: false,
            lastUpdated: DateTime.now(),
          );
          return true;
        },
      );
    } catch (e) {
      debugPrint('🔍 [WALLET-STATE] Error updating wallet settings: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Clear wallet cache
  Future<void> clearCache() async {
    final authState = _ref.read(authStateProvider);
    final userId = authState.user?.id;
    
    if (userId != null) {
      await _cacheService.clearWalletCache(userId, _userRole);
      debugPrint('🔍 [WALLET-STATE] Wallet cache cleared');
    }
  }

  /// Handle real-time wallet updates
  void handleRealtimeUpdate(StakeholderWallet updatedWallet) {
    debugPrint('🔍 [WALLET-STATE] Real-time wallet update received: ${updatedWallet.formattedAvailableBalance}');
    
    // Update cache
    _cacheService.cacheWallet(updatedWallet);
    
    state = state.copyWith(
      wallet: updatedWallet,
      hasRealtimeConnection: true,
      lastUpdated: DateTime.now(),
    );
  }

  /// Set real-time connection status
  void setRealtimeConnection(bool connected) {
    state = state.copyWith(hasRealtimeConnection: connected);
  }

  @override
  void dispose() {
    debugPrint('🔍 [WALLET-STATE] Disposing wallet state notifier');
    super.dispose();
  }
}

/// Wallet state provider factory for different user roles
final walletStateProvider = StateNotifierProvider.family<WalletStateNotifier, WalletState, String>((ref, userRole) {
  final repository = ref.watch(walletRepositoryProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  
  return WalletStateNotifier(repository, cacheService, ref, userRole);
});

/// Current user wallet provider (auto-detects role)
final currentUserWalletProvider = StateNotifierProvider<WalletStateNotifier, WalletState>((ref) {
  final authState = ref.watch(authStateProvider);
  final userRole = authState.user?.role.value ?? 'customer';
  
  final repository = ref.watch(walletRepositoryProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  
  return WalletStateNotifier(repository, cacheService, ref, userRole);
});

/// Wallet stream provider for real-time updates
final walletStreamProvider = StreamProvider.family<StakeholderWallet?, String>((ref, userRole) {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getWalletStream(userRole);
});

/// Current user wallet stream provider
final currentUserWalletStreamProvider = StreamProvider<StakeholderWallet?>((ref) {
  final authState = ref.watch(authStateProvider);
  final userRole = authState.user?.role.value ?? 'customer';
  
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getWalletStream(userRole);
});

/// Wallet balance provider (for quick access)
final walletBalanceProvider = Provider.family<double, String>((ref, userRole) {
  final walletState = ref.watch(walletStateProvider(userRole));
  return walletState.wallet?.availableBalance ?? 0.0;
});

/// Current user wallet balance provider
final currentUserWalletBalanceProvider = Provider<double>((ref) {
  final walletState = ref.watch(currentUserWalletProvider);
  return walletState.wallet?.availableBalance ?? 0.0;
});

/// Wallet status provider
final walletStatusProvider = Provider.family<WalletStatus, String>((ref, userRole) {
  final walletState = ref.watch(walletStateProvider(userRole));
  return walletState.wallet?.status ?? WalletStatus.inactive;
});

/// Wallet actions provider for UI operations
final walletActionsProvider = Provider<WalletActions>((ref) {
  return WalletActions(ref);
});

/// Wallet actions class for centralized wallet operations
class WalletActions {
  final Ref _ref;

  WalletActions(this._ref);

  /// Refresh wallet for specific role
  Future<void> refreshWallet(String userRole) async {
    final notifier = _ref.read(walletStateProvider(userRole).notifier);
    await notifier.refresh();
  }

  /// Refresh current user wallet
  Future<void> refreshCurrentUserWallet() async {
    final notifier = _ref.read(currentUserWalletProvider.notifier);
    await notifier.refresh();
  }

  /// Update wallet settings
  Future<bool> updateWalletSettings({
    required String userRole,
    bool? autoPayoutEnabled,
    double? autoPayoutThreshold,
    String? payoutSchedule,
    Map<String, dynamic>? bankAccountDetails,
  }) async {
    final notifier = _ref.read(walletStateProvider(userRole).notifier);
    return await notifier.updateWalletSettings(
      autoPayoutEnabled: autoPayoutEnabled,
      autoPayoutThreshold: autoPayoutThreshold,
      payoutSchedule: payoutSchedule,
      bankAccountDetails: bankAccountDetails,
    );
  }

  /// Clear wallet cache
  Future<void> clearWalletCache(String userRole) async {
    final notifier = _ref.read(walletStateProvider(userRole).notifier);
    await notifier.clearCache();
  }

  /// Get wallet for role
  WalletState getWalletState(String userRole) {
    return _ref.read(walletStateProvider(userRole));
  }

  /// Check if wallet can request payout
  bool canRequestPayout(String userRole) {
    final walletState = _ref.read(walletStateProvider(userRole));
    return walletState.canRequestPayout;
  }
}
