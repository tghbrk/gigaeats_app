import 'package:supabase_flutter/supabase_flutter.dart';

/// Debug script to test driver assignment and permission validation
/// This will help identify why the driver workflow status update is failing
void main() async {
  print('🔍 Driver Assignment Debug Test');
  print('================================');

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ixqhqfqjqjqjqjqjqjqj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4cWhxZnFqcWpxanFqcWpxanFqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ0MzI2NzQsImV4cCI6MjA1MDAwODY3NH0.Ej8JgGJZlQOjqJXGBBBJQJQJQJQJQJQJQJQJQJQJQJQ',
  );

  final supabase = Supabase.instance.client;

  try {
    print('\n🔐 Step 1: Authenticate as driver');
    
    // Sign in as the test driver
    final authResponse = await supabase.auth.signInWithPassword(
      email: 'driver.test@gigaeats.com',
      password: 'TestDriver123!',
    );

    if (authResponse.user == null) {
      print('❌ Failed to authenticate driver');
      return;
    }

    print('✅ Driver authenticated: ${authResponse.user!.email}');
    print('   User ID: ${authResponse.user!.id}');

    print('\n📋 Step 2: Get driver details');
    
    // Get driver details
    final driverQuery = await supabase
        .from('drivers')
        .select('id, user_id, is_active, status, current_delivery_status')
        .eq('user_id', authResponse.user!.id)
        .maybeSingle();

    if (driverQuery == null) {
      print('❌ Driver record not found');
      return;
    }

    print('✅ Driver found:');
    print('   Driver ID: ${driverQuery['id']}');
    print('   User ID: ${driverQuery['user_id']}');
    print('   Is Active: ${driverQuery['is_active']}');
    print('   Status: ${driverQuery['status']}');
    print('   Current Delivery Status: ${driverQuery['current_delivery_status']}');

    final driverId = driverQuery['id'] as String;

    print('\n📦 Step 3: Find assigned order');
    
    // Find orders assigned to this driver
    final ordersQuery = await supabase
        .from('orders')
        .select('id, order_number, status, assigned_driver_id, vendor_id, customer_id')
        .eq('assigned_driver_id', driverId)
        .eq('status', 'assigned')
        .limit(1);

    if (ordersQuery.isEmpty) {
      print('❌ No assigned orders found with status "assigned"');
      
      // Check if there are any orders assigned to this driver
      final allOrdersQuery = await supabase
          .from('orders')
          .select('id, order_number, status, assigned_driver_id')
          .eq('assigned_driver_id', driverId)
          .limit(5);
      
      print('📋 All orders assigned to driver:');
      for (final order in allOrdersQuery) {
        print('   Order ${order['order_number']}: ${order['status']}');
      }
      return;
    }

    final order = ordersQuery.first;
    final orderId = order['id'] as String;
    
    print('✅ Found assigned order:');
    print('   Order ID: $orderId');
    print('   Order Number: ${order['order_number']}');
    print('   Status: ${order['status']}');
    print('   Assigned Driver ID: ${order['assigned_driver_id']}');

    print('\n🔍 Step 4: Test permission validation');
    
    // Test permission for on_route_to_vendor status
    try {
      final permissionResult = await supabase.rpc('validate_status_update_permission', params: {
        'order_id_param': orderId,
        'new_status': 'on_route_to_vendor',
        'user_id_param': authResponse.user!.id,
      });

      print('✅ Permission validation result: $permissionResult');
      
      if (permissionResult == true) {
        print('✅ Driver has permission to update to on_route_to_vendor');
      } else {
        print('❌ Driver does NOT have permission to update to on_route_to_vendor');
        print('   This is the root cause of the issue!');
      }
    } catch (e) {
      print('❌ Error testing permission: $e');
    }

    print('\n🧪 Step 5: Test direct status update');
    
    // Test the actual RPC function that's failing
    try {
      final updateResult = await supabase.rpc('update_driver_order_status', params: {
        'p_order_id': orderId,
        'p_new_status': 'on_route_to_vendor',
        'p_driver_id': driverId,
        'p_notes': 'Debug test - driver starting navigation to vendor',
      });

      print('✅ Status update result: $updateResult');
      
      if (updateResult is Map && updateResult['success'] == true) {
        print('✅ Status update successful!');
        print('   Old status: ${updateResult['old_status']}');
        print('   New status: ${updateResult['new_status']}');
      } else {
        print('❌ Status update failed: $updateResult');
      }
    } catch (e) {
      print('❌ Error updating status: $e');
    }

    print('\n📊 Step 6: Verify final state');
    
    // Check the order status after update attempt
    final finalOrderQuery = await supabase
        .from('orders')
        .select('id, status, assigned_driver_id')
        .eq('id', orderId)
        .single();

    print('✅ Final order state:');
    print('   Order ID: ${finalOrderQuery['id']}');
    print('   Status: ${finalOrderQuery['status']}');
    print('   Assigned Driver ID: ${finalOrderQuery['assigned_driver_id']}');

  } catch (e) {
    print('❌ Test failed with error: $e');
  }

  print('\n🏁 Debug test completed');
}
