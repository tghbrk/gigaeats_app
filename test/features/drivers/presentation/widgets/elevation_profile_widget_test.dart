import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/presentation/widgets/elevation_profile_widget.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/enhanced_route_service.dart';

void main() {
  group('ElevationProfileWidget Tests', () {
    late List<ElevationPoint> mockElevationProfile;

    setUp(() {
      mockElevationProfile = [
        const ElevationPoint(
          distance: 0.0,
          elevation: 100.0,
          location: LatLng(3.1390, 101.6869),
        ),
        const ElevationPoint(
          distance: 0.5,
          elevation: 120.0,
          location: LatLng(3.1395, 101.6875),
        ),
        const ElevationPoint(
          distance: 1.0,
          elevation: 150.0,
          location: LatLng(3.1400, 101.6880),
        ),
        const ElevationPoint(
          distance: 1.5,
          elevation: 130.0,
          location: LatLng(3.1405, 101.6885),
        ),
        const ElevationPoint(
          distance: 2.0,
          elevation: 110.0,
          location: LatLng(3.1410, 101.6890),
        ),
      ];
    });

    Widget createTestWidget({
      List<ElevationPoint>? elevationProfile,
      double height = 150,
      bool showGrid = true,
      bool showTooltips = true,
      Color? lineColor,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ElevationProfileWidget(
            elevationProfile: elevationProfile ?? mockElevationProfile,
            height: height,
            showGrid: showGrid,
            showTooltips: showTooltips,
            lineColor: lineColor,
          ),
        ),
      );
    }

    testWidgets('displays elevation profile header', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Elevation Profile'), findsOneWidget);
      expect(find.text('Route elevation changes'), findsOneWidget);
      expect(find.byIcon(Icons.terrain), findsOneWidget);
    });

    testWidgets('displays elevation statistics', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for elevation statistics
      expect(find.text('Highest'), findsOneWidget);
      expect(find.text('Lowest'), findsOneWidget);
      expect(find.text('Gain'), findsOneWidget);

      // Check calculated values
      expect(find.text('150m'), findsOneWidget); // Highest elevation
      expect(find.text('100m'), findsOneWidget); // Lowest elevation
      expect(find.text('50m'), findsOneWidget);  // Elevation gain (150-100)
    });

    testWidgets('displays line chart', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify LineChart is present
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('shows nothing when elevation profile is empty', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(elevationProfile: []));

      // Should show nothing (SizedBox.shrink)
      expect(find.byType(Card), findsNothing);
      expect(find.text('Elevation Profile'), findsNothing);
    });

    testWidgets('respects custom height parameter', (WidgetTester tester) async {
      const customHeight = 200.0;
      await tester.pumpWidget(createTestWidget(height: customHeight));

      // Find the SizedBox that contains the chart
      final sizedBoxFinder = find.descendant(
        of: find.byType(LineChart),
        matching: find.byType(SizedBox),
      );

      expect(sizedBoxFinder, findsAtLeastNWidgets(1));
    });

    testWidgets('displays correct elevation statistics icons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);   // Highest
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget); // Lowest
      expect(find.byIcon(Icons.trending_up), findsOneWidget);         // Gain
    });

    testWidgets('calculates elevation statistics correctly', (WidgetTester tester) async {
      // Create a specific elevation profile for testing
      final testProfile = [
        const ElevationPoint(distance: 0.0, elevation: 50.0, location: LatLng(0, 0)),
        const ElevationPoint(distance: 1.0, elevation: 200.0, location: LatLng(0, 0)),
        const ElevationPoint(distance: 2.0, elevation: 75.0, location: LatLng(0, 0)),
      ];

      await tester.pumpWidget(createTestWidget(elevationProfile: testProfile));

      // Verify calculated statistics
      expect(find.text('200m'), findsOneWidget); // Highest (200)
      expect(find.text('50m'), findsOneWidget);  // Lowest (50)
      expect(find.text('150m'), findsOneWidget); // Gain (200-50)
    });

    testWidgets('handles single elevation point', (WidgetTester tester) async {
      final singlePointProfile = [
        const ElevationPoint(distance: 0.0, elevation: 100.0, location: LatLng(0, 0)),
      ];

      await tester.pumpWidget(createTestWidget(elevationProfile: singlePointProfile));

      // Should still display the widget
      expect(find.text('Elevation Profile'), findsOneWidget);
      expect(find.text('100m'), findsAtLeastNWidgets(2)); // Both highest and lowest
      expect(find.text('0m'), findsOneWidget); // Gain should be 0
    });

    testWidgets('displays terrain icon in header', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find the terrain icon in the header
      final headerContainer = find.descendant(
        of: find.byType(Card),
        matching: find.byIcon(Icons.terrain),
      );

      expect(headerContainer, findsOneWidget);
    });

    testWidgets('shows elevation statistics in correct format', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify the statistics are displayed with proper formatting
      final highestFinder = find.ancestor(
        of: find.text('Highest'),
        matching: find.byType(Column),
      );
      
      final lowestFinder = find.ancestor(
        of: find.text('Lowest'),
        matching: find.byType(Column),
      );
      
      final gainFinder = find.ancestor(
        of: find.text('Gain'),
        matching: find.byType(Column),
      );

      expect(highestFinder, findsOneWidget);
      expect(lowestFinder, findsOneWidget);
      expect(gainFinder, findsOneWidget);
    });

    testWidgets('handles zero elevation gain correctly', (WidgetTester tester) async {
      final flatProfile = [
        const ElevationPoint(distance: 0.0, elevation: 100.0, location: LatLng(0, 0)),
        const ElevationPoint(distance: 1.0, elevation: 100.0, location: LatLng(0, 0)),
        const ElevationPoint(distance: 2.0, elevation: 100.0, location: LatLng(0, 0)),
      ];

      await tester.pumpWidget(createTestWidget(elevationProfile: flatProfile));

      expect(find.text('100m'), findsAtLeastNWidgets(2)); // Highest and lowest
      expect(find.text('0m'), findsOneWidget); // Gain should be 0
    });

    testWidgets('displays statistics container with proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find the statistics container
      final statsContainer = find.descendant(
        of: find.byType(Card),
        matching: find.byType(Container),
      );

      expect(statsContainer, findsAtLeastNWidgets(1));
    });
  });

  group('ElevationProfileWidget Edge Cases', () {
    testWidgets('handles negative elevations', (WidgetTester tester) async {
      final negativeElevationProfile = [
        const ElevationPoint(distance: 0.0, elevation: -10.0, location: LatLng(0, 0)),
        const ElevationPoint(distance: 1.0, elevation: 50.0, location: LatLng(0, 0)),
        const ElevationPoint(distance: 2.0, elevation: -5.0, location: LatLng(0, 0)),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ElevationProfileWidget(
            elevationProfile: negativeElevationProfile,
          ),
        ),
      ));

      expect(find.text('50m'), findsOneWidget);  // Highest
      expect(find.text('-10m'), findsOneWidget); // Lowest (negative)
      expect(find.text('60m'), findsOneWidget);  // Gain (50 - (-10))
    });

    testWidgets('handles very large elevation differences', (WidgetTester tester) async {
      final largeElevationProfile = [
        const ElevationPoint(distance: 0.0, elevation: 0.0, location: LatLng(0, 0)),
        const ElevationPoint(distance: 1.0, elevation: 5000.0, location: LatLng(0, 0)),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ElevationProfileWidget(
            elevationProfile: largeElevationProfile,
          ),
        ),
      ));

      expect(find.text('5000m'), findsOneWidget); // Highest
      expect(find.text('0m'), findsOneWidget);    // Lowest
      expect(find.text('5000m'), findsAtLeastNWidgets(1)); // Gain
    });
  });
}
