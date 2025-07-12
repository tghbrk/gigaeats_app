import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../user_management/domain/user.dart';
import '../../../../data/models/user_role.dart';
import '../../../../data/repositories/base_repository.dart';
import '../../data/datasources/supabase_auth_service.dart';
import '../../../../core/utils/logger.dart';

// Shared Preferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Supabase Auth Service Provider
final supabaseAuthServiceProvider = Provider<SupabaseAuthService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SupabaseAuthService(
    prefs: prefs,
  );
});

// Current User Provider
final currentUserProvider = StateProvider<User?>((ref) => null);

// Authentication State Provider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authService = ref.watch(supabaseAuthServiceProvider);
  return AuthStateNotifier(authService);
});

// Auth State
enum AuthStatus { initial, authenticated, unauthenticated, loading, emailVerificationPending }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? pendingVerificationEmail;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.pendingVerificationEmail,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    String? pendingVerificationEmail,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingVerificationEmail: pendingVerificationEmail ?? this.pendingVerificationEmail,
    );
  }
}

// Auth State Notifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final SupabaseAuthService _authService;
  final AppLogger _logger = AppLogger();

  AuthStateNotifier(this._authService) : super(const AuthState(status: AuthStatus.initial)) {
    _logger.debug('🔄 AuthStateNotifier: Initializing basic auth provider...');
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _logger.debug('AuthStateNotifier: Starting auth status check...');
    state = state.copyWith(status: AuthStatus.loading);

    try {
      _logger.debug('AuthStateNotifier: Checking if user is authenticated...');
      if (_authService.isAuthenticated) {
        _logger.debug('AuthStateNotifier: User is authenticated');
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          _logger.debug('AuthStateNotifier: Current user found: ${currentUser.email}');
          // Try to get user profile from database using auth service
          try {
            final userId = currentUser.id;
            _logger.debug('AuthStateNotifier: Fetching user profile from database...');

            final user = await _authService.getUserProfile(userId);
            if (user != null) {
              _logger.debug('AuthStateNotifier: User profile found: ${user.email}');
              state = state.copyWith(
                status: AuthStatus.authenticated,
                user: user,
              );
              _logger.debug('AuthStateNotifier: State updated to authenticated');
            } else {
              _logger.warning('AuthStateNotifier: User profile not found in database');
              throw Exception('User profile not found');
            }
          } catch (e) {
            _logger.warning('AuthStateNotifier: User profile not found in database, creating fallback: $e');
            _logger.debug('AuthStateNotifier: Error details: ${e.toString()}');
            // Fallback to creating user object from Supabase auth data
            // Get the Supabase user directly from the auth service
            final supabaseUser = Supabase.instance.client.auth.currentUser;
            if (supabaseUser != null) {
              final user = User(
                id: supabaseUser.id,
                email: supabaseUser.email ?? '',
                fullName: supabaseUser.userMetadata?['full_name'] ?? 'User',
                phoneNumber: supabaseUser.phone ?? '',
                role: _authService.userRole ?? UserRole.salesAgent,
                isVerified: supabaseUser.emailConfirmedAt != null || supabaseUser.phoneConfirmedAt != null,
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              _logger.debug('AuthStateNotifier: Created fallback user: ${user.email}');
              state = state.copyWith(
                status: AuthStatus.authenticated,
                user: user,
              );
              _logger.debug('AuthStateNotifier: State updated to authenticated (fallback)');
            } else {
              _logger.error('AuthStateNotifier: No Supabase user found for fallback');
              state = state.copyWith(status: AuthStatus.unauthenticated);
            }
          }
        } else {
          _logger.debug('AuthStateNotifier: Current user is null');
          state = state.copyWith(status: AuthStatus.unauthenticated);
        }
      } else {
        _logger.debug('AuthStateNotifier: User is not authenticated');
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      _logger.error('AuthStateNotifier: Error checking auth status: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signIn(String email, String password) async {
    _logger.info('AuthProvider: Starting sign in process for $email');
    debugPrint('🔐 AuthProvider: Starting sign in process for $email');
    state = state.copyWith(status: AuthStatus.loading);

    try {
      _logger.debug('AuthProvider: Calling Supabase auth service sign in');
      debugPrint('🔐 AuthProvider: Calling Supabase auth service sign in');
      final result = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _logger.debug('AuthProvider: Auth service result - success: ${result.isSuccess}, user: ${result.user?.email}');
      debugPrint('🔐 AuthProvider: Auth service result - success: ${result.isSuccess}, user: ${result.user?.email}');

      if (result.isSuccess && result.user != null) {
        _logger.info('AuthProvider: Setting authenticated state');
        debugPrint('✅ AuthProvider: Setting authenticated state');

        // Mark session as recent to avoid aggressive expiry checks
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          final sessionId = session.accessToken.substring(0, 20);
          BaseRepository.markSessionAsRecent(sessionId);
          debugPrint('✅ AuthProvider: Marked session as recent: $sessionId');
        }

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: result.user,
        );
        _logger.debug('AuthProvider: State updated - status: ${state.status}, user: ${state.user?.email}');
      } else {
        _logger.warning('AuthProvider: Setting unauthenticated state with error: ${result.errorMessage}');
        debugPrint('❌ AuthProvider: Setting unauthenticated state with error: ${result.errorMessage}');
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: result.errorMessage,
        );
      }
    } catch (e) {
      _logger.error('AuthProvider: Exception during sign in: $e');
      debugPrint('💥 AuthProvider: Exception during sign in: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
  }) async {
    debugPrint('AuthProvider: Starting registration process');
    state = state.copyWith(status: AuthStatus.loading);

    try {
      debugPrint('AuthProvider: Calling Supabase auth service register');
      final result = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
      );

      debugPrint('AuthProvider: Auth service result - success: ${result.isSuccess}, user: ${result.user?.email}');

      if (result.isSuccess && result.user != null) {
        debugPrint('AuthProvider: Setting authenticated state after registration');
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: result.user,
        );
      } else {
        debugPrint('AuthProvider: Setting unauthenticated state with error: ${result.errorMessage}');
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: result.errorMessage,
        );
      }
    } catch (e) {
      debugPrint('AuthProvider: Exception during registration: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    _logger.info('AuthProvider: Starting sign out process');
    debugPrint('🔐 AuthProvider: Starting sign out process');
    debugPrint('🔐 AuthProvider: Current auth status: ${state.status}');
    debugPrint('🔐 AuthProvider: Current user: ${state.user?.email}');

    state = state.copyWith(status: AuthStatus.loading);
    debugPrint('🔐 AuthProvider: Auth status set to loading');

    try {
      debugPrint('🔐 AuthProvider: Calling Supabase auth service signOut...');
      await _authService.signOut();
      _logger.info('AuthProvider: Sign out successful');
      debugPrint('🔐 AuthProvider: Supabase sign out successful');

      // Clear all user data and set to unauthenticated
      debugPrint('🔐 AuthProvider: Clearing auth state and setting to unauthenticated');
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        user: null,
        errorMessage: null,
      );
      debugPrint('🔐 AuthProvider: Auth state cleared - status: ${state.status}, user: ${state.user}');
      debugPrint('🔐 AuthProvider: Sign out process completed successfully');
    } catch (e) {
      _logger.error('AuthProvider: Sign out error: $e');
      debugPrint('🔐 AuthProvider: Sign out error: $e');

      // Even if sign out fails, clear local state
      debugPrint('🔐 AuthProvider: Forcing local state clear despite error');
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        user: null,
        errorMessage: null,
      );
      debugPrint('🔐 AuthProvider: Local state cleared - status: ${state.status}, user: ${state.user}');
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Handle email verification completion
  Future<bool> handleEmailVerificationComplete() async {
    _logger.info('AuthStateNotifier: Handling email verification completion');

    try {
      // Clear pending verification state and refresh auth status
      state = state.copyWith(
        pendingVerificationEmail: null,
        errorMessage: null,
      );

      // Refresh authentication state to get updated user info
      await _checkAuthStatus();

      // Check if user is now authenticated
      final isAuthenticated = state.status == AuthStatus.authenticated && state.user != null;

      _logger.info('AuthStateNotifier: Email verification handled successfully, authenticated: $isAuthenticated');
      return isAuthenticated;
    } catch (e) {
      _logger.error('AuthStateNotifier: Error handling email verification: $e');
      state = state.copyWith(
        errorMessage: 'Verification completed but there was an issue. Please try signing in manually.',
      );
      return false;
    }
  }

  /// Clear pending verification state
  void clearPendingVerification() {
    _logger.info('AuthStateNotifier: Clearing pending verification');

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      pendingVerificationEmail: null,
      errorMessage: null,
      user: null,
    );
  }

  /// Resend verification email
  Future<void> resendVerificationEmail([String? email]) async {
    final targetEmail = email ?? state.pendingVerificationEmail;
    if (targetEmail == null) {
      _logger.warning('AuthStateNotifier: No email provided for verification');
      state = state.copyWith(
        errorMessage: 'No email provided for verification',
      );
      return;
    }

    _logger.info('AuthStateNotifier: Resending verification email to $targetEmail');

    try {
      final result = await _authService.resendVerificationEmail(targetEmail);
      if (result.isSuccess) {
        _logger.info('AuthStateNotifier: Verification email resent successfully');
        state = state.copyWith(
          errorMessage: null,
        );
      } else {
        _logger.error('AuthStateNotifier: Failed to resend verification email: ${result.errorMessage}');
        state = state.copyWith(
          errorMessage: result.errorMessage,
        );
      }
    } catch (e) {
      _logger.error('AuthStateNotifier: Error resending verification email: $e');
      state = state.copyWith(
        errorMessage: 'Failed to resend verification email. Please try again.',
      );
    }
  }

  /// Force refresh authentication state
  Future<void> refreshAuthState() async {
    await _checkAuthStatus();
  }
}
