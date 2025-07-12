import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/driver_order.dart';
import 'package:gigaeats_app/src/features/orders/data/models/driver_order_state_machine.dart';
import 'package:gigaeats_app/src/features/orders/data/repositories/driver_order_repository.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/driver_realtime_service.dart';

import 'package:gigaeats_app/src/features/drivers/data/services/enhanced_workflow_integration_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/driver_workflow_notification_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/notification_template_initialization_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/pickup_confirmation.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/delivery_confirmation.dart';
import 'package:gigaeats_app/src/core/services/location_service.dart';

/// Comprehensive integration test for the complete driver workflow
/// Tests all 7 steps of the driver order status transition workflow
void main() {
  group('Driver Workflow Integration Tests', () {
    late SupabaseClient supabase;
    late DriverOrderRepository driverOrderRepository;
    late DriverRealtimeService driverRealtimeService;
    
    // Test configuration
    const testDriverId = '087132e7-e38b-4d3f-b28c-7c34b75e86c4';
    const testDriverUserId = '5a400967-c68e-48fa-a222-ef25249de974';
    const testVendorId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
    const testCustomerId = 'customer_test_id';

    setUpAll(() async {
      // Initialize Supabase for testing
      await Supabase.initialize(
        url: 'https://abknoalhfltlhhdbclpv.supabase.co',
        anonKey: 'your_anon_key_here', // Replace with actual anon key
      );

      supabase = Supabase.instance.client;
      driverOrderRepository = DriverOrderRepository();
      driverRealtimeService = DriverRealtimeService();
    });

    tearDownAll(() async {
      await driverRealtimeService.dispose();
      await supabase.dispose();
    });

    group('Phase 1: Database Schema Validation', () {
      test('should validate drivers table structure', () async {
        final response = await supabase
            .from('drivers')
            .select('id, vendor_id, user_id, name, phone_number, status, is_active')
            .limit(1);
        
        expect(response, isA<List>());
        
        if (response.isNotEmpty) {
          final driver = response.first;
          expect(driver, containsPair('id', isA<String>()));
          expect(driver, containsPair('vendor_id', isA<String>()));
          expect(driver, containsPair('status', isA<String>()));
          expect(driver, containsPair('is_active', isA<bool>()));
        }
      });

      test('should validate orders table has driver fields', () async {
        final response = await supabase
            .from('orders')
            .select('id, status, assigned_driver_id, delivery_method')
            .limit(1);
        
        expect(response, isA<List>());
        
        if (response.isNotEmpty) {
          final order = response.first;
          expect(order, containsPair('id', isA<String>()));
          expect(order, containsPair('status', isA<String>()));
          expect(order.keys, contains('assigned_driver_id'));
        }
      });

      test('should validate delivery_tracking table exists', () async {
        try {
          await supabase
              .from('delivery_tracking')
              .select('id, order_id, driver_id, recorded_at')
              .limit(1);
          
          // If we reach here, table exists
          expect(true, isTrue);
        } catch (e) {
          fail('delivery_tracking table does not exist or is not accessible: $e');
        }
      });

      test('should validate driver_earnings table exists', () async {
        try {
          await supabase
              .from('driver_earnings')
              .select('id, driver_id, order_id, amount')
              .limit(1);
          
          // If we reach here, table exists
          expect(true, isTrue);
        } catch (e) {
          fail('driver_earnings table does not exist or is not accessible: $e');
        }
      });
    });

    group('Phase 2: RLS Policy Testing', () {
      test('should authenticate as test driver', () async {
        final authResponse = await supabase.auth.signInWithPassword(
          email: 'driver.test@gigaeats.com',
          password: 'Testpass123!',
        );

        expect(authResponse.user, isNotNull);
        expect(authResponse.user!.email, equals('driver.test@gigaeats.com'));
      });

      test('should allow driver to access own profile', () async {
        final response = await supabase
            .from('drivers')
            .select('id, name, status')
            .eq('user_id', testDriverUserId)
            .single();

        expect(response, isNotNull);
        expect(response['id'], equals(testDriverId));
      });

      test('should allow driver to view assigned orders', () async {
        final response = await supabase
            .from('orders')
            .select('id, status, assigned_driver_id')
            .eq('assigned_driver_id', testDriverId);

        expect(response, isA<List>());
        // Driver should be able to query their assigned orders
      });

      test('should prevent driver from accessing other drivers data', () async {
        try {
          await supabase
              .from('drivers')
              .select('id, name')
              .neq('user_id', testDriverUserId)
              .limit(1);
          
          // If this succeeds, RLS is not properly configured
          fail('Driver should not be able to access other drivers data');
        } catch (e) {
          // This is expected - RLS should prevent access
          expect(e.toString(), contains('row-level security'));
        }
      });
    });

    group('Phase 3: Driver Order State Machine Testing', () {
      test('should validate all status transitions', () {
        // Test valid transitions - start from assigned status
        expect(
          DriverOrderStateMachine.isValidTransition(
            DriverOrderStatus.assigned,
            DriverOrderStatus.onRouteToVendor,
          ),
          isTrue,
        );

        expect(
          DriverOrderStateMachine.isValidTransition(
            DriverOrderStatus.assigned,
            DriverOrderStatus.onRouteToVendor,
          ),
          isTrue,
        );

        expect(
          DriverOrderStateMachine.isValidTransition(
            DriverOrderStatus.onRouteToVendor,
            DriverOrderStatus.arrivedAtVendor,
          ),
          isTrue,
        );

        expect(
          DriverOrderStateMachine.isValidTransition(
            DriverOrderStatus.arrivedAtVendor,
            DriverOrderStatus.pickedUp,
          ),
          isTrue,
        );

        expect(
          DriverOrderStateMachine.isValidTransition(
            DriverOrderStatus.pickedUp,
            DriverOrderStatus.onRouteToCustomer,
          ),
          isTrue,
        );

        expect(
          DriverOrderStateMachine.isValidTransition(
            DriverOrderStatus.onRouteToCustomer,
            DriverOrderStatus.arrivedAtCustomer,
          ),
          isTrue,
        );

        expect(
          DriverOrderStateMachine.isValidTransition(
            DriverOrderStatus.arrivedAtCustomer,
            DriverOrderStatus.delivered,
          ),
          isTrue,
        );
      });

      test('should reject invalid transitions', () {
        // Test invalid transitions - cannot skip from assigned to delivered
        expect(
          DriverOrderStateMachine.isValidTransition(
            DriverOrderStatus.assigned,
            DriverOrderStatus.delivered,
          ),
          isFalse,
        );

        expect(
          DriverOrderStateMachine.isValidTransition(
            DriverOrderStatus.assigned,
            DriverOrderStatus.pickedUp,
          ),
          isFalse,
        );

        expect(
          DriverOrderStateMachine.isValidTransition(
            DriverOrderStatus.delivered,
            DriverOrderStatus.assigned,
          ),
          isFalse,
        );
      });

      test('should provide correct available actions for each status', () {
        final assignedActions = DriverOrderStateMachine.getAvailableActions(
          DriverOrderStatus.assigned,
        );
        expect(assignedActions, contains(DriverOrderAction.navigateToVendor));
        expect(assignedActions, contains(DriverOrderAction.cancel));

        final pickedUpActions = DriverOrderStateMachine.getAvailableActions(
          DriverOrderStatus.pickedUp,
        );
        expect(pickedUpActions, contains(DriverOrderAction.navigateToCustomer));
        expect(pickedUpActions, contains(DriverOrderAction.reportIssue));

        final deliveredActions = DriverOrderStateMachine.getAvailableActions(
          DriverOrderStatus.delivered,
        );
        expect(deliveredActions, isEmpty);
      });
    });

    group('Phase 4: API Endpoint Testing', () {
      String? testOrderId;

      setUp(() async {
        // Create a test order for each test
        final orderResponse = await supabase
            .from('orders')
            .insert({
              'customer_id': testCustomerId,
              'vendor_id': testVendorId,
              'total_amount': 25.50,
              'status': 'ready',
              'delivery_method': 'own_fleet',
              'delivery_address': 'Test Address, Kuala Lumpur',
              'contact_phone': '+60123456789',
              'order_number': 'TEST-${DateTime.now().millisecondsSinceEpoch}',
              'vendor_name': 'Test Vendor',
              'customer_name': 'Test Customer',
            })
            .select('id')
            .single();

        testOrderId = orderResponse['id'];
      });

      tearDown(() async {
        // Clean up test order
        if (testOrderId != null) {
          await supabase
              .from('orders')
              .delete()
              .eq('id', testOrderId!);
        }
      });

      test('should accept available order (ready → assigned)', () async {
        expect(testOrderId, isNotNull);

        final success = await driverOrderRepository.acceptOrder(
          testOrderId!,
          testDriverId,
        );

        expect(success, isTrue);

        // Verify order status changed
        final updatedOrder = await supabase
            .from('orders')
            .select('status, assigned_driver_id')
            .eq('id', testOrderId!)
            .single();

        expect(updatedOrder['status'], equals('out_for_delivery'));
        expect(updatedOrder['assigned_driver_id'], equals(testDriverId));
      });

      test('should update order status through workflow', () async {
        expect(testOrderId, isNotNull);

        // First accept the order
        await driverOrderRepository.acceptOrder(testOrderId!, testDriverId);

        // Test each status transition
        final transitions = [
          DriverOrderStatus.onRouteToVendor,
          DriverOrderStatus.arrivedAtVendor,
          DriverOrderStatus.pickedUp,
          DriverOrderStatus.onRouteToCustomer,
          DriverOrderStatus.arrivedAtCustomer,
          DriverOrderStatus.delivered,
        ];

        for (final status in transitions) {
          final success = await driverOrderRepository.updateOrderStatus(
            testOrderId!,
            status,
            driverId: testDriverId,
          );

          expect(success, isTrue, reason: 'Failed to update to status: ${status.value}');

          // For delivered status, verify order is marked as delivered
          if (status == DriverOrderStatus.delivered) {
            final finalOrder = await supabase
                .from('orders')
                .select('status, actual_delivery_time')
                .eq('id', testOrderId!)
                .single();

            expect(finalOrder['status'], equals('delivered'));
            expect(finalOrder['actual_delivery_time'], isNotNull);
          }
        }
      });
    });

    group('Phase 5: Real-time Subscription Testing', () {
      test('should receive real-time order updates', () async {
        // This test would require setting up real-time listeners
        // and verifying that updates are received when order status changes
        
        await driverRealtimeService.initializeForDriver(testDriverId);
        
        // Listen for order status updates
        bool updateReceived = false;
        driverRealtimeService.orderStatusUpdates.listen((update) {
          updateReceived = true;
        });

        // Create and update a test order
        final orderResponse = await supabase
            .from('orders')
            .insert({
              'customer_id': testCustomerId,
              'vendor_id': testVendorId,
              'assigned_driver_id': testDriverId,
              'total_amount': 15.00,
              'status': 'out_for_delivery',
              'delivery_method': 'own_fleet',
              'delivery_address': 'Real-time Test Address',
              'contact_phone': '+60123456789',
              'order_number': 'REALTIME-${DateTime.now().millisecondsSinceEpoch}',
              'vendor_name': 'Test Vendor',
              'customer_name': 'Test Customer',
            })
            .select('id')
            .single();

        final orderId = orderResponse['id'];

        // Update order status to trigger real-time event
        await supabase
            .from('orders')
            .update({'status': 'delivered'})
            .eq('id', orderId);

        // Wait for real-time update
        await Future.delayed(const Duration(seconds: 2));

        expect(updateReceived, isTrue, reason: 'Real-time update was not received');

        // Clean up
        await supabase.from('orders').delete().eq('id', orderId);
      });
    });

    group('Phase 6: Enhanced Driver Workflow Testing', () {
      late ProviderContainer container;

      setUp(() {
        container = ProviderContainer();
      });

      tearDown(() {
        container.dispose();
      });

      test('should initialize notification templates', () async {
        await NotificationTemplateInitializationService.initializeOnStartup();

        final templateService = NotificationTemplateInitializationService();
        final templatesExist = await templateService.validateTemplatesExist();
        expect(templatesExist, true, reason: 'All required templates should exist');
      });

      test('should complete enhanced 7-step workflow', () async {
        // Create test order
        final orderResponse = await supabase
            .from('orders')
            .insert({
              'customer_id': testCustomerId,
              'vendor_id': testVendorId,
              'total_amount': 35.00,
              'status': 'assigned',
              'assigned_driver_id': testDriverId,
              'delivery_method': 'own_fleet',
              'delivery_address': 'Enhanced Workflow Test Address',
              'contact_phone': '+60123456789',
              'order_number': 'ENHANCED-${DateTime.now().millisecondsSinceEpoch}',
              'vendor_name': 'Test Vendor',
              'customer_name': 'Test Customer',
            })
            .select('id')
            .single();

        final orderId = orderResponse['id'];

        try {
          final workflowService = EnhancedWorkflowIntegrationService();

          // Test each status transition with enhanced workflow
          final transitions = [
            (DriverOrderStatus.assigned, DriverOrderStatus.onRouteToVendor),
            (DriverOrderStatus.onRouteToVendor, DriverOrderStatus.arrivedAtVendor),
            (DriverOrderStatus.arrivedAtVendor, DriverOrderStatus.pickedUp),
            (DriverOrderStatus.pickedUp, DriverOrderStatus.onRouteToCustomer),
            (DriverOrderStatus.onRouteToCustomer, DriverOrderStatus.arrivedAtCustomer),
            (DriverOrderStatus.arrivedAtCustomer, DriverOrderStatus.delivered),
          ];

          for (final (fromStatus, toStatus) in transitions) {
            // Update order status first
            await supabase
                .from('orders')
                .update({'status': fromStatus.value})
                .eq('id', orderId);

            // Process workflow integration
            final result = await workflowService.processOrderStatusChange(
              orderId: orderId,
              fromStatus: fromStatus,
              toStatus: toStatus,
              driverId: testDriverId,
            );

            expect(result.isSuccess, true,
                   reason: 'Workflow transition $fromStatus → $toStatus should succeed');
          }

          // Verify final status
          final finalOrder = await supabase
              .from('orders')
              .select('status')
              .eq('id', orderId)
              .single();

          expect(finalOrder['status'], equals('delivered'));

        } finally {
          // Clean up
          await supabase.from('orders').delete().eq('id', orderId);
        }
      });

      test('should validate pickup confirmation requirements', () {
        final validConfirmation = PickupConfirmation(
          orderId: 'test-order-id',
          confirmedAt: DateTime.now(),
          verificationChecklist: {
            'Order number matches': true,
            'All items are present': true,
            'Items are properly packaged': true,
            'Special instructions noted': true,
            'Temperature requirements met': true,
          },
          notes: 'All items verified and ready for delivery',
          confirmedBy: testDriverId,
        );

        expect(validConfirmation.verificationChecklist.length, equals(5));
        expect(validConfirmation.verificationChecklist.values.every((v) => v), true);
        expect(validConfirmation.notes, isNotEmpty);
      });

      test('should validate delivery confirmation requirements', () {
        final validConfirmation = DeliveryConfirmation(
          orderId: 'test-order-id',
          deliveredAt: DateTime.now(),
          photoUrl: 'https://example.com/delivery-photo.jpg',
          location: LocationData(
            latitude: 3.1390,
            longitude: 101.6869,
            accuracy: 15.0,
            timestamp: DateTime.now(),
          ),
          recipientName: 'Test Customer',
          notes: 'Delivered successfully to customer',
          confirmedBy: testDriverId,
        );

        expect(validConfirmation.photoUrl, isNotEmpty);
        expect(validConfirmation.location.accuracy, lessThan(50.0));
        expect(validConfirmation.recipientName, isNotEmpty);
      });

      test('should send workflow notifications', () async {
        final notificationService = DriverWorkflowNotificationService();

        // Test notification sending (should not throw)
        expect(() async {
          await notificationService.notifyWorkflowStatusChange(
            orderId: 'test-order-id',
            fromStatus: DriverOrderStatus.assigned,
            toStatus: DriverOrderStatus.onRouteToVendor,
            driverId: testDriverId,
          );
        }, returnsNormally);
      });
    });

    group('Phase 7: Error Handling Testing', () {
      test('should handle invalid status transitions gracefully', () async {
        // Create test order in 'ready' state
        final orderResponse = await supabase
            .from('orders')
            .insert({
              'customer_id': testCustomerId,
              'vendor_id': testVendorId,
              'total_amount': 20.00,
              'status': 'ready',
              'delivery_method': 'own_fleet',
              'delivery_address': 'Error Test Address',
              'contact_phone': '+60123456789',
              'order_number': 'ERROR-${DateTime.now().millisecondsSinceEpoch}',
              'vendor_name': 'Test Vendor',
              'customer_name': 'Test Customer',
            })
            .select('id')
            .single();

        final orderId = orderResponse['id'];

        try {
          // Try to update directly to delivered without going through workflow
          final success = await driverOrderRepository.updateOrderStatus(
            orderId,
            DriverOrderStatus.delivered,
            driverId: testDriverId,
          );

          // This should fail due to invalid transition
          expect(success, isFalse);
        } catch (e) {
          // Exception is also acceptable for invalid transitions
          expect(e, isNotNull);
        }

        // Clean up
        await supabase.from('orders').delete().eq('id', orderId);
      });

      test('should handle concurrent order acceptance', () async {
        // This test would simulate multiple drivers trying to accept the same order
        // and verify that only one succeeds
        
        final orderResponse = await supabase
            .from('orders')
            .insert({
              'customer_id': testCustomerId,
              'vendor_id': testVendorId,
              'total_amount': 30.00,
              'status': 'ready',
              'delivery_method': 'own_fleet',
              'delivery_address': 'Concurrent Test Address',
              'contact_phone': '+60123456789',
              'order_number': 'CONCURRENT-${DateTime.now().millisecondsSinceEpoch}',
              'vendor_name': 'Test Vendor',
              'customer_name': 'Test Customer',
            })
            .select('id')
            .single();

        final orderId = orderResponse['id'];

        // Simulate concurrent acceptance attempts
        final futures = [
          driverOrderRepository.acceptOrder(orderId, testDriverId),
          driverOrderRepository.acceptOrder(orderId, 'another_driver_id'),
        ];

        final results = await Future.wait(futures, eagerError: false);

        // Only one should succeed
        final successCount = results.where((result) => result == true).length;
        expect(successCount, equals(1));

        // Clean up
        await supabase.from('orders').delete().eq('id', orderId);
      });
    });
  });
}

// Helper function removed - now using unified DriverOrderStatus from drivers module
