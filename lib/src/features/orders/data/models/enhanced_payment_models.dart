import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'enhanced_payment_models.g.dart';

/// Enhanced payment result with comprehensive status tracking
@JsonSerializable()
class EnhancedPaymentResult extends Equatable {
  final bool success;
  final String? transactionId;
  final String? paymentUrl;
  final String? clientSecret;
  final PaymentStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  final DateTime processedAt;

  const EnhancedPaymentResult({
    required this.success,
    this.transactionId,
    this.paymentUrl,
    this.clientSecret,
    required this.status,
    this.errorMessage,
    this.metadata,
    required this.processedAt,
  });

  factory EnhancedPaymentResult.fromJson(Map<String, dynamic> json) =>
      _$EnhancedPaymentResultFromJson(json);

  Map<String, dynamic> toJson() => _$EnhancedPaymentResultToJson(this);

  factory EnhancedPaymentResult.success({
    required String transactionId,
    String? clientSecret,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedPaymentResult(
      success: true,
      transactionId: transactionId,
      clientSecret: clientSecret,
      status: PaymentStatus.completed,
      metadata: metadata,
      processedAt: DateTime.now(),
    );
  }

  factory EnhancedPaymentResult.pending({
    required String transactionId,
    String? paymentUrl,
    String? clientSecret,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedPaymentResult(
      success: true,
      transactionId: transactionId,
      paymentUrl: paymentUrl,
      clientSecret: clientSecret,
      status: PaymentStatus.pending,
      metadata: metadata,
      processedAt: DateTime.now(),
    );
  }

  factory EnhancedPaymentResult.failed({
    required String errorMessage,
    String? transactionId,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedPaymentResult(
      success: false,
      transactionId: transactionId,
      status: PaymentStatus.failed,
      errorMessage: errorMessage,
      metadata: metadata,
      processedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        success,
        transactionId,
        paymentUrl,
        clientSecret,
        status,
        errorMessage,
        metadata,
        processedAt,
      ];
}

/// Payment status enumeration
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
  unknown;

  String get value {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.processing:
        return 'processing';
      case PaymentStatus.completed:
        return 'completed';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.cancelled:
        return 'cancelled';
      case PaymentStatus.refunded:
        return 'refunded';
      case PaymentStatus.unknown:
        return 'unknown';
    }
  }

  static PaymentStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.unknown:
        return 'Unknown';
    }
  }
}

/// Saved payment method model
@JsonSerializable()
class SavedPaymentMethod extends Equatable {
  final String id;
  final String stripePaymentMethodId;
  final String brand;
  final String last4;
  final int expiryMonth;
  final int expiryYear;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedPaymentMethod({
    required this.id,
    required this.stripePaymentMethodId,
    required this.brand,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    required this.isDefault,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$SavedPaymentMethodFromJson(json);

  Map<String, dynamic> toJson() => _$SavedPaymentMethodToJson(this);

  String get displayName => '**** **** **** $last4';

  String get expiryDisplay => '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear.toString().substring(2)}';

  bool get isExpired {
    final now = DateTime.now();
    final expiryDate = DateTime(expiryYear, expiryMonth + 1, 0);
    return now.isAfter(expiryDate);
  }

  @override
  List<Object?> get props => [
        id,
        stripePaymentMethodId,
        brand,
        last4,
        expiryMonth,
        expiryYear,
        isDefault,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Payment transaction model
@JsonSerializable()
class PaymentTransaction extends Equatable {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String paymentMethod;
  final String? gatewayTransactionId;
  final String? gatewayResponse;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    this.gatewayTransactionId,
    this.gatewayResponse,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) =>
      _$PaymentTransactionFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentTransactionToJson(this);

  bool get isCompleted => status == PaymentStatus.completed;
  bool get isPending => status == PaymentStatus.pending;
  bool get isFailed => status == PaymentStatus.failed;

  @override
  List<Object?> get props => [
        id,
        orderId,
        userId,
        amount,
        currency,
        status,
        paymentMethod,
        gatewayTransactionId,
        gatewayResponse,
        metadata,
        createdAt,
        updatedAt,
        completedAt,
      ];
}

/// Wallet transaction model
@JsonSerializable()
class WalletTransaction extends Equatable {
  final String id;
  final String walletId;
  final String type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? description;
  final String? referenceId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.description,
    this.referenceId,
    this.metadata,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionFromJson(json);

  Map<String, dynamic> toJson() => _$WalletTransactionToJson(this);

  bool get isCredit => amount > 0;
  bool get isDebit => amount < 0;

  @override
  List<Object?> get props => [
        id,
        walletId,
        type,
        amount,
        balanceBefore,
        balanceAfter,
        description,
        referenceId,
        metadata,
        createdAt,
      ];
}

/// Payment method configuration
@JsonSerializable()
class PaymentMethodConfig extends Equatable {
  final String id;
  final String name;
  final String displayName;
  final String? iconUrl;
  final bool isActive;
  final bool isDefault;
  final List<String> supportedCurrencies;
  final double? minimumAmount;
  final double? maximumAmount;
  final double? processingFee;
  final String? description;
  final Map<String, dynamic>? configuration;

  const PaymentMethodConfig({
    required this.id,
    required this.name,
    required this.displayName,
    this.iconUrl,
    required this.isActive,
    required this.isDefault,
    required this.supportedCurrencies,
    this.minimumAmount,
    this.maximumAmount,
    this.processingFee,
    this.description,
    this.configuration,
  });

  factory PaymentMethodConfig.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodConfigFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentMethodConfigToJson(this);

  bool supportsAmount(double amount) {
    if (minimumAmount != null && amount < minimumAmount!) return false;
    if (maximumAmount != null && amount > maximumAmount!) return false;
    return true;
  }

  bool supportsCurrency(String currency) {
    return supportedCurrencies.contains(currency.toUpperCase());
  }

  @override
  List<Object?> get props => [
        id,
        name,
        displayName,
        iconUrl,
        isActive,
        isDefault,
        supportedCurrencies,
        minimumAmount,
        maximumAmount,
        processingFee,
        description,
        configuration,
      ];
}

/// Payment error model
@JsonSerializable()
class PaymentError extends Equatable {
  final String code;
  final String message;
  final String? details;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  const PaymentError({
    required this.code,
    required this.message,
    this.details,
    this.metadata,
    required this.timestamp,
  });

  factory PaymentError.fromJson(Map<String, dynamic> json) =>
      _$PaymentErrorFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentErrorToJson(this);

  factory PaymentError.cardDeclined({String? details}) {
    return PaymentError(
      code: 'card_declined',
      message: 'Your card was declined',
      details: details,
      timestamp: DateTime.now(),
    );
  }

  factory PaymentError.insufficientFunds({String? details}) {
    return PaymentError(
      code: 'insufficient_funds',
      message: 'Insufficient funds',
      details: details,
      timestamp: DateTime.now(),
    );
  }

  factory PaymentError.networkError({String? details}) {
    return PaymentError(
      code: 'network_error',
      message: 'Network connection error',
      details: details,
      timestamp: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [code, message, details, metadata, timestamp];
}
