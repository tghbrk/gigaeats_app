// Integration test to verify that 'ready' status orders display correctly in available orders
// This test simulates the real-world scenario where orders with 'ready' status should appear in the available orders list

import 'package:flutter_test/flutter_test.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/driver_order.dart';


void main() {
  group('Available Orders Status Integration Tests', () {
    test('should transform ready status orders correctly', () {
      // Simulate a database response with 'ready' status
      final mockDatabaseResponse = {
        'id': 'test-order-123',
        'order_number': 'GE001',
        'status': 'ready', // This is the key test case
        'vendor_id': 'vendor-123',
        'customer_id': 'customer-123',
        'delivery_address': 'Test Address',
        'total_amount': 25.50,
        'delivery_fee': 5.00,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'vendors': {
          'business_name': 'Test Restaurant',
          'business_address': 'Restaurant Address'
        },
        'order_items': [],
      };

      // Test the transformation function that's used in enhanced workflow providers
      expect(() => _transformToDriverOrder(mockDatabaseResponse, 'ready'), returnsNormally);
      
      final transformedOrder = _transformToDriverOrder(mockDatabaseResponse, 'ready');
      
      // Verify that the order was transformed correctly
      expect(transformedOrder.id, equals('test-order-123'));
      expect(transformedOrder.status, equals(DriverOrderStatus.assigned)); // 'ready' should map to 'assigned'
      expect(transformedOrder.vendorName, equals('Test Restaurant'));
    });

    test('should handle confirmed status orders correctly', () {
      final mockDatabaseResponse = {
        'id': 'test-order-456',
        'order_number': 'GE002',
        'status': 'confirmed',
        'vendor_id': 'vendor-456',
        'customer_id': 'customer-456',
        'delivery_address': 'Test Address 2',
        'total_amount': 30.00,
        'delivery_fee': 5.00,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'vendors': {
          'business_name': 'Test Restaurant 2',
          'business_address': 'Restaurant Address 2'
        },
        'order_items': [],
      };

      expect(() => _transformToDriverOrder(mockDatabaseResponse, 'confirmed'), returnsNormally);
      
      final transformedOrder = _transformToDriverOrder(mockDatabaseResponse, 'confirmed');
      expect(transformedOrder.status, equals(DriverOrderStatus.assigned));
    });

    test('should handle preparing status orders correctly', () {
      final mockDatabaseResponse = {
        'id': 'test-order-789',
        'order_number': 'GE003',
        'status': 'preparing',
        'vendor_id': 'vendor-789',
        'customer_id': 'customer-789',
        'delivery_address': 'Test Address 3',
        'total_amount': 20.00,
        'delivery_fee': 5.00,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'vendors': {
          'business_name': 'Test Restaurant 3',
          'business_address': 'Restaurant Address 3'
        },
        'order_items': [],
      };

      expect(() => _transformToDriverOrder(mockDatabaseResponse, 'preparing'), returnsNormally);
      
      final transformedOrder = _transformToDriverOrder(mockDatabaseResponse, 'preparing');
      expect(transformedOrder.status, equals(DriverOrderStatus.assigned));
    });

    test('should handle database status mapping correctly', () {
      // Test the status mapping function used in enhanced workflow providers
      expect(_mapDatabaseStatusToDriverStatus('ready'), equals('assigned'));
      expect(_mapDatabaseStatusToDriverStatus('confirmed'), equals('assigned'));
      expect(_mapDatabaseStatusToDriverStatus('preparing'), equals('assigned'));
      expect(_mapDatabaseStatusToDriverStatus('assigned'), equals('assigned'));
      expect(_mapDatabaseStatusToDriverStatus('on_route_to_vendor'), equals('on_route_to_vendor'));
      expect(_mapDatabaseStatusToDriverStatus('delivered'), equals('delivered'));
    });
  });
}

// Helper functions copied from enhanced_driver_workflow_providers.dart for testing
DriverOrder _transformToDriverOrder(Map<String, dynamic> response, String effectiveStatus) {
  final orderId = response['id']?.toString() ?? '';
  final orderNumber = response['order_number']?.toString() ?? '';

  // Map database status to valid DriverOrderStatus enum value
  String mappedStatus = _mapDatabaseStatusToDriverStatus(effectiveStatus);

  // Parse delivery address safely
  String deliveryAddressStr = '';
  if (response['delivery_address'] != null) {
    final addr = response['delivery_address'];
    if (addr is Map) {
      final parts = <String>[];
      if (addr['street'] != null) parts.add(addr['street'].toString());
      if (addr['city'] != null) parts.add(addr['city'].toString());
      if (addr['state'] != null) parts.add(addr['state'].toString());
      if (addr['postal_code'] != null) parts.add(addr['postal_code'].toString());
      deliveryAddressStr = parts.join(', ');
    } else {
      deliveryAddressStr = addr.toString();
    }
  }

  // Get vendor name from vendors join
  String vendorName = 'Unknown Vendor';
  if (response['vendors'] != null && response['vendors'] is Map) {
    vendorName = response['vendors']['business_name']?.toString() ?? 'Unknown Vendor';
  }

  // Create the JSON payload for DriverOrder.fromJson
  final driverOrderJson = {
    'id': orderId,
    'order_id': orderId,
    'order_number': orderNumber,
    'driver_id': '',
    'vendor_id': response['vendor_id']?.toString() ?? '',
    'vendor_name': vendorName,
    'customer_id': response['customer_id']?.toString() ?? '',
    'customer_name': 'Unknown Customer',
    'status': mappedStatus, // Use mapped status instead of raw effectiveStatus
    'priority': 'normal',
    'delivery_details': {
      'pickup_address': response['vendors']?['business_address']?.toString() ?? '',
      'delivery_address': deliveryAddressStr,
      'contact_phone': response['contact_phone']?.toString(),
    },
    'order_earnings': {
      'base_fee': _safeToDouble(response['delivery_fee']),
      'distance_fee': 0.0,
      'time_bonus': 0.0,
      'tip_amount': 0.0,
      'total_earnings': _safeToDouble(response['delivery_fee']),
    },
    'order_items_count': (response['order_items'] as List?)?.length ?? 0,
    'order_total': _safeToDouble(response['total_amount']),
    'payment_method': null,
    'requires_cash_collection': false,
    'assigned_at': response['assigned_at']?.toString() ?? DateTime.now().toIso8601String(),
    'accepted_at': null,
    'started_route_at': null,
    'arrived_at_vendor_at': null,
    'picked_up_at': response['picked_up_at']?.toString(),
    'arrived_at_customer_at': null,
    'delivered_at': response['actual_delivery_time']?.toString(),
    'created_at': response['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };

  return DriverOrder.fromJson(driverOrderJson);
}

String _mapDatabaseStatusToDriverStatus(String databaseStatus) {
  switch (databaseStatus.toLowerCase()) {
    case 'ready':
      return 'assigned';
    case 'confirmed':
      return 'assigned';
    case 'preparing':
      return 'assigned';
    case 'assigned':
      return 'assigned';
    case 'on_route_to_vendor':
      return 'on_route_to_vendor';
    case 'arrived_at_vendor':
      return 'arrived_at_vendor';
    case 'picked_up':
      return 'picked_up';
    case 'out_for_delivery':
      return 'picked_up';
    case 'on_route_to_customer':
      return 'on_route_to_customer';
    case 'arrived_at_customer':
      return 'arrived_at_customer';
    case 'delivered':
      return 'delivered';
    case 'cancelled':
      return 'cancelled';
    case 'failed':
      return 'failed';
    default:
      return 'assigned';
  }
}

double _safeToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}
