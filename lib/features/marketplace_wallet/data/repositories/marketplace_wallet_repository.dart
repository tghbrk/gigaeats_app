import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../data/repositories/base_repository.dart';
import '../../../../core/errors/failures.dart';
import '../models/stakeholder_wallet.dart';
import '../models/wallet_transaction.dart';
import '../models/payout_request.dart';
import '../models/commission_breakdown.dart';

class MarketplaceWalletRepository extends BaseRepository {

  MarketplaceWalletRepository({super.client});

  /// Get stakeholder wallet for current user
  Future<Either<Failure, StakeholderWallet?>> getWallet(String userRole) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [WALLET-REPO] Getting wallet for user role: $userRole');

      final response = await client
          .from('stakeholder_wallets')
          .select('*')
          .eq('user_id', currentUserUid!)
          .eq('user_role', userRole)
          .maybeSingle();

      if (response == null) {
        debugPrint('🔍 [WALLET-REPO] No wallet found for user');
        return null;
      }

      final wallet = StakeholderWallet.fromJson(response);
      debugPrint('🔍 [WALLET-REPO] Wallet found: ${wallet.formattedAvailableBalance}');
      return wallet;
    });
  }

  /// Get wallet stream for real-time updates
  Stream<StakeholderWallet?> getWalletStream(String userRole) {
    return executeStreamQuery(() {
      debugPrint('🔍 [WALLET-REPO-STREAM] Setting up wallet stream for role: $userRole');

      return client
          .from('stakeholder_wallets')
          .stream(primaryKey: ['id'])
          .map((data) {
            // Filter data for current user and role
            final filtered = data.where((item) =>
                item['user_id'] == currentUserUid &&
                item['user_role'] == userRole).toList();

            if (filtered.isEmpty) return null;
            return StakeholderWallet.fromJson(filtered.first);
          });
    });
  }

  /// Get wallet transactions with pagination
  Future<Either<Failure, List<WalletTransaction>>> getWalletTransactions({
    required String walletId,
    int limit = 20,
    int offset = 0,
    WalletTransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [WALLET-REPO] Getting transactions for wallet: $walletId');

      // Build query with all filters applied before ordering
      var queryBuilder = client
          .from('wallet_transactions')
          .select('*')
          .eq('wallet_id', walletId);

      // Apply filters if provided
      if (type != null) {
        queryBuilder = queryBuilder.eq('transaction_type', type.value);
      }

      if (startDate != null) {
        queryBuilder = queryBuilder.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        queryBuilder = queryBuilder.lte('created_at', endDate.toIso8601String());
      }

      // Execute query with ordering and pagination
      final response = await queryBuilder
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final transactions = response
          .map((json) => WalletTransaction.fromJson(json))
          .toList();

      debugPrint('🔍 [WALLET-REPO] Found ${transactions.length} transactions');
      return transactions;
    });
  }

  /// Get wallet transactions stream for real-time updates
  Stream<List<WalletTransaction>> getWalletTransactionsStream({
    required String walletId,
    int limit = 20,
    WalletTransactionType? type,
  }) {
    return executeStreamQuery(() {
      debugPrint('🔍 [WALLET-REPO-STREAM] Setting up transactions stream for wallet: $walletId');

      // Create stream with filters applied correctly using dynamic type
      dynamic streamQuery = client
          .from('wallet_transactions')
          .stream(primaryKey: ['id'])
          .eq('wallet_id', walletId)
          .order('created_at', ascending: false)
          .limit(limit);

      // Apply type filter if provided
      if (type != null) {
        streamQuery = streamQuery.eq('transaction_type', type.value);
      }

      return streamQuery.map((data) =>
          data.map((json) => WalletTransaction.fromJson(json)).toList());
    });
  }

  /// Get payout requests for wallet
  Future<Either<Failure, List<PayoutRequest>>> getPayoutRequests({
    required String walletId,
    int limit = 20,
    int offset = 0,
    PayoutStatus? status,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [WALLET-REPO] Getting payout requests for wallet: $walletId');

      var query = client
          .from('payout_requests')
          .select('*')
          .eq('wallet_id', walletId);

      // Apply status filter if provided
      if (status != null) {
        query = query.eq('status', status.value);
      }

      // Execute query with ordering and pagination
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final payoutRequests = response
          .map((json) => PayoutRequest.fromJson(json))
          .toList();

      debugPrint('🔍 [WALLET-REPO] Found ${payoutRequests.length} payout requests');
      return payoutRequests;
    });
  }

  /// Create payout request
  Future<Either<Failure, PayoutRequest>> createPayoutRequest({
    required double amount,
    required String bankAccountNumber,
    required String bankName,
    required String accountHolderName,
    String? swiftCode,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [WALLET-REPO] Creating payout request for amount: $amount');

      final response = await client.functions.invoke(
        'process-payout-request',
        body: {
          'amount': amount,
          'bank_account_number': bankAccountNumber,
          'bank_name': bankName,
          'account_holder_name': accountHolderName,
          'swift_code': swiftCode,
          'currency': 'MYR',
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to create payout request: ${response.data}');
      }

      final result = response.data;
      if (!result['success']) {
        throw Exception(result['error'] ?? 'Unknown error occurred');
      }

      // Fetch the created payout request
      final payoutResponse = await client
          .from('payout_requests')
          .select('*')
          .eq('id', result['payout_request_id'])
          .single();

      final payoutRequest = PayoutRequest.fromJson(payoutResponse);
      debugPrint('🔍 [WALLET-REPO] Payout request created: ${payoutRequest.id}');
      return payoutRequest;
    });
  }

  /// Update wallet settings
  Future<Either<Failure, StakeholderWallet>> updateWalletSettings({
    required String walletId,
    bool? autoPayoutEnabled,
    double? autoPayoutThreshold,
    String? payoutSchedule,
    Map<String, dynamic>? bankAccountDetails,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [WALLET-REPO] Updating wallet settings for: $walletId');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (autoPayoutEnabled != null) {
        updateData['auto_payout_enabled'] = autoPayoutEnabled;
      }

      if (autoPayoutThreshold != null) {
        updateData['auto_payout_threshold'] = autoPayoutThreshold;
      }

      if (payoutSchedule != null) {
        updateData['payout_schedule'] = payoutSchedule;
      }

      if (bankAccountDetails != null) {
        updateData['bank_account_details'] = bankAccountDetails;
      }

      final response = await client
          .from('stakeholder_wallets')
          .update(updateData)
          .eq('id', walletId)
          .select()
          .single();

      final wallet = StakeholderWallet.fromJson(response);
      debugPrint('🔍 [WALLET-REPO] Wallet settings updated successfully');
      return wallet;
    });
  }

  /// Get commission breakdown for order
  Future<Either<Failure, CommissionBreakdown>> getCommissionBreakdown({
    required String orderId,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [WALLET-REPO] Getting commission breakdown for order: $orderId');

      // Get escrow account for the order
      final escrowResponse = await client
          .from('escrow_accounts')
          .select('*')
          .eq('order_id', orderId)
          .maybeSingle();

      if (escrowResponse == null) {
        throw Exception('No commission breakdown found for order');
      }

      final breakdown = CommissionBreakdown(
        totalAmount: escrowResponse['total_amount']?.toDouble() ?? 0.0,
        vendorAmount: escrowResponse['vendor_amount']?.toDouble() ?? 0.0,
        platformFee: escrowResponse['platform_fee']?.toDouble() ?? 0.0,
        salesAgentCommission: escrowResponse['sales_agent_commission']?.toDouble() ?? 0.0,
        driverCommission: escrowResponse['driver_commission']?.toDouble() ?? 0.0,
        deliveryFee: escrowResponse['delivery_fee']?.toDouble() ?? 0.0,
        currency: escrowResponse['currency'] ?? 'MYR',
        orderId: orderId,
        calculatedAt: DateTime.parse(escrowResponse['created_at']),
      );

      debugPrint('🔍 [WALLET-REPO] Commission breakdown retrieved: ${breakdown.formattedTotalAmount}');
      return breakdown;
    });
  }

  /// Get wallet analytics/summary
  Future<Either<Failure, WalletAnalytics>> getWalletAnalytics({
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [WALLET-REPO] Getting wallet analytics for: $walletId');

      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Get transaction summary
      final transactionsResponse = await client
          .from('wallet_transactions')
          .select('transaction_type, amount')
          .eq('wallet_id', walletId)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

      double totalCredits = 0;
      double totalDebits = 0;
      int transactionCount = 0;

      for (final transaction in transactionsResponse) {
        final amount = transaction['amount']?.toDouble() ?? 0.0;
        transactionCount++;

        if (amount > 0) {
          totalCredits += amount;
        } else {
          totalDebits += amount.abs();
        }
      }

      final analytics = WalletAnalytics(
        walletId: walletId,
        totalCredits: totalCredits,
        totalDebits: totalDebits,
        netAmount: totalCredits - totalDebits,
        transactionCount: transactionCount,
        periodStart: start,
        periodEnd: end,
      );

      debugPrint('🔍 [WALLET-REPO] Analytics retrieved: ${analytics.transactionCount} transactions');
      return analytics;
    });
  }
}

/// Wallet analytics data class
class WalletAnalytics extends Equatable {
  final String walletId;
  final double totalCredits;
  final double totalDebits;
  final double netAmount;
  final int transactionCount;
  final DateTime periodStart;
  final DateTime periodEnd;

  const WalletAnalytics({
    required this.walletId,
    required this.totalCredits,
    required this.totalDebits,
    required this.netAmount,
    required this.transactionCount,
    required this.periodStart,
    required this.periodEnd,
  });

  @override
  List<Object?> get props => [
        walletId,
        totalCredits,
        totalDebits,
        netAmount,
        transactionCount,
        periodStart,
        periodEnd,
      ];

  String get formattedTotalCredits => 'MYR ${totalCredits.toStringAsFixed(2)}';
  String get formattedTotalDebits => 'MYR ${totalDebits.toStringAsFixed(2)}';
  String get formattedNetAmount => 'MYR ${netAmount.toStringAsFixed(2)}';
}
