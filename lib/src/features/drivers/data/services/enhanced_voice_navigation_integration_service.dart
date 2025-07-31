import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/navigation_models.dart';
import '../models/voice_navigation_preferences.dart';
import '../models/traffic_models.dart';
import 'voice_navigation_service.dart';
import 'voice_command_service.dart';

/// Enhanced voice navigation integration service for Phase 4.1
/// Provides comprehensive integration between voice navigation, traffic alerts,
/// and driver workflow with advanced audio management and multi-language support
class EnhancedVoiceNavigationIntegrationService {
  final VoiceNavigationService _voiceService;
  final VoiceCommandService _voiceCommandService;
  
  // State management
  VoiceNavigationPreferences _currentPreferences = const VoiceNavigationPreferences();
  bool _isInitialized = false;
  bool _isNavigationActive = false;
  String? _currentSessionId;
  
  // Streams
  final StreamController<VoiceNavigationPreferences> _preferencesController = 
      StreamController<VoiceNavigationPreferences>.broadcast();
  final StreamController<Map<String, dynamic>> _statusController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Timers
  Timer? _statusUpdateTimer;

  EnhancedVoiceNavigationIntegrationService({
    VoiceNavigationService? voiceService,
    VoiceCommandService? voiceCommandService,
  }) : _voiceService = voiceService ?? VoiceNavigationService(),
       _voiceCommandService = voiceCommandService ?? VoiceCommandService();

  // Getters
  VoiceNavigationPreferences get currentPreferences => _currentPreferences;
  bool get isInitialized => _isInitialized;
  bool get isNavigationActive => _isNavigationActive;
  String? get currentSessionId => _currentSessionId;
  
  // Streams
  Stream<VoiceNavigationPreferences> get preferencesStream => _preferencesController.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  /// Initialize the enhanced voice navigation integration service
  Future<void> initialize({
    VoiceNavigationPreferences? preferences,
  }) async {
    if (_isInitialized) return;

    debugPrint('🔊 [VOICE-INTEGRATION] Initializing enhanced voice navigation integration service');

    try {
      // Set preferences
      if (preferences != null) {
        _currentPreferences = preferences;
      }

      // Validate preferences
      final validationErrors = _currentPreferences.validate();
      if (validationErrors.isNotEmpty) {
        debugPrint('⚠️ [VOICE-INTEGRATION] Preference validation errors: ${validationErrors.join(', ')}');
        // Use default preferences if validation fails
        _currentPreferences = const VoiceNavigationPreferences();
      }

      // Initialize voice service
      await _voiceService.initialize(
        language: _currentPreferences.language,
        volume: _currentPreferences.volume,
        speechRate: _currentPreferences.speechRate,
        pitch: _currentPreferences.pitch,
        enableBatteryOptimization: _currentPreferences.batteryOptimizationEnabled,
      );

      // Initialize voice command service if enabled
      if (_currentPreferences.isFeatureEnabled('voice_commands')) {
        await _voiceCommandService.initialize(
          language: _currentPreferences.language,
          enabled: true,
        );
        _setupVoiceCommandCallbacks();
      }

      // Start status monitoring
      _startStatusMonitoring();

      _isInitialized = true;
      debugPrint('🔊 [VOICE-INTEGRATION] Enhanced voice navigation integration service initialized');

      // Emit initial status
      _emitStatus();

    } catch (e) {
      debugPrint('❌ [VOICE-INTEGRATION] Error initializing service: $e');
      throw Exception('Failed to initialize voice navigation integration: $e');
    }
  }

  /// Update voice navigation preferences
  Future<void> updatePreferences(VoiceNavigationPreferences newPreferences) async {
    if (!_isInitialized) {
      await initialize(preferences: newPreferences);
      return;
    }

    debugPrint('🔊 [VOICE-INTEGRATION] Updating voice navigation preferences');

    // Store old preferences for potential rollback
    final oldPreferences = _currentPreferences;

    try {
      // Validate new preferences
      final validationErrors = newPreferences.validate();
      if (validationErrors.isNotEmpty) {
        throw Exception('Invalid preferences: ${validationErrors.join(', ')}');
      }

      _currentPreferences = newPreferences;

      // Update voice service settings
      await _voiceService.updateAudioPreferences(
        language: newPreferences.language != oldPreferences.language ? newPreferences.language : null,
        volume: newPreferences.volume != oldPreferences.volume ? newPreferences.volume : null,
        speechRate: newPreferences.speechRate != oldPreferences.speechRate ? newPreferences.speechRate : null,
        pitch: newPreferences.pitch != oldPreferences.pitch ? newPreferences.pitch : null,
        enabled: newPreferences.isEnabled != oldPreferences.isEnabled ? newPreferences.isEnabled : null,
        batteryOptimization: newPreferences.batteryOptimizationEnabled != oldPreferences.batteryOptimizationEnabled 
            ? newPreferences.batteryOptimizationEnabled : null,
      );

      // Update voice command service if needed
      if (newPreferences.language != oldPreferences.language && 
          newPreferences.isFeatureEnabled('voice_commands')) {
        await _voiceCommandService.setLanguage(newPreferences.language);
      }

      // Emit preferences update
      _preferencesController.add(_currentPreferences);
      _emitStatus();

      debugPrint('🔊 [VOICE-INTEGRATION] Voice navigation preferences updated successfully');

    } catch (e) {
      debugPrint('❌ [VOICE-INTEGRATION] Error updating preferences: $e');
      // Revert to old preferences on error
      _currentPreferences = oldPreferences;
      throw Exception('Failed to update preferences: $e');
    }
  }

