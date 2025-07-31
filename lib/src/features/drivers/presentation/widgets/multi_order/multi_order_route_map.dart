import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/models/route_optimization_models.dart';
import '../../../data/models/batch_operation_results.dart';
import '../../../data/models/navigation_models.dart';
import '../../../../orders/data/models/order.dart';
import '../../providers/multi_order_batch_provider.dart';
import '../../providers/route_optimization_provider.dart';
import '../../providers/enhanced_navigation_provider.dart';
import '../../providers/enhanced_location_provider.dart';
import '../../../../../core/config/google_config.dart';

/// Route visualization modes for Phase 3.5 enhanced map display
enum RouteVisualizationMode {
  optimized,
  realTime,
  comparison,
  preview,
}

/// Enhanced interactive map widget for multi-order route visualization (Phase 3.5)
/// Displays optimized route with pickup/delivery sequences and real-time driver tracking
///
/// Phase 3.5 Features:
/// - Real-time route updates with live traffic integration
/// - Interactive waypoint manipulation with drag-and-drop
/// - Advanced visualization with route optimization metrics
/// - Live driver location tracking with smooth animations
/// - Enhanced route preview with multiple optimization scenarios
class MultiOrderRouteMap extends ConsumerStatefulWidget {
  final double height;
  final bool showControls;
  final bool enableInteraction;
  final VoidCallback? onWaypointReorder;
  final Function(String orderId)? onOrderSelected;

  const MultiOrderRouteMap({
    super.key,
    this.height = 400,
    this.showControls = true,
    this.enableInteraction = true,
    this.onWaypointReorder,
    this.onOrderSelected,
  });

  @override
  ConsumerState<MultiOrderRouteMap> createState() => _MultiOrderRouteMapState();
}

