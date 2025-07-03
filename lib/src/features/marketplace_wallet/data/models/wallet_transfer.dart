import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wallet_transfer.g.dart';

/// Enum for transfer status
enum TransferStatus {
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
  @JsonValue('reversed')
  reversed,
}

/// Wallet transfer model for customer-to-customer transfers
@JsonSerializable()
class WalletTransfer extends Equatable {
  final String id;
  final String senderWalletId;
  final String recipientWalletId;
  final String senderUserId;
  final String recipientUserId;
  final double amount;
  final String currency;
  final double transferFee;
  final double netAmount;
  final String? description;
  final String referenceNumber;
  final TransferStatus status;
  final double senderBalanceBefore;
  final double senderBalanceAfter;
  final double recipientBalanceBefore;
  final double recipientBalanceAfter;
  final DateTime? processedAt;
  final DateTime? failedAt;
  final String? failureReason;
  final DateTime? reversedAt;
  final String? reversalReason;
  final String? senderTransactionId;
  final String? recipientTransactionId;
  final Map<String, dynamic>? metadata;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Profile information (populated from joins)
  final Map<String, dynamic>? senderProfile;
  final Map<String, dynamic>? recipientProfile;

  const WalletTransfer({
    required this.id,
    required this.senderWalletId,
    required this.recipientWalletId,
    required this.senderUserId,
    required this.recipientUserId,
    required this.amount,
    required this.currency,
    required this.transferFee,
    required this.netAmount,
    this.description,
    required this.referenceNumber,
    required this.status,
    required this.senderBalanceBefore,
    required this.senderBalanceAfter,
    required this.recipientBalanceBefore,
    required this.recipientBalanceAfter,
    this.processedAt,
    this.failedAt,
    this.failureReason,
    this.reversedAt,
    this.reversalReason,
    this.senderTransactionId,
    this.recipientTransactionId,
    this.metadata,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
    required this.updatedAt,
    this.senderProfile,
    this.recipientProfile,
  });

  factory WalletTransfer.fromJson(Map<String, dynamic> json) =>
      _$WalletTransferFromJson(json);

  Map<String, dynamic> toJson() => _$WalletTransferToJson(this);

  WalletTransfer copyWith({
    String? id,
    String? senderWalletId,
    String? recipientWalletId,
    String? senderUserId,
    String? recipientUserId,
    double? amount,
    String? currency,
    double? transferFee,
    double? netAmount,
    String? description,
    String? referenceNumber,
    TransferStatus? status,
    double? senderBalanceBefore,
    double? senderBalanceAfter,
    double? recipientBalanceBefore,
    double? recipientBalanceAfter,
    DateTime? processedAt,
    DateTime? failedAt,
    String? failureReason,
    DateTime? reversedAt,
    String? reversalReason,
    String? senderTransactionId,
    String? recipientTransactionId,
    Map<String, dynamic>? metadata,
    String? ipAddress,
    String? userAgent,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? senderProfile,
    Map<String, dynamic>? recipientProfile,
  }) {
    return WalletTransfer(
      id: id ?? this.id,
      senderWalletId: senderWalletId ?? this.senderWalletId,
      recipientWalletId: recipientWalletId ?? this.recipientWalletId,
      senderUserId: senderUserId ?? this.senderUserId,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      transferFee: transferFee ?? this.transferFee,
      netAmount: netAmount ?? this.netAmount,
      description: description ?? this.description,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      status: status ?? this.status,
      senderBalanceBefore: senderBalanceBefore ?? this.senderBalanceBefore,
      senderBalanceAfter: senderBalanceAfter ?? this.senderBalanceAfter,
      recipientBalanceBefore: recipientBalanceBefore ?? this.recipientBalanceBefore,
      recipientBalanceAfter: recipientBalanceAfter ?? this.recipientBalanceAfter,
      processedAt: processedAt ?? this.processedAt,
      failedAt: failedAt ?? this.failedAt,
      failureReason: failureReason ?? this.failureReason,
      reversedAt: reversedAt ?? this.reversedAt,
      reversalReason: reversalReason ?? this.reversalReason,
      senderTransactionId: senderTransactionId ?? this.senderTransactionId,
      recipientTransactionId: recipientTransactionId ?? this.recipientTransactionId,
      metadata: metadata ?? this.metadata,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      senderProfile: senderProfile ?? this.senderProfile,
      recipientProfile: recipientProfile ?? this.recipientProfile,
    );
  }

  @override
  List<Object?> get props => [
        id,
        senderWalletId,
        recipientWalletId,
        senderUserId,
        recipientUserId,
        amount,
        currency,
        transferFee,
        netAmount,
        description,
        referenceNumber,
        status,
        senderBalanceBefore,
        senderBalanceAfter,
        recipientBalanceBefore,
        recipientBalanceAfter,
        processedAt,
        failedAt,
        failureReason,
        reversedAt,
        reversalReason,
        senderTransactionId,
        recipientTransactionId,
        metadata,
        ipAddress,
        userAgent,
        createdAt,
        updatedAt,
        senderProfile,
        recipientProfile,
      ];

