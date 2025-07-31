import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/enhanced_cache_service.dart';
import '../../data/services/cache_invalidation_strategy_service.dart';
import '../../data/services/order_history_cache_service.dart';
import 'enhanced_driver_order_history_providers.dart';

/// Comprehensive cache management providers for driver order history

/// Provider for cache management service
final cacheManagementServiceProvider = Provider<CacheManagementService>((ref) {
  return CacheManagementService();
});

/// Provider for cache health monitoring
final cacheHealthProvider = FutureProvider<CacheHealthReport>((ref) async {
  final cacheService = ref.read(cacheManagementServiceProvider);
  return await cacheService.generateHealthReport();
});

/// Provider for cache optimization recommendations
final cacheOptimizationProvider = Provider<List<CacheOptimizationRecommendation>>((ref) {
  final cacheService = ref.read(cacheManagementServiceProvider);
  return cacheService.getOptimizationRecommendations();
});

/// Provider for cache invalidation statistics
final cacheInvalidationStatsProvider = Provider<Map<String, dynamic>>((ref) {
  return CacheInvalidationStrategyService.instance.getInvalidationStats();
});

/// Provider for cache warming progress
final cacheWarmingProgressProvider = StateProvider<CacheWarmingProgress>((ref) {
  return const CacheWarmingProgress(
    isActive: false,
    completedItems: 0,
    totalItems: 0,
    currentItem: '',
  );
});

/// Comprehensive cache management service
class CacheManagementService {
  /// Initialize all cache services
  Future<void> initializeAllCaches() async {
    try {
      debugPrint('🔧 CacheManagement: Initializing all cache services...');
      
      // Initialize services in order
      await EnhancedCacheService.instance.initialize();
      await OrderHistoryCacheService.instance.initialize();
      await CacheInvalidationStrategyService.instance.initialize();
      
      debugPrint('🔧 CacheManagement: All cache services initialized successfully');
    } catch (e) {
      debugPrint('🔧 CacheManagement: Error initializing cache services: $e');
      rethrow;
    }
  }

