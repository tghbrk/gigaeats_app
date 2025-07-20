import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:gigaeats/src/features/drivers/presentation/providers/multi_order_batch_provider.dart';
import 'package:gigaeats/src/features/drivers/presentation/providers/route_optimization_provider.dart';
import 'package:gigaeats/src/features/drivers/presentation/providers/batch_analytics_provider.dart';
import 'package:gigaeats/src/features/drivers/presentation/providers/enhanced_voice_navigation_provider.dart';

/// Mock providers for comprehensive testing
/// Provides controlled state management for testing multi-order workflow components

/// Mock Multi-Order Batch Provider
class MockMultiOrderBatchNotifier extends StateNotifier<MultiOrderBatchState> 
    with Mock implements MultiOrderBatchNotifier {
  MockMultiOrderBatchNotifier() : super(const MultiOrderBatchState());

  @override
  Future<void> initialize() async {
    state = state.copyWith(
      isInitialized: true,
      isLoading: false,
    );
  }

  @override
  Future<void> createBatch({
    required String driverId,
    required List<dynamic> orders,
    int maxOrdersPerBatch = 5,
  }) async {
    state = state.copyWith(isLoading: true);
    
    // Simulate batch creation
    await Future.delayed(const Duration(milliseconds: 100));
    
    final mockBatch = {
      'id': 'mock-batch-${DateTime.now().millisecondsSinceEpoch}',
      'driverId': driverId,
      'orders': orders.take(maxOrdersPerBatch).toList(),
      'status': 'created',
      'createdAt': DateTime.now(),
    };
    
    state = state.copyWith(
      isLoading: false,
      currentBatch: mockBatch,
      batches: [...state.batches, mockBatch],
    );
  }

  @override
  Future<void> updateBatchStatus({
    required String batchId,
    required String status,
  }) async {
    state = state.copyWith(isLoading: true);
    
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (state.currentBatch?['id'] == batchId) {
      final updatedBatch = Map<String, dynamic>.from(state.currentBatch!);
      updatedBatch['status'] = status;
      updatedBatch['updatedAt'] = DateTime.now();
      
      state = state.copyWith(
        isLoading: false,
        currentBatch: updatedBatch,
      );
    }
  }

  @override
  Future<void> completeBatch(String batchId) async {
    await updateBatchStatus(batchId: batchId, status: 'completed');
  }

  @override
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Mock Route Optimization Provider
class MockRouteOptimizationNotifier extends StateNotifier<RouteOptimizationState> 
    with Mock implements RouteOptimizationNotifier {
  MockRouteOptimizationNotifier() : super(const RouteOptimizationState());

  @override
  Future<void> initialize() async {
    state = state.copyWith(
      isInitialized: true,
      isLoading: false,
    );
  }

  @override
  Future<void> optimizeRoute({
    required List<dynamic> orders,
    required Map<String, dynamic> driverLocation,
    Map<String, dynamic>? criteria,
  }) async {
    state = state.copyWith(isLoading: true);
    
    // Simulate route optimization
    await Future.delayed(const Duration(milliseconds: 200));
    
    final mockOptimizedRoute = {
      'id': 'route-${DateTime.now().millisecondsSinceEpoch}',
      'orderSequence': orders.map((o) => o['id']).toList(),
      'waypoints': _generateMockWaypoints(orders),
      'totalDistance': 15.5 + (orders.length * 2.0),
      'totalDuration': Duration(minutes: 30 + (orders.length * 8)),
      'optimizationScore': 0.85,
      'efficiency': 0.92,
      'trafficConditions': {'average': 'moderate'},
      'optimizationMetrics': {
        'distance_priority': criteria?['prioritizeDistance'] ?? false,
        'time_priority': criteria?['prioritizeTime'] ?? false,
        'traffic_priority': criteria?['prioritizeTraffic'] ?? false,
        'traffic_considered': true,
        'traffic_weight': criteria?['trafficWeight'] ?? 0.2,
      },
    };
    
    state = state.copyWith(
      isLoading: false,
      currentRoute: mockOptimizedRoute,
      optimizationHistory: [...state.optimizationHistory, mockOptimizedRoute],
    );
  }

  @override
  Future<void> reoptimizeRoute({
    required Map<String, dynamic> currentRoute,
    required Map<String, dynamic> newDriverLocation,
    required List<String> completedWaypoints,
    Map<String, dynamic>? updatedTrafficConditions,
  }) async {
    state = state.copyWith(isLoading: true);
    
    await Future.delayed(const Duration(milliseconds: 150));
    
    final remainingWaypoints = (currentRoute['waypoints'] as List)
        .where((w) => !completedWaypoints.contains(w['id']))
        .toList();
    
    final reoptimizedRoute = Map<String, dynamic>.from(currentRoute);
    reoptimizedRoute['waypoints'] = remainingWaypoints;
    reoptimizedRoute['totalDistance'] = (currentRoute['totalDistance'] as double) * 0.8;
    reoptimizedRoute['updatedAt'] = DateTime.now();
    
    state = state.copyWith(
      isLoading: false,
      currentRoute: reoptimizedRoute,
    );
  }

  List<Map<String, dynamic>> _generateMockWaypoints(List<dynamic> orders) {
    final waypoints = <Map<String, dynamic>>[];
    
    for (int i = 0; i < orders.length; i++) {
      final order = orders[i];
      
      // Pickup waypoint
      waypoints.add({
        'id': 'pickup-${order['id']}',
        'type': 'pickup',
        'orderId': order['id'],
        'location': {
          'latitude': order['vendorLatitude'],
          'longitude': order['vendorLongitude'],
        },
        'address': order['vendorAddress'],
        'estimatedArrival': DateTime.now().add(Duration(minutes: 15 + (i * 10))),
        'preparationTime': Duration(minutes: order['preparationTimeMinutes'] ?? 20),
      });
      
      // Delivery waypoint
      waypoints.add({
        'id': 'delivery-${order['id']}',
        'type': 'delivery',
        'orderId': order['id'],
        'location': {
          'latitude': order['deliveryLatitude'],
          'longitude': order['deliveryLongitude'],
        },
        'address': order['deliveryAddress'],
        'estimatedArrival': DateTime.now().add(Duration(minutes: 35 + (i * 15))),
        'deliveryWindow': order['deliveryWindowStart'] != null ? {
          'start': order['deliveryWindowStart'],
          'end': order['deliveryWindowEnd'],
        } : null,
      });
    }
    
    return waypoints;
  }

  @override
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Mock Batch Analytics Provider
class MockBatchAnalyticsNotifier extends StateNotifier<BatchAnalyticsState> 
    with Mock implements BatchAnalyticsNotifier {
  MockBatchAnalyticsNotifier() : super(const BatchAnalyticsState());

  @override
  Future<void> initialize() async {
    state = state.copyWith(
      isInitialized: true,
      isLoading: false,
    );
  }

  @override
  Future<void> recordBatchCreation({
    required String batchId,
    required String driverId,
    required int orderCount,
    required double estimatedDistance,
    required Duration estimatedDuration,
    required Map<String, dynamic> optimizationMetrics,
  }) async {
    // Simulate analytics recording
    await Future.delayed(const Duration(milliseconds: 50));
    
    final event = {
      'id': 'event-${DateTime.now().millisecondsSinceEpoch}',
      'type': 'batch_created',
      'batchId': batchId,
      'driverId': driverId,
      'data': {
        'order_count': orderCount,
        'estimated_distance': estimatedDistance,
        'estimated_duration_minutes': estimatedDuration.inMinutes,
        ...optimizationMetrics,
      },
      'timestamp': DateTime.now(),
    };
    
    state = state.copyWith(
      recentEvents: [event, ...state.recentEvents],
    );
  }

  @override
  Future<void> recordBatchCompletion({
    required String batchId,
    required String driverId,
    required Duration actualDuration,
    required double actualDistance,
    required int completedOrders,
    required int totalOrders,
    required List<Duration> orderCompletionTimes,
    required Map<String, dynamic> performanceData,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    
    final event = {
      'id': 'event-${DateTime.now().millisecondsSinceEpoch}',
      'type': 'batch_completed',
      'batchId': batchId,
      'driverId': driverId,
      'data': {
        'actual_duration_minutes': actualDuration.inMinutes,
        'actual_distance': actualDistance,
        'completed_orders': completedOrders,
        'total_orders': totalOrders,
        'completion_rate': completedOrders / totalOrders,
        ...performanceData,
      },
      'timestamp': DateTime.now(),
    };
    
    state = state.copyWith(
      recentEvents: [event, ...state.recentEvents],
    );
  }

  @override
  Future<void> sendBatchAssignmentNotifications({
    required String batchId,
    required String driverId,
    required String driverName,
    required List<dynamic> orders,
  }) async {
    await Future.delayed(const Duration(milliseconds: 30));
    // Mock notification sending - no state change needed
  }

  @override
  Future<void> sendOrderPickedUpNotification({
    required String orderId,
    required String customerId,
    required String driverName,
    required String vendorName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 30));
    // Mock notification sending
  }

  @override
  Future<void> sendOrderDeliveredNotification({
    required String orderId,
    required String customerId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 30));
    // Mock notification sending
  }

  @override
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 100));
    state = state.copyWith(
      isLoading: false,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Mock Enhanced Voice Navigation Provider
class MockEnhancedVoiceNavigationNotifier extends StateNotifier<EnhancedVoiceNavigationState> 
    with Mock implements EnhancedVoiceNavigationNotifier {
  MockEnhancedVoiceNavigationNotifier() : super(const EnhancedVoiceNavigationState());

  @override
  Future<void> initialize({
    String language = 'en-MY',
    double volume = 0.8,
    double speechRate = 0.6,
    double pitch = 1.0,
    bool enableBatteryOptimization = false,
  }) async {
    state = state.copyWith(
      isInitialized: true,
      isEnabled: true,
      currentLanguage: language,
      volume: volume,
      speechRate: speechRate,
      pitch: pitch,
      batteryOptimizationEnabled: enableBatteryOptimization,
    );
  }

  @override
  Future<void> announceInstruction(dynamic instruction) async {
    if (!state.isEnabled) return;
    
    await Future.delayed(const Duration(milliseconds: 50));
    
    final announcement = {
      'instruction': instruction,
      'timestamp': DateTime.now(),
      'language': state.currentLanguage,
    };
    
    state = state.copyWith(
      recentAnnouncements: [announcement, ...state.recentAnnouncements.take(9).toList()],
    );
  }

  @override
  Future<void> announceTrafficAlert(
    String message, {
    dynamic severity,
    bool isUrgent = false,
  }) async {
    if (!state.isEnabled) return;
    
    await Future.delayed(const Duration(milliseconds: 50));
    
    final alert = {
      'message': message,
      'severity': severity?.toString() ?? 'moderate',
      'isUrgent': isUrgent,
      'timestamp': DateTime.now(),
    };
    
    state = state.copyWith(
      recentTrafficAlerts: [alert, ...state.recentTrafficAlerts.take(9).toList()],
    );
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(isEnabled: enabled);
  }

  @override
  Future<void> setLanguage(String language) async {
    state = state.copyWith(currentLanguage: language);
  }

  @override
  Future<void> setVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    state = state.copyWith(volume: clampedVolume);
  }

  @override
  Future<void> setSpeechRate(double speechRate) async {
    final clampedRate = speechRate.clamp(0.1, 2.0);
    state = state.copyWith(speechRate: clampedRate);
  }

  @override
  Future<void> testVoice() async {
    await announceInstruction({
      'text': 'Voice navigation test in ${state.currentLanguage}',
      'type': 'test',
    });
  }

  @override
  void clearError() {
    state = state.copyWith(error: null);
  }
}
