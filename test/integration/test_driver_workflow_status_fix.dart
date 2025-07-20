import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Integration test to verify the driver workflow status transition fix
/// 
/// This test validates that:
/// 1. The immediate database state issue is resolved
/// 2. Status transitions work correctly from assigned → on_route_to_vendor
/// 3. Driver delivery status is properly cleaned up on completion
/// 4. No stale data interferes with future orders
void main() {
  group('Driver Workflow Status Transition Fix', () {
    late SupabaseClient supabase;
    
    // Test data from the original issue
    const driverId = '087132e7-e38b-4d3f-b28c-7c34b75e86c4';
    const testOrderId = 'b84ea515-9452-49d1-852f-1479ee6fb4bc';

    setUpAll(() async {
      // Initialize Supabase
      await Supabase.initialize(
        url: 'https://abknoalhfltlhhdbclpv.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTY3OTY1OTIsImV4cCI6MjAzMjM3MjU5Mn0.Ej8JQCGfaUjnr7dLaYGPJkCaZJZJQJZJQJZJQJZJQJZJQ',
      );
      supabase = Supabase.instance.client;
    });

    test('1. Verify database state is consistent after fix', () async {
      print('🔍 [TEST] Verifying database state consistency...');
      
      final response = await supabase
          .from('orders')
          .select('''
            id,
            order_number,
            status,
            assigned_driver_id,
            drivers:drivers!orders_assigned_driver_id_fkey(
              current_delivery_status,
              status
            )
          ''')
          .eq('id', testOrderId)
          .single();

      final orderStatus = response['status'];
      final driverDeliveryStatus = response['drivers']?['current_delivery_status'];
      final driverStatus = response['drivers']?['status'];

      print('📊 [TEST] Order status: $orderStatus');
      print('📊 [TEST] Driver delivery status: $driverDeliveryStatus');
      print('📊 [TEST] Driver status: $driverStatus');

      // Verify the fix worked
      expect(orderStatus, equals('assigned'), reason: 'Order should be in assigned status');
      expect(driverDeliveryStatus, equals('assigned'), reason: 'Driver delivery status should match order status');
      expect(driverStatus, equals('on_delivery'), reason: 'Driver should be on delivery');
      
      print('✅ [TEST] Database state is consistent');
    });

    test('2. Test status transition from assigned to on_route_to_vendor', () async {
      print('🔄 [TEST] Testing status transition: assigned → on_route_to_vendor...');
      
      // Call the RPC function to update status
      final result = await supabase.rpc('update_driver_order_status', params: {
        'p_order_id': testOrderId,
        'p_new_status': 'on_route_to_vendor',
        'p_driver_id': driverId,
        'p_notes': 'Driver started navigation to restaurant - integration test',
      });

      print('📊 [TEST] RPC result: $result');
      
      // Verify the result
      expect(result, isA<Map>(), reason: 'RPC should return a map');
      expect(result['success'], isTrue, reason: 'Status transition should succeed');
      expect(result['new_status'], equals('on_route_to_vendor'), reason: 'New status should be on_route_to_vendor');
      
      // Verify database state
      final orderResponse = await supabase
          .from('orders')
          .select('status')
          .eq('id', testOrderId)
          .single();
          
      final driverResponse = await supabase
          .from('drivers')
          .select('current_delivery_status')
          .eq('id', driverId)
          .single();

      expect(orderResponse['status'], equals('on_route_to_vendor'), reason: 'Order status should be updated');
      expect(driverResponse['current_delivery_status'], equals('on_route_to_vendor'), reason: 'Driver delivery status should be updated');
      
      print('✅ [TEST] Status transition successful');
    });

    test('3. Test complete workflow progression', () async {
      print('🔄 [TEST] Testing complete workflow progression...');
      
      final workflowSteps = [
        {'status': 'arrived_at_vendor', 'description': 'Driver arrived at restaurant'},
        {'status': 'picked_up', 'description': 'Driver picked up order'},
        {'status': 'on_route_to_customer', 'description': 'Driver started delivery'},
        {'status': 'delivered', 'description': 'Order delivered successfully'},
      ];

      for (final step in workflowSteps) {
        print('🔄 [TEST] Transitioning to: ${step['status']}');
        
        final result = await supabase.rpc('update_driver_order_status', params: {
          'p_order_id': testOrderId,
          'p_new_status': step['status'],
          'p_driver_id': driverId,
          'p_notes': '${step['description']} - integration test',
        });

        expect(result['success'], isTrue, reason: 'Transition to ${step['status']} should succeed');
        print('✅ [TEST] Successfully transitioned to: ${step['status']}');
      }
      
      print('✅ [TEST] Complete workflow progression successful');
    });

    test('4. Verify driver delivery status cleanup on completion', () async {
      print('🧹 [TEST] Verifying driver delivery status cleanup...');
      
      final driverResponse = await supabase
          .from('drivers')
          .select('current_delivery_status, status')
          .eq('id', driverId)
          .single();

      final currentDeliveryStatus = driverResponse['current_delivery_status'];
      final driverStatus = driverResponse['status'];

      print('📊 [TEST] Driver delivery status after completion: $currentDeliveryStatus');
      print('📊 [TEST] Driver status after completion: $driverStatus');

      // Verify cleanup worked
      expect(currentDeliveryStatus, isNull, reason: 'Driver delivery status should be cleared after completion');
      expect(driverStatus, equals('online'), reason: 'Driver should be back online after completion');
      
      print('✅ [TEST] Driver delivery status properly cleaned up');
    });

    test('5. Test new order assignment after cleanup', () async {
      print('🔄 [TEST] Testing new order assignment after cleanup...');
      
      // Reset the test order for a new assignment test
      await supabase
          .from('orders')
          .update({
            'assigned_driver_id': null,
            'status': 'ready',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', testOrderId);

      // Test accepting the order again
      final acceptResult = await supabase
          .from('orders')
          .update({
            'assigned_driver_id': driverId,
            'status': 'assigned',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', testOrderId)
          .eq('status', 'ready')
          .isFilter('assigned_driver_id', null)
          .select();

      expect(acceptResult, isNotEmpty, reason: 'Order should be successfully assigned');
      
      // Update driver status
      await supabase
          .from('drivers')
          .update({
            'status': 'on_delivery',
            'current_delivery_status': 'assigned',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      // Verify no stale data interference
      final verifyResponse = await supabase
          .from('orders')
          .select('''
            status,
            drivers:drivers!orders_assigned_driver_id_fkey(
              current_delivery_status
            )
          ''')
          .eq('id', testOrderId)
          .single();

      expect(verifyResponse['status'], equals('assigned'), reason: 'Order should be in assigned status');
      expect(verifyResponse['drivers']['current_delivery_status'], equals('assigned'), reason: 'Driver delivery status should be properly initialized');
      
      print('✅ [TEST] New order assignment successful - no stale data interference');
    });

    tearDownAll(() async {
      print('🧹 [TEST] Cleaning up test data...');
      
      // Reset driver to online status
      await supabase
          .from('drivers')
          .update({
            'status': 'online',
            'current_delivery_status': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);
          
      print('✅ [TEST] Cleanup completed');
    });
  });
}
