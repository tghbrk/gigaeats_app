import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface BankTransferRequest {
  action: 'create_withdrawal_request' | 'process_bank_transfer' | 'verify_bank_account' | 
          'get_transfer_status' | 'cancel_withdrawal' | 'validate_bank_details'
  
  // Withdrawal request fields
  amount?: number
  withdrawal_method?: string
  bank_details?: {
    bank_name: string
    bank_code?: string
    account_number: string
    account_holder_name: string
    account_type?: string
  }
  notes?: string
  
  // Processing fields
  request_id?: string
  transaction_reference?: string
  failure_reason?: string
  
  // Verification fields
  verification_method?: string
  verification_code?: string
  
  metadata?: Record<string, any>
}

interface BankTransferResponse {
  success: boolean
  data?: any
  error?: string
  error_code?: string
  timestamp: string
}

// Malaysian bank codes mapping
const MALAYSIAN_BANKS = {
  'MBB': 'Malayan Banking Berhad (Maybank)',
  'CIMB': 'CIMB Bank Berhad',
  'PBB': 'Public Bank Berhad',
  'RHB': 'RHB Bank Berhad',
  'HLB': 'Hong Leong Bank Berhad',
  'AMBANK': 'AmBank (M) Berhad',
  'UOB': 'United Overseas Bank (Malaysia) Bhd',
  'OCBC': 'OCBC Bank (Malaysia) Berhad',
  'BSN': 'Bank Simpanan Nasional',
  'AGRO': 'Agrobank',
  'ISLAM': 'Bank Islam Malaysia Berhad',
  'MUAMALAT': 'Bank Muamalat Malaysia Berhad',
  'RAKYAT': 'Bank Rakyat',
  'AFFIN': 'Affin Bank Berhad',
  'ALLIANCE': 'Alliance Bank Malaysia Berhad'
}

serve(async (req) => {
  const timestamp = new Date().toISOString()
  console.log(`🏦 [BANK-TRANSFER-${timestamp}] Function called - Method: ${req.method}`)

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client with service role key
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get user from JWT token
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)

    if (authError || !user) {
      throw new Error('Unauthorized: Invalid or missing authentication token')
    }

    const requestBody: BankTransferRequest = await req.json()
    console.log('🔍 [BANK-TRANSFER] Request body:', JSON.stringify(requestBody, null, 2))

    const { action } = requestBody
    let response: any

    switch (action) {
      case 'create_withdrawal_request':
        response = await createWithdrawalRequest(supabaseClient, user.id, requestBody)
        break
      case 'process_bank_transfer':
        response = await processBankTransfer(supabaseClient, user.id, requestBody)
        break
      case 'verify_bank_account':
        response = await verifyBankAccount(supabaseClient, user.id, requestBody)
        break
      case 'get_transfer_status':
        response = await getTransferStatus(supabaseClient, user.id, requestBody)
        break
      case 'cancel_withdrawal':
        response = await cancelWithdrawal(supabaseClient, user.id, requestBody)
        break
      case 'validate_bank_details':
        response = await validateBankDetails(supabaseClient, user.id, requestBody)
        break
      default:
        throw new Error(`Unsupported action: ${action}`)
    }

    return new Response(
      JSON.stringify({ success: true, data: response, timestamp }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('❌ [BANK-TRANSFER] Error:', error.message)
    
    // Determine error code based on error message
    let errorCode = 'UNKNOWN_ERROR'
    if (error.message.includes('Unauthorized')) errorCode = 'UNAUTHORIZED'
    else if (error.message.includes('Insufficient')) errorCode = 'INSUFFICIENT_BALANCE'
    else if (error.message.includes('Invalid bank')) errorCode = 'INVALID_BANK_DETAILS'
    else if (error.message.includes('Daily limit')) errorCode = 'DAILY_LIMIT_EXCEEDED'
    else if (error.message.includes('not found')) errorCode = 'NOT_FOUND'
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message,
        error_code: errorCode,
        timestamp: new Date().toISOString()
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    )
  }
})

async function validateDriverAccess(supabase: any, userId: string) {
  console.log('🔍 Validating driver access for user:', userId)

  const { data: driver, error } = await supabase
    .from('drivers')
    .select('id, status, is_active')
    .eq('user_id', userId)
    .single()

  if (error || !driver) {
    throw new Error('Driver profile not found')
  }

  if (!driver.is_active) {
    throw new Error('Driver account is not active')
  }

  console.log('✅ Driver access validated successfully')
  return driver
}

