import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'driver_wallet_transaction.g.dart';

/// Custom JSON converter for DriverWalletTransactionType that handles database enum mapping
class DriverWalletTransactionTypeConverter implements JsonConverter<DriverWalletTransactionType, String> {
  const DriverWalletTransactionTypeConverter();

  @override
  DriverWalletTransactionType fromJson(String json) {
    return DriverWalletTransactionTypeExtension.fromString(json);
  }

  @override
  String toJson(DriverWalletTransactionType object) {
    return object.value;
  }
}

/// Driver-specific wallet transaction types
enum DriverWalletTransactionType {
  @JsonValue('delivery_earnings')
  deliveryEarnings,
  @JsonValue('completion_bonus')
  completionBonus,
  @JsonValue('tip_payment')
  tipPayment,
  @JsonValue('performance_bonus')
  performanceBonus,
  @JsonValue('fuel_allowance')
  fuelAllowance,
  @JsonValue('withdrawal_request')
  withdrawalRequest,
  @JsonValue('bank_transfer')
  bankTransfer,
  @JsonValue('ewallet_payout')
  ewalletPayout,
  @JsonValue('adjustment')
  adjustment,
  @JsonValue('refund')
  refund,
}

extension DriverWalletTransactionTypeExtension on DriverWalletTransactionType {
  String get displayName {
    switch (this) {
      case DriverWalletTransactionType.deliveryEarnings:
        return 'Delivery Earnings';
      case DriverWalletTransactionType.completionBonus:
        return 'Completion Bonus';
      case DriverWalletTransactionType.tipPayment:
        return 'Tip Payment';
      case DriverWalletTransactionType.performanceBonus:
        return 'Performance Bonus';
      case DriverWalletTransactionType.fuelAllowance:
        return 'Fuel Allowance';
      case DriverWalletTransactionType.withdrawalRequest:
        return 'Withdrawal Request';
      case DriverWalletTransactionType.bankTransfer:
        return 'Bank Transfer';
      case DriverWalletTransactionType.ewalletPayout:
        return 'E-Wallet Payout';
      case DriverWalletTransactionType.adjustment:
        return 'Adjustment';
      case DriverWalletTransactionType.refund:
        return 'Refund';
    }
  }

  String get value {
    switch (this) {
      case DriverWalletTransactionType.deliveryEarnings:
        return 'delivery_earnings';
      case DriverWalletTransactionType.completionBonus:
        return 'completion_bonus';
      case DriverWalletTransactionType.tipPayment:
        return 'tip_payment';
      case DriverWalletTransactionType.performanceBonus:
        return 'performance_bonus';
      case DriverWalletTransactionType.fuelAllowance:
        return 'fuel_allowance';
      case DriverWalletTransactionType.withdrawalRequest:
        return 'withdrawal_request';
      case DriverWalletTransactionType.bankTransfer:
        return 'bank_transfer';
      case DriverWalletTransactionType.ewalletPayout:
        return 'ewallet_payout';
      case DriverWalletTransactionType.adjustment:
        return 'adjustment';
      case DriverWalletTransactionType.refund:
        return 'refund';
    }
  }

  static DriverWalletTransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      // Driver-specific transaction types
      case 'delivery_earnings':
        return DriverWalletTransactionType.deliveryEarnings;
      case 'completion_bonus':
        return DriverWalletTransactionType.completionBonus;
      case 'tip_payment':
        return DriverWalletTransactionType.tipPayment;
      case 'performance_bonus':
        return DriverWalletTransactionType.performanceBonus;
      case 'fuel_allowance':
        return DriverWalletTransactionType.fuelAllowance;
      case 'withdrawal_request':
        return DriverWalletTransactionType.withdrawalRequest;
      case 'bank_transfer':
        return DriverWalletTransactionType.bankTransfer;
      case 'ewallet_payout':
        return DriverWalletTransactionType.ewalletPayout;
      case 'adjustment':
        return DriverWalletTransactionType.adjustment;
      case 'refund':
        return DriverWalletTransactionType.refund;

      // Database generic types mapped to driver-specific types
      case 'commission':
        return DriverWalletTransactionType.deliveryEarnings; // Commission = delivery earnings
      case 'bonus':
        return DriverWalletTransactionType.completionBonus; // Bonus = completion bonus
      case 'credit':
        return DriverWalletTransactionType.deliveryEarnings; // Generic credit = delivery earnings
      case 'debit':
        return DriverWalletTransactionType.withdrawalRequest; // Generic debit = withdrawal
      case 'payout':
        return DriverWalletTransactionType.bankTransfer; // Payout = bank transfer
      case 'transfer_in':
        return DriverWalletTransactionType.deliveryEarnings; // Transfer in = earnings
      case 'transfer_out':
        return DriverWalletTransactionType.withdrawalRequest; // Transfer out = withdrawal

