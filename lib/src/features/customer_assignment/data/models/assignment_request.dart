import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'assignment_request.g.dart';

/// Enum for assignment request status
enum AssignmentRequestStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('expired')
  expired,
}

/// Enum for assignment request priority
enum AssignmentRequestPriority {
  @JsonValue('low')
  low,
  @JsonValue('normal')
  normal,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

/// Extension for AssignmentRequestStatus
extension AssignmentRequestStatusExtension on AssignmentRequestStatus {
  String get displayName {
    switch (this) {
      case AssignmentRequestStatus.pending:
        return 'Pending';
      case AssignmentRequestStatus.approved:
        return 'Approved';
      case AssignmentRequestStatus.rejected:
        return 'Rejected';
      case AssignmentRequestStatus.cancelled:
        return 'Cancelled';
      case AssignmentRequestStatus.expired:
        return 'Expired';
    }
  }

  bool get isPending => this == AssignmentRequestStatus.pending;
  bool get isApproved => this == AssignmentRequestStatus.approved;
  bool get isRejected => this == AssignmentRequestStatus.rejected;
  bool get isCancelled => this == AssignmentRequestStatus.cancelled;
  bool get isExpired => this == AssignmentRequestStatus.expired;
  bool get isActive => isPending;
  bool get isCompleted => isApproved || isRejected || isCancelled || isExpired;
}

/// Extension for AssignmentRequestPriority
extension AssignmentRequestPriorityExtension on AssignmentRequestPriority {
  String get displayName {
    switch (this) {
      case AssignmentRequestPriority.low:
        return 'Low';
      case AssignmentRequestPriority.normal:
        return 'Normal';
      case AssignmentRequestPriority.high:
        return 'High';
      case AssignmentRequestPriority.urgent:
        return 'Urgent';
    }
  }

  int get sortOrder {
    switch (this) {
      case AssignmentRequestPriority.urgent:
        return 4;
      case AssignmentRequestPriority.high:
        return 3;
      case AssignmentRequestPriority.normal:
        return 2;
      case AssignmentRequestPriority.low:
        return 1;
    }
  }
}

/// Customer assignment request model
@JsonSerializable()
class AssignmentRequest extends Equatable {
  final String id;
  @JsonKey(name: 'customer_id')
  final String customerId;
  @JsonKey(name: 'sales_agent_id')
  final String salesAgentId;
  final AssignmentRequestStatus status;
  final AssignmentRequestPriority priority;
  final String? message;
  @JsonKey(name: 'sales_agent_notes')
  final String? salesAgentNotes;
  @JsonKey(name: 'customer_response')
  final String? customerResponse;
  @JsonKey(name: 'customer_response_at')
  final DateTime? customerResponseAt;
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;
  @JsonKey(name: 'approved_at')
  final DateTime? approvedAt;
  @JsonKey(name: 'rejected_at')
  final DateTime? rejectedAt;
  @JsonKey(name: 'cancelled_at')
  final DateTime? cancelledAt;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Related data (loaded separately)
  @JsonKey(name: 'customer_name')
  final String? customerName;
  @JsonKey(name: 'customer_email')
  final String? customerEmail;
  @JsonKey(name: 'customer_organization')
  final String? customerOrganization;
  @JsonKey(name: 'sales_agent_name')
  final String? salesAgentName;
  @JsonKey(name: 'sales_agent_email')
  final String? salesAgentEmail;

  const AssignmentRequest({
    required this.id,
    required this.customerId,
    required this.salesAgentId,
    required this.status,
    required this.priority,
    this.message,
    this.salesAgentNotes,
    this.customerResponse,
    this.customerResponseAt,
    required this.expiresAt,
    this.approvedAt,
    this.rejectedAt,
    this.cancelledAt,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.customerName,
    this.customerEmail,
    this.customerOrganization,
    this.salesAgentName,
    this.salesAgentEmail,
  });

  factory AssignmentRequest.fromJson(Map<String, dynamic> json) => 
      _$AssignmentRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$AssignmentRequestToJson(this);

  AssignmentRequest copyWith({
    String? id,
    String? customerId,
    String? salesAgentId,
    AssignmentRequestStatus? status,
    AssignmentRequestPriority? priority,
    String? message,
    String? salesAgentNotes,
    String? customerResponse,
    DateTime? customerResponseAt,
    DateTime? expiresAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    DateTime? cancelledAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerName,
    String? customerEmail,
    String? customerOrganization,
    String? salesAgentName,
    String? salesAgentEmail,
  }) {
    return AssignmentRequest(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      salesAgentId: salesAgentId ?? this.salesAgentId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      message: message ?? this.message,
      salesAgentNotes: salesAgentNotes ?? this.salesAgentNotes,
      customerResponse: customerResponse ?? this.customerResponse,
      customerResponseAt: customerResponseAt ?? this.customerResponseAt,
      expiresAt: expiresAt ?? this.expiresAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerOrganization: customerOrganization ?? this.customerOrganization,
      salesAgentName: salesAgentName ?? this.salesAgentName,
      salesAgentEmail: salesAgentEmail ?? this.salesAgentEmail,
    );
  }

  /// Check if the request is expired
  bool get isExpiredNow => DateTime.now().isAfter(expiresAt);

  /// Get time remaining until expiry
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  /// Get days until expiry
  int get daysUntilExpiry => timeUntilExpiry.inDays;

  /// Get hours until expiry
  int get hoursUntilExpiry => timeUntilExpiry.inHours;

  /// Check if request expires soon (within 24 hours)
  bool get expiresSoon => timeUntilExpiry.inHours <= 24 && timeUntilExpiry.inHours > 0;

  /// Get formatted expiry time
  String get formattedExpiryTime {
    if (isExpiredNow) return 'Expired';
    
    final duration = timeUntilExpiry;
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'} remaining';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'} remaining';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'} remaining';
    } else {
      return 'Expires soon';
    }
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        salesAgentId,
        status,
        priority,
        message,
        salesAgentNotes,
        customerResponse,
        customerResponseAt,
        expiresAt,
        approvedAt,
        rejectedAt,
        cancelledAt,
        metadata,
        createdAt,
        updatedAt,
        customerName,
        customerEmail,
        customerOrganization,
        salesAgentName,
        salesAgentEmail,
      ];
}
