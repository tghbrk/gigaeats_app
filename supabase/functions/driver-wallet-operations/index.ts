import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface DriverWalletRequest {
  action: 'get_balance' | 'process_earnings_deposit' | 'process_withdrawal' | 'get_transaction_history' |
          'validate_withdrawal' | 'get_wallet_settings' | 'update_wallet_settings' | 'get_withdrawal_requests' |
          'create_bank_withdrawal' | 'get_bank_accounts' | 'add_bank_account'
  wallet_id?: string
  order_id?: string
  amount?: number
  earnings_breakdown?: Record<string, any>
  withdrawal_method?: string
  destination_details?: Record<string, any>
  bank_details?: {
    bank_name: string
    bank_code?: string
    account_number: string
    account_holder_name: string
    account_type?: string
  }
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

interface DriverWalletResponse {
  success: boolean
  data?: any
  error?: string
  timestamp: string
}

serve(async (req) => {
  const timestamp = new Date().toISOString()
  console.log(`🚀 [DRIVER-WALLET-OPS-${timestamp}] Function called - Method: ${req.method}`)

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client with service role key for elevated permissions
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

    const requestBody: DriverWalletRequest = await req.json()
    console.log('🔍 [DRIVER-WALLET-OPS] Request body:', JSON.stringify(requestBody, null, 2))

    const { action } = requestBody
    let response: any

    switch (action) {
      case 'get_balance':
        response = await getDriverWalletBalance(supabaseClient, user.id)
        break
      case 'process_earnings_deposit':
        response = await processEarningsDeposit(supabaseClient, user.id, requestBody)
        break
      case 'process_withdrawal':
        response = await processWithdrawal(supabaseClient, user.id, requestBody)
        break
      case 'get_transaction_history':
        response = await getTransactionHistory(supabaseClient, user.id, requestBody)
        break
      case 'validate_withdrawal':
        response = await validateWithdrawal(supabaseClient, user.id, requestBody)
        break
      case 'get_wallet_settings':
        response = await getWalletSettings(supabaseClient, user.id)
        break
      case 'update_wallet_settings':
        response = await updateWalletSettings(supabaseClient, user.id, requestBody)
        break
      case 'get_withdrawal_requests':
        response = await getWithdrawalRequests(supabaseClient, user.id, requestBody)
        break
      case 'create_bank_withdrawal':
        response = await createBankWithdrawal(supabaseClient, user.id, requestBody)
        break
      case 'get_bank_accounts':
        response = await getBankAccounts(supabaseClient, user.id, requestBody)
        break
      case 'add_bank_account':
        response = await addBankAccount(supabaseClient, user.id, requestBody)
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
    console.error('❌ [DRIVER-WALLET-OPS] Error:', error.message)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message,
        timestamp: new Date().toISOString()
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    )
  }
})

async function getDriverWalletBalance(supabase: any, userId: string) {
  console.log('🔍 Getting driver wallet balance for user:', userId)
  
  // Validate driver access
  await validateDriverAccess(supabase, userId)
  
  const { data: wallet, error } = await supabase
    .from('stakeholder_wallets')
    .select('id, available_balance, pending_balance, total_earned, total_withdrawn, currency, is_active, is_verified')
    .eq('user_id', userId)
    .eq('user_role', 'driver')
    .single()

  if (error) {
    throw new Error(`Failed to get wallet: ${error.message}`)
  }

  console.log('✅ Driver wallet balance retrieved successfully')
  return wallet
}

