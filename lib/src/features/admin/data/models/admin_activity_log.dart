import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_activity_log.freezed.dart';
part 'admin_activity_log.g.dart';

/// Admin activity log model for audit trail
@freezed
class AdminActivityLog with _$AdminActivityLog {
  const factory AdminActivityLog({
    required String id,
    required String adminUserId,
    required String actionType,
    required String targetType,
    String? targetId,
    @Default({}) Map<String, dynamic> details,
    String? ipAddress,
    String? userAgent,
    required DateTime createdAt,

    // Extended fields for better tracking
    String? adminName,
    String? adminEmail,
    String? targetName,
    String? description,
  }) = _AdminActivityLog;

  factory AdminActivityLog.fromJson(Map<String, dynamic> json) {
    try {
      // Extract additional info from details if available
      String? adminName = json['admin_name'] ?? json['adminName'];
      String? adminEmail = json['admin_email'] ?? json['adminEmail'];
      String? targetName = json['target_name'] ?? json['targetName'];
      String? description = json['description'];

      if (json['details'] is Map<String, dynamic>) {
        final details = json['details'] as Map<String, dynamic>;
        adminName ??= details['admin_name'];
        adminEmail ??= details['admin_email'];
        targetName ??= details['target_name'];
        description ??= details['description'];
      }

      return AdminActivityLog(
        id: json['id'] as String,
        adminUserId: json['admin_user_id'] ?? json['adminUserId'] as String,
        actionType: json['action_type'] ?? json['actionType'] as String,
        targetType: json['target_type'] ?? json['targetType'] as String,
        targetId: json['target_id'] ?? json['targetId'],
        details: json['details'] ?? <String, dynamic>{},
        ipAddress: json['ip_address'] ?? json['ipAddress'],
        userAgent: json['user_agent'] ?? json['userAgent'],
        createdAt: json['created_at'] is String
            ? DateTime.parse(json['created_at'])
            : json['created_at'] ?? json['createdAt'] ?? DateTime.now(),
        adminName: adminName,
        adminEmail: adminEmail,
        targetName: targetName,
        description: description,
      );
    } catch (e) {
      throw FormatException('Failed to parse AdminActivityLog from JSON: $e');
    }
  }
}

/// Activity log filter options
@freezed
class ActivityLogFilter with _$ActivityLogFilter {
  const factory ActivityLogFilter({
    String? actionType,
    String? targetType,
    String? adminUserId,
    DateTime? startDate,
    DateTime? endDate,
    @Default(50) int limit,
    @Default(0) int offset,
  }) = _ActivityLogFilter;

  factory ActivityLogFilter.fromJson(Map<String, dynamic> json) =>
      _$ActivityLogFilterFromJson(json);
}

/// Predefined action types for consistency
class AdminActionType {
  static const String userCreated = 'user_created';
  static const String userUpdated = 'user_updated';
  static const String userActivated = 'user_activated';
  static const String userDeactivated = 'user_deactivated';
  static const String userDeleted = 'user_deleted';
  
  static const String vendorApproved = 'vendor_approved';
  static const String vendorRejected = 'vendor_rejected';
  static const String vendorSuspended = 'vendor_suspended';
  static const String vendorReactivated = 'vendor_reactivated';
  
  static const String orderCancelled = 'order_cancelled';
  static const String orderRefunded = 'order_refunded';
  static const String orderStatusChanged = 'order_status_changed';
  
  static const String systemSettingUpdated = 'system_setting_updated';
  static const String systemMaintenanceEnabled = 'system_maintenance_enabled';
  static const String systemMaintenanceDisabled = 'system_maintenance_disabled';
  
  static const String ticketCreated = 'ticket_created';
  static const String ticketAssigned = 'ticket_assigned';
  static const String ticketResolved = 'ticket_resolved';
  static const String ticketClosed = 'ticket_closed';
  
