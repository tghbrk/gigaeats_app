import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/driver_order.dart';
import '../../data/services/enhanced_route_service.dart';
import '../../data/services/navigation_app_service.dart';
import '../widgets/route_preview_map.dart';
import '../widgets/navigation_app_selector.dart';
import '../widgets/route_information_card.dart';
import '../widgets/elevation_profile_widget.dart';
import '../providers/navigation_location_providers.dart';
import '../../../../core/config/google_config.dart';

/// Pre-navigation overview screen that displays comprehensive route information
/// before starting navigation to vendor or customer
class PreNavigationOverviewScreen extends ConsumerStatefulWidget {
  final DriverOrder order;
  final DriverNavigationDestination destination;
  final VoidCallback onNavigationStarted;
  final VoidCallback onCancel;

  const PreNavigationOverviewScreen({
    super.key,
    required this.order,
    required this.destination,
    required this.onNavigationStarted,
    required this.onCancel,
  });

  @override
  ConsumerState<PreNavigationOverviewScreen> createState() => _PreNavigationOverviewScreenState();
}

class _PreNavigationOverviewScreenState extends ConsumerState<PreNavigationOverviewScreen> {
  DetailedRouteInfo? _routeInfo;
  List<NavigationApp> _availableApps = [];
  String _selectedAppId = 'in_app';
  bool _isLoading = true;
  String? _error;
  LatLng? _currentLocation;
  bool _isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _getCurrentLocation();
    await _loadAvailableApps();
    await _loadRouteInformation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      // Use the navigation location provider for enhanced location handling
      final navigationLocationNotifier = ref.read(navigationLocationProvider.notifier);
      await navigationLocationNotifier.getCurrentLocation(
        requireHighAccuracy: true,
        maxRetries: 3,
      );

      final locationState = ref.read(navigationLocationProvider);

