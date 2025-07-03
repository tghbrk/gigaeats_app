// Enhanced Authentication Configuration for GigaEats
// Phase 3: Backend Configuration
// Purpose: Centralized authentication configuration with enhanced settings

class AuthConfig {
  // =====================================================
  // Authentication Settings
  // =====================================================
  
  /// Site URL for authentication callbacks
  static const String siteUrl = 'gigaeats://auth/callback';
  
  /// JWT token expiry (1 hour)
  static const int jwtExpiry = 3600;
  
  /// Refresh token expiry (7 days)
  static const int refreshTokenExpiry = 604800;
  
  /// Password minimum length
  static const int passwordMinLength = 8;
  
  /// OTP expiry time (1 hour)
  static const int otpExpiry = 3600;
  
  /// Maximum frequency for sending emails (1 second)
  static const String maxFrequency = '1s';
  
  // =====================================================
  // Deep Link Configuration
  // =====================================================
  
  /// Primary deep link scheme
  static const String deepLinkScheme = 'gigaeats';
  
  /// Authentication callback path
  static const String authCallbackPath = '/auth/callback';
  
  /// Email verification path
  static const String emailVerificationPath = '/auth/verify-email';
  
  /// Password reset path
  static const String passwordResetPath = '/auth/reset-password';
  
  /// Magic link path
  static const String magicLinkPath = '/auth/magic-link';
  
  /// Complete deep link URLs
  static const String authCallbackUrl = '$deepLinkScheme://auth/callback';
  static const String emailVerificationUrl = '$deepLinkScheme://auth/verify-email';
  static const String passwordResetUrl = '$deepLinkScheme://auth/reset-password';
  static const String magicLinkUrl = '$deepLinkScheme://auth/magic-link';
  
  /// Allowed redirect URLs for Supabase
  static const List<String> allowedRedirectUrls = [
    'gigaeats://auth/callback',
    'gigaeats://auth/verify-email',
    'gigaeats://auth/reset-password',
    'gigaeats://auth/magic-link',
    'https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/callback',
    'http://localhost:3000/auth/callback',
    'https://localhost:3000/auth/callback',
    'https://gigaeats.app/auth/callback',
  ];
  
  // =====================================================
  // Email Template Configuration
  // =====================================================
  
  /// Email template subjects
  static const Map<String, String> emailSubjects = {
    'confirmation': 'Welcome to GigaEats - Verify Your Email',
    'recovery': 'Reset Your GigaEats Password',
    'magic_link': 'Your GigaEats Magic Link',
    'invite': 'You\'ve been invited to GigaEats',
  };
  
  /// Email template paths
  static const Map<String, String> emailTemplatePaths = {
    'confirmation': './supabase/templates/confirmation.html',
    'recovery': './supabase/templates/recovery.html',
    'magic_link': './supabase/templates/magic_link.html',
    'invite': './supabase/templates/invite.html',
  };
  
  // =====================================================
  // Authentication Flow Configuration
  // =====================================================
  
  /// Enable user signup
  static const bool enableSignup = true;
  
  /// Require email confirmation before login
  static const bool enableConfirmations = true;
  
  /// Require confirmation for email changes
  static const bool doubleConfirmChanges = true;
  
  /// Require recent authentication for password changes
  static const bool securePasswordChange = false;
  
  /// Enable SMS authentication
  static const bool enableSmsAuth = true;
  
  /// Enable magic link authentication
  static const bool enableMagicLink = true;
  
  // =====================================================
  // Security Configuration
  // =====================================================
  
  /// Maximum failed login attempts before account lockout
  static const int maxFailedLoginAttempts = 5;
  
  /// Account lockout duration (15 minutes)
  static const Duration accountLockoutDuration = Duration(minutes: 15);
  
  /// Session timeout duration (24 hours)
  static const Duration sessionTimeout = Duration(hours: 24);
  
  /// Password strength requirements
  static const Map<String, dynamic> passwordRequirements = {
    'minLength': 8,
    'requireUppercase': true,
    'requireLowercase': true,
    'requireNumbers': true,
    'requireSpecialChars': false,
  };
  
  /// Password validation regex
  static const String passwordValidationRegex = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$';
  
  // =====================================================
  // Role-based Configuration
  // =====================================================
  
