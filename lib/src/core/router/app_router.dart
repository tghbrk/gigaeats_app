import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_role.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/role_signup_screen.dart';
import '../../features/auth/presentation/screens/signup_role_selection_screen.dart';
import '../../features/auth/presentation/screens/enhanced_email_verification_screen.dart';
import '../../features/user_management/presentation/screens/sales_agent/sales_agent_dashboard.dart';
import '../../features/orders/presentation/screens/shared/create_order_screen.dart';
import '../../features/menu/presentation/screens/sales_agent/vendor_details_screen.dart';
import '../../features/orders/presentation/screens/sales_agent/cart_screen.dart';
import '../../features/orders/presentation/screens/shared/orders_screen.dart';
import '../../features/menu/presentation/screens/sales_agent/vendors_screen.dart';
import '../../features/payments/presentation/screens/payment_screen.dart';
import '../../features/orders/data/models/order.dart';
import '../../features/admin/presentation/screens/customer_management/customers_screen.dart';
import '../../features/admin/presentation/screens/customer_management/add_customer_screen.dart';
import '../../features/admin/presentation/screens/customer_management/customer_details_screen.dart';
import '../../features/admin/presentation/screens/customer_management/edit_customer_screen.dart';
import '../../features/user_management/presentation/screens/customer/customer_dashboard.dart';
import '../../features/orders/presentation/screens/customer/customer_orders_screen.dart';
import '../../features/orders/presentation/screens/customer/customer_order_details_screen.dart';
import '../../features/orders/presentation/screens/customer/customer_order_tracking_screen.dart';
import '../../features/menu/presentation/screens/customer/customer_restaurants_screen.dart';
import '../../features/menu/presentation/screens/customer/customer_restaurant_details_screen.dart';
import '../../features/menu/presentation/screens/customer/customer_menu_item_details_screen.dart';
import '../../features/orders/presentation/screens/customer/customer_cart_screen.dart';
import '../../features/payments/presentation/screens/customer/customer_checkout_screen.dart';
import '../../features/user_management/presentation/screens/sales_agent/sales_agent_profile_screen.dart';
import '../../features/user_management/presentation/screens/sales_agent/sales_agent_edit_profile_screen.dart';
import '../../features/user_management/presentation/screens/customer/customer_profile_screen.dart';
import '../../features/user_management/presentation/screens/customer/customer_profile_edit_screen.dart';
import '../../features/user_management/presentation/screens/customer/customer_account_settings_screen.dart';
import '../../features/user_management/presentation/screens/customer/customer_addresses_screen.dart';
import '../../features/user_management/presentation/screens/customer/customer_address_selection_screen.dart';
import '../../features/marketplace_wallet/presentation/screens/customer_payment_methods_screen.dart';
import '../../features/marketplace_wallet/presentation/screens/add_payment_method_screen.dart';

// Enhanced wallet imports
import '../../features/marketplace_wallet/presentation/screens/enhanced_customer_wallet_dashboard.dart';
import '../../features/marketplace_wallet/presentation/screens/customer/customer_wallet_topup_screen.dart';
import '../../features/marketplace_wallet/presentation/screens/customer/customer_wallet_transfer_screen.dart';
import '../../features/marketplace_wallet/presentation/screens/customer/customer_wallet_transfer_history_screen.dart';
import '../../features/marketplace_wallet/presentation/screens/customer/customer_wallet_transaction_history_screen.dart';
import '../../features/marketplace_wallet/presentation/screens/customer/customer_wallet_settings_screen.dart';
import '../../features/marketplace_wallet/presentation/screens/customer/customer_spending_analytics_screen.dart';
import '../../features/customers/presentation/screens/loyalty_dashboard_screen.dart';
import '../../features/payments/presentation/screens/sales_agent/commission_screen.dart';
import '../../features/customer_support/presentation/screens/customer_support_screen.dart';
import '../../features/customer_support/presentation/screens/create_support_ticket_screen.dart';
import '../../features/user_management/data/models/sales_agent_profile.dart';
import '../../features/user_management/presentation/screens/vendor/vendor_dashboard.dart';
import '../../features/orders/presentation/screens/vendor/vendor_orders_screen.dart';
import '../../features/menu/presentation/screens/vendor/vendor_menu_management_screen.dart';
import '../../features/menu/presentation/screens/vendor/template_analytics_dashboard_screen.dart';
import '../../features/user_management/presentation/screens/vendor/vendor_profile_screen.dart';
import '../../features/user_management/presentation/screens/vendor/vendor_analytics_screen.dart';
import '../../features/orders/presentation/screens/vendor/vendor_order_details_screen.dart';
import '../../features/admin/presentation/screens/vendor_management/vendor_management_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard.dart';
import '../../features/user_management/presentation/screens/admin/admin_users_screen.dart';
import '../../features/orders/presentation/screens/admin/admin_orders_screen.dart';
import '../../features/admin/presentation/screens/admin_reports_screen.dart';
import '../../features/drivers/presentation/screens/driver_dashboard.dart';
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
import '../../features/auth/presentation/providers/enhanced_auth_provider.dart';
import '../../features/orders/presentation/screens/shared/order_tracking_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../services/access_control_service.dart';

