
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'dart:async';

import '../../../../data/models/user.dart';
import '../../../../data/models/user_role.dart';
import '../../data/datasources/supabase_auth_service.dart';
import '../../../../core/utils/logger.dart';
import 'auth_provider.dart';

// Enhanced Auth State with more detailed verification states
enum EnhancedAuthStatus { 
  initial, 
  authenticated, 
  unauthenticated, 
  loading, 
  emailVerificationPending,
  emailVerificationExpired,
  emailVerificationFailed,
  profileIncomplete,
  networkError
}

class EnhancedAuthState {
  final EnhancedAuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? pendingVerificationEmail;
  final DateTime? verificationSentAt;
  final int verificationAttempts;
  final bool isNetworkAvailable;
  final Map<String, dynamic>? additionalData;

  const EnhancedAuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.pendingVerificationEmail,
    this.verificationSentAt,
    this.verificationAttempts = 0,
    this.isNetworkAvailable = true,
    this.additionalData,
  });

  EnhancedAuthState copyWith({
    EnhancedAuthStatus? status,
    User? user,
    String? errorMessage,
    String? pendingVerificationEmail,
    DateTime? verificationSentAt,
    int? verificationAttempts,
    bool? isNetworkAvailable,
    Map<String, dynamic>? additionalData,
  }) {
    return EnhancedAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingVerificationEmail: pendingVerificationEmail ?? this.pendingVerificationEmail,
      verificationSentAt: verificationSentAt ?? this.verificationSentAt,
      verificationAttempts: verificationAttempts ?? this.verificationAttempts,
      isNetworkAvailable: isNetworkAvailable ?? this.isNetworkAvailable,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Helper getters
  bool get isAuthenticated => status == EnhancedAuthStatus.authenticated && user != null;
  bool get isLoading => status == EnhancedAuthStatus.loading;
  bool get needsEmailVerification => status == EnhancedAuthStatus.emailVerificationPending;
  bool get hasError => errorMessage != null;
  
  Duration? get timeSinceVerificationSent {
    if (verificationSentAt == null) return null;
    return DateTime.now().difference(verificationSentAt!);
  }
  
  bool get canResendVerification {
    final timeSince = timeSinceVerificationSent;
    return timeSince == null || timeSince.inSeconds >= 60; // 1 minute cooldown
  }
  
  bool get isVerificationExpired {
    final timeSince = timeSinceVerificationSent;
    return timeSince != null && timeSince.inHours >= 24; // 24 hour expiry
  }
}

class EnhancedAuthStateNotifier extends StateNotifier<EnhancedAuthState> {
  final SupabaseAuthService _authService;
  final AppLogger _logger = AppLogger();
  Timer? _verificationCheckTimer;
  Timer? _networkCheckTimer;

  EnhancedAuthStateNotifier(this._authService) : super(const EnhancedAuthState(status: EnhancedAuthStatus.initial)) {
    _initializeAuth();
    _startPeriodicChecks();
  }

  @override
  void dispose() {
    _verificationCheckTimer?.cancel();
    _networkCheckTimer?.cancel();
    super.dispose();
  }

  // Initialize authentication state
  Future<void> _initializeAuth() async {
    state = state.copyWith(status: EnhancedAuthStatus.loading);
    await _checkAuthStatus();
  }

