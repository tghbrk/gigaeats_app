import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../providers/driver_map_provider.dart';

/// Driver map screen for navigation and delivery tracking
class DriverMapScreen extends ConsumerStatefulWidget {
  const DriverMapScreen({super.key});

  @override
  ConsumerState<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends ConsumerState<DriverMapScreen> {
  DateTime? _lastCameraMove;
  static const Duration _cameraThrottleDuration = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    // Map initialization is handled by the provider
  }

  @override
  void dispose() {
    // Clean up resources to prevent memory leaks
    _lastCameraMove = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapState = ref.watch(driverMapProvider);
    final mapActions = ref.read(driverMapActionsProvider);

    // Debug information
    debugPrint('🗺️ Map State Debug:');
    debugPrint('  - isLoading: ${mapState.isLoading}');
    debugPrint('  - isLocationEnabled: ${mapState.isLocationEnabled}');
    debugPrint('  - currentLocation: ${mapState.currentLocation}');
    debugPrint('  - error: ${mapState.error}');
    debugPrint('  - isTracking: ${mapState.isTracking}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Map'),
        actions: [
          IconButton(
            icon: Icon(mapState.isTracking ? Icons.location_on : Icons.location_off),
            onPressed: () => _toggleLocationTracking(mapActions),
            tooltip: mapState.isTracking ? 'Stop Tracking' : 'Start Tracking',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () => mapActions.centerOnLocation(),
            tooltip: 'Center on Location',
          ),
          IconButton(
            icon: const Icon(Icons.route),
            onPressed: () => mapActions.centerOnRoute(),
            tooltip: 'Show Route',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Maps
          Container(
            key: const ValueKey('google_maps_container'),
            child: _buildGoogleMap(mapState, mapActions),
          ),

          // Location status overlay
          if (!mapState.isLocationEnabled)
            Container(
              key: const ValueKey('location_disabled_overlay'),
              child: _buildLocationDisabledOverlay(theme),
            ),

          // Loading overlay
          if (mapState.isLoading)
            Container(
              key: const ValueKey('loading_overlay'),
              child: _buildLoadingOverlay(theme),
            ),

          // Error overlay
          if (mapState.error != null)
            Container(
              key: const ValueKey('error_overlay'),
              child: _buildErrorOverlay(theme, mapState.error!),
            ),

          // Active delivery info card
          if (mapState.isTracking && mapState.activeOrder != null)
            Container(
              key: const ValueKey('active_delivery_card'),
              child: _buildActiveDeliveryCard(theme, mapState),
            ),

          // Quick action buttons
          Container(
            key: const ValueKey('quick_action_buttons'),
            child: _buildQuickActionButtons(theme, mapState, mapActions),
          ),

          // Debug info overlay
          Container(
            key: const ValueKey('debug_overlay'),
            child: _buildDebugOverlay(mapState),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMap(DriverMapState mapState, DriverMapActions mapActions) {
    if (mapState.currentLocation == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        debugPrint('🗺️ GoogleMap onMapCreated called');
        mapActions.setMapController(controller);
      },
      initialCameraPosition: CameraPosition(
        target: mapState.currentLocation!,
        zoom: 15.0,
      ),
      markers: mapState.markers,
      polylines: mapState.polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false, // We'll use custom button
      compassEnabled: true,
      trafficEnabled: false, // Disable traffic to reduce buffer usage
      buildingsEnabled: false, // Disable 3D buildings to reduce memory
      mapType: MapType.normal,
      zoomControlsEnabled: false, // We'll use custom controls
      rotateGesturesEnabled: false, // Disable rotation to reduce rendering
      tiltGesturesEnabled: false, // Disable tilt to reduce 3D rendering
      mapToolbarEnabled: false, // Disable map toolbar
      indoorViewEnabled: false, // Disable indoor maps
      liteModeEnabled: false, // Ensure full map mode for better control
      onTap: (LatLng position) {
        debugPrint('🗺️ Map tapped at: $position');
      },
      onCameraMove: (CameraPosition position) {
        // Throttle camera movements to reduce buffer pressure
        _throttleCameraMovement();
      },
      onCameraIdle: () {
        debugPrint('🗺️ Camera movement finished');
      },
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme) {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(ThemeData theme, String error) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Retry initialization
                    ref.invalidate(driverMapProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDisabledOverlay(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_off,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Location Access Required',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please enable location services to use the map and navigation features.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _requestLocationPermission,
                        child: const Text('Enable'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveDeliveryCard(ThemeData theme, DriverMapState mapState) {
    final order = mapState.activeOrder!;

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Active Delivery',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref.read(driverMapActionsProvider).stopTracking();
                    },
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Order #${order.id.substring(0, 8)} - ${order.customerName}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.deliveryAddress.fullAddress,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Distance',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          mapState.routeDistance ?? 'Calculating...',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ETA',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          mapState.routeDuration ?? 'Calculating...',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openNavigation,
                    icon: const Icon(Icons.navigation, size: 16),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons(ThemeData theme, DriverMapState mapState, DriverMapActions mapActions) {
    return Positioned(
      bottom: 100,
      right: 16,
      child: Column(
        children: [
          // Location tracking toggle
          FloatingActionButton(
            heroTag: 'tracking',
            onPressed: () => _toggleLocationTracking(mapActions),
            tooltip: mapState.isTracking ? 'Stop Tracking' : 'Start Tracking',
            backgroundColor: mapState.isTracking ? Colors.orange : Colors.green,
            child: Icon(mapState.isTracking ? Icons.stop : Icons.play_arrow),
          ),
          const SizedBox(height: 12),
          // Navigation
          FloatingActionButton(
            heroTag: 'navigate',
            onPressed: _openNavigation,
            tooltip: 'Open Navigation',
            child: const Icon(Icons.navigation),
          ),
          const SizedBox(height: 12),
          // Call customer
          if (mapState.activeOrder != null)
            FloatingActionButton(
              heroTag: 'call_customer',
              onPressed: _callCustomer,
              tooltip: 'Call Customer',
              backgroundColor: Colors.green,
              child: const Icon(Icons.phone),
            ),
          if (mapState.activeOrder != null) const SizedBox(height: 12),
          // Emergency
          FloatingActionButton(
            heroTag: 'emergency',
            onPressed: _showEmergencyOptions,
            tooltip: 'Emergency',
            backgroundColor: Colors.red,
            child: const Icon(Icons.warning),
          ),
        ],
      ),
    );
  }

  void _toggleLocationTracking(DriverMapActions mapActions) {
    final mapState = ref.read(driverMapProvider);

    if (mapState.isTracking) {
      mapActions.stopTracking();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location tracking stopped'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      mapActions.startTracking();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location tracking started'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _requestLocationPermission() async {
    debugPrint('🚗 Requesting location permission');
    // Reinitialize the map provider to check permissions again
    ref.invalidate(driverMapProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking location permissions...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _throttleCameraMovement() {
    final now = DateTime.now();
    if (_lastCameraMove == null ||
        now.difference(_lastCameraMove!) > _cameraThrottleDuration) {
      _lastCameraMove = now;
      // Allow camera movement processing
    }
    // If called too frequently, ignore to reduce buffer pressure
  }

  void _openNavigation() {
    debugPrint('🚗 Opening navigation');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening navigation app'),
      ),
    );
    // TODO: Open external navigation app
  }

  void _callCustomer() {
    debugPrint('🚗 Calling customer');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calling customer'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Initiate phone call to customer
  }

  void _showEmergencyOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.local_police, color: Colors.blue),
              title: const Text('Call Police (999)'),
              onTap: () {
                Navigator.of(context).pop();
                _callEmergency('999');
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_hospital, color: Colors.red),
              title: const Text('Call Ambulance (999)'),
              onTap: () {
                Navigator.of(context).pop();
                _callEmergency('999');
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.orange),
              title: const Text('Call Support'),
              onTap: () {
                Navigator.of(context).pop();
                _callSupport();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _callEmergency(String number) {
    debugPrint('🚗 Calling emergency: $number');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $number'),
        backgroundColor: Colors.red,
      ),
    );
    // TODO: Initiate emergency call
  }

  void _callSupport() {
    debugPrint('🚗 Calling support');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calling GigaEats support'),
        backgroundColor: Colors.orange,
      ),
    );
    // TODO: Initiate support call
  }



  Widget _buildDebugOverlay(DriverMapState mapState) {
    return Positioned(
      top: 100,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug Info',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              'Loading: ${mapState.isLoading}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              'Location: ${mapState.isLocationEnabled}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              'Position: ${mapState.currentLocation != null ? 'Available' : 'Null'}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            if (mapState.error != null)
              Text(
                'Error: ${mapState.error}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
