# 🔧 GigaEats Marketplace Wallet - Troubleshooting Guide

## 🎯 Overview

This guide provides comprehensive troubleshooting procedures for common issues in the GigaEats Marketplace Wallet System. It covers user-facing problems, technical issues, and system-level diagnostics.

---

## 🚨 Critical Issues (Immediate Action Required)

### **🔴 Payment Processing Failures**

#### **Symptom**: Customer payments failing during checkout
```
Error: "Payment could not be processed"
Error Code: PAYMENT_INTENT_FAILED
```

#### **Diagnosis Steps**
```sql
-- Check recent payment failures
SELECT pi.id, pi.status, pi.last_payment_error, pi.created_at
FROM payment_intents pi 
WHERE pi.status = 'requires_payment_method' 
AND pi.created_at > NOW() - INTERVAL '1 hour'
ORDER BY pi.created_at DESC;

-- Check Stripe webhook delivery
SELECT * FROM stripe_webhook_logs 
WHERE event_type = 'payment_intent.payment_failed'
AND created_at > NOW() - INTERVAL '1 hour';
```

#### **Resolution Steps**
1. **Verify Stripe Configuration**
   ```bash
   # Check Stripe keys in Supabase
   supabase secrets list --project-ref YOUR_PROJECT_REF
   
   # Test Stripe connectivity
   curl -X POST https://api.stripe.com/v1/payment_intents \
     -H "Authorization: Bearer sk_live_..." \
     -d "amount=1000" \
     -d "currency=myr"
   ```

2. **Check Edge Function Status**
   ```bash
   # Verify function deployment
   supabase functions list --project-ref YOUR_PROJECT_REF
   
   # Check function logs
   supabase functions logs process-marketplace-payment \
     --project-ref YOUR_PROJECT_REF
   ```

3. **Validate Database Connectivity**
   ```sql
   -- Test database connection
   SELECT NOW() as current_time;
   
   -- Check escrow account creation
   SELECT COUNT(*) FROM escrow_accounts 
   WHERE created_at > NOW() - INTERVAL '1 hour';
   ```

### **🔴 Wallet Balance Discrepancies**

#### **Symptom**: User wallet balances don't match transaction history
```
Error: "Wallet balance calculation mismatch"
Expected: RM 150.00, Actual: RM 145.50
```

#### **Diagnosis Steps**
```sql
-- Calculate expected balance vs actual
WITH wallet_calc AS (
  SELECT 
    sw.id as wallet_id,
    sw.available_balance as current_balance,
    COALESCE(SUM(
      CASE 
        WHEN wt.transaction_type = 'credit' THEN wt.amount
        WHEN wt.transaction_type = 'debit' THEN -wt.amount
        ELSE 0
      END
    ), 0) as calculated_balance
  FROM stakeholder_wallets sw
  LEFT JOIN wallet_transactions wt ON sw.id = wt.wallet_id
  WHERE sw.user_id = 'USER_ID_HERE'
  GROUP BY sw.id, sw.available_balance
)
SELECT 
  wallet_id,
  current_balance,
  calculated_balance,
  (current_balance - calculated_balance) as discrepancy
FROM wallet_calc
WHERE ABS(current_balance - calculated_balance) > 0.01;
```

#### **Resolution Steps**
1. **Recalculate Wallet Balance**
   ```sql
   -- Backup current balance
   CREATE TEMP TABLE wallet_backup AS 
   SELECT * FROM stakeholder_wallets WHERE user_id = 'USER_ID_HERE';
   
   -- Recalculate and update
   UPDATE stakeholder_wallets 
   SET available_balance = (
     SELECT COALESCE(SUM(
       CASE 
         WHEN wt.transaction_type = 'credit' THEN wt.amount
         WHEN wt.transaction_type = 'debit' THEN -wt.amount
         ELSE 0
       END
     ), 0)
     FROM wallet_transactions wt 
     WHERE wt.wallet_id = stakeholder_wallets.id
   )
   WHERE user_id = 'USER_ID_HERE';
   ```

2. **Audit Transaction History**
   ```sql
   -- Check for missing transactions
   SELECT 
     ea.id as escrow_id,
     ea.vendor_amount,
     ea.sales_agent_commission,
     ea.driver_commission,
     ea.status,
     ea.release_date
   FROM escrow_accounts ea
   WHERE ea.status = 'released'
   AND ea.release_date > NOW() - INTERVAL '24 hours'
   AND NOT EXISTS (
     SELECT 1 FROM wallet_transactions wt 
     WHERE wt.reference_id = ea.id::text
   );
   ```

---

## ⚠️ Common User Issues

### **💳 Payment Method Problems**

#### **Issue**: "Card declined" or "Invalid payment method"

#### **User Resolution Steps**
1. **Verify Card Details**
   - Check card number, expiry date, and CVV
   - Ensure billing address matches bank records
   - Verify card has sufficient funds