      if (locationState.isSuccess && locationState.location != null) {
        setState(() {
          _currentLocation = locationState.location!.toLatLng();
          _isLocationLoading = false;
        });

        debugPrint('🗺️ PreNavigationOverview: Got accurate location - Lat: ${_currentLocation!.latitude}, Lng: ${_currentLocation!.longitude}');
      } else if (locationState.hasError) {
        setState(() {
          _error = locationState.errorMessage ?? 'Unable to get current location';
          _isLocationLoading = false;
        });
      } else {
        // Fallback to default location (Kuala Lumpur)
        setState(() {
          _currentLocation = const LatLng(GoogleConfig.defaultLatitude, GoogleConfig.defaultLongitude);
          _isLocationLoading = false;
        });
        debugPrint('🗺️ PreNavigationOverview: Using fallback location');
      }
    } catch (e) {
      debugPrint('🗺️ PreNavigationOverview: Error getting current location: $e');
      setState(() {
        _currentLocation = const LatLng(GoogleConfig.defaultLatitude, GoogleConfig.defaultLongitude);
        _isLocationLoading = false;
      });
    }
  }

  Future<void> _loadRouteInformation() async {
    if (_currentLocation == null) {
      setState(() {
        _error = 'Current location not available';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get destination coordinates
      final destinationCoords = await _getDestinationCoordinates();
      if (destinationCoords == null) {
        setState(() {
          _error = 'Unable to determine destination location';
          _isLoading = false;
        });
        return;
      }

      // Calculate detailed route using current location and Google API key
      final routeInfo = await EnhancedRouteService.calculateDetailedRoute(
        origin: _currentLocation!,
        destination: destinationCoords,
        googleApiKey: GoogleConfig.apiKeyForRequests,
        includeTraffic: GoogleConfig.includeTrafficByDefault,
        includeElevation: GoogleConfig.includeElevationByDefault,
      );

      if (routeInfo == null) {
        setState(() {
          _error = 'Unable to calculate route. Please check your internet connection.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _routeInfo = routeInfo;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('🗺️ PreNavigationOverview: Error loading route information: $e');
      setState(() {
        _error = 'Failed to load route information: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAvailableApps() async {
    try {
      final apps = await NavigationAppService.getAvailableNavigationApps();
      setState(() {
        _availableApps = apps;
        // Set default to first installed app or in-app
        _selectedAppId = apps.firstWhere(
          (app) => app.isInstalled,
          orElse: () => apps.first,
        ).id;
      });
    } catch (e) {
      debugPrint('🧭 PreNavigationOverview: Error loading navigation apps: $e');
    }
  }

  Future<LatLng?> _getDestinationCoordinates() async {
    switch (widget.destination) {
      case DriverNavigationDestination.vendor:
        // TODO: Get actual vendor coordinates from order
        return const LatLng(3.1478, 101.6953); // Mock vendor location
      case DriverNavigationDestination.customer:
        // TODO: Get actual customer coordinates from order
        return const LatLng(3.1590, 101.7123); // Mock customer location
    }
  }

  String _getDestinationName() {
    switch (widget.destination) {
      case DriverNavigationDestination.vendor:
        return widget.order.vendorName;
      case DriverNavigationDestination.customer:
        return 'Customer Location';
    }
  }

  String _getDestinationAddress() {
    switch (widget.destination) {
      case DriverNavigationDestination.vendor:
        return widget.order.vendorName; // TODO: Get actual vendor address
      case DriverNavigationDestination.customer:
        return widget.order.deliveryAddress; // deliveryAddress is already a string
    }
  }

  Future<void> _startNavigation() async {
    if (_routeInfo == null) return;

    try {
      if (_selectedAppId == 'in_app') {
        // Use in-app navigation
        widget.onNavigationStarted();
        Navigator.of(context).pop();
      } else {
        // Launch external navigation app
        final success = await NavigationAppService.launchNavigation(
          appId: _selectedAppId,
          destination: _routeInfo!.destination,
          origin: _routeInfo!.origin,
          destinationName: _getDestinationName(),
        );

        if (success) {
          widget.onNavigationStarted();
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to launch navigation app'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('🧭 PreNavigationOverview: Error starting navigation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error starting navigation'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Navigate to ${_getDestinationName()}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
        actions: [
          if (_isLocationLoading || _isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _buildBody(theme),
      bottomNavigationBar: _routeInfo != null && !_isLoading && _error == null
          ? _buildBottomActionBar(theme)
          : null,
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLocationLoading) {
      return _buildLocationLoadingView(theme);
    }

    if (_isLoading) {
      return _buildRouteLoadingView(theme);
    }

    if (_error != null) {
      return _buildErrorView(theme);
    }

    if (_routeInfo != null) {
      return _buildOverviewContent(theme);
    }

    return const Center(child: Text('Initializing...'));
  }

  Widget _buildLocationLoadingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Getting your location...',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Please ensure location services are enabled',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRouteLoadingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Calculating route...',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Finding the best route to your destination',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    final isLocationError = _error?.contains('location') == true || _error?.contains('Location') == true;
    final isPermissionError = _error?.contains('permission') == true || _error?.contains('Permission') == true;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLocationError ? Icons.location_off : Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (isLocationError || isPermissionError) ...[
              Text(
                isPermissionError
                    ? 'Please grant location permission in your device settings'
                    : 'Please enable location services and try again',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _initializeScreen,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _loadRouteInformation,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewContent(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route preview map
          RoutePreviewMap(
            routeInfo: _routeInfo!,
            height: 200,
          ),
          const SizedBox(height: 16),
          
          // Route information card
          RouteInformationCard(
            routeInfo: _routeInfo!,
            destinationName: _getDestinationName(),
            destinationAddress: _getDestinationAddress(),
          ),
          const SizedBox(height: 16),
          
          // Elevation profile (if available)
          if (_routeInfo!.hasElevationChanges) ...[
            ElevationProfileWidget(
              elevationProfile: _routeInfo!.elevationProfile,
            ),
            const SizedBox(height: 16),
          ],
          
          // Navigation app selector
          NavigationAppSelector(
            availableApps: _availableApps,
            selectedAppId: _selectedAppId,
            onAppSelected: (appId) {
              setState(() {
                _selectedAppId = appId;
              });
            },
          ),
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _startNavigation,
                icon: const Icon(Icons.navigation),
                label: Text(_selectedAppId == 'in_app' 
                    ? 'Start Navigation' 
                    : 'Open ${_availableApps.firstWhere((app) => app.id == _selectedAppId, orElse: () => _availableApps.first).name}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enum for navigation destination type
enum DriverNavigationDestination {
  vendor,
  customer,
}
