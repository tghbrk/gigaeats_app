import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/route_optimization_models.dart';
import '../../data/services/route_optimization_engine.dart';
import '../../data/services/preparation_time_service.dart';
import '../../../orders/data/models/order.dart';

/// Route optimization state
@immutable
class RouteOptimizationState {
  final OptimizedRoute? currentRoute;
  final Map<String, PreparationWindow> preparationWindows;
  final List<RouteEvent> recentEvents;
  final RouteProgress? routeProgress;
  final OptimizationCriteria criteria;
  final bool isOptimizing;
  final bool isReoptimizing;
  final String? error;
  final String? successMessage;

  const RouteOptimizationState({
    this.currentRoute,
    this.preparationWindows = const {},
    this.recentEvents = const [],
    this.routeProgress,
    this.criteria = const OptimizationCriteria(
      distanceWeight: 0.4,
      preparationTimeWeight: 0.3,
      trafficWeight: 0.2,
      deliveryWindowWeight: 0.1,
    ),
    this.isOptimizing = false,
    this.isReoptimizing = false,
    this.error,
    this.successMessage,
  });

  RouteOptimizationState copyWith({
    OptimizedRoute? currentRoute,
    Map<String, PreparationWindow>? preparationWindows,
    List<RouteEvent>? recentEvents,
    RouteProgress? routeProgress,
    OptimizationCriteria? criteria,
    bool? isOptimizing,
    bool? isReoptimizing,
    String? error,
    String? successMessage,
  }) {
    return RouteOptimizationState(
      currentRoute: currentRoute ?? this.currentRoute,
      preparationWindows: preparationWindows ?? this.preparationWindows,
      recentEvents: recentEvents ?? this.recentEvents,
      routeProgress: routeProgress ?? this.routeProgress,
      criteria: criteria ?? this.criteria,
      isOptimizing: isOptimizing ?? this.isOptimizing,
      isReoptimizing: isReoptimizing ?? this.isReoptimizing,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Check if route optimization is available
  bool get hasOptimizedRoute => currentRoute != null;

  /// Get current waypoint based on progress
  RouteWaypoint? get currentWaypoint {
    if (currentRoute == null || routeProgress == null) return null;
    
    final waypoints = currentRoute!.waypoints;
    final currentSequence = routeProgress!.currentWaypointSequence;
    
    final matchingWaypoints = waypoints.where((w) => w.sequence == currentSequence);
    return matchingWaypoints.isNotEmpty ? matchingWaypoints.first : null;
  }

  /// Get next waypoint
  RouteWaypoint? get nextWaypoint {
    if (currentRoute == null || routeProgress == null) return null;
    
    return currentRoute!.getNextWaypoint(routeProgress!.currentWaypointSequence);
  }

  /// Get pickup waypoints only
  List<RouteWaypoint> get pickupWaypoints {
    return currentRoute?.pickupWaypoints ?? [];
  }

  /// Get delivery waypoints only
  List<RouteWaypoint> get deliveryWaypoints {
    return currentRoute?.deliveryWaypoints ?? [];
  }

  /// Get route progress percentage
  double get progressPercentage {
    return routeProgress?.progressPercentage ?? 0.0;
  }

  /// Check if reoptimization is recommended
  bool get shouldReoptimize {
    if (currentRoute == null || recentEvents.isEmpty) return false;
    
    // Check for significant events that warrant reoptimization
    return recentEvents.any((event) {
      switch (event.type) {
        case RouteEventType.trafficIncident:
          final severity = event.data['severity'] as String? ?? 'moderate';
          return severity == 'severe' || severity == 'heavy';
        case RouteEventType.preparationDelay:
          final delayMinutes = event.data['delay_minutes'] as int? ?? 0;
          return delayMinutes > 15;
        default:
          return false;
      }
    });
  }
}

/// Route optimization provider
class RouteOptimizationNotifier extends StateNotifier<RouteOptimizationState> {
  final RouteOptimizationEngine _optimizationEngine = RouteOptimizationEngine();
  final PreparationTimeService _preparationTimeService = PreparationTimeService();
  
  Timer? _reoptimizationTimer;
  Timer? _eventCleanupTimer;

  RouteOptimizationNotifier() : super(const RouteOptimizationState()) {
    _startEventCleanup();
  }

  /// Calculate optimal route for orders
  Future<bool> calculateOptimalRoute({
    required List<Order> orders,
    required LatLng driverLocation,
    OptimizationCriteria? criteria,
  }) async {
    try {
      debugPrint('🔄 [ROUTE-OPT-PROVIDER] Calculating optimal route for ${orders.length} orders');
      
      state = state.copyWith(isOptimizing: true, error: null);

      criteria ??= state.criteria;

      // Get preparation time predictions
      final preparationWindows = await _preparationTimeService.predictPreparationTimes(orders);
      
      // Calculate optimal route
      final optimizedRoute = await _optimizationEngine.calculateOptimalRoute(
        orders: orders,
        driverLocation: driverLocation,
        criteria: criteria,
        preparationWindows: preparationWindows,
      );

      // Initialize route progress
      final routeProgress = RouteProgress(
        routeId: optimizedRoute.id,
        currentWaypointSequence: 1,
        completedWaypoints: [],
        progressPercentage: 0.0,
        lastUpdated: DateTime.now(),
      );

      state = state.copyWith(
        currentRoute: optimizedRoute,
        preparationWindows: preparationWindows,
        routeProgress: routeProgress,
        criteria: criteria,
        isOptimizing: false,
        successMessage: 'Route optimized successfully with ${optimizedRoute.optimizationScoreText} efficiency',
      );

      // Start periodic reoptimization monitoring
      _startReoptimizationMonitoring();

      debugPrint('✅ [ROUTE-OPT-PROVIDER] Route optimization completed with score: ${optimizedRoute.optimizationScoreText}');
      return true;
    } catch (e) {
      debugPrint('❌ [ROUTE-OPT-PROVIDER] Error calculating optimal route: $e');
      state = state.copyWith(
        isOptimizing: false,
        error: 'Failed to calculate optimal route: ${e.toString()}',
      );
      return false;
    }
  }

  /// Update optimization criteria
  Future<void> updateOptimizationCriteria(OptimizationCriteria criteria) async {
    if (!criteria.isValid) {
      state = state.copyWith(error: 'Invalid optimization criteria: weights must sum to 1.0');
      return;
    }

    state = state.copyWith(criteria: criteria);
    debugPrint('⚙️ [ROUTE-OPT-PROVIDER] Optimization criteria updated');

    // If we have a current route, suggest reoptimization
    if (state.currentRoute != null) {
      state = state.copyWith(
        successMessage: 'Optimization criteria updated. Consider reoptimizing route for better results.',
      );
    }
  }

  /// Add route event for reoptimization analysis
  void addRouteEvent(RouteEvent event) {
    debugPrint('📍 [ROUTE-OPT-PROVIDER] Adding route event: ${event.type.displayName}');
    
    final updatedEvents = List<RouteEvent>.from(state.recentEvents);
    updatedEvents.insert(0, event);
    
    // Keep only last 10 events
    if (updatedEvents.length > 10) {
      updatedEvents.removeLast();
    }
    
    state = state.copyWith(recentEvents: updatedEvents);
    
    // Check if immediate reoptimization is needed
    _checkImmediateReoptimization(event);
  }

  /// Update route progress
  void updateRouteProgress({
    required int currentWaypointSequence,
    required List<String> completedWaypoints,
  }) {
    if (state.currentRoute == null) return;

    final totalWaypoints = state.currentRoute!.waypoints.length;
    final progressPercentage = (completedWaypoints.length / totalWaypoints) * 100;

    final updatedProgress = RouteProgress(
      routeId: state.currentRoute!.id,
      currentWaypointSequence: currentWaypointSequence,
      completedWaypoints: completedWaypoints,
      progressPercentage: progressPercentage.clamp(0.0, 100.0),
      lastUpdated: DateTime.now(),
    );

    state = state.copyWith(routeProgress: updatedProgress);
    
    debugPrint('📊 [ROUTE-OPT-PROVIDER] Route progress updated: ${progressPercentage.toStringAsFixed(1)}%');
  }

  /// Complete current waypoint
  void completeWaypoint(String waypointId) {
    if (state.routeProgress == null) return;

    final updatedCompletedWaypoints = List<String>.from(state.routeProgress!.completedWaypoints);
    if (!updatedCompletedWaypoints.contains(waypointId)) {
      updatedCompletedWaypoints.add(waypointId);
    }

    // Find next waypoint sequence
    final currentWaypoint = state.currentRoute?.waypoints.firstWhere(
      (w) => w.id == waypointId,
      orElse: () => state.currentRoute!.waypoints.first,
    );

    final nextSequence = (currentWaypoint?.sequence ?? 0) + 1;

    updateRouteProgress(
      currentWaypointSequence: nextSequence,
      completedWaypoints: updatedCompletedWaypoints,
    );

    // Add waypoint completion event
    addRouteEvent(RouteEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      routeId: state.currentRoute!.id,
      type: RouteEventType.waypointCompleted,
      timestamp: DateTime.now(),
      data: {
        'waypoint_id': waypointId,
        'sequence': currentWaypoint?.sequence ?? 0,
        'type': currentWaypoint?.type.name ?? 'unknown',
      },
    ));
  }

  /// Trigger manual reoptimization
  Future<bool> reoptimizeRoute() async {
    if (state.currentRoute == null || state.routeProgress == null) {
      state = state.copyWith(error: 'No active route to reoptimize');
      return false;
    }

    try {
      debugPrint('🔄 [ROUTE-OPT-PROVIDER] Starting manual reoptimization');
      
      state = state.copyWith(isReoptimizing: true, error: null);

      final routeUpdate = await _optimizationEngine.reoptimizeRoute(
        state.currentRoute!,
        state.routeProgress!,
        state.recentEvents,
      );

      if (routeUpdate != null) {
        // Apply route update
        final currentRoute = state.currentRoute!;
        final updatedRoute = OptimizedRoute(
          id: currentRoute.id,
          batchId: currentRoute.batchId,
          waypoints: routeUpdate.updatedWaypoints,
          totalDistanceKm: currentRoute.totalDistanceKm,
          totalDuration: currentRoute.totalDuration,
          durationInTraffic: currentRoute.durationInTraffic,
          optimizationScore: routeUpdate.newOptimizationScore,
          criteria: currentRoute.criteria,
          calculatedAt: DateTime.now(),
          overallTrafficCondition: currentRoute.overallTrafficCondition,
          metadata: currentRoute.metadata,
        );

        state = state.copyWith(
          currentRoute: updatedRoute,
          isReoptimizing: false,
          successMessage: 'Route reoptimized successfully. Improvement: ${((routeUpdate.newOptimizationScore - state.currentRoute!.optimizationScore) * 100).toStringAsFixed(1)}%',
        );

        debugPrint('✅ [ROUTE-OPT-PROVIDER] Route reoptimized successfully');
        return true;
      } else {
        state = state.copyWith(
          isReoptimizing: false,
          successMessage: 'Current route is already optimal',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ [ROUTE-OPT-PROVIDER] Error reoptimizing route: $e');
      state = state.copyWith(
        isReoptimizing: false,
        error: 'Failed to reoptimize route: ${e.toString()}',
      );
      return false;
    }
  }

  /// Clear current route
  void clearRoute() {
    debugPrint('🗑️ [ROUTE-OPT-PROVIDER] Clearing current route');
    
    _stopReoptimizationMonitoring();
    
    state = state.copyWith(
      currentRoute: null,
      preparationWindows: {},
      recentEvents: [],
      routeProgress: null,
      error: null,
      successMessage: null,
    );
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  /// Start periodic reoptimization monitoring
  void _startReoptimizationMonitoring() {
    _stopReoptimizationMonitoring();
    
    _reoptimizationTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _checkPeriodicReoptimization();
    });
  }

  /// Stop reoptimization monitoring
  void _stopReoptimizationMonitoring() {
    _reoptimizationTimer?.cancel();
    _reoptimizationTimer = null;
  }

  /// Check for immediate reoptimization needs
  void _checkImmediateReoptimization(RouteEvent event) {
    bool shouldReoptimize = false;
    
    switch (event.type) {
      case RouteEventType.trafficIncident:
        final severity = event.data['severity'] as String? ?? 'moderate';
        shouldReoptimize = severity == 'severe';
        break;
      case RouteEventType.preparationDelay:
        final delayMinutes = event.data['delay_minutes'] as int? ?? 0;
        shouldReoptimize = delayMinutes > 30; // Immediate reoptimization for major delays
        break;
      default:
        break;
    }
    
    if (shouldReoptimize) {
      debugPrint('⚡ [ROUTE-OPT-PROVIDER] Triggering immediate reoptimization due to: ${event.type.displayName}');
      // Trigger reoptimization in next frame to avoid state mutation during build
      Future.microtask(() => reoptimizeRoute());
    }
  }

  /// Check for periodic reoptimization
  Future<void> _checkPeriodicReoptimization() async {
    if (state.shouldReoptimize && !state.isReoptimizing) {
      debugPrint('🔄 [ROUTE-OPT-PROVIDER] Triggering periodic reoptimization');
      await reoptimizeRoute();
    }
  }

  /// Start event cleanup timer
  void _startEventCleanup() {
    _eventCleanupTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _cleanupOldEvents();
    });
  }

