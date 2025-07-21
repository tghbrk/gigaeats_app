import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/presentation/providers/multi_order_batch_provider.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/route_optimization_provider.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/batch_analytics_provider.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/enhanced_voice_navigation_provider.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/voice_navigation_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/route_optimization_models.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/batch_analytics_models.dart';
import 'package:gigaeats_app/src/features/orders/data/models/order.dart';

/// Mock providers for comprehensive testing
/// Provides controlled state management for testing multi-order workflow components

/// Mock Multi-Order Batch Provider
class MockMultiOrderBatchNotifier extends StateNotifier<MultiOrderBatchState>
    with Mock implements MultiOrderBatchNotifier {
  MockMultiOrderBatchNotifier() : super(const MultiOrderBatchState());

  @override
  Future<void> loadActiveBatch(String driverId) async {
    state = state.copyWith(isLoading: true);

    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 100));

    state = state.copyWith(
      isLoading: false,
      activeBatch: null, // No active batch for testing
    );
  }

  @override
  Future<bool> createOptimizedBatch({
    required String driverId,
    required List<String> orderIds,
    int maxOrders = 3,
    double maxDeviationKm = 5.0,
  }) async {
    state = state.copyWith(isLoading: true);

    // Simulate batch creation
    await Future.delayed(const Duration(milliseconds: 100));

    state = state.copyWith(
      isLoading: false,
      successMessage: 'Mock batch created successfully',
    );

    return true;
  }

  @override
  Future<bool> startBatch() async {
    state = state.copyWith(isLoading: true);

    await Future.delayed(const Duration(milliseconds: 50));

    state = state.copyWith(
      isLoading: false,
      successMessage: 'Mock batch started',
    );

    return true;
  }

  @override
  Future<bool> completeBatch() async {
    state = state.copyWith(isLoading: true);

    await Future.delayed(const Duration(milliseconds: 50));

    state = state.copyWith(
      isLoading: false,
      successMessage: 'Mock batch completed',
    );

    return true;
  }

  @override
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }
}

/// Mock Route Optimization Provider
class MockRouteOptimizationNotifier extends StateNotifier<RouteOptimizationState> 
    with Mock implements RouteOptimizationNotifier {
  MockRouteOptimizationNotifier() : super(const RouteOptimizationState());

  @override
  Future<bool> calculateOptimalRoute({
    required List<Order> orders,
    required LatLng driverLocation,
    OptimizationCriteria? criteria,
  }) async {
    state = state.copyWith(isOptimizing: true);

    // Simulate route optimization
    await Future.delayed(const Duration(milliseconds: 200));

    state = state.copyWith(
      isOptimizing: false,
      successMessage: 'Mock route optimized successfully',
    );

    return true;
  }

  @override
  Future<void> updateOptimizationCriteria(OptimizationCriteria criteria) async {
    state = state.copyWith(criteria: criteria);
  }

  @override
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  @override
  Future<bool> reoptimizeRoute() async {
    state = state.copyWith(isReoptimizing: true);

    await Future.delayed(const Duration(milliseconds: 150));

    state = state.copyWith(
      isReoptimizing: false,
      successMessage: 'Mock route reoptimized successfully',
    );

    return true;
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
    
    final event = AnalyticsEvent.batchCreated(
      driverId: driverId,
      batchId: batchId,
      data: {
        'order_count': orderCount,
        'estimated_distance': estimatedDistance,
        'estimated_duration_minutes': estimatedDuration.inMinutes,
        ...optimizationMetrics,
      },
    );
    
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
    
    final event = AnalyticsEvent(
      eventId: 'event-${DateTime.now().millisecondsSinceEpoch}',
      eventType: 'batch_completed',
      driverId: driverId,
      batchId: batchId,
      data: {
        'actual_duration_minutes': actualDuration.inMinutes,
        'actual_distance': actualDistance,
        'completed_orders': completedOrders,
        'total_orders': totalOrders,
        'completion_rate': completedOrders / totalOrders,
        ...performanceData,
      },
      timestamp: DateTime.now(),
    );
    
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

    // Update state tracking
    state = state.copyWith(
      consecutiveAnnouncementCount: state.consecutiveAnnouncementCount + 1,
      lastAnnouncementTime: DateTime.now(),
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
    
    final alert = TrafficAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      severity: severity ?? TrafficSeverity.moderate,
      timestamp: DateTime.now(),
      isUrgent: isUrgent,
      wasAnnounced: true,
    );

    state = state.copyWith(
      recentTrafficAlerts: [alert, ...state.recentTrafficAlerts.take(9)],
    );
  }

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

  void clearError() {
    state = state.copyWith(error: null);
  }
}
