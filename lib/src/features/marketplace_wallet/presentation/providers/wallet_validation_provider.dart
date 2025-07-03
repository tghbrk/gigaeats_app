import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../orders/data/models/order.dart';
import '../../data/services/enhanced_customer_wallet_service.dart';

/// Wallet validation state
class WalletValidationState {
  final bool isValidating;
  final WalletValidationResult? validationResult;
  final SplitPaymentCalculation? splitPayment;
  final String? errorMessage;
  final PaymentOptions? paymentOptions;

  const WalletValidationState({
    this.isValidating = false,
    this.validationResult,
    this.splitPayment,
    this.errorMessage,
    this.paymentOptions,
  });

  WalletValidationState copyWith({
    bool? isValidating,
    WalletValidationResult? validationResult,
    SplitPaymentCalculation? splitPayment,
    String? errorMessage,
    PaymentOptions? paymentOptions,
  }) {
    return WalletValidationState(
      isValidating: isValidating ?? this.isValidating,
      validationResult: validationResult ?? this.validationResult,
      splitPayment: splitPayment ?? this.splitPayment,
      errorMessage: errorMessage ?? this.errorMessage,
      paymentOptions: paymentOptions ?? this.paymentOptions,
    );
  }

  bool get isValid => validationResult?.isValid ?? false;
  bool get hasError => errorMessage != null || (validationResult?.isValid == false);
  bool get canPayFully => splitPayment?.canPayFully ?? false;
  bool get needsTopUp => splitPayment?.needsTopUp ?? false;
  double get shortfall => validationResult?.shortfall ?? 0.0;
  String get formattedShortfall => validationResult?.formattedShortfall ?? 'RM 0.00';

  // Additional getters for compatibility
  bool get isLoading => isValidating;
  String? get error => errorMessage;
}

/// Wallet validation notifier
class WalletValidationNotifier extends StateNotifier<WalletValidationState> {
  final EnhancedCustomerWalletService _service;

  WalletValidationNotifier(this._service) : super(const WalletValidationState());

