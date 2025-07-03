import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/customer_wallet.dart';
import '../../data/services/enhanced_customer_wallet_service.dart';

/// Provider for enhanced customer wallet service
final enhancedCustomerWalletServiceProvider = Provider<EnhancedCustomerWalletService>((ref) {
  return EnhancedCustomerWalletService();
});

/// Enhanced customer wallet state with comprehensive error handling
class EnhancedCustomerWalletState {
  final CustomerWallet? wallet;
  final bool isLoading;
  final bool isRefreshing;
  final Failure? failure;
  final DateTime? lastUpdated;
  final int retryCount;
  final bool isConnected;

  const EnhancedCustomerWalletState({
    this.wallet,
    this.isLoading = false,
    this.isRefreshing = false,
    this.failure,
    this.lastUpdated,
    this.retryCount = 0,
    this.isConnected = true,
  });

  EnhancedCustomerWalletState copyWith({
    CustomerWallet? wallet,
    bool? isLoading,
    bool? isRefreshing,
    Failure? failure,
    DateTime? lastUpdated,
    int? retryCount,
    bool? isConnected,
  }) {
    return EnhancedCustomerWalletState(
      wallet: wallet ?? this.wallet,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      failure: failure,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      retryCount: retryCount ?? this.retryCount,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  /// Clear error state
  EnhancedCustomerWalletState clearError() {
    return copyWith(failure: null);
  }

  /// Increment retry count
  EnhancedCustomerWalletState incrementRetry() {
    return copyWith(retryCount: retryCount + 1);
  }

  /// Reset retry count
  EnhancedCustomerWalletState resetRetry() {
    return copyWith(retryCount: 0);
  }

  // Computed properties
  bool get hasWallet => wallet != null;
  bool get hasError => failure != null;
  bool get canRetry => retryCount < 5 && isConnected;
  double get availableBalance => wallet?.availableBalance ?? 0.0;
  String get formattedBalance => wallet?.formattedAvailableBalance ?? 'RM 0.00';
  String get errorMessage => failure?.message ?? '';
  bool get isHealthy => wallet?.isHealthy ?? false;
  WalletActivityStatus get activityStatus => wallet?.activityStatus ?? WalletActivityStatus.inactive;
}

/// Enhanced customer wallet notifier with comprehensive functionality
class EnhancedCustomerWalletNotifier extends StateNotifier<EnhancedCustomerWalletState> {
  final EnhancedCustomerWalletService _service;
  final Ref _ref;

  EnhancedCustomerWalletNotifier(this._service, this._ref) : super(const EnhancedCustomerWalletState());

  /// Load customer wallet data with enhanced error handling and session validation
  Future<void> loadWallet({bool forceRefresh = false}) async {
    if (state.isLoading && !forceRefresh) return;

    // Check authentication first
    final authState = _ref.read(authStateProvider);
    if (authState.user == null) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        failure: const AuthFailure(message: 'User session expired'),
      );
      return;
    }

    // Additional session validation
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    if (session == null || session.isExpired) {
      debugPrint('🔍 [ENHANCED-WALLET-PROVIDER] Session expired, attempting refresh');
      try {
        await supabase.auth.refreshSession();
        debugPrint('✅ [ENHANCED-WALLET-PROVIDER] Session refreshed successfully');
      } catch (e) {
        debugPrint('❌ [ENHANCED-WALLET-PROVIDER] Session refresh failed: $e');
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          failure: const AuthFailure(message: 'Session refresh failed. Please log in again.'),
        );
        return;
      }
    }

    state = state.copyWith(
      isLoading: true,
      isRefreshing: forceRefresh,
      failure: null,
    );

    try {
      debugPrint('🔍 [ENHANCED-WALLET-PROVIDER] Loading customer wallet (retry: ${state.retryCount})');

      // Add a small delay to ensure authentication context is fully established
      await Future.delayed(const Duration(milliseconds: 500));

      final result = await _service.getOrCreateCustomerWallet();

      result.fold(
        (failure) {
          debugPrint('❌ [ENHANCED-WALLET-PROVIDER] Failed to load wallet: ${failure.message}');
          state = state.copyWith(
            isLoading: false,
            isRefreshing: false,
            failure: failure,
          ).incrementRetry();
        },
        (wallet) {
          debugPrint('✅ [ENHANCED-WALLET-PROVIDER] Wallet loaded: ${wallet.formattedAvailableBalance}');
          state = state.copyWith(
            wallet: wallet,
            isLoading: false,
            isRefreshing: false,
            lastUpdated: DateTime.now(),
            isConnected: true,
          ).resetRetry();
        },
      );
    } catch (e) {
      debugPrint('❌ [ENHANCED-WALLET-PROVIDER] Exception loading wallet: $e');
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        failure: UnexpectedFailure(message: e.toString()),
        isConnected: false,
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
    debugPrint('🔄 [ENHANCED-WALLET-PROVIDER] Retrying in ${delaySeconds}s (attempt ${state.retryCount + 1})');

    await Future.delayed(Duration(seconds: delaySeconds));
    await loadWallet(forceRefresh: true);
  }

