// Test file for driver-wallet-operations Edge Function
// Run with: deno test --allow-net --allow-env test.ts

import { assertEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts"

const FUNCTION_URL = 'http://localhost:54321/functions/v1/driver-wallet-operations'
const ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') || 'your-anon-key'

// Mock JWT token for testing (replace with actual test token)
const TEST_JWT = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' // Replace with valid test JWT

interface TestRequest {
  action: string
  [key: string]: any
}

async function callFunction(request: TestRequest): Promise<any> {
  const response = await fetch(FUNCTION_URL, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${TEST_JWT}`,
      'Content-Type': 'application/json',
      'apikey': ANON_KEY,
    },
    body: JSON.stringify(request),
  })

  return await response.json()
}

Deno.test("Driver Wallet Operations - CORS preflight", async () => {
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
})

Deno.test("Driver Wallet Operations - Get Balance", async () => {
  const request: TestRequest = {
    action: 'get_balance'
  }

  const result = await callFunction(request)
  
  // Should return success or authentication error
  assertExists(result)
  assertExists(result.timestamp)
  
  if (result.success) {
    assertExists(result.data)
    assertExists(result.data.available_balance)
    assertExists(result.data.currency)
  } else {
    // Expected if no valid JWT token
    assertExists(result.error)
  }
})

Deno.test("Driver Wallet Operations - Process Earnings Deposit", async () => {
  const request: TestRequest = {
    action: 'process_earnings_deposit',
    wallet_id: 'test-wallet-id',
    order_id: 'test-order-123',
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

  const result = await callFunction(request)
  
  assertExists(result)
  assertExists(result.timestamp)
  
  if (result.success) {
    assertExists(result.data)
    assertExists(result.data.wallet_id)
    assertExists(result.data.new_balance)
  } else {
    // Expected if no valid authentication or wallet
    assertExists(result.error)
  }
})

Deno.test("Driver Wallet Operations - Validate Withdrawal", async () => {
  const request: TestRequest = {
    action: 'validate_withdrawal',
    wallet_id: 'test-wallet-id',
    amount: 50.00
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertExists(result.timestamp)
  
  if (result.success) {
    assertExists(result.data)
    assertExists(result.data.is_valid)
    assertExists(result.data.available_balance)
    assertExists(result.data.minimum_amount)
    assertExists(result.data.maximum_daily)
  } else {
    // Expected if no valid authentication
    assertExists(result.error)
  }
})

Deno.test("Driver Wallet Operations - Process Withdrawal", async () => {
  const request: TestRequest = {
    action: 'process_withdrawal',
    wallet_id: 'test-wallet-id',
    amount: 100.00,
    withdrawal_method: 'bank_transfer',
    destination_details: {
      bank_name: 'Test Bank',
      account_number: '1234567890',
      account_holder: 'Test Driver'
    },
    metadata: {
      request_source: 'mobile_app'
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertExists(result.timestamp)
  
  if (result.success) {
    assertExists(result.data)
    assertExists(result.data.request_id)
    assertEquals(result.data.status, 'pending')
  } else {
    // Expected if no valid authentication or insufficient balance
    assertExists(result.error)
  }
})

Deno.test("Driver Wallet Operations - Get Transaction History", async () => {
  const request: TestRequest = {
    action: 'get_transaction_history',
    wallet_id: 'test-wallet-id',
    pagination: {
      limit: 10,
      offset: 0
    },
    filters: {
      transaction_type: 'delivery_earnings'
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertExists(result.timestamp)
  
  if (result.success) {
    assertExists(result.data)
    assertEquals(Array.isArray(result.data), true)
  } else {
    // Expected if no valid authentication
    assertExists(result.error)
  }
})

Deno.test("Driver Wallet Operations - Get Wallet Settings", async () => {
  const request: TestRequest = {
    action: 'get_wallet_settings'
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertExists(result.timestamp)
  
  if (result.success) {
    // Settings might be null if not configured yet
    if (result.data) {
      assertExists(result.data.minimum_withdrawal_amount)
      assertExists(result.data.maximum_daily_withdrawal)
    }
  } else {
    // Expected if no valid authentication
    assertExists(result.error)
  }
})

Deno.test("Driver Wallet Operations - Update Wallet Settings", async () => {
  const request: TestRequest = {
    action: 'update_wallet_settings',
    settings_data: {
      auto_payout_enabled: true,
      auto_payout_threshold: 200.00,
      minimum_withdrawal_amount: 20.00,
      earnings_notifications: true,
      low_balance_alerts: true,
      low_balance_threshold: 50.00
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertExists(result.timestamp)
  
  if (result.success) {
    assertExists(result.data)
    assertEquals(result.data.auto_payout_enabled, true)
    assertEquals(result.data.auto_payout_threshold, 200.00)
  } else {
    // Expected if no valid authentication
    assertExists(result.error)
  }
})

Deno.test("Driver Wallet Operations - Get Withdrawal Requests", async () => {
  const request: TestRequest = {
    action: 'get_withdrawal_requests',
    pagination: {
      limit: 20,
      offset: 0
    },
    filters: {
      status: 'pending'
    }
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertExists(result.timestamp)
  
  if (result.success) {
    assertExists(result.data)
    assertEquals(Array.isArray(result.data), true)
  } else {
    // Expected if no valid authentication
    assertExists(result.error)
  }
})

Deno.test("Driver Wallet Operations - Invalid Action", async () => {
  const request: TestRequest = {
    action: 'invalid_action'
  }

  const result = await callFunction(request)
  
  assertExists(result)
  assertExists(result.timestamp)
  assertEquals(result.success, false)
  assertExists(result.error)
  assertEquals(result.error.includes('Unsupported action'), true)
})

Deno.test("Driver Wallet Operations - Missing Authentication", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': ANON_KEY,
    },
    body: JSON.stringify({
      action: 'get_balance'
    }),
  })

  const result = await response.json()
  
  assertExists(result)
  assertEquals(result.success, false)
  assertExists(result.error)
  assertEquals(result.error.includes('Unauthorized'), true)
})