  /// Clean up old events
  void _cleanupOldEvents() {
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 2));
    final filteredEvents = state.recentEvents
        .where((event) => event.timestamp.isAfter(cutoffTime))
        .toList();
    
    if (filteredEvents.length != state.recentEvents.length) {
      state = state.copyWith(recentEvents: filteredEvents);
      debugPrint('🧹 [ROUTE-OPT-PROVIDER] Cleaned up ${state.recentEvents.length - filteredEvents.length} old events');
    }
  }

  @override
  void dispose() {
    debugPrint('🗑️ [ROUTE-OPT-PROVIDER] Disposing route optimization provider');
    
    _stopReoptimizationMonitoring();
    _eventCleanupTimer?.cancel();
    
    super.dispose();
  }
}

/// Route optimization provider
final routeOptimizationProvider = StateNotifierProvider<RouteOptimizationNotifier, RouteOptimizationState>((ref) {
  return RouteOptimizationNotifier();
});

/// Current optimized route provider
final currentOptimizedRouteProvider = Provider<OptimizedRoute?>((ref) {
  return ref.watch(routeOptimizationProvider).currentRoute;
});

/// Route waypoints provider
final routeWaypointsProvider = Provider<List<RouteWaypoint>>((ref) {
  return ref.watch(routeOptimizationProvider).currentRoute?.waypoints ?? [];
});

