import 'package:flutter/foundation.dart';

import '../../../../core/data/repositories/base_repository.dart';
import 'enhanced_driver_wallet_service.dart';
import '../repositories/driver_wallet_repository.dart';

/// Service for handling failed wallet deposits and retry mechanisms
/// Ensures earnings are eventually deposited into driver wallets even if initial attempts fail
class WalletDepositRetryService extends BaseRepository {
  final EnhancedDriverWalletService _walletService;

  WalletDepositRetryService({
    EnhancedDriverWalletService? walletService,
  }) : _walletService = walletService ?? EnhancedDriverWalletService(DriverWalletRepository());

  /// Retry failed wallet deposits for earnings records without corresponding wallet transactions
  Future<List<String>> retryFailedDeposits({
    int limit = 50,
    Duration maxAge = const Duration(days: 7),
  }) async {
    return executeQuery(() async {
      debugPrint('🔄 [WALLET-DEPOSIT-RETRY] Starting retry process for failed deposits');
      
      final cutoffDate = DateTime.now().subtract(maxAge);
      final successfulRetries = <String>[];
      
      // Find earnings records without corresponding wallet transactions
      final failedDeposits = await _findFailedDeposits(cutoffDate, limit);
      
      debugPrint('🔄 [WALLET-DEPOSIT-RETRY] Found ${failedDeposits.length} failed deposits to retry');
      
      for (final earningsRecord in failedDeposits) {
        try {
          await _retryWalletDeposit(earningsRecord);
          successfulRetries.add(earningsRecord['order_id'] as String);
          debugPrint('✅ [WALLET-DEPOSIT-RETRY] Successfully retried deposit for order: ${earningsRecord['order_id']}');
        } catch (e) {
          debugPrint('❌ [WALLET-DEPOSIT-RETRY] Failed to retry deposit for order: ${earningsRecord['order_id']} - $e');
        }
      }
      
      debugPrint('✅ [WALLET-DEPOSIT-RETRY] Retry process completed: ${successfulRetries.length}/${failedDeposits.length} successful');
      return successfulRetries;
    });
  }

  /// Find earnings records that don't have corresponding wallet transactions
  Future<List<Map<String, dynamic>>> _findFailedDeposits(DateTime cutoffDate, int limit) async {
    debugPrint('🔍 [WALLET-DEPOSIT-RETRY] Finding failed deposits since ${cutoffDate.toIso8601String()}');
    
    // Query earnings records that don't have corresponding wallet transactions
    final response = await supabase
        .from('driver_earnings')
        .select('''
          order_id,
          driver_id,
          gross_earnings,
          net_earnings,
          base_commission,
          completion_bonus,
          peak_hour_bonus,
          rating_bonus,
          other_bonuses,
          deductions,
          created_at
        ''')
        .gte('created_at', cutoffDate.toIso8601String())
        .eq('earnings_type', 'delivery_completion')
        .order('created_at', ascending: false)
        .limit(limit * 2); // Get more records to filter

    // Filter out records that already have wallet transactions
    final failedDeposits = <Map<String, dynamic>>[];
    
    for (final earningsRecord in response) {
      final orderId = earningsRecord['order_id'] as String;
      
      // Check if wallet transaction exists for this order
      final existingTransaction = await supabase
          .from('wallet_transactions')
          .select('id')
          .eq('reference_id', orderId)
          .eq('reference_type', 'order')
          .eq('transaction_type', 'delivery_earnings')
          .maybeSingle();
      
      if (existingTransaction == null) {
        failedDeposits.add(earningsRecord);
        if (failedDeposits.length >= limit) break;
      }
    }
    
    return failedDeposits;
  }

  /// Retry wallet deposit for a specific earnings record
  Future<void> _retryWalletDeposit(Map<String, dynamic> earningsRecord) async {
    final orderId = earningsRecord['order_id'] as String;
    final grossEarnings = (earningsRecord['gross_earnings'] as num?)?.toDouble() ?? 0.0;
    final netEarnings = (earningsRecord['net_earnings'] as num?)?.toDouble() ?? 0.0;
    
    debugPrint('🔄 [WALLET-DEPOSIT-RETRY] Retrying deposit for order: $orderId');
    debugPrint('🔄 [WALLET-DEPOSIT-RETRY] Net earnings: RM ${netEarnings.toStringAsFixed(2)}');
    
    if (netEarnings <= 0) {
      debugPrint('⚠️ [WALLET-DEPOSIT-RETRY] Skipping order with no net earnings: $orderId');
      return;
    }
    
    // Build earnings breakdown from the record
    final earningsBreakdown = {
      'gross_earnings': grossEarnings,
      'net_earnings': netEarnings,
      'base_commission': (earningsRecord['base_commission'] as num?)?.toDouble() ?? 0.0,
      'completion_bonus': (earningsRecord['completion_bonus'] as num?)?.toDouble() ?? 0.0,
      'peak_hour_bonus': (earningsRecord['peak_hour_bonus'] as num?)?.toDouble() ?? 0.0,
      'rating_bonus': (earningsRecord['rating_bonus'] as num?)?.toDouble() ?? 0.0,
      'other_bonuses': (earningsRecord['other_bonuses'] as num?)?.toDouble() ?? 0.0,
      'deductions': (earningsRecord['deductions'] as num?)?.toDouble() ?? 0.0,
      'retry_attempt': true,
      'original_created_at': earningsRecord['created_at'],
    };
    
    // Process the wallet deposit
    await _walletService.processEarningsDeposit(
      orderId: orderId,
      grossEarnings: grossEarnings,
      netEarnings: netEarnings,
      earningsBreakdown: earningsBreakdown,
    );
  }

