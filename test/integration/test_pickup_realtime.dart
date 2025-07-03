import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigaeats_app/src/features/orders/presentation/screens/customer/customer_order_details_screen.dart';

void main() {
  group('Customer Order Details Real-time Updates', () {
    testWidgets('should update UI when order status changes to delivered', (WidgetTester tester) async {
      // Test order ID from database
      const testOrderId = 'ad8cb032-c9c6-49df-b16d-d0bd2626baeb';
      
      // Build the widget
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CustomerOrderDetailsScreen(orderId: testOrderId),
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Verify initial state shows "ready" status
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('Mark as Picked Up'), findsOneWidget);

      // Simulate pickup confirmation
      await tester.tap(find.text('Mark as Picked Up'));
      await tester.pumpAndSettle();

      // Confirm in dialog
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Wait for real-time update
      await tester.pump(const Duration(seconds: 2));

      // Verify status updated to delivered
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('Mark as Picked Up'), findsNothing);
    });
  });
}
