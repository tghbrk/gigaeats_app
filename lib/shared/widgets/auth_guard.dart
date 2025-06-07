import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../data/models/user_role.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Authentication guard widget that protects screens from unauthorized access
class AuthGuard extends ConsumerWidget {
  final Widget child;
  final List<UserRole>? allowedRoles;
  final bool requireAuthentication;

  const AuthGuard({
    super.key,
    required this.child,
    this.allowedRoles,
    this.requireAuthentication = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Show loading while checking authentication
    if (authState.status == AuthStatus.loading || authState.status == AuthStatus.initial) {
      return const _LoadingScreen();
    }

    // Check if authentication is required
    if (requireAuthentication) {
      // User must be authenticated
      if (authState.status != AuthStatus.authenticated || authState.user == null) {
        // Redirect to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go(AppRoutes.login);
        });
        return const _LoadingScreen();
      }

      // Check role-based access if roles are specified
      if (allowedRoles != null && allowedRoles!.isNotEmpty) {
        if (!allowedRoles!.contains(authState.user!.role)) {
          // User doesn't have required role, redirect to their dashboard
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final dashboardRoute = AppRouter.getDashboardRoute(authState.user!.role);
            context.go(dashboardRoute);
          });
          return const _UnauthorizedScreen();
        }
      }
    }

    // All checks passed, show the protected content
    return child;
  }
}

/// Loading screen shown while checking authentication
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 60,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              // App Name
              Text(
                AppConstants.appName,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Loading message
              Text(
                'Checking authentication...',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 32),

              // Loading Indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.8),
                  ),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen shown when user doesn't have permission to access a route
class _UnauthorizedScreen extends StatelessWidget {
  const _UnauthorizedScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You don\'t have permission to access this page.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You will be redirected to your dashboard.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Loading indicator
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience widget for protecting sales agent routes
class SalesAgentGuard extends StatelessWidget {
  final Widget child;

  const SalesAgentGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      allowedRoles: const [UserRole.salesAgent, UserRole.admin],
      child: child,
    );
  }
}

/// Convenience widget for protecting vendor routes
class VendorGuard extends StatelessWidget {
  final Widget child;

  const VendorGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      allowedRoles: const [UserRole.vendor, UserRole.admin],
      child: child,
    );
  }
}

/// Convenience widget for protecting admin routes
class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      allowedRoles: const [UserRole.admin],
      child: child,
    );
  }
}
