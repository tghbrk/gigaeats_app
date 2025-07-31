# 🔧 Production Environment Configuration Guide

## 🎯 Overview

This guide provides comprehensive configuration instructions for setting up the production environment for the GigaEats Multi-Order Route Optimization System, including environment variables, API keys, security configurations, and service integrations.

## 🔐 Environment Variables Configuration

### **Core Supabase Configuration**
```bash
# Supabase Production Settings
SUPABASE_URL=https://abknoalhfltlhhdbclpv.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNDIxOTEsImV4cCI6MjA2MzkxODE5MX0.NAThyz5_xSTkWX7pynS7APPFZUnOc8DyjMN2K-cTt-g
SUPABASE_SERVICE_ROLE_KEY=[PRODUCTION_SERVICE_ROLE_KEY]
SUPABASE_PROJECT_REF=abknoalhfltlhhdbclpv

# Database Configuration
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.abknoalhfltlhhdbclpv.supabase.co:5432/postgres
DATABASE_DIRECT_URL=postgresql://postgres:[PASSWORD]@db.abknoalhfltlhhdbclpv.supabase.co:5432/postgres
```

### **Google Maps API Configuration**
```bash
# Google Maps Platform APIs
GOOGLE_MAPS_API_KEY=[PRODUCTION_GOOGLE_MAPS_KEY]
GOOGLE_DIRECTIONS_API_KEY=[PRODUCTION_DIRECTIONS_KEY]
GOOGLE_PLACES_API_KEY=[PRODUCTION_PLACES_KEY]
GOOGLE_GEOCODING_API_KEY=[PRODUCTION_GEOCODING_KEY]

# API Quotas and Limits
GOOGLE_MAPS_DAILY_QUOTA=100000
GOOGLE_DIRECTIONS_DAILY_QUOTA=50000
GOOGLE_PLACES_DAILY_QUOTA=25000
```

### **Route Optimization Configuration**
```bash
# TSP Algorithm Settings
TSP_MAX_ITERATIONS=1000
TSP_GENETIC_POPULATION_SIZE=50
TSP_SIMULATED_ANNEALING_TEMP=1000
TSP_ALGORITHM_TIMEOUT_MS=5000

# Batch Configuration
MAX_BATCH_ORDERS=3
MAX_DEVIATION_KM=5.0
BATCH_CREATION_TIMEOUT_MS=10000
ROUTE_OPTIMIZATION_TIMEOUT_MS=15000

# Performance Monitoring
ENABLE_TSP_METRICS=true
ENABLE_ROUTE_ANALYTICS=true
METRICS_RETENTION_DAYS=90
```

### **Security Configuration**
```bash
# JWT Configuration
JWT_SECRET=[PRODUCTION_JWT_SECRET]
JWT_EXPIRY_HOURS=24
REFRESH_TOKEN_EXPIRY_DAYS=30

# API Rate Limiting
API_RATE_LIMIT_PER_MINUTE=100
BATCH_CREATION_RATE_LIMIT=10
ROUTE_OPTIMIZATION_RATE_LIMIT=20

# CORS Configuration
ALLOWED_ORIGINS=https://gigaeats.com,https://app.gigaeats.com
ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS
ALLOWED_HEADERS=authorization,x-client-info,apikey,content-type
```

## 🗄️ Supabase Production Configuration

### **Database Configuration**
```sql
-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Configure connection pooling
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';

-- Reload configuration
SELECT pg_reload_conf();
```

### **Real-time Configuration**
```toml
# supabase/config.toml - Production settings
[realtime]
enabled = true
max_header_length = 4096

[realtime.tenants.realtime]
name = "realtime"
db_host = "db.abknoalhfltlhhdbclpv.supabase.co"
db_port = 5432
db_name = "postgres"
db_user = "supabase_realtime_admin"
db_password = "[REALTIME_DB_PASSWORD]"
slot_name = "supabase_realtime_replication_slot"
temporary_slot = false
max_replication_lag_mb = 1024
max_slot_wal_keep_size_mb = 1024
```

