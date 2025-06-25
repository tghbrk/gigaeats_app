# ⚙️ GigaEats Marketplace Wallet - Operations & Maintenance Guide

## 🎯 Overview

This guide provides comprehensive procedures for ongoing operations, maintenance, and monitoring of the GigaEats Marketplace Wallet System. It covers daily operations, preventive maintenance, performance optimization, and compliance management.

---

## 📅 Daily Operations

### **Morning Health Check (9:00 AM MYT)**

#### **System Status Verification**
```sql
-- Daily system health dashboard
WITH daily_metrics AS (
  SELECT 
    'Active Wallets' as metric,
    COUNT(*) as value,
    'count' as unit
  FROM stakeholder_wallets 
  WHERE is_active = true
  
  UNION ALL
  
  SELECT 
    'Pending Escrow Amount',
    ROUND(SUM(total_amount), 2),
    'MYR'
  FROM escrow_accounts 
  WHERE status = 'held'
  
  UNION ALL
  
  SELECT 
    'Transactions (24h)',
    COUNT(*),
    'count'
  FROM wallet_transactions 
  WHERE created_at > NOW() - INTERVAL '24 hours'
  
  UNION ALL
  
  SELECT 
    'Failed Payouts (24h)',
    COUNT(*),
    'count'
  FROM payout_requests 
  WHERE status = 'failed' 
  AND created_at > NOW() - INTERVAL '24 hours'
  
  UNION ALL
  
  SELECT 
    'Compliance Alerts (24h)',
    COUNT(*),
    'count'
  FROM financial_audit_log 
  WHERE event_type = 'compliance_violation'
  AND created_at > NOW() - INTERVAL '24 hours'
)
SELECT 
  metric,
  value,
  unit,
  CASE 
    WHEN metric = 'Failed Payouts (24h)' AND value > 10 THEN '🔴 HIGH'
    WHEN metric = 'Compliance Alerts (24h)' AND value > 0 THEN '🟡 MEDIUM'
    ELSE '🟢 NORMAL'
  END as status
FROM daily_metrics;
```

#### **Performance Metrics Check**
```sql
-- Database performance monitoring
SELECT 
  query_type,
  avg_execution_time_ms,
  total_calls,
  cache_hit_ratio
FROM (
  SELECT 
    'Wallet Balance Queries' as query_type,
    ROUND(AVG(mean_exec_time), 2) as avg_execution_time_ms,
    SUM(calls) as total_calls,
    ROUND(AVG(shared_blks_hit::float / (shared_blks_hit + shared_blks_read + 1)), 4) as cache_hit_ratio
  FROM pg_stat_statements 
  WHERE query LIKE '%stakeholder_wallets%'
  
  UNION ALL
  
  SELECT 
    'Transaction History Queries',
    ROUND(AVG(mean_exec_time), 2),
    SUM(calls),
    ROUND(AVG(shared_blks_hit::float / (shared_blks_hit + shared_blks_read + 1)), 4)
  FROM pg_stat_statements 
  WHERE query LIKE '%wallet_transactions%'
) performance_data;
```

### **Escrow Account Management**

#### **Automatic Escrow Release Check**
```sql
-- Check escrow accounts ready for release
SELECT 
  ea.id,
  ea.order_id,
  ea.total_amount,
  ea.release_trigger,
  ea.hold_until,
  o.status as order_status,
  o.delivered_at
FROM escrow_accounts ea
JOIN orders o ON ea.order_id = o.id
WHERE ea.status = 'held'
AND (
  (ea.release_trigger = 'order_delivered' AND o.status = 'delivered')
  OR (ea.release_trigger = 'time_based' AND ea.hold_until <= NOW())
  OR (ea.release_trigger = 'manual_release' AND ea.manual_release_approved = true)
)
ORDER BY ea.created_at;
```

#### **Process Automatic Releases**
```sql
-- Execute automatic escrow releases
WITH releases AS (
  SELECT ea.id as escrow_id
  FROM escrow_accounts ea
  JOIN orders o ON ea.order_id = o.id
  WHERE ea.status = 'held'
  AND ea.release_trigger = 'order_delivered' 
  AND o.status = 'delivered'
  AND o.delivered_at <= NOW() - INTERVAL '1 hour' -- 1 hour grace period
)
UPDATE escrow_accounts 
SET 
  status = 'released',
  release_date = NOW(),
  processed_by = 'system_auto_release'
WHERE id IN (SELECT escrow_id FROM releases);
```

### **Payout Processing**

