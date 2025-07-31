# 🚀 Multi-Order Route Optimization System - Production Deployment Guide

## 🎯 Overview

This comprehensive guide provides step-by-step procedures for deploying the GigaEats Multi-Order Route Optimization System to production. The system enables drivers to efficiently handle 2-3 orders simultaneously through intelligent batching, dynamic route sequencing, and real-time optimization.

## ⚠️ Pre-Deployment Checklist

### **Critical Prerequisites**
- [ ] **Backup existing production database**
- [ ] **Verify Google Maps API production keys are configured**
- [ ] **Confirm Supabase production project access (abknoalhfltlhhdbclpv)**
- [ ] **Test all Edge Functions in staging environment**
- [ ] **Validate TSP algorithm performance benchmarks**
- [ ] **Prepare rollback procedures**
- [ ] **Verify Android emulator testing environment (emulator-5554)**

### **Environment Verification**
```bash
# Verify Supabase CLI is configured for production
supabase status --project-ref abknoalhfltlhhdbclpv

# Verify Flutter environment
flutter doctor
flutter --version

# Verify dependencies
flutter pub deps

# Check Google Maps API configuration
flutter pub run google_maps_flutter:check_api_key
```

### **System Requirements**
- Flutter 3.x with Dart 3.x
- Supabase CLI 1.x or later
- Google Maps API with Directions API enabled
- Production Supabase project with sufficient compute resources
- Real-time subscriptions enabled

## 🗄️ Phase 1: Database Migration Deployment

### **Step 1: Pre-Migration Backup**
```sql
-- Create comprehensive backup
pg_dump -h YOUR_DB_HOST -U postgres -d postgres \
  --schema=public \
  --data-only \
  --file=gigaeats_pre_route_optimization_backup_$(date +%Y%m%d_%H%M%S).sql

-- Verify backup integrity
psql -h YOUR_DB_HOST -U postgres -d postgres \
  -c "SELECT COUNT(*) FROM orders; SELECT COUNT(*) FROM drivers;"
```

### **Step 2: Apply Route Optimization Database Migration**
```bash
# Navigate to project root
cd /path/to/gigaeats-app

# Apply the route optimization migration
supabase db push --project-ref abknoalhfltlhhdbclpv

# Verify migration success
supabase db diff --project-ref abknoalhfltlhhdbclpv
```

### **Step 3: Verify Database Schema**
```sql
-- Verify all new tables exist
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
  'delivery_batches',
  'batch_orders', 
  'route_optimizations',
  'batch_waypoints',
  'driver_locations',
  'batch_performance_metrics'
);

-- Verify indexes are created
SELECT indexname, tablename 
FROM pg_indexes 
WHERE schemaname = 'public' 
AND tablename IN ('delivery_batches', 'batch_orders', 'route_optimizations');

-- Verify RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('delivery_batches', 'batch_orders', 'route_optimizations');
```

## 🔧 Phase 2: Edge Functions Deployment

### **Step 1: Deploy Route Optimization Edge Functions**
```bash
# Deploy batch creation function
supabase functions deploy create-delivery-batch --project-ref abknoalhfltlhhdbclpv

# Deploy route optimization function
supabase functions deploy optimize-delivery-route --project-ref abknoalhfltlhhdbclpv

# Deploy batch management function
supabase functions deploy manage-delivery-batch --project-ref abknoalhfltlhhdbclpv

# Verify deployments
supabase functions list --project-ref abknoalhfltlhhdbclpv
```

### **Step 2: Test Edge Function Endpoints**
```bash
# Test batch creation endpoint
curl -X POST 'https://abknoalhfltlhhdbclpv.supabase.co/functions/v1/create-delivery-batch' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "driverId": "test-driver-id",
    "orderIds": ["order1", "order2"],
    "maxOrders": 3,
    "maxDeviationKm": 5.0
  }'

# Test route optimization endpoint
curl -X POST 'https://abknoalhfltlhhdbclpv.supabase.co/functions/v1/optimize-delivery-route' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "batchId": "test-batch-id",
    "driverLocation": {"latitude": 3.1390, "longitude": 101.6869}
  }'
```

## 📱 Phase 3: Flutter Application Deployment

