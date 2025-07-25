import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'GigaEats';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'B2B2C Bulk Food Ordering Platform for Malaysia';

  // Colors
  static const Color primaryColor = Color(0xFF4CAF50);

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
  static const String keySettings = 'app_settings';

  // Supported Languages
  static const List<String> supportedLanguages = ['en', 'ms', 'zh'];
  static const String defaultLanguage = 'en';

  // Delivery Configuration
  static const double minOrderAmount = 20.0; // RM 20 minimum order
  static const double maxOrderAmount = 5000.0; // RM 5000 maximum order
  static const double freeDeliveryThreshold = 200.0; // RM 200 for free delivery
  static const double standardDeliveryFee = 15.0; // RM 15 standard delivery

  // Cart and Pricing Configuration
  static const double significantPriceChangeThreshold = 10.0; // RM 10 threshold for price change warnings
  static const double minSavingsThreshold = 5.0; // RM 5 minimum savings to show recommendations

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Error Messages
  static const String networkErrorMessage = 'Network connection failed. Please check your internet connection.';
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String authErrorMessage = 'Authentication failed. Please sign in again.';
  static const String validationErrorMessage = 'Please check your input and try again.';

  // Success Messages
  static const String orderPlacedMessage = 'Order placed successfully!';
  static const String orderUpdatedMessage = 'Order updated successfully!';
  static const String profileUpdatedMessage = 'Profile updated successfully!';
  static const String passwordChangedMessage = 'Password changed successfully!';

  // Feature Flags
  static const bool enableNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enableDebugMode = true;

  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 100;

  // Notification Configuration
  static const Duration notificationDisplayDuration = Duration(seconds: 4);
  static const int maxNotifications = 50;

  // Search Configuration
  static const Duration searchDebounceDelay = Duration(milliseconds: 500);
  static const int minSearchLength = 2;
  static const int maxSearchResults = 50;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;

  // Performance Configuration
  static const Duration debounceDelay = Duration(milliseconds: 300);
  static const int maxConcurrentRequests = 5;

  // Business Hours
  static const int businessStartHour = 8; // 8 AM
  static const int businessEndHour = 22; // 10 PM

  // Phone Validation
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;

  // Cuisine Types
  static const List<String> availableCuisineTypes = [
    'Malaysian',
    'Chinese',
    'Indian',
    'Western',
    'Japanese',
    'Korean',
    'Thai',
    'Italian',
    'Middle Eastern',
    'Fusion',
    'Vegetarian',
    'Halal',
    'Other',
  ];

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
  static const String salesAgentCart = '/sales-agent/cart';
  static const String salesAgentCreateOrder = '/sales-agent/create-order';

  // Vendor Routes
  static const String vendorDashboard = '/vendor/dashboard';
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

  // Driver Routes
  static const String driverDashboard = '/driver/dashboard';
  static const String driverOrders = '/driver/dashboard/orders';

  // Customer Routes (Phase 5: Role-based Routing)
  static const String customerDashboard = '/customer/dashboard';
  static const String customerOrders = '/customer/orders';
  static const String customerWallet = '/customer/wallet';
  static const String customerLoyalty = '/customer/loyalty';
  static const String customerProfile = '/customer/profile';

  // Enhanced Authentication Routes (Phase 4 & 5)
  static const String signupRoleSelection = '/signup-role-selection';
  static const String roleSignup = '/signup/:role';
  static const String emailVerification = '/email-verification';
  static const String authCallback = '/auth/callback';

  // Shared Routes
  static const String orderDetails = '/order-details/:orderId';
  static const String vendorDetails = '/vendor-details/:vendorId';
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
