import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_role.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/sales_agent/presentation/screens/sales_agent_dashboard.dart';
import '../../features/orders/presentation/screens/create_order_screen.dart';
import '../../features/sales_agent/presentation/screens/vendor_details_screen.dart';
import '../../features/sales_agent/presentation/screens/cart_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/sales_agent/presentation/screens/vendors_screen.dart';
import '../../features/payments/presentation/screens/payment_screen.dart';
import '../../features/orders/data/models/order.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/customers/presentation/screens/add_customer_screen.dart';
import '../../features/customers/presentation/screens/customer_details_screen.dart';
import '../../features/customers/presentation/screens/edit_customer_screen.dart';
import '../../features/sales_agent/presentation/screens/sales_agent_profile_screen.dart';
import '../../features/sales_agent/presentation/screens/sales_agent_edit_profile_screen.dart';
import '../../features/sales_agent/presentation/screens/commission_screen.dart';
import '../../features/sales_agent/data/models/sales_agent_profile.dart';
import '../../features/vendors/presentation/screens/vendor_dashboard.dart';
import '../../features/orders/presentation/screens/vendor_orders_screen.dart';
import '../../features/vendors/presentation/screens/vendor_menu_management_screen.dart';
import '../../features/vendors/presentation/screens/vendor_profile_screen.dart';
import '../../features/vendors/presentation/screens/vendor_analytics_screen.dart';
import '../../features/orders/presentation/screens/vendor_order_details_screen.dart';
import '../../features/vendors/presentation/screens/vendor_management_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_orders_screen.dart';
import '../../features/admin/presentation/screens/admin_reports_screen.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/test_screens/data_test_screen.dart';
import '../../shared/test_screens/test_menu_screen.dart';
import '../../shared/test_screens/order_creation_test_screen.dart';
import '../../shared/test_screens/customer_selector_test_screen.dart';
import '../../shared/test_screens/customer_infinite_loop_test.dart';
import '../../shared/test_screens/sales_agent_profile_test_screen.dart';
// TEMPORARILY COMMENTED OUT FOR QUICK WIN
// import '../../shared/test_screens/consolidated_test_screen.dart';
import '../../shared/test_screens/enhanced_features_test_screen.dart';
// import '../../shared/test_screens/customer_selection_test_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/orders/presentation/screens/order_tracking_screen.dart';
import '../../presentation/screens/settings_screen.dart';

// Authentication state notifier for router refresh
class _AuthStateNotifier extends ChangeNotifier {
  final Ref _ref;
  
  _AuthStateNotifier(this._ref) {
    // Listen to auth state changes
    _ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthStateNotifier(ref),
    redirect: (context, state) => _handleRedirect(context, state, ref),
    routes: _buildRoutes(),
    errorBuilder: (context, state) => _buildErrorPage(context, state),
  );
});

// Handle authentication-based redirects
String? _handleRedirect(BuildContext context, GoRouterState state, Ref ref) {
  final authState = ref.read(authStateProvider);
  final location = state.uri.toString();

  debugPrint('🔀 Router: Handling redirect for $location');
  debugPrint('🔀 Router: Auth status: ${authState.status}');

  // Allow access to splash screen during initial load
  if (location == AppRoutes.splash) {
    return null;
  }

  // Allow access to auth routes when not authenticated
  if (location == AppRoutes.login || location == AppRoutes.register) {
    // If already authenticated, redirect to dashboard
    if (authState.status == AuthStatus.authenticated && authState.user != null) {
      return AppRouter.getDashboardRoute(authState.user!.role);
    }
    return null;
  }

  // Allow access to test routes in debug mode
  if (location.startsWith('/test') && kDebugMode) {
    return null;
  }

  // Check authentication for protected routes
  if (authState.status == AuthStatus.loading || authState.status == AuthStatus.initial) {
    // Still loading, stay on splash
    return AppRoutes.splash;
  }

  if (authState.status == AuthStatus.unauthenticated || authState.user == null) {
    // Not authenticated, redirect to login
    debugPrint('🔀 Router: User not authenticated, redirecting to login');
    return AppRoutes.login;
  }

  // User is authenticated, check if they can access the route
  if (!AppRouter.canAccessRoute(location, authState.user!.role)) {
    debugPrint('🔀 Router: User cannot access route $location, redirecting to dashboard');
    return AppRouter.getDashboardRoute(authState.user!.role);
  }

  // Allow access
  return null;
}

// Build error page
Widget _buildErrorPage(BuildContext context, GoRouterState state) {
  return Scaffold(
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
  );
}