  /// Get statistics about failed deposits
  Future<Map<String, dynamic>> getFailedDepositStats({
    Duration period = const Duration(days: 30),
  }) async {
    return executeQuery(() async {
      debugPrint('📊 [WALLET-DEPOSIT-RETRY] Getting failed deposit statistics');
      
      final cutoffDate = DateTime.now().subtract(period);
      
      // Get total earnings records
      final totalEarningsResponse = await supabase
          .from('driver_earnings')
          .select('id')
          .gte('created_at', cutoffDate.toIso8601String())
          .eq('earnings_type', 'delivery_completion');

      final totalEarnings = totalEarningsResponse.length;

      // Get successful wallet transactions
      final successfulTransactionsResponse = await supabase
          .from('wallet_transactions')
          .select('id')
          .gte('created_at', cutoffDate.toIso8601String())
          .eq('transaction_type', 'delivery_earnings');

      final successfulTransactions = successfulTransactionsResponse.length;
      
      final failedDeposits = totalEarnings - successfulTransactions;
      final successRate = totalEarnings > 0 ? (successfulTransactions / totalEarnings * 100) : 100.0;
      
      final stats = {
        'period_days': period.inDays,
        'total_earnings_records': totalEarnings,
        'successful_deposits': successfulTransactions,
        'failed_deposits': failedDeposits,
        'success_rate_percentage': successRate,
        'generated_at': DateTime.now().toIso8601String(),
      };
      
      debugPrint('📊 [WALLET-DEPOSIT-RETRY] Stats: ${(stats['success_rate_percentage'] as double).toStringAsFixed(1)}% success rate');
      return stats;
    });
  }

  /// Manually retry deposit for a specific order
  Future<bool> retryDepositForOrder(String orderId) async {
    return executeQuery(() async {
      debugPrint('🔄 [WALLET-DEPOSIT-RETRY] Manual retry for order: $orderId');
      
      // Get the earnings record
      final earningsRecord = await supabase
          .from('driver_earnings')
          .select('*')
          .eq('order_id', orderId)
          .eq('earnings_type', 'delivery_completion')
          .maybeSingle();
      
      if (earningsRecord == null) {
        throw Exception('Earnings record not found for order: $orderId');
      }
      
      // Check if deposit already exists
      final existingTransaction = await supabase
          .from('wallet_transactions')
          .select('id')
          .eq('reference_id', orderId)
          .eq('reference_type', 'order')
          .eq('transaction_type', 'delivery_earnings')
          .maybeSingle();
      
      if (existingTransaction != null) {
        debugPrint('⚠️ [WALLET-DEPOSIT-RETRY] Deposit already exists for order: $orderId');
        return false;
      }
      
      // Retry the deposit
      await _retryWalletDeposit(earningsRecord);
      debugPrint('✅ [WALLET-DEPOSIT-RETRY] Manual retry successful for order: $orderId');
      return true;
    });
  }

  /// Schedule automatic retry for failed deposits
  /// This could be called by a background job or cron task
  Future<void> scheduleAutomaticRetry() async {
    debugPrint('⏰ [WALLET-DEPOSIT-RETRY] Starting scheduled automatic retry');
    
    try {
      final retriedOrders = await retryFailedDeposits(
        limit: 100, // Process up to 100 failed deposits per run
        maxAge: const Duration(days: 7), // Only retry deposits from last 7 days
      );
      
      if (retriedOrders.isNotEmpty) {
        debugPrint('✅ [WALLET-DEPOSIT-RETRY] Scheduled retry completed: ${retriedOrders.length} orders processed');
        
        // TODO: Send notification to admin about successful retries
        // TODO: Log metrics for monitoring
      } else {
        debugPrint('ℹ️ [WALLET-DEPOSIT-RETRY] No failed deposits found to retry');
      }
    } catch (e) {
      debugPrint('❌ [WALLET-DEPOSIT-RETRY] Scheduled retry failed: $e');
      // TODO: Send alert to admin about retry service failure
    }
  }
}