async function createWithdrawalRequest(supabase: any, userId: string, request: BankTransferRequest) {
  const { amount, withdrawal_method = 'bank_transfer', bank_details, notes, metadata } = request
  
  console.log('🔍 Creating withdrawal request:', { amount, withdrawal_method })

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  // Validate bank details
  if (!bank_details || !bank_details.bank_name || !bank_details.account_number || !bank_details.account_holder_name) {
    throw new Error('Invalid bank details: bank_name, account_number, and account_holder_name are required')
  }

  // Validate Malaysian bank
  const bankCode = bank_details.bank_code?.toUpperCase()
  if (bankCode && !MALAYSIAN_BANKS[bankCode]) {
    throw new Error(`Invalid bank code: ${bankCode}. Must be a valid Malaysian bank code.`)
  }

  // Validate account number format (basic validation)
  if (!/^\d{10,16}$/.test(bank_details.account_number.replace(/[-\s]/g, ''))) {
    throw new Error('Invalid account number format. Must be 10-16 digits.')
  }

  // Use database function for validation and creation
  const { data: result, error } = await supabase
    .rpc('process_withdrawal_request', {
      p_driver_id: driver.id,
      p_amount: amount,
      p_withdrawal_method: withdrawal_method,
      p_destination_details: {
        ...bank_details,
        bank_code: bankCode,
        validated_at: new Date().toISOString()
      },
      p_notes: notes
    })

  if (error) {
    throw new Error(`Failed to create withdrawal request: ${error.message}`)
  }

  if (!result.success) {
    throw new Error(result.error || 'Withdrawal validation failed')
  }

  console.log('✅ Withdrawal request created successfully')
  return result
}

async function processBankTransfer(supabase: any, userId: string, request: BankTransferRequest) {
  const { request_id, transaction_reference, failure_reason } = request

  console.log('🔍 Processing bank transfer for request:', request_id)

  // Validate admin access (only admins can process transfers)
  const { data: user, error: userError } = await supabase
    .from('users')
    .select('role')
    .eq('id', userId)
    .single()

  if (userError || user.role !== 'admin') {
    throw new Error('Unauthorized: Only administrators can process bank transfers')
  }

  // Get withdrawal request details
  const { data: withdrawalRequest, error: requestError } = await supabase
    .from('driver_withdrawal_requests')
    .select('*')
    .eq('id', request_id)
    .single()

  if (requestError || !withdrawalRequest) {
    throw new Error('Withdrawal request not found')
  }

  if (withdrawalRequest.status !== 'pending') {
    throw new Error(`Cannot process withdrawal request with status: ${withdrawalRequest.status}`)
  }

  // Simulate Malaysian bank transfer integration
  const transferResult = await initiateMalaysianBankTransfer(
    withdrawalRequest.destination_details,
    withdrawalRequest.amount,
    withdrawalRequest.id
  )

  // Update withdrawal request status
  const newStatus = transferResult.success ? 'processing' : 'failed'
  const { error: updateError } = await supabase
    .rpc('update_withdrawal_status', {
      p_request_id: request_id,
      p_status: newStatus,
      p_transaction_reference: transferResult.transaction_id || transaction_reference,
      p_failure_reason: transferResult.error_message || failure_reason,
      p_processed_by: userId
    })

  if (updateError) {
    throw new Error(`Failed to update withdrawal status: ${updateError.message}`)
  }

  console.log('✅ Bank transfer processing completed')
  return {
    request_id,
    status: newStatus,
    transaction_reference: transferResult.transaction_id,
    transfer_result: transferResult
  }
}

