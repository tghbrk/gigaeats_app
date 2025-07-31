import 'package:flutter/foundation.dart';

import '../../../../core/data/repositories/base_repository.dart';
import 'earnings_wallet_integration_service.dart';
import 'earnings_wallet_monitoring_service.dart';
import 'wallet_deposit_retry_service.dart';

/// Administrative service for managing earnings-wallet integration
/// Provides tools for admins to monitor, troubleshoot, and maintain the system
class EarningsWalletAdminService extends BaseRepository {
  final EarningsWalletMonitoringService _monitoringService;
  final WalletDepositRetryService _retryService;

  EarningsWalletAdminService({
    EarningsWalletMonitoringService? monitoringService,
    WalletDepositRetryService? retryService,
  }) : _monitoringService = monitoringService ?? EarningsWalletMonitoringService(),
       _retryService = retryService ?? WalletDepositRetryService();

  /// Get comprehensive admin dashboard data
  Future<AdminDashboardData> getAdminDashboardData() async {
    return executeQuery(() async {
      debugPrint('📊 [EARNINGS-WALLET-ADMIN] Getting admin dashboard data');

      // Get system health report
      final healthReport = await _monitoringService.getSystemHealthReport();
      
      // Get system statistics
      final systemStats = await _monitoringService.getSystemStatistics();
      
      // Get recent failed deposits
      final recentFailedDeposits = await _getRecentFailedDeposits();
      
      return AdminDashboardData(
        healthReport: healthReport,
        systemStatistics: systemStats,
        recentFailedDeposits: recentFailedDeposits,
        lastUpdated: DateTime.now(),
      );
    });
  }

