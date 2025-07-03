import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wallet_transaction.g.dart';

@JsonSerializable()
class WalletTransaction extends Equatable {
  final String id;
  final String walletId;
  final WalletTransactionType transactionType;
  final double amount;
  final String currency;
  final double balanceBefore;
  final double balanceAfter;
  final String? referenceType;
  final String? referenceId;
  final String? escrowAccountId;
  final String? description;
  final Map<String, dynamic>? metadata;
  final String? processedBy;
  final double processingFee;
  final DateTime createdAt;
  final DateTime? processedAt;

  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.transactionType,
    required this.amount,
    required this.currency,
    required this.balanceBefore,
    required this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.escrowAccountId,
    this.description,
    this.metadata,
    this.processedBy,
    required this.processingFee,
    required this.createdAt,
    this.processedAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionFromJson(json);

  Map<String, dynamic> toJson() => _$WalletTransactionToJson(this);

  WalletTransaction copyWith({
    String? id,
    String? walletId,
    WalletTransactionType? transactionType,
    double? amount,
    String? currency,
    double? balanceBefore,
    double? balanceAfter,
    String? referenceType,
    String? referenceId,
    String? escrowAccountId,
    String? description,
    Map<String, dynamic>? metadata,
    String? processedBy,
    double? processingFee,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      escrowAccountId: escrowAccountId ?? this.escrowAccountId,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      processedBy: processedBy ?? this.processedBy,
      processingFee: processingFee ?? this.processingFee,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        walletId,
        transactionType,
        amount,
        currency,
        balanceBefore,
        balanceAfter,
        referenceType,
        referenceId,
        escrowAccountId,
        description,
        metadata,
        processedBy,
        processingFee,
        createdAt,
        processedAt,
      ];

  /// Get formatted amount with currency
  String get formattedAmount => '$currency ${amount.abs().toStringAsFixed(2)}';

  /// Get formatted balance before
  String get formattedBalanceBefore => '$currency ${balanceBefore.toStringAsFixed(2)}';

  /// Get formatted balance after
  String get formattedBalanceAfter => '$currency ${balanceAfter.toStringAsFixed(2)}';

  /// Check if transaction is a credit (positive amount)
  bool get isCredit => amount > 0;

  /// Check if transaction is a debit (negative amount)
  bool get isDebit => amount < 0;

  /// Get transaction direction
  TransactionDirection get direction => isCredit ? TransactionDirection.credit : TransactionDirection.debit;

  /// Get transaction status
  TransactionStatus get status {
    if (processedAt != null) return TransactionStatus.completed;
    return TransactionStatus.pending;
  }

  /// Get display description
  String get displayDescription {
    if (description != null && description!.isNotEmpty) {
      return description!;
    }

    // Generate description based on transaction type
    switch (transactionType) {
      case WalletTransactionType.credit:
        return 'Credit transaction';
      case WalletTransactionType.debit:
        return 'Debit transaction';
      case WalletTransactionType.commission:
        return 'Commission earned';
      case WalletTransactionType.payout:
        return 'Payout processed';
      case WalletTransactionType.refund:
        return 'Refund received';
      case WalletTransactionType.adjustment:
        return 'Balance adjustment';
      case WalletTransactionType.bonus:
        return 'Bonus received';
    }
  }

  /// Get transaction icon based on type
  String get iconName {
    switch (transactionType) {
      case WalletTransactionType.credit:
        return 'add_circle';
      case WalletTransactionType.debit:
        return 'remove_circle';
      case WalletTransactionType.commission:
        return 'monetization_on';
      case WalletTransactionType.payout:
        return 'account_balance';
      case WalletTransactionType.refund:
        return 'undo';
      case WalletTransactionType.adjustment:
        return 'tune';
      case WalletTransactionType.bonus:
        return 'card_giftcard';
    }
  }

  /// Get net amount (amount minus processing fee)
  double get netAmount => amount - processingFee;

  /// Get formatted net amount
  String get formattedNetAmount => '$currency ${netAmount.toStringAsFixed(2)}';

  /// Check if transaction has processing fee
  bool get hasProcessingFee => processingFee > 0;

  /// Get formatted processing fee
  String get formattedProcessingFee => '$currency ${processingFee.toStringAsFixed(2)}';

  /// Create a test transaction for development
  factory WalletTransaction.test({
    String? id,
    String? walletId,
    WalletTransactionType? transactionType,
    double? amount,
    String? description,
  }) {
    final now = DateTime.now();
    final txnAmount = amount ?? 50.00;
    
    return WalletTransaction(
      id: id ?? 'test-transaction-id',
      walletId: walletId ?? 'test-wallet-id',
      transactionType: transactionType ?? WalletTransactionType.commission,
      amount: txnAmount,
      currency: 'MYR',
      balanceBefore: 100.00,
      balanceAfter: 100.00 + txnAmount,
      referenceType: 'order',
      referenceId: 'test-order-id',
      description: description ?? 'Test commission payment',
      processingFee: 0.00,
      createdAt: now,
      processedAt: now,
    );
  }
}

enum WalletTransactionType {
  @JsonValue('credit')
  credit,
  @JsonValue('debit')
  debit,
  @JsonValue('commission')
  commission,
  @JsonValue('payout')
  payout,
  @JsonValue('refund')
  refund,
  @JsonValue('adjustment')
  adjustment,
  @JsonValue('bonus')
  bonus,
}

extension WalletTransactionTypeExtension on WalletTransactionType {
  String get displayName {
    switch (this) {
      case WalletTransactionType.credit:
        return 'Credit';
      case WalletTransactionType.debit:
        return 'Debit';
      case WalletTransactionType.commission:
        return 'Commission';
      case WalletTransactionType.payout:
        return 'Payout';
      case WalletTransactionType.refund:
        return 'Refund';
      case WalletTransactionType.adjustment:
        return 'Adjustment';
      case WalletTransactionType.bonus:
        return 'Bonus';
    }
  }

  String get value {
    switch (this) {
      case WalletTransactionType.credit:
        return 'credit';
      case WalletTransactionType.debit:
        return 'debit';
      case WalletTransactionType.commission:
        return 'commission';
      case WalletTransactionType.payout:
        return 'payout';
      case WalletTransactionType.refund:
        return 'refund';
      case WalletTransactionType.adjustment:
        return 'adjustment';
      case WalletTransactionType.bonus:
        return 'bonus';
    }
  }

  static WalletTransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'credit':
        return WalletTransactionType.credit;
      case 'debit':
        return WalletTransactionType.debit;
      case 'commission':
        return WalletTransactionType.commission;
      case 'payout':
        return WalletTransactionType.payout;
      case 'refund':
        return WalletTransactionType.refund;
      case 'adjustment':
        return WalletTransactionType.adjustment;
      case 'bonus':
        return WalletTransactionType.bonus;
      default:
        throw ArgumentError('Invalid transaction type: $value');
    }
  }
}

enum TransactionDirection {
  credit,
  debit,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
}

extension TransactionStatusExtension on TransactionStatus {
  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
    }
  }
}
