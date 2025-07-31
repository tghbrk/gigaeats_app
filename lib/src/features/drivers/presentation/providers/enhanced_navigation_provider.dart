import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:battery_plus/battery_plus.dart';

import '../../data/models/navigation_models.dart';
import '../../data/services/enhanced_navigation_service.dart';

/// Enhanced navigation state
@immutable
class EnhancedNavigationState {
  final NavigationSession? currentSession;
  final NavigationInstruction? currentInstruction;
  final NavigationInstruction? nextInstruction;
  final List<String> recentTrafficAlerts;
  final bool isNavigating;
  final bool isVoiceEnabled;
  final double? remainingDistance;
  final DateTime? estimatedArrival;
  final String? error;

  const EnhancedNavigationState({
    this.currentSession,
    this.currentInstruction,
    this.nextInstruction,
    this.recentTrafficAlerts = const [],
    this.isNavigating = false,
    this.isVoiceEnabled = true,
    this.remainingDistance,
    this.estimatedArrival,
    this.error,
  });

  EnhancedNavigationState copyWith({
    NavigationSession? currentSession,
    NavigationInstruction? currentInstruction,
    NavigationInstruction? nextInstruction,
    List<String>? recentTrafficAlerts,
    bool? isNavigating,
    bool? isVoiceEnabled,
    double? remainingDistance,
    DateTime? estimatedArrival,
    String? error,
  }) {
    return EnhancedNavigationState(
      currentSession: currentSession ?? this.currentSession,
      currentInstruction: currentInstruction ?? this.currentInstruction,
      nextInstruction: nextInstruction ?? this.nextInstruction,
      recentTrafficAlerts: recentTrafficAlerts ?? this.recentTrafficAlerts,
      isNavigating: isNavigating ?? this.isNavigating,
      isVoiceEnabled: isVoiceEnabled ?? this.isVoiceEnabled,
      remainingDistance: remainingDistance ?? this.remainingDistance,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      error: error,
    );
  }
}

/// Enhanced navigation provider
class EnhancedNavigationNotifier extends StateNotifier<EnhancedNavigationState> {
  final EnhancedNavigationService _navigationService = EnhancedNavigationService();
  
  StreamSubscription<NavigationSession>? _sessionSubscription;
  StreamSubscription<NavigationInstruction>? _instructionSubscription;
  StreamSubscription<String>? _trafficAlertSubscription;
  Timer? _updateTimer;

  EnhancedNavigationNotifier() : super(const EnhancedNavigationState()) {
    debugPrint('🧭 [ENHANCED-NAV-PROVIDER] EnhancedNavigationNotifier initialized');
    _initialize();
  }

