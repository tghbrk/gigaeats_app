class SupabaseConfig {
  // Production environment
  static const String prodUrl = 'https://your-prod-project.supabase.co';
  static const String prodAnonKey = 'your-prod-anon-key';
  static const String prodServiceKey = 'your-prod-service-key'; // For server operations

  // Development environment (Local Supabase for Phase 1 testing)
  // Use 10.0.2.2 for Android emulator to access host machine's localhost
  static const String devUrl = 'http://10.0.2.2:54321';
  static const String devAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';
  static const String devServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';

  // Cloud Supabase (for production later)
  // static const String devUrl = 'https://abknoalhfltlhhdbclpv.supabase.co';
  // static const String devAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNDIxOTEsImV4cCI6MjA2MzkxODE5MX0.NAThyz5_xSTkWX7pynS7APPFZUnOc8DyjMN2K-cTt-g';
  // static const String devServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODM0MjE5MSwiZXhwIjoyMDYzOTE4MTkxfQ.c9U38XFDf8f4ngCNDp2XlSOLSlIaPI-Utg1GgaHwmSY';

  // Current environment settings
  static String get url => const bool.fromEnvironment('dart.vm.product')
      ? prodUrl : devUrl;
  static String get anonKey => const bool.fromEnvironment('dart.vm.product')
      ? prodAnonKey : devAnonKey;
  static String get serviceKey => const bool.fromEnvironment('dart.vm.product')
      ? prodServiceKey : devServiceKey;

  // Database configuration
  static const String schema = 'public';
  static const Duration timeout = Duration(seconds: 30);
  
  // Storage bucket names
  static const String profileImagesBucket = 'profile-images';
  static const String vendorImagesBucket = 'vendor-images';
  static const String menuImagesBucket = 'menu-images';
  static const String kycDocumentsBucket = 'kyc-documents';
  static const String orderDocumentsBucket = 'order-documents';
}
