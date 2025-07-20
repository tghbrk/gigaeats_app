import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audio_session/audio_session.dart';

import '../models/navigation_models.dart';

/// Traffic severity levels for enhanced voice announcements
enum TrafficSeverity {
  light,
  moderate,
  heavy,
  severe,
}

/// Enhanced Voice navigation service with multi-language TTS support
/// Provides voice guidance for turn-by-turn navigation with Malaysian language support
/// Phase 4.1 enhancements: Advanced audio session management, battery optimization,
/// traffic alert notifications, and improved multi-language support
class VoiceNavigationService {
  final FlutterTts _tts = FlutterTts();
  AudioSession? _audioSession;

  // Current state
  String _currentLanguage = 'en-MY';
  bool _isEnabled = true;
  bool _isInitialized = false;
  double _volume = 0.8;
  double _speechRate = 0.8;
  double _pitch = 1.0;

  // Advanced features for Phase 4.1
  bool _isDucking = false;
  bool _isBackgroundMode = false;
  Timer? _batteryOptimizationTimer;
  int _consecutiveAnnouncementCount = 0;
  DateTime? _lastAnnouncementTime;

  // Audio session configuration
  static const Duration _duckingDuration = Duration(milliseconds: 500);
  static const Duration _batteryOptimizationInterval = Duration(minutes: 5);
  static const int _maxConsecutiveAnnouncements = 3;
  
  // Voice settings for different languages
  static const Map<String, Map<String, dynamic>> _languageSettings = {
    'en-MY': {
      'language': 'en-US', // Fallback to US English for TTS
      'voice': 'en-us-x-sfg#female_1-local',
      'speechRate': 0.8,
      'pitch': 1.0,
    },
    'ms-MY': {
      'language': 'ms-MY',
      'voice': 'ms-my-x-mas#female_1-local',
      'speechRate': 0.7, // Slightly slower for Malay
      'pitch': 1.0,
    },
    'zh-CN': {
      'language': 'zh-CN',
      'voice': 'zh-cn-x-ccc#female_1-local',
      'speechRate': 0.7,
      'pitch': 1.1,
    },
    'ta-MY': {
      'language': 'ta-IN', // Tamil fallback
      'voice': 'ta-in-x-tag#female_1-local',
      'speechRate': 0.7,
      'pitch': 1.0,
    },
  };

  /// Initialize voice navigation service with enhanced Phase 4.1 features
  Future<void> initialize({
    String language = 'en-MY',
    double volume = 0.8,
    double speechRate = 0.8,
    double pitch = 1.0,
    bool enableBatteryOptimization = true,
  }) async {
    if (_isInitialized) return;

    debugPrint('🔊 [VOICE-NAV] Initializing enhanced voice navigation service (Phase 4.1)');

    try {
      _currentLanguage = language;
      _volume = volume;
      _speechRate = speechRate;
      _pitch = pitch;

      // Initialize audio session for better audio management
      await _initializeAudioSession();

      // Configure TTS with enhanced settings
      await _configureTts();

      // Set language-specific settings
      await _setLanguageSettings(language);

      // Start battery optimization if enabled
      if (enableBatteryOptimization) {
        _startBatteryOptimization();
      }

      _isInitialized = true;
      debugPrint('🔊 [VOICE-NAV] Enhanced voice navigation service initialized for language: $language');
    } catch (e) {
      debugPrint('❌ [VOICE-NAV] Error initializing voice navigation: $e');
      throw Exception('Failed to initialize voice navigation: $e');
    }
  }

  /// Initialize audio session for better audio management
  Future<void> _initializeAudioSession() async {
    try {
      _audioSession = await AudioSession.instance;
      await _audioSession!.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.audibilityEnforced,
          usage: AndroidAudioUsage.assistanceNavigationGuidance,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ));

