import 'package:flutter/foundation.dart';

import '../../../../core/data/repositories/base_repository.dart';
import 'earnings_wallet_integration_service.dart';
import 'wallet_deposit_retry_service.dart';

/// Service for monitoring and managing the earnings-wallet integration system
/// Provides administrative tools and health monitoring capabilities
class EarningsWalletMonitoringService extends BaseRepository {
  final EarningsWalletIntegrationService _integrationService;
  final WalletDepositRetryService _retryService;

  EarningsWalletMonitoringService({
    EarningsWalletIntegrationService? integrationService,
    WalletDepositRetryService? retryService,
  }) : _integrationService = integrationService ?? EarningsWalletIntegrationService(),
       _retryService = retryService ?? WalletDepositRetryService();

  /// Get comprehensive system health report
  Future<EarningsWalletHealthReport> getSystemHealthReport() async {
    return executeQuery(() async {
      debugPrint('🏥 [EARNINGS-WALLET-MONITORING] Generating system health report');

      // Get integration health status
      final integrationHealth = await _integrationService.getIntegrationHealthStatus();
      
      // Get failed deposit statistics
      final failedDepositStats = await _retryService.getFailedDepositStats(
        period: const Duration(days: 7),
      );
      
      // Get recent performance metrics
      final performanceMetrics = await _getPerformanceMetrics();
      
      // Generate recommendations
      final recommendations = _generateRecommendations(
        integrationHealth,
        failedDepositStats,
        performanceMetrics,
      );

      return EarningsWalletHealthReport(
        overallStatus: integrationHealth['status'] as String,
        successRate: integrationHealth['success_rate'] as double,
        failedDepositsCount: integrationHealth['failed_deposits_count'] as int,
        totalEarningsProcessed: integrationHealth['total_earnings_processed'] as int,
        performanceMetrics: performanceMetrics,
        recommendations: recommendations,
        lastUpdated: DateTime.now(),
      );
    });
  }

