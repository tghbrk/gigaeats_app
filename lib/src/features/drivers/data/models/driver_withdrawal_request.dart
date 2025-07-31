import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'driver_withdrawal_request.g.dart';

/// Driver withdrawal request status enumeration
enum DriverWithdrawalStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled;

  String get displayName {
    switch (this) {
      case DriverWithdrawalStatus.pending:
        return 'Pending';
      case DriverWithdrawalStatus.processing:
        return 'Processing';
      case DriverWithdrawalStatus.completed:
        return 'Completed';
      case DriverWithdrawalStatus.failed:
        return 'Failed';
      case DriverWithdrawalStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get colorHex {
    switch (this) {
      case DriverWithdrawalStatus.pending:
        return '#FF9800'; // Orange
      case DriverWithdrawalStatus.processing:
        return '#2196F3'; // Blue
      case DriverWithdrawalStatus.completed:
        return '#4CAF50'; // Green
      case DriverWithdrawalStatus.failed:
        return '#F44336'; // Red
      case DriverWithdrawalStatus.cancelled:
        return '#9E9E9E'; // Grey
    }
  }
}

/// Driver withdrawal request model
@JsonSerializable()
class DriverWithdrawalRequest extends Equatable {
  final String id;
  @JsonKey(name: 'driver_id')
  final String driverId;
  @JsonKey(name: 'wallet_id')
  final String walletId;
  
  // Request details
  final double amount;
  @JsonKey(name: 'withdrawal_method')
  final String withdrawalMethod;
  
  // Status tracking
  @JsonKey(name: 'status')
  final DriverWithdrawalStatus status;
  
  // Processing details
  @JsonKey(name: 'requested_at')
  final DateTime requestedAt;
  @JsonKey(name: 'processed_at')
  final DateTime? processedAt;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  
  // Payment details
  @JsonKey(name: 'destination_details')
  final Map<String, dynamic> destinationDetails;
  @JsonKey(name: 'transaction_reference')
  final String? transactionReference;
  @JsonKey(name: 'processing_fee')
  final double processingFee;
  @JsonKey(name: 'net_amount')
  final double netAmount;
  
  // Audit trail
  @JsonKey(name: 'processed_by')
  final String? processedBy;
  @JsonKey(name: 'failure_reason')
  final String? failureReason;
  final String? notes;
  final Map<String, dynamic>? metadata;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const DriverWithdrawalRequest({
    required this.id,
    required this.driverId,
    required this.walletId,
    required this.amount,
    required this.withdrawalMethod,
    this.status = DriverWithdrawalStatus.pending,
    required this.requestedAt,
    this.processedAt,
    this.completedAt,
    required this.destinationDetails,
    this.transactionReference,
    this.processingFee = 0.00,
    required this.netAmount,
    this.processedBy,
    this.failureReason,
    this.notes,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverWithdrawalRequest.fromJson(Map<String, dynamic> json) =>
      _$DriverWithdrawalRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DriverWithdrawalRequestToJson(this);

  @override
  List<Object?> get props => [
        id,
        driverId,
        walletId,
        amount,
        withdrawalMethod,
        status,
        requestedAt,
        processedAt,
        completedAt,
        destinationDetails,
        transactionReference,
        processingFee,
        netAmount,
        processedBy,
        failureReason,
        notes,
        metadata,
        createdAt,
        updatedAt,
      ];

  /// Formatted amount display
  String get formattedAmount => 'RM ${amount.toStringAsFixed(2)}';

  /// Formatted net amount display
  String get formattedNetAmount => 'RM ${netAmount.toStringAsFixed(2)}';

  /// Formatted processing fee display
  String get formattedProcessingFee => 'RM ${processingFee.toStringAsFixed(2)}';

  /// Get withdrawal method display name
  String get withdrawalMethodDisplayName {
    switch (withdrawalMethod) {
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'ewallet':
        return 'E-Wallet';
      case 'cash':
        return 'Cash Pickup';
      default:
        return 'Unknown';
    }
  }

  /// Check if request is in a final state
  bool get isFinalState => 
      status == DriverWithdrawalStatus.completed ||
      status == DriverWithdrawalStatus.failed ||
      status == DriverWithdrawalStatus.cancelled;

  /// Check if request can be cancelled
  bool get canBeCancelled => 
      status == DriverWithdrawalStatus.pending;

  /// Get processing duration if completed
  Duration? get processingDuration {
    if (processedAt == null || completedAt == null) return null;
    return completedAt!.difference(processedAt!);
  }

  /// Get total request duration if completed
  Duration? get totalDuration {
    if (completedAt == null) return null;
    return completedAt!.difference(requestedAt);
  }

  /// Get destination account summary for display
  String get destinationSummary {
    switch (withdrawalMethod) {
      case 'bank_transfer':
        final bankName = destinationDetails['bank_name'] as String?;
        final accountNumber = destinationDetails['account_number'] as String?;
        if (bankName != null && accountNumber != null) {
          final maskedAccount = accountNumber.length > 4 
              ? '****${accountNumber.substring(accountNumber.length - 4)}'
              : accountNumber;
          return '$bankName - $maskedAccount';
        }
        return 'Bank Transfer';
      case 'ewallet':
        final provider = destinationDetails['provider'] as String?;
        final accountId = destinationDetails['account_id'] as String?;
        if (provider != null && accountId != null) {
          final maskedId = accountId.length > 4 
              ? '****${accountId.substring(accountId.length - 4)}'
              : accountId;
          return '$provider - $maskedId';
        }
        return 'E-Wallet';
      case 'cash':
        return 'Cash Pickup';
      default:
        return 'Unknown Method';
    }
  }

  /// Create a test withdrawal request for development
  factory DriverWithdrawalRequest.test({
    String? id,
    String? driverId,
    String? walletId,
    double? amount,
    DriverWithdrawalStatus? status,
  }) {
    final now = DateTime.now();
    final requestAmount = amount ?? 100.00;
    
    return DriverWithdrawalRequest(
      id: id ?? 'test-withdrawal-request-id',
      driverId: driverId ?? 'test-driver-id',
      walletId: walletId ?? 'test-wallet-id',
      amount: requestAmount,
      withdrawalMethod: 'bank_transfer',
      status: status ?? DriverWithdrawalStatus.pending,
      requestedAt: now.subtract(const Duration(hours: 2)),
      destinationDetails: {
        'bank_name': 'Test Bank',
        'account_number': '1234567890',
        'account_holder': 'Test Driver',
      },
      processingFee: 0.00,
      netAmount: requestAmount,
      notes: 'Test withdrawal request',
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now,
    );
  }

  /// Copy with method for updates
  DriverWithdrawalRequest copyWith({
    String? id,
    String? driverId,
    String? walletId,
    double? amount,
    String? withdrawalMethod,
    DriverWithdrawalStatus? status,
    DateTime? requestedAt,
    DateTime? processedAt,
    DateTime? completedAt,
    Map<String, dynamic>? destinationDetails,
    String? transactionReference,
    double? processingFee,
    double? netAmount,
    String? processedBy,
    String? failureReason,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverWithdrawalRequest(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      walletId: walletId ?? this.walletId,
      amount: amount ?? this.amount,
      withdrawalMethod: withdrawalMethod ?? this.withdrawalMethod,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      completedAt: completedAt ?? this.completedAt,
      destinationDetails: destinationDetails ?? this.destinationDetails,
      transactionReference: transactionReference ?? this.transactionReference,
      processingFee: processingFee ?? this.processingFee,
      netAmount: netAmount ?? this.netAmount,
      processedBy: processedBy ?? this.processedBy,
      failureReason: failureReason ?? this.failureReason,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
