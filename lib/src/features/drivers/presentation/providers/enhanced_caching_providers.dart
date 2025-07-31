import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/data/models/order.dart';
import '../../../../data/models/user_role.dart';
import '../../data/services/enhanced_cache_service.dart';
import '../../data/services/optimized_database_service.dart';
import 'enhanced_driver_order_history_providers.dart';

/// Enhanced caching providers with intelligent cache management

/// Provider for enhanced cached order history with intelligent caching
final enhancedCachedOrderHistoryProvider = FutureProvider.family<List<Order>, DateRangeFilter>((ref, filter) async {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    debugPrint('🚀 EnhancedCachedHistory: User is not a driver, role: ${authState.user?.role}');
    return [];
  }

  final userId = authState.user?.id;
  if (userId == null) {
    debugPrint('🚀 EnhancedCachedHistory: No user ID found');
    return [];
  }

  try {
    final supabase = Supabase.instance.client;

    // Get driver ID
    final driverResponse = await supabase
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (driverResponse == null) {
      debugPrint('🚀 EnhancedCachedHistory: No driver found for user: $userId');
      return [];
    }

    final driverId = driverResponse['id'] as String;
    debugPrint('🚀 EnhancedCachedHistory: Found driver ID: $driverId for user: $userId');

    // Initialize enhanced cache service
    await EnhancedCacheService.instance.initialize();

    // Check enhanced cache first
    final cachedOrders = await EnhancedCacheService.instance.getCachedOrderHistory(driverId, filter);
    if (cachedOrders != null) {
      debugPrint('🚀 EnhancedCachedHistory: Cache hit with ${cachedOrders.length} orders');
      
      // Trigger prefetch for related filters in background
      _triggerIntelligentPrefetch(ref, driverId, filter);
      
      return cachedOrders;
    }

    // Cache miss - fetch from database
    debugPrint('🚀 EnhancedCachedHistory: Cache miss, fetching from database');
    final orders = await OptimizedDatabaseService.instance.getDriverOrderHistory(
      driverId: driverId,
      startDate: filter.startDate,
      endDate: filter.endDate,
      limit: filter.limit,
      offset: filter.offset,
    );

    // Cache the results with intelligent optimization
    await EnhancedCacheService.instance.cacheOrderHistory(
      driverId,
      filter,
      orders,
    );

    // Trigger intelligent cache warming for commonly used filters
    _triggerCacheWarming(ref, driverId);

    debugPrint('🚀 EnhancedCachedHistory: Fetched and cached ${orders.length} orders');
    return orders;
  } catch (e) {
    debugPrint('🚀 EnhancedCachedHistory: Error loading orders: $e');
    return [];
  }
});

/// Provider for cache analytics and performance monitoring
final cacheAnalyticsProvider = Provider<Map<String, dynamic>>((ref) {
  return EnhancedCacheService.instance.getCacheAnalytics();
});

/// Provider for cache warming status
final cacheWarmingStatusProvider = StateProvider<CacheWarmingStatus>((ref) {
  return const CacheWarmingStatus(isWarming: false, itemsWarmed: 0, totalItems: 0);
});

/// Provider for intelligent cache prefetching
final intelligentPrefetchProvider = FutureProvider.family<bool, PrefetchRequest>((ref, request) async {
  try {
    await EnhancedCacheService.instance.initialize();
    
    // Check if already cached
    final cachedData = await EnhancedCacheService.instance.getCachedOrderHistory(
      request.driverId, 
      request.filter,
    );
    
    if (cachedData != null) {
      debugPrint('🚀 IntelligentPrefetch: Data already cached for ${request.filter.description}');
      return true;
    }

    // Fetch and cache as prefetch
    final orders = await OptimizedDatabaseService.instance.getDriverOrderHistory(
      driverId: request.driverId,
      startDate: request.filter.startDate,
      endDate: request.filter.endDate,
      limit: request.filter.limit,
      offset: request.filter.offset,
    );

    await EnhancedCacheService.instance.cacheOrderHistory(
      request.driverId,
      request.filter,
      orders,
      isPrefetch: true,
    );

    debugPrint('🚀 IntelligentPrefetch: Prefetched ${orders.length} orders for ${request.filter.description}');
    return true;
  } catch (e) {
    debugPrint('🚀 IntelligentPrefetch: Error prefetching: $e');
    return false;
  }
});

/// Provider for cache invalidation
final cacheInvalidationProvider = Provider<CacheInvalidationService>((ref) {
  return CacheInvalidationService();
});

