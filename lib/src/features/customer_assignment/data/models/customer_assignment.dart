import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'customer_assignment.g.dart';

/// Customer assignment model representing an active assignment between customer and sales agent
@JsonSerializable()
class CustomerAssignment extends Equatable {
  final String id;
  @JsonKey(name: 'customer_id')
  final String customerId;
  @JsonKey(name: 'sales_agent_id')
  final String salesAgentId;
  @JsonKey(name: 'assignment_request_id')
  final String assignmentRequestId;
  @JsonKey(name: 'assigned_at')
  final DateTime assignedAt;
  @JsonKey(name: 'commission_rate')
  final double commissionRate;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'deactivated_at')
  final DateTime? deactivatedAt;
  @JsonKey(name: 'deactivated_by')
  final String? deactivatedBy;
  @JsonKey(name: 'deactivation_reason')
  final String? deactivationReason;
  @JsonKey(name: 'total_orders')
  final int totalOrders;
  @JsonKey(name: 'total_commission_earned')
  final double totalCommissionEarned;
  @JsonKey(name: 'last_order_date')
  final DateTime? lastOrderDate;
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
  @JsonKey(name: 'customer_phone')
  final String? customerPhone;
  @JsonKey(name: 'sales_agent_name')
  final String? salesAgentName;
  @JsonKey(name: 'sales_agent_email')
  final String? salesAgentEmail;
  @JsonKey(name: 'sales_agent_phone')
  final String? salesAgentPhone;

  const CustomerAssignment({
    required this.id,
    required this.customerId,
    required this.salesAgentId,
    required this.assignmentRequestId,
    required this.assignedAt,
    required this.commissionRate,
    required this.isActive,
    this.deactivatedAt,
    this.deactivatedBy,
    this.deactivationReason,
    this.totalOrders = 0,
    this.totalCommissionEarned = 0.0,
    this.lastOrderDate,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.customerName,
    this.customerEmail,
    this.customerOrganization,
    this.customerPhone,
    this.salesAgentName,
    this.salesAgentEmail,
    this.salesAgentPhone,
  });

  factory CustomerAssignment.fromJson(Map<String, dynamic> json) => 
      _$CustomerAssignmentFromJson(json);
  
  Map<String, dynamic> toJson() => _$CustomerAssignmentToJson(this);

  CustomerAssignment copyWith({
    String? id,
    String? customerId,
    String? salesAgentId,
    String? assignmentRequestId,
    DateTime? assignedAt,
    double? commissionRate,
    bool? isActive,
    DateTime? deactivatedAt,
    String? deactivatedBy,
    String? deactivationReason,
    int? totalOrders,
    double? totalCommissionEarned,
    DateTime? lastOrderDate,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerName,
    String? customerEmail,
    String? customerOrganization,
    String? customerPhone,
    String? salesAgentName,
    String? salesAgentEmail,
    String? salesAgentPhone,
  }) {
    return CustomerAssignment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      salesAgentId: salesAgentId ?? this.salesAgentId,
      assignmentRequestId: assignmentRequestId ?? this.assignmentRequestId,
      assignedAt: assignedAt ?? this.assignedAt,
      commissionRate: commissionRate ?? this.commissionRate,
      isActive: isActive ?? this.isActive,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      deactivatedBy: deactivatedBy ?? this.deactivatedBy,
      deactivationReason: deactivationReason ?? this.deactivationReason,
      totalOrders: totalOrders ?? this.totalOrders,
      totalCommissionEarned: totalCommissionEarned ?? this.totalCommissionEarned,
      lastOrderDate: lastOrderDate ?? this.lastOrderDate,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerOrganization: customerOrganization ?? this.customerOrganization,
      customerPhone: customerPhone ?? this.customerPhone,
      salesAgentName: salesAgentName ?? this.salesAgentName,
      salesAgentEmail: salesAgentEmail ?? this.salesAgentEmail,
      salesAgentPhone: salesAgentPhone ?? this.salesAgentPhone,
    );
  }

  /// Get commission rate as percentage
  double get commissionRatePercentage => commissionRate * 100;

  /// Get formatted commission rate
  String get formattedCommissionRate => '${commissionRatePercentage.toStringAsFixed(1)}%';

  /// Get average order value
  double get averageOrderValue {
    if (totalOrders == 0) return 0.0;
    return totalCommissionEarned / commissionRate / totalOrders;
  }

  /// Get formatted average order value
  String get formattedAverageOrderValue => 'RM ${averageOrderValue.toStringAsFixed(2)}';

  /// Get formatted total commission earned
  String get formattedTotalCommissionEarned => 'RM ${totalCommissionEarned.toStringAsFixed(2)}';

  /// Get assignment duration
  Duration get assignmentDuration {
    final endDate = deactivatedAt ?? DateTime.now();
    return endDate.difference(assignedAt);
  }

  /// Get assignment duration in days
  int get assignmentDurationDays => assignmentDuration.inDays;

  /// Get formatted assignment duration
  String get formattedAssignmentDuration {
    final days = assignmentDurationDays;
    if (days == 0) {
      return 'Today';
    } else if (days == 1) {
      return '1 day';
    } else if (days < 30) {
      return '$days days';
    } else if (days < 365) {
      final months = (days / 30).floor();
      return '$months month${months == 1 ? '' : 's'}';
    } else {
      final years = (days / 365).floor();
      return '$years year${years == 1 ? '' : 's'}';
    }
  }

  /// Check if assignment is recent (within 7 days)
  bool get isRecentAssignment => assignmentDurationDays <= 7;

  /// Check if customer has been active recently (ordered within 30 days)
  bool get isRecentlyActive {
    if (lastOrderDate == null) return false;
    return DateTime.now().difference(lastOrderDate!).inDays <= 30;
  }

  /// Get days since last order
  int? get daysSinceLastOrder {
    if (lastOrderDate == null) return null;
    return DateTime.now().difference(lastOrderDate!).inDays;
  }

  /// Get formatted last order date
  String get formattedLastOrderDate {
    if (lastOrderDate == null) return 'No orders yet';
    
    final days = daysSinceLastOrder!;
    if (days == 0) {
      return 'Today';
    } else if (days == 1) {
      return 'Yesterday';
    } else if (days < 7) {
      return '$days days ago';
    } else if (days < 30) {
      final weeks = (days / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (days < 365) {
      final months = (days / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (days / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }

  /// Get performance rating based on orders and commission
  String get performanceRating {
    if (totalOrders == 0) return 'New';
    
    final ordersPerMonth = totalOrders / (assignmentDurationDays / 30);
    if (ordersPerMonth >= 10) return 'Excellent';
    if (ordersPerMonth >= 5) return 'Good';
    if (ordersPerMonth >= 2) return 'Average';
    return 'Low';
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        salesAgentId,
        assignmentRequestId,
        assignedAt,
        commissionRate,
        isActive,
        deactivatedAt,
        deactivatedBy,
        deactivationReason,
        totalOrders,
        totalCommissionEarned,
        lastOrderDate,
        metadata,
        createdAt,
        updatedAt,
        customerName,
        customerEmail,
        customerOrganization,
        customerPhone,
        salesAgentName,
        salesAgentEmail,
        salesAgentPhone,
      ];
}
