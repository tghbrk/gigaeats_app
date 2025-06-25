# GigaEats Marketplace Payment System Setup Guide

## 🎯 Overview

This guide provides step-by-step instructions for setting up the GigaEats Multi-Party Marketplace Payment System. The system builds upon the existing Stripe payment infrastructure and adds comprehensive escrow, wallet, and commission management capabilities.

## 📋 Prerequisites

### **Required Components**
- ✅ Existing GigaEats database with orders, users, vendors, drivers tables
- ✅ Supabase project with RLS enabled
- ✅ Stripe integration already configured
- ✅ User profiles table with role management
- ✅ Payment transactions table (existing)

### **Verification Steps**
Before proceeding, verify these tables exist:
```sql
-- Check existing tables
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('orders', 'users', 'vendors', 'drivers', 'user_profiles', 'payment_transactions');
```

## 🚀 Installation Steps

### **Step 1: Apply Database Migration**

1. **Navigate to Supabase Dashboard**
   - Go to your GigaEats Supabase project
   - Open the SQL Editor

2. **Execute Migration**
   ```bash
   # Copy the migration file content
   cat supabase/migrations/020_create_marketplace_payment_system.sql
   ```
   
   - Paste the entire migration content into the SQL Editor
   - Click "Run" to execute
   - Verify all tables are created successfully

3. **Verify Installation**
   ```sql
   -- Check new tables
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name IN (
     'escrow_accounts', 
     'stakeholder_wallets', 
     'wallet_transactions', 
     'commission_structures', 
     'payout_requests', 
     'financial_audit_log'
   );
   ```

### **Step 2: Configure Commission Structures**

The migration includes default commission structures, but you may want to customize them:

```sql
-- View default commission structures
SELECT * FROM commission_structures WHERE is_active = true;

-- Update platform fee rate (example: change to 3%)
UPDATE commission_structures 
SET platform_fee_rate = 0.0300 
WHERE delivery_method IS NULL;

-- Add vendor-specific commission structure
INSERT INTO commission_structures (
  vendor_id,
  platform_fee_rate,
  vendor_commission_rate,
  sales_agent_commission_rate,
  delivery_method,
  is_active
) VALUES (
  'vendor-uuid-here',
  0.0400, -- 4% platform fee
  0.8800, -- 88% vendor share
  0.0300, -- 3% sales agent
  NULL,   -- All delivery methods
  true
);
```

### **Step 3: Create Initial Wallets**

Wallets are automatically created for new users, but you may need to create them for existing users:

```sql
-- Create wallets for existing users
INSERT INTO stakeholder_wallets (user_id, user_role, currency, is_active)
SELECT 
  up.user_id,
  up.role,
  'MYR',
  true
FROM user_profiles up
WHERE NOT EXISTS (
  SELECT 1 FROM stakeholder_wallets sw 
  WHERE sw.user_id = up.user_id AND sw.user_role = up.role
);
```

### **Step 4: Verify RLS Policies**

Test that Row Level Security is working correctly:

```sql
-- Test as different user roles
SET LOCAL role = 'authenticated';
SET LOCAL request.jwt.claims = '{"sub": "user-uuid", "role": "vendor"}';

-- Should only return wallets for the authenticated user
SELECT * FROM stakeholder_wallets;

-- Reset
RESET role;
```

## 🔧 Configuration

### **Environment Variables**

Add these to your Supabase Edge Functions environment:

```bash
# Stripe Configuration (existing)
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# New Payment System Configuration
MARKETPLACE_PLATFORM_FEE_RATE=0.05
MARKETPLACE_AUTO_RELEASE_DAYS=7
MARKETPLACE_MIN_PAYOUT_AMOUNT=10.00
MARKETPLACE_MAX_PAYOUT_AMOUNT=10000.00

# Bank Transfer Configuration
WISE_API_KEY=your_wise_api_key
LOCAL_BANK_API_ENDPOINT=https://api.bank.com
```

### **Commission Rate Configuration**

Customize commission rates based on your business model:

```sql
-- High-volume vendor discount
INSERT INTO commission_structures (
  vendor_id,
  platform_fee_rate,
  vendor_commission_rate,
  min_order_amount,
  effective_from,
  is_active
) VALUES (
  'high-volume-vendor-uuid',
  0.0300, -- 3% instead of 5%
  0.9000, -- 90% instead of 85%
  1000.00, -- Minimum RM 1000 monthly volume
  NOW(),
  true
);

-- Peak hour driver bonus
INSERT INTO commission_structures (
  driver_id,
  driver_commission_rate,
  fixed_delivery_fee,
  effective_from,
  effective_until,
  is_active
) VALUES (
  NULL, -- All drivers
  0.9000, -- 90% instead of 80%
  10.00, -- RM 10 instead of RM 8
  '2024-01-01 18:00:00+08', -- 6 PM
  '2024-01-01 22:00:00+08', -- 10 PM
  true
);
```

## 🧪 Testing

### **Test Payment Flow**

1. **Create Test Order**
   ```sql
   -- Insert test order
   INSERT INTO orders (
     order_number, customer_id, vendor_id, sales_agent_id,
     subtotal, delivery_fee, total_amount, status
   ) VALUES (
     'TEST-001', 'customer-uuid', 'vendor-uuid', 'agent-uuid',
     50.00, 8.00, 58.00, 'pending'
   );
   ```

