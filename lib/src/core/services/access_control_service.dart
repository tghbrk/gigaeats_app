import 'package:flutter/foundation.dart';
import '../../data/models/user_role.dart';

/// Result of route access check
class RouteAccessResult {
  final bool hasAccess;
  final String? reason;
  final List<String> requiredPermissions;
  final List<String> userPermissions;

  const RouteAccessResult({
    required this.hasAccess,
    this.reason,
    this.requiredPermissions = const [],
    this.userPermissions = const [],
  });

  factory RouteAccessResult.allowed() {
    return const RouteAccessResult(hasAccess: true);
  }

  factory RouteAccessResult.denied(String reason, {
    List<String> requiredPermissions = const [],
    List<String> userPermissions = const [],
  }) {
    return RouteAccessResult(
      hasAccess: false,
      reason: reason,
      requiredPermissions: requiredPermissions,
      userPermissions: userPermissions,
    );
  }
}

/// Comprehensive access control service for role-based routing and permissions
class AccessControlService {
  // Role-based permissions mapping
  static const Map<UserRole, Set<String>> _rolePermissions = {
    UserRole.customer: {
      'place_order',
      'view_orders',
      'update_profile',
      'view_vendors',
      'view_menu_items',
      'manage_wallet',
      'view_loyalty_points',
    },
    UserRole.vendor: {
      'manage_menu',
      'view_orders',
      'update_order_status',
      'view_analytics',
      'manage_profile',
      'view_customers',
      'manage_vendor_settings',
    },
    UserRole.salesAgent: {
      'view_all_vendors',
      'manage_vendor_status',
      'view_reports',
      'create_orders',
      'manage_customers',
      'view_analytics',
      'access_sales_tools',
    },
    UserRole.driver: {
      'view_assigned_orders',
      'update_delivery_status',
      'view_earnings',
      'manage_driver_profile',
      'access_gps_tracking',
      'view_delivery_history',
    },
    UserRole.admin: {
      'manage_users',
      'manage_vendors',
      'view_all_data',
      'system_settings',
      'manage_roles',
      'view_analytics',
      'manage_orders',
      'access_admin_panel',
      'manage_drivers',
      'view_financial_reports',
    },
  };

  // Route patterns and their required permissions
  static const Map<String, Set<String>> _routePermissions = {
    // Customer routes
    '/customer/dashboard': {'place_order'},
    '/customer/orders': {'view_orders'},
    '/customer/wallet': {'manage_wallet'},
    '/customer/loyalty': {'view_loyalty_points'},
    '/customer/profile': {'update_profile'},
    
    // Vendor routes
    '/vendor/dashboard': {'manage_menu'},
    '/vendor/orders': {'view_orders', 'update_order_status'},
    '/vendor/menu': {'manage_menu'},
    '/vendor/analytics': {'view_analytics'},
    '/vendor/profile': {'manage_profile'},
    
    // Sales Agent routes
    '/sales-agent/dashboard': {'access_sales_tools'},
    '/sales-agent/vendors': {'view_all_vendors'},
    '/sales-agent/customers': {'manage_customers'},
    '/sales-agent/orders': {'create_orders'},
    '/sales-agent/reports': {'view_reports'},
    
    // Driver routes
    '/driver/dashboard': {'view_assigned_orders'},
    '/driver/orders': {'view_assigned_orders'},
    '/driver/earnings': {'view_earnings'},
    '/driver/profile': {'manage_driver_profile'},
    
    // Admin routes
    '/admin/dashboard': {'access_admin_panel'},
    '/admin/users': {'manage_users'},
    '/admin/vendors': {'manage_vendors'},
    '/admin/orders': {'manage_orders'},
    '/admin/reports': {'view_financial_reports'},
    '/admin/drivers': {'manage_drivers'},
  };

  // Role-based route prefixes
  static const Map<UserRole, List<String>> _roleRoutePatterns = {
    UserRole.customer: ['/customer/', '/sales-agent/'], // Customers can also use sales agent interface
    UserRole.vendor: ['/vendor/'],
    UserRole.salesAgent: ['/sales-agent/'],
    UserRole.driver: ['/driver/'],
    UserRole.admin: ['/admin/', '/vendor/', '/sales-agent/', '/driver/', '/customer/'], // Admin can access all
  };