async function processEarningsDeposit(supabase: any, userId: string, request: DriverWalletRequest) {
  const { wallet_id, order_id, amount, earnings_breakdown, metadata } = request
  
  console.log('🔍 Processing earnings deposit:', { wallet_id, order_id, amount })

  // Validate driver access
  await validateDriverAccess(supabase, userId)

  // Validate wallet ownership
  const { data: wallet, error: walletError } = await supabase
    .from('stakeholder_wallets')
    .select('id, available_balance, user_id')
    .eq('id', wallet_id)
    .eq('user_id', userId)
    .eq('user_role', 'driver')
    .single()

  if (walletError || !wallet) {
    throw new Error('Wallet not found or access denied')
  }

  // Validate amount
  if (!amount || amount <= 0) {
    throw new Error('Invalid deposit amount')
  }

  // Check for duplicate deposit
  const { data: existingTransaction } = await supabase
    .from('wallet_transactions')
    .select('id')
    .eq('reference_id', order_id)
    .eq('reference_type', 'order')
    .eq('transaction_type', 'delivery_earnings')
    .maybeSingle()

  if (existingTransaction) {
    console.log('⚠️ Duplicate deposit attempt for order:', order_id)
    return { 
      wallet_id, 
      message: 'Deposit already processed for this order',
      duplicate: true 
    }
  }

  const newBalance = wallet.available_balance + amount

  // Update wallet balance
  const { error: updateError } = await supabase
    .from('stakeholder_wallets')
    .update({
      available_balance: newBalance,
      total_earned: wallet.total_earned + amount,
      last_activity_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    })
    .eq('id', wallet_id)

  if (updateError) {
    throw new Error(`Failed to update wallet: ${updateError.message}`)
  }

  // Create transaction record
  const { error: transactionError } = await supabase
    .from('wallet_transactions')
    .insert({
      wallet_id: wallet_id,
      transaction_type: 'delivery_earnings',
      amount: amount,
      currency: 'MYR',
      balance_before: wallet.available_balance,
      balance_after: newBalance,
      reference_type: 'order',
      reference_id: order_id,
      description: `Delivery earnings for order ${order_id}`,
      metadata: {
        ...metadata,
        earnings_breakdown,
        processed_by: 'driver_wallet_operations',
        processed_at: new Date().toISOString()
      },
      processing_fee: 0,
      created_at: new Date().toISOString()
    })

  if (transactionError) {
    throw new Error(`Failed to create transaction: ${transactionError.message}`)
  }

  console.log('✅ Earnings deposit processed successfully')
  return { wallet_id, new_balance: newBalance, transaction_amount: amount }
}

async function processWithdrawal(supabase: any, userId: string, request: DriverWalletRequest) {
  const { wallet_id, amount, withdrawal_method, destination_details, metadata } = request
  
  console.log('🔍 Processing withdrawal:', { wallet_id, amount, withdrawal_method })

  // Validate driver access
  await validateDriverAccess(supabase, userId)

  // Validate wallet ownership and balance
  const { data: wallet, error: walletError } = await supabase
    .from('stakeholder_wallets')
    .select('id, available_balance')
    .eq('id', wallet_id)
    .eq('user_id', userId)
    .eq('user_role', 'driver')
    .single()

  if (walletError || !wallet) {
    throw new Error('Wallet not found or access denied')
  }

  if (wallet.available_balance < amount) {
    throw new Error('Insufficient balance for withdrawal')
  }

  // Get driver ID
  const { data: driver, error: driverError } = await supabase
    .from('drivers')
    .select('id')
    .eq('user_id', userId)
    .single()

  if (driverError || !driver) {
    throw new Error('Driver profile not found')
  }

  // Create withdrawal request
  const { data: withdrawalRequest, error: requestError } = await supabase
    .from('driver_withdrawal_requests')
    .insert({
      driver_id: driver.id,
      wallet_id: wallet_id,
      amount: amount,
      withdrawal_method: withdrawal_method,
      destination_details: destination_details,
      status: 'pending',
      metadata: metadata,
      requested_at: new Date().toISOString()
    })
    .select('id')
    .single()

  if (requestError) {
    throw new Error(`Failed to create withdrawal request: ${requestError.message}`)
  }

  console.log('✅ Withdrawal request created successfully')
  return { request_id: withdrawalRequest.id, status: 'pending' }
}

async function validateDriverAccess(supabase: any, userId: string) {
  console.log('🔍 Validating driver access for user:', userId)

  // Check if user has a driver profile
  const { data: driver, error } = await supabase
    .from('drivers')
    .select('id, status, is_active')
    .eq('user_id', userId)
    .single()

  console.log('🔍 Driver query result:', { driver, error })

  if (error || !driver) {
    console.log('❌ Driver profile not found for user:', userId)
    throw new Error('Driver profile not found')
  }

  // Check if driver account is active (is_active field, not status)
  // Status can be 'online'/'offline' but driver should still access wallet when offline
  if (!driver.is_active) {
    console.log('❌ Driver account is not active:', { userId, is_active: driver.is_active, status: driver.status })
    throw new Error('Driver account is not active')
  }

  console.log('✅ Driver access validated successfully:', { userId, driver_id: driver.id, status: driver.status, is_active: driver.is_active })
  return driver
}

