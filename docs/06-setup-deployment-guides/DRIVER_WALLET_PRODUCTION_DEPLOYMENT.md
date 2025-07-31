# 🚗💰 GigaEats Driver Wallet System - Production Deployment Guide

## 🎯 Overview

This guide provides comprehensive instructions for deploying the GigaEats Driver Wallet System to production. Follow these steps carefully to ensure a secure, reliable, and performant deployment.

## 📋 Pre-Deployment Checklist

### **✅ Code Readiness**
- [ ] All integration tests passing
- [ ] Security audit completed
- [ ] Performance benchmarks met
- [ ] Code review approved
- [ ] Documentation updated

### **✅ Infrastructure Readiness**
- [ ] Supabase production project configured
- [ ] Database schema deployed
- [ ] RLS policies implemented
- [ ] Edge Functions deployed
- [ ] Monitoring systems configured

### **✅ Security Validation**
- [ ] Authentication flows tested
- [ ] Authorization policies verified
- [ ] Input validation implemented
- [ ] Audit logging configured
- [ ] Encryption verified

### **✅ Testing Completion**
- [ ] Unit tests: >90% coverage
- [ ] Integration tests: All critical flows
- [ ] Performance tests: Benchmarks met
- [ ] Security tests: Vulnerabilities addressed
- [ ] User acceptance tests: Completed

## 🗄️ Database Deployment

### **Step 1: Schema Migration**

Execute database migrations in the correct order:

```sql
-- 1. Create driver wallet tables (if not exists)
-- Run: supabase/migrations/20240115000001_create_driver_wallet_tables.sql

-- 2. Add RLS policies
-- Run: supabase/migrations/20240115000002_driver_wallet_rls_policies.sql

-- 3. Create indexes for performance
-- Run: supabase/migrations/20240115000003_driver_wallet_indexes.sql

-- 4. Add audit triggers
-- Run: supabase/migrations/20240115000004_driver_wallet_audit_triggers.sql
```

### **Step 2: Verify Schema**

```bash
# Connect to production database
supabase db connect --project-ref abknoalhfltlhhdbclpv

# Verify tables exist
\dt driver_*

# Verify RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename LIKE 'driver_%';

# Verify indexes
SELECT indexname, tablename, indexdef 
FROM pg_indexes 
WHERE tablename LIKE 'driver_%';
```

### **Step 3: Data Validation**

```sql
-- Verify table structure
DESCRIBE driver_wallets;
DESCRIBE driver_wallet_transactions;
DESCRIBE driver_withdrawal_requests;

-- Test RLS policies with sample data
SET ROLE authenticated;
SELECT * FROM driver_wallets WHERE driver_id = 'test-driver-id';
```

## ⚡ Edge Functions Deployment

### **Step 1: Deploy Edge Functions**

```bash
# Deploy driver wallet operations function
supabase functions deploy driver-wallet-operations \
  --project-ref abknoalhfltlhhdbclpv \
  --verify-jwt

# Deploy notification functions
supabase functions deploy driver-wallet-notifications \
  --project-ref abknoalhfltlhhdbclpv \
  --verify-jwt

# Verify deployment
supabase functions list --project-ref abknoalhfltlhhdbclpv
```

### **Step 2: Test Edge Functions**

```bash
# Test health check
curl -X POST \
  'https://abknoalhfltlhhdbclpv.supabase.co/functions/v1/driver-wallet-operations' \
  -H 'Authorization: Bearer <anon_key>' \
  -H 'Content-Type: application/json' \
  -d '{"action": "health_check"}'

# Expected response: {"status": "healthy", "timestamp": "..."}
```

### **Step 3: Configure Environment Variables**

```bash
# Set production environment variables
supabase secrets set STRIPE_SECRET_KEY=sk_live_... --project-ref abknoalhfltlhhdbclpv
supabase secrets set WEBHOOK_SECRET=whsec_... --project-ref abknoalhfltlhhdbclpv
supabase secrets set NOTIFICATION_API_KEY=... --project-ref abknoalhfltlhhdbclpv
```

## 📱 Flutter App Deployment

### **Step 1: Update Configuration**

Update `lib/src/core/config/app_config.dart`:

```dart
class AppConfig {
  static const String supabaseUrl = 'https://abknoalhfltlhhdbclpv.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  static const bool isProduction = true;
  static const String environment = 'production';
}
```

### **Step 2: Build Production App**

```bash
# Clean previous builds
flutter clean
flutter pub get

# Build Android APK
flutter build apk --release --target-platform android-arm64

# Build Android App Bundle (for Play Store)
flutter build appbundle --release

# Build iOS (if applicable)
flutter build ios --release
```

### **Step 3: Verify Build**

```bash
# Test production build on device
flutter install --release

# Verify wallet functionality
# - Login as test driver
# - Check wallet loading
# - Test earnings processing
# - Test withdrawal request
# - Verify notifications
```

## 🔐 Security Configuration

### **Step 1: RLS Policy Verification**

```sql
-- Test driver isolation
-- Should only return data for authenticated driver
SELECT * FROM driver_wallets WHERE driver_id = auth.uid()::text;

-- Test admin access (with admin role)
SELECT COUNT(*) FROM driver_wallets;

-- Verify transaction isolation
SELECT * FROM driver_wallet_transactions WHERE driver_id = auth.uid()::text;
```

### **Step 2: API Security**

```bash
# Test unauthorized access (should fail)
curl -X POST \
  'https://abknoalhfltlhhdbclpv.supabase.co/functions/v1/driver-wallet-operations' \
  -H 'Content-Type: application/json' \
  -d '{"action": "get_driver_wallet"}'

# Expected: 401 Unauthorized
```

