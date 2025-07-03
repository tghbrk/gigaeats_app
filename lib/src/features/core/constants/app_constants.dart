import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'GigaEats';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'B2B2C Bulk Food Ordering Platform for Malaysia';

  // Colors
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color secondaryColor = Color(0xFF2196F3);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color infoColor = Color(0xFF2196F3);

  // API Configuration
  static const String baseUrl = 'https://api.gigaeats.com';
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // User Roles
  static const String roleSalesAgent = 'sales_agent';
  static const String roleVendor = 'vendor';
  static const String roleAdmin = 'admin';
  static const String roleCustomer = 'customer';
  static const String roleDriver = 'driver';

  // Order Status
  static const String orderStatusPending = 'pending';
  static const String orderStatusConfirmed = 'confirmed';
  static const String orderStatusPreparing = 'preparing';
  static const String orderStatusReady = 'ready';
  static const String orderStatusOutForDelivery = 'out_for_delivery';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCancelled = 'cancelled';

  // Delivery Methods
  static const String deliveryMethodCustomerPickup = 'customer_pickup';
  static const String deliveryMethodSalesAgentPickup = 'sales_agent_pickup';
  static const String deliveryMethodOwnFleet = 'own_fleet';

  // Payment Methods
  static const String paymentMethodCash = 'cash';
  static const String paymentMethodCard = 'card';
  static const String paymentMethodWallet = 'wallet';
  static const String paymentMethodBankTransfer = 'bank_transfer';

  // Malaysian Business Constants
  static const double sstRate = 0.06; // 6% SST
  static const String malaysianPhonePrefix = '+60';
  static const String malaysianCurrency = 'RM';

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
  static const double minOrderAmount = 20.0; // RM 20 minimum order
  static const double freeDeliveryThreshold = 200.0; // RM 200 for free delivery
  static const double standardDeliveryFee = 15.0; // RM 15 standard delivery
  static const double expressDeliveryFee = 25.0; // RM 25 express delivery
  static const int standardDeliveryTimeMinutes = 60; // 1 hour
  static const int expressDeliveryTimeMinutes = 30; // 30 minutes

  // Commission Rates
  static const double platformCommissionRate = 0.15; // 15% platform commission
  static const double salesAgentCommissionRate = 0.05; // 5% sales agent commission
  static const double driverCommissionRate = 0.10; // 10% driver commission

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 50;
  static const int maxDescriptionLength = 500;
  static const int maxAddressLength = 200;

  // Business Hours
  static const int businessHoursStart = 6; // 6 AM
  static const int businessHoursEnd = 23; // 11 PM
  static const List<int> businessDays = [1, 2, 3, 4, 5, 6, 7]; // Monday to Sunday

  // Notification Types
  static const String notificationTypeOrderUpdate = 'order_update';
  static const String notificationTypePayment = 'payment';
  static const String notificationTypePromotion = 'promotion';
  static const String notificationTypeSystem = 'system';

  // Error Messages
  static const String errorNetworkConnection = 'Network connection error. Please check your internet connection.';
  static const String errorServerError = 'Server error. Please try again later.';
  static const String errorUnauthorized = 'Unauthorized access. Please login again.';
  static const String errorInvalidCredentials = 'Invalid email or password.';
  static const String errorEmailNotVerified = 'Please verify your email address before logging in.';

  // Success Messages
  static const String successOrderCreated = 'Order created successfully!';
  static const String successOrderUpdated = 'Order updated successfully!';
  static const String successProfileUpdated = 'Profile updated successfully!';
  static const String successPasswordChanged = 'Password changed successfully!';

  // Loading Messages
  static const String loadingSigningIn = 'Signing in...';
  static const String loadingCreatingOrder = 'Creating order...';
  static const String loadingUpdatingProfile = 'Updating profile...';
  static const String loadingProcessingPayment = 'Processing payment...';

  // Feature Flags
  static const bool enableRealtimeUpdates = true;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePerformanceMonitoring = true;

  // Debug Settings
  static const bool enableDebugLogging = true;
  static const bool enableNetworkLogging = true;
  static const bool enablePerformanceLogging = true;
}