      debugPrint('🔊 [VOICE-NAV] Audio session configured for navigation guidance');
    } catch (e) {
      debugPrint('❌ [VOICE-NAV] Error configuring audio session: $e');
      // Continue without audio session if it fails
    }
  }

  /// Start battery optimization timer
  void _startBatteryOptimization() {
    _batteryOptimizationTimer?.cancel();
    _batteryOptimizationTimer = Timer.periodic(_batteryOptimizationInterval, (timer) {
      _optimizeBatteryUsage();
    });
    debugPrint('🔋 [VOICE-NAV] Battery optimization started');
  }

  /// Optimize battery usage by managing audio session
  void _optimizeBatteryUsage() {
    if (!_isEnabled || !_isInitialized) return;

    final now = DateTime.now();
    final timeSinceLastAnnouncement = _lastAnnouncementTime != null
        ? now.difference(_lastAnnouncementTime!)
        : Duration.zero;

    // If no announcements for 5 minutes, enter background mode
    if (timeSinceLastAnnouncement.inMinutes >= 5 && !_isBackgroundMode) {
      _enterBackgroundMode();
    }

    // Reset consecutive announcement count if it's been a while
    if (timeSinceLastAnnouncement.inMinutes >= 2) {
      _consecutiveAnnouncementCount = 0;
    }

    debugPrint('🔋 [VOICE-NAV] Battery optimization check completed');
  }

  /// Enter background mode to save battery
  Future<void> _enterBackgroundMode() async {
    _isBackgroundMode = true;

    try {
      // Reduce TTS settings for battery saving
      await _tts.setVolume(_volume * 0.8);
      await _tts.setSpeechRate(_speechRate * 0.9);

      debugPrint('🔋 [VOICE-NAV] Entered background mode for battery optimization');
    } catch (e) {
      debugPrint('❌ [VOICE-NAV] Error entering background mode: $e');
    }
  }

  /// Exit background mode and restore full functionality
  Future<void> _exitBackgroundMode() async {
    if (!_isBackgroundMode) return;

    _isBackgroundMode = false;

    try {
      // Restore original TTS settings
      await _tts.setVolume(_volume);
      await _tts.setSpeechRate(_speechRate);

      debugPrint('🔋 [VOICE-NAV] Exited background mode');
    } catch (e) {
      debugPrint('❌ [VOICE-NAV] Error exiting background mode: $e');
    }
  }

  /// Check if announcement should be throttled to prevent spam
  bool _shouldThrottleAnnouncement() {
    if (_lastAnnouncementTime == null) return false;

    final timeSinceLastAnnouncement = DateTime.now().difference(_lastAnnouncementTime!);

    // Throttle if too many consecutive announcements in short time
    if (_consecutiveAnnouncementCount >= _maxConsecutiveAnnouncements &&
        timeSinceLastAnnouncement.inSeconds < 10) {
      return true;
    }

    // Throttle if announcements are too frequent (less than 2 seconds apart)
    if (timeSinceLastAnnouncement.inSeconds < 2) {
      return true;
    }

    return false;
  }

  /// Request audio focus and duck other audio
  Future<void> _requestAudioFocus() async {
    if (_audioSession == null || _isDucking) return;

    try {
      _isDucking = true;
      await _audioSession!.setActive(true);
      debugPrint('🔊 [VOICE-NAV] Audio focus requested');
    } catch (e) {
      debugPrint('❌ [VOICE-NAV] Error requesting audio focus: $e');
    }
  }

  /// Release audio focus
  Future<void> _releaseAudioFocus() async {
    if (_audioSession == null || !_isDucking) return;

    try {
      _isDucking = false;
      await _audioSession!.setActive(false);
      debugPrint('🔊 [VOICE-NAV] Audio focus released');
    } catch (e) {
      debugPrint('❌ [VOICE-NAV] Error releasing audio focus: $e');
    }
  }

  /// Configure TTS with platform-specific settings
  Future<void> _configureTts() async {
    // Set basic TTS settings
    await _tts.setVolume(_volume);
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(_pitch);
    
    // Platform-specific configuration
    if (Platform.isAndroid) {
      await _tts.setQueueMode(1); // Flush queue mode
    } else if (Platform.isIOS) {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
    }
    
    // Set completion handler
    _tts.setCompletionHandler(() {
      debugPrint('🔊 [VOICE-NAV] TTS completion');
    });
    
    // Set error handler
    _tts.setErrorHandler((message) {
      debugPrint('❌ [VOICE-NAV] TTS error: $message');
    });
  }

  /// Set language-specific TTS settings
  Future<void> _setLanguageSettings(String language) async {
    final settings = _languageSettings[language] ?? _languageSettings['en-MY']!;
    
    try {
      // Set language
      await _tts.setLanguage(settings['language']);
      
      // Set speech rate and pitch for language
      await _tts.setSpeechRate(settings['speechRate'] ?? _speechRate);
      await _tts.setPitch(settings['pitch'] ?? _pitch);
      
      // Try to set specific voice if available
      if (settings['voice'] != null) {
        final voices = await _tts.getVoices;
        final targetVoice = voices?.firstWhere(
          (voice) => voice['name'] == settings['voice'],
          orElse: () => null,
        );
        
        if (targetVoice != null) {
          await _tts.setVoice(targetVoice);
          debugPrint('🔊 [VOICE-NAV] Set voice: ${targetVoice['name']}');
        } else {
          debugPrint('🔊 [VOICE-NAV] Voice ${settings['voice']} not available, using default');
        }
      }
      
      debugPrint('🔊 [VOICE-NAV] Language settings applied for: $language');
    } catch (e) {
      debugPrint('❌ [VOICE-NAV] Error setting language settings: $e');
      // Fallback to English
      await _tts.setLanguage('en-US');
    }
  }

  /// Change language and update TTS settings
  Future<void> setLanguage(String language) async {
    if (!_isInitialized) {
      await initialize(language: language);
      return;
    }
    
    if (_currentLanguage == language) return;
    
    debugPrint('🔊 [VOICE-NAV] Changing language from $_currentLanguage to $language');
    
    _currentLanguage = language;
    await _setLanguageSettings(language);
  }

  /// Enable or disable voice guidance
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    debugPrint('🔊 [VOICE-NAV] Voice guidance ${enabled ? "enabled" : "disabled"}');
    
    if (!enabled) {
      await _tts.stop();
    }
  }

  /// Set volume level
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _tts.setVolume(_volume);
    debugPrint('🔊 [VOICE-NAV] Volume set to: $_volume');
  }

  /// Set speech rate
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 2.0);
    await _tts.setSpeechRate(_speechRate);
    debugPrint('🔊 [VOICE-NAV] Speech rate set to: $_speechRate');
  }

  /// Announce navigation instruction with enhanced Phase 4.1 features
  Future<void> announceInstruction(NavigationInstruction instruction) async {
    if (!_isEnabled || !_isInitialized) return;

    try {
      // Exit background mode if active
      if (_isBackgroundMode) {
        await _exitBackgroundMode();
      }

      // Check for consecutive announcement throttling
      if (_shouldThrottleAnnouncement()) {
        debugPrint('🔊 [VOICE-NAV] Throttling announcement to prevent spam');
        return;
      }

      // Request audio focus and duck other audio
      await _requestAudioFocus();

      final text = _getLocalizedInstructionText(instruction);
      debugPrint('🔊 [VOICE-NAV] Announcing: $text');

      // Update tracking variables
      _lastAnnouncementTime = DateTime.now();
      _consecutiveAnnouncementCount++;

      await _tts.speak(text);

      // Release audio focus after a delay
      Timer(_duckingDuration, () => _releaseAudioFocus());

    } catch (e) {
      debugPrint('❌ [VOICE-NAV] Error announcing instruction: $e');
    }
  }

  /// Announce traffic alert with enhanced Phase 4.1 features
  Future<void> announceTrafficAlert(String message, {
    TrafficSeverity severity = TrafficSeverity.moderate,
    bool isUrgent = false,
  }) async {
    if (!_isEnabled || !_isInitialized) return;

    try {
      // Exit background mode for traffic alerts
      if (_isBackgroundMode) {
        await _exitBackgroundMode();
      }

      // Traffic alerts bypass normal throttling for urgent situations
      if (!isUrgent && _shouldThrottleAnnouncement()) {
        debugPrint('🔊 [VOICE-NAV] Throttling traffic alert (non-urgent)');
        return;
      }

      // Request audio focus with higher priority for traffic alerts
      await _requestAudioFocus();

      final localizedMessage = _getLocalizedTrafficMessage(message, severity);
      debugPrint('🔊 [VOICE-NAV] Traffic alert (${severity.name}): $localizedMessage');

      // Adjust volume and speech rate based on severity
      final originalVolume = _volume;
      final originalSpeechRate = _speechRate;

      if (severity == TrafficSeverity.severe || isUrgent) {
        await _tts.setVolume((_volume * 1.2).clamp(0.0, 1.0));
        await _tts.setSpeechRate(_speechRate * 0.9); // Slower for important alerts
      }

      // Update tracking variables
      _lastAnnouncementTime = DateTime.now();
      _consecutiveAnnouncementCount++;

      await _tts.speak(localizedMessage);

      // Restore original settings
      await _tts.setVolume(originalVolume);
      await _tts.setSpeechRate(originalSpeechRate);

      // Release audio focus after a longer delay for traffic alerts
      Timer(const Duration(milliseconds: 1000), () => _releaseAudioFocus());

    } catch (e) {
      debugPrint('❌ [VOICE-NAV] Error announcing traffic alert: $e');
    }
  }

  /// Announce arrival at destination
  Future<void> announceArrival(String? destinationName) async {
    if (!_isEnabled || !_isInitialized) return;
    
    try {
      final message = _getLocalizedArrivalMessage(destinationName);
      debugPrint('🔊 [VOICE-NAV] Arrival: $message');
      
      await _tts.speak(message);
    } catch (e) {
      debugPrint('❌ [VOICE-NAV] Error announcing arrival: $e');
    }
  }

  /// Get localized instruction text based on current language
  String _getLocalizedInstructionText(NavigationInstruction instruction) {
    switch (_currentLanguage) {
      case 'ms-MY':
        return _getMalayInstructionText(instruction);
      case 'zh-CN':
        return _getChineseInstructionText(instruction);
      case 'ta-MY':
        return _getTamilInstructionText(instruction);
      default:
        return instruction.voiceText;
    }
  }

  /// Get Malay instruction text
  String _getMalayInstructionText(NavigationInstruction instruction) {
    final streetName = instruction.streetName;
    
    switch (instruction.type) {
      case NavigationInstructionType.turnLeft:
        return 'Belok kiri${streetName != null ? ' ke $streetName' : ''}';
      case NavigationInstructionType.turnRight:
        return 'Belok kanan${streetName != null ? ' ke $streetName' : ''}';
      case NavigationInstructionType.straight:
        return 'Terus lurus${streetName != null ? ' di $streetName' : ''}';
      case NavigationInstructionType.uturnLeft:
        return 'Buat pusingan U ke kiri';
      case NavigationInstructionType.uturnRight:
        return 'Buat pusingan U ke kanan';
      case NavigationInstructionType.destination:
        return 'Anda telah sampai ke destinasi';
      case NavigationInstructionType.roundaboutLeft:
        return 'Masuk bulatan dan keluar di kiri';
      case NavigationInstructionType.roundaboutRight:
        return 'Masuk bulatan dan keluar di kanan';
      default:
        return instruction.text;
    }
  }

  /// Get Chinese instruction text
  String _getChineseInstructionText(NavigationInstruction instruction) {
    final streetName = instruction.streetName;
    
    switch (instruction.type) {
      case NavigationInstructionType.turnLeft:
        return '左转${streetName != null ? '到$streetName' : ''}';
      case NavigationInstructionType.turnRight:
        return '右转${streetName != null ? '到$streetName' : ''}';
      case NavigationInstructionType.straight:
        return '直行${streetName != null ? '在$streetName' : ''}';
      case NavigationInstructionType.uturnLeft:
        return '向左掉头';
      case NavigationInstructionType.uturnRight:
        return '向右掉头';
      case NavigationInstructionType.destination:
        return '您已到达目的地';
      case NavigationInstructionType.roundaboutLeft:
        return '进入环岛，左侧出口';
      case NavigationInstructionType.roundaboutRight:
        return '进入环岛，右侧出口';
      default:
        return instruction.text;
    }
  }

  /// Get Tamil instruction text
  String _getTamilInstructionText(NavigationInstruction instruction) {
    final streetName = instruction.streetName;
    
    switch (instruction.type) {
      case NavigationInstructionType.turnLeft:
        return 'இடதுபுறம் திரும்பவும்${streetName != null ? ' $streetName இல்' : ''}';
      case NavigationInstructionType.turnRight:
        return 'வலதுபுறம் திரும்பவும்${streetName != null ? ' $streetName இல்' : ''}';
      case NavigationInstructionType.straight:
        return 'நேராக செல்லவும்${streetName != null ? ' $streetName இல்' : ''}';
      case NavigationInstructionType.destination:
        return 'நீங்கள் உங்கள் இலக்கை அடைந்துவிட்டீர்கள்';
      default:
        return instruction.text;
    }
  }

  /// Get localized traffic message with severity indication
  String _getLocalizedTrafficMessage(String message, [TrafficSeverity? severity]) {
    final severityPrefix = _getSeverityPrefix(severity);

    switch (_currentLanguage) {
      case 'ms-MY':
        return '$severityPrefix$message';
      case 'zh-CN':
        return '$severityPrefix$message';
      case 'ta-MY':
        return '$severityPrefix$message';
      default:
        return '$severityPrefix$message';
    }
  }

  /// Get severity prefix for traffic messages
  String _getSeverityPrefix(TrafficSeverity? severity) {
    severity ??= TrafficSeverity.moderate;

    switch (_currentLanguage) {
      case 'ms-MY':
        switch (severity) {
          case TrafficSeverity.light:
            return 'Amaran trafik ringan: ';
          case TrafficSeverity.moderate:
            return 'Amaran trafik: ';
          case TrafficSeverity.heavy:
            return 'Amaran trafik teruk: ';
          case TrafficSeverity.severe:
            return 'AMARAN TRAFIK KRITIKAL: ';
        }
      case 'zh-CN':
        switch (severity) {
          case TrafficSeverity.light:
            return '轻微交通警报：';
          case TrafficSeverity.moderate:
            return '交通警报：';
          case TrafficSeverity.heavy:
            return '严重交通警报：';
          case TrafficSeverity.severe:
            return '紧急交通警报：';
        }
      case 'ta-MY':
        switch (severity) {
          case TrafficSeverity.light:
            return 'லேசான போக்குவரத்து எச்சரிக்கை: ';
          case TrafficSeverity.moderate:
            return 'போக்குவரத்து எச்சரிக்கை: ';
          case TrafficSeverity.heavy:
            return 'கடுமையான போக்குவரத்து எச்சரிக்கை: ';
          case TrafficSeverity.severe:
            return 'அவசர போக்குவரத்து எச்சரிக்கை: ';
        }
      default:
        switch (severity) {
          case TrafficSeverity.light:
            return 'Light traffic alert: ';
          case TrafficSeverity.moderate:
            return 'Traffic alert: ';
          case TrafficSeverity.heavy:
            return 'Heavy traffic alert: ';
          case TrafficSeverity.severe:
            return 'CRITICAL TRAFFIC ALERT: ';
        }
    }
  }

  /// Get localized arrival message
  String _getLocalizedArrivalMessage(String? destinationName) {
    final name = destinationName ?? '';
    
    switch (_currentLanguage) {
      case 'ms-MY':
        return name.isNotEmpty 
          ? 'Anda telah sampai ke $name'
          : 'Anda telah sampai ke destinasi';
      case 'zh-CN':
        return name.isNotEmpty 
          ? '您已到达$name'
          : '您已到达目的地';
      case 'ta-MY':
        return name.isNotEmpty 
          ? 'நீங்கள் $name ஐ அடைந்துவிட்டீர்கள்'
          : 'நீங்கள் உங்கள் இலக்கை அடைந்துவிட்டீர்கள்';
      default:
        return name.isNotEmpty 
          ? 'You have arrived at $name'
          : 'You have arrived at your destination';
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    await _tts.stop();
  }

  /// Check if TTS is currently speaking
  Future<bool> get isSpeaking async {
    try {
      return await _tts.isLanguageAvailable(_currentLanguage) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get available languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _tts.getLanguages;
      return languages?.cast<String>() ?? [];
    } catch (e) {
      debugPrint('❌ [VOICE-NAV] Error getting available languages: $e');
      return ['en-US'];
    }
  }

  /// Get available voices for current language
  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      final voices = await _tts.getVoices;
      return voices?.cast<Map<String, String>>() ?? [];
    } catch (e) {
      debugPrint('❌ [VOICE-NAV] Error getting available voices: $e');
      return [];
    }
  }

  /// Test voice with sample text
  Future<void> testVoice() async {
    if (!_isEnabled || !_isInitialized) return;
    
    final testMessage = _getLocalizedTestMessage();
    await _tts.speak(testMessage);
  }

  /// Get localized test message
  String _getLocalizedTestMessage() {
    switch (_currentLanguage) {
      case 'ms-MY':
        return 'Ujian suara navigasi GigaEats';
      case 'zh-CN':
        return 'GigaEats导航语音测试';
      case 'ta-MY':
        return 'GigaEats வழிசெலுத்தல் குரல் சோதனை';
      default:
        return 'GigaEats navigation voice test';
    }
  }

  /// Dispose resources with enhanced Phase 4.1 cleanup
  Future<void> dispose() async {
    debugPrint('🔊 [VOICE-NAV] Disposing enhanced voice navigation service');

    // Cancel battery optimization timer
    _batteryOptimizationTimer?.cancel();
    _batteryOptimizationTimer = null;

    // Release audio focus if held
    if (_isDucking) {
      await _releaseAudioFocus();
    }

    // Deactivate audio session
    try {
      await _audioSession?.setActive(false);
    } catch (e) {
      debugPrint('❌ [VOICE-NAV] Error deactivating audio session: $e');
    }

    // Stop TTS
    await _tts.stop();

    // Reset state
    _isInitialized = false;
    _isBackgroundMode = false;
    _isDucking = false;
    _consecutiveAnnouncementCount = 0;
    _lastAnnouncementTime = null;

    debugPrint('🔊 [VOICE-NAV] Enhanced voice navigation service disposed');
  }

  // Getters
  bool get isEnabled => _isEnabled;
  bool get isInitialized => _isInitialized;
  String get currentLanguage => _currentLanguage;
  double get volume => _volume;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
}