async function getTransactionHistory(supabase: any, userId: string, request: DriverWalletRequest) {
  const { wallet_id, pagination, filters } = request

  console.log('🔍 Getting transaction history for wallet:', wallet_id)

  // Validate driver access
  await validateDriverAccess(supabase, userId)

  // Validate wallet ownership
  const { data: wallet, error: walletError } = await supabase
    .from('stakeholder_wallets')
    .select('id')
    .eq('id', wallet_id)
    .eq('user_id', userId)
    .eq('user_role', 'driver')
    .single()

  if (walletError || !wallet) {
    throw new Error('Wallet not found or access denied')
  }

  // Build query
  let query = supabase
    .from('wallet_transactions')
    .select('*')
    .eq('wallet_id', wallet_id)
    .order('created_at', { ascending: false })

  // Apply filters
  if (filters?.transaction_type) {
    query = query.eq('transaction_type', filters.transaction_type)
  }

  if (filters?.start_date) {
    query = query.gte('created_at', filters.start_date)
  }

  if (filters?.end_date) {
    query = query.lte('created_at', filters.end_date)
  }

  // Apply pagination
  const limit = pagination?.limit || 50
  const offset = pagination?.offset || 0
  query = query.range(offset, offset + limit - 1)

  const { data: transactions, error: transactionError } = await query

  if (transactionError) {
    throw new Error(`Failed to get transactions: ${transactionError.message}`)
  }

  console.log('✅ Transaction history retrieved successfully')
  return transactions
}

async function validateWithdrawal(supabase: any, userId: string, request: DriverWalletRequest) {
  const { wallet_id, amount } = request

  console.log('🔍 Validating withdrawal:', { wallet_id, amount })

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  // Validate wallet ownership
  const { data: wallet, error: walletError } = await supabase
    .from('stakeholder_wallets')
    .select('id, available_balance')
    .eq('id', wallet_id)
    .eq('user_id', userId)
    .eq('user_role', 'driver')
    .single()

  if (walletError || !wallet) {
    throw new Error('Wallet not found or access denied')
  }

  // Get wallet settings
  const { data: settings } = await supabase
    .from('driver_wallet_settings')
    .select('minimum_withdrawal_amount, maximum_daily_withdrawal')
    .eq('driver_id', driver.id)
    .maybeSingle()

  const minimumAmount = settings?.minimum_withdrawal_amount || 10.00
  const maximumDaily = settings?.maximum_daily_withdrawal || 1000.00

  // Get today's withdrawal total
  const today = new Date()
  const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate())
  const endOfDay = new Date(startOfDay.getTime() + 24 * 60 * 60 * 1000)

  const { data: todayRequests } = await supabase
    .from('driver_withdrawal_requests')
    .select('amount')
    .eq('driver_id', driver.id)
    .gte('requested_at', startOfDay.toISOString())
    .lt('requested_at', endOfDay.toISOString())
    .in('status', ['pending', 'processing', 'completed'])

  const todayTotal = todayRequests?.reduce((sum: number, req: any) => sum + req.amount, 0) || 0

  const validation = {
    is_valid: wallet.available_balance >= amount &&
             amount >= minimumAmount &&
             (todayTotal + amount) <= maximumDaily,
    available_balance: wallet.available_balance,
    minimum_amount: minimumAmount,
    maximum_daily: maximumDaily,
    today_total: todayTotal,
    remaining_daily_limit: maximumDaily - todayTotal,
    errors: [] as string[],
  }

  // Add specific error messages
  if (wallet.available_balance < amount) {
    validation.errors.push('Insufficient wallet balance')
  }
  if (amount < minimumAmount) {
    validation.errors.push(`Amount below minimum withdrawal limit of RM ${minimumAmount.toFixed(2)}`)
  }
  if ((todayTotal + amount) > maximumDaily) {
    validation.errors.push('Amount exceeds daily withdrawal limit')
  }

  console.log('✅ Withdrawal validation completed')
  return validation
}

async function getWalletSettings(supabase: any, userId: string) {
  console.log('🔍 Getting wallet settings for user:', userId)

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  const { data: settings, error } = await supabase
    .from('driver_wallet_settings')
    .select('*')
    .eq('user_id', userId)
    .eq('driver_id', driver.id)
    .maybeSingle()

  if (error) {
    throw new Error(`Failed to get wallet settings: ${error.message}`)
  }

  console.log('✅ Wallet settings retrieved successfully')
  return settings
}

async function updateWalletSettings(supabase: any, userId: string, request: DriverWalletRequest) {
  const { settings_data } = request

  console.log('🔍 Updating wallet settings for user:', userId)

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  // Update settings
  const updateData = {
    ...settings_data,
    updated_at: new Date().toISOString()
  }

  const { data: updatedSettings, error } = await supabase
    .from('driver_wallet_settings')
    .update(updateData)
    .eq('user_id', userId)
    .eq('driver_id', driver.id)
    .select()
    .single()

  if (error) {
    throw new Error(`Failed to update wallet settings: ${error.message}`)
  }

  console.log('✅ Wallet settings updated successfully')
  return updatedSettings
}