2. **Try Alternative Payment Method**
   - Use different credit/debit card
   - Try bank transfer or e-wallet
   - Contact bank to verify card status

3. **Clear App Cache**
   ```
   Android: Settings → Apps → GigaEats → Storage → Clear Cache
   iOS: Delete and reinstall app
   ```

#### **Admin Resolution Steps**
```sql
-- Check payment method validation logs
SELECT * FROM payment_method_validations 
WHERE user_id = 'USER_ID_HERE'
AND created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- Verify Stripe customer status
SELECT stripe_customer_id, payment_methods_count, default_payment_method
FROM user_payment_profiles 
WHERE user_id = 'USER_ID_HERE';
```

### **💰 Payout Request Issues**

#### **Issue**: "Payout request failed" or "Bank account verification failed"

#### **User Resolution Steps**
1. **Verify Bank Account Details**
   - Double-check account number and bank name
   - Ensure account holder name matches profile
   - Verify account is active and can receive transfers

2. **Check Minimum Payout Amount**
   - Minimum withdrawal: RM 10
   - Maximum daily withdrawal: RM 50,000
   - Ensure sufficient wallet balance

#### **Admin Resolution Steps**
```sql
-- Check payout request details
SELECT 
  pr.id,
  pr.amount,
  pr.bank_account_number,
  pr.bank_name,
  pr.status,
  pr.failure_reason,
  pr.created_at
FROM payout_requests pr
WHERE pr.user_id = 'USER_ID_HERE'
AND pr.status = 'failed'
ORDER BY pr.created_at DESC;

-- Verify bank account format
SELECT 
  bank_name,
  account_number,
  CASE 
    WHEN bank_name = 'Maybank' AND LENGTH(account_number) != 12 THEN 'Invalid length'
    WHEN bank_name = 'CIMB' AND LENGTH(account_number) != 10 THEN 'Invalid length'
    ELSE 'Valid format'
  END as validation_status
FROM payout_requests 
WHERE user_id = 'USER_ID_HERE';
```

### **📊 Transaction History Issues**

#### **Issue**: "Transactions not showing" or "Incomplete transaction history"

#### **User Resolution Steps**
1. **Refresh Transaction Data**
   - Pull down to refresh in mobile app
   - Clear app cache and restart
   - Check internet connection

2. **Verify Date Range**
   - Ensure correct date range is selected
   - Check if transactions are in different time period
   - Look for filters that might hide transactions

#### **Admin Resolution Steps**
```sql
-- Check transaction completeness
SELECT 
  DATE(wt.created_at) as transaction_date,
  COUNT(*) as transaction_count,
  SUM(wt.amount) as total_amount
FROM wallet_transactions wt
JOIN stakeholder_wallets sw ON wt.wallet_id = sw.id
WHERE sw.user_id = 'USER_ID_HERE'
AND wt.created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(wt.created_at)
ORDER BY transaction_date DESC;

-- Check for orphaned transactions
SELECT wt.* 
FROM wallet_transactions wt
LEFT JOIN stakeholder_wallets sw ON wt.wallet_id = sw.id
WHERE sw.id IS NULL;
```

---

## 🔧 Technical Issues

### **⚡ Performance Problems**

#### **Issue**: Slow wallet loading or transaction delays

#### **Diagnosis Steps**
```sql
-- Check database performance
EXPLAIN ANALYZE 
SELECT * FROM stakeholder_wallets sw
JOIN wallet_transactions wt ON sw.id = wt.wallet_id
WHERE sw.user_id = 'USER_ID_HERE'
ORDER BY wt.created_at DESC
LIMIT 50;

-- Check index usage
SELECT 
  schemaname,
  tablename,
  indexname,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch
FROM pg_stat_user_indexes 
WHERE tablename IN ('stakeholder_wallets', 'wallet_transactions')
ORDER BY idx_scan DESC;
```

#### **Resolution Steps**
1. **Optimize Database Queries**
   ```sql
   -- Add missing indexes if needed
   CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_wallet_transactions_wallet_id_created_at 
   ON wallet_transactions(wallet_id, created_at DESC);
   
   -- Update table statistics
   ANALYZE stakeholder_wallets;
   ANALYZE wallet_transactions;
   ```

2. **Check Edge Function Performance**
   ```bash
   # Monitor function execution time
   supabase functions logs wallet-management \
     --project-ref YOUR_PROJECT_REF | grep "execution_time"
   ```

### **🔄 Real-time Sync Issues**

#### **Issue**: Wallet balances not updating in real-time

#### **Diagnosis Steps**
```sql
-- Check real-time subscription status
SELECT 
  subscription_id,
  table_name,
  event_type,
  is_active,
  last_activity
FROM realtime_subscriptions 
WHERE table_name IN ('stakeholder_wallets', 'wallet_transactions');
```

#### **Resolution Steps**
1. **Restart Real-time Subscriptions**
   ```dart
   // In Flutter app
   await supabase.removeAllChannels();
   await _setupWalletSubscription();
   ```

