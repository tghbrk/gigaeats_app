import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'customer_wallet.g.dart';

/// Simplified customer wallet model focused on customer-specific operations
@JsonSerializable()
class CustomerWallet extends Equatable {
  final String id;
  final String userId;
  final double availableBalance;
  final double pendingBalance;
  final double totalSpent;
  final String currency;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActivityAt;

  const CustomerWallet({
    required this.id,
    required this.userId,
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalSpent,
    required this.currency,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
    this.lastActivityAt,
  });

  factory CustomerWallet.fromJson(Map<String, dynamic> json) =>
      _$CustomerWalletFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerWalletToJson(this);

  CustomerWallet copyWith({
    String? id,
    String? userId,
    double? availableBalance,
    double? pendingBalance,
    double? totalSpent,
    String? currency,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActivityAt,
  }) {
    return CustomerWallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalSpent: totalSpent ?? this.totalSpent,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        availableBalance,
        pendingBalance,
        totalSpent,
        currency,
        isActive,
        isVerified,
        createdAt,
        updatedAt,
        lastActivityAt,
      ];

  /// Formatted balance display
  String get formattedAvailableBalance => 'RM ${availableBalance.toStringAsFixed(2)}';
  String get formattedPendingBalance => 'RM ${pendingBalance.toStringAsFixed(2)}';
  String get formattedTotalSpent => 'RM ${totalSpent.toStringAsFixed(2)}';

  /// Total balance (available + pending)
  double get totalBalance => availableBalance + pendingBalance;
  String get formattedTotalBalance => 'RM ${totalBalance.toStringAsFixed(2)}';

  /// Check if wallet has sufficient balance for a transaction
  bool hasSufficientBalance(double amount) => availableBalance >= amount;

  /// Get the amount that can be paid with wallet (for split payments)
  double getPayableAmount(double requestedAmount) {
    return requestedAmount <= availableBalance ? requestedAmount : availableBalance;
  }

  /// Get the remaining amount after wallet payment (for split payments)
  double getRemainingAmount(double requestedAmount) {
    final payableAmount = getPayableAmount(requestedAmount);
    return requestedAmount - payableAmount;
  }

  /// Check if wallet needs top-up for a specific amount
  bool needsTopUp(double amount) => !hasSufficientBalance(amount);

  /// Get suggested top-up amount for a transaction
  double getSuggestedTopUpAmount(double requestedAmount) {
    if (hasSufficientBalance(requestedAmount)) return 0.0;
    final deficit = requestedAmount - availableBalance;
    // Round up to nearest RM 10 for convenience
    return ((deficit / 10).ceil() * 10).toDouble();
  }

  /// Check if wallet is healthy (active and verified)
  bool get isHealthy => isActive && isVerified;

  /// Get wallet status description
  String get statusDescription {
    if (!isActive) return 'Wallet is inactive';
    if (!isVerified) return 'Wallet verification pending';
    return 'Wallet is active and verified';
  }

  /// Get wallet activity status
  WalletActivityStatus get activityStatus {
    if (!isActive) return WalletActivityStatus.inactive;
    if (!isVerified) return WalletActivityStatus.unverified;
    if (lastActivityAt == null) return WalletActivityStatus.dormant;

    final daysSinceActivity = DateTime.now().difference(lastActivityAt!).inDays;
    if (daysSinceActivity > 30) return WalletActivityStatus.dormant;
    if (daysSinceActivity > 7) return WalletActivityStatus.lowActivity;
    return WalletActivityStatus.active;
  }

  /// Create a test wallet for development
  factory CustomerWallet.test({
    String? id,
    String? userId,
    double? availableBalance,
    double? totalSpent,
  }) {
    final now = DateTime.now();
    return CustomerWallet(
      id: id ?? 'test-customer-wallet-id',
      userId: userId ?? 'test-customer-user-id',
      availableBalance: availableBalance ?? 150.00,
      pendingBalance: 0.00,
      totalSpent: totalSpent ?? 350.00,
      currency: 'MYR',
      isActive: true,
      isVerified: true,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      lastActivityAt: now.subtract(const Duration(hours: 2)),
    );
  }

