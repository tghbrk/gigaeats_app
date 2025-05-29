import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user.dart';
import '../../data/models/user_role.dart';
import '../../data/services/auth_service.dart';
import 'repository_providers.dart';

// Shared Preferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final authSync = ref.watch(authSyncServiceProvider);
  return AuthService(
    prefs: prefs,
    authSync: authSync,
  );
});

// Current User Provider
final currentUserProvider = StateProvider<User?>((ref) => null);

// Authentication State Provider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
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
  final AuthService _authService;

  AuthStateNotifier(this._authService) : super(const AuthState(status: AuthStatus.initial)) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      if (_authService.isAuthenticated && _authService.userRole != null) {
        // Create user object from Firebase data - in production this would come from your backend API
        final user = User(
          id: _authService.userId ?? '',
          email: _authService.currentFirebaseUser?.email ?? '',
          fullName: _authService.currentFirebaseUser?.displayName ?? 'User',
          phoneNumber: _authService.currentFirebaseUser?.phoneNumber ?? '',
          role: _authService.userRole!,
          isVerified: _authService.currentFirebaseUser?.emailVerified ?? false,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signIn(String email, String password) async {
    debugPrint('AuthProvider: Starting sign in process');
    state = state.copyWith(status: AuthStatus.loading);

    try {
      debugPrint('AuthProvider: Calling auth service sign in');
      final result = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('AuthProvider: Auth service result - success: ${result.isSuccess}, user: ${result.user?.email}');

      if (result.isSuccess && result.user != null) {
        debugPrint('AuthProvider: Setting authenticated state');
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
      debugPrint('AuthProvider: Exception during sign in: $e');
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
      debugPrint('AuthProvider: Calling auth service register');
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
    state = state.copyWith(status: AuthStatus.loading);

    try {
      await _authService.signOut();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
