# Enhanced In-App Navigation System

## 🎯 Overview

The Enhanced In-App Navigation System eliminates the need for drivers to switch between the GigaEats app and external navigation apps by providing comprehensive turn-by-turn navigation, voice guidance, and real-time traffic integration directly within the driver interface.

## 🚀 Key Features

### **Core Navigation Capabilities**
- **Turn-by-turn directions** with visual and audio guidance
- **Voice navigation** in Malaysian languages (English, Malay, Chinese)
- **Real-time traffic integration** with automatic rerouting
- **Location-based automatic status transitions** using geofencing
- **Battery-optimized tracking** with adaptive update frequencies
- **Seamless integration** with existing 7-step driver workflow

### **Advanced Features**
- **Multi-waypoint navigation** for batch deliveries
- **Traffic incident alerts** with alternative route suggestions
- **Offline navigation capability** with cached map data
- **Speed limit warnings** and safety alerts
- **ETA predictions** with traffic-adjusted calculations

## 🏗️ Technical Architecture

### **Enhanced Navigation Service**
```dart
class EnhancedNavigationService {
  final GoogleMapsService _mapsService;
  final VoiceNavigationService _voiceService;
  final GeofencingService _geofencingService;
  final TrafficService _trafficService;
  
  /// Start comprehensive in-app navigation
  Future<NavigationSession> startInAppNavigation({
    required LatLng origin,
    required LatLng destination,
    required String orderId,
    String? batchId,
    NavigationPreferences? preferences,
  }) async {
    // 1. Calculate optimal route with traffic
    final route = await _mapsService.calculateRoute(
      origin: origin,
      destination: destination,
      includeTraffic: true,
      includeAlternatives: true,
    );
    
    // 2. Set up geofencing for automatic status updates
    await _geofencingService.setupGeofences([
      Geofence(
        id: 'destination_${orderId}',
        center: destination,
        radius: 50, // 50 meters
        events: [GeofenceEvent.enter],
      ),
    ]);
    
    // 3. Initialize voice guidance
    await _voiceService.initialize(
      language: preferences?.language ?? 'en-MY',
    );
    
    // 4. Start navigation session
    final session = NavigationSession(
      id: _generateSessionId(),
      orderId: orderId,
      batchId: batchId,
      route: route,
      startTime: DateTime.now(),
    );
    
    // 5. Begin instruction stream
    _startInstructionStream(session);
    
    return session;
  }
  
  /// Get real-time navigation instructions
  Stream<NavigationInstruction> getNavigationInstructions(NavigationSession session) async* {
    await for (final location in _locationStream) {
      final instruction = await _calculateNextInstruction(
        currentLocation: location,
        route: session.route,
        session: session,
      );
      
      if (instruction != null) {
        // Announce instruction via voice
        await _voiceService.announceInstruction(instruction);
        
        yield instruction;
      }
    }
  }
  
  /// Handle traffic updates and rerouting
  Stream<TrafficUpdate> getTrafficUpdates(NavigationSession session) async* {
    await for (final trafficData in _trafficService.getTrafficStream(session.route)) {
      if (trafficData.requiresRerouting) {
        final alternativeRoute = await _mapsService.calculateAlternativeRoute(
          currentLocation: session.currentLocation,
          destination: session.route.destination,
          avoidIncidents: trafficData.incidents,
        );
        
        yield TrafficUpdate(
          condition: trafficData.condition,
          incidents: trafficData.incidents,
          suggestedRoute: alternativeRoute,
          estimatedDelay: trafficData.estimatedDelay,
        );
      }
    }
  }
}
```

