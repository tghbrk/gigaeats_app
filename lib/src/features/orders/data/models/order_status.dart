/// Order status enumeration for GigaEats order management
enum OrderStatus {
  /// Order has been placed but not yet confirmed
  pending,
  
  /// Order has been confirmed by the vendor
  confirmed,
  
  /// Order is being prepared by the vendor
  preparing,
  
  /// Order is ready for pickup/delivery
  ready,
  
  /// Order is out for delivery
  outForDelivery,
  
  /// Order has been delivered successfully
  delivered,
  
  /// Order has been cancelled
  cancelled,
  
  /// Order has been refunded
  refunded;

  /// Get display name for the order status
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  /// Get color associated with the order status
  String get colorHex {
    switch (this) {
      case OrderStatus.pending:
        return '#FFA500'; // Orange
      case OrderStatus.confirmed:
        return '#2196F3'; // Blue
      case OrderStatus.preparing:
        return '#FF9800'; // Amber
      case OrderStatus.ready:
        return '#4CAF50'; // Green
      case OrderStatus.outForDelivery:
        return '#9C27B0'; // Purple
      case OrderStatus.delivered:
        return '#4CAF50'; // Green
      case OrderStatus.cancelled:
        return '#F44336'; // Red
      case OrderStatus.refunded:
        return '#607D8B'; // Blue Grey
    }
  }

  /// Check if the order status is active (not cancelled or delivered)
  bool get isActive {
    return this != OrderStatus.cancelled && 
           this != OrderStatus.delivered && 
           this != OrderStatus.refunded;
  }

  /// Check if the order can be cancelled
  bool get canBeCancelled {
    return this == OrderStatus.pending || 
           this == OrderStatus.confirmed;
  }

  /// Check if the order is in progress
  bool get isInProgress {
    return this == OrderStatus.confirmed || 
           this == OrderStatus.preparing || 
           this == OrderStatus.ready || 
           this == OrderStatus.outForDelivery;
  }

  /// Check if the order is completed
  bool get isCompleted {
    return this == OrderStatus.delivered || 
           this == OrderStatus.cancelled || 
           this == OrderStatus.refunded;
  }

  /// Get the next possible statuses from current status
  List<OrderStatus> get nextPossibleStatuses {
    switch (this) {
      case OrderStatus.pending:
        return [OrderStatus.confirmed, OrderStatus.cancelled];
      case OrderStatus.confirmed:
        return [OrderStatus.preparing, OrderStatus.cancelled];
      case OrderStatus.preparing:
        return [OrderStatus.ready, OrderStatus.cancelled];
      case OrderStatus.ready:
        return [OrderStatus.outForDelivery, OrderStatus.delivered];
      case OrderStatus.outForDelivery:
        return [OrderStatus.delivered];
      case OrderStatus.delivered:
        return [OrderStatus.refunded];
      case OrderStatus.cancelled:
        return [OrderStatus.refunded];
      case OrderStatus.refunded:
        return [];
    }
  }

  /// Create OrderStatus from string
  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'outfordelivery':
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
      default:
        throw ArgumentError('Unknown order status: $status');
    }
  }

  /// Convert to string for database storage
  String toDbString() {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.refunded:
        return 'refunded';
    }
  }
}
