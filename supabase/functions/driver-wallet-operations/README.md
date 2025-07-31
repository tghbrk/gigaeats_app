# Driver Wallet Operations Edge Function

This Edge Function provides secure wallet operations for drivers in the GigaEats platform, including balance queries, earnings deposits, withdrawal processing, and transaction history management.

## 🔧 Function Overview

The `driver-wallet-operations` Edge Function handles all driver wallet-related operations with proper authentication, validation, and security measures.

### **Supported Actions**

| Action | Description | Required Parameters |
|--------|-------------|-------------------|
| `get_balance` | Get driver wallet balance | None |
| `process_earnings_deposit` | Deposit earnings from completed deliveries | `wallet_id`, `order_id`, `amount`, `earnings_breakdown` |
| `process_withdrawal` | Create withdrawal request | `wallet_id`, `amount`, `withdrawal_method`, `destination_details` |
| `get_transaction_history` | Get wallet transaction history | `wallet_id`, optional `pagination`, `filters` |
| `validate_withdrawal` | Validate withdrawal request | `wallet_id`, `amount` |
| `get_wallet_settings` | Get driver wallet settings | None |
| `update_wallet_settings` | Update driver wallet settings | `settings_data` |
| `get_withdrawal_requests` | Get driver withdrawal requests | Optional `pagination`, `filters` |

## 🔐 Authentication & Security

### **Authentication Requirements**
- Valid JWT token in `Authorization` header
- Driver profile must exist and be active
- Wallet ownership validation for all operations

### **Security Features**
- RLS policy enforcement
- Duplicate transaction prevention
- Withdrawal limit validation
- Driver status verification
- Comprehensive audit logging

## 📝 API Reference

### **Request Format**
```typescript
interface DriverWalletRequest {
  action: string
  wallet_id?: string
  order_id?: string
  amount?: number
  earnings_breakdown?: Record<string, any>
  withdrawal_method?: string
  destination_details?: Record<string, any>
  settings_data?: Record<string, any>
  metadata?: Record<string, any>
  pagination?: {
    limit?: number
    offset?: number
  }
  filters?: {
    transaction_type?: string
    start_date?: string
    end_date?: string
    status?: string
  }
}
```

### **Response Format**
```typescript
interface DriverWalletResponse {
  success: boolean
  data?: any
  error?: string
  timestamp: string
}
```

## 🚀 Usage Examples

### **1. Get Driver Wallet Balance**
```javascript
const response = await supabase.functions.invoke('driver-wallet-operations', {
  body: {
    action: 'get_balance'
  }
})
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "wallet-uuid",
    "available_balance": 250.75,
    "pending_balance": 0.00,
    "total_earned": 1250.00,
    "total_withdrawn": 1000.00,
    "currency": "MYR",
    "is_active": true,
    "is_verified": true
  },
  "timestamp": "2024-12-26T10:30:00.000Z"
}
```

### **2. Process Earnings Deposit**
```javascript
const response = await supabase.functions.invoke('driver-wallet-operations', {
  body: {
    action: 'process_earnings_deposit',
    wallet_id: 'wallet-uuid',
    order_id: 'order-123',
    amount: 25.50,
    earnings_breakdown: {
      base_commission: 20.00,
      completion_bonus: 5.50
    },
    metadata: {
      gross_earnings: 30.00,
      net_earnings: 25.50,
      deposit_source: 'delivery_completion'
    }
  }
})
```

**Response:**
```json
{
  "success": true,
  "data": {
    "wallet_id": "wallet-uuid",
    "new_balance": 276.25,
    "transaction_amount": 25.50
  },
  "timestamp": "2024-12-26T10:35:00.000Z"
}
```

### **3. Validate Withdrawal**
```javascript
const response = await supabase.functions.invoke('driver-wallet-operations', {
  body: {
    action: 'validate_withdrawal',
    wallet_id: 'wallet-uuid',
    amount: 100.00
  }
})
```

**Response:**
```json
{
  "success": true,
  "data": {
    "is_valid": true,
    "available_balance": 276.25,
    "minimum_amount": 10.00,
    "maximum_daily": 1000.00,
    "today_total": 0.00,
    "remaining_daily_limit": 1000.00,
    "errors": []
  },
  "timestamp": "2024-12-26T10:40:00.000Z"
}
```

### **4. Process Withdrawal Request**
```javascript
const response = await supabase.functions.invoke('driver-wallet-operations', {
  body: {
    action: 'process_withdrawal',
    wallet_id: 'wallet-uuid',
    amount: 100.00,
    withdrawal_method: 'bank_transfer',
    destination_details: {
      bank_name: 'Maybank',
      account_number: '1234567890',
      account_holder: 'John Driver'
    }
  }
})
```

**Response:**
```json
{
  "success": true,
  "data": {
    "request_id": "withdrawal-request-uuid",
    "status": "pending"
  },
  "timestamp": "2024-12-26T10:45:00.000Z"
}
```

### **5. Get Transaction History**
```javascript
const response = await supabase.functions.invoke('driver-wallet-operations', {
  body: {
    action: 'get_transaction_history',
    wallet_id: 'wallet-uuid',
    pagination: {
      limit: 20,
      offset: 0
    },
    filters: {
      transaction_type: 'delivery_earnings',
      start_date: '2024-12-01T00:00:00.000Z'
    }
  }
})
```

## 🛠️ Development & Testing

### **Local Development**
```bash
# Start Supabase locally
supabase start

# Deploy function
supabase functions deploy driver-wallet-operations

# Test function
deno test --allow-net --allow-env supabase/functions/driver-wallet-operations/test.ts
```

### **Environment Variables**
- `SUPABASE_URL`: Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key for elevated permissions

## 🔍 Error Handling

### **Common Error Responses**

**Authentication Error:**
```json
{
  "success": false,
  "error": "Unauthorized: Invalid or missing authentication token",
  "timestamp": "2024-12-26T10:50:00.000Z"
}
```

**Driver Not Found:**
```json
{
  "success": false,
  "error": "Driver profile not found",
  "timestamp": "2024-12-26T10:50:00.000Z"
}
```

**Insufficient Balance:**
```json
{
  "success": false,
  "error": "Insufficient balance for withdrawal",
  "timestamp": "2024-12-26T10:50:00.000Z"
}
```

**Duplicate Transaction:**
```json
{
  "success": true,
  "data": {
    "wallet_id": "wallet-uuid",
    "message": "Deposit already processed for this order",
    "duplicate": true
  },
  "timestamp": "2024-12-26T10:50:00.000Z"
}
```

## 📊 Monitoring & Logging

The function includes comprehensive logging for:
- All function calls with timestamps
- Authentication attempts
- Wallet operations and balance changes
- Error conditions and validation failures
- Performance metrics

## 🔒 Security Considerations

1. **Authentication**: All requests require valid JWT tokens
2. **Authorization**: RLS policies enforce data access controls
3. **Validation**: Input validation and business rule enforcement
4. **Audit Trail**: All operations are logged for compliance
5. **Rate Limiting**: Consider implementing rate limiting for production
6. **Duplicate Prevention**: Automatic duplicate transaction detection

## 🚀 Production Deployment

1. Deploy the function to Supabase
2. Run database migrations for required tables and policies
3. Configure environment variables
4. Test all endpoints with valid authentication
5. Monitor function logs and performance
6. Set up alerting for error conditions
