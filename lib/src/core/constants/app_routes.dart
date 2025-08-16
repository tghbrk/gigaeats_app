/// Route constants for the GigaEats application
/// 
/// This class contains all the route paths used throughout the application
/// for consistent navigation and routing.
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();

  // Authentication Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String phoneVerification = '/phone-verification';
  static const String signupRoleSelection = '/signup-role-selection';

  // Customer Routes
  static const String customerDashboard = '/customer/dashboard';
  static const String customerRestaurants = '/customer/restaurants';
  static const String customerCart = '/customer/cart';
  static const String customerCheckout = '/customer/checkout';
  static const String customerOrders = '/customer/orders';
  static const String customerProfile = '/customer/profile';
  static const String customerSettings = '/customer/settings';
  static const String customerWallet = '/customer/wallet';
  static const String customerAddresses = '/customer/addresses';

  // Vendor Routes
  static const String vendorDashboard = '/vendor/dashboard';
  static const String vendorOrders = '/vendor/orders';
  static const String vendorMenu = '/vendor/menu';
  static const String vendorProfile = '/vendor/profile';
  static const String vendorAnalytics = '/vendor/analytics';
  static const String vendorSettings = '/vendor/settings';
  static const String vendorWallet = '/vendor/wallet';

  // Sales Agent Routes
  static const String salesAgentDashboard = '/sales-agent/dashboard';
  static const String salesAgentOrders = '/sales-agent/orders';
  static const String salesAgentCustomers = '/sales-agent/customers';
  static const String salesAgentVendors = '/sales-agent/vendors';
  static const String salesAgentCommission = '/sales-agent/commission';
  static const String salesAgentProfile = '/sales-agent/profile';
  static const String salesAgentSettings = '/sales-agent/settings';

  // Driver Routes
  static const String driverDashboard = '/driver/dashboard';
  static const String driverMultiOrderDashboard = '/driver/multi-order-dashboard';
  static const String driverOrders = '/driver/orders';
  static const String driverProfile = '/driver/profile';
  static const String driverEarnings = '/driver/earnings';
  static const String driverSettings = '/driver/settings';
  static const String driverWallet = '/driver/wallet';
  static const String driverWalletVerificationUnified = '/driver/wallet/verification/unified';

  // Admin Routes
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminOrders = '/admin/orders';
  static const String adminVendors = '/admin/vendors';
  static const String adminReports = '/admin/reports';
  static const String adminSettings = '/admin/settings';

  // Shared Routes
  static const String orderDetails = '/order/:orderId';
  static const String vendorDetails = '/vendor/:vendorId';
  static const String settings = '/settings';
  static const String help = '/help';
  static const String about = '/about';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String support = '/support';

  // Payment Routes
  static const String payment = '/payment/:orderId';
  static const String paymentSuccess = '/payment/success';
  static const String paymentFailed = '/payment/failed';

  // Test Routes (Debug only)
  static const String testData = '/test-data';
  static const String testMenu = '/test-menu';
  static const String testOrderCreation = '/test-order-creation';
  static const String testCustomerSelector = '/test-customer-selector';
  static const String testCustomerInfiniteLoop = '/test-customer-infinite-loop';
  static const String testEnhancedFeatures = '/test-enhanced-features';

  // Helper methods for dynamic routes
  static String getOrderDetailsRoute(String orderId) => '/order/$orderId';
  static String getVendorDetailsRoute(String vendorId) => '/vendor/$vendorId';
  static String getPaymentRoute(String orderId) => '/payment/$orderId';
  static String getRoleSignupRoute(String role) => '/signup/$role';
  static String getCustomerDetailsRoute(String customerId) => '/sales-agent/customers/$customerId';
  static String getEditCustomerRoute(String customerId) => '/sales-agent/customers/$customerId/edit';

  // Route validation helpers
  static bool isPublicRoute(String route) {
    const publicRoutes = [
      splash,
      login,
      register,
      forgotPassword,
      emailVerification,
      phoneVerification,
      signupRoleSelection,
    ];
    return publicRoutes.contains(route) || route.startsWith('/signup/') || route.startsWith('/email-verification');
  }

  static bool isAuthenticatedRoute(String route) {
    return !isPublicRoute(route) && !route.startsWith('/test');
  }

  static bool isTestRoute(String route) {
    return route.startsWith('/test');
  }

  // Role-based route helpers
  static List<String> getCustomerRoutes() {
    return [
      customerDashboard,
      customerRestaurants,
      customerCart,
      customerCheckout,
      customerOrders,
      customerProfile,
      customerSettings,
      customerWallet,
      customerAddresses,
    ];
  }

  static List<String> getVendorRoutes() {
    return [
      vendorDashboard,
      vendorOrders,
      vendorMenu,
      vendorProfile,
      vendorAnalytics,
      vendorSettings,
      vendorWallet,
    ];
  }

  static List<String> getSalesAgentRoutes() {
    return [
      salesAgentDashboard,
      salesAgentOrders,
      salesAgentCustomers,
      salesAgentVendors,
      salesAgentCommission,
      salesAgentProfile,
      salesAgentSettings,
    ];
  }

  static List<String> getDriverRoutes() {
    return [
      driverDashboard,
      driverMultiOrderDashboard,
      driverOrders,
      driverProfile,
      driverEarnings,
      driverSettings,
      driverWallet,
    ];
  }

  static List<String> getAdminRoutes() {
    return [
      adminDashboard,
      adminUsers,
      adminOrders,
      adminVendors,
      adminReports,
      adminSettings,
    ];
  }

  static List<String> getSharedRoutes() {
    return [
      settings,
      help,
      about,
      privacyPolicy,
      termsOfService,
      support,
    ];
  }
}
