import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/navigation_models.dart';

/// Voice navigation service with multi-language TTS support
/// Provides voice guidance for turn-by-turn navigation with Malaysian language support
class VoiceNavigationService {
  final FlutterTts _tts = FlutterTts();
  
  // Current state
  String _currentLanguage = 'en-MY';
  bool _isEnabled = true;
  bool _isInitialized = false;
  double _volume = 0.8;
  double _speechRate = 0.8;
  double _pitch = 1.0;
  
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

  /// Initialize voice navigation service
  Future<void> initialize({
    String language = 'en-MY',
    double volume = 0.8,
    double speechRate = 0.8,
    double pitch = 1.0,
  }) async {
    if (_isInitialized) return;
    
    debugPrint('🔊 [VOICE-NAV] Initializing voice navigation service');
    
    try {
      _currentLanguage = language;
      _volume = volume;
      _speechRate = speechRate;
      _pitch = pitch;
      
      // Configure TTS
      await _configureTts();
      
      // Set language-specific settings
      await _setLanguageSettings(language);
      
      _isInitialized = true;
      debugPrint('🔊 [VOICE-NAV] Voice navigation service initialized for language: $language');
    } catch (e) {
      debugPrint('❌ [VOICE-NAV] Error initializing voice navigation: $e');
      throw Exception('Failed to initialize voice navigation: $e');
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

  /// Announce navigation instruction
  Future<void> announceInstruction(NavigationInstruction instruction) async {
    if (!_isEnabled || !_isInitialized) return;
    
    try {
      final text = _getLocalizedInstructionText(instruction);
      debugPrint('🔊 [VOICE-NAV] Announcing: $text');
      
      await _tts.speak(text);
    } catch (e) {
      debugPrint('❌ [VOICE-NAV] Error announcing instruction: $e');
    }
  }

  /// Announce traffic alert
  Future<void> announceTrafficAlert(String message) async {
    if (!_isEnabled || !_isInitialized) return;
    
    try {
      final localizedMessage = _getLocalizedTrafficMessage(message);
      debugPrint('🔊 [VOICE-NAV] Traffic alert: $localizedMessage');
      
      await _tts.speak(localizedMessage);
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

  /// Get localized traffic message
  String _getLocalizedTrafficMessage(String message) {
    switch (_currentLanguage) {
      case 'ms-MY':
        return 'Amaran trafik: $message';
      case 'zh-CN':
        return '交通警报：$message';
      case 'ta-MY':
        return 'போக்குவரத்து எச்சரிக்கை: $message';
      default:
        return 'Traffic alert: $message';
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

  /// Dispose resources
  Future<void> dispose() async {
    debugPrint('🔊 [VOICE-NAV] Disposing voice navigation service');
    
    await _tts.stop();
    _isInitialized = false;
  }

  // Getters
  bool get isEnabled => _isEnabled;
  bool get isInitialized => _isInitialized;
  String get currentLanguage => _currentLanguage;
  double get volume => _volume;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
}