### **Voice Navigation Service**
```dart
class VoiceNavigationService {
  final FlutterTts _tts = FlutterTts();
  String _currentLanguage = 'en-MY';
  bool _isEnabled = true;
  
  /// Initialize voice navigation with language support
  Future<void> initialize({String language = 'en-MY'}) async {
    _currentLanguage = language;
    
    await _tts.setLanguage(_getLanguageCode(language));
    await _tts.setSpeechRate(0.8); // Slightly slower for clarity
    await _tts.setVolume(0.9);
    await _tts.setPitch(1.0);
    
    // Set voice based on language
    await _setVoiceForLanguage(language);
  }
  
  /// Announce navigation instruction
  Future<void> announceInstruction(NavigationInstruction instruction) async {
    if (!_isEnabled) return;
    
    final announcement = _formatInstructionForVoice(instruction);
    await _tts.speak(announcement);
  }
  
  /// Announce traffic alert
  Future<void> announceTrafficAlert(TrafficAlert alert) async {
    if (!_isEnabled) return;
    
    final message = _formatTrafficAlert(alert);
    await _tts.speak(message);
  }
  
  /// Format instruction for voice announcement
  String _formatInstructionForVoice(NavigationInstruction instruction) {
    switch (_currentLanguage) {
      case 'en-MY':
        return _formatEnglishInstruction(instruction);
      case 'ms-MY':
        return _formatMalayInstruction(instruction);
      case 'zh-MY':
        return _formatChineseInstruction(instruction);
      default:
        return _formatEnglishInstruction(instruction);
    }
  }
  
  String _formatEnglishInstruction(NavigationInstruction instruction) {
    final distance = _formatDistance(instruction.distanceToManeuver);
    
    switch (instruction.type) {
      case ManeuverType.turnLeft:
        return "In $distance, turn left onto ${instruction.roadName}";
      case ManeuverType.turnRight:
        return "In $distance, turn right onto ${instruction.roadName}";
      case ManeuverType.continue:
        return "Continue straight for $distance";
      case ManeuverType.arrive:
        return "You have arrived at your destination";
      default:
        return instruction.instruction;
    }
  }
  
  String _formatMalayInstruction(NavigationInstruction instruction) {
    final distance = _formatDistance(instruction.distanceToManeuver);
    
    switch (instruction.type) {
      case ManeuverType.turnLeft:
        return "Dalam $distance, belok kiri ke ${instruction.roadName}";
      case ManeuverType.turnRight:
        return "Dalam $distance, belok kanan ke ${instruction.roadName}";
      case ManeuverType.continue:
        return "Teruskan lurus untuk $distance";
      case ManeuverType.arrive:
        return "Anda telah tiba di destinasi";
      default:
        return instruction.instruction;
    }
  }
}
```

### **Geofencing Service**
```dart
class GeofencingService {
  final List<Geofence> _activeGeofences = [];
  StreamSubscription<Position>? _locationSubscription;
  
  /// Set up geofences for automatic status transitions
  Future<void> setupGeofences(List<Geofence> geofences) async {
    _activeGeofences.clear();
    _activeGeofences.addAll(geofences);
    
    // Start monitoring location for geofence events
    _startGeofenceMonitoring();
  }
  
  void _startGeofenceMonitoring() {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Check every 5 meters
      ),
    ).listen(_checkGeofences);
  }
  
  void _checkGeofences(Position position) {
    for (final geofence in _activeGeofences) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        geofence.center.latitude,
        geofence.center.longitude,
      );
      
      if (distance <= geofence.radius) {
        _handleGeofenceEvent(geofence, GeofenceEvent.enter, position);
      }
    }
  }
  
  void _handleGeofenceEvent(Geofence geofence, GeofenceEvent event, Position position) {
    // Trigger automatic status update
    if (geofence.id.startsWith('destination_')) {
      final orderId = geofence.id.split('_')[1];
      _triggerStatusUpdate(orderId, 'arrived_at_customer');
    } else if (geofence.id.startsWith('pickup_')) {
      final orderId = geofence.id.split('_')[1];
      _triggerStatusUpdate(orderId, 'arrived_at_vendor');
    }
  }
}
```

## 📱 UI Components

