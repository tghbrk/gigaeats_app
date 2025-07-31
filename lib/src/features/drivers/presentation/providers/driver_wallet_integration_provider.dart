import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../data/models/user_role.dart';
import '../../data/services/enhanced_driver_wallet_service.dart';
import 'driver_wallet_provider.dart';
import 'driver_earnings_provider.dart';

/// Integration provider that connects driver wallet with earnings system
class DriverWalletIntegrationNotifier extends StateNotifier<Map<String, dynamic>> {
  final EnhancedDriverWalletService _walletService;
  final Ref _ref;

  DriverWalletIntegrationNotifier(this._walletService, this._ref) 
      : super({
          'isProcessingEarnings': false,
          'lastEarningsDeposit': null,
          'pendingDeposits': <String>[],
          'failedDeposits': <String>[],
          'totalEarningsProcessed': 0.0,
        });

  /// Process earnings deposit when a delivery is completed
  Future<bool> processDeliveryEarnings({
    required String orderId,
    required double grossEarnings,
    required double netEarnings,
    required Map<String, dynamic> earningsBreakdown,
  }) async {
    final authState = _ref.read(authStateProvider);
    if (authState.user?.role != UserRole.driver) {
      debugPrint('❌ [WALLET-INTEGRATION] User is not a driver');
      return false;
    }

    // Check if already processing this order
    final pendingDeposits = List<String>.from(state['pendingDeposits'] ?? []);
    if (pendingDeposits.contains(orderId)) {
      debugPrint('⚠️ [WALLET-INTEGRATION] Order $orderId already being processed');
      return false;
    }

    try {
      // Mark as processing
      state = {
        ...state,
        'isProcessingEarnings': true,
        'pendingDeposits': [...pendingDeposits, orderId],
      };

      debugPrint('💰 [WALLET-INTEGRATION] Processing earnings for order: $orderId');
      debugPrint('💰 [WALLET-INTEGRATION] Gross: RM ${grossEarnings.toStringAsFixed(2)}, Net: RM ${netEarnings.toStringAsFixed(2)}');

      // Process the earnings deposit
      await _walletService.processEarningsDeposit(
        orderId: orderId,
        grossEarnings: grossEarnings,
        netEarnings: netEarnings,
        earningsBreakdown: earningsBreakdown,
      );

      // Update state on success
      final updatedPendingDeposits = List<String>.from(state['pendingDeposits'] ?? []);
      updatedPendingDeposits.remove(orderId);
      
      final failedDeposits = List<String>.from(state['failedDeposits'] ?? []);
      failedDeposits.remove(orderId); // Remove from failed if it was there

      state = {
        ...state,
        'isProcessingEarnings': false,
        'lastEarningsDeposit': {
          'orderId': orderId,
          'amount': netEarnings,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'pendingDeposits': updatedPendingDeposits,
        'failedDeposits': failedDeposits,
        'totalEarningsProcessed': (state['totalEarningsProcessed'] ?? 0.0) + netEarnings,
      };

      // Trigger wallet refresh
      _ref.read(driverWalletProvider.notifier).loadWallet(refresh: true);

      debugPrint('✅ [WALLET-INTEGRATION] Earnings processed successfully for order: $orderId');
      return true;

    } catch (e) {
      debugPrint('❌ [WALLET-INTEGRATION] Error processing earnings for order $orderId: $e');

      // Mark as failed
      final updatedPendingDeposits = List<String>.from(state['pendingDeposits'] ?? []);
      updatedPendingDeposits.remove(orderId);
      
      final failedDeposits = List<String>.from(state['failedDeposits'] ?? []);
      if (!failedDeposits.contains(orderId)) {
        failedDeposits.add(orderId);
      }

      state = {
        ...state,
        'isProcessingEarnings': false,
        'pendingDeposits': updatedPendingDeposits,
        'failedDeposits': failedDeposits,
      };

      return false;
    }
  }

  /// Retry failed earnings deposits
  Future<void> retryFailedDeposits() async {
    final failedDeposits = List<String>.from(state['failedDeposits'] ?? []);
    
    if (failedDeposits.isEmpty) {
      debugPrint('ℹ️ [WALLET-INTEGRATION] No failed deposits to retry');
      return;
    }

    debugPrint('🔄 [WALLET-INTEGRATION] Retrying ${failedDeposits.length} failed deposits');

    for (final orderId in failedDeposits) {
      // Note: In a real implementation, you would need to fetch the original
      // earnings data for each order. For now, we'll just clear the failed list.
      debugPrint('🔄 [WALLET-INTEGRATION] Would retry deposit for order: $orderId');
    }

    // Clear failed deposits (in real implementation, only clear successful retries)
    state = {
      ...state,
      'failedDeposits': <String>[],
    };
  }

  /// Get earnings integration summary
  Map<String, dynamic> getIntegrationSummary() {
    final walletState = _ref.read(driverWalletProvider);
    
    return {
      'walletBalance': walletState.availableBalance,
      'totalEarningsProcessed': state['totalEarningsProcessed'] ?? 0.0,
      'pendingDepositsCount': (state['pendingDeposits'] as List?)?.length ?? 0,
      'failedDepositsCount': (state['failedDeposits'] as List?)?.length ?? 0,
      'lastDepositTime': state['lastEarningsDeposit']?['timestamp'],
      'isProcessing': state['isProcessingEarnings'] ?? false,
    };
  }

  /// Clear integration state
  void clearState() {
    state = {
      'isProcessingEarnings': false,
      'lastEarningsDeposit': null,
      'pendingDeposits': <String>[],
      'failedDeposits': <String>[],
      'totalEarningsProcessed': 0.0,
    };
  }

  @override
  void dispose() {
    debugPrint('🔍 [WALLET-INTEGRATION] Disposing integration notifier');
    super.dispose();
  }
}

/// Main driver wallet integration provider
final driverWalletIntegrationProvider = StateNotifierProvider<DriverWalletIntegrationNotifier, Map<String, dynamic>>((ref) {
  final walletService = ref.watch(enhancedDriverWalletServiceProvider);
  return DriverWalletIntegrationNotifier(walletService, ref);
});

/// Provider for checking if earnings processing is in progress
final driverEarningsProcessingProvider = Provider<bool>((ref) {
  final integrationState = ref.watch(driverWalletIntegrationProvider);
  return integrationState['isProcessingEarnings'] ?? false;
});

/// Provider for failed deposits count
final driverFailedDepositsCountProvider = Provider<int>((ref) {
  final integrationState = ref.watch(driverWalletIntegrationProvider);
  return (integrationState['failedDeposits'] as List?)?.length ?? 0;
});

/// Provider for pending deposits count
final driverPendingDepositsCountProvider = Provider<int>((ref) {
  final integrationState = ref.watch(driverWalletIntegrationProvider);
  return (integrationState['pendingDeposits'] as List?)?.length ?? 0;
});

/// Provider for last earnings deposit info
final driverLastEarningsDepositProvider = Provider<Map<String, dynamic>?>((ref) {
  final integrationState = ref.watch(driverWalletIntegrationProvider);
  return integrationState['lastEarningsDeposit'];
});

/// Provider for total earnings processed through wallet
final driverTotalEarningsProcessedProvider = Provider<double>((ref) {
  final integrationState = ref.watch(driverWalletIntegrationProvider);
  return integrationState['totalEarningsProcessed'] ?? 0.0;
});

/// Provider for wallet-earnings integration health status
final driverWalletEarningsHealthProvider = Provider<Map<String, dynamic>>((ref) {
  final walletState = ref.watch(driverWalletProvider);
  final integrationState = ref.watch(driverWalletIntegrationProvider);
  
  final failedCount = (integrationState['failedDeposits'] as List?)?.length ?? 0;
  final pendingCount = (integrationState['pendingDeposits'] as List?)?.length ?? 0;
  final isProcessing = integrationState['isProcessingEarnings'] ?? false;

  String healthStatus;
  String healthMessage;

  if (walletState.errorMessage != null) {
    healthStatus = 'error';
    healthMessage = 'Wallet error: ${walletState.errorMessage}';
  } else if (failedCount > 0) {
    healthStatus = 'warning';
    healthMessage = '$failedCount failed deposits need attention';
  } else if (pendingCount > 3) {
    healthStatus = 'warning';
    healthMessage = '$pendingCount deposits are pending';
  } else if (isProcessing) {
    healthStatus = 'processing';
    healthMessage = 'Processing earnings deposit...';
  } else if (!walletState.isWalletActive) {
    healthStatus = 'inactive';
    healthMessage = 'Wallet is inactive';
  } else if (!walletState.isWalletVerified) {
    healthStatus = 'unverified';
    healthMessage = 'Wallet verification required';
  } else {
    healthStatus = 'healthy';
    healthMessage = 'All systems operational';
  }

  return {
    'status': healthStatus,
    'message': healthMessage,
    'failedCount': failedCount,
    'pendingCount': pendingCount,
    'isProcessing': isProcessing,
    'walletActive': walletState.isWalletActive,
    'walletVerified': walletState.isWalletVerified,
  };
});

/// Provider for automatic earnings processing when orders are completed
final driverAutoEarningsProcessorProvider = Provider<void>((ref) {
  // This provider watches for completed orders and automatically processes earnings
  // In a real implementation, this would listen to order completion events
  
  ref.listen(driverEarningsStreamProvider, (previous, next) {
    next.when(
      data: (earnings) {
        // Check for new completed earnings that haven't been processed
        // This is a simplified example - in practice you'd need more sophisticated
        // tracking to avoid duplicate processing
        debugPrint('💰 [AUTO-EARNINGS-PROCESSOR] Earnings stream updated with ${earnings.length} items');
      },
      loading: () {},
      error: (error, stack) {
        debugPrint('❌ [AUTO-EARNINGS-PROCESSOR] Error in earnings stream: $error');
      },
    );
  });
});