async function initiateMalaysianBankTransfer(bankDetails: any, amount: number, requestId: string) {
  console.log('🏦 Initiating Malaysian bank transfer:', { bankDetails, amount })

  // In production, integrate with Malaysian payment gateways like:
  // - iPay88
  // - MOLPay (Razer Merchant Services)
  // - Billplz
  // - FPX (Financial Process Exchange)
  // - Local bank APIs (Maybank, CIMB, etc.)

  try {
    // Simulate API call to Malaysian payment gateway
    const mockTransactionId = `MYR_${Date.now()}_${requestId.substring(0, 8)}`
    const mockReference = `REF_${bankDetails.bank_code || 'MBB'}_${Date.now()}`

    // Validate bank details format for Malaysian banks
    const isValidMalaysianAccount = validateMalaysianBankAccount(bankDetails)
    if (!isValidMalaysianAccount.valid) {
      return {
        success: false,
        error_message: isValidMalaysianAccount.error
      }
    }

    // Simulate processing delay and success rate (95% success for demo)
    const shouldSucceed = Math.random() > 0.05

    if (shouldSucceed) {
      console.log(`🏦 Malaysian bank transfer initiated: ${mockTransactionId}`)

      return {
        success: true,
        transaction_id: mockTransactionId,
        reference: mockReference,
        estimated_completion: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(), // 2 hours
        gateway: 'malaysian_bank_gateway',
        bank_code: bankDetails.bank_code,
        processing_fee: amount * 0.01 // 1% processing fee
      }
    } else {
      const errorReasons = [
        'Invalid account number',
        'Account holder name mismatch',
        'Bank temporarily unavailable',
        'Daily transfer limit exceeded',
        'Account frozen or inactive'
      ]

      return {
        success: false,
        error_message: errorReasons[Math.floor(Math.random() * errorReasons.length)]
      }
    }

  } catch (error) {
    console.error('❌ Bank transfer initiation failed:', error)
    return {
      success: false,
      error_message: 'Bank transfer service temporarily unavailable'
    }
  }
}

function validateMalaysianBankAccount(bankDetails: any) {
  const { bank_code, account_number, account_holder_name } = bankDetails

  // Validate bank code
  if (bank_code && !MALAYSIAN_BANKS[bank_code.toUpperCase()]) {
    return { valid: false, error: `Invalid Malaysian bank code: ${bank_code}` }
  }

  // Validate account number format (Malaysian banks typically use 10-16 digits)
  const cleanAccountNumber = account_number.replace(/[-\s]/g, '')
  if (!/^\d{10,16}$/.test(cleanAccountNumber)) {
    return { valid: false, error: 'Invalid account number format for Malaysian bank' }
  }

  // Validate account holder name (basic validation)
  if (!account_holder_name || account_holder_name.length < 2) {
    return { valid: false, error: 'Invalid account holder name' }
  }

  // Bank-specific validations
  if (bank_code) {
    switch (bank_code.toUpperCase()) {
      case 'MBB': // Maybank
        if (!/^(1|5)\d{11}$/.test(cleanAccountNumber)) {
          return { valid: false, error: 'Invalid Maybank account number format' }
        }
        break
      case 'CIMB':
        if (!/^(7|8)\d{11}$/.test(cleanAccountNumber)) {
          return { valid: false, error: 'Invalid CIMB account number format' }
        }
        break
      case 'PBB': // Public Bank
        if (!/^(3|4)\d{9,11}$/.test(cleanAccountNumber)) {
          return { valid: false, error: 'Invalid Public Bank account number format' }
        }
        break
      // Add more bank-specific validations as needed
    }
  }

  return { valid: true }
}

