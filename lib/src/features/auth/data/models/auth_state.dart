import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication state for state management
class AuthState extends Equatable {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final String? userRole;
  final Map<String, dynamic>? userMetadata;
  final bool isEmailVerified;
  final bool isSigningIn;
  final bool isSigningUp;
  final bool isSigningOut;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.userRole,
    this.userMetadata,
    this.isEmailVerified = false,
    this.isSigningIn = false,
    this.isSigningUp = false,
    this.isSigningOut = false,
  });

  /// Create a copy of AuthState with updated fields
  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    String? userRole,
    Map<String, dynamic>? userMetadata,
    bool? isEmailVerified,
    bool? isSigningIn,
    bool? isSigningUp,
    bool? isSigningOut,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userRole: userRole ?? this.userRole,
      userMetadata: userMetadata ?? this.userMetadata,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isSigningIn: isSigningIn ?? this.isSigningIn,
      isSigningUp: isSigningUp ?? this.isSigningUp,
      isSigningOut: isSigningOut ?? this.isSigningOut,
    );
  }

  /// Clear error
  AuthState clearError() {
    return copyWith(error: null);
  }

  /// Set loading state
  AuthState setLoading(bool loading) {
    return copyWith(isLoading: loading);
  }

  /// Set signing in state
  AuthState setSigningIn(bool signingIn) {
    return copyWith(isSigningIn: signingIn);
  }

  /// Set signing up state
  AuthState setSigningUp(bool signingUp) {
    return copyWith(isSigningUp: signingUp);
  }

  /// Set signing out state
  AuthState setSigningOut(bool signingOut) {
    return copyWith(isSigningOut: signingOut);
  }

  /// Set error
  AuthState setError(String error) {
    return copyWith(
      error: error,
      isLoading: false,
      isSigningIn: false,
      isSigningUp: false,
      isSigningOut: false,
    );
  }

  /// Set authenticated user
  AuthState setUser(User user) {
    return copyWith(
      user: user,
      isAuthenticated: true,
      isEmailVerified: user.emailConfirmedAt != null,
      userRole: user.userMetadata?['role'] as String?,
      userMetadata: user.userMetadata,
      isLoading: false,
      isSigningIn: false,
      isSigningUp: false,
      error: null,
    );
  }

  /// Set unauthenticated state
  AuthState setUnauthenticated() {
    return const AuthState();
  }

  /// Check if any operation is in progress
  bool get isOperationInProgress => 
      isLoading || isSigningIn || isSigningUp || isSigningOut;

  /// Get user ID
  String? get userId => user?.id;

  /// Get user email
  String? get userEmail => user?.email;

  /// Get user phone
  String? get userPhone => user?.phone;

  /// Check if user has specific role
  bool hasRole(String role) => userRole == role;

  /// Check if user is customer
  bool get isCustomer => hasRole('customer');

  /// Check if user is vendor
  bool get isVendor => hasRole('vendor');

  /// Check if user is sales agent
  bool get isSalesAgent => hasRole('sales_agent');

  /// Check if user is driver
  bool get isDriver => hasRole('driver');

  /// Check if user is admin
  bool get isAdmin => hasRole('admin');

  /// Create initial state
  factory AuthState.initial() {
    return const AuthState();
  }

  /// Create loading state
  factory AuthState.loading() {
    return const AuthState(isLoading: true);
  }

  /// Create signing in state
  factory AuthState.signingIn() {
    return const AuthState(isSigningIn: true);
  }

  /// Create signing up state
  factory AuthState.signingUp() {
    return const AuthState(isSigningUp: true);
  }

  /// Create signing out state
  factory AuthState.signingOut() {
    return const AuthState(isSigningOut: true);
  }

  /// Create error state
  factory AuthState.error(String error) {
    return AuthState(error: error);
  }

  /// Create authenticated state
  factory AuthState.authenticated(User user) {
    return AuthState(
      user: user,
      isAuthenticated: true,
      isEmailVerified: user.emailConfirmedAt != null,
      userRole: user.userMetadata?['role'] as String?,
      userMetadata: user.userMetadata,
    );
  }

  /// Create unauthenticated state
  factory AuthState.unauthenticated() {
    return const AuthState();
  }

  @override
  List<Object?> get props => [
        user,
        isLoading,
        error,
        isAuthenticated,
        userRole,
        userMetadata,
        isEmailVerified,
        isSigningIn,
        isSigningUp,
        isSigningOut,
      ];
}
