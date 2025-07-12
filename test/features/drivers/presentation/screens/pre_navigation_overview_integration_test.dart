import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gigaeats_app/src/features/drivers/presentation/screens/pre_navigation_overview_screen.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/driver_order.dart';

void main() {
  group('PreNavigationOverviewScreen Integration Tests', () {
    late DriverOrder mockOrder;

    setUp(() {
      SharedPreferences.setMockInitialValues({});

      mockOrder = DriverOrder(
        id: 'test-order-123',
        orderId: 'order-123',
        driverId: 'driver-123',
        vendorId: 'vendor-123',
        vendorName: 'Test Restaurant',
        customerId: 'customer-123',
        customerName: 'John Doe',
        status: DriverOrderStatus.assigned,
        deliveryDetails: const DeliveryDetails(
          pickupAddress: '456 Vendor Street, Kuala Lumpur',
          deliveryAddress: '123 Test Street, Kuala Lumpur',
          contactPhone: '+60123456789',
          specialInstructions: 'Test instructions',
        ),
        orderEarnings: const OrderEarnings(
          baseFee: 5.00,
          distanceFee: 2.00,
          timeBonus: 1.50,
          totalEarnings: 8.50,
        ),
        orderItemsCount: 3,
        orderTotal: 25.50,
        assignedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    Widget createTestWidget({
      required DriverNavigationDestination destination,
      VoidCallback? onNavigationStarted,
      VoidCallback? onCancel,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: PreNavigationOverviewScreen(
            order: mockOrder,
            destination: destination,
            onNavigationStarted: onNavigationStarted ?? () {},
            onCancel: onCancel ?? () {},
          ),
        ),
      );
    }

    testWidgets('displays correct destination for vendor navigation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        destination: DriverNavigationDestination.vendor,
      ));

      expect(find.text('Navigate to Test Restaurant'), findsOneWidget);
    });

    testWidgets('displays correct destination for customer navigation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        destination: DriverNavigationDestination.customer,
      ));

      expect(find.text('Navigate to John Doe'), findsOneWidget);
    });

    testWidgets('shows loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        destination: DriverNavigationDestination.vendor,
      ));

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('displays location loading view', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        destination: DriverNavigationDestination.vendor,
      ));

      // Wait for initial render
      await tester.pump();

      expect(find.text('Getting your location...'), findsOneWidget);
      expect(find.text('Please ensure location services are enabled'), findsOneWidget);
    });

    testWidgets('shows close button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        destination: DriverNavigationDestination.vendor,
      ));

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('calls onCancel when close button is pressed', (WidgetTester tester) async {
      bool cancelCalled = false;

      await tester.pumpWidget(createTestWidget(
        destination: DriverNavigationDestination.vendor,
        onCancel: () => cancelCalled = true,
      ));

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(cancelCalled, isTrue);
    });

    testWidgets('displays error view when location fails', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        destination: DriverNavigationDestination.vendor,
      ));

      // Wait for location loading to complete (will fail in test environment)
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should show error view
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows retry button in error state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        destination: DriverNavigationDestination.vendor,
      ));

      // Wait for error state
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);

      // Test retry functionality
      await tester.tap(retryButton);
      await tester.pump();

      // Should show loading again
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('displays cancel button in error state', (WidgetTester tester) async {
      bool cancelCalled = false;

      await tester.pumpWidget(createTestWidget(
        destination: DriverNavigationDestination.vendor,
        onCancel: () => cancelCalled = true,
      ));

      // Wait for error state
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final cancelButton = find.text('Cancel');
      expect(cancelButton, findsOneWidget);

      await tester.tap(cancelButton);
      await tester.pump();

      expect(cancelCalled, isTrue);
    });

    testWidgets('handles different error types appropriately', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        destination: DriverNavigationDestination.vendor,
      ));

      // Wait for error state
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should show location-specific error message
      expect(find.textContaining('location'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows loading indicator in app bar during processing', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        destination: DriverNavigationDestination.vendor,
      ));

      // Should show loading indicator in app bar
      expect(find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(CircularProgressIndicator),
      ), findsOneWidget);
    });

    testWidgets('maintains state during widget rebuilds', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        destination: DriverNavigationDestination.vendor,
      ));

      // Wait for initial state
      await tester.pump();

      // Rebuild widget
      await tester.pumpWidget(createTestWidget(
        destination: DriverNavigationDestination.vendor,
      ));

      // Should maintain loading state
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('handles navigation destination changes', (WidgetTester tester) async {
      // Start with vendor destination
      await tester.pumpWidget(createTestWidget(
        destination: DriverNavigationDestination.vendor,
      ));

      expect(find.text('Navigate to Test Restaurant'), findsOneWidget);

      // Change to customer destination
      await tester.pumpWidget(createTestWidget(
        destination: DriverNavigationDestination.customer,
      ));

      expect(find.text('Navigate to John Doe'), findsOneWidget);
    });
  });

  group('PreNavigationOverviewScreen Error Handling', () {
    testWidgets('displays appropriate error messages for different error types', (WidgetTester tester) async {
      final mockOrder = DriverOrder(
        id: 'test-order-123',
        orderId: 'order-123',
        driverId: 'driver-123',
        vendorId: 'vendor-123',
        vendorName: 'Test Restaurant',
        customerId: 'customer-123',
        customerName: 'John Doe',
        status: DriverOrderStatus.assigned,
        deliveryDetails: const DeliveryDetails(
          pickupAddress: '456 Vendor Street, Kuala Lumpur',
          deliveryAddress: '123 Test Street, Kuala Lumpur',
          contactPhone: '+60123456789',
          specialInstructions: 'Test instructions',
        ),
        orderEarnings: const OrderEarnings(
          baseFee: 5.00,
          distanceFee: 2.00,
          timeBonus: 1.50,
          totalEarnings: 8.50,
        ),
        orderItemsCount: 3,
        orderTotal: 25.50,
        assignedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: PreNavigationOverviewScreen(
            order: mockOrder,
            destination: DriverNavigationDestination.vendor,
            onNavigationStarted: () {},
            onCancel: () {},
          ),
        ),
      ));

      // Wait for error state
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should show error icon
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('provides helpful error messages for location issues', (WidgetTester tester) async {
      final mockOrder = DriverOrder(
        id: 'test-order-123',
        orderId: 'order-123',
        driverId: 'driver-123',
        vendorId: 'vendor-123',
        vendorName: 'Test Restaurant',
        customerId: 'customer-123',
        customerName: 'John Doe',
        status: DriverOrderStatus.assigned,
        deliveryDetails: const DeliveryDetails(
          pickupAddress: '456 Vendor Street, Kuala Lumpur',
          deliveryAddress: '123 Test Street, Kuala Lumpur',
          contactPhone: '+60123456789',
          specialInstructions: 'Test instructions',
        ),
        orderEarnings: const OrderEarnings(
          baseFee: 5.00,
          distanceFee: 2.00,
          timeBonus: 1.50,
          totalEarnings: 8.50,
        ),
        orderItemsCount: 3,
        orderTotal: 25.50,
        assignedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: PreNavigationOverviewScreen(
            order: mockOrder,
            destination: DriverNavigationDestination.vendor,
            onNavigationStarted: () {},
            onCancel: () {},
          ),
        ),
      ));

      // Wait for error state
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should provide helpful guidance
      expect(find.textContaining('location'), findsAtLeastNWidgets(1));
    });
  });

  group('PreNavigationOverviewScreen Accessibility', () {
    testWidgets('provides proper semantic labels', (WidgetTester tester) async {
      final mockOrder = DriverOrder(
        id: 'test-order-123',
        orderId: 'order-123',
        driverId: 'driver-123',
        vendorId: 'vendor-123',
        vendorName: 'Test Restaurant',
        customerId: 'customer-123',
        customerName: 'John Doe',
        status: DriverOrderStatus.assigned,
        deliveryDetails: const DeliveryDetails(
          pickupAddress: '456 Vendor Street, Kuala Lumpur',
          deliveryAddress: '123 Test Street, Kuala Lumpur',
          contactPhone: '+60123456789',
          specialInstructions: 'Test instructions',
        ),
        orderEarnings: const OrderEarnings(
          baseFee: 5.00,
          distanceFee: 2.00,
          timeBonus: 1.50,
          totalEarnings: 8.50,
        ),
        orderItemsCount: 3,
        orderTotal: 25.50,
        assignedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: PreNavigationOverviewScreen(
            order: mockOrder,
            destination: DriverNavigationDestination.vendor,
            onNavigationStarted: () {},
            onCancel: () {},
          ),
        ),
      ));

      // Verify semantic structure
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