#### **Daily Payout Queue Review**
```sql
-- Review pending payout requests
SELECT 
  pr.id,
  up.role as user_role,
  pr.amount,
  pr.bank_name,
  pr.account_holder_name,
  pr.created_at,
  pr.compliance_status,
  CASE 
    WHEN pr.amount >= 25000 THEN 'Requires AML Review'
    WHEN pr.compliance_status = 'flagged' THEN 'Compliance Review Required'
    ELSE 'Ready for Processing'
  END as processing_status
FROM payout_requests pr
JOIN stakeholder_wallets sw ON pr.wallet_id = sw.id
JOIN user_profiles up ON sw.user_id = up.user_id
WHERE pr.status = 'pending'
ORDER BY pr.created_at;
```

#### **Process Approved Payouts**
```sql
-- Mark payouts as processing (to be handled by external system)
UPDATE payout_requests 
SET 
  status = 'processing',
  processing_started_at = NOW()
WHERE status = 'pending'
AND compliance_status = 'approved'
AND amount < 25000; -- Below AML threshold
```

---

## 📊 Weekly Operations

### **Monday: Performance Review**

#### **Weekly Performance Report**
```sql
-- Generate weekly performance metrics
WITH weekly_stats AS (
  SELECT 
    'Total Transaction Volume' as metric,
    CONCAT('RM ', ROUND(SUM(amount), 2)) as value
  FROM wallet_transactions 
  WHERE created_at >= DATE_TRUNC('week', NOW()) - INTERVAL '1 week'
  AND created_at < DATE_TRUNC('week', NOW())
  
  UNION ALL
  
  SELECT 
    'Average Transaction Size',
    CONCAT('RM ', ROUND(AVG(amount), 2))
  FROM wallet_transactions 
  WHERE created_at >= DATE_TRUNC('week', NOW()) - INTERVAL '1 week'
  AND created_at < DATE_TRUNC('week', NOW())
  
  UNION ALL
  
  SELECT 
    'Payout Success Rate',
    CONCAT(ROUND(
      COUNT(CASE WHEN status = 'completed' THEN 1 END)::float / 
      COUNT(*)::float * 100, 2
    ), '%')
  FROM payout_requests 
  WHERE created_at >= DATE_TRUNC('week', NOW()) - INTERVAL '1 week'
  AND created_at < DATE_TRUNC('week', NOW())
  
  UNION ALL
  
  SELECT 
    'Commission Distribution Accuracy',
    CONCAT(ROUND(
      COUNT(CASE WHEN distribution_status = 'completed' THEN 1 END)::float / 
      COUNT(*)::float * 100, 2
    ), '%')
  FROM escrow_accounts 
  WHERE status = 'released'
  AND release_date >= DATE_TRUNC('week', NOW()) - INTERVAL '1 week'
  AND release_date < DATE_TRUNC('week', NOW())
)
SELECT * FROM weekly_stats;
```

### **Wednesday: Commission Structure Review**

#### **Commission Performance Analysis**
```sql
-- Analyze commission structure effectiveness
SELECT 
  cs.id as structure_id,
  cs.platform_fee_rate,
  cs.vendor_commission_rate,
  cs.sales_agent_commission_rate,
  cs.driver_commission_rate,
  COUNT(ea.id) as orders_processed,
  ROUND(AVG(ea.total_amount), 2) as avg_order_value,
  ROUND(SUM(ea.platform_fee), 2) as total_platform_revenue
FROM commission_structures cs
LEFT JOIN escrow_accounts ea ON ea.commission_structure_id = cs.id
WHERE ea.created_at >= NOW() - INTERVAL '7 days'
AND cs.is_active = true
GROUP BY cs.id, cs.platform_fee_rate, cs.vendor_commission_rate, 
         cs.sales_agent_commission_rate, cs.driver_commission_rate
ORDER BY total_platform_revenue DESC;
```

### **Friday: Security Audit**

#### **Weekly Security Review**
```sql
-- Security audit report
WITH security_metrics AS (
  SELECT 
    'Failed Login Attempts' as metric,
    COUNT(*) as value
  FROM auth_audit_logs 
  WHERE event_type = 'sign_in_failed'
  AND created_at >= NOW() - INTERVAL '7 days'
  
  UNION ALL
  
  SELECT 
    'Suspicious Transactions',
    COUNT(*)
  FROM financial_audit_log 
  WHERE event_type = 'suspicious_activity'
  AND created_at >= NOW() - INTERVAL '7 days'
  
  UNION ALL
  
  SELECT 
    'AML Alerts',
    COUNT(*)
  FROM financial_audit_log 
  WHERE event_type = 'aml_alert'
  AND created_at >= NOW() - INTERVAL '7 days'
  
  UNION ALL
  
  SELECT 
    'Compliance Violations',
    COUNT(*)
  FROM financial_audit_log 
  WHERE event_type = 'compliance_violation'
  AND created_at >= NOW() - INTERVAL '7 days'
)
SELECT 
  metric,
  value,
  CASE 
    WHEN metric = 'Failed Login Attempts' AND value > 100 THEN '🔴 HIGH RISK'
    WHEN metric = 'AML Alerts' AND value > 5 THEN '🟡 REVIEW REQUIRED'
    WHEN metric = 'Compliance Violations' AND value > 0 THEN '🟡 REVIEW REQUIRED'
    ELSE '🟢 NORMAL'
  END as risk_level
FROM security_metrics;
```