### **Step 3: Input Validation**

```bash
# Test invalid inputs (should fail gracefully)
curl -X POST \
  'https://abknoalhfltlhhdbclpv.supabase.co/functions/v1/driver-wallet-operations' \
  -H 'Authorization: Bearer <valid_token>' \
  -H 'Content-Type: application/json' \
  -d '{"action": "process_earnings_deposit", "amount": -100}'

# Expected: 400 Bad Request with validation error
```

## 📊 Monitoring Setup

### **Step 1: Supabase Monitoring**

Configure Supabase monitoring:

```bash
# Enable database monitoring
# Go to Supabase Dashboard → Settings → Monitoring
# Enable: Database metrics, API metrics, Auth metrics

# Set up alerts for:
# - High error rates (>5%)
# - Slow queries (>2s)
# - High CPU usage (>80%)
# - High memory usage (>80%)
```

### **Step 2: Application Monitoring**

Set up application-level monitoring:

```dart
// Add to main.dart
void main() async {
  // Initialize error tracking
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  
  // Initialize performance monitoring
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
  
  runApp(MyApp());
}
```

### **Step 3: Business Metrics**

Set up business metrics tracking:

```sql
-- Create monitoring views
CREATE VIEW driver_wallet_metrics AS
SELECT 
  DATE(created_at) as date,
  COUNT(*) as total_transactions,
  SUM(amount) as total_volume,
  AVG(amount) as avg_transaction_amount
FROM driver_wallet_transactions
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at);
```

## 🚀 Deployment Execution

### **Step 1: Maintenance Window**

```bash
# Schedule maintenance window
# Notify drivers via in-app notification
# Expected downtime: 15-30 minutes
```

### **Step 2: Database Migration**

```bash
# 1. Backup current database
supabase db dump --project-ref abknoalhfltlhhdbclpv > backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Apply migrations
supabase db push --project-ref abknoalhfltlhhdbclpv

# 3. Verify migration success
supabase db status --project-ref abknoalhfltlhhdbclpv
```

### **Step 3: Edge Function Deployment**

```bash
# Deploy all functions
supabase functions deploy --project-ref abknoalhfltlhhdbclpv

# Test critical functions
./scripts/test_production_functions.sh
```

### **Step 4: App Deployment**

```bash
# Deploy to Play Store (staged rollout)
# Start with 5% of users
# Monitor for 24 hours
# Gradually increase to 100%

# Deploy to App Store (phased release)
# Similar staged approach
```

## ✅ Post-Deployment Validation

### **Step 1: Smoke Tests**

```bash
# Run automated smoke tests
./scripts/production_smoke_tests.sh

# Expected results:
# ✅ Database connectivity
# ✅ Edge Functions responding
# ✅ Authentication working
# ✅ Basic wallet operations
# ✅ Real-time subscriptions
```

### **Step 2: End-to-End Testing**

```bash
# Test complete user flows
# 1. Driver login
# 2. Wallet loading
# 3. Complete delivery (earnings deposit)
# 4. Withdrawal request
# 5. Notification delivery
# 6. Transaction history
```

### **Step 3: Performance Validation**

```bash
# Monitor key metrics for 24 hours:
# - Response times (<2s for all operations)
# - Error rates (<1%)
# - Database performance
# - Memory usage
# - CPU utilization
```

## 🔄 Rollback Plan

### **Emergency Rollback Procedure**

If critical issues are detected:

```bash
# 1. Immediate app rollback
# Revert to previous app version in stores

# 2. Edge Function rollback
supabase functions deploy driver-wallet-operations-v1.0 \
  --project-ref abknoalhfltlhhdbclpv

# 3. Database rollback (if necessary)
# Restore from backup (last resort)
psql -h db.abknoalhfltlhhdbclpv.supabase.co \
     -U postgres \
     -d postgres \
     -f backup_YYYYMMDD_HHMMSS.sql
```

### **Rollback Triggers**

Initiate rollback if:
- Error rate >5% for >10 minutes
- Response time >5s for >5 minutes
- Critical security vulnerability discovered
- Data corruption detected
- User complaints >50 in 1 hour

## 📈 Success Metrics

### **Technical Metrics**
- **Uptime**: >99.9%
- **Response Time**: <2s for 95% of requests
- **Error Rate**: <1%
- **Database Performance**: <500ms for 95% of queries

### **Business Metrics**
- **Wallet Adoption**: >90% of active drivers
- **Transaction Success Rate**: >99%
- **Withdrawal Processing**: <24 hours average
- **User Satisfaction**: >4.5/5 rating

### **Security Metrics**
- **Security Incidents**: 0 critical incidents
- **Data Breaches**: 0 incidents
- **Unauthorized Access**: 0 successful attempts
- **Audit Compliance**: 100% compliance

## 📞 Support & Escalation

### **Support Contacts**
- **Technical Lead**: tech-lead@gigaeats.com
- **DevOps Team**: devops@gigaeats.com
- **Security Team**: security@gigaeats.com
- **On-call Engineer**: +60 12-345-6789

### **Escalation Matrix**
1. **Level 1**: Development team (response: 15 minutes)
2. **Level 2**: Technical lead (response: 30 minutes)
3. **Level 3**: CTO (response: 1 hour)
4. **Level 4**: CEO (response: 2 hours)

---

*This deployment guide ensures a secure, reliable, and successful production deployment of the GigaEats Driver Wallet System. Follow all steps carefully and maintain communication with stakeholders throughout the process.*