### **Navigation Instruction Overlay**
```dart
class NavigationInstructionOverlay extends StatelessWidget {
  final NavigationInstruction instruction;
  final Duration? timeToManeuver;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 8,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Row(
          children: [
            // Maneuver icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                _getManeuverIcon(instruction.type),
                color: Colors.white,
                size: 30,
              ),
            ),
            
            SizedBox(width: 16),
            
            // Instruction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instruction.instruction,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${_formatDistance(instruction.distanceToManeuver)} • ${instruction.roadName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (timeToManeuver != null) ...[
                    SizedBox(height: 4),
                    Text(
                      'ETA: ${_formatDuration(timeToManeuver!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Voice toggle
            IconButton(
              onPressed: () => _toggleVoiceGuidance(),
              icon: Icon(
                _isVoiceEnabled ? Icons.volume_up : Icons.volume_off,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### **In-App Navigation Map Widget**
```dart
class InAppNavigationMapWidget extends StatefulWidget {
  final NavigationSession session;
  final Function(NavigationInstruction) onInstructionUpdate;
  final Function(TrafficUpdate) onTrafficUpdate;
  
  @override
  State<InAppNavigationMapWidget> createState() => _InAppNavigationMapWidgetState();
}

class _InAppNavigationMapWidgetState extends State<InAppNavigationMapWidget> {
  GoogleMapController? _controller;
  NavigationInstruction? _currentInstruction;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Google Map with navigation
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: widget.session.route.origin,
            zoom: 18,
            bearing: 0,
            tilt: 60, // 3D perspective for navigation
          ),
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          trafficEnabled: true,
          buildingsEnabled: true,
          compassEnabled: true,
          rotateGesturesEnabled: false, // Lock rotation during navigation
          scrollGesturesEnabled: false, // Lock scrolling during navigation
          zoomGesturesEnabled: true,
          tiltGesturesEnabled: false,
          mapType: MapType.normal,
        ),
        
        // Navigation instruction overlay
        if (_currentInstruction != null)
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: NavigationInstructionOverlay(
              instruction: _currentInstruction!,
              timeToManeuver: _calculateTimeToManeuver(),
            ),
          ),
        
        // Navigation controls
        Positioned(
          bottom: 100,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: "recenter",
                mini: true,
                onPressed: _recenterMap,
                child: Icon(Icons.my_location),
              ),
              SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "reroute",
                mini: true,
                onPressed: _requestReroute,
                child: Icon(Icons.alt_route),
              ),
            ],
          ),
        ),
        
        // Speed and ETA display
        Positioned(
          top: 200,
          right: 16,
          child: NavigationStatsCard(
            currentSpeed: widget.session.currentSpeed,
            eta: widget.session.estimatedArrival,
            remainingDistance: widget.session.remainingDistance,
          ),
        ),
      ],
    );
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _initializeNavigation();
  }
  
  void _initializeNavigation() {
    // Set up markers and route polyline
    _updateMapElements();
    
    // Start listening to navigation instructions
    widget.session.instructionStream.listen((instruction) {
      setState(() {
        _currentInstruction = instruction;
      });
      
      // Update camera to follow navigation
      _updateCameraForNavigation(instruction);
      
      widget.onInstructionUpdate(instruction);
    });
    
    // Listen to traffic updates
    widget.session.trafficStream.listen((trafficUpdate) {
      if (trafficUpdate.requiresRerouting) {
        _showRerouteDialog(trafficUpdate);
      }
      
      widget.onTrafficUpdate(trafficUpdate);
    });
  }
  
  void _updateCameraForNavigation(NavigationInstruction instruction) {
    if (_controller == null) return;
    
    _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: instruction.location,
          zoom: 18,
          bearing: instruction.bearing ?? 0,
          tilt: 60,
        ),
      ),
    );
  }
}
```

## 🔧 Integration with Driver Workflow

### **Enhanced Driver Workflow Provider**
```dart
class EnhancedDriverWorkflowProvider extends StateNotifier<DriverWorkflowState> {
  final EnhancedNavigationService _navigationService;
  final GeofencingService _geofencingService;
  
