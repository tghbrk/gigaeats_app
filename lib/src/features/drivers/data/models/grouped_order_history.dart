import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../orders/data/models/order.dart';

/// Model for representing orders grouped by date
@immutable
class GroupedOrderHistory {
  final String dateKey;
  final String displayDate;
  final DateTime date;
  final List<Order> orders;
  final int totalOrders;

  const GroupedOrderHistory({
    required this.dateKey,
    required this.displayDate,
    required this.date,
    required this.orders,
    required this.totalOrders,
  });

  /// Get delivered orders count
  int get deliveredOrders => orders.where((order) => order.status.value == 'delivered').length;

  /// Get cancelled orders count
  int get cancelledOrders => orders.where((order) => order.status.value == 'cancelled').length;

  /// Get total earnings from delivered orders
  double get totalEarnings => orders
      .where((order) => order.status.value == 'delivered')
      .fold(0.0, (sum, order) => sum + order.totalAmount);

  /// Check if this group is for today
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date == today;
  }

  /// Check if this group is for yesterday
  bool get isYesterday {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    return date == yesterday;
  }

  /// Get average order value for delivered orders
  double get averageOrderValue => deliveredOrders > 0 ? totalEarnings / deliveredOrders : 0.0;

  /// Get success rate (delivered / total)
  double get successRate => totalOrders > 0 ? deliveredOrders / totalOrders : 0.0;

  /// Create grouped order history from a list of orders
  static List<GroupedOrderHistory> fromOrders(List<Order> orders) {
    final grouped = <String, List<Order>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Group orders by date
    for (final order in orders) {
      // Use actual_delivery_time if available, otherwise fall back to created_at
      final orderDateTime = order.actualDeliveryTime ?? order.createdAt;
      final orderDate = DateTime(
        orderDateTime.year,
        orderDateTime.month,
        orderDateTime.day,
      );

      final dateKey = orderDate.toIso8601String().split('T')[0];
      grouped.putIfAbsent(dateKey, () => []).add(order);
    }

    // Convert to GroupedOrderHistory objects with proper display names
    final result = <GroupedOrderHistory>[];
    
    for (final entry in grouped.entries) {
      final dateKey = entry.key;
      final dayOrders = entry.value;
      final date = DateTime.parse(dateKey);
      
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

      result.add(GroupedOrderHistory(
        dateKey: dateKey,
        displayDate: displayDate,
        date: date,
        orders: dayOrders,
        totalOrders: dayOrders.length,
      ));
    }

    // Sort by date (most recent first)
    result.sort((a, b) => b.date.compareTo(a.date));
    
    return result;
  }

  /// Get orders for a specific date
  static List<Order> getOrdersForDate(List<Order> orders, DateTime targetDate) {
    final targetDateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    return orders.where((order) {
      final orderDateTime = order.actualDeliveryTime ?? order.createdAt;
      final orderDateOnly = DateTime(
        orderDateTime.year,
        orderDateTime.month,
        orderDateTime.day,
      );
      return orderDateOnly == targetDateOnly;
    }).toList();
  }



  /// Check if this is from current week
  bool get isCurrentWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return date.isAfter(weekStartDate.subtract(const Duration(days: 1)));
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

  /// Get summary statistics for a list of grouped orders
  static OrderHistorySummary getSummary(List<GroupedOrderHistory> groups) {
    final allOrders = groups.expand((group) => group.orders).toList();
    
    return OrderHistorySummary(
      totalOrders: allOrders.length,
      totalEarnings: allOrders.fold(0.0, (sum, order) => sum + order.totalAmount),
      deliveredOrders: allOrders.where((order) => order.status.value == 'delivered').length,
      cancelledOrders: allOrders.where((order) => order.status.value == 'cancelled').length,
      dateRange: groups.isEmpty 
          ? null 
          : DateRange(
              start: groups.last.date,
              end: groups.first.date,
            ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupedOrderHistory &&
          runtimeType == other.runtimeType &&
          dateKey == other.dateKey &&
          displayDate == other.displayDate &&
          date == other.date &&
          listEquals(orders, other.orders) &&
          totalOrders == other.totalOrders;

  @override
  int get hashCode =>
      dateKey.hashCode ^
      displayDate.hashCode ^
      date.hashCode ^
      orders.hashCode ^
      totalOrders.hashCode;

  @override
  String toString() {
    return 'GroupedOrderHistory(dateKey: $dateKey, displayDate: $displayDate, totalOrders: $totalOrders)';
  }
}

/// Summary statistics for order history
@immutable
class OrderHistorySummary {
  final int totalOrders;
  final double totalEarnings;
  final int deliveredOrders;
  final int cancelledOrders;
  final DateRange? dateRange;

  const OrderHistorySummary({
    required this.totalOrders,
    required this.totalEarnings,
    required this.deliveredOrders,
    required this.cancelledOrders,
    this.dateRange,
  });

  double get deliverySuccessRate {
    if (totalOrders == 0) return 0.0;
    return deliveredOrders / totalOrders;
  }

  double get averageEarningsPerOrder {
    if (totalOrders == 0) return 0.0;
    return totalEarnings / totalOrders;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderHistorySummary &&
          runtimeType == other.runtimeType &&
          totalOrders == other.totalOrders &&
          totalEarnings == other.totalEarnings &&
          deliveredOrders == other.deliveredOrders &&
          cancelledOrders == other.cancelledOrders &&
          dateRange == other.dateRange;

  @override
  int get hashCode =>
      totalOrders.hashCode ^
      totalEarnings.hashCode ^
      deliveredOrders.hashCode ^
      cancelledOrders.hashCode ^
      dateRange.hashCode;

  @override
  String toString() {
    return 'OrderHistorySummary(totalOrders: $totalOrders, totalEarnings: $totalEarnings, deliveredOrders: $deliveredOrders, cancelledOrders: $cancelledOrders)';
  }
}

/// Date range model
@immutable
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({
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
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;

  @override
  String toString() => 'DateRange(start: $start, end: $end)';
}
