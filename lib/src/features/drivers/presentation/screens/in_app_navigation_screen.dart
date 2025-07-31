import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/navigation_models.dart';
import '../providers/enhanced_navigation_provider.dart';
import '../providers/multi_order_batch_provider.dart';
import '../widgets/multi_order/navigation_instruction_overlay.dart';
import '../widgets/multi_order/enhanced_navigation_map_overlay.dart';
import '../widgets/multi_order/multi_waypoint_navigation_system.dart';
import '../widgets/navigation_stats_card.dart';
import '../widgets/navigation_loading_states.dart';
import '../theming/navigation_theme_service.dart';


/// Main in-app navigation screen providing full-screen turn-by-turn navigation
/// This is the critical missing component identified in the investigation
/// 
/// Features:
/// - Full-screen Google Maps with 3D navigation perspective
/// - Real-time NavigationSession integration
/// - Turn-by-turn instruction overlay
/// - Voice guidance controls
/// - Traffic layer integration
/// - Multi-waypoint support for batch deliveries
/// - Locked navigation mode (disabled rotation/scroll)
/// - Automatic camera following with bearing-based orientation
class InAppNavigationScreen extends ConsumerStatefulWidget {
  final NavigationSession session;
  final VoidCallback? onNavigationComplete;
  final VoidCallback? onNavigationCancelled;

  const InAppNavigationScreen({
    super.key,
    required this.session,
    this.onNavigationComplete,
    this.onNavigationCancelled,
  });

  @override
  ConsumerState<InAppNavigationScreen> createState() => _InAppNavigationScreenState();
}

