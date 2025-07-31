import 'package:flutter/foundation.dart';

import '../../../../core/data/repositories/base_repository.dart';
import 'enhanced_driver_wallet_service.dart';
import 'wallet_deposit_retry_service.dart';
import 'driver_wallet_notification_service.dart';
import '../repositories/driver_wallet_repository.dart';

/// Comprehensive service for integrating driver earnings with wallet system
/// Provides high-level operations for earnings-to-wallet transfers and monitoring
class EarningsWalletIntegrationService extends BaseRepository {
  final EnhancedDriverWalletService _walletService;
  final WalletDepositRetryService _retryService;
  final DriverWalletNotificationService? _notificationService;

  EarningsWalletIntegrationService({
    EnhancedDriverWalletService? walletService,
    WalletDepositRetryService? retryService,
    DriverWalletNotificationService? notificationService,
  }) : _walletService = walletService ?? EnhancedDriverWalletService(DriverWalletRepository()),
       _retryService = retryService ?? WalletDepositRetryService(),
       _notificationService = notificationService;

  /// Process complete earnings-to-wallet flow for order completion
  /// This is the main entry point for earnings integration
  Future<EarningsWalletResult> processOrderEarningsToWallet({
    required String orderId,
    required String driverId,
    required Map<String, dynamic> earningsData,
    bool retryOnFailure = true,
  }) async {
    return executeQuery(() async {
      debugPrint('💰 [EARNINGS-WALLET-INTEGRATION] Processing earnings to wallet');
      debugPrint('💰 [EARNINGS-WALLET-INTEGRATION] Order: $orderId, Driver: $driverId');
      
      final grossEarnings = earningsData['gross_earnings']?.toDouble() ?? 0.0;
      final netEarnings = earningsData['net_earnings']?.toDouble() ?? 0.0;
      
      debugPrint('💰 [EARNINGS-WALLET-INTEGRATION] Gross: RM ${grossEarnings.toStringAsFixed(2)}, Net: RM ${netEarnings.toStringAsFixed(2)}');
      
      // Validate earnings data
      if (netEarnings <= 0) {
        debugPrint('⚠️ [EARNINGS-WALLET-INTEGRATION] No net earnings to process');
        return EarningsWalletResult.noEarnings(orderId, 'No net earnings to deposit');
      }
      
      try {
        // Ensure driver has a wallet
        final wallet = await _walletService.getOrCreateDriverWallet();
        debugPrint('💰 [EARNINGS-WALLET-INTEGRATION] Driver wallet confirmed: ${wallet.id}');
        
        // Process the earnings deposit
        await _walletService.processEarningsDeposit(
          orderId: orderId,
          grossEarnings: grossEarnings,
          netEarnings: netEarnings,
          earningsBreakdown: earningsData,
        );

        debugPrint('✅ [EARNINGS-WALLET-INTEGRATION] Earnings deposited successfully');

        // Get updated wallet balance for notification
        final updatedWallet = await _walletService.getDriverWallet();
        final newBalance = updatedWallet?.availableBalance ?? 0.0;

        // Send earnings notification if service is available
        if (_notificationService != null) {
          try {
            await _notificationService.sendEarningsNotification(
              driverId: driverId,
              orderId: orderId,
              earningsAmount: netEarnings,
              newBalance: newBalance,
              earningsBreakdown: earningsData,
            );
            debugPrint('✅ [EARNINGS-WALLET-INTEGRATION] Earnings notification sent');
          } catch (notificationError) {
            debugPrint('⚠️ [EARNINGS-WALLET-INTEGRATION] Failed to send earnings notification: $notificationError');
            // Don't fail the entire operation for notification errors
          }
        }

        return EarningsWalletResult.success(
          orderId: orderId,
          walletId: wallet.id,
          amountDeposited: netEarnings,
          message: 'Earnings deposited successfully',
        );
        
      } catch (e) {
        debugPrint('❌ [EARNINGS-WALLET-INTEGRATION] Deposit failed: $e');
        
        if (retryOnFailure) {
          // Schedule for retry
          debugPrint('🔄 [EARNINGS-WALLET-INTEGRATION] Scheduling retry for order: $orderId');
          // The retry service will pick this up later
        }
        
        return EarningsWalletResult.failure(
          orderId: orderId,
          error: e.toString(),
          canRetry: retryOnFailure,
        );
      }
    });
  }

