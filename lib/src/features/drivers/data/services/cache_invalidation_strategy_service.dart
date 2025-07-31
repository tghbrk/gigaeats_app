import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'enhanced_cache_service.dart';
import 'order_history_cache_service.dart';

/// Advanced cache invalidation strategy service with intelligent invalidation patterns
class CacheInvalidationStrategyService {
  static CacheInvalidationStrategyService? _instance;
  static CacheInvalidationStrategyService get instance => _instance ??= CacheInvalidationStrategyService._();
  
  CacheInvalidationStrategyService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Track invalidation patterns
  final Map<String, DateTime> _lastInvalidationTimes = {};
  final Map<String, int> _invalidationCounts = {};
  final Set<String> _pendingInvalidations = {};

  /// Initialize invalidation strategy with real-time listeners
  Future<void> initialize() async {
    await _setupRealtimeInvalidation();
    debugPrint('🔄 CacheInvalidationStrategy: Initialized with real-time invalidation');
  }

  /// Setup real-time cache invalidation based on database changes
  Future<void> _setupRealtimeInvalidation() async {
    try {
      // Listen to order status changes that affect driver history
      _supabase
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('status', 'delivered')
          .listen((data) {
            _handleOrderStatusChange(data);
          });

      // Listen to order updates
      _supabase
          .from('orders')
          .stream(primaryKey: ['id'])
          .listen((data) {
            _handleOrderUpdate(data);
          });

      debugPrint('🔄 CacheInvalidationStrategy: Real-time listeners setup complete');
    } catch (e) {
      debugPrint('🔄 CacheInvalidationStrategy: Error setting up real-time listeners: $e');
    }
  }

  /// Handle order status changes for cache invalidation
  void _handleOrderStatusChange(List<Map<String, dynamic>> data) {
    for (final orderData in data) {
      final driverId = orderData['assigned_driver_id'] as String?;
      if (driverId != null) {
        _scheduleInvalidation(driverId, InvalidationReason.orderStatusChange);
      }
    }
  }

  /// Handle order updates for cache invalidation
  void _handleOrderUpdate(List<Map<String, dynamic>> data) {
    for (final orderData in data) {
      final driverId = orderData['assigned_driver_id'] as String?;
      if (driverId != null) {
        _scheduleInvalidation(driverId, InvalidationReason.orderUpdate);
      }
    }
  }

  /// Schedule intelligent cache invalidation
  void _scheduleInvalidation(String driverId, InvalidationReason reason) {
    final invalidationKey = '${driverId}_${reason.name}';
    
    // Prevent excessive invalidations
    final lastInvalidation = _lastInvalidationTimes[invalidationKey];
    if (lastInvalidation != null && 
        DateTime.now().difference(lastInvalidation).inMinutes < 2) {
      debugPrint('🔄 CacheInvalidationStrategy: Skipping invalidation for $driverId (too recent)');
      return;
    }

    if (_pendingInvalidations.contains(invalidationKey)) {
      debugPrint('🔄 CacheInvalidationStrategy: Invalidation already pending for $driverId');
      return;
    }

    _pendingInvalidations.add(invalidationKey);
    
    // Schedule invalidation with appropriate delay based on reason
    final delay = _getInvalidationDelay(reason);
    Future.delayed(delay, () => _executeInvalidation(driverId, reason, invalidationKey));
  }

  /// Get appropriate delay for invalidation based on reason
  Duration _getInvalidationDelay(InvalidationReason reason) {
    switch (reason) {
      case InvalidationReason.orderStatusChange:
        return const Duration(seconds: 5); // Quick invalidation for status changes
      case InvalidationReason.orderUpdate:
        return const Duration(seconds: 10); // Slightly delayed for updates
      case InvalidationReason.newOrderAssigned:
        return const Duration(seconds: 2); // Very quick for new assignments
      case InvalidationReason.manualRefresh:
        return Duration.zero; // Immediate for manual refresh
      case InvalidationReason.scheduledCleanup:
        return const Duration(minutes: 1); // Delayed for cleanup
    }
  }

  /// Execute cache invalidation with strategy
  Future<void> _executeInvalidation(String driverId, InvalidationReason reason, String invalidationKey) async {
    try {
      _pendingInvalidations.remove(invalidationKey);
      
      switch (reason) {
        case InvalidationReason.orderStatusChange:
        case InvalidationReason.newOrderAssigned:
          // Invalidate recent data caches (today, this week)
          await _invalidateRecentDataCaches(driverId);
          break;
          
        case InvalidationReason.orderUpdate:
          // Selective invalidation based on update type
          await _selectiveInvalidation(driverId);
          break;
          
        case InvalidationReason.manualRefresh:
          // Full invalidation for manual refresh
          await _fullInvalidation(driverId);
          break;
          
        case InvalidationReason.scheduledCleanup:
          // Cleanup expired entries only
          await _cleanupInvalidation(driverId);
          break;
      }

      _lastInvalidationTimes[invalidationKey] = DateTime.now();
      _invalidationCounts[invalidationKey] = (_invalidationCounts[invalidationKey] ?? 0) + 1;
      
      debugPrint('🔄 CacheInvalidationStrategy: Executed ${reason.name} invalidation for driver: $driverId');
    } catch (e) {
      debugPrint('🔄 CacheInvalidationStrategy: Error executing invalidation: $e');
    }
  }