2. **Simulate Payment**
   ```sql
   -- Create escrow account
   INSERT INTO escrow_accounts (
     order_id, total_amount, vendor_amount, platform_fee,
     sales_agent_commission, driver_commission, delivery_fee,
     status, release_trigger
   ) VALUES (
     'order-uuid', 58.00, 40.00, 2.90, 1.74, 6.00, 8.00,
     'held', 'order_delivered'
   );
   ```

3. **Test Fund Distribution**
   ```sql
   -- Simulate order completion and fund release
   UPDATE escrow_accounts 
   SET status = 'released', release_date = NOW()
   WHERE order_id = 'order-uuid';
   
   -- Check wallet balances
   SELECT sw.user_role, sw.available_balance 
   FROM stakeholder_wallets sw
   JOIN user_profiles up ON sw.user_id = up.user_id;
   ```

### **Test Payout Flow**

```sql
-- Create test payout request
INSERT INTO payout_requests (
  wallet_id, amount, bank_account_number, bank_name, 
  account_holder_name, status
) VALUES (
  'wallet-uuid', 100.00, '1234567890', 'Maybank', 
  'John Doe', 'pending'
);

-- Simulate payout processing
UPDATE payout_requests 
SET status = 'completed', processed_at = NOW()
WHERE id = 'payout-uuid';
```

## 🔍 Monitoring & Maintenance

### **Health Check Queries**

```sql
-- Check escrow account status
SELECT status, COUNT(*), SUM(total_amount) 
FROM escrow_accounts 
GROUP BY status;

-- Check wallet balances
SELECT user_role, COUNT(*), SUM(available_balance) 
FROM stakeholder_wallets 
GROUP BY user_role;

-- Check pending payouts
SELECT status, COUNT(*), SUM(amount) 
FROM payout_requests 
GROUP BY status;

-- Check recent audit logs
SELECT event_type, COUNT(*) 
FROM financial_audit_log 
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY event_type;
```

### **Performance Monitoring**

```sql
-- Slow query detection
SELECT query, mean_exec_time, calls 
FROM pg_stat_statements 
WHERE query LIKE '%escrow_accounts%' 
OR query LIKE '%stakeholder_wallets%'
ORDER BY mean_exec_time DESC;

-- Index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes 
WHERE tablename IN ('escrow_accounts', 'stakeholder_wallets', 'wallet_transactions')
ORDER BY idx_scan DESC;
```

## 🚨 Troubleshooting

### **Common Issues**

#### **1. Wallet Not Created for User**
```sql
-- Check if user profile exists
SELECT * FROM user_profiles WHERE user_id = 'user-uuid';

-- Manually create wallet
INSERT INTO stakeholder_wallets (user_id, user_role, currency, is_active)
VALUES ('user-uuid', 'vendor', 'MYR', true);
```

#### **2. Commission Calculation Incorrect**
```sql
-- Check active commission structures
SELECT * FROM commission_structures 
WHERE is_active = true 
AND (effective_until IS NULL OR effective_until > NOW())
ORDER BY effective_from DESC;

-- Verify commission breakdown
SELECT 
  platform_fee_rate + vendor_commission_rate + sales_agent_commission_rate as total_rate
FROM commission_structures 
WHERE id = 'structure-uuid';
```

#### **3. RLS Policy Blocking Access**
```sql
-- Check user role
SELECT role FROM user_profiles WHERE user_id = auth.uid();

-- Test policy manually
SELECT * FROM stakeholder_wallets WHERE user_id = auth.uid();
```

#### **4. Escrow Release Not Triggered**
```sql
-- Check escrow status
SELECT id, status, release_trigger, hold_until 
FROM escrow_accounts 
WHERE status = 'held' AND release_date IS NULL;

-- Manual release (admin only)
UPDATE escrow_accounts 
SET status = 'released', release_date = NOW()
WHERE id = 'escrow-uuid';
```

## 📊 Backup & Recovery

### **Critical Data Backup**
```sql
-- Backup financial tables
pg_dump -t escrow_accounts -t stakeholder_wallets -t wallet_transactions 
         -t commission_structures -t payout_requests -t financial_audit_log 
         gigaeats_db > marketplace_payment_backup.sql
```

### **Recovery Verification**
```sql
-- Verify data integrity after recovery
SELECT 
  (SELECT SUM(total_amount) FROM escrow_accounts WHERE status = 'held') as held_funds,
  (SELECT SUM(available_balance) FROM stakeholder_wallets) as wallet_balances,
  (SELECT COUNT(*) FROM wallet_transactions) as total_transactions;
```

## 🔄 Maintenance Tasks

### **Daily Tasks**
- Monitor escrow account releases
- Check failed payout requests
- Review audit logs for anomalies
- Verify wallet balance consistency

### **Weekly Tasks**
- Analyze commission distribution
- Review payout processing times
- Check system performance metrics
- Update commission structures if needed

### **Monthly Tasks**
- Generate financial reports
- Audit compliance metrics
- Review and optimize database performance
- Update documentation and procedures
