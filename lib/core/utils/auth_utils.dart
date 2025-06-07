import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Utility class for authentication-related operations
class AuthUtils {
  /// Show logout confirmation dialog and handle logout
  static Future<void> showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await logout(context, ref);
    }
  }

  /// Perform logout and navigate to login screen
  static Future<void> logout(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Perform logout
      await ref.read(authStateProvider.notifier).signOut();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to login screen
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Check if user is authenticated
  static bool isAuthenticated(WidgetRef ref) {
    final authState = ref.read(authStateProvider);
    return authState.status == AuthStatus.authenticated && authState.user != null;
  }

  /// Get current user or null if not authenticated
  static dynamic getCurrentUser(WidgetRef ref) {
    final authState = ref.read(authStateProvider);
    return authState.user;
  }

  /// Check if current user has specific role
  static bool hasRole(WidgetRef ref, dynamic role) {
    final user = getCurrentUser(ref);
    return user?.role == role;
  }

  /// Check if current user has any of the specified roles
  static bool hasAnyRole(WidgetRef ref, List<dynamic> roles) {
    final user = getCurrentUser(ref);
    return user != null && roles.contains(user.role);
  }

  /// Force refresh authentication state
  static Future<void> refreshAuthState(WidgetRef ref) async {
    await ref.read(authStateProvider.notifier).refreshAuthState();
  }

  /// Show authentication error dialog
  static void showAuthError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show session expired dialog and redirect to login
  static void showSessionExpiredDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('Your session has expired. Please login again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(AppRoutes.login);
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  /// Validate authentication and show appropriate error if needed
  static bool validateAuthentication(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authStateProvider);
    
    if (authState.status == AuthStatus.unauthenticated || authState.user == null) {
      showSessionExpiredDialog(context, ref);
      return false;
    }
    
    return true;
  }

  /// Get user display name
  static String getUserDisplayName(WidgetRef ref) {
    final user = getCurrentUser(ref);
    if (user == null) return 'Guest';
    
    return user.fullName?.isNotEmpty == true 
        ? user.fullName 
        : user.email?.split('@').first ?? 'User';
  }

  /// Get user role display name
  static String getUserRoleDisplayName(WidgetRef ref) {
    final user = getCurrentUser(ref);
    if (user == null) return 'Guest';
    
    switch (user.role.toString()) {
      case 'UserRole.salesAgent':
        return 'Sales Agent';
      case 'UserRole.vendor':
        return 'Vendor';
      case 'UserRole.admin':
        return 'Administrator';
      case 'UserRole.customer':
        return 'Customer';
      default:
        return 'User';
    }
  }
}
