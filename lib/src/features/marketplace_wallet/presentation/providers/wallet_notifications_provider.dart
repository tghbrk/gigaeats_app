import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/stakeholder_wallet.dart';
import '../../data/models/wallet_transaction.dart';
import '../../data/models/payout_request.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import 'wallet_state_provider.dart';
import 'wallet_transactions_provider.dart';


/// Wallet notification types
enum WalletNotificationType {
  balanceUpdate,
  transactionReceived,
  payoutCompleted,
  payoutFailed,
  autoPayoutTriggered,
  lowBalance,
  verificationRequired,
}

/// Wallet notification data class
class WalletNotification {
  final String id;
  final WalletNotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final bool isRead;
  final String? actionUrl;

  const WalletNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.timestamp,
    this.isRead = false,
    this.actionUrl,
  });

  WalletNotification copyWith({
    String? id,
    WalletNotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    String? actionUrl,
  }) {
    return WalletNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case WalletNotificationType.balanceUpdate:
        return 'Balance Update';
      case WalletNotificationType.transactionReceived:
        return 'Transaction Received';
      case WalletNotificationType.payoutCompleted:
        return 'Payout Completed';
      case WalletNotificationType.payoutFailed:
        return 'Payout Failed';
      case WalletNotificationType.autoPayoutTriggered:
        return 'Auto Payout';
      case WalletNotificationType.lowBalance:
        return 'Low Balance';
      case WalletNotificationType.verificationRequired:
        return 'Verification Required';
    }
  }

  String get iconName {
    switch (type) {
      case WalletNotificationType.balanceUpdate:
        return 'account_balance_wallet';
      case WalletNotificationType.transactionReceived:
        return 'payment';
      case WalletNotificationType.payoutCompleted:
        return 'check_circle';
      case WalletNotificationType.payoutFailed:
        return 'error';
      case WalletNotificationType.autoPayoutTriggered:
        return 'autorenew';
      case WalletNotificationType.lowBalance:
        return 'warning';
      case WalletNotificationType.verificationRequired:
        return 'verified_user';
    }
  }
}

/// Wallet notifications state
class WalletNotificationsState {
  final List<WalletNotification> notifications;
  final bool isLoading;
  final String? errorMessage;
  final int unreadCount;
  final DateTime? lastUpdated;

  const WalletNotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
    this.unreadCount = 0,
    this.lastUpdated,
  });

  WalletNotificationsState copyWith({
    List<WalletNotification>? notifications,
    bool? isLoading,
    String? errorMessage,
    int? unreadCount,
    DateTime? lastUpdated,
  }) {
    return WalletNotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get hasUnreadNotifications => unreadCount > 0;
  bool get isEmpty => notifications.isEmpty && !isLoading;
}

/// Wallet notifications notifier for managing notifications
class WalletNotificationsNotifier extends StateNotifier<WalletNotificationsState> {
  final Ref _ref;
  final String _userRole;

  WalletNotificationsNotifier(this._ref, this._userRole) : super(const WalletNotificationsState()) {
    _initialize();
  }

  void _initialize() {
    debugPrint('🔔 [WALLET-NOTIFICATIONS] Initializing notifications for role: $_userRole');
    _setupRealtimeListeners();
  }

  /// Setup real-time listeners for wallet updates
  void _setupRealtimeListeners() {
    // Listen to wallet stream for balance updates
    _ref.listen(walletStreamProvider(_userRole), (previous, next) {
      next.when(
        data: (wallet) => _handleWalletUpdate(previous?.value, wallet),
        loading: () {},
        error: (error, stack) {},
      );
    });

    // Listen to transaction stream for new transactions
    final walletState = _ref.read(walletStateProvider(_userRole));
    if (walletState.wallet != null) {
      _ref.listen(transactionStreamProvider(walletState.wallet!.id), (previous, next) {
        next.when(
          data: (transactions) => _handleTransactionUpdate(previous?.value, transactions),
          loading: () {},
          error: (error, stack) {},
        );
      });
    }
  }

  /// Handle wallet updates
  void _handleWalletUpdate(StakeholderWallet? previousWallet, StakeholderWallet? currentWallet) {
    if (previousWallet == null || currentWallet == null) return;

    // Check for balance changes
    if (previousWallet.availableBalance != currentWallet.availableBalance) {
      final difference = currentWallet.availableBalance - previousWallet.availableBalance;
      _addBalanceUpdateNotification(difference, currentWallet.availableBalance);
    }

    // Check for low balance
    if (currentWallet.availableBalance < 50.0 && previousWallet.availableBalance >= 50.0) {
      _addLowBalanceNotification(currentWallet.availableBalance);
    }

    // Check for auto payout eligibility
    if (currentWallet.isAutoPayoutEligible && !previousWallet.isAutoPayoutEligible) {
      _addAutoPayoutNotification(currentWallet.availableBalance, currentWallet.autoPayoutThreshold!);
    }

    // Check for verification status changes
    if (!previousWallet.isVerified && currentWallet.isVerified) {
      _addVerificationCompletedNotification();
    } else if (previousWallet.isVerified && !currentWallet.isVerified) {
      _addVerificationRequiredNotification();
    }
  }

