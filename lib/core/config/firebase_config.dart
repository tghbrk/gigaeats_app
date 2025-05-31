class FirebaseConfig {
  // Firebase configuration for authentication
  static const String prodProjectId = 'gigaeats-app';
  static const String devProjectId = 'gigaeats-app';

  static String get projectId => const bool.fromEnvironment('dart.vm.product')
      ? prodProjectId : devProjectId;

  // Firebase Functions configuration
  static const String functionsRegion = 'asia-southeast1'; // Singapore region for Malaysia
  
  // Custom claims for user roles
  static const String roleClaimKey = 'role';
  static const String verifiedClaimKey = 'verified';
  static const String activeClaimKey = 'active';
  
  // Phone verification configuration
  static const String malaysianPhonePrefix = '+60';
  static const Duration phoneVerificationTimeout = Duration(seconds: 60);
  
  // Firebase Cloud Messaging configuration
  static const String fcmVapidKey = 'your-vapid-key'; // For web push notifications
}
