import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/notification_service.dart';
import '../../../notifications/data/services/notification_service.dart' as app_notifications;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../data/models/user_role.dart';
import '../../data/services/driver_wallet_notification_service.dart';
import '../../data/models/driver_wallet.dart';
import 'driver_wallet_provider.dart';

/// Provider for core notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provider for app notification service
final appNotificationServiceProvider = Provider<app_notifications.NotificationService>((ref) {
  return app_notifications.NotificationService();
});

/// Provider for driver wallet notification service
final driverWalletNotificationServiceProvider = Provider<DriverWalletNotificationService>((ref) {
  final supabase = Supabase.instance.client;
  final notificationService = ref.watch(notificationServiceProvider);
  final appNotificationService = ref.watch(appNotificationServiceProvider);

  return DriverWalletNotificationService(
    supabase: supabase,
    notificationService: notificationService,
    appNotificationService: appNotificationService,
  );
});

/// Enhanced driver wallet notification state
class DriverWalletNotificationState {
  final bool isEnabled;
  final bool earningsNotificationsEnabled;
  final bool lowBalanceAlertsEnabled;
  final bool balanceUpdatesEnabled;
  final bool withdrawalNotificationsEnabled;
  final double lowBalanceThreshold;
  final DateTime? lastNotificationSent;
  final List<String> recentNotificationIds;

  const DriverWalletNotificationState({
    this.isEnabled = true,
    this.earningsNotificationsEnabled = true,
    this.lowBalanceAlertsEnabled = true,
    this.balanceUpdatesEnabled = true,
    this.withdrawalNotificationsEnabled = true,
    this.lowBalanceThreshold = 20.0,
    this.lastNotificationSent,
    this.recentNotificationIds = const [],
  });

  DriverWalletNotificationState copyWith({
    bool? isEnabled,
    bool? earningsNotificationsEnabled,
    bool? lowBalanceAlertsEnabled,
    bool? balanceUpdatesEnabled,
    bool? withdrawalNotificationsEnabled,
    double? lowBalanceThreshold,
    DateTime? lastNotificationSent,
    List<String>? recentNotificationIds,
  }) {
    return DriverWalletNotificationState(
      isEnabled: isEnabled ?? this.isEnabled,
      earningsNotificationsEnabled: earningsNotificationsEnabled ?? this.earningsNotificationsEnabled,
      lowBalanceAlertsEnabled: lowBalanceAlertsEnabled ?? this.lowBalanceAlertsEnabled,
      balanceUpdatesEnabled: balanceUpdatesEnabled ?? this.balanceUpdatesEnabled,
      withdrawalNotificationsEnabled: withdrawalNotificationsEnabled ?? this.withdrawalNotificationsEnabled,
      lowBalanceThreshold: lowBalanceThreshold ?? this.lowBalanceThreshold,
      lastNotificationSent: lastNotificationSent ?? this.lastNotificationSent,
      recentNotificationIds: recentNotificationIds ?? this.recentNotificationIds,
    );
  }
}

/// Driver wallet notification notifier
class DriverWalletNotificationNotifier extends StateNotifier<DriverWalletNotificationState> {
  final DriverWalletNotificationService _notificationService;
  final Ref _ref;

  DriverWalletNotificationNotifier(this._notificationService, this._ref)
      : super(const DriverWalletNotificationState()) {
    _initializeNotificationListeners();
  }

  /// Initialize notification listeners
  void _initializeNotificationListeners() {
    debugPrint('🔔 [DRIVER-WALLET-NOTIFICATIONS] Initializing notification listeners');
    
    // Listen to wallet changes for balance updates and low balance alerts
    _ref.listen(driverWalletProvider, (previous, next) {
      _handleWalletStateChange(previous?.wallet, next.wallet);
    });
  }

