import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/route_optimization_models.dart';
import '../../../orders/data/models/order.dart';

/// Enhanced service for predicting vendor preparation times using machine learning and real-time data
/// Phase 3.2 Enhancement: Implements ML-based vendor readiness prediction, historical data analysis,
/// real-time kitchen status integration, and dynamic preparation window calculation for optimal pickup timing
class PreparationTimeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Phase 3.2: Enhanced caching and ML model integration
  final Map<String, VendorPreparationStats> _vendorStatsCache = {};
  final Map<String, KitchenStatusData> _kitchenStatusCache = {};
  final Map<String, MLPredictionModel> _mlModelsCache = {};
  final Duration _cacheExpiry = const Duration(hours: 1);
  final Duration _kitchenStatusExpiry = const Duration(minutes: 5);
  final Duration _mlModelExpiry = const Duration(hours: 6);
  DateTime? _lastCacheUpdate;
  // ignore: unused_field
  DateTime? _lastKitchenStatusUpdate; // TODO: Use for cache invalidation
  // ignore: unused_field
  DateTime? _lastMLModelUpdate; // TODO: Use for ML model refresh

  // Phase 3.2: Real-time kitchen status subscription
  // ignore: unused_field
  RealtimeChannel? _kitchenStatusChannel; // TODO: Use for real-time kitchen updates
  // ignore: unused_field
  final Map<String, StreamController<KitchenStatusUpdate>> _kitchenStatusControllers = {}; // TODO: Use for streaming updates

  /// Enhanced preparation time prediction with ML integration (Phase 3.2)
  /// Combines historical data, real-time kitchen status, and machine learning models
  Future<Map<String, PreparationWindow>> predictPreparationTimes(
    List<Order> orders
  ) async {
    try {
      debugPrint('🕒 [PREP-TIME-3.2] Enhanced ML-based prediction for ${orders.length} orders');

      final predictions = <String, PreparationWindow>{};

      // Group orders by vendor for batch processing
      final ordersByVendor = <String, List<Order>>{};
      for (final order in orders) {
        ordersByVendor.putIfAbsent(order.vendorId, () => []).add(order);
      }

      // Process each vendor's orders with enhanced ML prediction
      for (final entry in ordersByVendor.entries) {
        final vendorId = entry.key;
        final vendorOrders = entry.value;

        final vendorPredictions = await _predictVendorPreparationTimesML(vendorId, vendorOrders);
        predictions.addAll(vendorPredictions);
      }

      debugPrint('✅ [PREP-TIME-3.2] Generated ${predictions.length} ML-enhanced preparation predictions');
      return predictions;
    } catch (e) {
      debugPrint('❌ [PREP-TIME-3.2] Error in enhanced prediction, falling back: $e');
      // Fallback to original method if ML enhancement fails
      return _predictPreparationTimesFallback(orders);
    }
  }

  /// Fallback preparation time prediction using original method
  Future<Map<String, PreparationWindow>> _predictPreparationTimesFallback(
    List<Order> orders
  ) async {
    try {
      debugPrint('🔄 [PREP-TIME-3.2] Using fallback prediction method');

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

      return predictions;
    } catch (e) {
      debugPrint('❌ [PREP-TIME-3.2] Fallback prediction failed: $e');
      return _generateFallbackPredictions(orders);
    }
  }

  /// Enhanced ML-based vendor preparation time prediction (Phase 3.2)
  Future<Map<String, PreparationWindow>> _predictVendorPreparationTimesML(
    String vendorId,
    List<Order> orders,
  ) async {
    try {
      debugPrint('🧠 [PREP-TIME-3.2] ML prediction for vendor $vendorId with ${orders.length} orders');

      // 1. Get vendor preparation statistics
      final vendorStats = await _getVendorPreparationStats(vendorId);

      // 2. Get real-time kitchen status
      final kitchenStatus = await _getKitchenStatus(vendorId);

      // 3. Get ML prediction model
      final mlModel = await _getMLPredictionModel(vendorId);

      final predictions = <String, PreparationWindow>{};
      DateTime currentTime = DateTime.now();

      // Sort orders by complexity and priority
      final sortedOrders = List<Order>.from(orders);
      sortedOrders.sort((a, b) {
        // Primary sort: complexity (item count)
        final complexityCompare = a.items.length.compareTo(b.items.length);
        if (complexityCompare != 0) return complexityCompare;

        // Secondary sort: order priority (if available)
        // For now, use creation time as proxy for priority
        return a.createdAt.compareTo(b.createdAt);
      });

      for (int i = 0; i < sortedOrders.length; i++) {
        final order = sortedOrders[i];

        // Calculate preparation time using ML model if available
        Duration preparationDuration;
        double confidenceScore;

        if (mlModel != null && kitchenStatus != null) {
          preparationDuration = _calculateMLPreparationDuration(
            order, vendorStats, kitchenStatus, mlModel,
          );
          confidenceScore = _calculateMLConfidenceScore(mlModel, kitchenStatus, vendorStats);
        } else {
          // Fallback to enhanced statistical method
          preparationDuration = _calculateEnhancedPreparationDuration(
            order, vendorStats, kitchenStatus,
          );
          confidenceScore = _calculateEnhancedConfidenceScore(vendorStats, kitchenStatus, order);
        }

        // Account for kitchen queue with real-time load
        final queueDelay = _calculateDynamicQueueDelay(i, kitchenStatus, vendorStats);
        final startTime = currentTime.add(queueDelay);
        final completionTime = startTime.add(preparationDuration);

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
            'kitchen_load': kitchenStatus?.kitchenLoad ?? 0.5,
            'staff_count': kitchenStatus?.staffCount ?? 2,
            'busy_level': kitchenStatus?.busyLevel.name ?? 'moderate',
            'prediction_method': mlModel != null ? 'ml_enhanced' : 'statistical_enhanced',
            'ml_model_version': mlModel?.modelVersion,
            'ml_model_accuracy': mlModel?.accuracy,
            'phase': '3.2',
          },
        );

        // Update current time for next order with dynamic overlap
        final overlapFactor = _calculateOverlapFactor(kitchenStatus, vendorStats);
        currentTime = startTime.add(Duration(
          minutes: (preparationDuration.inMinutes * overlapFactor).round(),
        ));
      }

      return predictions;
    } catch (e) {
      debugPrint('❌ [PREP-TIME-3.2] Error in ML vendor prediction: $e');
      // Fallback to original method
      return _predictVendorPreparationTimes(vendorId, orders);
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

  /// Get real-time kitchen status for vendor (Phase 3.2)
  Future<KitchenStatusData?> _getKitchenStatus(String vendorId) async {
    try {
      // Check cache first
      if (_kitchenStatusCache.containsKey(vendorId)) {
        final cachedStatus = _kitchenStatusCache[vendorId]!;
        final cacheAge = DateTime.now().difference(cachedStatus.lastUpdated);
        if (cacheAge < _kitchenStatusExpiry) {
          debugPrint('🏪 [PREP-TIME-3.2] Using cached kitchen status for vendor $vendorId');
          return cachedStatus;
        }
      }

      // Query real-time kitchen status
      final response = await _supabase
          .from('kitchen_status')
          .select('''
            vendor_id,
            current_order_count,
            staff_count,
            kitchen_load,
            average_current_wait_time,
            active_order_ids,
            busy_level,
            equipment_status,
            last_updated
          ''')
          .eq('vendor_id', vendorId)
          .maybeSingle();

      KitchenStatusData? status;
      if (response != null) {
        status = KitchenStatusData.fromJson(response);
        _kitchenStatusCache[vendorId] = status;
        debugPrint('🏪 [PREP-TIME-3.2] Retrieved kitchen status for vendor $vendorId: ${status.busyLevel.name}');
      } else {
        // Generate estimated status from current orders
        status = await _estimateKitchenStatus(vendorId);
        if (status != null) {
          _kitchenStatusCache[vendorId] = status;
        }
      }

      return status;
    } catch (e) {
      debugPrint('❌ [PREP-TIME-3.2] Error getting kitchen status: $e');
      return null;
    }
  }

  /// Get ML prediction model for vendor (Phase 3.2)
  Future<MLPredictionModel?> _getMLPredictionModel(String vendorId) async {
    try {
      // Check cache first
      if (_mlModelsCache.containsKey(vendorId)) {
        final cachedModel = _mlModelsCache[vendorId]!;
        final cacheAge = DateTime.now().difference(cachedModel.trainedAt);
        if (cacheAge < _mlModelExpiry) {
          debugPrint('🧠 [PREP-TIME-3.2] Using cached ML model for vendor $vendorId');
          return cachedModel;
        }
      }

      // Query ML prediction model
      final response = await _supabase
          .from('ml_prediction_models')
          .select('''
            vendor_id,
            model_version,
            feature_weights,
            accuracy,
            training_data_size,
            trained_at,
            hyperparameters,
            feature_names
          ''')
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .order('trained_at', ascending: false)
          .limit(1)
          .maybeSingle();

      MLPredictionModel? model;
      if (response != null) {
        model = MLPredictionModel.fromJson(response);
        _mlModelsCache[vendorId] = model;
        debugPrint('🧠 [PREP-TIME-3.2] Retrieved ML model for vendor $vendorId: v${model.modelVersion} (accuracy: ${model.accuracy.toStringAsFixed(3)})');
      } else {
        debugPrint('🧠 [PREP-TIME-3.2] No ML model found for vendor $vendorId, using statistical fallback');
      }

      return model;
    } catch (e) {
      debugPrint('❌ [PREP-TIME-3.2] Error getting ML model: $e');
      return null;
    }
  }

  /// Estimate kitchen status from current orders when real-time data unavailable
  Future<KitchenStatusData?> _estimateKitchenStatus(String vendorId) async {
    try {
      // Get current active orders for the vendor
      final response = await _supabase
          .from('orders')
          .select('id, created_at, status')
          .eq('vendor_id', vendorId)
          .inFilter('status', ['confirmed', 'preparing', 'ready'])
          .order('created_at', ascending: false);

      final activeOrders = response as List<dynamic>;
      final currentOrderCount = activeOrders.length;
      final activeOrderIds = activeOrders.map((order) => order['id'] as String).toList();

      // Estimate kitchen load based on order count
      final kitchenLoad = (currentOrderCount / 10.0).clamp(0.0, 1.0); // Assume max 10 concurrent orders
      final averageWaitTime = Duration(minutes: (15 + (kitchenLoad * 20)).round()); // 15-35 min based on load

      // Determine busy level
      KitchenBusyLevel busyLevel;
      if (kitchenLoad < 0.3) {
        busyLevel = KitchenBusyLevel.low;
      } else if (kitchenLoad < 0.6) {
        busyLevel = KitchenBusyLevel.moderate;
      } else if (kitchenLoad < 0.8) {
        busyLevel = KitchenBusyLevel.high;
      } else {
        busyLevel = KitchenBusyLevel.critical;
      }

      return KitchenStatusData(
        vendorId: vendorId,
        currentOrderCount: currentOrderCount,
        staffCount: 2, // Default estimate
        kitchenLoad: kitchenLoad,
        averageCurrentWaitTime: averageWaitTime,
        activeOrderIds: activeOrderIds,
        busyLevel: busyLevel,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [PREP-TIME-3.2] Error estimating kitchen status: $e');
      return null;
    }
  }

  /// Calculate preparation duration using ML model (Phase 3.2)
  Duration _calculateMLPreparationDuration(
    Order order,
    VendorPreparationStats stats,
    KitchenStatusData kitchenStatus,
    MLPredictionModel mlModel,
  ) {
    final complexityScore = _calculateOrderComplexityScore(order);
    final isPeakHour = _isPeakHour(DateTime.now());
    final historicalAverage = stats.avgPreparationTime.inMinutes.toDouble();

    final prediction = mlModel.predictPreparationTime(
      itemCount: order.items.length,
      complexityScore: complexityScore,
      kitchenLoad: kitchenStatus.kitchenLoad,
      staffCount: kitchenStatus.staffCount,
      isPeakHour: isPeakHour,
      historicalAverage: historicalAverage,
    );

    debugPrint('🧠 [PREP-TIME-3.2] ML prediction: ${prediction.inMinutes}min (complexity: ${complexityScore.toStringAsFixed(2)}, load: ${kitchenStatus.kitchenLoad.toStringAsFixed(2)})');

    return prediction;
  }

  /// Calculate enhanced preparation duration with kitchen status (Phase 3.2)
  Duration _calculateEnhancedPreparationDuration(
    Order order,
    VendorPreparationStats stats,
    KitchenStatusData? kitchenStatus,
  ) {
    // Base preparation time
    var preparationMinutes = stats.avgPreparationTime.inMinutes.toDouble();

    // Apply complexity factor based on number of items
    final complexityMultiplier = 1.0 + (order.items.length - 1) * stats.orderComplexityFactor;
    preparationMinutes *= complexityMultiplier;

    // Apply peak hour multiplier if during busy hours
    if (_isPeakHour(DateTime.now())) {
      preparationMinutes *= stats.peakHourMultiplier;
    }

    // Apply kitchen load multiplier if available
    if (kitchenStatus != null) {
      preparationMinutes *= kitchenStatus.busyLevel.loadMultiplier;

      // Additional adjustment based on staff count
      final staffMultiplier = 1.0 - ((kitchenStatus.staffCount - 2) * 0.1).clamp(-0.3, 0.3);
      preparationMinutes *= staffMultiplier;
    }

    // Add variance based on vendor consistency
    final varianceMinutes = stats.preparationTimeVariance.inMinutes * 0.5; // 50% of variance
    preparationMinutes += (Random().nextDouble() - 0.5) * varianceMinutes;

    // Ensure minimum preparation time
    preparationMinutes = max(preparationMinutes, 10.0); // Minimum 10 minutes

    return Duration(minutes: preparationMinutes.round());
  }

  /// Calculate order complexity score based on items and customizations
  double _calculateOrderComplexityScore(Order order) {
    double complexity = order.items.length.toDouble();

    // Add complexity for customizations
    for (final item in order.items) {
      if (item.customizations != null && item.customizations!.isNotEmpty) {
        complexity += item.customizations!.length * 0.5;
      }
    }

    // Normalize to 0-1 scale (assuming max 20 items with customizations)
    return (complexity / 20.0).clamp(0.0, 1.0);
  }

  /// Calculate ML confidence score based on model and data quality
  double _calculateMLConfidenceScore(
    MLPredictionModel mlModel,
    KitchenStatusData kitchenStatus,
    VendorPreparationStats stats,
  ) {
    // Base confidence from ML model accuracy
    double confidence = mlModel.accuracy;

    // Adjust based on training data size
    if (mlModel.trainingDataSize < 100) {
      confidence *= 0.8; // Reduce confidence for small training sets
    } else if (mlModel.trainingDataSize > 1000) {
      confidence *= 1.1; // Increase confidence for large training sets
    }

    // Adjust based on kitchen status data freshness
    final statusAge = DateTime.now().difference(kitchenStatus.lastUpdated);
    if (statusAge.inMinutes > 30) {
      confidence *= 0.9; // Reduce confidence for stale data
    }

    // Adjust based on vendor stats quality
    if (stats.totalOrdersAnalyzed < 50) {
      confidence *= 0.85; // Reduce confidence for limited historical data
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// Calculate enhanced confidence score for statistical method
  double _calculateEnhancedConfidenceScore(
    VendorPreparationStats stats,
    KitchenStatusData? kitchenStatus,
    Order order,
  ) {
    // Base confidence from vendor efficiency
    double confidence = stats.efficiencyScore;

    // Adjust based on historical data quality
    if (stats.totalOrdersAnalyzed < 30) {
      confidence *= 0.7;
    } else if (stats.totalOrdersAnalyzed > 200) {
      confidence *= 1.1;
    }

    // Adjust based on kitchen status availability
    if (kitchenStatus != null) {
      confidence *= 1.1; // Boost confidence when real-time data available

      // Adjust based on kitchen load
      if (kitchenStatus.busyLevel == KitchenBusyLevel.critical) {
        confidence *= 0.8; // Reduce confidence during critical load
      }
    } else {
      confidence *= 0.8; // Reduce confidence without real-time data
    }

    // Adjust based on order complexity
    final complexity = _calculateOrderComplexityScore(order);
    if (complexity > 0.7) {
      confidence *= 0.9; // Reduce confidence for complex orders
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// Calculate dynamic queue delay based on kitchen status
  Duration _calculateDynamicQueueDelay(
    int queuePosition,
    KitchenStatusData? kitchenStatus,
    VendorPreparationStats stats,
  ) {
    if (queuePosition == 0) return Duration.zero;

    // Base delay per position
    int baseDelayMinutes = 8; // 8 minutes per position

    // Adjust based on kitchen status
    if (kitchenStatus != null) {
      // Adjust based on busy level
      baseDelayMinutes = (baseDelayMinutes * kitchenStatus.busyLevel.loadMultiplier).round();

      // Adjust based on staff count
      final staffMultiplier = 1.0 - ((kitchenStatus.staffCount - 2) * 0.15).clamp(-0.4, 0.4);
      baseDelayMinutes = (baseDelayMinutes * staffMultiplier).round();
    }

    // Apply vendor efficiency
    baseDelayMinutes = (baseDelayMinutes * (2.0 - stats.efficiencyScore)).round();

    return Duration(minutes: baseDelayMinutes * queuePosition);
  }

  /// Calculate overlap factor for parallel processing
  double _calculateOverlapFactor(
    KitchenStatusData? kitchenStatus,
    VendorPreparationStats stats,
  ) {
    // Base overlap factor (30% parallel processing)
    double overlapFactor = 0.3;

    // Adjust based on kitchen status
    if (kitchenStatus != null) {
      // More staff = more parallel processing
      if (kitchenStatus.staffCount >= 3) {
        overlapFactor = 0.2; // 20% overlap with more staff
      } else if (kitchenStatus.staffCount <= 1) {
        overlapFactor = 0.5; // 50% overlap with limited staff
      }

      // Adjust based on kitchen load
      if (kitchenStatus.busyLevel == KitchenBusyLevel.critical) {
        overlapFactor += 0.1; // Less parallel processing when critical
      }
    }

    // Adjust based on vendor efficiency
    overlapFactor *= (2.0 - stats.efficiencyScore); // More efficient = less overlap needed

    return overlapFactor.clamp(0.1, 0.8);
  }

  /// Clear cache
  void clearCache() {
    _vendorStatsCache.clear();
    _kitchenStatusCache.clear();
    _mlModelsCache.clear();
    _lastCacheUpdate = null;
    _lastKitchenStatusUpdate = null;
    _lastMLModelUpdate = null;
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

/// Phase 3.2: Real-time kitchen status data model
class KitchenStatusData {
  final String vendorId;
  final int currentOrderCount;
  final int staffCount;
  final double kitchenLoad; // 0.0 to 1.0
  final Duration averageCurrentWaitTime;
  final List<String> activeOrderIds;
  final KitchenBusyLevel busyLevel;
  final Map<String, dynamic>? equipmentStatus;
  final DateTime lastUpdated;

  const KitchenStatusData({
    required this.vendorId,
    required this.currentOrderCount,
    required this.staffCount,
    required this.kitchenLoad,
    required this.averageCurrentWaitTime,
    required this.activeOrderIds,
    required this.busyLevel,
    this.equipmentStatus,
    required this.lastUpdated,
  });

  factory KitchenStatusData.fromJson(Map<String, dynamic> json) {
    return KitchenStatusData(
      vendorId: json['vendor_id'],
      currentOrderCount: json['current_order_count'],
      staffCount: json['staff_count'],
      kitchenLoad: json['kitchen_load'].toDouble(),
      averageCurrentWaitTime: Duration(minutes: json['average_current_wait_time']),
      activeOrderIds: List<String>.from(json['active_order_ids'] ?? []),
      busyLevel: KitchenBusyLevel.values.firstWhere(
        (level) => level.name == json['busy_level'],
        orElse: () => KitchenBusyLevel.moderate,
      ),
      equipmentStatus: json['equipment_status'],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor_id': vendorId,
      'current_order_count': currentOrderCount,
      'staff_count': staffCount,
      'kitchen_load': kitchenLoad,
      'average_current_wait_time': averageCurrentWaitTime.inMinutes,
      'active_order_ids': activeOrderIds,
      'busy_level': busyLevel.name,
      'equipment_status': equipmentStatus,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

/// Kitchen busy level enumeration
enum KitchenBusyLevel {
  low,
  moderate,
  high,
  critical;

  String get displayName {
    switch (this) {
      case KitchenBusyLevel.low:
        return 'Low';
      case KitchenBusyLevel.moderate:
        return 'Moderate';
      case KitchenBusyLevel.high:
        return 'High';
      case KitchenBusyLevel.critical:
        return 'Critical';
    }
  }

  double get loadMultiplier {
    switch (this) {
      case KitchenBusyLevel.low:
        return 0.8;
      case KitchenBusyLevel.moderate:
        return 1.0;
      case KitchenBusyLevel.high:
        return 1.3;
      case KitchenBusyLevel.critical:
        return 1.6;
    }
  }
}

/// Phase 3.2: Kitchen status update model for real-time streaming
class KitchenStatusUpdate {
  final String vendorId;
  final String updateType; // 'order_started', 'order_completed', 'staff_change', 'equipment_status'
  final Map<String, dynamic> updateData;
  final DateTime timestamp;

  const KitchenStatusUpdate({
    required this.vendorId,
    required this.updateType,
    required this.updateData,
    required this.timestamp,
  });

  factory KitchenStatusUpdate.fromJson(Map<String, dynamic> json) {
    return KitchenStatusUpdate(
      vendorId: json['vendor_id'],
      updateType: json['update_type'],
      updateData: json['update_data'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor_id': vendorId,
      'update_type': updateType,
      'update_data': updateData,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Phase 3.2: Machine Learning prediction model for preparation times
class MLPredictionModel {
  final String vendorId;
  final String modelVersion;
  final Map<String, double> featureWeights;
  final double accuracy;
  final int trainingDataSize;
  final DateTime trainedAt;
  final Map<String, dynamic> hyperparameters;
  final List<String> featureNames;

  const MLPredictionModel({
    required this.vendorId,
    required this.modelVersion,
    required this.featureWeights,
    required this.accuracy,
    required this.trainingDataSize,
    required this.trainedAt,
    required this.hyperparameters,
    required this.featureNames,
  });

  factory MLPredictionModel.fromJson(Map<String, dynamic> json) {
    return MLPredictionModel(
      vendorId: json['vendor_id'],
      modelVersion: json['model_version'],
      featureWeights: Map<String, double>.from(json['feature_weights']),
      accuracy: json['accuracy'].toDouble(),
      trainingDataSize: json['training_data_size'],
      trainedAt: DateTime.parse(json['trained_at']),
      hyperparameters: json['hyperparameters'],
      featureNames: List<String>.from(json['feature_names']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor_id': vendorId,
      'model_version': modelVersion,
      'feature_weights': featureWeights,
      'accuracy': accuracy,
      'training_data_size': trainingDataSize,
      'trained_at': trainedAt.toIso8601String(),
      'hyperparameters': hyperparameters,
      'feature_names': featureNames,
    };
  }

  /// Predict preparation time using the ML model
  Duration predictPreparationTime({
    required int itemCount,
    required double complexityScore,
    required double kitchenLoad,
    required int staffCount,
    required bool isPeakHour,
    required double historicalAverage,
  }) {
    // Feature vector
    final features = {
      'item_count': itemCount.toDouble(),
      'complexity_score': complexityScore,
      'kitchen_load': kitchenLoad,
      'staff_count': staffCount.toDouble(),
      'is_peak_hour': isPeakHour ? 1.0 : 0.0,
      'historical_average': historicalAverage,
    };

    // Linear combination of features
    double prediction = 0.0;
    for (final featureName in featureNames) {
      final featureValue = features[featureName] ?? 0.0;
      final weight = featureWeights[featureName] ?? 0.0;
      prediction += featureValue * weight;
    }

    // Apply activation function (ReLU) and ensure minimum time
    prediction = prediction.clamp(10.0, 120.0); // 10 min to 2 hours

    return Duration(minutes: prediction.round());
  }
}
