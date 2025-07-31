import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../domain/models/driver_document_verification.dart';
import '../../../../core/utils/logger.dart';

/// Logger for notification provider
final _logger = AppLogger();

/// Notification types for driver verification
enum VerificationNotificationType {
  documentUploaded,
  processingStarted,
  processingCompleted,
  verificationSuccess,
  verificationFailed,
  manualReviewRequired,
  identityVerified,
  documentExpired,
  error,
  warning,
  info,
}

/// Notification model for driver verification
class VerificationNotification {
  final String id;
  final VerificationNotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final bool isRead;
  final bool isPersistent;
  final Duration? autoHideDuration;
  final IconData? icon;
  final Color? color;

  const VerificationNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.data = const {},
    this.isRead = false,
    this.isPersistent = false,
    this.autoHideDuration,
    this.icon,
    this.color,
  });

  VerificationNotification copyWith({
    String? id,
    VerificationNotificationType? type,
    String? title,
    String? message,
    DateTime? timestamp,
    Map<String, dynamic>? data,
    bool? isRead,
    bool? isPersistent,
    Duration? autoHideDuration,
    IconData? icon,
    Color? color,
  }) {
    return VerificationNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      isPersistent: isPersistent ?? this.isPersistent,
      autoHideDuration: autoHideDuration ?? this.autoHideDuration,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  /// Get notification icon based on type
  IconData get defaultIcon {
    switch (type) {
      case VerificationNotificationType.documentUploaded:
        return Icons.upload_file;
      case VerificationNotificationType.processingStarted:
        return Icons.hourglass_empty;
      case VerificationNotificationType.processingCompleted:
        return Icons.check_circle;
      case VerificationNotificationType.verificationSuccess:
        return Icons.verified;
      case VerificationNotificationType.verificationFailed:
        return Icons.error;
      case VerificationNotificationType.manualReviewRequired:
        return Icons.person_search;
      case VerificationNotificationType.identityVerified:
        return Icons.verified_user;
      case VerificationNotificationType.documentExpired:
        return Icons.schedule;
      case VerificationNotificationType.error:
        return Icons.error_outline;
      case VerificationNotificationType.warning:
        return Icons.warning;
      case VerificationNotificationType.info:
        return Icons.info;
    }
  }

  /// Get notification color based on type
  Color get defaultColor {
    switch (type) {
      case VerificationNotificationType.documentUploaded:
      case VerificationNotificationType.processingStarted:
      case VerificationNotificationType.info:
        return Colors.blue;
      case VerificationNotificationType.processingCompleted:
      case VerificationNotificationType.verificationSuccess:
      case VerificationNotificationType.identityVerified:
        return Colors.green;
      case VerificationNotificationType.verificationFailed:
      case VerificationNotificationType.documentExpired:
      case VerificationNotificationType.error:
        return Colors.red;
      case VerificationNotificationType.manualReviewRequired:
      case VerificationNotificationType.warning:
        return Colors.orange;
    }
  }

  /// Check if notification should auto-hide
  bool get shouldAutoHide => autoHideDuration != null && !isPersistent;

  /// Check if notification is expired (for auto-hide)
  bool get isExpired {
    if (!shouldAutoHide) return false;
    return DateTime.now().difference(timestamp) > autoHideDuration!;
  }
}

/// State for verification notifications
class VerificationNotificationState {
  final List<VerificationNotification> notifications;
  final List<VerificationNotification> activeNotifications;
  final int unreadCount;
  final DateTime lastUpdated;

  const VerificationNotificationState({
    this.notifications = const [],
    this.activeNotifications = const [],
    this.unreadCount = 0,
    required this.lastUpdated,
  });