  /// Get recent failed deposits for admin review
  Future<List<Map<String, dynamic>>> _getRecentFailedDeposits() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 3));
    
    // Get recent earnings without corresponding wallet transactions
    final earningsResponse = await supabase
        .from('driver_earnings')
        .select('''
          order_id,
          driver_id,
          net_earnings,
          created_at,
          drivers!inner(user_id, users!inner(email))
        ''')
        .gte('created_at', cutoffDate.toIso8601String())
        .eq('earnings_type', 'delivery_completion')
        .order('created_at', ascending: false)
        .limit(20);
    
    final failedDeposits = <Map<String, dynamic>>[];
    
    for (final earning in earningsResponse) {
      final orderId = earning['order_id'] as String;
      
      // Check if wallet transaction exists
      final transactionExists = await supabase
          .from('wallet_transactions')
          .select('id')
          .eq('reference_id', orderId)
          .eq('transaction_type', 'delivery_earnings')
          .maybeSingle();
      
      if (transactionExists == null) {
        failedDeposits.add({
          'order_id': orderId,
          'driver_id': earning['driver_id'],
          'net_earnings': earning['net_earnings'],
          'created_at': earning['created_at'],
          'driver_email': earning['drivers']['users']['email'],
        });
      }
    }
    
    return failedDeposits;
  }

  /// Manually process a specific failed deposit
  Future<bool> manuallyProcessDeposit(String orderId) async {
    return executeQuery(() async {
      debugPrint('🔧 [EARNINGS-WALLET-ADMIN] Manually processing deposit for order: $orderId');
      
      try {
        final success = await _retryService.retryDepositForOrder(orderId);
        
        if (success) {
          debugPrint('✅ [EARNINGS-WALLET-ADMIN] Manual deposit successful for order: $orderId');
        } else {
          debugPrint('⚠️ [EARNINGS-WALLET-ADMIN] Deposit already exists for order: $orderId');
        }
        
        return success;
      } catch (e) {
        debugPrint('❌ [EARNINGS-WALLET-ADMIN] Manual deposit failed for order: $orderId - $e');
        return false;
      }
    });
  }

  /// Run bulk retry for all failed deposits
  Future<BulkRetryResult> runBulkRetry({
    int limit = 100,
    Duration maxAge = const Duration(days: 7),
  }) async {
    return executeQuery(() async {
      debugPrint('🔄 [EARNINGS-WALLET-ADMIN] Running bulk retry process');
      
      final startTime = DateTime.now();
      
      try {
        final retriedOrders = await _retryService.retryFailedDeposits(
          limit: limit,
          maxAge: maxAge,
        );
        
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        
        debugPrint('✅ [EARNINGS-WALLET-ADMIN] Bulk retry completed: ${retriedOrders.length} orders processed');
        
        return BulkRetryResult(
          success: true,
          processedCount: retriedOrders.length,
          retriedOrders: retriedOrders,
          duration: duration,
          completedAt: endTime,
        );
        
      } catch (e) {
        debugPrint('❌ [EARNINGS-WALLET-ADMIN] Bulk retry failed: $e');
        
        return BulkRetryResult(
          success: false,
          processedCount: 0,
          retriedOrders: [],
          duration: DateTime.now().difference(startTime),
          completedAt: DateTime.now(),
          error: e.toString(),
        );
      }
    });
  }

  /// Get detailed driver earnings-wallet report
  Future<DetailedDriverReport> getDetailedDriverReport(String driverId) async {
    return executeQuery(() async {
      debugPrint('📋 [EARNINGS-WALLET-ADMIN] Getting detailed report for driver: $driverId');
      
      // Get driver summary
      final summary = await _monitoringService.getDriverSummary(driverId);
      
      // Get recent earnings
      final recentEarnings = await _getDriverRecentEarnings(driverId);
      
      // Get recent wallet transactions
      final recentTransactions = await _getDriverRecentWalletTransactions(driverId);
      
      // Get failed deposits for this driver
      final failedDeposits = await _getDriverFailedDeposits(driverId);
      
      return DetailedDriverReport(
        driverId: driverId,
        summary: summary,
        recentEarnings: recentEarnings,
        recentTransactions: recentTransactions,
        failedDeposits: failedDeposits,
        generatedAt: DateTime.now(),
      );
    });
  }

  /// Get driver's recent earnings
  Future<List<Map<String, dynamic>>> _getDriverRecentEarnings(String driverId) async {
    final response = await supabase
        .from('driver_earnings')
        .select('order_id, net_earnings, created_at, earnings_type')
        .eq('driver_id', driverId)
        .order('created_at', ascending: false)
        .limit(20);
    
    return response;
  }

  /// Get driver's recent wallet transactions
  Future<List<Map<String, dynamic>>> _getDriverRecentWalletTransactions(String driverId) async {
    // First get driver's wallet ID
    final driverResponse = await supabase
        .from('drivers')
        .select('user_id')
        .eq('id', driverId)
        .single();
    
    final userId = driverResponse['user_id'] as String;
    
    final walletResponse = await supabase
        .from('stakeholder_wallets')
        .select('id')
        .eq('user_id', userId)
        .eq('user_role', 'driver')
        .maybeSingle();
    
    if (walletResponse == null) {
      return [];
    }
    
    final walletId = walletResponse['id'] as String;
    
    final transactionsResponse = await supabase
        .from('wallet_transactions')
        .select('amount, transaction_type, created_at, reference_id')
        .eq('wallet_id', walletId)
        .order('created_at', ascending: false)
        .limit(20);
    
    return transactionsResponse;
  }

  /// Get driver's failed deposits
  Future<List<Map<String, dynamic>>> _getDriverFailedDeposits(String driverId) async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    
    final earningsResponse = await supabase
        .from('driver_earnings')
        .select('order_id, net_earnings, created_at')
        .eq('driver_id', driverId)
        .gte('created_at', cutoffDate.toIso8601String())
        .eq('earnings_type', 'delivery_completion');
    
    final failedDeposits = <Map<String, dynamic>>[];
    
    for (final earning in earningsResponse) {
      final orderId = earning['order_id'] as String;
      
      final transactionExists = await supabase
          .from('wallet_transactions')
          .select('id')
          .eq('reference_id', orderId)
          .eq('transaction_type', 'delivery_earnings')
          .maybeSingle();
      
      if (transactionExists == null) {
        failedDeposits.add(earning);
      }
    }
    
    return failedDeposits;
  }

  /// Export system data for analysis
  Future<Map<String, dynamic>> exportSystemData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuery(() async {
      debugPrint('📤 [EARNINGS-WALLET-ADMIN] Exporting system data');
      
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();
      
      // Get earnings data
      final earningsData = await supabase
          .from('driver_earnings')
          .select('*')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .eq('earnings_type', 'delivery_completion');
      
      // Get wallet transactions data
      final transactionsData = await supabase
          .from('wallet_transactions')
          .select('*')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .eq('transaction_type', 'delivery_earnings');
      
      return {
        'export_period': {
          'start_date': start.toIso8601String(),
          'end_date': end.toIso8601String(),
        },
        'earnings_records': earningsData,
        'wallet_transactions': transactionsData,
        'summary': {
          'total_earnings_records': earningsData.length,
          'total_wallet_transactions': transactionsData.length,
          'success_rate': earningsData.isNotEmpty 
              ? (transactionsData.length / earningsData.length * 100)
              : 100.0,
        },
        'exported_at': DateTime.now().toIso8601String(),
      };
    });
  }
}

/// Admin dashboard data class
class AdminDashboardData {
  final EarningsWalletHealthReport healthReport;
  final Map<String, dynamic> systemStatistics;
  final List<Map<String, dynamic>> recentFailedDeposits;
  final DateTime lastUpdated;

  AdminDashboardData({
    required this.healthReport,
    required this.systemStatistics,
    required this.recentFailedDeposits,
    required this.lastUpdated,
  });
}

/// Bulk retry result class
class BulkRetryResult {
  final bool success;
  final int processedCount;
  final List<String> retriedOrders;
  final Duration duration;
  final DateTime completedAt;
  final String? error;

  BulkRetryResult({
    required this.success,
    required this.processedCount,
    required this.retriedOrders,
    required this.duration,
    required this.completedAt,
    this.error,
  });
}

/// Detailed driver report class
class DetailedDriverReport {
  final String driverId;
  final DriverEarningsWalletSummary summary;
  final List<Map<String, dynamic>> recentEarnings;
  final List<Map<String, dynamic>> recentTransactions;
  final List<Map<String, dynamic>> failedDeposits;
  final DateTime generatedAt;

  DetailedDriverReport({
    required this.driverId,
    required this.summary,
    required this.recentEarnings,
    required this.recentTransactions,
    required this.failedDeposits,
    required this.generatedAt,
  });
}