  /// Get earnings and wallet summary for a driver
  Future<DriverEarningsWalletSummary> getDriverEarningsWalletSummary(String driverId) async {
    return executeQuery(() async {
      debugPrint('📊 [EARNINGS-WALLET-INTEGRATION] Getting summary for driver: $driverId');
      
      // Get driver's wallet
      final wallet = await _walletService.getDriverWallet();
      
      // Get earnings statistics
      final earningsStats = await _getDriverEarningsStats(driverId);
      
      // Get recent transactions
      final recentTransactions = await _getRecentWalletTransactions(wallet?.id);
      
      // Get failed deposits count
      final failedDepositsCount = await _getFailedDepositsCount(driverId);
      
      return DriverEarningsWalletSummary(
        driverId: driverId,
        wallet: wallet,
        totalEarningsThisMonth: earningsStats['total_earnings_this_month'] ?? 0.0,
        totalDepositsThisMonth: earningsStats['total_deposits_this_month'] ?? 0.0,
        pendingDeposits: failedDepositsCount,
        recentTransactionCount: recentTransactions.length,
        lastDepositAt: earningsStats['last_deposit_at'],
        walletCreatedAt: wallet?.createdAt,
      );
    });
  }

  /// Get driver earnings statistics
  Future<Map<String, dynamic>> _getDriverEarningsStats(String driverId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    // Get earnings for current month
    final earningsResponse = await supabase
        .from('driver_earnings')
        .select('net_earnings, created_at')
        .eq('driver_id', driverId)
        .gte('created_at', startOfMonth.toIso8601String())
        .order('created_at', ascending: false);
    
    double totalEarnings = 0.0;
    DateTime? lastEarningAt;
    
    for (final earning in earningsResponse) {
      totalEarnings += (earning['net_earnings'] as num?)?.toDouble() ?? 0.0;
      lastEarningAt ??= DateTime.parse(earning['created_at']);
    }
    
    // Get wallet deposits for current month
    final depositsResponse = await supabase
        .from('wallet_transactions')
        .select('amount, created_at')
        .eq('transaction_type', 'delivery_earnings')
        .gte('created_at', startOfMonth.toIso8601String())
        .order('created_at', ascending: false);
    
    double totalDeposits = 0.0;
    DateTime? lastDepositAt;
    
    for (final deposit in depositsResponse) {
      totalDeposits += (deposit['amount'] as num?)?.toDouble() ?? 0.0;
      lastDepositAt ??= DateTime.parse(deposit['created_at']);
    }
    
    return {
      'total_earnings_this_month': totalEarnings,
      'total_deposits_this_month': totalDeposits,
      'last_earning_at': lastEarningAt?.toIso8601String(),
      'last_deposit_at': lastDepositAt?.toIso8601String(),
    };
  }

  /// Get recent wallet transactions
  Future<List<Map<String, dynamic>>> _getRecentWalletTransactions(String? walletId) async {
    if (walletId == null) return [];
    
    final response = await supabase
        .from('wallet_transactions')
        .select('id, amount, transaction_type, created_at')
        .eq('wallet_id', walletId)
        .order('created_at', ascending: false)
        .limit(10);
    
    return response;
  }

  /// Get count of failed deposits for a driver
  Future<int> _getFailedDepositsCount(String driverId) async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    
    // Get earnings without corresponding wallet transactions
    final earningsResponse = await supabase
        .from('driver_earnings')
        .select('order_id')
        .eq('driver_id', driverId)
        .gte('created_at', cutoffDate.toIso8601String())
        .eq('earnings_type', 'delivery_completion');
    
    int failedCount = 0;
    
    for (final earning in earningsResponse) {
      final orderId = earning['order_id'] as String;
      
      final transactionExists = await supabase
          .from('wallet_transactions')
          .select('id')
          .eq('reference_id', orderId)
          .eq('transaction_type', 'delivery_earnings')
          .maybeSingle();
      
      if (transactionExists == null) {
        failedCount++;
      }
    }
    