  /// Handle transaction updates
  void _handleTransactionUpdate(List<WalletTransaction>? previousTransactions, List<WalletTransaction>? currentTransactions) {
    if (previousTransactions == null || currentTransactions == null) return;

    // Find new transactions
    final newTransactions = currentTransactions.where((current) {
      return !previousTransactions.any((previous) => previous.id == current.id);
    }).toList();

    // Add notifications for new transactions
    for (final transaction in newTransactions) {
      _addTransactionNotification(transaction);
    }
  }

  /// Add balance update notification
  void _addBalanceUpdateNotification(double difference, double newBalance) {
    final isIncrease = difference > 0;
    final notification = WalletNotification(
      id: 'balance_${DateTime.now().millisecondsSinceEpoch}',
      type: WalletNotificationType.balanceUpdate,
      title: isIncrease ? 'Balance Increased' : 'Balance Decreased',
      message: 'Your wallet balance ${isIncrease ? 'increased' : 'decreased'} by MYR ${difference.abs().toStringAsFixed(2)}. New balance: MYR ${newBalance.toStringAsFixed(2)}',
      timestamp: DateTime.now(),
      data: {
        'difference': difference,
        'new_balance': newBalance,
      },
    );

    _addNotification(notification);
  }

  /// Add transaction notification
  void _addTransactionNotification(WalletTransaction transaction) {
    final notification = WalletNotification(
      id: 'transaction_${transaction.id}',
      type: WalletNotificationType.transactionReceived,
      title: 'New ${transaction.transactionType.displayName}',
      message: '${transaction.displayDescription} - ${transaction.formattedAmount}',
      timestamp: transaction.createdAt,
      data: {
        'transaction_id': transaction.id,
        'amount': transaction.amount,
        'type': transaction.transactionType.value,
      },
      actionUrl: '/wallet/transactions/${transaction.id}',
    );

    _addNotification(notification);
  }

  /// Add low balance notification
  void _addLowBalanceNotification(double balance) {
    final notification = WalletNotification(
      id: 'low_balance_${DateTime.now().millisecondsSinceEpoch}',
      type: WalletNotificationType.lowBalance,
      title: 'Low Balance Alert',
      message: 'Your wallet balance is low (MYR ${balance.toStringAsFixed(2)}). Consider adding funds or completing more orders.',
      timestamp: DateTime.now(),
      data: {'balance': balance},
      actionUrl: '/wallet/top-up',
    );

    _addNotification(notification);
  }

  /// Add auto payout notification
  void _addAutoPayoutNotification(double balance, double threshold) {
    final notification = WalletNotification(
      id: 'auto_payout_${DateTime.now().millisecondsSinceEpoch}',
      type: WalletNotificationType.autoPayoutTriggered,
      title: 'Auto Payout Eligible',
      message: 'Your balance (MYR ${balance.toStringAsFixed(2)}) has reached the auto payout threshold (MYR ${threshold.toStringAsFixed(2)}). Payout will be processed automatically.',
      timestamp: DateTime.now(),
      data: {
        'balance': balance,
        'threshold': threshold,
      },
      actionUrl: '/wallet/payouts',
    );

    _addNotification(notification);
  }

  /// Add verification required notification
  void _addVerificationRequiredNotification() {
    final notification = WalletNotification(
      id: 'verification_required_${DateTime.now().millisecondsSinceEpoch}',
      type: WalletNotificationType.verificationRequired,
      title: 'Verification Required',
      message: 'Please verify your account to continue using wallet features and request payouts.',
      timestamp: DateTime.now(),
      actionUrl: '/wallet/verification',
    );

    _addNotification(notification);
  }

  /// Add verification completed notification
  void _addVerificationCompletedNotification() {
    final notification = WalletNotification(
      id: 'verification_completed_${DateTime.now().millisecondsSinceEpoch}',
      type: WalletNotificationType.verificationRequired,
      title: 'Verification Completed',
      message: 'Your account has been successfully verified. You can now access all wallet features.',
      timestamp: DateTime.now(),
      actionUrl: '/wallet',
    );

    _addNotification(notification);
  }

  /// Add payout completed notification
  void addPayoutCompletedNotification(PayoutRequest payout) {
    final notification = WalletNotification(
      id: 'payout_completed_${payout.id}',
      type: WalletNotificationType.payoutCompleted,
      title: 'Payout Completed',
      message: 'Your payout of ${payout.formattedNetAmount} to ${payout.bankName} has been completed successfully.',
      timestamp: payout.completedAt ?? DateTime.now(),
      data: {
        'payout_id': payout.id,
        'amount': payout.amount,
        'net_amount': payout.netAmount,
        'bank_name': payout.bankName,
      },
      actionUrl: '/wallet/payouts/${payout.id}',
    );

    _addNotification(notification);
  }