  static const String notificationSent = 'notification_sent';
  static const String bulkOperation = 'bulk_operation';
  static const String dataExported = 'data_exported';
  static const String reportGenerated = 'report_generated';
  
  static const String loginAttempt = 'login_attempt';
  static const String loginSuccess = 'login_success';
  static const String loginFailure = 'login_failure';
  static const String logout = 'logout';
  
  static const String permissionGranted = 'permission_granted';
  static const String permissionRevoked = 'permission_revoked';
  static const String roleChanged = 'role_changed';

  /// Get all available action types
  static List<String> get allActionTypes => [
    userCreated, userUpdated, userActivated, userDeactivated, userDeleted,
    vendorApproved, vendorRejected, vendorSuspended, vendorReactivated,
    orderCancelled, orderRefunded, orderStatusChanged,
    systemSettingUpdated, systemMaintenanceEnabled, systemMaintenanceDisabled,
    ticketCreated, ticketAssigned, ticketResolved, ticketClosed,
    notificationSent, bulkOperation, dataExported, reportGenerated,
    loginAttempt, loginSuccess, loginFailure, logout,
    permissionGranted, permissionRevoked, roleChanged,
  ];

  /// Get human-readable description for action type
  static String getDescription(String actionType) {
    switch (actionType) {
      case userCreated: return 'User Created';
      case userUpdated: return 'User Updated';
      case userActivated: return 'User Activated';
      case userDeactivated: return 'User Deactivated';
      case userDeleted: return 'User Deleted';
      
      case vendorApproved: return 'Vendor Approved';
      case vendorRejected: return 'Vendor Rejected';
      case vendorSuspended: return 'Vendor Suspended';
      case vendorReactivated: return 'Vendor Reactivated';
      
      case orderCancelled: return 'Order Cancelled';
      case orderRefunded: return 'Order Refunded';
      case orderStatusChanged: return 'Order Status Changed';
      
      case systemSettingUpdated: return 'System Setting Updated';
      case systemMaintenanceEnabled: return 'Maintenance Mode Enabled';
      case systemMaintenanceDisabled: return 'Maintenance Mode Disabled';
      
      case ticketCreated: return 'Support Ticket Created';
      case ticketAssigned: return 'Ticket Assigned';
      case ticketResolved: return 'Ticket Resolved';
      case ticketClosed: return 'Ticket Closed';
      
      case notificationSent: return 'Notification Sent';
      case bulkOperation: return 'Bulk Operation';
      case dataExported: return 'Data Exported';
      case reportGenerated: return 'Report Generated';
      
      case loginAttempt: return 'Login Attempt';
      case loginSuccess: return 'Login Success';
      case loginFailure: return 'Login Failure';
      case logout: return 'Logout';
      
      case permissionGranted: return 'Permission Granted';
      case permissionRevoked: return 'Permission Revoked';
      case roleChanged: return 'Role Changed';
      
      default: return actionType.replaceAll('_', ' ').split(' ')
          .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }
  }
}

/// Target types for activity logs
class AdminTargetType {
  static const String user = 'user';
  static const String vendor = 'vendor';
  static const String customer = 'customer';
  static const String order = 'order';
  static const String system = 'system';
  static const String ticket = 'support_ticket';
  static const String notification = 'notification';
  static const String report = 'report';
  static const String setting = 'setting';

  /// Get all available target types
  static List<String> get allTargetTypes => [
    user, vendor, customer, order, system, ticket, notification, report, setting,
  ];

  /// Get human-readable description for target type
  static String getDescription(String targetType) {
    switch (targetType) {
      case user: return 'User';
      case vendor: return 'Vendor';
      case customer: return 'Customer';
      case order: return 'Order';
      case system: return 'System';
      case ticket: return 'Support Ticket';
      case notification: return 'Notification';
      case report: return 'Report';
      case setting: return 'Setting';
      default: return targetType.replaceAll('_', ' ').split(' ')
          .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }
  }
}
