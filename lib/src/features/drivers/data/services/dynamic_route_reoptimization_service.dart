import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/route_optimization_models.dart';
import '../../../orders/data/models/order.dart';
import 'route_optimization_engine.dart';
import 'preparation_time_service.dart';
import 'driver_realtime_service.dart';

/// Phase 3.3: Dynamic Route Reoptimization Service
/// Implements real-time route reoptimization system that automatically adjusts routes
/// based on traffic changes, preparation delays, customer requests, and unexpected events
class DynamicRouteReoptimizationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final RouteOptimizationEngine _optimizationEngine;
  // ignore: unused_field
  final PreparationTimeService _preparationTimeService; // TODO: Use for advanced preparation time analysis
  final DriverRealtimeService _realtimeService;
  
  // Phase 3.3: Real-time event processing
  final Map<String, dynamic> _eventSubscriptions = {};
  final Map<String, Timer> _reoptimizationTimers = {};
  final Map<String, RouteReoptimizationState> _reoptimizationStates = {};
  
  // Phase 3.3: Event processing configuration
  // ignore: unused_field
  static const Duration _eventProcessingDelay = Duration(seconds: 30); // TODO: Use for event batching
  static const Duration _reoptimizationCooldown = Duration(minutes: 5);
  static const int _maxReoptimizationsPerHour = 6;
  
  // Phase 3.3: Stream controllers for real-time updates
  final StreamController<RouteReoptimizationEvent> _reoptimizationEventController = 
      StreamController.broadcast();
  final StreamController<DriverNotification> _driverNotificationController = 
      StreamController.broadcast();

  DynamicRouteReoptimizationService({
    required RouteOptimizationEngine optimizationEngine,
    required PreparationTimeService preparationTimeService,
    required DriverRealtimeService realtimeService,
  }) : _optimizationEngine = optimizationEngine,
       _preparationTimeService = preparationTimeService,
       _realtimeService = realtimeService;

  /// Stream of route reoptimization events
  Stream<RouteReoptimizationEvent> get reoptimizationEvents => 
      _reoptimizationEventController.stream;

  /// Stream of driver notifications
  Stream<DriverNotification> get driverNotifications => 
      _driverNotificationController.stream;

  /// Initialize dynamic reoptimization for a driver's route (Phase 3.3)
  Future<void> initializeRouteMonitoring({
    required String driverId,
    required String routeId,
    required OptimizedRoute currentRoute,
  }) async {
    try {
      debugPrint('🔄 [REOPT-3.3] Initializing dynamic route monitoring for driver $driverId');
      
      // Initialize reoptimization state
      _reoptimizationStates[routeId] = RouteReoptimizationState(
        routeId: routeId,
        driverId: driverId,
        currentRoute: currentRoute,
        lastReoptimization: DateTime.now(),
        reoptimizationCount: 0,
        isMonitoring: true,
      );
      
      // Subscribe to real-time events
      await _subscribeToRouteEvents(driverId, routeId);
      
      // Start periodic monitoring
      _startPeriodicMonitoring(routeId);
      
      debugPrint('✅ [REOPT-3.3] Dynamic route monitoring initialized for route $routeId');
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error initializing route monitoring: $e');
      rethrow;
    }
  }

  /// Subscribe to real-time route events (Phase 3.3)
  Future<void> _subscribeToRouteEvents(String driverId, String routeId) async {
    try {
      // Subscribe to order status changes
      // ignore: cancel_subscriptions
      final orderStatusSubscription = _realtimeService.orderStatusUpdates.listen(
        (event) => _handleOrderStatusEvent(routeId, event),
      );
      _eventSubscriptions['${routeId}_orders'] = orderStatusSubscription;

      // Subscribe to driver location updates
      // ignore: cancel_subscriptions
      final locationSubscription = _realtimeService.locationUpdates.listen(
        (event) => _handleLocationUpdateEvent(routeId, event),
      );
      _eventSubscriptions['${routeId}_location'] = locationSubscription;
      
      // Subscribe to traffic incidents
      await _subscribeToTrafficEvents(routeId);
      
      // Subscribe to preparation time updates
      await _subscribeToPreparationEvents(routeId);
      
      // Subscribe to customer requests
      await _subscribeToCustomerRequests(routeId);
      
      debugPrint('🔔 [REOPT-3.3] Subscribed to real-time events for route $routeId');
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error subscribing to route events: $e');
    }
  }

  /// Subscribe to traffic incident events
  Future<void> _subscribeToTrafficEvents(String routeId) async {
    try {
      final trafficChannel = _supabase
          .channel('traffic_incidents_$routeId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'traffic_incidents',
            callback: (payload) => _handleTrafficIncidentEvent(routeId, payload),
          )
          .subscribe();

      // Store subscription for cleanup
      _eventSubscriptions['traffic_$routeId'] = trafficChannel;

      debugPrint('🚦 [REOPT-3.3] Subscribed to traffic incidents for route $routeId');
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error subscribing to traffic events: $e');
    }
  }

  /// Subscribe to preparation time update events
  Future<void> _subscribeToPreparationEvents(String routeId) async {
    try {
      final preparationChannel = _supabase
          .channel('preparation_updates_$routeId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'kitchen_status',
            callback: (payload) => _handlePreparationUpdateEvent(routeId, payload),
          )
          .subscribe();

      // Store subscription for cleanup
      _eventSubscriptions['preparation_$routeId'] = preparationChannel;

      debugPrint('🍳 [REOPT-3.3] Subscribed to preparation updates for route $routeId');
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error subscribing to preparation events: $e');
    }
  }

  /// Subscribe to customer request events
  Future<void> _subscribeToCustomerRequests(String routeId) async {
    try {
      final customerChannel = _supabase
          .channel('customer_requests_$routeId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'customer_requests',
            callback: (payload) => _handleCustomerRequestEvent(routeId, payload),
          )
          .subscribe();

      // Store subscription for cleanup
      _eventSubscriptions['customer_$routeId'] = customerChannel;

      debugPrint('👥 [REOPT-3.3] Subscribed to customer requests for route $routeId');
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error subscribing to customer requests: $e');
    }
  }

  /// Start periodic monitoring for route optimization opportunities
  void _startPeriodicMonitoring(String routeId) {
    _reoptimizationTimers[routeId] = Timer.periodic(
      const Duration(minutes: 2),
      (timer) => _performPeriodicCheck(routeId),
    );
    
    debugPrint('⏰ [REOPT-3.3] Started periodic monitoring for route $routeId');
  }

  /// Handle order status change events
  void _handleOrderStatusEvent(String routeId, Map<String, dynamic> event) {
    try {
      final oldStatus = event['old_record']?['status'] as String?;
      final newStatus = event['new_record']?['status'] as String?;
      final orderId = event['new_record']?['id'] as String?;
      
      if (orderId == null || oldStatus == newStatus) return;
      
      debugPrint('📦 [REOPT-3.3] Order status change: $orderId ($oldStatus → $newStatus)');
      
      // Create route event for processing
      final routeEvent = RouteEvent(
        id: 'order_status_${DateTime.now().millisecondsSinceEpoch}',
        routeId: routeId,
        type: _getRouteEventTypeFromOrderStatus(newStatus),
        timestamp: DateTime.now(),
        data: {
          'order_id': orderId,
          'old_status': oldStatus,
          'new_status': newStatus,
          'event_source': 'order_status_change',
        },
      );
      
      _processRouteEvent(routeEvent);
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error handling order status event: $e');
    }
  }

  /// Handle driver location update events
  void _handleLocationUpdateEvent(String routeId, Map<String, dynamic> event) {
    try {
      final latitude = event['latitude'] as double?;
      final longitude = event['longitude'] as double?;
      final timestamp = event['timestamp'] as String?;
      
      if (latitude == null || longitude == null) return;
      
      // Create route event for location-based optimization
      final routeEvent = RouteEvent(
        id: 'location_${DateTime.now().millisecondsSinceEpoch}',
        routeId: routeId,
        type: RouteEventType.driverLocationUpdate,
        timestamp: DateTime.parse(timestamp ?? DateTime.now().toIso8601String()),
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'event_source': 'driver_location_update',
        },
      );
      
      _processRouteEvent(routeEvent);
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error handling location update event: $e');
    }
  }

  /// Handle traffic incident events
  void _handleTrafficIncidentEvent(String routeId, PostgresChangePayload payload) {
    try {
      final incidentData = payload.newRecord;
      final severity = incidentData['severity'] as String? ?? 'moderate';
      final latitude = incidentData['latitude'] as double?;
      final longitude = incidentData['longitude'] as double?;
      final estimatedDelay = incidentData['estimated_delay_minutes'] as int? ?? 0;
      
      debugPrint('🚦 [REOPT-3.3] Traffic incident detected: $severity (${estimatedDelay}min delay)');
      
      final routeEvent = RouteEvent(
        id: 'traffic_${DateTime.now().millisecondsSinceEpoch}',
        routeId: routeId,
        type: RouteEventType.trafficIncident,
        timestamp: DateTime.now(),
        data: {
          'severity': severity,
          'latitude': latitude,
          'longitude': longitude,
          'estimated_delay_minutes': estimatedDelay,
          'incident_id': incidentData['id'],
          'event_source': 'traffic_incident',
        },
      );
      
      _processRouteEvent(routeEvent);
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error handling traffic incident event: $e');
    }
  }

  /// Handle preparation time update events
  void _handlePreparationUpdateEvent(String routeId, PostgresChangePayload payload) {
    try {
      final kitchenData = payload.newRecord;
      final vendorId = kitchenData['vendor_id'] as String?;
      final oldLoad = payload.oldRecord['kitchen_load'] as double? ?? 0.5;
      final newLoad = kitchenData['kitchen_load'] as double? ?? 0.5;
      
      // Only process significant load changes
      if ((newLoad - oldLoad).abs() < 0.2) return;
      
      debugPrint('🍳 [REOPT-3.3] Kitchen load change: $vendorId (${oldLoad.toStringAsFixed(2)} → ${newLoad.toStringAsFixed(2)})');
      
      final routeEvent = RouteEvent(
        id: 'prep_${DateTime.now().millisecondsSinceEpoch}',
        routeId: routeId,
        type: RouteEventType.preparationDelay,
        timestamp: DateTime.now(),
        data: {
          'vendor_id': vendorId,
          'old_kitchen_load': oldLoad,
          'new_kitchen_load': newLoad,
          'load_change': newLoad - oldLoad,
          'event_source': 'kitchen_status_update',
        },
      );
      
      _processRouteEvent(routeEvent);
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error handling preparation update event: $e');
    }
  }

  /// Handle customer request events
  void _handleCustomerRequestEvent(String routeId, PostgresChangePayload payload) {
    try {
      final requestData = payload.newRecord;
      final requestType = requestData['request_type'] as String?;
      final orderId = requestData['order_id'] as String?;
      final urgency = requestData['urgency'] as String? ?? 'normal';
      
      debugPrint('👥 [REOPT-3.3] Customer request: $requestType for order $orderId (urgency: $urgency)');
      
      final routeEvent = RouteEvent(
        id: 'customer_${DateTime.now().millisecondsSinceEpoch}',
        routeId: routeId,
        type: _getRouteEventTypeFromCustomerRequest(requestType),
        timestamp: DateTime.now(),
        data: {
          'request_type': requestType,
          'order_id': orderId,
          'urgency': urgency,
          'request_id': requestData['id'],
          'event_source': 'customer_request',
        },
      );
      
      _processRouteEvent(routeEvent);
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error handling customer request event: $e');
    }
  }

  /// Process route event and determine if reoptimization is needed (Phase 3.3)
  Future<void> _processRouteEvent(RouteEvent event) async {
    try {
      final state = _reoptimizationStates[event.routeId];
      if (state == null || !state.isMonitoring) return;

      debugPrint('🔄 [REOPT-3.3] Processing route event: ${event.type.displayName}');

      // Analyze event impact and determine reoptimization need
      final reoptimizationAnalysis = await _analyzeReoptimizationNeed(event, state);

      if (reoptimizationAnalysis.isRecommended) {
        await _executeReoptimization(event, state, reoptimizationAnalysis);
      } else {
        debugPrint('📊 [REOPT-3.3] Event does not warrant reoptimization: ${reoptimizationAnalysis.reason}');
      }

      // Emit reoptimization event for monitoring
      _reoptimizationEventController.add(RouteReoptimizationEvent(
        routeId: event.routeId,
        triggerEvent: event,
        analysis: reoptimizationAnalysis,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error processing route event: $e');
    }
  }

  /// Analyze if reoptimization is needed based on event (Phase 3.3)
  Future<ReoptimizationAnalysis> _analyzeReoptimizationNeed(
    RouteEvent event,
    RouteReoptimizationState state,
  ) async {
    try {
      // Check reoptimization cooldown
      final timeSinceLastReopt = DateTime.now().difference(state.lastReoptimization);
      if (timeSinceLastReopt < _reoptimizationCooldown) {
        return ReoptimizationAnalysis(
          isRecommended: false,
          reason: 'Reoptimization cooldown active (${_reoptimizationCooldown.inMinutes}min)',
          confidence: 0.0,
          estimatedTimeSaving: Duration.zero,
          priority: ReoptimizationPriority.low,
        );
      }

      // Check hourly reoptimization limit
      if (state.reoptimizationCount >= _maxReoptimizationsPerHour) {
        return ReoptimizationAnalysis(
          isRecommended: false,
          reason: 'Maximum reoptimizations per hour reached ($_maxReoptimizationsPerHour)',
          confidence: 0.0,
          estimatedTimeSaving: Duration.zero,
          priority: ReoptimizationPriority.low,
        );
      }

      // Analyze event-specific impact
      switch (event.type) {
        case RouteEventType.trafficIncident:
          return await _analyzeTrafficIncidentImpact(event, state);
        case RouteEventType.preparationDelay:
          return await _analyzePreparationDelayImpact(event, state);
        case RouteEventType.orderReady:
          return await _analyzeOrderReadyImpact(event, state);
        case RouteEventType.driverLocationUpdate:
          return await _analyzeLocationUpdateImpact(event, state);
        default:
          return ReoptimizationAnalysis(
            isRecommended: false,
            reason: 'Event type not configured for reoptimization',
            confidence: 0.0,
            estimatedTimeSaving: Duration.zero,
            priority: ReoptimizationPriority.low,
          );
      }
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error analyzing reoptimization need: $e');
      return ReoptimizationAnalysis(
        isRecommended: false,
        reason: 'Analysis error: $e',
        confidence: 0.0,
        estimatedTimeSaving: Duration.zero,
        priority: ReoptimizationPriority.low,
      );
    }
  }

  /// Analyze traffic incident impact on route
  Future<ReoptimizationAnalysis> _analyzeTrafficIncidentImpact(
    RouteEvent event,
    RouteReoptimizationState state,
  ) async {
    final severity = event.data['severity'] as String? ?? 'moderate';
    final estimatedDelay = event.data['estimated_delay_minutes'] as int? ?? 0;
    final incidentLat = event.data['latitude'] as double?;
    final incidentLng = event.data['longitude'] as double?;

    // Calculate impact on current route
    double routeImpact = 0.0;
    if (incidentLat != null && incidentLng != null) {
      routeImpact = await _calculateRouteImpact(
        LatLng(incidentLat, incidentLng),
        state.currentRoute,
      );
    }

    // Determine if reoptimization is beneficial
    bool isRecommended = false;
    ReoptimizationPriority priority = ReoptimizationPriority.low;
    double confidence = 0.0;
    Duration estimatedSaving = Duration.zero;

    if (severity == 'severe' && estimatedDelay > 20 && routeImpact > 0.7) {
      isRecommended = true;
      priority = ReoptimizationPriority.high;
      confidence = 0.9;
      estimatedSaving = Duration(minutes: (estimatedDelay * 0.6).round());
    } else if (severity == 'heavy' && estimatedDelay > 15 && routeImpact > 0.5) {
      isRecommended = true;
      priority = ReoptimizationPriority.medium;
      confidence = 0.7;
      estimatedSaving = Duration(minutes: (estimatedDelay * 0.4).round());
    } else if (estimatedDelay > 30 && routeImpact > 0.3) {
      isRecommended = true;
      priority = ReoptimizationPriority.medium;
      confidence = 0.6;
      estimatedSaving = Duration(minutes: (estimatedDelay * 0.3).round());
    }

    return ReoptimizationAnalysis(
      isRecommended: isRecommended,
      reason: isRecommended
          ? 'Traffic incident ($severity) with ${estimatedDelay}min delay affects route (${(routeImpact * 100).toStringAsFixed(1)}% impact)'
          : 'Traffic incident impact insufficient for reoptimization',
      confidence: confidence,
      estimatedTimeSaving: estimatedSaving,
      priority: priority,
      metadata: {
        'incident_severity': severity,
        'estimated_delay_minutes': estimatedDelay,
        'route_impact_score': routeImpact,
      },
    );
  }

  /// Analyze preparation delay impact on route
  Future<ReoptimizationAnalysis> _analyzePreparationDelayImpact(
    RouteEvent event,
    RouteReoptimizationState state,
  ) async {
    final vendorId = event.data['vendor_id'] as String?;
    final loadChange = event.data['load_change'] as double? ?? 0.0;
    final newLoad = event.data['new_kitchen_load'] as double? ?? 0.5;

    // Check if this vendor is in the current route
    final affectedOrders = state.currentRoute.waypoints
        .where((wp) => wp.type == WaypointType.pickup)
        .length; // Simplified - would need actual vendor lookup

    if (affectedOrders == 0) {
      return ReoptimizationAnalysis(
        isRecommended: false,
        reason: 'Preparation delay does not affect current route',
        confidence: 0.0,
        estimatedTimeSaving: Duration.zero,
        priority: ReoptimizationPriority.low,
      );
    }

    // Analyze load change impact
    bool isRecommended = false;
    ReoptimizationPriority priority = ReoptimizationPriority.low;
    double confidence = 0.0;
    Duration estimatedSaving = Duration.zero;

    if (loadChange > 0.3 && newLoad > 0.8) {
      // Significant load increase - might benefit from resequencing
      isRecommended = true;
      priority = ReoptimizationPriority.medium;
      confidence = 0.6;
      estimatedSaving = Duration(minutes: (loadChange * 20).round());
    } else if (loadChange < -0.3 && newLoad < 0.4) {
      // Significant load decrease - orders might be ready earlier
      isRecommended = true;
      priority = ReoptimizationPriority.low;
      confidence = 0.5;
      estimatedSaving = Duration(minutes: (loadChange.abs() * 15).round());
    }

    return ReoptimizationAnalysis(
      isRecommended: isRecommended,
      reason: isRecommended
          ? 'Kitchen load change (${loadChange.toStringAsFixed(2)}) affects $affectedOrders orders'
          : 'Kitchen load change insufficient for reoptimization',
      confidence: confidence,
      estimatedTimeSaving: estimatedSaving,
      priority: priority,
      metadata: {
        'vendor_id': vendorId,
        'load_change': loadChange,
        'new_kitchen_load': newLoad,
        'affected_orders': affectedOrders,
      },
    );
  }

  /// Analyze order ready impact on route
  Future<ReoptimizationAnalysis> _analyzeOrderReadyImpact(
    RouteEvent event,
    RouteReoptimizationState state,
  ) async {
    final orderId = event.data['order_id'] as String?;
    final newStatus = event.data['new_status'] as String?;

    if (newStatus != 'ready') {
      return ReoptimizationAnalysis(
        isRecommended: false,
        reason: 'Order status change does not indicate readiness',
        confidence: 0.0,
        estimatedTimeSaving: Duration.zero,
        priority: ReoptimizationPriority.low,
      );
    }

    // Check if this order is in current route and not yet picked up
    final orderWaypoint = state.currentRoute.waypoints
        .where((wp) => wp.orderId == orderId && wp.type == WaypointType.pickup)
        .firstOrNull;

    if (orderWaypoint == null) {
      return ReoptimizationAnalysis(
        isRecommended: false,
        reason: 'Ready order not in current route',
        confidence: 0.0,
        estimatedTimeSaving: Duration.zero,
        priority: ReoptimizationPriority.low,
      );
    }

    // Order ready early - might benefit from resequencing
    return ReoptimizationAnalysis(
      isRecommended: true,
      reason: 'Order ready early - resequencing may optimize pickup timing',
      confidence: 0.7,
      estimatedTimeSaving: const Duration(minutes: 8),
      priority: ReoptimizationPriority.medium,
      metadata: {
        'order_id': orderId,
        'waypoint_sequence': orderWaypoint.sequence,
      },
    );
  }

  /// Analyze driver location update impact
  Future<ReoptimizationAnalysis> _analyzeLocationUpdateImpact(
    RouteEvent event,
    RouteReoptimizationState state,
  ) async {
    // Location updates typically don't trigger immediate reoptimization
    // unless there's significant deviation from planned route
    return ReoptimizationAnalysis(
      isRecommended: false,
      reason: 'Location updates processed in periodic monitoring',
      confidence: 0.0,
      estimatedTimeSaving: Duration.zero,
      priority: ReoptimizationPriority.low,
    );
  }

  /// Execute route reoptimization based on analysis (Phase 3.3)
  Future<void> _executeReoptimization(
    RouteEvent event,
    RouteReoptimizationState state,
    ReoptimizationAnalysis analysis,
  ) async {
    try {
      debugPrint('🚀 [REOPT-3.3] Executing reoptimization for route ${state.routeId} (${analysis.priority.displayName} priority)');

      // Get current orders for reoptimization
      final currentOrders = await _getCurrentRouteOrders(state.routeId);
      if (currentOrders.isEmpty) {
        debugPrint('⚠️ [REOPT-3.3] No orders found for route ${state.routeId}');
        return;
      }

      // Perform route reoptimization
      final reoptimizedRoute = await _optimizationEngine.calculateOptimalRoute(
        orders: currentOrders,
        driverLocation: await _getCurrentDriverLocation(state.driverId),
        criteria: OptimizationCriteria.balanced(), // Use balanced criteria for reoptimization
      );

      // Compare with current route to validate improvement
      final improvement = _calculateRouteImprovement(state.currentRoute, reoptimizedRoute);

      if (improvement.isSignificant) {
        // Update route in database
        await _updateRouteInDatabase(state.routeId, reoptimizedRoute);

        // Update state
        _reoptimizationStates[state.routeId] = state.copyWith(
          currentRoute: reoptimizedRoute,
          lastReoptimization: DateTime.now(),
          reoptimizationCount: state.reoptimizationCount + 1,
          recentEventIds: [...state.recentEventIds, event.id].take(10).toList(),
        );

        // Notify driver
        await _notifyDriverOfReoptimization(state.driverId, state.routeId, reoptimizedRoute, improvement);

        debugPrint('✅ [REOPT-3.3] Route reoptimized successfully: ${improvement.timeSaving.inMinutes}min saved, ${improvement.distanceSaving.toStringAsFixed(1)}km reduced');
      } else {
        debugPrint('📊 [REOPT-3.3] Reoptimization did not yield significant improvement');
      }
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error executing reoptimization: $e');
    }
  }

  /// Get current orders for a route
  Future<List<Order>> _getCurrentRouteOrders(String routeId) async {
    try {
      final response = await _supabase
          .from('route_waypoints')
          .select('''
            order_id,
            orders!inner(*)
          ''')
          .eq('route_id', routeId)
          .eq('type', 'pickup')
          .not('order_id', 'is', null);

      final orders = <Order>[];
      for (final item in response) {
        if (item['orders'] != null) {
          orders.add(Order.fromJson(item['orders']));
        }
      }

      return orders;
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error getting current route orders: $e');
      return [];
    }
  }

  /// Get current driver location
  Future<LatLng> _getCurrentDriverLocation(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_locations')
          .select('latitude, longitude')
          .eq('driver_id', driverId)
          .order('updated_at', ascending: false)
          .limit(1)
          .single();

      return LatLng(response['latitude'], response['longitude']);
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error getting driver location: $e');
      // Return default location if not found
      return const LatLng(3.1390, 101.6869); // Kuala Lumpur default
    }
  }

  /// Calculate route improvement metrics
  RouteImprovement _calculateRouteImprovement(
    OptimizedRoute oldRoute,
    OptimizedRoute newRoute,
  ) {
    final timeSaving = oldRoute.totalDuration - newRoute.totalDuration;
    final distanceSaving = oldRoute.totalDistanceKm - newRoute.totalDistanceKm;
    final scoreImprovement = newRoute.optimizationScore - oldRoute.optimizationScore;

    // Consider improvement significant if:
    // - Time saving > 5 minutes OR
    // - Distance saving > 2km OR
    // - Score improvement > 0.1
    final isSignificant = timeSaving.inMinutes > 5 ||
                         distanceSaving > 2.0 ||
                         scoreImprovement > 0.1;

    return RouteImprovement(
      timeSaving: timeSaving,
      distanceSaving: distanceSaving,
      scoreImprovement: scoreImprovement,
      isSignificant: isSignificant,
    );
  }

  /// Update route in database
  Future<void> _updateRouteInDatabase(String routeId, OptimizedRoute newRoute) async {
    try {
      // Update route record
      await _supabase
          .from('optimized_routes')
          .update({
            'total_distance_km': newRoute.totalDistanceKm,
            'total_duration_minutes': newRoute.totalDuration.inMinutes,
            'optimization_score': newRoute.optimizationScore,
            'updated_at': DateTime.now().toIso8601String(),
            'metadata': newRoute.metadata,
          })
          .eq('id', routeId);

      // Update waypoints
      await _updateRouteWaypoints(routeId, newRoute.waypoints);

      debugPrint('💾 [REOPT-3.3] Route updated in database: $routeId');
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error updating route in database: $e');
    }
  }

  /// Update route waypoints in database
  Future<void> _updateRouteWaypoints(String routeId, List<RouteWaypoint> waypoints) async {
    try {
      // Delete existing waypoints
      await _supabase
          .from('route_waypoints')
          .delete()
          .eq('route_id', routeId);

      // Insert new waypoints
      final waypointData = waypoints.map((wp) => {
        'route_id': routeId,
        'sequence_number': wp.sequence,
        'type': wp.type.name,
        'latitude': wp.location.latitude,
        'longitude': wp.location.longitude,
        'order_id': wp.orderId,
        'estimated_arrival': wp.estimatedArrivalTime?.toIso8601String(),
        'estimated_duration_minutes': wp.estimatedDuration?.inMinutes,
        'address': wp.address,
        'distance_from_previous': wp.distanceFromPrevious,
        'metadata': wp.metadata,
      }).toList();

      await _supabase
          .from('route_waypoints')
          .insert(waypointData);

      debugPrint('📍 [REOPT-3.3] Updated ${waypoints.length} waypoints for route $routeId');
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error updating route waypoints: $e');
    }
  }

  /// Notify driver of route reoptimization
  Future<void> _notifyDriverOfReoptimization(
    String driverId,
    String routeId,
    OptimizedRoute newRoute,
    RouteImprovement improvement,
  ) async {
    try {
      final notification = DriverNotification(
        id: 'reopt_${DateTime.now().millisecondsSinceEpoch}',
        driverId: driverId,
        routeId: routeId,
        type: DriverNotificationType.routeReoptimized,
        title: 'Route Optimized',
        message: 'Your route has been optimized to save ${improvement.timeSaving.inMinutes} minutes and ${improvement.distanceSaving.toStringAsFixed(1)}km',
        timestamp: DateTime.now(),
        isUrgent: improvement.timeSaving.inMinutes > 15,
        data: {
          'time_saving_minutes': improvement.timeSaving.inMinutes,
          'distance_saving_km': improvement.distanceSaving,
          'score_improvement': improvement.scoreImprovement,
          'new_total_duration_minutes': newRoute.totalDuration.inMinutes,
          'new_total_distance_km': newRoute.totalDistanceKm,
        },
      );

      // Emit notification
      _driverNotificationController.add(notification);

      // Store notification in database
      await _supabase
          .from('driver_notifications')
          .insert({
            'id': notification.id,
            'driver_id': notification.driverId,
            'route_id': notification.routeId,
            'type': notification.type.name,
            'title': notification.title,
            'message': notification.message,
            'timestamp': notification.timestamp.toIso8601String(),
            'is_urgent': notification.isUrgent,
            'data': notification.data,
            'is_read': false,
          });

      debugPrint('🔔 [REOPT-3.3] Driver notification sent: ${notification.title}');
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error notifying driver: $e');
    }
  }

  /// Perform periodic monitoring check
  Future<void> _performPeriodicCheck(String routeId) async {
    try {
      final state = _reoptimizationStates[routeId];
      if (state == null || !state.isMonitoring) return;

      // Check for route optimization opportunities
      // This could include checking for traffic updates, preparation time changes, etc.
      debugPrint('⏰ [REOPT-3.3] Performing periodic check for route $routeId');

      // For now, this is a placeholder for future periodic optimization logic
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error in periodic check: $e');
    }
  }

  /// Get route event type from order status
  RouteEventType _getRouteEventTypeFromOrderStatus(String? status) {
    switch (status) {
      case 'ready':
        return RouteEventType.orderReady;
      case 'preparing':
        return RouteEventType.preparationDelay;
      default:
        return RouteEventType.waypointCompleted;
    }
  }

  /// Get route event type from customer request
  RouteEventType _getRouteEventTypeFromCustomerRequest(String? requestType) {
    switch (requestType) {
      case 'urgent_delivery':
      case 'change_address':
      case 'cancel_order':
        return RouteEventType.orderReady; // Treat as high priority
      default:
        return RouteEventType.waypointCompleted;
    }
  }

  /// Calculate route impact score for traffic incidents
  Future<double> _calculateRouteImpact(LatLng incidentLocation, OptimizedRoute route) async {
    // Simplified impact calculation based on proximity to route waypoints
    double maxImpact = 0.0;

    for (final waypoint in route.waypoints) {
      final distance = _calculateDistance(incidentLocation, waypoint.location);
      // Impact decreases with distance (within 5km radius)
      final impact = (5.0 - distance).clamp(0.0, 5.0) / 5.0;
      maxImpact = maxImpact > impact ? maxImpact : impact;
    }

    return maxImpact;
  }

  /// Calculate distance between two points (simplified)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final lat1Rad = point1.latitude * (pi / 180);
    final lat2Rad = point2.latitude * (pi / 180);
    final deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    final deltaLngRad = (point2.longitude - point1.longitude) * (pi / 180);

    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Stop monitoring for a route
  Future<void> stopRouteMonitoring(String routeId) async {
    try {
      debugPrint('🛑 [REOPT-3.3] Stopping route monitoring for $routeId');

      // Cancel subscriptions
      _eventSubscriptions['${routeId}_orders']?.cancel();
      _eventSubscriptions['${routeId}_location']?.cancel();
      _eventSubscriptions.removeWhere((key, _) => key.startsWith(routeId));

      // Cancel timers
      _reoptimizationTimers[routeId]?.cancel();
      _reoptimizationTimers.remove(routeId);

      // Update state
      final state = _reoptimizationStates[routeId];
      if (state != null) {
        _reoptimizationStates[routeId] = state.copyWith(isMonitoring: false);
      }

      debugPrint('✅ [REOPT-3.3] Route monitoring stopped for $routeId');
    } catch (e) {
      debugPrint('❌ [REOPT-3.3] Error stopping route monitoring: $e');
    }
  }

  /// Dispose of all resources
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _eventSubscriptions.values) {
      subscription.cancel();
    }
    _eventSubscriptions.clear();

    // Cancel all timers
    for (final timer in _reoptimizationTimers.values) {
      timer.cancel();
    }
    _reoptimizationTimers.clear();

    // Close stream controllers
    _reoptimizationEventController.close();
    _driverNotificationController.close();

    // Clear states
    _reoptimizationStates.clear();

    debugPrint('🧹 [REOPT-3.3] Dynamic route reoptimization service disposed');
  }
}
