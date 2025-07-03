// Simple stub for order summary model
class OrderSummary {
  final String id;
  final String orderNumber;
  final double total;
  final double totalAmount;
  final int itemCount;
  final String status;
  final String? vendorName;
  final DateTime createdAt;

  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.total,
    required this.totalAmount,
    required this.itemCount,
    required this.status,
    this.vendorName,
    required this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final total = (json['total'] ?? 0).toDouble();
    return OrderSummary(
      id: json['id'] ?? '',
      orderNumber: json['order_number'] ?? json['id'] ?? '',
      total: total,
      totalAmount: total,
      itemCount: json['item_count'] ?? 0,
      status: json['status'] ?? '',
      vendorName: json['vendor_name'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'total': total,
      'item_count': itemCount,
      'status': status,
      'vendor_name': vendorName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