2. **Verify RLS Policies**
   ```sql
   -- Check if RLS is blocking real-time updates
   SELECT * FROM pg_policies 
   WHERE tablename = 'stakeholder_wallets'
   AND policyname LIKE '%realtime%';
   ```

---

## 🛡️ Security Issues

### **🔒 Unauthorized Access Attempts**

#### **Issue**: Suspicious wallet access or transaction attempts

#### **Detection Steps**
```sql
-- Check for unusual access patterns
SELECT 
  user_id,
  ip_address,
  user_agent,
  COUNT(*) as access_count,
  MIN(created_at) as first_access,
  MAX(created_at) as last_access
FROM financial_audit_log 
WHERE event_type = 'wallet_access'
AND created_at > NOW() - INTERVAL '24 hours'
GROUP BY user_id, ip_address, user_agent
HAVING COUNT(*) > 50
ORDER BY access_count DESC;

-- Check for failed authentication attempts
SELECT * FROM auth_audit_logs 
WHERE event_type = 'sign_in_failed'
AND created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;
```

#### **Response Steps**
1. **Immediate Security Measures**
   ```sql
   -- Temporarily lock suspicious accounts
   UPDATE user_profiles 
   SET account_status = 'temporarily_locked'
   WHERE user_id IN ('SUSPICIOUS_USER_IDS');
   
   -- Log security incident
   INSERT INTO security_incidents (
     incident_type,
     user_id,
     description,
     severity,
     status
   ) VALUES (
     'unauthorized_access_attempt',
     'USER_ID_HERE',
     'Multiple failed wallet access attempts',
     'high',
     'investigating'
   );
   ```

2. **Notify Affected Users**
   ```sql
   -- Send security alert notifications
   INSERT INTO notifications (
     user_id,
     notification_type,
     title,
     message,
     priority
   ) VALUES (
     'USER_ID_HERE',
     'security_alert',
     'Security Alert: Unusual Account Activity',
     'We detected unusual activity on your account. Please review your recent transactions.',
     'high'
   );
   ```

---

## 📊 Monitoring and Alerts

### **System Health Checks**

#### **Daily Health Check Script**
```sql
-- Wallet system health check
WITH health_metrics AS (
  SELECT 
    'Total Wallets' as metric,
    COUNT(*)::text as value
  FROM stakeholder_wallets
  WHERE is_active = true
  
  UNION ALL
  
  SELECT 
    'Pending Escrow',
    CONCAT(COUNT(*), ' (RM ', ROUND(SUM(total_amount), 2), ')')
  FROM escrow_accounts
  WHERE status = 'held'
  
  UNION ALL
  
  SELECT 
    'Failed Payouts (24h)',
    COUNT(*)::text
  FROM payout_requests
  WHERE status = 'failed'
  AND created_at > NOW() - INTERVAL '24 hours'
  
  UNION ALL
  
  SELECT 
    'Compliance Violations (24h)',
    COUNT(*)::text
  FROM financial_audit_log
  WHERE event_type = 'compliance_violation'
  AND created_at > NOW() - INTERVAL '24 hours'
)
SELECT * FROM health_metrics;
```

### **Automated Alert Conditions**
```sql
-- Set up monitoring alerts
INSERT INTO monitoring_rules (
  rule_name,
  condition_sql,
  threshold_value,
  alert_frequency,
  notification_channels
) VALUES 
(
  'High Escrow Balance Alert',
  'SELECT SUM(total_amount) FROM escrow_accounts WHERE status = ''held''',
  100000,
  '1 hour',
  'email,slack'
),
(
  'Payout Failure Rate Alert',
  'SELECT COUNT(*) FROM payout_requests WHERE status = ''failed'' AND created_at > NOW() - INTERVAL ''1 hour''',
  10,
  '15 minutes',
  'email,sms'
);
```

---

## 📞 Escalation Procedures

### **Issue Severity Levels**

#### **🔴 Critical (Immediate Response)**
- Payment processing completely down
- Security breach or unauthorized access
- Data corruption or loss
- **Response Time**: Within 15 minutes
- **Escalation**: CTO, Security Team, On-call Engineer

#### **🟡 High (4-hour Response)**
- Individual payment failures
- Wallet balance discrepancies
- Payout processing delays
- **Response Time**: Within 4 hours
- **Escalation**: Engineering Team Lead, Product Manager

#### **🟢 Medium (24-hour Response)**
- UI/UX issues
- Performance degradation
- Feature requests
- **Response Time**: Within 24 hours
- **Escalation**: Development Team, Customer Support

### **Contact Information**
- **Emergency Hotline**: +60-3-XXXX-XXXX
- **Engineering Team**: engineering@gigaeats.com
- **Security Team**: security@gigaeats.com
- **Customer Support**: support@gigaeats.com

---

**🔧 Remember**: Always document issues and resolutions in the system for future reference and continuous improvement.
