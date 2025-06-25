import 'package:equatable/equatable.dart';

/// Model representing a wallet-to-wallet transfer
class CustomerWalletTransfer extends Equatable {
  final String id;
  final String senderUserId;
  final String recipientUserId;
  final String recipientIdentifier; // Email or phone used to identify recipient
  final double amount;
  final String? note;
  final String status; // pending, completed, failed, cancelled
  final String? failureReason;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  const CustomerWalletTransfer({
    required this.id,
    required this.senderUserId,
    required this.recipientUserId,
    required this.recipientIdentifier,
    required this.amount,
    this.note,
    required this.status,
    this.failureReason,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });

  /// Create a CustomerWalletTransfer from JSON
  factory CustomerWalletTransfer.fromJson(Map<String, dynamic> json) {
    return CustomerWalletTransfer(
      id: json['id'] as String,
      senderUserId: json['sender_user_id'] as String,
      recipientUserId: json['recipient_user_id'] as String,
      recipientIdentifier: json['recipient_identifier'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      status: json['status'] as String,
      failureReason: json['failure_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert CustomerWalletTransfer to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_user_id': senderUserId,
      'recipient_user_id': recipientUserId,
      'recipient_identifier': recipientIdentifier,
      'amount': amount,
      'note': note,
      'status': status,
      'failure_reason': failureReason,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  CustomerWalletTransfer copyWith({
    String? id,
    String? senderUserId,
    String? recipientUserId,
    String? recipientIdentifier,
    double? amount,
    String? note,
    String? status,
    String? failureReason,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return CustomerWalletTransfer(
      id: id ?? this.id,
      senderUserId: senderUserId ?? this.senderUserId,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      recipientIdentifier: recipientIdentifier ?? this.recipientIdentifier,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      status: status ?? this.status,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get formatted amount string
  String get formattedAmount => 'RM ${amount.toStringAsFixed(2)}';

  /// Check if transfer is completed
  bool get isCompleted => status == 'completed';

  /// Check if transfer is pending
  bool get isPending => status == 'pending';

  /// Check if transfer failed
  bool get isFailed => status == 'failed';

  /// Check if transfer was cancelled
  bool get isCancelled => status == 'cancelled';

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  /// Get status color for UI
  String get statusColor {
    switch (status) {
      case 'completed':
        return 'success';
      case 'pending':
        return 'warning';
      case 'failed':
      case 'cancelled':
        return 'error';
      default:
        return 'info';
    }
  }

  /// Get transfer direction text for display
  String getDirectionText(String currentUserId) {
    if (senderUserId == currentUserId) {
      return 'Sent to $recipientIdentifier';
    } else {
      return 'Received from $recipientIdentifier';
    }
  }

  /// Check if current user is the sender
  bool isSender(String currentUserId) {
    return senderUserId == currentUserId;
  }

  /// Check if current user is the recipient
  bool isRecipient(String currentUserId) {
    return recipientUserId == currentUserId;
  }

  /// Get the other party's identifier
  String getOtherPartyIdentifier(String currentUserId) {
    return recipientIdentifier;
  }

  /// Get transfer fee (if any)
  double get transferFee {
    if (metadata != null && metadata!.containsKey('transfer_fee')) {
      return (metadata!['transfer_fee'] as num).toDouble();
    }
    return 0.0;
  }

  /// Get formatted transfer fee
  String get formattedTransferFee {
    final fee = transferFee;
    return fee > 0 ? 'RM ${fee.toStringAsFixed(2)}' : 'Free';
  }

  /// Get total amount including fees
  double get totalAmount => amount + transferFee;

  /// Get formatted total amount
  String get formattedTotalAmount => 'RM ${totalAmount.toStringAsFixed(2)}';

  @override
  List<Object?> get props => [
        id,
        senderUserId,
        recipientUserId,
        recipientIdentifier,
        amount,
        note,
        status,
        failureReason,
        createdAt,
        completedAt,
        metadata,
      ];

  @override
  String toString() {
    return 'CustomerWalletTransfer('
        'id: $id, '
        'senderUserId: $senderUserId, '
        'recipientUserId: $recipientUserId, '
        'recipientIdentifier: $recipientIdentifier, '
        'amount: $amount, '
        'status: $status, '
        'createdAt: $createdAt'
        ')';
  }

  /// Create a test instance for development
  factory CustomerWalletTransfer.test({
    String? id,
    String? senderUserId,
    String? recipientUserId,
    String? recipientIdentifier,
    double? amount,
    String? note,
    String? status,
    DateTime? createdAt,
  }) {
    return CustomerWalletTransfer(
      id: id ?? 'transfer_test_123',
      senderUserId: senderUserId ?? 'user_sender_123',
      recipientUserId: recipientUserId ?? 'user_recipient_456',
      recipientIdentifier: recipientIdentifier ?? 'recipient@example.com',
      amount: amount ?? 50.0,
      note: note ?? 'Test transfer',
      status: status ?? 'completed',
      createdAt: createdAt ?? DateTime.now(),
      completedAt: status == 'completed' ? DateTime.now() : null,
    );
  }
}

/// Transfer status constants
class TransferStatus {
  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String cancelled = 'cancelled';

  static const List<String> all = [
    pending,
    completed,
    failed,
    cancelled,
  ];

  static bool isValid(String status) {
    return all.contains(status);
  }
}

/// Transfer limits model
class TransferLimits extends Equatable {
  final double dailyLimit;
  final double weeklyLimit;
  final double monthlyLimit;
  final double perTransactionLimit;
  final double minimumAmount;
  final double maximumAmount;

  const TransferLimits({
    required this.dailyLimit,
    required this.weeklyLimit,
    required this.monthlyLimit,
    required this.perTransactionLimit,
    required this.minimumAmount,
    required this.maximumAmount,
  });

  factory TransferLimits.fromJson(Map<String, dynamic> json) {
    return TransferLimits(
      dailyLimit: (json['daily_limit'] as num).toDouble(),
      weeklyLimit: (json['weekly_limit'] as num).toDouble(),
      monthlyLimit: (json['monthly_limit'] as num).toDouble(),
      perTransactionLimit: (json['per_transaction_limit'] as num).toDouble(),
      minimumAmount: (json['minimum_amount'] as num).toDouble(),
      maximumAmount: (json['maximum_amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_limit': dailyLimit,
      'weekly_limit': weeklyLimit,
      'monthly_limit': monthlyLimit,
      'per_transaction_limit': perTransactionLimit,
      'minimum_amount': minimumAmount,
      'maximum_amount': maximumAmount,
    };
  }

  @override
  List<Object?> get props => [
        dailyLimit,
        weeklyLimit,
        monthlyLimit,
        perTransactionLimit,
        minimumAmount,
        maximumAmount,
      ];

  /// Create default transfer limits
  factory TransferLimits.defaults() {
    return const TransferLimits(
      dailyLimit: 1000.0,
      weeklyLimit: 5000.0,
      monthlyLimit: 20000.0,
      perTransactionLimit: 500.0,
      minimumAmount: 1.0,
      maximumAmount: 500.0,
    );
  }
}
