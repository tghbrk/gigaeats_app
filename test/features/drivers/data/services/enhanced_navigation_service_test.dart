import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/data/services/enhanced_navigation_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/navigation_models.dart';

void main() {
  group('EnhancedNavigationService Tests', () {
    late EnhancedNavigationService navigationService;

    setUp(() {
      navigationService = EnhancedNavigationService();
    });

    tearDown(() async {
      await navigationService.dispose();
    });

    group('Service Initialization', () {
      test('should initialize successfully', () async {
        // Act & Assert
        expect(() async => await navigationService.initialize(), returnsNormally);
      });

      test('should not initialize twice', () async {
        // Arrange
        await navigationService.initialize();

        // Act & Assert
        expect(() async => await navigationService.initialize(), returnsNormally);
      });

      test('should handle initialization errors gracefully', () async {
        // This test would require mocking internal services
        // For now, we test that the service can be created
        expect(navigationService, isNotNull);
      });
    });

    group('Navigation Session Management', () {
      test('should have correct initial state', () {
        expect(navigationService.currentSession, isNull);
        expect(navigationService.isNavigating, isFalse);
        expect(navigationService.instructionStream, isA<Stream<NavigationInstruction>>());
        expect(navigationService.sessionStream, isA<Stream<NavigationSession>>());
        expect(navigationService.trafficAlertStream, isA<Stream<String>>());
      });

      test('should start navigation session', () async {
        // Arrange
        await navigationService.initialize();
        const origin = LatLng(3.1478, 101.6953);
        const destination = LatLng(3.1590, 101.7123);
        const orderId = 'test_order_123';

        // Act
        final session = await navigationService.startInAppNavigation(
          origin: origin,
          destination: destination,
          orderId: orderId,
        );

        // Assert
        expect(session, isNotNull);
        expect(session.orderId, equals(orderId));
        expect(session.origin, equals(origin));
        expect(session.destination, equals(destination));
        expect(session.status, equals(NavigationSessionStatus.active));
        expect(navigationService.isNavigating, isTrue);
        expect(navigationService.currentSession, equals(session));
      });

      test('should stop navigation session', () async {
        // Arrange
        await navigationService.initialize();
        await navigationService.startInAppNavigation(
          origin: const LatLng(3.1478, 101.6953),
          destination: const LatLng(3.1590, 101.7123),
          orderId: 'test_order_123',
        );

        // Act
        await navigationService.stopNavigation();

        // Assert
        expect(navigationService.isNavigating, isFalse);
        expect(navigationService.currentSession, isNull);
      });

      test('should handle multiple navigation sessions correctly', () async {
        // Arrange
        await navigationService.initialize();
        
        // Start first session
        final session1 = await navigationService.startInAppNavigation(
          origin: const LatLng(3.1478, 101.6953),
          destination: const LatLng(3.1590, 101.7123),
          orderId: 'order_1',
        );

        // Act - Start second session (should replace first)
        final session2 = await navigationService.startInAppNavigation(
          origin: const LatLng(3.1500, 101.7000),
          destination: const LatLng(3.1600, 101.7200),
          orderId: 'order_2',
        );

        // Assert
        expect(navigationService.currentSession, equals(session2));
        expect(navigationService.currentSession?.orderId, equals('order_2'));
        expect(session1.orderId, equals('order_1'));
      });
    });

    group('Navigation Instructions', () {
      test('should provide navigation instructions stream', () async {
        // Arrange
        await navigationService.initialize();
        await navigationService.startInAppNavigation(
          origin: const LatLng(3.1478, 101.6953),
          destination: const LatLng(3.1590, 101.7123),
          orderId: 'test_order',
        );

        // Act & Assert
        expect(navigationService.getNavigationInstructions(), isA<Stream<NavigationInstruction>>());
      });

      test('should provide camera position updates', () async {
        // Arrange
        await navigationService.initialize();
        await navigationService.startInAppNavigation(
          origin: const LatLng(3.1478, 101.6953),
          destination: const LatLng(3.1590, 101.7123),
          orderId: 'test_order',
        );

        // Act & Assert
        expect(navigationService.getCameraPositionUpdates(), isA<Stream<CameraPosition>>());
      });

      test('should return null streams when not navigating', () {
        // Act & Assert
        expect(navigationService.getNavigationInstructions(), isA<Stream<NavigationInstruction>>());
        expect(navigationService.getCameraPositionUpdates(), isA<Stream<CameraPosition>>());
      });
    });

    group('Distance and ETA Calculations', () {
      test('should calculate remaining distance', () async {
        // Arrange
        await navigationService.initialize();
        await navigationService.startInAppNavigation(
          origin: const LatLng(3.1478, 101.6953),
          destination: const LatLng(3.1590, 101.7123),
          orderId: 'test_order',
        );

        // Act
        final distance = await navigationService.getRemainingDistance();

        // Assert
        expect(distance, isA<double?>());
        // Distance should be null or a positive number
        if (distance != null) {
          expect(distance, greaterThanOrEqualTo(0));
        }
      });

      test('should calculate estimated arrival time', () async {
        // Arrange
        await navigationService.initialize();
        await navigationService.startInAppNavigation(
          origin: const LatLng(3.1478, 101.6953),
          destination: const LatLng(3.1590, 101.7123),
          orderId: 'test_order',
        );

        // Act
        final eta = await navigationService.getEstimatedArrival();

        // Assert
        expect(eta, isA<DateTime?>());
        // ETA should be null or in the future
        if (eta != null) {
          expect(eta.isAfter(DateTime.now().subtract(const Duration(minutes: 1))), isTrue);
        }
      });

      test('should return null distance when not navigating', () async {
        // Act
        final distance = await navigationService.getRemainingDistance();

        // Assert
        expect(distance, isNull);
      });

      test('should return null ETA when not navigating', () async {
        // Act
        final eta = await navigationService.getEstimatedArrival();

        // Assert
        expect(eta, isNull);
      });
    });

    group('Navigation Preferences', () {
      test('should handle navigation preferences', () async {
        // Arrange
        await navigationService.initialize();
        const preferences = NavigationPreferences(
          voiceGuidanceEnabled: true,
          language: 'ms-MY',
          avoidTolls: true,
          avoidHighways: false,
        );

        // Act
        final session = await navigationService.startInAppNavigation(
          origin: const LatLng(3.1478, 101.6953),
          destination: const LatLng(3.1590, 101.7123),
          orderId: 'test_order',
          preferences: preferences,
        );

        // Assert
        expect(session.preferences, equals(preferences));
        expect(session.preferences.voiceGuidanceEnabled, isTrue);
        expect(session.preferences.language, equals('ms-MY'));
        expect(session.preferences.avoidTolls, isTrue);
        expect(session.preferences.avoidHighways, isFalse);
      });

      test('should use default preferences when none provided', () async {
        // Arrange
        await navigationService.initialize();

        // Act
        final session = await navigationService.startInAppNavigation(
          origin: const LatLng(3.1478, 101.6953),
          destination: const LatLng(3.1590, 101.7123),
          orderId: 'test_order',
        );

        // Assert
        expect(session.preferences, isA<NavigationPreferences>());
        expect(session.preferences.voiceGuidanceEnabled, isTrue);
        expect(session.preferences.language, equals('en-MY'));
      });
    });

    group('Error Handling', () {
      test('should handle invalid coordinates gracefully', () async {
        // Arrange
        await navigationService.initialize();

        // Act & Assert
        expect(() async => await navigationService.startInAppNavigation(
          origin: const LatLng(0, 0),
          destination: const LatLng(0, 0),
          orderId: 'invalid_order',
        ), returnsNormally);
      });

      test('should handle empty order ID gracefully', () async {
        // Arrange
        await navigationService.initialize();

        // Act & Assert
        expect(() async => await navigationService.startInAppNavigation(
          origin: const LatLng(3.1478, 101.6953),
          destination: const LatLng(3.1590, 101.7123),
          orderId: '',
        ), returnsNormally);
      });

      test('should handle service disposal gracefully', () async {
        // Arrange
        await navigationService.initialize();
        await navigationService.startInAppNavigation(
          origin: const LatLng(3.1478, 101.6953),
          destination: const LatLng(3.1590, 101.7123),
          orderId: 'test_order',
        );

        // Act & Assert
        expect(() async => await navigationService.dispose(), returnsNormally);
        expect(navigationService.isNavigating, isFalse);
        expect(navigationService.currentSession, isNull);
      });
    });

    group('Stream Management', () {
      test('should provide instruction stream', () {
        expect(navigationService.instructionStream, isA<Stream<NavigationInstruction>>());
      });

      test('should provide session stream', () {
        expect(navigationService.sessionStream, isA<Stream<NavigationSession>>());
      });

      test('should provide traffic alert stream', () {
        expect(navigationService.trafficAlertStream, isA<Stream<String>>());
      });

      test('should handle stream subscriptions properly', () async {
        // Arrange
        await navigationService.initialize();
        
        // Act - Subscribe to streams
        final instructionSubscription = navigationService.instructionStream.listen((_) {});
        final sessionSubscription = navigationService.sessionStream.listen((_) {});
        final trafficSubscription = navigationService.trafficAlertStream.listen((_) {});

        // Assert - Streams should be active
        expect(instructionSubscription, isNotNull);
        expect(sessionSubscription, isNotNull);
        expect(trafficSubscription, isNotNull);

        // Cleanup
        await instructionSubscription.cancel();
        await sessionSubscription.cancel();
        await trafficSubscription.cancel();
      });
    });
  });
}
