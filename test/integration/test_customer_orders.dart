import 'package:flutter/material.dart';
import 'package:gigaeats_app/src/features/orders/data/repositories/order_repository.dart';

/// Test script to verify customer order access fix
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Testing customer order access...');
  
  try {
    final orderRepository = OrderRepository();
    
    print('🔍 Attempting to get orders for customer user...');
    final orders = await orderRepository.getOrders(limit: 10);
    
    print('✅ SUCCESS: Customer can access orders!');
    print('📊 Found ${orders.length} orders');
    
    for (int i = 0; i < orders.length && i < 3; i++) {
      final order = orders[i];
      print('   Order ${i + 1}: ${order.orderNumber} - ${order.status.value} - ${order.customerName}');
    }
    
  } catch (e) {
    print('❌ ERROR: Customer order access failed');
    print('💥 Error details: $e');
    
    if (e.toString().contains('Invalid user role for order access')) {
      print('🚨 This is the exact error we were trying to fix!');
      print('🔧 The customer role is not being handled in the switch statement');
    }
  }
  
  print('🧪 Test completed');
}
