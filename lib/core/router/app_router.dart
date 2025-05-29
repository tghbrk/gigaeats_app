import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_role.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/sales_agent/sales_agent_dashboard.dart';
import '../../presentation/screens/sales_agent/create_order_screen.dart';
import '../../presentation/screens/sales_agent/vendor_details_screen.dart';
import '../../presentation/screens/sales_agent/cart_screen.dart';
import '../../presentation/screens/sales_agent/customers_screen.dart';
import '../../presentation/screens/sales_agent/customer_details_screen.dart';
import '../../presentation/screens/sales_agent/customer_form_screen.dart';
import '../../presentation/screens/vendor/vendor_dashboard.dart';
import '../../presentation/screens/admin/admin_dashboard.dart';
import '../../core/constants/app_constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication Routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Sales Agent Routes
      GoRoute(
        path: AppRoutes.salesAgentDashboard,
        name: 'sales-agent-dashboard',
        builder: (context, state) => const SalesAgentDashboard(),
        routes: [
          GoRoute(
            path: 'create-order',
            name: 'create-order',
            builder: (context, state) => const CreateOrderScreen(),
          ),
          GoRoute(
            path: 'cart',
            name: 'cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: 'orders',
            name: 'sales-agent-orders',
            builder: (context, state) => const Placeholder(), // TODO: Implement
          ),
          GoRoute(
            path: 'vendors',
            name: 'sales-agent-vendors',
            builder: (context, state) => const Placeholder(), // TODO: Implement
          ),
          GoRoute(
            path: 'customers',
            name: 'sales-agent-customers',
            builder: (context, state) => const CustomersScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'create-customer',
                builder: (context, state) => const CustomerFormScreen(),
              ),
              GoRoute(
                path: ':customerId',
                name: 'customer-details',
                builder: (context, state) {
                  final customerId = state.pathParameters['customerId']!;
                  return CustomerDetailsScreen(customerId: customerId);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'edit-customer',
                    builder: (context, state) {
                      final customerId = state.pathParameters['customerId']!;
                      return CustomerFormScreen(customerId: customerId);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'profile',
            name: 'sales-agent-profile',
            builder: (context, state) => const Placeholder(), // TODO: Implement
          ),
          GoRoute(
            path: 'commissions',
            name: 'sales-agent-commissions',
            builder: (context, state) => const Placeholder(), // TODO: Implement
          ),
        ],
      ),

      // Vendor Routes
      GoRoute(
        path: AppRoutes.vendorDashboard,
        name: 'vendor-dashboard',
        builder: (context, state) => const VendorDashboard(),
        routes: [
          GoRoute(
            path: 'orders',
            name: 'vendor-orders',
            builder: (context, state) => const Placeholder(), // TODO: Implement
          ),
          GoRoute(
            path: 'menu',
            name: 'vendor-menu',
            builder: (context, state) => const Placeholder(), // TODO: Implement
          ),
          GoRoute(
            path: 'profile',
            name: 'vendor-profile',
            builder: (context, state) => const Placeholder(), // TODO: Implement
          ),
          GoRoute(
            path: 'analytics',
            name: 'vendor-analytics',
            builder: (context, state) => const Placeholder(), // TODO: Implement
          ),
        ],
      ),

      // Admin Routes
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboard(),
        routes: [
          GoRoute(
            path: 'users',
            name: 'admin-users',
            builder: (context, state) => const Placeholder(), // TODO: Implement
          ),
          GoRoute(
            path: 'orders',
            name: 'admin-orders',
            builder: (context, state) => const Placeholder(), // TODO: Implement
          ),
          GoRoute(
            path: 'vendors',
            name: 'admin-vendors',
            builder: (context, state) => const Placeholder(), // TODO: Implement
          ),
          GoRoute(
            path: 'reports',
            name: 'admin-reports',
            builder: (context, state) => const Placeholder(), // TODO: Implement
          ),
        ],
      ),

      // Shared Routes
      GoRoute(
        path: AppRoutes.orderDetails,
        name: 'order-details',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return Placeholder(); // TODO: Implement OrderDetailsScreen(orderId: orderId)
        },
      ),
      GoRoute(
        path: AppRoutes.vendorDetails,
        name: 'vendor-details',
        builder: (context, state) {
          final vendorId = state.pathParameters['vendorId']!;
          return VendorDetailsScreen(vendorId: vendorId);
        },
      ),

      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const Placeholder(), // TODO: Implement
      ),
    ],
    redirect: (context, state) {
      // TODO: Implement authentication and role-based redirection logic
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.splash),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  // Helper method to get the appropriate dashboard route based on user role
  static String getDashboardRoute(UserRole role) {
    switch (role) {
      case UserRole.salesAgent:
        return AppRoutes.salesAgentDashboard;
      case UserRole.vendor:
        return AppRoutes.vendorDashboard;
      case UserRole.admin:
        return AppRoutes.adminDashboard;
      case UserRole.customer:
        return AppRoutes.salesAgentDashboard; // Customers use sales agent interface
    }
  }

  // Helper method to check if user can access a route
  static bool canAccessRoute(String route, UserRole? userRole) {
    if (userRole == null) {
      // Only allow access to auth routes if not logged in
      return route == AppRoutes.splash ||
          route == AppRoutes.login ||
          route == AppRoutes.register;
    }

    // Admin can access all routes
    if (userRole == UserRole.admin) {
      return true;
    }

    // Sales agents can access sales agent routes and shared routes
    if (userRole == UserRole.salesAgent) {
      return route.startsWith(AppRoutes.salesAgentDashboard) ||
          _isSharedRoute(route);
    }

    // Vendors can access vendor routes and shared routes
    if (userRole == UserRole.vendor) {
      return route.startsWith(AppRoutes.vendorDashboard) || _isSharedRoute(route);
    }

    // Customers can access sales agent routes (they use the same interface)
    if (userRole == UserRole.customer) {
      return route.startsWith(AppRoutes.salesAgentDashboard) ||
          _isSharedRoute(route);
    }

    return false;
  }

  // Helper method to check if a route is shared
  static bool _isSharedRoute(String route) {
    return route == AppRoutes.orderDetails ||
        route == AppRoutes.vendorDetails ||
        route == AppRoutes.settings ||
        route == AppRoutes.help ||
        route == AppRoutes.about;
  }
}