  /// Invalidate recent data caches (today, this week)
  Future<void> _invalidateRecentDataCaches(String driverId) async {
    // Invalidate enhanced cache
    await EnhancedCacheService.instance.invalidateDriverCache(driverId);
    
    // Invalidate legacy cache for compatibility
    await OrderHistoryCacheService.instance.invalidateDriverCache(driverId);
    
    debugPrint('🔄 CacheInvalidationStrategy: Invalidated recent data caches for driver: $driverId');
  }

  /// Selective invalidation based on data characteristics
  Future<void> _selectiveInvalidation(String driverId) async {
    // For now, use full invalidation
    // Could be enhanced to invalidate specific date ranges
    await _invalidateRecentDataCaches(driverId);
    
    debugPrint('🔄 CacheInvalidationStrategy: Executed selective invalidation for driver: $driverId');
  }

  /// Full cache invalidation
  Future<void> _fullInvalidation(String driverId) async {
    await EnhancedCacheService.instance.invalidateDriverCache(driverId);
    await OrderHistoryCacheService.instance.invalidateDriverCache(driverId);
    
    debugPrint('🔄 CacheInvalidationStrategy: Executed full invalidation for driver: $driverId');
  }

  /// Cleanup invalidation (expired entries only)
  Future<void> _cleanupInvalidation(String driverId) async {
    // Enhanced cache service handles cleanup internally
    // This could be extended for more sophisticated cleanup
    debugPrint('🔄 CacheInvalidationStrategy: Executed cleanup invalidation for driver: $driverId');
  }

  /// Manual invalidation trigger
  Future<void> manualInvalidation(String driverId) async {
    _scheduleInvalidation(driverId, InvalidationReason.manualRefresh);
  }

  /// Invalidate cache when new order is assigned
  Future<void> invalidateOnNewOrderAssignment(String driverId) async {
    _scheduleInvalidation(driverId, InvalidationReason.newOrderAssigned);
  }

  /// Scheduled cleanup invalidation
  Future<void> scheduledCleanup(String driverId) async {
    _scheduleInvalidation(driverId, InvalidationReason.scheduledCleanup);
  }

  /// Get invalidation statistics
  Map<String, dynamic> getInvalidationStats() {
    final totalInvalidations = _invalidationCounts.values.fold(0, (sum, count) => sum + count);
    final uniqueDrivers = _invalidationCounts.keys.map((key) => key.split('_')[0]).toSet().length;
    
    return {
      'totalInvalidations': totalInvalidations,
      'uniqueDriversAffected': uniqueDrivers,
      'pendingInvalidations': _pendingInvalidations.length,
      'invalidationsByReason': _getInvalidationsByReason(),
      'averageInvalidationsPerDriver': uniqueDrivers > 0 ? totalInvalidations / uniqueDrivers : 0.0,
    };
  }

  /// Get invalidations grouped by reason
  Map<String, int> _getInvalidationsByReason() {
    final byReason = <String, int>{};
    
    for (final entry in _invalidationCounts.entries) {
      final reason = entry.key.split('_').skip(1).join('_');
      byReason[reason] = (byReason[reason] ?? 0) + entry.value;
    }
    
    return byReason;
  }

  /// Check if invalidation is pending for driver
  bool isInvalidationPending(String driverId) {
    return _pendingInvalidations.any((key) => key.startsWith(driverId));
  }

  /// Get last invalidation time for driver
  DateTime? getLastInvalidationTime(String driverId) {
    final driverInvalidations = _lastInvalidationTimes.entries
        .where((entry) => entry.key.startsWith(driverId))
        .map((entry) => entry.value);
    
    if (driverInvalidations.isEmpty) return null;
    
    return driverInvalidations.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Dispose and cleanup
  void dispose() {
    _lastInvalidationTimes.clear();
    _invalidationCounts.clear();
    _pendingInvalidations.clear();
    debugPrint('🔄 CacheInvalidationStrategy: Disposed and cleaned up');
  }
}

/// Reasons for cache invalidation
enum InvalidationReason {
  orderStatusChange,
  orderUpdate,
  newOrderAssigned,
  manualRefresh,
  scheduledCleanup,
}

extension InvalidationReasonExtension on InvalidationReason {
  String get displayName {
    switch (this) {
      case InvalidationReason.orderStatusChange:
        return 'Order Status Change';
      case InvalidationReason.orderUpdate:
        return 'Order Update';
      case InvalidationReason.newOrderAssigned:
        return 'New Order Assigned';
      case InvalidationReason.manualRefresh:
        return 'Manual Refresh';
      case InvalidationReason.scheduledCleanup:
        return 'Scheduled Cleanup';
    }
  }

  String get description {
    switch (this) {
      case InvalidationReason.orderStatusChange:
        return 'Order status changed, affecting driver history';
      case InvalidationReason.orderUpdate:
        return 'Order details updated';
      case InvalidationReason.newOrderAssigned:
        return 'New order assigned to driver';
      case InvalidationReason.manualRefresh:
        return 'User manually refreshed data';
      case InvalidationReason.scheduledCleanup:
        return 'Scheduled cache cleanup';
    }
  }
}
