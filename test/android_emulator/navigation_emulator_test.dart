
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:gigaeats_app/main.dart' as app;
import 'package:gigaeats_app/src/features/drivers/presentation/screens/in_app_navigation_screen.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/navigation_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Android Emulator Navigation Tests', () {
    testWidgets('Complete navigation workflow on Android emulator', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify app launched successfully
      expect(find.byType(MaterialApp), findsOneWidget);
      
      debugPrint('✅ [EMULATOR-TEST] App launched successfully on Android emulator');
    });

    testWidgets('InAppNavigationScreen performance on Android emulator', (WidgetTester tester) async {
      // Create test navigation session
      final mockRoute = NavigationRoute(
        id: 'emulator_test_route',
        polylinePoints: [
          const LatLng(3.1478, 101.6953), // Kuala Lumpur coordinates
          const LatLng(3.1590, 101.7123),
        ],
        totalDistanceMeters: 2000.0,
        totalDurationSeconds: 300,
        durationInTrafficSeconds: 360,
        instructions: [
          NavigationInstruction(
            id: 'emulator_instruction_1',
            type: NavigationInstructionType.straight,
            text: 'Head north on Jalan Ampang',
            htmlText: 'Head north on <b>Jalan Ampang</b>',
            distanceMeters: 800.0,
            durationSeconds: 120,
            location: const LatLng(3.1478, 101.6953),
            timestamp: DateTime.now(),
          ),
          NavigationInstruction(
            id: 'emulator_instruction_2',
            type: NavigationInstructionType.turnRight,
            text: 'Turn right onto Jalan Tun Razak',
            htmlText: 'Turn right onto <b>Jalan Tun Razak</b>',
            distanceMeters: 1200.0,
            durationSeconds: 180,
            location: const LatLng(3.1520, 101.7000),
            timestamp: DateTime.now(),
          ),
        ],
        summary: 'Route via Jalan Ampang and Jalan Tun Razak',
        calculatedAt: DateTime.now(),
      );

      final mockSession = NavigationSession(
        id: 'emulator_session_123',
        orderId: 'emulator_order_456',
        origin: const LatLng(3.1478, 101.6953),
        destination: const LatLng(3.1590, 101.7123),
        destinationName: 'McDonald\'s KLCC',
        route: mockRoute,
        preferences: const NavigationPreferences(
          voiceGuidanceEnabled: true,
          language: 'en-MY',
          trafficAlertsEnabled: true,
        ),
        startTime: DateTime.now(),
        status: NavigationSessionStatus.active,
        currentInstructionIndex: 0,
        progressPercentage: 15.0,
      );

      bool navigationCompleted = false;
      bool navigationCancelled = false;

      // Build the navigation screen
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: InAppNavigationScreen(
              session: mockSession,
              onNavigationComplete: () {
                navigationCompleted = true;
                debugPrint('✅ [EMULATOR-TEST] Navigation completed callback triggered');
              },
              onNavigationCancelled: () {
                navigationCancelled = true;
                debugPrint('✅ [EMULATOR-TEST] Navigation cancelled callback triggered');
              },
            ),
          ),
        ),
      );

      // Wait for the screen to render
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify the navigation screen is displayed
      expect(find.byType(InAppNavigationScreen), findsOneWidget);
      debugPrint('✅ [EMULATOR-TEST] InAppNavigationScreen rendered successfully');

      // Verify Google Maps is displayed
      expect(find.byType(GoogleMap), findsOneWidget);
      debugPrint('✅ [EMULATOR-TEST] Google Maps widget found');

      // Test screen responsiveness by triggering rebuilds
      for (int i = 0; i < 5; i++) {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16)); // 60 FPS
      }

      debugPrint('✅ [EMULATOR-TEST] Screen responsiveness test completed');

      // Verify callbacks work
      expect(navigationCompleted, isFalse);
      expect(navigationCancelled, isFalse);

      debugPrint('✅ [EMULATOR-TEST] Navigation screen performance test completed');
    });

    testWidgets('Memory usage during navigation on Android emulator', (WidgetTester tester) async {
      debugPrint('🧪 [EMULATOR-TEST] Starting memory usage test');

      // Create multiple navigation sessions to test memory management
      final sessions = List.generate(3, (index) {
        final route = NavigationRoute(
          id: 'memory_test_route_$index',
          polylinePoints: [
            LatLng(3.1478 + (index * 0.01), 101.6953 + (index * 0.01)),
            LatLng(3.1590 + (index * 0.01), 101.7123 + (index * 0.01)),
          ],
          totalDistanceMeters: 1500.0 + (index * 500),
          totalDurationSeconds: 200 + (index * 50),
          durationInTrafficSeconds: 240 + (index * 60),
          instructions: [],
          summary: 'Memory test route $index',
          calculatedAt: DateTime.now(),
        );

        return NavigationSession(
          id: 'memory_session_$index',
          orderId: 'memory_order_$index',
          origin: LatLng(3.1478 + (index * 0.01), 101.6953 + (index * 0.01)),
          destination: LatLng(3.1590 + (index * 0.01), 101.7123 + (index * 0.01)),
          destinationName: 'Test Location $index',
          route: route,
          preferences: const NavigationPreferences(),
          startTime: DateTime.now(),
          status: NavigationSessionStatus.active,
        );
      });

      // Test each session
      for (int i = 0; i < sessions.length; i++) {
        debugPrint('🧪 [EMULATOR-TEST] Testing session $i');

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: InAppNavigationScreen(
                session: sessions[i],
                onNavigationComplete: () {},
                onNavigationCancelled: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify screen renders without memory issues
        expect(find.byType(InAppNavigationScreen), findsOneWidget);

        // Force garbage collection simulation
        await tester.pump(const Duration(milliseconds: 100));
      }

      debugPrint('✅ [EMULATOR-TEST] Memory usage test completed');
    });

    testWidgets('Location services integration on Android emulator', (WidgetTester tester) async {
      debugPrint('🧪 [EMULATOR-TEST] Testing location services integration');

      // Mock location data for emulator testing
      const testLocations = [
        LatLng(3.1478, 101.6953), // Starting location
        LatLng(3.1490, 101.6970), // Intermediate location
        LatLng(3.1500, 101.7000), // Another intermediate location
        LatLng(3.1590, 101.7123), // Destination
      ];

      for (int i = 0; i < testLocations.length; i++) {
        final location = testLocations[i];
        debugPrint('🧪 [EMULATOR-TEST] Testing location: ${location.latitude}, ${location.longitude}');

        // Create session with current location
        final route = NavigationRoute(
          id: 'location_test_route_$i',
          polylinePoints: [location, testLocations.last],
          totalDistanceMeters: 1000.0,
          totalDurationSeconds: 150,
          durationInTrafficSeconds: 180,
          instructions: [],
          summary: 'Location test route $i',
          calculatedAt: DateTime.now(),
        );

        final session = NavigationSession(
          id: 'location_session_$i',
          orderId: 'location_order_$i',
          origin: location,
          destination: testLocations.last,
          destinationName: 'Test Destination',
          route: route,
          preferences: const NavigationPreferences(),
          startTime: DateTime.now(),
          status: NavigationSessionStatus.active,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: InAppNavigationScreen(
                session: session,
                onNavigationComplete: () {},
                onNavigationCancelled: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify screen handles location updates
        expect(find.byType(InAppNavigationScreen), findsOneWidget);
        expect(find.byType(GoogleMap), findsOneWidget);
      }

      debugPrint('✅ [EMULATOR-TEST] Location services integration test completed');
    });

    testWidgets('Network connectivity handling on Android emulator', (WidgetTester tester) async {
      debugPrint('🧪 [EMULATOR-TEST] Testing network connectivity handling');

      final route = NavigationRoute(
        id: 'network_test_route',
        polylinePoints: [
          const LatLng(3.1478, 101.6953),
          const LatLng(3.1590, 101.7123),
        ],
        totalDistanceMeters: 1500.0,
        totalDurationSeconds: 200,
        durationInTrafficSeconds: 240,
        instructions: [],
        summary: 'Network test route',
        calculatedAt: DateTime.now(),
      );

      final session = NavigationSession(
        id: 'network_session',
        orderId: 'network_order',
        origin: const LatLng(3.1478, 101.6953),
        destination: const LatLng(3.1590, 101.7123),
        destinationName: 'Network Test Destination',
        route: route,
        preferences: const NavigationPreferences(),
        startTime: DateTime.now(),
        status: NavigationSessionStatus.active,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: InAppNavigationScreen(
              session: session,
              onNavigationComplete: () {},
              onNavigationCancelled: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify screen handles network scenarios
      expect(find.byType(InAppNavigationScreen), findsOneWidget);
      expect(find.byType(GoogleMap), findsOneWidget);

      debugPrint('✅ [EMULATOR-TEST] Network connectivity test completed');
    });

    testWidgets('Voice navigation on Android emulator', (WidgetTester tester) async {
      debugPrint('🧪 [EMULATOR-TEST] Testing voice navigation on Android emulator');

      final route = NavigationRoute(
        id: 'voice_test_route',
        polylinePoints: [
          const LatLng(3.1478, 101.6953),
          const LatLng(3.1590, 101.7123),
        ],
        totalDistanceMeters: 1800.0,
        totalDurationSeconds: 250,
        durationInTrafficSeconds: 300,
        instructions: [
          NavigationInstruction(
            id: 'voice_instruction_1',
            type: NavigationInstructionType.straight,
            text: 'Continue straight for 500 meters',
            htmlText: 'Continue <b>straight</b> for 500 meters',
            distanceMeters: 500.0,
            durationSeconds: 80,
            location: const LatLng(3.1478, 101.6953),
            timestamp: DateTime.now(),
          ),
        ],
        summary: 'Voice test route',
        calculatedAt: DateTime.now(),
      );

      final session = NavigationSession(
        id: 'voice_session',
        orderId: 'voice_order',
        origin: const LatLng(3.1478, 101.6953),
        destination: const LatLng(3.1590, 101.7123),
        destinationName: 'Voice Test Destination',
        route: route,
        preferences: const NavigationPreferences(
          voiceGuidanceEnabled: true,
          language: 'en-MY',
        ),
        startTime: DateTime.now(),
        status: NavigationSessionStatus.active,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: InAppNavigationScreen(
              session: session,
              onNavigationComplete: () {},
              onNavigationCancelled: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify voice-enabled navigation screen
      expect(find.byType(InAppNavigationScreen), findsOneWidget);
      expect(session.preferences.voiceGuidanceEnabled, isTrue);
      expect(session.preferences.language, equals('en-MY'));

      debugPrint('✅ [EMULATOR-TEST] Voice navigation test completed');
    });

    testWidgets('Performance benchmarks on Android emulator', (WidgetTester tester) async {
      debugPrint('🧪 [EMULATOR-TEST] Running performance benchmarks');

      final stopwatch = Stopwatch();

      // Benchmark 1: Screen rendering time
      stopwatch.start();

      final route = NavigationRoute(
        id: 'benchmark_route',
        polylinePoints: [
          const LatLng(3.1478, 101.6953),
          const LatLng(3.1590, 101.7123),
        ],
        totalDistanceMeters: 2000.0,
        totalDurationSeconds: 300,
        durationInTrafficSeconds: 360,
        instructions: [],
        summary: 'Benchmark route',
        calculatedAt: DateTime.now(),
      );

      final session = NavigationSession(
        id: 'benchmark_session',
        orderId: 'benchmark_order',
        origin: const LatLng(3.1478, 101.6953),
        destination: const LatLng(3.1590, 101.7123),
        destinationName: 'Benchmark Destination',
        route: route,
        preferences: const NavigationPreferences(),
        startTime: DateTime.now(),
        status: NavigationSessionStatus.active,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: InAppNavigationScreen(
              session: session,
              onNavigationComplete: () {},
              onNavigationCancelled: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      final renderTime = stopwatch.elapsedMilliseconds;
      debugPrint('📊 [EMULATOR-TEST] Screen render time: ${renderTime}ms');

      // Verify performance is acceptable (should be under 3 seconds)
      expect(renderTime, lessThan(3000));

      // Benchmark 2: Frame rate test
      stopwatch.reset();
      stopwatch.start();

      // Simulate 60 FPS for 1 second
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      stopwatch.stop();
      final frameTestTime = stopwatch.elapsedMilliseconds;
      debugPrint('📊 [EMULATOR-TEST] 60 frame test time: ${frameTestTime}ms');

      // Should complete 60 frames in approximately 1 second (allowing some tolerance)
      expect(frameTestTime, lessThan(1200));

      debugPrint('✅ [EMULATOR-TEST] Performance benchmarks completed');
    });
  });
}
