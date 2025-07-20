import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/navigation_models.dart';
import '../models/geofence.dart';
import 'voice_navigation_service.dart';
import 'geofencing_service.dart';
import '../../../../core/config/google_config.dart';

/// Enhanced navigation service with in-app navigation, voice guidance, and traffic-aware routing
/// Integrates with geofencing for automatic status transitions and provides comprehensive navigation features
class EnhancedNavigationService {
  final VoiceNavigationService _voiceService = VoiceNavigationService();
  final GeofencingService _geofencingService = GeofencingService();
  
  // Current navigation state
  NavigationSession? _currentSession;
  StreamSubscription<Position>? _locationSubscription;
  Timer? _instructionTimer;
  Timer? _trafficUpdateTimer;
  
  // Navigation streams
  final StreamController<NavigationInstruction> _instructionController = 
      StreamController<NavigationInstruction>.broadcast();
  final StreamController<NavigationSession> _sessionController = 
      StreamController<NavigationSession>.broadcast();
  final StreamController<String> _trafficAlertController = 
      StreamController<String>.broadcast();
  
  // Configuration
  static const double _instructionTriggerDistance = 100.0; // meters
  static const double _arrivalDistance = 20.0; // meters
  static const Duration _trafficUpdateInterval = Duration(minutes: 5);
  
  bool _isInitialized = false;

  /// Streams
  Stream<NavigationInstruction> get instructionStream => _instructionController.stream;
  Stream<NavigationSession> get sessionStream => _sessionController.stream;
  Stream<String> get trafficAlertStream => _trafficAlertController.stream;

  /// Initialize the enhanced navigation service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('🧭 [ENHANCED-NAV] Initializing enhanced navigation service');
    
