# 💰 Withdrawal Request Management System

## Overview

The Withdrawal Request Management System provides comprehensive backend functionality for managing driver withdrawal requests in the GigaEats platform. It includes advanced fraud detection, status tracking, daily limits enforcement, and administrative controls.

## Features

- **Complete Request Lifecycle**: Create, update, approve, reject, and cancel withdrawal requests
- **Advanced Fraud Detection**: Multi-layer fraud detection with risk scoring
- **Status Tracking**: Comprehensive status management with audit trails
- **Daily Limits**: Configurable withdrawal limits with real-time enforcement
- **Batch Processing**: Administrative batch operations for efficiency
- **Analytics & Reporting**: Detailed withdrawal analytics and performance metrics
- **Role-based Access**: Driver and admin access controls

## Supported Actions

### 1. Create Withdrawal Request
```javascript
const response = await supabase.functions.invoke('withdrawal-request-management', {
  body: {
    action: 'create_request',
    amount: 150.00,
    withdrawal_method: 'bank_transfer',
    bank_account_id: 'account-uuid',
    notes: 'Weekly withdrawal'
  }
})
```

### 2. Update Request Status (Admin)
```javascript
const response = await supabase.functions.invoke('withdrawal-request-management', {
  body: {
    action: 'update_status',
    request_id: 'request-uuid',
    new_status: 'processing',
    admin_notes: 'Approved for processing',
    transaction_reference: 'TXN123456'
  }
})
```

### 3. Get Withdrawal Requests
```javascript
const response = await supabase.functions.invoke('withdrawal-request-management', {
  body: {
    action: 'get_requests',
    filters: {
      status: 'pending',
      start_date: '2024-01-01T00:00:00Z',
      end_date: '2024-01-31T23:59:59Z'
    },
    pagination: {
      page: 1,
      limit: 20,
      sort_by: 'requested_at',
      sort_order: 'desc'
    }
  }
})
```

### 4. Get Request Details
```javascript
const response = await supabase.functions.invoke('withdrawal-request-management', {
  body: {
    action: 'get_request_details',
    request_id: 'request-uuid'
  }
})
```

### 5. Cancel Request (Driver)
```javascript
const response = await supabase.functions.invoke('withdrawal-request-management', {
  body: {
    action: 'cancel_request',
    request_id: 'request-uuid',
    notes: 'Changed my mind'
  }
})
```

### 6. Approve Request (Admin)
```javascript
const response = await supabase.functions.invoke('withdrawal-request-management', {
  body: {
    action: 'approve_request',
    request_id: 'request-uuid',
    admin_notes: 'Verified and approved',
    transaction_reference: 'TXN123456'
  }
})
```

### 7. Reject Request (Admin)
```javascript
const response = await supabase.functions.invoke('withdrawal-request-management', {
  body: {
    action: 'reject_request',
    request_id: 'request-uuid',
    admin_notes: 'Insufficient documentation',
    failure_reason: 'Missing bank verification'
  }
})
```

### 8. Batch Processing (Admin)
```javascript
const response = await supabase.functions.invoke('withdrawal-request-management', {
  body: {
    action: 'process_batch',
    request_ids: ['req1-uuid', 'req2-uuid', 'req3-uuid'],
    batch_action: 'approve',
    admin_notes: 'Batch approval for verified requests'
  }
})
```

### 9. Get Withdrawal Limits
```javascript
const response = await supabase.functions.invoke('withdrawal-request-management', {
  body: {
    action: 'get_limits'
  }
})
```

### 10. Update Limits (Admin)
```javascript
const response = await supabase.functions.invoke('withdrawal-request-management', {
  body: {
    action: 'update_limits',
    limit_type: 'daily',
    limit_amount: 1500.00,
    filters: {
      driver_id: 'driver-uuid'
    }
  }
})
```

### 11. Check Fraud Score
```javascript
const response = await supabase.functions.invoke('withdrawal-request-management', {
  body: {
    action: 'check_fraud_score',
    amount: 500.00,
    withdrawal_method: 'bank_transfer'
  }
})
```

