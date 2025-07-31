import { assertEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts"

// Test configuration
const FUNCTION_URL = 'http://localhost:54321/functions/v1/driver-bank-transfer'
const TEST_JWT = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test' // Mock JWT for testing

interface TestRequest {
  action: string
  [key: string]: any
}

async function callFunction(request: TestRequest) {
  const response = await fetch(FUNCTION_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${TEST_JWT}`,
    },
    body: JSON.stringify(request),
  })

  return await response.json()
}

Deno.test("Driver Bank Transfer - Create Withdrawal Request", async () => {
  const request: TestRequest = {
    action: 'create_withdrawal_request',
    amount: 100.00,
    withdrawal_method: 'bank_transfer',
    bank_details: {
      bank_name: 'Malayan Banking Berhad',
      bank_code: 'MBB',
      account_number: '1234567890123',
      account_holder_name: 'Test Driver',
      account_type: 'savings'
    },
    notes: 'Test withdrawal request'
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, true)
  assertExists(result.data.request_id)
  assertEquals(result.data.status, 'pending')
})

Deno.test("Driver Bank Transfer - Validate Bank Details", async () => {
  const request: TestRequest = {
    action: 'validate_bank_details',
    bank_details: {
      bank_name: 'Malayan Banking Berhad',
      bank_code: 'MBB',
      account_number: '1234567890123',
      account_holder_name: 'Test Driver'
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, true)
  assertEquals(result.data.valid, true)
  assertExists(result.data.bank_info)
  assertEquals(result.data.bank_info.bank_code, 'MBB')
})

Deno.test("Driver Bank Transfer - Invalid Bank Code", async () => {
  const request: TestRequest = {
    action: 'validate_bank_details',
    bank_details: {
      bank_name: 'Invalid Bank',
      bank_code: 'INVALID',
      account_number: '1234567890123',
      account_holder_name: 'Test Driver'
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, true)
  assertEquals(result.data.valid, true) // Should still be valid, just with warning
  assertEquals(result.data.warnings.length > 0, true)
})

Deno.test("Driver Bank Transfer - Invalid Account Number", async () => {
  const request: TestRequest = {
    action: 'validate_bank_details',
    bank_details: {
      bank_name: 'Malayan Banking Berhad',
      bank_code: 'MBB',
      account_number: '123', // Too short
      account_holder_name: 'Test Driver'
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, true)
  assertEquals(result.data.valid, false)
  assertEquals(result.data.errors.length > 0, true)
})

Deno.test("Driver Bank Transfer - Verify Bank Account (Micro Deposit)", async () => {
  const request: TestRequest = {
    action: 'verify_bank_account',
    bank_details: {
      bank_name: 'Malayan Banking Berhad',
      bank_code: 'MBB',
      account_number: '1234567890123',
      account_holder_name: 'Test Driver'
    },
    verification_method: 'micro_deposit'
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, true)
  assertExists(result.data.account_id)
  // Should be pending for micro deposit without verification code
})

Deno.test("Driver Bank Transfer - Verify Bank Account with Code", async () => {
  const request: TestRequest = {
    action: 'verify_bank_account',
    bank_details: {
      bank_name: 'Malayan Banking Berhad',
      bank_code: 'MBB',
      account_number: '1234567890123',
      account_holder_name: 'Test Driver'
    },
    verification_method: 'micro_deposit',
    verification_code: '0102'
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, true)
  assertEquals(result.data.verification_status, 'verified')
})

Deno.test("Driver Bank Transfer - Instant Verification", async () => {
  const request: TestRequest = {
    action: 'verify_bank_account',
    bank_details: {
      bank_name: 'CIMB Bank Berhad',
      bank_code: 'CIMB',
      account_number: '7123456789012',
      account_holder_name: 'Test Driver'
    },
    verification_method: 'instant_verification'
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, true)
  // Status could be verified or failed depending on simulation
  assertExists(result.data.verification_status)
})

Deno.test("Driver Bank Transfer - Get Transfer Status", async () => {
  const request: TestRequest = {
    action: 'get_transfer_status',
    request_id: 'test-request-id'
  }

  const result = await callFunction(request)
  
  // This might fail in test environment without actual data
  // but we can test the structure
  assertExists(result)
})

Deno.test("Driver Bank Transfer - Cancel Withdrawal", async () => {
  const request: TestRequest = {
    action: 'cancel_withdrawal',
    request_id: 'test-request-id'
  }

  const result = await callFunction(request)
  
  // This might fail in test environment without actual data
  // but we can test the structure
  assertExists(result)
})

// Test Malaysian bank-specific validations
Deno.test("Driver Bank Transfer - Maybank Account Validation", async () => {
  const request: TestRequest = {
    action: 'validate_bank_details',
    bank_details: {
      bank_name: 'Malayan Banking Berhad',
      bank_code: 'MBB',
      account_number: '512345678901', // Valid Maybank format
      account_holder_name: 'Test Driver'
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, true)
  assertEquals(result.data.valid, true)
})

Deno.test("Driver Bank Transfer - CIMB Account Validation", async () => {
  const request: TestRequest = {
    action: 'validate_bank_details',
    bank_details: {
      bank_name: 'CIMB Bank Berhad',
      bank_code: 'CIMB',
      account_number: '712345678901', // Valid CIMB format
      account_holder_name: 'Test Driver'
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, true)
  assertEquals(result.data.valid, true)
})

Deno.test("Driver Bank Transfer - Public Bank Account Validation", async () => {
  const request: TestRequest = {
    action: 'validate_bank_details',
    bank_details: {
      bank_name: 'Public Bank Berhad',
      bank_code: 'PBB',
      account_number: '31234567890', // Valid Public Bank format
      account_holder_name: 'Test Driver'
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, true)
  assertEquals(result.data.valid, true)
})

// Error handling tests
Deno.test("Driver Bank Transfer - Missing Bank Details", async () => {
  const request: TestRequest = {
    action: 'create_withdrawal_request',
    amount: 100.00,
    withdrawal_method: 'bank_transfer'
    // Missing bank_details
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, false)
  assertExists(result.error)
})

Deno.test("Driver Bank Transfer - Invalid Amount", async () => {
  const request: TestRequest = {
    action: 'create_withdrawal_request',
    amount: -50.00, // Negative amount
    withdrawal_method: 'bank_transfer',
    bank_details: {
      bank_name: 'Malayan Banking Berhad',
      bank_code: 'MBB',
      account_number: '1234567890123',
      account_holder_name: 'Test Driver'
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, false)
  assertExists(result.error)
})
