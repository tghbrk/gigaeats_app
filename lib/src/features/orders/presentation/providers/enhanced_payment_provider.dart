import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enhanced_payment_models.dart';
import '../../data/services/enhanced_payment_service.dart';
import '../../../core/utils/logger.dart';

/// Enhanced payment state
class EnhancedPaymentState {
  final List<SavedPaymentMethod> savedCards;
  final double? walletBalance;
  final List<PaymentMethodConfig> availablePaymentMethods;
  final bool isLoading;
  final String? error;
  final PaymentTransaction? currentTransaction;
  final DateTime lastUpdated;

  const EnhancedPaymentState({
    this.savedCards = const [],
    this.walletBalance,
    this.availablePaymentMethods = const [],
    this.isLoading = false,
    this.error,
    this.currentTransaction,
    required this.lastUpdated,
  });

  EnhancedPaymentState copyWith({
    List<SavedPaymentMethod>? savedCards,
    double? walletBalance,
    List<PaymentMethodConfig>? availablePaymentMethods,
    bool? isLoading,
    String? error,
    PaymentTransaction? currentTransaction,
    DateTime? lastUpdated,
  }) {
    return EnhancedPaymentState(
      savedCards: savedCards ?? this.savedCards,
      walletBalance: walletBalance ?? this.walletBalance,
      availablePaymentMethods: availablePaymentMethods ?? this.availablePaymentMethods,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentTransaction: currentTransaction ?? this.currentTransaction,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  bool get hasWalletBalance => walletBalance != null && walletBalance! > 0;
  bool get hasSavedCards => savedCards.isNotEmpty;
  
  SavedPaymentMethod? get defaultCard {
    try {
      return savedCards.firstWhere((card) => card.isDefault);
    } catch (e) {
      return savedCards.isNotEmpty ? savedCards.first : null;
    }
  }
}

/// Enhanced payment state notifier
class EnhancedPaymentNotifier extends StateNotifier<EnhancedPaymentState> {
  final EnhancedPaymentService _paymentService;
  final AppLogger _logger = AppLogger();

  EnhancedPaymentNotifier(this._paymentService)
      : super(EnhancedPaymentState(lastUpdated: DateTime.now()));

  /// Load payment methods
  Future<void> loadPaymentMethods() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _logger.info('💳 [PAYMENT-PROVIDER] Loading payment methods');

      final savedCards = await _paymentService.getSavedPaymentMethods();

      state = state.copyWith(
        savedCards: savedCards,
        isLoading: false,
      );

      _logger.info('✅ [PAYMENT-PROVIDER] Loaded ${savedCards.length} saved cards');

    } catch (e) {
      _logger.error('❌ [PAYMENT-PROVIDER] Failed to load payment methods', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load wallet balance
  Future<void> loadWalletBalance() async {
    try {
      _logger.info('💰 [PAYMENT-PROVIDER] Loading wallet balance');

      final balance = await _paymentService.getWalletBalance();

      state = state.copyWith(walletBalance: balance);

      _logger.info('✅ [PAYMENT-PROVIDER] Wallet balance: RM ${balance.toStringAsFixed(2)}');

    } catch (e) {
      _logger.error('❌ [PAYMENT-PROVIDER] Failed to load wallet balance', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Process payment
  Future<EnhancedPaymentResult> processPayment({
    required String orderId,
    required PaymentMethodType paymentMethod,
    required double amount,
    String currency = 'MYR',
    dynamic cardDetails,
    String? savedCardId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _logger.info('💳 [PAYMENT-PROVIDER] Processing payment: $paymentMethod');

      final result = await _paymentService.processPayment(
        orderId: orderId,
        paymentMethod: paymentMethod,
        amount: amount,
        currency: currency,
        cardDetails: cardDetails,
        savedCardId: savedCardId,
        metadata: metadata,
      );

      if (result.success) {
        // Refresh wallet balance if wallet payment was used
        if (paymentMethod == PaymentMethodType.wallet) {
          await loadWalletBalance();
        }
      }

      state = state.copyWith(isLoading: false);

      _logger.info('✅ [PAYMENT-PROVIDER] Payment result: ${result.success}');
      return result;

    } catch (e) {
      _logger.error('❌ [PAYMENT-PROVIDER] Payment processing failed', e);
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return EnhancedPaymentResult.failed(errorMessage: e.toString());
    }
  }

  /// Save payment method
  Future<void> savePaymentMethod({
    required String stripePaymentMethodId,
    required String brand,
    required String last4,
    required int expiryMonth,
    required int expiryYear,
    bool setAsDefault = false,
  }) async {
    try {
      _logger.info('💾 [PAYMENT-PROVIDER] Saving payment method');

      await _paymentService.savePaymentMethod(
        stripePaymentMethodId: stripePaymentMethodId,
        brand: brand,
        last4: last4,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        setAsDefault: setAsDefault,
      );

      // Reload payment methods
      await loadPaymentMethods();

      _logger.info('✅ [PAYMENT-PROVIDER] Payment method saved');

    } catch (e) {
      _logger.error('❌ [PAYMENT-PROVIDER] Failed to save payment method', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete saved payment method
  Future<void> deleteSavedPaymentMethod(String paymentMethodId) async {
    try {
      _logger.info('🗑️ [PAYMENT-PROVIDER] Deleting payment method: $paymentMethodId');

      await _paymentService.deleteSavedPaymentMethod(paymentMethodId);

      // Remove from local state
      final updatedCards = state.savedCards
          .where((card) => card.id != paymentMethodId)
          .toList();

      state = state.copyWith(savedCards: updatedCards);

      _logger.info('✅ [PAYMENT-PROVIDER] Payment method deleted');

    } catch (e) {
      _logger.error('❌ [PAYMENT-PROVIDER] Failed to delete payment method', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Top up wallet
  Future<EnhancedPaymentResult> topUpWallet({
    required double amount,
    required dynamic cardDetails,
    String currency = 'MYR',
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _logger.info('💰 [PAYMENT-PROVIDER] Processing wallet top-up: $amount');

      final result = await _paymentService.topUpWallet(
        amount: amount,
        cardDetails: cardDetails,
        currency: currency,
      );

      if (result.success) {
        // Refresh wallet balance
        await loadWalletBalance();
      }

      state = state.copyWith(isLoading: false);

      _logger.info('✅ [PAYMENT-PROVIDER] Wallet top-up result: ${result.success}');
      return result;

    } catch (e) {
      _logger.error('❌ [PAYMENT-PROVIDER] Wallet top-up failed', e);
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return EnhancedPaymentResult.failed(errorMessage: e.toString());
    }
  }

  /// Get payment status
  Future<PaymentStatus> getPaymentStatus(String transactionId) async {
    try {
      _logger.info('🔍 [PAYMENT-PROVIDER] Getting payment status: $transactionId');

      final status = await _paymentService.getPaymentStatus(transactionId);

      _logger.info('✅ [PAYMENT-PROVIDER] Payment status: ${status.value}');
      return status;

    } catch (e) {
      _logger.error('❌ [PAYMENT-PROVIDER] Failed to get payment status', e);
      return PaymentStatus.unknown;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh all payment data
  Future<void> refresh() async {
    await Future.wait([
      loadPaymentMethods(),
      loadWalletBalance(),
    ]);
  }

  /// Check if payment method is valid for amount
  bool isPaymentMethodValidForAmount(PaymentMethodType method, double amount) {
    switch (method) {
      case PaymentMethodType.wallet:
        return state.walletBalance != null && state.walletBalance! >= amount;
      case PaymentMethodType.card:
        return true; // Card validation happens during payment processing
      case PaymentMethodType.cash:
        return true; // Cash is always valid
    }
  }

  /// Get recommended payment method
  PaymentMethodType getRecommendedPaymentMethod(double amount) {
    // Prefer wallet if sufficient balance
    if (state.hasWalletBalance && state.walletBalance! >= amount) {
      return PaymentMethodType.wallet;
    }

    // Prefer saved card if available
    if (state.hasSavedCards) {
      return PaymentMethodType.card;
    }

    // Default to card
    return PaymentMethodType.card;
  }
}

/// Enhanced payment provider
final enhancedPaymentProvider = StateNotifierProvider<EnhancedPaymentNotifier, EnhancedPaymentState>((ref) {
  final paymentService = ref.watch(enhancedPaymentServiceProvider);
  return EnhancedPaymentNotifier(paymentService);
});

/// Enhanced payment service provider
final enhancedPaymentServiceProvider = Provider<EnhancedPaymentService>((ref) {
  return EnhancedPaymentService();
});

/// Convenience providers
final savedCardsProvider = Provider<List<SavedPaymentMethod>>((ref) {
  return ref.watch(enhancedPaymentProvider).savedCards;
});

final walletBalanceProvider = Provider<double?>((ref) {
  return ref.watch(enhancedPaymentProvider).walletBalance;
});

final defaultCardProvider = Provider<SavedPaymentMethod?>((ref) {
  return ref.watch(enhancedPaymentProvider).defaultCard;
});

final isPaymentLoadingProvider = Provider<bool>((ref) {
  return ref.watch(enhancedPaymentProvider).isLoading;
});

final paymentErrorProvider = Provider<String?>((ref) {
  return ref.watch(enhancedPaymentProvider).error;
});

/// Payment method types
enum PaymentMethodType {
  card,
  wallet,
  cash,
}

extension PaymentMethodTypeExtension on PaymentMethodType {
  String get value {
    switch (this) {
      case PaymentMethodType.card:
        return 'credit_card';
      case PaymentMethodType.wallet:
        return 'wallet';
      case PaymentMethodType.cash:
        return 'cash';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethodType.card:
        return 'Credit/Debit Card';
      case PaymentMethodType.wallet:
        return 'Digital Wallet';
      case PaymentMethodType.cash:
        return 'Cash on Delivery';
    }
  }
}