    try {
      await _voiceService.initialize();
      await _geofencingService.initialize();
      
      _isInitialized = true;
      debugPrint('🧭 [ENHANCED-NAV] Enhanced navigation service initialized');
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error initializing: $e');
      throw Exception('Failed to initialize enhanced navigation: $e');
    }
  }

  /// Start comprehensive in-app navigation
  Future<NavigationSession> startInAppNavigation({
    required LatLng origin,
    required LatLng destination,
    required String orderId,
    String? batchId,
    String? destinationName,
    NavigationPreferences? preferences,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    debugPrint('🧭 [ENHANCED-NAV] Starting in-app navigation for order: $orderId');
    
    try {
      // Stop any existing navigation
      await stopNavigation();
      
      final prefs = preferences ?? NavigationPreferences.defaults();
      
      // Calculate optimal route with traffic
      final route = await _calculateRoute(
        origin: origin,
        destination: destination,
        preferences: prefs,
      );
      
      if (route == null) {
        throw Exception('Failed to calculate route');
      }
      
      // Create navigation session
      final session = NavigationSession(
        id: _generateSessionId(),
        orderId: orderId,
        batchId: batchId,
        route: route,
        preferences: prefs,
        status: NavigationSessionStatus.initializing,
        startTime: DateTime.now(),
        origin: origin,
        destination: destination,
        destinationName: destinationName,
      );
      
      // Set up destination geofence for automatic arrival detection
      await _setupDestinationGeofence(destination, orderId);
      
      // Initialize voice guidance if enabled
      if (prefs.voiceGuidanceEnabled) {
        await _voiceService.setLanguage(prefs.language);
        await _voiceService.setVolume(prefs.voiceVolume);
        await _voiceService.setEnabled(true);
      }
      
      // Start navigation session
      _currentSession = session.copyWith(status: NavigationSessionStatus.active);
      _sessionController.add(_currentSession!);
      
      // Start location tracking and instruction monitoring
      await _startLocationTracking();
      _startTrafficUpdates();
      
      debugPrint('🧭 [ENHANCED-NAV] In-app navigation started successfully');
      return _currentSession!;
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error starting navigation: $e');
      throw Exception('Failed to start navigation: $e');
    }
  }

  /// Calculate route with traffic data
  Future<NavigationRoute?> _calculateRoute({
    required LatLng origin,
    required LatLng destination,
    required NavigationPreferences preferences,
  }) async {
    try {
      debugPrint('🗺️ [ENHANCED-NAV] Calculating route with traffic data');
      
      final apiKey = GoogleConfig.apiKeyForRequests;
      if (apiKey == null) {
        debugPrint('⚠️ [ENHANCED-NAV] No Google API key, using simplified route');
        return await _calculateSimplifiedRoute(origin, destination);
      }
      
      // Build Google Directions API request
      final url = _buildDirectionsUrl(origin, destination, preferences, apiKey);
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(GoogleConfig.routeCalculationTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          return _parseGoogleDirectionsResponse(data['routes'][0]);
        } else {
          debugPrint('❌ [ENHANCED-NAV] Google Directions API error: ${data['status']}');
          return await _calculateSimplifiedRoute(origin, destination);
        }
      } else {
        debugPrint('❌ [ENHANCED-NAV] HTTP error: ${response.statusCode}');
        return await _calculateSimplifiedRoute(origin, destination);
      }
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error calculating route: $e');
      return await _calculateSimplifiedRoute(origin, destination);
    }
  }

  /// Build Google Directions API URL
  String _buildDirectionsUrl(
    LatLng origin,
    LatLng destination,
    NavigationPreferences preferences,
    String apiKey,
  ) {
    final params = <String, String>{
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': 'driving',
      'units': preferences.units == 'imperial' ? 'imperial' : 'metric',
      'language': preferences.language.split('-')[0], // Extract language code
      'region': 'MY', // Malaysia region
      'departure_time': 'now', // For traffic data
      'traffic_model': 'best_guess',
      'key': apiKey,
    };
    
    // Add route preferences
    final avoid = <String>[];
    if (preferences.avoidTolls) avoid.add('tolls');
    if (preferences.avoidHighways) avoid.add('highways');
    if (preferences.avoidFerries) avoid.add('ferries');
    
    if (avoid.isNotEmpty) {
      params['avoid'] = avoid.join('|');
    }
    
    // Request detailed instructions
    params['alternatives'] = 'false'; // Single best route
    params['optimize'] = 'true';
    
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '${GoogleConfig.directionsApiUrl}?$query';
  }

  /// Parse Google Directions API response
  NavigationRoute _parseGoogleDirectionsResponse(Map<String, dynamic> route) {
    final leg = route['legs'][0];
    final steps = leg['steps'] as List;
    
    // Parse polyline points
    final polylinePoints = decodePolyline(route['overview_polyline']['points'])
        .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
        .toList();
    
    // Parse instructions
    final instructions = <NavigationInstruction>[];
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final instruction = _parseNavigationStep(step, i);
      if (instruction != null) {
        instructions.add(instruction);
      }
    }
    
    // Calculate traffic condition
    final duration = leg['duration']['value'] as int;
    final durationInTraffic = leg['duration_in_traffic']?['value'] as int? ?? duration;
    final trafficCondition = _calculateTrafficCondition(duration, durationInTraffic);
    
    return NavigationRoute(
      id: _generateRouteId(),
      polylinePoints: polylinePoints,
      totalDistanceMeters: (leg['distance']['value'] as int).toDouble(),
      totalDurationSeconds: duration,
      durationInTrafficSeconds: durationInTraffic,
      instructions: instructions,
      overallTrafficCondition: trafficCondition,
      summary: route['summary'] ?? 'Route to destination',
      warnings: (route['warnings'] as List?)?.cast<String>() ?? [],
      calculatedAt: DateTime.now(),
    );
  }

  /// Parse individual navigation step
  NavigationInstruction? _parseNavigationStep(Map<String, dynamic> step, int index) {
    try {
      final startLocation = step['start_location'];
      final maneuver = step['maneuver'] as String?;
      
      return NavigationInstruction(
        id: 'instruction_$index',
        type: _parseInstructionType(maneuver),
        text: _stripHtmlTags(step['html_instructions']),
        htmlText: step['html_instructions'],
        distanceMeters: (step['distance']['value'] as int).toDouble(),
        durationSeconds: step['duration']['value'] as int,
        location: LatLng(
          startLocation['lat'].toDouble(),
          startLocation['lng'].toDouble(),
        ),
        maneuver: maneuver,
        trafficCondition: TrafficCondition.unknown,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error parsing step: $e');
      return null;
    }
  }

  /// Parse instruction type from maneuver
  NavigationInstructionType _parseInstructionType(String? maneuver) {
    if (maneuver == null) return NavigationInstructionType.straight;
    
    switch (maneuver.toLowerCase()) {
      case 'turn-left':
        return NavigationInstructionType.turnLeft;
      case 'turn-right':
        return NavigationInstructionType.turnRight;
      case 'turn-slight-left':
        return NavigationInstructionType.turnSlightLeft;
      case 'turn-slight-right':
        return NavigationInstructionType.turnSlightRight;
      case 'turn-sharp-left':
        return NavigationInstructionType.turnSharpLeft;
      case 'turn-sharp-right':
        return NavigationInstructionType.turnSharpRight;
      case 'uturn-left':
        return NavigationInstructionType.uturnLeft;
      case 'uturn-right':
        return NavigationInstructionType.uturnRight;
      case 'straight':
        return NavigationInstructionType.straight;
      case 'ramp-left':
        return NavigationInstructionType.rampLeft;
      case 'ramp-right':
        return NavigationInstructionType.rampRight;
      case 'merge':
        return NavigationInstructionType.merge;
      case 'fork-left':
        return NavigationInstructionType.forkLeft;
      case 'fork-right':
        return NavigationInstructionType.forkRight;
      case 'ferry':
        return NavigationInstructionType.ferry;
      case 'roundabout-left':
        return NavigationInstructionType.roundaboutLeft;
      case 'roundabout-right':
        return NavigationInstructionType.roundaboutRight;
      default:
        return NavigationInstructionType.straight;
    }
  }

  /// Calculate traffic condition based on duration difference
  TrafficCondition _calculateTrafficCondition(int normalDuration, int trafficDuration) {
    final delay = trafficDuration - normalDuration;
    final delayPercentage = (delay / normalDuration) * 100;
    
    if (delayPercentage < 10) return TrafficCondition.clear;
    if (delayPercentage < 25) return TrafficCondition.light;
    if (delayPercentage < 50) return TrafficCondition.moderate;
    if (delayPercentage < 100) return TrafficCondition.heavy;
    return TrafficCondition.severe;
  }

  /// Calculate simplified route without Google API
  Future<NavigationRoute> _calculateSimplifiedRoute(LatLng origin, LatLng destination) async {
    debugPrint('🗺️ [ENHANCED-NAV] Calculating simplified route');
    
    final distance = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );
    
    // Estimate duration (assuming 40 km/h average speed in city)
    final duration = (distance / 40000 * 3600).round(); // seconds
    
    // Create simple polyline (straight line)
    final polylinePoints = [origin, destination];
    
    // Create basic instruction
    final instruction = NavigationInstruction(
      id: 'instruction_0',
      type: NavigationInstructionType.destination,
      text: 'Head to destination',
      htmlText: 'Head to destination',
      distanceMeters: distance,
      durationSeconds: duration,
      location: origin,
      timestamp: DateTime.now(),
    );
    
    return NavigationRoute(
      id: _generateRouteId(),
      polylinePoints: polylinePoints,
      totalDistanceMeters: distance,
      totalDurationSeconds: duration,
      durationInTrafficSeconds: duration,
      instructions: [instruction],
      overallTrafficCondition: TrafficCondition.unknown,
      summary: 'Direct route to destination',
      calculatedAt: DateTime.now(),
    );
  }

  /// Set up destination geofence for automatic arrival detection
  Future<void> _setupDestinationGeofence(LatLng destination, String orderId) async {
    final geofence = Geofence(
      id: 'destination_$orderId',
      center: GeofenceLocation(
        latitude: destination.latitude,
        longitude: destination.longitude,
      ),
      radius: _arrivalDistance,
      events: [GeofenceEventType.enter],
      orderId: orderId,
      description: 'Destination arrival geofence',
      metadata: {
        'type': 'destination',
        'auto_complete': true,
      },
    );
    
    await _geofencingService.addGeofence(geofence);
    debugPrint('🎯 [ENHANCED-NAV] Destination geofence set up');
  }

  /// Start location tracking for navigation
  Future<void> _startLocationTracking() async {
    debugPrint('📍 [ENHANCED-NAV] Starting location tracking for navigation');
    
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen(
      _handleLocationUpdate,
      onError: (error) {
        debugPrint('❌ [ENHANCED-NAV] Location stream error: $error');
      },
    );
  }

  /// Handle location updates during navigation
  Future<void> _handleLocationUpdate(Position position) async {
    if (_currentSession == null || !_currentSession!.isActive) return;
    
    final currentLocation = LatLng(position.latitude, position.longitude);
    
    // Check for instruction triggers
    await _checkInstructionTriggers(currentLocation);
    
    // Check for arrival
    await _checkArrival(currentLocation);
    
    // Update session progress
    await _updateSessionProgress(currentLocation);
  }

  /// Check if we should trigger the next instruction
  Future<void> _checkInstructionTriggers(LatLng currentLocation) async {
    if (_currentSession == null) return;
    
    final currentInstruction = _currentSession!.currentInstruction;
    if (currentInstruction == null) return;
    
    final distanceToInstruction = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      currentInstruction.location.latitude,
      currentInstruction.location.longitude,
    );
    
    // Trigger instruction if within trigger distance
    if (distanceToInstruction <= _instructionTriggerDistance) {
      await _announceInstruction(currentInstruction);
      
      // Move to next instruction
      final nextIndex = _currentSession!.currentInstructionIndex + 1;
      if (nextIndex < _currentSession!.route.instructions.length) {
        _currentSession = _currentSession!.copyWith(currentInstructionIndex: nextIndex);
        _sessionController.add(_currentSession!);
      }
    }
  }

  /// Check if we've arrived at destination
  Future<void> _checkArrival(LatLng currentLocation) async {
    if (_currentSession == null) return;
    
    final distanceToDestination = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      _currentSession!.destination.latitude,
      _currentSession!.destination.longitude,
    );
    
    if (distanceToDestination <= _arrivalDistance) {
      await _handleArrival();
    }
  }

  /// Handle arrival at destination
  Future<void> _handleArrival() async {
    if (_currentSession == null) return;
    
    debugPrint('🎯 [ENHANCED-NAV] Arrived at destination');
    
    // Announce arrival
    await _voiceService.announceArrival(_currentSession!.destinationName);
    
    // Complete navigation session
    _currentSession = _currentSession!.copyWith(
      status: NavigationSessionStatus.completed,
      endTime: DateTime.now(),
      progressPercentage: 100.0,
    );
    
    _sessionController.add(_currentSession!);
    
    // Stop navigation
    await stopNavigation();
  }

  /// Update session progress
  Future<void> _updateSessionProgress(LatLng currentLocation) async {
    if (_currentSession == null) return;
    
    // Calculate progress based on distance traveled
    final totalDistance = _currentSession!.route.totalDistanceMeters;
    final remainingDistance = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      _currentSession!.destination.latitude,
      _currentSession!.destination.longitude,
    );
    
    final progress = ((totalDistance - remainingDistance) / totalDistance * 100).clamp(0.0, 100.0);
    
    _currentSession = _currentSession!.copyWith(progressPercentage: progress);
    _sessionController.add(_currentSession!);
  }

  /// Announce navigation instruction
  Future<void> _announceInstruction(NavigationInstruction instruction) async {
    debugPrint('🔊 [ENHANCED-NAV] Announcing instruction: ${instruction.text}');

    _instructionController.add(instruction);

    if (_currentSession?.preferences.voiceGuidanceEnabled == true) {
      await _voiceService.announceInstruction(instruction);
    }
  }

  /// Start traffic updates
  void _startTrafficUpdates() {
    _trafficUpdateTimer?.cancel();
    _trafficUpdateTimer = Timer.periodic(_trafficUpdateInterval, (timer) async {
      await _checkTrafficUpdates();
    });
  }

  /// Check for traffic updates and alerts
  Future<void> _checkTrafficUpdates() async {
    if (_currentSession == null || !_currentSession!.isActive) return;

    try {
      // In a real implementation, this would fetch live traffic data
      // For now, we'll simulate traffic alerts based on route conditions
      final trafficCondition = _currentSession!.route.overallTrafficCondition;

      if (trafficCondition == TrafficCondition.heavy || trafficCondition == TrafficCondition.severe) {
        final alertMessage = _getTrafficAlertMessage(trafficCondition);
        _trafficAlertController.add(alertMessage);

        if (_currentSession!.preferences.trafficAlertsEnabled) {
          await _voiceService.announceTrafficAlert(alertMessage);
        }
      }
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error checking traffic updates: $e');
    }
  }

  /// Get traffic alert message
  String _getTrafficAlertMessage(TrafficCondition condition) {
    switch (condition) {
      case TrafficCondition.heavy:
        return 'Heavy traffic ahead. Consider alternative route.';
      case TrafficCondition.severe:
        return 'Severe traffic congestion detected. Significant delays expected.';
      default:
        return 'Traffic conditions have changed.';
    }
  }

  /// Stop navigation
  Future<void> stopNavigation() async {
    debugPrint('🧭 [ENHANCED-NAV] Stopping navigation');

    // Stop location tracking
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    // Stop timers
    _instructionTimer?.cancel();
    _trafficUpdateTimer?.cancel();

    // Clear geofences
    await _geofencingService.clearGeofences();

    // Stop voice guidance
    await _voiceService.stop();

    // Update session status
    if (_currentSession != null && _currentSession!.status == NavigationSessionStatus.active) {
      _currentSession = _currentSession!.copyWith(
        status: NavigationSessionStatus.cancelled,
        endTime: DateTime.now(),
      );
      _sessionController.add(_currentSession!);
    }

    _currentSession = null;
  }

  /// Pause navigation
  Future<void> pauseNavigation() async {
    if (_currentSession == null) return;

    debugPrint('⏸️ [ENHANCED-NAV] Pausing navigation');

    await _locationSubscription?.cancel();
    _instructionTimer?.cancel();
    _trafficUpdateTimer?.cancel();

    _currentSession = _currentSession!.copyWith(status: NavigationSessionStatus.paused);
    _sessionController.add(_currentSession!);
  }

  /// Resume navigation
  Future<void> resumeNavigation() async {
    if (_currentSession == null || _currentSession!.status != NavigationSessionStatus.paused) return;

    debugPrint('▶️ [ENHANCED-NAV] Resuming navigation');

    _currentSession = _currentSession!.copyWith(status: NavigationSessionStatus.active);
    _sessionController.add(_currentSession!);

    await _startLocationTracking();
    _startTrafficUpdates();
  }

  /// Update navigation preferences
  Future<void> updatePreferences(NavigationPreferences preferences) async {
    if (_currentSession == null) return;

    debugPrint('⚙️ [ENHANCED-NAV] Updating navigation preferences');

    _currentSession = _currentSession!.copyWith(preferences: preferences);
    _sessionController.add(_currentSession!);

    // Update voice settings
    if (preferences.voiceGuidanceEnabled) {
      await _voiceService.setLanguage(preferences.language);
      await _voiceService.setVolume(preferences.voiceVolume);
      await _voiceService.setEnabled(true);
    } else {
      await _voiceService.setEnabled(false);
    }
  }

  /// Get current navigation session
  NavigationSession? get currentSession => _currentSession;

  /// Check if navigation is active
  bool get isNavigating => _currentSession?.isActive == true;

  /// Get remaining distance to destination
  Future<double?> getRemainingDistance() async {
    if (_currentSession == null) return null;

    try {
      final currentPosition = await Geolocator.getCurrentPosition();
      return Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        _currentSession!.destination.latitude,
        _currentSession!.destination.longitude,
      );
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error getting remaining distance: $e');
      return null;
    }
  }

  /// Get estimated time of arrival
  Future<DateTime?> getEstimatedArrival() async {
    if (_currentSession == null) return null;

    final remainingDistance = await getRemainingDistance();
    if (remainingDistance == null) return null;

    // Estimate based on average speed (40 km/h in city)
    final remainingTimeSeconds = (remainingDistance / 40000 * 3600).round();
    return DateTime.now().add(Duration(seconds: remainingTimeSeconds));
  }

  /// Utility methods
  String _generateSessionId() {
    return 'nav_session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateRouteId() {
    return 'route_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Dispose resources
  Future<void> dispose() async {
    debugPrint('🧭 [ENHANCED-NAV] Disposing enhanced navigation service');

    await stopNavigation();
    await _instructionController.close();
    await _sessionController.close();
    await _trafficAlertController.close();
    await _voiceService.dispose();
    await _geofencingService.dispose();

    _isInitialized = false;
  }
}
