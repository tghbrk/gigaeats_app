import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/customer_wallet_topup_service.dart';

/// State for wallet top-up operations
@immutable
class CustomerWalletTopupState {
  final bool isLoading;
  final String? errorMessage;
  final bool isProcessing;
  final String? lastTransactionId;

  const CustomerWalletTopupState({
    this.isLoading = false,
    this.errorMessage,
    this.isProcessing = false,
    this.lastTransactionId,
  });

  CustomerWalletTopupState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isProcessing,
    String? lastTransactionId,
  }) {
    return CustomerWalletTopupState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
      lastTransactionId: lastTransactionId ?? this.lastTransactionId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerWalletTopupState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          isProcessing == other.isProcessing &&
          lastTransactionId == other.lastTransactionId;

  @override
  int get hashCode =>
      isLoading.hashCode ^
      errorMessage.hashCode ^
      isProcessing.hashCode ^
      lastTransactionId.hashCode;
}

/// Provider for wallet top-up service
final customerWalletTopupServiceProvider = Provider<CustomerWalletTopupService>((ref) {
  return CustomerWalletTopupService();
});

/// Provider for wallet top-up state management
final customerWalletTopupProvider = StateNotifierProvider<CustomerWalletTopupNotifier, CustomerWalletTopupState>((ref) {
  final service = ref.watch(customerWalletTopupServiceProvider);
  return CustomerWalletTopupNotifier(service);
});

/// Notifier for managing wallet top-up operations
class CustomerWalletTopupNotifier extends StateNotifier<CustomerWalletTopupState> {
  final CustomerWalletTopupService _service;

  CustomerWalletTopupNotifier(this._service) : super(const CustomerWalletTopupState());

  /// Process wallet top-up with Stripe
  Future<void> processTopUp({
    required double amount,
    bool savePaymentMethod = false,
  }) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);

    try {
      debugPrint('🔍 [WALLET-TOPUP] Processing top-up: RM $amount');

      // Step 1: Create payment intent
      final paymentIntentData = await _service.createPaymentIntent(
        amount: amount,
        savePaymentMethod: savePaymentMethod,
      );

      final clientSecret = paymentIntentData['client_secret'] as String;
      final transactionId = paymentIntentData['transaction_id'] as String;

      debugPrint('🔍 [WALLET-TOPUP] Payment intent created: $transactionId');

      // Step 2: Confirm payment with Stripe
      final paymentMethod = stripe.PaymentMethodParams.card(
        paymentMethodData: stripe.PaymentMethodData(
          billingDetails: stripe.BillingDetails(
            email: Supabase.instance.client.auth.currentUser?.email,
          ),
        ),
      );

      await stripe.Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: paymentMethod,
      );

      debugPrint('🔍 [WALLET-TOPUP] Payment confirmed successfully');

      // If we reach here without exception, payment was successful
      state = state.copyWith(
        isProcessing: false,
        lastTransactionId: transactionId,
      );
      debugPrint('✅ [WALLET-TOPUP] Top-up successful');
    } catch (e) {
      debugPrint('❌ [WALLET-TOPUP] Payment error: $e');
      state = state.copyWith(
        isProcessing: false,
        errorMessage: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  /// Process wallet top-up with saved payment method
  Future<void> processTopUpWithSavedMethod({
    required double amount,
    required String paymentMethodId,
  }) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);

    try {
      debugPrint('🔍 [WALLET-TOPUP] Processing top-up with saved method: RM $amount');

      // Step 1: Create payment intent with saved payment method
      final paymentIntentData = await _service.createPaymentIntentWithSavedMethod(
        amount: amount,
        paymentMethodId: paymentMethodId,
      );

      final clientSecret = paymentIntentData['client_secret'] as String;
      final transactionId = paymentIntentData['transaction_id'] as String;
      final requiresAction = paymentIntentData['requires_action'] as bool? ?? false;

      debugPrint('🔍 [WALLET-TOPUP] Payment intent created: $transactionId');

      if (requiresAction) {
        // Handle 3D Secure or other authentication
        await stripe.Stripe.instance.confirmPayment(
          paymentIntentClientSecret: clientSecret,
          data: const stripe.PaymentMethodParams.card(
            paymentMethodData: stripe.PaymentMethodData(),
          ),
        );
      }

      debugPrint('🔍 [WALLET-TOPUP] Payment confirmed successfully');

      // If we reach here without exception, payment was successful
      state = state.copyWith(
        isProcessing: false,
        lastTransactionId: transactionId,
      );
      debugPrint('✅ [WALLET-TOPUP] Top-up with saved method successful');
    } catch (e) {
      debugPrint('❌ [WALLET-TOPUP] Payment error with saved method: $e');
      state = state.copyWith(
        isProcessing: false,
        errorMessage: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Reset state
  void reset() {
    state = const CustomerWalletTopupState();
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('card') && errorString.contains('declined')) {
      return 'Your card was declined. Please try a different payment method.';
    } else if (errorString.contains('insufficient')) {
      return 'Your card has insufficient funds.';
    } else if (errorString.contains('expired')) {
      return 'Your card has expired. Please use a different card.';
    } else if (errorString.contains('cvc') || errorString.contains('security')) {
      return 'Your card\'s security code is incorrect.';
    } else if (errorString.contains('invalid') && errorString.contains('number')) {
      return 'Your card number is invalid.';
    } else if (errorString.contains('processing')) {
      return 'An error occurred while processing your card. Please try again.';
    } else {
      return 'Payment failed. Please check your card details and try again.';
    }
  }
}
