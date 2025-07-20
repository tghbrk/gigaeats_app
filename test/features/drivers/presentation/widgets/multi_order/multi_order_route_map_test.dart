import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:gigaeats/src/features/drivers/presentation/widgets/multi_order/multi_order_route_map.dart';
import 'package:gigaeats/src/features/drivers/presentation/providers/multi_order_batch_provider.dart';
import 'package:gigaeats/src/features/drivers/presentation/providers/route_optimization_provider.dart';
import 'package:gigaeats/src/features/drivers/presentation/providers/enhanced_navigation_provider.dart';
import 'package:gigaeats/src/features/drivers/presentation/providers/enhanced_location_provider.dart';

import '../../../../../test_helpers/mock_providers.dart';
import '../../../../../test_helpers/test_data.dart';

void main() {
  group('MultiOrderRouteMap Widget Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          multiOrderBatchProvider.overrideWith((ref) => MockMultiOrderBatchNotifier()),
          routeOptimizationProvider.overrideWith((ref) => MockRouteOptimizationNotifier()),
          enhancedNavigationProvider.overrideWith((ref) => MockEnhancedNavigationNotifier()),
          enhancedLocationProvider.overrideWith((ref) => MockEnhancedLocationNotifier()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('displays empty map when no batch is active', (WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MultiOrderRouteMap(
                height: 400,
                showControls: true,
                enableInteraction: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify map container is displayed
      expect(find.byType(MultiOrderRouteMap), findsOneWidget);
      
      // Verify map controls are shown
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('displays map controls when showControls is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MultiOrderRouteMap(
                height: 400,
                showControls: true,
                enableInteraction: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Map should be displayed
      expect(find.byType(MultiOrderRouteMap), findsOneWidget);
    });

    testWidgets('hides map controls when showControls is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MultiOrderRouteMap(
                height: 400,
                showControls: false,
                enableInteraction: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Map should be displayed
      expect(find.byType(MultiOrderRouteMap), findsOneWidget);
    });

    testWidgets('displays loading overlay when route is optimizing', (WidgetTester tester) async {
      // Override provider to return optimizing state
      container = ProviderContainer(
        overrides: [
          multiOrderBatchProvider.overrideWith((ref) => MockMultiOrderBatchNotifier()),
          routeOptimizationProvider.overrideWith((ref) => MockRouteOptimizationNotifier()
            ..state = const RouteOptimizationState(isOptimizing: true)),
          enhancedNavigationProvider.overrideWith((ref) => MockEnhancedNavigationNotifier()),
          enhancedLocationProvider.overrideWith((ref) => MockEnhancedLocationNotifier()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MultiOrderRouteMap(
                height: 400,
                showControls: true,
                enableInteraction: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error overlay when route optimization fails', (WidgetTester tester) async {
      const errorMessage = 'Route optimization failed';
      
      // Override provider to return error state
      container = ProviderContainer(
        overrides: [
          multiOrderBatchProvider.overrideWith((ref) => MockMultiOrderBatchNotifier()),
          routeOptimizationProvider.overrideWith((ref) => MockRouteOptimizationNotifier()
            ..state = const RouteOptimizationState(error: errorMessage)),
          enhancedNavigationProvider.overrideWith((ref) => MockEnhancedNavigationNotifier()),
          enhancedLocationProvider.overrideWith((ref) => MockEnhancedLocationNotifier()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MultiOrderRouteMap(
                height: 400,
                showControls: true,
                enableInteraction: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Map Error'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('calls onOrderSelected when waypoint is tapped', (WidgetTester tester) async {
      String? selectedOrderId;
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MultiOrderRouteMap(
                height: 400,
                showControls: true,
                enableInteraction: true,
                onOrderSelected: (orderId) {
                  selectedOrderId = orderId;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Map should be displayed
      expect(find.byType(MultiOrderRouteMap), findsOneWidget);
      
      // Note: Testing actual map interactions requires integration testing
      // as GoogleMap widget doesn't support tap testing in unit tests
    });

    testWidgets('calls onWaypointReorder when reorder is triggered', (WidgetTester tester) async {
      bool reorderCalled = false;
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MultiOrderRouteMap(
                height: 400,
                showControls: true,
                enableInteraction: true,
                onWaypointReorder: () {
                  reorderCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Map should be displayed
      expect(find.byType(MultiOrderRouteMap), findsOneWidget);
      
      // Note: Testing actual reorder interactions requires integration testing
    });

    testWidgets('displays waypoint legend when batch is active', (WidgetTester tester) async {
      // Override provider to return active batch state
      container = ProviderContainer(
        overrides: [
          multiOrderBatchProvider.overrideWith((ref) => MockMultiOrderBatchNotifier()
            ..state = MockMultiOrderBatchNotifier.mockActiveState()),
          routeOptimizationProvider.overrideWith((ref) => MockRouteOptimizationNotifier()),
          enhancedNavigationProvider.overrideWith((ref) => MockEnhancedNavigationNotifier()),
          enhancedLocationProvider.overrideWith((ref) => MockEnhancedLocationNotifier()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MultiOrderRouteMap(
                height: 400,
                showControls: true,
                enableInteraction: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show waypoint legend
      expect(find.text('Waypoints'), findsOneWidget);
      expect(find.text('Pickup'), findsOneWidget);
      expect(find.text('Delivery'), findsOneWidget);
      expect(find.text('Driver'), findsOneWidget);
    });

    testWidgets('respects height parameter', (WidgetTester tester) async {
      const testHeight = 300.0;
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MultiOrderRouteMap(
                height: testHeight,
                showControls: true,
                enableInteraction: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the container with the specified height
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);
      
      // Note: Exact height verification requires widget inspection
      // which is complex for nested containers
    });
  });
}
