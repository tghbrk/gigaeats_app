import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_role.dart';
import 'access_control_service.dart';

/// Navigation service for role-based routing and navigation management
/// Phase 5: Role-based Routing & Access Control
class NavigationService {
  
  /// Navigate to the appropriate dashboard based on user role
  static void navigateToDashboard(GoRouter router, UserRole role) {
    final dashboardRoute = AccessControlService.getDashboardRoute(role);
    debugPrint('🧭 Navigation: Navigating to dashboard for ${role.displayName}: $dashboardRoute');
    router.go(dashboardRoute);
  }

  /// Navigate to a route with access control validation
  static bool navigateWithAccessControl(
    GoRouter router, 
    String route, 
    UserRole? userRole, {
    bool showErrorOnDenied = true,
  }) {
    if (userRole == null) {
      debugPrint('🧭 Navigation: User not authenticated, redirecting to login');
      router.go('/login');
      return false;
    }

    final accessResult = AccessControlService.checkRouteAccess(route, userRole);
    if (accessResult.hasAccess) {
      debugPrint('🧭 Navigation: Access granted for $route');
      router.go(route);
      return true;
    } else {
      debugPrint('🧭 Navigation: Access denied for $route. Reason: ${accessResult.reason}');
      if (showErrorOnDenied) {
        // Navigate to dashboard instead
        navigateToDashboard(router, userRole);
      }
      return false;
    }
  }

