import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/navigation_models.dart';

/// Comprehensive navigation error recovery service for the GigaEats Enhanced In-App Navigation System
/// Handles graceful fallback to external navigation apps, network failure recovery, and GPS signal loss
class NavigationErrorRecoveryService {
  static const String _tag = 'NAV-ERROR-RECOVERY';
  
  // Network connectivity monitoring
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isNetworkAvailable = true;
  
  // GPS signal monitoring
  StreamSubscription<Position>? _gpsMonitoringSubscription;
  bool _isGpsSignalStrong = true;
  DateTime? _lastGpsSignalTime;
  
  // Error recovery state
  int _consecutiveNetworkErrors = 0;
  int _consecutiveGpsErrors = 0;
  DateTime? _lastErrorTime;
  
  // Recovery thresholds
  static const int _maxNetworkRetries = 3;
  static const int _maxGpsRetries = 5;
  static const Duration _gpsSignalTimeout = Duration(seconds: 30);
  static const Duration _networkRetryDelay = Duration(seconds: 5);
  static const Duration _errorCooldownPeriod = Duration(minutes: 2);
  
  // External navigation apps
  static const Map<String, String> _externalNavApps = {
    'google_maps': 'com.google.android.apps.maps',
    'waze': 'com.waze',
    'apple_maps': 'com.apple.Maps', // iOS only
  };
  
  bool _isInitialized = false;
  
  /// Initialize the error recovery service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('🛡️ [$_tag] Initializing navigation error recovery service');
    
