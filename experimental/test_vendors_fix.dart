import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase client
  final supabase = SupabaseClient(
    'https://abknoalhfltlhhdbclpv.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNDIxOTEsImV4cCI6MjA2MzkxODE5MX0.NAThyz5_xSTkWX7pynS7APPFZUnOc8DyjMN2K-cTt-g',
  );

  try {
    print('🔐 Testing authentication...');
    final authResponse = await supabase.auth.signInWithPassword(
      email: 'test@gigaeats.com',
      password: 'Test123!',
    );

    if (authResponse.user != null) {
      print('✅ Authentication successful: ${authResponse.user!.email}');
      print('   User ID: ${authResponse.user!.id}');
      
      print('\n📋 Testing vendors query with new foreign key...');
      
      // Test the basic vendors query (what the app uses)
      final vendorsResponse = await supabase
          .from('vendors')
          .select('*')
          .eq('is_active', true)
          .limit(5);
      
      print('✅ Basic vendors query successful: ${vendorsResponse.length} vendors found');
      
      // Test the vendors query with user join (what was failing)
      print('\n🔗 Testing vendors query with user join...');
      try {
        final vendorsWithUserResponse = await supabase
            .from('vendors')
            .select('''
              *,
              user:users!vendors_user_id_fkey(
                id,
                email,
                full_name,
                phone_number,
                profile_image_url
              )
            ''')
            .eq('is_active', true)
            .limit(5);
        
        print('✅ Vendors with user join successful: ${vendorsWithUserResponse.length} vendors found');
        
        if (vendorsWithUserResponse.isNotEmpty) {
          final firstVendor = vendorsWithUserResponse.first;
          print('   First vendor: ${firstVendor['business_name']}');
          print('   User data: ${firstVendor['user']}');
        }
        
      } catch (e) {
        print('❌ Vendors with user join failed: $e');
      }
      
      // Test specific vendor by ID (what was in the error logs)
      print('\n🎯 Testing specific vendor by ID...');
      try {
        final specificVendorResponse = await supabase
            .from('vendors')
            .select('''
              *,
              user:users!vendors_user_id_fkey(
                id,
                email,
                full_name,
                phone_number,
                profile_image_url
              )
            ''')
            .eq('id', '550e8400-e29b-41d4-a716-446655440101')
            .single();
        
        print('✅ Specific vendor query successful');
        print('   Vendor: ${specificVendorResponse['business_name']}');
        print('   User data: ${specificVendorResponse['user']}');
        
      } catch (e) {
        print('❌ Specific vendor query failed: $e');
      }
      
    } else {
      print('❌ Authentication failed');
    }

  } catch (e) {
    print('💥 Error: $e');
  }

  exit(0);
}
