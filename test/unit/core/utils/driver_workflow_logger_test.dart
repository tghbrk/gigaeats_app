import 'package:flutter_test/flutter_test.dart';
import 'package:gigaeats_app/src/core/utils/driver_workflow_logger.dart';

void main() {
  group('DriverWorkflowLogger', () {
    setUp(() {
      // Enable logging for tests
      DriverWorkflowLogger.setEnabled(true);
    });

    test('should log status transitions correctly', () {
      expect(() {
        DriverWorkflowLogger.logStatusTransition(
          orderId: 'test-order-123',
          fromStatus: 'assigned',
          toStatus: 'on_route_to_vendor',
          driverId: 'driver-456',
          context: 'TEST',
        );
      }, returnsNormally);
    });

    test('should log button interactions correctly', () {
      expect(() {
        DriverWorkflowLogger.logButtonInteraction(
          buttonName: 'Navigate to Customer',
          orderId: 'test-order-123',
          currentStatus: 'picked_up',
          context: 'DIALOG',
          metadata: {'action': 'navigate'},
        );
      }, returnsNormally);
    });

    test('should log database operations correctly', () {
      expect(() {
        DriverWorkflowLogger.logDatabaseOperation(
          operation: 'UPDATE',
          orderId: 'test-order-123',
          data: {'status': 'on_route_to_customer'},
          context: 'PROVIDER',
          isSuccess: true,
        );
      }, returnsNormally);
    });

    test('should log validation results correctly', () {
      expect(() {
        DriverWorkflowLogger.logValidation(
          validationType: 'Status Transition',
          isValid: true,
          orderId: 'test-order-123',
          context: 'PROVIDER',
        );
      }, returnsNormally);
    });

    test('should log errors correctly', () {
      expect(() {
        DriverWorkflowLogger.logError(
          operation: 'Status Update',
          error: 'Invalid transition',
          orderId: 'test-order-123',
          context: 'DIALOG',
        );
      }, returnsNormally);
    });

    test('should log performance metrics correctly', () {
      expect(() {
        DriverWorkflowLogger.logPerformance(
          operation: 'Database Update',
          duration: const Duration(milliseconds: 150),
          orderId: 'test-order-123',
          context: 'PROVIDER',
        );
      }, returnsNormally);
    });

    test('should log workflow summary correctly', () {
      expect(() {
        DriverWorkflowLogger.logWorkflowSummary(
          orderId: 'test-order-123',
          currentStatus: 'on_route_to_customer',
          availableActions: ['Navigate to Customer', 'Report Issue'],
          driverId: 'driver-456',
          timestamps: {
            'created_at': DateTime.now(),
            'picked_up_at': DateTime.now().subtract(const Duration(minutes: 10)),
          },
        );
      }, returnsNormally);
    });

    test('should respect enabled/disabled state', () {
      DriverWorkflowLogger.setEnabled(false);
      expect(DriverWorkflowLogger.isEnabled, false);
      
      DriverWorkflowLogger.setEnabled(true);
      expect(DriverWorkflowLogger.isEnabled, true);
    });
  });
}