// Build all routes
List<RouteBase> _buildRoutes() {
  return [
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
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: 'vendors',
          name: 'sales-agent-vendors',
          builder: (context, state) => const VendorsScreen(),
        ),
        GoRoute(
          path: 'customers',
          name: 'sales-agent-customers',
          builder: (context, state) {
            debugPrint('🚀 Router: Navigating to CustomersScreen');
            debugPrint('🚀 Router: Route path: ${state.fullPath}');
            debugPrint('🚀 Router: Route name: ${state.name}');
            return const CustomersScreen();
          },
          routes: [
            GoRoute(
              path: 'add',
              name: 'add-customer',
              builder: (context, state) => const AddCustomerScreen(),
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
                    return EditCustomerScreen(customerId: customerId);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: 'profile',
          name: 'sales-agent-profile',
          builder: (context, state) => const SalesAgentProfileScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              name: 'sales-agent-profile-edit',
              builder: (context, state) {
                final profile = state.extra as SalesAgentProfile;
                return SalesAgentEditProfileScreen(profile: profile);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'commissions',
          name: 'sales-agent-commissions',
          builder: (context, state) => const CommissionScreen(),
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
          builder: (context, state) => const VendorOrdersScreen(),
        ),
        GoRoute(
          path: 'menu',
          name: 'vendor-menu',
          builder: (context, state) => const VendorMenuManagementScreen(),
        ),
        GoRoute(
          path: 'profile',
          name: 'vendor-profile',
          builder: (context, state) => const VendorProfileScreen(),
        ),
        GoRoute(
          path: 'analytics',
          name: 'vendor-analytics',
          builder: (context, state) => const VendorAnalyticsScreen(),
        ),
        GoRoute(
          path: 'order-details/:orderId',
          name: 'vendor-order-details',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId']!;
            return VendorOrderDetailsScreen(orderId: orderId);
          },
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
          builder: (context, state) => const AdminUsersScreen(),
        ),
        GoRoute(
          path: 'orders',
          name: 'admin-orders',
          builder: (context, state) => const AdminOrdersScreen(),
        ),
        GoRoute(
          path: 'vendors',
          name: 'admin-vendors',
          builder: (context, state) => const VendorManagementScreen(),
        ),
        GoRoute(
          path: 'reports',
          name: 'admin-reports',
          builder: (context, state) => const AdminReportsScreen(),
        ),
      ],
    ),

    // Shared Routes
    GoRoute(
      path: AppRoutes.orderDetails,
      name: 'order-details',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;
        return OrderTrackingScreen(orderId: orderId);
      },
    ),

    // Payment Routes
    GoRoute(
      path: '/payment/:orderId',
      name: 'payment',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;
        // For testing, we'll create a mock order
        // In production, this would fetch the order from the database
        final mockOrder = Order(
          id: orderId,
          orderNumber: 'TEST-001',
          status: OrderStatus.pending,
          items: [],
          vendorId: 'test-vendor',
          vendorName: 'Test Vendor',
          customerId: 'test-customer',
          customerName: 'Test Customer',
          deliveryDate: DateTime.now().add(const Duration(days: 1)),
          deliveryAddress: Address(
            street: '123 Test Street',
            city: 'Kuala Lumpur',
            state: 'Selangor',
            postalCode: '50000',
            country: 'Malaysia',
          ),
          subtotal: 25.00,
          deliveryFee: 5.00,
          sstAmount: 1.50,
          totalAmount: 31.50,
          commissionAmount: 1.75,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        return PaymentScreen(order: mockOrder);
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
      builder: (context, state) => const SettingsScreen(),
    ),

    // Test Routes (only in debug mode)
    GoRoute(
      path: '/test-data',
      name: 'test-data',
      builder: (context, state) => const DataTestScreen(),
    ),
    GoRoute(
      path: '/test-menu',
      name: 'test-menu',
      builder: (context, state) => const TestMenuScreen(),
    ),
    GoRoute(
      path: '/test-order-creation',
      name: 'test-order-creation',
      builder: (context, state) => const OrderCreationTestScreen(),
    ),
    GoRoute(
      path: '/test-customer-selector',
      name: 'test-customer-selector',
      builder: (context, state) => const CustomerSelectorTestScreen(),
    ),
    GoRoute(
      path: '/test-customer-infinite-loop',
      name: 'test-customer-infinite-loop',
      builder: (context, state) => const CustomerInfiniteLoopTest(),
    ),
    // TEMPORARILY COMMENTED OUT FOR QUICK WIN
    // GoRoute(
    //   path: '/test-consolidated',
    //   name: 'test-consolidated',
    //   builder: (context, state) => const ConsolidatedTestScreen(),
    // ),
    GoRoute(
      path: '/test-enhanced-features',
      name: 'test-enhanced-features',
      builder: (context, state) => const EnhancedFeaturesTestScreen(),
    ),
    GoRoute(
      path: '/test-sales-agent-profile',
      name: 'test-sales-agent-profile',
      builder: (context, state) => const SalesAgentProfileTestScreen(),
    ),
    // TEMPORARILY COMMENTED OUT FOR QUICK WIN
    // GoRoute(
    //   path: '/test-customer-selection',
    //   name: 'test-customer-selection',
    //   builder: (context, state) => const CustomerSelectionTestScreen(),
    // ),
  ];
}

class AppRouter {
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
    return route.startsWith('/order-details/') ||
        route.startsWith('/vendor-details/') ||
        route == AppRoutes.settings ||
        route == AppRoutes.help ||
        route == AppRoutes.about;
  }
}