### **Step 1: Production Build Configuration**
```yaml
# pubspec.yaml - Verify production dependencies
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  flutter_riverpod: ^2.4.0
  go_router: ^12.0.0
  http: ^1.1.0
```

### **Step 2: Environment Configuration**
```dart
// lib/src/core/config/environment_config.dart
class EnvironmentConfig {
  static const String supabaseUrl = 'https://abknoalhfltlhhdbclpv.supabase.co';
  static const String supabaseAnonKey = 'YOUR_PRODUCTION_ANON_KEY';
  static const String googleMapsApiKey = 'YOUR_PRODUCTION_GOOGLE_MAPS_KEY';
  
  // Route optimization settings
  static const int maxBatchOrders = 3;
  static const double maxDeviationKm = 5.0;
  static const int tspMaxIterations = 1000;
  static const int geneticAlgorithmPopulation = 50;
}
```

### **Step 3: Build and Deploy Flutter App**
```bash
# Clean previous builds
flutter clean
flutter pub get

# Build for Android (production)
flutter build apk --release --target-platform android-arm64

# Build for iOS (production)
flutter build ios --release

# Build for Web (production)
flutter build web --release --web-renderer canvaskit
```

## 🔍 Phase 4: Performance Monitoring Setup

### **Step 1: TSP Algorithm Performance Monitoring**
```sql
-- Create performance monitoring table
CREATE TABLE IF NOT EXISTS tsp_performance_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID REFERENCES delivery_batches(id),
    algorithm_used TEXT NOT NULL,
    problem_size INTEGER NOT NULL,
    calculation_time_ms INTEGER NOT NULL,
    optimization_score DECIMAL(10,2) NOT NULL,
    distance_improvement_percent DECIMAL(5,2),
    time_improvement_percent DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance queries
CREATE INDEX IF NOT EXISTS idx_tsp_performance_batch_id ON tsp_performance_metrics(batch_id);
CREATE INDEX IF NOT EXISTS idx_tsp_performance_algorithm ON tsp_performance_metrics(algorithm_used);
CREATE INDEX IF NOT EXISTS idx_tsp_performance_created_at ON tsp_performance_metrics(created_at);
```

### **Step 2: Route Optimization Metrics Dashboard**
```sql
-- Create real-time metrics view
CREATE OR REPLACE VIEW route_optimization_dashboard AS
SELECT 
    DATE_TRUNC('hour', created_at) as hour,
    COUNT(*) as total_batches,
    AVG(total_distance_km) as avg_distance_km,
    AVG(estimated_duration_minutes) as avg_duration_minutes,
    AVG(optimization_score) as avg_optimization_score,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_batches,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_batches
FROM delivery_batches 
WHERE created_at >= NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', created_at)
ORDER BY hour DESC;
```

## 🚦 Phase 5: Rollout Strategy Implementation

### **Step 1: Feature Flag Configuration**
```dart
// lib/src/core/config/feature_flags.dart
class FeatureFlags {
  static const bool enableMultiOrderBatching = true;
  static const bool enableAdvancedTSP = true;
  static const bool enableRealTimeOptimization = true;
  static const double batchingRolloutPercentage = 100.0; // Start with 10%, increase gradually
  
  static bool shouldEnableBatchingForDriver(String driverId) {
    // Implement gradual rollout logic
    final hash = driverId.hashCode.abs();
    final percentage = (hash % 100) / 100.0;
    return percentage < (batchingRolloutPercentage / 100.0);
  }
}
```

### **Step 2: Beta Testing Program Setup**
```sql
-- Create beta testing tracking table
CREATE TABLE IF NOT EXISTS beta_testing_drivers (
    driver_id UUID PRIMARY KEY REFERENCES drivers(id),
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    feedback_count INTEGER DEFAULT 0,
    performance_score DECIMAL(5,2),
    issues_reported INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed'))
);

-- Insert initial beta drivers (replace with actual driver IDs)
INSERT INTO beta_testing_drivers (driver_id) VALUES 
('driver-uuid-1'),
('driver-uuid-2'),
('driver-uuid-3');
```

## 📊 Phase 6: System Health Monitoring

