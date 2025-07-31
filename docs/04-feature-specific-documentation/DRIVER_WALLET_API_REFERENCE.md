# 🚗💰 GigaEats Driver Wallet System - API Reference

## 🎯 Overview

This document provides comprehensive API reference for the GigaEats Driver Wallet System, including Edge Functions, database operations, and integration endpoints.

## 🔧 Edge Functions

### **driver-wallet-operations**

Primary Edge Function for all driver wallet operations.

**Base URL:** `https://abknoalhfltlhhdbclpv.supabase.co/functions/v1/driver-wallet-operations`

#### **Health Check**

Check Edge Function availability and status.

```typescript
POST /driver-wallet-operations
Content-Type: application/json
Authorization: Bearer <supabase_anon_key>

{
  "action": "health_check"
}
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0"
}
```

#### **Get Driver Wallet**

Retrieve driver wallet information with balance and settings.

```typescript
POST /driver-wallet-operations
Content-Type: application/json
Authorization: Bearer <user_jwt_token>

{
  "action": "get_driver_wallet"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "wallet_123",
    "user_id": "driver_456",
    "driver_id": "driver_456",
    "available_balance": 150.75,
    "pending_balance": 25.00,
    "total_earned": 1250.50,
    "total_withdrawn": 1100.00,
    "currency": "MYR",
    "is_active": true,
    "is_verified": true,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

#### **Process Earnings Deposit**

Deposit earnings from completed delivery into driver wallet.

```typescript
POST /driver-wallet-operations
Content-Type: application/json
Authorization: Bearer <user_jwt_token>

{
  "action": "process_earnings_deposit",
  "wallet_id": "wallet_123",
  "order_id": "order_789",
  "amount": 25.50,
  "earnings_breakdown": {
    "base_commission": 20.00,
    "tip": 5.50,
    "distance_bonus": 2.00,
    "platform_fee": -2.00
  },
  "metadata": {
    "gross_earnings": 27.50,
    "net_earnings": 25.50,
    "deposit_source": "delivery_completion",
    "processed_at": "2024-01-15T10:30:00Z"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "transaction_id": "txn_abc123",
    "wallet_id": "wallet_123",
    "amount": 25.50,
    "new_balance": 176.25,
    "processed_at": "2024-01-15T10:30:00Z"
  }
}
```

#### **Process Withdrawal Request**

Create and process driver withdrawal request.

```typescript
POST /driver-wallet-operations
Content-Type: application/json
Authorization: Bearer <user_jwt_token>

{
  "action": "process_withdrawal_request",
  "wallet_id": "wallet_123",
  "amount": 100.00,
  "withdrawal_method": "bank_transfer",
  "destination_details": {
    "bank_name": "Maybank",
    "account_number": "1234567890",
    "account_holder": "John Doe Driver"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "withdrawal_id": "wd_xyz789",
    "wallet_id": "wallet_123",
    "amount": 100.00,
    "status": "processing",
    "estimated_completion": "2024-01-16T10:30:00Z",
    "processing_fee": 2.50
  }
}
```

#### **Get Transaction History**

Retrieve paginated transaction history with filtering.

```typescript
POST /driver-wallet-operations
Content-Type: application/json
Authorization: Bearer <user_jwt_token>