  /// Get formatted amount display
  String get formattedAmount => 'RM ${amount.toStringAsFixed(2)}';
  String get formattedTransferFee => 'RM ${transferFee.toStringAsFixed(2)}';
  String get formattedNetAmount => 'RM ${netAmount.toStringAsFixed(2)}';

  /// Get status display information
  String get statusDisplayName {
    switch (status) {
      case TransferStatus.pending:
        return 'Pending';
      case TransferStatus.processing:
        return 'Processing';
      case TransferStatus.completed:
        return 'Completed';
      case TransferStatus.failed:
        return 'Failed';
      case TransferStatus.cancelled:
        return 'Cancelled';
      case TransferStatus.reversed:
        return 'Reversed';
    }
  }

  /// Get status color for UI
  String get statusColor {
    switch (status) {
      case TransferStatus.pending:
        return 'orange';
      case TransferStatus.processing:
        return 'blue';
      case TransferStatus.completed:
        return 'green';
      case TransferStatus.failed:
        return 'red';
      case TransferStatus.cancelled:
        return 'grey';
      case TransferStatus.reversed:
        return 'purple';
    }
  }

  /// Check if transfer is in progress
  bool get isInProgress => status == TransferStatus.pending || status == TransferStatus.processing;

  /// Check if transfer is completed
  bool get isCompleted => status == TransferStatus.completed;

  /// Check if transfer has failed
  bool get hasFailed => status == TransferStatus.failed;

  /// Check if transfer can be cancelled
  bool get canBeCancelled => status == TransferStatus.pending;

  /// Get sender name from profile
  String get senderName {
    if (senderProfile != null && senderProfile!['full_name'] != null) {
      return senderProfile!['full_name'] as String;
    }
    return 'Unknown Sender';
  }

  /// Get recipient name from profile
  String get recipientName {
    if (recipientProfile != null && recipientProfile!['full_name'] != null) {
      return recipientProfile!['full_name'] as String;
    }
    return 'Unknown Recipient';
  }

  /// Get sender email from profile
  String? get senderEmail {
    if (senderProfile != null && senderProfile!['email'] != null) {
      return senderProfile!['email'] as String;
    }
    return null;
  }

  /// Get recipient email from profile
  String? get recipientEmail {
    if (recipientProfile != null && recipientProfile!['email'] != null) {
      return recipientProfile!['email'] as String;
    }
    return null;
  }

  /// Get formatted date display
  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Get transfer direction for current user
  String getTransferDirection(String currentUserId) {
    if (senderUserId == currentUserId) {
      return 'sent';
    } else if (recipientUserId == currentUserId) {
      return 'received';
    } else {
      return 'unknown';
    }
  }

  /// Get other party name for current user
  String getOtherPartyName(String currentUserId) {
    if (senderUserId == currentUserId) {
      return recipientName;
    } else if (recipientUserId == currentUserId) {
      return senderName;
    } else {
      return 'Unknown';
    }
  }

  /// Create a test transfer for development
  factory WalletTransfer.test({
    String? id,
    String? senderUserId,
    String? recipientUserId,
    double? amount,
    TransferStatus? status,
    String? description,
  }) {
    final now = DateTime.now();
    final transferAmount = amount ?? 100.00;
    final fee = 1.00;

    return WalletTransfer(
      id: id ?? 'test-transfer-id',
      senderWalletId: 'test-sender-wallet-id',
      recipientWalletId: 'test-recipient-wallet-id',
      senderUserId: senderUserId ?? 'test-sender-user-id',
      recipientUserId: recipientUserId ?? 'test-recipient-user-id',
      amount: transferAmount,
      currency: 'MYR',
      transferFee: fee,
      netAmount: transferAmount - fee,
      description: description ?? 'Test transfer',
      referenceNumber: 'TXF${now.millisecondsSinceEpoch}',
      status: status ?? TransferStatus.completed,
      senderBalanceBefore: 500.00,
      senderBalanceAfter: 500.00 - transferAmount,
      recipientBalanceBefore: 200.00,
      recipientBalanceAfter: 200.00 + (transferAmount - fee),
      processedAt: status == TransferStatus.completed ? now : null,
      createdAt: now.subtract(const Duration(minutes: 30)),
      updatedAt: now,
      senderProfile: {
        'full_name': 'John Doe',
        'email': 'john@example.com',
      },
      recipientProfile: {
        'full_name': 'Jane Smith',
        'email': 'jane@example.com',
      },
    );
  }

  /// Create multiple test transfers
  static List<WalletTransfer> testList({
    String? currentUserId,
    int count = 5,
  }) {
    return List.generate(count, (index) {
      final isSender = index % 2 == 0;
      return WalletTransfer.test(
        id: 'test-transfer-$index',
        senderUserId: isSender ? currentUserId : 'other-user-$index',
        recipientUserId: isSender ? 'other-user-$index' : currentUserId,
        amount: (index + 1) * 50.0,
        status: index == 0 ? TransferStatus.pending : TransferStatus.completed,
        description: 'Test transfer ${index + 1}',
      );
    });
  }
}
