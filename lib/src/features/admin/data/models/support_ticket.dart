import 'package:freezed_annotation/freezed_annotation.dart';

part 'support_ticket.freezed.dart';
part 'support_ticket.g.dart';

/// Support ticket model
@freezed
class SupportTicket with _$SupportTicket {
  const factory SupportTicket({
    required String id,
    required String ticketNumber,
    String? userId,
    required String subject,
    required String description,
    @Default(TicketStatus.open) TicketStatus status,
    @Default(TicketPriority.medium) TicketPriority priority,
    @Default('general') String category,
    String? assignedAdminId,
    String? resolutionNotes,
    @Default([]) List<String> attachments,
    @Default({}) Map<String, dynamic> metadata,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? resolvedAt,

    // Extended fields for better management
    String? userEmail,
    String? userName,
    String? assignedAdminName,
    @Default(0) int messageCount,
    DateTime? lastMessageAt,
    String? lastMessageBy,
    @Default([]) List<String> tags,
    String? escalationLevel,
    DateTime? dueDate,
  }) = _SupportTicket;

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    try {
      // Extract additional info from metadata if available
      String? userEmail = json['user_email'] ?? json['userEmail'];
      String? userName = json['user_name'] ?? json['userName'];
      String? assignedAdminName = json['assigned_admin_name'] ?? json['assignedAdminName'];
      String? escalationLevel = json['escalation_level'] ?? json['escalationLevel'];
      List<String> tags = json['tags'] is List
          ? List<String>.from(json['tags'])
          : <String>[];

      if (json['metadata'] is Map<String, dynamic>) {
        final metadata = json['metadata'] as Map<String, dynamic>;
        userEmail ??= metadata['user_email'];
        userName ??= metadata['user_name'];
        assignedAdminName ??= metadata['assigned_admin_name'];
        escalationLevel ??= metadata['escalation_level'];
        if (metadata['tags'] is List) {
          tags = List<String>.from(metadata['tags']);
        }
      }

      return SupportTicket(
        id: json['id'] as String,
        ticketNumber: json['ticket_number'] ?? json['ticketNumber'] as String,
        userId: json['user_id'] ?? json['userId'],
        subject: json['subject'] as String,
        description: json['description'] as String,
        status: _ticketStatusFromJson(json['status']),
        priority: _ticketPriorityFromJson(json['priority']),
        category: json['category'] ?? 'general',
        assignedAdminId: json['assigned_admin_id'] ?? json['assignedAdminId'],
        resolutionNotes: json['resolution_notes'] ?? json['resolutionNotes'],
        attachments: json['attachments'] is List
            ? List<String>.from(json['attachments'])
            : <String>[],
        metadata: json['metadata'] ?? <String, dynamic>{},
        createdAt: json['created_at'] is String
            ? DateTime.parse(json['created_at'])
            : json['created_at'] ?? json['createdAt'] ?? DateTime.now(),
        updatedAt: json['updated_at'] is String
            ? DateTime.parse(json['updated_at'])
            : json['updated_at'] ?? json['updatedAt'] ?? DateTime.now(),
        resolvedAt: json['resolved_at'] is String
            ? DateTime.parse(json['resolved_at'])
            : json['resolved_at'] ?? json['resolvedAt'],
        userEmail: userEmail,
        userName: userName,
        assignedAdminName: assignedAdminName,
        messageCount: json['message_count'] ?? json['messageCount'] ?? 0,
        lastMessageAt: json['last_message_at'] is String
            ? DateTime.parse(json['last_message_at'])
            : json['last_message_at'] ?? json['lastMessageAt'],
        lastMessageBy: json['last_message_by'] ?? json['lastMessageBy'],
        tags: tags,
        escalationLevel: escalationLevel,
        dueDate: json['due_date'] is String
            ? DateTime.parse(json['due_date'])
            : json['due_date'] ?? json['dueDate'],
      );
    } catch (e) {
      throw FormatException('Failed to parse SupportTicket from JSON: $e');
    }
  }
}

/// Ticket status enum
enum TicketStatus {
  open,
  inProgress,
  resolved,
  closed;

  String get value => name.replaceAll(RegExp(r'([A-Z])'), '_\$1').toLowerCase().substring(1);
  
  String get displayName {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }
}

/// Ticket priority enum
enum TicketPriority {
  low,
  medium,
  high,
  urgent;