---

## 🗓️ Monthly Operations

### **First Monday: Financial Reconciliation**

#### **Monthly Financial Reconciliation**
```sql
-- Monthly financial reconciliation report
WITH monthly_reconciliation AS (
  SELECT 
    'Total Revenue Processed' as category,
    ROUND(SUM(total_amount), 2) as amount
  FROM escrow_accounts 
  WHERE status = 'released'
  AND release_date >= DATE_TRUNC('month', NOW()) - INTERVAL '1 month'
  AND release_date < DATE_TRUNC('month', NOW())
  
  UNION ALL
  
  SELECT 
    'Platform Fees Collected',
    ROUND(SUM(platform_fee), 2)
  FROM escrow_accounts 
  WHERE status = 'released'
  AND release_date >= DATE_TRUNC('month', NOW()) - INTERVAL '1 month'
  AND release_date < DATE_TRUNC('month', NOW())
  
  UNION ALL
  
  SELECT 
    'Total Payouts Processed',
    ROUND(SUM(amount), 2)
  FROM payout_requests 
  WHERE status = 'completed'
  AND processed_at >= DATE_TRUNC('month', NOW()) - INTERVAL '1 month'
  AND processed_at < DATE_TRUNC('month', NOW())
  
  UNION ALL
  
  SELECT 
    'Outstanding Wallet Balances',
    ROUND(SUM(available_balance), 2)
  FROM stakeholder_wallets 
  WHERE is_active = true
)
SELECT * FROM monthly_reconciliation;
```

### **Mid-Month: Performance Optimization**

#### **Database Maintenance**
```sql
-- Monthly database maintenance
-- Vacuum and analyze critical tables
VACUUM ANALYZE stakeholder_wallets;
VACUUM ANALYZE wallet_transactions;
VACUUM ANALYZE escrow_accounts;
VACUUM ANALYZE payout_requests;
VACUUM ANALYZE financial_audit_log;

-- Update table statistics
ANALYZE stakeholder_wallets;
ANALYZE wallet_transactions;
ANALYZE escrow_accounts;

-- Check for unused indexes
SELECT 
  schemaname,
  tablename,
  indexname,
  idx_scan,
  idx_tup_read
FROM pg_stat_user_indexes 
WHERE idx_scan = 0
AND tablename IN ('stakeholder_wallets', 'wallet_transactions', 'escrow_accounts')
ORDER BY pg_relation_size(indexrelid) DESC;
```

#### **Archive Old Data**
```sql
-- Archive old audit logs (keep 7 years for compliance)
CREATE TABLE IF NOT EXISTS financial_audit_log_archive (
  LIKE financial_audit_log INCLUDING ALL
);

-- Move old data to archive
WITH archived_logs AS (
  DELETE FROM financial_audit_log 
  WHERE created_at < NOW() - INTERVAL '7 years'
  RETURNING *
)
INSERT INTO financial_audit_log_archive 
SELECT * FROM archived_logs;
```

### **End of Month: Compliance Reporting**

#### **Generate Compliance Reports**
```sql
-- Monthly compliance report for regulators
WITH compliance_summary AS (
  SELECT 
    'Large Transactions (>RM 25,000)' as report_type,
    COUNT(*) as transaction_count,
    ROUND(SUM(amount), 2) as total_amount
  FROM wallet_transactions 
  WHERE amount >= 25000
  AND created_at >= DATE_TRUNC('month', NOW()) - INTERVAL '1 month'
  AND created_at < DATE_TRUNC('month', NOW())
  
  UNION ALL
  
  SELECT 
    'AML Alerts Generated',
    COUNT(*),
    NULL
  FROM financial_audit_log 
  WHERE event_type = 'aml_alert'
  AND created_at >= DATE_TRUNC('month', NOW()) - INTERVAL '1 month'
  AND created_at < DATE_TRUNC('month', NOW())
  
  UNION ALL
  
  SELECT 
    'Suspicious Activity Reports',
    COUNT(*),
    NULL
  FROM financial_audit_log 
  WHERE event_type = 'suspicious_activity'
  AND created_at >= DATE_TRUNC('month', NOW()) - INTERVAL '1 month'
  AND created_at < DATE_TRUNC('month', NOW())
)
SELECT * FROM compliance_summary;
```