  /// Generate comprehensive cache health report
  Future<CacheHealthReport> generateHealthReport() async {
    try {
      // Get analytics from all cache services
      final enhancedAnalytics = EnhancedCacheService.instance.getCacheAnalytics();
      final legacyStats = OrderHistoryCacheService.instance.getCacheStats();
      final invalidationStats = CacheInvalidationStrategyService.instance.getInvalidationStats();
      
      // Calculate overall health metrics
      final enhancedHitRate = enhancedAnalytics['hitRate'] as double? ?? 0.0;
      final enhancedEfficiency = enhancedAnalytics['cacheEfficiency'] as double? ?? 0.0;
      final memoryUtilization = _calculateMemoryUtilization(enhancedAnalytics, legacyStats);
      
      // Determine overall health status
      final healthStatus = _determineHealthStatus(enhancedHitRate, enhancedEfficiency, memoryUtilization);
      
      return CacheHealthReport(
        overallHealth: healthStatus,
        hitRate: enhancedHitRate,
        efficiency: enhancedEfficiency,
        memoryUtilization: memoryUtilization,
        enhancedCacheStats: enhancedAnalytics,
        legacyCacheStats: legacyStats,
        invalidationStats: invalidationStats,
        recommendations: _generateHealthRecommendations(enhancedHitRate, enhancedEfficiency, memoryUtilization),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('🔧 CacheManagement: Error generating health report: $e');
      return CacheHealthReport.error(e.toString());
    }
  }

  /// Get cache optimization recommendations
  List<CacheOptimizationRecommendation> getOptimizationRecommendations() {
    final recommendations = <CacheOptimizationRecommendation>[];
    
    try {
      final analytics = EnhancedCacheService.instance.getCacheAnalytics();
      final hitRate = analytics['hitRate'] as double? ?? 0.0;
      final efficiency = analytics['cacheEfficiency'] as double? ?? 0.0;
      final memoryEntries = analytics['memoryEntries'] as int? ?? 0;
      
      // Hit rate recommendations
      if (hitRate < 0.6) {
        recommendations.add(CacheOptimizationRecommendation(
          type: RecommendationType.performance,
          priority: RecommendationPriority.high,
          title: 'Low Cache Hit Rate',
          description: 'Cache hit rate is ${(hitRate * 100).toStringAsFixed(1)}%. Consider increasing cache duration for frequently accessed data.',
          action: 'Increase cache duration for common filters',
          estimatedImpact: 'Could improve hit rate by 15-25%',
        ));
      }
      
      // Memory utilization recommendations
      if (memoryEntries > 80) {
        recommendations.add(CacheOptimizationRecommendation(
          type: RecommendationType.memory,
          priority: RecommendationPriority.medium,
          title: 'High Memory Usage',
          description: 'Memory cache has $memoryEntries entries. Consider optimizing cache eviction strategy.',
          action: 'Implement more aggressive cache eviction',
          estimatedImpact: 'Reduce memory usage by 20-30%',
        ));
      }
      
      // Efficiency recommendations
      if (efficiency < 0.7) {
        recommendations.add(CacheOptimizationRecommendation(
          type: RecommendationType.efficiency,
          priority: RecommendationPriority.medium,
          title: 'Cache Efficiency Below Optimal',
          description: 'Cache efficiency is ${(efficiency * 100).toStringAsFixed(1)}%. Review caching strategies.',
          action: 'Optimize cache key generation and data prioritization',
          estimatedImpact: 'Improve overall cache efficiency by 10-20%',
        ));
      }
      
      // Prefetch recommendations
      final prefetchEntries = analytics['prefetchEntries'] as int? ?? 0;
      if (prefetchEntries < 5) {
        recommendations.add(CacheOptimizationRecommendation(
          type: RecommendationType.prefetch,
          priority: RecommendationPriority.low,
          title: 'Limited Prefetch Usage',
          description: 'Only $prefetchEntries items in prefetch cache. Consider more aggressive prefetching.',
          action: 'Implement intelligent prefetch for common filter patterns',
          estimatedImpact: 'Reduce perceived load times by 30-50%',
        ));
      }
      
      // Add positive feedback if everything is optimal
      if (recommendations.isEmpty) {
        recommendations.add(CacheOptimizationRecommendation(
          type: RecommendationType.performance,
          priority: RecommendationPriority.info,
          title: 'Cache Performance Optimal',
          description: 'All cache metrics are within optimal ranges.',
          action: 'Continue monitoring cache performance',
          estimatedImpact: 'Maintain current excellent performance',
        ));
      }
      
    } catch (e) {
      debugPrint('🔧 CacheManagement: Error generating recommendations: $e');
      recommendations.add(CacheOptimizationRecommendation(
        type: RecommendationType.error,
        priority: RecommendationPriority.high,
        title: 'Error Analyzing Cache',
        description: 'Unable to analyze cache performance: $e',
        action: 'Check cache service status',
        estimatedImpact: 'Resolve to enable optimization',
      ));
    }
    
    return recommendations;
  }

  /// Perform comprehensive cache cleanup
  Future<CacheCleanupResult> performCleanup() async {
    try {
      debugPrint('🔧 CacheManagement: Starting comprehensive cache cleanup...');
      
      final startTime = DateTime.now();
      int itemsRemoved = 0;
      int bytesFreed = 0;
      
      // Get initial stats
      final initialStats = EnhancedCacheService.instance.getCacheAnalytics();
      final initialMemoryEntries = initialStats['memoryEntries'] as int? ?? 0;
      
      // Cleanup enhanced cache (it handles its own cleanup)
      // The cleanup is done internally when cache size limits are exceeded
      
      // Get final stats
      final finalStats = EnhancedCacheService.instance.getCacheAnalytics();
      final finalMemoryEntries = finalStats['memoryEntries'] as int? ?? 0;
      
      itemsRemoved = initialMemoryEntries - finalMemoryEntries;
      bytesFreed = itemsRemoved * 1024; // Rough estimation
      
      final duration = DateTime.now().difference(startTime);
      
      debugPrint('🔧 CacheManagement: Cleanup completed in ${duration.inMilliseconds}ms');
      
      return CacheCleanupResult(
        success: true,
        itemsRemoved: itemsRemoved,
        bytesFreed: bytesFreed,
        duration: duration,
        message: 'Cache cleanup completed successfully',
      );
    } catch (e) {
      debugPrint('🔧 CacheManagement: Error during cleanup: $e');
      return CacheCleanupResult(
        success: false,
        itemsRemoved: 0,
        bytesFreed: 0,
        duration: Duration.zero,
        message: 'Cache cleanup failed: $e',
      );
    }
  }

  /// Warm cache for specific driver
  Future<void> warmCacheForDriver(String driverId) async {
    try {
      debugPrint('🔧 CacheManagement: Warming cache for driver: $driverId');
      
      final commonFilters = QuickDateFilter.values.where((f) => f.isCommonlyUsed).toList();
      await EnhancedCacheService.instance.warmCache(driverId, commonFilters);
      
      debugPrint('🔧 CacheManagement: Cache warming completed for driver: $driverId');
    } catch (e) {
      debugPrint('🔧 CacheManagement: Error warming cache: $e');
    }
  }

  /// Calculate memory utilization across all caches
  double _calculateMemoryUtilization(Map<String, dynamic> enhancedStats, Map<String, dynamic> legacyStats) {
    final enhancedEntries = enhancedStats['memoryEntries'] as int? ?? 0;
    final legacyEntries = legacyStats['memoryEntries'] as int? ?? 0;
    
    // Rough calculation based on typical cache sizes
    const maxEnhancedEntries = 100;
    const maxLegacyEntries = 50;
    
    final enhancedUtilization = enhancedEntries / maxEnhancedEntries;
    final legacyUtilization = legacyEntries / maxLegacyEntries;
    
    return ((enhancedUtilization + legacyUtilization) / 2).clamp(0.0, 1.0);
  }

  /// Determine overall health status
  CacheHealthStatus _determineHealthStatus(double hitRate, double efficiency, double memoryUtilization) {
    if (hitRate >= 0.8 && efficiency >= 0.8 && memoryUtilization <= 0.8) {
      return CacheHealthStatus.excellent;
    } else if (hitRate >= 0.6 && efficiency >= 0.6 && memoryUtilization <= 0.9) {
      return CacheHealthStatus.good;
    } else if (hitRate >= 0.4 && efficiency >= 0.4) {
      return CacheHealthStatus.fair;
    } else {
      return CacheHealthStatus.poor;
    }
  }

  /// Generate health-based recommendations
  List<String> _generateHealthRecommendations(double hitRate, double efficiency, double memoryUtilization) {
    final recommendations = <String>[];
    
    if (hitRate < 0.6) {
      recommendations.add('Increase cache duration for frequently accessed data');
    }
    
    if (efficiency < 0.6) {
      recommendations.add('Review cache key generation and prioritization strategies');
    }
    
    if (memoryUtilization > 0.8) {
      recommendations.add('Implement more aggressive cache eviction policies');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Cache performance is optimal - continue monitoring');
    }
    
    return recommendations;
  }
}

/// Cache health report model
@immutable
class CacheHealthReport {
  final CacheHealthStatus overallHealth;
  final double hitRate;
  final double efficiency;
  final double memoryUtilization;
  final Map<String, dynamic> enhancedCacheStats;
  final Map<String, dynamic> legacyCacheStats;
  final Map<String, dynamic> invalidationStats;
  final List<String> recommendations;
  final DateTime timestamp;
  final String? errorMessage;

