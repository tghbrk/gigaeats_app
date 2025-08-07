import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../orders/data/models/order.dart';

/// Model for representing customer orders grouped by date with status-based organization
@immutable
class CustomerGroupedOrderHistory {
  final String dateKey;
  final String displayDate;
  final DateTime date;
  final List<Order> completedOrders;
  final List<Order> cancelledOrders;
  final int totalOrders;
  final int completedCount;
  final int cancelledCount;
  final double totalSpent;
  final double completedSpent;

  const CustomerGroupedOrderHistory({
    required this.dateKey,
    required this.displayDate,
    required this.date,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalOrders,
    required this.completedCount,
    required this.cancelledCount,
    required this.totalSpent,
    required this.completedSpent,
  });

  /// Get all orders (completed + cancelled) for this date
  List<Order> get allOrders => [...completedOrders, ...cancelledOrders];

  /// Check if this date has any orders
  bool get hasOrders => totalOrders > 0;

  /// Check if this date has completed orders
  bool get hasCompletedOrders => completedCount > 0;

  /// Check if this date has cancelled orders
  bool get hasCancelledOrders => cancelledCount > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerGroupedOrderHistory &&
          runtimeType == other.runtimeType &&
          dateKey == other.dateKey &&
          displayDate == other.displayDate &&
          date == other.date &&
          listEquals(completedOrders, other.completedOrders) &&
          listEquals(cancelledOrders, other.cancelledOrders);

  @override
  int get hashCode => Object.hash(
        dateKey,
        displayDate,
        date,
        Object.hashAll(completedOrders),
        Object.hashAll(cancelledOrders),
      );

  @override
  String toString() => 'CustomerGroupedOrderHistory('
      'dateKey: $dateKey, '
      'displayDate: $displayDate, '
      'totalOrders: $totalOrders, '
      'completedCount: $completedCount, '
      'cancelledCount: $cancelledCount'
      ')';

  /// Create grouped customer order history from a list of orders
  static List<CustomerGroupedOrderHistory> fromOrders(List<Order> orders) {
    final grouped = <String, List<Order>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    debugPrint('🛒 CustomerGroupedOrderHistory: Processing ${orders.length} orders for grouping');

    // Group orders by date
    for (final order in orders) {
      // Use actual_delivery_time for completed orders, created_at for cancelled orders
      final orderDateTime = order.status == OrderStatus.delivered
          ? (order.actualDeliveryTime ?? order.createdAt)
          : order.createdAt;
      
      final orderDate = DateTime(
        orderDateTime.year,
        orderDateTime.month,
        orderDateTime.day,
      );

      final dateKey = orderDate.toIso8601String().split('T')[0];
      grouped.putIfAbsent(dateKey, () => []).add(order);
    }

    debugPrint('🛒 CustomerGroupedOrderHistory: Grouped into ${grouped.length} date groups');

    final result = <CustomerGroupedOrderHistory>[];
    
    for (final entry in grouped.entries) {
      final dateKey = entry.key;
      final dayOrders = entry.value;
      final date = DateTime.parse(dateKey);
      
      // Separate orders by status
      final completedOrders = dayOrders
          .where((order) => order.status == OrderStatus.delivered)
          .toList();
      final cancelledOrders = dayOrders
          .where((order) => order.status == OrderStatus.cancelled)
          .toList();

      // Calculate spending totals
      final totalSpent = dayOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
      final completedSpent = completedOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
      
      // Generate display date
      String displayDate;
      if (date == today) {
        displayDate = 'Today';
      } else if (date == yesterday) {
        displayDate = 'Yesterday';
      } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
        // Show day name for recent dates (e.g., "Monday", "Tuesday")
        displayDate = DateFormat('EEEE').format(date);
      } else if (date.year == now.year) {
        // Show month and day for current year (e.g., "Jan 15")
        displayDate = DateFormat('MMM dd').format(date);
      } else {
        // Show full date for older dates (e.g., "Jan 15, 2024")
        displayDate = DateFormat('MMM dd, yyyy').format(date);
      }

      result.add(CustomerGroupedOrderHistory(
        dateKey: dateKey,
        displayDate: displayDate,
        date: date,
        completedOrders: completedOrders,
        cancelledOrders: cancelledOrders,
        totalOrders: dayOrders.length,
        completedCount: completedOrders.length,
        cancelledCount: cancelledOrders.length,
        totalSpent: totalSpent,
        completedSpent: completedSpent,
      ));

      debugPrint('🛒 CustomerGroupedOrderHistory: $displayDate - ${dayOrders.length} orders '
          '(${completedOrders.length} completed, ${cancelledOrders.length} cancelled)');
    }

    // Sort by date (most recent first)
    result.sort((a, b) => b.date.compareTo(a.date));
    