class _InAppNavigationScreenState extends ConsumerState<InAppNavigationScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  late AnimationController _cameraAnimationController;
  
  // Map state
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  
  // Navigation state
  NavigationInstruction? _currentInstruction;
  bool _isMapReady = false;
  bool _isFollowingLocation = true;
  bool _showTrafficLayer = true;
  
  // Camera animation
  bool _isCameraAnimating = false;

  @override
  void initState() {
    super.initState();
    
    debugPrint('🧭 [IN-APP-NAV] Initializing in-app navigation screen for session: ${widget.session.id}');
    
    // Initialize camera animation controller
    _cameraAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Set immersive navigation mode
    _setNavigationMode();
    
    // Initialize map elements
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMapElements();
    });
  }

  @override
  void dispose() {
    debugPrint('🧭 [IN-APP-NAV] Disposing in-app navigation screen');
    
    _cameraAnimationController.dispose();
    _restoreSystemUI();
    
    super.dispose();
  }

  /// Set immersive navigation mode with locked orientation
  void _setNavigationMode() {
    // Set immersive mode for navigation
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top], // Keep status bar for safety
    );
    
    // Lock to portrait orientation during navigation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  /// Restore normal system UI when navigation ends
  void _restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  @override
  Widget build(BuildContext context) {
    try {
      final theme = Theme.of(context);
      final navState = ref.watch(enhancedNavigationProvider);
      final batchState = ref.watch(multiOrderBatchProvider);

      debugPrint('🧭 [IN-APP-NAV] Building navigation screen - Session: ${widget.session.id}, Active: ${navState.isNavigating}');

      // Validate session before rendering
      if (widget.session.id.isEmpty) {
        debugPrint('❌ [IN-APP-NAV] Invalid session ID, returning error screen');
        return _buildErrorScreen('Invalid navigation session');
      }

      return NavigationThemeService.applyNavigationTheme(
        context: context,
        child: Scaffold(
          body: Stack(
            children: [
            // Main Google Maps with 3D navigation perspective
            _buildNavigationMap(navState),

            // Navigation instruction overlay (top) or loading placeholder
            if (_currentInstruction != null)
              NavigationInstructionOverlay(
                showVoiceControls: true,
                showTrafficAlerts: true,
                showMultiWaypointInfo: batchState.hasActiveBatch,
                onToggleVoice: _toggleVoiceGuidance,
                onToggleTraffic: _toggleTrafficLayer,
              )
          else if (!_isMapReady)
            const NavigationInstructionLoadingPlaceholder(),
          
          // Enhanced navigation map overlay (controls and info)
          EnhancedNavigationMapOverlay(
            mapController: _mapController,
            showNavigationControls: true,
            showTrafficLayer: _showTrafficLayer,
            showVoiceControls: true,
            onToggleVoice: _toggleVoiceGuidance,
            onToggleTraffic: _toggleTrafficLayer,
            onCenterOnLocation: _centerOnLocation,
            onStopNavigation: _showStopNavigationDialog,
          ),
          
          // Multi-waypoint navigation system (for batch deliveries)
          if (batchState.hasActiveBatch)
            MultiWaypointNavigationSystem(
              showWaypointList: true,
              showRouteOptimization: false, // Hide during active navigation
              showBatchProgress: true,
            ),

          // Navigation statistics card (top right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 200,
            right: 16,
            child: NavigationStatsCard.fromProviders(
              compact: true,
              margin: EdgeInsets.zero,
              onTap: () => _showDetailedStats(context),
            ),
          ),

          // Exit navigation button (top left)
          _buildExitNavigationButton(theme),

          // Loading overlay when navigation is initializing
          if (!_isMapReady)
            const NavigationLoadingOverlay(
              message: 'Initializing navigation map...',
              showProgress: false,
            ),
        ],
      ),
    ),
    );
    } catch (e, stackTrace) {
      debugPrint('❌ [IN-APP-NAV] Error building navigation screen: $e');
      debugPrint('❌ [IN-APP-NAV] Stack trace: $stackTrace');
      return _buildErrorScreen('Navigation screen error: $e');
    }
  }

  /// Build error screen for navigation failures
  Widget _buildErrorScreen(String errorMessage) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Navigation Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        debugPrint('🔄 [IN-APP-NAV] Returning to dashboard from error screen');
                        if (widget.onNavigationCancelled != null) {
                          widget.onNavigationCancelled!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

  /// Build the main Google Maps widget with 3D navigation perspective
  Widget _buildNavigationMap(EnhancedNavigationState navState) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: widget.session.origin,
        zoom: 18.0, // Close zoom for navigation
        bearing: 0.0, // Will be updated based on route direction
        tilt: 60.0, // 3D perspective for navigation
      ),
      markers: _markers,
      polylines: _polylines,
      circles: _circles,
      
      // Navigation-optimized settings
      myLocationEnabled: true,
      myLocationButtonEnabled: false, // Custom location button
      compassEnabled: false, // Custom compass in overlay
      trafficEnabled: _showTrafficLayer,
      buildingsEnabled: true, // 3D buildings for better navigation context
      indoorViewEnabled: false,
      mapToolbarEnabled: false,
      
      // Locked navigation mode - disable user gestures during navigation
      rotateGesturesEnabled: false, // Lock rotation
      scrollGesturesEnabled: false, // Lock scrolling
      zoomGesturesEnabled: true, // Allow zoom for safety
      tiltGesturesEnabled: false, // Lock tilt
      
      // Map style optimized for navigation
      mapType: MapType.normal,
      
      // Camera movement callback
      onCameraMove: _onCameraMove,
      onCameraIdle: _onCameraIdle,
    );
  }

  /// Build exit navigation button
  Widget _buildExitNavigationButton(ThemeData theme) {
    final navTheme = NavigationTheme.of(context);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: Material(
        elevation: navTheme?.elevationTheme.overlayElevation ?? 8.0,
        borderRadius: BorderRadius.circular(navTheme?.borderRadius.circular ?? 28),
        shadowColor: navTheme?.elevationTheme.shadowColor ??
                    theme.colorScheme.shadow.withValues(alpha: 0.3),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: navTheme?.colors.navigationSurface ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(navTheme?.borderRadius.circular ?? 28),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: IconButton(
            onPressed: _showStopNavigationDialog,
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            tooltip: 'Exit Navigation',
          ),
        ),
      ),
    );
  }

  /// Handle map creation
  void _onMapCreated(GoogleMapController controller) {
    debugPrint('🧭 [IN-APP-NAV] Google Maps created');

    _mapController = controller;

    // Initialize enhanced 3D camera service asynchronously
    _initializeEnhanced3DCamera(controller).then((_) {
      debugPrint('🧭 [IN-APP-NAV] Enhanced 3D camera service initialization complete');

      setState(() {
        _isMapReady = true;
      });

      // Initialize navigation elements
      _initializeMapElements();

      // Start listening to navigation updates
      _startNavigationUpdates();
    }).catchError((error) {
      debugPrint('❌ [IN-APP-NAV] Error during camera service initialization: $error');

      // Continue with basic navigation even if camera service fails
      setState(() {
        _isMapReady = true;
      });

      // Initialize navigation elements
      _initializeMapElements();

      // Start listening to navigation updates
      _startNavigationUpdates();
    });
  }

  /// Initialize enhanced 3D camera service
  Future<void> _initializeEnhanced3DCamera(GoogleMapController controller) async {
    try {
      debugPrint('📹 [IN-APP-NAV] Initializing enhanced 3D camera service');

      final navService = ref.read(enhancedNavigationProvider.notifier);
      await navService.initializeCameraService(controller);

      debugPrint('📹 [IN-APP-NAV] Enhanced 3D camera service initialized successfully');
    } catch (e) {
      debugPrint('❌ [IN-APP-NAV] Error initializing enhanced 3D camera service: $e');

      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('3D navigation camera initialization failed: $e'),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Initialize map markers, polylines, and other elements
  void _initializeMapElements() {
    if (!_isMapReady) return;
    
    debugPrint('🧭 [IN-APP-NAV] Initializing map elements');
    
    _updateRoutePolyline();
    _updateNavigationMarkers();
    _fitMapToRoute();
  }

  /// Update route polyline on map
  void _updateRoutePolyline() {
    final route = widget.session.route;
    
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('navigation_route'),
          points: route.polylinePoints,
          color: Colors.blue.shade600,
          width: 6,
          patterns: [], // Solid line for main route
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
    });
  }

  /// Update navigation markers (origin, destination, current location)
  void _updateNavigationMarkers() {
    setState(() {
      _markers = {
        // Origin marker
        Marker(
          markerId: const MarkerId('origin'),
          position: widget.session.origin,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Start'),
        ),
        
        // Destination marker
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.session.destination,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: widget.session.destinationName,
          ),
        ),
      };
    });
  }

  /// Fit map camera to show the entire route
  void _fitMapToRoute() {
    if (_mapController == null) return;

    final route = widget.session.route;
    if (route.polylinePoints.isEmpty) return;

    // Calculate bounds for all route points
    double minLat = route.polylinePoints.first.latitude;
    double maxLat = route.polylinePoints.first.latitude;
    double minLng = route.polylinePoints.first.longitude;
    double maxLng = route.polylinePoints.first.longitude;

    for (final point in route.polylinePoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  /// Start listening to navigation updates
  void _startNavigationUpdates() {
    debugPrint('🧭 [IN-APP-NAV] Starting navigation updates');

    // Listen to navigation state changes
    ref.listen<EnhancedNavigationState>(enhancedNavigationProvider, (previous, current) {
      _handleNavigationStateChange(previous, current);
    });

    // Start real-time instruction stream
    _startRealTimeInstructionStream();

    // Start automatic camera following
    _startAutomaticCameraFollowing();

    // Update current instruction
    _updateCurrentInstruction();
  }

  /// Start real-time instruction stream
  void _startRealTimeInstructionStream() {
    final navNotifier = ref.read(enhancedNavigationProvider.notifier);
    final instructionStream = navNotifier.getNavigationInstructionsStream();

    if (instructionStream != null) {
      debugPrint('🧭 [IN-APP-NAV] Starting real-time instruction stream');

      instructionStream.listen(
        (instruction) {
          debugPrint('🧭 [IN-APP-NAV] Received real-time instruction: ${instruction.text}');

          if (mounted) {
            setState(() {
              _currentInstruction = instruction;
            });
          }
        },
        onError: (error) {
          debugPrint('❌ [IN-APP-NAV] Instruction stream error: $error');
        },
        onDone: () {
          debugPrint('🧭 [IN-APP-NAV] Instruction stream completed');
        },
      );
    }
  }

  /// Start automatic camera following
  void _startAutomaticCameraFollowing() {
    final navNotifier = ref.read(enhancedNavigationProvider.notifier);
    final cameraStream = navNotifier.getCameraPositionUpdates();

    if (cameraStream != null && _isFollowingLocation) {
      debugPrint('📹 [IN-APP-NAV] Starting automatic camera following');

      cameraStream.listen(
        (cameraPosition) {
          if (mounted && _mapController != null && _isFollowingLocation && !_isCameraAnimating) {
            debugPrint('📹 [IN-APP-NAV] Updating camera position automatically');

            _isCameraAnimating = true;
            _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(cameraPosition),
            ).then((_) {
              _isCameraAnimating = false;
            });
          }
        },
        onError: (error) {
          debugPrint('❌ [IN-APP-NAV] Camera stream error: $error');
        },
        onDone: () {
          debugPrint('📹 [IN-APP-NAV] Camera stream completed');
        },
      );
    }
  }

  /// Handle navigation state changes
  void _handleNavigationStateChange(
    EnhancedNavigationState? previous,
    EnhancedNavigationState current,
  ) {
    debugPrint('🧭 [IN-APP-NAV] Navigation state changed - Navigating: ${current.isNavigating}');

    // Update current instruction
    if (current.currentInstruction != _currentInstruction) {
      setState(() {
        _currentInstruction = current.currentInstruction;
      });

      // Update camera for new instruction
      if (_currentInstruction != null && _isFollowingLocation) {
        _updateCameraForInstruction(_currentInstruction!);
      }
    }

    // Handle navigation completion
    if (previous?.isNavigating == true && !current.isNavigating) {
      _handleNavigationComplete();
    }

    // Handle navigation errors
    if (current.error != null && previous?.error != current.error) {
      _handleNavigationError(current.error!);
    }
  }

  /// Update current instruction from session
  void _updateCurrentInstruction() {
    final navState = ref.read(enhancedNavigationProvider);
    if (navState.currentInstruction != null) {
      setState(() {
        _currentInstruction = navState.currentInstruction;
      });
    }
  }

  /// Update camera position for navigation instruction
  void _updateCameraForInstruction(NavigationInstruction instruction) {
    if (_mapController == null || _isCameraAnimating) return;

    debugPrint('🧭 [IN-APP-NAV] Updating camera for instruction: ${instruction.text}');

    _isCameraAnimating = true;

    // Calculate bearing based on instruction location and next point
    double bearing = 0.0;
    final route = widget.session.route;
    final currentIndex = route.instructions.indexOf(instruction);

    if (currentIndex >= 0 && currentIndex < route.instructions.length - 1) {
      final nextInstruction = route.instructions[currentIndex + 1];
      bearing = _calculateBearing(instruction.location, nextInstruction.location);
    }

    // Animate camera to instruction location with 3D perspective
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: instruction.location,
          zoom: 18.0,
          bearing: bearing,
          tilt: 60.0, // 3D perspective
        ),
      ),
    ).then((_) {
      _isCameraAnimating = false;
    });
  }

  /// Calculate bearing between two points
  double _calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * (3.14159 / 180);
    final startLng = start.longitude * (3.14159 / 180);
    final endLat = end.latitude * (3.14159 / 180);
    final endLng = end.longitude * (3.14159 / 180);

    final dLng = endLng - startLng;

    final y = sin(dLng) * cos(endLat);
    final x = cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);

    final bearing = atan2(y, x) * (180 / 3.14159);
    return (bearing + 360) % 360;
  }

  /// Handle camera movement
  void _onCameraMove(CameraPosition position) {
    // Track if user manually moved camera
    if (!_isCameraAnimating) {
      _isFollowingLocation = false;
    }
  }

  /// Handle camera idle
  void _onCameraIdle() {
    // Camera movement finished
  }

  /// Center camera on current location
  void _centerOnLocation() {
    if (_mapController == null) return;

    debugPrint('🧭 [IN-APP-NAV] Centering on current location');

    final navState = ref.read(enhancedNavigationProvider);
    if (navState.currentInstruction != null) {
      _isFollowingLocation = true;
      _updateCameraForInstruction(navState.currentInstruction!);
    }
  }

  /// Toggle voice guidance
  void _toggleVoiceGuidance() {
    debugPrint('🧭 [IN-APP-NAV] Toggling voice guidance');

    final navState = ref.read(enhancedNavigationProvider);
    final navNotifier = ref.read(enhancedNavigationProvider.notifier);

    // Get current preferences or create default ones
    final currentPreferences = navState.currentSession?.preferences ?? const NavigationPreferences();

    // Toggle voice guidance
    final updatedPreferences = currentPreferences.copyWith(
      voiceGuidanceEnabled: !currentPreferences.voiceGuidanceEnabled,
    );

    navNotifier.updatePreferences(updatedPreferences);
  }

  /// Toggle traffic layer
  void _toggleTrafficLayer() {
    debugPrint('🧭 [IN-APP-NAV] Toggling traffic layer');

    setState(() {
      _showTrafficLayer = !_showTrafficLayer;
    });
  }

  /// Show stop navigation confirmation dialog
  void _showStopNavigationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Navigation'),
        content: const Text(
          'Are you sure you want to stop navigation? You can restart it anytime from the order details.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _stopNavigation();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Stop Navigation'),
          ),
        ],
      ),
    );
  }

  /// Stop navigation and exit screen
  void _stopNavigation() {
    debugPrint('🧭 [IN-APP-NAV] Stopping navigation');

    final navNotifier = ref.read(enhancedNavigationProvider.notifier);
    navNotifier.stopNavigation();

    widget.onNavigationCancelled?.call();
    Navigator.of(context).pop();
  }

  /// Handle navigation completion
  void _handleNavigationComplete() {
    debugPrint('🧭 [IN-APP-NAV] Navigation completed');

    widget.onNavigationComplete?.call();

    // Show completion dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Navigation Complete'),
        content: const Text('You have arrived at your destination!'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Exit navigation screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  /// Show detailed navigation statistics dialog
  void _showDetailedStats(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Navigation Statistics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              NavigationStatsCard.fromProviders(
                compact: false,
                margin: EdgeInsets.zero,
                showSpeedLimit: true,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle navigation errors
  void _handleNavigationError(String error) {
    debugPrint('❌ [IN-APP-NAV] Navigation error: $error');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigation Error: $error'),
        backgroundColor: Colors.red.shade700,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            // Clear error state
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
