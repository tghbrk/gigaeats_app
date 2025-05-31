import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

import '../models/payment_method.dart' as app_payment;
import '../models/order.dart';

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
  static const String _stripePublishableKey = 'your-stripe-publishable-key';
  static const String _collectionId = 'your-collection-id';
  
  final bool _isProduction;
  final http.Client _httpClient;

  PaymentService({
    bool isProduction = false,
    http.Client? httpClient,
  }) : _isProduction = isProduction,
       _httpClient = httpClient ?? http.Client();

  String get _baseUrl => _isProduction ? _billplzApiUrl : _billplzSandboxUrl;

  // Initialize Stripe
  Future<void> initializeStripe() async {
    try {
      stripe.Stripe.publishableKey = _stripePublishableKey;
      await stripe.Stripe.instance.applySettings();
      debugPrint('Stripe initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Stripe: $e');
      rethrow;
    }
  }

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

  // Process Credit Card Payment via Stripe
  Future<PaymentResult> processCreditCardPayment({
    required Order order,
    required String paymentMethodId,
  }) async {
    try {
      // In a real implementation, you would:
      // 1. Create payment intent on your backend
      // 2. Confirm payment with Stripe
      // 3. Handle 3D Secure if required
      
      // For now, simulate the process
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate success/failure
      final random = Random();
      if (random.nextBool()) {
        return PaymentResult.success(
          transactionId: 'stripe_${DateTime.now().millisecondsSinceEpoch}',
          metadata: {
            'payment_method': 'credit_card',
            'stripe_payment_method_id': paymentMethodId,
          },
        );
      } else {
        return PaymentResult.failure(
          errorMessage: 'Card payment declined',
        );
      }
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