    return failedCount;
  }

  /// Retry failed deposits for a specific driver
  Future<List<String>> retryFailedDepositsForDriver(String driverId) async {
    return executeQuery(() async {
      debugPrint('🔄 [EARNINGS-WALLET-INTEGRATION] Retrying failed deposits for driver: $driverId');
      
      // This would need to be implemented in the retry service
      // For now, use the general retry mechanism
      final retriedOrders = await _retryService.retryFailedDeposits(limit: 50);
      
      debugPrint('✅ [EARNINGS-WALLET-INTEGRATION] Retried ${retriedOrders.length} deposits');
      return retriedOrders;
    });
  }

  /// Get integration health status
  Future<Map<String, dynamic>> getIntegrationHealthStatus() async {
    return executeQuery(() async {
      debugPrint('🏥 [EARNINGS-WALLET-INTEGRATION] Checking integration health');
      
      final stats = await _retryService.getFailedDepositStats(
        period: const Duration(days: 7),
      );
      
      final successRate = stats['success_rate_percentage'] as double;
      final failedDeposits = stats['failed_deposits'] as int;
      
      String healthStatus;
      if (successRate >= 95.0) {
        healthStatus = 'healthy';
      } else if (successRate >= 90.0) {
        healthStatus = 'warning';
      } else {
        healthStatus = 'critical';
      }
      
      return {
        'status': healthStatus,
        'success_rate': successRate,
        'failed_deposits_count': failedDeposits,
        'total_earnings_processed': stats['total_earnings_records'],
        'last_check': DateTime.now().toIso8601String(),
        'recommendations': _getHealthRecommendations(healthStatus, failedDeposits),
      };
    });
  }

  List<String> _getHealthRecommendations(String status, int failedDeposits) {
    final recommendations = <String>[];
    
    if (status == 'critical') {
      recommendations.add('Immediate attention required - high failure rate');
      recommendations.add('Check Edge Function logs for errors');
      recommendations.add('Verify database connectivity');
    } else if (status == 'warning') {
      recommendations.add('Monitor closely - elevated failure rate');
      recommendations.add('Consider running manual retry process');
    }
    
    if (failedDeposits > 10) {
      recommendations.add('Run retry service to process failed deposits');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('System operating normally');
    }
    
    return recommendations;
  }
}

/// Result class for earnings-to-wallet operations
class EarningsWalletResult {
  final String orderId;
  final String? walletId;
  final double? amountDeposited;
  final String message;
  final bool isSuccess;
  final String? error;
  final bool canRetry;

  EarningsWalletResult._({
    required this.orderId,
    this.walletId,
    this.amountDeposited,
    required this.message,
    required this.isSuccess,
    this.error,
    this.canRetry = false,
  });

  factory EarningsWalletResult.success({
    required String orderId,
    required String walletId,
    required double amountDeposited,
    required String message,
  }) {
    return EarningsWalletResult._(
      orderId: orderId,
      walletId: walletId,
      amountDeposited: amountDeposited,
      message: message,
      isSuccess: true,
    );
  }

  factory EarningsWalletResult.failure({
    required String orderId,
    required String error,
    bool canRetry = false,
  }) {
    return EarningsWalletResult._(
      orderId: orderId,
      message: 'Failed to process earnings deposit',
      isSuccess: false,
      error: error,
      canRetry: canRetry,
    );
  }

  factory EarningsWalletResult.noEarnings(String orderId, String reason) {
    return EarningsWalletResult._(
      orderId: orderId,
      message: reason,
      isSuccess: true,
      amountDeposited: 0.0,
    );
  }
}

/// Summary class for driver earnings and wallet data
class DriverEarningsWalletSummary {
  final String driverId;
  final dynamic wallet; // DriverWallet?
  final double totalEarningsThisMonth;
  final double totalDepositsThisMonth;
  final int pendingDeposits;
  final int recentTransactionCount;
  final String? lastDepositAt;
  final DateTime? walletCreatedAt;

  DriverEarningsWalletSummary({
    required this.driverId,
    this.wallet,
    required this.totalEarningsThisMonth,
    required this.totalDepositsThisMonth,
    required this.pendingDeposits,
    required this.recentTransactionCount,
    this.lastDepositAt,
    this.walletCreatedAt,
  });

  double get depositSuccessRate {
    if (totalEarningsThisMonth == 0) return 100.0;
    return (totalDepositsThisMonth / totalEarningsThisMonth) * 100;
  }

  bool get hasWallet => wallet != null;
  
  bool get hasRecentActivity => recentTransactionCount > 0;
  
  bool get needsAttention => pendingDeposits > 0 || depositSuccessRate < 95.0;
}