  /// Get performance metrics for the last 24 hours
  Future<Map<String, dynamic>> _getPerformanceMetrics() async {
    final last24Hours = DateTime.now().subtract(const Duration(hours: 24));
    
    // Get earnings processing volume
    final earningsVolume = await supabase
        .from('driver_earnings')
        .select('net_earnings')
        .gte('created_at', last24Hours.toIso8601String())
        .eq('earnings_type', 'delivery_completion');

    // Get wallet transaction volume
    final walletVolume = await supabase
        .from('wallet_transactions')
        .select('amount')
        .gte('created_at', last24Hours.toIso8601String())
        .eq('transaction_type', 'delivery_earnings');
    
    // Calculate total amounts
    double totalEarningsAmount = 0.0;
    for (final earning in earningsVolume) {
      totalEarningsAmount += (earning['net_earnings'] as num?)?.toDouble() ?? 0.0;
    }
    
    double totalWalletAmount = 0.0;
    for (final transaction in walletVolume) {
      totalWalletAmount += (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    }
    
    return {
      'earnings_count_24h': earningsVolume.length,
      'wallet_deposits_count_24h': walletVolume.length,
      'total_earnings_amount_24h': totalEarningsAmount,
      'total_wallet_amount_24h': totalWalletAmount,
      'processing_rate_24h': earningsVolume.isNotEmpty
          ? (walletVolume.length / earningsVolume.length * 100)
          : 100.0,
    };
  }

  /// Generate system recommendations based on health data
  List<String> _generateRecommendations(
    Map<String, dynamic> integrationHealth,
    Map<String, dynamic> failedDepositStats,
    Map<String, dynamic> performanceMetrics,
  ) {
    final recommendations = <String>[];
    
    final successRate = integrationHealth['success_rate'] as double;
    final failedCount = integrationHealth['failed_deposits_count'] as int;
    final processingRate24h = performanceMetrics['processing_rate_24h'] as double;
    
    // Success rate recommendations
    if (successRate < 90.0) {
      recommendations.add('CRITICAL: Success rate below 90% - immediate investigation required');
      recommendations.add('Check Edge Function logs for recurring errors');
      recommendations.add('Verify database connectivity and performance');
    } else if (successRate < 95.0) {
      recommendations.add('WARNING: Success rate below 95% - monitor closely');
      recommendations.add('Consider running manual retry process');
    }
    
    // Failed deposits recommendations
    if (failedCount > 50) {
      recommendations.add('HIGH: Large number of failed deposits - run bulk retry process');
    } else if (failedCount > 10) {
      recommendations.add('MEDIUM: Multiple failed deposits - schedule retry service');
    }
    
    // Processing rate recommendations
    if (processingRate24h < 95.0) {
      recommendations.add('Processing rate below 95% in last 24 hours - investigate delays');
    }
    
    // General maintenance recommendations
    if (recommendations.isEmpty) {
      recommendations.add('System operating normally - no immediate action required');
      recommendations.add('Continue regular monitoring and maintenance');
    } else {
      recommendations.add('Run system diagnostics to identify root causes');
      recommendations.add('Consider scaling Edge Function resources if needed');
    }
    
    return recommendations;
  }

  /// Run automated maintenance tasks
  Future<MaintenanceResult> runAutomatedMaintenance() async {
    return executeQuery(() async {
      debugPrint('🔧 [EARNINGS-WALLET-MONITORING] Running automated maintenance');
      
      final results = <String, dynamic>{};
      final errors = <String>[];
      
      try {
        // Run retry service for failed deposits
        debugPrint('🔧 [EARNINGS-WALLET-MONITORING] Running retry service...');
        final retriedOrders = await _retryService.retryFailedDeposits(
          limit: 100,
          maxAge: const Duration(days: 7),
        );
        results['retried_deposits'] = retriedOrders.length;
        debugPrint('✅ [EARNINGS-WALLET-MONITORING] Retried ${retriedOrders.length} deposits');
        
      } catch (e) {
        errors.add('Failed to run retry service: $e');
        debugPrint('❌ [EARNINGS-WALLET-MONITORING] Retry service failed: $e');
      }
      
      try {
        // Get updated health status
        debugPrint('🔧 [EARNINGS-WALLET-MONITORING] Checking health status...');
        final healthStatus = await _integrationService.getIntegrationHealthStatus();
        results['health_status'] = healthStatus['status'];
        results['success_rate'] = healthStatus['success_rate'];
        debugPrint('✅ [EARNINGS-WALLET-MONITORING] Health check completed');
        
      } catch (e) {
        errors.add('Failed to get health status: $e');
        debugPrint('❌ [EARNINGS-WALLET-MONITORING] Health check failed: $e');
      }
      
      return MaintenanceResult(
        success: errors.isEmpty,
        results: results,
        errors: errors,
        completedAt: DateTime.now(),
      );
    });
  }

  /// Get driver-specific earnings-wallet summary
  Future<DriverEarningsWalletSummary> getDriverSummary(String driverId) async {
    return executeQuery(() async {
      debugPrint('📊 [EARNINGS-WALLET-MONITORING] Getting driver summary: $driverId');
      return await _integrationService.getDriverEarningsWalletSummary(driverId);
    });
  }

  /// Manually retry deposits for a specific driver
  Future<List<String>> retryDepositsForDriver(String driverId) async {
    return executeQuery(() async {
      debugPrint('🔄 [EARNINGS-WALLET-MONITORING] Manual retry for driver: $driverId');
      return await _integrationService.retryFailedDepositsForDriver(driverId);
    });
  }

  /// Get system statistics for dashboard display
  Future<Map<String, dynamic>> getSystemStatistics() async {
    return executeQuery(() async {
      debugPrint('📈 [EARNINGS-WALLET-MONITORING] Getting system statistics');
      
      final now = DateTime.now();
      
      // Get 7-day statistics
      final stats7d = await _retryService.getFailedDepositStats(
        period: const Duration(days: 7),
      );
      
      // Get 30-day statistics
      final stats30d = await _retryService.getFailedDepositStats(
        period: const Duration(days: 30),
      );
      
      // Get performance metrics
      final performanceMetrics = await _getPerformanceMetrics();
      
      return {
        'last_7_days': {
          'total_earnings': stats7d['total_earnings_records'],
          'successful_deposits': stats7d['successful_deposits'],
          'failed_deposits': stats7d['failed_deposits'],
          'success_rate': stats7d['success_rate_percentage'],
        },
        'last_30_days': {
          'total_earnings': stats30d['total_earnings_records'],
          'successful_deposits': stats30d['successful_deposits'],
          'failed_deposits': stats30d['failed_deposits'],
          'success_rate': stats30d['success_rate_percentage'],
        },
        'last_24_hours': performanceMetrics,
        'generated_at': now.toIso8601String(),
      };
    });
  }
}

/// Health report class for earnings-wallet integration
class EarningsWalletHealthReport {
  final String overallStatus;
  final double successRate;
  final int failedDepositsCount;
  final int totalEarningsProcessed;
  final Map<String, dynamic> performanceMetrics;
  final List<String> recommendations;
  final DateTime lastUpdated;

  EarningsWalletHealthReport({
    required this.overallStatus,
    required this.successRate,
    required this.failedDepositsCount,
    required this.totalEarningsProcessed,
    required this.performanceMetrics,
    required this.recommendations,
    required this.lastUpdated,
  });

  bool get isHealthy => overallStatus == 'healthy';
  bool get needsAttention => overallStatus == 'warning' || overallStatus == 'critical';
  bool get isCritical => overallStatus == 'critical';
  
  String get statusDisplayName {
    switch (overallStatus) {
      case 'healthy':
        return 'Healthy';
      case 'warning':
        return 'Needs Attention';
      case 'critical':
        return 'Critical';
      default:
        return 'Unknown';
    }
  }
}

/// Maintenance result class
class MaintenanceResult {
  final bool success;
  final Map<String, dynamic> results;
  final List<String> errors;
  final DateTime completedAt;

  MaintenanceResult({
    required this.success,
    required this.results,
    required this.errors,
    required this.completedAt,
  });

  bool get hasErrors => errors.isNotEmpty;
  int get retriedDeposits => results['retried_deposits'] as int? ?? 0;
  String get healthStatus => results['health_status'] as String? ?? 'unknown';
  double get successRate => results['success_rate'] as double? ?? 0.0;
}
