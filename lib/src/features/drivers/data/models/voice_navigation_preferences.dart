import 'package:equatable/equatable.dart';

/// Enhanced voice navigation preferences for Phase 4.1
/// Provides comprehensive audio settings and language preferences
class VoiceNavigationPreferences extends Equatable {
  final String language;
  final bool isEnabled;
  final double volume;
  final double speechRate;
  final double pitch;
  final bool batteryOptimizationEnabled;
  final bool trafficAlertsEnabled;
  final bool emergencyAlertsEnabled;
  final VoiceGender preferredVoiceGender;
  final AudioDuckingMode duckingMode;
  final int instructionRepeatCount;
  final bool hapticFeedbackEnabled;
  final List<String> enabledFeatures;
  final Map<String, dynamic> customSettings;

  const VoiceNavigationPreferences({
    this.language = 'en-MY',
    this.isEnabled = true,
    this.volume = 0.8,
    this.speechRate = 0.8,
    this.pitch = 1.0,
    this.batteryOptimizationEnabled = true,
    this.trafficAlertsEnabled = true,
    this.emergencyAlertsEnabled = true,
    this.preferredVoiceGender = VoiceGender.female,
    this.duckingMode = AudioDuckingMode.duckOthers,
    this.instructionRepeatCount = 1,
    this.hapticFeedbackEnabled = true,
    this.enabledFeatures = const ['navigation', 'traffic', 'emergency'],
    this.customSettings = const {},
  });

