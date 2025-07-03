import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigaeats_app/src/features/marketplace_wallet/data/models/customer_wallet_error.dart';

/// Customer wallet transfer state
class CustomerWalletTransferState {
  final bool isLoading;
  final CustomerWalletError? error;
  final double? amount;
  final String? recipientId;
  final String? note;
  final bool isProcessing;

  const CustomerWalletTransferState({
    this.isLoading = false,
    this.error,
    this.amount,
    this.recipientId,
    this.note,
    this.isProcessing = false,
  });

  CustomerWalletTransferState copyWith({
    bool? isLoading,
    CustomerWalletError? error,
    double? amount,
    String? recipientId,
    String? note,
    bool? isProcessing,
  }) {
    return CustomerWalletTransferState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      amount: amount ?? this.amount,
      recipientId: recipientId ?? this.recipientId,
      note: note ?? this.note,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

/// Customer wallet transfer provider
final customerWalletTransferProvider = StateNotifierProvider<CustomerWalletTransferNotifier, CustomerWalletTransferState>((ref) {
  return CustomerWalletTransferNotifier();
});

/// Customer wallet transfer notifier
class CustomerWalletTransferNotifier extends StateNotifier<CustomerWalletTransferState> {
  CustomerWalletTransferNotifier() : super(const CustomerWalletTransferState());

  /// Set transfer amount
  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  /// Set recipient
  void setRecipient(String recipientId) {
    state = state.copyWith(recipientId: recipientId);
  }

  /// Set note
  void setNote(String note) {
    state = state.copyWith(note: note);
  }

  /// Process transfer
  Future<bool> processTransfer(String senderId) async {
    if (state.amount == null || state.recipientId == null) {
      state = state.copyWith(
        error: CustomerWalletError.transactionFailed('Amount and recipient required'),
      );
      return false;
    }

    state = state.copyWith(isProcessing: true, error: null);

    try {
      // TODO: Implement actual transfer processing
      await Future.delayed(const Duration(seconds: 2)); // Simulate processing
      
      state = state.copyWith(
        isProcessing: false,
        amount: null,
        recipientId: null,
        note: null,
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
    state = const CustomerWalletTransferState();
  }
}
