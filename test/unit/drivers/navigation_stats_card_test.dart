import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gigaeats_app/src/features/drivers/presentation/widgets/navigation_stats_card.dart';

void main() {
  group('NavigationStatsCard Widget Tests', () {
    testWidgets('should display navigation stats correctly', (WidgetTester tester) async {
      // Arrange
      final currentSpeed = 45.0; // km/h
      final eta = DateTime.now().add(const Duration(minutes: 15));
      final remainingDistance = 2500.0; // meters

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationStatsCard(
              currentSpeed: currentSpeed,
              eta: eta,
              remainingDistance: remainingDistance,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Navigation Stats'), findsOneWidget);
      expect(find.text('45'), findsOneWidget); // Speed value
      expect(find.text('km/h'), findsOneWidget); // Speed unit
      expect(find.text('2.5km'), findsOneWidget); // Distance
      // Check for ETA text more flexibly (time may vary slightly)
      expect(find.textContaining('min'), findsAtLeastNWidgets(1)); // ETA should contain 'min'
    });

    testWidgets('should display compact layout correctly', (WidgetTester tester) async {
      // Arrange
      final currentSpeed = 30.0;
      final eta = DateTime.now().add(const Duration(minutes: 8));
      final remainingDistance = 800.0;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationStatsCard(
              currentSpeed: currentSpeed,
              eta: eta,
              remainingDistance: remainingDistance,
              compact: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('30'), findsOneWidget); // Speed value
      expect(find.text('800m'), findsOneWidget); // Distance in meters
      expect(find.textContaining('min'), findsAtLeastNWidgets(1)); // ETA should contain 'min'
    });

    testWidgets('should handle null values gracefully', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationStatsCard(
              currentSpeed: null,
              eta: null,
              remainingDistance: null,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('--'), findsAtLeastNWidgets(3)); // All values should show '--'
    });

    testWidgets('should show speed limit warning when enabled', (WidgetTester tester) async {
      // Arrange
      final currentSpeed = 75.0; // Above speed limit
      final speedLimit = 60.0;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationStatsCard(
              currentSpeed: currentSpeed,
              eta: DateTime.now().add(const Duration(minutes: 10)),
              remainingDistance: 1000.0,
              showSpeedLimit: true,
              speedLimit: speedLimit,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Speed limit: 60 km/h'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('should handle tap callback', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      void onTap() {
        tapped = true;
      }

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationStatsCard(
              currentSpeed: 50.0,
              eta: DateTime.now().add(const Duration(minutes: 5)),
              remainingDistance: 500.0,
              onTap: onTap,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(NavigationStatsCard));
      await tester.pump();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('should format ETA correctly for different durations', (WidgetTester tester) async {
      // Test cases for different ETA formats
      final testCases = [
        {
          'duration': Duration(seconds: 30),
          'expectedPattern': 'Now',
        },
        {
          'duration': Duration(minutes: 45),
          'expectedPattern': 'min', // Should contain 'min' for minutes
        },
        {
          'duration': Duration(hours: 1, minutes: 30),
          'expectedPattern': 'h', // Should contain 'h' for hours
        },
        {
          'duration': Duration(hours: 2, minutes: 5),
          'expectedPattern': 'h', // Should contain 'h' for hours
        },
      ];

      for (final testCase in testCases) {
        final eta = DateTime.now().add(testCase['duration'] as Duration);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NavigationStatsCard(
                currentSpeed: 50.0,
                eta: eta,
                remainingDistance: 1000.0,
                compact: true,
              ),
            ),
          ),
        );

        final pattern = testCase['expectedPattern'] as String;
        if (pattern == 'Now') {
          expect(find.text('Now'), findsOneWidget);
        } else {
          expect(find.textContaining(pattern), findsAtLeastNWidgets(1));
        }
      }
    });

    testWidgets('should format distance correctly for different values', (WidgetTester tester) async {
      // Test cases for different distance formats
      final testCases = [
        {
          'distance': 150.0,
          'expected': '150m',
        },
        {
          'distance': 999.0,
          'expected': '999m',
        },
        {
          'distance': 1000.0,
          'expected': '1.0km',
        },
        {
          'distance': 2500.0,
          'expected': '2.5km',
        },
        {
          'distance': 15750.0,
          'expected': '15.8km',
        },
      ];

      for (final testCase in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NavigationStatsCard(
                currentSpeed: 50.0,
                eta: DateTime.now().add(const Duration(minutes: 10)),
                remainingDistance: testCase['distance'] as double,
                compact: true,
              ),
            ),
          ),
        );

        expect(find.text(testCase['expected'] as String), findsOneWidget);
      }
    });

    group('Speed Warning Logic', () {
      testWidgets('should not show warning when speed is within limit', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NavigationStatsCard(
                currentSpeed: 55.0, // Within tolerance
                eta: DateTime.now().add(const Duration(minutes: 10)),
                remainingDistance: 1000.0,
                showSpeedLimit: true,
                speedLimit: 60.0,
              ),
            ),
          ),
        );

        expect(find.text('Speed limit: 60 km/h'), findsNothing);
      });

      testWidgets('should show warning when speed exceeds limit by tolerance', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NavigationStatsCard(
                currentSpeed: 70.0, // Exceeds 60 + 5 tolerance
                eta: DateTime.now().add(const Duration(minutes: 10)),
                remainingDistance: 1000.0,
                showSpeedLimit: true,
                speedLimit: 60.0,
              ),
            ),
          ),
        );

        expect(find.text('Speed limit: 60 km/h'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);
      });
    });
  });
}