// Authentication state notifier for router refresh
class _AuthStateNotifier extends ChangeNotifier {
  final Ref _ref;
  AuthStatus? _lastAuthStatus;

  _AuthStateNotifier(this._ref) {
    // Listen to auth state changes with debouncing to prevent infinite loops
    _ref.listen(authStateProvider, (previous, next) {
      debugPrint('🔀 Router: Auth state changed from ${previous?.status} to ${next.status}');

      // Only notify if the auth status actually changed to prevent infinite loops
      if (_lastAuthStatus != next.status) {
        _lastAuthStatus = next.status;
        debugPrint('🔀 Router: Notifying listeners of auth status change to ${next.status}');
        notifyListeners();
      } else {
        debugPrint('🔀 Router: Ignoring duplicate auth status: ${next.status}');
      }
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

// Handle authentication-based redirects with enhanced role-based access control
String? _handleRedirect(BuildContext context, GoRouterState state, Ref ref) {
  final authState = ref.read(authStateProvider);
  final enhancedAuthState = ref.read(enhancedAuthStateProvider);
  final location = state.uri.toString();

  debugPrint('🔀 Router: Handling redirect for $location');
  debugPrint('🔀 Router: Auth status: ${authState.status}');
  debugPrint('🔀 Router: Enhanced auth status: ${enhancedAuthState.status}');

  // Handle authentication callback routes
  if (location.startsWith('/auth/callback')) {
    return null; // Allow access to callback handler
  }

  // Handle role-specific signup routes
  if (location.startsWith('/signup/')) {
    // Allow access to role-specific signup screens
    return null;
  }

  // Handle email verification routes
  if (location.startsWith('/email-verification')) {
    return null; // Allow access to email verification screens
  }

  // Allow access to splash screen during initial load
  if (location == AppRoutes.splash) {
    return null;
  }

  // Public routes that don't require authentication
  final publicRoutes = [
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
    '/welcome',
    '/signup-role-selection',
  ];

  if (publicRoutes.any((route) => location.startsWith(route))) {
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

  // Handle enhanced auth states
  if (enhancedAuthState.status == EnhancedAuthStatus.emailVerificationPending) {
    if (!location.startsWith('/email-verification')) {
      final email = enhancedAuthState.pendingVerificationEmail ?? '';
      return '/email-verification?email=${Uri.encodeComponent(email)}';
    }
    return null;
  }

  if (authState.status == AuthStatus.unauthenticated || authState.user == null) {
    // Not authenticated, redirect to login
    debugPrint('🔀 Router: User not authenticated, redirecting to login');
    return AppRoutes.login;
  }

  // User is authenticated, check role-based access control
  final accessResult = AccessControlService.checkRouteAccess(location, authState.user!.role);
  if (!accessResult.hasAccess) {
    debugPrint('🔀 Router: Access denied for route $location. Reason: ${accessResult.reason}');
    debugPrint('🔀 Router: Redirecting to dashboard');
    return AccessControlService.getDashboardRoute(authState.user!.role);
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

    // Enhanced Authentication Routes (Phase 4 & 5)
    GoRoute(
      path: '/signup-role-selection',
      name: 'signup-role-selection',
      builder: (context, state) => const SignupRoleSelectionScreen(),
    ),
    GoRoute(
      path: '/signup/:role',
      name: 'role-signup',
      builder: (context, state) {
        final roleString = state.pathParameters['role']!;
        final role = UserRole.fromString(roleString);
        return RoleSignupScreen(role: role);
      },
    ),
    GoRoute(
      path: '/email-verification',
      name: 'email-verification',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'];
        return EnhancedEmailVerificationScreen(email: email);
      },
    ),
    GoRoute(
      path: '/auth/callback',
      name: 'auth-callback',
      builder: (context, state) {
        // Handle deep link callback for email verification
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing verification...'),
              ],
            ),
          ),
        );
      },
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
          path: 'template-analytics/:vendorId',
          name: 'vendor-template-analytics',
          builder: (context, state) {
            final vendorId = state.pathParameters['vendorId']!;
            return TemplateAnalyticsDashboardScreen(vendorId: vendorId);
          },
        ),
        GoRoute(
          path: 'order-details/:orderId',
          name: 'vendor-order-details',
          builder: (context, state) {
            debugPrint('🔍 [ROUTER] Building VendorOrderDetailsScreen route');
            debugPrint('🔍 [ROUTER] Full path: ${state.fullPath}');
            debugPrint('🔍 [ROUTER] Path parameters: ${state.pathParameters}');
            final orderId = state.pathParameters['orderId']!;
            debugPrint('🔍 [ROUTER] Extracted order ID: $orderId');
            debugPrint('🔍 [ROUTER] Creating VendorOrderDetailsScreen with order ID: $orderId');
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

    // Driver Routes
    GoRoute(
      path: AppRoutes.driverDashboard,
      name: 'driver-dashboard',
      builder: (context, state) => const DriverDashboard(),
    ),

    // Customer Routes (Phase 5: Role-based Routing)
    GoRoute(
      path: '/customer/dashboard',
      name: 'customer-dashboard',
      builder: (context, state) => const CustomerDashboard(), // Fixed: Use proper CustomerDashboard
    ),
    GoRoute(
      path: '/customer/restaurants',
      name: 'customer-restaurants',
      builder: (context, state) {
        debugPrint('🏪 [ROUTER] Building CustomerRestaurantsScreen');
        return const CustomerRestaurantsScreen();
      },
    ),
    GoRoute(
      path: '/customer/restaurant/:vendorId',
      name: 'customer-restaurant-details',
      builder: (context, state) {
        final vendorId = state.pathParameters['vendorId']!;
        debugPrint('🏪 [ROUTER] Building CustomerRestaurantDetailsScreen for vendor: $vendorId');
        return CustomerRestaurantDetailsScreen(restaurantId: vendorId);
      },
    ),
    GoRoute(
      path: '/customer/menu-item/:productId',
      name: 'customer-menu-item-details',
      builder: (context, state) {
        final productId = state.pathParameters['productId']!;
        debugPrint('🍽️ [ROUTER] Building CustomerMenuItemDetailsScreen for product: $productId');
        final screen = CustomerMenuItemDetailsScreen(menuItemId: productId);
        debugPrint('🍽️ [ROUTER] CustomerMenuItemDetailsScreen created successfully');
        return screen;
      },
    ),
    GoRoute(
      path: '/customer/cart',
      name: 'customer-cart',
      builder: (context, state) {
        debugPrint('🛒 [ROUTER] Building CustomerCartScreen');
        return const CustomerCartScreen();
      },
    ),
    GoRoute(
      path: '/customer/checkout',
      name: 'customer-checkout',
      builder: (context, state) {
        debugPrint('💳 [ROUTER] Building CustomerCheckoutScreen');
        return const CustomerCheckoutScreen();
      },
    ),
    GoRoute(
      path: '/customer/orders',
      name: 'customer-orders',
      builder: (context, state) => const CustomerOrdersScreen(), // Fixed: Use proper CustomerOrdersScreen
    ),
    GoRoute(
      path: '/customer/wallet',
      name: 'customer-wallet',
      builder: (context, state) => const EnhancedCustomerWalletDashboard(),
      routes: [
        GoRoute(
          path: 'top-up',
          name: 'wallet-top-up',
          builder: (context, state) => const CustomerWalletTopupScreen(),
        ),
        GoRoute(
          path: 'transfer',
          name: 'wallet-transfer',
          builder: (context, state) => const CustomerWalletTransferScreen(),
        ),
        GoRoute(
          path: 'transfer-history',
          name: 'wallet-transfer-history',
          builder: (context, state) => const CustomerWalletTransferHistoryScreen(),
        ),
        GoRoute(
          path: 'transactions',
          name: 'wallet-transactions',
          builder: (context, state) => const CustomerWalletTransactionHistoryScreen(),
        ),
        GoRoute(
          path: 'payment-methods',
          name: 'wallet-payment-methods',
          builder: (context, state) => const CustomerPaymentMethodsScreen(),
        ),
        GoRoute(
          path: 'loyalty',
          name: 'wallet-loyalty',
          builder: (context, state) => const LoyaltyDashboardScreen(),
        ),
        GoRoute(
          path: 'settings',
          name: 'wallet-settings',
          builder: (context, state) => const CustomerWalletSettingsScreen(),
        ),
        GoRoute(
          path: 'security',
          name: 'wallet-security',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Wallet Security - Coming Soon')),
          ),
        ),
        GoRoute(
          path: 'analytics',
          name: 'wallet-analytics',
          builder: (context, state) => const CustomerSpendingAnalyticsScreen(),
        ),
        GoRoute(
          path: 'notifications',
          name: 'wallet-notifications',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Wallet Notifications - Coming Soon')),
          ),
        ),
        GoRoute(
          path: 'help',
          name: 'wallet-help',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Wallet Help - Coming Soon')),
          ),
        ),
        GoRoute(
          path: 'export',
          name: 'wallet-export',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Wallet Export - Coming Soon')),
          ),
        ),
        GoRoute(
          path: 'transaction/:transactionId',
          name: 'wallet-transaction-details',
          builder: (context, state) {
            final transactionId = state.pathParameters['transactionId']!;
            return Scaffold(
              body: Center(child: Text('Transaction Details: $transactionId - Coming Soon')),
            );
          },
        ),
        GoRoute(
          path: 'promotions',
          name: 'wallet-promotions',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Wallet Promotions - Coming Soon')),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/customer/loyalty',
      name: 'customer-loyalty',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: Text('Customer Loyalty - Coming Soon'),
        ),
      ),
    ),
    GoRoute(
      path: '/customer/profile',
      name: 'customer-profile',
      builder: (context, state) => const CustomerProfileScreen(),
      routes: [
        GoRoute(
          path: 'edit',
          name: 'customer-profile-edit',
          builder: (context, state) => const CustomerProfileEditScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/customer/addresses',
      name: 'customer-addresses',
      builder: (context, state) => const CustomerAddressesScreen(),
      routes: [
        GoRoute(
          path: 'select',
          name: 'customer-address-selection',
          builder: (context, state) {
            final selectedAddressId = state.uri.queryParameters['selected'];
            return CustomerAddressSelectionScreen(
              selectedAddressId: selectedAddressId,
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/customer/settings',
      name: 'customer-account-settings',
      builder: (context, state) => const CustomerAccountSettingsScreen(),
    ),

    // Customer Payment Methods Routes
    GoRoute(
      path: '/customer/payment-methods',
      name: 'customer-payment-methods',
      builder: (context, state) => const CustomerPaymentMethodsScreen(),
      routes: [
        GoRoute(
          path: 'add',
          name: 'customer-payment-methods-add',
          builder: (context, state) => const AddPaymentMethodScreen(),
        ),
      ],
    ),

    // Customer Order Routes
    GoRoute(
      path: '/customer/order/:orderId',
      name: 'customer-order-details',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;
        return CustomerOrderDetailsScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/customer/order/:orderId/track',
      name: 'customer-order-tracking',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;
        return CustomerOrderTrackingScreen(orderId: orderId);
      },
    ),

    // Customer Support Routes
    GoRoute(
      path: '/customer/support',
      name: 'customer-support',
      builder: (context, state) => const CustomerSupportScreen(),
    ),
    GoRoute(
      path: '/customer/support/create-ticket',
      name: 'customer-support-create-ticket',
      builder: (context, state) {
        final orderId = state.uri.queryParameters['orderId'];
        return CreateSupportTicketScreen(orderId: orderId);
      },
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
    return AccessControlService.getDashboardRoute(role);
  }

  // Helper method to check if user can access a route
  static bool canAccessRoute(String route, UserRole? userRole) {
    final result = AccessControlService.checkRouteAccess(route, userRole);
    return result.hasAccess;
  }

  // Enhanced method to get detailed access information
  static RouteAccessResult checkRouteAccess(String route, UserRole? userRole) {
    return AccessControlService.checkRouteAccess(route, userRole);
  }



  // Get available routes for a user role
  static List<String> getAvailableRoutes(UserRole role) {
    return AccessControlService.getAvailableRoutes(role);
  }

  // Check if user has specific permission
  static bool hasPermission(UserRole role, String permission) {
    return AccessControlService.hasPermission(role, permission);
  }

  // Get all permissions for a user role
  static Set<String> getPermissions(UserRole role) {
    return AccessControlService.getPermissions(role);
  }
}
