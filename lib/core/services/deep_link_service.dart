import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';

/// Service to handle deep links for email verification and other auth flows
class DeepLinkService {
  static const MethodChannel _channel = MethodChannel('gigaeats.app/deeplink');
  static StreamSubscription? _linkSubscription;
  static bool _isInitialized = false;
  static GlobalKey<NavigatorState>? _navigatorKey;
  static bool _isProcessingEmailVerification = false;

  /// Set navigator key for navigation
  static void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Initialize deep link handling
  static Future<void> initialize(WidgetRef ref) async {
    if (_isInitialized) return;

    debugPrint('🔗 DeepLinkService: Initializing deep link handling');

    try {
      // Listen for auth state changes to handle email verification
      _linkSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        final session = data.session;

        debugPrint('🔗 DeepLinkService: Auth state change - Event: $event');

        // Only handle email verification success if we're actually processing an email verification
        // This prevents regular logins from triggering the verification success flow
        if (event == AuthChangeEvent.signedIn && session != null && _isProcessingEmailVerification) {
          debugPrint('🔗 DeepLinkService: User signed in during email verification process');
          if (session.user.emailConfirmedAt != null) {
            debugPrint('✅ DeepLinkService: Email verified via auth state change');
            _handleEmailVerificationSuccess(ref);
          } else {
            debugPrint('⚠️ DeepLinkService: User signed in but email not verified');
          }
        } else if (event == AuthChangeEvent.signedIn && session != null) {
          debugPrint('🔗 DeepLinkService: User signed in (regular login) - not processing as email verification');
        } else if (event == AuthChangeEvent.tokenRefreshed && session != null && _isProcessingEmailVerification) {
          debugPrint('🔗 DeepLinkService: Token refreshed during email verification, checking if email verified');
          _handleTokenRefresh(ref, session);
        }
      });

      // Handle initial link when app is launched from a deep link
      await _handleInitialLink(ref);

