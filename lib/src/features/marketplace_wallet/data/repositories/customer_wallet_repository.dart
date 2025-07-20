import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';

import '../../../../data/repositories/base_repository.dart';
import '../../../../core/errors/failures.dart';
import '../models/customer_wallet.dart';

/// Customer-focused wallet repository that provides direct database access
/// for customer-specific wallet operations
class CustomerWalletRepository extends BaseRepository {
  CustomerWalletRepository({
    super.client,
  });

  /// Get customer wallet for current user
  Future<Either<Failure, CustomerWallet?>> getCustomerWallet() async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [CUSTOMER-WALLET-REPO] === GETTING CUSTOMER WALLET ===');

      // Get current user
      debugPrint('🔍 [CUSTOMER-WALLET-REPO] Getting current user from auth...');
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        debugPrint('🔍 [CUSTOMER-WALLET-REPO] ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [CUSTOMER-WALLET-REPO] Current user ID: ${currentUser.id}');
      debugPrint('🔍 [CUSTOMER-WALLET-REPO] Current user email: ${currentUser.email}');

      // Log session information for debugging
      final session = client.auth.currentSession;
      if (session != null) {
        debugPrint('🔍 [CUSTOMER-WALLET-REPO] Session expires at: ${session.expiresAt}');
        debugPrint('🔍 [CUSTOMER-WALLET-REPO] Session is expired: ${session.isExpired}');
        debugPrint('🔍 [CUSTOMER-WALLET-REPO] Access token length: ${session.accessToken.length}');
      } else {
        debugPrint('⚠️ [CUSTOMER-WALLET-REPO] No session found');
      }

      // Query wallet directly from database
      final queryStartTime = DateTime.now();
      debugPrint('🔍 [CUSTOMER-WALLET-REPO] Executing wallet query at ${queryStartTime.toIso8601String()}...');
      debugPrint('🔍 [CUSTOMER-WALLET-REPO] Query: SELECT specific_fields FROM stakeholder_wallets WHERE user_id = ${currentUser.id} AND user_role = customer');

      final response = await client
          .from('stakeholder_wallets')
          .select('''
            id,
            user_id,
            available_balance,
            pending_balance,
            total_withdrawn,
            currency,
            is_active,
            is_verified,
            created_at,
            updated_at,
            last_activity_at
          ''')
          .eq('user_id', currentUser.id)
          .eq('user_role', 'customer')
          .maybeSingle();

      final queryEndTime = DateTime.now();
      final queryDuration = queryEndTime.difference(queryStartTime);
      debugPrint('🔍 [CUSTOMER-WALLET-REPO] Query completed in ${queryDuration.inMilliseconds}ms, response: ${response?.toString() ?? 'NULL'}');

      if (response == null) {
        debugPrint('🔍 [CUSTOMER-WALLET-REPO] No wallet found for customer');
        return null;
      }

      final customerWallet = CustomerWallet(
        id: response['id'],
        userId: response['user_id'],
        availableBalance: (response['available_balance'] as num?)?.toDouble() ?? 0.0,
        pendingBalance: (response['pending_balance'] as num?)?.toDouble() ?? 0.0,
        totalSpent: (response['total_withdrawn'] as num?)?.toDouble() ?? 0.0,
        currency: response['currency'] ?? 'MYR',
        isActive: response['is_active'] ?? true,
        isVerified: response['is_verified'] ?? false,
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        lastActivityAt: response['last_activity_at'] != null
            ? DateTime.parse(response['last_activity_at'])
            : null,
      );