  /// Validate wallet for payment amount
  Future<void> validatePayment({
    required double amount,
    String transactionType = 'payment',
  }) async {
    if (amount <= 0) {
      state = state.copyWith(
        errorMessage: 'Invalid payment amount',
        validationResult: null,
        splitPayment: null,
      );
      return;
    }

    state = state.copyWith(
      isValidating: true,
      errorMessage: null,
    );

    try {
      debugPrint('🔍 [WALLET-VALIDATION] Validating payment: RM ${amount.toStringAsFixed(2)}');

      // Validate wallet for transaction
      final validationResult = await _service.validateWalletForTransaction(
        amount: amount,
        transactionType: transactionType,
      );

      // Calculate split payment options
      final splitPaymentResult = await _service.calculateSplitPayment(amount);

      validationResult.fold(
        (failure) {
          debugPrint('❌ [WALLET-VALIDATION] Validation failed: ${failure.message}');
          state = state.copyWith(
            isValidating: false,
            errorMessage: failure.message,
          );
        },
        (validation) {
          splitPaymentResult.fold(
            (failure) {
              debugPrint('❌ [WALLET-VALIDATION] Split payment calculation failed: ${failure.message}');
              state = state.copyWith(
                isValidating: false,
                validationResult: validation,
                errorMessage: failure.message,
              );
            },
            (splitPayment) {
              debugPrint('✅ [WALLET-VALIDATION] Validation complete - Valid: ${validation.isValid}');
              state = state.copyWith(
                isValidating: false,
                validationResult: validation,
                splitPayment: splitPayment,
                errorMessage: null,
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('❌ [WALLET-VALIDATION] Validation error: $e');
      state = state.copyWith(
        isValidating: false,
        errorMessage: 'Failed to validate payment: $e',
      );
    }
  }

  /// Validate wallet for order payment
  Future<void> validateOrderPayment(Order order) async {
    await validatePayment(
      amount: order.totalAmount,
      transactionType: 'order_payment',
    );
  }

  /// Check if wallet has sufficient balance
  Future<bool> hasSufficientBalance(double amount) async {
    try {
      final result = await _service.hasSufficientBalance(amount);
      return result.fold(
        (failure) {
          debugPrint('❌ [WALLET-VALIDATION] Balance check failed: ${failure.message}');
          return false;
        },
        (hasSufficient) => hasSufficient,
      );
    } catch (e) {
      debugPrint('❌ [WALLET-VALIDATION] Balance check error: $e');
      return false;
    }
  }

  /// Get payment options for amount
  Future<PaymentOptions> getPaymentOptions(double amount) async {
    try {
      final splitResult = await _service.calculateSplitPayment(amount);
      return splitResult.fold(
        (failure) => PaymentOptions.cardOnly(amount),
        (splitPayment) => PaymentOptions.fromSplitPayment(splitPayment),
      );
    } catch (e) {
      debugPrint('❌ [WALLET-VALIDATION] Payment options error: $e');
      return PaymentOptions.cardOnly(amount);
    }
  }

  /// Clear validation state
  void clearValidation() {
    state = const WalletValidationState();
  }
}

/// Payment options based on wallet balance
class PaymentOptions {
  final double totalAmount;
  final double walletAmount;
  final double cardAmount;
  final bool canPayWithWalletOnly;
  final bool needsCard;
  final bool needsTopUp;
  final double suggestedTopUp;

  const PaymentOptions({
    required this.totalAmount,
    required this.walletAmount,
    required this.cardAmount,
    required this.canPayWithWalletOnly,
    required this.needsCard,
    required this.needsTopUp,
    required this.suggestedTopUp,
  });

  factory PaymentOptions.fromSplitPayment(SplitPaymentCalculation split) {
    return PaymentOptions(
      totalAmount: split.requestedAmount,
      walletAmount: split.walletAmount,
      cardAmount: split.remainingAmount,
      canPayWithWalletOnly: split.canPayFully,
      needsCard: split.remainingAmount > 0,
      needsTopUp: split.needsTopUp,
      suggestedTopUp: split.suggestedTopUp,
    );
  }

  factory PaymentOptions.cardOnly(double amount) {
    return PaymentOptions(
      totalAmount: amount,
      walletAmount: 0.0,
      cardAmount: amount,
      canPayWithWalletOnly: false,
      needsCard: true,
      needsTopUp: false,
      suggestedTopUp: 0.0,
    );
  }

  String get formattedWalletAmount => 'RM ${walletAmount.toStringAsFixed(2)}';
  String get formattedCardAmount => 'RM ${cardAmount.toStringAsFixed(2)}';
  String get formattedSuggestedTopUp => 'RM ${suggestedTopUp.toStringAsFixed(2)}';
}

/// Enhanced customer wallet service provider
final enhancedCustomerWalletServiceProvider = Provider<EnhancedCustomerWalletService>((ref) {
  return EnhancedCustomerWalletService();
});

/// Wallet validation provider
final walletValidationProvider = StateNotifierProvider<WalletValidationNotifier, WalletValidationState>((ref) {
  final service = ref.watch(enhancedCustomerWalletServiceProvider);
  return WalletValidationNotifier(service);
});

/// Quick balance check provider
final walletBalanceCheckProvider = FutureProvider.family<bool, double>((ref, amount) async {
  final service = ref.watch(enhancedCustomerWalletServiceProvider);
  final result = await service.hasSufficientBalance(amount);
  return result.fold(
    (failure) => false,
    (hasSufficient) => hasSufficient,
  );
});

/// Payment options provider
final paymentOptionsProvider = FutureProvider.family<PaymentOptions, double>((ref, amount) async {
  final notifier = ref.read(walletValidationProvider.notifier);
  return notifier.getPaymentOptions(amount);
});
