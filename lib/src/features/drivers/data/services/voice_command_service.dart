import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

/// Voice command service for hands-free navigation control
/// Phase 2 enhancement: Provides voice command recognition for navigation actions
class VoiceCommandService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  // State management
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isEnabled = true;
  String _currentLanguage = 'en-MY';
  
  // Command recognition
  final Map<String, List<String>> _commandPatterns = {
    'mute_voice': [
      'mute voice',
      'turn off voice',
      'silence voice',
      'stop talking',
      'quiet',
      'senyap', // Malay
      '静音', // Chinese
    ],
    'unmute_voice': [
      'unmute voice',
      'turn on voice',
      'enable voice',
      'start talking',
      'speak',
      'bercakap', // Malay
      '开启语音', // Chinese
    ],
    'repeat_instruction': [
      'repeat',
      'say again',
      'what did you say',
      'repeat instruction',
      'ulang', // Malay
      '重复', // Chinese
    ],
    'call_customer': [
      'call customer',
      'phone customer',
      'contact customer',
      'dial customer',
      'hubungi pelanggan', // Malay
      '联系客户', // Chinese
    ],
    'report_issue': [
      'report issue',
      'report problem',
      'there is a problem',
      'something wrong',
      'laporkan masalah', // Malay
      '报告问题', // Chinese
    ],
    'skip_instruction': [
      'skip',
      'next instruction',
      'skip this',
      'langkau', // Malay
      '跳过', // Chinese
    ],
    'stop_navigation': [
      'stop navigation',
      'end navigation',
      'cancel navigation',
      'stop',
      'hentikan navigasi', // Malay
      '停止导航', // Chinese
    ],
    'center_map': [
      'center map',
      'center on location',
      'show my location',
      'where am i',
      'tengahkan peta', // Malay
      '居中地图', // Chinese
    ],
  };

  // Callbacks for voice commands
  VoidCallback? onMuteVoice;
  VoidCallback? onUnmuteVoice;
  VoidCallback? onRepeatInstruction;
  VoidCallback? onCallCustomer;
  VoidCallback? onReportIssue;
  VoidCallback? onSkipInstruction;
  VoidCallback? onStopNavigation;
  VoidCallback? onCenterMap;

  /// Initialize voice command service
  Future<void> initialize({
    String language = 'en-MY',
    bool enabled = true,
  }) async {
    if (_isInitialized) return;

    debugPrint('🎤 [VOICE-COMMAND] Initializing voice command service');

    try {
      _currentLanguage = language;
      _isEnabled = enabled;

      // Initialize speech recognition
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: kDebugMode,
      );

      if (!available) {
        throw Exception('Speech recognition not available on this device');
      }

      _isInitialized = true;
      debugPrint('🎤 [VOICE-COMMAND] Voice command service initialized successfully');
    } catch (e) {
      debugPrint('❌ [VOICE-COMMAND] Error initializing voice command service: $e');
      throw Exception('Failed to initialize voice command service: $e');
    }
  }

  /// Start listening for voice commands
  Future<void> startListening() async {
    if (!_isInitialized || !_isEnabled || _isListening) return;

    try {
      debugPrint('🎤 [VOICE-COMMAND] Starting to listen for voice commands');

      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        localeId: _getLocaleId(_currentLanguage),
        onSoundLevelChange: _onSoundLevelChange,
        listenOptions: stt.SpeechListenOptions(
          partialResults: false,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );

      _isListening = true;
    } catch (e) {
      debugPrint('❌ [VOICE-COMMAND] Error starting voice recognition: $e');
    }
  }

  /// Stop listening for voice commands
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      debugPrint('🎤 [VOICE-COMMAND] Stopped listening for voice commands');
    } catch (e) {
      debugPrint('❌ [VOICE-COMMAND] Error stopping voice recognition: $e');
    }
  }

  /// Enable or disable voice commands
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    debugPrint('🎤 [VOICE-COMMAND] Voice commands ${enabled ? "enabled" : "disabled"}');
    
    if (!enabled && _isListening) {
      await stopListening();
    }
  }

  /// Set language for voice recognition
  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    debugPrint('🎤 [VOICE-COMMAND] Language set to: $language');
  }

  /// Handle speech recognition status changes
  void _onSpeechStatus(String status) {
    debugPrint('🎤 [VOICE-COMMAND] Speech status: $status');
    
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  /// Handle speech recognition errors
  void _onSpeechError(dynamic error) {
    debugPrint('❌ [VOICE-COMMAND] Speech error: $error');
    _isListening = false;
  }

  /// Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!result.finalResult) return;

    final recognizedText = result.recognizedWords.toLowerCase().trim();
    debugPrint('🎤 [VOICE-COMMAND] Recognized: "$recognizedText"');

    // Process the recognized command
    _processVoiceCommand(recognizedText);
  }

  /// Handle sound level changes (for visual feedback)
  void _onSoundLevelChange(double level) {
    // This could be used to provide visual feedback of voice input level
    // For now, we'll just log it in debug mode
    if (kDebugMode && level > 0.5) {
      debugPrint('🎤 [VOICE-COMMAND] Sound level: ${level.toStringAsFixed(2)}');
    }
  }

  /// Process recognized voice command
  void _processVoiceCommand(String recognizedText) {
    debugPrint('🎤 [VOICE-COMMAND] Processing command: "$recognizedText"');

    // Check each command pattern
    for (final entry in _commandPatterns.entries) {
      final command = entry.key;
      final patterns = entry.value;

      // Check if recognized text matches any pattern for this command
      for (final pattern in patterns) {
        if (_matchesPattern(recognizedText, pattern)) {
          debugPrint('🎤 [VOICE-COMMAND] Matched command: $command');
          _executeCommand(command);
          return;
        }
      }
    }

    debugPrint('🎤 [VOICE-COMMAND] No matching command found for: "$recognizedText"');
  }

  /// Check if recognized text matches a command pattern
  bool _matchesPattern(String recognizedText, String pattern) {
    // Simple fuzzy matching - check if pattern words are contained in recognized text
    final patternWords = pattern.toLowerCase().split(' ');
    final recognizedWords = recognizedText.split(' ');

    // Check if all pattern words are present in recognized text
    return patternWords.every((patternWord) =>
        recognizedWords.any((recognizedWord) =>
            recognizedWord.contains(patternWord) || patternWord.contains(recognizedWord)));
  }

  /// Execute the matched voice command
  void _executeCommand(String command) {
    debugPrint('🎤 [VOICE-COMMAND] Executing command: $command');

    switch (command) {
      case 'mute_voice':
        onMuteVoice?.call();
        break;
      case 'unmute_voice':
        onUnmuteVoice?.call();
        break;
      case 'repeat_instruction':
        onRepeatInstruction?.call();
        break;
      case 'call_customer':
        onCallCustomer?.call();
        break;
      case 'report_issue':
        onReportIssue?.call();
        break;
      case 'skip_instruction':
        onSkipInstruction?.call();
        break;
      case 'stop_navigation':
        onStopNavigation?.call();
        break;
      case 'center_map':
        onCenterMap?.call();
        break;
    }
  }

  /// Get locale ID for speech recognition
  String _getLocaleId(String language) {
    switch (language) {
      case 'ms-MY':
        return 'ms-MY';
      case 'zh-CN':
        return 'zh-CN';
      case 'ta-MY':
        return 'ta-IN'; // Fallback to Tamil India
      default:
        return 'en-US'; // Default to US English
    }
  }

  /// Get available locales for speech recognition
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) return [];
    
    try {
      return await _speech.locales();
    } catch (e) {
      debugPrint('❌ [VOICE-COMMAND] Error getting available locales: $e');
      return [];
    }
  }

  /// Check if speech recognition is available
  bool get isAvailable => _speech.isAvailable;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Check if service is enabled
  bool get isEnabled => _isEnabled;

  /// Dispose of resources
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    _isInitialized = false;
    _isListening = false;
    debugPrint('🎤 [VOICE-COMMAND] Voice command service disposed');
  }
}