  String get value => name;
  
  String get displayName {
    switch (this) {
      case TicketPriority.low:
        return 'Low';
      case TicketPriority.medium:
        return 'Medium';
      case TicketPriority.high:
        return 'High';
      case TicketPriority.urgent:
        return 'Urgent';
    }
  }
}

// Helper functions for status serialization
TicketStatus _ticketStatusFromJson(dynamic value) {
  if (value is String) {
    switch (value) {
      case 'open': return TicketStatus.open;
      case 'in_progress': return TicketStatus.inProgress;
      case 'resolved': return TicketStatus.resolved;
      case 'closed': return TicketStatus.closed;
      default: return TicketStatus.open;
    }
  }
  return TicketStatus.open;
}

// Helper functions for priority serialization
TicketPriority _ticketPriorityFromJson(dynamic value) {
  if (value is String) {
    return TicketPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => TicketPriority.medium,
    );
  }
  return TicketPriority.medium;
}

/// Ticket filter options
@freezed
class TicketFilter with _$TicketFilter {
  const factory TicketFilter({
    TicketStatus? status,
    TicketPriority? priority,
    String? category,
    String? assignedAdminId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    @Default(50) int limit,
    @Default(0) int offset,
  }) = _TicketFilter;

  factory TicketFilter.fromJson(Map<String, dynamic> json) =>
      _$TicketFilterFromJson(json);
}

/// Ticket categories
class TicketCategory {
  static const String general = 'general';
  static const String payment = 'payment';
  static const String order = 'order';
  static const String technical = 'technical';
  static const String account = 'account';
  static const String vendor = 'vendor';
  static const String delivery = 'delivery';
  static const String refund = 'refund';
  static const String billing = 'billing';
  static const String feature = 'feature';
  static const String bug = 'bug';
  static const String complaint = 'complaint';

  /// Get all categories
  static List<String> get allCategories => [
    general, payment, order, technical, account, vendor, 
    delivery, refund, billing, feature, bug, complaint,
  ];

  /// Get category display name
  static String getDisplayName(String category) {
    switch (category) {
      case general: return 'General';
      case payment: return 'Payment';
      case order: return 'Order';
      case technical: return 'Technical';
      case account: return 'Account';
      case vendor: return 'Vendor';
      case delivery: return 'Delivery';
      case refund: return 'Refund';
      case billing: return 'Billing';
      case feature: return 'Feature Request';
      case bug: return 'Bug Report';
      case complaint: return 'Complaint';
      default: return category.replaceAll('_', ' ').split(' ')
          .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }
  }
}

/// Ticket statistics for admin dashboard
@freezed
class TicketStatistics with _$TicketStatistics {
  const factory TicketStatistics({
    @Default(0) int totalTickets,
    @Default(0) int openTickets,
    @Default(0) int inProgressTickets,
    @Default(0) int resolvedTickets,
    @Default(0) int closedTickets,
    @Default(0) int urgentTickets,
    @Default(0) int highPriorityTickets,
    @Default(0) int unassignedTickets,
    @Default(0) int overdueTickets,
    @Default(0.0) double averageResolutionTime,
    @Default(0.0) double customerSatisfactionScore,
  }) = _TicketStatistics;

  factory TicketStatistics.fromJson(Map<String, dynamic> json) =>
      _$TicketStatisticsFromJson(json);
}

/// Ticket assignment request
@freezed
class TicketAssignmentRequest with _$TicketAssignmentRequest {
  const factory TicketAssignmentRequest({
    required String ticketId,
    required String adminId,
    String? reason,
    String? notes,
  }) = _TicketAssignmentRequest;

  factory TicketAssignmentRequest.fromJson(Map<String, dynamic> json) =>
      _$TicketAssignmentRequestFromJson(json);
}

/// Ticket resolution request
@freezed
class TicketResolutionRequest with _$TicketResolutionRequest {
  const factory TicketResolutionRequest({
    required String ticketId,
    required String resolutionNotes,
    @Default(TicketStatus.resolved) TicketStatus newStatus,
    String? followUpRequired,
    @Default([]) List<String> tags,
  }) = _TicketResolutionRequest;

  factory TicketResolutionRequest.fromJson(Map<String, dynamic> json) =>
      _$TicketResolutionRequestFromJson(json);
}
