import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/notification_service.dart';
import '../../../notifications/data/services/notification_service.dart' as app_notifications;
import '../../../notifications/data/models/notification.dart';
import '../models/driver_withdrawal_request.dart';

/// Enhanced service for withdrawal-related notifications with real-time updates
class EnhancedWithdrawalNotificationService {
  final SupabaseClient _supabase;
  final NotificationService _notificationService;
  final app_notifications.NotificationService _appNotificationService;

  EnhancedWithdrawalNotificationService({
    required SupabaseClient supabase,
    required NotificationService notificationService,
    required app_notifications.NotificationService appNotificationService,
  })  : _supabase = supabase,
        _notificationService = notificationService,
        _appNotificationService = appNotificationService;

  /// Send comprehensive withdrawal status notification
  Future<void> sendWithdrawalStatusNotification({
    required String driverId,
    required DriverWithdrawalRequest request,
    String? previousStatus,
  }) async {
    try {
      debugPrint('🔔 [ENHANCED-WITHDRAWAL-NOTIFICATIONS] Sending status notification');
      debugPrint('🔔 [ENHANCED-WITHDRAWAL-NOTIFICATIONS] Status: ${request.status.name} (was: $previousStatus)');

      final notificationData = _buildNotificationData(request, previousStatus);
      
      // Send in-app notification
      await _sendInAppNotification(driverId, notificationData, request);
      
      // Send push notification for important status changes
      if (_shouldSendPushNotification(request.status)) {
        await _sendPushNotification(notificationData, request);
      }
      
      // Store notification in database for history
      await _storeNotificationInDatabase(driverId, notificationData, request);
      
      debugPrint('✅ [ENHANCED-WITHDRAWAL-NOTIFICATIONS] Status notification sent successfully');
    } catch (e) {
      debugPrint('❌ [ENHANCED-WITHDRAWAL-NOTIFICATIONS] Error sending status notification: $e');
      rethrow;
    }
  }

  /// Send balance update notification after withdrawal processing
  Future<void> sendBalanceUpdateNotification({
    required String driverId,
    required double previousBalance,
    required double newBalance,
    required DriverWithdrawalRequest request,
  }) async {
    try {
      debugPrint('💰 [ENHANCED-WITHDRAWAL-NOTIFICATIONS] Sending balance update notification');
      debugPrint('💰 [ENHANCED-WITHDRAWAL-NOTIFICATIONS] Balance: RM ${previousBalance.toStringAsFixed(2)} → RM ${newBalance.toStringAsFixed(2)}');

      final difference = newBalance - previousBalance;
      final formattedDifference = 'RM ${difference.abs().toStringAsFixed(2)}';
      final formattedNewBalance = 'RM ${newBalance.toStringAsFixed(2)}';

      final notificationData = {
        'title': '💰 Wallet Balance Updated',
        'message': 'Your wallet balance decreased by $formattedDifference due to withdrawal processing. New balance: $formattedNewBalance',
        'type': 'balance_update',
        'priority': 'normal',
        'data': {
          'withdrawal_id': request.id,
          'previous_balance': previousBalance,
          'new_balance': newBalance,
          'difference': difference,
          'withdrawal_amount': request.amount,
          'update_reason': 'withdrawal_processing',
        },
      };

      // Send in-app notification
      final appNotification = AppNotification(
        id: 'balance_update_${request.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: notificationData['title'] as String,
        message: notificationData['message'] as String,
        type: NotificationType.systemAlert,
        priority: NotificationPriority.normal,
        userId: driverId,
        createdAt: DateTime.now(),
        data: notificationData['data'] as Map<String, dynamic>,
      );

      await _appNotificationService.addNotification(appNotification);

      // Store in database
      await _storeNotificationInDatabase(driverId, notificationData, request);

      debugPrint('✅ [ENHANCED-WITHDRAWAL-NOTIFICATIONS] Balance update notification sent');
    } catch (e) {
      debugPrint('❌ [ENHANCED-WITHDRAWAL-NOTIFICATIONS] Error sending balance update notification: $e');
      rethrow;
    }
  }