  VerificationNotificationState copyWith({
    List<VerificationNotification>? notifications,
    List<VerificationNotification>? activeNotifications,
    int? unreadCount,
    DateTime? lastUpdated,
  }) {
    return VerificationNotificationState(
      notifications: notifications ?? this.notifications,
      activeNotifications: activeNotifications ?? this.activeNotifications,
      unreadCount: unreadCount ?? this.unreadCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get notifications by type
  List<VerificationNotification> getNotificationsByType(VerificationNotificationType type) {
    return notifications.where((n) => n.type == type).toList();
  }

  /// Get recent notifications (last 24 hours)
  List<VerificationNotification> get recentNotifications {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return notifications.where((n) => n.timestamp.isAfter(yesterday)).toList();
  }

  /// Check if there are any error notifications
  bool get hasErrors => notifications.any((n) => n.type == VerificationNotificationType.error);

  /// Check if there are any warning notifications
  bool get hasWarnings => notifications.any((n) => n.type == VerificationNotificationType.warning);
}

/// Notification state notifier for driver verification
class VerificationNotificationNotifier extends StateNotifier<VerificationNotificationState> {
  VerificationNotificationNotifier() : super(VerificationNotificationState(lastUpdated: DateTime.now())) {
    _startAutoHideTimer();
  }

  /// Add a new notification
  void addNotification(VerificationNotification notification) {
    _logger.info('📢 Adding notification: ${notification.title}');
    
    final updatedNotifications = [notification, ...state.notifications];
    final updatedActiveNotifications = [...state.activeNotifications, notification];
    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
    
    state = state.copyWith(
      notifications: updatedNotifications,
      activeNotifications: updatedActiveNotifications,
      unreadCount: unreadCount,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create and add notification from verification status change
  void addVerificationStatusNotification(
    VerificationStatus oldStatus,
    VerificationStatus newStatus,
    DriverDocumentVerification verification,
  ) {
    final notification = _createStatusChangeNotification(oldStatus, newStatus, verification);
    if (notification != null) {
      addNotification(notification);
    }
  }

  /// Create and add document processing notification
  void addDocumentProcessingNotification(
    String documentType,
    String status,
    {String? documentSide, Map<String, dynamic>? data}
  ) {
    final notification = _createDocumentProcessingNotification(
      documentType,
      status,
      documentSide: documentSide,
      data: data,
    );
    if (notification != null) {
      addNotification(notification);
    }
  }

  /// Add error notification
  void addErrorNotification(String title, String message, {Map<String, dynamic>? data}) {
    final notification = VerificationNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: VerificationNotificationType.error,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      data: data ?? {},
      isPersistent: true,
      icon: Icons.error_outline,
      color: Colors.red,
    );
    
    addNotification(notification);
  }

  /// Add warning notification
  void addWarningNotification(String title, String message, {Map<String, dynamic>? data}) {
    final notification = VerificationNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: VerificationNotificationType.warning,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      data: data ?? {},
      autoHideDuration: const Duration(seconds: 8),
      icon: Icons.warning,
      color: Colors.orange,
    );
    
    addNotification(notification);
  }

  /// Add info notification
  void addInfoNotification(String title, String message, {Map<String, dynamic>? data}) {
    final notification = VerificationNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: VerificationNotificationType.info,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      data: data ?? {},
      autoHideDuration: const Duration(seconds: 5),
      icon: Icons.info,
      color: Colors.blue,
    );
    
    addNotification(notification);
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final updatedNotifications = state.notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    
    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
    
    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
      lastUpdated: DateTime.now(),
    );
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    final updatedNotifications = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    
    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: 0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Remove notification
  void removeNotification(String notificationId) {
    final updatedNotifications = state.notifications.where((n) => n.id != notificationId).toList();
    final updatedActiveNotifications = state.activeNotifications.where((n) => n.id != notificationId).toList();
    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
    
    state = state.copyWith(
      notifications: updatedNotifications,
      activeNotifications: updatedActiveNotifications,
      unreadCount: unreadCount,
      lastUpdated: DateTime.now(),
    );
  }

  /// Clear all notifications
  void clearAll() {
    state = VerificationNotificationState(lastUpdated: DateTime.now());
  }

  /// Clear notifications by type
  void clearByType(VerificationNotificationType type) {
    final updatedNotifications = state.notifications.where((n) => n.type != type).toList();
    final updatedActiveNotifications = state.activeNotifications.where((n) => n.type != type).toList();
    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
    
    state = state.copyWith(
      notifications: updatedNotifications,
      activeNotifications: updatedActiveNotifications,
      unreadCount: unreadCount,
      lastUpdated: DateTime.now(),
    );
  }

  /// Start auto-hide timer for notifications
  void _startAutoHideTimer() {
    // Check for expired notifications every 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _removeExpiredNotifications();
      _startAutoHideTimer();
    });
  }

  /// Remove expired notifications
  void _removeExpiredNotifications() {
    final now = DateTime.now();
    final activeNotifications = state.activeNotifications.where((n) {
      if (n.shouldAutoHide && n.timestamp.add(n.autoHideDuration!).isBefore(now)) {
        return false;
      }
      return true;
    }).toList();
    
    if (activeNotifications.length != state.activeNotifications.length) {
      state = state.copyWith(
        activeNotifications: activeNotifications,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Create notification from status change
  VerificationNotification? _createStatusChangeNotification(
    VerificationStatus oldStatus,
    VerificationStatus newStatus,
    DriverDocumentVerification verification,
  ) {
    String title;
    String message;
    VerificationNotificationType type;
    bool isPersistent = false;
    Duration? autoHideDuration = const Duration(seconds: 5);

    switch (newStatus) {
      case VerificationStatus.processing:
        title = 'Processing Started';
        message = 'Your documents are being verified using AI technology';
        type = VerificationNotificationType.processingStarted;
        break;
      case VerificationStatus.verified:
        title = 'Verification Complete';
        message = 'Your documents have been successfully verified!';
        type = VerificationNotificationType.verificationSuccess;
        isPersistent = true;
        autoHideDuration = null;
        break;
      case VerificationStatus.failed:
        title = 'Verification Failed';
        message = 'Some documents could not be verified. Please check and resubmit.';
        type = VerificationNotificationType.verificationFailed;
        isPersistent = true;
        autoHideDuration = null;
        break;
      case VerificationStatus.manualReview:
        title = 'Manual Review Required';
        message = 'Your documents are being reviewed by our team. This usually takes 1-2 business days.';
        type = VerificationNotificationType.manualReviewRequired;
        isPersistent = true;
        autoHideDuration = null;
        break;
      case VerificationStatus.expired:
        title = 'Documents Expired';
        message = 'Your documents have expired. Please upload new ones.';
        type = VerificationNotificationType.documentExpired;
        isPersistent = true;
        autoHideDuration = null;
        break;
      default:
        return null;
    }

    return VerificationNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      data: {
        'verification_id': verification.id,
        'old_status': oldStatus.name,
        'new_status': newStatus.name,
        'completion_percentage': verification.completionPercentage,
      },
      isPersistent: isPersistent,
      autoHideDuration: autoHideDuration,
    );
  }

  /// Create notification from document processing
  VerificationNotification? _createDocumentProcessingNotification(
    String documentType,
    String status,
    {String? documentSide, Map<String, dynamic>? data}
  ) {
    String title;
    String message;
    VerificationNotificationType type;

    final docName = _getDocumentDisplayName(documentType, documentSide);

    switch (status) {
      case 'uploaded':
        title = 'Document Uploaded';
        message = '$docName has been uploaded successfully';
        type = VerificationNotificationType.documentUploaded;
        break;
      case 'processing':
        title = 'Processing Document';
        message = '$docName is being processed...';
        type = VerificationNotificationType.processingStarted;
        break;
      case 'completed':
        title = 'Processing Complete';
        message = '$docName has been processed successfully';
        type = VerificationNotificationType.processingCompleted;
        break;
      case 'failed':
        title = 'Processing Failed';
        message = '$docName could not be processed. Please try again.';
        type = VerificationNotificationType.error;
        break;
      default:
        return null;
    }

    return VerificationNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      data: {
        'document_type': documentType,
        'document_side': documentSide,
        'status': status,
        ...?data,
      },
      autoHideDuration: const Duration(seconds: 4),
    );
  }

  /// Get display name for document type
  String _getDocumentDisplayName(String documentType, String? documentSide) {
    String baseName;
    switch (documentType) {
      case 'ic_card':
        baseName = 'Malaysian IC';
        break;
      case 'passport':
        baseName = 'Passport';
        break;
      case 'driver_license':
        baseName = 'Driver\'s License';
        break;
      case 'selfie':
        baseName = 'Selfie Photo';
        break;
      default:
        baseName = documentType.replaceAll('_', ' ').toUpperCase();
    }

    if (documentSide != null) {
      return '$baseName (${documentSide.toUpperCase()})';
    }
    return baseName;
  }
}

/// Provider for verification notification state
final verificationNotificationProvider = StateNotifierProvider<VerificationNotificationNotifier, VerificationNotificationState>((ref) {
  return VerificationNotificationNotifier();
});

/// Provider for active notifications (for UI display)
final activeVerificationNotificationsProvider = Provider<List<VerificationNotification>>((ref) {
  final notificationState = ref.watch(verificationNotificationProvider);
  return notificationState.activeNotifications;
});

/// Provider for unread notification count
final unreadVerificationNotificationCountProvider = Provider<int>((ref) {
  final notificationState = ref.watch(verificationNotificationProvider);
  return notificationState.unreadCount;
});