### **Step 1: Edge Function Performance Monitoring**
```sql
-- Create Edge Function performance tracking
CREATE TABLE IF NOT EXISTS edge_function_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    function_name TEXT NOT NULL,
    execution_time_ms INTEGER NOT NULL,
    memory_usage_mb DECIMAL(8,2),
    success BOOLEAN NOT NULL,
    error_message TEXT,
    request_payload_size INTEGER,
    response_payload_size INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### **Step 2: Automated Alerting Setup**
```sql
-- Create alerting rules for critical metrics
CREATE OR REPLACE FUNCTION check_system_health() 
RETURNS TABLE(alert_type TEXT, message TEXT, severity TEXT) AS $$
BEGIN
    -- Check for high TSP calculation times
    RETURN QUERY
    SELECT 
        'TSP_PERFORMANCE'::TEXT,
        'TSP calculations taking longer than 5 seconds'::TEXT,
        'HIGH'::TEXT
    WHERE EXISTS (
        SELECT 1 FROM tsp_performance_metrics 
        WHERE calculation_time_ms > 5000 
        AND created_at > NOW() - INTERVAL '1 hour'
    );
    
    -- Check for batch creation failures
    RETURN QUERY
    SELECT 
        'BATCH_FAILURES'::TEXT,
        'High batch creation failure rate detected'::TEXT,
        'CRITICAL'::TEXT
    WHERE (
        SELECT COUNT(*) FROM delivery_batches 
        WHERE status = 'failed' 
        AND created_at > NOW() - INTERVAL '1 hour'
    ) > 5;
END;
$$ LANGUAGE plpgsql;
```

## ✅ Production Deployment Completion Checklist

### **Database & Backend**
- [ ] All route optimization tables created successfully
- [ ] RLS policies applied and tested
- [ ] Database indexes created for performance
- [ ] Edge Functions deployed and responding
- [ ] Real-time subscriptions working

### **Application**
- [ ] Flutter app built for production
- [ ] Environment variables configured
- [ ] Google Maps API integration working
- [ ] TSP algorithm performance validated
- [ ] Route optimization UI functional

### **Monitoring & Alerting**
- [ ] Performance metrics collection active
- [ ] System health monitoring configured
- [ ] Automated alerting rules in place
- [ ] Dashboard for real-time monitoring
- [ ] Beta testing program initiated

### **Security & Compliance**
- [ ] RLS policies restrict data access appropriately
- [ ] API keys secured and rotated
- [ ] Driver location data encrypted
- [ ] Audit logging enabled
- [ ] GDPR compliance verified

### **Testing & Validation**
- [ ] End-to-end testing completed on Android emulator
- [ ] Performance benchmarks met
- [ ] Rollback procedures tested
- [ ] Beta driver feedback collected
- [ ] System load testing passed

## 🔄 Emergency Rollback Procedures

### **Immediate Rollback Steps**
```bash
# 1. Disable feature flags
# Update FeatureFlags.enableMultiOrderBatching = false

# 2. Stop Edge Functions
supabase functions delete create-delivery-batch --project-ref abknoalhfltlhhdbclpv
supabase functions delete optimize-delivery-route --project-ref abknoalhfltlhhdbclpv

# 3. Restore database backup if needed
psql -h YOUR_DB_HOST -U postgres -d postgres < gigaeats_pre_route_optimization_backup_TIMESTAMP.sql

# 4. Deploy previous app version
flutter build apk --release
# Deploy to app stores or distribution channels
```

## 📞 Support and Troubleshooting

### **Common Issues**
1. **TSP Algorithm Timeout**: Reduce problem size or increase timeout limits
2. **Google Maps API Quota Exceeded**: Monitor usage and increase quotas
3. **Database Performance**: Check indexes and query optimization
4. **Real-time Subscription Issues**: Verify Supabase connection and RLS policies

### **Emergency Contacts**
- **Technical Lead**: [Contact Information]
- **Database Administrator**: [Contact Information]
- **DevOps Engineer**: [Contact Information]
- **Product Manager**: [Contact Information]

---

**Deployment Date**: [To be filled]
**Deployed By**: [To be filled]
**Version**: Multi-Order Route Optimization System v1.0
**Next Review Date**: [To be scheduled]
