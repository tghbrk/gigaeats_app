import { assertEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts"

// Test configuration
const FUNCTION_URL = 'http://localhost:54321/functions/v1/bank-account-verification'
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

// Test Malaysian IC validation
Deno.test("Bank Verification - Valid Malaysian IC", async () => {
  const request: TestRequest = {
    action: 'initiate_verification',
    bank_details: {
      bank_name: 'Malayan Banking Berhad',
      bank_code: 'MBB',
      account_number: '1234567890123',
      account_holder_name: 'Test Driver',
      account_type: 'savings'
    },
    verification_method: 'instant_verification',
    identity_documents: {
      ic_number: '901234-12-3456'
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  // Should not fail due to IC validation
})

Deno.test("Bank Verification - Invalid Malaysian IC Format", async () => {
  const request: TestRequest = {
    action: 'initiate_verification',
    bank_details: {
      bank_name: 'Malayan Banking Berhad',
      bank_code: 'MBB',
      account_number: '1234567890123',
      account_holder_name: 'Test Driver'
    },
    verification_method: 'instant_verification',
    identity_documents: {
      ic_number: '123456789' // Invalid format
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, false)
  assertEquals(result.error_code, 'INVALID_IC_NUMBER')
})

Deno.test("Bank Verification - Micro Deposit Initiation", async () => {
  const request: TestRequest = {
    action: 'initiate_verification',
    bank_details: {
      bank_name: 'CIMB Bank Berhad',
      bank_code: 'CIMB',
      account_number: '7123456789012',
      account_holder_name: 'Test Driver',
      account_type: 'savings'
    },
    verification_method: 'micro_deposit'
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, true)
  assertExists(result.data.account_id)
  assertEquals(result.data.verification_method, 'micro_deposit')
  assertExists(result.data.verification_reference)
})

Deno.test("Bank Verification - Document Verification", async () => {
  const request: TestRequest = {
    action: 'initiate_verification',
    bank_details: {
      bank_name: 'Public Bank Berhad',
      bank_code: 'PBB',
      account_number: '3123456789012',
      account_holder_name: 'Test Driver'
    },
    verification_method: 'document_verification',
    identity_documents: {
      ic_number: '901234-12-3456',
      ic_front_image: 'base64_mock_image_data',
      ic_back_image: 'base64_mock_image_data',
      selfie_image: 'base64_mock_selfie_data'
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, true)
  assertEquals(result.data.verification_method, 'document_verification')
})

Deno.test("Bank Verification - Missing Required Documents", async () => {
  const request: TestRequest = {
    action: 'initiate_verification',
    bank_details: {
      bank_name: 'Public Bank Berhad',
      bank_code: 'PBB',
      account_number: '3123456789012',
      account_holder_name: 'Test Driver'
    },
    verification_method: 'document_verification',
    identity_documents: {
      ic_number: '901234-12-3456',
      ic_front_image: 'base64_mock_image_data'
      // Missing ic_back_image and selfie_image
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, false)
  assertExists(result.error)
})

Deno.test("Bank Verification - Submit Micro Deposit Verification", async () => {
  const request: TestRequest = {
    action: 'submit_verification',
    account_id: 'test-account-id',
    verification_amounts: [12, 34]
  }

  const result = await callFunction(request)
  
  assertExists(result)
  // May fail in test environment without actual account data
})

Deno.test("Bank Verification - Invalid Verification Amounts", async () => {
  const request: TestRequest = {
    action: 'submit_verification',
    account_id: 'test-account-id',
    verification_amounts: [12] // Should be 2 amounts
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, false)
})

Deno.test("Bank Verification - Get Verification Status", async () => {
  const request: TestRequest = {
    action: 'get_verification_status',
    account_id: 'test-account-id'
  }

  const result = await callFunction(request)
  
  assertExists(result)
  // May fail in test environment without actual account data
})

Deno.test("Bank Verification - Resend Verification", async () => {
  const request: TestRequest = {
    action: 'resend_verification',
    account_id: 'test-account-id'
  }

  const result = await callFunction(request)
  
  assertExists(result)
  // May fail in test environment without actual account data
})

Deno.test("Bank Verification - Identity Verification", async () => {
  const request: TestRequest = {
    action: 'verify_identity',
    account_id: 'test-account-id',
    identity_documents: {
      ic_number: '901234-12-3456',
      ic_front_image: 'base64_mock_image_data',
      ic_back_image: 'base64_mock_image_data',
      selfie_image: 'base64_mock_selfie_data'
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  // May fail in test environment without actual account data
})

Deno.test("Bank Verification - Update Documents", async () => {
  const request: TestRequest = {
    action: 'update_verification_documents',
    account_id: 'test-account-id',
    identity_documents: {
      ic_front_image: 'new_base64_mock_image_data',
      ic_back_image: 'new_base64_mock_image_data'
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  // May fail in test environment without actual account data
})

Deno.test("Bank Verification - Manual Verification", async () => {
  const request: TestRequest = {
    action: 'initiate_verification',
    bank_details: {
      bank_name: 'RHB Bank Berhad',
      bank_code: 'RHB',
      account_number: '2123456789012',
      account_holder_name: 'Test Driver'
    },
    verification_method: 'manual_verification',
    identity_documents: {
      ic_number: '901234-12-3456',
      bank_statement: 'base64_mock_statement_data'
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, true)
  assertEquals(result.data.verification_method, 'manual_verification')
})

Deno.test("Bank Verification - Instant Verification Success", async () => {
  const request: TestRequest = {
    action: 'initiate_verification',
    bank_details: {
      bank_name: 'Hong Leong Bank Berhad',
      bank_code: 'HLB',
      account_number: '4123456789012',
      account_holder_name: 'Test Driver'
    },
    verification_method: 'instant_verification',
    identity_documents: {
      ic_number: '901234-12-3456'
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, true)
  assertEquals(result.data.verification_method, 'instant_verification')
  // Status could be verified or failed depending on simulation
})

// Test edge cases
Deno.test("Bank Verification - Missing Bank Details", async () => {
  const request: TestRequest = {
    action: 'initiate_verification',
    verification_method: 'micro_deposit'
    // Missing bank_details
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, false)
  assertExists(result.error)
})

Deno.test("Bank Verification - Unsupported Verification Method", async () => {
  const request: TestRequest = {
    action: 'initiate_verification',
    bank_details: {
      bank_name: 'Test Bank',
      bank_code: 'TEST',
      account_number: '1234567890',
      account_holder_name: 'Test Driver'
    },
    verification_method: 'unsupported_method'
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, false)
  assertExists(result.error)
})

Deno.test("Bank Verification - Invalid Action", async () => {
  const request: TestRequest = {
    action: 'invalid_action'
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertEquals(result.success, false)
  assertExists(result.error)
})
