import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/services/enhanced_route_service.dart';

/// Widget that displays a route preview map with origin, destination, and route polyline
class RoutePreviewMap extends StatefulWidget {
  final DetailedRouteInfo routeInfo;
  final double height;
  final bool showControls;

  const RoutePreviewMap({
    super.key,
    required this.routeInfo,
    this.height = 200,
    this.showControls = false,
  });

  @override
  State<RoutePreviewMap> createState() => _RoutePreviewMapState();
}

class _RoutePreviewMapState extends State<RoutePreviewMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _setupMapData();
  }

  @override
  void didUpdateWidget(RoutePreviewMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeInfo != widget.routeInfo) {
      _setupMapData();
    }
  }

  void _setupMapData() {
    _createMarkers();
    _createPolylines();
  }

  void _createMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('origin'),
        position: widget.routeInfo.origin,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(
          title: 'Start',
          snippet: 'Your current location',
        ),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.routeInfo.destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(
          title: 'Destination',
          snippet: 'Your delivery destination',
        ),
      ),
    };
  }

  void _createPolylines() {
    if (widget.routeInfo.polylinePoints.isNotEmpty) {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: widget.routeInfo.polylinePoints,
          color: Colors.blue,
          width: 4,
          patterns: [],
        ),
      };
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitMapToRoute();
  }

  void _fitMapToRoute() {
    if (_mapController == null || widget.routeInfo.polylinePoints.isEmpty) return;

    // Calculate bounds that include all route points
    double minLat = widget.routeInfo.polylinePoints.first.latitude;
    double maxLat = widget.routeInfo.polylinePoints.first.latitude;
    double minLng = widget.routeInfo.polylinePoints.first.longitude;
    double maxLng = widget.routeInfo.polylinePoints.first.longitude;

    for (final point in widget.routeInfo.polylinePoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    // Add padding to bounds
    const padding = 0.01; // Approximately 1km padding
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: widget.routeInfo.origin,
                zoom: 12,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: widget.showControls,
              scrollGesturesEnabled: widget.showControls,
              zoomGesturesEnabled: widget.showControls,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              trafficEnabled: false,
              buildingsEnabled: false,
              indoorViewEnabled: false,
              liteModeEnabled: !widget.showControls, // Use lite mode for preview
            ),
            
            // Route info overlay
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.route,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.routeInfo.distanceText} • ${widget.routeInfo.durationText}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Traffic condition indicator
            if (widget.routeInfo.trafficCondition != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTrafficColor(widget.routeInfo.trafficCondition!).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.traffic,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.routeInfo.trafficCondition!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Tap overlay for non-interactive maps
            if (!widget.showControls)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Show full-screen map or enable interactions
                      _showFullScreenMap(context);
                    },
                    child: Container(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getTrafficColor(String trafficCondition) {
    switch (trafficCondition.toLowerCase()) {
      case 'light traffic':
        return Colors.green;
      case 'moderate traffic':
        return Colors.orange;
      case 'heavy traffic':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showFullScreenMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Route Preview'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: RoutePreviewMap(
            routeInfo: widget.routeInfo,
            height: double.infinity,
            showControls: true,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