### 12. Get Analytics (Admin)
```javascript
const response = await supabase.functions.invoke('withdrawal-request-management', {
  body: {
    action: 'get_analytics',
    filters: {
      start_date: '2024-01-01T00:00:00Z',
      end_date: '2024-01-31T23:59:59Z'
    }
  }
})
```

## Fraud Detection System

### Detection Criteria
1. **High Amount Threshold**: Requests above RM 1,000
2. **Rapid Requests**: 5+ requests within 1 hour
3. **Suspicious Patterns**: 3+ similar amounts recently
4. **Daily Limit Check**: Exceeding daily request limits
5. **Velocity Check**: High total amount in 24 hours

### Risk Scoring
- **Low Risk**: Score 0-49 (Green light)
- **Medium Risk**: Score 50-79 (Review required)
- **High Risk**: Score 80+ (Blocked/Manual review)

### Fraud Response
```json
{
  "score": 45,
  "risk_level": "low",
  "checks": {
    "high_amount": false,
    "rapid_requests": false,
    "suspicious_pattern": true,
    "velocity_check": false,
    "daily_limit_check": false
  },
  "reason": "3 similar amounts recently"
}
```

## Status Workflow

### Status Transitions
- **pending** → processing, cancelled, failed
- **processing** → completed, failed
- **completed** → (final state)
- **failed** → pending (retry allowed)
- **cancelled** → (final state)

### Status Descriptions
- **pending**: Awaiting admin approval
- **processing**: Approved and being processed
- **completed**: Successfully transferred
- **failed**: Transfer failed or rejected
- **cancelled**: Cancelled by user or admin

## Withdrawal Limits

### Default Limits
- **Daily**: RM 1,000
- **Weekly**: RM 5,000
- **Monthly**: RM 20,000

### Configurable Settings
- Minimum withdrawal amount
- Maximum daily withdrawal
- Auto-payout threshold
- Risk-based limit adjustments

## Access Control

### Driver Permissions
- Create withdrawal requests
- View own requests
- Cancel pending requests
- Check own limits and fraud scores

### Admin Permissions
- View all requests
- Update request status
- Approve/reject requests
- Batch processing
- Update limits
- View analytics

## Analytics & Reporting

### Available Metrics
- Total requests and amounts
- Success/failure rates
- Processing times
- Fraud statistics
- Method distribution
- Performance trends

### Sample Analytics Response
```json
{
  "totals": {
    "total_requests": 150,
    "total_amount": 45000.00,
    "completed_requests": 135,
    "success_rate": 90.0
  },
  "performance": {
    "average_processing_time_hours": 2.5,
    "requests_per_day": 5.0
  },
  "fraud_analytics": {
    "high_risk_requests": 3,
    "average_fraud_score": 25.5
  }
}
```

## Error Handling

### Error Codes
- `UNAUTHORIZED`: Invalid authentication
- `INSUFFICIENT_BALANCE`: Wallet balance too low
- `LIMIT_EXCEEDED`: Daily/weekly/monthly limit exceeded
- `FRAUD_DETECTED`: High fraud risk detected
- `INVALID_STATUS`: Invalid status transition
- `NOT_FOUND`: Resource not found

### Error Response Format
```json
{
  "success": false,
  "error": "Daily withdrawal limit exceeded",
  "error_code": "LIMIT_EXCEEDED",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## Integration Notes

### Database Dependencies
- `driver_withdrawal_requests` table
- `driver_withdrawal_limits` table
- `driver_wallet_settings` table
- `stakeholder_wallets` table
- `wallet_transactions` table

### Required Functions
- `process_withdrawal_request()`
- `update_withdrawal_status()`
- `validate_withdrawal_request()`

### Security Considerations
- JWT authentication required
- Role-based access control
- Sensitive data masking
- Audit trail logging
- Fraud detection integration

## Testing

The system includes comprehensive test coverage for:
- Request creation and validation
- Status transitions and workflows
- Fraud detection scenarios
- Limit enforcement
- Batch processing operations
- Analytics calculations

## Dependencies

- Supabase client library
- Deno standard library
- Database functions and triggers
- Authentication middleware
