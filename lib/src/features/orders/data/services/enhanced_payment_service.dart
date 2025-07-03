import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/enhanced_payment_models.dart';
import '../../../core/utils/logger.dart';
import '../../presentation/providers/enhanced_payment_provider.dart';

/// Enhanced payment service with Stripe and wallet integration
class EnhancedPaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppLogger _logger = AppLogger();

  /// Process payment using selected method
  Future<EnhancedPaymentResult> processPayment({
    required String orderId,
    required PaymentMethodType paymentMethod,
    required double amount,
    String currency = 'MYR',
    stripe.CardFieldInputDetails? cardDetails,
    String? savedCardId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.info('💳 [PAYMENT-SERVICE] Processing payment: $paymentMethod for order: $orderId');

      switch (paymentMethod) {
        case PaymentMethodType.card:
          return await _processCardPayment(
            orderId: orderId,
            amount: amount,
            currency: currency,
            cardDetails: cardDetails,
            savedCardId: savedCardId,
            metadata: metadata,
          );
        
        case PaymentMethodType.wallet:
          return await _processWalletPayment(
            orderId: orderId,
            amount: amount,
            currency: currency,
            metadata: metadata,
          );
        
        case PaymentMethodType.cash:
          return await _processCashPayment(
            orderId: orderId,
            amount: amount,
            currency: currency,
            metadata: metadata,
          );
      }
    } catch (e) {
      _logger.error('❌ [PAYMENT-SERVICE] Payment processing failed', e);
      
      return EnhancedPaymentResult(
        success: false,
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
        processedAt: DateTime.now(),
      );
    }
  }

  /// Process card payment using Stripe
  Future<EnhancedPaymentResult> _processCardPayment({
    required String orderId,
    required double amount,
    required String currency,
    stripe.CardFieldInputDetails? cardDetails,
    String? savedCardId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.info('💳 [PAYMENT-SERVICE] Processing card payment');

      // Step 1: Create payment intent via Edge Function
      final response = await _supabase.functions.invoke(
        'process-payment',
        body: {
          'order_id': orderId,
          'payment_method': 'credit_card',
          'amount': amount,
          'currency': currency,
          'metadata': metadata,
        },
      );

      // Supabase functions throw exceptions on error, no need to check response.error

      final paymentData = response.data;
      final clientSecret = paymentData['client_secret'];

      if (clientSecret == null) {
        throw Exception('No client secret received from payment service');
      }

      // Step 2: Confirm payment with Stripe
      if (savedCardId != null) {
        // Use saved payment method
        await stripe.Stripe.instance.confirmPayment(
          paymentIntentClientSecret: clientSecret,
          data: stripe.PaymentMethodParams.cardFromMethodId(
            paymentMethodData: stripe.PaymentMethodDataCardFromMethod(
              paymentMethodId: savedCardId,
            ),
          ),
        );
      } else {
        // Use card field for new payment - simplified approach
        // TODO: Implement proper card field integration
        // For now, this will require the payment to be handled by the UI layer
        throw Exception('Card payment requires UI integration with CardField widget');
      }

      _logger.info('✅ [PAYMENT-SERVICE] Card payment confirmed');

      return EnhancedPaymentResult(
        success: true,
        transactionId: paymentData['transaction_id'],
        clientSecret: clientSecret,
        status: PaymentStatus.completed,
        metadata: paymentData['metadata'],
        processedAt: DateTime.now(),
      );

    } catch (e) {
      _logger.error('❌ [PAYMENT-SERVICE] Card payment failed', e);
      
      return EnhancedPaymentResult(
        success: false,
        status: PaymentStatus.failed,
        errorMessage: _getStripeErrorMessage(e),
        processedAt: DateTime.now(),
      );
    }
  }

  /// Process wallet payment
  Future<EnhancedPaymentResult> _processWalletPayment({
    required String orderId,
    required double amount,
    required String currency,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.info('💰 [PAYMENT-SERVICE] Processing wallet payment');

      // Step 1: Check wallet balance
      final walletBalance = await getWalletBalance();
      if (walletBalance < amount) {
        throw Exception('Insufficient wallet balance');
      }

      // Step 2: Process wallet payment via Edge Function
      final response = await _supabase.functions.invoke(
        'process-wallet-payment',
        body: {
          'order_id': orderId,
          'amount': amount,
          'currency': currency,
          'metadata': metadata,
        },
      );

      // Supabase functions throw exceptions on error, no need to check response.error

      final paymentData = response.data;

      _logger.info('✅ [PAYMENT-SERVICE] Wallet payment completed');

      return EnhancedPaymentResult(
        success: true,
        transactionId: paymentData['transaction_id'],
        status: PaymentStatus.completed,
        metadata: paymentData['metadata'],
        processedAt: DateTime.now(),
      );

    } catch (e) {
      _logger.error('❌ [PAYMENT-SERVICE] Wallet payment failed', e);
      
      return EnhancedPaymentResult(
        success: false,
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
        processedAt: DateTime.now(),
      );
    }
  }

  /// Process cash on delivery payment
  Future<EnhancedPaymentResult> _processCashPayment({
    required String orderId,
    required double amount,
    required String currency,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.info('💵 [PAYMENT-SERVICE] Processing cash payment');

      // Create cash payment record
      final response = await _supabase.functions.invoke(
        'process-cash-payment',
        body: {
          'order_id': orderId,
          'amount': amount,
          'currency': currency,
          'metadata': metadata,
        },
      );

      // Supabase functions throw exceptions on error, no need to check response.error

      final paymentData = response.data;

      _logger.info('✅ [PAYMENT-SERVICE] Cash payment setup completed');

      return EnhancedPaymentResult(
        success: true,
        transactionId: paymentData['transaction_id'],
        status: PaymentStatus.pending,
        metadata: paymentData['metadata'],
        processedAt: DateTime.now(),
      );

    } catch (e) {
      _logger.error('❌ [PAYMENT-SERVICE] Cash payment setup failed', e);
      
      return EnhancedPaymentResult(
        success: false,
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
        processedAt: DateTime.now(),
      );
    }
  }

  /// Get user's wallet balance
  Future<double> getWalletBalance() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('stakeholder_wallets')
          .select('available_balance')
          .eq('user_id', user.id)
          .single();

      return (response['available_balance'] as num).toDouble();
    } catch (e) {
      _logger.error('❌ [PAYMENT-SERVICE] Failed to get wallet balance', e);
      return 0.0;
    }
  }

  /// Get saved payment methods
  Future<List<SavedPaymentMethod>> getSavedPaymentMethods() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('saved_payment_methods')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response.map((json) => SavedPaymentMethod.fromJson(json)).toList();
    } catch (e) {
      _logger.error('❌ [PAYMENT-SERVICE] Failed to get saved payment methods', e);
      return [];
    }
  }

  /// Save payment method for future use
  Future<void> savePaymentMethod({
    required String stripePaymentMethodId,
    required String brand,
    required String last4,
    required int expiryMonth,
    required int expiryYear,
    bool setAsDefault = false,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // If setting as default, unset other default methods
      if (setAsDefault) {
        await _supabase
            .from('saved_payment_methods')
            .update({'is_default': false})
            .eq('user_id', user.id);
      }

      await _supabase.from('saved_payment_methods').insert({
        'user_id': user.id,
        'stripe_payment_method_id': stripePaymentMethodId,
        'brand': brand,
        'last4': last4,
        'expiry_month': expiryMonth,
        'expiry_year': expiryYear,
        'is_default': setAsDefault,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      _logger.info('✅ [PAYMENT-SERVICE] Payment method saved');
    } catch (e) {
      _logger.error('❌ [PAYMENT-SERVICE] Failed to save payment method', e);
      throw Exception('Failed to save payment method: $e');
    }
  }

  /// Delete saved payment method
  Future<void> deleteSavedPaymentMethod(String paymentMethodId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('saved_payment_methods')
          .update({'is_active': false})
          .eq('id', paymentMethodId)
          .eq('user_id', user.id);

      _logger.info('✅ [PAYMENT-SERVICE] Payment method deleted');
    } catch (e) {
      _logger.error('❌ [PAYMENT-SERVICE] Failed to delete payment method', e);
      throw Exception('Failed to delete payment method: $e');
    }
  }

  /// Get payment status
  Future<PaymentStatus> getPaymentStatus(String transactionId) async {
    try {
      final response = await _supabase
          .from('payment_transactions')
          .select('status')
          .eq('id', transactionId)
          .single();

      return PaymentStatus.fromString(response['status']);
    } catch (e) {
      _logger.error('❌ [PAYMENT-SERVICE] Failed to get payment status', e);
      return PaymentStatus.unknown;
    }
  }

  /// Top up wallet
  Future<EnhancedPaymentResult> topUpWallet({
    required double amount,
    required stripe.CardFieldInputDetails cardDetails,
    String currency = 'MYR',
  }) async {
    try {
      _logger.info('💰 [PAYMENT-SERVICE] Processing wallet top-up: $amount');

      // TODO: Implement proper wallet top-up with Supabase Edge Function
      // await _supabase.functions.invoke('wallet-topup', body: {'amount': amount, 'currency': currency});

      // TODO: Implement proper card field integration for wallet top-up
      // For now, this will require the payment to be handled by the UI layer
      throw Exception('Wallet top-up requires UI integration with CardField widget');

    } catch (e) {
      _logger.error('❌ [PAYMENT-SERVICE] Wallet top-up failed', e);
      
      return EnhancedPaymentResult(
        success: false,
        status: PaymentStatus.failed,
        errorMessage: _getStripeErrorMessage(e),
        processedAt: DateTime.now(),
      );
    }
  }

  /// Get user-friendly error message from Stripe error
  String _getStripeErrorMessage(dynamic error) {
    if (error is stripe.StripeException) {
      // Use the localized message if available, otherwise provide a generic message
      return error.error.localizedMessage ??
             'Payment failed. Please check your payment details and try again.';
    } else if (error is Exception) {
      return error.toString();
    } else {
      return 'An unexpected error occurred during payment processing.';
    }
  }
}