    debugPrint('🛒 CustomerGroupedOrderHistory: Created ${result.length} grouped entries');
    return result;
  }

  /// Get orders for a specific date and status
  static List<Order> getOrdersForDate(
    List<Order> orders, 
    DateTime targetDate, {
    OrderStatus? status,
  }) {
    final targetDateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    return orders.where((order) {
      // Use appropriate date field based on order status
      final orderDateTime = order.status == OrderStatus.delivered
          ? (order.actualDeliveryTime ?? order.createdAt)
          : order.createdAt;
      
      final orderDateOnly = DateTime(
        orderDateTime.year,
        orderDateTime.month,
        orderDateTime.day,
      );
      
      final dateMatches = orderDateOnly == targetDateOnly;
      final statusMatches = status == null || order.status == status;
      
      return dateMatches && statusMatches;
    }).toList();
  }

  /// Get formatted date range for display (e.g., "Jan 15 - Jan 21")
  static String getDateRangeDisplay(DateTime startDate, DateTime endDate) {
    final now = DateTime.now();
    
    if (startDate.year == endDate.year && startDate.year == now.year) {
      if (startDate.month == endDate.month) {
        // Same month and year: "Jan 15 - 21"
        return '${DateFormat('MMM dd').format(startDate)} - ${endDate.day}';
      } else {
        // Different months, same year: "Jan 15 - Feb 21"
        return '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd').format(endDate)}';
      }
    } else {
      // Different years: "Jan 15, 2023 - Feb 21, 2024"
      return '${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}';
    }
  }

  /// Get summary statistics for a list of grouped customer orders
  static CustomerOrderHistorySummary getSummary(List<CustomerGroupedOrderHistory> groups) {
    final allOrders = groups.expand((group) => group.allOrders).toList();
    final completedOrders = groups.expand((group) => group.completedOrders).toList();
    final cancelledOrders = groups.expand((group) => group.cancelledOrders).toList();
    
    return CustomerOrderHistorySummary(
      totalOrders: allOrders.length,
      completedOrders: completedOrders.length,
      cancelledOrders: cancelledOrders.length,
      totalSpent: allOrders.fold(0.0, (sum, order) => sum + order.totalAmount),
      completedSpent: completedOrders.fold(0.0, (sum, order) => sum + order.totalAmount),
      averageOrderValue: allOrders.isEmpty 
          ? 0.0 
          : allOrders.fold(0.0, (sum, order) => sum + order.totalAmount) / allOrders.length,
      dateRange: groups.isEmpty 
          ? null 
          : CustomerDateRange(
              start: groups.last.date,
              end: groups.first.date,
            ),
    );
  }
}

/// Summary statistics for customer order history
@immutable
class CustomerOrderHistorySummary {
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalSpent;
  final double completedSpent;
  final double averageOrderValue;
  final CustomerDateRange? dateRange;

  const CustomerOrderHistorySummary({
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalSpent,
    required this.completedSpent,
    required this.averageOrderValue,
    this.dateRange,
  });

  /// Get cancellation rate as percentage
  double get cancellationRate => totalOrders == 0 ? 0.0 : (cancelledOrders / totalOrders) * 100;

  /// Get completion rate as percentage
  double get completionRate => totalOrders == 0 ? 0.0 : (completedOrders / totalOrders) * 100;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerOrderHistorySummary &&
          runtimeType == other.runtimeType &&
          totalOrders == other.totalOrders &&
          completedOrders == other.completedOrders &&
          cancelledOrders == other.cancelledOrders &&
          totalSpent == other.totalSpent &&
          completedSpent == other.completedSpent &&
          averageOrderValue == other.averageOrderValue &&
          dateRange == other.dateRange;

  @override
  int get hashCode => Object.hash(
        totalOrders,
        completedOrders,
        cancelledOrders,
        totalSpent,
        completedSpent,
        averageOrderValue,
        dateRange,
      );

  @override
  String toString() => 'CustomerOrderHistorySummary('
      'totalOrders: $totalOrders, '
      'completedOrders: $completedOrders, '
      'cancelledOrders: $cancelledOrders, '
      'totalSpent: RM${totalSpent.toStringAsFixed(2)}, '
      'averageOrderValue: RM${averageOrderValue.toStringAsFixed(2)}'
      ')';
}

/// Date range model for customer orders
@immutable
class CustomerDateRange {
  final DateTime start;
  final DateTime end;

  const CustomerDateRange({
    required this.start,
    required this.end,
  });

  Duration get duration => end.difference(start);

  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(days: 1))) && 
           date.isBefore(end.add(const Duration(days: 1)));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerDateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;

  @override
  String toString() => 'CustomerDateRange(start: $start, end: $end)';
}
