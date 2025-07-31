import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/voice_navigation_service.dart';
import '../../data/models/navigation_models.dart';
import '../../data/models/traffic_models.dart';
import '../../data/models/voice_navigation_preferences.dart';

/// Enhanced voice navigation provider for Phase 4.1
/// Provides advanced voice guidance with multi-language support, traffic alerts,
/// and battery optimization for the GigaEats driver workflow
final enhancedVoiceNavigationProvider = StateNotifierProvider<EnhancedVoiceNavigationNotifier, EnhancedVoiceNavigationState>((ref) {
  return EnhancedVoiceNavigationNotifier();
});

/// Enhanced voice navigation state for Phase 4.1
@immutable
class EnhancedVoiceNavigationState {
  final bool isEnabled;
  final bool isInitialized;
  final String currentLanguage;
  final double volume;
  final double speechRate;
  final double pitch;
  final bool isBackgroundMode;
  final bool isDucking;
  final List<String> availableLanguages;
  final List<Map<String, String>> availableVoices;
  final String? error;
  final bool isLoading;
  
  // Phase 4.1 enhancements
  final bool batteryOptimizationEnabled;
  final int consecutiveAnnouncementCount;
  final DateTime? lastAnnouncementTime;
  final List<TrafficAlert> recentTrafficAlerts;

  const EnhancedVoiceNavigationState({
    this.isEnabled = true,
    this.isInitialized = false,
    this.currentLanguage = 'en-MY',
    this.volume = 0.8,
    this.speechRate = 0.8,
    this.pitch = 1.0,
    this.isBackgroundMode = false,
    this.isDucking = false,
    this.availableLanguages = const [],
    this.availableVoices = const [],
    this.error,
    this.isLoading = false,
    this.batteryOptimizationEnabled = true,
    this.consecutiveAnnouncementCount = 0,
    this.lastAnnouncementTime,
    this.recentTrafficAlerts = const [],
  });

  EnhancedVoiceNavigationState copyWith({
    bool? isEnabled,
    bool? isInitialized,
    String? currentLanguage,
    double? volume,
    double? speechRate,
    double? pitch,
    bool? isBackgroundMode,
    bool? isDucking,
    List<String>? availableLanguages,
    List<Map<String, String>>? availableVoices,
    String? error,
    bool? isLoading,
    bool? batteryOptimizationEnabled,
    int? consecutiveAnnouncementCount,
    DateTime? lastAnnouncementTime,
    List<TrafficAlert>? recentTrafficAlerts,
  }) {
    return EnhancedVoiceNavigationState(
      isEnabled: isEnabled ?? this.isEnabled,
      isInitialized: isInitialized ?? this.isInitialized,
      currentLanguage: currentLanguage ?? this.currentLanguage,
      volume: volume ?? this.volume,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      isBackgroundMode: isBackgroundMode ?? this.isBackgroundMode,
      isDucking: isDucking ?? this.isDucking,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      availableVoices: availableVoices ?? this.availableVoices,
      error: error,
      isLoading: isLoading ?? this.isLoading,
      batteryOptimizationEnabled: batteryOptimizationEnabled ?? this.batteryOptimizationEnabled,
      consecutiveAnnouncementCount: consecutiveAnnouncementCount ?? this.consecutiveAnnouncementCount,
      lastAnnouncementTime: lastAnnouncementTime ?? this.lastAnnouncementTime,
      recentTrafficAlerts: recentTrafficAlerts ?? this.recentTrafficAlerts,
    );
  }
}

/// Traffic alert model for enhanced voice navigation
@immutable
class TrafficAlert {
  final String id;
  final String message;
  final TrafficSeverity severity;
  final DateTime timestamp;
  final bool isUrgent;
  final bool wasAnnounced;

  const TrafficAlert({
    required this.id,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.isUrgent = false,
    this.wasAnnounced = false,
  });

  TrafficAlert copyWith({
    String? id,
    String? message,
    TrafficSeverity? severity,
    DateTime? timestamp,
    bool? isUrgent,
    bool? wasAnnounced,
  }) {
    return TrafficAlert(
      id: id ?? this.id,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      isUrgent: isUrgent ?? this.isUrgent,
      wasAnnounced: wasAnnounced ?? this.wasAnnounced,
    );
  }
}

/// Enhanced voice navigation notifier for Phase 4.1
class EnhancedVoiceNavigationNotifier extends StateNotifier<EnhancedVoiceNavigationState> {
  final VoiceNavigationService _voiceService = VoiceNavigationService();