async function verifyBankAccount(supabase: any, userId: string, request: BankTransferRequest) {
  const { bank_details, verification_method = 'micro_deposit', verification_code } = request

  console.log('🔍 Verifying bank account for user:', userId)

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  if (!bank_details) {
    throw new Error('Bank details are required for verification')
  }

  // Validate bank details format
  const validation = validateMalaysianBankAccount(bank_details)
  if (!validation.valid) {
    throw new Error(validation.error)
  }

  // Check if account already exists and is verified
  const { data: existingAccount } = await supabase
    .from('driver_bank_accounts')
    .select('*')
    .eq('driver_id', driver.id)
    .eq('account_number', bank_details.account_number)
    .eq('bank_code', bank_details.bank_code)
    .maybeSingle()

  if (existingAccount && existingAccount.verification_status === 'verified') {
    return {
      account_id: existingAccount.id,
      verification_status: 'verified',
      message: 'Bank account already verified'
    }
  }

  // Create or update bank account record
  const accountData = {
    driver_id: driver.id,
    user_id: userId,
    bank_name: bank_details.bank_name,
    bank_code: bank_details.bank_code?.toUpperCase(),
    account_number: bank_details.account_number,
    account_holder_name: bank_details.account_holder_name,
    account_type: bank_details.account_type || 'savings',
    verification_method,
    verification_status: 'pending',
    verification_attempts: (existingAccount?.verification_attempts || 0) + 1,
    encrypted_details: {
      // In production, encrypt sensitive data
      account_number_hash: await hashAccountNumber(bank_details.account_number),
      verification_timestamp: new Date().toISOString()
    }
  }

  let accountId: string

  if (existingAccount) {
    // Update existing account
    const { data: updatedAccount, error } = await supabase
      .from('driver_bank_accounts')
      .update(accountData)
      .eq('id', existingAccount.id)
      .select('id')
      .single()

    if (error) {
      throw new Error(`Failed to update bank account: ${error.message}`)
    }
    accountId = updatedAccount.id
  } else {
    // Create new account
    const { data: newAccount, error } = await supabase
      .from('driver_bank_accounts')
      .insert(accountData)
      .select('id')
      .single()

    if (error) {
      throw new Error(`Failed to create bank account: ${error.message}`)
    }
    accountId = newAccount.id
  }

  // Simulate verification process
  let verificationResult
  if (verification_method === 'micro_deposit') {
    verificationResult = await simulateMicroDepositVerification(bank_details, verification_code)
  } else if (verification_method === 'instant_verification') {
    verificationResult = await simulateInstantVerification(bank_details)
  } else {
    verificationResult = { success: false, error: 'Unsupported verification method' }
  }

  // Update verification status
  const newStatus = verificationResult.success ? 'verified' : 'failed'
  await supabase
    .from('driver_bank_accounts')
    .update({
      verification_status: newStatus,
      verified_at: verificationResult.success ? new Date().toISOString() : null,
      verification_reference: verificationResult.reference,
      updated_at: new Date().toISOString()
    })
    .eq('id', accountId)

  console.log('✅ Bank account verification completed')
  return {
    account_id: accountId,
    verification_status: newStatus,
    verification_method,
    verification_result: verificationResult
  }
}

async function hashAccountNumber(accountNumber: string): Promise<string> {
  // Simple hash for demo - in production use proper encryption
  const encoder = new TextEncoder()
  const data = encoder.encode(accountNumber + 'GIGAEATS_SALT')
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
}

async function simulateMicroDepositVerification(bankDetails: any, verificationCode?: string) {
  console.log('🔍 Simulating micro deposit verification')

  // In production, this would:
  // 1. Send small amounts (e.g., RM 0.01, RM 0.02) to the account
  // 2. Ask user to verify the amounts received
  // 3. Validate the verification code

  if (verificationCode) {
    // Simulate verification code validation
    const expectedCode = '0102' // Mock expected code
    if (verificationCode === expectedCode) {
      return {
        success: true,
        reference: `MICRO_${Date.now()}`,
        message: 'Micro deposit verification successful'
      }
    } else {
      return {
        success: false,
        error: 'Invalid verification code',
        reference: `MICRO_FAIL_${Date.now()}`
      }
    }
  } else {
    // Initiate micro deposit
    return {
      success: false,
      pending: true,
      message: 'Micro deposits sent. Please check your account and enter the verification code.',
      reference: `MICRO_PENDING_${Date.now()}`
    }
  }
}

async function simulateInstantVerification(bankDetails: any) {
  console.log('🔍 Simulating instant bank verification')

  // In production, this would integrate with bank APIs for instant verification
  // Success rate simulation (90% for demo)
  const shouldSucceed = Math.random() > 0.1

  if (shouldSucceed) {
    return {
      success: true,
      reference: `INSTANT_${Date.now()}`,
      message: 'Bank account verified instantly'
    }
  } else {
    return {
      success: false,
      error: 'Unable to verify account instantly. Please try micro deposit verification.',
      reference: `INSTANT_FAIL_${Date.now()}`
    }
  }
}

