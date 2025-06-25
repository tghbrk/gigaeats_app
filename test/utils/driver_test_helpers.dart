import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gigaeats_app/features/drivers/data/models/driver_order.dart';
import 'package:gigaeats_app/features/drivers/data/models/driver_order_state_machine.dart';

/// Test utilities and helpers for driver workflow testing
class DriverTestHelpers {
  /// Test configuration constants
  static const testConfig = {
    'supabaseUrl': 'https://abknoalhfltlhhdbclpv.supabase.co',
    'testDriverId': '087132e7-e38b-4d3f-b28c-7c34b75e86c4',
    'testDriverUserId': '5a400967-c68e-48fa-a222-ef25249de974',
    'testVendorId': 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    'testCustomerId': 'customer_test_id',
    'testDriverEmail': 'driver.test@gigaeats.com',
    'testDriverPassword': 'Testpass123!',
  };

  /// Create a test ProviderContainer with mock overrides
  static ProviderContainer createTestContainer({
    List<Override> overrides = const [],
  }) {
    return ProviderContainer(
      overrides: overrides,
    );
  }

  /// Create a test MaterialApp with ProviderScope
  static Widget createTestApp({
    required Widget child,
    ProviderContainer? container,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  /// Create a mock DriverOrder for testing
  static DriverOrder createMockDriverOrder({
    String? id,
    String? orderNumber,
    String? vendorName,
    String? customerName,
    double? totalAmount,
    String? deliveryAddress,
    String? contactPhone,
    String? specialInstructions,
    DriverOrderStatus? status,
    DateTime? createdAt,
  }) {
    return DriverOrder(
      id: id ?? 'test-order-${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: orderNumber ?? 'ORD-TEST-${DateTime.now().millisecondsSinceEpoch}',
      vendorName: vendorName ?? 'Test Restaurant',
      customerName: customerName ?? 'Test Customer',
      totalAmount: totalAmount ?? 25.50,
      deliveryFee: 5.0,
      status: status ?? DriverOrderStatus.available,
      deliveryAddress: deliveryAddress ?? '123 Test Street, Kuala Lumpur',
      customerPhone: contactPhone ?? '+60123456789',
      specialInstructions: specialInstructions,
      vendorAddress: '456 Vendor Street, KL',
      estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Create a test order in the database
  static Future<String> createTestOrder(
    SupabaseClient supabase, {
    String? customerId,
    String? vendorId,
    double? totalAmount,
    String? status,
    String? deliveryMethod,
    String? assignedDriverId,
  }) async {
    final orderData = {
      'customer_id': customerId ?? testConfig['testCustomerId'],
      'vendor_id': vendorId ?? testConfig['testVendorId'],
      'total_amount': totalAmount ?? 25.50,
      'status': status ?? 'ready',
      'delivery_method': deliveryMethod ?? 'own_fleet',
      'delivery_address': 'Test Address, Kuala Lumpur',
      'contact_phone': '+60123456789',
      'order_number': 'TEST-${DateTime.now().millisecondsSinceEpoch}',
      'vendor_name': 'Test Vendor',
      'customer_name': 'Test Customer',
    };

    if (assignedDriverId != null) {
      orderData['assigned_driver_id'] = assignedDriverId;
    }

    final response = await supabase
        .from('orders')
        .insert(orderData)
        .select('id')
        .single();

    return response['id'];
  }

  /// Clean up test order from database
  static Future<void> cleanupTestOrder(
    SupabaseClient supabase,
    String orderId,
  ) async {
    try {
      await supabase
          .from('orders')
          .delete()
          .eq('id', orderId);
    } catch (e) {
      // Ignore cleanup errors in tests
      debugPrint('Failed to cleanup test order $orderId: $e');
    }
  }

  /// Authenticate as test driver
  static Future<User?> authenticateAsTestDriver(SupabaseClient supabase) async {
    final authResponse = await supabase.auth.signInWithPassword(
      email: testConfig['testDriverEmail']!,
      password: testConfig['testDriverPassword']!,
    );
    return authResponse.user;
  }

  /// Sign out current user
  static Future<void> signOut(SupabaseClient supabase) async {
    await supabase.auth.signOut();
  }

  /// Wait for async operations to complete in tests
  static Future<void> waitForAsyncOperation({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await Future.delayed(timeout);
  }

  /// Verify order status in database
  static Future<String?> getOrderStatus(
    SupabaseClient supabase,
    String orderId,
  ) async {
    try {
      final response = await supabase
          .from('orders')
          .select('status')
          .eq('id', orderId)
          .single();
      return response['status'];
    } catch (e) {
      return null;
    }
  }

  /// Verify driver delivery status in database
  static Future<String?> getDriverDeliveryStatus(
    SupabaseClient supabase,
    String driverId,
  ) async {
    try {
      final response = await supabase
          .from('drivers')
          .select('current_delivery_status')
          .eq('id', driverId)
          .single();
      return response['current_delivery_status'];
    } catch (e) {
      return null;
    }
  }

  /// Update order status for testing
  static Future<bool> updateOrderStatus(
    SupabaseClient supabase,
    String orderId,
    String status, {
    String? assignedDriverId,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (assignedDriverId != null) {
        updateData['assigned_driver_id'] = assignedDriverId;
      }

      if (status == 'out_for_delivery') {
        updateData['out_for_delivery_at'] = DateTime.now().toIso8601String();
      } else if (status == 'delivered') {
        updateData['actual_delivery_time'] = DateTime.now().toIso8601String();
      }

      await supabase
          .from('orders')
          .update(updateData)
          .eq('id', orderId);

      return true;
    } catch (e) {
      debugPrint('Failed to update order status: $e');
      return false;
    }
  }

  /// Update driver delivery status for testing
  static Future<bool> updateDriverDeliveryStatus(
    SupabaseClient supabase,
    String driverId,
    String deliveryStatus,
  ) async {
    try {
      await supabase
          .from('drivers')
          .update({
            'current_delivery_status': deliveryStatus,
            'last_seen': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      return true;
    } catch (e) {
      debugPrint('Failed to update driver delivery status: $e');
      return false;
    }
  }

  /// Simulate complete workflow progression
  static Future<List<String>> simulateCompleteWorkflow(
    SupabaseClient supabase,
    String orderId,
    String driverId,
  ) async {
    final results = <String>[];

    try {
      // Step 1: Accept order
      final acceptSuccess = await updateOrderStatus(
        supabase,
        orderId,
        'out_for_delivery',
        assignedDriverId: driverId,
      );
      results.add(acceptSuccess ? 'Accept: SUCCESS' : 'Accept: FAILED');

      // Step 2: Start journey to vendor
      final startJourneySuccess = await updateDriverDeliveryStatus(
        supabase,
        driverId,
        'on_route_to_vendor',
      );
      results.add(startJourneySuccess ? 'Start Journey: SUCCESS' : 'Start Journey: FAILED');

      // Step 3: Arrive at vendor
      final arriveVendorSuccess = await updateDriverDeliveryStatus(
        supabase,
        driverId,
        'arrived_at_vendor',
      );
      results.add(arriveVendorSuccess ? 'Arrive Vendor: SUCCESS' : 'Arrive Vendor: FAILED');

      // Step 4: Pick up order
      final pickupSuccess = await updateDriverDeliveryStatus(
        supabase,
        driverId,
        'picked_up',
      );
      results.add(pickupSuccess ? 'Pickup: SUCCESS' : 'Pickup: FAILED');

      // Step 5: Start delivery
      final startDeliverySuccess = await updateDriverDeliveryStatus(
        supabase,
        driverId,
        'on_route_to_customer',
      );
      results.add(startDeliverySuccess ? 'Start Delivery: SUCCESS' : 'Start Delivery: FAILED');

      // Step 6: Arrive at customer
      final arriveCustomerSuccess = await updateDriverDeliveryStatus(
        supabase,
        driverId,
        'arrived_at_customer',
      );
      results.add(arriveCustomerSuccess ? 'Arrive Customer: SUCCESS' : 'Arrive Customer: FAILED');

      // Step 7: Complete delivery
      final completeSuccess = await updateOrderStatus(
        supabase,
        orderId,
        'delivered',
      );
      results.add(completeSuccess ? 'Complete: SUCCESS' : 'Complete: FAILED');

    } catch (e) {
      results.add('Workflow Error: $e');
    }

    return results;
  }

  /// Validate workflow state machine transitions
  static Map<String, bool> validateStateMachineTransitions() {
    final results = <String, bool>{};

    // Test valid transitions
    final validTransitions = [
      (DriverOrderStatus.available, DriverOrderStatus.assigned),
      (DriverOrderStatus.assigned, DriverOrderStatus.onRouteToVendor),
      (DriverOrderStatus.onRouteToVendor, DriverOrderStatus.arrivedAtVendor),
      (DriverOrderStatus.arrivedAtVendor, DriverOrderStatus.pickedUp),
      (DriverOrderStatus.pickedUp, DriverOrderStatus.onRouteToCustomer),
      (DriverOrderStatus.onRouteToCustomer, DriverOrderStatus.arrivedAtCustomer),
      (DriverOrderStatus.arrivedAtCustomer, DriverOrderStatus.delivered),
    ];

    for (final (from, to) in validTransitions) {
      final isValid = DriverOrderStateMachine.isValidTransition(from, to);
      results['Valid: ${from.value} → ${to.value}'] = isValid;
    }

    // Test invalid transitions
    final invalidTransitions = [
      (DriverOrderStatus.available, DriverOrderStatus.delivered),
      (DriverOrderStatus.assigned, DriverOrderStatus.pickedUp),
      (DriverOrderStatus.delivered, DriverOrderStatus.assigned),
      (DriverOrderStatus.onRouteToVendor, DriverOrderStatus.onRouteToCustomer),
    ];

    for (final (from, to) in invalidTransitions) {
      final isValid = DriverOrderStateMachine.isValidTransition(from, to);
      results['Invalid: ${from.value} → ${to.value}'] = !isValid; // Should be false
    }

    return results;
  }

  /// Generate test report
  static String generateTestReport(
    Map<String, bool> testResults,
    Map<String, String> testDetails,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('Driver Workflow Test Report');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    final totalTests = testResults.length;
    final passedTests = testResults.values.where((result) => result).length;
    final failedTests = totalTests - passedTests;

    buffer.writeln('SUMMARY:');
    buffer.writeln('Total Tests: $totalTests');
    buffer.writeln('Passed: $passedTests');
    buffer.writeln('Failed: $failedTests');
    buffer.writeln('Success Rate: ${((passedTests / totalTests) * 100).toStringAsFixed(1)}%');
    buffer.writeln();

    buffer.writeln('DETAILED RESULTS:');
    testResults.forEach((testName, passed) {
      final status = passed ? 'PASS' : 'FAIL';
      final details = testDetails[testName] ?? 'No details available';
      buffer.writeln('[$status] $testName');
      buffer.writeln('   $details');
      buffer.writeln();
    });

    return buffer.toString();
  }

  /// Print test results to console
  static void printTestResults(
    Map<String, bool> testResults,
    Map<String, String> testDetails,
  ) {
    final separator = '=' * 60;
    print('\n$separator');
    print('📊 DRIVER WORKFLOW TEST RESULTS');
    print(separator);

    final totalTests = testResults.length;
    final passedTests = testResults.values.where((result) => result).length;
    final failedTests = totalTests - passedTests;

    print('\n📈 SUMMARY:');
    print('   Total Tests: $totalTests');
    print('   Passed: $passedTests');
    print('   Failed: $failedTests');
    print('   Success Rate: ${((passedTests / totalTests) * 100).toStringAsFixed(1)}%');

    print('\n📋 DETAILED RESULTS:');
    testResults.forEach((testName, passed) {
      final status = passed ? '✅ PASS' : '❌ FAIL';
      final details = testDetails[testName] ?? 'No details available';
      print('   $status $testName');
      print('      $details');
    });

    print('\n$separator');
  }

  /// Create test data for performance testing
  static List<Map<String, dynamic>> createBulkTestOrders(int count) {
    return List.generate(count, (index) => {
      'customer_id': testConfig['testCustomerId'],
      'vendor_id': testConfig['testVendorId'],
      'total_amount': 20.0 + (index * 5.0),
      'status': 'ready',
      'delivery_method': 'own_fleet',
      'delivery_address': 'Test Address $index, Kuala Lumpur',
      'contact_phone': '+6012345678$index',
      'order_number': 'PERF-TEST-$index-${DateTime.now().millisecondsSinceEpoch}',
      'vendor_name': 'Test Vendor $index',
      'customer_name': 'Test Customer $index',
    });
  }

  /// Cleanup bulk test data
  static Future<void> cleanupBulkTestOrders(
    SupabaseClient supabase,
    List<String> orderIds,
  ) async {
    try {
      await supabase
          .from('orders')
          .delete()
          .inFilter('id', orderIds);
    } catch (e) {
      debugPrint('Failed to cleanup bulk test orders: $e');
    }
  }
}
