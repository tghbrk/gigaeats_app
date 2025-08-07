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
import '../../features/customers/presentation/screens/enhanced_customer_orders_screen.dart';
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
import '../../features/marketplace_wallet/presentation/screens/customer/customer_unified_wallet_verification_screen.dart';
import '../../features/marketplace_wallet/presentation/screens/customer/customer_wallet_document_upload_screen.dart';
import '../../features/marketplace_wallet/presentation/screens/customer/customer_wallet_instant_verification_screen.dart';
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
import '../../features/user_management/presentation/screens/vendor/vendor_profile_edit_screen.dart';
import '../../features/user_management/presentation/screens/vendor/vendor_analytics_screen.dart';
import '../../features/orders/presentation/screens/vendor/vendor_order_details_screen.dart';
import '../../features/admin/presentation/screens/vendor_management/vendor_management_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard.dart';
import '../../features/user_management/presentation/screens/admin/admin_users_screen.dart';
import '../../features/orders/presentation/screens/admin/admin_orders_screen.dart';
import '../../features/admin/presentation/screens/admin_reports_screen.dart';
import '../../features/drivers/presentation/screens/driver_dashboard.dart';
import '../../features/drivers/presentation/screens/driver_orders_management_screen.dart';
import '../../features/drivers/presentation/screens/multi_order_driver_dashboard.dart';
import '../../features/drivers/presentation/screens/in_app_navigation_screen.dart';
import '../../features/drivers/presentation/screens/driver_wallet_dashboard_screen.dart';
import '../../features/drivers/presentation/screens/driver_withdrawal_history_screen.dart';
import '../../features/drivers/presentation/screens/driver_withdrawal_detail_screen.dart';
import '../../features/drivers/presentation/screens/driver_withdrawal_request_screen.dart';
import '../../features/drivers/presentation/screens/driver_wallet_transaction_history_screen.dart';
import '../../features/drivers/presentation/screens/driver_wallet_transaction_detail_screen.dart';
import '../../features/drivers/presentation/screens/driver_wallet_verification_screen.dart';
import '../../features/drivers/presentation/screens/driver_unified_wallet_verification_screen.dart';
import '../../features/drivers/presentation/screens/driver_bank_account_verification_screen.dart';
import '../../features/drivers/presentation/screens/driver_bank_account_add_screen.dart';
import '../../features/drivers/presentation/screens/driver_wallet_document_upload_screen.dart';
import '../../features/drivers/presentation/screens/driver_wallet_instant_verification_screen.dart';
import '../../features/drivers/presentation/providers/enhanced_navigation_provider.dart';
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
      debugPrint('🔀 Router: Previous user: ${previous?.user?.email}');
      debugPrint('🔀 Router: Next user: ${next.user?.email}');

      // Only notify if the auth status actually changed to prevent infinite loops
      if (_lastAuthStatus != next.status) {
        _lastAuthStatus = next.status;
        debugPrint('🔀 Router: Notifying listeners of auth status change to ${next.status}');
        debugPrint('🔀 Router: This will trigger router refresh and redirect logic');
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
      final dashboardRoute = AppRouter.getDashboardRoute(authState.user!.role);
      debugPrint('🔀 Router: User already authenticated, redirecting from $location to $dashboardRoute');
      debugPrint('🔀 Router: User role: ${authState.user!.role}');
      return dashboardRoute;
    }
    debugPrint('🔀 Router: Allowing access to public route: $location');
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
    debugPrint('🔀 Router: Auth status: ${authState.status}');
    debugPrint('🔀 Router: User: ${authState.user}');
    debugPrint('🔀 Router: Current location: $location');
    debugPrint('🔀 Router: Redirecting to: ${AppRoutes.login}');
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
          routes: [
            GoRoute(
              path: 'edit',
              name: 'vendor-profile-edit',
              builder: (context, state) => const VendorProfileEditScreen(),
            ),
          ],
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
      routes: [
        GoRoute(
          path: 'orders',
          name: 'driver-orders-management',
          builder: (context, state) => const DriverOrdersManagementScreen(),
        ),
        GoRoute(
          path: 'wallet',
          name: 'driver-wallet',
          builder: (context, state) => const DriverWalletDashboardScreen(),
          routes: [
            GoRoute(
              path: 'withdraw',
              name: 'driver-wallet-withdraw',
              builder: (context, state) => const DriverWithdrawalRequestScreen(),
            ),
            GoRoute(
              path: 'withdrawals',
              name: 'driver-wallet-withdrawals',
              builder: (context, state) => const DriverWithdrawalHistoryScreen(),
            ),
            GoRoute(
              path: 'withdrawal/:withdrawalId',
              name: 'driver-wallet-withdrawal-detail',
              builder: (context, state) {
                final withdrawalId = state.pathParameters['withdrawalId']!;
                return DriverWithdrawalDetailScreen(withdrawalId: withdrawalId);
              },
            ),
            GoRoute(
              path: 'transactions',
              name: 'driver-wallet-transactions',
              builder: (context, state) => const DriverWalletTransactionHistoryScreen(),
            ),
            GoRoute(
              path: 'transaction/:transactionId',
              name: 'driver-wallet-transaction-detail',
              builder: (context, state) {
                final transactionId = state.pathParameters['transactionId']!;
                return DriverWalletTransactionDetailScreen(transactionId: transactionId);
              },
            ),
            GoRoute(
              path: 'settings',
              name: 'driver-wallet-settings',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Driver Wallet Settings - Coming Soon')),
              ),
            ),
            GoRoute(
              path: 'support',
              name: 'driver-wallet-support',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Driver Wallet Support - Coming Soon')),
              ),
            ),
            GoRoute(
              path: 'analytics',
              name: 'driver-wallet-analytics',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Driver Wallet Analytics - Coming Soon')),
              ),
            ),

            GoRoute(
              path: 'security',
              name: 'driver-wallet-security',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Driver Wallet Security - Coming Soon')),
              ),
            ),
            GoRoute(
              path: 'notifications',
              name: 'driver-wallet-notifications',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Driver Wallet Notifications - Coming Soon')),
              ),
            ),
            GoRoute(
              path: 'bank-accounts/add',
              name: 'driver-wallet-bank-accounts-add',
              builder: (context, state) => const DriverBankAccountAddScreen(),
            ),
          ],
        ),
        GoRoute(
          path: 'navigation',
          name: 'driver-navigation',
          builder: (context, state) {
            debugPrint('🚨 [ROUTER] /driver/navigation OUTER builder called - BEFORE Consumer');
            debugPrint('🚨 [ROUTER] Context: $context');
            debugPrint('🚨 [ROUTER] State: $state');
            debugPrint('🚨 [ROUTER] State path: ${state.fullPath}');

            return Consumer(
              builder: (context, ref, child) {
                debugPrint('🚨 [ROUTER] /driver/navigation INNER Consumer builder called');
                try {
                  debugPrint('🧭 [ROUTER] /driver/navigation route builder called');

                final navState = ref.watch(enhancedNavigationProvider);

                debugPrint('🧭 [ROUTER] /driver/navigation accessed');
                debugPrint('🧭 [ROUTER] Navigation state - isNavigating: ${navState.isNavigating}');
                debugPrint('🧭 [ROUTER] Navigation state - currentSession: ${navState.currentSession?.id ?? 'null'}');
                debugPrint('🧭 [ROUTER] Navigation state - error: ${navState.error ?? 'none'}');

                // If no active navigation session, show loading screen briefly before redirecting
                // This handles race conditions where state hasn't been set yet
                if (!navState.isNavigating || navState.currentSession == null) {
                  debugPrint('⚠️ [ROUTER] No active navigation session detected');
                  debugPrint('⚠️ [ROUTER] isNavigating: ${navState.isNavigating}, currentSession: ${navState.currentSession?.id ?? 'null'}');
                  debugPrint('⚠️ [ROUTER] Navigation error: ${navState.error ?? 'none'}');

                  // Give a longer moment for state to update before redirecting
                  Future.delayed(const Duration(milliseconds: 3000), () {
                    if (context.mounted) {
                      final updatedState = ref.read(enhancedNavigationProvider);
                      debugPrint('🔄 [ROUTER] Rechecking navigation state after delay...');
                      debugPrint('🔄 [ROUTER] Updated state - isNavigating: ${updatedState.isNavigating}, currentSession: ${updatedState.currentSession?.id ?? 'null'}');
                      debugPrint('🔄 [ROUTER] Updated state - error: ${updatedState.error ?? 'none'}');

                      if (!updatedState.isNavigating || updatedState.currentSession == null) {
                        debugPrint('❌ [ROUTER] Still no navigation session after delay, redirecting to dashboard');
                        debugPrint('❌ [ROUTER] Final error state: ${updatedState.error ?? 'No error reported'}');
                        context.go('/driver/dashboard');
                      }
                    }
                  });

                  return Scaffold(
                    backgroundColor: Colors.black,
                    body: SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Starting Navigation...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Initializing Enhanced In-App Navigation',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            if (navState.error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 32),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade300,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Navigation Setup Error',
                                      style: TextStyle(
                                        color: Colors.red.shade300,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      navState.error!,
                                      style: TextStyle(
                                        color: Colors.red.shade200,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: () {
                                debugPrint('🔄 [ROUTER] User cancelled navigation loading');
                                context.go('/driver/dashboard');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                debugPrint('✅ [ROUTER] Active navigation session found, attempting to render InAppNavigationScreen');
                debugPrint('✅ [ROUTER] Session details: ID=${navState.currentSession!.id}, Status=${navState.currentSession!.status}');
                debugPrint('✅ [ROUTER] Session origin: ${navState.currentSession!.origin}');
                debugPrint('✅ [ROUTER] Session destination: ${navState.currentSession!.destination}');

                // Validate session before rendering
                if (navState.currentSession!.id.isEmpty) {
                  debugPrint('❌ [ROUTER] Invalid navigation session ID');
                  throw Exception('Invalid navigation session');
                }

                debugPrint('🧭 [ROUTER] Creating InAppNavigationScreen widget...');

                try {
                  // Validate session data before creating widget
                  debugPrint('🔍 [ROUTER] Validating session data...');
                  debugPrint('🔍 [ROUTER] Session ID: ${navState.currentSession!.id}');
                  debugPrint('🔍 [ROUTER] Session status: ${navState.currentSession!.status}');
                  debugPrint('🔍 [ROUTER] Session origin: ${navState.currentSession!.origin.latitude}, ${navState.currentSession!.origin.longitude}');
                  debugPrint('🔍 [ROUTER] Session destination: ${navState.currentSession!.destination.latitude}, ${navState.currentSession!.destination.longitude}');
                  debugPrint('🔍 [ROUTER] Session route points: ${navState.currentSession!.route.polylinePoints.length}');

                  // Create the navigation screen with comprehensive error handling
                  debugPrint('🧭 [ROUTER] Instantiating InAppNavigationScreen...');

                  final navigationScreen = InAppNavigationScreen(
                    session: navState.currentSession!,
                    onNavigationComplete: () {
                      debugPrint('🏁 [ROUTER] Navigation completed, returning to dashboard');
                      context.go('/driver/dashboard');
                    },
                    onNavigationCancelled: () {
                      debugPrint('❌ [ROUTER] Navigation cancelled, returning to dashboard');
                      context.go('/driver/dashboard');
                    },
                  );

                  debugPrint('✅ [ROUTER] InAppNavigationScreen widget created successfully');
                  debugPrint('✅ [ROUTER] Widget type: ${navigationScreen.runtimeType}');
                  debugPrint('✅ [ROUTER] Widget key: ${navigationScreen.key}');

                  // Wrap the navigation screen in an error boundary to catch runtime exceptions
                  return _NavigationScreenErrorBoundary(
                    child: navigationScreen,
                    onError: (error, stackTrace) {
                      debugPrint('❌ [ROUTER] Runtime error in InAppNavigationScreen: $error');
                      debugPrint('❌ [ROUTER] Runtime stack trace: $stackTrace');
                      return _buildFallbackNavigationScreen(context, navState.currentSession!);
                    },
                  );
                } catch (widgetError, widgetStackTrace) {
                  debugPrint('❌ [ROUTER] CRITICAL ERROR creating InAppNavigationScreen widget: $widgetError');
                  debugPrint('❌ [ROUTER] Widget error type: ${widgetError.runtimeType}');
                  debugPrint('❌ [ROUTER] Widget stack trace: $widgetStackTrace');

                  // Return fallback screen instead of throwing
                  return _buildFallbackNavigationScreen(context, navState.currentSession!);
                }
              } catch (e, stackTrace) {
                debugPrint('❌ [ROUTER] Error in navigation route builder: $e');
                debugPrint('❌ [ROUTER] Stack trace: $stackTrace');

                // Try to get navigation state for fallback
                try {
                  final navState = ref.read(enhancedNavigationProvider);
                  if (navState.isNavigating && navState.currentSession != null) {
                    debugPrint('🔄 [ROUTER] Attempting fallback navigation screen...');
                    return _buildFallbackNavigationScreen(context, navState.currentSession!);
                  }
                } catch (fallbackError) {
                  debugPrint('❌ [ROUTER] Fallback navigation screen also failed: $fallbackError');
                }

                return _buildNavigationErrorScreen(context, e.toString());
              }
            },
          );
        },
        ),
      ],
    ),

    // Multi-Order Driver Dashboard
    GoRoute(
      path: AppRoutes.driverMultiOrderDashboard,
      name: 'driver-multi-order-dashboard',
      builder: (context, state) => const MultiOrderDriverDashboard(),
    ),

    // Driver Wallet Routes (Direct access like customer wallet)
    GoRoute(
      path: '/driver/wallet',
      name: 'driver-wallet-direct',
      builder: (context, state) {
        debugPrint('🔍 [ROUTER] Building DriverWalletDashboardScreen for /driver/wallet');
        return const DriverWalletDashboardScreen();
      },
      routes: [
        GoRoute(
          path: 'withdraw',
          name: 'driver-wallet-withdraw-direct',
          builder: (context, state) => const DriverWithdrawalRequestScreen(),
        ),
        GoRoute(
          path: 'withdrawals',
          name: 'driver-wallet-withdrawals-direct',
          builder: (context, state) => const DriverWithdrawalHistoryScreen(),
        ),
        GoRoute(
          path: 'withdrawal/:withdrawalId',
          name: 'driver-wallet-withdrawal-detail-direct',
          builder: (context, state) {
            final withdrawalId = state.pathParameters['withdrawalId']!;
            return DriverWithdrawalDetailScreen(withdrawalId: withdrawalId);
          },
        ),
        GoRoute(
          path: 'transactions',
          name: 'driver-wallet-transactions-direct',
          builder: (context, state) => const DriverWalletTransactionHistoryScreen(),
        ),
        GoRoute(
          path: 'verification',
          name: 'driver-wallet-verification-direct',
          builder: (context, state) => const DriverWalletVerificationScreen(),
          routes: [
            GoRoute(
              path: 'unified',
              name: 'driver-wallet-verification-unified',
              builder: (context, state) => const DriverUnifiedWalletVerificationScreen(),
            ),
            // Legacy routes - kept for backward compatibility but deprecated
            // TODO: Remove these routes in a future version after migration is complete
            GoRoute(
              path: 'bank-account',
              name: 'driver-wallet-verification-bank-account',
              builder: (context, state) {
                debugPrint('⚠️ [ROUTER] Using deprecated bank-account verification route');
                return const DriverBankAccountVerificationScreen();
              },
            ),
            GoRoute(
              path: 'documents',
              name: 'driver-wallet-verification-documents',
              builder: (context, state) {
                debugPrint('⚠️ [ROUTER] Using deprecated documents verification route');
                return const DriverWalletDocumentUploadScreen();
              },
            ),
            GoRoute(
              path: 'instant',
              name: 'driver-wallet-verification-instant',
              builder: (context, state) {
                debugPrint('⚠️ [ROUTER] Using deprecated instant verification route');
                return const DriverWalletInstantVerificationScreen();
              },
            ),
          ],
        ),
        GoRoute(
          path: 'transaction/:transactionId',
          name: 'driver-wallet-transaction-detail-direct',
          builder: (context, state) {
            final transactionId = state.pathParameters['transactionId']!;
            return DriverWalletTransactionDetailScreen(transactionId: transactionId);
          },
        ),
        GoRoute(
          path: 'settings',
          name: 'driver-wallet-settings-direct',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Driver Wallet Settings - Coming Soon')),
          ),
        ),
        GoRoute(
          path: 'support',
          name: 'driver-wallet-support-direct',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Driver Wallet Support - Coming Soon')),
          ),
        ),
        GoRoute(
          path: 'analytics',
          name: 'driver-wallet-analytics-direct',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Driver Wallet Analytics - Coming Soon')),
          ),
        ),

        GoRoute(
          path: 'security',
          name: 'driver-wallet-security-direct',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Driver Wallet Security - Coming Soon')),
          ),
        ),
        GoRoute(
          path: 'notifications',
          name: 'driver-wallet-notifications-direct',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Driver Wallet Notifications - Coming Soon')),
          ),
        ),
      ],
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
      builder: (context, state) => const EnhancedCustomerOrdersScreen(), // Enhanced: Use new enhanced customer orders screen
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
        GoRoute(
          path: 'verification',
          name: 'customer-wallet-verification',
          builder: (context, state) => const CustomerUnifiedWalletVerificationScreen(),
          routes: [
            GoRoute(
              path: 'unified',
              name: 'customer-wallet-verification-unified',
              builder: (context, state) => const CustomerUnifiedWalletVerificationScreen(),
            ),
            // Legacy routes - kept for backward compatibility but deprecated
            // TODO: Remove these routes in a future version after migration is complete
            GoRoute(
              path: 'documents',
              name: 'customer-wallet-verification-documents',
              builder: (context, state) {
                debugPrint('⚠️ [ROUTER] Using deprecated documents verification route');
                return const CustomerWalletDocumentUploadScreen();
              },
            ),
            GoRoute(
              path: 'instant',
              name: 'customer-wallet-verification-instant',
              builder: (context, state) {
                debugPrint('⚠️ [ROUTER] Using deprecated instant verification route');
                return const CustomerWalletInstantVerificationScreen();
              },
            ),
          ],
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

/// Build fallback navigation screen when InAppNavigationScreen fails
Widget _buildFallbackNavigationScreen(BuildContext context, dynamic session) {
  return Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: const Text('Navigation'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          debugPrint('🔄 [ROUTER] Returning to dashboard from fallback navigation screen');
          context.go('/driver/dashboard');
        },
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.navigation,
              size: 64,
              color: Colors.blue.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Navigation Active',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Enhanced In-App Navigation is running in the background.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Session ID: ${session.id ?? 'Unknown'}',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    debugPrint('🗺️ [ROUTER] Opening external Google Maps');
                    // TODO: Launch external Google Maps
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Open Google Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    debugPrint('🔄 [ROUTER] Returning to dashboard from fallback screen');
                    context.go('/driver/dashboard');
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Build error screen for navigation failures
Widget _buildNavigationErrorScreen(BuildContext context, String errorMessage) {
  return Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Navigation Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to start Enhanced In-App Navigation',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      debugPrint('🔄 [ROUTER] Returning to dashboard from error screen');
                      context.go('/driver/dashboard');
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      debugPrint('🔄 [ROUTER] Retrying navigation from error screen');
                      // Try to restart navigation
                      context.go('/driver/dashboard');
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
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

/// Error boundary widget to catch runtime exceptions in InAppNavigationScreen
class _NavigationScreenErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace stackTrace) onError;

  const _NavigationScreenErrorBoundary({
    required this.child,
    required this.onError,
  });

  @override
  State<_NavigationScreenErrorBoundary> createState() => _NavigationScreenErrorBoundaryState();
}

class _NavigationScreenErrorBoundaryState extends State<_NavigationScreenErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null && _stackTrace != null) {
      debugPrint('🚨 [ERROR-BOUNDARY] Rendering error fallback for: $_error');
      return widget.onError(_error!, _stackTrace!);
    }

    try {
      return widget.child;
    } catch (error, stackTrace) {
      debugPrint('🚨 [ERROR-BOUNDARY] Caught build error: $error');
      debugPrint('🚨 [ERROR-BOUNDARY] Build stack trace: $stackTrace');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _error = error;
            _stackTrace = stackTrace;
          });
        }
      });

      return widget.onError(error, stackTrace);
    }
  }
}