  // Start periodic checks for verification and network status
  void _startPeriodicChecks() {
    // Check verification status every 30 seconds when pending
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (state.needsEmailVerification) {
        _checkVerificationStatus();
      }
    });

    // Check network status every 10 seconds
    _networkCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkNetworkStatus();
    });
  }

  // Enhanced registration with better error handling
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    UserRole role = UserRole.customer,
  }) async {
    try {
      state = state.copyWith(
        status: EnhancedAuthStatus.loading,
        errorMessage: null,
      );

      _logger.info('Starting registration for $email with role: ${role.value}');

      final result = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
      );

      if (result.isSuccess) {
        if (result.user != null) {
          // User was immediately authenticated (email already confirmed)
          _logger.info('Registration successful with immediate authentication');
          state = state.copyWith(
            status: EnhancedAuthStatus.authenticated,
            user: result.user,
            errorMessage: null,
          );
        } else {
          // Registration successful - user needs to verify email
          _logger.info('Registration successful, email verification required');
          state = state.copyWith(
            status: EnhancedAuthStatus.emailVerificationPending,
            errorMessage: null,
            pendingVerificationEmail: email,
            verificationSentAt: DateTime.now(),
            verificationAttempts: 1,
          );
        }
      } else {
        _logger.error('Registration failed: ${result.errorMessage}');
        state = state.copyWith(
          status: EnhancedAuthStatus.unauthenticated,
          errorMessage: result.errorMessage,
        );
      }
    } catch (e) {
      _logger.error('Registration exception: $e');
      state = state.copyWith(
        status: EnhancedAuthStatus.unauthenticated,
        errorMessage: _getNetworkErrorMessage(e),
      );
    }
  }

  // Enhanced sign in with better error handling
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(
        status: EnhancedAuthStatus.loading,
        errorMessage: null,
      );

      _logger.info('Starting sign in for $email');

      final result = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.isSuccess && result.user != null) {
        _logger.info('Sign in successful');
        
        // Check if user profile is complete
        if (_isProfileComplete(result.user!)) {
          state = state.copyWith(
            status: EnhancedAuthStatus.authenticated,
            user: result.user,
            errorMessage: null,
          );
        } else {
          state = state.copyWith(
            status: EnhancedAuthStatus.profileIncomplete,
            user: result.user,
            errorMessage: null,
          );
        }
      } else {
        _logger.error('Sign in failed: ${result.errorMessage}');
        
        // Check if it's an email verification issue
        if (result.errorMessage?.toLowerCase().contains('email') == true ||
            result.errorMessage?.toLowerCase().contains('confirm') == true) {
          state = state.copyWith(
            status: EnhancedAuthStatus.emailVerificationPending,
            pendingVerificationEmail: email,
            errorMessage: 'Please verify your email address before signing in.',
          );
        } else {
          state = state.copyWith(
            status: EnhancedAuthStatus.unauthenticated,
            errorMessage: result.errorMessage,
          );
        }
      }
    } catch (e) {
      _logger.error('Sign in exception: $e');
      state = state.copyWith(
        status: EnhancedAuthStatus.unauthenticated,
        errorMessage: _getNetworkErrorMessage(e),
      );
    }
  }

  // Enhanced resend verification with rate limiting
  Future<bool> resendVerificationEmail(String email) async {
    if (!state.canResendVerification) {
      final remainingTime = 60 - (state.timeSinceVerificationSent?.inSeconds ?? 0);
      state = state.copyWith(
        errorMessage: 'Please wait $remainingTime seconds before resending.',
      );
      return false;
    }

    try {
      _logger.info('Resending verification email to $email');

      final result = await _authService.resendVerificationEmail(email);

      if (result.isSuccess) {
        _logger.info('Verification email resent successfully');
        state = state.copyWith(
          errorMessage: null,
          verificationSentAt: DateTime.now(),
          verificationAttempts: state.verificationAttempts + 1,
        );
        return true;
      } else {
        _logger.error('Failed to resend verification email: ${result.errorMessage}');
        state = state.copyWith(errorMessage: result.errorMessage);
        return false;
      }
    } catch (e) {
      _logger.error('Resend verification exception: $e');
      state = state.copyWith(errorMessage: _getNetworkErrorMessage(e));
      return false;
    }
  }

  // Enhanced verification completion handling
  Future<bool> handleEmailVerificationComplete() async {
    try {
      _logger.info('Handling email verification completion');

      state = state.copyWith(
        status: EnhancedAuthStatus.loading,
        pendingVerificationEmail: null,
        errorMessage: null,
      );

      // Refresh auth status to get updated user info
      await _checkAuthStatus();

      // Check if auto-login was successful
      final isAuthenticated = state.status == EnhancedAuthStatus.authenticated && state.user != null;

      if (isAuthenticated) {
        _logger.info('Email verification complete - user auto-logged in');
        
        // Verify user profile exists and is complete
        if (state.user != null) {
          try {
            final userProfile = await _authService.getUserProfile(state.user!.id);
            if (userProfile != null) {
              state = state.copyWith(user: userProfile);
              _logger.info('User profile verified and updated');
            }
          } catch (e) {
            _logger.warning('Could not verify user profile: $e');
          }
        }
      } else {
        _logger.info('Email verification complete - manual login required');
        state = state.copyWith(
          status: EnhancedAuthStatus.unauthenticated,
          user: null,
        );
      }

      return isAuthenticated;
    } catch (e) {
      _logger.error('Error handling email verification: $e');
      state = state.copyWith(
        status: EnhancedAuthStatus.emailVerificationFailed,
        errorMessage: 'Verification completed but there was an issue. Please try signing in manually.',
      );
      return false;
    }
  }

  // Check current authentication status
  Future<void> _checkAuthStatus() async {
    try {
      // Use the existing method from the auth service
      final isAuthenticated = _authService.isAuthenticated;
      User? currentUser;

      if (isAuthenticated) {
        // Try to get user profile
        final supabaseUser = Supabase.instance.client.auth.currentUser;
        if (supabaseUser != null) {
          currentUser = await _authService.getUserProfile(supabaseUser.id);
        }
      }
      
      if (currentUser != null) {
        if (_isProfileComplete(currentUser)) {
          state = state.copyWith(
            status: EnhancedAuthStatus.authenticated,
            user: currentUser,
            errorMessage: null,
          );
        } else {
          state = state.copyWith(
            status: EnhancedAuthStatus.profileIncomplete,
            user: currentUser,
            errorMessage: null,
          );
        }
      } else {
        state = state.copyWith(
          status: EnhancedAuthStatus.unauthenticated,
          user: null,
        );
      }
    } catch (e) {
      _logger.error('Error checking auth status: $e');
      state = state.copyWith(
        status: EnhancedAuthStatus.networkError,
        errorMessage: _getNetworkErrorMessage(e),
      );
    }
  }

  // Periodically check verification status
  Future<void> _checkVerificationStatus() async {
    if (!state.needsEmailVerification) return;

    try {
      await _checkAuthStatus();
      
      // If user is now authenticated, verification was successful
      if (state.isAuthenticated) {
        _logger.info('Verification detected during periodic check');
      }
      
      // Check if verification has expired
      if (state.isVerificationExpired) {
        state = state.copyWith(
          status: EnhancedAuthStatus.emailVerificationExpired,
          errorMessage: 'Verification link has expired. Please request a new one.',
        );
      }
    } catch (e) {
      _logger.error('Error during verification status check: $e');
    }
  }

  // Check network connectivity
  Future<void> _checkNetworkStatus() async {
    try {
      // Simple network check - try to check if authenticated
      _authService.isAuthenticated;

      if (!state.isNetworkAvailable) {
        state = state.copyWith(isNetworkAvailable: true);
        _logger.info('Network connectivity restored');
      }
    } catch (e) {
      if (state.isNetworkAvailable) {
        state = state.copyWith(isNetworkAvailable: false);
        _logger.warning('Network connectivity lost');
      }
    }
  }

  // Helper methods
  bool _isProfileComplete(User user) {
    return user.fullName.isNotEmpty && 
           user.email.isNotEmpty && 
           user.isVerified;
  }

  String _getNetworkErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return 'Network connection error. Please check your internet connection and try again.';
    }
    
    return error.toString();
  }

  // Public methods for state management
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void clearPendingVerification() {
    state = state.copyWith(
      status: EnhancedAuthStatus.unauthenticated,
      pendingVerificationEmail: null,
      verificationSentAt: null,
      verificationAttempts: 0,
      errorMessage: null,
    );
  }

  Future<void> refreshAuthState() async {
    await _checkAuthStatus();
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const EnhancedAuthState(status: EnhancedAuthStatus.unauthenticated);
      _logger.info('User signed out successfully');
    } catch (e) {
      _logger.error('Error during sign out: $e');
      // Force sign out locally even if remote sign out fails
      state = const EnhancedAuthState(status: EnhancedAuthStatus.unauthenticated);
    }
  }
}

// Enhanced Auth Provider
final enhancedAuthStateProvider = StateNotifierProvider<EnhancedAuthStateNotifier, EnhancedAuthState>((ref) {
  final authService = ref.watch(supabaseAuthServiceProvider);
  return EnhancedAuthStateNotifier(authService);
});

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(enhancedAuthStateProvider);
  return authState.isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(enhancedAuthStateProvider);
  return authState.user;
});

final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(enhancedAuthStateProvider);
  return authState.errorMessage;
});

final needsEmailVerificationProvider = Provider<bool>((ref) {
  final authState = ref.watch(enhancedAuthStateProvider);
  return authState.needsEmailVerification;
});

final canResendVerificationProvider = Provider<bool>((ref) {
  final authState = ref.watch(enhancedAuthStateProvider);
  return authState.canResendVerification;
});