    try {
      // Start network connectivity monitoring
      await _startNetworkMonitoring();
      
      // Start GPS signal monitoring
      await _startGpsMonitoring();
      
      _isInitialized = true;
      debugPrint('🛡️ [$_tag] Navigation error recovery service initialized');
    } catch (e) {
      debugPrint('❌ [$_tag] Error initializing recovery service: $e');
      throw Exception('Failed to initialize navigation error recovery: $e');
    }
  }
  
  /// Handle navigation errors with appropriate recovery strategies
  Future<NavigationErrorRecoveryResult> handleNavigationError(
    NavigationError error,
    NavigationSession? currentSession,
  ) async {
    debugPrint('🛡️ [$_tag] Handling navigation error: ${error.type} - ${error.message}');
    
    // Check if we're in error cooldown period
    if (_isInErrorCooldown()) {
      debugPrint('⏳ [$_tag] In error cooldown period, skipping recovery');
      return NavigationErrorRecoveryResult.cooldown();
    }
    
    switch (error.type) {
      case NavigationErrorType.networkFailure:
        return await _handleNetworkError(error, currentSession);
      
      case NavigationErrorType.gpsSignalLoss:
        return await _handleGpsError(error, currentSession);
      
      case NavigationErrorType.routeCalculationFailure:
        return await _handleRouteCalculationError(error, currentSession);
      
      case NavigationErrorType.mapLoadingFailure:
        return await _handleMapLoadingError(error, currentSession);
      
      case NavigationErrorType.voiceServiceFailure:
        return await _handleVoiceServiceError(error, currentSession);
      
      case NavigationErrorType.cameraServiceFailure:
        return await _handleCameraServiceError(error, currentSession);
      
      case NavigationErrorType.criticalSystemFailure:
        return await _handleCriticalSystemError(error, currentSession);
      
      default:
        return await _handleGenericError(error, currentSession);
    }
  }
  
  /// Handle network-related errors
  Future<NavigationErrorRecoveryResult> _handleNetworkError(
    NavigationError error,
    NavigationSession? currentSession,
  ) async {
    _consecutiveNetworkErrors++;
    debugPrint('🌐 [$_tag] Network error #$_consecutiveNetworkErrors: ${error.message}');
    
    // Check network connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _isNetworkAvailable = !connectivityResult.contains(ConnectivityResult.none);
    
    if (!_isNetworkAvailable) {
      return NavigationErrorRecoveryResult.networkUnavailable(
        'No internet connection available. Please check your network settings.',
        suggestedAction: 'Enable mobile data or connect to Wi-Fi',
      );
    }
    
    // If we've exceeded retry limit, suggest external navigation
    if (_consecutiveNetworkErrors >= _maxNetworkRetries) {
      return await _suggestExternalNavigation(
        currentSession,
        'Network issues persist. Would you like to continue with an external navigation app?',
      );
    }
    
    // Attempt network recovery
    await Future.delayed(_networkRetryDelay);
    return NavigationErrorRecoveryResult.retry(
      'Network connection restored. Retrying navigation...',
      retryCount: _consecutiveNetworkErrors,
    );
  }
  
  /// Handle GPS signal loss errors
  Future<NavigationErrorRecoveryResult> _handleGpsError(
    NavigationError error,
    NavigationSession? currentSession,
  ) async {
    _consecutiveGpsErrors++;
    debugPrint('📍 [$_tag] GPS error #$_consecutiveGpsErrors: ${error.message}');
    
    // Check GPS permissions and availability
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return NavigationErrorRecoveryResult.permissionRequired(
        'Location permission is required for navigation.',
        suggestedAction: 'Grant location permission in app settings',
      );
    }
    
    final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      return NavigationErrorRecoveryResult.serviceRequired(
        'Location services are disabled.',
        suggestedAction: 'Enable location services in device settings',
      );
    }
    
    // If GPS errors persist, suggest external navigation
    if (_consecutiveGpsErrors >= _maxGpsRetries) {
      return await _suggestExternalNavigation(
        currentSession,
        'GPS signal issues persist. Would you like to continue with an external navigation app?',
      );
    }
    
    // Attempt GPS recovery
    return NavigationErrorRecoveryResult.retry(
      'Attempting to restore GPS signal...',
      retryCount: _consecutiveGpsErrors,
    );
  }
  
  /// Handle route calculation errors
  Future<NavigationErrorRecoveryResult> _handleRouteCalculationError(
    NavigationError error,
    NavigationSession? currentSession,
  ) async {
    debugPrint('🗺️ [$_tag] Route calculation error: ${error.message}');
    
    // If we have a current session, try external navigation
    if (currentSession != null) {
      return await _suggestExternalNavigation(
        currentSession,
        'Unable to calculate route. Would you like to use an external navigation app?',
      );
    }
    
    return NavigationErrorRecoveryResult.failed(
      'Route calculation failed. Please try again or use an external navigation app.',
    );
  }
  
  /// Handle map loading errors
  Future<NavigationErrorRecoveryResult> _handleMapLoadingError(
    NavigationError error,
    NavigationSession? currentSession,
  ) async {
    debugPrint('🗺️ [$_tag] Map loading error: ${error.message}');
    
    // Check network connectivity first
    if (!_isNetworkAvailable) {
      return NavigationErrorRecoveryResult.networkUnavailable(
        'Map cannot load without internet connection.',
        suggestedAction: 'Check your network connection',
      );
    }
    
    // Suggest external navigation as fallback
    if (currentSession != null) {
      return await _suggestExternalNavigation(
        currentSession,
        'Map loading failed. Would you like to use an external navigation app?',
      );
    }
    
    return NavigationErrorRecoveryResult.retry(
      'Retrying map loading...',
      retryCount: 1,
    );
  }
  
  /// Handle voice service errors
  Future<NavigationErrorRecoveryResult> _handleVoiceServiceError(
    NavigationError error,
    NavigationSession? currentSession,
  ) async {
    debugPrint('🔊 [$_tag] Voice service error: ${error.message}');
    
    // Voice service errors are not critical - continue without voice
    return NavigationErrorRecoveryResult.degraded(
      'Voice guidance unavailable. Navigation will continue without voice instructions.',
      degradedFeatures: ['voice_guidance'],
    );
  }
  
  /// Handle camera service errors
  Future<NavigationErrorRecoveryResult> _handleCameraServiceError(
    NavigationError error,
    NavigationSession? currentSession,
  ) async {
    debugPrint('📹 [$_tag] Camera service error: ${error.message}');
    
    // Camera service errors are not critical - continue with basic map
    return NavigationErrorRecoveryResult.degraded(
      '3D navigation camera unavailable. Navigation will continue with basic map view.',
      degradedFeatures: ['3d_camera', 'smooth_transitions'],
    );
  }
  
  /// Handle critical system errors
  Future<NavigationErrorRecoveryResult> _handleCriticalSystemError(
    NavigationError error,
    NavigationSession? currentSession,
  ) async {
    debugPrint('💥 [$_tag] Critical system error: ${error.message}');
    
    // For critical errors, immediately suggest external navigation
    if (currentSession != null) {
      return await _suggestExternalNavigation(
        currentSession,
        'Navigation system encountered a critical error. Please use an external navigation app.',
        isUrgent: true,
      );
    }
    
    return NavigationErrorRecoveryResult.failed(
      'Critical navigation error. Please restart the app or use an external navigation app.',
    );
  }
  
  /// Handle generic errors
  Future<NavigationErrorRecoveryResult> _handleGenericError(
    NavigationError error,
    NavigationSession? currentSession,
  ) async {
    debugPrint('⚠️ [$_tag] Generic error: ${error.message}');
    
    return NavigationErrorRecoveryResult.retry(
      'Navigation error occurred. Retrying...',
      retryCount: 1,
    );
  }
  
  /// Suggest external navigation apps as fallback
  Future<NavigationErrorRecoveryResult> _suggestExternalNavigation(
    NavigationSession? session,
    String message, {
    bool isUrgent = false,
  }) async {
    if (session == null) {
      return NavigationErrorRecoveryResult.failed(message);
    }
    
    final availableApps = await _getAvailableExternalNavApps();
    
    if (availableApps.isEmpty) {
      return NavigationErrorRecoveryResult.failed(
        '$message No external navigation apps are available.',
      );
    }
    
    return NavigationErrorRecoveryResult.externalNavigation(
      message,
      availableApps: availableApps,
      destination: session.destination,
      isUrgent: isUrgent,
    );
  }
  
  /// Get list of available external navigation apps
  Future<List<ExternalNavApp>> _getAvailableExternalNavApps() async {
    final availableApps = <ExternalNavApp>[];
    
    for (final entry in _externalNavApps.entries) {
      try {
        final appName = entry.key;
        final packageName = entry.value;
        
        // Check if app is available (this is a simplified check)
        // In a real implementation, you'd use platform-specific methods
        if (Platform.isAndroid) {
          // For Android, we can check if the app is installed
          availableApps.add(ExternalNavApp(
            name: _getAppDisplayName(appName),
            packageName: packageName,
            platform: 'android',
          ));
        } else if (Platform.isIOS && appName == 'apple_maps') {
          // For iOS, Apple Maps is always available
          availableApps.add(ExternalNavApp(
            name: 'Apple Maps',
            packageName: packageName,
            platform: 'ios',
          ));
        }
      } catch (e) {
        debugPrint('⚠️ [$_tag] Error checking app availability: $e');
      }
    }
    
    return availableApps;
  }
  
  /// Get display name for external navigation app
  String _getAppDisplayName(String appKey) {
    switch (appKey) {
      case 'google_maps':
        return 'Google Maps';
      case 'waze':
        return 'Waze';
      case 'apple_maps':
        return 'Apple Maps';
      default:
        return appKey;
    }
  }
  
  /// Launch external navigation app
  Future<bool> launchExternalNavigation(
    ExternalNavApp app,
    LatLng destination, {
    LatLng? origin,
  }) async {
    try {
      debugPrint('🚀 [$_tag] Launching ${app.name} for navigation');
      
      final uri = _buildNavigationUri(app, destination, origin: origin);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        debugPrint('❌ [$_tag] Cannot launch ${app.name}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [$_tag] Error launching ${app.name}: $e');
      return false;
    }
  }
  
  /// Build navigation URI for external app
  Uri _buildNavigationUri(
    ExternalNavApp app,
    LatLng destination, {
    LatLng? origin,
  }) {
    final lat = destination.latitude;
    final lng = destination.longitude;
    
    switch (app.packageName) {
      case 'com.google.android.apps.maps':
        if (origin != null) {
          return Uri.parse(
            'google.navigation:q=$lat,$lng&origin=${origin.latitude},${origin.longitude}',
          );
        } else {
          return Uri.parse('google.navigation:q=$lat,$lng');
        }
      
      case 'com.waze':
        return Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
      
      case 'com.apple.Maps':
        return Uri.parse('maps://?daddr=$lat,$lng');
      
      default:
        // Fallback to Google Maps web
        return Uri.parse('https://maps.google.com/?q=$lat,$lng');
    }
  }
  
  /// Start network connectivity monitoring
  Future<void> _startNetworkMonitoring() async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasNetworkAvailable = _isNetworkAvailable;
        _isNetworkAvailable = !results.contains(ConnectivityResult.none);
        
        if (!wasNetworkAvailable && _isNetworkAvailable) {
          debugPrint('🌐 [$_tag] Network connectivity restored');
          _consecutiveNetworkErrors = 0;
        } else if (wasNetworkAvailable && !_isNetworkAvailable) {
          debugPrint('🌐 [$_tag] Network connectivity lost');
        }
      },
    );
  }
  
  /// Start GPS signal monitoring
  Future<void> _startGpsMonitoring() async {
    try {
      _gpsMonitoringSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (Position position) {
          _lastGpsSignalTime = DateTime.now();
          if (!_isGpsSignalStrong) {
            debugPrint('📍 [$_tag] GPS signal restored');
            _isGpsSignalStrong = true;
            _consecutiveGpsErrors = 0;
          }
        },
        onError: (error) {
          debugPrint('📍 [$_tag] GPS monitoring error: $error');
          _isGpsSignalStrong = false;
        },
      );
    } catch (e) {
      debugPrint('❌ [$_tag] Error starting GPS monitoring: $e');
    }
  }
  
  /// Check if we're in error cooldown period
  bool _isInErrorCooldown() {
    if (_lastErrorTime == null) return false;
    return DateTime.now().difference(_lastErrorTime!) < _errorCooldownPeriod;
  }
  
  /// Reset error counters
  void resetErrorCounters() {
    _consecutiveNetworkErrors = 0;
    _consecutiveGpsErrors = 0;
    _lastErrorTime = null;
    debugPrint('🔄 [$_tag] Error counters reset');
  }
  
  /// Check if GPS signal is strong
  bool get isGpsSignalStrong {
    if (_lastGpsSignalTime == null) return false;
    return DateTime.now().difference(_lastGpsSignalTime!) < _gpsSignalTimeout;
  }
  
  /// Check if network is available
  bool get isNetworkAvailable => _isNetworkAvailable;
  
  /// Dispose resources
  Future<void> dispose() async {
    debugPrint('🛡️ [$_tag] Disposing navigation error recovery service');
    
    await _connectivitySubscription?.cancel();
    await _gpsMonitoringSubscription?.cancel();
    
    _isInitialized = false;
  }
}
