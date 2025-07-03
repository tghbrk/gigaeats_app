import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/services/base_service.dart';
import '../models/commission_breakdown.dart';
import '../models/escrow_account.dart';
import '../../../payments/data/models/payment_result.dart';

class MarketplacePaymentService extends BaseService {
  MarketplacePaymentService({required super.client});

  /// Process marketplace payment with escrow
  Future<Either<Failure, MarketplacePaymentResult>> processMarketplacePayment({
    required String orderId,
    required String paymentMethod,
    required double amount,
    String currency = 'MYR',
    bool autoEscrow = true,
    String releaseTriger = 'order_delivered',
    int? holdDurationHours,
    Map<String, dynamic>? gatewayData,
    String? callbackUrl,
    String? redirectUrl,
  }) async {
    return executeServiceCall(() async {
      debugPrint('🔄 [PAYMENT-SERVICE] Processing marketplace payment for order: $orderId');

      final response = await client.functions.invoke(
        'marketplace-payment-processor',
        body: {
          'order_id': orderId,
          'payment_method': paymentMethod,
          'amount': amount,
          'currency': currency,
          'auto_escrow': autoEscrow,
          'release_trigger': releaseTriger,
          'hold_duration_hours': holdDurationHours,
          'gateway_data': gatewayData,
          'callback_url': callbackUrl,
          'redirect_url': redirectUrl,
        },
      );

      if (response.status != 200) {
        throw Exception('Payment processing failed: ${response.data}');
      }

      final result = response.data;
      if (!result['success']) {
        throw Exception(result['error'] ?? 'Payment processing failed');
      }

      final paymentResult = MarketplacePaymentResult.fromJson(result);
      debugPrint('🔄 [PAYMENT-SERVICE] Payment processed: ${paymentResult.status}');
      return paymentResult;
    });
  }

  /// Distribute funds from escrow
  Future<Either<Failure, FundDistributionResult>> distributeFunds({
    String? escrowAccountId,
    String? orderId,
    required String releaseReason,
    bool forceRelease = false,
  }) async {
    return executeServiceCall(() async {
      debugPrint('🔄 [PAYMENT-SERVICE] Distributing funds - escrow: $escrowAccountId, order: $orderId');

      final response = await client.functions.invoke(
        'distribute-escrow-funds',
        body: {
          'escrow_account_id': escrowAccountId,
          'order_id': orderId,
          'release_reason': releaseReason,
          'force_release': forceRelease,
        },
      );

      if (response.status != 200) {
        throw Exception('Fund distribution failed: ${response.data}');
      }

      final result = response.data;
      if (!result['success']) {
        throw Exception(result['error'] ?? 'Fund distribution failed');
      }

      final distributionResult = FundDistributionResult.fromJson(result);
      debugPrint('🔄 [PAYMENT-SERVICE] Funds distributed: ${distributionResult.totalDistributed} MYR');
      return distributionResult;
    });
  }

  /// Complete order and trigger fund release
  Future<Either<Failure, OrderCompletionResult>> completeOrder({
    required String orderId,
    required String completionType,
    String? completedBy,
    String? completionNotes,
    bool forceRelease = false,
  }) async {
    return executeServiceCall(() async {
      debugPrint('🔄 [PAYMENT-SERVICE] Completing order: $orderId - $completionType');

      final response = await client.functions.invoke(
        'order-completion-handler',
        body: {
          'order_id': orderId,
          'completion_type': completionType,
          'completed_by': completedBy,
          'completion_notes': completionNotes,
          'force_release': forceRelease,
        },
      );

      if (response.status != 200) {
        throw Exception('Order completion failed: ${response.data}');
      }

      final result = response.data;
      if (!result['success']) {
        throw Exception(result['error'] ?? 'Order completion failed');
      }

      final completionResult = OrderCompletionResult.fromJson(result);
      debugPrint('🔄 [PAYMENT-SERVICE] Order completed: escrow released: ${completionResult.escrowReleased}');
      return completionResult;
    });
  }

