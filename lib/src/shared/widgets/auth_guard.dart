import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_routes.dart';
// TODO: Restore app_router import when needed
// import '../../core/router/app_router.dart';
import '../../core/services/access_control_service.dart';
import '../../data/models/user_role.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/enhanced_auth_provider.dart';

/// Enhanced authentication guard widget that protects screens from unauthorized access
/// Phase 5: Role-based Routing & Access Control
class AuthGuard extends ConsumerWidget {
  final Widget child;
  final List<UserRole>? allowedRoles;
  final List<String>? requiredPermissions;
  final bool requireAuthentication;
  final String? routePath;

  const AuthGuard({
    super.key,
    required this.child,
    this.allowedRoles,
    this.requiredPermissions,
    this.requireAuthentication = true,
    this.routePath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final enhancedAuthState = ref.watch(enhancedAuthStateProvider);

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

      // Handle enhanced auth states
      if (enhancedAuthState.status == EnhancedAuthStatus.emailVerificationPending) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final email = enhancedAuthState.pendingVerificationEmail ?? '';
          context.go('/email-verification?email=${Uri.encodeComponent(email)}');
        });
        return const _LoadingScreen();
      }

      // Check route-based access control if route path is provided
      if (routePath != null) {
        final accessResult = AccessControlService.checkRouteAccess(routePath!, authState.user!.role);
        if (!accessResult.hasAccess) {
          debugPrint('🔐 AuthGuard: Access denied for route $routePath. Reason: ${accessResult.reason}');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final dashboardRoute = AccessControlService.getDashboardRoute(authState.user!.role);
            context.go(dashboardRoute);
          });
          return _UnauthorizedScreen(
            reason: accessResult.reason ?? 'Access denied',
            requiredPermissions: accessResult.requiredPermissions,
            userPermissions: accessResult.userPermissions,
          );
        }
      }

      // Check role-based access if roles are specified
      if (allowedRoles != null && allowedRoles!.isNotEmpty) {
        if (!allowedRoles!.contains(authState.user!.role)) {
          // User doesn't have required role, redirect to their dashboard
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final dashboardRoute = AccessControlService.getDashboardRoute(authState.user!.role);
            context.go(dashboardRoute);
          });
          return _UnauthorizedScreen(
            reason: 'Role ${authState.user!.role.displayName} not allowed',
            requiredPermissions: allowedRoles!.map((role) => role.displayName).toList(),
            userPermissions: [authState.user!.role.displayName],
          );
        }
      }

      // Check permission-based access if permissions are specified
      if (requiredPermissions != null && requiredPermissions!.isNotEmpty) {
        final userPermissions = AccessControlService.getPermissions(authState.user!.role);
        final hasAllPermissions = requiredPermissions!.every(
          (permission) => userPermissions.contains(permission),
        );

        if (!hasAllPermissions) {
          final missingPermissions = requiredPermissions!
              .where((permission) => !userPermissions.contains(permission))
              .toList();

          debugPrint('🔐 AuthGuard: Missing permissions: $missingPermissions');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final dashboardRoute = AccessControlService.getDashboardRoute(authState.user!.role);
            context.go(dashboardRoute);
          });
          return _UnauthorizedScreen(
            reason: 'Missing required permissions: ${missingPermissions.join(', ')}',
            requiredPermissions: requiredPermissions!,
            userPermissions: userPermissions.toList(),
          );
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
  final String? reason;
  final List<String> requiredPermissions;
  final List<String> userPermissions;

  const _UnauthorizedScreen({
    this.reason,
    this.requiredPermissions = const [],
    this.userPermissions = const [],
  });

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
                reason ?? 'You don\'t have permission to access this page.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (requiredPermissions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Required permissions:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  requiredPermissions.join(', '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (userPermissions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Your permissions:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  userPermissions.join(', '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
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

/// Convenience widget for protecting customer routes
class CustomerGuard extends StatelessWidget {
  final Widget child;

  const CustomerGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      allowedRoles: const [UserRole.customer, UserRole.admin],
      child: child,
    );
  }
}

/// Convenience widget for protecting driver routes
class DriverGuard extends StatelessWidget {
  final Widget child;

  const DriverGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      allowedRoles: const [UserRole.driver, UserRole.admin],
      child: child,
    );
  }
}

/// Convenience widget for protecting routes with specific permissions
class PermissionGuard extends StatelessWidget {
  final Widget child;
  final List<String> requiredPermissions;

  const PermissionGuard({
    super.key,
    required this.child,
    required this.requiredPermissions,
  });

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      requiredPermissions: requiredPermissions,
      child: child,
    );
  }
}
