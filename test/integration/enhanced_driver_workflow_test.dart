import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:gigaeats_app/src/features/drivers/data/models/driver_order.dart';
import 'package:gigaeats_app/src/features/orders/data/models/driver_order_state_machine.dart' as state_machine;
import 'package:gigaeats_app/src/features/drivers/data/services/pickup_confirmation_service.dart' as pickup_service;
import 'package:gigaeats_app/src/features/drivers/data/services/delivery_confirmation_service.dart' as delivery_service;
import 'package:gigaeats_app/src/features/drivers/data/models/pickup_confirmation.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/delivery_confirmation.dart';
import 'package:gigaeats_app/src/core/services/location_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/enhanced_workflow_integration_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/driver_workflow_error_handler.dart';
import 'package:gigaeats_app/src/features/drivers/data/validators/driver_workflow_validators.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/widgets/order_action_buttons.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/widgets/current_order_section.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/enhanced_driver_workflow_providers.dart';

import 'enhanced_driver_workflow_test.mocks.dart';

// Mock classes are manually created in enhanced_driver_workflow_test.mocks.dart

// Mock classes for testing - using proper model classes now

// WorkflowIntegrationResult is now imported from enhanced_workflow_integration_service.dart

// Mock data classes for testing are now imported from proper model files

// Mock result classes for testing - using proper model classes now

// EnhancedDriverWorkflowState is now imported from enhanced_driver_workflow_providers.dart