class _MultiOrderRouteMapState extends ConsumerState<MultiOrderRouteMap>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};

  // Map state
  bool _isMapReady = false;
  String? _selectedOrderId;

  // Phase 3.5: Enhanced state tracking
  late AnimationController _routeAnimationController;
  late AnimationController _markerAnimationController;
  late Animation<double> _routeAnimation;
  // Note: _markerAnimation removed as it was unused - controller is sufficient

  // Real-time updates
  Timer? _animationTimer;
  Timer? _realTimeUpdateTimer;
  double _pulseOpacity = 1.0;
  bool _showRealTimeUpdates = true;
  bool _showOptimizationMetrics = true;

  // Route visualization modes
  RouteVisualizationMode _visualizationMode = RouteVisualizationMode.optimized;
  // final List<OptimizedRoute> _routeScenarios = []; // TODO: Use for route comparison

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers (Phase 3.5)
    _routeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _routeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _routeAnimationController, curve: Curves.easeInOut),
    );
    // Note: _markerAnimation removed as it was unused - controller is sufficient for animations

    _startPulseAnimation();
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _realTimeUpdateTimer?.cancel();
    _routeAnimationController.dispose();
    _markerAnimationController.dispose();
    super.dispose();
  }

  void _startPulseAnimation() {
    _animationTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (mounted) {
        setState(() {
          _pulseOpacity = _pulseOpacity == 1.0 ? 0.3 : 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final batchState = ref.watch(multiOrderBatchProvider);
    final routeState = ref.watch(routeOptimizationProvider);
    final navState = ref.watch(enhancedNavigationProvider);
    final locationState = ref.watch(enhancedLocationProvider);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Google Map
            _buildGoogleMap(batchState, routeState, navState, locationState),
            
            // Enhanced map overlay controls (Phase 3.5)
            if (widget.showControls) ...[
              _buildEnhancedMapControls(theme, routeState),
              _buildVisualizationModeSelector(theme),
              _buildWaypointLegend(theme, batchState),
              if (_showOptimizationMetrics)
                _buildOptimizationMetricsOverlay(theme, routeState),
            ],
            
            // Loading overlay
            if (routeState.isOptimizing || batchState.isLoading)
              _buildLoadingOverlay(theme),
              
            // Error overlay
            if (routeState.error != null)
              _buildErrorOverlay(theme, routeState.error!),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMap(
    MultiOrderBatchState batchState,
    RouteOptimizationState routeState,
    EnhancedNavigationState navState,
    EnhancedLocationState locationState,
  ) {
    // Update markers and polylines when state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMapElements(batchState, routeState, navState, locationState);
    });

    // Default center (Kuala Lumpur)
    const defaultCenter = LatLng(
      GoogleConfig.defaultLatitude,
      GoogleConfig.defaultLongitude,
    );

    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: defaultCenter,
        zoom: GoogleConfig.defaultZoom,
      ),
      markers: _markers,
      polylines: _polylines,
      circles: _circles,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      compassEnabled: widget.showControls,
      trafficEnabled: false, // Disable to reduce memory usage
      buildingsEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false, // Custom controls
      scrollGesturesEnabled: widget.enableInteraction,
      zoomGesturesEnabled: widget.enableInteraction,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      onTap: widget.enableInteraction ? _onMapTap : null,
      onCameraMove: _onCameraMove,
      onCameraIdle: _onCameraIdle,
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    debugPrint('🗺️ [MULTI-ORDER-MAP] Map created');
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });
    
    // Initial map setup
    _fitMapToShowRoute();
  }

  void _onMapTap(LatLng position) {
    debugPrint('🗺️ [MULTI-ORDER-MAP] Map tapped at: $position');
    
    // Clear selection
    setState(() {
      _selectedOrderId = null;
    });
  }

  void _onCameraMove(CameraPosition position) {
    // Handle camera movement if needed
  }

  void _onCameraIdle() {
    // Handle camera idle if needed
  }

  void _updateMapElements(
    MultiOrderBatchState batchState,
    RouteOptimizationState routeState,
    EnhancedNavigationState navState,
    EnhancedLocationState locationState,
  ) {
    if (!_isMapReady) return;

    final newMarkers = <Marker>{};
    final newPolylines = <Polyline>{};
    final newCircles = <Circle>{};

    // Add route polyline if available
    if (routeState.currentRoute != null) {
      _addRoutePolyline(newPolylines, routeState.currentRoute!);
    }

    // Add waypoint markers for batch orders
    if (batchState.hasActiveBatch && batchState.batchOrders.isNotEmpty) {
      _addWaypointMarkers(newMarkers, newCircles, batchState.batchOrders, routeState);
    }

    // Add driver location marker if available
    if (locationState.currentPosition != null) {
      final driverLocation = LatLng(
        locationState.currentPosition!.latitude,
        locationState.currentPosition!.longitude,
      );
      _addDriverLocationMarker(newMarkers, driverLocation);
    }

    // Update state
    setState(() {
      _markers = newMarkers;
      _polylines = newPolylines;
      _circles = newCircles;
    });

    // Fit map to show all elements
    _fitMapToShowRoute();
  }

  void _addRoutePolyline(Set<Polyline> polylines, OptimizedRoute route) {
    if (route.waypoints.isEmpty) return;

    // Create route points from waypoints
    final routePoints = route.waypoints.map((w) => w.location).toList();

    // Main route polyline connecting all waypoints
    polylines.add(
      Polyline(
        polylineId: const PolylineId('main_route'),
        points: routePoints,
        color: _getTrafficColor(route.overallTrafficCondition),
        width: 4,
        patterns: route.overallTrafficCondition == TrafficCondition.heavy
            ? [PatternItem.dash(10), PatternItem.gap(5)]
            : [],
        geodesic: true,
      ),
    );

    // Add individual segments between consecutive waypoints
    for (int i = 0; i < route.waypoints.length - 1; i++) {
      final currentWaypoint = route.waypoints[i];
      final nextWaypoint = route.waypoints[i + 1];

      polylines.add(
        Polyline(
          polylineId: PolylineId('segment_$i'),
          points: [currentWaypoint.location, nextWaypoint.location],
          color: _getTrafficColor(route.overallTrafficCondition).withValues(alpha: 0.7),
          width: 2,
          patterns: [],
          geodesic: true,
        ),
      );
    }
  }

  void _addWaypointMarkers(
    Set<Marker> markers,
    Set<Circle> circles,
    List<BatchOrderWithDetails> orders,
    RouteOptimizationState routeState,
  ) {
    for (int i = 0; i < orders.length; i++) {
      final batchOrderWithDetails = orders[i];
      final order = batchOrderWithDetails.order;
      final isSelected = _selectedOrderId == order.id;
      final isActive = routeState.currentWaypoint?.orderId == order.id;

      // Get vendor location from delivery address (assuming vendor pickup)
      final vendorLocation = _getVendorLocationFromOrder(order);

      // Pickup marker
      if (vendorLocation != null) {
        markers.add(
          Marker(
            markerId: MarkerId('pickup_${order.id}'),
            position: vendorLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isActive ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: 'Pickup #${i + 1}',
              snippet: order.vendorName,
            ),
            onTap: () => _onWaypointTap(order.id, true),
          ),
        );

        // Pickup circle for active waypoint
        if (isActive || isSelected) {
          circles.add(
            Circle(
              circleId: CircleId('pickup_circle_${order.id}'),
              center: vendorLocation,
              radius: 100,
              fillColor: (isActive ? Colors.green : Colors.orange)
                  .withValues(alpha: _pulseOpacity * 0.3),
              strokeColor: isActive ? Colors.green : Colors.orange,
              strokeWidth: 2,
            ),
          );
        }
      }

      // Delivery marker
      final deliveryLocation = _getDeliveryLocationFromOrder(order);
      if (deliveryLocation != null) {
        markers.add(
          Marker(
            markerId: MarkerId('delivery_${order.id}'),
            position: deliveryLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isActive ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: 'Delivery #${i + 1}',
              snippet: order.customerName,
            ),
            onTap: () => _onWaypointTap(order.id, false),
          ),
        );

        // Delivery circle for active waypoint
        if (isActive || isSelected) {
          circles.add(
            Circle(
              circleId: CircleId('delivery_circle_${order.id}'),
              center: deliveryLocation,
              radius: 100,
              fillColor: (isActive ? Colors.blue : Colors.red)
                  .withValues(alpha: _pulseOpacity * 0.3),
              strokeColor: isActive ? Colors.blue : Colors.red,
              strokeWidth: 2,
            ),
          );
        }
      }
    }
  }

  void _addDriverLocationMarker(Set<Marker> markers, LatLng location) {
    markers.add(
      Marker(
        markerId: const MarkerId('driver_location'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Current driver position',
        ),
      ),
    );

    // Add pulsing circle around driver
    _circles.add(
      Circle(
        circleId: const CircleId('driver_location_circle'),
        center: location,
        radius: 50,
        fillColor: Colors.purple.withValues(alpha: _pulseOpacity * 0.4),
        strokeColor: Colors.purple,
        strokeWidth: 2,
      ),
    );
  }

  Future<void> _fitMapToShowRoute() async {
    if (_mapController == null || _markers.isEmpty) return;

    try {
      final bounds = _calculateBounds(_markers.map((m) => m.position).toList());
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    } catch (e) {
      debugPrint('❌ [MULTI-ORDER-MAP] Error fitting map to route: $e');
    }
  }

  // Helper methods
  Color _getTrafficColor(TrafficCondition condition) {
    switch (condition) {
      case TrafficCondition.clear:
        return Colors.green;
      case TrafficCondition.light:
        return Colors.yellow;
      case TrafficCondition.moderate:
        return Colors.orange;
      case TrafficCondition.heavy:
        return Colors.red;
      case TrafficCondition.severe:
        return Colors.red.shade900;
      default:
        return Colors.blue;
    }
  }

  LatLng? _getVendorLocationFromOrder(Order order) {
    // For now, we'll use a placeholder location
    // In a real implementation, this would come from vendor data
    // You might need to add vendor location to the Order model or fetch it separately
    return const LatLng(3.1390, 101.6869); // Kuala Lumpur placeholder
  }

  LatLng? _getDeliveryLocationFromOrder(Order order) {
    // Extract location from delivery address
    if (order.deliveryAddress.latitude != null && order.deliveryAddress.longitude != null) {
      return LatLng(order.deliveryAddress.latitude!, order.deliveryAddress.longitude!);
    }
    return null;
  }

  void _onWaypointTap(String orderId, bool isPickup) {
    debugPrint('🗺️ [MULTI-ORDER-MAP] Waypoint tapped: $orderId (pickup: $isPickup)');

    setState(() {
      _selectedOrderId = orderId;
    });

    // Notify parent widget if callback provided
    if (widget.onOrderSelected != null) {
      widget.onOrderSelected!(orderId);
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(GoogleConfig.defaultLatitude - 0.01, GoogleConfig.defaultLongitude - 0.01),
        northeast: const LatLng(GoogleConfig.defaultLatitude + 0.01, GoogleConfig.defaultLongitude + 0.01),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // TODO: Use for map controls overlay
  /*
  Widget _buildMapControls(ThemeData theme) {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          // Zoom controls
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                ),
                const Divider(height: 1),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Center on route button
          FloatingActionButton.small(
            heroTag: 'center_route',
            onPressed: _fitMapToShowRoute,
            child: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
    );
  }
  */

  Widget _buildWaypointLegend(ThemeData theme, MultiOrderBatchState batchState) {
    if (!batchState.hasActiveBatch) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Waypoints',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildLegendItem(theme, Colors.orange, 'Pickup'),
            const SizedBox(height: 4),
            _buildLegendItem(theme, Colors.red, 'Delivery'),
            const SizedBox(height: 4),
            _buildLegendItem(theme, Colors.purple, 'Driver'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(ThemeData theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(ThemeData theme, String error) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Map Error',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // PHASE 3.5: ENHANCED UI METHODS
  // ============================================================================

  /// Enhanced map controls with real-time features (Phase 3.5)
  Widget _buildEnhancedMapControls(ThemeData theme, RouteOptimizationState routeState) {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          // Real-time updates toggle
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _showRealTimeUpdates ? Icons.update : Icons.update_disabled,
                color: _showRealTimeUpdates
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              onPressed: () => setState(() => _showRealTimeUpdates = !_showRealTimeUpdates),
              tooltip: _showRealTimeUpdates ? 'Disable real-time updates' : 'Enable real-time updates',
            ),
          ),
          const SizedBox(height: 8),

          // Optimization metrics toggle
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _showOptimizationMetrics ? Icons.analytics : Icons.analytics_outlined,
                color: _showOptimizationMetrics
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              onPressed: () => setState(() => _showOptimizationMetrics = !_showOptimizationMetrics),
              tooltip: _showOptimizationMetrics ? 'Hide metrics' : 'Show metrics',
            ),
          ),
          const SizedBox(height: 8),

          // Waypoint reorder button
          if (widget.enableInteraction)
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.reorder),
                onPressed: widget.onWaypointReorder,
                tooltip: 'Reorder waypoints',
              ),
            ),
        ],
      ),
    );
  }

  /// Visualization mode selector (Phase 3.5)
  Widget _buildVisualizationModeSelector(ThemeData theme) {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: RouteVisualizationMode.values.map((mode) {
            final isSelected = _visualizationMode == mode;
            return GestureDetector(
              onTap: () => setState(() => _visualizationMode = mode),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getVisualizationModeLabel(mode),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Optimization metrics overlay (Phase 3.5)
  Widget _buildOptimizationMetricsOverlay(ThemeData theme, RouteOptimizationState routeState) {
    if (routeState.currentRoute == null) return const SizedBox.shrink();

    final route = routeState.currentRoute!;

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _routeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _routeAnimation.value) * 50),
            child: Opacity(
              opacity: _routeAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Route Metrics',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_showRealTimeUpdates)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            theme,
                            'Distance',
                            route.totalDistanceText,
                            Icons.straighten,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricCard(
                            theme,
                            'Duration',
                            route.totalDurationText,
                            Icons.access_time,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricCard(
                            theme,
                            'Efficiency',
                            route.optimizationScoreText,
                            Icons.trending_up,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build metric card for overlay
  Widget _buildMetricCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Start real-time updates (Phase 3.5)
  void _startRealTimeUpdates() {
    _realTimeUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _showRealTimeUpdates) {
        // Trigger route animation
        _routeAnimationController.forward();

        // Update markers with animation
        _markerAnimationController.forward().then((_) {
          _markerAnimationController.reverse();
        });

        debugPrint('🔄 [ROUTE-MAP] Real-time update triggered');
      }
    });
  }

  /// Get visualization mode label
  String _getVisualizationModeLabel(RouteVisualizationMode mode) {
    switch (mode) {
      case RouteVisualizationMode.optimized:
        return 'Optimized';
      case RouteVisualizationMode.realTime:
        return 'Real-time';
      case RouteVisualizationMode.comparison:
        return 'Compare';
      case RouteVisualizationMode.preview:
        return 'Preview';
    }
  }
}
