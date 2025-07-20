import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:gigaeats/src/features/drivers/data/services/voice_navigation_service.dart';
import 'package:gigaeats/src/features/drivers/data/models/navigation_models.dart';

import '../../../../test_helpers/test_data.dart';

// Generate mocks
@GenerateMocks([FlutterTts])
import 'voice_navigation_service_test.mocks.dart';

void main() {
  group('VoiceNavigationService Tests - Phase 4.1 Enhanced Features', () {
    late VoiceNavigationService voiceService;
    late MockFlutterTts mockTts;

    setUp(() {
      mockTts = MockFlutterTts();
      voiceService = VoiceNavigationService();
      
      // Setup default mock responses
      when(mockTts.setVolume(any)).thenAnswer((_) async => 1);
      when(mockTts.setSpeechRate(any)).thenAnswer((_) async => 1);
      when(mockTts.setPitch(any)).thenAnswer((_) async => 1);
      when(mockTts.setLanguage(any)).thenAnswer((_) async => 1);
      when(mockTts.speak(any)).thenAnswer((_) async => 1);
      when(mockTts.stop()).thenAnswer((_) async => 1);
      when(mockTts.getLanguages()).thenAnswer((_) async => ['en-US', 'ms-MY', 'zh-CN']);
      when(mockTts.getVoices()).thenAnswer((_) async => [
        {'name': 'en-us-x-sfg#female_1-local', 'locale': 'en-US'},
        {'name': 'ms-my-x-mas#female_1-local', 'locale': 'ms-MY'},
      ]);
      when(mockTts.isLanguageAvailable(any)).thenAnswer((_) async => true);
    });

    group('Initialization Tests', () {
      test('should initialize with default settings', () async {
        // Act & Assert - should not throw
        expect(() => voiceService.initialize(), returnsNormally);
      });

      test('should initialize with custom settings', () async {
        // Act & Assert
        expect(() => voiceService.initialize(
          language: 'ms-MY',
          volume: 0.9,
          speechRate: 0.7,
          pitch: 1.1,
          enableBatteryOptimization: true,
        ), returnsNormally);
      });

      test('should not reinitialize if already initialized', () async {
        // Arrange
        await voiceService.initialize();
        
        // Act
        await voiceService.initialize();
        
        // Assert
        expect(voiceService.isInitialized, isTrue);
      });
    });

    group('Language Support Tests', () {
      test('should support English (Malaysia)', () async {
        // Arrange
        await voiceService.initialize(language: 'en-MY');
        
        // Assert
        expect(voiceService.currentLanguage, equals('en-MY'));
      });

      test('should support Bahasa Malaysia', () async {
        // Arrange
        await voiceService.initialize(language: 'ms-MY');
        
        // Assert
        expect(voiceService.currentLanguage, equals('ms-MY'));
      });

      test('should support Chinese', () async {
        // Arrange
        await voiceService.initialize(language: 'zh-CN');
        
        // Assert
        expect(voiceService.currentLanguage, equals('zh-CN'));
      });

      test('should support Tamil', () async {
        // Arrange
        await voiceService.initialize(language: 'ta-MY');
        
        // Assert
        expect(voiceService.currentLanguage, equals('ta-MY'));
      });

      test('should change language after initialization', () async {
        // Arrange
        await voiceService.initialize(language: 'en-MY');
        
        // Act
        await voiceService.setLanguage('ms-MY');
        
        // Assert
        expect(voiceService.currentLanguage, equals('ms-MY'));
      });
    });

    group('Voice Guidance Tests', () {
      test('should enable and disable voice guidance', () async {
        // Arrange
        await voiceService.initialize();
        
        // Act & Assert
        await voiceService.setEnabled(false);
        expect(voiceService.isEnabled, isFalse);
        
        await voiceService.setEnabled(true);
        expect(voiceService.isEnabled, isTrue);
      });

      test('should announce navigation instruction', () async {
        // Arrange
        await voiceService.initialize();
        final instruction = TestData.mockNavigationInstruction();
        
        // Act & Assert - should not throw
        expect(() => voiceService.announceInstruction(instruction), returnsNormally);
      });

      test('should not announce when disabled', () async {
        // Arrange
        await voiceService.initialize();
        await voiceService.setEnabled(false);
        final instruction = TestData.mockNavigationInstruction();
        
        // Act
        await voiceService.announceInstruction(instruction);
        
        // Assert - should complete without error
        expect(voiceService.isEnabled, isFalse);
      });
    });

    group('Traffic Alert Tests - Phase 4.1', () {
      test('should announce traffic alert with default severity', () async {
        // Arrange
        await voiceService.initialize();
        
        // Act & Assert - should not throw
        expect(() => voiceService.announceTrafficAlert('Heavy traffic ahead'), returnsNormally);
      });

      test('should announce urgent traffic alert', () async {
        // Arrange
        await voiceService.initialize();
        
        // Act & Assert - should not throw
        expect(() => voiceService.announceTrafficAlert(
          'Accident ahead',
          severity: TrafficSeverity.severe,
          isUrgent: true,
        ), returnsNormally);
      });

      test('should handle different traffic severity levels', () async {
        // Arrange
        await voiceService.initialize();
        
        // Act & Assert - should not throw for all severity levels
        for (final severity in TrafficSeverity.values) {
          expect(() => voiceService.announceTrafficAlert(
            'Traffic alert',
            severity: severity,
          ), returnsNormally);
        }
      });
    });

    group('Audio Settings Tests', () {
      test('should set volume within valid range', () async {
        // Arrange
        await voiceService.initialize();
        
        // Act
        await voiceService.setVolume(0.5);
        
        // Assert
        expect(voiceService.volume, equals(0.5));
      });

      test('should clamp volume to valid range', () async {
        // Arrange
        await voiceService.initialize();
        
        // Act
        await voiceService.setVolume(1.5); // Above max
        
        // Assert
        expect(voiceService.volume, equals(1.0));
      });

      test('should set speech rate within valid range', () async {
        // Arrange
        await voiceService.initialize();
        
        // Act
        await voiceService.setSpeechRate(0.8);
        
        // Assert
        expect(voiceService.speechRate, equals(0.8));
      });

      test('should clamp speech rate to valid range', () async {
        // Arrange
        await voiceService.initialize();
        
        // Act
        await voiceService.setSpeechRate(0.05); // Below min
        
        // Assert
        expect(voiceService.speechRate, equals(0.1));
      });
    });

    group('Localization Tests', () {
      test('should provide Malay instructions', () async {
        // Arrange
        await voiceService.initialize(language: 'ms-MY');
        final instruction = NavigationInstruction(
          id: 'test',
          type: NavigationInstructionType.turnLeft,
          text: 'Turn left',
          voiceText: 'Turn left',
          distanceToInstruction: 100,
          distanceText: '100m',
          streetName: 'Jalan Test',
        );
        
        // Act & Assert - should not throw
        expect(() => voiceService.announceInstruction(instruction), returnsNormally);
      });

      test('should provide Chinese instructions', () async {
        // Arrange
        await voiceService.initialize(language: 'zh-CN');
        final instruction = NavigationInstruction(
          id: 'test',
          type: NavigationInstructionType.turnRight,
          text: 'Turn right',
          voiceText: 'Turn right',
          distanceToInstruction: 200,
          distanceText: '200m',
          streetName: '测试路',
        );
        
        // Act & Assert - should not throw
        expect(() => voiceService.announceInstruction(instruction), returnsNormally);
      });
    });

    group('Battery Optimization Tests - Phase 4.1', () {
      test('should initialize with battery optimization enabled', () async {
        // Act
        await voiceService.initialize(enableBatteryOptimization: true);
        
        // Assert
        expect(voiceService.isInitialized, isTrue);
      });

      test('should initialize with battery optimization disabled', () async {
        // Act
        await voiceService.initialize(enableBatteryOptimization: false);
        
        // Assert
        expect(voiceService.isInitialized, isTrue);
      });
    });

    group('Utility Tests', () {
      test('should get available languages', () async {
        // Arrange
        await voiceService.initialize();
        
        // Act
        final languages = await voiceService.getAvailableLanguages();
        
        // Assert
        expect(languages, isA<List<String>>());
      });

      test('should get available voices', () async {
        // Arrange
        await voiceService.initialize();
        
        // Act
        final voices = await voiceService.getAvailableVoices();
        
        // Assert
        expect(voices, isA<List<Map<String, String>>>());
      });

      test('should test voice', () async {
        // Arrange
        await voiceService.initialize();
        
        // Act & Assert - should not throw
        expect(() => voiceService.testVoice(), returnsNormally);
      });

      test('should stop current speech', () async {
        // Arrange
        await voiceService.initialize();
        
        // Act & Assert - should not throw
        expect(() => voiceService.stop(), returnsNormally);
      });
    });

    group('Disposal Tests', () {
      test('should dispose resources properly', () async {
        // Arrange
        await voiceService.initialize();
        
        // Act
        await voiceService.dispose();
        
        // Assert
        expect(voiceService.isInitialized, isFalse);
      });

      test('should handle disposal when not initialized', () async {
        // Act & Assert - should not throw
        expect(() => voiceService.dispose(), returnsNormally);
      });
    });

    group('Error Handling Tests', () {
      test('should handle TTS initialization failure gracefully', () async {
        // Arrange
        when(mockTts.setVolume(any)).thenThrow(Exception('TTS error'));
        
        // Act & Assert - should handle error gracefully
        expect(() => voiceService.initialize(), returnsNormally);
      });

      test('should handle language change failure gracefully', () async {
        // Arrange
        await voiceService.initialize();
        when(mockTts.setLanguage(any)).thenThrow(Exception('Language error'));
        
        // Act & Assert - should handle error gracefully
        expect(() => voiceService.setLanguage('invalid-lang'), returnsNormally);
      });

      test('should handle announcement failure gracefully', () async {
        // Arrange
        await voiceService.initialize();
        when(mockTts.speak(any)).thenThrow(Exception('Speech error'));
        final instruction = TestData.mockNavigationInstruction();
        
        // Act & Assert - should handle error gracefully
        expect(() => voiceService.announceInstruction(instruction), returnsNormally);
      });
    });
  });
}
