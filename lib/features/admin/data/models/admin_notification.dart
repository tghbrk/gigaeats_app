import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_notification.freezed.dart';
part 'admin_notification.g.dart';

/// Admin notification model
@freezed
class AdminNotification with _$AdminNotification {
  const factory AdminNotification({
    required String id,
    required String title,
    required String message,
    required AdminNotificationType type,
    @Default(1) int priority,
    @Default(false) bool isRead,
    required String adminUserId,
    @Default({}) Map<String, dynamic> metadata,
    DateTime? expiresAt,
    required DateTime createdAt,

    // Extended fields
    String? actionUrl,
    String? actionLabel,
    String? category,
    @Default([]) List<String> tags,
  }) = _AdminNotification;

  factory AdminNotification.fromJson(Map<String, dynamic> json) {
    try {
      // Extract additional info from metadata if available
      String? actionUrl = json['action_url'] ?? json['actionUrl'];
      String? actionLabel = json['action_label'] ?? json['actionLabel'];
      String? category = json['category'];
      List<String> tags = json['tags'] is List
          ? List<String>.from(json['tags'])
          : <String>[];

      if (json['metadata'] is Map<String, dynamic>) {
        final metadata = json['metadata'] as Map<String, dynamic>;
        actionUrl ??= metadata['action_url'];
        actionLabel ??= metadata['action_label'];
        category ??= metadata['category'];
        if (metadata['tags'] is List) {
          tags = List<String>.from(metadata['tags']);
        }
      }

      return AdminNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        type: _notificationTypeFromJson(json['type']),
        priority: json['priority'] ?? 1,
        isRead: json['is_read'] ?? json['isRead'] ?? false,
        adminUserId: json['admin_user_id'] ?? json['adminUserId'] as String,
        metadata: json['metadata'] ?? <String, dynamic>{},
        expiresAt: json['expires_at'] is String
            ? DateTime.parse(json['expires_at'])
            : json['expires_at'] ?? json['expiresAt'],
        createdAt: json['created_at'] is String
            ? DateTime.parse(json['created_at'])
            : json['created_at'] ?? json['createdAt'] ?? DateTime.now(),
        actionUrl: actionUrl,
        actionLabel: actionLabel,
        category: category,
        tags: tags,
      );
    } catch (e) {
      throw FormatException('Failed to parse AdminNotification from JSON: $e');
    }
  }
}

/// Notification types
enum AdminNotificationType {
  info,
  warning,
  error,
  success;

  String get value => name;
  
  String get displayName {
    switch (this) {
      case AdminNotificationType.info:
        return 'Information';
      case AdminNotificationType.warning:
        return 'Warning';
      case AdminNotificationType.error:
        return 'Error';
      case AdminNotificationType.success:
        return 'Success';
    }
  }
}

// Helper functions for notification type serialization
AdminNotificationType _notificationTypeFromJson(dynamic value) {
  if (value is String) {
    return AdminNotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AdminNotificationType.info,
    );
  }
  return AdminNotificationType.info;
}



/// Notification filter options
@freezed
class NotificationFilter with _$NotificationFilter {
  const factory NotificationFilter({
    AdminNotificationType? type,
    int? minPriority,
    int? maxPriority,
    bool? isRead,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    @Default(50) int limit,
    @Default(0) int offset,
  }) = _NotificationFilter;

  factory NotificationFilter.fromJson(Map<String, dynamic> json) =>
      _$NotificationFilterFromJson(json);
}

/// Notification priority levels
class NotificationPriority {
  static const int low = 1;
  static const int medium = 2;
  static const int high = 3;
  static const int critical = 4;

  /// Get priority name
  static String getName(int priority) {
    switch (priority) {
      case low: return 'Low';
      case medium: return 'Medium';
      case high: return 'High';
      case critical: return 'Critical';
      default: return 'Unknown';
    }
  }

  /// Get all priority levels
  static List<int> get allPriorities => [low, medium, high, critical];
}

/// Notification categories
class NotificationCategory {
  static const String system = 'system';
  static const String user = 'user';
  static const String order = 'order';
  static const String vendor = 'vendor';
  static const String payment = 'payment';
  static const String security = 'security';
  static const String maintenance = 'maintenance';
  static const String report = 'report';

  /// Get all categories
  static List<String> get allCategories => [
    system, user, order, vendor, payment, security, maintenance, report,
  ];

  /// Get category display name
  static String getDisplayName(String category) {
    switch (category) {
      case system: return 'System';
      case user: return 'User Management';
      case order: return 'Orders';
      case vendor: return 'Vendors';
      case payment: return 'Payments';
      case security: return 'Security';
      case maintenance: return 'Maintenance';
      case report: return 'Reports';
      default: return category.replaceAll('_', ' ').split(' ')
          .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }
  }
}

/// Notification builder for creating notifications
class AdminNotificationBuilder {
  String? _title;
  String? _message;
  AdminNotificationType _type = AdminNotificationType.info;
  int _priority = NotificationPriority.medium;
  String? _adminUserId;
  Map<String, dynamic> _metadata = {};
  DateTime? _expiresAt;
  String? _actionUrl;
  String? _actionLabel;
  String? _category;
  List<String> _tags = [];

  AdminNotificationBuilder title(String title) {
    _title = title;
    return this;
  }

  AdminNotificationBuilder message(String message) {
    _message = message;
    return this;
  }

  AdminNotificationBuilder type(AdminNotificationType type) {
    _type = type;
    return this;
  }

  AdminNotificationBuilder priority(int priority) {
    _priority = priority;
    return this;
  }

  AdminNotificationBuilder adminUserId(String adminUserId) {
    _adminUserId = adminUserId;
    return this;
  }

  AdminNotificationBuilder metadata(Map<String, dynamic> metadata) {
    _metadata = metadata;
    return this;
  }

  AdminNotificationBuilder expiresAt(DateTime expiresAt) {
    _expiresAt = expiresAt;
    return this;
  }

  AdminNotificationBuilder actionUrl(String actionUrl) {
    _actionUrl = actionUrl;
    return this;
  }

  AdminNotificationBuilder actionLabel(String actionLabel) {
    _actionLabel = actionLabel;
    return this;
  }

  AdminNotificationBuilder category(String category) {
    _category = category;
    return this;
  }

  AdminNotificationBuilder tags(List<String> tags) {
    _tags = tags;
    return this;
  }

  AdminNotification build() {
    if (_title == null || _message == null || _adminUserId == null) {
      throw ArgumentError('Title, message, and adminUserId are required');
    }

    // Add action info to metadata
    if (_actionUrl != null) _metadata['action_url'] = _actionUrl;
    if (_actionLabel != null) _metadata['action_label'] = _actionLabel;
    if (_category != null) _metadata['category'] = _category;
    if (_tags.isNotEmpty) _metadata['tags'] = _tags;

    return AdminNotification(
      id: '', // Will be generated by database
      title: _title!,
      message: _message!,
      type: _type,
      priority: _priority,
      adminUserId: _adminUserId!,
      metadata: _metadata,
      expiresAt: _expiresAt,
      createdAt: DateTime.now(),
      actionUrl: _actionUrl,
      actionLabel: _actionLabel,
      category: _category,
      tags: _tags,
    );
  }
}
