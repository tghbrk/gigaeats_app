# GigaEats Authentication Troubleshooting Guide

## 🔧 Overview

This comprehensive troubleshooting guide provides solutions for common authentication issues, debugging procedures, and resolution strategies for the GigaEats authentication system.

## 🚨 Common Authentication Issues

### **Issue 1: Login Failures**

**Symptoms:**
- User cannot log in with valid credentials
- "Invalid credentials" error message
- Authentication timeout errors

**Possible Causes:**
1. Email not verified
2. Incorrect password
3. Account disabled/suspended
4. Network connectivity issues
5. Supabase service issues

**Debugging Steps:**
```dart
// Enable debug logging
debugPrint('🔍 Login attempt for email: $email');
debugPrint('🔍 Auth response: ${response.toString()}');

// Check email verification status
final user = response.user;
if (user?.emailConfirmedAt == null) {
  debugPrint('❌ Email not verified for user: ${user?.email}');
}
```

**Solutions:**
1. **Email Verification Required:**
   ```dart
   // Redirect to email verification
   if (user?.emailConfirmedAt == null) {
     context.go('/email-verification?email=${Uri.encodeComponent(email)}');
   }
   ```

2. **Password Reset:**
   ```dart
   // Trigger password reset
   await supabase.auth.resetPasswordForEmail(email);
   ```

3. **Network Issues:**
   ```dart
   // Check connectivity
   final connectivity = await Connectivity().checkConnectivity();
   if (connectivity == ConnectivityResult.none) {
     showErrorDialog('No internet connection');
   }
   ```

### **Issue 2: Email Verification Problems**

**Symptoms:**
- Verification emails not received
- Verification links not working
- "Token expired" errors

**Possible Causes:**
1. Email in spam folder
2. Incorrect email configuration
3. Expired verification tokens
4. Deep link handling issues

**Debugging Steps:**
```dart
// Check email verification status
debugPrint('🔍 Email verification status: ${user?.emailConfirmedAt}');
debugPrint('🔍 User created at: ${user?.createdAt}');

// Verify deep link handling
void handleDeepLink(Uri uri) {
  debugPrint('🔍 Deep link received: ${uri.toString()}');
  debugPrint('🔍 Query parameters: ${uri.queryParameters}');
}
```

**Solutions:**
1. **Resend Verification Email:**
   ```dart
   await supabase.auth.resend(
     type: OtpType.signup,
     email: email,
   );
   ```

2. **Check Email Configuration:**
   ```typescript
   // Supabase dashboard settings
   {
     "SITE_URL": "https://gigaeats.app",
     "REDIRECT_URLS": ["gigaeats://auth/callback"],
     "EMAIL_CONFIRM_REDIRECT_TO": "gigaeats://auth/callback"
   }
   ```

3. **Manual Verification (Admin):**
   ```sql
   -- Admin can manually verify email
   UPDATE auth.users 
   SET email_confirmed_at = NOW() 
   WHERE email = 'user@example.com';
   ```

### **Issue 3: Role-Based Access Denied**

**Symptoms:**
- User redirected from protected routes
- "Access denied" messages
- Incorrect dashboard routing

**Possible Causes:**
1. Insufficient permissions
2. Role not properly assigned
3. Access control misconfiguration
4. Cache issues with permissions

**Debugging Steps:**
```dart
// Debug access control
final accessResult = AccessControlService.checkRouteAccess(route, userRole);
debugPrint('🔍 Route: $route');
debugPrint('🔍 User role: ${userRole?.displayName}');
debugPrint('🔍 Access result: ${accessResult.hasAccess}');
debugPrint('🔍 Reason: ${accessResult.reason}');
debugPrint('🔍 Required permissions: ${accessResult.requiredPermissions}');
debugPrint('🔍 User permissions: ${accessResult.userPermissions}');
```

**Solutions:**
1. **Check User Role:**
   ```sql
   -- Verify user role in database
   SELECT up.role, up.user_id, au.email 
   FROM user_profiles up 
   JOIN auth.users au ON up.user_id = au.id 
   WHERE au.email = 'user@example.com';
   ```