  EnhancedVoiceNavigationNotifier() : super(const EnhancedVoiceNavigationState());

  /// Initialize enhanced voice navigation with Phase 4.1 features
  Future<void> initialize({
    String language = 'en-MY',
    double volume = 0.8,
    double speechRate = 0.8,
    double pitch = 1.0,
    bool enableBatteryOptimization = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('🔊 [ENHANCED-VOICE-NAV] Initializing enhanced voice navigation');

      await _voiceService.initialize(
        language: language,
        volume: volume,
        speechRate: speechRate,
        pitch: pitch,
        enableBatteryOptimization: enableBatteryOptimization,
      );

      // Get available languages and voices
      final languages = await _voiceService.getAvailableLanguages();
      final voices = await _voiceService.getAvailableVoices();

      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
        currentLanguage: language,
        volume: volume,
        speechRate: speechRate,
        pitch: pitch,
        batteryOptimizationEnabled: enableBatteryOptimization,
        availableLanguages: languages,
        availableVoices: voices,
      );

      debugPrint('🔊 [ENHANCED-VOICE-NAV] Enhanced voice navigation initialized successfully');
    } catch (e) {
      debugPrint('❌ [ENHANCED-VOICE-NAV] Error initializing: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize voice navigation: ${e.toString()}',
      );
    }
  }

  /// Change language with enhanced error handling
  Future<void> setLanguage(String language) async {
    if (!state.isInitialized || state.currentLanguage == language) return;

    try {
      debugPrint('🔊 [ENHANCED-VOICE-NAV] Changing language to: $language');
      
      await _voiceService.setLanguage(language);
      
      state = state.copyWith(
        currentLanguage: language,
        error: null,
      );
      
      debugPrint('🔊 [ENHANCED-VOICE-NAV] Language changed successfully');
    } catch (e) {
      debugPrint('❌ [ENHANCED-VOICE-NAV] Error changing language: $e');
      state = state.copyWith(
        error: 'Failed to change language: ${e.toString()}',
      );
    }
  }

  /// Toggle voice guidance
  Future<void> toggleVoiceGuidance() async {
    if (!state.isInitialized) return;

    try {
      final newEnabled = !state.isEnabled;
      await _voiceService.setEnabled(newEnabled);
      
      state = state.copyWith(
        isEnabled: newEnabled,
        error: null,
      );
      
      debugPrint('🔊 [ENHANCED-VOICE-NAV] Voice guidance ${newEnabled ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('❌ [ENHANCED-VOICE-NAV] Error toggling voice guidance: $e');
      state = state.copyWith(
        error: 'Failed to toggle voice guidance: ${e.toString()}',
      );
    }
  }

  /// Set volume with validation
  Future<void> setVolume(double volume) async {
    if (!state.isInitialized) return;

    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _voiceService.setVolume(clampedVolume);
      
      state = state.copyWith(
        volume: clampedVolume,
        error: null,
      );
    } catch (e) {
      debugPrint('❌ [ENHANCED-VOICE-NAV] Error setting volume: $e');
      state = state.copyWith(
        error: 'Failed to set volume: ${e.toString()}',
      );
    }
  }

  /// Set speech rate with validation
  Future<void> setSpeechRate(double rate) async {
    if (!state.isInitialized) return;

    try {
      final clampedRate = rate.clamp(0.1, 2.0);
      await _voiceService.setSpeechRate(clampedRate);
      
      state = state.copyWith(
        speechRate: clampedRate,
        error: null,
      );
    } catch (e) {
      debugPrint('❌ [ENHANCED-VOICE-NAV] Error setting speech rate: $e');
      state = state.copyWith(
        error: 'Failed to set speech rate: ${e.toString()}',
      );
    }
  }

  /// Announce navigation instruction with enhanced tracking
  Future<void> announceInstruction(NavigationInstruction instruction) async {
    if (!state.isEnabled || !state.isInitialized) return;

    try {
      await _voiceService.announceInstruction(instruction);
      
      // Update state tracking
      state = state.copyWith(
        consecutiveAnnouncementCount: state.consecutiveAnnouncementCount + 1,
        lastAnnouncementTime: DateTime.now(),
        error: null,
      );
    } catch (e) {
      debugPrint('❌ [ENHANCED-VOICE-NAV] Error announcing instruction: $e');
      state = state.copyWith(
        error: 'Failed to announce instruction: ${e.toString()}',
      );
    }
  }

  /// Announce traffic alert with enhanced Phase 4.1 features
  Future<void> announceTrafficAlert(
    String message, {
    TrafficSeverity severity = TrafficSeverity.medium,
    bool isUrgent = false,
  }) async {
    if (!state.isEnabled || !state.isInitialized) return;

    try {
      // Create traffic alert record
      final alert = TrafficAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: message,
        severity: severity,
        timestamp: DateTime.now(),
        isUrgent: isUrgent,
        wasAnnounced: true,
      );

      // Convert TrafficSeverity to VoiceTrafficSeverity
      final voiceSeverity = _mapToVoiceTrafficSeverity(severity);

      await _voiceService.announceTrafficAlert(
        message,
        severity: voiceSeverity,
        isUrgent: isUrgent,
      );

      // Update state with new alert
      final updatedAlerts = [...state.recentTrafficAlerts, alert];
      
      // Keep only last 10 alerts
      if (updatedAlerts.length > 10) {
        updatedAlerts.removeAt(0);
      }

      state = state.copyWith(
        recentTrafficAlerts: updatedAlerts,
        consecutiveAnnouncementCount: state.consecutiveAnnouncementCount + 1,
        lastAnnouncementTime: DateTime.now(),
        error: null,
      );
    } catch (e) {
      debugPrint('❌ [ENHANCED-VOICE-NAV] Error announcing traffic alert: $e');
      state = state.copyWith(
        error: 'Failed to announce traffic alert: ${e.toString()}',
      );
    }
  }

  /// Test voice with current settings
  Future<void> testVoice() async {
    if (!state.isInitialized) return;

    try {
      await _voiceService.testVoice();
      state = state.copyWith(error: null);
    } catch (e) {
      debugPrint('❌ [ENHANCED-VOICE-NAV] Error testing voice: $e');
      state = state.copyWith(
        error: 'Failed to test voice: ${e.toString()}',
      );
    }
  }

  /// Clear recent traffic alerts
  void clearTrafficAlerts() {
    state = state.copyWith(recentTrafficAlerts: []);
  }

  /// Update voice navigation preferences (Phase 4.1 enhancement)
  Future<void> updateVoicePreferences(VoiceNavigationPreferences preferences) async {
    if (!state.isInitialized) return;

    try {
      debugPrint('🔊 [ENHANCED-VOICE-NAV] Updating voice preferences');

      // Update voice service with new preferences
      await _voiceService.updateAudioPreferences(
        language: preferences.language != state.currentLanguage ? preferences.language : null,
        volume: preferences.volume != state.volume ? preferences.volume : null,
        speechRate: preferences.speechRate != state.speechRate ? preferences.speechRate : null,
        pitch: preferences.pitch != state.pitch ? preferences.pitch : null,
        enabled: preferences.isEnabled != state.isEnabled ? preferences.isEnabled : null,
        batteryOptimization: preferences.batteryOptimizationEnabled != state.batteryOptimizationEnabled
            ? preferences.batteryOptimizationEnabled : null,
      );

      // Update state
      state = state.copyWith(
        isEnabled: preferences.isEnabled,
        currentLanguage: preferences.language,
        volume: preferences.volume,
        speechRate: preferences.speechRate,
        pitch: preferences.pitch,
        batteryOptimizationEnabled: preferences.batteryOptimizationEnabled,
        error: null,
      );

      debugPrint('🔊 [ENHANCED-VOICE-NAV] Voice preferences updated successfully');

    } catch (e) {
      debugPrint('❌ [ENHANCED-VOICE-NAV] Error updating voice preferences: $e');
      state = state.copyWith(
        error: 'Failed to update voice preferences: ${e.toString()}',
      );
    }
  }

  /// Get current preferences as VoiceNavigationPreferences object
  VoiceNavigationPreferences getCurrentPreferences() {
    return VoiceNavigationPreferences(
      language: state.currentLanguage,
      isEnabled: state.isEnabled,
      volume: state.volume,
      speechRate: state.speechRate,
      pitch: state.pitch,
      batteryOptimizationEnabled: state.batteryOptimizationEnabled,
      trafficAlertsEnabled: true, // Default to enabled
      emergencyAlertsEnabled: true, // Default to enabled
    );
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
  @override
  void dispose() {
    try {
      _voiceService.dispose();
      debugPrint('🔊 [ENHANCED-VOICE-NAV] Enhanced voice navigation disposed');
    } catch (e) {
      debugPrint('❌ [ENHANCED-VOICE-NAV] Error disposing: $e');
    }
    super.dispose();
  }
}
