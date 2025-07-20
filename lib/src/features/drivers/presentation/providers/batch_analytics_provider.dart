import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/batch_analytics_service.dart';
import '../../data/services/automated_customer_notification_service.dart';
import '../../data/models/batch_analytics_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Batch analytics provider for Phase 4.2
/// Provides comprehensive analytics and communication features for multi-order delivery batches
final batchAnalyticsProvider = StateNotifierProvider<BatchAnalyticsNotifier, BatchAnalyticsState>((ref) {
  return BatchAnalyticsNotifier(ref);
});

/// Batch analytics state for comprehensive tracking
@immutable
class BatchAnalyticsState {
  final bool isInitialized;
  final bool isLoading;
  final String? error;
  final BatchPerformanceMetrics? currentMetrics;
  final DriverPerformanceInsights? driverInsights;
  final List<BatchDeliveryReport> recentReports;
  final List<AnalyticsEvent> recentEvents;
  final Map<String, dynamic> realTimeData;
  final DateTime? lastUpdated;

  const BatchAnalyticsState({
    this.isInitialized = false,
    this.isLoading = false,
    this.error,
    this.currentMetrics,
    this.driverInsights,
    this.recentReports = const [],
    this.recentEvents = const [],
    this.realTimeData = const {},
    this.lastUpdated,
  });

