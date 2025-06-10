import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payment_method.dart' as app_payment;
import '../../../orders/data/models/order.dart';

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? errorMessage;
  final app_payment.PaymentStatus status;
  final Map<String, dynamic>? metadata;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.errorMessage,
    required this.status,
    this.metadata,
  });

  factory PaymentResult.success({
    required String transactionId,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResult(
      success: true,
      transactionId: transactionId,
      status: app_payment.PaymentStatus.completed,
      metadata: metadata,
    );
  }

  factory PaymentResult.failure({
    required String errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResult(
      success: false,
      errorMessage: errorMessage,
      status: app_payment.PaymentStatus.failed,
      metadata: metadata,
    );
  }

  factory PaymentResult.pending({
    String? transactionId,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResult(
      success: false,
      transactionId: transactionId,
      status: app_payment.PaymentStatus.pending,
      metadata: metadata,
    );
  }
}

class PaymentService {
  static const String _billplzApiUrl = 'https://www.billplz.com/api/v3';
  static const String _billplzSandboxUrl = 'https://www.billplz-sandbox.com/api/v3';
  
  // These should be loaded from environment variables or secure storage
  static const String _billplzApiKey = 'your-billplz-api-key';
  static const String _collectionId = 'your-collection-id';
  
  final bool _isProduction;
  final http.Client _httpClient;

  PaymentService({
    bool isProduction = false,
    http.Client? httpClient,
  }) : _isProduction = isProduction,
       _httpClient = httpClient ?? http.Client();

  String get _baseUrl => _isProduction ? _billplzApiUrl : _billplzSandboxUrl;



  // Get available payment methods
  Future<List<app_payment.PaymentMethod>> getAvailablePaymentMethods() async {
    // In a real implementation, this would fetch from your backend
    return [
      const app_payment.PaymentMethod(
        id: 'fpx',
        type: app_payment.PaymentMethodType.fpx,
        name: 'FPX',
        displayName: 'Online Banking (FPX)',
        description: 'Pay directly from your bank account',
        minimumAmount: 1.0,
        maximumAmount: 30000.0,
      ),
      const app_payment.PaymentMethod(
        id: 'credit_card',
        type: app_payment.PaymentMethodType.creditCard,
        name: 'Credit Card',
        displayName: 'Credit/Debit Card',
        description: 'Visa, Mastercard, American Express',
        minimumAmount: 1.0,
        processingFee: 0.034, // 3.4% + RM 0.50
      ),
      const app_payment.PaymentMethod(
        id: 'grabpay',
        type: app_payment.PaymentMethodType.grabPay,
        name: 'GrabPay',
        displayName: 'GrabPay Wallet',
        description: 'Pay with your GrabPay wallet',
        minimumAmount: 1.0,
        maximumAmount: 1500.0,
      ),
      const app_payment.PaymentMethod(
        id: 'touchngo',
        type: app_payment.PaymentMethodType.touchNGo,
        name: 'TouchNGo',
        displayName: 'Touch \'n Go eWallet',
        description: 'Pay with your Touch \'n Go eWallet',
        minimumAmount: 1.0,
        maximumAmount: 999.0,
      ),
      const app_payment.PaymentMethod(
        id: 'boost',
        type: app_payment.PaymentMethodType.boost,
        name: 'Boost',
        displayName: 'Boost Wallet',
        description: 'Pay with your Boost wallet',
        minimumAmount: 1.0,
        maximumAmount: 1500.0,
      ),
    ];
  }

  // Process FPX Payment via Billplz
  Future<PaymentResult> processFPXPayment({
    required Order order,
    required String bankCode,
    required String callbackUrl,
    String? redirectUrl,
  }) async {
    try {
      final billData = {
        'collection_id': _collectionId,
        'email': 'customer@example.com', // TODO: Get customer email from customer record
        'name': order.customerName,
        'amount': (order.totalAmount * 100).toInt().toString(), // Convert to cents
        'description': 'Order ${order.orderNumber}',
        'callback_url': callbackUrl,
        'reference_1_label': 'Bank Code',
        'reference_1': bankCode,
        'reference_2_label': 'Order ID',
        'reference_2': order.id,
      };

      if (redirectUrl != null) {
        billData['redirect_url'] = redirectUrl;
      }

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/bills'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_billplzApiKey:'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: billData,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final billUrl = responseData['url'];
        
        return PaymentResult.pending(
          transactionId: responseData['id'],
          metadata: {
            'bill_url': '$billUrl?auto_submit=true',
            'bill_id': responseData['id'],
            'payment_method': 'fpx',
            'bank_code': bankCode,
          },
        );
      } else {
        return PaymentResult.failure(
          errorMessage: 'Failed to create Billplz bill: ${response.body}',
        );
      }
    } catch (e) {
      return PaymentResult.failure(
        errorMessage: 'FPX payment error: $e',
      );
    }
  }

  // Create Payment Intent via Supabase Edge Function
  Future<Map<String, dynamic>> createPaymentIntent({
    required String orderId,
    required double amount,
    String currency = 'myr',
  }) async {
    try {
      debugPrint('PaymentService: Creating payment intent for order $orderId, amount: $amount');

      final response = await Supabase.instance.client.functions.invoke(
        'process-payment',
        body: {
          'order_id': orderId,
          'amount': amount,
          'currency': currency,
          'payment_method': 'credit_card',
        },
      );

      debugPrint('PaymentService: Edge Function response status: ${response.status}');
      debugPrint('PaymentService: Edge Function response data: ${response.data}');

      // Check for response data
      if (response.data == null) {
        throw Exception('Failed to create payment intent: No response data from Edge Function');
      }

      // Check if the response indicates an error
      if (response.data is Map && response.data['success'] == false) {
        final errorMessage = response.data['error'] ?? 'Unknown error from payment service';
        throw Exception('Payment service error: $errorMessage');
      }

      // For development/testing, create a mock response if Edge Function is not available
      if (response.status != 200) {
        debugPrint('PaymentService: Edge Function not available (status: ${response.status}), using mock response');
        return _createMockPaymentIntent(orderId, amount, currency);
      }

      return response.data;
    } catch (e) {
      debugPrint('PaymentService: Error creating payment intent: $e');

      // Check if this is a network/deployment issue and provide fallback
      if (e.toString().contains('FunctionsException') ||
          e.toString().contains('404') ||
          e.toString().contains('not found')) {
        debugPrint('PaymentService: Edge Function not deployed, using mock payment intent for testing');
        return _createMockPaymentIntent(orderId, amount, currency);
      }

      throw Exception('Error creating payment intent: $e');
    }
  }

  // Mock payment intent for development/testing when Edge Function is not available
  Map<String, dynamic> _createMockPaymentIntent(String orderId, double amount, String currency) {
    final mockClientSecret = 'pi_mock_${DateTime.now().millisecondsSinceEpoch}_secret_mock';
    final mockTransactionId = 'pi_mock_${DateTime.now().millisecondsSinceEpoch}';

    debugPrint('PaymentService: Created mock payment intent - client_secret: $mockClientSecret');

    return {
      'success': true,
      'client_secret': mockClientSecret,
      'transaction_id': mockTransactionId,
      'status': 'pending',
      'metadata': {
        'gateway': 'stripe_mock',
        'payment_method': 'credit_card',
        'order_id': orderId,
        'amount': amount,
        'currency': currency,
        'mock': true,
      }
    };
  }

  // Process Credit Card Payment via Stripe
  Future<PaymentResult> processCreditCardPayment({
    required Order order,
    required String paymentMethodId,
  }) async {
    try {
      // This method is now deprecated in favor of the new Stripe flow
      // Use createPaymentIntent + Stripe.instance.confirmPayment instead
      return PaymentResult.failure(
        errorMessage: 'Use the new Stripe payment flow with createPaymentIntent',
      );
    } catch (e) {
      return PaymentResult.failure(
        errorMessage: 'Credit card payment error: $e',
      );
    }
  }

  // Process E-wallet Payment
  Future<PaymentResult> processEWalletPayment({
    required Order order,
    required app_payment.PaymentMethodType walletType,
    required String callbackUrl,
    String? redirectUrl,
  }) async {
    try {
      String gatewayCode;
      switch (walletType) {
        case app_payment.PaymentMethodType.grabPay:
          gatewayCode = 'BP-2C2PGRB';
          break;
        case app_payment.PaymentMethodType.touchNGo:
          gatewayCode = 'BP-2C2PTNG';
          break;
        case app_payment.PaymentMethodType.boost:
          gatewayCode = 'BP-2C2PBST';
          break;
        case app_payment.PaymentMethodType.shopeePay:
          gatewayCode = 'BP-2C2PSHPE';
          break;
        default:
          throw Exception('Unsupported e-wallet type: $walletType');
      }

      return await processFPXPayment(
        order: order,
        bankCode: gatewayCode,
        callbackUrl: callbackUrl,
        redirectUrl: redirectUrl,
      );
    } catch (e) {
      return PaymentResult.failure(
        errorMessage: 'E-wallet payment error: $e',
      );
    }
  }

  // Verify payment callback from Billplz
  bool verifyBillplzCallback({
    required Map<String, dynamic> callbackData,
    required String xSignatureKey,
  }) {
    try {
      final xSignature = callbackData.remove('x_signature');
      if (xSignature == null) return false;

      // Sort parameters
      final sortedParams = Map.fromEntries(
        callbackData.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

      // Create source string
      final sourceString = sortedParams.entries
          .map((entry) => '${entry.key}${entry.value}')
          .join('|');

      // Calculate HMAC-SHA256
      final key = utf8.encode(xSignatureKey);
      final bytes = utf8.encode(sourceString);
      final hmacSha256 = Hmac(sha256, key);
      final digest = hmacSha256.convert(bytes);

      return digest.toString() == xSignature;
    } catch (e) {
      debugPrint('Error verifying Billplz callback: $e');
      return false;
    }
  }

  // Get payment transaction status
  Future<app_payment.PaymentTransaction?> getPaymentStatus(String transactionId) async {
    try {
      // In a real implementation, query your backend or payment gateway
      // For now, return mock data
      return app_payment.PaymentTransaction(
        id: transactionId,
        orderId: 'order_123',
        paymentMethodId: 'fpx',
        paymentMethodType: app_payment.PaymentMethodType.fpx,
        status: app_payment.PaymentStatus.completed,
        amount: 100.0,
        currency: 'MYR',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        updatedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error getting payment status: $e');
      return null;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