  /// Send withdrawal completion summary notification
  Future<void> sendWithdrawalCompletionSummary({
    required String driverId,
    required DriverWithdrawalRequest request,
    required double finalBalance,
  }) async {
    try {
      debugPrint('📋 [ENHANCED-WITHDRAWAL-NOTIFICATIONS] Sending completion summary');

      final processingTime = request.completedAt != null && request.processedAt != null
          ? request.completedAt!.difference(request.processedAt!).inHours
          : null;

      final summaryData = {
        'title': '✅ Withdrawal Complete - Summary',
        'message': 'Your withdrawal of RM ${request.amount.toStringAsFixed(2)} has been completed successfully.',
        'type': 'withdrawal_summary',
        'priority': 'high',
        'data': {
          'withdrawal_id': request.id,
          'amount': request.amount,
          'net_amount': request.netAmount,
          'processing_fee': request.processingFee,
          'withdrawal_method': request.withdrawalMethod,
          'final_balance': finalBalance,
          'processing_time_hours': processingTime,
          'transaction_reference': request.transactionReference,
          'completed_at': request.completedAt?.toIso8601String(),
        },
      };

      // Send comprehensive in-app notification
      final appNotification = AppNotification(
        id: 'withdrawal_summary_${request.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: summaryData['title'] as String,
        message: summaryData['message'] as String,
        type: NotificationType.paymentReceived,
        priority: NotificationPriority.high,
        userId: driverId,
        createdAt: DateTime.now(),
        data: summaryData['data'] as Map<String, dynamic>,
      );

      await _appNotificationService.addNotification(appNotification);

      // Send push notification for completion
      await _notificationService.showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: summaryData['title'] as String,
        body: summaryData['message'] as String,
        payload: request.id,
      );

      // Store in database
      await _storeNotificationInDatabase(driverId, summaryData, request);

      debugPrint('✅ [ENHANCED-WITHDRAWAL-NOTIFICATIONS] Completion summary sent');
    } catch (e) {
      debugPrint('❌ [ENHANCED-WITHDRAWAL-NOTIFICATIONS] Error sending completion summary: $e');
      rethrow;
    }
  }

  /// Send withdrawal failure notification with detailed information
  Future<void> sendWithdrawalFailureNotification({
    required String driverId,
    required DriverWithdrawalRequest request,
    required String failureReason,
  }) async {
    try {
      debugPrint('❌ [ENHANCED-WITHDRAWAL-NOTIFICATIONS] Sending failure notification');

      final failureData = {
        'title': '❌ Withdrawal Failed',
        'message': 'Your withdrawal of RM ${request.amount.toStringAsFixed(2)} has failed. $failureReason',
        'type': 'withdrawal_failure',
        'priority': 'high',
        'data': {
          'withdrawal_id': request.id,
          'amount': request.amount,
          'failure_reason': failureReason,
          'withdrawal_method': request.withdrawalMethod,
          'can_retry': true,
          'support_contact': true,
          'failed_at': DateTime.now().toIso8601String(),
        },
      };

      // Send high-priority in-app notification
      final appNotification = AppNotification(
        id: 'withdrawal_failure_${request.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: failureData['title'] as String,
        message: failureData['message'] as String,
        type: NotificationType.systemAlert,
        priority: NotificationPriority.high,
        userId: driverId,
        createdAt: DateTime.now(),
        data: failureData['data'] as Map<String, dynamic>,
      );

      await _appNotificationService.addNotification(appNotification);

      // Send immediate push notification for failures
      await _notificationService.showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: failureData['title'] as String,
        body: failureData['message'] as String,
        payload: request.id,
      );

      // Store in database
      await _storeNotificationInDatabase(driverId, failureData, request);

      debugPrint('✅ [ENHANCED-WITHDRAWAL-NOTIFICATIONS] Failure notification sent');
    } catch (e) {
      debugPrint('❌ [ENHANCED-WITHDRAWAL-NOTIFICATIONS] Error sending failure notification: $e');
      rethrow;
    }
  }

  /// Build notification data based on withdrawal status
  Map<String, dynamic> _buildNotificationData(DriverWithdrawalRequest request, String? previousStatus) {
    final formattedAmount = 'RM ${request.amount.toStringAsFixed(2)}';
    
    switch (request.status) {
      case DriverWithdrawalStatus.pending:
        return {
          'title': '⏳ Withdrawal Request Submitted',
          'message': 'Your withdrawal request for $formattedAmount has been submitted and is pending approval.',
          'type': 'withdrawal_pending',
          'priority': 'normal',
        };
        
      case DriverWithdrawalStatus.processing:
        return {
          'title': '🔄 Withdrawal Processing',
          'message': 'Your withdrawal of $formattedAmount is now being processed.',
          'type': 'withdrawal_processing',
          'priority': 'normal',
        };
        
      case DriverWithdrawalStatus.completed:
        return {
          'title': '✅ Withdrawal Completed',
          'message': 'Your withdrawal of $formattedAmount has been completed successfully.',
          'type': 'withdrawal_completed',
          'priority': 'high',
        };
        
      case DriverWithdrawalStatus.failed:
        return {
          'title': '❌ Withdrawal Failed',
          'message': 'Your withdrawal of $formattedAmount has failed. ${request.failureReason ?? 'Please contact support.'}',
          'type': 'withdrawal_failed',
          'priority': 'high',
        };
        
      case DriverWithdrawalStatus.cancelled:
        return {
          'title': '🚫 Withdrawal Cancelled',
          'message': 'Your withdrawal of $formattedAmount has been cancelled.',
          'type': 'withdrawal_cancelled',
          'priority': 'normal',
        };
    }
  }

  /// Send in-app notification
  Future<void> _sendInAppNotification(
    String driverId,
    Map<String, dynamic> notificationData,
    DriverWithdrawalRequest request,
  ) async {
    final appNotification = AppNotification(
      id: 'withdrawal_${request.id}_${request.status.name}_${DateTime.now().millisecondsSinceEpoch}',
      title: notificationData['title'] as String,
      message: notificationData['message'] as String,
      type: _getNotificationType(request.status),
      priority: _getNotificationPriority(notificationData['priority'] as String),
      userId: driverId,
      createdAt: DateTime.now(),
      data: {
        'withdrawal_id': request.id,
        'status': request.status.name,
        'amount': request.amount,
        'withdrawal_method': request.withdrawalMethod,
        'transaction_reference': request.transactionReference,
        ...notificationData,
      },
    );

    await _appNotificationService.addNotification(appNotification);
  }

  /// Send push notification for important status changes
  Future<void> _sendPushNotification(
    Map<String, dynamic> notificationData,
    DriverWithdrawalRequest request,
  ) async {
    await _notificationService.showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: notificationData['title'] as String,
      body: notificationData['message'] as String,
      payload: request.id,
    );
  }

  /// Store notification in database for history
  Future<void> _storeNotificationInDatabase(
    String driverId,
    Map<String, dynamic> notificationData,
    DriverWithdrawalRequest request,
  ) async {
    await _supabase.from('notifications').insert({
      'recipient_id': driverId,
      'title': notificationData['title'],
      'message': notificationData['message'],
      'type': notificationData['type'],
      'priority': notificationData['priority'],
      'data': {
        'withdrawal_id': request.id,
        'status': request.status.name,
        'amount': request.amount,
        'withdrawal_method': request.withdrawalMethod,
        ...notificationData['data'] ?? {},
      },
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Determine if push notification should be sent
  bool _shouldSendPushNotification(DriverWithdrawalStatus status) {
    return status == DriverWithdrawalStatus.completed ||
           status == DriverWithdrawalStatus.failed ||
           status == DriverWithdrawalStatus.processing;
  }

  /// Get notification type based on withdrawal status
  NotificationType _getNotificationType(DriverWithdrawalStatus status) {
    switch (status) {
      case DriverWithdrawalStatus.completed:
        return NotificationType.paymentReceived;
      case DriverWithdrawalStatus.failed:
        return NotificationType.systemAlert;
      default:
        return NotificationType.systemAlert;
    }
  }

  /// Get notification priority
  NotificationPriority _getNotificationPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return NotificationPriority.high;
      case 'low':
        return NotificationPriority.low;
      default:
        return NotificationPriority.normal;
    }
  }
}