  /// Start navigation to vendor with automatic status tracking
  Future<void> startNavigationToVendor(String orderId) async {
    final order = await _getOrder(orderId);
    final currentLocation = await _getCurrentLocation();
    
    // Start in-app navigation
    final session = await _navigationService.startInAppNavigation(
      origin: currentLocation,
      destination: order.vendorLocation,
      orderId: orderId,
    );
    
    // Update order status
    await updateOrderStatus(orderId, DriverOrderStatus.onRouteToVendor);
    
    // Set up automatic status transitions
    await _geofencingService.setupGeofences([
      Geofence(
        id: 'pickup_$orderId',
        center: order.vendorLocation,
        radius: 50,
        events: [GeofenceEvent.enter],
      ),
    ]);
    
    state = state.copyWith(
      currentNavigationSession: session,
      isNavigating: true,
    );
  }
  
  /// Handle automatic status updates from geofencing
  Future<void> handleGeofenceEvent(String geofenceId, GeofenceEvent event) async {
    if (event == GeofenceEvent.enter) {
      if (geofenceId.startsWith('pickup_')) {
        final orderId = geofenceId.split('_')[1];
        await updateOrderStatus(orderId, DriverOrderStatus.arrivedAtVendor);
        
        // Show arrival confirmation dialog
        _showArrivalConfirmation(orderId, 'vendor');
      } else if (geofenceId.startsWith('destination_')) {
        final orderId = geofenceId.split('_')[1];
        await updateOrderStatus(orderId, DriverOrderStatus.arrivedAtCustomer);
        
        // Show arrival confirmation dialog
        _showArrivalConfirmation(orderId, 'customer');
      }
    }
  }
}
```

## 🧪 Testing Strategy

### **Navigation Testing Scenarios**
```dart
// Test navigation instruction generation
testWidgets('Navigation instructions are generated correctly', (tester) async {
  final mockRoute = MockRoute();
  final mockLocation = MockLocation();
  
  final navigationService = EnhancedNavigationService();
  final session = await navigationService.startInAppNavigation(
    origin: mockLocation.origin,
    destination: mockLocation.destination,
    orderId: 'test_order_123',
  );
  
  expect(session.instructionStream, emitsInOrder([
    isA<NavigationInstruction>().having((i) => i.type, 'type', ManeuverType.continue),
    isA<NavigationInstruction>().having((i) => i.type, 'type', ManeuverType.turnRight),
    isA<NavigationInstruction>().having((i) => i.type, 'type', ManeuverType.arrive),
  ]));
});

// Test voice guidance in multiple languages
testWidgets('Voice guidance works in Malaysian languages', (tester) async {
  final voiceService = VoiceNavigationService();
  
  // Test English
  await voiceService.initialize(language: 'en-MY');
  await voiceService.announceInstruction(mockInstruction);
  
  // Test Malay
  await voiceService.initialize(language: 'ms-MY');
  await voiceService.announceInstruction(mockInstruction);
  
  // Verify TTS was called with correct language
  verify(mockTts.setLanguage('en-MY')).called(1);
  verify(mockTts.setLanguage('ms-MY')).called(1);
});

// Test geofencing accuracy
testWidgets('Geofencing triggers status updates correctly', (tester) async {
  final geofencingService = GeofencingService();
  final mockWorkflowProvider = MockDriverWorkflowProvider();
  
  await geofencingService.setupGeofences([
    Geofence(
      id: 'destination_test_order',
      center: LatLng(3.1390, 101.6869),
      radius: 50,
    ),
  ]);
  
  // Simulate driver entering geofence
  geofencingService.simulateLocationUpdate(
    Position(
      latitude: 3.1390,
      longitude: 101.6869,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    ),
  );
  
  // Verify status update was triggered
  verify(mockWorkflowProvider.updateOrderStatus('test_order', DriverOrderStatus.arrivedAtCustomer)).called(1);
});
```

This enhanced in-app navigation system provides comprehensive navigation capabilities while maintaining seamless integration with the existing GigaEats driver workflow, eliminating the need for external navigation apps and improving overall driver productivity.
