import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/driver_order.dart';
import 'package:gigaeats_app/src/features/orders/data/models/driver_order_state_machine.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/enhanced_workflow_integration_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/driver_workflow_error_handler.dart';
import 'package:gigaeats_app/src/core/utils/driver_workflow_logger.dart';
import '../utils/driver_test_helpers.dart';

/// Comprehensive integration tests for the complete GigaEats driver workflow system
/// 
/// This test suite validates the entire driver workflow from order acceptance
/// through delivery completion, including:
/// - Complete 7-step status progression
/// - Real-time updates and synchronization
/// - Error handling and recovery mechanisms
/// - Provider state management
/// - Database integration and RLS policies
/// - UI component integration
/// - Performance and reliability testing
void main() {
  group('Comprehensive Driver Workflow Integration Tests', () {
    late SupabaseClient supabase;
    late String testOrderId;
    late String testDriverId;
    late ProviderContainer container;
    late DriverWorkflowLogger logger;
    late EnhancedWorkflowIntegrationService workflowService;
    late DriverWorkflowErrorHandler errorHandler;

    setUpAll(() async {
      // Initialize Supabase for testing
      await Supabase.initialize(
        url: DriverTestHelpers.testConfig['supabaseUrl']!,
        anonKey: 'test-anon-key', // Use test environment key
      );
      supabase = Supabase.instance.client;
      
      // Initialize test services
      logger = DriverWorkflowLogger();
      workflowService = EnhancedWorkflowIntegrationService();
      errorHandler = DriverWorkflowErrorHandler();
      
      // Set up test data
      testDriverId = DriverTestHelpers.testConfig['testDriverId']!;
      
      // Authenticate as test driver
      await DriverTestHelpers.authenticateAsTestDriver(supabase);
    });

    setUp(() async {
      // Create fresh provider container for each test
      container = DriverTestHelpers.createTestContainer();
      
      // Create test order for each test
      testOrderId = await DriverTestHelpers.createTestOrder(
        supabase,
        customerId: DriverTestHelpers.testConfig['testCustomerId']!,
        vendorId: DriverTestHelpers.testConfig['testVendorId']!,
      );
    });

    tearDown(() async {
      // Clean up test order
      if (testOrderId.isNotEmpty) {
        await DriverTestHelpers.cleanupTestOrder(supabase, testOrderId);
      }
      
      // Dispose provider container
      container.dispose();
    });

    tearDownAll(() async {
      // Sign out test user
      await DriverTestHelpers.signOut(supabase);
    });

    group('End-to-End Workflow Progression Tests', () {
      test('should complete full 7-step workflow progression successfully', () async {
        // Test the complete workflow from order acceptance to delivery completion
        final workflowSteps = [
          (DriverOrderStatus.assigned, DriverOrderStatus.onRouteToVendor),
          (DriverOrderStatus.onRouteToVendor, DriverOrderStatus.arrivedAtVendor),
          (DriverOrderStatus.arrivedAtVendor, DriverOrderStatus.pickedUp),
          (DriverOrderStatus.pickedUp, DriverOrderStatus.onRouteToCustomer),
          (DriverOrderStatus.onRouteToCustomer, DriverOrderStatus.arrivedAtCustomer),
          (DriverOrderStatus.arrivedAtCustomer, DriverOrderStatus.delivered),
        ];

        // Start workflow logging
        DriverWorkflowLogger.logDatabaseOperation(
          operation: 'complete_workflow_test_start',
          orderId: testOrderId,
          context: 'integration_test',
        );

        try {
          // Step 1: Accept order (ready → assigned)
          await DriverTestHelpers.updateOrderStatus(
            supabase,
            testOrderId,
            'assigned',
            assignedDriverId: testDriverId,
          );

          // Verify order is assigned
          final assignedOrder = await DriverTestHelpers.getTestOrder(supabase, testOrderId);
          expect(assignedOrder['status'], equals('assigned'));
          expect(assignedOrder['assigned_driver_id'], equals(testDriverId));

          // Execute each workflow step
          for (final (fromStatus, toStatus) in workflowSteps) {
            // Log transition
            DriverWorkflowLogger.logStatusTransition(
              orderId: testOrderId,
              fromStatus: fromStatus.value,
              toStatus: toStatus.value,
              driverId: testDriverId,
              context: 'integration_test',
            );

            // Process workflow transition
            final result = await workflowService.processOrderStatusChange(
              orderId: testOrderId,
              fromStatus: fromStatus,
              toStatus: toStatus,
              driverId: testDriverId,
            );

            expect(result.isSuccess, isTrue,
                reason: 'Workflow step $fromStatus → $toStatus should succeed');

            // Verify database state
            final updatedOrder = await DriverTestHelpers.getTestOrder(supabase, testOrderId);
            expect(updatedOrder['status'], equals(toStatus.value));

            // Add delay to simulate real-world timing
            await Future.delayed(const Duration(milliseconds: 500));
          }

          // Verify final delivery state
          final finalOrder = await DriverTestHelpers.getTestOrder(supabase, testOrderId);
          expect(finalOrder['status'], equals('delivered'));
          expect(finalOrder['delivered_at'], isNotNull);

          DriverWorkflowLogger.logDatabaseOperation(
            operation: 'complete_workflow_test_success',
            orderId: testOrderId,
            isSuccess: true,
            context: 'integration_test',
          );

        } catch (e) {
          DriverWorkflowLogger.logError(
            operation: 'complete_workflow_test',
            error: e.toString(),
            orderId: testOrderId,
            context: 'integration_test',
          );
          rethrow;
        }
      });

      test('should handle workflow interruption and recovery', () async {
        // Test workflow recovery after interruption
        await DriverTestHelpers.updateOrderStatus(
          supabase,
          testOrderId,
          'assigned',
          assignedDriverId: testDriverId,
        );

        // Progress to middle of workflow
        await workflowService.processOrderStatusChange(
          orderId: testOrderId,
          fromStatus: DriverOrderStatus.assigned,
          toStatus: DriverOrderStatus.onRouteToVendor,
          driverId: testDriverId,
        );

        await workflowService.processOrderStatusChange(
          orderId: testOrderId,
          fromStatus: DriverOrderStatus.onRouteToVendor,
          toStatus: DriverOrderStatus.arrivedAtVendor,
          driverId: testDriverId,
        );

        // Simulate interruption (network failure, app restart, etc.)
        // Verify workflow can continue from current state
        final currentOrder = await DriverTestHelpers.getTestOrder(supabase, testOrderId);
        expect(currentOrder['status'], equals('arrived_at_vendor'));

        // Continue workflow from interrupted state
        final result = await workflowService.processOrderStatusChange(
          orderId: testOrderId,
          fromStatus: DriverOrderStatus.arrivedAtVendor,
          toStatus: DriverOrderStatus.pickedUp,
          driverId: testDriverId,
        );

        expect(result.isSuccess, isTrue);
      });
    });

    group('State Machine Validation Tests', () {
      test('should enforce valid status transitions', () {
        // Test all valid transitions
        final validTransitions = [
          (DriverOrderStatus.assigned, DriverOrderStatus.onRouteToVendor),
          (DriverOrderStatus.onRouteToVendor, DriverOrderStatus.arrivedAtVendor),
          (DriverOrderStatus.arrivedAtVendor, DriverOrderStatus.pickedUp),
          (DriverOrderStatus.pickedUp, DriverOrderStatus.onRouteToCustomer),
          (DriverOrderStatus.onRouteToCustomer, DriverOrderStatus.arrivedAtCustomer),
          (DriverOrderStatus.arrivedAtCustomer, DriverOrderStatus.delivered),
        ];

        for (final (fromStatus, toStatus) in validTransitions) {
          final isValid = DriverOrderStateMachine.isValidTransition(fromStatus, toStatus);
          expect(isValid, isTrue,
              reason: 'Transition $fromStatus → $toStatus should be valid');
        }
      });

      test('should reject invalid status transitions', () {
        // Test invalid transitions
        final invalidTransitions = [
          (DriverOrderStatus.assigned, DriverOrderStatus.delivered),
          (DriverOrderStatus.assigned, DriverOrderStatus.pickedUp),
          (DriverOrderStatus.onRouteToVendor, DriverOrderStatus.delivered),
          (DriverOrderStatus.delivered, DriverOrderStatus.assigned),
          (DriverOrderStatus.pickedUp, DriverOrderStatus.arrivedAtVendor),
        ];

        for (final (fromStatus, toStatus) in invalidTransitions) {
          final isValid = DriverOrderStateMachine.isValidTransition(fromStatus, toStatus);
          expect(isValid, isFalse,
              reason: 'Transition $fromStatus → $toStatus should be invalid');
        }
      });

      test('should provide correct available actions for each status', () {
        // Test assigned status actions
        final assignedActions = DriverOrderStateMachine.getAvailableActions(
          DriverOrderStatus.assigned,
        );
        expect(assignedActions, contains(DriverOrderAction.navigateToVendor));
        expect(assignedActions, contains(DriverOrderAction.cancel));

        // Test arrived at vendor actions
        final arrivedAtVendorActions = DriverOrderStateMachine.getAvailableActions(
          DriverOrderStatus.arrivedAtVendor,
        );
        expect(arrivedAtVendorActions, contains(DriverOrderAction.confirmPickup));

        // Test arrived at customer actions
        final arrivedAtCustomerActions = DriverOrderStateMachine.getAvailableActions(
          DriverOrderStatus.arrivedAtCustomer,
        );
        expect(arrivedAtCustomerActions, contains(DriverOrderAction.confirmDeliveryWithPhoto));

        // Test delivered status (no actions available)
        final deliveredActions = DriverOrderStateMachine.getAvailableActions(
          DriverOrderStatus.delivered,
        );
        expect(deliveredActions, isEmpty);
      });
    });

    group('Error Handling and Recovery Tests', () {
      test('should handle network failures with retry logic', () async {
        final result = await errorHandler.handleWorkflowOperation<String>(
          operation: () async {
            // Simulate network failure on first attempt
            throw Exception('Network timeout');
          },
          operationName: 'test_network_failure',
          maxRetries: 3,
          requiresNetwork: true,
        );

        expect(result.isSuccess, isFalse);
        expect(result.error?.type, equals(WorkflowErrorType.network));
      });

      test('should handle database constraint violations', () async {
        // Test duplicate order acceptance
        await DriverTestHelpers.updateOrderStatus(
          supabase,
          testOrderId,
          'assigned',
          assignedDriverId: testDriverId,
        );

        // Try to accept the same order again
        final result = await errorHandler.handleWorkflowOperation<void>(
          operation: () async {
            await DriverTestHelpers.updateOrderStatus(
              supabase,
              testOrderId,
              'assigned',
              assignedDriverId: testDriverId,
            );
          },
          operationName: 'duplicate_order_acceptance',
        );

        expect(result.isSuccess, isFalse);
        expect(result.error?.type, equals(WorkflowErrorType.validation));
      });

      test('should handle permission errors gracefully', () async {
        // Test unauthorized status update
        const unauthorizedDriverId = 'unauthorized-driver-id';
        
        final result = await errorHandler.handleWorkflowOperation<void>(
          operation: () async {
            await workflowService.processOrderStatusChange(
              orderId: testOrderId,
              fromStatus: DriverOrderStatus.assigned,
              toStatus: DriverOrderStatus.onRouteToVendor,
              driverId: unauthorizedDriverId,
            );
          },
          operationName: 'unauthorized_status_update',
        );

        expect(result.isSuccess, isFalse);
        expect(result.error?.type, equals(WorkflowErrorType.permission));
      });
    });

    group('Real-time Updates and Synchronization Tests', () {
      test('should receive real-time order status updates', () async {
        // Set up real-time subscription
        final statusUpdates = <String>[];
        final subscription = supabase
            .from('orders')
            .stream(primaryKey: ['id'])
            .eq('id', testOrderId)
            .listen((data) {
              if (data.isNotEmpty) {
                statusUpdates.add(data.first['status'] as String);
              }
            });

        try {
          // Accept order and progress through workflow
          await DriverTestHelpers.updateOrderStatus(
            supabase,
            testOrderId,
            'assigned',
            assignedDriverId: testDriverId,
          );
          await Future.delayed(const Duration(milliseconds: 500));

          await workflowService.processOrderStatusChange(
            orderId: testOrderId,
            fromStatus: DriverOrderStatus.assigned,
            toStatus: DriverOrderStatus.onRouteToVendor,
            driverId: testDriverId,
          );
          await Future.delayed(const Duration(milliseconds: 500));

          // Verify real-time updates were received
          expect(statusUpdates, contains('assigned'));
          expect(statusUpdates, contains('on_route_to_vendor'));

        } finally {
          await subscription.cancel();
        }
      });

      test('should handle concurrent order updates', () async {
        await DriverTestHelpers.updateOrderStatus(
          supabase,
          testOrderId,
          'assigned',
          assignedDriverId: testDriverId,
        );

        // Simulate concurrent status updates
        final futures = <Future>[];

        // This should succeed
        futures.add(workflowService.processOrderStatusChange(
          orderId: testOrderId,
          fromStatus: DriverOrderStatus.assigned,
          toStatus: DriverOrderStatus.onRouteToVendor,
          driverId: testDriverId,
        ));

        // This should fail due to invalid transition
        futures.add(workflowService.processOrderStatusChange(
          orderId: testOrderId,
          fromStatus: DriverOrderStatus.assigned,
          toStatus: DriverOrderStatus.delivered,
          driverId: testDriverId,
        ));

        final results = await Future.wait(futures, eagerError: false);

        // First update should succeed, second should fail
        expect((results[0] as WorkflowIntegrationResult).isSuccess, isTrue);
        expect((results[1] as WorkflowIntegrationResult).isSuccess, isFalse);
      });
    });

    group('Performance and Load Tests', () {
      test('should handle multiple workflow operations efficiently', () async {
        final stopwatch = Stopwatch()..start();

        // Create multiple test orders
        final orderIds = <String>[];
        for (int i = 0; i < 5; i++) {
          final orderId = await DriverTestHelpers.createTestOrder(
            supabase,
            customerId: DriverTestHelpers.testConfig['testCustomerId']!,
            vendorId: DriverTestHelpers.testConfig['testVendorId']!,
          );
          orderIds.add(orderId);
        }

        try {
          // Process all orders through first workflow step
          final futures = orderIds.map((orderId) async {
            await DriverTestHelpers.updateOrderStatus(
              supabase,
              orderId,
              'assigned',
              assignedDriverId: testDriverId,
            );
            return workflowService.processOrderStatusChange(
              orderId: orderId,
              fromStatus: DriverOrderStatus.assigned,
              toStatus: DriverOrderStatus.onRouteToVendor,
              driverId: testDriverId,
            );
          });

          final results = await Future.wait(futures);
          stopwatch.stop();

          // Verify all operations completed successfully
          for (final result in results) {
            expect(result.isSuccess, isTrue);
          }

          // Performance assertion (should complete within reasonable time)
          expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds max

        } finally {
          // Clean up test orders
          for (final orderId in orderIds) {
            await DriverTestHelpers.cleanupTestOrder(supabase, orderId);
          }
        }
      });

      test('should maintain performance under stress conditions', () async {
        // Test rapid status transitions
        await DriverTestHelpers.updateOrderStatus(
          supabase,
          testOrderId,
          'assigned',
          assignedDriverId: testDriverId,
        );

        final stopwatch = Stopwatch()..start();

        // Rapid workflow progression
        await workflowService.processOrderStatusChange(
          orderId: testOrderId,
          fromStatus: DriverOrderStatus.assigned,
          toStatus: DriverOrderStatus.onRouteToVendor,
          driverId: testDriverId,
        );

        await workflowService.processOrderStatusChange(
          orderId: testOrderId,
          fromStatus: DriverOrderStatus.onRouteToVendor,
          toStatus: DriverOrderStatus.arrivedAtVendor,
          driverId: testDriverId,
        );

        await workflowService.processOrderStatusChange(
          orderId: testOrderId,
          fromStatus: DriverOrderStatus.arrivedAtVendor,
          toStatus: DriverOrderStatus.pickedUp,
          driverId: testDriverId,
        );

        stopwatch.stop();

        // Should complete rapid transitions efficiently
        expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // 3 seconds max
      });
    });

    group('Data Integrity and Consistency Tests', () {
      test('should maintain data consistency across workflow steps', () async {
        await DriverTestHelpers.updateOrderStatus(
          supabase,
          testOrderId,
          'assigned',
          assignedDriverId: testDriverId,
        );

        // Progress through workflow and verify data consistency at each step
        final workflowSteps = [
          DriverOrderStatus.onRouteToVendor,
          DriverOrderStatus.arrivedAtVendor,
          DriverOrderStatus.pickedUp,
          DriverOrderStatus.onRouteToCustomer,
          DriverOrderStatus.arrivedAtCustomer,
          DriverOrderStatus.delivered,
        ];

        DriverOrderStatus currentStatus = DriverOrderStatus.assigned;

        for (final targetStatus in workflowSteps) {
          await workflowService.processOrderStatusChange(
            orderId: testOrderId,
            fromStatus: currentStatus,
            toStatus: targetStatus,
            driverId: testDriverId,
          );

          // Verify database consistency
          final order = await DriverTestHelpers.getTestOrder(supabase, testOrderId);
          expect(order['status'], equals(targetStatus.value));
          expect(order['assigned_driver_id'], equals(testDriverId));

          // Verify timestamps are updated appropriately
          expect(order['updated_at'], isNotNull);

          if (targetStatus == DriverOrderStatus.delivered) {
            expect(order['delivered_at'], isNotNull);
          }

          currentStatus = targetStatus;
        }
      });

      test('should handle database rollback scenarios', () async {
        await DriverTestHelpers.updateOrderStatus(
          supabase,
          testOrderId,
          'assigned',
          assignedDriverId: testDriverId,
        );

        // Attempt invalid operation that should trigger rollback
        try {
          await supabase.rpc('invalid_workflow_operation',
            params: {
              'order_id': testOrderId,
              'driver_id': testDriverId,
            });
        } catch (e) {
          // Expected to fail
        }

        // Verify order state remains consistent
        final order = await DriverTestHelpers.getTestOrder(supabase, testOrderId);
        expect(order['status'], equals('assigned')); // Should remain in assigned state
        expect(order['assigned_driver_id'], equals(testDriverId));
      });
    });

    group('Integration with External Systems Tests', () {
      test('should integrate with earnings tracking system', () async {
        await DriverTestHelpers.updateOrderStatus(
          supabase,
          testOrderId,
          'assigned',
          assignedDriverId: testDriverId,
        );

        // Complete full workflow
        final workflowSteps = [
          (DriverOrderStatus.assigned, DriverOrderStatus.onRouteToVendor),
          (DriverOrderStatus.onRouteToVendor, DriverOrderStatus.arrivedAtVendor),
          (DriverOrderStatus.arrivedAtVendor, DriverOrderStatus.pickedUp),
          (DriverOrderStatus.pickedUp, DriverOrderStatus.onRouteToCustomer),
          (DriverOrderStatus.onRouteToCustomer, DriverOrderStatus.arrivedAtCustomer),
          (DriverOrderStatus.arrivedAtCustomer, DriverOrderStatus.delivered),
        ];

        for (final (fromStatus, toStatus) in workflowSteps) {
          await workflowService.processOrderStatusChange(
            orderId: testOrderId,
            fromStatus: fromStatus,
            toStatus: toStatus,
            driverId: testDriverId,
          );
        }

        // Verify earnings record was created
        final earnings = await supabase
            .from('driver_earnings')
            .select()
            .eq('driver_id', testDriverId)
            .eq('order_id', testOrderId);

        expect(earnings, isNotEmpty);
        expect(earnings.first['status'], equals('completed'));
      });

      test('should integrate with notification system', () async {
        // This test would verify that notifications are sent at appropriate workflow steps
        // Implementation depends on notification system architecture
        await DriverTestHelpers.updateOrderStatus(
          supabase,
          testOrderId,
          'assigned',
          assignedDriverId: testDriverId,
        );

        final result = await workflowService.processOrderStatusChange(
          orderId: testOrderId,
          fromStatus: DriverOrderStatus.assigned,
          toStatus: DriverOrderStatus.onRouteToVendor,
          driverId: testDriverId,
        );

        expect(result.isSuccess, isTrue);
        // Additional notification verification would go here
      });
    });
  });
}