  /// Create from StakeholderWallet
  factory CustomerWallet.fromStakeholderWallet(Map<String, dynamic> stakeholderWallet) {
    return CustomerWallet(
      id: stakeholderWallet['id'],
      userId: stakeholderWallet['user_id'],
      availableBalance: (stakeholderWallet['available_balance'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (stakeholderWallet['pending_balance'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (stakeholderWallet['total_withdrawn'] as num?)?.toDouble() ?? 0.0,
      currency: stakeholderWallet['currency'] ?? 'MYR',
      isActive: stakeholderWallet['is_active'] ?? true,
      isVerified: stakeholderWallet['is_verified'] ?? false,
      createdAt: DateTime.parse(stakeholderWallet['created_at']),
      updatedAt: DateTime.parse(stakeholderWallet['updated_at']),
      lastActivityAt: stakeholderWallet['last_activity_at'] != null
          ? DateTime.parse(stakeholderWallet['last_activity_at'])
          : null,
    );
  }
}

/// Customer wallet transaction model
@JsonSerializable()
class CustomerWalletTransaction extends Equatable {
  final String id;
  final String walletId;
  final CustomerTransactionType type;
  final double amount;
  final String currency;
  final double balanceBefore;
  final double balanceAfter;
  final String? description;
  final String? referenceId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const CustomerWalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.balanceBefore,
    required this.balanceAfter,
    this.description,
    this.referenceId,
    this.metadata,
    required this.createdAt,
  });

  factory CustomerWalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$CustomerWalletTransactionFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerWalletTransactionToJson(this);

  @override
  List<Object?> get props => [
        id,
        walletId,
        type,
        amount,
        currency,
        balanceBefore,
        balanceAfter,
        description,
        referenceId,
        metadata,
        createdAt,
      ];

  /// Formatted amount display
  String get formattedAmount => 'RM ${amount.abs().toStringAsFixed(2)}';
  String get formattedBalanceAfter => 'RM ${balanceAfter.toStringAsFixed(2)}';

  /// Check if transaction is a credit (positive) or debit (negative)
  bool get isCredit => amount > 0;
  bool get isDebit => amount < 0;

  /// Get transaction icon based on type
  String get iconName {
    switch (type) {
      case CustomerTransactionType.topUp:
        return 'add_circle';
      case CustomerTransactionType.orderPayment:
        return 'shopping_cart';
      case CustomerTransactionType.refund:
        return 'undo';
      case CustomerTransactionType.transfer:
        return 'send';
      case CustomerTransactionType.adjustment:
        return 'tune';
    }
  }

  /// Create from WalletTransaction
  factory CustomerWalletTransaction.fromWalletTransaction(Map<String, dynamic> walletTransaction) {
    return CustomerWalletTransaction(
      id: walletTransaction['id'],
      walletId: walletTransaction['wallet_id'],
      type: _mapTransactionType(walletTransaction['transaction_type']),
      amount: (walletTransaction['amount'] as num?)?.toDouble() ?? 0.0,
      currency: walletTransaction['currency'] ?? 'MYR',
      balanceBefore: (walletTransaction['balance_before'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (walletTransaction['balance_after'] as num?)?.toDouble() ?? 0.0,
      description: walletTransaction['description'],
      referenceId: walletTransaction['reference_id'],
      metadata: walletTransaction['metadata'],
      createdAt: DateTime.parse(walletTransaction['created_at']),
    );
  }

  static CustomerTransactionType _mapTransactionType(String type) {
    switch (type) {
      case 'credit':
        return CustomerTransactionType.topUp;
      case 'debit':
        return CustomerTransactionType.orderPayment;
      case 'refund':
        return CustomerTransactionType.refund;
      case 'adjustment':
        return CustomerTransactionType.adjustment;
      case 'commission':
        return CustomerTransactionType.adjustment;
      case 'payout':
        return CustomerTransactionType.transfer;
      case 'bonus':
        return CustomerTransactionType.adjustment;
      case 'transfer_in':
        return CustomerTransactionType.transfer;
      case 'transfer_out':
        return CustomerTransactionType.transfer;
      default:
        return CustomerTransactionType.adjustment;
    }
  }
}

/// Customer-specific transaction types
enum CustomerTransactionType {
  topUp,
  orderPayment,
  refund,
  transfer,
  adjustment,
}

extension CustomerTransactionTypeExtension on CustomerTransactionType {
  String get displayName {
    switch (this) {
      case CustomerTransactionType.topUp:
        return 'Top Up';
      case CustomerTransactionType.orderPayment:
        return 'Order Payment';
      case CustomerTransactionType.refund:
        return 'Refund';
      case CustomerTransactionType.transfer:
        return 'Transfer';
      case CustomerTransactionType.adjustment:
        return 'Adjustment';
    }
  }

  String get value {
    switch (this) {
      case CustomerTransactionType.topUp:
        return 'top_up';
      case CustomerTransactionType.orderPayment:
        return 'order_payment';
      case CustomerTransactionType.refund:
        return 'refund';
      case CustomerTransactionType.transfer:
        return 'transfer';
      case CustomerTransactionType.adjustment:
        return 'adjustment';
    }
  }
}

/// Wallet activity status enum
enum WalletActivityStatus {
  active,
  lowActivity,
  dormant,
  inactive,
  unverified,
}

extension WalletActivityStatusExtension on WalletActivityStatus {
  String get displayName {
    switch (this) {
      case WalletActivityStatus.active:
        return 'Active';
      case WalletActivityStatus.lowActivity:
        return 'Low Activity';
      case WalletActivityStatus.dormant:
        return 'Dormant';
      case WalletActivityStatus.inactive:
        return 'Inactive';
      case WalletActivityStatus.unverified:
        return 'Unverified';
    }
  }

  String get description {
    switch (this) {
      case WalletActivityStatus.active:
        return 'Wallet is actively used';
      case WalletActivityStatus.lowActivity:
        return 'Wallet has low recent activity';
      case WalletActivityStatus.dormant:
        return 'Wallet has been inactive for over 30 days';
      case WalletActivityStatus.inactive:
        return 'Wallet is deactivated';
      case WalletActivityStatus.unverified:
        return 'Wallet verification is pending';
    }
  }

  bool get isHealthy {
    switch (this) {
      case WalletActivityStatus.active:
      case WalletActivityStatus.lowActivity:
        return true;
      case WalletActivityStatus.dormant:
      case WalletActivityStatus.inactive:
      case WalletActivityStatus.unverified:
        return false;
    }
  }
}
