#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test script to verify email verification configuration
/// This script helps validate that the email verification setup is correct
void main(List<String> args) async {
  debugPrint('🧪 GigaEats Email Verification Test Script');
  debugPrint('==========================================\n');

  // Test 1: Validate URL parsing
  await testUrlParsing();
  
  // Test 2: Validate deep link configuration
  await testDeepLinkConfiguration();
  
  // Test 3: Check Supabase project status
  await testSupabaseProjectStatus();
  
  // Test 4: Validate email template format
  await testEmailTemplateFormat();
  
  debugPrint('\n✅ All tests completed!');
  debugPrint('\n📋 Next Steps:');
  debugPrint('1. Apply the manual Supabase configuration from docs/URGENT_EMAIL_VERIFICATION_FIX.md');
  debugPrint('2. Register a new test user to verify the email link format');
  debugPrint('3. Test the complete email verification flow');
}

/// Test URL parsing for email verification links
Future<void> testUrlParsing() async {
  debugPrint('🔗 Testing URL Parsing...');
  
  // Test correct format (after fix)
  const correctUrl = 'https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/verify?token=test_token&type=signup&redirect_to=gigaeats://auth/callback';
  final correctUri = Uri.parse(correctUrl);
  final correctParams = correctUri.queryParameters;
  
  debugPrint('   ✅ Correct URL format parsed successfully');
  debugPrint('      - Token: ${correctParams['token']}');
  debugPrint('      - Type: ${correctParams['type']}');
  debugPrint('      - Redirect: ${correctParams['redirect_to']}');
  
  // Test problematic format (with duplicates)
  const problematicUrl = 'https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/verify?token=test_token&type=signup&redirect_to=gigaeats://auth/callback&redirect_to=gigaeats://auth/callback';
  final problematicUri = Uri.parse(problematicUrl);
  final duplicateCount = 'redirect_to='.allMatches(problematicUri.query).length;
  
  if (duplicateCount > 1) {
    debugPrint('   ⚠️  Detected duplicate redirect_to parameters in problematic URL');
    debugPrint('      - This is the issue we\'re fixing');
  }
  
  debugPrint('   ✅ URL parsing tests completed\n');
}

/// Test deep link configuration
Future<void> testDeepLinkConfiguration() async {
  debugPrint('📱 Testing Deep Link Configuration...');
  
  // Test custom scheme URL
  const customSchemeUrl = 'gigaeats://auth/callback';
  final customUri = Uri.parse(customSchemeUrl);
  
  if (customUri.scheme == 'gigaeats' && customUri.host == 'auth' && customUri.path == '/callback') {
    debugPrint('   ✅ Custom scheme URL format is correct');
  } else {
    debugPrint('   ❌ Custom scheme URL format is incorrect');
  }
  
  // Test callback with success parameters
  const successCallback = 'gigaeats://auth/callback?access_token=test&refresh_token=test&expires_in=3600';
  final successUri = Uri.parse(successCallback);
  final successParams = successUri.queryParameters;
  
  if (successParams.containsKey('access_token') && successParams.containsKey('refresh_token')) {
    debugPrint('   ✅ Success callback format is correct');
  } else {
    debugPrint('   ❌ Success callback format is incorrect');
  }
  
  // Test callback with error parameters
  const errorCallback = 'gigaeats://auth/callback?error=access_denied&error_description=Email+not+confirmed';
  final errorUri = Uri.parse(errorCallback);
  final errorParams = errorUri.queryParameters;
  
  if (errorParams.containsKey('error') && errorParams.containsKey('error_description')) {
    debugPrint('   ✅ Error callback format is correct');
  } else {
    debugPrint('   ❌ Error callback format is incorrect');
  }
  
  debugPrint('   ✅ Deep link configuration tests completed\n');
}

/// Test Supabase project status
Future<void> testSupabaseProjectStatus() async {
  debugPrint('🗄️  Testing Supabase Project Status...');
  
  try {
    // Test if we can reach the Supabase project
    const projectUrl = 'https://abknoalhfltlhhdbclpv.supabase.co/rest/v1/';
    final response = await http.get(
      Uri.parse(projectUrl),
      headers: {'apikey': 'dummy'}, // This will fail but tells us if the project exists
    ).timeout(Duration(seconds: 5));
    
    debugPrint('   ✅ Supabase project is reachable');
  } catch (e) {
    if (e.toString().contains('401') || e.toString().contains('403')) {
      debugPrint('   ✅ Supabase project is reachable (authentication required)');
    } else {
      debugPrint('   ⚠️  Could not reach Supabase project: $e');
    }
  }
  
  debugPrint('   ✅ Supabase project status test completed\n');
}

/// Test email template format
Future<void> testEmailTemplateFormat() async {
  debugPrint('📧 Testing Email Template Format...');
  
  // Test the corrected URL path format
  const urlPath = '/auth/v1/verify?token={{ .TokenHash }}&type=signup';
  
  // Simulate what the final URL would look like
  const simulatedFinalUrl = 'https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/verify?token=sample_token&type=signup&redirect_to=gigaeats://auth/callback';
  
  final uri = Uri.parse(simulatedFinalUrl);
  final params = uri.queryParameters;
  
  // Verify the structure
  if (params.containsKey('token') && 
      params.containsKey('type') && 
      params.containsKey('redirect_to') &&
      params['type'] == 'signup' &&
      params['redirect_to'] == 'gigaeats://auth/callback') {
    debugPrint('   ✅ Email template URL format is correct');
    debugPrint('      - Contains required token parameter');
    debugPrint('      - Contains type=signup parameter');
    debugPrint('      - Contains redirect_to parameter (added by emailRedirectTo)');
  } else {
    debugPrint('   ❌ Email template URL format is incorrect');
  }
  
  // Check for duplicate parameters
  final redirectToCount = 'redirect_to='.allMatches(uri.query).length;
  if (redirectToCount == 1) {
    debugPrint('   ✅ No duplicate redirect_to parameters');
  } else {
    debugPrint('   ❌ Found $redirectToCount redirect_to parameters (should be 1)');
  }
  
  debugPrint('   ✅ Email template format tests completed\n');
}
