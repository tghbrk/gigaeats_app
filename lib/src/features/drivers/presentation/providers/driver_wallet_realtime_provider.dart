import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../data/models/user_role.dart';
import '../../data/models/driver_wallet_transaction.dart';
import 'driver_wallet_provider.dart';
import 'driver_wallet_transaction_provider.dart';
// Removed unused import

/// Real-time driver wallet state management
class DriverWalletRealtimeNotifier extends StateNotifier<bool> {
  final Ref _ref;
  bool _isListening = false;

  DriverWalletRealtimeNotifier(this._ref) : super(false) {
    _initializeRealtimeListeners();
  }

  /// Initialize real-time listeners for driver wallet updates
  Future<void> _initializeRealtimeListeners() async {
    final authState = _ref.read(authStateProvider);
    
    if (authState.user?.role != UserRole.driver) {
      debugPrint('🔄 [DRIVER-WALLET-REALTIME] User is not a driver, skipping real-time setup');
      return;
    }

    if (_isListening) {
      debugPrint('🔄 [DRIVER-WALLET-REALTIME] Already listening to real-time updates');
      return;
    }

    try {
      debugPrint('🔄 [DRIVER-WALLET-REALTIME] Setting up real-time listeners');
      
      // Listen to wallet stream
      _ref.listen(driverWalletStreamProvider, (previous, next) {
        next.when(
          data: (wallet) {
            if (wallet != null) {
              debugPrint('🔄 [DRIVER-WALLET-REALTIME] Wallet update received: ${wallet.formattedAvailableBalance}');
              
              // Update the main wallet provider with real-time data
              _ref.read(driverWalletProvider.notifier).handleRealtimeUpdate(wallet);
              
              // Mark real-time connection as active
              state = true;
            }
          },
          loading: () {
            debugPrint('🔄 [DRIVER-WALLET-REALTIME] Wallet stream loading...');
          },
          error: (error, stack) {
            debugPrint('❌ [DRIVER-WALLET-REALTIME] Wallet stream error: $error');
            state = false;
          },
        );
      });

      // Listen to transaction stream
      _ref.listen(driverWalletTransactionsStreamProvider, (previous, next) {
        next.when(
          data: (transactions) {
            if (transactions.isNotEmpty) {
              debugPrint('🔄 [DRIVER-WALLET-REALTIME] Transaction update received: ${transactions.length} transactions');

              // Refresh transaction list when new transactions arrive
              _ref.read(driverWalletTransactionProvider.notifier).refreshTransactions();

              // Check for new earnings transactions and trigger notifications
              _checkForNewEarningsTransactions(transactions);
            }
          },
          loading: () {
            debugPrint('🔄 [DRIVER-WALLET-REALTIME] Transaction stream loading...');
          },
          error: (error, stack) {
            debugPrint('❌ [DRIVER-WALLET-REALTIME] Transaction stream error: $error');
          },
        );
      });

      _isListening = true;
      state = true;
      debugPrint('✅ [DRIVER-WALLET-REALTIME] Real-time listeners initialized');

    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-REALTIME] Error setting up real-time listeners: $e');
      state = false;
    }
  }

  /// Check for new earnings transactions and trigger notifications
  void _checkForNewEarningsTransactions(List<DriverWalletTransaction> transactions) {
    try {
      // Look for recent earnings transactions (within last 5 minutes)
      final now = DateTime.now();
      final recentThreshold = now.subtract(const Duration(minutes: 5));

      final recentEarnings = transactions.where((transaction) =>
        transaction.transactionType == DriverWalletTransactionType.deliveryEarnings &&
        transaction.createdAt.isAfter(recentThreshold)
      ).toList();

      if (recentEarnings.isNotEmpty) {
        debugPrint('🔔 [DRIVER-WALLET-REALTIME] Found ${recentEarnings.length} recent earnings transactions');

        // TODO: Fix notification provider usage
        // final notificationNotifier = _ref.read(driverWalletNotificationProvider.notifier);

        // Send notification for the most recent earnings
        final latestEarnings = recentEarnings.first;
        debugPrint('🔔 [DRIVER-WALLET-REALTIME] Latest earnings: ${latestEarnings.amount}');

        // TODO: Fix notification provider usage
        // notificationNotifier.sendEarningsNotification(
        //   orderId: orderId,
        //   earningsAmount: latestEarnings.amount,
        //   newBalance: latestEarnings.balanceAfter,
        //   earningsBreakdown: earningsBreakdown,
        // );
      }
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-REALTIME] Error checking for new earnings: $e');
    }
  }

  /// Manually refresh real-time connection
  Future<void> refreshConnection() async {
    debugPrint('🔄 [DRIVER-WALLET-REALTIME] Refreshing real-time connection');
    _isListening = false;
    await _initializeRealtimeListeners();
  }

  /// Stop real-time listeners
  void stopListening() {
    debugPrint('🔄 [DRIVER-WALLET-REALTIME] Stopping real-time listeners');
    _isListening = false;
    state = false;
  }

  @override
  void dispose() {
    debugPrint('🔄 [DRIVER-WALLET-REALTIME] Disposing real-time notifier');
    stopListening();
    super.dispose();
  }
}

