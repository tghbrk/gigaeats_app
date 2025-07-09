import 'package:flutter_test/flutter_test.dart';
import 'package:gigaeats_app/src/features/orders/data/models/driver_order.dart' as OrderModels;
import 'package:gigaeats_app/src/features/drivers/data/models/driver_order.dart';
import 'package:gigaeats_app/src/features/orders/data/models/driver_order_state_machine.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/pickup_confirmation.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/delivery_confirmation.dart';
import 'package:gigaeats_app/src/core/services/location_service.dart';

/// Unit tests for the enhanced driver workflow components
/// Tests core logic without requiring Supabase initialization
void main() {
  group('Enhanced Driver Workflow Unit Tests', () {
    
    group('Driver Order Status Machine Tests', () {
      test('should validate all 7-step workflow transitions', () {
        // Test complete workflow transitions
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
          expect(isValid, true, 
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
          expect(isValid, false, 
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

      test('should identify mandatory confirmation requirements', () {
        // Test pickup confirmation requirement
        final requiresPickupConfirmation = DriverOrderStateMachine.actionRequiresConfirmation(
          DriverOrderAction.confirmPickup,
        );
        expect(requiresPickupConfirmation, true);

        // Test delivery confirmation requirement
        final requiresDeliveryConfirmation = DriverOrderStateMachine.actionRequiresConfirmation(
          DriverOrderAction.confirmDeliveryWithPhoto,
        );
        expect(requiresDeliveryConfirmation, true);
      });
    });

    group('Pickup Confirmation Tests', () {
      test('should create valid pickup confirmation', () {
        final confirmation = PickupConfirmation(
          orderId: 'test-order-123',
          confirmedAt: DateTime.now(),
          verificationChecklist: {
            'Order number matches': true,
            'All items are present': true,
            'Items are properly packaged': true,
            'Special instructions noted': true,
            'Temperature requirements met': true,
          },
          notes: 'All items verified and ready for delivery',
          confirmedBy: 'test-driver-456',
        );

        expect(confirmation.orderId, equals('test-order-123'));
        expect(confirmation.verificationChecklist.length, equals(5));
        expect(confirmation.verificationChecklist.values.every((v) => v), true);
        expect(confirmation.notes, isNotEmpty);
        expect(confirmation.confirmedBy, equals('test-driver-456'));
      });

      test('should validate complete verification checklist', () {
        final completeChecklist = {
          'Order number matches': true,
          'All items are present': true,
          'Items are properly packaged': true,
          'Special instructions noted': true,
          'Temperature requirements met': true,
        };

        final incompleteChecklist = {
          'Order number matches': true,
          'All items are present': false, // Missing item
          'Items are properly packaged': true,
        };

        expect(completeChecklist.values.every((v) => v), true);
        expect(incompleteChecklist.values.every((v) => v), false);
      });

      test('should handle optional notes and special instructions', () {
        final confirmationWithNotes = PickupConfirmation(
          orderId: 'test-order-123',
          confirmedAt: DateTime.now(),
          verificationChecklist: {
            'Order number matches': true,
            'All items are present': true,
            'Items are properly packaged': true,
            'Special instructions noted': true,
            'Temperature requirements met': true,
          },
          notes: 'Customer requested extra napkins - added to bag',
          confirmedBy: 'test-driver-456',
        );

        final confirmationWithoutNotes = PickupConfirmation(
          orderId: 'test-order-124',
          confirmedAt: DateTime.now(),
          verificationChecklist: {
            'Order number matches': true,
            'All items are present': true,
            'Items are properly packaged': true,
            'Special instructions noted': true,
            'Temperature requirements met': true,
          },
          confirmedBy: 'test-driver-456',
        );

        expect(confirmationWithNotes.notes, isNotEmpty);
        expect(confirmationWithoutNotes.notes, isNull);
      });
    });

    group('Delivery Confirmation Tests', () {
      test('should create valid delivery confirmation with photo and GPS', () {
        final confirmation = DeliveryConfirmation(
          orderId: 'test-order-123',
          deliveredAt: DateTime.now(),
          photoUrl: 'https://storage.supabase.co/delivery-proofs/test-photo.jpg',
          location: LocationData(
            latitude: 3.1390,
            longitude: 101.6869,
            accuracy: 15.0,
            timestamp: DateTime.now(),
            address: '123 Test Street, Kuala Lumpur',
          ),
          recipientName: 'John Doe',
          notes: 'Delivered to customer at front door',
          confirmedBy: 'test-driver-456',
        );

        expect(confirmation.orderId, equals('test-order-123'));
        expect(confirmation.photoUrl, isNotEmpty);
        expect(confirmation.photoUrl, contains('delivery-proofs'));
        expect(confirmation.location.latitude, equals(3.1390));
        expect(confirmation.location.longitude, equals(101.6869));
        expect(confirmation.location.accuracy, lessThan(50.0));
        expect(confirmation.recipientName, equals('John Doe'));
        expect(confirmation.confirmedBy, equals('test-driver-456'));
      });

      test('should validate GPS accuracy requirements', () {
        final accurateLocation = LocationData(
          latitude: 3.1390,
          longitude: 101.6869,
          accuracy: 10.0, // Good accuracy
          timestamp: DateTime.now(),
        );

        final poorAccuracyLocation = LocationData(
          latitude: 3.1390,
          longitude: 101.6869,
          accuracy: 100.0, // Poor accuracy
          timestamp: DateTime.now(),
        );

        expect(LocationService.isLocationAccurate(accurateLocation), true);
        expect(LocationService.isLocationAccurate(poorAccuracyLocation), false);
      });

      test('should require photo URL for delivery confirmation', () {
        expect(() => DeliveryConfirmation(
          orderId: 'test-order-123',
          deliveredAt: DateTime.now(),
          photoUrl: '', // Empty photo URL should fail validation
          location: LocationData(
            latitude: 3.1390,
            longitude: 101.6869,
            accuracy: 15.0,
            timestamp: DateTime.now(),
          ),
          confirmedBy: 'test-driver-456',
        ), throwsA(isA<AssertionError>()));
      });

      test('should handle optional recipient name and notes', () {
        final confirmationWithDetails = DeliveryConfirmation(
          orderId: 'test-order-123',
          deliveredAt: DateTime.now(),
          photoUrl: 'https://storage.supabase.co/delivery-proofs/test-photo.jpg',
          location: LocationData(
            latitude: 3.1390,
            longitude: 101.6869,
            accuracy: 15.0,
            timestamp: DateTime.now(),
          ),
          recipientName: 'Jane Smith',
          notes: 'Left at front door as requested',
          confirmedBy: 'test-driver-456',
        );

        final confirmationMinimal = DeliveryConfirmation(
          orderId: 'test-order-124',
          deliveredAt: DateTime.now(),
          photoUrl: 'https://storage.supabase.co/delivery-proofs/test-photo2.jpg',
          location: LocationData(
            latitude: 3.1390,
            longitude: 101.6869,
            accuracy: 15.0,
            timestamp: DateTime.now(),
          ),
          confirmedBy: 'test-driver-456',
        );

        expect(confirmationWithDetails.recipientName, equals('Jane Smith'));
        expect(confirmationWithDetails.notes, equals('Left at front door as requested'));
        expect(confirmationMinimal.recipientName, isNull);
        expect(confirmationMinimal.notes, isNull);
      });
    });

    group('Driver Order Model Tests', () {
      test('should create driver order with all required fields', () {
        final order = OrderModels.DriverOrder(
          id: 'test-order-123',
          orderNumber: 'ORD-2024-001',
          vendorName: 'Test Restaurant',
          vendorAddress: '123 Restaurant Street, KL',
          customerName: 'John Doe',
          deliveryAddress: '456 Customer Street, KL',
          customerPhone: '+60123456789',
          totalAmount: 45.50,
          deliveryFee: 5.00,
          status: DriverOrderStatus.assigned,
          estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
          specialInstructions: 'Ring doorbell twice',
          createdAt: DateTime.now(),
        );

        expect(order.id, equals('test-order-123'));
        expect(order.status, equals(DriverOrderStatus.assigned));
        expect(order.totalAmount, equals(45.50));
        expect(order.vendorName, equals('Test Restaurant'));
      });

      test('should convert status to/from string correctly', () {
        // Test status to string conversion
        expect(DriverOrderStatus.assigned.value, equals('assigned'));
        expect(DriverOrderStatus.onRouteToVendor.value, equals('on_route_to_vendor'));
        expect(DriverOrderStatus.arrivedAtVendor.value, equals('arrived_at_vendor'));
        expect(DriverOrderStatus.pickedUp.value, equals('picked_up'));
        expect(DriverOrderStatus.onRouteToCustomer.value, equals('on_route_to_customer'));
        expect(DriverOrderStatus.arrivedAtCustomer.value, equals('arrived_at_customer'));
        expect(DriverOrderStatus.delivered.value, equals('delivered'));

        // Test string to status conversion
        expect(DriverOrderStatus.fromString('assigned'), equals(DriverOrderStatus.assigned));
        expect(DriverOrderStatus.fromString('on_route_to_vendor'), equals(DriverOrderStatus.onRouteToVendor));
        expect(DriverOrderStatus.fromString('delivered'), equals(DriverOrderStatus.delivered));

        // Test legacy status mapping
        expect(DriverOrderStatus.fromString('out_for_delivery'), equals(DriverOrderStatus.pickedUp));
      });

      test('should handle invalid status strings', () {
        expect(() => DriverOrderStatus.fromString('invalid_status'), 
               throwsA(isA<ArgumentError>()));
      });
    });

    group('Location Service Tests', () {
      test('should validate location accuracy', () {
        final accurateLocation = LocationData(
          latitude: 3.1390,
          longitude: 101.6869,
          accuracy: 25.0,
          timestamp: DateTime.now(),
        );

        final inaccurateLocation = LocationData(
          latitude: 3.1390,
          longitude: 101.6869,
          accuracy: 75.0,
          timestamp: DateTime.now(),
        );

        expect(LocationService.isLocationAccurate(accurateLocation), true);
        expect(LocationService.isLocationAccurate(inaccurateLocation), false);
      });

      test('should calculate distance between coordinates', () {
        // Test distance calculation between two known points
        final distance = LocationService.calculateDistance(
          3.1390, 101.6869, // Kuala Lumpur
          3.1478, 101.6953, // Nearby location
        );

        expect(distance, greaterThan(0));
        expect(distance, lessThan(2000)); // Should be less than 2km
      });
    });
  });
}