---

## 🚨 Emergency Procedures

### **Payment System Outage**

#### **Immediate Response (0-15 minutes)**
1. **Assess Impact**
   ```sql
   -- Check recent payment failures
   SELECT COUNT(*) as failed_payments
   FROM payment_intents 
   WHERE status = 'requires_payment_method'
   AND created_at > NOW() - INTERVAL '15 minutes';
   ```

2. **Enable Maintenance Mode**
   ```sql
   -- Disable new payment processing
   UPDATE system_config 
   SET config_value = 'true'
   WHERE config_key = 'maintenance_mode_enabled';
   ```

3. **Notify Stakeholders**
   ```sql
   -- Send system alert notifications
   INSERT INTO system_notifications (
     notification_type,
     title,
     message,
     priority,
     target_audience
   ) VALUES (
     'system_alert',
     'Payment System Maintenance',
     'Payment processing is temporarily unavailable. We are working to resolve this issue.',
     'high',
     'all_users'
   );
   ```

#### **Recovery Procedures (15-60 minutes)**
1. **Identify Root Cause**
   - Check Stripe API status
   - Verify database connectivity
   - Review Edge Function logs
   - Validate SSL certificates

2. **Implement Fix**
   - Restart failed services
   - Deploy hotfix if needed
   - Verify system functionality

3. **Resume Operations**
   ```sql
   -- Disable maintenance mode
   UPDATE system_config 
   SET config_value = 'false'
   WHERE config_key = 'maintenance_mode_enabled';
   ```

### **Security Breach Response**

#### **Immediate Actions**
1. **Isolate Affected Systems**
2. **Preserve Evidence**
3. **Assess Data Impact**
4. **Notify Security Team**
5. **Implement Containment Measures**

#### **Communication Plan**
- **Internal**: Immediate notification to CTO and security team
- **External**: Customer notification within 72 hours (GDPR compliance)
- **Regulatory**: Report to Bank Negara Malaysia if financial data affected

---

## 📈 Performance Monitoring

### **Key Performance Indicators (KPIs)**

#### **Financial KPIs**
- **Transaction Success Rate**: >99.5%
- **Average Payout Processing Time**: <24 hours
- **Commission Distribution Accuracy**: >99.9%
- **Escrow Release Timeliness**: >95% within SLA

#### **Technical KPIs**
- **API Response Time**: <500ms (95th percentile)
- **Database Query Performance**: <100ms average
- **System Uptime**: >99.9%
- **Error Rate**: <0.1%

#### **Security KPIs**
- **Failed Authentication Rate**: <1%
- **AML Alert Response Time**: <4 hours
- **Compliance Violation Resolution**: <24 hours
- **Security Incident Response**: <15 minutes

### **Automated Monitoring Setup**
```sql
-- Create monitoring views for dashboards
CREATE OR REPLACE VIEW wallet_system_health AS
SELECT 
  'payment_success_rate' as metric,
  ROUND(
    COUNT(CASE WHEN status = 'succeeded' THEN 1 END)::float / 
    COUNT(*)::float * 100, 2
  ) as value,
  '%' as unit
FROM payment_intents 
WHERE created_at > NOW() - INTERVAL '24 hours'

UNION ALL

SELECT 
  'avg_payout_processing_time',
  ROUND(
    EXTRACT(EPOCH FROM AVG(processed_at - created_at)) / 3600, 2
  ),
  'hours'
FROM payout_requests 
WHERE status = 'completed'
AND processed_at > NOW() - INTERVAL '7 days';
```

---

## 📋 Maintenance Schedules

### **Daily Tasks (Automated)**
- [ ] System health check
- [ ] Escrow release processing
- [ ] Payout queue review
- [ ] Performance metrics collection
- [ ] Security log review

### **Weekly Tasks**
- [ ] Performance optimization review
- [ ] Commission structure analysis
- [ ] Security audit
- [ ] Database maintenance
- [ ] Backup verification

### **Monthly Tasks**
- [ ] Financial reconciliation
- [ ] Compliance reporting
- [ ] Data archival
- [ ] Capacity planning
- [ ] Security assessment

### **Quarterly Tasks**
- [ ] Disaster recovery testing
- [ ] Security penetration testing
- [ ] Performance benchmarking
- [ ] Compliance audit
- [ ] System architecture review

---

**⚙️ Remember**: Consistent monitoring and maintenance ensure the reliability, security, and performance of the marketplace wallet system.
