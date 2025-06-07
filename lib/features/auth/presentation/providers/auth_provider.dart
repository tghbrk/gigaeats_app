import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../data/models/user.dart';
import '../../../../data/models/user_role.dart';
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
enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Auth State Notifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final SupabaseAuthService _authService;
  final AppLogger _logger = AppLogger();

  AuthStateNotifier(this._authService) : super(const AuthState(status: AuthStatus.initial)) {
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
          // Try to get user profile from database
          try {
            final userId = currentUser.id;
            final supabase = Supabase.instance.client;
            _logger.debug('AuthStateNotifier: Fetching user profile from database...');

            final response = await supabase
                .from('users')
                .select()
                .eq('supabase_user_id', userId)
                .single();

            final user = User.fromJson(response);
            _logger.debug('AuthStateNotifier: User profile found: ${user.email}');

            state = state.copyWith(
              status: AuthStatus.authenticated,
              user: user,
            );
          } catch (e) {
            _logger.warning('AuthStateNotifier: User profile not found in database, creating fallback: $e');
            // Fallback to creating user object from Supabase auth data
            final supabaseUser = currentUser as supabase.User;
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
    state = state.copyWith(status: AuthStatus.loading);

    try {
      await _authService.signOut();
      _logger.info('AuthProvider: Sign out successful');
      debugPrint('🔐 AuthProvider: Sign out successful');

      // Clear all user data and set to unauthenticated
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        user: null,
        errorMessage: null,
      );
    } catch (e) {
      _logger.error('AuthProvider: Sign out error: $e');
      debugPrint('🔐 AuthProvider: Sign out error: $e');

      // Even if sign out fails, clear local state
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        user: null,
        errorMessage: null,
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Force refresh authentication state
  Future<void> refreshAuthState() async {
    await _checkAuthStatus();
  }
}
