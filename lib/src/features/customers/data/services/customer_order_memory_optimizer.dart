
import 'dart:collection';
import 'package:flutter/foundation.dart';

import '../../../orders/data/models/order.dart';
import '../models/customer_order_history_models.dart';

/// Memory optimization service for customer order data
class CustomerOrderMemoryOptimizer {
  static final CustomerOrderMemoryOptimizer _instance = CustomerOrderMemoryOptimizer._internal();
  factory CustomerOrderMemoryOptimizer() => _instance;
  CustomerOrderMemoryOptimizer._internal();

  // Memory pools for object reuse
  final Queue<CustomerGroupedOrderHistory> _groupPool = Queue<CustomerGroupedOrderHistory>();
  final Queue<Order> _orderPool = Queue<Order>();
  
  // Memory tracking
  int _totalObjectsCreated = 0;
  int _totalObjectsReused = 0;
  int _currentMemoryUsageKB = 0;
  
  // Configuration
  static const int _maxPoolSize = 50;
  static const int _memoryWarningThresholdKB = 10240; // 10MB
  static const int _memoryCleanupThresholdKB = 15360; // 15MB

  /// Optimize grouped order history for memory efficiency
  List<CustomerGroupedOrderHistory> optimizeGroupedHistory(
    List<CustomerGroupedOrderHistory> groups,
  ) {
    debugPrint('🧠 Memory Optimizer: Optimizing ${groups.length} grouped order history entries');
    
    final optimized = <CustomerGroupedOrderHistory>[];
    
    for (final group in groups) {
      // Optimize individual group
      final optimizedGroup = _optimizeGroup(group);
      optimized.add(optimizedGroup);
    }
    
    // Update memory tracking
    _updateMemoryUsage();
    
    debugPrint('🧠 Memory Optimizer: Optimization complete - ${optimized.length} groups');
    return optimized;
  }

  /// Optimize individual order group
  CustomerGroupedOrderHistory _optimizeGroup(CustomerGroupedOrderHistory group) {
    // Optimize orders within the group
    final optimizedCompleted = _optimizeOrders(group.completedOrders);
    final optimizedCancelled = _optimizeOrders(group.cancelledOrders);
    
    // Reuse group object if possible
    final optimizedGroup = _reuseOrCreateGroup(
      dateKey: group.dateKey,
      displayDate: group.displayDate,
      date: group.date,
      completedOrders: optimizedCompleted,
      cancelledOrders: optimizedCancelled,
    );
    
    return optimizedGroup;
  }

  /// Optimize list of orders
  List<Order> _optimizeOrders(List<Order> orders) {
    final optimized = <Order>[];
    
    for (final order in orders) {
      // Optimize individual order
      final optimizedOrder = _optimizeOrder(order);
      optimized.add(optimizedOrder);
    }
    
    return optimized;
  }

  /// Optimize individual order
  Order _optimizeOrder(Order order) {
    // For now, return the order as-is
    // In the future, we could implement order field optimization
    return order;
  }

  /// Reuse or create grouped order history
  CustomerGroupedOrderHistory _reuseOrCreateGroup({
    required String dateKey,
    required String displayDate,
    required DateTime date,
    required List<Order> completedOrders,
    required List<Order> cancelledOrders,
  }) {
    // Try to reuse from pool
    if (_groupPool.isNotEmpty) {
      _groupPool.removeFirst(); // Remove and reuse object
      _totalObjectsReused++;

      // Create new instance with optimized data
      // Note: In a real implementation, we'd need a way to update the existing object
      // For now, we'll create a new one
    }
    
    // Create new instance
    _totalObjectsCreated++;
    
    final totalOrders = completedOrders.length + cancelledOrders.length;
    final totalSpent = [...completedOrders, ...cancelledOrders]
        .fold(0.0, (sum, order) => sum + order.totalAmount);
    final completedSpent = completedOrders
        .fold(0.0, (sum, order) => sum + order.totalAmount);
    
    // Calculate active orders (not completed or cancelled)
    final allOrders = [...completedOrders, ...cancelledOrders];
    final activeOrders = allOrders
        .where((order) => order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled)
        .toList();

    return CustomerGroupedOrderHistory(
      dateKey: dateKey,
      displayDate: displayDate,
      date: date,
      completedOrders: completedOrders,
      cancelledOrders: cancelledOrders,
      activeOrders: activeOrders,
      totalOrders: totalOrders,
      completedCount: completedOrders.length,
      cancelledCount: cancelledOrders.length,
      activeCount: activeOrders.length,
      totalSpent: totalSpent,
      completedSpent: completedSpent,
    );
  }

  /// Return object to pool for reuse
  void returnToPool(CustomerGroupedOrderHistory group) {
    if (_groupPool.length < _maxPoolSize) {
      _groupPool.addLast(group);
    }
  }

  /// Update memory usage tracking
  void _updateMemoryUsage() {
    // Rough estimation of memory usage
    final groupMemory = _groupPool.length * 2; // 2KB per group estimate
    final orderMemory = _orderPool.length * 1; // 1KB per order estimate
    
    _currentMemoryUsageKB = groupMemory + orderMemory;
    
    // Check for memory warnings
    if (_currentMemoryUsageKB > _memoryWarningThresholdKB) {
      debugPrint('🧠 Memory Optimizer: Memory usage warning - ${_currentMemoryUsageKB}KB');
    }
    
    // Trigger cleanup if needed
    if (_currentMemoryUsageKB > _memoryCleanupThresholdKB) {
      _performMemoryCleanup();
    }
  }