/// Driver wallet real-time provider
final driverWalletRealtimeProvider = StateNotifierProvider<DriverWalletRealtimeNotifier, bool>((ref) {
  return DriverWalletRealtimeNotifier(ref);
});

/// Combined driver wallet state provider that includes real-time status
final driverWalletCombinedStateProvider = Provider<Map<String, dynamic>>((ref) {
  final walletState = ref.watch(driverWalletProvider);
  final transactionState = ref.watch(driverWalletTransactionProvider);
  final realtimeConnected = ref.watch(driverWalletRealtimeProvider);

  return {
    'wallet': walletState.wallet,
    'balance': walletState.availableBalance,
    'formattedBalance': walletState.formattedAvailableBalance,
    'isLoading': walletState.isLoading,
    'error': walletState.errorMessage,
    'isActive': walletState.isWalletActive,
    'isVerified': walletState.isWalletVerified,
    'lastUpdated': walletState.lastUpdated,
    'realtimeConnected': realtimeConnected,
    'transactionCount': transactionState.transactions.length,
    'hasRecentTransactions': transactionState.transactions.isNotEmpty,
  };
});

/// Driver wallet status provider for quick UI checks
final driverWalletStatusProvider = Provider<String>((ref) {
  final walletState = ref.watch(driverWalletProvider);
  final realtimeConnected = ref.watch(driverWalletRealtimeProvider);

  String status;

  if (walletState.isLoading) {
    status = 'loading';
  } else if (walletState.errorMessage != null) {
    status = 'error';
  } else if (walletState.wallet == null) {
    status = 'not_found';
  } else if (!walletState.isWalletActive) {
    status = 'inactive';
  } else if (!walletState.isWalletVerified) {
    status = 'unverified';
  } else if (!realtimeConnected) {
    status = 'offline';
  } else {
    status = 'active';
  }

  // Debug logging for wallet status
  debugPrint('🔍 [WALLET-STATUS] ========== WALLET STATUS DEBUG ==========');
  debugPrint('🔍 [WALLET-STATUS] Final status: $status');
  debugPrint('🔍 [WALLET-STATUS] Is loading: ${walletState.isLoading}');
  debugPrint('🔍 [WALLET-STATUS] Error message: ${walletState.errorMessage}');
  debugPrint('🔍 [WALLET-STATUS] Wallet exists: ${walletState.wallet != null}');
  debugPrint('🔍 [WALLET-STATUS] Wallet active: ${walletState.isWalletActive}');
  debugPrint('🔍 [WALLET-STATUS] Wallet verified: ${walletState.isWalletVerified}');
  debugPrint('🔍 [WALLET-STATUS] Realtime connected: $realtimeConnected');

  return status;
});