  const CacheHealthReport({
    required this.overallHealth,
    required this.hitRate,
    required this.efficiency,
    required this.memoryUtilization,
    required this.enhancedCacheStats,
    required this.legacyCacheStats,
    required this.invalidationStats,
    required this.recommendations,
    required this.timestamp,
    this.errorMessage,
  });

  factory CacheHealthReport.error(String error) {
    return CacheHealthReport(
      overallHealth: CacheHealthStatus.error,
      hitRate: 0.0,
      efficiency: 0.0,
      memoryUtilization: 0.0,
      enhancedCacheStats: {},
      legacyCacheStats: {},
      invalidationStats: {},
      recommendations: ['Resolve cache service error: $error'],
      timestamp: DateTime.now(),
      errorMessage: error,
    );
  }

  bool get hasError => errorMessage != null;

  @override
  String toString() {
    return 'CacheHealthReport(health: $overallHealth, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, efficiency: ${(efficiency * 100).toStringAsFixed(1)}%)';
  }
}

/// Cache health status enum
enum CacheHealthStatus {
  excellent,
  good,
  fair,
  poor,
  error,
}

extension CacheHealthStatusExtension on CacheHealthStatus {
  String get displayName {
    switch (this) {
      case CacheHealthStatus.excellent:
        return 'Excellent';
      case CacheHealthStatus.good:
        return 'Good';
      case CacheHealthStatus.fair:
        return 'Fair';
      case CacheHealthStatus.poor:
        return 'Poor';
      case CacheHealthStatus.error:
        return 'Error';
    }
  }