      default:
        throw ArgumentError('Invalid driver transaction type: $value');
    }
  }

  /// Check if transaction type is a credit (increases balance)
  bool get isCredit {
    switch (this) {
      case DriverWalletTransactionType.deliveryEarnings:
      case DriverWalletTransactionType.completionBonus:
      case DriverWalletTransactionType.tipPayment:
      case DriverWalletTransactionType.performanceBonus:
      case DriverWalletTransactionType.fuelAllowance:
      case DriverWalletTransactionType.refund:
        return true;
      case DriverWalletTransactionType.withdrawalRequest:
      case DriverWalletTransactionType.bankTransfer:
      case DriverWalletTransactionType.ewalletPayout:
        return false;
      case DriverWalletTransactionType.adjustment:
        return false; // Depends on amount sign
    }
  }

  /// Get icon for transaction type
  String get icon {
    switch (this) {
      case DriverWalletTransactionType.deliveryEarnings:
        return '🚗';
      case DriverWalletTransactionType.completionBonus:
        return '🎯';
      case DriverWalletTransactionType.tipPayment:
        return '💰';
      case DriverWalletTransactionType.performanceBonus:
        return '⭐';
      case DriverWalletTransactionType.fuelAllowance:
        return '⛽';
      case DriverWalletTransactionType.withdrawalRequest:
        return '📤';
      case DriverWalletTransactionType.bankTransfer:
        return '🏦';
      case DriverWalletTransactionType.ewalletPayout:
        return '📱';
      case DriverWalletTransactionType.adjustment:
        return '⚖️';
      case DriverWalletTransactionType.refund:
        return '↩️';
    }
  }
}

/// Driver wallet transaction model
@JsonSerializable()
class DriverWalletTransaction extends Equatable {
  final String id;
  @JsonKey(name: 'wallet_id')
  final String walletId;
  @JsonKey(name: 'driver_id')
  final String driverId;
  @JsonKey(name: 'transaction_type')
  final DriverWalletTransactionType transactionType;
  final double amount;
  final String currency;
  @JsonKey(name: 'balance_before')
  final double balanceBefore;
  @JsonKey(name: 'balance_after')
  final double balanceAfter;
  @JsonKey(name: 'reference_type')
  final String? referenceType;
  @JsonKey(name: 'reference_id')
  final String? referenceId;
  final String? description;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'processed_by')
  final String? processedBy;
  @JsonKey(name: 'processing_fee')
  final double processingFee;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'processed_at')
  final DateTime? processedAt;

  const DriverWalletTransaction({
    required this.id,
    required this.walletId,
    required this.driverId,
    required this.transactionType,
    required this.amount,
    required this.currency,
    required this.balanceBefore,
    required this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.description,
    this.metadata,
    this.processedBy,
    required this.processingFee,
    required this.createdAt,
    this.processedAt,
  });

  factory DriverWalletTransaction.fromJson(Map<String, dynamic> json) {
    // Handle custom transaction type parsing for database compatibility
    final transactionTypeString = json['transaction_type'] as String;
    final transactionType = DriverWalletTransactionTypeExtension.fromString(transactionTypeString);

    // Create a modified JSON map with the parsed transaction type
    final modifiedJson = Map<String, dynamic>.from(json);
    modifiedJson['transaction_type'] = transactionType.value;

    return _$DriverWalletTransactionFromJson(modifiedJson);
  }

  Map<String, dynamic> toJson() => _$DriverWalletTransactionToJson(this);

  @override
  List<Object?> get props => [
        id,
        walletId,
        driverId,
        transactionType,
        amount,
        currency,
        balanceBefore,
        balanceAfter,
        referenceType,
        referenceId,
        description,
        metadata,
        processedBy,
        processingFee,
        createdAt,
        processedAt,
      ];

  /// Get formatted amount with currency
  String get formattedAmount {
    final sign = amount >= 0 ? '+' : '';
    return '$sign$currency ${amount.toStringAsFixed(2)}';
  }

  /// Get formatted amount without sign
  String get formattedAmountAbsolute {
    return '$currency ${amount.abs().toStringAsFixed(2)}';
  }

  /// Check if transaction is a credit (positive amount)
  bool get isCredit => amount > 0;

  /// Check if transaction is a debit (negative amount)
  bool get isDebit => amount < 0;

  /// Get transaction direction
  String get direction => isCredit ? 'Credit' : 'Debit';

  /// Get status based on processed_at
  String get status => processedAt != null ? 'Completed' : 'Pending';

  /// Get formatted date
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Get formatted time
  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted date and time
  String get formattedDateTime {
    return '$formattedDate $formattedTime';
  }

  /// Create a test transaction for development
  factory DriverWalletTransaction.test({
    String? id,
    String? walletId,
    String? driverId,
    DriverWalletTransactionType? transactionType,
    double? amount,
    String? description,
  }) {
    final now = DateTime.now();
    final txnAmount = amount ?? 25.00;
    
    return DriverWalletTransaction(
      id: id ?? 'test-driver-transaction-id',
      walletId: walletId ?? 'test-driver-wallet-id',
      driverId: driverId ?? 'test-driver-id',
      transactionType: transactionType ?? DriverWalletTransactionType.deliveryEarnings,
      amount: txnAmount,
      currency: 'MYR',
      balanceBefore: 100.00,
      balanceAfter: 100.00 + txnAmount,
      referenceType: 'order',
      referenceId: 'test-order-id',
      description: description ?? 'Test delivery earnings',
      processingFee: 0.00,
      createdAt: now,
      processedAt: now,
    );
  }

  /// Copy with method for updates
  DriverWalletTransaction copyWith({
    String? id,
    String? walletId,
    String? driverId,
    DriverWalletTransactionType? transactionType,
    double? amount,
    String? currency,
    double? balanceBefore,
    double? balanceAfter,
    String? referenceType,
    String? referenceId,
    String? description,
    Map<String, dynamic>? metadata,
    String? processedBy,
    double? processingFee,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return DriverWalletTransaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      driverId: driverId ?? this.driverId,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      processedBy: processedBy ?? this.processedBy,
      processingFee: processingFee ?? this.processingFee,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}
