import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../orders/data/models/order.dart';

/// Model for representing vendor orders grouped by date
@immutable
class VendorGroupedOrderHistory {
  final String dateKey;
  final String displayDate;
  final DateTime date;
  final List<Order> orders;
  final int totalOrders;

  const VendorGroupedOrderHistory({
    required this.dateKey,
    required this.displayDate,
    required this.date,
    required this.orders,
    required this.totalOrders,
  });

  /// Get pending orders count
  int get pendingOrders => orders.where((order) => order.status.value == 'pending').length;

  /// Get confirmed orders count
  int get confirmedOrders => orders.where((order) => order.status.value == 'confirmed').length;

  /// Get preparing orders count
  int get preparingOrders => orders.where((order) => order.status.value == 'preparing').length;

  /// Get ready orders count
  int get readyOrders => orders.where((order) => order.status.value == 'ready').length;

  /// Get delivered orders count
  int get deliveredOrders => orders.where((order) => order.status.value == 'delivered').length;

  /// Get cancelled orders count
  int get cancelledOrders => orders.where((order) => order.status.value == 'cancelled').length;

  /// Get active orders count (pending, confirmed, preparing, ready)
  int get activeOrders => pendingOrders + confirmedOrders + preparingOrders + readyOrders;

  /// Get completed orders count (delivered + cancelled)
  int get completedOrders => deliveredOrders + cancelledOrders;

  /// Get total revenue from delivered orders
  double get totalRevenue => orders
      .where((order) => order.status.value == 'delivered')
      .fold(0.0, (sum, order) => sum + order.totalAmount);

  /// Get total commission from delivered orders
  double get totalCommission => orders
      .where((order) => order.status.value == 'delivered')
      .fold(0.0, (sum, order) => sum + (order.commissionAmount ?? 0.0));

  /// Get net earnings (revenue - commission)
  double get netEarnings => totalRevenue - totalCommission;

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
  double get averageOrderValue => deliveredOrders > 0 ? totalRevenue / deliveredOrders : 0.0;

  /// Get completion rate (delivered / total)
  double get completionRate => totalOrders > 0 ? deliveredOrders / totalOrders : 0.0;

  /// Get cancellation rate (cancelled / total)
  double get cancellationRate => totalOrders > 0 ? cancelledOrders / totalOrders : 0.0;

  /// Check if this is from current week
  bool get isCurrentWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return date.isAfter(weekStartDate.subtract(const Duration(days: 1)));
  }

  /// Create grouped order history from a list of orders
  static List<VendorGroupedOrderHistory> fromOrders(List<Order> orders) {
    final grouped = <String, List<Order>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Group orders by date
    for (final order in orders) {
      // Use created_at for vendor orders (when order was placed)
      final orderDateTime = order.createdAt;
      final orderDate = DateTime(
        orderDateTime.year,
        orderDateTime.month,
        orderDateTime.day,
      );

      final dateKey = orderDate.toIso8601String().split('T')[0];
      grouped.putIfAbsent(dateKey, () => []).add(order);
    }

    // Convert to VendorGroupedOrderHistory objects with proper display names
    final result = <VendorGroupedOrderHistory>[];
    
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

      result.add(VendorGroupedOrderHistory(
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
      final orderDateTime = order.createdAt;
      final orderDateOnly = DateTime(
        orderDateTime.year,
        orderDateTime.month,
        orderDateTime.day,
      );
      return orderDateOnly == targetDateOnly;
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
      // Different years or not current year: "Jan 15, 2023 - Feb 21, 2024"
      return '${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}';
    }
  }

  /// Get summary statistics for a list of grouped history
  static VendorOrderHistorySummary getSummary(List<VendorGroupedOrderHistory> groupedHistory) {
    final totalOrders = groupedHistory.fold(0, (sum, group) => sum + group.totalOrders);
    final totalRevenue = groupedHistory.fold(0.0, (sum, group) => sum + group.totalRevenue);
    final totalCommission = groupedHistory.fold(0.0, (sum, group) => sum + group.totalCommission);
    final totalDelivered = groupedHistory.fold(0, (sum, group) => sum + group.deliveredOrders);
    final totalCancelled = groupedHistory.fold(0, (sum, group) => sum + group.cancelledOrders);

    return VendorOrderHistorySummary(
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      totalCommission: totalCommission,
      netEarnings: totalRevenue - totalCommission,
      deliveredOrders: totalDelivered,
      cancelledOrders: totalCancelled,
      averageOrderValue: totalDelivered > 0 ? totalRevenue / totalDelivered : 0.0,
      completionRate: totalOrders > 0 ? totalDelivered / totalOrders : 0.0,
      cancellationRate: totalOrders > 0 ? totalCancelled / totalOrders : 0.0,
      totalDays: groupedHistory.length,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VendorGroupedOrderHistory &&
        other.dateKey == dateKey &&
        other.displayDate == displayDate &&
        other.date == date &&
        listEquals(other.orders, orders) &&
        other.totalOrders == totalOrders;
  }

  @override
  int get hashCode {
    return Object.hash(
      dateKey,
      displayDate,
      date,
      Object.hashAll(orders),
      totalOrders,
    );
  }

  @override
  String toString() {
    return 'VendorGroupedOrderHistory(dateKey: $dateKey, displayDate: $displayDate, totalOrders: $totalOrders, revenue: RM${totalRevenue.toStringAsFixed(2)})';
  }
}

/// Summary statistics for vendor order history
@immutable
class VendorOrderHistorySummary {
  final int totalOrders;
  final double totalRevenue;
  final double totalCommission;
  final double netEarnings;
  final int deliveredOrders;
  final int cancelledOrders;
  final double averageOrderValue;
  final double completionRate;
  final double cancellationRate;
  final int totalDays;

  const VendorOrderHistorySummary({
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalCommission,
    required this.netEarnings,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.averageOrderValue,
    required this.completionRate,
    required this.cancellationRate,
    required this.totalDays,
  });

  /// Get active orders count
  int get activeOrders => totalOrders - deliveredOrders - cancelledOrders;

  /// Get daily average orders
  double get dailyAverageOrders => totalDays > 0 ? totalOrders / totalDays : 0.0;

  /// Get daily average revenue
  double get dailyAverageRevenue => totalDays > 0 ? totalRevenue / totalDays : 0.0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VendorOrderHistorySummary &&
        other.totalOrders == totalOrders &&
        other.totalRevenue == totalRevenue &&
        other.totalCommission == totalCommission &&
        other.netEarnings == netEarnings &&
        other.deliveredOrders == deliveredOrders &&
        other.cancelledOrders == cancelledOrders &&
        other.averageOrderValue == averageOrderValue &&
        other.completionRate == completionRate &&
        other.cancellationRate == cancellationRate &&
        other.totalDays == totalDays;
  }

  @override
  int get hashCode {
    return Object.hash(
      totalOrders,
      totalRevenue,
      totalCommission,
      netEarnings,
      deliveredOrders,
      cancelledOrders,
      averageOrderValue,
      completionRate,
      cancellationRate,
      totalDays,
    );
  }

  @override
  String toString() {
    return 'VendorOrderHistorySummary(totalOrders: $totalOrders, totalRevenue: RM${totalRevenue.toStringAsFixed(2)}, netEarnings: RM${netEarnings.toStringAsFixed(2)})';
  }
}
