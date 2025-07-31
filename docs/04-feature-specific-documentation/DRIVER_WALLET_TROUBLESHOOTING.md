# 🚗💰 GigaEats Driver Wallet System - Troubleshooting Guide

## 🎯 Overview

This comprehensive troubleshooting guide helps diagnose and resolve common issues with the GigaEats Driver Wallet System. Issues are organized by category with step-by-step resolution procedures.

## 🔍 Quick Diagnosis

### **Symptom Checker**

| Symptom | Likely Cause | Quick Fix |
|---------|--------------|-----------|
| Wallet not loading | Network/Auth issue | Check connection, re-login |
| Earnings not appearing | Processing delay | Wait 5 minutes, check order status |
| Withdrawal failed | Insufficient balance/Invalid details | Check balance, verify account info |
| Notifications not working | Permission/Settings issue | Check app permissions |
| Balance incorrect | Sync issue | Force refresh, check transaction history |

## 💰 Wallet Loading Issues

### **Problem: Wallet Not Loading**

**Symptoms:**
- Wallet screen shows loading spinner indefinitely
- "Failed to load wallet" error message
- Blank wallet screen

**Diagnosis Steps:**

1. **Check Network Connection**
   ```bash
   # Test Supabase connectivity
   curl -I https://abknoalhfltlhhdbclpv.supabase.co/rest/v1/
   # Expected: 200 OK
   ```

2. **Verify Authentication**
   ```dart
   // Check auth state in Flutter
   final user = Supabase.instance.client.auth.currentUser;
   print('User: ${user?.id}');
   print('Role: ${user?.userMetadata?['role']}');
   ```

3. **Check Database Connectivity**
   ```sql
   -- Test database access
   SELECT 1 FROM driver_wallets LIMIT 1;
   ```

**Resolution Steps:**

1. **Force App Refresh**
   - Pull down on wallet screen to refresh
   - Or restart the app completely

2. **Clear App Cache**
   ```bash
   # Android
   adb shell pm clear com.gigaeats.app
   
   # iOS
   # Delete and reinstall app
   ```

3. **Re-authenticate**
   - Log out and log back in
   - Verify driver role is correctly assigned

4. **Check RLS Policies**
   ```sql
   -- Verify driver can access their wallet
   SELECT * FROM driver_wallets 
   WHERE driver_id = auth.uid()::text;
   ```

### **Problem: Wallet Balance Incorrect**

**Symptoms:**
- Balance doesn't match expected amount
- Recent transactions not reflected
- Negative balance showing

**Diagnosis Steps:**

1. **Check Transaction History**
   ```sql
   SELECT * FROM driver_wallet_transactions 
   WHERE driver_id = $1 
   ORDER BY created_at DESC 
   LIMIT 10;
   ```

2. **Verify Balance Calculation**
   ```sql
   SELECT 
     SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as total_credits,
     SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END) as total_debits,
     SUM(amount) as calculated_balance
   FROM driver_wallet_transactions 
   WHERE driver_id = $1;
   ```

3. **Check for Pending Transactions**
   ```sql
   SELECT * FROM driver_wallet_transactions 
   WHERE driver_id = $1 
   AND status = 'pending';
   ```

**Resolution Steps:**

1. **Force Balance Recalculation**
   ```sql
   -- Recalculate and update balance
   UPDATE driver_wallets 
   SET available_balance = (
     SELECT COALESCE(SUM(amount), 0) 
     FROM driver_wallet_transactions 
     WHERE driver_id = driver_wallets.driver_id 
     AND status = 'completed'
   )
   WHERE driver_id = $1;
   ```

2. **Sync Real-time Subscriptions**
   ```dart
   // Restart real-time subscriptions
   await ref.read(driverWalletRealtimeProvider.notifier).restartSubscriptions();
   ```

## 📈 Earnings Processing Issues

### **Problem: Earnings Not Deposited**

**Symptoms:**
- Completed delivery but no earnings in wallet
- Earnings notification not received
- Order shows completed but wallet unchanged

**Diagnosis Steps:**

1. **Check Order Status**
   ```sql
   SELECT status, driver_id, total_amount, created_at 
   FROM orders 
   WHERE id = $1;
   ```

2. **Check Earnings Processing**
   ```sql
   SELECT * FROM driver_wallet_transactions 
   WHERE reference_id = $1 
   AND reference_type = 'order';
   ```

3. **Check Edge Function Logs**
   ```bash
   # View Edge Function logs
   supabase functions logs driver-wallet-operations \
     --project-ref abknoalhfltlhhdbclpv
   ```

**Resolution Steps:**