2. **Update User Role:**
   ```sql
   -- Update user role (admin only)
   UPDATE user_profiles 
   SET role = 'vendor'::user_role 
   WHERE user_id = 'user-uuid';
   ```

3. **Clear Permission Cache:**
   ```dart
   // Clear access control cache
   AccessControlService._accessCache.clear();
   ```

### **Issue 4: Session Management Problems**

**Symptoms:**
- User logged out unexpectedly
- Session not persisting
- "Session expired" errors

**Possible Causes:**
1. Token expiration
2. Storage issues
3. Network interruption
4. Multiple device conflicts

**Debugging Steps:**
```dart
// Debug session state
final session = supabase.auth.currentSession;
debugPrint('🔍 Current session: ${session?.accessToken}');
debugPrint('🔍 Session expires at: ${session?.expiresAt}');
debugPrint('🔍 Refresh token: ${session?.refreshToken}');

// Monitor auth state changes
supabase.auth.onAuthStateChange.listen((data) {
  debugPrint('🔍 Auth state changed: ${data.event}');
  debugPrint('🔍 Session: ${data.session?.user?.email}');
});
```

**Solutions:**
1. **Refresh Session:**
   ```dart
   try {
     await supabase.auth.refreshSession();
   } catch (e) {
     // Redirect to login
     context.go('/login');
   }
   ```

2. **Clear Storage:**
   ```dart
   // Clear secure storage
   await FlutterSecureStorage().deleteAll();
   await supabase.auth.signOut();
   ```

## 🔍 Debugging Procedures

### **Enable Debug Logging**

**1. Authentication Debug Mode:**
```dart
// lib/core/utils/debug_logger.dart
class DebugLogger {
  static void logAuth(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('🔐 AUTH: $message');
      if (error != null) {
        debugPrint('❌ ERROR: $error');
      }
    }
  }
  
  static void logNavigation(String message) {
    if (kDebugMode) {
      debugPrint('🧭 NAV: $message');
    }
  }
  
  static void logPermission(String message) {
    if (kDebugMode) {
      debugPrint('🛡️ PERM: $message');
    }
  }
}
```

**2. Supabase Debug Mode:**
```dart
// Enable Supabase debug logging
await Supabase.initialize(
  url: SupabaseConfig.url,
  anonKey: SupabaseConfig.anonKey,
  debug: kDebugMode, // Enable debug mode
);
```

### **Network Debugging**

**1. Check Supabase Connectivity:**
```dart
Future<bool> checkSupabaseConnectivity() async {
  try {
    final response = await supabase.from('user_profiles').select('id').limit(1);
    return response.isNotEmpty || response.isEmpty; // Both are valid
  } catch (e) {
    debugPrint('❌ Supabase connectivity failed: $e');
    return false;
  }
}
```

**2. Monitor Network Requests:**
```dart
// Add HTTP interceptor for debugging
class DebugInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('🌐 REQUEST: ${options.method} ${options.uri}');
    super.onRequest(options, handler);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
    super.onResponse(response, handler);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('❌ ERROR: ${err.response?.statusCode} ${err.requestOptions.uri}');
    super.onError(err, handler);
  }
}
```

## 🛠️ Advanced Troubleshooting

### **Database Issues**

**1. Check RLS Policies:**
```sql
-- Verify RLS policies are active
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND rowsecurity = true;

-- Test RLS policy for user
SET ROLE authenticated;
SET request.jwt.claims TO '{"sub": "user-uuid", "role": "authenticated"}';
SELECT * FROM user_profiles WHERE user_id = 'user-uuid';
```

**2. Check Triggers:**
```sql
-- Verify authentication triggers
SELECT trigger_name, event_manipulation, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public';

-- Test trigger manually
INSERT INTO auth.users (id, email) VALUES ('test-uuid', 'test@example.com');
SELECT * FROM user_profiles WHERE user_id = 'test-uuid';
```

### **Performance Issues**

**1. Authentication Performance:**
```dart
// Measure authentication performance
final stopwatch = Stopwatch()..start();
try {
  final response = await supabase.auth.signInWithPassword(
    email: email,
    password: password,
  );
  stopwatch.stop();
  debugPrint('🚀 Login took: ${stopwatch.elapsedMilliseconds}ms');
} catch (e) {
  stopwatch.stop();
  debugPrint('❌ Login failed after: ${stopwatch.elapsedMilliseconds}ms');
}
```

