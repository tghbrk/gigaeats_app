import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'payout_request.g.dart';

@JsonSerializable()
class PayoutRequest extends Equatable {
  final String id;
  final String walletId;
  final double amount;
  final String currency;
  final PayoutStatus status;
  final String bankAccountNumber;
  final String bankName;
  final String accountHolderName;
  final String? swiftCode;
  final double processingFee;
  final double netAmount;
  final String? paymentGateway;
  final String? gatewayTransactionId;
  final String? gatewayReference;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final DateTime? failedAt;
  final String? failureReason;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PayoutRequest({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.bankAccountNumber,
    required this.bankName,
    required this.accountHolderName,
    this.swiftCode,
    required this.processingFee,
    required this.netAmount,
    this.paymentGateway,
    this.gatewayTransactionId,
    this.gatewayReference,
    required this.requestedAt,
    this.processedAt,
    this.completedAt,
    this.failedAt,
    this.failureReason,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PayoutRequest.fromJson(Map<String, dynamic> json) =>
      _$PayoutRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PayoutRequestToJson(this);

  PayoutRequest copyWith({
    String? id,
    String? walletId,
    double? amount,
    String? currency,
    PayoutStatus? status,
    String? bankAccountNumber,
    String? bankName,
    String? accountHolderName,
    String? swiftCode,
    double? processingFee,
    double? netAmount,
    String? paymentGateway,
    String? gatewayTransactionId,
    String? gatewayReference,
    DateTime? requestedAt,
    DateTime? processedAt,
    DateTime? completedAt,
    DateTime? failedAt,
    String? failureReason,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PayoutRequest(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankName: bankName ?? this.bankName,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      swiftCode: swiftCode ?? this.swiftCode,
      processingFee: processingFee ?? this.processingFee,
      netAmount: netAmount ?? this.netAmount,
      paymentGateway: paymentGateway ?? this.paymentGateway,
      gatewayTransactionId: gatewayTransactionId ?? this.gatewayTransactionId,
      gatewayReference: gatewayReference ?? this.gatewayReference,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      completedAt: completedAt ?? this.completedAt,
      failedAt: failedAt ?? this.failedAt,
      failureReason: failureReason ?? this.failureReason,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        walletId,
        amount,
        currency,
        status,
        bankAccountNumber,
        bankName,
        accountHolderName,
        swiftCode,
        processingFee,
        netAmount,
        paymentGateway,
        gatewayTransactionId,
        gatewayReference,
        requestedAt,
        processedAt,
        completedAt,
        failedAt,
        failureReason,
        approvedBy,
        approvedAt,
        rejectionReason,
        createdAt,
        updatedAt,
      ];

  /// Get formatted amount with currency
  String get formattedAmount => '$currency ${amount.toStringAsFixed(2)}';

  /// Get formatted net amount with currency
  String get formattedNetAmount => '$currency ${netAmount.toStringAsFixed(2)}';

  /// Get formatted processing fee with currency
  String get formattedProcessingFee => '$currency ${processingFee.toStringAsFixed(2)}';

  /// Get masked bank account number for display
  String get maskedBankAccountNumber {
    if (bankAccountNumber.length <= 4) return bankAccountNumber;
    final lastFour = bankAccountNumber.substring(bankAccountNumber.length - 4);
    final masked = '*' * (bankAccountNumber.length - 4);
    return '$masked$lastFour';
  }

  /// Get estimated completion time
  DateTime? get estimatedCompletion {
    if (processedAt == null) return null;
    
    // Estimate 1-3 business days for completion
    return processedAt!.add(const Duration(days: 3));
  }

  /// Get processing duration
  Duration? get processingDuration {
    if (processedAt == null) return null;
    return processedAt!.difference(requestedAt);
  }

  /// Get completion duration
  Duration? get completionDuration {
    if (completedAt == null) return null;
    return completedAt!.difference(requestedAt);
  }

  /// Check if payout can be cancelled
  bool get canBeCancelled => status == PayoutStatus.pending;

  /// Check if payout is in progress
  bool get isInProgress => status == PayoutStatus.processing;

  /// Check if payout is completed
  bool get isCompleted => status == PayoutStatus.completed;

  /// Check if payout has failed
  bool get hasFailed => status == PayoutStatus.failed || status == PayoutStatus.cancelled;

  /// Get status color for UI
  String get statusColor {
    switch (status) {
      case PayoutStatus.pending:
        return 'orange';
      case PayoutStatus.processing:
        return 'blue';
      case PayoutStatus.completed:
        return 'green';
      case PayoutStatus.failed:
      case PayoutStatus.cancelled:
        return 'red';
    }
  }

  /// Get status icon for UI
  String get statusIcon {
    switch (status) {
      case PayoutStatus.pending:
        return 'schedule';
      case PayoutStatus.processing:
        return 'sync';
      case PayoutStatus.completed:
        return 'check_circle';
      case PayoutStatus.failed:
        return 'error';
      case PayoutStatus.cancelled:
        return 'cancel';
    }
  }

  /// Create a test payout request for development
  factory PayoutRequest.test({
    String? id,
    String? walletId,
    double? amount,
    PayoutStatus? status,
  }) {
    final now = DateTime.now();
    final payoutAmount = amount ?? 100.00;
    final processingFee = payoutAmount * 0.01; // 1% fee
    
    return PayoutRequest(
      id: id ?? 'test-payout-id',
      walletId: walletId ?? 'test-wallet-id',
      amount: payoutAmount,
      currency: 'MYR',
      status: status ?? PayoutStatus.pending,
      bankAccountNumber: '1234567890',
      bankName: 'Maybank',
      accountHolderName: 'John Doe',
      processingFee: processingFee,
      netAmount: payoutAmount - processingFee,
      paymentGateway: 'local_bank',
      requestedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }
}

enum PayoutStatus {
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
}

extension PayoutStatusExtension on PayoutStatus {
  String get displayName {
    switch (this) {
      case PayoutStatus.pending:
        return 'Pending';
      case PayoutStatus.processing:
        return 'Processing';
      case PayoutStatus.completed:
        return 'Completed';
      case PayoutStatus.failed:
        return 'Failed';
      case PayoutStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get value {
    switch (this) {
      case PayoutStatus.pending:
        return 'pending';
      case PayoutStatus.processing:
        return 'processing';
      case PayoutStatus.completed:
        return 'completed';
      case PayoutStatus.failed:
        return 'failed';
      case PayoutStatus.cancelled:
        return 'cancelled';
    }
  }

  static PayoutStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return PayoutStatus.pending;
      case 'processing':
        return PayoutStatus.processing;
      case 'completed':
        return PayoutStatus.completed;
      case 'failed':
        return PayoutStatus.failed;
      case 'cancelled':
        return PayoutStatus.cancelled;
      default:
        throw ArgumentError('Invalid payout status: $value');
    }
  }

  bool get isActive => this == PayoutStatus.pending || this == PayoutStatus.processing;
  bool get isFinal => this == PayoutStatus.completed || this == PayoutStatus.failed || this == PayoutStatus.cancelled;
}
