import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:gigaeats/src/features/drivers/presentation/screens/multi_order_driver_dashboard.dart';
import 'package:gigaeats/src/features/drivers/presentation/providers/multi_order_batch_provider.dart';
import 'package:gigaeats/src/features/drivers/presentation/providers/route_optimization_provider.dart';
import 'package:gigaeats/src/features/drivers/data/models/delivery_batch.dart';
import 'package:gigaeats/src/features/drivers/data/models/batch_operation_results.dart';
import 'package:gigaeats/src/features/drivers/data/models/route_optimization_models.dart';
import 'package:gigaeats/src/features/orders/data/models/order.dart';
import 'package:gigaeats/src/data/models/user_role.dart';

// Mock classes
class MockMultiOrderBatchNotifier extends StateNotifier<MultiOrderBatchState>
    with Mock
    implements MultiOrderBatchNotifier {
  MockMultiOrderBatchNotifier() : super(const MultiOrderBatchState());
}

class MockRouteOptimizationNotifier extends StateNotifier<RouteOptimizationState>
    with Mock
    implements RouteOptimizationNotifier {
  MockRouteOptimizationNotifier() : super(const RouteOptimizationState());
}

void main() {
  group('MultiOrderDriverDashboard', () {
    late MockMultiOrderBatchNotifier mockBatchNotifier;
    late MockRouteOptimizationNotifier mockRouteNotifier;

    setUp(() {
      mockBatchNotifier = MockMultiOrderBatchNotifier();
      mockRouteNotifier = MockRouteOptimizationNotifier();
    });

    Widget createTestWidget({
      MultiOrderBatchState? batchState,
      RouteOptimizationState? routeState,
    }) {
      return ProviderScope(
        overrides: [
          multiOrderBatchProvider.overrideWith((ref) {
            mockBatchNotifier.state = batchState ?? const MultiOrderBatchState();
            return mockBatchNotifier;
          }),
          routeOptimizationProvider.overrideWith((ref) {
            mockRouteNotifier.state = routeState ?? const RouteOptimizationState();
            return mockRouteNotifier;
          }),
        ],
        child: MaterialApp(
          home: const MultiOrderDriverDashboard(),
        ),
      );
    }

    testWidgets('displays empty state when no active batch', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('No Active Batch'), findsOneWidget);
      expect(find.text('Create a new batch to start multi-order delivery'), findsOneWidget);
      expect(find.text('Create Batch'), findsOneWidget);
    });

    testWidgets('displays batch overview when active batch exists', (tester) async {
      final mockBatch = DeliveryBatch(
        id: 'batch_123',
        driverId: 'driver_123',
        batchNumber: 'B001',
        status: BatchStatus.active,
        maxOrders: 3,
        maxDeviationKm: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final batchState = MultiOrderBatchState(
        activeBatch: mockBatch,
        batchOrders: [],
        isLoading: false,
      );

      await tester.pumpWidget(createTestWidget(batchState: batchState));
      await tester.pumpAndSettle();

      // Should show batch overview
      expect(find.text('Batch #batch_12'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets('displays loading state correctly', (tester) async {
      const batchState = MultiOrderBatchState(isLoading: true);

      await tester.pumpWidget(createTestWidget(batchState: batchState));
      await tester.pumpAndSettle();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('displays error state correctly', (tester) async {
      const batchState = MultiOrderBatchState(
        error: 'Failed to load batch data',
        isLoading: false,
      );

      await tester.pumpWidget(createTestWidget(batchState: batchState));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Error loading batch'), findsOneWidget);
      expect(find.text('Failed to load batch data'), findsOneWidget);
    });

    testWidgets('displays order sequence cards when batch orders exist', (tester) async {
      final mockOrder = Order(
        id: 'order_123',
        orderNumber: 'ORD001',
        customerId: 'customer_123',
        vendorId: 'vendor_123',
        vendorName: 'Test Restaurant',
        status: OrderStatus.confirmed,
        items: [],
        totalAmount: 25.50,
        deliveryAddress: const Address(
          street: '123 Test St',
          city: 'Test City',
          state: 'Test State',
          postalCode: '12345',
          country: 'Test Country',
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockBatchOrder = BatchOrderWithDetails(
        batchId: 'batch_123',
        orderId: 'order_123',
        sequence: 1,
        pickupStatus: BatchOrderPickupStatus.pending,
        deliveryStatus: BatchOrderDeliveryStatus.pending,
        order: mockOrder,
      );

      final mockBatch = DeliveryBatch(
        id: 'batch_123',
        driverId: 'driver_123',
        batchNumber: 'B001',
        status: BatchStatus.active,
        maxOrders: 3,
        maxDeviationKm: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final batchState = MultiOrderBatchState(
        activeBatch: mockBatch,
        batchOrders: [mockBatchOrder],
        isLoading: false,
      );

      await tester.pumpWidget(createTestWidget(batchState: batchState));
      await tester.pumpAndSettle();

      // Should show order sequence card
      expect(find.text('Order #ORD001'), findsOneWidget);
      expect(find.text('Test Restaurant'), findsOneWidget);
    });

    testWidgets('displays route optimization controls when route exists', (tester) async {
      final mockRoute = OptimizedRoute(
        id: 'route_123',
        batchId: 'batch_123',
        waypoints: [],
        totalDistanceKm: 10.5,
        totalDuration: const Duration(minutes: 45),
        durationInTraffic: const Duration(minutes: 50),
        optimizationScore: 85.0,
        criteria: OptimizationCriteria.balanced(),
        calculatedAt: DateTime.now(),
      );

      final routeState = RouteOptimizationState(
        currentRoute: mockRoute,
        isOptimizing: false,
      );

      await tester.pumpWidget(createTestWidget(routeState: routeState));
      await tester.pumpAndSettle();

      // Should show route optimization controls
      expect(find.text('Route Optimization'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget); // Optimization score
    });

    testWidgets('refresh functionality works correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);
      
      await tester.tap(refreshButton);
      await tester.pumpAndSettle();

      // Verify loadActiveBatch was called
      verify(mockBatchNotifier.loadActiveBatch(any)).called(1);
    });

    testWidgets('quick actions panel opens correctly', (tester) async {
      final mockBatch = DeliveryBatch(
        id: 'batch_123',
        driverId: 'driver_123',
        batchNumber: 'B001',
        status: BatchStatus.active,
        maxOrders: 3,
        maxDeviationKm: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final batchState = MultiOrderBatchState(
        activeBatch: mockBatch,
        isLoading: false,
      );

      await tester.pumpWidget(createTestWidget(batchState: batchState));
      await tester.pumpAndSettle();

      // Find and tap quick actions FAB
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Should show quick actions panel
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Navigate'), findsOneWidget);
      expect(find.text('Call Customer'), findsOneWidget);
    });

    testWidgets('app bar displays correct batch status', (tester) async {
      final mockBatch = DeliveryBatch(
        id: 'batch_123',
        driverId: 'driver_123',
        batchNumber: 'B001',
        status: BatchStatus.active,
        maxOrders: 3,
        maxDeviationKm: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final batchState = MultiOrderBatchState(
        activeBatch: mockBatch,
        isLoading: false,
      );

      await tester.pumpWidget(createTestWidget(batchState: batchState));
      await tester.pumpAndSettle();

      // Should show batch status in app bar
      expect(find.text('Multi-Order Dashboard'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('handles different batch statuses correctly', (tester) async {
      for (final status in BatchStatus.values) {
        final mockBatch = DeliveryBatch(
          id: 'batch_123',
          driverId: 'driver_123',
          batchNumber: 'B001',
          status: status,
          maxOrders: 3,
          maxDeviationKm: 5.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final batchState = MultiOrderBatchState(
          activeBatch: mockBatch,
          isLoading: false,
        );

        await tester.pumpWidget(createTestWidget(batchState: batchState));
        await tester.pumpAndSettle();

        // Should display the correct status
        expect(find.text(status.displayName), findsOneWidget);
        
        // Clean up for next iteration
        await tester.pumpWidget(Container());
      }
    });
  });
}
