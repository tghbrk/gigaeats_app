import { assertEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts"

// Test configuration
const FUNCTION_URL = 'http://localhost:54321/functions/v1/driver-document-ai-verification'
const TEST_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'

interface TestResponse {
  success: boolean
  data?: any
  error?: string
  timestamp: string
}

// Helper function to make API calls
async function callFunction(payload: any): Promise<TestResponse> {
  const response = await fetch(FUNCTION_URL, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${TEST_ANON_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  })

  return await response.json()
}

// Test 1: Health check with invalid verification ID
Deno.test("Health Check - Invalid Verification ID", async () => {
  const response = await callFunction({
    action: 'get_processing_status',
    verification_id: 'non-existent-id'
  })

  // Should return error for non-existent verification
  assertEquals(response.success, false)
  assertExists(response.error)
  assertExists(response.timestamp)
  
  console.log('✅ Health check test passed')
})

// Test 2: Invalid action handling
Deno.test("Invalid Action Handling", async () => {
  const response = await callFunction({
    action: 'invalid_action'
  })

  assertEquals(response.success, false)
  assertExists(response.error)
  assertEquals(response.error.includes('Unsupported action'), true)
  
  console.log('✅ Invalid action test passed')
})

// Test 3: Missing required parameters
Deno.test("Missing Required Parameters", async () => {
  const response = await callFunction({
    action: 'process_document'
    // Missing document_id and file_path
  })

  assertEquals(response.success, false)
  assertExists(response.error)
  
  console.log('✅ Missing parameters test passed')
})

// Test 4: Document processing with mock data
Deno.test("Document Processing - Mock Data", async () => {
  // This test would normally require actual document data
  // For now, we test the parameter validation
  const response = await callFunction({
    action: 'process_document',
    document_id: 'test-doc-id',
    verification_id: 'test-verification-id',
    document_type: 'ic_card',
    file_path: 'test/path/document.jpg'
  })

  // Should fail because document doesn't exist, but validates parameters
  assertEquals(response.success, false)
  assertExists(response.error)
  
  console.log('✅ Document processing parameter validation test passed')
})

// Test 5: Identity verification with missing verification ID
Deno.test("Identity Verification - Missing Verification ID", async () => {
  const response = await callFunction({
    action: 'verify_identity'
    // Missing verification_id
  })

  assertEquals(response.success, false)
  assertExists(response.error)
  assertEquals(response.error.includes('Verification ID is required'), true)
  
  console.log('✅ Identity verification parameter test passed')
})

// Test 6: Authenticity validation with missing document ID
Deno.test("Authenticity Validation - Missing Document ID", async () => {
  const response = await callFunction({
    action: 'validate_authenticity'
    // Missing document_id
  })

  assertEquals(response.success, false)
  assertExists(response.error)
  assertEquals(response.error.includes('Document ID is required'), true)
  
  console.log('✅ Authenticity validation parameter test passed')
})

// Test 7: CORS handling
Deno.test("CORS Preflight Request", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: 'OPTIONS',
    headers: {
      'Origin': 'http://localhost:3000',
      'Access-Control-Request-Method': 'POST',
      'Access-Control-Request-Headers': 'authorization, content-type',
    },
  })

  assertEquals(response.status, 200)
  assertEquals(response.headers.get('Access-Control-Allow-Origin'), '*')
  assertExists(response.headers.get('Access-Control-Allow-Headers'))
  
  console.log('✅ CORS preflight test passed')
})

// Test 8: Response format validation
Deno.test("Response Format Validation", async () => {
  const response = await callFunction({
    action: 'get_processing_status',
    verification_id: 'test-id'
  })

  // Check response structure
  assertExists(response.success)
  assertExists(response.timestamp)
  
  if (response.success) {
    assertExists(response.data)
  } else {
    assertExists(response.error)
  }
  
  console.log('✅ Response format test passed')
})

// Test 9: Document type validation
Deno.test("Document Type Validation", async () => {
  const validDocumentTypes = ['ic_card', 'passport', 'driver_license', 'utility_bill', 'bank_statement', 'selfie']
  
  for (const docType of validDocumentTypes) {
    const response = await callFunction({
      action: 'process_document',
      document_id: 'test-doc-id',
      verification_id: 'test-verification-id',
      document_type: docType,
      file_path: 'test/path/document.jpg'
    })

    // Should fail due to missing document, but document type should be accepted
    assertEquals(response.success, false)
    // Error should not be about invalid document type
    assertEquals(response.error?.includes('Invalid document type'), false)
  }
  
  console.log('✅ Document type validation test passed')
})

// Test 10: Timestamp format validation
Deno.test("Timestamp Format Validation", async () => {
  const response = await callFunction({
    action: 'get_processing_status',
    verification_id: 'test-id'
  })

  assertExists(response.timestamp)
  
  // Check if timestamp is valid ISO 8601 format
  const timestamp = new Date(response.timestamp)
  assertEquals(isNaN(timestamp.getTime()), false)
  
  console.log('✅ Timestamp format test passed')
})

// Integration test helper
async function runIntegrationTests() {
  console.log('\n🧪 Running Driver Document AI Verification Edge Function Tests')
  console.log('==============================================================')
  
  try {
    // Test function availability
    const healthResponse = await fetch(FUNCTION_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${TEST_ANON_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        action: 'get_processing_status',
        verification_id: 'health-check'
      }),
    })

    if (healthResponse.ok) {
      console.log('✅ Edge Function is accessible')
    } else {
      console.log('❌ Edge Function is not accessible')
      console.log(`Status: ${healthResponse.status}`)
      console.log(`Response: ${await healthResponse.text()}`)
    }

  } catch (error) {
    console.log('❌ Integration test failed:', error.message)
  }
}

// Run integration tests if this file is executed directly
if (import.meta.main) {
  await runIntegrationTests()
}