  /// Check if customer has sufficient balance
  Future<bool> hasSufficientBalance(double amount) async {
    try {
      final result = await _service.hasSufficientBalance(amount);
      return result.fold(
        (failure) {
          debugPrint('❌ [ENHANCED-WALLET-PROVIDER] Balance check failed: ${failure.message}');
          state = state.copyWith(failure: failure);
          return false;
        },
        (hasSufficient) {
          if (!hasSufficient && state.wallet != null) {
            final insufficientFailure = ValidationFailure(
              message: 'Insufficient wallet balance. Available: ${state.wallet!.formattedAvailableBalance}, Required: RM ${amount.toStringAsFixed(2)}',
            );
            state = state.copyWith(failure: insufficientFailure);
          }
          return hasSufficient;
        },
      );
    } catch (e) {
      debugPrint('❌ [ENHANCED-WALLET-PROVIDER] Error checking balance: $e');
      state = state.copyWith(failure: UnexpectedFailure(message: e.toString()));
      return false;
    }
  }

  /// Calculate split payment
  Future<SplitPaymentCalculation?> calculateSplitPayment(double amount) async {
    try {
      final result = await _service.calculateSplitPayment(amount);
      return result.fold(
        (failure) {
          debugPrint('❌ [ENHANCED-WALLET-PROVIDER] Split payment calculation failed: ${failure.message}');
          state = state.copyWith(failure: failure);
          return null;
        },
        (calculation) => calculation,
      );
    } catch (e) {
      debugPrint('❌ [ENHANCED-WALLET-PROVIDER] Error calculating split payment: $e');
      state = state.copyWith(failure: UnexpectedFailure(message: e.toString()));
      return null;
    }
  }

  /// Validate wallet for transaction
  Future<WalletValidationResult?> validateWalletForTransaction({
    required double amount,
    required String transactionType,
  }) async {
    try {
      final result = await _service.validateWalletForTransaction(
        amount: amount,
        transactionType: transactionType,
      );
      return result.fold(
        (failure) {
          debugPrint('❌ [ENHANCED-WALLET-PROVIDER] Wallet validation failed: ${failure.message}');
          state = state.copyWith(failure: failure);
          return null;
        },
        (validationResult) {
          if (!validationResult.isValid) {
            final validationFailure = ValidationFailure(
              message: validationResult.errorMessage ?? 'Wallet validation failed',
              code: validationResult.errorCode,
            );
            state = state.copyWith(failure: validationFailure);
          }
          return validationResult;
        },
      );
    } catch (e) {
      debugPrint('❌ [ENHANCED-WALLET-PROVIDER] Error validating wallet: $e');
      state = state.copyWith(failure: UnexpectedFailure(message: e.toString()));
      return null;
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
      debugPrint('🔍 [ENHANCED-WALLET-PROVIDER] Checking wallet health');
      final result = await _service.getCustomerWallet();
      final isHealthy = result.fold(
        (failure) => false,
        (wallet) => wallet?.isHealthy ?? false,
      );
      
      state = state.copyWith(isConnected: isHealthy);
      return isHealthy;
    } catch (e) {
      debugPrint('❌ [ENHANCED-WALLET-PROVIDER] Health check failed: $e');
      state = state.copyWith(isConnected: false);
      return false;
    }
  }
}

/// Enhanced customer wallet provider
final enhancedCustomerWalletProvider = StateNotifierProvider<EnhancedCustomerWalletNotifier, EnhancedCustomerWalletState>((ref) {
  final service = ref.watch(enhancedCustomerWalletServiceProvider);
  return EnhancedCustomerWalletNotifier(service, ref);
});

/// Enhanced customer wallet stream provider for real-time updates
final enhancedCustomerWalletStreamProvider = StreamProvider<CustomerWallet?>((ref) {
  final service = ref.watch(enhancedCustomerWalletServiceProvider);
  return service.getCustomerWalletStream().map((either) {
    return either.fold(
      (failure) {
        debugPrint('❌ [ENHANCED-WALLET-STREAM] Stream error: ${failure.message}');
        return null;
      },
      (wallet) => wallet,
    );
  });
});

/// Quick access providers
final enhancedCustomerWalletBalanceProvider = Provider<double>((ref) {
  final walletState = ref.watch(enhancedCustomerWalletProvider);
  return walletState.availableBalance;
});

final enhancedCustomerWalletErrorProvider = Provider<Failure?>((ref) {
  final walletState = ref.watch(enhancedCustomerWalletProvider);
  return walletState.failure;
});

final enhancedCustomerWalletLoadingProvider = Provider<bool>((ref) {
  final walletState = ref.watch(enhancedCustomerWalletProvider);
  return walletState.isLoading;
});

final enhancedCustomerWalletHealthProvider = Provider<bool>((ref) {
  final walletState = ref.watch(enhancedCustomerWalletProvider);
  return walletState.isHealthy;
});