  /// Default role for new users
  static const String defaultRole = 'customer';
  
  /// Available user roles
  static const List<String> availableRoles = [
    'customer',
    'vendor',
    'driver',
    'sales_agent',
    'admin',
  ];
  
  /// Role-specific redirect URLs after authentication
  static const Map<String, String> roleRedirectUrls = {
    'customer': '/customer/dashboard',
    'vendor': '/vendor/dashboard',
    'driver': '/driver/dashboard',
    'sales_agent': '/sales-agent/dashboard',
    'admin': '/admin/dashboard',
  };
  
  /// Roles that require phone verification
  static const List<String> phoneVerificationRequiredRoles = [
    'driver',
    'sales_agent',
    'vendor',
  ];
  
  /// Roles that require additional profile information
  static const List<String> extendedProfileRequiredRoles = [
    'vendor',
    'sales_agent',
    'driver',
  ];
  
  // =====================================================
  // Development Configuration
  // =====================================================
  
  /// Enable debug mode for authentication
  static const bool debugMode = true;
  
  /// Test email domains (for development)
  static const List<String> testEmailDomains = [
    'test.com',
    'example.com',
    'gigaeats.test',
  ];
  
  /// Development redirect URLs
  static const List<String> devRedirectUrls = [
    'http://localhost:3000/auth/callback',
    'https://localhost:3000/auth/callback',
    'http://127.0.0.1:3000/auth/callback',
  ];
  
  // =====================================================
  // Utility Methods
  // =====================================================
  
  /// Get redirect URL for a specific role
  static String getRedirectUrlForRole(String role) {
    return roleRedirectUrls[role] ?? roleRedirectUrls[defaultRole]!;
  }
  
  /// Check if role requires phone verification
  static bool requiresPhoneVerification(String role) {
    return phoneVerificationRequiredRoles.contains(role);
  }
  
  /// Check if role requires extended profile
  static bool requiresExtendedProfile(String role) {
    return extendedProfileRequiredRoles.contains(role);
  }
  
  /// Validate password strength
  static bool isPasswordValid(String password) {
    return RegExp(passwordValidationRegex).hasMatch(password);
  }
  
  /// Get email subject for template type
  static String getEmailSubject(String templateType) {
    return emailSubjects[templateType] ?? 'GigaEats Notification';
  }
  
  /// Get email template path for template type
  static String getEmailTemplatePath(String templateType) {
    return emailTemplatePaths[templateType] ?? '';
  }
  
  /// Check if email domain is for testing
  static bool isTestEmailDomain(String email) {
    final domain = email.split('@').last.toLowerCase();
    return testEmailDomains.contains(domain);
  }
  
  /// Get complete deep link URL for a specific path
  static String getDeepLinkUrl(String path) {
    return '$deepLinkScheme://$path';
  }
  
  /// Parse deep link and extract parameters
  static Map<String, String> parseDeepLink(String url) {
    final uri = Uri.parse(url);
    return {
      'scheme': uri.scheme,
      'host': uri.host,
      'path': uri.path,
      'query': uri.query,
      ...uri.queryParameters,
    };
  }
  
  // =====================================================
  // Configuration Validation
  // =====================================================
  
  /// Validate authentication configuration
  static bool validateConfiguration() {
    // Check required configurations
    if (siteUrl.isEmpty) return false;
    if (jwtExpiry <= 0) return false;
    if (refreshTokenExpiry <= 0) return false;
    if (passwordMinLength < 6) return false;
    if (allowedRedirectUrls.isEmpty) return false;
    if (availableRoles.isEmpty) return false;
    
    return true;
  }
  
  /// Get configuration summary
  static Map<String, dynamic> getConfigurationSummary() {
    return {
      'site_url': siteUrl,
      'jwt_expiry': jwtExpiry,
      'refresh_token_expiry': refreshTokenExpiry,
      'password_min_length': passwordMinLength,
      'enable_signup': enableSignup,
      'enable_confirmations': enableConfirmations,
      'available_roles': availableRoles,
      'redirect_urls_count': allowedRedirectUrls.length,
      'email_templates_count': emailSubjects.length,
      'debug_mode': debugMode,
      'configuration_valid': validateConfiguration(),
    };
  }
}
