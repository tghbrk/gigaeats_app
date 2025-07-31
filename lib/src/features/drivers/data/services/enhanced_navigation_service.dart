import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/navigation_models.dart';
import '../models/geofence.dart';
import 'voice_navigation_service.dart';
import 'voice_command_service.dart';
import 'geofencing_service.dart';
import 'traffic_service.dart';
import 'enhanced_3d_navigation_camera_service.dart';
import 'navigation_error_recovery_service.dart';
import 'navigation_battery_optimization_service.dart';
import '../../../../core/config/google_config.dart';

/// Enhanced navigation service with in-app navigation, voice guidance, and traffic-aware routing
/// Integrates with geofencing for automatic status transitions and provides comprehensive navigation features
class EnhancedNavigationService {
  final VoiceNavigationService _voiceService = VoiceNavigationService();
  final VoiceCommandService _voiceCommandService = VoiceCommandService();
  final GeofencingService _geofencingService = GeofencingService();
  final TrafficService _trafficService = TrafficService();
  final Enhanced3DNavigationCameraService _cameraService = Enhanced3DNavigationCameraService();
  final NavigationErrorRecoveryService _errorRecoveryService = NavigationErrorRecoveryService();
  final NavigationBatteryOptimizationService _batteryOptimizationService = NavigationBatteryOptimizationService();
  
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

      // Initialize traffic service
      await _trafficService.initialize();

      // Initialize error recovery service
      await _errorRecoveryService.initialize();

      // Initialize battery optimization service
      await _batteryOptimizationService.initialize();