  /// Calculate commission breakdown for order
  Future<Either<Failure, CommissionBreakdown>> calculateCommissionBreakdown({
    required String orderId,
  }) async {
    return executeServiceCall(() async {
      debugPrint('🔄 [PAYMENT-SERVICE] Calculating commission breakdown for order: $orderId');

      // Get order details
      final orderResponse = await client
          .from('orders')
          .select('''
            id, total_amount, subtotal, delivery_fee, delivery_method,
            vendors!inner(id, user_id),
            sales_agent_id,
            assigned_driver_id
          ''')
          .eq('id', orderId)
          .single();

      // Get applicable commission structure
      final commissionResponse = await client
          .from('commission_structures')
          .select('*')
          .eq('is_active', true)
          .or('delivery_method.eq.${orderResponse['delivery_method']},delivery_method.is.null')
          .order('effective_from', ascending: false)
          .limit(1)
          .maybeSingle();

      // Use default rates if no specific structure found
      final rates = commissionResponse ?? {
        'platform_fee_rate': 0.0500,
        'vendor_commission_rate': 0.8500,
        'sales_agent_commission_rate': 0.0300,
        'driver_commission_rate': 0.8000,
        'fixed_delivery_fee': _getDefaultDeliveryFee(orderResponse['delivery_method']),
      };

      final totalAmount = orderResponse['total_amount']?.toDouble() ?? 0.0;
      final subtotal = orderResponse['subtotal']?.toDouble() ?? (totalAmount - (orderResponse['delivery_fee']?.toDouble() ?? 0.0));
      final deliveryFee = orderResponse['delivery_fee']?.toDouble() ?? rates['fixed_delivery_fee']?.toDouble() ?? 0.0;

      // Calculate commission amounts
      final platformFee = totalAmount * (rates['platform_fee_rate']?.toDouble() ?? 0.05);
      final vendorAmount = subtotal * (rates['vendor_commission_rate']?.toDouble() ?? 0.85);
      final salesAgentCommission = totalAmount * (rates['sales_agent_commission_rate']?.toDouble() ?? 0.03);
      
      // Driver commission calculation depends on delivery method
      double driverCommission = 0.0;
      if (orderResponse['delivery_method'] == 'own_fleet' && orderResponse['assigned_driver_id'] != null) {
        final driverRate = rates['driver_commission_rate']?.toDouble() ?? 0.80;
        driverCommission = (deliveryFee * driverRate) + (subtotal * (driverRate - (rates['vendor_commission_rate']?.toDouble() ?? 0.85)));
      }

      final breakdown = CommissionBreakdown(
        totalAmount: totalAmount,
        vendorAmount: _roundToTwoDecimals(vendorAmount),
        platformFee: _roundToTwoDecimals(platformFee),
        salesAgentCommission: _roundToTwoDecimals(salesAgentCommission),
        driverCommission: _roundToTwoDecimals(driverCommission),
        deliveryFee: deliveryFee,
        currency: 'MYR',
        orderId: orderId,
        deliveryMethod: orderResponse['delivery_method'],
        calculatedAt: DateTime.now(),
      );

      debugPrint('🔄 [PAYMENT-SERVICE] Commission breakdown calculated: ${breakdown.formattedTotalAmount}');
      return breakdown;
    });
  }

