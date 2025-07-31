# 🔐 Bank Account Verification System

## Overview

The Bank Account Verification System provides comprehensive verification capabilities for driver bank accounts in the GigaEats platform. It implements multiple verification methods, data encryption, and compliance with Malaysian banking regulations.

## Features

- **Multiple Verification Methods**: Micro-deposit, instant verification, document verification, and manual verification
- **Malaysian IC Validation**: Comprehensive validation of Malaysian Identity Card numbers
- **Data Encryption**: End-to-end encryption for sensitive banking and identity data
- **Document Verification**: AI-powered document quality checks and face matching
- **Compliance**: Adherence to Malaysian banking and data protection regulations
- **Fraud Prevention**: Multiple security layers and verification attempts tracking

## Verification Methods

### 1. Micro Deposit Verification
```javascript
const response = await supabase.functions.invoke('bank-account-verification', {
  body: {
    action: 'initiate_verification',
    bank_details: {
      bank_name: 'Malayan Banking Berhad',
      bank_code: 'MBB',
      account_number: '1234567890123',
      account_holder_name: 'John Driver',
      account_type: 'savings'
    },
    verification_method: 'micro_deposit'
  }
})
```

### 2. Instant Verification
```javascript
const response = await supabase.functions.invoke('bank-account-verification', {
  body: {
    action: 'initiate_verification',
    bank_details: {
      bank_name: 'CIMB Bank Berhad',
      bank_code: 'CIMB',
      account_number: '7123456789012',
      account_holder_name: 'John Driver'
    },
    verification_method: 'instant_verification',
    identity_documents: {
      ic_number: '901234-12-3456'
    }
  }
})
```

### 3. Document Verification
```javascript
const response = await supabase.functions.invoke('bank-account-verification', {
  body: {
    action: 'initiate_verification',
    bank_details: {
      bank_name: 'Public Bank Berhad',
      bank_code: 'PBB',
      account_number: '3123456789012',
      account_holder_name: 'John Driver'
    },
    verification_method: 'document_verification',
    identity_documents: {
      ic_number: '901234-12-3456',
      ic_front_image: 'base64_encoded_image',
      ic_back_image: 'base64_encoded_image',
      selfie_image: 'base64_encoded_selfie'
    }
  }
})
```

### 4. Manual Verification
```javascript
const response = await supabase.functions.invoke('bank-account-verification', {
  body: {
    action: 'initiate_verification',
    bank_details: {
      bank_name: 'RHB Bank Berhad',
      bank_code: 'RHB',
      account_number: '2123456789012',
      account_holder_name: 'John Driver'
    },
    verification_method: 'manual_verification',
    identity_documents: {
      ic_number: '901234-12-3456',
      bank_statement: 'base64_encoded_statement'
    }
  }
})
```

## Supported Actions

### Initiate Verification
Start the verification process for a bank account.

### Submit Verification
Submit verification codes or amounts for completion.
```javascript
const response = await supabase.functions.invoke('bank-account-verification', {
  body: {
    action: 'submit_verification',
    account_id: 'account-uuid',
    verification_amounts: [12, 34] // For micro deposit
  }
})
```

### Get Verification Status
Check the current status of verification.
```javascript
const response = await supabase.functions.invoke('bank-account-verification', {
  body: {
    action: 'get_verification_status',
    account_id: 'account-uuid'
  }
})
```

### Resend Verification
Resend verification for failed or expired attempts.
```javascript
const response = await supabase.functions.invoke('bank-account-verification', {
  body: {
    action: 'resend_verification',
    account_id: 'account-uuid'
  }
})
```

### Verify Identity
Perform comprehensive identity verification.
```javascript
const response = await supabase.functions.invoke('bank-account-verification', {
  body: {
    action: 'verify_identity',
    account_id: 'account-uuid',
    identity_documents: {
      ic_number: '901234-12-3456',
      ic_front_image: 'base64_encoded_image',
      ic_back_image: 'base64_encoded_image',
      selfie_image: 'base64_encoded_selfie'
    }
  }
})
```

### Update Verification Documents
Update documents for pending verification.
```javascript
const response = await supabase.functions.invoke('bank-account-verification', {
  body: {
    action: 'update_verification_documents',
    account_id: 'account-uuid',
    identity_documents: {
      ic_front_image: 'new_base64_encoded_image',
      ic_back_image: 'new_base64_encoded_image'
    }
  }
})
```

## Malaysian IC Validation

The system validates Malaysian Identity Card numbers according to the format:
- **Format**: YYMMDD-SS-NNNN
- **Birth Date**: Valid date in YYMMDD format
- **State Code**: Valid Malaysian state code (01-16)
- **Serial Number**: 4-digit serial number

### Supported State Codes
- 01-02: Johor
- 03-04: Kedah
- 05-06: Kelantan
- 07-08: Malacca
- 09-10: Negeri Sembilan
- 11-12: Pahang
- 13-14: Penang
- 15-16: Perak
- And more...

## Security Features

### Data Encryption
- **AES-GCM Encryption**: All sensitive data encrypted at rest
- **Key Management**: Secure encryption key handling
- **Data Masking**: Account numbers masked in responses

### Fraud Prevention
- **Attempt Limiting**: Maximum verification attempts per method
- **Time-based Restrictions**: Cooldown periods between attempts
- **Identity Verification**: Multi-factor identity validation

### Compliance
- **Malaysian Regulations**: Compliance with Bank Negara Malaysia guidelines
- **Data Protection**: PDPA compliance for personal data handling
- **Audit Trails**: Complete verification history tracking

## Verification Workflow

1. **Initiation**: Driver submits bank details and chooses verification method
2. **Processing**: System validates details and initiates verification process
3. **Verification**: Driver completes verification (amounts, codes, documents)
4. **Review**: Automated or manual review of verification data
5. **Completion**: Account marked as verified and ready for withdrawals

## Error Handling

### Error Codes
- `UNAUTHORIZED`: Invalid authentication
- `INVALID_IC_NUMBER`: Malaysian IC validation failed
- `INVALID_BANK_DETAILS`: Bank account validation failed
- `VERIFICATION_FAILED`: Verification process failed
- `INVALID_DOCUMENT`: Document validation failed
- `NOT_FOUND`: Resource not found

### Response Format
```json
{
  "success": false,
  "error": "Invalid Malaysian IC number format",
  "error_code": "INVALID_IC_NUMBER",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## Production Integration

### Document Verification Services
- **Jumio**: Global identity verification
- **Onfido**: Document and biometric verification
- **Local Providers**: Malaysian-specific KYC services

### Banking APIs
- **Bank Negara Malaysia**: Central bank integration
- **Individual Banks**: Direct API integration
- **Payment Gateways**: Third-party verification services

### Monitoring & Analytics
- **Verification Success Rates**: Track method effectiveness
- **Fraud Detection**: Monitor suspicious patterns
- **Performance Metrics**: Response times and completion rates

## Testing

The system includes comprehensive test coverage for:
- Malaysian IC validation
- Bank account format validation
- Encryption/decryption processes
- Verification workflow scenarios
- Error handling and edge cases

## Dependencies

- Supabase client library
- Web Crypto API for encryption
- Deno standard library
- Base64 encoding/decoding utilities
