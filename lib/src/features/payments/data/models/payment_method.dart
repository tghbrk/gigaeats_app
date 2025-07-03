import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'payment_method.g.dart';

enum PaymentMethodType {
  @JsonValue('fpx')
  fpx,
  @JsonValue('credit_card')
  creditCard,
  @JsonValue('grabpay')
  grabPay,
  @JsonValue('touchngo')
  touchNGo,
  @JsonValue('boost')
  boost,
  @JsonValue('shopee_pay')
  shopeePay,
  @JsonValue('billplz')
  billplz,
  @JsonValue('bank_transfer')
  bankTransfer,
}

enum PaymentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('refunded')
  refunded,
}

@JsonSerializable()
class PaymentMethod extends Equatable {
  final String id;
  final PaymentMethodType type;
  final String name;
  final String displayName;
  final String? iconUrl;
  final bool isActive;
  final bool isDefault;
  final Map<String, dynamic>? configuration;
  final List<String> supportedCurrencies;
  final double? minimumAmount;
  final double? maximumAmount;
  final double? processingFee;
  final String? description;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.name,
    required this.displayName,
    this.iconUrl,
    this.isActive = true,
    this.isDefault = false,
    this.configuration,
    this.supportedCurrencies = const ['MYR'],
    this.minimumAmount,
    this.maximumAmount,
    this.processingFee,
    this.description,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => _$PaymentMethodFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentMethodToJson(this);

  @override
  List<Object?> get props => [
        id,
        type,
        name,
        displayName,
        iconUrl,
        isActive,
        isDefault,
        configuration,
        supportedCurrencies,
        minimumAmount,
        maximumAmount,
        processingFee,
        description,
      ];

  PaymentMethod copyWith({
    String? id,
    PaymentMethodType? type,
    String? name,
    String? displayName,
    String? iconUrl,
    bool? isActive,
    bool? isDefault,
    Map<String, dynamic>? configuration,
    List<String>? supportedCurrencies,
    double? minimumAmount,
    double? maximumAmount,
    double? processingFee,
    String? description,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      iconUrl: iconUrl ?? this.iconUrl,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      configuration: configuration ?? this.configuration,
      supportedCurrencies: supportedCurrencies ?? this.supportedCurrencies,
      minimumAmount: minimumAmount ?? this.minimumAmount,
      maximumAmount: maximumAmount ?? this.maximumAmount,
      processingFee: processingFee ?? this.processingFee,
      description: description ?? this.description,
    );
  }
}

@JsonSerializable()
class PaymentTransaction extends Equatable {
  final String id;
  final String orderId;
  final String paymentMethodId;
  final PaymentMethodType paymentMethodType;
  final PaymentStatus status;
  final double amount;
  final double? processingFee;
  final String currency;
  final String? transactionReference;
  final String? gatewayTransactionId;
  final String? gatewayResponse;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  const PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.paymentMethodId,
    required this.paymentMethodType,
    required this.status,
    required this.amount,
    this.processingFee,
    this.currency = 'MYR',
    this.transactionReference,
    this.gatewayTransactionId,
    this.gatewayResponse,
    this.failureReason,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.metadata,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) => _$PaymentTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentTransactionToJson(this);

  @override
  List<Object?> get props => [
        id,
        orderId,
        paymentMethodId,
        paymentMethodType,
        status,
        amount,
        processingFee,
        currency,
        transactionReference,
        gatewayTransactionId,
        gatewayResponse,
        failureReason,
        createdAt,
        updatedAt,
        completedAt,
        metadata,
      ];

  PaymentTransaction copyWith({
    String? id,
    String? orderId,
    String? paymentMethodId,
    PaymentMethodType? paymentMethodType,
    PaymentStatus? status,
    double? amount,
    double? processingFee,
    String? currency,
    String? transactionReference,
    String? gatewayTransactionId,
    String? gatewayResponse,
    String? failureReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentMethodType: paymentMethodType ?? this.paymentMethodType,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      processingFee: processingFee ?? this.processingFee,
      currency: currency ?? this.currency,
      transactionReference: transactionReference ?? this.transactionReference,
      gatewayTransactionId: gatewayTransactionId ?? this.gatewayTransactionId,
      gatewayResponse: gatewayResponse ?? this.gatewayResponse,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Malaysian FPX Bank Codes
class FPXBankCodes {
  static const Map<String, String> banks = {
    'ABMB0212': 'Alliance Bank',
    'ABB0233': 'Affin Bank',
    'AMBB0209': 'AmBank',
    'AGRO01': 'AgroBank',
    'BCBB0235': 'CIMB Bank',
    'BIMB0340': 'Bank Islam',
    'BKRM0602': 'Bank Rakyat',
    'BMMB0341': 'Bank Muamalat',
    'BSN0601': 'BSN',
    'CIT0219': 'Citibank',
    'HLB0224': 'Hong Leong Bank',
    'HSBC0223': 'HSBC Bank',
    'KFH0346': 'Kuwait Finance House',
    'MB2U0227': 'Maybank',
    'MBB0228': 'Maybank2E',
    'OCBC0229': 'OCBC Bank',
    'PBB0233': 'Public Bank',
    'RHB0218': 'RHB Bank',
    'SCB0216': 'Standard Chartered',
    'UOB0226': 'UOB Bank',
  };

  static String getBankName(String code) {
    return banks[code] ?? 'Unknown Bank';
  }

  static List<MapEntry<String, String>> getAllBanks() {
    return banks.entries.toList();
  }
}
