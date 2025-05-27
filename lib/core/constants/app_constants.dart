class AppConstants {
  // App Information
  static const String appName = 'GigaEats';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'B2B2C Bulk Food Ordering Platform for Malaysia';

  // API Configuration
  static const String baseUrl = 'https://api.gigaeats.com';
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // User Roles
  static const String roleSalesAgent = 'sales_agent';
  static const String roleVendor = 'vendor';
  static const String roleAdmin = 'admin';
  static const String roleCustomer = 'customer';

  // Order Status
  static const String orderStatusPending = 'pending';
  static const String orderStatusConfirmed = 'confirmed';
  static const String orderStatusPreparing = 'preparing';
  static const String orderStatusReady = 'ready';
  static const String orderStatusOutForDelivery = 'out_for_delivery';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCancelled = 'cancelled';

  // Payment Methods
  static const String paymentFPX = 'fpx';
  static const String paymentGrabPay = 'grabpay';
  static const String paymentTouchNGo = 'touchngo';
  static const String paymentCreditCard = 'credit_card';

  // Commission Rate
  static const double defaultCommissionRate = 0.07; // 7%

  // Malaysian Business Constants
  static const double sstRate = 0.06; // 6% SST
  static const String malaysianPhonePrefix = '+60';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File Upload
  static const int maxImageSizeMB = 5;
  static const int maxDocumentSizeMB = 10;
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedDocumentFormats = ['pdf', 'doc', 'docx'];

  // Cache Keys
  static const String cacheKeyUserProfile = 'user_profile';
  static const String cacheKeyVendors = 'vendors';
  static const String cacheKeyOrders = 'orders';
  static const String cacheKeySettings = 'settings';

  // Shared Preferences Keys
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keySelectedLanguage = 'selected_language';
  static const String keyThemeMode = 'theme_mode';
  static const String keyUserToken = 'user_token';
  static const String keyUserRole = 'user_role';
  static const String keyUserId = 'user_id';

  // Supported Languages
  static const List<String> supportedLanguages = ['en', 'ms', 'zh'];
  static const String defaultLanguage = 'en';

  // Delivery Configuration
  static const double minOrderAmount = 50.0; // RM 50 minimum order
  static const double freeDeliveryThreshold = 200.0; // RM 200 for free delivery
  static const double standardDeliveryFee = 15.0; // RM 15 standard delivery

  // Business Hours
  static const int businessStartHour = 8; // 8 AM
  static const int businessEndHour = 22; // 10 PM

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;

  // Error Messages
  static const String errorNetworkConnection = 'No internet connection';
  static const String errorServerError = 'Server error occurred';
  static const String errorUnauthorized = 'Unauthorized access';
  static const String errorNotFound = 'Resource not found';
  static const String errorValidation = 'Validation error';
  static const String errorUnknown = 'Unknown error occurred';
}

class AppRoutes {
  // Authentication Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyPhone = '/verify-phone';

  // Sales Agent Routes
  static const String salesAgentDashboard = '/sales-agent';
  static const String salesAgentOrders = '/sales-agent/orders';
  static const String salesAgentVendors = '/sales-agent/vendors';
  static const String salesAgentCustomers = '/sales-agent/customers';
  static const String salesAgentProfile = '/sales-agent/profile';
  static const String salesAgentCommissions = '/sales-agent/commissions';

  // Vendor Routes
  static const String vendorDashboard = '/vendor';
  static const String vendorOrders = '/vendor/orders';
  static const String vendorMenu = '/vendor/menu';
  static const String vendorProfile = '/vendor/profile';
  static const String vendorAnalytics = '/vendor/analytics';

  // Admin Routes
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminOrders = '/admin/orders';
  static const String adminVendors = '/admin/vendors';
  static const String adminReports = '/admin/reports';

  // Shared Routes
  static const String orderDetails = '/order-details';
  static const String vendorDetails = '/vendor-details';
  static const String settings = '/settings';
  static const String help = '/help';
  static const String about = '/about';
}

class AppImages {
  static const String logo = 'assets/logos/gigaeats_logo.png';
  static const String logoWhite = 'assets/logos/gigaeats_logo_white.png';
  static const String placeholder = 'assets/images/placeholder.png';
  static const String noData = 'assets/images/no_data.png';
  static const String error = 'assets/images/error.png';
  static const String success = 'assets/images/success.png';
}

class AppIcons {
  static const String dashboard = 'assets/icons/dashboard.svg';
  static const String orders = 'assets/icons/orders.svg';
  static const String vendors = 'assets/icons/vendors.svg';
  static const String customers = 'assets/icons/customers.svg';
  static const String profile = 'assets/icons/profile.svg';
  static const String settings = 'assets/icons/settings.svg';
  static const String logout = 'assets/icons/logout.svg';
}
