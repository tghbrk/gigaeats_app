import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'assignment_history.g.dart';

/// Enum for assignment history actions
enum AssignmentHistoryAction {
  @JsonValue('requested')
  requested,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('expired')
  expired,
  @JsonValue('deactivated')
  deactivated,
  @JsonValue('reactivated')
  reactivated,
}

/// Enum for actor types
enum AssignmentActorType {
  @JsonValue('sales_agent')
  salesAgent,
  @JsonValue('customer')
  customer,
  @JsonValue('admin')
  admin,
}

/// Extension for AssignmentHistoryAction
extension AssignmentHistoryActionExtension on AssignmentHistoryAction {
  String get displayName {
    switch (this) {
      case AssignmentHistoryAction.requested:
        return 'Requested';
      case AssignmentHistoryAction.approved:
        return 'Approved';
      case AssignmentHistoryAction.rejected:
        return 'Rejected';
      case AssignmentHistoryAction.cancelled:
        return 'Cancelled';
      case AssignmentHistoryAction.expired:
        return 'Expired';
      case AssignmentHistoryAction.deactivated:
        return 'Deactivated';
      case AssignmentHistoryAction.reactivated:
        return 'Reactivated';
    }
  }

  String get pastTense {
    switch (this) {
      case AssignmentHistoryAction.requested:
        return 'requested assignment';
      case AssignmentHistoryAction.approved:
        return 'approved the request';
      case AssignmentHistoryAction.rejected:
        return 'rejected the request';
      case AssignmentHistoryAction.cancelled:
        return 'cancelled the request';
      case AssignmentHistoryAction.expired:
        return 'request expired';
      case AssignmentHistoryAction.deactivated:
        return 'deactivated assignment';
      case AssignmentHistoryAction.reactivated:
        return 'reactivated assignment';
    }
  }

  bool get isPositive => this == AssignmentHistoryAction.approved || 
                        this == AssignmentHistoryAction.reactivated;
  
  bool get isNegative => this == AssignmentHistoryAction.rejected || 
                        this == AssignmentHistoryAction.cancelled ||
                        this == AssignmentHistoryAction.expired ||
                        this == AssignmentHistoryAction.deactivated;
}

/// Extension for AssignmentActorType
extension AssignmentActorTypeExtension on AssignmentActorType {
  String get displayName {
    switch (this) {
      case AssignmentActorType.salesAgent:
        return 'Sales Agent';
      case AssignmentActorType.customer:
        return 'Customer';
      case AssignmentActorType.admin:
        return 'Admin';
    }
  }
}

/// Assignment history model for audit trail
@JsonSerializable()
class AssignmentHistory extends Equatable {
  final String id;
  @JsonKey(name: 'customer_id')
  final String customerId;
  @JsonKey(name: 'sales_agent_id')
  final String salesAgentId;
  @JsonKey(name: 'assignment_id')
  final String? assignmentId;
  final AssignmentHistoryAction action;
  @JsonKey(name: 'actor_id')
  final String actorId;
  @JsonKey(name: 'actor_type')
  final AssignmentActorType actorType;
  final String? details;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  // Related data (loaded separately)
  @JsonKey(name: 'customer_name')
  final String? customerName;
  @JsonKey(name: 'customer_organization')
  final String? customerOrganization;
  @JsonKey(name: 'sales_agent_name')
  final String? salesAgentName;
  @JsonKey(name: 'actor_name')
  final String? actorName;

  const AssignmentHistory({
    required this.id,
    required this.customerId,
    required this.salesAgentId,
    this.assignmentId,
    required this.action,
    required this.actorId,
    required this.actorType,
    this.details,
    this.metadata,
    required this.createdAt,
    this.customerName,
    this.customerOrganization,
    this.salesAgentName,
    this.actorName,
  });

  factory AssignmentHistory.fromJson(Map<String, dynamic> json) => 
      _$AssignmentHistoryFromJson(json);
  
  Map<String, dynamic> toJson() => _$AssignmentHistoryToJson(this);

  AssignmentHistory copyWith({
    String? id,
    String? customerId,
    String? salesAgentId,
    String? assignmentId,
    AssignmentHistoryAction? action,
    String? actorId,
    AssignmentActorType? actorType,
    String? details,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    String? customerName,
    String? customerOrganization,
    String? salesAgentName,
    String? actorName,
  }) {
    return AssignmentHistory(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      salesAgentId: salesAgentId ?? this.salesAgentId,
      assignmentId: assignmentId ?? this.assignmentId,
      action: action ?? this.action,
      actorId: actorId ?? this.actorId,
      actorType: actorType ?? this.actorType,
      details: details ?? this.details,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      customerOrganization: customerOrganization ?? this.customerOrganization,
      salesAgentName: salesAgentName ?? this.salesAgentName,
      actorName: actorName ?? this.actorName,
    );
  }

  /// Get formatted action description
  String get actionDescription {
    final actor = actorName ?? actorType.displayName;
    return '$actor ${action.pastTense}';
  }

  /// Get detailed description with context
  String get detailedDescription {
    final actor = actorName ?? actorType.displayName;
    final customer = customerName ?? 'Customer';
    final salesAgent = salesAgentName ?? 'Sales Agent';
    
    switch (action) {
      case AssignmentHistoryAction.requested:
        return '$salesAgent requested assignment to $customer';
      case AssignmentHistoryAction.approved:
        return '$customer approved assignment request from $salesAgent';
      case AssignmentHistoryAction.rejected:
        return '$customer rejected assignment request from $salesAgent';
      case AssignmentHistoryAction.cancelled:
        return '$salesAgent cancelled assignment request to $customer';
      case AssignmentHistoryAction.expired:
        return 'Assignment request from $salesAgent to $customer expired';
      case AssignmentHistoryAction.deactivated:
        return '$actor deactivated assignment between $salesAgent and $customer';
      case AssignmentHistoryAction.reactivated:
        return '$actor reactivated assignment between $salesAgent and $customer';
    }
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Check if this is a recent action (within 24 hours)
  bool get isRecent => DateTime.now().difference(createdAt).inHours <= 24;

  /// Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final actionDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    
    if (actionDate == today) {
      return 'Today';
    } else if (actionDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(createdAt).inDays < 7) {
      return timeAgo;
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Get formatted time
  String get formattedTime {
    final hour = createdAt.hour;
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Get formatted date and time
  String get formattedDateTime => '$formattedDate at $formattedTime';

  @override
  List<Object?> get props => [
        id,
        customerId,
        salesAgentId,
        assignmentId,
        action,
        actorId,
        actorType,
        details,
        metadata,
        createdAt,
        customerName,
        customerOrganization,
        salesAgentName,
        actorName,
      ];
}