  /// Initialize the navigation service and set up listeners
  Future<void> _initialize() async {
    try {
      debugPrint('🧭 [ENHANCED-NAV-PROVIDER] Initializing enhanced navigation provider');
      
      await _navigationService.initialize();
      
      // Listen to navigation sessions
      _sessionSubscription = _navigationService.sessionStream.listen(
        _handleSessionUpdate,
        onError: (error) {
          debugPrint('❌ [ENHANCED-NAV-PROVIDER] Session stream error: $error');
          state = state.copyWith(error: error.toString());
        },
      );
      
      // Listen to navigation instructions
      _instructionSubscription = _navigationService.instructionStream.listen(
        _handleInstructionUpdate,
        onError: (error) {
          debugPrint('❌ [ENHANCED-NAV-PROVIDER] Instruction stream error: $error');
        },
      );
      
      // Listen to traffic alerts
      _trafficAlertSubscription = _navigationService.trafficAlertStream.listen(
        _handleTrafficAlert,
        onError: (error) {
          debugPrint('❌ [ENHANCED-NAV-PROVIDER] Traffic alert stream error: $error');
        },
      );
      
      debugPrint('🧭 [ENHANCED-NAV-PROVIDER] Enhanced navigation provider initialized');
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Error initializing: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Initialize enhanced 3D camera service with map controller
  Future<void> initializeCameraService(GoogleMapController mapController) async {
    try {
      debugPrint('📹 [ENHANCED-NAV-PROVIDER] Initializing enhanced 3D camera service');
      await _navigationService.initializeCameraService(mapController);
      debugPrint('📹 [ENHANCED-NAV-PROVIDER] Enhanced 3D camera service initialized');
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Error initializing camera service: $e');
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Start in-app navigation
  Future<bool> startNavigation({
    required LatLng origin,
    required LatLng destination,
    required String orderId,
    String? batchId,
    String? destinationName,
    NavigationPreferences? preferences,
  }) async {
    try {
      debugPrint('🧭 [ENHANCED-NAV-PROVIDER] Starting navigation for order: $orderId');
      debugPrint('🧭 [ENHANCED-NAV-PROVIDER] Origin: ${origin.latitude}, ${origin.longitude}');
      debugPrint('🧭 [ENHANCED-NAV-PROVIDER] Destination: ${destination.latitude}, ${destination.longitude}');
      debugPrint('🧭 [ENHANCED-NAV-PROVIDER] Destination name: $destinationName');

      // Clear any previous error state
      state = state.copyWith(error: null);

      final session = await _navigationService.startInAppNavigation(
        origin: origin,
        destination: destination,
        orderId: orderId,
        batchId: batchId,
        destinationName: destinationName,
        preferences: preferences,
      );

      debugPrint('🧭 [ENHANCED-NAV-PROVIDER] Navigation session created: ${session.id}');
      debugPrint('🧭 [ENHANCED-NAV-PROVIDER] Session status: ${session.status}');
      debugPrint('🧭 [ENHANCED-NAV-PROVIDER] Route distance: ${session.route.totalDistanceMeters}m');
      debugPrint('🧭 [ENHANCED-NAV-PROVIDER] Route duration: ${session.route.totalDurationSeconds}s');

      state = state.copyWith(
        currentSession: session,
        isNavigating: true,
        isVoiceEnabled: session.preferences.voiceGuidanceEnabled,
        error: null,
      );

      debugPrint('✅ [ENHANCED-NAV-PROVIDER] Navigation started successfully');
      debugPrint('✅ [ENHANCED-NAV-PROVIDER] Provider state updated - isNavigating: ${state.isNavigating}');

      // Start periodic updates
      _startPeriodicUpdates();

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Error starting navigation: $e');
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Stack trace: $stackTrace');

      // Determine error type and provide helpful message
      String errorMessage;
      if (e.toString().contains('Failed to calculate route')) {
        errorMessage = 'Unable to calculate route. Please check your internet connection and try again.';
      } else if (e.toString().contains('Google API')) {
        errorMessage = 'Navigation service temporarily unavailable. Please try external navigation.';
      } else if (e.toString().contains('GPS') || e.toString().contains('location')) {
        errorMessage = 'GPS signal required. Please enable location services and try again.';
      } else {
        errorMessage = 'Navigation setup failed: ${e.toString()}';
      }

      state = state.copyWith(
        error: errorMessage,
        isNavigating: false,
        currentSession: null,
      );

      return false;
    }
  }

  /// Stop navigation
  Future<void> stopNavigation() async {
    try {
      debugPrint('🧭 [ENHANCED-NAV-PROVIDER] Stopping navigation');
      
      await _navigationService.stopNavigation();
      _stopPeriodicUpdates();
      
      state = state.copyWith(
        currentSession: null,
        currentInstruction: null,
        nextInstruction: null,
        isNavigating: false,
        remainingDistance: null,
        estimatedArrival: null,
        error: null,
      );
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Error stopping navigation: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Pause navigation
  Future<void> pauseNavigation() async {
    try {
      await _navigationService.pauseNavigation();
      _stopPeriodicUpdates();
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Error pausing navigation: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Resume navigation
  Future<void> resumeNavigation() async {
    try {
      await _navigationService.resumeNavigation();
      _startPeriodicUpdates();
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Error resuming navigation: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update navigation preferences
  Future<void> updatePreferences(NavigationPreferences preferences) async {
    try {
      await _navigationService.updatePreferences(preferences);

      if (state.currentSession != null) {
        state = state.copyWith(
          currentSession: state.currentSession!.copyWith(preferences: preferences),
          isVoiceEnabled: preferences.voiceGuidanceEnabled,
        );
      }
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Error updating preferences: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Launch external navigation app
  Future<bool> launchExternalNavigation(ExternalNavApp app, LatLng destination, {LatLng? origin}) async {
    try {
      debugPrint('🚀 [ENHANCED-NAV-PROVIDER] Launching external navigation: ${app.name}');

      final success = await _navigationService.launchExternalNavigation(app, destination, origin: origin);

      if (success) {
        // Stop current navigation since we're switching to external app
        await stopNavigation();
        debugPrint('🚀 [ENHANCED-NAV-PROVIDER] Successfully launched ${app.name}');
      }

      return success;
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Error launching external navigation: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Handle navigation error with recovery
  Future<NavigationErrorRecoveryResult> handleNavigationError(NavigationError error) async {
    try {
      debugPrint('🛡️ [ENHANCED-NAV-PROVIDER] Handling navigation error: ${error.type}');

      final result = await _navigationService.handleNavigationError(error);

      // Update state based on recovery result
      if (result.type == NavigationErrorRecoveryType.failed) {
        state = state.copyWith(error: result.message);
      }

      return result;
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Error in error recovery: $e');
      state = state.copyWith(error: e.toString());

      return NavigationErrorRecoveryResult.failed(
        'Error recovery failed: $e',
      );
    }
  }

  /// Get available external navigation apps
  Future<List<ExternalNavApp>> getAvailableExternalNavApps() async {
    try {
      return await _navigationService.getAvailableExternalNavApps();
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Error getting external nav apps: $e');
      return [];
    }
  }

  /// Enter background mode for battery optimization
  void enterBackgroundMode() {
    try {
      debugPrint('🔋 [ENHANCED-NAV-PROVIDER] Entering background mode');
      _navigationService.enterBackgroundMode();
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Error entering background mode: $e');
    }
  }

  /// Exit background mode
  void exitBackgroundMode() {
    try {
      debugPrint('🔋 [ENHANCED-NAV-PROVIDER] Exiting background mode');
      _navigationService.exitBackgroundMode();
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Error exiting background mode: $e');
    }
  }

  /// Update navigation context for adaptive location tracking
  void updateNavigationContext(NavigationContext context) {
    try {
      debugPrint('🔋 [ENHANCED-NAV-PROVIDER] Updating navigation context: $context');
      _navigationService.updateNavigationContext(context);
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Error updating navigation context: $e');
    }
  }

  /// Get battery optimization recommendations
  NavigationBatteryOptimizationRecommendations getBatteryOptimizationRecommendations() {
    try {
      return _navigationService.getBatteryOptimizationRecommendations();
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Error getting battery recommendations: $e');
      // Return default recommendations on error
      return NavigationBatteryOptimizationRecommendations(
        batteryLevel: 50, // Default battery level
        batteryState: BatteryState.unknown,
        currentLocationMode: NavigationLocationMode.balanced,
        recommendations: ['Unable to get battery recommendations'],
        criticalActions: [],
      );
    }
  }

  /// Handle session updates
  void _handleSessionUpdate(NavigationSession session) {
    debugPrint('🧭 [ENHANCED-NAV-PROVIDER] Session update: ${session.status}');
    
    state = state.copyWith(
      currentSession: session,
      isNavigating: session.isActive,
      currentInstruction: session.currentInstruction,
      nextInstruction: session.nextInstruction,
    );
    
    // Stop updates if navigation completed or cancelled
    if (session.isCompleted || session.status == NavigationSessionStatus.cancelled) {
      _stopPeriodicUpdates();
    }
  }

  /// Handle instruction updates
  void _handleInstructionUpdate(NavigationInstruction instruction) {
    debugPrint('🧭 [ENHANCED-NAV-PROVIDER] Instruction update: ${instruction.text}');
    
    state = state.copyWith(currentInstruction: instruction);
  }

  /// Handle traffic alerts
  void _handleTrafficAlert(String alert) {
    debugPrint('🚦 [ENHANCED-NAV-PROVIDER] Traffic alert: $alert');
    
    final updatedAlerts = List<String>.from(state.recentTrafficAlerts);
    updatedAlerts.insert(0, alert);
    
    // Keep only last 5 alerts
    if (updatedAlerts.length > 5) {
      updatedAlerts.removeLast();
    }
    
    state = state.copyWith(recentTrafficAlerts: updatedAlerts);
  }

  /// Start periodic updates for distance and ETA
  void _startPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _updateNavigationData();
    });
  }

  /// Stop periodic updates
  void _stopPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Update navigation data (distance, ETA)
  Future<void> _updateNavigationData() async {
    if (!state.isNavigating) return;
    
    try {
      final remainingDistance = await _navigationService.getRemainingDistance();
      final estimatedArrival = await _navigationService.getEstimatedArrival();
      
      state = state.copyWith(
        remainingDistance: remainingDistance,
        estimatedArrival: estimatedArrival,
      );
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Error updating navigation data: $e');
    }
  }

  /// Get formatted remaining distance with enhanced validation
  String? get remainingDistanceText {
    final distance = state.remainingDistance;
    if (distance == null) return null;

    // Validate distance is reasonable
    if (distance < 0) {
      debugPrint('⚠️ [ENHANCED-NAV-PROVIDER] Negative distance detected: $distance');
      return null;
    }

    if (distance > 100000) { // > 100km
      debugPrint('⚠️ [ENHANCED-NAV-PROVIDER] Unrealistic distance detected: ${distance}m (${(distance/1000).toStringAsFixed(2)}km)');
      return null;
    }

    // Format based on distance magnitude
    if (distance < 10) {
      return '${distance.toStringAsFixed(1)}m';
    } else if (distance < 1000) {
      return '${distance.round()}m';
    } else if (distance < 10000) {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    } else {
      return '${(distance / 1000).round()}km';
    }
  }

  /// Get formatted estimated arrival time with enhanced validation
  String? get estimatedArrivalText {
    final eta = state.estimatedArrival;
    if (eta == null) return null;

    final now = DateTime.now();
    final difference = eta.difference(now);

    // Handle past times (should not happen in normal navigation)
    if (difference.isNegative) {
      debugPrint('⚠️ [ENHANCED-NAV-PROVIDER] ETA is in the past: $eta');
      return 'Overdue';
    }

    // Handle unrealistic future times (more than 24 hours)
    if (difference.inHours > 24) {
      debugPrint('⚠️ [ENHANCED-NAV-PROVIDER] Unrealistic ETA detected: $eta (${difference.inHours}h from now)');
      return null;
    }

    // Format based on time remaining
    if (difference.inSeconds < 30) {
      return 'Arriving';
    } else if (difference.inMinutes < 1) {
      return '<1min';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}min';
      }
    }
  }

  /// Get route polyline points for map display
  List<LatLng>? get routePolylinePoints {
    return state.currentSession?.route.polylinePoints;
  }

  /// Get current navigation progress percentage
  double get progressPercentage {
    return state.currentSession?.progressPercentage ?? 0.0;
  }

  /// Get real-time navigation instructions stream
  /// This exposes the new real-time instruction streaming feature
  Stream<NavigationInstruction>? getNavigationInstructionsStream() {
    if (!state.isNavigating || state.currentSession == null) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Cannot get instruction stream - not navigating');
      return null;
    }

    debugPrint('🧭 [ENHANCED-NAV-PROVIDER] Starting real-time instruction stream');
    return _navigationService.getNavigationInstructions();
  }

  /// Get camera position updates for automatic following
  /// This exposes the new automatic camera following feature
  Stream<CameraPosition>? getCameraPositionUpdates() {
    if (!state.isNavigating || state.currentSession == null) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Cannot get camera updates - not navigating');
      return null;
    }

    debugPrint('📹 [ENHANCED-NAV-PROVIDER] Starting automatic camera following');
    return _navigationService.getCameraPositionUpdates();
  }

  /// Force refresh of navigation data (distance, ETA)
  Future<void> refreshNavigationData() async {
    if (!state.isNavigating) return;

    debugPrint('🔄 [ENHANCED-NAV-PROVIDER] Refreshing navigation data');
    await _updateNavigationData();
  }

  @override
  void dispose() {
    debugPrint('🧭 [ENHANCED-NAV-PROVIDER] Disposing enhanced navigation provider');
    
    _sessionSubscription?.cancel();
    _instructionSubscription?.cancel();
    _trafficAlertSubscription?.cancel();
    _stopPeriodicUpdates();
    _navigationService.dispose();
    
    super.dispose();
  }
}

/// Enhanced navigation provider
final enhancedNavigationProvider = StateNotifierProvider<EnhancedNavigationNotifier, EnhancedNavigationState>((ref) {
  return EnhancedNavigationNotifier();
});

/// Current navigation session provider
final currentNavigationSessionProvider = Provider<NavigationSession?>((ref) {
  return ref.watch(enhancedNavigationProvider).currentSession;
});

/// Current navigation instruction provider
final currentNavigationInstructionProvider = Provider<NavigationInstruction?>((ref) {
  return ref.watch(enhancedNavigationProvider).currentInstruction;
});

/// Navigation route polyline provider
final navigationRoutePolylineProvider = Provider<List<LatLng>?>((ref) {
  return ref.watch(enhancedNavigationProvider.notifier).routePolylinePoints;
});

/// Remaining distance text provider
final remainingDistanceTextProvider = Provider<String?>((ref) {
  return ref.watch(enhancedNavigationProvider.notifier).remainingDistanceText;
});

/// Estimated arrival text provider
final estimatedArrivalTextProvider = Provider<String?>((ref) {
  return ref.watch(enhancedNavigationProvider.notifier).estimatedArrivalText;
});

/// Navigation progress provider
final navigationProgressProvider = Provider<double>((ref) {
  return ref.watch(enhancedNavigationProvider.notifier).progressPercentage;
});
