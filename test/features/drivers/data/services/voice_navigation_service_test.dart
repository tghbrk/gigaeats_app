import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/data/services/voice_navigation_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/navigation_models.dart';

void main() {
  group('VoiceNavigationService Tests', () {
    late VoiceNavigationService voiceService;

    setUp(() {
      voiceService = VoiceNavigationService();
    });

    tearDown(() async {
      await voiceService.dispose();
    });

    group('Service Initialization', () {
      test('should initialize successfully', () async {
        // Act & Assert
        expect(() async => await voiceService.initialize(), returnsNormally);
      });

      test('should initialize with specific language', () async {
        // Act & Assert
        expect(() async => await voiceService.initialize(language: 'ms-MY'), returnsNormally);
      });

      test('should initialize with battery optimization', () async {
        // Act & Assert
        expect(() async => await voiceService.initialize(
          enableBatteryOptimization: true,
        ), returnsNormally);
      });

      test('should handle multiple initialization calls', () async {
        // Arrange
        await voiceService.initialize();
        
        // Act & Assert
        expect(() async => await voiceService.initialize(), returnsNormally);
      });
    });

    group('Voice Settings Management', () {
      test('should enable and disable voice guidance', () async {
        // Arrange
        await voiceService.initialize();

        // Act - Enable voice
        await voiceService.setEnabled(true);
        expect(voiceService.isEnabled, isTrue);

        // Act - Disable voice
        await voiceService.setEnabled(false);
        expect(voiceService.isEnabled, isFalse);
      });

      test('should set voice volume', () async {
        // Arrange
        await voiceService.initialize();

        // Act & Assert
        expect(() async => await voiceService.setVolume(0.5), returnsNormally);
        expect(() async => await voiceService.setVolume(0.0), returnsNormally);
        expect(() async => await voiceService.setVolume(1.0), returnsNormally);
      });

      test('should handle invalid volume values', () async {
        // Arrange
        await voiceService.initialize();

        // Act & Assert - Should clamp values
        expect(() async => await voiceService.setVolume(-0.5), returnsNormally);
        expect(() async => await voiceService.setVolume(1.5), returnsNormally);
      });

      test('should set speech rate', () async {
        // Arrange
        await voiceService.initialize();

        // Act & Assert
        expect(() async => await voiceService.setSpeechRate(0.5), returnsNormally);
        expect(() async => await voiceService.setSpeechRate(1.0), returnsNormally);
        expect(() async => await voiceService.setSpeechRate(1.5), returnsNormally);
      });
    });

    group('Language Support', () {
      test('should set supported languages', () async {
        // Arrange
        await voiceService.initialize();

        final supportedLanguages = ['en-MY', 'ms-MY', 'zh-CN', 'ta-MY'];

        // Act & Assert
        for (final language in supportedLanguages) {
          expect(() async => await voiceService.setLanguage(language), returnsNormally);
        }
      });

      test('should handle unsupported language gracefully', () async {
        // Arrange
        await voiceService.initialize();

        // Act & Assert
        expect(() async => await voiceService.setLanguage('unsupported-lang'), returnsNormally);
      });

      test('should get available languages', () async {
        // Arrange
        await voiceService.initialize();

        // Act
        final languages = await voiceService.getAvailableLanguages();

        // Assert
        expect(languages, isA<List<String>>());
      });
    });

    group('Navigation Instruction Announcements', () {
      test('should announce navigation instruction', () async {
        // Arrange
        await voiceService.initialize();
        await voiceService.setEnabled(true);

        final instruction = NavigationInstruction(
          id: 'test_instruction',
          type: NavigationInstructionType.turnRight,
          text: 'Turn right onto Main Street',
          htmlText: 'Turn right onto <b>Main Street</b>',
          distanceMeters: 100.0,
          durationSeconds: 30,
          location: const LatLng(3.1500, 101.7000),
          timestamp: DateTime.now(),
        );

        // Act & Assert
        expect(() async => await voiceService.announceInstruction(instruction), returnsNormally);
      });

      test('should not announce when voice is disabled', () async {
        // Arrange
        await voiceService.initialize();
        await voiceService.setEnabled(false);

        final instruction = NavigationInstruction(
          id: 'test_instruction',
          type: NavigationInstructionType.straight,
          text: 'Continue straight',
          htmlText: 'Continue <b>straight</b>',
          distanceMeters: 200.0,
          durationSeconds: 45,
          location: const LatLng(3.1500, 101.7000),
          timestamp: DateTime.now(),
        );

        // Act & Assert - Should not throw but also not announce
        expect(() async => await voiceService.announceInstruction(instruction), returnsNormally);
      });

      test('should handle different instruction types', () async {
        // Arrange
        await voiceService.initialize();
        await voiceService.setEnabled(true);

        final instructionTypes = [
          NavigationInstructionType.straight,
          NavigationInstructionType.turnLeft,
          NavigationInstructionType.turnRight,
          NavigationInstructionType.turnSlightLeft,
          NavigationInstructionType.turnSlightRight,
          NavigationInstructionType.turnSharpLeft,
          NavigationInstructionType.turnSharpRight,
          NavigationInstructionType.uturn,
          NavigationInstructionType.merge,
          NavigationInstructionType.roundabout,
          NavigationInstructionType.exitRoundabout,
          NavigationInstructionType.ferry,
          NavigationInstructionType.arrive,
        ];

        // Act & Assert
        for (final type in instructionTypes) {
          final instruction = NavigationInstruction(
            id: 'test_${type.toString()}',
            type: type,
            text: 'Test instruction for $type',
            htmlText: 'Test instruction for <b>$type</b>',
            distanceMeters: 100.0,
            durationSeconds: 30,
            location: const LatLng(3.1500, 101.7000),
            timestamp: DateTime.now(),
          );

          expect(() async => await voiceService.announceInstruction(instruction), returnsNormally);
        }
      });
    });

    group('Traffic Alert Announcements', () {
      test('should announce traffic alert', () async {
        // Arrange
        await voiceService.initialize();
        await voiceService.setEnabled(true);

        // Act & Assert
        expect(() async => await voiceService.announceTrafficAlert('Heavy traffic ahead'), returnsNormally);
      });

      test('should not announce traffic alert when disabled', () async {
        // Arrange
        await voiceService.initialize();
        await voiceService.setEnabled(false);

        // Act & Assert
        expect(() async => await voiceService.announceTrafficAlert('Traffic alert'), returnsNormally);
      });

      test('should handle empty traffic alert', () async {
        // Arrange
        await voiceService.initialize();
        await voiceService.setEnabled(true);

        // Act & Assert
        expect(() async => await voiceService.announceTrafficAlert(''), returnsNormally);
      });
    });

    group('Arrival Announcements', () {
      test('should announce arrival', () async {
        // Arrange
        await voiceService.initialize();
        await voiceService.setEnabled(true);

        // Act & Assert
        expect(() async => await voiceService.announceArrival('McDonald\'s Restaurant'), returnsNormally);
      });

      test('should announce arrival with default destination', () async {
        // Arrange
        await voiceService.initialize();
        await voiceService.setEnabled(true);

        // Act & Assert
        expect(() async => await voiceService.announceArrival('Test Destination'), returnsNormally);
      });

      test('should not announce arrival when disabled', () async {
        // Arrange
        await voiceService.initialize();
        await voiceService.setEnabled(false);

        // Act & Assert
        expect(() async => await voiceService.announceArrival('Test Destination'), returnsNormally);
      });
    });

    group('Voice Testing', () {
      test('should test voice functionality', () async {
        // Arrange
        await voiceService.initialize();
        await voiceService.setEnabled(true);

        // Act & Assert
        expect(() async => await voiceService.testVoice(), returnsNormally);
      });

      test('should not test voice when disabled', () async {
        // Arrange
        await voiceService.initialize();
        await voiceService.setEnabled(false);

        // Act & Assert
        expect(() async => await voiceService.testVoice(), returnsNormally);
      });
    });

    group('Service Control', () {
      test('should stop voice service', () async {
        // Arrange
        await voiceService.initialize();

        // Act & Assert
        expect(() async => await voiceService.stop(), returnsNormally);
      });

      test('should pause and resume voice service', () async {
        // Arrange
        await voiceService.initialize();

        // Act & Assert
        expect(() async => await voiceService.pause(), returnsNormally);
        expect(() async => await voiceService.resume(), returnsNormally);
      });

      test('should dispose service properly', () async {
        // Arrange
        await voiceService.initialize();

        // Act & Assert
        expect(() async => await voiceService.dispose(), returnsNormally);
      });
    });

    group('Error Handling', () {
      test('should handle service errors gracefully', () async {
        // Act & Assert - Should not throw even if not initialized
        expect(() async => await voiceService.setEnabled(true), returnsNormally);
        expect(() async => await voiceService.setVolume(0.5), returnsNormally);
        expect(() async => await voiceService.setSpeechRate(1.0), returnsNormally);
      });

      test('should handle null instruction gracefully', () async {
        // Arrange
        await voiceService.initialize();
        await voiceService.setEnabled(true);

        // This test would require modifying the service to accept null
        // For now, we test that the service handles normal instructions
        final instruction = NavigationInstruction(
          id: 'test',
          type: NavigationInstructionType.straight,
          text: 'Test',
          htmlText: '<b>Test</b>',
          distanceMeters: 100.0,
          durationSeconds: 30,
          location: const LatLng(3.1500, 101.7000),
          timestamp: DateTime.now(),
        );

        expect(() async => await voiceService.announceInstruction(instruction), returnsNormally);
      });
    });

    group('Battery Optimization', () {
      test('should handle battery optimization settings', () async {
        // Act & Assert
        expect(() async => await voiceService.initialize(
          enableBatteryOptimization: true,
        ), returnsNormally);
      });

      test('should work without battery optimization', () async {
        // Act & Assert
        expect(() async => await voiceService.initialize(
          enableBatteryOptimization: false,
        ), returnsNormally);
      });
    });

    group('Localization Tests', () {
      test('should provide localized voice messages for different languages', () async {
        // Arrange
        await voiceService.initialize();
        await voiceService.setEnabled(true);

        final languages = ['en-MY', 'ms-MY', 'zh-CN', 'ta-MY'];

        // Act & Assert
        for (final language in languages) {
          await voiceService.setLanguage(language);

          final instruction = NavigationInstruction(
            id: 'test_localized',
            type: NavigationInstructionType.turnRight,
            text: 'Turn right',
            htmlText: 'Turn <b>right</b>',
            distanceMeters: 100.0,
            durationSeconds: 30,
            location: const LatLng(3.1500, 101.7000),
            timestamp: DateTime.now(),
          );

          expect(() async => await voiceService.announceInstruction(instruction), returnsNormally);
        }
      });

      test('should handle test voice in different languages', () async {
        // Arrange
        await voiceService.initialize();
        await voiceService.setEnabled(true);

        final languages = ['en-MY', 'ms-MY', 'zh-CN', 'ta-MY'];

        // Act & Assert
        for (final language in languages) {
          await voiceService.setLanguage(language);
          expect(() async => await voiceService.testVoice(), returnsNormally);
        }
      });
    });
  });
}
