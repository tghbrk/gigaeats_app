import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
      
      final session = await _navigationService.startInAppNavigation(
        origin: origin,
        destination: destination,
        orderId: orderId,
        batchId: batchId,
        destinationName: destinationName,
        preferences: preferences,
      );
      
      state = state.copyWith(
        currentSession: session,
        isNavigating: true,
        isVoiceEnabled: session.preferences.voiceGuidanceEnabled,
        error: null,
      );
      
      // Start periodic updates
      _startPeriodicUpdates();
      
      return true;
    } catch (e) {
      debugPrint('❌ [ENHANCED-NAV-PROVIDER] Error starting navigation: $e');
      state = state.copyWith(error: e.toString());
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

  /// Get formatted remaining distance
  String? get remainingDistanceText {
    final distance = state.remainingDistance;
    if (distance == null) return null;
    
    if (distance < 1000) {
      return '${distance.round()}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Get formatted estimated arrival time
  String? get estimatedArrivalText {
    final eta = state.estimatedArrival;
    if (eta == null) return null;
    
    final now = DateTime.now();
    final difference = eta.difference(now);
    
    if (difference.inMinutes < 1) {
      return 'Arriving now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}min';
    } else {
      return '${difference.inHours}h ${difference.inMinutes % 60}min';
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