  /// Get navigation items for a specific role
  static List<NavigationItem> getNavigationItems(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return _getCustomerNavigationItems();
      case UserRole.vendor:
        return _getVendorNavigationItems();
      case UserRole.salesAgent:
        return _getSalesAgentNavigationItems();
      case UserRole.driver:
        return _getDriverNavigationItems();
      case UserRole.admin:
        return _getAdminNavigationItems();
    }
  }

  /// Get customer navigation items
  static List<NavigationItem> _getCustomerNavigationItems() {
    return [
      NavigationItem(
        title: 'Dashboard',
        route: '/customer/dashboard',
        icon: 'dashboard',
        description: 'View your orders and browse restaurants',
      ),
      NavigationItem(
        title: 'My Orders',
        route: '/customer/orders',
        icon: 'orders',
        description: 'Track your current and past orders',
      ),
      NavigationItem(
        title: 'Wallet',
        route: '/customer/wallet',
        icon: 'wallet',
        description: 'Manage your payment methods and balance',
      ),
      NavigationItem(
        title: 'Loyalty Points',
        route: '/customer/loyalty',
        icon: 'loyalty',
        description: 'View and redeem your loyalty points',
      ),
      NavigationItem(
        title: 'Profile',
        route: '/customer/profile',
        icon: 'profile',
        description: 'Manage your account settings',
      ),
    ];
  }

  /// Get vendor navigation items
  static List<NavigationItem> _getVendorNavigationItems() {
    return [
      NavigationItem(
        title: 'Dashboard',
        route: '/vendor/dashboard',
        icon: 'dashboard',
        description: 'Overview of your restaurant performance',
      ),
      NavigationItem(
        title: 'Orders',
        route: '/vendor/orders',
        icon: 'orders',
        description: 'Manage incoming orders',
      ),
      NavigationItem(
        title: 'Menu Management',
        route: '/vendor/menu',
        icon: 'menu',
        description: 'Update your menu items and pricing',
      ),
      NavigationItem(
        title: 'Analytics',
        route: '/vendor/analytics',
        icon: 'analytics',
        description: 'View sales and performance analytics',
      ),
      NavigationItem(
        title: 'Profile',
        route: '/vendor/profile',
        icon: 'profile',
        description: 'Manage restaurant information',
      ),
    ];
  }

  /// Get sales agent navigation items
  static List<NavigationItem> _getSalesAgentNavigationItems() {
    return [
      NavigationItem(
        title: 'Dashboard',
        route: '/sales-agent/dashboard',
        icon: 'dashboard',
        description: 'Sales overview and quick actions',
      ),
      NavigationItem(
        title: 'Vendors',
        route: '/sales-agent/vendors',
        icon: 'vendors',
        description: 'Browse and manage vendor relationships',
      ),
      NavigationItem(
        title: 'Customers',
        route: '/sales-agent/customers',
        icon: 'customers',
        description: 'Manage customer accounts',
      ),
      NavigationItem(
        title: 'Orders',
        route: '/sales-agent/orders',
        icon: 'orders',
        description: 'Create and track orders',
      ),
      NavigationItem(
        title: 'Reports',
        route: '/sales-agent/reports',
        icon: 'reports',
        description: 'View sales reports and analytics',
      ),
    ];
  }

  /// Get driver navigation items
  static List<NavigationItem> _getDriverNavigationItems() {
    return [
      NavigationItem(
        title: 'Dashboard',
        route: '/driver/dashboard',
        icon: 'dashboard',
        description: 'View available and assigned deliveries',
      ),
      NavigationItem(
        title: 'My Orders',
        route: '/driver/orders',
        icon: 'orders',
        description: 'Track your delivery assignments',
      ),
      NavigationItem(
        title: 'Earnings',
        route: '/driver/earnings',
        icon: 'earnings',
        description: 'View your earnings and payment history',
      ),
      NavigationItem(
        title: 'Profile',
        route: '/driver/profile',
        icon: 'profile',
        description: 'Manage your driver profile and settings',
      ),
    ];
  }

  /// Get admin navigation items
  static List<NavigationItem> _getAdminNavigationItems() {
    return [
      NavigationItem(
        title: 'Dashboard',
        route: '/admin/dashboard',
        icon: 'dashboard',
        description: 'System overview and key metrics',
      ),
      NavigationItem(
        title: 'Users',
        route: '/admin/users',
        icon: 'users',
        description: 'Manage all user accounts',
      ),
      NavigationItem(
        title: 'Vendors',
        route: '/admin/vendors',
        icon: 'vendors',
        description: 'Manage vendor accounts and approvals',
      ),
      NavigationItem(
        title: 'Orders',
        route: '/admin/orders',
        icon: 'orders',
        description: 'Monitor all orders in the system',
      ),
      NavigationItem(
        title: 'Drivers',
        route: '/admin/drivers',
        icon: 'drivers',
        description: 'Manage driver fleet and assignments',
      ),
      NavigationItem(
        title: 'Reports',
        route: '/admin/reports',
        icon: 'reports',
        description: 'View comprehensive system reports',
      ),
    ];
  }

  /// Check if a route is accessible for a user role
  static bool isRouteAccessible(String route, UserRole role) {
    final result = AccessControlService.checkRouteAccess(route, role);
    return result.hasAccess;
  }

  /// Get filtered navigation items based on user permissions
  static List<NavigationItem> getAccessibleNavigationItems(UserRole role) {
    final allItems = getNavigationItems(role);
    return allItems.where((item) => isRouteAccessible(item.route, role)).toList();
  }

  /// Get breadcrumb navigation for a route
  static List<BreadcrumbItem> getBreadcrumbs(String currentRoute, UserRole role) {
    final breadcrumbs = <BreadcrumbItem>[];
    
    // Add dashboard as root
    final dashboardRoute = AccessControlService.getDashboardRoute(role);
    breadcrumbs.add(BreadcrumbItem(
      title: 'Dashboard',
      route: dashboardRoute,
    ));

    // Parse route segments
    final segments = currentRoute.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length > 2) {
      // Add intermediate segments
      for (int i = 2; i < segments.length; i++) {
        final segmentRoute = '/${segments.sublist(0, i + 1).join('/')}';
        final title = _getRouteTitle(segments[i]);
        breadcrumbs.add(BreadcrumbItem(
          title: title,
          route: segmentRoute,
        ));
      }
    }

    return breadcrumbs;
  }

  /// Get human-readable title for a route segment
  static String _getRouteTitle(String segment) {
    switch (segment) {
      case 'orders':
        return 'Orders';
      case 'menu':
        return 'Menu';
      case 'analytics':
        return 'Analytics';
      case 'profile':
        return 'Profile';
      case 'vendors':
        return 'Vendors';
      case 'customers':
        return 'Customers';
      case 'reports':
        return 'Reports';
      case 'users':
        return 'Users';
      case 'drivers':
        return 'Drivers';
      case 'wallet':
        return 'Wallet';
      case 'loyalty':
        return 'Loyalty';
      case 'earnings':
        return 'Earnings';
      default:
        return segment.split('-').map((word) => 
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }
}

/// Navigation item model
class NavigationItem {
  final String title;
  final String route;
  final String icon;
  final String description;
  final bool isActive;

  const NavigationItem({
    required this.title,
    required this.route,
    required this.icon,
    required this.description,
    this.isActive = false,
  });

  NavigationItem copyWith({
    String? title,
    String? route,
    String? icon,
    String? description,
    bool? isActive,
  }) {
    return NavigationItem(
      title: title ?? this.title,
      route: route ?? this.route,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Breadcrumb item model
class BreadcrumbItem {
  final String title;
  final String route;

  const BreadcrumbItem({
    required this.title,
    required this.route,
  });
}
