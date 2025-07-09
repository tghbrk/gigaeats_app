import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:gigaeats_app/src/features/drivers/data/models/driver_order.dart';
import 'package:gigaeats_app/src/features/drivers/data/validators/driver_workflow_validators.dart';

/// Unit tests for driver workflow validators
/// Tests all validation logic for the enhanced driver workflow
void main() {
  group('DriverWorkflowValidators', () {
    group('validateOrderStatusTransition', () {
      test('should validate correct status transitions', () {
        final order = _createTestOrder(DriverOrderStatus.assigned);

        final result = DriverWorkflowValidators.validateOrderStatusTransition(
          order: order,
          targetStatus: DriverOrderStatus.onRouteToVendor,
        );

        expect(result.isValid, isTrue);
      });

      test('should reject invalid status transitions', () {
        final order = _createTestOrder(DriverOrderStatus.assigned);

        final result = DriverWorkflowValidators.validateOrderStatusTransition(
          order: order,
          targetStatus: DriverOrderStatus.pickedUp, // Skipping steps
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, isNotNull);
      });

      test('should validate pickup confirmation requirements', () {
        final order = _createTestOrder(DriverOrderStatus.arrivedAtVendor);
        final validPickupData = {
          'pickup_confirmation': {
            'verification_checklist': {
              'Order number matches': true,
              'All items are present': true,
              'Items are properly packaged': true,
              'Special instructions noted': true,
              'Temperature requirements met': true,
            },
            'notes': 'All verified',
          }
        };

        final result = DriverWorkflowValidators.validateOrderStatusTransition(
          order: order,
          targetStatus: DriverOrderStatus.pickedUp,
          additionalData: validPickupData,
        );

        expect(result.isValid, isTrue);
      });

      test('should validate delivery confirmation requirements', () {
        final order = _createTestOrder(DriverOrderStatus.arrivedAtCustomer);
        final validDeliveryData = {
          'delivery_confirmation': {
            'photo_url': 'https://example.com/photo.jpg',
            'latitude': 3.1390,
            'longitude': 101.6869,
            'location_accuracy': 5.0,
            'recipient_name': 'John Doe',
            'notes': 'Delivered successfully',
          }
        };

        final result = DriverWorkflowValidators.validateOrderStatusTransition(
          order: order,
          targetStatus: DriverOrderStatus.delivered,
          additionalData: validDeliveryData,
        );

        expect(result.isValid, isTrue);
      });
    });

    group('validatePickupConfirmationData', () {
      test('should validate complete pickup confirmation', () {
        final checklist = {
          'Order number matches': true,
          'All items are present': true,
          'Items are properly packaged': true,
          'Special instructions noted': true,
          'Temperature requirements met': true,
        };

        final result = DriverWorkflowValidators.validatePickupConfirmationData(
          verificationChecklist: checklist,
          notes: 'All items verified successfully',
        );

        expect(result.isValid, isTrue);
      });

      test('should reject empty checklist', () {
        final result = DriverWorkflowValidators.validatePickupConfirmationData(
          verificationChecklist: {},
          notes: null,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('empty'));
      });

      test('should enforce 80% completion rule', () {
        final incompleteChecklist = {
          'Order number matches': true,
          'All items are present': true,
          'Items are properly packaged': false,
          'Special instructions noted': false,
          'Temperature requirements met': false,
        }; // Only 40% completed

        final result = DriverWorkflowValidators.validatePickupConfirmationData(
          verificationChecklist: incompleteChecklist,
          notes: null,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('80%'));
      });

      test('should require critical verification items', () {
        final missingCriticalItems = {
          'Order number matches': false, // Critical item not verified
          'All items are present': true,
          'Items are properly packaged': true,
          'Special instructions noted': true,
          'Temperature requirements met': true,
        };

        final result = DriverWorkflowValidators.validatePickupConfirmationData(
          verificationChecklist: missingCriticalItems,
          notes: null,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('Critical verification required'));
      });

      test('should validate notes length', () {
        final checklist = {
          'Order number matches': true,
          'All items are present': true,
          'Items are properly packaged': true,
        };
        final longNotes = 'A' * 501; // Exceeds 500 character limit

        final result = DriverWorkflowValidators.validatePickupConfirmationData(
          verificationChecklist: checklist,
          notes: longNotes,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('500 characters'));
      });
    });

    group('validateDeliveryConfirmationData', () {
      test('should validate complete delivery confirmation', () {
        final result = DriverWorkflowValidators.validateDeliveryConfirmationData(
          photoUrl: 'https://example.com/delivery-proof.jpg',
          latitude: 3.1390,
          longitude: 101.6869,
          accuracy: 5.0,
          recipientName: 'John Doe',
          notes: 'Delivered successfully',
        );

        expect(result.isValid, isTrue);
      });

      test('should require photo URL', () {
        final result = DriverWorkflowValidators.validateDeliveryConfirmationData(
          photoUrl: null,
          latitude: 3.1390,
          longitude: 101.6869,
          accuracy: 5.0,
          recipientName: 'John Doe',
          notes: 'Attempted delivery',
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('photo'));
      });

      test('should require valid GPS coordinates', () {
        final result = DriverWorkflowValidators.validateDeliveryConfirmationData(
          photoUrl: 'https://example.com/photo.jpg',
          latitude: null,
          longitude: null,
          accuracy: 5.0,
          recipientName: 'John Doe',
          notes: 'Delivery attempt',
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('GPS location'));
      });

      test('should validate GPS coordinate ranges', () {
        // Test invalid latitude
        final invalidLatResult = DriverWorkflowValidators.validateDeliveryConfirmationData(
          photoUrl: 'https://example.com/photo.jpg',
          latitude: 95.0, // Invalid latitude > 90
          longitude: 101.6869,
          accuracy: 5.0,
          recipientName: 'John Doe',
          notes: 'Delivery',
        );

        expect(invalidLatResult.isValid, isFalse);
        expect(invalidLatResult.errorMessage, contains('latitude'));

        // Test invalid longitude
        final invalidLngResult = DriverWorkflowValidators.validateDeliveryConfirmationData(
          photoUrl: 'https://example.com/photo.jpg',
          latitude: 3.1390,
          longitude: 185.0, // Invalid longitude > 180
          accuracy: 5.0,
          recipientName: 'John Doe',
          notes: 'Delivery',
        );

        expect(invalidLngResult.isValid, isFalse);
        expect(invalidLngResult.errorMessage, contains('longitude'));
      });

      test('should validate GPS accuracy', () {
        final result = DriverWorkflowValidators.validateDeliveryConfirmationData(
          photoUrl: 'https://example.com/photo.jpg',
          latitude: 3.1390,
          longitude: 101.6869,
          accuracy: 150.0, // Poor accuracy > 100m
          recipientName: 'John Doe',
          notes: 'Delivery with poor GPS',
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('accuracy'));
      });

      test('should validate recipient name format', () {
        final result = DriverWorkflowValidators.validateDeliveryConfirmationData(
          photoUrl: 'https://example.com/photo.jpg',
          latitude: 3.1390,
          longitude: 101.6869,
          accuracy: 5.0,
          recipientName: 'John123!@#', // Invalid characters
          notes: 'Delivery',
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('invalid characters'));
      });

      test('should validate notes length', () {
        final longNotes = 'A' * 501; // Exceeds 500 character limit

        final result = DriverWorkflowValidators.validateDeliveryConfirmationData(
          photoUrl: 'https://example.com/photo.jpg',
          latitude: 3.1390,
          longitude: 101.6869,
          accuracy: 5.0,
          recipientName: 'John Doe',
          notes: longNotes,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('500 characters'));
      });
    });

    group('validatePhotoFile', () {
      test('should validate JPEG photo file', () {
        final mockPhoto = XFile(
          'test_photo.jpg',
          name: 'test_photo.jpg',
          mimeType: 'image/jpeg',
        );

        final result = DriverWorkflowValidators.validatePhotoFile(mockPhoto);
        expect(result.isValid, isTrue);
      });

      test('should validate PNG photo file', () {
        final mockPhoto = XFile(
          'test_photo.png',
          name: 'test_photo.png',
          mimeType: 'image/png',
        );

        final result = DriverWorkflowValidators.validatePhotoFile(mockPhoto);
        expect(result.isValid, isTrue);
      });

      test('should reject invalid file extensions', () {
        final mockPhoto = XFile(
          'test_file.txt',
          name: 'test_file.txt',
          mimeType: 'text/plain',
        );

        final result = DriverWorkflowValidators.validatePhotoFile(mockPhoto);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('JPEG or PNG'));
      });

      test('should reject invalid MIME types', () {
        final mockPhoto = XFile(
          'test_photo.jpg',
          name: 'test_photo.jpg',
          mimeType: 'application/pdf',
        );

        final result = DriverWorkflowValidators.validatePhotoFile(mockPhoto);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('Invalid image format'));
      });
    });

    group('validateDriverLocation', () {
      test('should validate driver within acceptable distance', () {
        final result = DriverWorkflowValidators.validateDriverLocation(
          driverLatitude: 3.1390,
          driverLongitude: 101.6869,
          targetLatitude: 3.1391,
          targetLongitude: 101.6870,
          maxDistanceMeters: 100.0,
          operationType: 'pickup',
        );

        expect(result.isValid, isTrue);
      });

      test('should reject driver too far from target', () {
        final result = DriverWorkflowValidators.validateDriverLocation(
          driverLatitude: 3.1390,
          driverLongitude: 101.6869,
          targetLatitude: 3.1500, // Much further away
          targetLongitude: 101.7000,
          maxDistanceMeters: 100.0,
          operationType: 'pickup',
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('within'));
        expect(result.errorMessage, contains('100m'));
      });
    });

    group('validateOrderTiming', () {
      test('should validate recent order', () {
        final recentOrder = _createTestOrder(DriverOrderStatus.assigned);

        final result = DriverWorkflowValidators.validateOrderTiming(recentOrder);
        expect(result.isValid, isTrue);
      });

      test('should reject very old order', () {
        final now = DateTime.now();
        final oldOrder = DriverOrder(
          id: 'test-order',
          orderId: 'order-123',
          orderNumber: 'ORD-123',
          driverId: 'test-driver-id',
          vendorId: 'test-vendor-id',
          vendorName: 'Test Vendor',
          customerId: 'test-customer-id',
          customerName: 'Test Customer',
          status: DriverOrderStatus.assigned,
          deliveryDetails: const DeliveryDetails(
            pickupAddress: '456 Restaurant Street, Test City',
            deliveryAddress: 'Test Address',
          ),
          orderEarnings: const OrderEarnings(
            baseFee: 5.0,
            totalEarnings: 8.50,
          ),
          orderItemsCount: 2,
          orderTotal: 25.0,
          assignedAt: now.subtract(const Duration(hours: 25)),
          createdAt: now.subtract(const Duration(hours: 25)), // Too old
          updatedAt: now,
        );

        final result = DriverWorkflowValidators.validateOrderTiming(oldOrder);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('too old'));
      });
    });
  });
}

/// Helper function to create test driver order
DriverOrder _createTestOrder(DriverOrderStatus status) {
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
      pickupAddress: '456 Restaurant Street, Test City',
      deliveryAddress: '123 Test Street, Test City',
      contactPhone: '+60123456789',
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
    deliveryNotes: 'Test delivery notes',
    requestedDeliveryTime: now.add(const Duration(minutes: 30)),
  );
}