1. **Manual Earnings Processing**
   ```bash
   # Trigger manual earnings processing
   curl -X POST \
     'https://abknoalhfltlhhdbclpv.supabase.co/functions/v1/driver-wallet-operations' \
     -H 'Authorization: Bearer <driver_token>' \
     -H 'Content-Type: application/json' \
     -d '{
       "action": "process_earnings_deposit",
       "order_id": "order_123",
       "amount": 25.50,
       "earnings_breakdown": {...}
     }'
   ```

2. **Check Retry Queue**
   ```sql
   SELECT * FROM wallet_deposit_retry_queue 
   WHERE order_id = $1;
   ```

3. **Verify Driver Wallet Exists**
   ```sql
   SELECT * FROM driver_wallets 
   WHERE driver_id = $1 
   AND is_active = true;
   ```

### **Problem: Duplicate Earnings**

**Symptoms:**
- Same order earnings deposited multiple times
- Balance higher than expected
- Duplicate transactions in history

**Diagnosis Steps:**

1. **Check for Duplicate Transactions**
   ```sql
   SELECT reference_id, COUNT(*) 
   FROM driver_wallet_transactions 
   WHERE driver_id = $1 
   AND reference_type = 'order'
   GROUP BY reference_id 
   HAVING COUNT(*) > 1;
   ```

2. **Check Processing Timestamps**
   ```sql
   SELECT * FROM driver_wallet_transactions 
   WHERE reference_id = $1 
   ORDER BY created_at;
   ```

**Resolution Steps:**

1. **Remove Duplicate Transactions**
   ```sql
   -- Keep only the first transaction for each order
   DELETE FROM driver_wallet_transactions 
   WHERE id NOT IN (
     SELECT MIN(id) 
     FROM driver_wallet_transactions 
     WHERE driver_id = $1 
     GROUP BY reference_id
   );
   ```

2. **Recalculate Balance**
   ```sql
   UPDATE driver_wallets 
   SET available_balance = (
     SELECT SUM(amount) 
     FROM driver_wallet_transactions 
     WHERE driver_id = driver_wallets.driver_id
   )
   WHERE driver_id = $1;
   ```

## 💸 Withdrawal Issues

### **Problem: Withdrawal Request Failed**

**Symptoms:**
- "Withdrawal failed" error message
- Request stuck in "processing" status
- Money not transferred to account

**Diagnosis Steps:**

1. **Check Withdrawal Status**
   ```sql
   SELECT * FROM driver_withdrawal_requests 
   WHERE driver_id = $1 
   ORDER BY created_at DESC;
   ```

2. **Verify Account Details**
   ```sql
   SELECT destination_details 
   FROM driver_withdrawal_requests 
   WHERE id = $1;
   ```

3. **Check Available Balance**
   ```sql
   SELECT available_balance 
   FROM driver_wallets 
   WHERE driver_id = $1;
   ```

**Resolution Steps:**

1. **Retry Withdrawal Processing**
   ```bash
   # Retry failed withdrawal
   curl -X POST \
     'https://abknoalhfltlhhdbclpv.supabase.co/functions/v1/driver-wallet-operations' \
     -H 'Authorization: Bearer <admin_token>' \
     -H 'Content-Type: application/json' \
     -d '{
       "action": "retry_withdrawal",
       "withdrawal_id": "wd_123"
     }'
   ```

2. **Update Withdrawal Status**
   ```sql
   UPDATE driver_withdrawal_requests 
   SET status = 'failed',
       failure_reason = 'Invalid account details'
   WHERE id = $1;
   ```

3. **Refund to Wallet**
   ```sql
   -- If withdrawal failed, refund amount to wallet
   UPDATE driver_wallets 
   SET available_balance = available_balance + $2
   WHERE driver_id = $1;
   ```

### **Problem: Withdrawal Limits Exceeded**

**Symptoms:**
- "Daily limit exceeded" error
- "Monthly limit exceeded" error
- Cannot submit withdrawal request

**Diagnosis Steps:**

1. **Check Daily Withdrawals**
   ```sql
   SELECT SUM(amount) as daily_total
   FROM driver_withdrawal_requests 
   WHERE driver_id = $1 
   AND DATE(created_at) = CURRENT_DATE
   AND status IN ('completed', 'processing');
   ```

2. **Check Monthly Withdrawals**
   ```sql
   SELECT SUM(amount) as monthly_total
   FROM driver_withdrawal_requests 
   WHERE driver_id = $1 
   AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
   AND status IN ('completed', 'processing');
   ```

**Resolution Steps:**

1. **Wait for Limit Reset**
   - Daily limits reset at midnight
   - Monthly limits reset on the 1st of each month

