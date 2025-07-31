import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/presentation/screens/in_app_navigation_screen.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/navigation_models.dart';

void main() {
  group('InAppNavigationScreen Basic Tests', () {
    testWidgets('should create InAppNavigationScreen without crashing', (WidgetTester tester) async {
      // Create a minimal navigation session for testing
      final mockRoute = NavigationRoute(
        id: 'test_route',
        polylinePoints: [
          const LatLng(3.1478, 101.6953),
          const LatLng(3.1590, 101.7123),
        ],
        totalDistanceMeters: 1000.0,
        totalDurationSeconds: 120,
        durationInTrafficSeconds: 150,
        instructions: [],
        summary: 'Test route',
        calculatedAt: DateTime.now(),
      );

      final mockSession = NavigationSession(
        id: 'test_session',
        orderId: 'test_order',
        origin: const LatLng(3.1478, 101.6953),
        destination: const LatLng(3.1590, 101.7123),
        destinationName: 'Test Destination',
        route: mockRoute,
        preferences: const NavigationPreferences(),
        startTime: DateTime.now(),
        status: NavigationSessionStatus.active,
      );

      // Test that the widget can be created without throwing
      expect(() {
        InAppNavigationScreen(
          session: mockSession,
          onNavigationComplete: () {},
          onNavigationCancelled: () {},
        );
      }, returnsNormally);
    });

    testWidgets('should have required properties set correctly', (WidgetTester tester) async {
      final mockRoute = NavigationRoute(
        id: 'test_route',
        polylinePoints: [
          const LatLng(3.1478, 101.6953),
          const LatLng(3.1590, 101.7123),
        ],
        totalDistanceMeters: 1000.0,
        totalDurationSeconds: 120,
        durationInTrafficSeconds: 150,
        instructions: [],
        summary: 'Test route',
        calculatedAt: DateTime.now(),
      );

      final mockSession = NavigationSession(
        id: 'test_session_123',
        orderId: 'test_order_456',
        origin: const LatLng(3.1478, 101.6953),
        destination: const LatLng(3.1590, 101.7123),
        destinationName: 'Test Restaurant',
        route: mockRoute,
        preferences: const NavigationPreferences(),
        startTime: DateTime.now(),
        status: NavigationSessionStatus.active,
      );

      bool navigationCompleted = false;
      bool navigationCancelled = false;

      final screen = InAppNavigationScreen(
        session: mockSession,
        onNavigationComplete: () {
          navigationCompleted = true;
        },
        onNavigationCancelled: () {
          navigationCancelled = true;
        },
      );

      // Verify properties are set correctly
      expect(screen.session.id, equals('test_session_123'));
      expect(screen.session.orderId, equals('test_order_456'));
      expect(screen.session.destinationName, equals('Test Restaurant'));
      expect(navigationCompleted, isFalse);
      expect(navigationCancelled, isFalse);

      // Test callbacks can be called
      screen.onNavigationComplete?.call();
      screen.onNavigationCancelled?.call();

      expect(navigationCompleted, isTrue);
      expect(navigationCancelled, isTrue);
    });

    test('NavigationSession should have correct structure', () {
      final mockRoute = NavigationRoute(
        id: 'test_route',
        polylinePoints: [
          const LatLng(3.1478, 101.6953),
          const LatLng(3.1590, 101.7123),
        ],
        totalDistanceMeters: 1500.0,
        totalDurationSeconds: 180,
        durationInTrafficSeconds: 210,
        instructions: [],
        summary: 'Test route summary',
        calculatedAt: DateTime.now(),
      );

      final session = NavigationSession(
        id: 'session_test',
        orderId: 'order_test',
        origin: const LatLng(3.1478, 101.6953),
        destination: const LatLng(3.1590, 101.7123),
        destinationName: 'Test Location',
        route: mockRoute,
        preferences: const NavigationPreferences(
          voiceGuidanceEnabled: true,
          language: 'en-MY',
        ),
        startTime: DateTime.now(),
        status: NavigationSessionStatus.active,
      );

      // Verify session structure
      expect(session.id, equals('session_test'));
      expect(session.orderId, equals('order_test'));
      expect(session.destinationName, equals('Test Location'));
      expect(session.route.totalDistanceMeters, equals(1500.0));
      expect(session.route.totalDurationSeconds, equals(180));
      expect(session.preferences.voiceGuidanceEnabled, isTrue);
      expect(session.preferences.language, equals('en-MY'));
      expect(session.status, equals(NavigationSessionStatus.active));
    });
  });
}
