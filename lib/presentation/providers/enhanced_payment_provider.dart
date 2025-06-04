import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/debug_logger.dart';
import 'enhanced_order_provider.dart'; // For supabaseProvider

// Enhanced Payment Management with Edge Functions

// Payment Request Model
class PaymentRequest {
  final String orderId;
  final String paymentMethod;
  final double amount;
  final String currency;
  final Map<String, dynamic>? gatewayData;
  final String? callbackUrl;
  final String? redirectUrl;

  PaymentRequest({
    required this.orderId,
    required this.paymentMethod,
    required this.amount,
    this.currency = 'MYR',
    this.gatewayData,
    this.callbackUrl,
    this.redirectUrl,
  });

  Map<String, dynamic> toJson() => {
    'order_id': orderId,
    'payment_method': paymentMethod,
    'amount': amount,
    'currency': currency,
    'gateway_data': gatewayData,
    'callback_url': callbackUrl,
    'redirect_url': redirectUrl,
  };
}

// Payment Result Model
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? paymentUrl;
  final String status;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.paymentUrl,
    required this.status,
    this.errorMessage,
    this.metadata,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['success'] ?? false,
      transactionId: json['transaction_id'],
      paymentUrl: json['payment_url'],
      status: json['status'] ?? 'failed',
      errorMessage: json['error_message'],
      metadata: json['metadata'],
    );
  }
}

// Payment State
class PaymentState {
  final bool isProcessing;
  final String? errorMessage;
  final PaymentResult? lastResult;
  final List<PaymentTransaction> transactions;

  PaymentState({
    this.isProcessing = false,
    this.errorMessage,
    this.lastResult,
    this.transactions = const [],
  });

  PaymentState copyWith({
    bool? isProcessing,
    String? errorMessage,
    PaymentResult? lastResult,
    List<PaymentTransaction>? transactions,
  }) {
    return PaymentState(
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage,
      lastResult: lastResult ?? this.lastResult,
      transactions: transactions ?? this.transactions,
    );
  }
}