2. **Request Limit Increase** (Admin only)
   ```sql
   UPDATE driver_profiles 
   SET withdrawal_daily_limit = 5000,
       withdrawal_monthly_limit = 50000
   WHERE driver_id = $1;
   ```

## 🔔 Notification Issues

### **Problem: Notifications Not Received**

**Symptoms:**
- No earnings notifications
- Missing withdrawal updates
- Low balance alerts not working

**Diagnosis Steps:**

1. **Check Notification Permissions**
   ```dart
   // Check app notification permissions
   final permission = await Permission.notification.status;
   print('Notification permission: $permission');
   ```

2. **Check Notification Settings**
   ```sql
   SELECT notification_preferences 
   FROM driver_profiles 
   WHERE driver_id = $1;
   ```

3. **Check Notification History**
   ```sql
   SELECT * FROM notifications 
   WHERE recipient_id = $1 
   ORDER BY created_at DESC 
   LIMIT 10;
   ```

**Resolution Steps:**

1. **Enable Notifications**
   ```dart
   // Request notification permission
   await Permission.notification.request();
   ```

2. **Update Notification Preferences**
   ```sql
   UPDATE driver_profiles 
   SET notification_preferences = jsonb_set(
     notification_preferences,
     '{earnings_notifications}',
     'true'
   )
   WHERE driver_id = $1;
   ```

3. **Test Notification Delivery**
   ```bash
   # Send test notification
   curl -X POST \
     'https://abknoalhfltlhhdbclpv.supabase.co/functions/v1/driver-wallet-notifications' \
     -H 'Authorization: Bearer <admin_token>' \
     -H 'Content-Type: application/json' \
     -d '{
       "action": "send_test_notification",
       "driver_id": "driver_123"
     }'
   ```

## 🔄 Real-time Sync Issues

### **Problem: Real-time Updates Not Working**

**Symptoms:**
- Balance not updating automatically
- New transactions not appearing
- Manual refresh required

**Diagnosis Steps:**

1. **Check Subscription Status**
   ```dart
   final realtimeStatus = ref.read(driverWalletRealtimeProvider);
   print('Real-time status: $realtimeStatus');
   ```

2. **Check Network Connectivity**
   ```dart
   final connectivity = await Connectivity().checkConnectivity();
   print('Network status: $connectivity');
   ```

3. **Check Supabase Connection**
   ```dart
   final client = Supabase.instance.client;
   print('Supabase status: ${client.realtime.isConnected}');
   ```

**Resolution Steps:**

1. **Restart Real-time Subscriptions**
   ```dart
   await ref.read(driverWalletRealtimeProvider.notifier).restartSubscriptions();
   ```

2. **Check Subscription Filters**
   ```dart
   // Verify subscription filter
   final subscription = supabase
     .channel('driver-wallet-updates')
     .on('postgres_changes', {
       'event': 'UPDATE',
       'schema': 'public',
       'table': 'driver_wallets',
       'filter': 'driver_id=eq.$driverId'
     }, (payload) => {
       // Handle update
     });
   ```

## 🛠️ Development & Testing Issues

### **Problem: Integration Tests Failing**

**Symptoms:**
- Test suite failures
- Mock service errors
- Provider state issues

**Diagnosis Steps:**

1. **Run Specific Test**
   ```bash
   flutter test test/integration/driver_wallet_system_integration_test.dart \
     --name "should complete full earnings-to-wallet-to-notification flow"
   ```

2. **Check Mock Setup**
   ```dart
   // Verify mock configuration
   when(mockWalletService.getDriverWallet())
     .thenAnswer((_) async => testWallet);
   ```

**Resolution Steps:**

1. **Reset Test Environment**
   ```bash
   flutter clean
   flutter pub get
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

2. **Update Test Data**
   ```dart
   final testWallet = DriverWallet(
     id: 'test-wallet-${DateTime.now().millisecondsSinceEpoch}',
     // ... other properties
   );
   ```

## 📞 Escalation Procedures

### **When to Escalate**

Escalate to Level 2 support if:
- Issue affects >10 drivers
- Security concern identified
- Data corruption suspected
- Resolution time >2 hours

### **Escalation Contacts**

- **Level 1**: Development team (response: 15 minutes)
- **Level 2**: Technical lead (response: 30 minutes)
- **Level 3**: CTO (response: 1 hour)

### **Information to Include**

- Driver ID(s) affected
- Error messages and screenshots
- Steps to reproduce
- Impact assessment
- Attempted resolution steps

---

*This troubleshooting guide covers the most common issues with the GigaEats Driver Wallet System. For issues not covered here, contact the development team with detailed information about the problem.*
