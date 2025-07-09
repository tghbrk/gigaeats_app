import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://abknoalhfltlhhdbclpv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQzMzQ4NzQsImV4cCI6MjA0OTkxMDg3NH0.Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8',
  );

  final supabase = Supabase.instance.client;

  print('🧪 Testing Driver Order Acceptance Fix');
  print('=====================================');

  try {
    // Sign in as test driver
    print('\n🔐 Signing in as test driver...');
    final authResponse = await supabase.auth.signInWithPassword(
      email: 'driver.test@gigaeats.com',
      password: 'Testpass123!',
    );

    if (authResponse.user == null) {
      print('❌ Failed to sign in as driver');
      return;
    }

    print('✅ Signed in as driver: ${authResponse.user!.email}');

    // Get driver ID
    final driverQuery = await supabase
        .from('drivers')
        .select('id, status, is_active')
        .eq('user_id', authResponse.user!.id)
        .single();

    final driverId = driverQuery['id'];
    print('✅ Driver ID: $driverId');
    print('✅ Driver Status: ${driverQuery['status']}');
    print('✅ Driver Active: ${driverQuery['is_active']}');

    // Check for available orders
    print('\n📋 Checking for available orders...');
    final availableOrders = await supabase
        .from('orders')
        .select('id, status, vendor_id, total_amount')
        .eq('status', 'ready')
        .isFilter('assigned_driver_id', null)
        .limit(5);

    print('✅ Found ${availableOrders.length} available orders');

    if (availableOrders.isEmpty) {
      print('⚠️ No available orders to test with. Creating a test order...');

      // Create a test order
      final testOrder = await supabase
          .from('orders')
          .insert({
            'customer_id': authResponse.user!.id, // Use driver as customer for test
            'vendor_id': 'f47ac10b-58cc-4372-a567-0e02b2c3d479', // Use a test vendor ID
            'total_amount': 25.50,
            'status': 'ready',
            'delivery_method': 'ownFleet',
            'delivery_address': 'Test Address, Kuala Lumpur',
            'contact_phone': '+60123456789',
            'order_number': 'TEST-${DateTime.now().millisecondsSinceEpoch}',
          })
          .select()
          .single();

      print('✅ Created test order: ${testOrder['id']}');
      availableOrders.add(testOrder);
    }

    final testOrderId = availableOrders.first['id'];
    print('\n🎯 Testing order acceptance with order: $testOrderId');

    // Test the fixed order acceptance logic
    print('\n🔄 Testing order acceptance...');

    // First verify the driver exists and is active
    final driverCheck = await supabase
        .from('drivers')
        .select('id, status, is_active')
        .eq('id', driverId)
        .eq('is_active', true)
        .single();

    if (driverCheck['status'] != 'online') {
      print('❌ Driver must be online to accept orders. Current status: ${driverCheck['status']}');
      return;
    }

    print('✅ Driver status validation passed');

    // Update order with driver assignment and status using enhanced workflow
    final response = await supabase
        .from('orders')
        .update({
          'assigned_driver_id': driverId,
          'status': 'assigned', // Enhanced workflow: ready → assigned
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', testOrderId)
        .eq('status', 'ready') // Only accept orders that are ready
        .isFilter('assigned_driver_id', null) // Ensure order is not already assigned
        .select(); // Add select to get the updated rows back

    final success = response.isNotEmpty;
    print('✅ Order acceptance result: $success, updated ${response.length} row(s)');

    if (success) {
      // Update driver status to on_delivery
      await supabase
          .from('drivers')
          .update({
            'status': 'on_delivery',
            'last_seen': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      print('✅ Driver status updated to on_delivery');
      print('🎉 Order acceptance test PASSED!');
    } else {
      print('❌ Order acceptance test FAILED!');
    }

    // Clean up - reset driver status
    print('\n🧹 Cleaning up...');
    await supabase
        .from('drivers')
        .update({
          'status': 'online',
          'last_seen': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', driverId);

    print('✅ Driver status reset to online');

  } catch (e) {
    print('❌ Test failed with error: $e');
  }

  print('\n🏁 Test completed');
}