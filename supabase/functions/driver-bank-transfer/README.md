# 🏦 Driver Bank Transfer Edge Function

## Overview

The Driver Bank Transfer Edge Function provides comprehensive bank transfer processing capabilities for the GigaEats driver wallet system. It handles secure bank transfers, account verification, and compliance with Malaysian banking regulations.

## Features

- **Secure Bank Transfers**: Process withdrawals to Malaysian bank accounts
- **Bank Account Verification**: Support for micro-deposit and instant verification
- **Malaysian Banking Integration**: Support for major Malaysian banks
- **Fraud Prevention**: Daily limits, validation, and security checks
- **Audit Trail**: Complete transaction logging and status tracking
- **Real-time Status**: Track transfer progress and completion

## Supported Actions

### 1. Create Withdrawal Request
```javascript
const response = await supabase.functions.invoke('driver-bank-transfer', {
  body: {
    action: 'create_withdrawal_request',
    amount: 100.00,
    withdrawal_method: 'bank_transfer',
    bank_details: {
      bank_name: 'Malayan Banking Berhad',
      bank_code: 'MBB',
      account_number: '1234567890123',
      account_holder_name: 'John Driver',
      account_type: 'savings'
    },
    notes: 'Weekly withdrawal'
  }
})
```

### 2. Process Bank Transfer (Admin Only)
```javascript
const response = await supabase.functions.invoke('driver-bank-transfer', {
  body: {
    action: 'process_bank_transfer',
    request_id: 'withdrawal-request-uuid',
    transaction_reference: 'TXN123456'
  }
})
```

### 3. Verify Bank Account
```javascript
const response = await supabase.functions.invoke('driver-bank-transfer', {
  body: {
    action: 'verify_bank_account',
    bank_details: {
      bank_name: 'Malayan Banking Berhad',
      bank_code: 'MBB',
      account_number: '1234567890123',
      account_holder_name: 'John Driver'
    },
    verification_method: 'micro_deposit',
    verification_code: '0102' // For micro deposit verification
  }
})
```

### 4. Get Transfer Status
```javascript
const response = await supabase.functions.invoke('driver-bank-transfer', {
  body: {
    action: 'get_transfer_status',
    request_id: 'withdrawal-request-uuid'
  }
})
```

### 5. Cancel Withdrawal
```javascript
const response = await supabase.functions.invoke('driver-bank-transfer', {
  body: {
    action: 'cancel_withdrawal',
    request_id: 'withdrawal-request-uuid'
  }
})
```

### 6. Validate Bank Details
```javascript
const response = await supabase.functions.invoke('driver-bank-transfer', {
  body: {
    action: 'validate_bank_details',
    bank_details: {
      bank_name: 'Malayan Banking Berhad',
      bank_code: 'MBB',
      account_number: '1234567890123',
      account_holder_name: 'John Driver'
    }
  }
})
```

## Supported Malaysian Banks

| Bank Code | Bank Name |
|-----------|-----------|
| MBB | Malayan Banking Berhad (Maybank) |
| CIMB | CIMB Bank Berhad |
| PBB | Public Bank Berhad |
| RHB | RHB Bank Berhad |
| HLB | Hong Leong Bank Berhad |
| AMBANK | AmBank (M) Berhad |
| UOB | United Overseas Bank (Malaysia) Bhd |
| OCBC | OCBC Bank (Malaysia) Berhad |
| BSN | Bank Simpanan Nasional |
| AGRO | Agrobank |
| ISLAM | Bank Islam Malaysia Berhad |
| MUAMALAT | Bank Muamalat Malaysia Berhad |
| RAKYAT | Bank Rakyat |
| AFFIN | Affin Bank Berhad |
| ALLIANCE | Alliance Bank Malaysia Berhad |

## Bank Account Validation

### Account Number Formats
- **Maybank (MBB)**: 12 digits starting with 1 or 5
- **CIMB**: 12 digits starting with 7 or 8
- **Public Bank (PBB)**: 10-12 digits starting with 3 or 4
- **General**: 10-16 digits for other banks

### Verification Methods
1. **Micro Deposit**: Send small amounts to verify account ownership
2. **Instant Verification**: Real-time verification via bank APIs
3. **Manual Verification**: Admin-assisted verification process

## Security Features

- **Authentication**: JWT token validation for all requests
- **Authorization**: Role-based access control (drivers vs admins)
- **Data Encryption**: Sensitive bank details are encrypted
- **Fraud Prevention**: Daily withdrawal limits and validation
- **Audit Logging**: Complete transaction history and status tracking

## Error Codes

| Code | Description |
|------|-------------|
| UNAUTHORIZED | Invalid or missing authentication |
| INSUFFICIENT_BALANCE | Wallet balance too low |
| INVALID_BANK_DETAILS | Bank account validation failed |
| DAILY_LIMIT_EXCEEDED | Daily withdrawal limit reached |
| NOT_FOUND | Resource not found |
| UNKNOWN_ERROR | Unexpected error occurred |

## Response Format

### Success Response
```json
{
  "success": true,
  "data": {
    "request_id": "uuid",
    "status": "pending",
    "amount": 100.00,
    "net_amount": 99.00,
    "processing_fee": 1.00
  },
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### Error Response
```json
{
  "success": false,
  "error": "Insufficient wallet balance",
  "error_code": "INSUFFICIENT_BALANCE",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## Integration Notes

### Production Considerations
1. **Payment Gateway Integration**: Replace mock implementations with real Malaysian payment gateways
2. **Bank API Integration**: Connect to actual bank APIs for verification and transfers
3. **Encryption**: Implement proper encryption for sensitive data
4. **Monitoring**: Add comprehensive logging and monitoring
5. **Rate Limiting**: Implement API rate limiting for security

### Malaysian Banking Compliance
- Follow Bank Negara Malaysia (BNM) guidelines
- Implement proper KYC (Know Your Customer) procedures
- Ensure data protection compliance (PDPA)
- Maintain transaction records as required by law

## Testing

Use the provided test cases to validate functionality:
- Valid withdrawal requests
- Invalid bank details
- Insufficient balance scenarios
- Daily limit validations
- Account verification flows

## Dependencies

- Supabase client library
- Deno standard library
- Crypto API for hashing and encryption