**2. Route Access Performance:**
```dart
// Measure access control performance
final stopwatch = Stopwatch()..start();
final accessResult = AccessControlService.checkRouteAccess(route, userRole);
stopwatch.stop();
debugPrint('🛡️ Access check took: ${stopwatch.elapsedMilliseconds}ms');
```

## 📊 Monitoring & Alerts

### **Health Check Implementation**

**1. Authentication Health Check:**
```dart
class AuthHealthCheck {
  static Future<HealthStatus> checkAuthenticationHealth() async {
    final checks = <String, bool>{};
    
    // Check Supabase connectivity
    checks['supabase_connectivity'] = await _checkSupabaseConnectivity();
    
    // Check authentication service
    checks['auth_service'] = await _checkAuthService();
    
    // Check database access
    checks['database_access'] = await _checkDatabaseAccess();
    
    final allHealthy = checks.values.every((check) => check);
    
    return HealthStatus(
      isHealthy: allHealthy,
      checks: checks,
      timestamp: DateTime.now(),
    );
  }
}
```

**2. Error Rate Monitoring:**
```dart
class ErrorRateMonitor {
  static int _totalAttempts = 0;
  static int _failedAttempts = 0;
  
  static void recordAuthAttempt(bool success) {
    _totalAttempts++;
    if (!success) _failedAttempts++;
    
    final errorRate = _failedAttempts / _totalAttempts;
    if (errorRate > 0.1) { // 10% error rate threshold
      _sendAlert('High authentication error rate: ${(errorRate * 100).toStringAsFixed(1)}%');
    }
  }
}
```

## 🔧 Quick Fixes

### **Common Quick Fixes**

**1. Clear App Data:**
```bash
# Android
adb shell pm clear com.gigaeats.gigaeats_app

# iOS
# Delete and reinstall app
```

**2. Reset Authentication State:**
```dart
// Reset all authentication state
await supabase.auth.signOut();
await FlutterSecureStorage().deleteAll();
ref.invalidate(authStateProvider);
ref.invalidate(enhancedAuthStateProvider);
```

**3. Force Email Verification:**
```sql
-- Admin can force email verification
UPDATE auth.users 
SET email_confirmed_at = NOW() 
WHERE email = 'user@example.com';
```

**4. Reset User Role:**
```sql
-- Reset user role to customer
UPDATE user_profiles 
SET role = 'customer'::user_role 
WHERE user_id = 'user-uuid';
```

## 📞 Support Escalation

### **When to Escalate**

**Level 1 - Development Team:**
- Basic authentication issues
- UI/UX problems
- Configuration issues

**Level 2 - Technical Lead:**
- Complex permission issues
- Database-related problems
- Integration failures

**Level 3 - Emergency Response:**
- System-wide authentication failures
- Security breaches
- Data corruption issues

### **Escalation Information**

**Include in Escalation:**
1. **User Information**: Email, role, user ID
2. **Error Details**: Full error messages and stack traces
3. **Reproduction Steps**: Exact steps to reproduce the issue
4. **Environment**: Device, OS version, app version
5. **Logs**: Relevant debug logs and timestamps
6. **Impact**: Number of affected users and business impact

## 🎯 Prevention Strategies

### **Proactive Monitoring**
1. **Set up authentication metrics** monitoring
2. **Implement automated health checks**
3. **Monitor error rates and response times**
4. **Set up alerting for critical issues**
5. **Regular security audits and testing**

### **User Education**
1. **Provide clear error messages** with next steps
2. **Create user guides** for common scenarios
3. **Implement in-app help** and support
4. **Offer multiple contact channels** for support
5. **Maintain FAQ** with common solutions

## 🎉 Troubleshooting Summary

This troubleshooting guide provides comprehensive solutions for authentication issues in the GigaEats application. Regular monitoring, proactive debugging, and clear escalation procedures ensure quick resolution of authentication problems and maintain excellent user experience.