  BatchAnalyticsState copyWith({
    bool? isInitialized,
    bool? isLoading,
    String? error,
    BatchPerformanceMetrics? currentMetrics,
    DriverPerformanceInsights? driverInsights,
    List<BatchDeliveryReport>? recentReports,
    List<AnalyticsEvent>? recentEvents,
    Map<String, dynamic>? realTimeData,
    DateTime? lastUpdated,
  }) {
    return BatchAnalyticsState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentMetrics: currentMetrics ?? this.currentMetrics,
      driverInsights: driverInsights ?? this.driverInsights,
      recentReports: recentReports ?? this.recentReports,
      recentEvents: recentEvents ?? this.recentEvents,
      realTimeData: realTimeData ?? this.realTimeData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Batch analytics notifier for Phase 4.2
class BatchAnalyticsNotifier extends StateNotifier<BatchAnalyticsState> {
  final Ref _ref;
  final BatchAnalyticsService _analyticsService = BatchAnalyticsService();
  final AutomatedCustomerNotificationService _notificationService = AutomatedCustomerNotificationService();

  BatchAnalyticsNotifier(this._ref) : super(const BatchAnalyticsState());

  /// Initialize analytics and communication services
  Future<void> initialize() async {
    if (state.isInitialized) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('📊 [BATCH-ANALYTICS-PROVIDER] Initializing analytics and communication services');

      // Initialize services
      await _analyticsService.initialize();
      await _notificationService.initialize();

      // Get current user for driver-specific analytics
      final authState = _ref.read(authStateProvider);
      if (authState.user != null) {
        await _startDriverAnalytics(authState.user!.id);
      }

      // Subscribe to real-time updates
      _subscribeToAnalyticsUpdates();

      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      debugPrint('📊 [BATCH-ANALYTICS-PROVIDER] Analytics and communication services initialized successfully');
    } catch (e) {
      debugPrint('❌ [BATCH-ANALYTICS-PROVIDER] Error initializing: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize analytics: ${e.toString()}',
      );
    }
  }

  /// Start driver-specific analytics tracking
  Future<void> _startDriverAnalytics(String driverId) async {
    try {
      await _analyticsService.startDriverAnalytics(driverId);
      await _loadDriverMetrics(driverId);
    } catch (e) {
      debugPrint('❌ [BATCH-ANALYTICS-PROVIDER] Error starting driver analytics: $e');
    }
  }

  /// Subscribe to real-time analytics updates
  void _subscribeToAnalyticsUpdates() {
    // Subscribe to batch metrics updates
    _analyticsService.batchMetricsStream.listen(
      (metrics) {
        state = state.copyWith(
          currentMetrics: metrics,
          lastUpdated: DateTime.now(),
        );
      },
      onError: (error) {
        debugPrint('❌ [BATCH-ANALYTICS-PROVIDER] Batch metrics stream error: $error');
      },
    );

    // Subscribe to driver insights updates
    _analyticsService.driverInsightsStream.listen(
      (insights) {
        state = state.copyWith(
          driverInsights: insights,
          lastUpdated: DateTime.now(),
        );
      },
      onError: (error) {
        debugPrint('❌ [BATCH-ANALYTICS-PROVIDER] Driver insights stream error: $error');
      },
    );
  }

  /// Load driver performance metrics
  Future<void> _loadDriverMetrics(String driverId) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));

      // Load batch performance metrics
      final metrics = await _analyticsService.getBatchPerformanceMetrics(
        driverId: driverId,
        startDate: startDate,
        endDate: endDate,
      );

      // Load driver performance insights
      final insights = await _analyticsService.getDriverPerformanceInsights(
        driverId: driverId,
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(
        currentMetrics: metrics,
        driverInsights: insights,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [BATCH-ANALYTICS-PROVIDER] Error loading driver metrics: $e');
    }
  }

  /// Record batch creation analytics
  Future<void> recordBatchCreation({
    required String batchId,
    required String driverId,
    required int orderCount,
    required double estimatedDistance,
    required Duration estimatedDuration,
    required Map<String, dynamic> optimizationMetrics,
  }) async {
    try {
      await _analyticsService.recordBatchCreation(
        batchId: batchId,
        driverId: driverId,
        orderCount: orderCount,
        estimatedDistance: estimatedDistance,
        estimatedDuration: estimatedDuration,
        optimizationMetrics: optimizationMetrics,
      );

      // Add to recent events
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

      final updatedEvents = [event, ...state.recentEvents];
      if (updatedEvents.length > 50) {
        updatedEvents.removeRange(50, updatedEvents.length);
      }

      state = state.copyWith(
        recentEvents: updatedEvents,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [BATCH-ANALYTICS-PROVIDER] Error recording batch creation: $e');
      state = state.copyWith(
        error: 'Failed to record batch creation: ${e.toString()}',
      );
    }
  }

  /// Record batch completion analytics
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
    try {
      await _analyticsService.recordBatchCompletion(
        batchId: batchId,
        driverId: driverId,
        actualDuration: actualDuration,
        actualDistance: actualDistance,
        completedOrders: completedOrders,
        totalOrders: totalOrders,
        orderCompletionTimes: orderCompletionTimes,
        performanceData: performanceData,
      );

      // Refresh metrics after completion
      await _loadDriverMetrics(driverId);
    } catch (e) {
      debugPrint('❌ [BATCH-ANALYTICS-PROVIDER] Error recording batch completion: $e');
      state = state.copyWith(
        error: 'Failed to record batch completion: ${e.toString()}',
      );
    }
  }

  /// Send automated customer notifications for batch assignment
  Future<void> sendBatchAssignmentNotifications({
    required String batchId,
    required String driverId,
    required String driverName,
    required List<dynamic> orders, // BatchOrderWithDetails
  }) async {
    try {
      await _notificationService.notifyBatchAssignment(
        batchId: batchId,
        driverId: driverId,
        driverName: driverName,
        orders: orders.cast(),
      );

      debugPrint('📱 [BATCH-ANALYTICS-PROVIDER] Batch assignment notifications sent successfully');
    } catch (e) {
      debugPrint('❌ [BATCH-ANALYTICS-PROVIDER] Error sending batch assignment notifications: $e');
      state = state.copyWith(
        error: 'Failed to send notifications: ${e.toString()}',
      );
    }
  }

  /// Send driver en route notifications
  Future<void> sendDriverEnRouteNotifications({
    required String batchId,
    required String driverId,
    required String driverName,
    required List<dynamic> orders,
    required Duration estimatedArrival,
  }) async {
    try {
      await _notificationService.notifyDriverEnRouteToPickup(
        batchId: batchId,
        driverId: driverId,
        driverName: driverName,
        orders: orders.cast(),
        estimatedArrival: estimatedArrival,
      );

      debugPrint('📱 [BATCH-ANALYTICS-PROVIDER] Driver en route notifications sent successfully');
    } catch (e) {
      debugPrint('❌ [BATCH-ANALYTICS-PROVIDER] Error sending driver en route notifications: $e');
      state = state.copyWith(
        error: 'Failed to send notifications: ${e.toString()}',
      );
    }
  }

  /// Send order picked up notification
  Future<void> sendOrderPickedUpNotification({
    required String orderId,
    required String customerId,
    required String driverName,
    required String vendorName,
  }) async {
    try {
      await _notificationService.notifyOrderPickedUp(
        orderId: orderId,
        customerId: customerId,
        driverName: driverName,
        vendorName: vendorName,
      );

      debugPrint('📱 [BATCH-ANALYTICS-PROVIDER] Order picked up notification sent successfully');
    } catch (e) {
      debugPrint('❌ [BATCH-ANALYTICS-PROVIDER] Error sending order picked up notification: $e');
    }
  }

  /// Send order delivered notification
  Future<void> sendOrderDeliveredNotification({
    required String orderId,
    required String customerId,
  }) async {
    try {
      await _notificationService.notifyOrderDelivered(
        orderId: orderId,
        customerId: customerId,
      );

      debugPrint('📱 [BATCH-ANALYTICS-PROVIDER] Order delivered notification sent successfully');
    } catch (e) {
      debugPrint('❌ [BATCH-ANALYTICS-PROVIDER] Error sending order delivered notification: $e');
    }
  }

  /// Send delivery delay notification
  Future<void> sendDeliveryDelayNotification({
    required String orderId,
    required String customerId,
    required Duration delayDuration,
    required String reason,
    required Duration newETA,
  }) async {
    try {
      await _notificationService.notifyDeliveryDelay(
        orderId: orderId,
        customerId: customerId,
        delayDuration: delayDuration,
        reason: reason,
        newETA: newETA,
      );

      debugPrint('📱 [BATCH-ANALYTICS-PROVIDER] Delivery delay notification sent successfully');
    } catch (e) {
      debugPrint('❌ [BATCH-ANALYTICS-PROVIDER] Error sending delivery delay notification: $e');
    }
  }

  /// Refresh analytics data
  Future<void> refresh() async {
    if (!state.isInitialized) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final authState = _ref.read(authStateProvider);
      if (authState.user != null) {
        await _loadDriverMetrics(authState.user!.id);
      }

      state = state.copyWith(
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [BATCH-ANALYTICS-PROVIDER] Error refreshing analytics: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh analytics: ${e.toString()}',
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Dispose resources
  @override
  void dispose() {
    try {
      // Dispose services asynchronously without await since dispose() is not async
      _analyticsService.dispose();
      _notificationService.dispose();
      debugPrint('📊 [BATCH-ANALYTICS-PROVIDER] Analytics provider disposed');
    } catch (e) {
      debugPrint('❌ [BATCH-ANALYTICS-PROVIDER] Error disposing: $e');
    }
    super.dispose();
  }
}
