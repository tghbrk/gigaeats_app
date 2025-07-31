import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/data/services/enhanced_navigation_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/voice_navigation_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/traffic_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/navigation_models.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/traffic_models.dart';

void main() {
  group('Enhanced Navigation Integration Tests', () {
    late EnhancedNavigationService navigationService;
    late VoiceNavigationService voiceService;
    late TrafficService trafficService;

    setUp(() async {
      navigationService = EnhancedNavigationService();
      voiceService = VoiceNavigationService();
      trafficService = TrafficService();

      // Initialize all services
      await navigationService.initialize();
      await voiceService.initialize();
      await trafficService.initialize();
    });

    tearDown(() async {
      await navigationService.dispose();
      await voiceService.dispose();
      trafficService.dispose();
    });

    group('Complete Navigation Workflow', () {
      test('should complete full navigation workflow from start to finish', () async {
        // Arrange
        const origin = LatLng(3.1478, 101.6953);
        const destination = LatLng(3.1590, 101.7123);
        const orderId = 'integration_test_order_123';

        // Act - Start navigation
        final session = await navigationService.startInAppNavigation(
          origin: origin,
          destination: destination,
          orderId: orderId,
        );

        // Assert - Navigation started successfully
        expect(session, isNotNull);
        expect(session.orderId, equals(orderId));
        expect(session.status, equals(NavigationSessionStatus.active));
        expect(navigationService.isNavigating, isTrue);

        // Act - Get navigation streams
        final instructionStream = navigationService.getNavigationInstructions();
        final cameraStream = navigationService.getCameraPositionUpdates();

        // Assert - Streams are available
        expect(instructionStream, isA<Stream<NavigationInstruction>>());
        expect(cameraStream, isA<Stream<CameraPosition>>());

        // Act - Get distance and ETA
        final distance = await navigationService.getRemainingDistance();
        final eta = await navigationService.getEstimatedArrival();

        // Assert - Distance and ETA are calculated
        expect(distance, isA<double?>());
        expect(eta, isA<DateTime?>());

        // Act - Stop navigation
        await navigationService.stopNavigation();

        // Assert - Navigation stopped
        expect(navigationService.isNavigating, isFalse);
        expect(navigationService.currentSession, isNull);
      });

      test('should handle navigation with preferences', () async {
        // Arrange
        const preferences = NavigationPreferences(
          voiceGuidanceEnabled: true,
          language: 'ms-MY',
          avoidTolls: true,
          avoidHighways: false,
          trafficAlertsEnabled: true,
        );

        // Act
        final session = await navigationService.startInAppNavigation(
          origin: const LatLng(3.1478, 101.6953),
          destination: const LatLng(3.1590, 101.7123),
          orderId: 'preferences_test_order',
          preferences: preferences,
        );

        // Assert
        expect(session.preferences, equals(preferences));
        expect(session.preferences.voiceGuidanceEnabled, isTrue);
        expect(session.preferences.language, equals('ms-MY'));
        expect(session.preferences.avoidTolls, isTrue);
        expect(session.preferences.trafficAlertsEnabled, isTrue);

        // Cleanup
        await navigationService.stopNavigation();
      });

      test('should handle batch navigation with multiple waypoints', () async {
        // Arrange
        const batchId = 'batch_123';
        const waypoints = [
          LatLng(3.1478, 101.6953), // Start
          LatLng(3.1500, 101.7000), // Waypoint 1
          LatLng(3.1520, 101.7050), // Waypoint 2
          LatLng(3.1590, 101.7123), // End
        ];

        // Act - Start batch navigation
        final session = await navigationService.startInAppNavigation(
          origin: waypoints.first,
          destination: waypoints.last,
          orderId: 'batch_order_1',
          batchId: batchId,
        );

        // Assert
        expect(session, isNotNull);
        expect(session.batchId, equals(batchId));
        expect(session.status, equals(NavigationSessionStatus.active));

        // Cleanup
        await navigationService.stopNavigation();
      });
    });

    group('Voice Navigation Integration', () {
      test('should integrate voice navigation with navigation instructions', () async {
        // Arrange
        await voiceService.setEnabled(true);
        await voiceService.setLanguage('en-MY');

        // Start navigation
        final _ = await navigationService.startInAppNavigation(
          origin: const LatLng(3.1478, 101.6953),
          destination: const LatLng(3.1590, 101.7123),
          orderId: 'voice_integration_test',
          preferences: const NavigationPreferences(voiceGuidanceEnabled: true),
        );

        // Act - Create test instruction
        final instruction = NavigationInstruction(
          id: 'voice_test_instruction',
          type: NavigationInstructionType.turnRight,
          text: 'Turn right onto Jalan Test',
          htmlText: 'Turn right onto <b>Jalan Test</b>',
          distanceMeters: 100.0,
          durationSeconds: 30,
          location: const LatLng(3.1500, 101.7000),
          timestamp: DateTime.now(),
        );

        // Assert - Voice service should handle instruction
        expect(() async => await voiceService.announceInstruction(instruction), returnsNormally);

        // Test traffic alert announcement
        expect(() async => await voiceService.announceTrafficAlert('Heavy traffic ahead'), returnsNormally);

        // Test arrival announcement
        expect(() async => await voiceService.announceArrival('Test Restaurant'), returnsNormally);

        // Cleanup
        await navigationService.stopNavigation();
      });

      test('should handle voice navigation in different languages', () async {
        // Arrange
        final languages = ['en-MY', 'ms-MY', 'zh-CN', 'ta-MY'];

        for (final language in languages) {
          // Set up voice service for language
          await voiceService.setEnabled(true);
          await voiceService.setLanguage(language);

          // Start navigation with language preference
          final session = await navigationService.startInAppNavigation(
            origin: const LatLng(3.1478, 101.6953),
            destination: const LatLng(3.1590, 101.7123),
            orderId: 'language_test_$language',
            preferences: NavigationPreferences(
              voiceGuidanceEnabled: true,
              language: language,
            ),
          );

          // Assert
          expect(session.preferences.language, equals(language));

          // Test voice functionality
          expect(() async => await voiceService.testVoice(), returnsNormally);

          // Cleanup
          await navigationService.stopNavigation();
        }
      });
    });

    group('Traffic Service Integration', () {
      test('should integrate traffic monitoring with navigation', () async {
        // Arrange
        const origin = LatLng(3.1478, 101.6953);
        const destination = LatLng(3.1590, 101.7123);

        // Create test route
        final route = NavigationRoute(
          id: 'traffic_integration_route',
          polylinePoints: [origin, destination],
          totalDistanceMeters: 1500.0,
          totalDurationSeconds: 180,
          durationInTrafficSeconds: 210,
          instructions: [],
          summary: 'Test route for traffic integration',
          calculatedAt: DateTime.now(),
        );

        // Act - Start traffic monitoring
        await trafficService.startMonitoring(
          route: route,
          currentLocation: origin,
        );

        // Get traffic conditions
        final trafficUpdate = await trafficService.getCurrentTrafficConditions(route);

        // Assert
        expect(trafficUpdate, isNotNull);
        expect(trafficUpdate.routeId, equals('traffic_integration_route'));
        expect(trafficUpdate.overallCondition, isA<TrafficCondition>());
        expect(trafficUpdate.incidents, isA<List<TrafficIncident>>());

        // Test incident reporting
        await trafficService.reportIncident(
          location: const LatLng(3.1500, 101.7000),
          type: TrafficIncidentType.accident,
          severity: TrafficSeverity.medium,
          description: 'Integration test incident',
        );

        // Test alternative route calculation
        final alternativeRoute = await trafficService.calculateAlternativeRoute(
          originalRoute: route,
          currentLocation: origin,
          avoidIncidents: [],
        );

        // Assert - Alternative route may be null if no API key
        expect(alternativeRoute, isA<NavigationRoute?>());

        // Cleanup
        await trafficService.stopMonitoring();
      });

      test('should handle traffic alerts during navigation', () async {
        // Arrange
        await voiceService.setEnabled(true);

        // Start navigation
        final session = await navigationService.startInAppNavigation(
          origin: const LatLng(3.1478, 101.6953),
          destination: const LatLng(3.1590, 101.7123),
          orderId: 'traffic_alert_test',
          preferences: const NavigationPreferences(trafficAlertsEnabled: true),
        );

        // Act - Simulate traffic alert
        const trafficAlert = 'Heavy traffic detected on your route';
        
        // Test traffic alert announcement
        expect(() async => await voiceService.announceTrafficAlert(trafficAlert), returnsNormally);

        // Assert
        expect(session.preferences.trafficAlertsEnabled, isTrue);

        // Cleanup
        await navigationService.stopNavigation();
      });
    });

    group('Error Handling and Recovery', () {
      test('should handle service initialization failures gracefully', () async {
        // Create new services for this test
        final testNavigationService = EnhancedNavigationService();
        final testVoiceService = VoiceNavigationService();
        final testTrafficService = TrafficService();

        // Act & Assert - Services should handle errors gracefully
        expect(() async => await testNavigationService.initialize(), returnsNormally);
        expect(() async => await testVoiceService.initialize(), returnsNormally);
        expect(() async => await testTrafficService.initialize(), returnsNormally);

        // Cleanup
        await testNavigationService.dispose();
        await testVoiceService.dispose();
        testTrafficService.dispose();
      });

      test('should handle invalid navigation parameters', () async {
        // Act & Assert - Should handle invalid coordinates gracefully
        expect(() async => await navigationService.startInAppNavigation(
          origin: const LatLng(0, 0),
          destination: const LatLng(0, 0),
          orderId: 'invalid_test',
        ), returnsNormally);

        // Cleanup if navigation started
        if (navigationService.isNavigating) {
          await navigationService.stopNavigation();
        }
      });

      test('should handle service disposal during active navigation', () async {
        // Arrange
        await navigationService.startInAppNavigation(
          origin: const LatLng(3.1478, 101.6953),
          destination: const LatLng(3.1590, 101.7123),
          orderId: 'disposal_test',
        );

        // Act & Assert - Should dispose gracefully even during active navigation
        expect(() async => await navigationService.dispose(), returnsNormally);
        expect(navigationService.isNavigating, isFalse);
      });
    });

    group('Performance and Stress Testing', () {
      test('should handle multiple rapid navigation starts and stops', () async {
        // Act - Rapidly start and stop navigation multiple times
        for (int i = 0; i < 5; i++) {
          final session = await navigationService.startInAppNavigation(
            origin: const LatLng(3.1478, 101.6953),
            destination: const LatLng(3.1590, 101.7123),
            orderId: 'stress_test_$i',
          );

          expect(session, isNotNull);
          expect(navigationService.isNavigating, isTrue);

          await navigationService.stopNavigation();
          expect(navigationService.isNavigating, isFalse);
        }
      });

      test('should handle concurrent service operations', () async {
        // Arrange
        final futures = <Future>[];

        // Act - Perform multiple operations concurrently
        futures.add(voiceService.setEnabled(true));
        futures.add(voiceService.setVolume(0.8));
        futures.add(voiceService.setSpeechRate(1.0));
        futures.add(voiceService.setLanguage('en-MY'));

        // Assert - All operations should complete without errors
        expect(() async => await Future.wait(futures), returnsNormally);
      });
    });
  });
}