  /// Handle wallet state changes for notifications
  void _handleWalletStateChange(DriverWallet? previousWallet, DriverWallet? currentWallet) {
    if (currentWallet == null) return;

    final authState = _ref.read(authStateProvider);
    if (authState.user?.role != UserRole.driver) return;

    final driverId = authState.user!.id;

    // Check for balance updates
    if (previousWallet != null && state.balanceUpdatesEnabled) {
      _checkForBalanceUpdate(driverId, previousWallet, currentWallet);
    }

    // Check for low balance alerts
    if (state.lowBalanceAlertsEnabled) {
      _checkForLowBalanceAlert(driverId, currentWallet);
    }
  }

  /// Check for significant balance updates
  void _checkForBalanceUpdate(String driverId, DriverWallet previousWallet, DriverWallet currentWallet) {
    final previousBalance = previousWallet.availableBalance;
    final currentBalance = currentWallet.availableBalance;
    final difference = currentBalance - previousBalance;

    // Only notify for significant changes (> RM 1.00) and not for earnings (handled separately)
    if (difference.abs() >= 1.0) {
      debugPrint('🔄 [DRIVER-WALLET-NOTIFICATIONS] Significant balance change detected');
      debugPrint('🔄 [DRIVER-WALLET-NOTIFICATIONS] Previous: RM ${previousBalance.toStringAsFixed(2)}');
      debugPrint('🔄 [DRIVER-WALLET-NOTIFICATIONS] Current: RM ${currentBalance.toStringAsFixed(2)}');

      _notificationService.sendBalanceUpdateNotification(
        driverId: driverId,
        previousBalance: previousBalance,
        newBalance: currentBalance,
        updateReason: difference > 0 ? 'balance_increase' : 'balance_decrease',
      );

      _updateLastNotificationSent();
    }
  }

  /// Check for low balance alerts
  void _checkForLowBalanceAlert(String driverId, DriverWallet currentWallet) {
    final currentBalance = currentWallet.availableBalance;
    
    // Check if balance is below threshold
    if (currentBalance < state.lowBalanceThreshold && currentBalance > 0) {
      // Prevent spam notifications - only send once per hour for low balance
      final now = DateTime.now();
      if (state.lastNotificationSent != null) {
        final timeSinceLastNotification = now.difference(state.lastNotificationSent!);
        if (timeSinceLastNotification.inHours < 1) {
          return; // Don't send notification yet
        }
      }

      debugPrint('⚠️ [DRIVER-WALLET-NOTIFICATIONS] Low balance detected');
      debugPrint('⚠️ [DRIVER-WALLET-NOTIFICATIONS] Balance: RM ${currentBalance.toStringAsFixed(2)}');
      debugPrint('⚠️ [DRIVER-WALLET-NOTIFICATIONS] Threshold: RM ${state.lowBalanceThreshold.toStringAsFixed(2)}');

      _notificationService.sendLowBalanceAlert(
        driverId: driverId,
        currentBalance: currentBalance,
        threshold: state.lowBalanceThreshold,
      );

      _updateLastNotificationSent();
    }
  }

  /// Send earnings notification manually (called from earnings integration)
  Future<void> sendEarningsNotification({
    required String orderId,
    required double earningsAmount,
    required double newBalance,
    required Map<String, dynamic> earningsBreakdown,
  }) async {
    if (!state.earningsNotificationsEnabled) return;

    final authState = _ref.read(authStateProvider);
    if (authState.user?.role != UserRole.driver) return;

    final driverId = authState.user!.id;

    debugPrint('💰 [DRIVER-WALLET-NOTIFICATIONS] Sending earnings notification');
    debugPrint('💰 [DRIVER-WALLET-NOTIFICATIONS] Order: $orderId, Amount: RM ${earningsAmount.toStringAsFixed(2)}');

    await _notificationService.sendEarningsNotification(
      driverId: driverId,
      orderId: orderId,
      earningsAmount: earningsAmount,
      newBalance: newBalance,
      earningsBreakdown: earningsBreakdown,
    );

    _updateLastNotificationSent();
  }