async function getTransferStatus(supabase: any, userId: string, request: BankTransferRequest) {
  const { request_id } = request

  console.log('🔍 Getting transfer status for request:', request_id)

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  // Get withdrawal request with status
  const { data: withdrawalRequest, error } = await supabase
    .from('driver_withdrawal_requests')
    .select(`
      *,
      stakeholder_wallets!inner(user_id)
    `)
    .eq('id', request_id)
    .eq('driver_id', driver.id)
    .single()

  if (error || !withdrawalRequest) {
    throw new Error('Withdrawal request not found or access denied')
  }

  // Get related transaction if completed
  let transaction = null
  if (withdrawalRequest.status === 'completed') {
    const { data: txn } = await supabase
      .from('wallet_transactions')
      .select('*')
      .eq('reference_id', request_id)
      .eq('reference_type', 'withdrawal_request')
      .maybeSingle()

    transaction = txn
  }

  console.log('✅ Transfer status retrieved successfully')
  return {
    request_id,
    status: withdrawalRequest.status,
    amount: withdrawalRequest.amount,
    net_amount: withdrawalRequest.net_amount,
    processing_fee: withdrawalRequest.processing_fee,
    withdrawal_method: withdrawalRequest.withdrawal_method,
    destination_details: withdrawalRequest.destination_details,
    transaction_reference: withdrawalRequest.transaction_reference,
    requested_at: withdrawalRequest.requested_at,
    processed_at: withdrawalRequest.processed_at,
    completed_at: withdrawalRequest.completed_at,
    failure_reason: withdrawalRequest.failure_reason,
    transaction
  }
}

async function cancelWithdrawal(supabase: any, userId: string, request: BankTransferRequest) {
  const { request_id } = request

  console.log('🔍 Cancelling withdrawal request:', request_id)

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  // Get withdrawal request
  const { data: withdrawalRequest, error } = await supabase
    .from('driver_withdrawal_requests')
    .select('*')
    .eq('id', request_id)
    .eq('driver_id', driver.id)
    .single()

  if (error || !withdrawalRequest) {
    throw new Error('Withdrawal request not found or access denied')
  }

  // Only allow cancellation of pending requests
  if (withdrawalRequest.status !== 'pending') {
    throw new Error(`Cannot cancel withdrawal request with status: ${withdrawalRequest.status}`)
  }

  // Update status to cancelled using database function
  const { error: updateError } = await supabase
    .rpc('update_withdrawal_status', {
      p_request_id: request_id,
      p_status: 'cancelled',
      p_failure_reason: 'Cancelled by user',
      p_processed_by: userId
    })

  if (updateError) {
    throw new Error(`Failed to cancel withdrawal: ${updateError.message}`)
  }

  console.log('✅ Withdrawal request cancelled successfully')
  return {
    request_id,
    status: 'cancelled',
    cancelled_at: new Date().toISOString()
  }
}

async function validateBankDetails(supabase: any, userId: string, request: BankTransferRequest) {
  const { bank_details } = request

  console.log('🔍 Validating bank details for user:', userId)

  // Validate driver access
  await validateDriverAccess(supabase, userId)

  if (!bank_details) {
    throw new Error('Bank details are required for validation')
  }

  // Validate bank details format
  const validation = validateMalaysianBankAccount(bank_details)

  // Additional validations
  const validationResult = {
    valid: validation.valid,
    errors: [] as string[],
    warnings: [] as string[],
    bank_info: null as any
  }

  if (!validation.valid) {
    validationResult.errors.push(validation.error)
  }

  // Check if bank is supported
  const bankCode = bank_details.bank_code?.toUpperCase()
  if (bankCode && MALAYSIAN_BANKS[bankCode]) {
    validationResult.bank_info = {
      bank_code: bankCode,
      bank_name: MALAYSIAN_BANKS[bankCode],
      supported: true
    }
  } else if (bankCode) {
    validationResult.warnings.push(`Bank code ${bankCode} not in our supported list`)
    validationResult.bank_info = {
      bank_code: bankCode,
      bank_name: bank_details.bank_name,
      supported: false
    }
  }

  // Check for existing verified account
  if (validation.valid) {
    const { data: existingAccount } = await supabase
      .from('driver_bank_accounts')
      .select('verification_status, is_primary')
      .eq('user_id', userId)
      .eq('account_number', bank_details.account_number)
      .eq('bank_code', bankCode)
      .maybeSingle()

    if (existingAccount) {
      if (existingAccount.verification_status === 'verified') {
        validationResult.warnings.push('This bank account is already verified')
      } else {
        validationResult.warnings.push('This bank account exists but is not yet verified')
      }
    }
  }

  console.log('✅ Bank details validation completed')
  return validationResult
}
