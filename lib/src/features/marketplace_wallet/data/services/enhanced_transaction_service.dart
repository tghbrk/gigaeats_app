import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/repositories/base_repository.dart';
import '../models/customer_wallet.dart';

/// Enhanced transaction service with advanced filtering and search
class EnhancedTransactionService extends BaseRepository {
  EnhancedTransactionService({super.client});

  /// Get customer transactions with advanced filtering
  Future<Either<Failure, List<CustomerWalletTransaction>>> getCustomerTransactions({
    int limit = 20,
    int offset = 0,
    CustomerTransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    double? minAmount,
    double? maxAmount,
    String? sortBy = 'created_at',
    bool ascending = false,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ENHANCED-TRANSACTION-SERVICE] Getting customer transactions with filters');

      // First get the customer wallet to get the wallet ID
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final walletResponse = await client
          .from('stakeholder_wallets')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('user_role', 'customer')
          .maybeSingle();

      if (walletResponse == null) {
        throw Exception('Customer wallet not found');
      }

      final walletId = walletResponse['id'];

      // Build query with filters
      var queryBuilder = client
          .from('wallet_transactions')
          .select('*')
          .eq('wallet_id', walletId);

      // Apply filters
      if (type != null) {
        final dbType = _mapCustomerTransactionTypeToDb(type);
        queryBuilder = queryBuilder.eq('transaction_type', dbType);
      }

      if (startDate != null) {
        queryBuilder = queryBuilder.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        queryBuilder = queryBuilder.lte('created_at', endDate.toIso8601String());
      }

      if (minAmount != null) {
        queryBuilder = queryBuilder.gte('amount', minAmount);
      }

      if (maxAmount != null) {
        queryBuilder = queryBuilder.lte('amount', maxAmount);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('description', '%$searchQuery%');
      }

      // Apply sorting and pagination
      final response = await queryBuilder
          .order(sortBy ?? 'created_at', ascending: ascending)
          .range(offset, offset + limit - 1);

      final transactions = response
          .map((json) => CustomerWalletTransaction.fromWalletTransaction(json))
          .toList();

      debugPrint('🔍 [ENHANCED-TRANSACTION-SERVICE] Found ${transactions.length} transactions');
      return transactions;
    });
  }

  /// Get customer transactions stream for real-time updates
  Stream<Either<Failure, List<CustomerWalletTransaction>>> getCustomerTransactionsStream({
    int limit = 20,
    CustomerTransactionType? type,
  }) {
    return executeStreamQuery(() async* {
      debugPrint('🔍 [ENHANCED-TRANSACTION-SERVICE] Setting up customer transactions stream');

      try {
        // Get wallet ID first
        final currentUser = client.auth.currentUser;
        if (currentUser == null) {
          yield const Left(AuthFailure(message: 'User not authenticated'));
          return;
        }

        final walletResponse = await client
            .from('stakeholder_wallets')
            .select('id')
            .eq('user_id', currentUser.id)
            .eq('user_role', 'customer')
            .maybeSingle();

        if (walletResponse == null) {
          yield const Left(ValidationFailure(message: 'Customer wallet not found'));
          return;
        }

        final walletId = walletResponse['id'];

        // Set up stream
        await for (final data in client
            .from('wallet_transactions')
            .stream(primaryKey: ['id'])) {
          try {
            // Filter for current wallet
            final filtered = data.where((item) =>
                item['wallet_id'] == walletId).toList();

            // Apply type filter if specified
            if (type != null) {
              final dbType = _mapCustomerTransactionTypeToDb(type);
              filtered.removeWhere((item) => item['transaction_type'] != dbType);
            }

            // Sort by created_at descending and limit
            filtered.sort((a, b) => DateTime.parse(b['created_at'])
                .compareTo(DateTime.parse(a['created_at'])));

            final limited = filtered.take(limit).toList();

            final transactions = limited
                .map((json) => CustomerWalletTransaction.fromWalletTransaction(json))
                .toList();

            yield Right(transactions);
          } catch (e) {
            debugPrint('❌ [ENHANCED-TRANSACTION-SERVICE] Stream error: $e');
            yield Left(UnexpectedFailure(message: e.toString()));
          }
        }
      } catch (e) {
        debugPrint('❌ [ENHANCED-TRANSACTION-SERVICE] Stream setup error: $e');
        yield Left(UnexpectedFailure(message: e.toString()));
      }
    });
  }

  /// Search transactions by description or reference
  Future<Either<Failure, List<CustomerWalletTransaction>>> searchTransactions({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ENHANCED-TRANSACTION-SERVICE] Searching transactions for: $query');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final walletResponse = await client
          .from('stakeholder_wallets')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('user_role', 'customer')
          .maybeSingle();

      if (walletResponse == null) {
        throw Exception('Customer wallet not found');
      }

      final walletId = walletResponse['id'];

      // Search in description and reference_id
      final response = await client
          .from('wallet_transactions')
          .select('*')
          .eq('wallet_id', walletId)
          .or('description.ilike.%$query%,reference_id.ilike.%$query%')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final transactions = response
          .map((json) => CustomerWalletTransaction.fromWalletTransaction(json))
          .toList();

      debugPrint('🔍 [ENHANCED-TRANSACTION-SERVICE] Found ${transactions.length} matching transactions');
      return transactions;
    });
  }

  /// Get transaction statistics
  Future<Either<Failure, TransactionStatistics>> getTransactionStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ENHANCED-TRANSACTION-SERVICE] Getting transaction statistics');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final walletResponse = await client
          .from('stakeholder_wallets')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('user_role', 'customer')
          .maybeSingle();

      if (walletResponse == null) {
        throw Exception('Customer wallet not found');
      }

      final walletId = walletResponse['id'];

      // Build query with date filters
      var queryBuilder = client
          .from('wallet_transactions')
          .select('transaction_type, amount, created_at')
          .eq('wallet_id', walletId);

      if (startDate != null) {
        queryBuilder = queryBuilder.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        queryBuilder = queryBuilder.lte('created_at', endDate.toIso8601String());
      }

      final response = await queryBuilder;

      // Calculate statistics
      double totalTopUps = 0.0;
      double totalSpent = 0.0;
      double totalRefunds = 0.0;
      int topUpCount = 0;
      int spentCount = 0;
      int refundCount = 0;

      for (final transaction in response) {
        final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
        final type = transaction['transaction_type'] as String;

        switch (type) {
          case 'credit':
            totalTopUps += amount;
            topUpCount++;
            break;
          case 'debit':
            totalSpent += amount.abs();
            spentCount++;
            break;
          case 'refund':
            totalRefunds += amount;
            refundCount++;
            break;
        }
      }

      return TransactionStatistics(
        totalTopUps: totalTopUps,
        totalSpent: totalSpent,
        totalRefunds: totalRefunds,
        topUpCount: topUpCount,
        spentCount: spentCount,
        refundCount: refundCount,
        totalTransactions: response.length,
        averageTopUp: topUpCount > 0 ? totalTopUps / topUpCount : 0.0,
        averageSpent: spentCount > 0 ? totalSpent / spentCount : 0.0,
      );
    });
  }

  /// Export transactions to CSV format
  Future<Either<Failure, String>> exportTransactionsToCSV({
    DateTime? startDate,
    DateTime? endDate,
    CustomerTransactionType? type,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ENHANCED-TRANSACTION-SERVICE] Exporting transactions to CSV');

      final transactionsResult = await getCustomerTransactions(
        limit: 10000, // Large limit for export
        startDate: startDate,
        endDate: endDate,
        type: type,
        sortBy: 'created_at',
        ascending: true,
      );

      return transactionsResult.fold(
        (failure) => throw Exception('Failed to get transactions: ${failure.message}'),
        (transactions) {
          final csvHeader = 'Date,Type,Description,Amount,Balance After,Reference ID\n';
          final csvRows = transactions.map((transaction) {
            final date = transaction.createdAt.toIso8601String().split('T')[0];
            final transactionType = transaction.type.displayName;
            final description = transaction.description?.replaceAll(',', ';') ?? '';
            final amount = transaction.formattedAmount;
            final balanceAfter = transaction.formattedBalanceAfter;
            final referenceId = transaction.referenceId ?? '';

            return '$date,$transactionType,"$description",$amount,$balanceAfter,$referenceId';
          }).join('\n');

          return csvHeader + csvRows;
        },
      );
    });
  }

  /// Map customer transaction type to database type
  String _mapCustomerTransactionTypeToDb(CustomerTransactionType type) {
    switch (type) {
      case CustomerTransactionType.topUp:
        return 'credit';
      case CustomerTransactionType.orderPayment:
        return 'debit';
      case CustomerTransactionType.refund:
        return 'refund';
      case CustomerTransactionType.transfer:
        return 'payout';
      case CustomerTransactionType.adjustment:
        return 'adjustment';
    }
  }
}

/// Transaction statistics model
class TransactionStatistics {
  final double totalTopUps;
  final double totalSpent;
  final double totalRefunds;
  final int topUpCount;
  final int spentCount;
  final int refundCount;
  final int totalTransactions;
  final double averageTopUp;
  final double averageSpent;

  const TransactionStatistics({
    required this.totalTopUps,
    required this.totalSpent,
    required this.totalRefunds,
    required this.topUpCount,
    required this.spentCount,
    required this.refundCount,
    required this.totalTransactions,
    required this.averageTopUp,
    required this.averageSpent,
  });

  String get formattedTotalTopUps => 'RM ${totalTopUps.toStringAsFixed(2)}';
  String get formattedTotalSpent => 'RM ${totalSpent.toStringAsFixed(2)}';
  String get formattedTotalRefunds => 'RM ${totalRefunds.toStringAsFixed(2)}';
  String get formattedAverageTopUp => 'RM ${averageTopUp.toStringAsFixed(2)}';
  String get formattedAverageSpent => 'RM ${averageSpent.toStringAsFixed(2)}';

  double get netAmount => totalTopUps + totalRefunds - totalSpent;
  String get formattedNetAmount => 'RM ${netAmount.toStringAsFixed(2)}';
}
