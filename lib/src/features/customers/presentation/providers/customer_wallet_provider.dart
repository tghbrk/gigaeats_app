import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigaeats_app/src/features/marketplace_wallet/data/models/stakeholder_wallet.dart';
import 'package:gigaeats_app/src/features/marketplace_wallet/data/models/customer_wallet_error.dart';

// Temporary provider until wallet service is implemented
final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService();
});

// Temporary wallet service implementation
class WalletService {
  Future<StakeholderWallet?> getWalletByUserId(String userId) async {
    // TODO: Implement actual wallet service
    await Future.delayed(const Duration(seconds: 1));
    return null;
  }
}

/// Customer wallet state
class CustomerWalletState {
  final StakeholderWallet? wallet;
  final bool isLoading;
  final CustomerWalletError? error;
  final bool isRefreshing;

  const CustomerWalletState({
    this.wallet,
    this.isLoading = false,
    this.error,
    this.isRefreshing = false,
  });

  CustomerWalletState copyWith({
    StakeholderWallet? wallet,
    bool? isLoading,
    CustomerWalletError? error,
    bool? isRefreshing,
  }) {
    return CustomerWalletState(
      wallet: wallet ?? this.wallet,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// Customer wallet provider
final customerWalletProvider = StateNotifierProvider<CustomerWalletNotifier, CustomerWalletState>((ref) {
  return CustomerWalletNotifier(ref);
});

/// Customer wallet notifier
class CustomerWalletNotifier extends StateNotifier<CustomerWalletState> {
  final Ref _ref;

  CustomerWalletNotifier(this._ref) : super(const CustomerWalletState());

  /// Load customer wallet
  Future<void> loadWallet(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final walletService = _ref.read(walletServiceProvider);
      final wallet = await walletService.getWalletByUserId(userId);
      
      state = state.copyWith(
        wallet: wallet,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: CustomerWalletError.fromException(e is Exception ? e : Exception(e.toString())),
      );
    }
  }

  /// Refresh wallet data
  Future<void> refreshWallet() async {
    if (state.wallet == null) return;

    state = state.copyWith(isRefreshing: true, error: null);

    try {
      final walletService = _ref.read(walletServiceProvider);
      final wallet = await walletService.getWalletByUserId(state.wallet!.userId);
      
      state = state.copyWith(
        wallet: wallet,
        isRefreshing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: CustomerWalletError.fromException(e is Exception ? e : Exception(e.toString())),
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