/// Trigger intelligent prefetch for related filters
void _triggerIntelligentPrefetch(Ref ref, String driverId, DateRangeFilter currentFilter) {
  // Fire and forget prefetch for commonly accessed related filters
  Future(() async {
    try {
      final commonFilters = [
        QuickDateFilter.today,
        QuickDateFilter.yesterday,
        QuickDateFilter.thisWeek,
        QuickDateFilter.thisMonth,
      ];

      for (final filter in commonFilters) {
        if (filter.isCommonlyUsed) {
          final dateFilter = filter.toDateRangeFilter();
          
          // Skip if it's the same as current filter
          if (dateFilter.startDate == currentFilter.startDate && 
              dateFilter.endDate == currentFilter.endDate) {
            continue;
          }

          final prefetchRequest = PrefetchRequest(
            driverId: driverId,
            filter: dateFilter,
            priority: filter.cachePriority,
          );

          // Trigger prefetch
          ref.read(intelligentPrefetchProvider(prefetchRequest));
        }
      }
    } catch (e) {
      debugPrint('🚀 IntelligentPrefetch: Error triggering prefetch: $e');
    }
  });
}

/// Trigger cache warming for commonly used filters
void _triggerCacheWarming(Ref ref, String driverId) {
  // Fire and forget cache warming
  Future(() async {
    try {
      final commonFilters = QuickDateFilter.values.where((f) => f.isCommonlyUsed).toList();
      await EnhancedCacheService.instance.warmCache(driverId, commonFilters);
      
      // Update warming status
      ref.read(cacheWarmingStatusProvider.notifier).state = CacheWarmingStatus(
        isWarming: false,
        itemsWarmed: commonFilters.length,
        totalItems: commonFilters.length,
      );
    } catch (e) {
      debugPrint('🚀 CacheWarming: Error warming cache: $e');
    }
  });
}

/// Cache warming status model
@immutable
class CacheWarmingStatus {
  final bool isWarming;
  final int itemsWarmed;
  final int totalItems;

  const CacheWarmingStatus({
    required this.isWarming,
    required this.itemsWarmed,
    required this.totalItems,
  });

  double get progress => totalItems > 0 ? itemsWarmed / totalItems : 0.0;

  CacheWarmingStatus copyWith({
    bool? isWarming,
    int? itemsWarmed,
    int? totalItems,
  }) {
    return CacheWarmingStatus(
      isWarming: isWarming ?? this.isWarming,
      itemsWarmed: itemsWarmed ?? this.itemsWarmed,
      totalItems: totalItems ?? this.totalItems,
    );
  }

  @override
  String toString() {
    return 'CacheWarmingStatus(isWarming: $isWarming, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }
}

/// Prefetch request model
@immutable
class PrefetchRequest {
  final String driverId;
  final DateRangeFilter filter;
  final int priority;

  const PrefetchRequest({
    required this.driverId,
    required this.filter,
    required this.priority,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrefetchRequest &&
        other.driverId == driverId &&
        other.filter == filter &&
        other.priority == priority;
  }

  @override
  int get hashCode {
    return Object.hash(driverId, filter, priority);
  }

  @override
  String toString() {
    return 'PrefetchRequest(driverId: $driverId, filter: ${filter.description}, priority: $priority)';
  }
}

/// Cache invalidation service
class CacheInvalidationService {
  /// Invalidate cache for specific driver
  Future<void> invalidateDriverCache(String driverId) async {
    await EnhancedCacheService.instance.invalidateDriverCache(driverId);
    debugPrint('🚀 CacheInvalidation: Invalidated cache for driver: $driverId');
  }

  /// Invalidate cache based on filter criteria
  Future<void> invalidateFilterCache(String driverId, DateRangeFilter filter) async {
    // For now, invalidate entire driver cache
    // Could be enhanced to invalidate specific filter ranges
    await invalidateDriverCache(driverId);
  }

  /// Smart invalidation based on data changes
  Future<void> smartInvalidation(String driverId, {
    DateTime? orderCreatedAt,
    DateTime? orderUpdatedAt,
  }) async {
    // Invalidate caches that might be affected by the data change
    if (orderCreatedAt != null || orderUpdatedAt != null) {
      await invalidateDriverCache(driverId);
      debugPrint('🚀 CacheInvalidation: Smart invalidation triggered for driver: $driverId');
    }
  }
}

/// Provider for cache performance monitoring
final cachePerformanceMonitorProvider = Provider<Map<String, dynamic>>((ref) {
  final analytics = ref.watch(cacheAnalyticsProvider);
  
  return {
    'cacheAnalytics': analytics,
    'timestamp': DateTime.now().toIso8601String(),
    'recommendations': _generateCacheRecommendations(analytics),
  };
});

/// Generate cache optimization recommendations
List<String> _generateCacheRecommendations(Map<String, dynamic> analytics) {
  final recommendations = <String>[];
  
  final hitRate = analytics['hitRate'] as double? ?? 0.0;
  final memoryEntries = analytics['memoryEntries'] as int? ?? 0;
  final efficiency = analytics['cacheEfficiency'] as double? ?? 0.0;
  
  if (hitRate < 0.7) {
    recommendations.add('Consider increasing cache duration for frequently accessed data');
  }
  
  if (memoryEntries > 80) {
    recommendations.add('Memory cache is near capacity - consider optimizing cache eviction');
  }
  
  if (efficiency < 0.6) {
    recommendations.add('Cache efficiency is low - review caching strategies');
  }
  
  if (recommendations.isEmpty) {
    recommendations.add('Cache performance is optimal');
  }
  
  return recommendations;
}