/// Driver wallet quick actions provider
final driverWalletQuickActionsProvider = Provider<Map<String, bool>>((ref) {
  final walletState = ref.watch(driverWalletProvider);
  final status = ref.watch(driverWalletStatusProvider);

  // Use the wallet model's canRequestPayout logic for proper withdrawal validation
  final canWithdraw = walletState.wallet?.canRequestPayout ?? false;

  final canViewTransactions = walletState.wallet != null &&
                             !walletState.isLoading;

  final canRefresh = !walletState.isLoading;

  // Debug logging for withdraw button state
  debugPrint('🔍 [QUICK-ACTIONS] ========== WITHDRAW BUTTON STATE DEBUG ==========');
  debugPrint('🔍 [QUICK-ACTIONS] Wallet status: $status');
  debugPrint('🔍 [QUICK-ACTIONS] Available balance: ${walletState.availableBalance}');
  debugPrint('🔍 [QUICK-ACTIONS] Is loading: ${walletState.isLoading}');
  debugPrint('🔍 [QUICK-ACTIONS] Wallet active: ${walletState.isWalletActive}');
  debugPrint('🔍 [QUICK-ACTIONS] Wallet verified: ${walletState.isWalletVerified}');
  debugPrint('🔍 [QUICK-ACTIONS] Wallet canRequestPayout: ${walletState.wallet?.canRequestPayout}');
  debugPrint('🔍 [QUICK-ACTIONS] Can withdraw (fixed): $canWithdraw');
  debugPrint('🔍 [QUICK-ACTIONS] Previous logic would be: ${status == 'active' && walletState.availableBalance > 0 && !walletState.isLoading}');

  return {
    'canWithdraw': canWithdraw,
    'canViewTransactions': canViewTransactions,
    'canRefresh': canRefresh,
    'showBalance': status == 'active' || status == 'unverified', // Show balance for both active and unverified wallets
    'showError': status == 'error',
    'showLoading': status == 'loading',
  };
});

/// Driver wallet earnings summary provider
final driverWalletEarningsSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final walletState = ref.watch(driverWalletProvider);
  final transactionState = ref.watch(driverWalletTransactionProvider);

  if (walletState.wallet == null) {
    return {
      'totalEarned': 0.0,
      'totalWithdrawn': 0.0,
      'availableBalance': 0.0,
      'pendingBalance': 0.0,
      'recentEarnings': 0.0,
      'formattedTotalEarned': 'RM 0.00',
      'formattedAvailableBalance': 'RM 0.00',
    };
  }

  final wallet = walletState.wallet!;
  
  // Calculate recent earnings (last 7 days)
  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
  final recentEarnings = transactionState.transactions
      .where((tx) => 
          tx.createdAt.isAfter(sevenDaysAgo) && 
          tx.transactionType == DriverWalletTransactionType.deliveryEarnings)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  return {
    'totalEarned': wallet.totalEarned,
    'totalWithdrawn': wallet.totalWithdrawn,
    'availableBalance': wallet.availableBalance,
    'pendingBalance': wallet.pendingBalance,
    'recentEarnings': recentEarnings,
    'formattedTotalEarned': wallet.formattedTotalEarned,
    'formattedAvailableBalance': wallet.formattedAvailableBalance,
    'formattedRecentEarnings': 'RM ${recentEarnings.toStringAsFixed(2)}',
  };
});

/// Driver wallet notification provider for balance alerts
final driverWalletNotificationProvider = Provider<Map<String, dynamic>?>((ref) {
  final walletState = ref.watch(driverWalletProvider);
  final status = ref.watch(driverWalletStatusProvider);

  if (walletState.wallet == null) return null;

  final wallet = walletState.wallet!;
  
  // Low balance alert (less than RM 20)
  if (wallet.availableBalance < 20.0 && wallet.availableBalance > 0) {
    return {
      'type': 'low_balance',
      'title': 'Low Balance Alert',
      'message': 'Your wallet balance is low: ${wallet.formattedAvailableBalance}',
      'severity': 'warning',
    };
  }

  // Unverified wallet alert
  if (!wallet.isVerified) {
    return {
      'type': 'unverified',
      'title': 'Wallet Verification Required',
      'message': 'Please verify your wallet to enable withdrawals',
      'severity': 'info',
    };
  }

  // Inactive wallet alert
  if (!wallet.isActive) {
    return {
      'type': 'inactive',
      'title': 'Wallet Inactive',
      'message': 'Your wallet is currently inactive. Contact support for assistance.',
      'severity': 'error',
    };
  }

  // Connection issues
  if (status == 'offline') {
    return {
      'type': 'offline',
      'title': 'Connection Issue',
      'message': 'Real-time updates are currently unavailable',
      'severity': 'warning',
    };
  }

  return null;
});