      _isInitialized = true;
      debugPrint('✅ DeepLinkService: Deep link handling initialized successfully');
    } catch (e) {
      debugPrint('❌ DeepLinkService: Failed to initialize deep link handling: $e');
    }
  }

  /// Handle initial link when app is launched
  static Future<void> _handleInitialLink(WidgetRef ref) async {
    try {
      // Check if app was launched from a deep link
      final initialUri = await _getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 DeepLinkService: App launched with initial link: $initialUri');
        await _processDeepLink(initialUri, ref);
      }
    } catch (e) {
      debugPrint('❌ DeepLinkService: Error handling initial link: $e');
    }
  }

  /// Get initial link (platform-specific implementation)
  static Future<Uri?> _getInitialLink() async {
    try {
      final String? initialLink = await _channel.invokeMethod('getInitialLink');
      if (initialLink != null) {
        return Uri.parse(initialLink);
      }
    } on PlatformException catch (e) {
      debugPrint('🔗 DeepLinkService: Platform exception getting initial link: $e');
    }
    return null;
  }

  /// Process incoming deep link
  static Future<void> _processDeepLink(Uri uri, WidgetRef ref) async {
    debugPrint('🔗 DeepLinkService: Processing deep link: $uri');
    
    try {
      // Check if this is a Supabase auth callback
      if (uri.host == 'abknoalhfltlhhdbclpv.supabase.co' && uri.path.contains('/auth/v1/verify')) {
        await _handleSupabaseAuthCallback(uri, ref);
      } else if (uri.scheme == 'gigaeats') {
        await _handleCustomSchemeLink(uri, ref);
      } else {
        debugPrint('🔗 DeepLinkService: Unhandled deep link: $uri');
      }
    } catch (e) {
      debugPrint('❌ DeepLinkService: Error processing deep link: $e');
    }
  }

  /// Handle Supabase auth callback (email verification)
  static Future<void> _handleSupabaseAuthCallback(Uri uri, WidgetRef ref) async {
    debugPrint('🔗 DeepLinkService: Handling Supabase auth callback');

    // Set flag to indicate we're processing email verification
    _isProcessingEmailVerification = true;

    try {
      // Extract query parameters
      final queryParams = uri.queryParameters;
      debugPrint('🔗 DeepLinkService: Query params: $queryParams');

      // Check for error parameters
      if (queryParams.containsKey('error')) {
        await _handleVerificationError(queryParams, ref);
        return;
      }

      // Check for success parameters (access_token, refresh_token)
      if (queryParams.containsKey('access_token') && queryParams.containsKey('refresh_token')) {
        debugPrint('✅ DeepLinkService: Email verification successful');

        try {
          // Set the session in Supabase using both tokens
          final accessToken = queryParams['access_token']!;
          final refreshToken = queryParams['refresh_token']!;

          debugPrint('🔗 DeepLinkService: Setting session with tokens');
          await Supabase.instance.client.auth.setSession('$accessToken.$refreshToken');

          // Wait a moment for the session to be established
          await Future.delayed(const Duration(milliseconds: 500));

          // Verify the session was set correctly
          final currentUser = Supabase.instance.client.auth.currentUser;
          if (currentUser != null) {
            debugPrint('✅ DeepLinkService: Session established for user: ${currentUser.email}');

            // Navigate to enhanced success screen
            await _handleEmailVerificationSuccess(ref);
          } else {
            debugPrint('❌ DeepLinkService: Session not established properly');
            await _handleVerificationError({
              'error': 'session_error',
              'error_description': 'Failed to establish user session after verification'
            }, ref);
          }
        } catch (e) {
          debugPrint('❌ DeepLinkService: Error setting session: $e');
          await _handleVerificationError({
            'error': 'session_error',
            'error_description': 'Failed to establish session: $e'
          }, ref);
        }
      } else {
        debugPrint('🔗 DeepLinkService: No auth tokens found in callback');
        // Navigate to error screen for invalid link
        await _handleVerificationError({
          'error': 'invalid_request',
          'error_description': 'Invalid verification link - missing authentication tokens'
        }, ref);
      }
    } catch (e) {
      debugPrint('❌ DeepLinkService: Error handling Supabase auth callback: $e');
      await _handleVerificationError({
        'error': 'network_error',
        'error_description': 'Failed to process email verification: $e'
      }, ref);
    } finally {
      // Always clear the email verification processing flag
      _isProcessingEmailVerification = false;
      debugPrint('🔗 DeepLinkService: Supabase auth callback processing completed');
    }
  }

  /// Handle custom scheme links (gigaeats://)
  static Future<void> _handleCustomSchemeLink(Uri uri, WidgetRef ref) async {
    debugPrint('🔗 DeepLinkService: Handling custom scheme link: $uri');

    // Handle different custom scheme paths
    switch (uri.host) {
      case 'auth':
        if (uri.path == '/verify-email') {
          // Set flag to indicate we're processing email verification
          _isProcessingEmailVerification = true;
          // Handle email verification success
          await _handleEmailVerificationSuccess(ref);
        }
        break;
      default:
        debugPrint('🔗 DeepLinkService: Unhandled custom scheme: ${uri.host}');
    }
  }



  /// Handle token refresh
  static void _handleTokenRefresh(WidgetRef ref, Session session) {
    debugPrint('🔗 DeepLinkService: Handling token refresh during email verification');

    // Check if email is now verified (only during email verification process)
    if (session.user.emailConfirmedAt != null) {
      debugPrint('✅ DeepLinkService: Email confirmed via token refresh');
      _handleEmailVerificationSuccess(ref);
    } else {
      debugPrint('⚠️ DeepLinkService: Token refreshed but email still not verified');
    }
  }

  /// Handle verification errors with enhanced error routing
  static Future<void> _handleVerificationError(Map<String, String> params, WidgetRef ref) async {
    final errorCode = params['error'];
    final errorDescription = params['error_description'];
    final email = params['email'] ?? ref.read(authStateProvider).pendingVerificationEmail;

    debugPrint('❌ DeepLinkService: Verification error - $errorCode: $errorDescription');

    // Map error codes to user-friendly messages and actions
    String? errorMessage;
    String? actionMessage;

    switch (errorCode) {
      case 'otp_expired':
        errorMessage = 'Your verification link has expired. Verification links are only valid for 24 hours.';
        actionMessage = 'Please request a new verification email to continue.';
        break;
      case 'access_denied':
        errorMessage = 'Access to this verification link was denied.';
        actionMessage = 'This may happen if the link was already used or is invalid.';
        break;
      case 'invalid_request':
        errorMessage = 'The verification link is invalid or malformed.';
        actionMessage = 'Please check the link or request a new verification email.';
        break;
      case 'network_error':
        errorMessage = 'A network error occurred during verification.';
        actionMessage = 'Please check your internet connection and try again.';
        break;
      default:
        errorMessage = errorDescription ?? 'Email verification failed.';
        actionMessage = 'Please try again or request a new verification email.';
    }

    // Navigate to enhanced error screen
    _navigateToVerificationError(ref, errorCode, errorMessage, actionMessage, email);
  }

  /// Handle email verification success
  static Future<void> _handleEmailVerificationSuccess(WidgetRef ref) async {
    debugPrint('✅ DeepLinkService: Email verification successful');

    try {
      // First, refresh the auth state to get the latest user info
      await ref.read(authStateProvider.notifier).refreshAuthState();

      // Handle email verification completion with auto-login attempt
      final autoLoginSuccessful = await ref.read(authStateProvider.notifier).handleEmailVerificationComplete();

      // Get current auth state after handling verification
      final authState = ref.read(authStateProvider);

      // Determine the email to use for the success screen
      String? email = authState.user?.email ?? authState.pendingVerificationEmail;

      if (autoLoginSuccessful && authState.user != null) {
        debugPrint('✅ DeepLinkService: Auto-login successful, user: ${authState.user!.email}');
        debugPrint('✅ DeepLinkService: User role: ${authState.user!.role}');
        email = authState.user!.email;

        // Ensure pending verification is completely cleared
        ref.read(authStateProvider.notifier).clearPendingVerification();
      } else {
        debugPrint('ℹ️ DeepLinkService: Auto-login not available, using pending email: $email');
        // Clear pending verification state even if auto-login failed
        ref.read(authStateProvider.notifier).clearPendingVerification();
      }

      // Navigate to the enhanced success screen
      _navigateToVerificationSuccess(ref, email);

    } catch (e) {
      debugPrint('❌ DeepLinkService: Error handling verification success: $e');
      // Clear pending verification state on error too
      ref.read(authStateProvider.notifier).clearPendingVerification();

      // Navigate to error screen if something goes wrong
      await _handleVerificationError({
        'error': 'verification_processing_error',
        'error_description': 'Failed to complete verification process: $e'
      }, ref);
    } finally {
      // Always clear the email verification processing flag
      _isProcessingEmailVerification = false;
      debugPrint('🔗 DeepLinkService: Email verification processing completed');
    }
  }

  /// Navigate to enhanced verification success screen
  static void _navigateToVerificationSuccess(WidgetRef ref, String? email) {
    debugPrint('✅ Navigating to enhanced verification success screen - email: $email');

    try {
      // Use the navigator key to navigate directly
      if (_navigatorKey?.currentContext != null) {
        final context = _navigatorKey!.currentContext!;
        final emailParam = email != null ? '?email=${Uri.encodeComponent(email)}' : '';
        context.go('/email-verification-success$emailParam');
        debugPrint('✅ Successfully navigated to verification success screen');
      } else {
        debugPrint('❌ Navigator key not available, cannot navigate');
        // Fallback: Update auth state to trigger router redirect
        _triggerSuccessStateUpdate(ref, email);
      }
    } catch (e) {
      debugPrint('❌ Error navigating to success screen: $e');
      // Fallback: Update auth state to trigger router redirect
      _triggerSuccessStateUpdate(ref, email);
    }
  }

  /// Trigger auth state update to show success
  static void _triggerSuccessStateUpdate(WidgetRef ref, String? email) {
    debugPrint('🔄 Triggering auth state update for verification success');
    // The router will handle the redirect based on auth state
    // This is a fallback when direct navigation fails
  }

  /// Navigate to enhanced verification error screen
  static void _navigateToVerificationError(WidgetRef ref, String? errorCode, String? errorMessage, String? actionMessage, String? email) {
    debugPrint('❌ Navigating to enhanced verification error screen - error: $errorCode');

    try {
      // Use the navigator key to navigate directly
      if (_navigatorKey?.currentContext != null) {
        final context = _navigatorKey!.currentContext!;
        final params = <String, String>{};
        if (errorCode != null) params['error'] = errorCode;
        if (errorMessage != null) params['message'] = errorMessage;
        if (actionMessage != null) params['action'] = actionMessage;
        if (email != null) params['email'] = email;

        final queryString = params.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        final url = '/email-verification-error${queryString.isNotEmpty ? '?$queryString' : ''}';

        context.go(url);
        debugPrint('✅ Successfully navigated to verification error screen');
      } else {
        debugPrint('❌ Navigator key not available, cannot navigate to error screen');
      }
    } catch (e) {
      debugPrint('❌ Error navigating to error screen: $e');
    }
  }

  /// Dispose resources
  static void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _isInitialized = false;
    debugPrint('🔗 DeepLinkService: Disposed');
  }
}

/// Provider for deep link service
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService();
});
