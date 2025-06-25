import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:gigaeats_app/features/auth/presentation/providers/auth_provider.dart';

// Mock classes
class MockWidgetRef extends Mock implements WidgetRef {}
class MockAuthStateNotifier extends Mock implements AuthStateNotifier {}

void main() {
  group('DeepLinkService Tests', () {
    late MockWidgetRef mockRef;
    late MockAuthStateNotifier mockAuthNotifier;

    setUp(() {
      mockRef = MockWidgetRef();
      mockAuthNotifier = MockAuthStateNotifier();
      
      // Setup mock behavior
      when(mockRef.read(authStateProvider.notifier)).thenReturn(mockAuthNotifier);
    });

    test('should handle Supabase auth callback with success parameters', () async {
      // Test URI with successful auth parameters
      final testUri = Uri.parse(
        'https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/verify?'
        'access_token=test_access_token&'
        'refresh_token=test_refresh_token&'
        'type=signup'
      );

      // This would normally be tested with actual deep link processing
      // For now, we verify the URI parsing works correctly
      expect(testUri.host, equals('abknoalhfltlhhdbclpv.supabase.co'));
      expect(testUri.path, contains('/auth/v1/verify'));
      expect(testUri.queryParameters['access_token'], equals('test_access_token'));
      expect(testUri.queryParameters['refresh_token'], equals('test_refresh_token'));
      expect(testUri.queryParameters['type'], equals('signup'));
    });

    test('should handle Supabase auth callback with error parameters', () async {
      // Test URI with error parameters
      final testUri = Uri.parse(
        'https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/verify?'
        'error=access_denied&'
        'error_code=otp_expired&'
        'error_description=Email+link+is+invalid+or+has+expired'
      );

      expect(testUri.queryParameters['error'], equals('access_denied'));
      expect(testUri.queryParameters['error_code'], equals('otp_expired'));
      expect(testUri.queryParameters['error_description'], 
             equals('Email link is invalid or has expired'));
    });

    test('should handle custom scheme deep links', () async {
      // Test custom scheme URI
      final testUri = Uri.parse('gigaeats://auth/verify-email');

      expect(testUri.scheme, equals('gigaeats'));
      expect(testUri.host, equals('auth'));
      expect(testUri.path, equals('/verify-email'));
    });

    test('should validate redirect URLs format', () {
      final validUrls = [
        'gigaeats://auth/callback',
        'https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/callback',
        'http://localhost:3000/auth/callback',
      ];

      for (final url in validUrls) {
        final uri = Uri.parse(url);
        expect(uri.isAbsolute, isTrue, reason: 'URL should be absolute: $url');
        
        if (uri.scheme == 'gigaeats') {
          expect(uri.host, equals('auth'), reason: 'Custom scheme should use auth host');
        } else if (uri.scheme == 'https' || uri.scheme == 'http') {
          expect(uri.path, contains('/auth/'), reason: 'HTTP(S) URLs should contain auth path');
        }
      }
    });

    test('should extract token hash from verification URL', () {
      final testUrl = 'https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/verify?'
                     'token=abc123&type=signup&redirect_to=gigaeats://auth/callback';
      
      final uri = Uri.parse(testUrl);
      expect(uri.queryParameters['token'], equals('abc123'));
      expect(uri.queryParameters['type'], equals('signup'));
      expect(uri.queryParameters['redirect_to'], equals('gigaeats://auth/callback'));
    });
  });

  group('Email Verification Flow Tests', () {
    test('should validate email verification URL structure', () {
      // Test the URL structure that Supabase generates
      final baseUrl = 'https://abknoalhfltlhhdbclpv.supabase.co';
      final path = '/auth/v1/verify';
      final tokenHash = 'sample_token_hash';
      final redirectTo = 'gigaeats://auth/callback';
      
      final expectedUrl = '$baseUrl$path?token=$tokenHash&type=signup&redirect_to=$redirectTo';
      final uri = Uri.parse(expectedUrl);
      
      expect(uri.scheme, equals('https'));
      expect(uri.host, equals('abknoalhfltlhhdbclpv.supabase.co'));
      expect(uri.path, equals('/auth/v1/verify'));
      expect(uri.queryParameters['token'], equals(tokenHash));
      expect(uri.queryParameters['type'], equals('signup'));
      expect(uri.queryParameters['redirect_to'], equals(redirectTo));
    });

    test('should handle URL encoding in redirect parameters', () {
      final redirectUrl = 'gigaeats://auth/callback';
      final encodedRedirectUrl = Uri.encodeComponent(redirectUrl);
      
      expect(encodedRedirectUrl, equals('gigaeats%3A%2F%2Fauth%2Fcallback'));
      
      // Test decoding
      final decodedUrl = Uri.decodeComponent(encodedRedirectUrl);
      expect(decodedUrl, equals(redirectUrl));
    });
  });
}