### **Storage Configuration**
```sql
-- Configure storage buckets for route optimization
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'route-optimization-data',
  'route-optimization-data',
  false,
  10485760, -- 10MB limit
  ARRAY['application/json', 'text/plain']
);

-- Set up RLS policies for storage
CREATE POLICY "Drivers can access their route data" ON storage.objects
FOR ALL USING (
  bucket_id = 'route-optimization-data' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

## 🔧 Edge Functions Configuration

### **Environment Variables for Edge Functions**
```typescript
// supabase/functions/_shared/config.ts
export const config = {
  supabase: {
    url: Deno.env.get('SUPABASE_URL') || 'https://abknoalhfltlhhdbclpv.supabase.co',
    serviceRoleKey: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '',
  },
  googleMaps: {
    apiKey: Deno.env.get('GOOGLE_MAPS_API_KEY') || '',
    directionsApiUrl: 'https://maps.googleapis.com/maps/api/directions/json',
    distanceMatrixApiUrl: 'https://maps.googleapis.com/maps/api/distancematrix/json',
  },
  optimization: {
    maxIterations: parseInt(Deno.env.get('TSP_MAX_ITERATIONS') || '1000'),
    populationSize: parseInt(Deno.env.get('TSP_GENETIC_POPULATION_SIZE') || '50'),
    timeoutMs: parseInt(Deno.env.get('TSP_ALGORITHM_TIMEOUT_MS') || '5000'),
  },
  batch: {
    maxOrders: parseInt(Deno.env.get('MAX_BATCH_ORDERS') || '3'),
    maxDeviationKm: parseFloat(Deno.env.get('MAX_DEVIATION_KM') || '5.0'),
    creationTimeoutMs: parseInt(Deno.env.get('BATCH_CREATION_TIMEOUT_MS') || '10000'),
  },
};
```

### **Edge Function Deployment Configuration**
```bash
# Deploy with environment variables
supabase functions deploy create-delivery-batch \
  --project-ref abknoalhfltlhhdbclpv \
  --env-file .env.production

supabase functions deploy optimize-delivery-route \
  --project-ref abknoalhfltlhhdbclpv \
  --env-file .env.production

supabase functions deploy manage-delivery-batch \
  --project-ref abknoalhfltlhhdbclpv \
  --env-file .env.production
```

## 📱 Flutter Application Configuration

### **Production Build Configuration**
```dart
// lib/src/core/config/app_config.dart
class AppConfig {
  static const String environment = 'production';
  static const bool debugMode = false;
  static const bool enableLogging = false;
  static const bool enableAnalytics = true;
  
  // Supabase Configuration
  static const String supabaseUrl = 'https://abknoalhfltlhhdbclpv.supabase.co';
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  );
  
  // Google Maps Configuration
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
  
  // Route Optimization Settings
  static const int maxBatchOrders = 3;
  static const double maxDeviationKm = 5.0;
  static const int tspMaxIterations = 1000;
  static const int algorithmTimeoutMs = 5000;
  
  // Performance Settings
  static const bool enableTspMetrics = true;
  static const bool enableRouteAnalytics = true;
  static const int metricsRetentionDays = 90;
}
```

### **Android Configuration**
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    
    <application
        android:label="GigaEats"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="false"
        android:networkSecurityConfig="@xml/network_security_config">
        
        <!-- Google Maps API Key -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="${GOOGLE_MAPS_API_KEY}" />
            
        <!-- Activities and Services -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
                
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### **iOS Configuration**
```xml
<!-- ios/Runner/Info.plist -->
<dict>
    <!-- Google Maps API Key -->
    <key>GOOGLE_MAPS_API_KEY</key>
    <string>${GOOGLE_MAPS_API_KEY}</string>
    
    <!-- Location Permissions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>GigaEats needs location access to optimize delivery routes and provide accurate navigation.</string>
    
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>GigaEats needs location access to track deliveries and optimize routes for better service.</string>
    
    <!-- Background Modes -->
    <key>UIBackgroundModes</key>
    <array>
        <string>location</string>
        <string>background-fetch</string>
    </array>
    
    <!-- Network Security -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
        <key>NSExceptionDomains</key>
        <dict>
            <key>supabase.co</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <false/>
                <key>NSExceptionMinimumTLSVersion</key>
                <string>TLSv1.2</string>
            </dict>
        </dict>
    </dict>