  /// Convert to JSON map for serialization
  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'isEnabled': isEnabled,
      'volume': volume,
      'speechRate': speechRate,
      'pitch': pitch,
      'batteryOptimizationEnabled': batteryOptimizationEnabled,
      'trafficAlertsEnabled': trafficAlertsEnabled,
      'emergencyAlertsEnabled': emergencyAlertsEnabled,
      'preferredVoiceGender': preferredVoiceGender.name,
      'duckingMode': duckingMode.name,
      'instructionRepeatCount': instructionRepeatCount,
      'hapticFeedbackEnabled': hapticFeedbackEnabled,
      'enabledFeatures': enabledFeatures,
      'customSettings': customSettings,
    };
  }

  /// Create from JSON map
  factory VoiceNavigationPreferences.fromJson(Map<String, dynamic> json) {
    return VoiceNavigationPreferences(
      language: json['language'] ?? 'en-MY',
      isEnabled: json['isEnabled'] ?? true,
      volume: (json['volume'] ?? 0.8).toDouble(),
      speechRate: (json['speechRate'] ?? 0.8).toDouble(),
      pitch: (json['pitch'] ?? 1.0).toDouble(),
      batteryOptimizationEnabled: json['batteryOptimizationEnabled'] ?? true,
      trafficAlertsEnabled: json['trafficAlertsEnabled'] ?? true,
      emergencyAlertsEnabled: json['emergencyAlertsEnabled'] ?? true,
      preferredVoiceGender: VoiceGender.values.firstWhere(
        (e) => e.name == json['preferredVoiceGender'],
        orElse: () => VoiceGender.female,
      ),
      duckingMode: AudioDuckingMode.values.firstWhere(
        (e) => e.name == json['duckingMode'],
        orElse: () => AudioDuckingMode.duckOthers,
      ),
      instructionRepeatCount: json['instructionRepeatCount'] ?? 1,
      hapticFeedbackEnabled: json['hapticFeedbackEnabled'] ?? true,
      enabledFeatures: List<String>.from(json['enabledFeatures'] ?? ['navigation', 'traffic', 'emergency']),
      customSettings: Map<String, dynamic>.from(json['customSettings'] ?? {}),
    );
  }

  /// Create default preferences for a specific language
  factory VoiceNavigationPreferences.forLanguage(String language) {
    switch (language) {
      case 'ms-MY':
        return const VoiceNavigationPreferences(
          language: 'ms-MY',
          speechRate: 0.7, // Slightly slower for Malay
          enabledFeatures: ['navigation', 'traffic', 'emergency'],
        );
      case 'zh-CN':
        return const VoiceNavigationPreferences(
          language: 'zh-CN',
          speechRate: 0.7,
          pitch: 1.1,
          enabledFeatures: ['navigation', 'traffic', 'emergency'],
        );
      case 'ta-MY':
        return const VoiceNavigationPreferences(
          language: 'ta-MY',
          speechRate: 0.7,
          enabledFeatures: ['navigation', 'traffic'], // Limited features for Tamil
        );
      default:
        return VoiceNavigationPreferences(language: language);
    }
  }

  /// Copy with method for immutable updates
  VoiceNavigationPreferences copyWith({
    String? language,
    bool? isEnabled,
    double? volume,
    double? speechRate,
    double? pitch,
    bool? batteryOptimizationEnabled,
    bool? trafficAlertsEnabled,
    bool? emergencyAlertsEnabled,
    VoiceGender? preferredVoiceGender,
    AudioDuckingMode? duckingMode,
    int? instructionRepeatCount,
    bool? hapticFeedbackEnabled,
    List<String>? enabledFeatures,
    Map<String, dynamic>? customSettings,
  }) {
    return VoiceNavigationPreferences(
      language: language ?? this.language,
      isEnabled: isEnabled ?? this.isEnabled,
      volume: volume ?? this.volume,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      batteryOptimizationEnabled: batteryOptimizationEnabled ?? this.batteryOptimizationEnabled,
      trafficAlertsEnabled: trafficAlertsEnabled ?? this.trafficAlertsEnabled,
      emergencyAlertsEnabled: emergencyAlertsEnabled ?? this.emergencyAlertsEnabled,
      preferredVoiceGender: preferredVoiceGender ?? this.preferredVoiceGender,
      duckingMode: duckingMode ?? this.duckingMode,
      instructionRepeatCount: instructionRepeatCount ?? this.instructionRepeatCount,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  /// Validate preferences and return validation errors
  List<String> validate() {
    final errors = <String>[];

    if (volume < 0.0 || volume > 1.0) {
      errors.add('Volume must be between 0.0 and 1.0');
    }

    if (speechRate < 0.1 || speechRate > 2.0) {
      errors.add('Speech rate must be between 0.1 and 2.0');
    }

    if (pitch < 0.5 || pitch > 2.0) {
      errors.add('Pitch must be between 0.5 and 2.0');
    }

    if (instructionRepeatCount < 1 || instructionRepeatCount > 3) {
      errors.add('Instruction repeat count must be between 1 and 3');
    }

    final supportedLanguages = ['en-MY', 'ms-MY', 'zh-CN', 'ta-MY'];
    if (!supportedLanguages.contains(language)) {
      errors.add('Unsupported language: $language');
    }

    return errors;
  }

  /// Check if a feature is enabled
  bool isFeatureEnabled(String feature) {
    return enabledFeatures.contains(feature);
  }

  /// Get display name for current language
  String get languageDisplayName {
    switch (language) {
      case 'en-MY':
        return 'English (Malaysia)';
      case 'ms-MY':
        return 'Bahasa Melayu (Malaysia)';
      case 'zh-CN':
        return '中文 (简体)';
      case 'ta-MY':
        return 'தமிழ் (மலேசியா)';
      default:
        return language;
    }
  }

  /// Get native display name for current language
  String get nativeLanguageDisplayName {
    switch (language) {
      case 'en-MY':
        return 'English (Malaysia)';
      case 'ms-MY':
        return 'Bahasa Melayu (Malaysia)';
      case 'zh-CN':
        return '中文 (简体)';
      case 'ta-MY':
        return 'தமிழ் (மலேசியா)';
      default:
        return language;
    }
  }

  @override
  List<Object?> get props => [
        language,
        isEnabled,
        volume,
        speechRate,
        pitch,
        batteryOptimizationEnabled,
        trafficAlertsEnabled,
        emergencyAlertsEnabled,
        preferredVoiceGender,
        duckingMode,
        instructionRepeatCount,
        hapticFeedbackEnabled,
        enabledFeatures,
        customSettings,
      ];
}

/// Voice gender preference
enum VoiceGender {
  male,
  female,
  neutral,
}

/// Audio ducking mode for managing other audio during voice guidance
enum AudioDuckingMode {
  duckOthers,
  mixWithOthers,
  interruptOthers,
}

/// Extension methods for VoiceGender
extension VoiceGenderExtension on VoiceGender {
  String get displayName {
    switch (this) {
      case VoiceGender.male:
        return 'Male';
      case VoiceGender.female:
        return 'Female';
      case VoiceGender.neutral:
        return 'Neutral';
    }
  }
}

/// Extension methods for AudioDuckingMode
extension AudioDuckingModeExtension on AudioDuckingMode {
  String get displayName {
    switch (this) {
      case AudioDuckingMode.duckOthers:
        return 'Lower other audio';
      case AudioDuckingMode.mixWithOthers:
        return 'Mix with other audio';
      case AudioDuckingMode.interruptOthers:
        return 'Pause other audio';
    }
  }

  String get description {
    switch (this) {
      case AudioDuckingMode.duckOthers:
        return 'Temporarily lower the volume of other audio during voice guidance';
      case AudioDuckingMode.mixWithOthers:
        return 'Play voice guidance alongside other audio at normal volume';
      case AudioDuckingMode.interruptOthers:
        return 'Pause other audio completely during voice guidance';
    }
  }
}