      _isInitialized = true;
      debugPrint('🧭 [ENHANCED-NAV] Enhanced navigation service initialized');
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error initializing: $e');
      throw Exception('Failed to initialize enhanced navigation: $e');
    }
  }

  /// Initialize enhanced 3D camera service with map controller
  Future<void> initializeCameraService(GoogleMapController mapController) async {
    try {
      debugPrint('📹 [ENHANCED-NAV] Initializing enhanced 3D camera service');
      await _cameraService.initialize(mapController);
      debugPrint('📹 [ENHANCED-NAV] Enhanced 3D camera service initialized');
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error initializing camera service: $e');
      throw Exception('Failed to initialize camera service: $e');
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

      // Initialize voice commands
      await _initializeVoiceCommands(prefs);
      
      // Start navigation session
      _currentSession = session.copyWith(status: NavigationSessionStatus.active);
      _sessionController.add(_currentSession!);
      
      // Start location tracking and instruction monitoring
      await _startLocationTracking();
      _startTrafficUpdates();

      // Start traffic monitoring with the new TrafficService
      await _trafficService.startMonitoring(
        route: _currentSession!.route,
        currentLocation: origin,
      );

      // Start enhanced 3D camera navigation if camera service is initialized
      try {
        await _cameraService.startNavigationCamera(_currentSession!);
        debugPrint('📹 [ENHANCED-NAV] Enhanced 3D camera navigation started');
      } catch (e) {
        debugPrint('⚠️ [ENHANCED-NAV] Camera service not initialized, skipping 3D camera: $e');
      }

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
          final status = data['status'];
          debugPrint('❌ [ENHANCED-NAV] Google Directions API error: $status');

          // Provide specific error messages for common API issues
          String errorMessage;
          String troubleshootingTip;

          switch (status) {
            case 'REQUEST_DENIED':
              errorMessage = 'Google Directions API access denied';
              troubleshootingTip = 'Check API key configuration, billing status, and API restrictions';
              debugPrint('🔧 [ENHANCED-NAV] API Key: ${apiKey.substring(0, 10)}...');
              debugPrint('🔧 [ENHANCED-NAV] Troubleshooting: $troubleshootingTip');
              break;
            case 'OVER_QUERY_LIMIT':
              errorMessage = 'Google Directions API quota exceeded';
              troubleshootingTip = 'API quota limit reached, using fallback route calculation';
              break;
            case 'ZERO_RESULTS':
              errorMessage = 'No route found between locations';
              troubleshootingTip = 'Check if locations are accessible by road';
              break;
            case 'INVALID_REQUEST':
              errorMessage = 'Invalid request parameters';
              troubleshootingTip = 'Check origin and destination coordinates';
              break;
            default:
              errorMessage = 'Google Directions API error: $status';
              troubleshootingTip = 'Using simplified route calculation as fallback';
          }

          // Handle route calculation error with recovery
          final error = NavigationError.routeCalculationFailure(
            errorMessage,
            details: 'API Status: $status, Troubleshooting: $troubleshootingTip',
          );
          await handleNavigationError(error);

          debugPrint('🔄 [ENHANCED-NAV] Falling back to simplified route calculation');
          return await _calculateSimplifiedRoute(origin, destination);
        }
      } else {
        debugPrint('❌ [ENHANCED-NAV] HTTP error: ${response.statusCode}');

        // Handle network error with recovery
        final error = NavigationError.networkFailure(
          'HTTP error: ${response.statusCode}',
          details: 'Failed to fetch route from Google Directions API',
        );
        await handleNavigationError(error);

        return await _calculateSimplifiedRoute(origin, destination);
      }
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error calculating route: $e');

      // Handle generic route calculation error
      final error = NavigationError.routeCalculationFailure(
        'Route calculation failed: $e',
        details: e.toString(),
      );
      await handleNavigationError(error);

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

    // Get optimized location settings based on battery and context
    final locationSettings = _batteryOptimizationService.getOptimizedLocationSettings(
      context: NavigationContext.active,
    );

    debugPrint('📍 [ENHANCED-NAV] Using optimized location settings - Mode: ${_batteryOptimizationService.currentLocationMode}');

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _handleLocationUpdate,
      onError: (error) async {
        debugPrint('❌ [ENHANCED-NAV] Location stream error: $error');

        // Handle GPS signal loss error with recovery
        final navError = NavigationError.gpsSignalLoss(
          'GPS signal lost: $error',
          details: error.toString(),
        );
        await handleNavigationError(navError);
      },
    );
  }

  /// Handle location updates during navigation
  Future<void> _handleLocationUpdate(Position position) async {
    if (_currentSession == null || !_currentSession!.isActive) return;

    final currentLocation = LatLng(position.latitude, position.longitude);
    debugPrint('📍 [ENHANCED-NAV] Location update: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)');

    // Record location update for battery optimization
    _batteryOptimizationService.recordLocationUpdate(position);

    // Update traffic service with current location
    _trafficService.updateLocation(currentLocation);

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

  /// Announce navigation instruction with haptic feedback
  Future<void> _announceInstruction(NavigationInstruction instruction) async {
    debugPrint('🔊 [ENHANCED-NAV] Announcing instruction: ${instruction.text}');

    _instructionController.add(instruction);

    // Provide haptic feedback for navigation instructions
    await _provideHapticFeedback(instruction);

    if (_currentSession?.preferences.voiceGuidanceEnabled == true) {
      await _voiceService.announceInstruction(instruction);
    }
  }

  /// Provide haptic feedback based on instruction type
  Future<void> _provideHapticFeedback(NavigationInstruction instruction) async {
    try {
      switch (instruction.type) {
        case NavigationInstructionType.turnLeft:
        case NavigationInstructionType.turnRight:
        case NavigationInstructionType.turnSlightLeft:
        case NavigationInstructionType.turnSlightRight:
          // Medium impact for regular turns
          await HapticFeedback.mediumImpact();
          debugPrint('🔄 [ENHANCED-NAV] Haptic feedback: Medium impact for turn');
          break;

        case NavigationInstructionType.turnSharpLeft:
        case NavigationInstructionType.turnSharpRight:
        case NavigationInstructionType.uturnLeft:
        case NavigationInstructionType.uturnRight:
        case NavigationInstructionType.uturn:
          // Heavy impact for sharp turns and U-turns (more significant maneuvers)
          await HapticFeedback.heavyImpact();
          debugPrint('🔄 [ENHANCED-NAV] Haptic feedback: Heavy impact for sharp turn/U-turn');
          break;

        case NavigationInstructionType.merge:
        case NavigationInstructionType.rampLeft:
        case NavigationInstructionType.rampRight:
        case NavigationInstructionType.forkLeft:
        case NavigationInstructionType.forkRight:
          // Light impact for merges, ramps, and forks
          await HapticFeedback.lightImpact();
          debugPrint('🔄 [ENHANCED-NAV] Haptic feedback: Light impact for merge/ramp/fork');
          break;

        case NavigationInstructionType.roundabout:
        case NavigationInstructionType.roundaboutLeft:
        case NavigationInstructionType.roundaboutRight:
        case NavigationInstructionType.exitRoundabout:
          // Medium impact for roundabout maneuvers
          await HapticFeedback.mediumImpact();
          debugPrint('🔄 [ENHANCED-NAV] Haptic feedback: Medium impact for roundabout');
          break;

        case NavigationInstructionType.straight:
          // Selection click for continue/straight (subtle feedback)
          await HapticFeedback.selectionClick();
          debugPrint('🔄 [ENHANCED-NAV] Haptic feedback: Selection click for continue straight');
          break;

        case NavigationInstructionType.arrive:
        case NavigationInstructionType.destination:
          // Double vibration pattern for arrival
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 200));
          await HapticFeedback.heavyImpact();
          debugPrint('🔄 [ENHANCED-NAV] Haptic feedback: Double heavy impact for arrival');
          break;

        case NavigationInstructionType.ferry:
          // Light impact for ferry instructions
          await HapticFeedback.lightImpact();
          debugPrint('🔄 [ENHANCED-NAV] Haptic feedback: Light impact for ferry');
          break;
      }
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error providing haptic feedback: $e');
    }
  }

  /// Start traffic updates
  void _startTrafficUpdates() {
    _trafficUpdateTimer?.cancel();
    _trafficUpdateTimer = Timer.periodic(_trafficUpdateInterval, (timer) async {
      await _checkTrafficUpdates();
    });
  }

  /// Check for traffic updates and alerts with haptic feedback
  Future<void> _checkTrafficUpdates() async {
    if (_currentSession == null || !_currentSession!.isActive) return;

    try {
      // In a real implementation, this would fetch live traffic data
      // For now, we'll simulate traffic alerts based on route conditions
      final trafficCondition = _currentSession!.route.overallTrafficCondition;

      if (trafficCondition == TrafficCondition.heavy || trafficCondition == TrafficCondition.severe) {
        final alertMessage = _getTrafficAlertMessage(trafficCondition);
        _trafficAlertController.add(alertMessage);

        // Provide haptic feedback for traffic alerts
        await _provideTrafficHapticFeedback(trafficCondition);

        if (_currentSession!.preferences.trafficAlertsEnabled) {
          await _voiceService.announceTrafficAlert(alertMessage);
        }
      }
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error checking traffic updates: $e');
    }
  }

  /// Provide haptic feedback for traffic conditions
  Future<void> _provideTrafficHapticFeedback(TrafficCondition condition) async {
    try {
      switch (condition) {
        case TrafficCondition.heavy:
          // Medium impact for heavy traffic
          await HapticFeedback.mediumImpact();
          debugPrint('🔄 [ENHANCED-NAV] Haptic feedback: Medium impact for heavy traffic');
          break;

        case TrafficCondition.severe:
          // Heavy impact for severe traffic with double pulse
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.heavyImpact();
          debugPrint('🔄 [ENHANCED-NAV] Haptic feedback: Double heavy impact for severe traffic');
          break;

        case TrafficCondition.moderate:
          // Light impact for moderate traffic
          await HapticFeedback.lightImpact();
          debugPrint('🔄 [ENHANCED-NAV] Haptic feedback: Light impact for moderate traffic');
          break;

        case TrafficCondition.clear:
        case TrafficCondition.light:
        case TrafficCondition.unknown:
          // No haptic feedback for clear/light traffic
          break;
      }
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error providing traffic haptic feedback: $e');
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

    // Stop traffic monitoring
    await _trafficService.stopMonitoring();

    // Clear geofences
    await _geofencingService.clearGeofences();

    // Stop voice guidance
    await _voiceService.stop();

    // Stop enhanced 3D camera navigation
    try {
      await _cameraService.stopNavigationCamera();
      debugPrint('📹 [ENHANCED-NAV] Enhanced 3D camera navigation stopped');
    } catch (e) {
      debugPrint('⚠️ [ENHANCED-NAV] Error stopping camera service: $e');
    }

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

  /// Get remaining distance to destination with validation and error handling
  Future<double?> getRemainingDistance() async {
    if (_currentSession == null) {
      debugPrint('⚠️ [ENHANCED-NAV] No active navigation session for distance calculation');
      return null;
    }

    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Validate current position
      if (!_isValidCoordinate(currentPosition.latitude, currentPosition.longitude)) {
        debugPrint('❌ [ENHANCED-NAV] Invalid current position: ${currentPosition.latitude}, ${currentPosition.longitude}');
        return null;
      }

      // Validate destination coordinates
      if (!_isValidCoordinate(_currentSession!.destination.latitude, _currentSession!.destination.longitude)) {
        debugPrint('❌ [ENHANCED-NAV] Invalid destination coordinates: ${_currentSession!.destination.latitude}, ${_currentSession!.destination.longitude}');
        return null;
      }

      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        _currentSession!.destination.latitude,
        _currentSession!.destination.longitude,
      );

      // Validate calculated distance (should be reasonable for local delivery)
      if (!_isValidDistance(distance)) {
        debugPrint('❌ [ENHANCED-NAV] Unrealistic distance calculated: ${distance}m (${(distance/1000).toStringAsFixed(2)}km)');
        debugPrint('❌ [ENHANCED-NAV] Current: ${currentPosition.latitude}, ${currentPosition.longitude}');
        debugPrint('❌ [ENHANCED-NAV] Destination: ${_currentSession!.destination.latitude}, ${_currentSession!.destination.longitude}');

        // Return null to trigger fallback behavior in UI
        return null;
      }

      debugPrint('📏 [ENHANCED-NAV] Distance calculated: ${distance.toStringAsFixed(1)}m (${(distance/1000).toStringAsFixed(2)}km)');
      debugPrint('📍 [ENHANCED-NAV] From: ${currentPosition.latitude.toStringAsFixed(6)}, ${currentPosition.longitude.toStringAsFixed(6)}');
      debugPrint('🎯 [ENHANCED-NAV] To: ${_currentSession!.destination.latitude.toStringAsFixed(6)}, ${_currentSession!.destination.longitude.toStringAsFixed(6)}');

      return distance;
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error getting remaining distance: $e');
      return null;
    }
  }

  /// Validate if coordinates are reasonable (within Malaysia bounds approximately)
  bool _isValidCoordinate(double latitude, double longitude) {
    // Malaysia bounds: roughly 1°N to 7°N, 99°E to 119°E
    // Adding some buffer for edge cases
    return latitude >= 0.5 && latitude <= 8.0 &&
           longitude >= 98.0 && longitude <= 120.0;
  }

  /// Validate if distance is reasonable for local delivery (max 100km)
  bool _isValidDistance(double distanceMeters) {
    const maxReasonableDistance = 100000; // 100km in meters
    const minReasonableDistance = 1; // 1 meter minimum

    return distanceMeters >= minReasonableDistance &&
           distanceMeters <= maxReasonableDistance;
  }



  /// Get real-time navigation instructions stream
  /// This is the critical missing feature identified in the investigation
  Stream<NavigationInstruction> getNavigationInstructions() async* {
    if (_currentSession == null || !_currentSession!.isActive) {
      debugPrint('❌ [ENHANCED-NAV] Cannot start instruction stream - no active session');
      return;
    }

    debugPrint('🧭 [ENHANCED-NAV] Starting real-time navigation instruction stream');

    // Get optimized location settings for instruction tracking
    final locationSettings = _batteryOptimizationService.getOptimizedLocationSettings(
      context: NavigationContext.active,
    );

    await for (final position in Geolocator.getPositionStream(
      locationSettings: locationSettings,
    )) {
      if (_currentSession == null || !_currentSession!.isActive) break;

      final currentLocation = LatLng(position.latitude, position.longitude);

      // Calculate next instruction based on current location
      final instruction = await _calculateNextInstruction(
        currentLocation: currentLocation,
        route: _currentSession!.route,
        session: _currentSession!,
      );

      if (instruction != null) {
        // Update current instruction index in session
        await _updateCurrentInstruction(instruction);

        // Announce instruction via voice if enabled
        if (_currentSession!.preferences.voiceGuidanceEnabled) {
          await _voiceService.announceInstruction(instruction);
        }

        // Yield the instruction to the stream
        yield instruction;
      }

      // Update session progress
      await _updateSessionProgress(currentLocation);
    }
  }

  /// Calculate next navigation instruction based on current location
  Future<NavigationInstruction?> _calculateNextInstruction({
    required LatLng currentLocation,
    required NavigationRoute route,
    required NavigationSession session,
  }) async {
    try {
      final instructions = route.instructions;
      if (instructions.isEmpty) return null;

      // Find the next instruction based on current location and progress
      for (int i = session.currentInstructionIndex; i < instructions.length; i++) {
        final instruction = instructions[i];
        final distanceToInstruction = Geolocator.distanceBetween(
          currentLocation.latitude,
          currentLocation.longitude,
          instruction.location.latitude,
          instruction.location.longitude,
        );

        // Trigger instruction when within trigger distance
        if (distanceToInstruction <= _instructionTriggerDistance) {
          debugPrint('🧭 [ENHANCED-NAV] Next instruction triggered: ${instruction.text} (${distanceToInstruction.round()}m away)');
          return instruction;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error calculating next instruction: $e');
      return null;
    }
  }

  /// Update current instruction index in session
  Future<void> _updateCurrentInstruction(NavigationInstruction instruction) async {
    if (_currentSession == null) return;

    try {
      final instructions = _currentSession!.route.instructions;
      final instructionIndex = instructions.indexWhere((i) => i.id == instruction.id);

      if (instructionIndex >= 0 && instructionIndex != _currentSession!.currentInstructionIndex) {
        // Update session with new instruction index
        _currentSession = _currentSession!.copyWith(
          currentInstructionIndex: instructionIndex,
        );

        // Notify session update
        _sessionController.add(_currentSession!);

        // Update enhanced 3D camera for new instruction
        try {
          await _cameraService.updateCameraForInstruction(instruction);
          debugPrint('📹 [ENHANCED-NAV] Updated 3D camera for instruction: ${instruction.text}');
        } catch (e) {
          debugPrint('⚠️ [ENHANCED-NAV] Error updating camera for instruction: $e');
        }

        debugPrint('🧭 [ENHANCED-NAV] Updated current instruction index to: $instructionIndex');
      }
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error updating current instruction: $e');
    }
  }

  /// Get estimated time of arrival with traffic-adjusted calculations
  Future<DateTime?> getEstimatedArrival() async {
    if (_currentSession == null) return null;

    try {
      final remainingDistance = await getRemainingDistance();
      if (remainingDistance == null) return null;

      // Calculate remaining time based on current progress and traffic conditions
      final route = _currentSession!.route;
      final totalDistance = route.totalDistanceMeters;

      if (totalDistance <= 0) return null;

      final progressRatio = 1.0 - (remainingDistance / totalDistance);

      // Use traffic-adjusted duration for more accurate ETA
      final totalDurationWithTraffic = route.durationInTrafficSeconds;
      final remainingDuration = totalDurationWithTraffic * (1.0 - progressRatio);

      // Apply traffic condition multiplier for real-time adjustments
      final trafficMultiplier = _getTrafficMultiplier(route.overallTrafficCondition);
      final adjustedDuration = remainingDuration * trafficMultiplier;

      debugPrint('🧭 [ENHANCED-NAV] ETA calculation - Distance: ${remainingDistance.round()}m, Duration: ${adjustedDuration.round()}s, Traffic: ${route.overallTrafficCondition}');

      return DateTime.now().add(Duration(seconds: adjustedDuration.round()));
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error calculating estimated arrival: $e');

      // Fallback to simple calculation
      final remainingDistance = await getRemainingDistance();
      if (remainingDistance != null) {
        final remainingTimeSeconds = (remainingDistance / 40000 * 3600).round();
        return DateTime.now().add(Duration(seconds: remainingTimeSeconds));
      }

      return null;
    }
  }

  /// Get traffic condition multiplier for ETA calculations
  double _getTrafficMultiplier(TrafficCondition condition) {
    switch (condition) {
      case TrafficCondition.clear:
        return 0.9; // 10% faster than expected
      case TrafficCondition.light:
        return 1.0; // As expected
      case TrafficCondition.moderate:
        return 1.2; // 20% slower
      case TrafficCondition.heavy:
        return 1.5; // 50% slower
      case TrafficCondition.severe:
        return 2.0; // 100% slower
      case TrafficCondition.unknown:
        return 1.1; // Slightly conservative
    }
  }

  /// Get camera position updates for automatic following during navigation
  /// This provides the InAppNavigationScreen with camera position updates
  Stream<CameraPosition> getCameraPositionUpdates() async* {
    if (_currentSession == null || !_currentSession!.isActive) {
      debugPrint('❌ [ENHANCED-NAV] Cannot start camera updates - no active session');
      return;
    }

    debugPrint('📹 [ENHANCED-NAV] Starting automatic camera following');

    await for (final position in Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update camera every 10 meters
      ),
    )) {
      if (_currentSession == null || !_currentSession!.isActive) break;

      final currentLocation = LatLng(position.latitude, position.longitude);

      // Calculate bearing to next instruction or destination
      final bearing = await _calculateNavigationBearing(currentLocation);

      // Create camera position with 3D navigation perspective
      final cameraPosition = CameraPosition(
        target: currentLocation,
        zoom: 18.0, // Close zoom for navigation
        bearing: bearing,
        tilt: 60.0, // 3D perspective
      );

      debugPrint('📹 [ENHANCED-NAV] Camera update - Lat: ${currentLocation.latitude.toStringAsFixed(6)}, Lng: ${currentLocation.longitude.toStringAsFixed(6)}, Bearing: ${bearing.toStringAsFixed(1)}°');

      yield cameraPosition;
    }
  }

  /// Calculate navigation bearing based on current location and route
  Future<double> _calculateNavigationBearing(LatLng currentLocation) async {
    if (_currentSession == null) return 0.0;

    try {
      final route = _currentSession!.route;
      final instructions = route.instructions;

      // If we have a current instruction, calculate bearing to it
      if (_currentSession!.currentInstructionIndex < instructions.length) {
        final nextInstruction = instructions[_currentSession!.currentInstructionIndex];
        return _calculateBearing(currentLocation, nextInstruction.location);
      }

      // Otherwise, calculate bearing to destination
      return _calculateBearing(currentLocation, _currentSession!.destination);
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error calculating navigation bearing: $e');
      return 0.0;
    }
  }

  /// Calculate bearing between two points
  double _calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * (pi / 180);
    final startLng = start.longitude * (pi / 180);
    final endLat = end.latitude * (pi / 180);
    final endLng = end.longitude * (pi / 180);

    final dLng = endLng - startLng;

    final y = sin(dLng) * cos(endLat);
    final x = cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);

    final bearing = atan2(y, x) * (180 / pi);
    return (bearing + 360) % 360;
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

  /// Handle navigation errors with enhanced recovery strategies and user feedback
  Future<NavigationErrorRecoveryResult> handleNavigationError(NavigationError error) async {
    debugPrint('🛡️ [ENHANCED-NAV] Handling navigation error: ${error.type} - ${error.message}');

    try {
      // Provide haptic feedback for error
      await _provideErrorHapticFeedback(error.type);

      // Stop voice commands during error handling
      await stopVoiceCommandListening();

      final result = await _errorRecoveryService.handleNavigationError(error, _currentSession);

      // Handle recovery result with appropriate feedback
      await _handleErrorRecoveryResult(result);

      // Log recovery result
      debugPrint('🛡️ [ENHANCED-NAV] Error recovery result: ${result.type} - ${result.message}');

      return result;
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error in error recovery: $e');

      // Provide critical error haptic feedback
      await _provideCriticalErrorFeedback();

      // Fallback to basic error handling
      return NavigationErrorRecoveryResult.failed(
        'Navigation error occurred and recovery failed. Please restart navigation.',
      );
    }
  }

  /// Provide haptic feedback based on error type
  Future<void> _provideErrorHapticFeedback(NavigationErrorType errorType) async {
    try {
      switch (errorType) {
        case NavigationErrorType.gpsSignalLoss:
          // Double medium impact for GPS issues
          await HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 150));
          await HapticFeedback.mediumImpact();
          debugPrint('🔄 [ENHANCED-NAV] Haptic feedback: GPS signal loss');
          break;

        case NavigationErrorType.networkFailure:
          // Light impact pattern for network issues
          await HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.lightImpact();
          debugPrint('🔄 [ENHANCED-NAV] Haptic feedback: Network failure');
          break;

        case NavigationErrorType.routeCalculationFailure:
        case NavigationErrorType.mapLoadingFailure:
          // Medium impact for route/map issues
          await HapticFeedback.mediumImpact();
          debugPrint('🔄 [ENHANCED-NAV] Haptic feedback: Route/map error');
          break;

        case NavigationErrorType.criticalSystemFailure:
          // Heavy impact for critical errors
          await HapticFeedback.heavyImpact();
          debugPrint('🔄 [ENHANCED-NAV] Haptic feedback: Critical system failure');
          break;

        default:
          // Light impact for other errors
          await HapticFeedback.lightImpact();
          debugPrint('🔄 [ENHANCED-NAV] Haptic feedback: General error');
      }
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error providing error haptic feedback: $e');
    }
  }

  /// Handle error recovery result with appropriate actions
  Future<void> _handleErrorRecoveryResult(NavigationErrorRecoveryResult result) async {
    try {
      switch (result.type) {
        case NavigationErrorRecoveryType.retry:
          // Retry feedback - restart voice commands
          await HapticFeedback.lightImpact();
          await startVoiceCommandListening();
          debugPrint('🔄 [ENHANCED-NAV] Retrying navigation, resuming normal operation');
          break;

        case NavigationErrorRecoveryType.degraded:
          // Degraded service feedback - limited functionality
          await HapticFeedback.mediumImpact();
          debugPrint('⚠️ [ENHANCED-NAV] Degraded mode activated: ${result.degradedFeatures?.join(', ')}');
          break;

        case NavigationErrorRecoveryType.externalNavigation:
          // External navigation feedback - switching apps
          await HapticFeedback.heavyImpact();
          debugPrint('🚀 [ENHANCED-NAV] Switching to external navigation');
          break;

        case NavigationErrorRecoveryType.failed:
          // Failure feedback - critical error
          await _provideCriticalErrorFeedback();
          debugPrint('❌ [ENHANCED-NAV] Error recovery failed');
          break;

        case NavigationErrorRecoveryType.networkUnavailable:
        case NavigationErrorRecoveryType.permissionRequired:
        case NavigationErrorRecoveryType.serviceRequired:
          // User action required feedback - attention needed
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 200));
          await HapticFeedback.heavyImpact();
          debugPrint('👤 [ENHANCED-NAV] User action required: ${result.type}');
          break;

        case NavigationErrorRecoveryType.cooldown:
          // Cooldown feedback - wait period
          await HapticFeedback.mediumImpact();
          debugPrint('⏳ [ENHANCED-NAV] Error recovery in cooldown period');
          break;
      }
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error handling recovery result: $e');
    }
  }

  /// Provide critical error haptic feedback pattern
  Future<void> _provideCriticalErrorFeedback() async {
    try {
      // Critical error pattern: three heavy impacts
      for (int i = 0; i < 3; i++) {
        await HapticFeedback.heavyImpact();
        if (i < 2) await Future.delayed(const Duration(milliseconds: 200));
      }
      debugPrint('🔄 [ENHANCED-NAV] Haptic feedback: Critical error pattern');
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error providing critical error feedback: $e');
    }
  }

  /// Launch external navigation app
  Future<bool> launchExternalNavigation(ExternalNavApp app, LatLng destination, {LatLng? origin}) async {
    try {
      debugPrint('🚀 [ENHANCED-NAV] Launching external navigation: ${app.name}');

      final success = await _errorRecoveryService.launchExternalNavigation(app, destination, origin: origin);

      if (success) {
        // Stop current navigation since we're switching to external app
        await stopNavigation();
        debugPrint('🚀 [ENHANCED-NAV] Successfully launched ${app.name}');
      } else {
        debugPrint('❌ [ENHANCED-NAV] Failed to launch ${app.name}');
      }

      return success;
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error launching external navigation: $e');
      return false;
    }
  }

  /// Get available external navigation apps
  Future<List<ExternalNavApp>> getAvailableExternalNavApps() async {
    try {
      // This would typically call the error recovery service method
      // For now, return a basic list
      return [
        const ExternalNavApp(
          name: 'Google Maps',
          packageName: 'com.google.android.apps.maps',
          platform: 'android',
        ),
        const ExternalNavApp(
          name: 'Waze',
          packageName: 'com.waze',
          platform: 'android',
        ),
      ];
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error getting external nav apps: $e');
      return [];
    }
  }

  /// Check network connectivity status
  bool get isNetworkAvailable => _errorRecoveryService.isNetworkAvailable;

  /// Check GPS signal strength
  bool get isGpsSignalStrong => _errorRecoveryService.isGpsSignalStrong;

  /// Reset error recovery counters
  void resetErrorCounters() {
    _errorRecoveryService.resetErrorCounters();
  }

  /// Enter background mode for battery optimization
  void enterBackgroundMode() {
    debugPrint('🔋 [ENHANCED-NAV] Entering background mode');
    _batteryOptimizationService.enterBackgroundMode();
  }

  /// Exit background mode
  void exitBackgroundMode() {
    debugPrint('🔋 [ENHANCED-NAV] Exiting background mode');
    _batteryOptimizationService.exitBackgroundMode();
  }

  /// Update navigation context for adaptive location tracking
  void updateNavigationContext(NavigationContext context) {
    debugPrint('🔋 [ENHANCED-NAV] Updating navigation context: $context');
    _batteryOptimizationService.updateLocationMode(context);
  }

  /// Get battery optimization recommendations
  NavigationBatteryOptimizationRecommendations getBatteryOptimizationRecommendations() {
    return _batteryOptimizationService.getOptimizationRecommendations();
  }

  /// Get current battery level
  int get currentBatteryLevel => _batteryOptimizationService.currentBatteryLevel;

  /// Get current location mode
  NavigationLocationMode get currentLocationMode => _batteryOptimizationService.currentLocationMode;

  /// Check if in background mode
  bool get isInBackgroundMode => _batteryOptimizationService.isInBackgroundMode;

  /// Initialize voice commands for hands-free navigation control
  Future<void> _initializeVoiceCommands(NavigationPreferences prefs) async {
    try {
      debugPrint('🎤 [ENHANCED-NAV] Initializing voice commands');

      await _voiceCommandService.initialize(
        language: prefs.language,
        enabled: true, // Always enable voice commands during navigation
      );

      // Set up voice command callbacks
      _voiceCommandService.onMuteVoice = () async {
        debugPrint('🎤 [ENHANCED-NAV] Voice command: Mute voice');
        await _voiceService.setEnabled(false);
        await HapticFeedback.selectionClick();
      };

      _voiceCommandService.onUnmuteVoice = () async {
        debugPrint('🎤 [ENHANCED-NAV] Voice command: Unmute voice');
        await _voiceService.setEnabled(true);
        await HapticFeedback.selectionClick();
      };

      _voiceCommandService.onRepeatInstruction = () async {
        debugPrint('🎤 [ENHANCED-NAV] Voice command: Repeat instruction');
        final currentInstruction = _currentSession?.route.instructions.isNotEmpty == true
            ? _currentSession!.route.instructions.first
            : null;
        if (currentInstruction != null) {
          await _voiceService.announceInstruction(currentInstruction);
          await HapticFeedback.lightImpact();
        }
      };

      _voiceCommandService.onStopNavigation = () async {
        debugPrint('🎤 [ENHANCED-NAV] Voice command: Stop navigation');
        await stopNavigation();
        await HapticFeedback.heavyImpact();
      };

      debugPrint('🎤 [ENHANCED-NAV] Voice commands initialized successfully');
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error initializing voice commands: $e');
    }
  }

  /// Start listening for voice commands
  Future<void> startVoiceCommandListening() async {
    try {
      await _voiceCommandService.startListening();
      debugPrint('🎤 [ENHANCED-NAV] Started listening for voice commands');
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error starting voice command listening: $e');
    }
  }

  /// Stop listening for voice commands
  Future<void> stopVoiceCommandListening() async {
    try {
      await _voiceCommandService.stopListening();
      debugPrint('🎤 [ENHANCED-NAV] Stopped listening for voice commands');
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV] Error stopping voice command listening: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    debugPrint('🧭 [ENHANCED-NAV] Disposing enhanced navigation service');

    await stopNavigation();
    await _instructionController.close();
    await _sessionController.close();
    await _trafficAlertController.close();
    await _voiceService.dispose();
    _voiceCommandService.dispose();
    await _geofencingService.dispose();
    _trafficService.dispose();
    await _cameraService.dispose();
    await _errorRecoveryService.dispose();
    await _batteryOptimizationService.dispose();

    _isInitialized = false;
  }
}