      debugPrint('🔍 [CUSTOMER-WALLET-REPO] Customer wallet found: ${customerWallet.formattedAvailableBalance}');
      return customerWallet;
    });
  }

  /// Get customer wallet stream for real-time updates
  Stream<CustomerWallet?> getCustomerWalletStream() {
    return executeStreamQuery(() {
      debugPrint('🔍 [CUSTOMER-WALLET-REPO-STREAM] Setting up customer wallet stream');

      // Get current user
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        return Stream.error(Exception('User not authenticated'));
      }

      return client
          .from('stakeholder_wallets')
          .stream(primaryKey: ['id'])
          .map((data) {
            // Efficiently filter for current user and customer role
            for (final item in data) {
              if (item['user_id'] == currentUser.id && item['user_role'] == 'customer') {
                return CustomerWallet(
                  id: item['id'],
                  userId: item['user_id'],
                  availableBalance: (item['available_balance'] as num?)?.toDouble() ?? 0.0,
                  pendingBalance: (item['pending_balance'] as num?)?.toDouble() ?? 0.0,
                  totalSpent: (item['total_withdrawn'] as num?)?.toDouble() ?? 0.0,
                  currency: item['currency'] ?? 'MYR',
                  isActive: item['is_active'] ?? true,
                  isVerified: item['is_verified'] ?? false,
                  createdAt: DateTime.parse(item['created_at']),
                  updatedAt: DateTime.parse(item['updated_at']),
                  lastActivityAt: item['last_activity_at'] != null
                      ? DateTime.parse(item['last_activity_at'])
                      : null,
                );
              }
            }
            return null;
          });
    });
  }

  /// Get customer wallet transactions with pagination
  Future<Either<Failure, List<CustomerWalletTransaction>>> getCustomerTransactions({
    int limit = 50, // Increased limit to include older credit transactions
    int offset = 0,
    CustomerTransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [CUSTOMER-WALLET-REPO] Getting customer transactions');

      // First get the customer wallet to get the wallet ID
      final walletResult = await getCustomerWallet();

      return walletResult.fold(
        (failure) => throw Exception('Failed to get wallet: ${failure.message}'),
        (customerWallet) async {
          if (customerWallet == null) {
            throw Exception('Customer wallet not found');
          }

          // Query transactions directly from database
          debugPrint('🔍 [CUSTOMER-WALLET-REPO] Querying wallet_transactions for wallet_id: ${customerWallet.id}');
          debugPrint('🔍 [CUSTOMER-WALLET-REPO] Query params - limit: $limit, offset: $offset');

          var queryBuilder = client
              .from('wallet_transactions')
              .select('*')
              .eq('wallet_id', customerWallet.id)
              .order('created_at', ascending: false);

          // Apply pagination
          final response = await queryBuilder.range(offset, offset + limit - 1);
          debugPrint('🔍 [CUSTOMER-WALLET-REPO] Raw database response: ${response.length} transactions found');

          if (response.isNotEmpty) {
            debugPrint('🔍 [CUSTOMER-WALLET-REPO] Sample transaction types: ${response.take(3).map((t) => t['transaction_type']).toList()}');
          }

          final customerTransactions = response
              .map((json) => CustomerWalletTransaction(
                    id: json['id'],
                    walletId: json['wallet_id'],
                    type: _mapToCustomerTransactionType(json['transaction_type']),
                    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
                    currency: json['currency'] ?? 'MYR',
                    balanceBefore: (json['balance_before'] as num?)?.toDouble() ?? 0.0,
                    balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0.0,
                    description: json['description'],
                    referenceId: json['reference_id'],
                    metadata: json['metadata'],
                    createdAt: DateTime.parse(json['created_at']),
                  ))
              .toList();

          debugPrint('🔍 [CUSTOMER-WALLET-REPO] Mapped ${customerTransactions.length} customer transactions');
          if (customerTransactions.isNotEmpty) {
            final topUpTransactions = customerTransactions.where((t) => t.type == CustomerTransactionType.topUp).length;
            debugPrint('🔍 [CUSTOMER-WALLET-REPO] Found $topUpTransactions top-up transactions');
          }
          return customerTransactions;
        },
      );
    });
  }

  /// Get customer wallet transactions stream for real-time updates
  Stream<List<CustomerWalletTransaction>> getCustomerTransactionsStream({
    int limit = 20,
    CustomerTransactionType? type,
  }) {
    return executeStreamQuery(() async* {
      debugPrint('🔍 [CUSTOMER-WALLET-REPO-STREAM] Setting up customer transactions stream');

      // First get the customer wallet to get the wallet ID
      final walletResult = await getCustomerWallet();

      await for (final result in walletResult.fold(
        (failure) => Stream.error(Exception('Failed to get wallet: ${failure.message}')),
        (customerWallet) {
          if (customerWallet == null) {
            return Stream.error(Exception('Customer wallet not found'));
          }

          return client
              .from('wallet_transactions')
              .stream(primaryKey: ['id'])
              .map((data) {
                // Filter for current wallet and apply limit
                final filtered = data.where((item) =>
                    item['wallet_id'] == customerWallet.id).toList();

                // Sort by created_at descending and limit
                filtered.sort((a, b) => DateTime.parse(b['created_at'])
                    .compareTo(DateTime.parse(a['created_at'])));

                final limited = filtered.take(limit).toList();

                return limited
                    .map((json) => CustomerWalletTransaction(
                          id: json['id'],
                          walletId: json['wallet_id'],
                          type: _mapToCustomerTransactionType(json['transaction_type']),
                          amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
                          currency: json['currency'] ?? 'MYR',
                          balanceBefore: (json['balance_before'] as num?)?.toDouble() ?? 0.0,
                          balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0.0,
                          description: json['description'],
                          referenceId: json['reference_id'],
                          metadata: json['metadata'],
                          createdAt: DateTime.parse(json['created_at']),
                        ))
                    .toList();
              });
        },
      )) {
        yield result;
      }
    });
  }

  /// Check if customer has sufficient balance for a transaction
  Future<Either<Failure, bool>> hasSufficientBalance(double amount) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [CUSTOMER-WALLET-REPO] Checking sufficient balance for amount: $amount');

      final walletResult = await getCustomerWallet();
      
      return walletResult.fold(
        (failure) => throw Exception('Failed to get wallet: ${failure.message}'),
        (customerWallet) {
          if (customerWallet == null) {
            return false;
          }

          final hasSufficient = customerWallet.hasSufficientBalance(amount);
          debugPrint('🔍 [CUSTOMER-WALLET-REPO] Sufficient balance check: $hasSufficient');
          return hasSufficient;
        },
      );
    });
  }

  /// Map wallet transaction type string to customer transaction type
  CustomerTransactionType _mapToCustomerTransactionType(String type) {
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
