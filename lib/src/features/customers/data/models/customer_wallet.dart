import 'package:equatable/equatable.dart';

/// Customer transaction type enum
enum CustomerTransactionType {
  topup,
  payment,
  transfer,
  refund,
  commission,
  withdrawal,
}

/// Customer wallet transactions state
class CustomerWalletTransactionsState extends Equatable {
  final List<CustomerWalletTransaction> transactions;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const CustomerWalletTransactionsState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 0,
  });

  CustomerWalletTransactionsState copyWith({
    List<CustomerWalletTransaction>? transactions,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return CustomerWalletTransactionsState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [transactions, isLoading, error, hasMore, currentPage];
}

/// Customer wallet transaction model
class CustomerWalletTransaction extends Equatable {
  final String id;
  final String walletId;
  final CustomerTransactionType type;
  final double amount;
  final String description;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const CustomerWalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.metadata,
  });

  factory CustomerWalletTransaction.fromJson(Map<String, dynamic> json) {
    return CustomerWalletTransaction(
      id: json['id'] as String,
      walletId: json['wallet_id'] as String,
      type: CustomerTransactionType.values.firstWhere(
        (e) => e.name == json['transaction_type'],
        orElse: () => CustomerTransactionType.payment,
      ),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'transaction_type': type.name,
      'amount': amount,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [id, walletId, type, amount, description, createdAt, metadata];
}

/// Customer wallet model
class CustomerWallet extends Equatable {
  final String id;
  final String userId;
  final double availableBalance;
  final double pendingBalance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerWallet({
    required this.id,
    required this.userId,
    required this.availableBalance,
    required this.pendingBalance,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerWallet.fromJson(Map<String, dynamic> json) {
    return CustomerWallet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      availableBalance: (json['available_balance'] as num).toDouble(),
      pendingBalance: (json['pending_balance'] as num).toDouble(),
      currency: json['currency'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'available_balance': availableBalance,
      'pending_balance': pendingBalance,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CustomerWallet copyWith({
    String? id,
    String? userId,
    double? availableBalance,
    double? pendingBalance,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerWallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, availableBalance, pendingBalance, currency, createdAt, updatedAt];
}