async function getWithdrawalRequests(supabase: any, userId: string, request: DriverWalletRequest) {
  const { pagination, filters } = request

  console.log('🔍 Getting withdrawal requests for user:', userId)

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  // Build query
  let query = supabase
    .from('driver_withdrawal_requests')
    .select('*')
    .eq('driver_id', driver.id)
    .order('requested_at', { ascending: false })

  // Apply filters
  if (filters?.status) {
    query = query.eq('status', filters.status)
  }

  if (filters?.start_date) {
    query = query.gte('requested_at', filters.start_date)
  }

  if (filters?.end_date) {
    query = query.lte('requested_at', filters.end_date)
  }

  // Apply pagination
  const limit = pagination?.limit || 50
  const offset = pagination?.offset || 0
  query = query.range(offset, offset + limit - 1)

  const { data: requests, error } = await query

  if (error) {
    throw new Error(`Failed to get withdrawal requests: ${error.message}`)
  }

  console.log('✅ Withdrawal requests retrieved successfully')
  return requests
}

async function createBankWithdrawal(supabase: any, userId: string, request: DriverWalletRequest) {
  const { amount, bank_details, metadata } = request

  console.log('🔍 Creating bank withdrawal request:', { amount })

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  // Get wallet
  const { data: wallet, error: walletError } = await supabase
    .from('stakeholder_wallets')
    .select('id, available_balance')
    .eq('user_id', userId)
    .eq('user_role', 'driver')
    .single()

  if (walletError || !wallet) {
    throw new Error('Driver wallet not found')
  }

  // Use the database function to create withdrawal request
  const { data: result, error } = await supabase
    .rpc('process_withdrawal_request', {
      p_driver_id: driver.id,
      p_amount: amount,
      p_withdrawal_method: 'bank_transfer',
      p_destination_details: bank_details,
      p_notes: 'Bank withdrawal via wallet operations'
    })

  if (error) {
    throw new Error(`Failed to create bank withdrawal: ${error.message}`)
  }

  if (!result.success) {
    throw new Error(result.error || 'Bank withdrawal validation failed')
  }

  console.log('✅ Bank withdrawal request created successfully')
  return result
}

async function getBankAccounts(supabase: any, userId: string, request: DriverWalletRequest) {
  console.log('🔍 Getting bank accounts for user:', userId)

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  const { data: accounts, error } = await supabase
    .from('driver_bank_accounts')
    .select('id, bank_name, bank_code, account_number, account_holder_name, account_type, verification_status, is_primary, is_active, created_at')
    .eq('driver_id', driver.id)
    .eq('is_active', true)
    .order('is_primary', { ascending: false })
    .order('created_at', { ascending: false })

  if (error) {
    throw new Error(`Failed to get bank accounts: ${error.message}`)
  }

  // Mask account numbers for security
  const maskedAccounts = accounts.map((account: any) => ({
    ...account,
    account_number: maskAccountNumber(account.account_number)
  }))

  console.log('✅ Bank accounts retrieved successfully')
  return maskedAccounts
}

async function addBankAccount(supabase: any, userId: string, request: DriverWalletRequest) {
  const { bank_details } = request

  console.log('🔍 Adding bank account for user:', userId)

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  if (!bank_details) {
    throw new Error('Bank details are required')
  }

  // Check if account already exists
  const { data: existingAccount } = await supabase
    .from('driver_bank_accounts')
    .select('id, verification_status')
    .eq('driver_id', driver.id)
    .eq('account_number', bank_details.account_number)
    .eq('bank_code', bank_details.bank_code)
    .maybeSingle()

  if (existingAccount) {
    throw new Error('Bank account already exists')
  }

  // Create new bank account
  const { data: newAccount, error } = await supabase
    .from('driver_bank_accounts')
    .insert({
      driver_id: driver.id,
      user_id: userId,
      bank_name: bank_details.bank_name,
      bank_code: bank_details.bank_code?.toUpperCase(),
      account_number: bank_details.account_number,
      account_holder_name: bank_details.account_holder_name,
      account_type: bank_details.account_type || 'savings',
      verification_status: 'pending',
      is_primary: false,
      is_active: true
    })
    .select('id, bank_name, bank_code, account_number, account_holder_name, verification_status')
    .single()

  if (error) {
    throw new Error(`Failed to add bank account: ${error.message}`)
  }

  // Mask account number in response
  newAccount.account_number = maskAccountNumber(newAccount.account_number)

  console.log('✅ Bank account added successfully')
  return newAccount
}

function maskAccountNumber(accountNumber: string): string {
  if (!accountNumber || accountNumber.length < 4) {
    return '****'
  }

  const visibleDigits = 4
  const maskedPart = '*'.repeat(accountNumber.length - visibleDigits)
  const visiblePart = accountNumber.slice(-visibleDigits)

  return maskedPart + visiblePart
}
