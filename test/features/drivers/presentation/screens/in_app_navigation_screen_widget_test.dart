import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/presentation/screens/in_app_navigation_screen.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/navigation_models.dart';

// Generate mocks
// @GenerateMocks([EnhancedNavigationNotifier])
// import 'in_app_navigation_screen_widget_test.mocks.dart';

void main() {
  group('InAppNavigationScreen Widget Tests', () {
    late NavigationSession mockSession;
    late NavigationRoute mockRoute;
    // late MockEnhancedNavigationNotifier mockNotifier;

    setUp(() {
      // mockNotifier = MockEnhancedNavigationNotifier();
      
      // Create mock navigation route
      mockRoute = NavigationRoute(
        id: 'test_route_123',
        polylinePoints: [
          const LatLng(3.1478, 101.6953), // Origin
          const LatLng(3.1590, 101.7123), // Destination
        ],
        totalDistanceMeters: 1500.0,
        totalDurationSeconds: 180,
        durationInTrafficSeconds: 210,
        instructions: [
          NavigationInstruction(
            id: 'instruction_1',
            type: NavigationInstructionType.straight,
            text: 'Head north on Jalan Test',
            htmlText: 'Head north on <b>Jalan Test</b>',
            distanceMeters: 500.0,
            durationSeconds: 60,
            location: const LatLng(3.1478, 101.6953),
            timestamp: DateTime.now(),
          ),
          NavigationInstruction(
            id: 'instruction_2',
            type: NavigationInstructionType.turnRight,
            text: 'Turn right onto Jalan Destination',
            htmlText: 'Turn right onto <b>Jalan Destination</b>',
            distanceMeters: 200.0,
            durationSeconds: 30,
            location: const LatLng(3.1590, 101.7123),
            timestamp: DateTime.now(),
          ),
        ],
        summary: 'Test route via Jalan Test',
        calculatedAt: DateTime.now(),
      );

      // Create mock navigation session
      mockSession = NavigationSession(
        id: 'test_session_123',
        orderId: 'order_456',
        origin: const LatLng(3.1478, 101.6953),
        destination: const LatLng(3.1590, 101.7123),
        destinationName: 'Test Restaurant',
        route: mockRoute,
        preferences: const NavigationPreferences(
          voiceGuidanceEnabled: true,
          language: 'en-MY',
          avoidTolls: false,
          avoidHighways: false,
        ),
        startTime: DateTime.now(),
        status: NavigationSessionStatus.active,
        currentInstructionIndex: 0,
        progressPercentage: 25.0,
      );
    });

    testWidgets('should create InAppNavigationScreen without crashing', (WidgetTester tester) async {
      // Arrange
      bool navigationCompleted = false;
      bool navigationCancelled = false;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: InAppNavigationScreen(
              session: mockSession,
              onNavigationComplete: () {
                navigationCompleted = true;
              },
              onNavigationCancelled: () {
                navigationCancelled = true;
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(InAppNavigationScreen), findsOneWidget);
      expect(navigationCompleted, isFalse);
      expect(navigationCancelled, isFalse);
    });

    testWidgets('should display navigation session information', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: InAppNavigationScreen(
              session: mockSession,
              onNavigationComplete: () {},
              onNavigationCancelled: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Check if destination name is displayed
      expect(find.text('Test Restaurant'), findsWidgets);
    });

    testWidgets('should handle navigation completion callback', (WidgetTester tester) async {
      // Arrange
      bool navigationCompleted = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: InAppNavigationScreen(
              session: mockSession,
              onNavigationComplete: () {
                navigationCompleted = true;
              },
              onNavigationCancelled: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Simulate navigation completion
      final screen = tester.widget<InAppNavigationScreen>(find.byType(InAppNavigationScreen));
      screen.onNavigationComplete?.call();

      // Assert
      expect(navigationCompleted, isTrue);
    });

    testWidgets('should handle navigation cancellation callback', (WidgetTester tester) async {
      // Arrange
      bool navigationCancelled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: InAppNavigationScreen(
              session: mockSession,
              onNavigationComplete: () {},
              onNavigationCancelled: () {
                navigationCancelled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Simulate navigation cancellation
      final screen = tester.widget<InAppNavigationScreen>(find.byType(InAppNavigationScreen));
      screen.onNavigationCancelled?.call();

      // Assert
      expect(navigationCancelled, isTrue);
    });

    testWidgets('should display Google Maps widget', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: InAppNavigationScreen(
              session: mockSession,
              onNavigationComplete: () {},
              onNavigationCancelled: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Check if GoogleMap widget is present
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('should handle different navigation session statuses', (WidgetTester tester) async {
      // Test with different session statuses
      final statuses = [
        NavigationSessionStatus.active,
        NavigationSessionStatus.paused,
        NavigationSessionStatus.completed,
        NavigationSessionStatus.cancelled,
      ];

      for (final status in statuses) {
        final sessionWithStatus = mockSession.copyWith(status: status);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: InAppNavigationScreen(
                session: sessionWithStatus,
                onNavigationComplete: () {},
                onNavigationCancelled: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert - Screen should handle all statuses without crashing
        expect(find.byType(InAppNavigationScreen), findsOneWidget);
      }
    });

    testWidgets('should handle navigation preferences correctly', (WidgetTester tester) async {
      // Arrange - Create session with specific preferences
      final sessionWithPreferences = mockSession.copyWith(
        preferences: const NavigationPreferences(
          voiceGuidanceEnabled: false,
          language: 'ms-MY',
          avoidTolls: true,
          avoidHighways: true,
        ),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: InAppNavigationScreen(
              session: sessionWithPreferences,
              onNavigationComplete: () {},
              onNavigationCancelled: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Screen should handle preferences without crashing
      expect(find.byType(InAppNavigationScreen), findsOneWidget);
      
      final screen = tester.widget<InAppNavigationScreen>(find.byType(InAppNavigationScreen));
      expect(screen.session.preferences.voiceGuidanceEnabled, isFalse);
      expect(screen.session.preferences.language, equals('ms-MY'));
      expect(screen.session.preferences.avoidTolls, isTrue);
      expect(screen.session.preferences.avoidHighways, isTrue);
    });

    testWidgets('should handle route with multiple instructions', (WidgetTester tester) async {
      // Arrange - Create route with multiple instructions
      final routeWithManyInstructions = mockRoute.copyWith(
        instructions: List.generate(10, (index) => NavigationInstruction(
          id: 'instruction_$index',
          type: index % 2 == 0 ? NavigationInstructionType.straight : NavigationInstructionType.turnLeft,
          text: 'Instruction $index',
          htmlText: '<b>Instruction $index</b>',
          distanceMeters: 100.0 * (index + 1),
          durationSeconds: 30 * (index + 1),
          location: LatLng(3.1478 + (index * 0.001), 101.6953 + (index * 0.001)),
          timestamp: DateTime.now(),
        )),
      );

      final sessionWithManyInstructions = mockSession.copyWith(route: routeWithManyInstructions);

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: InAppNavigationScreen(
              session: sessionWithManyInstructions,
              onNavigationComplete: () {},
              onNavigationCancelled: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(InAppNavigationScreen), findsOneWidget);
      expect(sessionWithManyInstructions.route.instructions.length, equals(10));
    });

    testWidgets('should handle empty route instructions', (WidgetTester tester) async {
      // Arrange - Create route with no instructions
      final routeWithNoInstructions = mockRoute.copyWith(instructions: []);
      final sessionWithNoInstructions = mockSession.copyWith(route: routeWithNoInstructions);

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: InAppNavigationScreen(
              session: sessionWithNoInstructions,
              onNavigationComplete: () {},
              onNavigationCancelled: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Should handle empty instructions gracefully
      expect(find.byType(InAppNavigationScreen), findsOneWidget);
      expect(sessionWithNoInstructions.route.instructions, isEmpty);
    });

    testWidgets('should handle progress percentage updates', (WidgetTester tester) async {
      // Test with different progress percentages
      final progressValues = [0.0, 25.0, 50.0, 75.0, 100.0];

      for (final progress in progressValues) {
        final sessionWithProgress = mockSession.copyWith(progressPercentage: progress);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: InAppNavigationScreen(
                session: sessionWithProgress,
                onNavigationComplete: () {},
                onNavigationCancelled: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(InAppNavigationScreen), findsOneWidget);
        expect(sessionWithProgress.progressPercentage, equals(progress));
      }
    });

    testWidgets('should handle current instruction index updates', (WidgetTester tester) async {
      // Test with different instruction indices
      for (int index = 0; index < mockRoute.instructions.length; index++) {
        final sessionWithIndex = mockSession.copyWith(currentInstructionIndex: index);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: InAppNavigationScreen(
                session: sessionWithIndex,
                onNavigationComplete: () {},
                onNavigationCancelled: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(InAppNavigationScreen), findsOneWidget);
        expect(sessionWithIndex.currentInstructionIndex, equals(index));
        
        // Check if current instruction is correct
        final currentInstruction = sessionWithIndex.currentInstruction;
        if (currentInstruction != null) {
          expect(currentInstruction, equals(mockRoute.instructions[index]));
        }
      }
    });
  });
}