// Payment Transaction Model
class PaymentTransaction {
  final String id;
  final String orderId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String paymentGateway;
  final String? gatewayTransactionId;
  final String status;
  final String? failureReason;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.paymentGateway,
    this.gatewayTransactionId,
    required this.status,
    this.failureReason,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'],
      orderId: json['order_id'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'MYR',
      paymentMethod: json['payment_method'],
      paymentGateway: json['payment_gateway'],
      gatewayTransactionId: json['gateway_transaction_id'],
      status: json['status'],
      failureReason: json['failure_reason'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

// Enhanced Payment Notifier with Edge Functions
class EnhancedPaymentNotifier extends StateNotifier<PaymentState> {
  final SupabaseClient _supabase;
  final Ref _ref;

  EnhancedPaymentNotifier(this._supabase, this._ref) : super(PaymentState());

  // Process payment using mock processing (Edge Function not available)
  Future<PaymentResult?> processPayment(PaymentRequest request) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);

    try {
      DebugLogger.info('Processing payment with mock processor (Edge Function not available)', tag: 'EnhancedPaymentNotifier');
      DebugLogger.info('Payment request: ${request.toJson()}', tag: 'EnhancedPaymentNotifier');

      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock payment processing logic
      final paymentResult = _mockPaymentProcessing(request);

      if (!paymentResult.success) {
        throw Exception(paymentResult.errorMessage ?? 'Payment failed');
      }

      // Update local state
      state = state.copyWith(
        isProcessing: false,
        lastResult: paymentResult,
      );

      DebugLogger.success('Payment processed successfully (mock): ${paymentResult.transactionId}', tag: 'EnhancedPaymentNotifier');
      return paymentResult;

    } catch (e) {
      DebugLogger.error('Error processing payment: $e', tag: 'EnhancedPaymentNotifier');
      state = state.copyWith(
        isProcessing: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  // Mock payment processing for testing
  PaymentResult _mockPaymentProcessing(PaymentRequest request) {
    // Generate mock transaction ID
    final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';

    // Simulate different payment method behaviors
    switch (request.paymentMethod) {
      case 'fpx':
        return PaymentResult(
          success: true,
          transactionId: transactionId,
          paymentUrl: 'https://mock-fpx-gateway.com/pay/$transactionId',
          status: 'pending',
          metadata: {
            'bank_code': request.gatewayData?['bank_code'] ?? 'maybank',
            'payment_method': 'fpx',
          },
        );

      case 'credit_card':
        return PaymentResult(
          success: true,
          transactionId: transactionId,
          status: 'completed',
          metadata: {
            'payment_method_id': request.gatewayData?['payment_method_id'],
            'payment_method': 'credit_card',
          },
        );

      case 'grabpay':
      case 'tng':
      case 'boost':
      case 'shopeepay':
        return PaymentResult(
          success: true,
          transactionId: transactionId,
          paymentUrl: 'https://mock-${request.paymentMethod}-gateway.com/pay/$transactionId',
          status: 'pending',
          metadata: {
            'payment_method': request.paymentMethod,
            'wallet_type': request.paymentMethod,
          },
        );

      default:
        return PaymentResult(
          success: false,
          status: 'failed',
          errorMessage: 'Unsupported payment method: ${request.paymentMethod}',
        );
    }
  }

  // Process FPX Payment
  Future<PaymentResult?> processFPXPayment({
    required String orderId,
    required double amount,
    required String bankCode,
    String? callbackUrl,
    String? redirectUrl,
  }) async {
    final request = PaymentRequest(
      orderId: orderId,
      paymentMethod: 'fpx',
      amount: amount,
      gatewayData: {'bank_code': bankCode},
      callbackUrl: callbackUrl,
      redirectUrl: redirectUrl,
    );

    return await processPayment(request);
  }

  // Process Credit Card Payment
  Future<PaymentResult?> processCreditCardPayment({
    required String orderId,
    required double amount,
    required String paymentMethodId,
  }) async {
    final request = PaymentRequest(
      orderId: orderId,
      paymentMethod: 'credit_card',
      amount: amount,
      gatewayData: {'payment_method_id': paymentMethodId},
    );

    return await processPayment(request);
  }

  // Process E-wallet Payment
  Future<PaymentResult?> processEWalletPayment({
    required String orderId,
    required double amount,
    required String walletType, // 'grabpay', 'tng', 'boost', 'shopeepay'
    String? callbackUrl,
    String? redirectUrl,
  }) async {
    final request = PaymentRequest(
      orderId: orderId,
      paymentMethod: walletType,
      amount: amount,
      callbackUrl: callbackUrl,
      redirectUrl: redirectUrl,
    );

    return await processPayment(request);
  }

  // Load payment transactions for an order
  Future<void> loadPaymentTransactions(String orderId) async {
    try {
      final response = await _supabase
          .from('payment_transactions')
          .select('*')
          .eq('order_id', orderId)
          .order('created_at', ascending: false);

      final transactions = (response as List)
          .map((json) => PaymentTransaction.fromJson(json))
          .toList();

      state = state.copyWith(transactions: transactions);

    } catch (e) {
      DebugLogger.error('Error loading payment transactions: $e', tag: 'EnhancedPaymentNotifier');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // Handle payment webhook (for testing)
  Future<void> handlePaymentWebhook(Map<String, dynamic> webhookData) async {
    try {
      DebugLogger.info('Handling payment webhook: $webhookData', tag: 'EnhancedPaymentNotifier');

      final transactionId = webhookData['transaction_id'] as String?;
      final status = webhookData['status'] as String?;

      if (transactionId != null && status != null) {
        // Update transaction status in database
        await _supabase
            .from('payment_transactions')
            .update({
              'status': status,
              'gateway_transaction_id': webhookData['gateway_transaction_id'],
              'webhook_data': webhookData,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', transactionId);

        DebugLogger.success('Payment webhook processed successfully', tag: 'EnhancedPaymentNotifier');
      }

    } catch (e) {
      DebugLogger.error('Error handling payment webhook: $e', tag: 'EnhancedPaymentNotifier');
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Enhanced Payment Provider
final enhancedPaymentProvider = StateNotifierProvider<EnhancedPaymentNotifier, PaymentState>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return EnhancedPaymentNotifier(supabase, ref);
});

// Payment Transactions Provider for specific order
final paymentTransactionsProvider = FutureProvider.family<List<PaymentTransaction>, String>((ref, orderId) async {
  final supabase = ref.watch(supabaseProvider);
  
  final response = await supabase
      .from('payment_transactions')
      .select('*')
      .eq('order_id', orderId)
      .order('created_at', ascending: false);

  return (response as List)
      .map((json) => PaymentTransaction.fromJson(json))
      .toList();
});

// Payment Methods Provider (available payment methods)
final availablePaymentMethodsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {
      'id': 'fpx',
      'name': 'FPX Online Banking',
      'icon': 'assets/icons/fpx.png',
      'description': 'Pay directly from your bank account',
      'enabled': true,
    },
    {
      'id': 'credit_card',
      'name': 'Credit/Debit Card',
      'icon': 'assets/icons/card.png',
      'description': 'Visa, Mastercard, American Express',
      'enabled': true,
    },
    {
      'id': 'grabpay',
      'name': 'GrabPay',
      'icon': 'assets/icons/grabpay.png',
      'description': 'Pay with GrabPay wallet',
      'enabled': true,
    },
    {
      'id': 'tng',
      'name': 'Touch \'n Go eWallet',
      'icon': 'assets/icons/tng.png',
      'description': 'Pay with Touch \'n Go eWallet',
      'enabled': true,
    },
    {
      'id': 'boost',
      'name': 'Boost',
      'icon': 'assets/icons/boost.png',
      'description': 'Pay with Boost wallet',
      'enabled': true,
    },
    {
      'id': 'shopeepay',
      'name': 'ShopeePay',
      'icon': 'assets/icons/shopeepay.png',
      'description': 'Pay with ShopeePay wallet',
      'enabled': true,
    },
  ];
});
