// Test script to verify DriverOrderStatus enum validation fixes
// This test ensures that 'ready', 'confirmed', and 'preparing' statuses are handled correctly

import 'package:flutter_test/flutter_test.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/driver_order.dart';

void main() {
  group('DriverOrderStatus Enum Validation Tests', () {
    test('should handle ready status correctly', () {
      expect(() => DriverOrderStatus.fromString('ready'), returnsNormally);
      expect(DriverOrderStatus.fromString('ready'), equals(DriverOrderStatus.assigned));
    });

    test('should handle confirmed status correctly', () {
      expect(() => DriverOrderStatus.fromString('confirmed'), returnsNormally);
      expect(DriverOrderStatus.fromString('confirmed'), equals(DriverOrderStatus.assigned));
    });

    test('should handle preparing status correctly', () {
      expect(() => DriverOrderStatus.fromString('preparing'), returnsNormally);
      expect(DriverOrderStatus.fromString('preparing'), equals(DriverOrderStatus.assigned));
    });

    test('should handle available status correctly', () {
      expect(() => DriverOrderStatus.fromString('available'), returnsNormally);
      expect(DriverOrderStatus.fromString('available'), equals(DriverOrderStatus.assigned));
    });

    test('should handle assigned status correctly', () {
      expect(() => DriverOrderStatus.fromString('assigned'), returnsNormally);
      expect(DriverOrderStatus.fromString('assigned'), equals(DriverOrderStatus.assigned));
    });

    test('should handle legacy statuses correctly', () {
      expect(() => DriverOrderStatus.fromString('out_for_delivery'), returnsNormally);
      expect(DriverOrderStatus.fromString('out_for_delivery'), equals(DriverOrderStatus.pickedUp));
      
      expect(() => DriverOrderStatus.fromString('en_route'), returnsNormally);
      expect(DriverOrderStatus.fromString('en_route'), equals(DriverOrderStatus.pickedUp));
    });

    test('should handle all granular workflow statuses', () {
      expect(DriverOrderStatus.fromString('on_route_to_vendor'), equals(DriverOrderStatus.onRouteToVendor));
      expect(DriverOrderStatus.fromString('arrived_at_vendor'), equals(DriverOrderStatus.arrivedAtVendor));
      expect(DriverOrderStatus.fromString('picked_up'), equals(DriverOrderStatus.pickedUp));
      expect(DriverOrderStatus.fromString('on_route_to_customer'), equals(DriverOrderStatus.onRouteToCustomer));
      expect(DriverOrderStatus.fromString('arrived_at_customer'), equals(DriverOrderStatus.arrivedAtCustomer));
      expect(DriverOrderStatus.fromString('delivered'), equals(DriverOrderStatus.delivered));
      expect(DriverOrderStatus.fromString('cancelled'), equals(DriverOrderStatus.cancelled));
      expect(DriverOrderStatus.fromString('failed'), equals(DriverOrderStatus.failed));
    });

    test('should handle case insensitive input', () {
      expect(DriverOrderStatus.fromString('READY'), equals(DriverOrderStatus.assigned));
      expect(DriverOrderStatus.fromString('Ready'), equals(DriverOrderStatus.assigned));
      expect(DriverOrderStatus.fromString('CONFIRMED'), equals(DriverOrderStatus.assigned));
      expect(DriverOrderStatus.fromString('Preparing'), equals(DriverOrderStatus.assigned));
    });

    test('should throw ArgumentError for invalid status', () {
      expect(() => DriverOrderStatus.fromString('invalid_status'), throwsArgumentError);
      expect(() => DriverOrderStatus.fromString('unknown'), throwsArgumentError);
      expect(() => DriverOrderStatus.fromString(''), throwsArgumentError);
    });
  });

  group('DriverOrderStatus Value Tests', () {
    test('should return correct string values', () {
      expect(DriverOrderStatus.assigned.value, equals('assigned'));
      expect(DriverOrderStatus.onRouteToVendor.value, equals('on_route_to_vendor'));
      expect(DriverOrderStatus.arrivedAtVendor.value, equals('arrived_at_vendor'));
      expect(DriverOrderStatus.pickedUp.value, equals('picked_up'));
      expect(DriverOrderStatus.onRouteToCustomer.value, equals('on_route_to_customer'));
      expect(DriverOrderStatus.arrivedAtCustomer.value, equals('arrived_at_customer'));
      expect(DriverOrderStatus.delivered.value, equals('delivered'));
      expect(DriverOrderStatus.cancelled.value, equals('cancelled'));
      expect(DriverOrderStatus.failed.value, equals('failed'));
    });

    test('should have correct display names', () {
      expect(DriverOrderStatus.assigned.displayName, equals('Assigned'));
      expect(DriverOrderStatus.onRouteToVendor.displayName, equals('On Route to Restaurant'));
      expect(DriverOrderStatus.arrivedAtVendor.displayName, equals('Arrived at Restaurant'));
      expect(DriverOrderStatus.pickedUp.displayName, equals('Order Picked Up'));
      expect(DriverOrderStatus.onRouteToCustomer.displayName, equals('On Route to Customer'));
      expect(DriverOrderStatus.arrivedAtCustomer.displayName, equals('Arrived at Customer'));
      expect(DriverOrderStatus.delivered.displayName, equals('Delivered'));
      expect(DriverOrderStatus.cancelled.displayName, equals('Cancelled'));
      expect(DriverOrderStatus.failed.displayName, equals('Failed'));
    });
  });
}
