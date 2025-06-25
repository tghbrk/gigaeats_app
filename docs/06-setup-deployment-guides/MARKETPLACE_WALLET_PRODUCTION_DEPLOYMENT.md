# 🚀 GigaEats Marketplace Wallet - Production Deployment Guide

## 🎯 Overview

This guide provides comprehensive step-by-step procedures for deploying the GigaEats Marketplace Wallet System to production. It covers database migrations, Edge Function deployment, security configuration, and post-deployment validation.

## ⚠️ Pre-Deployment Checklist

### **Critical Prerequisites**
- [ ] **Backup existing production database**
- [ ] **Verify Stripe production keys are configured**
- [ ] **Confirm Malaysian bank integration credentials**
- [ ] **Test all Edge Functions in staging environment**
- [ ] **Validate security compliance requirements**
- [ ] **Prepare rollback procedures**

### **Environment Verification**
```bash
# Verify Supabase CLI is configured for production
supabase status --project-ref YOUR_PRODUCTION_PROJECT_REF

# Verify Flutter environment
flutter doctor
flutter --version

# Verify dependencies
flutter pub deps
```

## 🗄️ Phase 1: Database Migration Deployment

### **Step 1: Pre-Migration Backup**
```sql
-- Create comprehensive backup
pg_dump -h YOUR_DB_HOST -U postgres -d postgres \
  --schema=public \
  --data-only \
  --file=gigaeats_pre_wallet_backup_$(date +%Y%m%d_%H%M%S).sql

-- Verify backup integrity
psql -h YOUR_DB_HOST -U postgres -d postgres \
  -c "SELECT COUNT(*) FROM orders; SELECT COUNT(*) FROM users;"
```

### **Step 2: Apply Database Migration**
```bash
# Navigate to project root
cd /path/to/gigaeats-app

# Apply the marketplace wallet migration
supabase db push --project-ref YOUR_PRODUCTION_PROJECT_REF

# Verify migration success
supabase db diff --project-ref YOUR_PRODUCTION_PROJECT_REF
```

### **Step 3: Verify Database Schema**
```sql
-- Verify all new tables exist
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
  'escrow_accounts',
  'stakeholder_wallets', 
  'wallet_transactions',
  'commission_structures',
  'payout_requests',
  'financial_audit_log'
);

-- Verify RLS policies are active
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN (
  'escrow_accounts',
  'stakeholder_wallets',
  'wallet_transactions',
  'payout_requests'
);

-- Verify indexes are created
SELECT schemaname, tablename, indexname, indexdef 
FROM pg_indexes 
WHERE tablename IN (
  'escrow_accounts',
  'stakeholder_wallets',
  'wallet_transactions'
);
```

## ⚡ Phase 2: Edge Functions Deployment

### **Step 1: Deploy Payment Processing Functions**
```bash
# Deploy process-marketplace-payment function
supabase functions deploy process-marketplace-payment \
  --project-ref YOUR_PRODUCTION_PROJECT_REF

# Deploy commission-distribution function  
supabase functions deploy commission-distribution \
  --project-ref YOUR_PRODUCTION_PROJECT_REF

# Deploy payout-processing function
supabase functions deploy payout-processing \
  --project-ref YOUR_PRODUCTION_PROJECT_REF

# Deploy wallet-management function
supabase functions deploy wallet-management \
  --project-ref YOUR_PRODUCTION_PROJECT_REF
```

### **Step 2: Configure Environment Variables**
```bash
# Set production environment variables
supabase secrets set STRIPE_SECRET_KEY=sk_live_... \
  --project-ref YOUR_PRODUCTION_PROJECT_REF

supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_... \
  --project-ref YOUR_PRODUCTION_PROJECT_REF

supabase secrets set MARKETPLACE_PLATFORM_FEE_RATE=0.05 \
  --project-ref YOUR_PRODUCTION_PROJECT_REF

supabase secrets set MARKETPLACE_AUTO_RELEASE_DAYS=7 \
  --project-ref YOUR_PRODUCTION_PROJECT_REF

supabase secrets set WISE_API_KEY=your_production_wise_key \
  --project-ref YOUR_PRODUCTION_PROJECT_REF

supabase secrets set BNM_COMPLIANCE_ENDPOINT=https://api.bnm.gov.my \
  --project-ref YOUR_PRODUCTION_PROJECT_REF
```

### **Step 3: Verify Edge Function Deployment**
```bash
# Test each function endpoint
curl -X POST 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/process-marketplace-payment' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"test": true}'

# Check function logs
supabase functions logs process-marketplace-payment \
  --project-ref YOUR_PRODUCTION_PROJECT_REF
```

## 📱 Phase 3: Flutter Application Deployment

### **Step 1: Update Production Configuration**
```dart
// lib/core/config/supabase_config.dart
class SupabaseConfig {
  static const String url = 'https://YOUR_PRODUCTION_PROJECT_REF.supabase.co';
  static const String anonKey = 'YOUR_PRODUCTION_ANON_KEY';
  static const String serviceRoleKey = 'YOUR_PRODUCTION_SERVICE_ROLE_KEY';
}

// lib/core/config/stripe_config.dart  
class StripeConfig {
  static const String publishableKey = 'pk_live_...'; // Production key
  static const String merchantId = 'merchant.com.gigaeats.app';
}
```

### **Step 2: Build Production App**
```bash
# Clean previous builds
flutter clean
flutter pub get

# Build for Android
flutter build apk --release --target-platform android-arm64

# Build for iOS  
flutter build ios --release

# Build for Web
flutter build web --release
```

### **Step 3: Deploy to App Stores**
```bash
# Android - Upload to Google Play Console
# iOS - Upload to App Store Connect via Xcode
# Web - Deploy to hosting platform

# Verify deployment
flutter test
flutter analyze
```

