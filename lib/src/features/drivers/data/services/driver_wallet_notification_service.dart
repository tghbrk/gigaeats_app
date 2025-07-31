import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/notification_service.dart';
import '../../../notifications/data/models/notification.dart';
import '../../../notifications/data/services/notification_service.dart' as app_notifications;
// Removed unused imports

/// Comprehensive notification service for driver wallet events
class DriverWalletNotificationService {
  final SupabaseClient _supabase;
  final NotificationService _notificationService;
  final app_notifications.NotificationService _appNotificationService;

  DriverWalletNotificationService({
    required SupabaseClient supabase,
    required NotificationService notificationService,
    required app_notifications.NotificationService appNotificationService,
  }) : _supabase = supabase,
       _notificationService = notificationService,
       _appNotificationService = appNotificationService;

  /// Send earnings notification when delivery is completed
  Future<void> sendEarningsNotification({
    required String driverId,
    required String orderId,
    required double earningsAmount,
    required double newBalance,
    required Map<String, dynamic> earningsBreakdown,
  }) async {
    try {
      debugPrint('💰 [DRIVER-WALLET-NOTIFICATIONS] Sending earnings notification');
      debugPrint('💰 [DRIVER-WALLET-NOTIFICATIONS] Driver: $driverId, Order: $orderId');
      debugPrint('💰 [DRIVER-WALLET-NOTIFICATIONS] Earnings: RM ${earningsAmount.toStringAsFixed(2)}');

      final formattedEarnings = 'RM ${earningsAmount.toStringAsFixed(2)}';
      final formattedBalance = 'RM ${newBalance.toStringAsFixed(2)}';

      // Create rich notification content
      final richContent = {
        'earnings_amount': earningsAmount,
        'new_balance': newBalance,
        'order_id': orderId,
        'earnings_breakdown': earningsBreakdown,
        'notification_type': 'earnings_received',
      };

      // Send in-app notification
      final appNotification = AppNotification(
        id: 'earnings_${orderId}_${DateTime.now().millisecondsSinceEpoch}',
        title: '💰 Earnings Received',
        message: 'You earned $formattedEarnings from your delivery! New balance: $formattedBalance',
        type: NotificationType.paymentReceived,
        priority: NotificationPriority.high,
        userId: driverId,
        orderId: orderId,
        createdAt: DateTime.now(),
        data: richContent,
      );

      await _appNotificationService.addNotification(appNotification);

      // Send local push notification
      await _notificationService.showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: '💰 Earnings Received',
        body: 'You earned $formattedEarnings from your delivery! New balance: $formattedBalance',
        payload: orderId,
      );

      // Store notification in database
      await _storeNotificationInDatabase(
        driverId: driverId,
        type: 'earnings_received',
        title: '💰 Earnings Received',
        message: 'You earned $formattedEarnings from your delivery! New balance: $formattedBalance',
        data: richContent,
      );

      debugPrint('✅ [DRIVER-WALLET-NOTIFICATIONS] Earnings notification sent successfully');
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-NOTIFICATIONS] Error sending earnings notification: $e');
    }
  }

  /// Send low balance alert notification
  Future<void> sendLowBalanceAlert({
    required String driverId,
    required double currentBalance,
    required double threshold,
  }) async {
    try {
      debugPrint('⚠️ [DRIVER-WALLET-NOTIFICATIONS] Sending low balance alert');
      debugPrint('⚠️ [DRIVER-WALLET-NOTIFICATIONS] Driver: $driverId');
      debugPrint('⚠️ [DRIVER-WALLET-NOTIFICATIONS] Balance: RM ${currentBalance.toStringAsFixed(2)}');

      final formattedBalance = 'RM ${currentBalance.toStringAsFixed(2)}';

      // Create rich notification content
      final richContent = {
        'current_balance': currentBalance,
        'threshold': threshold,
        'notification_type': 'low_balance_alert',
        'severity': currentBalance <= 5.0 ? 'critical' : 'warning',
      };

      final severity = currentBalance <= 5.0 ? 'Critical' : 'Warning';
      final title = '⚠️ $severity: Low Balance Alert';
      final message = currentBalance <= 5.0
          ? 'Your wallet balance is critically low: $formattedBalance. Consider withdrawing your earnings or topping up.'
          : 'Your wallet balance is low: $formattedBalance. You may want to withdraw your earnings soon.';

      // Send in-app notification
      final appNotification = AppNotification(
        id: 'low_balance_${driverId}_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        type: NotificationType.systemAlert,
        priority: currentBalance <= 5.0 ? NotificationPriority.high : NotificationPriority.normal,
        userId: driverId,
        createdAt: DateTime.now(),
        data: richContent,
      );

      await _appNotificationService.addNotification(appNotification);

      // Send local push notification for critical alerts
      if (currentBalance <= 5.0) {
        await _notificationService.showLocalNotification(
          id: DateTime.now().millisecondsSinceEpoch,
          title: title,
          body: message,
          payload: 'wallet_low_balance',
        );
      }

      // Store notification in database
      await _storeNotificationInDatabase(
        driverId: driverId,
        type: 'low_balance_alert',
        title: title,
        message: message,
        data: richContent,
      );

      debugPrint('✅ [DRIVER-WALLET-NOTIFICATIONS] Low balance alert sent successfully');
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-NOTIFICATIONS] Error sending low balance alert: $e');
    }
  }

  /// Send balance update notification for significant changes
  Future<void> sendBalanceUpdateNotification({
    required String driverId,
    required double previousBalance,
    required double newBalance,
    required String updateReason,
    String? transactionId,
  }) async {
    try {
      final difference = newBalance - previousBalance;
      final isIncrease = difference > 0;
      
      // Only send notifications for significant changes (> RM 1.00)
      if (difference.abs() < 1.0) return;

      debugPrint('🔄 [DRIVER-WALLET-NOTIFICATIONS] Sending balance update notification');
      debugPrint('🔄 [DRIVER-WALLET-NOTIFICATIONS] Driver: $driverId');
      debugPrint('🔄 [DRIVER-WALLET-NOTIFICATIONS] Change: RM ${difference.toStringAsFixed(2)}');

      final formattedDifference = 'RM ${difference.abs().toStringAsFixed(2)}';
      final formattedNewBalance = 'RM ${newBalance.toStringAsFixed(2)}';

      // Create rich notification content
      final richContent = {
        'previous_balance': previousBalance,
        'new_balance': newBalance,
        'difference': difference,
        'update_reason': updateReason,
        'transaction_id': transactionId,
        'notification_type': 'balance_update',
      };

      final title = isIncrease ? '📈 Balance Increased' : '📉 Balance Decreased';
      final message = 'Your wallet balance ${isIncrease ? 'increased' : 'decreased'} by $formattedDifference. New balance: $formattedNewBalance';

      // Send in-app notification
      final appNotification = AppNotification(
        id: 'balance_update_${driverId}_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        type: NotificationType.systemAlert,
        priority: NotificationPriority.normal,
        userId: driverId,
        createdAt: DateTime.now(),
        data: richContent,
      );

      await _appNotificationService.addNotification(appNotification);

      // Store notification in database
      await _storeNotificationInDatabase(
        driverId: driverId,
        type: 'balance_update',
        title: title,
        message: message,
        data: richContent,
      );

      debugPrint('✅ [DRIVER-WALLET-NOTIFICATIONS] Balance update notification sent successfully');
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-NOTIFICATIONS] Error sending balance update notification: $e');
    }
  }

  /// Send withdrawal notification
  Future<void> sendWithdrawalNotification({
    required String driverId,
    required String withdrawalId,
    required double amount,
    required String status,
    required String withdrawalMethod,
    String? failureReason,
  }) async {
    try {
      debugPrint('💸 [DRIVER-WALLET-NOTIFICATIONS] Sending withdrawal notification');
      debugPrint('💸 [DRIVER-WALLET-NOTIFICATIONS] Driver: $driverId, Status: $status');

      final formattedAmount = 'RM ${amount.toStringAsFixed(2)}';

      // Create rich notification content
      final richContent = {
        'withdrawal_id': withdrawalId,
        'amount': amount,
        'status': status,
        'withdrawal_method': withdrawalMethod,
        'failure_reason': failureReason,
        'notification_type': 'withdrawal_update',
      };

      String title;
      String message;
      NotificationPriority priority;

      switch (status.toLowerCase()) {
        case 'completed':
          title = '✅ Withdrawal Completed';
          message = 'Your withdrawal of $formattedAmount has been completed successfully.';
          priority = NotificationPriority.high;
          break;
        case 'failed':
          title = '❌ Withdrawal Failed';
          message = 'Your withdrawal of $formattedAmount has failed. ${failureReason ?? 'Please try again or contact support.'}';
          priority = NotificationPriority.high;
          break;
        case 'processing':
          title = '⏳ Withdrawal Processing';
          message = 'Your withdrawal of $formattedAmount is being processed.';
          priority = NotificationPriority.normal;
          break;
        default:
          title = '📋 Withdrawal Update';
          message = 'Your withdrawal of $formattedAmount status: $status';
          priority = NotificationPriority.normal;
      }

      // Send in-app notification
      final appNotification = AppNotification(
        id: 'withdrawal_${withdrawalId}_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        type: NotificationType.paymentReceived,
        priority: priority,
        userId: driverId,
        createdAt: DateTime.now(),
        data: richContent,
      );

      await _appNotificationService.addNotification(appNotification);

      // Send local push notification for completed/failed withdrawals
      if (status.toLowerCase() == 'completed' || status.toLowerCase() == 'failed') {
        await _notificationService.showLocalNotification(
          id: DateTime.now().millisecondsSinceEpoch,
          title: title,
          body: message,
          payload: withdrawalId,
        );
      }

      // Store notification in database
      await _storeNotificationInDatabase(
        driverId: driverId,
        type: 'withdrawal_update',
        title: title,
        message: message,
        data: richContent,
      );

      debugPrint('✅ [DRIVER-WALLET-NOTIFICATIONS] Withdrawal notification sent successfully');
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-NOTIFICATIONS] Error sending withdrawal notification: $e');
    }
  }

  /// Store notification in database for persistence
  Future<void> _storeNotificationInDatabase({
    required String driverId,
    required String type,
    required String title,
    required String message,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'recipient_id': driverId,
        'title': title,
        'message': message,
        'type': type,
        'data': data,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-NOTIFICATIONS] Error storing notification in database: $e');
    }
  }
}
