import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Email Verification Link Tests', () {
    test('should parse email verification link correctly without duplicate parameters', () {
      // Test the expected format after our fix
      const testLink = 'https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/verify?token=test_token&type=signup&redirect_to=gigaeats://auth/callback';
      
      final uri = Uri.parse(testLink);
      final queryParams = uri.queryParameters;
      
      // Verify the link structure
      expect(uri.scheme, equals('https'));
      expect(uri.host, equals('abknoalhfltlhhdbclpv.supabase.co'));
      expect(uri.path, equals('/auth/v1/verify'));
      
      // Verify query parameters
      expect(queryParams['token'], equals('test_token'));
      expect(queryParams['type'], equals('signup'));
      expect(queryParams['redirect_to'], equals('gigaeats://auth/callback'));
      
      // Verify no duplicate parameters by checking the raw query string
      final queryString = uri.query;
      final redirectToCount = 'redirect_to='.allMatches(queryString).length;
      expect(redirectToCount, equals(1), reason: 'Should have exactly one redirect_to parameter');
    });

    test('should handle problematic link with duplicate redirect_to parameters', () {
      // Test the problematic format that was causing issues
      const problematicLink = 'https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/verify?token=test_token&type=signup&redirect_to=gigaeats://auth/callback&redirect_to=gigaeats://auth/callback';
      
      final uri = Uri.parse(problematicLink);
      final queryParams = uri.queryParameters;
      
      // Uri.queryParameters automatically handles duplicates by taking the last value
      expect(queryParams['redirect_to'], equals('gigaeats://auth/callback'));
      
      // But we can detect the duplicate in the raw query string
      final queryString = uri.query;
      final redirectToCount = 'redirect_to='.allMatches(queryString).length;
      expect(redirectToCount, equals(2), reason: 'This is the problematic case with duplicates');
    });

    test('should validate deep link callback URL format', () {
      const callbackUrl = 'gigaeats://auth/callback';
      
      final uri = Uri.parse(callbackUrl);
      
      expect(uri.scheme, equals('gigaeats'));
      expect(uri.host, equals('auth'));
      expect(uri.path, equals('/callback'));
    });

    test('should validate Supabase auth callback with success parameters', () {
      const successCallback = 'gigaeats://auth/callback?access_token=test_access&refresh_token=test_refresh&expires_in=3600&token_type=bearer';
      
      final uri = Uri.parse(successCallback);
      final queryParams = uri.queryParameters;
      
      expect(uri.scheme, equals('gigaeats'));
      expect(uri.host, equals('auth'));
      expect(uri.path, equals('/callback'));
      
      expect(queryParams['access_token'], equals('test_access'));
      expect(queryParams['refresh_token'], equals('test_refresh'));
      expect(queryParams['expires_in'], equals('3600'));
      expect(queryParams['token_type'], equals('bearer'));
    });

    test('should validate Supabase auth callback with error parameters', () {
      const errorCallback = 'gigaeats://auth/callback?error=access_denied&error_description=Email+not+confirmed';
      
      final uri = Uri.parse(errorCallback);
      final queryParams = uri.queryParameters;
      
      expect(uri.scheme, equals('gigaeats'));
      expect(uri.host, equals('auth'));
      expect(uri.path, equals('/callback'));
      
      expect(queryParams['error'], equals('access_denied'));
      expect(queryParams['error_description'], equals('Email not confirmed'));
    });

    test('should validate email template URL path format', () {
      // Test the corrected URL path format (without redirect_to)
      // Simulate token replacement
      const simulatedUrl = '/auth/v1/verify?token=sample_token_hash&type=signup';
      
      final uri = Uri.parse('https://abknoalhfltlhhdbclpv.supabase.co$simulatedUrl');
      final queryParams = uri.queryParameters;
      
      expect(uri.path, equals('/auth/v1/verify'));
      expect(queryParams['token'], equals('sample_token_hash'));
      expect(queryParams['type'], equals('signup'));
      expect(queryParams.containsKey('redirect_to'), isFalse, 
        reason: 'URL path should not contain redirect_to parameter');
    });
  });

  group('Deep Link Service Tests', () {
    test('should identify Supabase auth URLs correctly', () {
      const supabaseUrl = 'https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/verify?token=test&type=signup&redirect_to=gigaeats://auth/callback';
      
      final uri = Uri.parse(supabaseUrl);
      
      // This is how DeepLinkService identifies Supabase URLs
      final isSupabaseAuth = uri.scheme == 'https' && 
                            uri.host.contains('supabase.co') && 
                            uri.path.startsWith('/auth/');
      
      expect(isSupabaseAuth, isTrue);
    });

    test('should identify custom scheme URLs correctly', () {
      const customUrl = 'gigaeats://auth/callback';
      
      final uri = Uri.parse(customUrl);
      
      // This is how DeepLinkService identifies custom scheme URLs
      final isCustomScheme = uri.scheme == 'gigaeats';
      
      expect(isCustomScheme, isTrue);
    });
  });
}
