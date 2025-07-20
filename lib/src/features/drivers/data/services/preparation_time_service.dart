import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/route_optimization_models.dart';
import '../../../orders/data/models/order.dart';

/// Service for predicting vendor preparation times using historical data and machine learning
/// Provides accurate preparation time windows for route optimization
class PreparationTimeService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Cache for vendor preparation statistics
  final Map<String, VendorPreparationStats> _vendorStatsCache = {};
  final Duration _cacheExpiry = const Duration(hours: 1);
  DateTime? _lastCacheUpdate;

  /// Predict preparation times for multiple orders
  Future<Map<String, PreparationWindow>> predictPreparationTimes(
    List<Order> orders
  ) async {
    try {
      debugPrint('🕒 [PREP-TIME] Predicting preparation times for ${orders.length} orders');
      
      final predictions = <String, PreparationWindow>{};
      
      // Group orders by vendor for batch processing
      final ordersByVendor = <String, List<Order>>{};
      for (final order in orders) {
        ordersByVendor.putIfAbsent(order.vendorId, () => []).add(order);
      }
      
      // Process each vendor's orders
      for (final entry in ordersByVendor.entries) {
        final vendorId = entry.key;
        final vendorOrders = entry.value;
        
        final vendorPredictions = await _predictVendorPreparationTimes(vendorId, vendorOrders);
        predictions.addAll(vendorPredictions);
      }
      
      debugPrint('✅ [PREP-TIME] Generated ${predictions.length} preparation predictions');
      return predictions;
    } catch (e) {
      debugPrint('❌ [PREP-TIME] Error predicting preparation times: $e');
      return _generateFallbackPredictions(orders);
    }
  }

  /// Predict preparation times for a single vendor's orders
  Future<Map<String, PreparationWindow>> _predictVendorPreparationTimes(
    String vendorId,
    List<Order> orders,
  ) async {
    try {
      // Get vendor preparation statistics
      final vendorStats = await _getVendorPreparationStats(vendorId);
      
      final predictions = <String, PreparationWindow>{};
      DateTime currentTime = DateTime.now();
      
      // Sort orders by complexity (item count) to simulate kitchen queue
      final sortedOrders = List<Order>.from(orders);
      sortedOrders.sort((a, b) => a.items.length.compareTo(b.items.length));
      
      for (int i = 0; i < sortedOrders.length; i++) {
        final order = sortedOrders[i];
        
        // Calculate preparation time based on order complexity and vendor stats
        final preparationDuration = _calculatePreparationDuration(order, vendorStats);
        
        // Account for kitchen queue (orders prepared sequentially with some overlap)
        final queueDelay = _calculateQueueDelay(i, vendorStats);
        final startTime = currentTime.add(queueDelay);
        final completionTime = startTime.add(preparationDuration);
        
        // Calculate confidence score based on data quality
        final confidenceScore = _calculateConfidenceScore(vendorStats, order);
        
        predictions[order.id] = PreparationWindow(
          orderId: order.id,
          vendorId: vendorId,
          estimatedStartTime: startTime,
          estimatedCompletionTime: completionTime,
          estimatedDuration: preparationDuration,
          confidenceScore: confidenceScore,
          metadata: {
            'order_complexity': order.items.length,
            'queue_position': i + 1,
            'vendor_efficiency': vendorStats.efficiencyScore,
            'prediction_method': 'ml_enhanced',
          },
        );
        
        // Update current time for next order (assuming some parallel processing)
        currentTime = startTime.add(Duration(
          minutes: (preparationDuration.inMinutes * 0.3).round(), // 30% overlap
        ));
      }
      
      return predictions;
    } catch (e) {
      debugPrint('❌ [PREP-TIME] Error predicting vendor preparation times: $e');
      return _generateFallbackPredictions(orders);
    }
  }

  /// Get vendor preparation statistics from database and cache
  Future<VendorPreparationStats> _getVendorPreparationStats(String vendorId) async {
    // Check cache first
    if (_vendorStatsCache.containsKey(vendorId) && 
        _lastCacheUpdate != null && 
        DateTime.now().difference(_lastCacheUpdate!).compareTo(_cacheExpiry) < 0) {
      return _vendorStatsCache[vendorId]!;
    }
    
    try {
      // Query historical preparation data
      final response = await _supabase
          .from('order_preparation_analytics')
          .select('''
            vendor_id,
            avg_preparation_time,
            preparation_time_variance,
            order_complexity_factor,
            peak_hour_multiplier,
            efficiency_score,
            total_orders_analyzed,
            last_updated
          ''')
          .eq('vendor_id', vendorId)
          .maybeSingle();

      VendorPreparationStats stats;
      
      if (response != null) {
        stats = VendorPreparationStats.fromJson(response);
      } else {
        // Generate stats from recent order history
        stats = await _generateVendorStatsFromHistory(vendorId);
      }
      
      // Cache the stats
      _vendorStatsCache[vendorId] = stats;
      _lastCacheUpdate = DateTime.now();
      
      return stats;
    } catch (e) {
      debugPrint('❌ [PREP-TIME] Error getting vendor stats: $e');
      return VendorPreparationStats.defaultStats(vendorId);
    }
  }

  /// Generate vendor statistics from recent order history
  Future<VendorPreparationStats> _generateVendorStatsFromHistory(String vendorId) async {
    try {
      // Get recent completed orders for analysis
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final response = await _supabase
          .from('orders')
          .select('''
            id,
            created_at,
            ready_at,
            order_items!inner(id)
          ''')
          .eq('vendor_id', vendorId)
          .eq('status', 'delivered')
          .gte('created_at', thirtyDaysAgo.toIso8601String())
          .not('ready_at', 'is', null)
          .limit(100);

      if (response.isEmpty) {
        return VendorPreparationStats.defaultStats(vendorId);
      }

      // Analyze preparation times
      final preparationTimes = <Duration>[];
      final complexityFactors = <int, List<Duration>>{};
      
      for (final orderData in response) {
        final createdAt = DateTime.parse(orderData['created_at']);
        final readyAt = DateTime.parse(orderData['ready_at']);
        final preparationTime = readyAt.difference(createdAt);
        final itemCount = (orderData['order_items'] as List).length;
        
        preparationTimes.add(preparationTime);
        complexityFactors.putIfAbsent(itemCount, () => []).add(preparationTime);
      }
      
      // Calculate statistics
      final avgPreparationTime = _calculateAverageTime(preparationTimes);
      final variance = _calculateVariance(preparationTimes, avgPreparationTime);
      final complexityFactor = _calculateComplexityFactor(complexityFactors);
      final efficiencyScore = _calculateEfficiencyScore(preparationTimes);
      
      final stats = VendorPreparationStats(
        vendorId: vendorId,
        avgPreparationTime: avgPreparationTime,
        preparationTimeVariance: variance,
        orderComplexityFactor: complexityFactor,
        peakHourMultiplier: 1.2, // Default multiplier
        efficiencyScore: efficiencyScore,
        totalOrdersAnalyzed: preparationTimes.length,
        lastUpdated: DateTime.now(),
      );
      
      // Store in database for future use
      await _storeVendorStats(stats);
      
      return stats;
    } catch (e) {
      debugPrint('❌ [PREP-TIME] Error generating vendor stats from history: $e');
      return VendorPreparationStats.defaultStats(vendorId);
    }
  }

  /// Calculate preparation duration for an order
  Duration _calculatePreparationDuration(Order order, VendorPreparationStats stats) {
    // Base preparation time
    var preparationMinutes = stats.avgPreparationTime.inMinutes.toDouble();
    
    // Apply complexity factor based on number of items
    final complexityMultiplier = 1.0 + (order.items.length - 1) * stats.orderComplexityFactor;
    preparationMinutes *= complexityMultiplier;
    
    // Apply peak hour multiplier if during busy hours
    if (_isPeakHour(DateTime.now())) {
      preparationMinutes *= stats.peakHourMultiplier;
    }
    
    // Add variance based on vendor consistency
    final varianceMinutes = stats.preparationTimeVariance.inMinutes * 0.5; // 50% of variance
    preparationMinutes += (Random().nextDouble() - 0.5) * varianceMinutes;
    
    // Ensure minimum preparation time
    preparationMinutes = max(preparationMinutes, 10.0); // Minimum 10 minutes
    
    return Duration(minutes: preparationMinutes.round());
  }

  /// Calculate queue delay based on position and vendor efficiency
  Duration _calculateQueueDelay(int queuePosition, VendorPreparationStats stats) {
    if (queuePosition == 0) return Duration.zero;
    
    // Base delay per position in queue
    final baseDelayMinutes = 5.0; // 5 minutes per position
    
    // Adjust based on vendor efficiency
    final efficiencyAdjustment = 2.0 - stats.efficiencyScore; // Higher efficiency = less delay
    final adjustedDelay = baseDelayMinutes * efficiencyAdjustment;
    
    return Duration(minutes: (adjustedDelay * queuePosition).round());
  }

  /// Calculate confidence score for prediction
  double _calculateConfidenceScore(VendorPreparationStats stats, Order order) {
    double confidence = 0.8; // Base confidence
    
    // Adjust based on data quality
    if (stats.totalOrdersAnalyzed > 50) {
      confidence += 0.1;
    } else if (stats.totalOrdersAnalyzed < 10) {
      confidence -= 0.2;
    }
    
    // Adjust based on vendor consistency (lower variance = higher confidence)
    final varianceHours = stats.preparationTimeVariance.inMinutes / 60.0;
    if (varianceHours < 0.5) {
      confidence += 0.1;
    } else if (varianceHours > 1.0) {
      confidence -= 0.1;
    }
    
    // Adjust based on order complexity
    if (order.items.length > 5) {
      confidence -= 0.05; // More complex orders are harder to predict
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Check if current time is during peak hours
  bool _isPeakHour(DateTime time) {
    final hour = time.hour;
    // Peak hours: 11:30-14:00 (lunch) and 18:00-21:00 (dinner)
    return (hour >= 11 && hour <= 14) || (hour >= 18 && hour <= 21);
  }

  /// Generate fallback predictions when ML prediction fails
  Map<String, PreparationWindow> _generateFallbackPredictions(List<Order> orders) {
    debugPrint('🔄 [PREP-TIME] Using fallback prediction method');
    
    final predictions = <String, PreparationWindow>{};
    DateTime currentTime = DateTime.now();
    
    for (int i = 0; i < orders.length; i++) {
      final order = orders[i];
      
      // Simple fallback: 20 minutes base + 5 minutes per item
      final preparationMinutes = 20 + (order.items.length * 5);
      final preparationDuration = Duration(minutes: preparationMinutes);
      
      final startTime = currentTime.add(Duration(minutes: i * 10)); // 10 min queue delay
      final completionTime = startTime.add(preparationDuration);
      
      predictions[order.id] = PreparationWindow(
        orderId: order.id,
        vendorId: order.vendorId,
        estimatedStartTime: startTime,
        estimatedCompletionTime: completionTime,
        estimatedDuration: preparationDuration,
        confidenceScore: 0.6, // Lower confidence for fallback
        metadata: {
          'prediction_method': 'fallback',
          'order_complexity': order.items.length,
        },
      );
    }
    
    return predictions;
  }

  /// Helper methods for statistical calculations
  Duration _calculateAverageTime(List<Duration> times) {
    if (times.isEmpty) return const Duration(minutes: 25);
    
    final totalMinutes = times.fold<int>(0, (sum, time) => sum + time.inMinutes);
    return Duration(minutes: (totalMinutes / times.length).round());
  }

  Duration _calculateVariance(List<Duration> times, Duration average) {
    if (times.isEmpty) return const Duration(minutes: 10);
    
    final avgMinutes = average.inMinutes;
    final squaredDiffs = times.map((time) {
      final diff = time.inMinutes - avgMinutes;
      return diff * diff;
    });
    
    final variance = squaredDiffs.reduce((a, b) => a + b) / times.length;
    return Duration(minutes: sqrt(variance).round());
  }

  double _calculateComplexityFactor(Map<int, List<Duration>> complexityFactors) {
    if (complexityFactors.length < 2) return 0.1; // Default factor
    
    // Calculate how much preparation time increases per additional item
    final factors = <double>[];
    
    for (int items = 1; items <= 5; items++) {
      if (complexityFactors.containsKey(items) && complexityFactors.containsKey(items + 1)) {
        final avgTimeForItems = _calculateAverageTime(complexityFactors[items]!);
        final avgTimeForMoreItems = _calculateAverageTime(complexityFactors[items + 1]!);
        
        final factor = (avgTimeForMoreItems.inMinutes - avgTimeForItems.inMinutes) / avgTimeForItems.inMinutes;
        factors.add(factor);
      }
    }
    
    if (factors.isEmpty) return 0.1;
    return factors.reduce((a, b) => a + b) / factors.length;
  }

  double _calculateEfficiencyScore(List<Duration> preparationTimes) {
    if (preparationTimes.isEmpty) return 0.8;
    
    // Efficiency based on consistency and speed
    final avgTime = _calculateAverageTime(preparationTimes);
    final variance = _calculateVariance(preparationTimes, avgTime);
    
    // Lower average time and lower variance = higher efficiency
    final speedScore = max(0.0, 1.0 - (avgTime.inMinutes - 20) / 60.0); // Normalize around 20 min
    final consistencyScore = max(0.0, 1.0 - variance.inMinutes / 30.0); // Normalize around 30 min variance
    
    return ((speedScore + consistencyScore) / 2).clamp(0.0, 1.0);
  }

  /// Store vendor statistics in database
  Future<void> _storeVendorStats(VendorPreparationStats stats) async {
    try {
      await _supabase
          .from('order_preparation_analytics')
          .upsert(stats.toJson())
          .eq('vendor_id', stats.vendorId);
    } catch (e) {
      debugPrint('❌ [PREP-TIME] Error storing vendor stats: $e');
    }
  }

  /// Clear cache
  void clearCache() {
    _vendorStatsCache.clear();
    _lastCacheUpdate = null;
  }
}

/// Vendor preparation statistics model
class VendorPreparationStats {
  final String vendorId;
  final Duration avgPreparationTime;
  final Duration preparationTimeVariance;
  final double orderComplexityFactor;
  final double peakHourMultiplier;
  final double efficiencyScore;
  final int totalOrdersAnalyzed;
  final DateTime lastUpdated;

  const VendorPreparationStats({
    required this.vendorId,
    required this.avgPreparationTime,
    required this.preparationTimeVariance,
    required this.orderComplexityFactor,
    required this.peakHourMultiplier,
    required this.efficiencyScore,
    required this.totalOrdersAnalyzed,
    required this.lastUpdated,
  });

  factory VendorPreparationStats.fromJson(Map<String, dynamic> json) {
    return VendorPreparationStats(
      vendorId: json['vendor_id'],
      avgPreparationTime: Duration(minutes: json['avg_preparation_time']),
      preparationTimeVariance: Duration(minutes: json['preparation_time_variance']),
      orderComplexityFactor: json['order_complexity_factor'].toDouble(),
      peakHourMultiplier: json['peak_hour_multiplier'].toDouble(),
      efficiencyScore: json['efficiency_score'].toDouble(),
      totalOrdersAnalyzed: json['total_orders_analyzed'],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor_id': vendorId,
      'avg_preparation_time': avgPreparationTime.inMinutes,
      'preparation_time_variance': preparationTimeVariance.inMinutes,
      'order_complexity_factor': orderComplexityFactor,
      'peak_hour_multiplier': peakHourMultiplier,
      'efficiency_score': efficiencyScore,
      'total_orders_analyzed': totalOrdersAnalyzed,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory VendorPreparationStats.defaultStats(String vendorId) {
    return VendorPreparationStats(
      vendorId: vendorId,
      avgPreparationTime: const Duration(minutes: 25),
      preparationTimeVariance: const Duration(minutes: 10),
      orderComplexityFactor: 0.1,
      peakHourMultiplier: 1.2,
      efficiencyScore: 0.8,
      totalOrdersAnalyzed: 0,
      lastUpdated: DateTime.now(),
    );
  }
}