</dict>
```

## 🔍 Monitoring and Analytics Configuration

### **Performance Monitoring Setup**
```dart
// lib/src/core/services/analytics_service.dart
class AnalyticsService {
  static const bool _enableAnalytics = AppConfig.enableAnalytics;
  
  static Future<void> trackTspPerformance({
    required String batchId,
    required String algorithm,
    required int problemSize,
    required int calculationTimeMs,
    required double optimizationScore,
  }) async {
    if (!_enableAnalytics) return;
    
    await Supabase.instance.client
        .from('tsp_performance_metrics')
        .insert({
          'batch_id': batchId,
          'algorithm_used': algorithm,
          'problem_size': problemSize,
          'calculation_time_ms': calculationTimeMs,
          'optimization_score': optimizationScore,
        });
  }
  
  static Future<void> trackRouteOptimization({
    required String batchId,
    required double distanceKm,
    required int durationMinutes,
    required double improvementPercent,
  }) async {
    if (!_enableAnalytics) return;
    
    await Supabase.instance.client
        .from('route_optimization_metrics')
        .insert({
          'batch_id': batchId,
          'total_distance_km': distanceKm,
          'estimated_duration_minutes': durationMinutes,
          'improvement_percent': improvementPercent,
        });
  }
}
```

### **Error Tracking Configuration**
```dart
// lib/src/core/services/error_tracking_service.dart
class ErrorTrackingService {
  static Future<void> reportError({
    required String component,
    required String error,
    required String stackTrace,
    Map<String, dynamic>? context,
  }) async {
    await Supabase.instance.client
        .from('error_logs')
        .insert({
          'component': component,
          'error_message': error,
          'stack_trace': stackTrace,
          'context': context,
          'environment': AppConfig.environment,
        });
  }
  
  static Future<void> reportTspError({
    required String batchId,
    required String algorithm,
    required String error,
  }) async {
    await reportError(
      component: 'TSP_ALGORITHM',
      error: error,
      stackTrace: StackTrace.current.toString(),
      context: {
        'batch_id': batchId,
        'algorithm': algorithm,
      },
    );
  }
}
```

## 🔒 Security Configuration

### **API Security Settings**
```sql
-- Create API security policies
CREATE POLICY "Drivers can only access their own batches" ON delivery_batches
FOR ALL USING (
  driver_id = auth.uid()::text OR
  EXISTS (
    SELECT 1 FROM drivers 
    WHERE id = auth.uid()::text 
    AND role IN ('admin', 'supervisor')
  )
);

CREATE POLICY "Route optimization data is driver-specific" ON route_optimizations
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM delivery_batches 
    WHERE id = batch_id 
    AND driver_id = auth.uid()::text
  )
);
```

### **Rate Limiting Configuration**
```typescript
// supabase/functions/_shared/rate-limiter.ts
export class RateLimiter {
  private static readonly limits = {
    batchCreation: 10, // per minute
    routeOptimization: 20, // per minute
    general: 100, // per minute
  };
  
  static async checkRateLimit(
    userId: string,
    operation: keyof typeof RateLimiter.limits
  ): Promise<boolean> {
    const limit = this.limits[operation];
    const key = `rate_limit:${operation}:${userId}`;
    
    // Implementation using Redis or Supabase storage
    // Return true if within limits, false if exceeded
    return true;
  }
}
```

## ✅ Configuration Validation Checklist

### **Environment Variables**
- [ ] All Supabase credentials configured
- [ ] Google Maps API keys set and validated
- [ ] TSP algorithm parameters configured
- [ ] Security settings applied
- [ ] Monitoring and analytics enabled

### **Database Configuration**
- [ ] Connection pooling optimized
- [ ] Required extensions enabled
- [ ] RLS policies applied
- [ ] Indexes created for performance
- [ ] Real-time subscriptions configured

### **Application Configuration**
- [ ] Production build settings applied
- [ ] API keys integrated
- [ ] Permissions configured
- [ ] Error tracking enabled
- [ ] Performance monitoring active

### **Security Configuration**
- [ ] HTTPS enforced
- [ ] API rate limiting enabled
- [ ] Data access policies applied
- [ ] Authentication configured
- [ ] CORS settings validated

---

**Configuration Version**: Multi-Order Route Optimization v1.0
**Last Updated**: [Date]
**Next Review**: [Date]
