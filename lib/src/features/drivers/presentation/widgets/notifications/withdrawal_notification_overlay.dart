import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../notifications/data/models/notification.dart';
import '../../../../notifications/data/services/notification_service.dart';
import 'withdrawal_notification_banner.dart';

/// Overlay widget for displaying withdrawal notifications as floating banners
class WithdrawalNotificationOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const WithdrawalNotificationOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<WithdrawalNotificationOverlay> createState() => _WithdrawalNotificationOverlayState();
}

class _WithdrawalNotificationOverlayState extends ConsumerState<WithdrawalNotificationOverlay> {
  final List<AppNotification> _activeNotifications = [];
  final Map<String, Timer> _dismissTimers = {};

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  @override
  void dispose() {
    // Cancel all timers
    for (final timer in _dismissTimers.values) {
      timer.cancel();
    }
    _dismissTimers.clear();
    super.dispose();
  }

  void _setupNotificationListener() {
    // Listen to new notifications from the notification service
    final notificationService = ref.read(notificationServiceProvider);
    
    notificationService.newNotificationStream.listen((notification) {
      if (_isWithdrawalNotification(notification)) {
        _showNotification(notification);
      }
    });
  }

  bool _isWithdrawalNotification(AppNotification notification) {
    final notificationType = notification.data?['type'] as String? ?? '';
    return notificationType.startsWith('withdrawal_') || 
           notificationType == 'balance_update';
  }

  void _showNotification(AppNotification notification) {
    if (mounted) {
      setState(() {
        _activeNotifications.add(notification);
      });

      // Auto-dismiss after delay based on priority
      final dismissDelay = _getDismissDelay(notification.priority);
      final timer = Timer(dismissDelay, () {
        _dismissNotification(notification.id);
      });
      
      _dismissTimers[notification.id] = timer;
    }
  }

  Duration _getDismissDelay(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return const Duration(seconds: 10);
      case NotificationPriority.high:
        return const Duration(seconds: 8);
      case NotificationPriority.normal:
        return const Duration(seconds: 6);
      case NotificationPriority.low:
        return const Duration(seconds: 4);
    }
  }

  void _dismissNotification(String notificationId) {
    if (mounted) {
      setState(() {
        _activeNotifications.removeWhere((n) => n.id == notificationId);
      });
      
      // Cancel and remove timer
      _dismissTimers[notificationId]?.cancel();
      _dismissTimers.remove(notificationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        widget.child,
        
        // Notification overlay
        if (_activeNotifications.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: _activeNotifications.map((notification) {
                  return WithdrawalNotificationBanner(
                    key: ValueKey(notification.id),
                    notification: notification,
                    onDismiss: () => _dismissNotification(notification.id),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Timer class for auto-dismissing notifications
class Timer {
  final Duration duration;
  final VoidCallback callback;
  bool _cancelled = false;

  Timer(this.duration, this.callback) {
    Future.delayed(duration).then((_) {
      if (!_cancelled) {
        callback();
      }
    });
  }

  void cancel() {
    _cancelled = true;
  }
}