  /// Start navigation session with voice guidance
  Future<void> startNavigationSession(String sessionId) async {
    if (!_isInitialized) {
      throw Exception('Service not initialized');
    }

    debugPrint('🔊 [VOICE-INTEGRATION] Starting navigation session: $sessionId');

    try {
      _currentSessionId = sessionId;
      _isNavigationActive = true;

      // Enable voice service if preferences allow
      if (_currentPreferences.isEnabled) {
        await _voiceService.setEnabled(true);
      }

      // Start voice commands if enabled
      if (_currentPreferences.isFeatureEnabled('voice_commands')) {
        await _voiceCommandService.startListening();
      }

      _emitStatus();
      debugPrint('🔊 [VOICE-INTEGRATION] Navigation session started successfully');

    } catch (e) {
      debugPrint('❌ [VOICE-INTEGRATION] Error starting navigation session: $e');
      _isNavigationActive = false;
      _currentSessionId = null;
      throw Exception('Failed to start navigation session: $e');
    }
  }

  /// Stop navigation session
  Future<void> stopNavigationSession() async {
    if (!_isNavigationActive) return;

    debugPrint('🔊 [VOICE-INTEGRATION] Stopping navigation session: $_currentSessionId');

    try {
      // Stop voice commands
      await _voiceCommandService.stopListening();

      // Reset state
      _isNavigationActive = false;
      _currentSessionId = null;

      _emitStatus();
      debugPrint('🔊 [VOICE-INTEGRATION] Navigation session stopped successfully');

    } catch (e) {
      debugPrint('❌ [VOICE-INTEGRATION] Error stopping navigation session: $e');
    }
  }

  /// Announce navigation instruction
  Future<void> announceInstruction(NavigationInstruction instruction) async {
    if (!_isInitialized || !_currentPreferences.isEnabled || !_isNavigationActive) return;

    try {
      await _voiceService.announceInstruction(instruction);
      
      // Provide haptic feedback if enabled
      if (_currentPreferences.hapticFeedbackEnabled) {
        await HapticFeedback.selectionClick();
      }

    } catch (e) {
      debugPrint('❌ [VOICE-INTEGRATION] Error announcing instruction: $e');
    }
  }

  /// Announce traffic alert
  Future<void> announceTrafficAlert(String message, {
    TrafficSeverity severity = TrafficSeverity.medium,
    bool isUrgent = false,
  }) async {
    if (!_isInitialized || !_currentPreferences.trafficAlertsEnabled) return;

    try {
      // Map TrafficSeverity to VoiceTrafficSeverity
      final voiceSeverity = _mapToVoiceTrafficSeverity(severity);
      
      await _voiceService.announceTrafficAlert(
        message,
        severity: voiceSeverity,
        isUrgent: isUrgent,
      );

      // Provide haptic feedback for urgent alerts
      if (isUrgent && _currentPreferences.hapticFeedbackEnabled) {
        await HapticFeedback.heavyImpact();
      }

    } catch (e) {
      debugPrint('❌ [VOICE-INTEGRATION] Error announcing traffic alert: $e');
    }
  }

  /// Test voice with current settings
  Future<void> testVoice() async {
    if (!_isInitialized) return;

    try {
      await _voiceService.testVoice();
      
      if (_currentPreferences.hapticFeedbackEnabled) {
        await HapticFeedback.lightImpact();
      }

    } catch (e) {
      debugPrint('❌ [VOICE-INTEGRATION] Error testing voice: $e');
    }
  }

  /// Get available language options
  List<Map<String, dynamic>> getAvailableLanguages() {
    if (!_isInitialized) return [];
    return _voiceService.getAvailableLanguageOptions();
  }

  /// Setup voice command callbacks
  void _setupVoiceCommandCallbacks() {
    _voiceCommandService.onMuteVoice = () async {
      debugPrint('🎤 [VOICE-INTEGRATION] Voice command: Mute voice');
      await updatePreferences(_currentPreferences.copyWith(isEnabled: false));
    };

    _voiceCommandService.onUnmuteVoice = () async {
      debugPrint('🎤 [VOICE-INTEGRATION] Voice command: Unmute voice');
      await updatePreferences(_currentPreferences.copyWith(isEnabled: true));
    };

    _voiceCommandService.onRepeatInstruction = () async {
      debugPrint('🎤 [VOICE-INTEGRATION] Voice command: Repeat instruction');
      // This would be handled by the navigation service
    };
  }

  /// Start status monitoring
  void _startStatusMonitoring() {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _emitStatus();
    });
  }

  /// Emit current status
  void _emitStatus() {
    final status = {
      'isInitialized': _isInitialized,
      'isNavigationActive': _isNavigationActive,
      'currentSessionId': _currentSessionId,
      'preferences': _currentPreferences.toJson(),
      'voiceSystemStatus': _voiceService.getSystemStatus(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    _statusController.add(status);
  }

  /// Map TrafficSeverity to VoiceTrafficSeverity
  VoiceTrafficSeverity _mapToVoiceTrafficSeverity(TrafficSeverity severity) {
    switch (severity) {
      case TrafficSeverity.low:
        return VoiceTrafficSeverity.light;
      case TrafficSeverity.medium:
        return VoiceTrafficSeverity.moderate;
      case TrafficSeverity.high:
        return VoiceTrafficSeverity.heavy;
      case TrafficSeverity.critical:
        return VoiceTrafficSeverity.severe;
    }
  }

  /// Dispose resources
  void dispose() {
    debugPrint('🔊 [VOICE-INTEGRATION] Disposing enhanced voice navigation integration service');
    
    _statusUpdateTimer?.cancel();
    _preferencesController.close();
    _statusController.close();
    _voiceService.dispose();
    _voiceCommandService.dispose();
  }
}