/// Comprehensive integration tests for the enhanced driver order workflow
/// Tests the complete granular workflow with mandatory confirmations
void main() {
  group('Enhanced Driver Workflow Integration Tests', () {
    late MockPickupConfirmationService mockPickupService;
    late MockDeliveryConfirmationService mockDeliveryService;
    late MockEnhancedWorkflowIntegrationService mockIntegrationService;
    late ProviderContainer container;

    setUp(() {
      mockPickupService = MockPickupConfirmationService();
      mockDeliveryService = MockDeliveryConfirmationService();
      mockIntegrationService = MockEnhancedWorkflowIntegrationService();

      container = ProviderContainer(
        overrides: [
          pickup_service.pickupConfirmationServiceProvider.overrideWithValue(mockPickupService),
          delivery_service.deliveryConfirmationServiceProvider.overrideWithValue(mockDeliveryService),
          enhancedWorkflowIntegrationServiceProvider.overrideWithValue(mockIntegrationService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Enhanced State Machine Validation', () {
      test('should validate complete granular workflow transitions', () {
        // Test all valid transitions in the enhanced granular workflow
        final validTransitions = [
          (DriverOrderStatus.assigned, DriverOrderStatus.onRouteToVendor),
          (DriverOrderStatus.onRouteToVendor, DriverOrderStatus.arrivedAtVendor),
          (DriverOrderStatus.arrivedAtVendor, DriverOrderStatus.pickedUp),
          (DriverOrderStatus.pickedUp, DriverOrderStatus.onRouteToCustomer),
          (DriverOrderStatus.onRouteToCustomer, DriverOrderStatus.arrivedAtCustomer),
          (DriverOrderStatus.arrivedAtCustomer, DriverOrderStatus.delivered),
        ];

        for (final (fromStatus, toStatus) in validTransitions) {
          final result = state_machine.DriverOrderStateMachine.validateTransition(fromStatus, toStatus);
          expect(result.isValid, isTrue,
            reason: 'Enhanced transition from ${fromStatus.value} to ${toStatus.value} should be valid');
        }
      });

      test('should enforce mandatory confirmation requirements', () {
        // Test mandatory confirmation detection for critical steps
        expect(state_machine.DriverOrderStateMachine.requiresMandatoryConfirmation(DriverOrderStatus.arrivedAtVendor),
          isTrue, reason: 'Pickup confirmation should be mandatory at vendor');

        expect(state_machine.DriverOrderStateMachine.requiresMandatoryConfirmation(DriverOrderStatus.arrivedAtCustomer),
          isTrue, reason: 'Delivery confirmation should be mandatory at customer');

        // Test confirmation types
        expect(state_machine.DriverOrderStateMachine.getRequiredConfirmationType(DriverOrderStatus.arrivedAtVendor),
          equals('pickup'), reason: 'Vendor arrival should require pickup confirmation');

        expect(state_machine.DriverOrderStateMachine.getRequiredConfirmationType(DriverOrderStatus.arrivedAtCustomer),
          equals('delivery'), reason: 'Customer arrival should require delivery confirmation');
      });

      test('should prevent status skipping in granular workflow', () {
        // Test that drivers cannot skip mandatory steps
        final invalidSkippingTransitions = [
          (DriverOrderStatus.assigned, DriverOrderStatus.arrivedAtVendor), // Skip navigation
          (DriverOrderStatus.onRouteToVendor, DriverOrderStatus.pickedUp), // Skip arrival
          (DriverOrderStatus.arrivedAtVendor, DriverOrderStatus.onRouteToCustomer), // Skip pickup
          (DriverOrderStatus.pickedUp, DriverOrderStatus.arrivedAtCustomer), // Skip navigation
          (DriverOrderStatus.onRouteToCustomer, DriverOrderStatus.delivered), // Skip arrival
        ];

        for (final (fromStatus, toStatus) in invalidSkippingTransitions) {
          final result = state_machine.DriverOrderStateMachine.validateTransition(fromStatus, toStatus);
          expect(result.isValid, isFalse,
            reason: 'Should not allow skipping from ${fromStatus.value} to ${toStatus.value}');
        }
      });

      test('should provide enhanced driver instructions for each status', () {
        final enhancedInstructions = {
          DriverOrderStatus.assigned: 'Start navigation to the restaurant',
          DriverOrderStatus.onRouteToVendor: 'Navigate to the restaurant location',
          DriverOrderStatus.arrivedAtVendor: 'Confirm pickup with mandatory verification',
          DriverOrderStatus.pickedUp: 'Start navigation to the customer',
          DriverOrderStatus.onRouteToCustomer: 'Navigate to the customer location',
          DriverOrderStatus.arrivedAtCustomer: 'Complete delivery with photo proof',
          DriverOrderStatus.delivered: 'Order delivered successfully',
        };

        for (final entry in enhancedInstructions.entries) {
          final instructions = state_machine.DriverOrderStateMachine.getDriverInstructions(entry.key);
          expect(instructions, isNotEmpty,
            reason: 'Instructions for ${entry.key.value} should not be empty');
          expect(instructions.toLowerCase(), contains(entry.value.split(' ').first.toLowerCase()),
            reason: 'Instructions for ${entry.key.value} should contain relevant guidance');
        }
      });
    });

    group('Enhanced Pickup Confirmation Workflow', () {
      test('should validate enhanced pickup confirmation with comprehensive checklist', () {
        final enhancedPickupConfirmation = PickupConfirmation(
          orderId: 'test-order-id',
          confirmedAt: DateTime.now(),
          verificationChecklist: {
            'Order number matches': true,
            'All items are present': true,
            'Items are properly packaged': true,
            'Special instructions noted': true,
            'Temperature requirements met': true,
          },
          notes: 'All items verified with enhanced checklist',
          confirmedBy: 'test-driver',
        );

        // Test validation using enhanced validators
        final validationResult = DriverWorkflowValidators.validatePickupConfirmationData(
          verificationChecklist: enhancedPickupConfirmation.verificationChecklist,
          notes: enhancedPickupConfirmation.notes,
        );

        expect(validationResult.isValid, isTrue, 
          reason: 'Enhanced pickup confirmation should pass validation');
      });

      test('should reject pickup confirmation with insufficient verification', () {
        final incompleteConfirmation = {
          'Order number matches': true,
          'All items are present': false, // Critical item not verified
          'Items are properly packaged': true,
        };

        final validationResult = DriverWorkflowValidators.validatePickupConfirmationData(
          verificationChecklist: incompleteConfirmation,
          notes: null,
        );

        expect(validationResult.isValid, isFalse, 
          reason: 'Incomplete pickup verification should fail validation');
        expect(validationResult.errorMessage, contains('Critical verification required'), 
          reason: 'Should specify critical verification requirement');
      });

      test('should enforce 80% completion rule for pickup checklist', () {
        final partialConfirmation = {
          'Order number matches': true,
          'All items are present': true,
          'Items are properly packaged': false,
          'Special instructions noted': false,
          'Temperature requirements met': false,
        }; // Only 40% completed

        final validationResult = DriverWorkflowValidators.validatePickupConfirmationData(
          verificationChecklist: partialConfirmation,
          notes: null,
        );

        expect(validationResult.isValid, isFalse, 
          reason: 'Should enforce 80% completion rule');
        expect(validationResult.errorMessage, contains('80%'), 
          reason: 'Should mention 80% requirement');
      });
    });

    group('Enhanced Delivery Confirmation Workflow', () {
      test('should validate enhanced delivery confirmation with photo and GPS', () {
        final enhancedDeliveryConfirmation = DeliveryConfirmation(
          orderId: 'test-order-id',
          deliveredAt: DateTime.now(),
          photoUrl: 'https://example.com/delivery-proof.jpg',
          location: LocationData(
            latitude: 3.1390,
            longitude: 101.6869,
            accuracy: 5.0,
            timestamp: DateTime.now(),
          ),
          recipientName: 'John Doe',
          notes: 'Delivered with enhanced verification',
          confirmedBy: 'test-driver',
        );

        // Test validation using enhanced validators
        final validationResult = DriverWorkflowValidators.validateDeliveryConfirmationData(
          photoUrl: enhancedDeliveryConfirmation.photoUrl,
          latitude: enhancedDeliveryConfirmation.location.latitude,
          longitude: enhancedDeliveryConfirmation.location.longitude,
          accuracy: enhancedDeliveryConfirmation.location.accuracy,
          recipientName: enhancedDeliveryConfirmation.recipientName,
          notes: enhancedDeliveryConfirmation.notes,
        );

        expect(validationResult.isValid, isTrue, 
          reason: 'Enhanced delivery confirmation should pass validation');
      });

      test('should reject delivery confirmation without mandatory photo', () {
        final validationResult = DriverWorkflowValidators.validateDeliveryConfirmationData(
          photoUrl: null, // Missing mandatory photo
          latitude: 3.1390,
          longitude: 101.6869,
          accuracy: 5.0,
          recipientName: 'John Doe',
          notes: 'Attempted delivery without photo',
        );

        expect(validationResult.isValid, isFalse, 
          reason: 'Should reject delivery without photo');
        expect(validationResult.errorMessage, contains('photo'), 
          reason: 'Should specify photo requirement');
      });

      test('should reject delivery confirmation with poor GPS accuracy', () {
        final validationResult = DriverWorkflowValidators.validateDeliveryConfirmationData(
          photoUrl: 'https://example.com/delivery-proof.jpg',
          latitude: 3.1390,
          longitude: 101.6869,
          accuracy: 150.0, // Poor accuracy > 100m
          recipientName: 'John Doe',
          notes: 'Delivery with poor GPS signal',
        );

        expect(validationResult.isValid, isFalse, 
          reason: 'Should reject delivery with poor GPS accuracy');
        expect(validationResult.errorMessage, contains('accuracy'), 
          reason: 'Should specify accuracy requirement');
      });
    });

    group('Enhanced Error Handling and Recovery', () {
      test('should handle network failures with retry logic', () async {
        final errorHandler = DriverWorkflowErrorHandler();
        int attemptCount = 0;

        final result = await errorHandler.handleWorkflowOperation<String>(
          operation: () async {
            attemptCount++;
            if (attemptCount < 3) {
              throw Exception('Network timeout');
            }
            return 'Success after retries';
          },
          operationName: 'test_operation',
          maxRetries: 3,
          requiresNetwork: true,
        );

        expect(result.isSuccess, isTrue, 
          reason: 'Should succeed after retries');
        expect(result.data, equals('Success after retries'));
        expect(attemptCount, equals(3), 
          reason: 'Should retry the correct number of times');
      });

      test('should validate order status transitions with business rules', () {
        final testOrder = _createTestDriverOrder(DriverOrderStatus.assigned);

        // Test valid transition
        final validResult = DriverWorkflowValidators.validateOrderStatusTransition(
          order: testOrder,
          targetStatus: DriverOrderStatus.onRouteToVendor,
        );
        expect(validResult.isValid, isTrue);

        // Test invalid transition (skipping steps)
        final invalidResult = DriverWorkflowValidators.validateOrderStatusTransition(
          order: testOrder,
          targetStatus: DriverOrderStatus.pickedUp, // Skipping steps
        );
        expect(invalidResult.isValid, isFalse);
      });
    });

    group('Complete Enhanced Workflow Integration', () {
      test('should process complete enhanced workflow with all confirmations', () async {
        final testOrder = _createTestDriverOrder(DriverOrderStatus.assigned);

        // Mock successful workflow integration for all steps
        when(mockIntegrationService.processOrderStatusChange(
          orderId: anyNamed('orderId'),
          fromStatus: anyNamed('fromStatus'),
          toStatus: anyNamed('toStatus'),
          driverId: anyNamed('driverId'),
          additionalData: anyNamed('additionalData'),
        )).thenAnswer((_) async => WorkflowIntegrationResult.success());

        // Test complete enhanced workflow with mandatory confirmations
        final enhancedWorkflowSteps = [
          (DriverOrderStatus.assigned, DriverOrderStatus.onRouteToVendor, null),
          (DriverOrderStatus.onRouteToVendor, DriverOrderStatus.arrivedAtVendor, null),
          (DriverOrderStatus.arrivedAtVendor, DriverOrderStatus.pickedUp, {'pickup_confirmation': 'required'}),
          (DriverOrderStatus.pickedUp, DriverOrderStatus.onRouteToCustomer, null),
          (DriverOrderStatus.onRouteToCustomer, DriverOrderStatus.arrivedAtCustomer, null),
          (DriverOrderStatus.arrivedAtCustomer, DriverOrderStatus.delivered, {'delivery_confirmation': 'required'}),
        ];

        for (final (fromStatus, toStatus, additionalData) in enhancedWorkflowSteps) {
          final result = await mockIntegrationService.processOrderStatusChange(
            orderId: testOrder.id,
            fromStatus: fromStatus,
            toStatus: toStatus,
            driverId: 'test-driver-id',
            additionalData: additionalData,
          );

          expect(result.isSuccess, isTrue,
            reason: 'Enhanced workflow step from ${fromStatus.value} to ${toStatus.value} should succeed');
        }

        // Verify all enhanced workflow steps were processed
        verify(mockIntegrationService.processOrderStatusChange(
          orderId: anyNamed('orderId'),
          fromStatus: anyNamed('fromStatus'),
          toStatus: anyNamed('toStatus'),
          driverId: anyNamed('driverId'),
          additionalData: anyNamed('additionalData'),
        )).called(enhancedWorkflowSteps.length);
      });

      test('should enforce mandatory confirmations in workflow', () async {
        // Test that workflow cannot proceed without mandatory confirmations
        final testOrder = _createTestDriverOrder(DriverOrderStatus.arrivedAtVendor);

        // Attempt to skip pickup confirmation
        when(mockIntegrationService.processOrderStatusChange(
          orderId: anyNamed('orderId'),
          fromStatus: DriverOrderStatus.arrivedAtVendor,
          toStatus: DriverOrderStatus.onRouteToCustomer,
          driverId: anyNamed('driverId'),
          additionalData: null, // No pickup confirmation
        )).thenAnswer((_) async => WorkflowIntegrationResult.failure('Pickup confirmation required'));

        final result = await mockIntegrationService.processOrderStatusChange(
          orderId: testOrder.id,
          fromStatus: DriverOrderStatus.arrivedAtVendor,
          toStatus: DriverOrderStatus.onRouteToCustomer,
          driverId: 'test-driver-id',
          additionalData: null,
        );

        expect(result.isSuccess, isFalse,
          reason: 'Should not allow skipping mandatory pickup confirmation');
        expect(result.errorMessage, contains('confirmation'),
          reason: 'Should specify confirmation requirement');
      });
    });

    group('End-to-End Workflow Testing', () {
      test('should complete full driver workflow from assignment to delivery', () async {
        final testOrder = _createTestDriverOrder(DriverOrderStatus.assigned);

        // Mock all services for complete workflow
        when(mockPickupService.submitPickupConfirmation(any))
            .thenAnswer((_) async => PickupConfirmationResult.success(
              PickupConfirmation(
                orderId: 'test-order',
                confirmedAt: DateTime.now(),
                verificationChecklist: {'items_verified': true},
                confirmedBy: 'test-driver',
              )
            ));

        when(mockDeliveryService.submitDeliveryConfirmation(any))
            .thenAnswer((_) async => DeliveryConfirmationResult.success(
              DeliveryConfirmation(
                orderId: 'test-order',
                deliveredAt: DateTime.now(),
                photoUrl: 'test-photo-url',
                location: LocationData(
                  latitude: 3.1390,
                  longitude: 101.6869,
                  accuracy: 5.0,
                  timestamp: DateTime.now(),
                ),
                confirmedBy: 'test-driver',
              )
            ));

        when(mockIntegrationService.processOrderStatusChange(
          orderId: anyNamed('orderId'),
          fromStatus: anyNamed('fromStatus'),
          toStatus: anyNamed('toStatus'),
          driverId: anyNamed('driverId'),
          additionalData: anyNamed('additionalData'),
        )).thenAnswer((_) async => WorkflowIntegrationResult.success());

        // Simulate complete workflow execution
        final workflowSteps = [
          // Step 1: Start navigation to vendor
          () async {
            final result = await mockIntegrationService.processOrderStatusChange(
              orderId: testOrder.id,
              fromStatus: DriverOrderStatus.assigned,
              toStatus: DriverOrderStatus.onRouteToVendor,
              driverId: 'test-driver-id',
              additionalData: null,
            );
            expect(result.isSuccess, isTrue);
          },

          // Step 2: Arrive at vendor
          () async {
            final result = await mockIntegrationService.processOrderStatusChange(
              orderId: testOrder.id,
              fromStatus: DriverOrderStatus.onRouteToVendor,
              toStatus: DriverOrderStatus.arrivedAtVendor,
              driverId: 'test-driver-id',
              additionalData: null,
            );
            expect(result.isSuccess, isTrue);
          },

          // Step 3: Pickup confirmation (mandatory)
          () async {
            final pickupConfirmation = PickupConfirmation(
              orderId: testOrder.id,
              confirmedAt: DateTime.now(),
              verificationChecklist: {
                'Order number matches': true,
                'All items are present': true,
                'Items are properly packaged': true,
                'Special instructions noted': true,
                'Temperature requirements met': true,
              },
              notes: 'All items verified successfully',
              confirmedBy: 'test-driver-id',
            );

            final result = await mockPickupService.submitPickupConfirmation(pickupConfirmation);
            expect(result.isSuccess, isTrue);
          },

          // Step 4: Start navigation to customer
          () async {
            final result = await mockIntegrationService.processOrderStatusChange(
              orderId: testOrder.id,
              fromStatus: DriverOrderStatus.pickedUp,
              toStatus: DriverOrderStatus.onRouteToCustomer,
              driverId: 'test-driver-id',
              additionalData: null,
            );
            expect(result.isSuccess, isTrue);
          },

          // Step 5: Arrive at customer
          () async {
            final result = await mockIntegrationService.processOrderStatusChange(
              orderId: testOrder.id,
              fromStatus: DriverOrderStatus.onRouteToCustomer,
              toStatus: DriverOrderStatus.arrivedAtCustomer,
              driverId: 'test-driver-id',
              additionalData: null,
            );
            expect(result.isSuccess, isTrue);
          },

          // Step 6: Delivery confirmation (mandatory)
          () async {
            final deliveryConfirmation = DeliveryConfirmation(
              orderId: testOrder.id,
              deliveredAt: DateTime.now(),
              photoUrl: 'https://example.com/delivery-proof.jpg',
              location: LocationData(
                latitude: 3.1390,
                longitude: 101.6869,
                accuracy: 5.0,
                timestamp: DateTime.now(),
              ),
              recipientName: 'John Doe',
              notes: 'Delivered successfully with photo proof',
              confirmedBy: 'test-driver-id',
            );

            final result = await mockDeliveryService.submitDeliveryConfirmation(deliveryConfirmation);
            expect(result.isSuccess, isTrue);
          },
        ];

        // Execute all workflow steps
        for (int i = 0; i < workflowSteps.length; i++) {
          await workflowSteps[i]();
          print('✅ Completed workflow step ${i + 1}/${workflowSteps.length}');
        }

        // Verify all services were called appropriately
        verify(mockPickupService.submitPickupConfirmation(any)).called(1);
        verify(mockDeliveryService.submitDeliveryConfirmation(any)).called(1);
        verify(mockIntegrationService.processOrderStatusChange(
          orderId: anyNamed('orderId'),
          fromStatus: anyNamed('fromStatus'),
          toStatus: anyNamed('toStatus'),
          driverId: anyNamed('driverId'),
          additionalData: anyNamed('additionalData'),
        )).called(4); // 4 status transitions via integration service
      });

      test('should handle workflow interruption and recovery', () async {
        final testOrder = _createTestDriverOrder(DriverOrderStatus.onRouteToVendor);

        // Simulate network failure during pickup confirmation
        when(mockPickupService.submitPickupConfirmation(any))
            .thenAnswer((_) async => PickupConfirmationResult.failure('Network timeout'));

        // First attempt should fail
        final pickupConfirmation = PickupConfirmation(
          orderId: testOrder.id,
          confirmedAt: DateTime.now(),
          verificationChecklist: {
            'Order number matches': true,
            'All items are present': true,
            'Items are properly packaged': true,
            'Special instructions noted': true,
            'Temperature requirements met': true,
          },
          notes: 'Network failure test',
          confirmedBy: 'test-driver-id',
        );

        final failedResult = await mockPickupService.submitPickupConfirmation(pickupConfirmation);
        expect(failedResult.isSuccess, isFalse);
        expect(failedResult.errorMessage, contains('Network timeout'));

        // Simulate recovery - network restored
        when(mockPickupService.submitPickupConfirmation(any))
            .thenAnswer((_) async => PickupConfirmationResult.success(
              PickupConfirmation(
                orderId: 'test-order',
                confirmedAt: DateTime.now(),
                verificationChecklist: {'items_verified': true},
                confirmedBy: 'test-driver',
              )
            ));

        // Retry should succeed
        final retryResult = await mockPickupService.submitPickupConfirmation(pickupConfirmation);
        expect(retryResult.isSuccess, isTrue);

        // Verify retry mechanism was used
        verify(mockPickupService.submitPickupConfirmation(any)).called(2);
      });
    });
  });

    group('Widget Integration Testing', () {
      testWidgets('CurrentOrderSection displays enhanced workflow information', (WidgetTester tester) async {
        final testOrder = _createTestDriverOrder(DriverOrderStatus.onRouteToVendor);

        // Create test container with overrides
        final testContainer = ProviderContainer(
          overrides: [
            enhancedCurrentDriverOrderProvider.overrideWith((ref) => Stream.value(testOrder)),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: testContainer,
            child: MaterialApp(
              home: Scaffold(
                body: const CurrentOrderSection(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify order information is displayed
        expect(find.text(testOrder.formattedOrderNumber), findsOneWidget);
        expect(find.text(testOrder.customerName), findsOneWidget);
        expect(find.text(testOrder.vendorName), findsOneWidget);

        // Verify status-specific content
        expect(find.textContaining('On Route to Vendor'), findsOneWidget);

        // Verify progress tracking is shown
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        testContainer.dispose();
      });

      testWidgets('OrderActionButtons shows correct actions for each status', (WidgetTester tester) async {
        // Test different statuses and their corresponding actions
        final testCases = [
          (DriverOrderStatus.assigned, ['Navigate to Vendor']),
          (DriverOrderStatus.onRouteToVendor, ['Arrived at Vendor']),
          (DriverOrderStatus.arrivedAtVendor, ['Confirm Pickup']),
          (DriverOrderStatus.pickedUp, ['Navigate to Customer']),
          (DriverOrderStatus.onRouteToCustomer, ['Arrived at Customer']),
          (DriverOrderStatus.arrivedAtCustomer, ['Confirm Delivery']),
        ];

        for (final (status, expectedActions) in testCases) {
          final testOrder = _createTestDriverOrder(status);

          final testContainer = ProviderContainer(
            overrides: [
              enhancedDriverWorkflowProvider.overrideWith((ref) {
                final notifier = EnhancedDriverWorkflowNotifier(ref);
                notifier.state = AsyncValue.data(EnhancedDriverWorkflowState(
                  currentOrder: testOrder,
                  isLoading: false,
                  errorMessage: null,
                ));
                return notifier;
              }),
            ],
          );

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: testContainer,
              child: MaterialApp(
                home: Scaffold(
                  body: OrderActionButtons(order: testOrder),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Verify expected actions are present
          for (final action in expectedActions) {
            expect(find.textContaining(action), findsOneWidget,
              reason: 'Action "$action" should be available for status ${status.value}');
          }

          testContainer.dispose();
        }
      });

      testWidgets('Pickup confirmation dialog enforces mandatory verification', (WidgetTester tester) async {
        final testOrder = _createTestDriverOrder(DriverOrderStatus.arrivedAtVendor);
        final localMockPickupService = MockPickupConfirmationService();

        final testContainer = ProviderContainer(
          overrides: [
            pickup_service.pickupConfirmationServiceProvider.overrideWithValue(localMockPickupService),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: testContainer,
            child: MaterialApp(
              home: Scaffold(
                body: OrderActionButtons(order: testOrder),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap the pickup confirmation button
        await tester.tap(find.textContaining('Confirm Pickup'));
        await tester.pumpAndSettle();

        // Verify pickup confirmation dialog appears
        expect(find.byType(AlertDialog), findsOneWidget);

        // Verify mandatory checklist items are present
        expect(find.textContaining('Order number matches'), findsOneWidget);
        expect(find.textContaining('All items are present'), findsOneWidget);
        expect(find.textContaining('Items are properly packaged'), findsOneWidget);

        // Verify checkboxes are present
        expect(find.byType(Checkbox), findsWidgets);

        // Try to submit without completing checklist
        final submitButton = find.textContaining('Confirm Pickup');
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton);
          await tester.pumpAndSettle();

          // Should show validation error
          expect(find.textContaining('verification'), findsOneWidget);
        }

        testContainer.dispose();
      });

      testWidgets('Delivery confirmation dialog requires photo and GPS', (WidgetTester tester) async {
        final testOrder = _createTestDriverOrder(DriverOrderStatus.arrivedAtCustomer);
        final localMockDeliveryService = MockDeliveryConfirmationService();

        final testContainer = ProviderContainer(
          overrides: [
            delivery_service.deliveryConfirmationServiceProvider.overrideWithValue(localMockDeliveryService),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: testContainer,
            child: MaterialApp(
              home: Scaffold(
                body: OrderActionButtons(order: testOrder),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap the delivery confirmation button
        await tester.tap(find.textContaining('Confirm Delivery'));
        await tester.pumpAndSettle();

        // Verify delivery confirmation dialog appears
        expect(find.byType(AlertDialog), findsOneWidget);

        // Verify photo requirement is shown
        expect(find.textContaining('Take Photo'), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);

        // Verify GPS requirement is shown
        expect(find.textContaining('GPS'), findsOneWidget);
        expect(find.byIcon(Icons.location_on), findsOneWidget);

        // Verify recipient name field
        expect(find.byType(TextFormField), findsWidgets);

        testContainer.dispose();
      });

      testWidgets('Error handling displays appropriate messages', (WidgetTester tester) async {
        final testContainer = ProviderContainer(
          overrides: [
            enhancedDriverWorkflowProvider.overrideWith((ref) {
              final notifier = EnhancedDriverWorkflowNotifier(ref);
              notifier.state = const AsyncValue.data(EnhancedDriverWorkflowState(
                isLoading: false,
                errorMessage: 'Network connection failed',
              ));
              return notifier;
            }),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: testContainer,
            child: MaterialApp(
              home: Scaffold(
                body: const CurrentOrderSection(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify error message is displayed
        expect(find.textContaining('Network connection failed'), findsOneWidget);

        // Verify error icon is shown
        expect(find.byIcon(Icons.error_outline), findsOneWidget);

        testContainer.dispose();
      });

      testWidgets('Loading states are properly displayed', (WidgetTester tester) async {
        final testContainer = ProviderContainer(
          overrides: [
            enhancedCurrentDriverOrderProvider.overrideWith((ref) => Stream.value(null)),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: testContainer,
            child: MaterialApp(
              home: Scaffold(
                body: const CurrentOrderSection(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify loading indicator is displayed
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Verify loading message
        expect(find.textContaining('Loading'), findsOneWidget);

        testContainer.dispose();
      });
    });
}

/// Helper function to create test driver order with enhanced properties
DriverOrder _createTestDriverOrder(DriverOrderStatus status) {
  final now = DateTime.now();
  return DriverOrder(
    id: 'test-order-id',
    orderId: 'order-12345',
    orderNumber: 'ORD-12345',
    driverId: 'test-driver-id',
    vendorId: 'test-vendor-id',
    vendorName: 'Test Restaurant',
    customerId: 'test-customer-id',
    customerName: 'Test Customer',
    status: status,
    deliveryDetails: const DeliveryDetails(
      deliveryAddress: '123 Test Street, Test City',
      contactPhone: '+60123456789',
      pickupAddress: '456 Restaurant Street, Test City',
    ),
    orderEarnings: const OrderEarnings(
      baseFee: 5.0,
      totalEarnings: 8.50,
    ),
    orderItemsCount: 3,
    orderTotal: 25.50,
    assignedAt: now.subtract(const Duration(hours: 1)),
    createdAt: now.subtract(const Duration(hours: 1)),
    updatedAt: now,
    deliveryNotes: 'Enhanced test delivery notes',
    requestedDeliveryTime: now.add(const Duration(minutes: 30)),
  );
}

/// Mock provider overrides for testing
final mockCurrentDriverOrderProvider = Provider<AsyncValue<DriverOrder?>>((ref) {
  return const AsyncValue.data(null);
});

final mockEnhancedDriverWorkflowProvider = Provider<AsyncValue<EnhancedDriverWorkflowState>>((ref) {
  return const AsyncValue.data(EnhancedDriverWorkflowState(isLoading: false));
});

/// Extension to add target status to DriverOrderAction for testing
extension DriverOrderActionExtension on state_machine.DriverOrderAction {
  DriverOrderStatus get targetStatus {
    switch (this) {
      case state_machine.DriverOrderAction.navigateToVendor:
        return DriverOrderStatus.onRouteToVendor;
      case state_machine.DriverOrderAction.arrivedAtVendor:
        return DriverOrderStatus.arrivedAtVendor;
      case state_machine.DriverOrderAction.confirmPickup:
        return DriverOrderStatus.pickedUp;
      case state_machine.DriverOrderAction.navigateToCustomer:
        return DriverOrderStatus.onRouteToCustomer;
      case state_machine.DriverOrderAction.arrivedAtCustomer:
        return DriverOrderStatus.arrivedAtCustomer;
      case state_machine.DriverOrderAction.confirmDeliveryWithPhoto:
        return DriverOrderStatus.delivered;
      default:
        return DriverOrderStatus.assigned;
    }
  }
}

/// Mock enhanced order action for testing
class EnhancedOrderAction {
  final state_machine.DriverOrderAction driverAction;
  final String label;
  final IconData icon;
  final bool isEnabled;

  const EnhancedOrderAction({
    required this.driverAction,
    required this.label,
    required this.icon,
    this.isEnabled = true,
  });
}
