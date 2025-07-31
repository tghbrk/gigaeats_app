import 'package:supabase_flutter/supabase_flutter.dart';

/// Test script to debug delivery completion workflow
Future<void> main() async {
  print('🧪 Testing Delivery Completion Workflow...');
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://abknoalhfltlhhdbclpv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzM4MjY5NzQsImV4cCI6MjA0OTQwMjk3NH0.Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8',
  );
  
  final supabase = Supabase.instance.client;
  
  // Test authentication
  print('\n🔐 Testing Authentication...');
  try {
    final response = await supabase.auth.signInWithPassword(
      email: 'necros@gmail.com',
      password: 'Testpass123!',
    );
    print('✅ Authentication successful: ${response.user?.email}');
  } catch (e) {
    print('❌ Authentication failed: $e');
    return;
  }
  
  // Test order status update
  await testOrderStatusUpdate(supabase);
  
  // Test provider refresh
  await testProviderRefresh(supabase);
  
  print('\n✅ All tests completed!');
}

Future<void> testOrderStatusUpdate(SupabaseClient supabase) async {
  print('\n📦 Testing Order Status Update...');
  
  final testOrderId = '856497cc-42eb-4247-8dd5-24c7bfa46e14';
  final testDriverId = '10aa81ab-2fd6-4cef-90f4-f728f39d0e79';
  
  try {
    // Check if order exists
    final orderCheck = await supabase
        .from('orders')
        .select('id, status, assigned_driver_id')
        .eq('id', testOrderId)
        .maybeSingle();
    
    if (orderCheck == null) {
      print('❌ Test order not found: $testOrderId');
      return;
    }
    
    print('✅ Order found: ${orderCheck['id']} (Status: ${orderCheck['status']})');
    
    // Test the RPC call that the app makes
    print('\n🔄 Testing RPC call: update_driver_order_status');
    final rpcResult = await supabase.rpc('update_driver_order_status', params: {
      'p_order_id': testOrderId,
      'p_new_status': 'delivered',
      'p_driver_id': testDriverId,
      'p_notes': 'Test delivery completion from debug script',
    });
    
    print('✅ RPC call result: $rpcResult');
    
    // Check order status after update
    final updatedOrder = await supabase
        .from('orders')
        .select('id, status, actual_delivery_time, assigned_driver_id')
        .eq('id', testOrderId)
        .single();

    print('✅ Updated order status: ${updatedOrder['status']}');
    print('✅ Delivered at: ${updatedOrder['actual_delivery_time']}');
    
  } catch (e) {
    print('❌ Error testing order status update: $e');
  }
}

Future<void> testProviderRefresh(SupabaseClient supabase) async {
  print('\n🔄 Testing Provider Data Refresh...');
  
  final testDriverId = '10aa81ab-2fd6-4cef-90f4-f728f39d0e79';
  
  try {
    // Simulate getting driver orders (like the provider does)
    final driverOrders = await supabase
        .from('orders')
        .select('''
          id,
          order_number,
          status,
          vendor_name,
          vendor_address,
          delivery_address,
          delivery_fee,
          customer_name,
          special_instructions,
          created_at,
          updated_at
        ''')
        .eq('assigned_driver_id', testDriverId)
        .order('created_at', ascending: false);
    
    print('✅ Found ${driverOrders.length} orders for driver');
    
    // Filter active orders (like activeDriverOrdersProvider does)
    final activeOrders = driverOrders.where((order) {
      final status = order['status'] as String;
      return status == 'assigned' || status == 'preparing' || status == 'out_for_delivery';
    }).toList();
    
    print('✅ Active orders: ${activeOrders.length}');
    
    // Filter completed orders (like completedDriverOrdersProvider does)
    final completedOrders = driverOrders.where((order) {
      final status = order['status'] as String;
      return status == 'delivered' || status == 'cancelled';
    }).toList();
    
    print('✅ Completed orders: ${completedOrders.length}');
    
    // Print order details for debugging
    for (final order in driverOrders.take(3)) {
      print('  📋 Order ${order['order_number']}: ${order['status']}');
    }
    
  } catch (e) {
    print('❌ Error testing provider refresh: $e');
  }
}