{
  "action": "get_transaction_history",
  "wallet_id": "wallet_123",
  "filters": {
    "transaction_type": "delivery_earnings",
    "date_from": "2024-01-01",
    "date_to": "2024-01-15",
    "status": "completed"
  },
  "pagination": {
    "page": 1,
    "limit": 20
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "transactions": [
      {
        "id": "txn_abc123",
        "transaction_type": "delivery_earnings",
        "amount": 25.50,
        "currency": "MYR",
        "balance_before": 150.75,
        "balance_after": 176.25,
        "reference_type": "order",
        "reference_id": "order_789",
        "description": "Delivery earnings for order #789",
        "metadata": {
          "earnings_breakdown": {
            "base_commission": 20.00,
            "tip": 5.50
          }
        },
        "status": "completed",
        "created_at": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 45,
      "total_pages": 3
    }
  }
}
```

#### **Update Withdrawal Status**

Update withdrawal request status (admin/system use).

```typescript
POST /driver-wallet-operations
Content-Type: application/json
Authorization: Bearer <admin_jwt_token>

{
  "action": "update_withdrawal_status",
  "withdrawal_id": "wd_xyz789",
  "status": "completed",
  "completion_details": {
    "transaction_reference": "bank_ref_123",
    "completed_at": "2024-01-16T09:15:00Z",
    "processing_notes": "Transfer completed successfully"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "withdrawal_id": "wd_xyz789",
    "status": "completed",
    "updated_at": "2024-01-16T09:15:00Z"
  }
}
```

## 📊 Database Operations

### **Direct Database Queries**

For real-time subscriptions and read operations.

#### **Driver Wallets Table**

```sql
-- Get driver wallet
SELECT * FROM driver_wallets 
WHERE driver_id = $1 AND is_active = true;

-- Update wallet balance
UPDATE driver_wallets 
SET available_balance = available_balance + $1,
    total_earned = total_earned + $1,
    updated_at = NOW()
WHERE driver_id = $2;
```

#### **Driver Wallet Transactions Table**

```sql
-- Get transaction history with pagination
SELECT * FROM driver_wallet_transactions 
WHERE driver_id = $1 
ORDER BY created_at DESC 
LIMIT $2 OFFSET $3;

-- Get transactions by type
SELECT * FROM driver_wallet_transactions 
WHERE driver_id = $1 
AND transaction_type = $2 
AND created_at >= $3;
```

#### **Driver Withdrawal Requests Table**

```sql
-- Get pending withdrawals
SELECT * FROM driver_withdrawal_requests 
WHERE driver_id = $1 
AND status = 'pending' 
ORDER BY created_at DESC;

-- Update withdrawal status
UPDATE driver_withdrawal_requests 
SET status = $1, 
    updated_at = NOW() 
WHERE id = $2 AND driver_id = $3;
```

## 🔔 Real-time Subscriptions

### **Wallet Balance Updates**

Subscribe to real-time wallet balance changes.

```typescript
const walletSubscription = supabase
  .channel('driver-wallet-updates')
  .on(
    'postgres_changes',
    {
      event: 'UPDATE',
      schema: 'public',
      table: 'driver_wallets',
      filter: `driver_id=eq.${driverId}`
    },
    (payload) => {
      console.log('Wallet updated:', payload.new);
      // Update UI with new balance
    }
  )
  .subscribe();
```

### **Transaction Updates**

Subscribe to new transactions.

```typescript
const transactionSubscription = supabase
  .channel('driver-transaction-updates')
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'driver_wallet_transactions',
      filter: `driver_id=eq.${driverId}`
    },
    (payload) => {
      console.log('New transaction:', payload.new);
      // Update transaction history
    }
  )
  .subscribe();
```

### **Withdrawal Status Updates**

Subscribe to withdrawal status changes.

```typescript
const withdrawalSubscription = supabase
  .channel('driver-withdrawal-updates')
  .on(
    'postgres_changes',
    {
      event: 'UPDATE',
      schema: 'public',
      table: 'driver_withdrawal_requests',
      filter: `driver_id=eq.${driverId}`
    },
    (payload) => {
      console.log('Withdrawal updated:', payload.new);
      // Update withdrawal status
    }
  )
  .subscribe();
```

## 🔒 Authentication & Security

### **Authentication Requirements**

All API calls require proper authentication:

```typescript
// User JWT token for driver operations
Authorization: Bearer <user_jwt_token>

// Admin JWT token for admin operations
Authorization: Bearer <admin_jwt_token>

// Supabase anon key for health checks
Authorization: Bearer <supabase_anon_key>
```

### **RLS Policy Enforcement**

All database operations are protected by Row Level Security policies:

- **Drivers**: Can only access their own wallet data
- **Admins**: Can access all wallet data for management
- **System**: Can perform automated operations with service role

### **Input Validation**

All inputs are validated for:
- **Data Types**: Correct types for all parameters
- **Range Validation**: Amounts within acceptable ranges
- **Format Validation**: Proper format for account numbers, etc.
- **Business Rules**: Compliance with business logic constraints

## ❌ Error Handling

### **Error Response Format**

```json
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_BALANCE",
    "message": "Insufficient wallet balance for withdrawal",
    "details": {
      "requested_amount": 100.00,
      "available_balance": 75.50,
      "shortfall": 24.50
    }
  }
}
```

### **Common Error Codes**

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `WALLET_NOT_FOUND` | Driver wallet not found | 404 |
| `INSUFFICIENT_BALANCE` | Insufficient wallet balance | 400 |
| `INVALID_AMOUNT` | Invalid transaction amount | 400 |
| `WITHDRAWAL_LIMIT_EXCEEDED` | Daily/monthly withdrawal limit exceeded | 400 |
| `UNAUTHORIZED_ACCESS` | User not authorized for operation | 403 |
| `PROCESSING_ERROR` | Transaction processing failed | 500 |
| `VALIDATION_ERROR` | Input validation failed | 400 |

## 📈 Rate Limiting

### **API Rate Limits**

- **Standard Operations**: 100 requests per minute per user
- **Withdrawal Requests**: 10 requests per hour per user
- **Transaction History**: 50 requests per minute per user
- **Health Checks**: 1000 requests per minute (global)

### **Rate Limit Headers**

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642248600
```

## 🧪 Testing

### **Test Environment**

- **Base URL**: `https://test-abknoalhfltlhhdbclpv.supabase.co/functions/v1/`
- **Test Driver ID**: `test-driver-123`
- **Test Wallet ID**: `test-wallet-456`

### **Sample Test Requests**

See [Integration Testing Guide](../testing/DRIVER_WALLET_INTEGRATION_TESTING_GUIDE.md) for comprehensive test scenarios and examples.

---

*This API reference is part of the GigaEats Driver Wallet System documentation. For implementation examples, see the integration guide.*