  /// Add payout failed notification
  void addPayoutFailedNotification(PayoutRequest payout) {
    final notification = WalletNotification(
      id: 'payout_failed_${payout.id}',
      type: WalletNotificationType.payoutFailed,
      title: 'Payout Failed',
      message: 'Your payout of ${payout.formattedAmount} to ${payout.bankName} has failed. ${payout.failureReason ?? 'Please try again or contact support.'}',
      timestamp: payout.failedAt ?? DateTime.now(),
      data: {
        'payout_id': payout.id,
        'amount': payout.amount,
        'bank_name': payout.bankName,
        'failure_reason': payout.failureReason,
      },
      actionUrl: '/wallet/payouts/${payout.id}',
    );

    _addNotification(notification);
  }

  /// Add notification to state
  void _addNotification(WalletNotification notification) {
    final updatedNotifications = [notification, ...state.notifications];
    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications.take(50).toList(), // Keep only last 50 notifications
      unreadCount: unreadCount,
      lastUpdated: DateTime.now(),
    );

    debugPrint('🔔 [WALLET-NOTIFICATIONS] Added notification: ${notification.title}');
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final updatedNotifications = state.notifications.map((notification) {
      return notification.id == notificationId
          ? notification.copyWith(isRead: true)
          : notification;
    }).toList();

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
      lastUpdated: DateTime.now(),
    );

    debugPrint('🔔 [WALLET-NOTIFICATIONS] Marked notification as read: $notificationId');
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    final updatedNotifications = state.notifications.map((notification) {
      return notification.copyWith(isRead: true);
    }).toList();

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: 0,
      lastUpdated: DateTime.now(),
    );

    debugPrint('🔔 [WALLET-NOTIFICATIONS] Marked all notifications as read');
  }

  /// Clear all notifications
  void clearAllNotifications() {
    state = state.copyWith(
      notifications: [],
      unreadCount: 0,
      lastUpdated: DateTime.now(),
    );

    debugPrint('🔔 [WALLET-NOTIFICATIONS] Cleared all notifications');
  }

  /// Remove specific notification
  void removeNotification(String notificationId) {
    final updatedNotifications = state.notifications.where((n) => n.id != notificationId).toList();
    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
      lastUpdated: DateTime.now(),
    );

    debugPrint('🔔 [WALLET-NOTIFICATIONS] Removed notification: $notificationId');
  }

  @override
  void dispose() {
    debugPrint('🔔 [WALLET-NOTIFICATIONS] Disposing notifications notifier');
    super.dispose();
  }
}

/// Wallet notifications provider for different user roles
final walletNotificationsProvider = StateNotifierProvider.family<WalletNotificationsNotifier, WalletNotificationsState, String>((ref, userRole) {
  return WalletNotificationsNotifier(ref, userRole);
});

/// Current user wallet notifications provider
final currentUserWalletNotificationsProvider = StateNotifierProvider<WalletNotificationsNotifier, WalletNotificationsState>((ref) {
  final authState = ref.watch(authStateProvider);
  final userRole = authState.user?.role.value ?? 'customer';
  
  return WalletNotificationsNotifier(ref, userRole);
});

/// Unread notifications count provider
final unreadNotificationsCountProvider = Provider.family<int, String>((ref, userRole) {
  final notificationsState = ref.watch(walletNotificationsProvider(userRole));
  return notificationsState.unreadCount;
});

/// Current user unread notifications count provider
final currentUserUnreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsState = ref.watch(currentUserWalletNotificationsProvider);
  return notificationsState.unreadCount;
});

/// Wallet notifications actions provider
final walletNotificationsActionsProvider = Provider<WalletNotificationsActions>((ref) {
  return WalletNotificationsActions(ref);
});

/// Wallet notifications actions class
class WalletNotificationsActions {
  final Ref _ref;

  WalletNotificationsActions(this._ref);

  /// Mark notification as read
  void markAsRead(String userRole, String notificationId) {
    final notifier = _ref.read(walletNotificationsProvider(userRole).notifier);
    notifier.markAsRead(notificationId);
  }

  /// Mark all notifications as read
  void markAllAsRead(String userRole) {
    final notifier = _ref.read(walletNotificationsProvider(userRole).notifier);
    notifier.markAllAsRead();
  }

  /// Clear all notifications
  void clearAllNotifications(String userRole) {
    final notifier = _ref.read(walletNotificationsProvider(userRole).notifier);
    notifier.clearAllNotifications();
  }

  /// Remove specific notification
  void removeNotification(String userRole, String notificationId) {
    final notifier = _ref.read(walletNotificationsProvider(userRole).notifier);
    notifier.removeNotification(notificationId);
  }

  /// Add payout completed notification
  void addPayoutCompletedNotification(String userRole, PayoutRequest payout) {
    final notifier = _ref.read(walletNotificationsProvider(userRole).notifier);
    notifier.addPayoutCompletedNotification(payout);
  }

  /// Add payout failed notification
  void addPayoutFailedNotification(String userRole, PayoutRequest payout) {
    final notifier = _ref.read(walletNotificationsProvider(userRole).notifier);
    notifier.addPayoutFailedNotification(payout);
  }

  /// Get notifications state
  WalletNotificationsState getNotificationsState(String userRole) {
    return _ref.read(walletNotificationsProvider(userRole));
  }
}