## 🔒 Phase 4: Security Configuration

### **Step 1: Configure SSL/TLS**
```bash
# Verify HTTPS is enforced
curl -I https://YOUR_PROJECT_REF.supabase.co/functions/v1/process-marketplace-payment

# Check SSL certificate
openssl s_client -connect YOUR_PROJECT_REF.supabase.co:443 -servername YOUR_PROJECT_REF.supabase.co
```

### **Step 2: Configure Rate Limiting**
```sql
-- Configure rate limiting for financial operations
INSERT INTO rate_limits (
  endpoint_pattern,
  max_requests_per_minute,
  max_requests_per_hour,
  is_active
) VALUES 
('/functions/v1/process-marketplace-payment', 60, 1000, true),
('/functions/v1/payout-processing', 30, 500, true),
('/functions/v1/wallet-management', 120, 2000, true);
```

### **Step 3: Enable Audit Logging**
```sql
-- Verify audit logging is active
SELECT * FROM financial_audit_log 
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 10;

-- Configure log retention
UPDATE system_config 
SET config_value = '2555' -- 7 years in days
WHERE config_key = 'audit_log_retention_days';
```

## 🧪 Phase 5: Post-Deployment Validation

### **Step 1: End-to-End Testing**
```bash
# Run comprehensive test suite
flutter test test/features/marketplace_wallet/
flutter test test/integration/marketplace_wallet_integration_test.dart

# Test payment flow
curl -X POST 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/process-marketplace-payment' \
  -H 'Authorization: Bearer YOUR_SERVICE_ROLE_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "order_id": "test-order-123",
    "amount": 5000,
    "currency": "myr",
    "customer_id": "test-customer-456"
  }'
```

### **Step 2: Performance Validation**
```sql
-- Check database performance
EXPLAIN ANALYZE SELECT * FROM stakeholder_wallets WHERE user_id = 'test-user';
EXPLAIN ANALYZE SELECT * FROM escrow_accounts WHERE status = 'held';

-- Monitor query performance
SELECT query, mean_exec_time, calls 
FROM pg_stat_statements 
WHERE query LIKE '%stakeholder_wallets%' 
OR query LIKE '%escrow_accounts%'
ORDER BY mean_exec_time DESC
LIMIT 10;
```

### **Step 3: Security Validation**
```bash
# Test authentication
curl -X GET 'https://YOUR_PROJECT_REF.supabase.co/rest/v1/stakeholder_wallets' \
  -H 'Authorization: Bearer INVALID_TOKEN'
# Should return 401 Unauthorized

# Test RLS policies
curl -X GET 'https://YOUR_PROJECT_REF.supabase.co/rest/v1/stakeholder_wallets' \
  -H 'Authorization: Bearer VALID_USER_TOKEN'
# Should only return user's own wallets
```

## 📊 Phase 6: Monitoring Setup

### **Step 1: Configure Alerts**
```sql
-- Set up critical alerts
INSERT INTO monitoring_alerts (
  alert_name,
  condition_query,
  threshold_value,
  alert_frequency,
  notification_channels
) VALUES 
('High Escrow Balance', 'SELECT SUM(total_amount) FROM escrow_accounts WHERE status = ''held''', 100000, '1 hour', 'email,slack'),
('Failed Payouts', 'SELECT COUNT(*) FROM payout_requests WHERE status = ''failed'' AND created_at > NOW() - INTERVAL ''1 hour''', 5, '15 minutes', 'email,sms'),
('Compliance Violations', 'SELECT COUNT(*) FROM financial_audit_log WHERE event_type = ''compliance_violation'' AND created_at > NOW() - INTERVAL ''1 hour''', 1, '5 minutes', 'email,slack,sms');
```

### **Step 2: Dashboard Configuration**
```bash
# Configure monitoring dashboards
# - Wallet balance trends
# - Transaction volume metrics  
# - Payout processing times
# - Compliance monitoring
# - Error rate tracking
```

## 🔄 Phase 7: Rollback Procedures

### **Emergency Rollback Plan**
```bash
# 1. Stop new transactions
supabase functions delete process-marketplace-payment --project-ref YOUR_PRODUCTION_PROJECT_REF

# 2. Restore database backup
psql -h YOUR_DB_HOST -U postgres -d postgres < gigaeats_pre_wallet_backup_TIMESTAMP.sql

# 3. Revert application deployment
# Deploy previous version of Flutter app

# 4. Verify system stability
curl -X GET 'https://YOUR_PROJECT_REF.supabase.co/rest/v1/orders'
```

## ✅ Deployment Completion Checklist

- [ ] **Database migration applied successfully**
- [ ] **All Edge Functions deployed and tested**
- [ ] **Production environment variables configured**
- [ ] **Flutter application built and deployed**
- [ ] **Security configurations verified**
- [ ] **SSL/TLS certificates validated**
- [ ] **Rate limiting configured**
- [ ] **Audit logging enabled**
- [ ] **End-to-end testing completed**
- [ ] **Performance benchmarks met**
- [ ] **Monitoring and alerts configured**
- [ ] **Rollback procedures documented and tested**
- [ ] **Team notified of successful deployment**

## 📞 Post-Deployment Support

### **Immediate Actions (First 24 Hours)**
- Monitor error rates and performance metrics
- Verify payment processing functionality
- Check compliance monitoring alerts
- Review audit log completeness

### **First Week Actions**
- Analyze transaction volume and patterns
- Review payout processing efficiency
- Validate commission distribution accuracy
- Monitor user adoption and feedback

### **Ongoing Monitoring**
- Weekly performance reviews
- Monthly compliance audits
- Quarterly security assessments
- Annual penetration testing

---

**🎉 Deployment Complete!** The GigaEats Marketplace Wallet System is now live in production.
