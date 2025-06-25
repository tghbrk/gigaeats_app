import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../data/models/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/driver_order.dart';

import '../../data/services/route_service.dart';
import 'driver_orders_provider.dart';

/// Map state for driver map screen
class DriverMapState {
  final GoogleMapController? mapController;
  final LatLng? currentLocation;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final bool isLocationEnabled;
  final bool isTracking;
  final DriverOrder? activeOrder;
  final LatLng? pickupLocation;
  final LatLng? deliveryLocation;
  final String? routeDistance;
  final String? routeDuration;
  final bool isLoading;
  final String? error;

  const DriverMapState({
    this.mapController,
    this.currentLocation,
    this.markers = const {},
    this.polylines = const {},
    this.isLocationEnabled = false,
    this.isTracking = false,
    this.activeOrder,
    this.pickupLocation,
    this.deliveryLocation,
    this.routeDistance,
    this.routeDuration,
    this.isLoading = false,
    this.error,
  });

  DriverMapState copyWith({
    GoogleMapController? mapController,
    LatLng? currentLocation,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    bool? isLocationEnabled,
    bool? isTracking,
    DriverOrder? activeOrder,
    LatLng? pickupLocation,
    LatLng? deliveryLocation,
    String? routeDistance,
    String? routeDuration,
    bool? isLoading,
    String? error,
  }) {
    return DriverMapState(
      mapController: mapController ?? this.mapController,
      currentLocation: currentLocation ?? this.currentLocation,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      isLocationEnabled: isLocationEnabled ?? this.isLocationEnabled,
      isTracking: isTracking ?? this.isTracking,
      activeOrder: activeOrder ?? this.activeOrder,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      routeDistance: routeDistance ?? this.routeDistance,
      routeDuration: routeDuration ?? this.routeDuration,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Driver map state notifier
class DriverMapNotifier extends StateNotifier<DriverMapState> {
  final Ref _ref;
  Timer? _locationUpdateTimer;
  StreamSubscription<Position>? _locationSubscription;

  DriverMapNotifier(this._ref) : super(const DriverMapState()) {
    _initializeMap();
  }

  /// Initialize map and check permissions
  Future<void> _initializeMap() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Check location permissions
      final isEnabled = await _checkLocationPermissions();
      state = state.copyWith(
        isLocationEnabled: isEnabled,
        isLoading: false,
      );

      if (isEnabled) {
        await _getCurrentLocation();
        await _loadActiveOrder();
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to initialize map: $e',
        isLoading: false,
      );
    }
  }

  /// Check and request location permissions
  Future<bool> _checkLocationPermissions() async {
    try {
      debugPrint('🗺️ Checking location permissions...');

      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('🗺️ Initial permission status: $permission');

      if (permission == LocationPermission.denied) {
        debugPrint('🗺️ Permission denied, requesting...');
        permission = await Geolocator.requestPermission();
        debugPrint('🗺️ Permission after request: $permission');
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('🗺️ Permission denied forever');
        return false;
      }

      final isEnabled = permission == LocationPermission.whileInUse ||
                       permission == LocationPermission.always;
      debugPrint('🗺️ Location permissions enabled: $isEnabled');

      // Also check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('🗺️ Location services enabled: $serviceEnabled');

      return isEnabled && serviceEnabled;
    } catch (e) {
      debugPrint('🗺️ Error checking location permissions: $e');
      return false;
    }
  }

  /// Get current location
  Future<void> _getCurrentLocation() async {
    try {
      debugPrint('🗺️ Attempting to get current location...');

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );

      debugPrint('🗺️ Location obtained: ${position.latitude}, ${position.longitude}');
      final currentLocation = LatLng(position.latitude, position.longitude);
      state = state.copyWith(currentLocation: currentLocation);

      await _updateMarkers();
    } catch (e) {
      debugPrint('🗺️ Error getting current location: $e');

      // Fallback to Kuala Lumpur center for testing
      debugPrint('🗺️ Using fallback location (Kuala Lumpur)');
      final fallbackLocation = const LatLng(3.1390, 101.6869); // Kuala Lumpur center
      state = state.copyWith(
        currentLocation: fallbackLocation,
        error: 'Using fallback location: $e',
      );

      await _updateMarkers();
    }
  }

  /// Load active order and set up route
  Future<void> _loadActiveOrder() async {
    try {
      final authState = _ref.read(authStateProvider);
      if (authState.user?.role != UserRole.driver) return;

      final activeOrders = _ref.read(activeDriverOrdersProvider);

      if (activeOrders.isNotEmpty) {
        final activeOrder = activeOrders.first;
        state = state.copyWith(activeOrder: activeOrder);

        // For now, we'll use mock coordinates since the DriverOrder model
        // doesn't have lat/lng fields yet. In production, you'd geocode the addresses
        // or store coordinates in the database

        // Mock pickup location (vendor location)
        state = state.copyWith(
          pickupLocation: const LatLng(3.1390, 101.6869), // Kuala Lumpur center
        );

        // Mock delivery location
        state = state.copyWith(
          deliveryLocation: const LatLng(3.1478, 101.6953), // Slightly offset
        );

        await _updateMarkers();
        await _calculateRoute();
      }
    } catch (e) {
      debugPrint('Error loading active order: $e');
    }
  }

