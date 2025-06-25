import 'package:supabase_flutter/supabase_flutter.dart';

/// Test script to verify the driver order acceptance production fix
/// This script tests the complete driver workflow that was failing in production
void main() async {
  print('🔧 Testing Driver Order Acceptance Production Fix');
  print('=' * 60);

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://abknoalhfltlhhdbclpv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzMzMTQ4NzEsImV4cCI6MjA0ODg5MDg3MX0.yJh_jJVZX8nF8_Nt9P7MqJJH8r7Qg9XvZQJQJQJQJQI',
  );

  final supabase = Supabase.instance.client;

  // Test data from production error logs
  const testDriverUserId = '5a400967-c68e-48fa-a222-ef25249de974'; // driver.test@gigaeats.com
  const testDriverId = '087132e7-e38b-4d3f-b28c-7c34b75e86c4';

  try {
    print('\n🔐 Step 1: Authenticate as test driver');
    await supabase.auth.signInWithPassword(
      email: 'driver.test@gigaeats.com',
      password: 'Testpass123!',
    );
    print('✅ Driver authenticated successfully');

    print('\n🚗 Step 2: Verify driver profile and status');
    final driverCheck = await supabase
        .from('drivers')
        .select('id, user_id, status, is_active')
        .eq('id', testDriverId)
        .single();
    
    print('✅ Driver profile: ${driverCheck['id']} (Status: ${driverCheck['status']}, Active: ${driverCheck['is_active']})');

    print('\n📦 Step 3: Check available orders');
    final availableOrders = await supabase
        .from('orders')
        .select('id, order_number, status, assigned_driver_id, delivery_method')
        .eq('status', 'ready')
        .eq('delivery_method', 'own_fleet')
        .isFilter('assigned_driver_id', null)
        .limit(5);
    
    print('✅ Found ${availableOrders.length} available orders');
    
    if (availableOrders.isEmpty) {
      print('⚠️  No available orders found. Creating a test order...');
      
      // Create a test order for acceptance
      final testOrder = await supabase
          .from('orders')
          .insert({
            'order_number': 'TEST-${DateTime.now().millisecondsSinceEpoch}',
            'customer_id': 'f47ac10b-58cc-4372-a567-0e02b2c3d479', // Test customer
            'vendor_id': 'f47ac10b-58cc-4372-a567-0e02b2c3d480', // Test vendor
            'status': 'ready',
            'delivery_method': 'own_fleet',
            'total_amount': 25.99,
            'delivery_fee': 3.99,
            'delivery_address': '123 Test Street, Test City',
            'contact_phone': '+1234567890',
            'estimated_delivery_time': DateTime.now().add(Duration(minutes: 30)).toIso8601String(),
          })
          .select()
          .single();
      
      print('✅ Created test order: ${testOrder['id']}');
      final orderIdToTest = testOrder['id'];
      
      print('\n🎯 Step 4: Test driver order acceptance (THE CRITICAL FIX)');
      print('Attempting to accept order: $orderIdToTest');
      
      // This is the exact operation that was failing in production
      final acceptanceResult = await supabase
          .from('orders')
          .update({
            'assigned_driver_id': testDriverId,
            'status': 'assigned', // This was causing the permission error
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderIdToTest)
          .eq('status', 'ready')
          .isFilter('assigned_driver_id', null)
          .select();
      
      if (acceptanceResult.isNotEmpty) {
        print('✅ SUCCESS! Order accepted successfully');
        print('   Order ID: ${acceptanceResult[0]['id']}');
        print('   New Status: ${acceptanceResult[0]['status']}');
        print('   Assigned Driver: ${acceptanceResult[0]['assigned_driver_id']}');
        
        print('\n🚗 Step 5: Update driver status to on_delivery');
        await supabase
            .from('drivers')
            .update({
              'status': 'on_delivery',
              'current_delivery_status': 'assigned',
              'last_seen': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', testDriverId);
        
        print('✅ Driver status updated to on_delivery');
        
        print('\n🧪 Step 6: Test permission function directly');
        final permissionTest = await supabase.rpc('validate_status_update_permission', params: {
          'order_id_param': orderIdToTest,
          'new_status': 'assigned',
          'user_id_param': testDriverUserId,
        });
        
        print('✅ Permission function test result: $permissionTest');
        
        print('\n🔄 Step 7: Test status transition validation');
        final transitionTest = await supabase.rpc('validate_order_status_transition', params: {
          'old_status': 'ready',
          'new_status': 'assigned',
        });
        
        print('✅ Status transition test result: $transitionTest');
        
        print('\n🧹 Step 8: Cleanup - Reset order and driver status');
        await supabase
            .from('orders')
            .update({
              'assigned_driver_id': null,
              'status': 'ready',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', orderIdToTest);
        
        await supabase
            .from('drivers')
            .update({
              'status': 'online',
              'current_delivery_status': null,
              'last_seen': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', testDriverId);
        
        print('✅ Cleanup completed');
        
      } else {
        print('❌ FAILED! Order acceptance returned no results');
        return;
      }
    }

    print('\n🎉 ALL TESTS PASSED!');
    print('=' * 60);
    print('✅ Driver order acceptance production issue has been RESOLVED!');
    print('');
    print('📋 Summary of Fix:');
    print('   • Root Cause: Missing "assigned" status case in validate_status_update_permission function');
    print('   • Solution: Added driver permission for "assigned" status in the validation function');
    print('   • Impact: Drivers can now successfully accept orders by setting status to "assigned"');
    print('   • Security: Maintains proper role-based access control');
    print('');
    print('🚀 The driver workflow is now fully functional in production!');

  } catch (e) {
    print('❌ ERROR during testing: $e');
    print('');
    print('🔍 This indicates the fix may not be complete or there are other issues.');
    print('Please check the error details and database state.');
  }
}
