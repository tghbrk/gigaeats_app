import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://abknoalhfltlhhdbclpv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTkwNDY4NzQsImV4cCI6MjAzNDYyMjg3NH0.Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8',
  );

  final supabase = Supabase.instance.client;
  
  print('🔍 Testing driver wallet database function...');
  
  try {
    // Test the RPC function directly
    final response = await supabase
        .rpc('get_or_create_driver_wallet', params: {
          'p_user_id': '5a400967-c68e-48fa-a222-ef25249de974',
        });

    print('✅ RPC Response: $response');
    
    if (response != null && response.isNotEmpty) {
      final walletData = response[0];
      print('✅ Wallet ID: ${walletData['id']}');
      print('✅ Available Balance: ${walletData['available_balance']}');
      print('✅ Currency: ${walletData['currency']}');
      print('✅ Is Active: ${walletData['is_active']}');
    } else {
      print('❌ No wallet data returned');
    }
    
  } catch (e) {
    print('❌ Error testing wallet function: $e');
  }
}