  /// Update map markers with memory optimization
  Future<void> _updateMarkers() async {
    // Clear existing markers to prevent memory buildup
    final markers = <Marker>{};

    // Only add markers if we have valid locations to reduce memory usage
    if (state.currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: state.currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Only add pickup marker if we have an active order
    if (state.pickupLocation != null && state.activeOrder != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup_location'),
          position: state.pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: state.activeOrder?.vendorAddress ?? '',
          ),
        ),
      );
    }

    // Only add delivery marker if we have an active order
    if (state.deliveryLocation != null && state.activeOrder != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('delivery_location'),
          position: state.deliveryLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Delivery Location',
            snippet: state.activeOrder?.deliveryAddress ?? '',
          ),
        ),
      );
    }

    // Update state only if markers have changed to prevent unnecessary rebuilds
    if (markers.length != state.markers.length) {
      state = state.copyWith(markers: markers);
    }
  }

  /// Calculate route between locations
  Future<void> _calculateRoute() async {
    if (state.currentLocation != null && state.deliveryLocation != null) {
      try {
        // Calculate route using RouteService
        final routeInfo = await RouteService.calculateRoute(
          origin: state.currentLocation!,
          destination: state.deliveryLocation!,
        );

        if (routeInfo != null) {
          final polylines = <Polyline>{
            Polyline(
              polylineId: const PolylineId('route'),
              points: routeInfo.polylinePoints,
              color: const Color(0xFF2196F3),
              width: 5,
            ),
          };

          state = state.copyWith(
            polylines: polylines,
            routeDistance: routeInfo.distanceText,
            routeDuration: routeInfo.durationText,
          );
        } else {
          // Fallback to simple route
          final polylines = <Polyline>{
            Polyline(
              polylineId: const PolylineId('route'),
              points: [state.currentLocation!, state.deliveryLocation!],
              color: const Color(0xFF2196F3),
              width: 5,
            ),
          };

          state = state.copyWith(
            polylines: polylines,
            routeDistance: 'Calculating...',
            routeDuration: 'Calculating...',
          );
        }
      } catch (e) {
        debugPrint('Error calculating route: $e');
      }
    }
  }

  /// Set map controller
  void setMapController(GoogleMapController controller) {
    state = state.copyWith(mapController: controller);
  }

  /// Start location tracking
  Future<void> startLocationTracking() async {
    if (!state.isLocationEnabled) {
      await _initializeMap();
      return;
    }

    try {
      final locationService = _ref.read(driverLocationServiceProvider);
      final authState = _ref.read(authStateProvider);
      
      if (authState.user?.id == null) return;
      
      final success = await locationService.startLocationTracking(
        authState.user!.id,
        state.activeOrder?.id ?? '',
        intervalSeconds: 15, // Update every 15 seconds
      );
      
      if (success) {
        state = state.copyWith(isTracking: true);
        _startLocationUpdates();
      }
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      state = state.copyWith(error: 'Failed to start location tracking');
    }
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    try {
      final locationService = _ref.read(driverLocationServiceProvider);
      await locationService.stopLocationTracking();
      
      _locationUpdateTimer?.cancel();
      _locationSubscription?.cancel();
      
      state = state.copyWith(isTracking: false);
    } catch (e) {
      debugPrint('Error stopping location tracking: $e');
    }
  }

  /// Start periodic location updates
  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _getCurrentLocation();
    });

    // Listen to location stream with optimized settings to reduce buffer pressure
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium, // Use medium instead of high
        distanceFilter: 20, // Update every 20 meters instead of 10
        timeLimit: Duration(seconds: 10), // Add time limit
      ),
    ).listen((position) {
      final newLocation = LatLng(position.latitude, position.longitude);
      state = state.copyWith(currentLocation: newLocation);
      _updateMarkers();
    });
  }

  /// Center map on current location
  Future<void> centerOnCurrentLocation() async {
    if (state.mapController != null && state.currentLocation != null) {
      await state.mapController!.animateCamera(
        CameraUpdate.newLatLng(state.currentLocation!),
      );
    }
  }

  /// Center map on route
  Future<void> centerOnRoute() async {
    if (state.mapController != null && 
        state.currentLocation != null && 
        state.deliveryLocation != null) {
      
      final bounds = LatLngBounds(
        southwest: LatLng(
          state.currentLocation!.latitude < state.deliveryLocation!.latitude
              ? state.currentLocation!.latitude
              : state.deliveryLocation!.latitude,
          state.currentLocation!.longitude < state.deliveryLocation!.longitude
              ? state.currentLocation!.longitude
              : state.deliveryLocation!.longitude,
        ),
        northeast: LatLng(
          state.currentLocation!.latitude > state.deliveryLocation!.latitude
              ? state.currentLocation!.latitude
              : state.deliveryLocation!.latitude,
          state.currentLocation!.longitude > state.deliveryLocation!.longitude
              ? state.currentLocation!.longitude
              : state.deliveryLocation!.longitude,
        ),
      );
      
      await state.mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for driver map state
final driverMapProvider = StateNotifierProvider<DriverMapNotifier, DriverMapState>((ref) {
  return DriverMapNotifier(ref);
});

/// Provider for map actions
final driverMapActionsProvider = Provider<DriverMapActions>((ref) {
  return DriverMapActions(ref);
});

/// Driver map actions class
class DriverMapActions {
  final Ref _ref;

  DriverMapActions(this._ref);

  Future<void> startTracking() async {
    await _ref.read(driverMapProvider.notifier).startLocationTracking();
  }

  Future<void> stopTracking() async {
    await _ref.read(driverMapProvider.notifier).stopLocationTracking();
  }

  Future<void> centerOnLocation() async {
    await _ref.read(driverMapProvider.notifier).centerOnCurrentLocation();
  }

  Future<void> centerOnRoute() async {
    await _ref.read(driverMapProvider.notifier).centerOnRoute();
  }

  void setMapController(GoogleMapController controller) {
    _ref.read(driverMapProvider.notifier).setMapController(controller);
  }
}