  /// Send withdrawal notification manually (called from withdrawal processing)
  Future<void> sendWithdrawalNotification({
    required String withdrawalId,
    required double amount,
    required String status,
    required String withdrawalMethod,
    String? failureReason,
  }) async {
    if (!state.withdrawalNotificationsEnabled) return;

    final authState = _ref.read(authStateProvider);
    if (authState.user?.role != UserRole.driver) return;

    final driverId = authState.user!.id;

    debugPrint('💸 [DRIVER-WALLET-NOTIFICATIONS] Sending withdrawal notification');
    debugPrint('💸 [DRIVER-WALLET-NOTIFICATIONS] Withdrawal: $withdrawalId, Status: $status');

    await _notificationService.sendWithdrawalNotification(
      driverId: driverId,
      withdrawalId: withdrawalId,
      amount: amount,
      status: status,
      withdrawalMethod: withdrawalMethod,
      failureReason: failureReason,
    );

    _updateLastNotificationSent();
  }

  /// Update notification preferences
  void updateNotificationPreferences({
    bool? earningsNotificationsEnabled,
    bool? lowBalanceAlertsEnabled,
    bool? balanceUpdatesEnabled,
    bool? withdrawalNotificationsEnabled,
    double? lowBalanceThreshold,
  }) {
    debugPrint('⚙️ [DRIVER-WALLET-NOTIFICATIONS] Updating notification preferences');
    
    state = state.copyWith(
      earningsNotificationsEnabled: earningsNotificationsEnabled,
      lowBalanceAlertsEnabled: lowBalanceAlertsEnabled,
      balanceUpdatesEnabled: balanceUpdatesEnabled,
      withdrawalNotificationsEnabled: withdrawalNotificationsEnabled,
      lowBalanceThreshold: lowBalanceThreshold,
    );

    debugPrint('✅ [DRIVER-WALLET-NOTIFICATIONS] Notification preferences updated');
  }

  /// Enable/disable all notifications
  void setNotificationsEnabled(bool enabled) {
    debugPrint('🔔 [DRIVER-WALLET-NOTIFICATIONS] ${enabled ? 'Enabling' : 'Disabling'} all notifications');
    
    state = state.copyWith(isEnabled: enabled);
  }

  /// Update last notification sent timestamp
  void _updateLastNotificationSent() {
    state = state.copyWith(lastNotificationSent: DateTime.now());
  }

  @override
  void dispose() {
    debugPrint('🔔 [DRIVER-WALLET-NOTIFICATIONS] Disposing notification notifier');
    super.dispose();
  }
}

/// Main driver wallet notification provider
final driverWalletNotificationProvider = StateNotifierProvider<DriverWalletNotificationNotifier, DriverWalletNotificationState>((ref) {
  final notificationService = ref.watch(driverWalletNotificationServiceProvider);
  return DriverWalletNotificationNotifier(notificationService, ref);
});

/// Provider for checking if notifications are enabled
final driverWalletNotificationsEnabledProvider = Provider<bool>((ref) {
  final notificationState = ref.watch(driverWalletNotificationProvider);
  return notificationState.isEnabled;
});

/// Provider for low balance alert status
final driverWalletLowBalanceAlertProvider = Provider<Map<String, dynamic>?>((ref) {
  final walletState = ref.watch(driverWalletProvider);
  final notificationState = ref.watch(driverWalletNotificationProvider);

  if (walletState.wallet == null || !notificationState.lowBalanceAlertsEnabled) {
    return null;
  }

  final wallet = walletState.wallet!;
  final threshold = notificationState.lowBalanceThreshold;
  
  if (wallet.availableBalance < threshold && wallet.availableBalance > 0) {
    return {
      'type': 'low_balance',
      'title': 'Low Balance Alert',
      'message': 'Your wallet balance is low: ${wallet.formattedAvailableBalance}',
      'severity': wallet.availableBalance <= 5.0 ? 'critical' : 'warning',
      'current_balance': wallet.availableBalance,
      'threshold': threshold,
    };
  }

  return null;
});
