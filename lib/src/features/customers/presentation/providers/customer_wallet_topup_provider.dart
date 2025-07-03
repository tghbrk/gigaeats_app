import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigaeats_app/src/features/marketplace_wallet/data/models/customer_wallet_error.dart';

/// Customer wallet topup state
class CustomerWalletTopupState {
  final bool isLoading;
  final CustomerWalletError? error;
  final double? amount;
  final String? paymentMethodId;
  final bool isProcessing;

  const CustomerWalletTopupState({
    this.isLoading = false,
    this.error,
    this.amount,
    this.paymentMethodId,
    this.isProcessing = false,
  });

  CustomerWalletTopupState copyWith({
    bool? isLoading,
    CustomerWalletError? error,
    double? amount,
    String? paymentMethodId,
    bool? isProcessing,
  }) {
    return CustomerWalletTopupState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      amount: amount ?? this.amount,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

/// Customer wallet topup provider
final customerWalletTopupProvider = StateNotifierProvider<CustomerWalletTopupNotifier, CustomerWalletTopupState>((ref) {
  return CustomerWalletTopupNotifier();
});

/// Customer wallet topup notifier
class CustomerWalletTopupNotifier extends StateNotifier<CustomerWalletTopupState> {
  CustomerWalletTopupNotifier() : super(const CustomerWalletTopupState());

  /// Set topup amount
  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  /// Set payment method
  void setPaymentMethod(String paymentMethodId) {
    state = state.copyWith(paymentMethodId: paymentMethodId);
  }

  /// Process topup
  Future<bool> processTopup(String userId) async {
    if (state.amount == null || state.paymentMethodId == null) {
      state = state.copyWith(
        error: CustomerWalletError.transactionFailed('Amount and payment method required'),
      );
      return false;
    }

    state = state.copyWith(isProcessing: true, error: null);

    try {
      // TODO: Implement actual topup processing with Stripe
      await Future.delayed(const Duration(seconds: 2)); // Simulate processing
      
      state = state.copyWith(
        isProcessing: false,
        amount: null,
        paymentMethodId: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: CustomerWalletError.fromException(e is Exception ? e : Exception(e.toString())),
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset state
  void reset() {
    state = const CustomerWalletTopupState();
  }
}