  /// Get payment status for order
  Future<Either<Failure, PaymentStatus>> getPaymentStatus({
    required String orderId,
  }) async {
    return executeServiceCall(() async {
      debugPrint('🔄 [PAYMENT-SERVICE] Getting payment status for order: $orderId');

      // Get order payment status
      final orderResponse = await client
          .from('orders')
          .select('payment_status, payment_reference')
          .eq('id', orderId)
          .single();

      // Get escrow account status
      final escrowResponse = await client
          .from('escrow_accounts')
          .select('status, release_date, total_amount')
          .eq('order_id', orderId)
          .maybeSingle();

      // Get payment transaction details
      final transactionResponse = await client
          .from('payment_transactions')
          .select('status, gateway_transaction_id, amount')
          .eq('order_id', orderId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final paymentStatus = PaymentStatus(
        orderId: orderId,
        orderPaymentStatus: orderResponse['payment_status'],
        paymentReference: orderResponse['payment_reference'],
        escrowStatus: escrowResponse?['status'],
        escrowReleaseDate: escrowResponse?['release_date'] != null 
            ? DateTime.parse(escrowResponse!['release_date'])
            : null,
        escrowAmount: escrowResponse?['total_amount']?.toDouble(),
        transactionStatus: transactionResponse?['status'],
        gatewayTransactionId: transactionResponse?['gateway_transaction_id'],
        transactionAmount: transactionResponse?['amount']?.toDouble(),
      );

      debugPrint('🔄 [PAYMENT-SERVICE] Payment status retrieved: ${paymentStatus.orderPaymentStatus}');
      return paymentStatus;
    });
  }

  /// Helper method to get default delivery fee
  double _getDefaultDeliveryFee(String? deliveryMethod) {
    switch (deliveryMethod) {
      case 'own_fleet':
        return 8.00;
      case 'sales_agent_pickup':
        return 3.00;
      case 'customer_pickup':
      default:
        return 0.00;
    }
  }

  /// Helper method to round to two decimal places
  double _roundToTwoDecimals(double value) {
    return (value * 100).round() / 100;
  }

  /// Alias for distributeFunds method (for backward compatibility)
  Future<Either<Failure, FundDistributionResult>> releaseEscrowFunds({
    String? escrowAccountId,
    String? orderId,
    required String releaseReason,
    String? releasedBy,
    bool forceRelease = false,
  }) async {
    return distributeFunds(
      escrowAccountId: escrowAccountId,
      orderId: orderId,
      releaseReason: releaseReason,
      forceRelease: forceRelease,
    );
  }

  /// Alias for calculateCommissionBreakdown method (for backward compatibility)
  Future<Either<Failure, CommissionBreakdown>> getCommissionBreakdown({
    required String orderId,
  }) async {
    return calculateCommissionBreakdown(orderId: orderId);
  }

  /// Create escrow account for order
  Future<Either<Failure, EscrowAccount>> createEscrowAccount({
    required String orderId,
    required double totalAmount,
    required String currency,
    required EscrowReleaseTrigger releaseTrigger,
    required int holdDurationHours,
  }) async {
    return executeServiceCall(() async {
      debugPrint('🔄 [PAYMENT-SERVICE] Creating escrow account for order: $orderId');

      final response = await client.functions.invoke(
        'create-escrow-account',
        body: {
          'order_id': orderId,
          'total_amount': totalAmount,
          'currency': currency,
          'release_trigger': releaseTrigger.value,
          'hold_duration_hours': holdDurationHours,
        },
      );

      if (response.status != 200) {
        throw Exception('Escrow account creation failed: ${response.data}');
      }

      return EscrowAccount.fromJson(response.data);
    });
  }

  /// Process payment (alias for processMarketplacePayment)
  Future<Either<Failure, PaymentResult>> processPayment({
    required String orderId,
    required String paymentMethod,
    required double amount,
    required String currency,
    Map<String, dynamic>? gatewayData,
    String? callbackUrl,
    String? redirectUrl,
    bool autoEscrow = true,
    EscrowReleaseTrigger releaseTrigger = EscrowReleaseTrigger.orderDelivered,
    int? holdDurationHours,
  }) async {
    return executeServiceCall(() async {
      final marketplaceResult = await processMarketplacePayment(
        orderId: orderId,
        paymentMethod: paymentMethod,
        amount: amount,
        currency: currency,
        autoEscrow: autoEscrow,
        releaseTriger: releaseTrigger.value,
        holdDurationHours: holdDurationHours,
        gatewayData: gatewayData,
        callbackUrl: callbackUrl,
        redirectUrl: redirectUrl,
      );

      return marketplaceResult.fold(
        (failure) => throw Exception(failure.message),
        (result) => PaymentResult(
          success: result.success,
          transactionId: result.transactionId,
          paymentUrl: result.paymentUrl,
          clientSecret: result.clientSecret,
          status: PaymentResultStatus.fromString(result.status),
          errorMessage: result.errorMessage,
          metadata: result.metadata,
        ),
      );
    });
  }

  /// Initiate refund for payment
  Future<Either<Failure, PaymentResult>> initiateRefund({
    required String transactionId,
    required double amount,
    required String reason,
  }) async {
    return executeServiceCall(() async {
      debugPrint('🔄 [PAYMENT-SERVICE] Initiating refund for transaction: $transactionId');

      final response = await client.functions.invoke(
        'initiate-refund',
        body: {
          'transaction_id': transactionId,
          'amount': amount,
          'reason': reason,
        },
      );

      if (response.status != 200) {
        throw Exception('Refund initiation failed: ${response.data}');
      }

      return PaymentResult.fromJson(response.data);
    });
  }

  /// Update escrow status
  Future<Either<Failure, EscrowAccount>> updateEscrowStatus({
    required String escrowAccountId,
    required EscrowStatus status,
    String? reason,
  }) async {
    return executeServiceCall(() async {
      debugPrint('🔄 [PAYMENT-SERVICE] Updating escrow status: $escrowAccountId -> ${status.value}');

      final response = await client.functions.invoke(
        'update-escrow-status',
        body: {
          'escrow_account_id': escrowAccountId,
          'status': status.value,
          'reason': reason,
        },
      );

      if (response.status != 200) {
        throw Exception('Escrow status update failed: ${response.data}');
      }

      return EscrowAccount.fromJson(response.data);
    });
  }

  /// Get escrow status
  Future<Either<Failure, Map<String, dynamic>>> getEscrowStatus(String orderId) async {
    return executeServiceCall(() async {
      debugPrint('🔄 [PAYMENT-SERVICE] Getting escrow status for order: $orderId');

      final response = await client.functions.invoke(
        'get-escrow-status',
        body: {
          'order_id': orderId,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to get escrow status: ${response.data}');
      }

      return response.data as Map<String, dynamic>;
    });
  }


}

/// Marketplace payment result data class
class MarketplacePaymentResult {
  final bool success;
  final String? transactionId;
  final String? escrowAccountId;
  final String? paymentUrl;
  final String? clientSecret;
  final String status;
  final CommissionBreakdown? commissionBreakdown;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const MarketplacePaymentResult({
    required this.success,
    this.transactionId,
    this.escrowAccountId,
    this.paymentUrl,
    this.clientSecret,
    required this.status,
    this.commissionBreakdown,
    this.errorMessage,
    this.metadata,
  });

  factory MarketplacePaymentResult.fromJson(Map<String, dynamic> json) {
    return MarketplacePaymentResult(
      success: json['success'] ?? false,
      transactionId: json['transaction_id'],
      escrowAccountId: json['escrow_account_id'],
      paymentUrl: json['payment_url'],
      clientSecret: json['client_secret'],
      status: json['status'] ?? 'failed',
      commissionBreakdown: json['commission_breakdown'] != null
          ? CommissionBreakdown.fromJson(json['commission_breakdown'])
          : null,
      errorMessage: json['error_message'],
      metadata: json['metadata'],
    );
  }
}

/// Fund distribution result data class
class FundDistributionResult {
  final bool success;
  final String escrowAccountId;
  final List<WalletDistribution> distributions;
  final double totalDistributed;
  final String? errorMessage;

  const FundDistributionResult({
    required this.success,
    required this.escrowAccountId,
    required this.distributions,
    required this.totalDistributed,
    this.errorMessage,
  });

  factory FundDistributionResult.fromJson(Map<String, dynamic> json) {
    return FundDistributionResult(
      success: json['success'] ?? false,
      escrowAccountId: json['escrow_account_id'] ?? '',
      distributions: (json['distributions'] as List<dynamic>?)
              ?.map((item) => WalletDistribution.fromJson(item))
              .toList() ??
          [],
      totalDistributed: json['total_distributed']?.toDouble() ?? 0.0,
      errorMessage: json['error_message'],
    );
  }
}

/// Wallet distribution data class
class WalletDistribution {
  final String walletId;
  final String userId;
  final String userRole;
  final double amount;
  final String transactionType;
  final String description;

  const WalletDistribution({
    required this.walletId,
    required this.userId,
    required this.userRole,
    required this.amount,
    required this.transactionType,
    required this.description,
  });

  factory WalletDistribution.fromJson(Map<String, dynamic> json) {
    return WalletDistribution(
      walletId: json['wallet_id'] ?? '',
      userId: json['user_id'] ?? '',
      userRole: json['user_role'] ?? '',
      amount: json['amount']?.toDouble() ?? 0.0,
      transactionType: json['transaction_type'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

/// Order completion result data class
class OrderCompletionResult {
  final bool success;
  final String orderId;
  final bool escrowReleased;
  final bool fundsDistributed;
  final double? totalDistributed;
  final String? errorMessage;

  const OrderCompletionResult({
    required this.success,
    required this.orderId,
    required this.escrowReleased,
    required this.fundsDistributed,
    this.totalDistributed,
    this.errorMessage,
  });

  factory OrderCompletionResult.fromJson(Map<String, dynamic> json) {
    return OrderCompletionResult(
      success: json['success'] ?? false,
      orderId: json['order_id'] ?? '',
      escrowReleased: json['escrow_released'] ?? false,
      fundsDistributed: json['funds_distributed'] ?? false,
      totalDistributed: json['total_distributed']?.toDouble(),
      errorMessage: json['error_message'],
    );
  }
}

/// Payment status data class
class PaymentStatus {
  final String orderId;
  final String? orderPaymentStatus;
  final String? paymentReference;
  final String? escrowStatus;
  final DateTime? escrowReleaseDate;
  final double? escrowAmount;
  final String? transactionStatus;
  final String? gatewayTransactionId;
  final double? transactionAmount;

  const PaymentStatus({
    required this.orderId,
    this.orderPaymentStatus,
    this.paymentReference,
    this.escrowStatus,
    this.escrowReleaseDate,
    this.escrowAmount,
    this.transactionStatus,
    this.gatewayTransactionId,
    this.transactionAmount,
  });

  bool get isPaid => orderPaymentStatus == 'paid';
  bool get isEscrowed => escrowStatus == 'held';
  bool get isReleased => escrowStatus == 'released';
  bool get isRefunded => escrowStatus == 'refunded';
}
