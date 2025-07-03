import 'package:freezed_annotation/freezed_annotation.dart';
import 'support_category.dart';

part 'support_ticket.freezed.dart';
part 'support_ticket.g.dart';

/// Support ticket model
@freezed
class SupportTicket with _$SupportTicket {
  const factory SupportTicket({
    required String id,
    required String ticketNumber,
    required String customerId,
    String? categoryId,
    String? orderId,
    required String subject,
    required String description,
    @Default(TicketPriority.medium) TicketPriority priority,
    @Default(TicketStatus.open) TicketStatus status,
    String? assignedTo,
    DateTime? assignedAt,
    String? customerEmail,
    String? customerPhone,
    @Default({}) Map<String, dynamic> metadata,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? resolvedAt,
    DateTime? closedAt,
    
    // Related data
    SupportCategory? category,
    OrderInfo? order,
  }) = _SupportTicket;

  factory SupportTicket.fromJson(Map<String, dynamic> json) => _$SupportTicketFromJson(json);
}

/// Order information for support tickets
@freezed
class OrderInfo with _$OrderInfo {
  const factory OrderInfo({
    required String orderNumber,
    required String vendorName,
  }) = _OrderInfo;

  factory OrderInfo.fromJson(Map<String, dynamic> json) => _$OrderInfoFromJson(json);
}

/// Ticket priority levels
enum TicketPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

/// Ticket status values
enum TicketStatus {
  @JsonValue('open')
  open,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('waiting_customer')
  waitingCustomer,
  @JsonValue('resolved')
  resolved,
  @JsonValue('closed')
  closed,
}

/// Extensions for ticket priority
extension TicketPriorityExtension on TicketPriority {
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

  String get colorCode {
    switch (this) {
      case TicketPriority.low:
        return '#4CAF50'; // Green
      case TicketPriority.medium:
        return '#FF9800'; // Orange
      case TicketPriority.high:
        return '#F44336'; // Red
      case TicketPriority.urgent:
        return '#9C27B0'; // Purple
    }
  }
}

/// Extensions for ticket status
extension TicketStatusExtension on TicketStatus {
  String get displayName {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.waitingCustomer:
        return 'Waiting for Response';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }

  String get colorCode {
    switch (this) {
      case TicketStatus.open:
        return '#2196F3'; // Blue
      case TicketStatus.inProgress:
        return '#FF9800'; // Orange
      case TicketStatus.waitingCustomer:
        return '#9C27B0'; // Purple
      case TicketStatus.resolved:
        return '#4CAF50'; // Green
      case TicketStatus.closed:
        return '#757575'; // Grey
    }
  }

  bool get isActive {
    return this == TicketStatus.open || 
           this == TicketStatus.inProgress || 
           this == TicketStatus.waitingCustomer;
  }

  bool get isClosed {
    return this == TicketStatus.resolved || this == TicketStatus.closed;
  }
}
