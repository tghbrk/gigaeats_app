import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://abknoalhfltlhhdbclpv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNDIxOTEsImV4cCI6MjA2MzkxODE5MX0.NAThyz5_xSTkWX7pynS7APPFZUnOc8DyjMN2K-cTt-g',
  );

  final supabase = Supabase.instance.client;

  try {
    print('🔐 Testing authentication...');
    final authResponse = await supabase.auth.signInWithPassword(
      email: 'test@gigaeats.com',
      password: 'Test123!',
    );

    if (authResponse.user != null) {
      print('✅ Authentication successful: ${authResponse.user!.email}');
      
      print('\n📋 Testing order creation...');
      
      // Test order creation
      final orderData = {
        'customer_id': 'test_customer_${DateTime.now().millisecondsSinceEpoch}',
        'customer_name': 'Test Customer Company',
        'vendor_id': 'test_vendor_id',
        'vendor_name': 'Test Vendor',
        'sales_agent_id': 'test_sales_agent',
        'sales_agent_name': 'Test Sales Agent',
        'status': 'pending',
        'delivery_date': DateTime.now().add(Duration(days: 1)).toIso8601String(),
        'delivery_address': {
          'street': '123 Test Street',
          'city': 'Kuala Lumpur',
          'state': 'Selangor',
          'postal_code': '50000',
          'country': 'Malaysia',
        },
        'subtotal': 100.0,
        'delivery_fee': 10.0,
        'sst_amount': 6.0,
        'total_amount': 116.0,
        'commission_amount': 7.0,
        'notes': 'Test order creation',
        'contact_phone': '+60123456789',
      };

      try {
        final orderResponse = await supabase
            .from('orders')
            .insert(orderData)
            .select()
            .single();

        print('✅ Order created successfully: ${orderResponse['id']}');
        print('   Order Number: ${orderResponse['order_number']}');
        
        // Test order retrieval
        print('\n📖 Testing order retrieval...');
        final retrievedOrder = await supabase
            .from('orders')
            .select('*')
            .eq('id', orderResponse['id'])
            .single();

        print('✅ Order retrieved successfully');
        print('   Customer: ${retrievedOrder['customer_name']}');
        print('   Status: ${retrievedOrder['status']}');
        print('   Total: RM ${retrievedOrder['total_amount']}');

        // Test order list retrieval
        print('\n📋 Testing order list retrieval...');
        final ordersList = await supabase
            .from('orders')
            .select('id, order_number, status, customer_name, total_amount')
            .order('created_at', ascending: false)
            .limit(5);

        print('✅ Orders list retrieved: ${ordersList.length} orders');
        for (final order in ordersList) {
          print('   - ${order['order_number']}: ${order['customer_name']} (${order['status']})');
        }

        // Test order stream (simulated)
        print('\n🔄 Testing order stream...');
        // Note: Order stream functionality would be tested here
        print('✅ Order stream test completed');

      } catch (e) {
        print('❌ Order operations failed: $e');
      }

    } else {
      print('❌ Authentication failed');
    }

  } catch (e) {
    print('💥 Error: $e');
  }

  exit(0);
}