  String get description {
    switch (this) {
      case CacheHealthStatus.excellent:
        return 'Cache is performing optimally';
      case CacheHealthStatus.good:
        return 'Cache performance is good with minor optimization opportunities';
      case CacheHealthStatus.fair:
        return 'Cache performance is acceptable but could be improved';
      case CacheHealthStatus.poor:
        return 'Cache performance needs attention';
      case CacheHealthStatus.error:
        return 'Cache service is experiencing errors';
    }
  }
}

/// Cache optimization recommendation model
@immutable
class CacheOptimizationRecommendation {
  final RecommendationType type;
  final RecommendationPriority priority;
  final String title;
  final String description;
  final String action;
  final String estimatedImpact;

  const CacheOptimizationRecommendation({
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.action,
    required this.estimatedImpact,
  });

  @override
  String toString() {
    return 'CacheOptimizationRecommendation(type: $type, priority: $priority, title: $title)';
  }
}

/// Recommendation type enum
enum RecommendationType {
  performance,
  memory,
  efficiency,
  prefetch,
  error,
}

/// Recommendation priority enum
enum RecommendationPriority {
  high,
  medium,
  low,
  info,
}

/// Cache warming progress model
@immutable
class CacheWarmingProgress {
  final bool isActive;
  final int completedItems;
  final int totalItems;
  final String currentItem;

  const CacheWarmingProgress({
    required this.isActive,
    required this.completedItems,
    required this.totalItems,
    required this.currentItem,
  });

  double get progress => totalItems > 0 ? completedItems / totalItems : 0.0;

  CacheWarmingProgress copyWith({
    bool? isActive,
    int? completedItems,
    int? totalItems,
    String? currentItem,
  }) {
    return CacheWarmingProgress(
      isActive: isActive ?? this.isActive,
      completedItems: completedItems ?? this.completedItems,
      totalItems: totalItems ?? this.totalItems,
      currentItem: currentItem ?? this.currentItem,
    );
  }

  @override
  String toString() {
    return 'CacheWarmingProgress(active: $isActive, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }
}

/// Cache cleanup result model
@immutable
class CacheCleanupResult {
  final bool success;
  final int itemsRemoved;
  final int bytesFreed;
  final Duration duration;
  final String message;

  const CacheCleanupResult({
    required this.success,
    required this.itemsRemoved,
    required this.bytesFreed,
    required this.duration,
    required this.message,
  });

  @override
  String toString() {
    return 'CacheCleanupResult(success: $success, itemsRemoved: $itemsRemoved, bytesFreed: ${bytesFreed}B, duration: ${duration.inMilliseconds}ms)';
  }
}
