import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/admin_repository.dart';
import '../../data/models/admin_notification.dart';
import '../../data/models/support_ticket.dart';
import 'admin_providers.dart';

// ============================================================================
// ADMIN OPERATIONS STATE
// ============================================================================

/// Admin operations state for managing async operations
class AdminOperationsState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, bool> operationStates;

  const AdminOperationsState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.operationStates = const {},
  });

  AdminOperationsState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    Map<String, bool>? operationStates,
  }) {
    return AdminOperationsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      operationStates: operationStates ?? this.operationStates,
    );
  }

  /// Check if a specific operation is loading
  bool isOperationLoading(String operationKey) {
    return operationStates[operationKey] ?? false;
  }
}

/// Admin operations notifier
class AdminOperationsNotifier extends StateNotifier<AdminOperationsState> {
  final AdminRepository _repository;
  final Ref _ref;

  AdminOperationsNotifier(this._repository, this._ref) : super(const AdminOperationsState());

  /// Set operation loading state
  void _setOperationLoading(String operationKey, bool isLoading) {
    final newOperationStates = Map<String, bool>.from(state.operationStates);
    newOperationStates[operationKey] = isLoading;
    state = state.copyWith(operationStates: newOperationStates);
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  // ============================================================================
  // NOTIFICATION OPERATIONS
  // ============================================================================

  /// Create admin notification
  Future<void> createNotification(AdminNotification notification) async {
    const operationKey = 'create_notification';
    _setOperationLoading(operationKey, true);
    
    try {
      await _repository.createNotification(notification);
      state = state.copyWith(
        successMessage: 'Notification created successfully',
        errorMessage: null,
      );
      _setOperationLoading(operationKey, false);
    } catch (e) {
      debugPrint('🔍 AdminOperationsNotifier: Error creating notification: $e');
      state = state.copyWith(
        errorMessage: 'Failed to create notification: $e',
        successMessage: null,
      );
      _setOperationLoading(operationKey, false);
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    const operationKey = 'mark_notification_read';
    _setOperationLoading(operationKey, true);
    
    try {
      await _repository.markNotificationAsRead(notificationId);
      _setOperationLoading(operationKey, false);
    } catch (e) {
      debugPrint('🔍 AdminOperationsNotifier: Error marking notification as read: $e');
      state = state.copyWith(errorMessage: 'Failed to mark notification as read: $e');
      _setOperationLoading(operationKey, false);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    const operationKey = 'mark_all_notifications_read';
    _setOperationLoading(operationKey, true);
    
    try {
      await _repository.markAllNotificationsAsRead();
      state = state.copyWith(
        successMessage: 'All notifications marked as read',
        errorMessage: null,
      );
      _setOperationLoading(operationKey, false);
    } catch (e) {
      debugPrint('🔍 AdminOperationsNotifier: Error marking all notifications as read: $e');
      state = state.copyWith(
        errorMessage: 'Failed to mark all notifications as read: $e',
        successMessage: null,
      );
      _setOperationLoading(operationKey, false);
    }
  }

  // ============================================================================
  // SUPPORT TICKET OPERATIONS
  // ============================================================================

  /// Create support ticket
  Future<void> createSupportTicket({
    required String subject,
    required String description,
    String category = 'general',
    String priority = 'medium',
  }) async {
    const operationKey = 'create_ticket';
    _setOperationLoading(operationKey, true);
    
    try {
      await _repository.createSupportTicket(
        subject: subject,
        description: description,
        category: category,
        priority: priority,
      );
      state = state.copyWith(
        successMessage: 'Support ticket created successfully',
        errorMessage: null,
      );
      _setOperationLoading(operationKey, false);
    } catch (e) {
      debugPrint('🔍 AdminOperationsNotifier: Error creating support ticket: $e');
      state = state.copyWith(
        errorMessage: 'Failed to create support ticket: $e',
        successMessage: null,
      );
      _setOperationLoading(operationKey, false);
    }
  }

  /// Assign ticket to admin
  Future<void> assignTicket(String ticketId, String adminId, {String? reason}) async {
    const operationKey = 'assign_ticket';
    _setOperationLoading(operationKey, true);
    
    try {
      await _repository.assignTicket(ticketId, adminId, reason: reason);
      state = state.copyWith(
        successMessage: 'Ticket assigned successfully',
        errorMessage: null,
      );
      _setOperationLoading(operationKey, false);
    } catch (e) {
      debugPrint('🔍 AdminOperationsNotifier: Error assigning ticket: $e');
      state = state.copyWith(
        errorMessage: 'Failed to assign ticket: $e',
        successMessage: null,
      );
      _setOperationLoading(operationKey, false);
    }
  }

  /// Update ticket status
  Future<void> updateTicketStatus(String ticketId, TicketStatus newStatus, {String? notes}) async {
    const operationKey = 'update_ticket_status';
    _setOperationLoading(operationKey, true);
    
    try {
      await _repository.updateTicketStatus(ticketId, newStatus, notes: notes);
      state = state.copyWith(
        successMessage: 'Ticket status updated successfully',
        errorMessage: null,
      );
      _setOperationLoading(operationKey, false);
    } catch (e) {
      debugPrint('🔍 AdminOperationsNotifier: Error updating ticket status: $e');
      state = state.copyWith(
        errorMessage: 'Failed to update ticket status: $e',
        successMessage: null,
      );
      _setOperationLoading(operationKey, false);
    }
  }

  // ============================================================================
  // SYSTEM SETTINGS OPERATIONS
  // ============================================================================

  /// Update system setting
  Future<void> updateSystemSetting(String settingKey, dynamic settingValue, {String? reason}) async {
    const operationKey = 'update_setting';
    _setOperationLoading(operationKey, true);
    
    try {
      await _repository.updateSystemSetting(settingKey, settingValue, reason: reason);
      state = state.copyWith(
        successMessage: 'System setting updated successfully',
        errorMessage: null,
      );
      _setOperationLoading(operationKey, false);
    } catch (e) {
      debugPrint('🔍 AdminOperationsNotifier: Error updating system setting: $e');
      state = state.copyWith(
        errorMessage: 'Failed to update system setting: $e',
        successMessage: null,
      );
      _setOperationLoading(operationKey, false);
    }
  }

  /// Create system setting
  Future<void> createSystemSetting({
    required String settingKey,
    required dynamic settingValue,
    String? description,
    String category = 'general',
    bool isPublic = false,
  }) async {
    const operationKey = 'create_setting';
    _setOperationLoading(operationKey, true);
    
    try {
      await _repository.createSystemSetting(
        settingKey: settingKey,
        settingValue: settingValue,
        description: description,
        category: category,
        isPublic: isPublic,
      );
      state = state.copyWith(
        successMessage: 'System setting created successfully',
        errorMessage: null,
      );
      _setOperationLoading(operationKey, false);
    } catch (e) {
      debugPrint('🔍 AdminOperationsNotifier: Error creating system setting: $e');
      state = state.copyWith(
        errorMessage: 'Failed to create system setting: $e',
        successMessage: null,
      );
      _setOperationLoading(operationKey, false);
    }
  }

  /// Delete system setting
  Future<void> deleteSystemSetting(String settingKey, {String? reason}) async {
    const operationKey = 'delete_setting';
    _setOperationLoading(operationKey, true);
    
    try {
      await _repository.deleteSystemSetting(settingKey, reason: reason);
      state = state.copyWith(
        successMessage: 'System setting deleted successfully',
        errorMessage: null,
      );
      _setOperationLoading(operationKey, false);
    } catch (e) {
      debugPrint('🔍 AdminOperationsNotifier: Error deleting system setting: $e');
      state = state.copyWith(
        errorMessage: 'Failed to delete system setting: $e',
        successMessage: null,
      );
      _setOperationLoading(operationKey, false);
    }
  }

  // ============================================================================
  // BULK OPERATIONS
  // ============================================================================

  /// Bulk update user status
  Future<void> bulkUpdateUserStatus(List<String> userIds, bool isActive, {String? reason}) async {
    const operationKey = 'bulk_update_users';
    _setOperationLoading(operationKey, true);
    
    try {
      int successCount = 0;
      int errorCount = 0;
      
      for (final userId in userIds) {
        try {
          await _repository.updateUserStatus(userId, isActive, reason: reason);
          successCount++;
        } catch (e) {
          errorCount++;
          debugPrint('🔍 AdminOperationsNotifier: Error updating user $userId: $e');
        }
      }
      
      if (errorCount == 0) {
        state = state.copyWith(
          successMessage: 'Successfully updated $successCount users',
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          successMessage: 'Updated $successCount users, $errorCount failed',
          errorMessage: null,
        );
      }
      
      _setOperationLoading(operationKey, false);
      
      // Refresh user management data
      _ref.read(adminUserManagementProvider.notifier).loadUsers(refresh: true);
    } catch (e) {
      debugPrint('🔍 AdminOperationsNotifier: Error in bulk user update: $e');
      state = state.copyWith(
        errorMessage: 'Failed to update users: $e',
        successMessage: null,
      );
      _setOperationLoading(operationKey, false);
    }
  }

  /// Send notification to multiple admins
  Future<void> sendBulkNotification({
    required String title,
    required String message,
    required AdminNotificationType type,
    int priority = 2,
    List<String>? adminUserIds,
  }) async {
    const operationKey = 'bulk_notification';
    _setOperationLoading(operationKey, true);
    
    try {
      // If no specific admin IDs provided, send to current admin only
      final targetAdminIds = adminUserIds ?? [_repository.currentUserId!];
      
      int successCount = 0;
      int errorCount = 0;
      
      for (final adminId in targetAdminIds) {
        try {
          final notification = AdminNotification(
            id: '',
            title: title,
            message: message,
            type: type,
            priority: priority,
            adminUserId: adminId,
            createdAt: DateTime.now(),
          );
          
          await _repository.createNotification(notification);
          successCount++;
        } catch (e) {
          errorCount++;
          debugPrint('🔍 AdminOperationsNotifier: Error sending notification to $adminId: $e');
        }
      }
      
      if (errorCount == 0) {
        state = state.copyWith(
          successMessage: 'Successfully sent notification to $successCount admins',
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          successMessage: 'Sent to $successCount admins, $errorCount failed',
          errorMessage: null,
        );
      }
      
      _setOperationLoading(operationKey, false);
    } catch (e) {
      debugPrint('🔍 AdminOperationsNotifier: Error in bulk notification: $e');
      state = state.copyWith(
        errorMessage: 'Failed to send notifications: $e',
        successMessage: null,
      );
      _setOperationLoading(operationKey, false);
    }
  }
}

/// Admin operations provider
final adminOperationsProvider = StateNotifierProvider<AdminOperationsNotifier, AdminOperationsState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminOperationsNotifier(repository, ref);
});
