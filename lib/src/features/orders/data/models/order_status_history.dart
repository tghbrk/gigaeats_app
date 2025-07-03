import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'order_status.dart';

part 'order_status_history.g.dart';

@JsonSerializable()
class OrderStatusHistory extends Equatable {
  final String id;
  @JsonKey(name: 'order_id')
  final String orderId;
  @JsonKey(name: 'old_status', fromJson: _orderStatusFromJsonNullable, toJson: _orderStatusToJsonNullable)
  final OrderStatus? oldStatus;
  @JsonKey(name: 'new_status', fromJson: _orderStatusFromJson, toJson: _orderStatusToJson)
  final OrderStatus newStatus;
  @JsonKey(name: 'changed_by')
  final String? changedBy;
  final String? reason;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const OrderStatusHistory({
    required this.id,
    required this.orderId,
    this.oldStatus,
    required this.newStatus,
    this.changedBy,
    this.reason,
    this.notes,
    required this.createdAt,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) => 
      _$OrderStatusHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$OrderStatusHistoryToJson(this);

  OrderStatusHistory copyWith({
    String? id,
    String? orderId,
    OrderStatus? oldStatus,
    OrderStatus? newStatus,
    String? changedBy,
    String? reason,
    String? notes,
    DateTime? createdAt,
  }) {
    return OrderStatusHistory(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      oldStatus: oldStatus ?? this.oldStatus,
      newStatus: newStatus ?? this.newStatus,
      changedBy: changedBy ?? this.changedBy,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        oldStatus,
        newStatus,
        changedBy,
        reason,
        notes,
        createdAt,
      ];

  @override
  String toString() {
    return 'OrderStatusHistory(id: $id, orderId: $orderId, oldStatus: $oldStatus, newStatus: $newStatus)';
  }
}

// Helper functions for JSON serialization
OrderStatus? _orderStatusFromJsonNullable(String? value) {
  if (value == null) return null;
  return OrderStatus.fromString(value);
}

OrderStatus _orderStatusFromJson(String value) {
  return OrderStatus.fromString(value);
}

String? _orderStatusToJsonNullable(OrderStatus? status) {
  return status?.toDbString();
}

String _orderStatusToJson(OrderStatus status) {
  return status.toDbString();
}
