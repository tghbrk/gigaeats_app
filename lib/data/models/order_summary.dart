import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'order_summary.g.dart';

/// A simplified order model for displaying basic order information
/// without the complexity of the full Order model
@JsonSerializable()
class OrderSummary extends Equatable {
  final String id;
  @JsonKey(name: 'order_number')
  final String orderNumber;
  final String status;
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @JsonKey(name: 'vendor_name')
  final String? vendorName;
  @JsonKey(name: 'customer_name')
  final String? customerName;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    this.vendorName,
    this.customerName,
    required this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) => _$OrderSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$OrderSummaryToJson(this);

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        status,
        totalAmount,
        vendorName,
        customerName,
        createdAt,
      ];

  @override
  String toString() {
    return 'OrderSummary(orderNumber: $orderNumber, status: $status, totalAmount: $totalAmount)';
  }
}