  // Shared routes accessible by all authenticated users
  static const Set<String> _sharedRoutes = {
    '/settings',
    '/help',
    '/about',
    '/privacy-policy',
    '/terms-of-service',
    '/support',
  };

  /// Check if a user role has a specific permission
  static bool hasPermission(UserRole role, String permission) {
    return _rolePermissions[role]?.contains(permission) ?? false;
  }

  /// Get all permissions for a user role
  static Set<String> getPermissions(UserRole role) {
    return _rolePermissions[role] ?? <String>{};
  }

  /// Check if a user can access a specific route
  static RouteAccessResult checkRouteAccess(String route, UserRole? userRole) {
    if (userRole == null) {
      return RouteAccessResult.denied('User not authenticated');
    }

    debugPrint('🔐 AccessControl: Checking access for route: $route, role: ${userRole.displayName}');

    // Admin can access all routes
    if (userRole == UserRole.admin) {
      debugPrint('🔐 AccessControl: Admin access granted');
      return RouteAccessResult.allowed();
    }

    // Check if it's a shared route
    if (_isSharedRoute(route)) {
      debugPrint('🔐 AccessControl: Shared route access granted');
      return RouteAccessResult.allowed();
    }

    // Check role-based route patterns
    final allowedPatterns = _roleRoutePatterns[userRole] ?? [];
    final hasPatternAccess = allowedPatterns.any((pattern) => route.startsWith(pattern));
    
    if (!hasPatternAccess) {
      debugPrint('🔐 AccessControl: Route pattern access denied');
      return RouteAccessResult.denied(
        'User role ${userRole.displayName} cannot access route $route',
        requiredPermissions: ['access_to_${route.split('/')[1]}'],
        userPermissions: getPermissions(userRole).toList(),
      );
    }

    // Check specific route permissions
    final requiredPermissions = _getRoutePermissions(route);
    final userPermissions = getPermissions(userRole);
    
    if (requiredPermissions.isNotEmpty) {
      final hasRequiredPermissions = requiredPermissions.every(
        (permission) => userPermissions.contains(permission),
      );
      
      if (!hasRequiredPermissions) {
        final missingPermissions = requiredPermissions
            .where((permission) => !userPermissions.contains(permission))
            .toList();
        
        debugPrint('🔐 AccessControl: Missing permissions: $missingPermissions');
        return RouteAccessResult.denied(
          'Missing required permissions: ${missingPermissions.join(', ')}',
          requiredPermissions: requiredPermissions.toList(),
          userPermissions: userPermissions.toList(),
        );
      }
    }

    debugPrint('🔐 AccessControl: Access granted');
    return RouteAccessResult.allowed();
  }

  /// Check if a route is shared (accessible by all authenticated users)
  static bool _isSharedRoute(String route) {
    return _sharedRoutes.any((sharedRoute) => route.startsWith(sharedRoute)) ||
           route.startsWith('/order-details/') ||
           route.startsWith('/vendor-details/');
  }

  /// Get required permissions for a specific route
  static Set<String> _getRoutePermissions(String route) {
    // Check exact match first
    if (_routePermissions.containsKey(route)) {
      return _routePermissions[route]!;
    }

    // Check for pattern matches
    for (final routePattern in _routePermissions.keys) {
      if (route.startsWith(routePattern)) {
        return _routePermissions[routePattern]!;
      }
    }

    return <String>{};
  }

  /// Get the appropriate dashboard route for a user role
  static String getDashboardRoute(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return '/customer/dashboard';
      case UserRole.vendor:
        return '/vendor/dashboard';
      case UserRole.salesAgent:
        return '/sales-agent/dashboard';
      case UserRole.driver:
        return '/driver/dashboard';
      case UserRole.admin:
        return '/admin/dashboard';
    }
  }

  /// Check if a user can perform a specific action
  static bool canPerformAction(UserRole role, String action) {
    return hasPermission(role, action);
  }

  /// Get navigation items available for a user role
  static List<String> getAvailableRoutes(UserRole role) {
    final patterns = _roleRoutePatterns[role] ?? [];
    final routes = <String>[];
    
    for (final pattern in patterns) {
      routes.addAll(_routePermissions.keys.where((route) => route.startsWith(pattern)));
    }
    
    // Add shared routes
    routes.addAll(_sharedRoutes);
    
    return routes;
  }
}