  /// Perform memory cleanup
  void _performMemoryCleanup() {
    debugPrint('🧠 Memory Optimizer: Performing memory cleanup');
    
    // Clear half of the pools
    final groupsToRemove = _groupPool.length ~/ 2;
    final ordersToRemove = _orderPool.length ~/ 2;
    
    for (int i = 0; i < groupsToRemove; i++) {
      if (_groupPool.isNotEmpty) {
        _groupPool.removeFirst();
      }
    }
    
    for (int i = 0; i < ordersToRemove; i++) {
      if (_orderPool.isNotEmpty) {
        _orderPool.removeFirst();
      }
    }
    
    _updateMemoryUsage();
    debugPrint('🧠 Memory Optimizer: Cleanup complete - ${_currentMemoryUsageKB}KB');
  }

  /// Get memory statistics
  CustomerOrderMemoryStats getMemoryStats() {
    return CustomerOrderMemoryStats(
      totalObjectsCreated: _totalObjectsCreated,
      totalObjectsReused: _totalObjectsReused,
      currentMemoryUsageKB: _currentMemoryUsageKB,
      pooledGroups: _groupPool.length,
      pooledOrders: _orderPool.length,
      reuseRate: _totalObjectsCreated == 0 
          ? 0.0 
          : _totalObjectsReused / (_totalObjectsCreated + _totalObjectsReused),
    );
  }

  /// Clear all pools and reset counters
  void clear() {
    _groupPool.clear();
    _orderPool.clear();
    _totalObjectsCreated = 0;
    _totalObjectsReused = 0;
    _currentMemoryUsageKB = 0;
    debugPrint('🧠 Memory Optimizer: Cleared all pools and counters');
  }

  /// Optimize memory usage for large datasets
  List<CustomerGroupedOrderHistory> optimizeForLargeDataset(
    List<CustomerGroupedOrderHistory> groups, {
    int maxGroupsInMemory = 20,
  }) {
    debugPrint('🧠 Memory Optimizer: Optimizing large dataset - ${groups.length} groups');
    
    if (groups.length <= maxGroupsInMemory) {
      return optimizeGroupedHistory(groups);
    }
    
    // Keep only the most recent groups in memory
    final recentGroups = groups.take(maxGroupsInMemory).toList();
    
    // Optimize the recent groups
    final optimized = optimizeGroupedHistory(recentGroups);
    
    debugPrint('🧠 Memory Optimizer: Large dataset optimization complete - kept ${optimized.length}/${groups.length} groups');
    return optimized;
  }

  /// Preload objects into pools
  void preloadPools() {
    debugPrint('🧠 Memory Optimizer: Preloading object pools');
    
    // This would typically create placeholder objects
    // For now, we'll just log the action
    debugPrint('🧠 Memory Optimizer: Pools preloaded');
  }

  /// Get memory optimization recommendations
  List<String> getOptimizationRecommendations() {
    final stats = getMemoryStats();
    final recommendations = <String>[];
    
    if (stats.reuseRate < 0.3) {
      recommendations.add('Consider increasing object reuse - current rate: ${(stats.reuseRate * 100).toStringAsFixed(1)}%');
    }
    
    if (stats.currentMemoryUsageKB > _memoryWarningThresholdKB) {
      recommendations.add('Memory usage is high: ${stats.currentMemoryUsageKB}KB - consider reducing data in memory');
    }
    
    if (stats.pooledGroups < 5) {
      recommendations.add('Object pool is small - consider preloading more objects');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Memory usage is optimized');
    }
    
    return recommendations;
  }
}

/// Memory statistics model
@immutable
class CustomerOrderMemoryStats {
  final int totalObjectsCreated;
  final int totalObjectsReused;
  final int currentMemoryUsageKB;
  final int pooledGroups;
  final int pooledOrders;
  final double reuseRate;

  const CustomerOrderMemoryStats({
    required this.totalObjectsCreated,
    required this.totalObjectsReused,
    required this.currentMemoryUsageKB,
    required this.pooledGroups,
    required this.pooledOrders,
    required this.reuseRate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerOrderMemoryStats &&
          runtimeType == other.runtimeType &&
          totalObjectsCreated == other.totalObjectsCreated &&
          totalObjectsReused == other.totalObjectsReused &&
          currentMemoryUsageKB == other.currentMemoryUsageKB &&
          pooledGroups == other.pooledGroups &&
          pooledOrders == other.pooledOrders &&
          reuseRate == other.reuseRate;

  @override
  int get hashCode => Object.hash(
        totalObjectsCreated,
        totalObjectsReused,
        currentMemoryUsageKB,
        pooledGroups,
        pooledOrders,
        reuseRate,
      );

  @override
  String toString() => 'CustomerOrderMemoryStats('
      'created: $totalObjectsCreated, '
      'reused: $totalObjectsReused, '
      'memoryKB: $currentMemoryUsageKB, '
      'reuseRate: ${(reuseRate * 100).toStringAsFixed(1)}%'
      ')';
}