/// Current waypoint provider
final currentWaypointProvider = Provider<RouteWaypoint?>((ref) {
  return ref.watch(routeOptimizationProvider).currentWaypoint;
});

/// Next waypoint provider
final nextWaypointProvider = Provider<RouteWaypoint?>((ref) {
  return ref.watch(routeOptimizationProvider).nextWaypoint;
});

/// Pickup waypoints provider
final pickupWaypointsProvider = Provider<List<RouteWaypoint>>((ref) {
  return ref.watch(routeOptimizationProvider).pickupWaypoints;
});

/// Delivery waypoints provider
final deliveryWaypointsProvider = Provider<List<RouteWaypoint>>((ref) {
  return ref.watch(routeOptimizationProvider).deliveryWaypoints;
});

/// Route progress provider
final routeProgressProvider = Provider<RouteProgress?>((ref) {
  return ref.watch(routeOptimizationProvider).routeProgress;
});

/// Route progress percentage provider
final routeProgressPercentageProvider = Provider<double>((ref) {
  return ref.watch(routeOptimizationProvider).progressPercentage;
});

/// Preparation windows provider
final preparationWindowsProvider = Provider<Map<String, PreparationWindow>>((ref) {
  return ref.watch(routeOptimizationProvider).preparationWindows;
});

/// Should reoptimize provider
final shouldReoptimizeProvider = Provider<bool>((ref) {
  return ref.watch(routeOptimizationProvider).shouldReoptimize;
});

/// Optimization criteria provider
final optimizationCriteriaProvider = Provider<OptimizationCriteria>((ref) {
  return ref.watch(routeOptimizationProvider).criteria;
});

/// Route optimization score provider
final routeOptimizationScoreProvider = Provider<double?>((ref) {
  return ref.watch(routeOptimizationProvider).currentRoute?.optimizationScore;
});

/// Route total distance provider
final routeTotalDistanceProvider = Provider<String?>((ref) {
  return ref.watch(routeOptimizationProvider).currentRoute?.totalDistanceText;
});

/// Route total duration provider
final routeTotalDurationProvider = Provider<String?>((ref) {
  return ref.watch(routeOptimizationProvider).currentRoute?.totalDurationText;
});
