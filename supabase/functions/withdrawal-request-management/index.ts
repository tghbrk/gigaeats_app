import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface WithdrawalManagementRequest {
  action: 'create_request' | 'update_status' | 'get_requests' | 'get_request_details' | 
          'cancel_request' | 'approve_request' | 'reject_request' | 'process_batch' |
          'get_limits' | 'update_limits' | 'check_fraud_score' | 'get_analytics'
  
  // Request creation/update
  request_id?: string
  amount?: number
  withdrawal_method?: string
  bank_account_id?: string
  notes?: string
  
  // Status management
  new_status?: string
  admin_notes?: string
  failure_reason?: string
  transaction_reference?: string
  
  // Batch processing
  request_ids?: string[]
  batch_action?: string
  
  // Filtering and pagination
  filters?: {
    status?: string
    method?: string
    driver_id?: string
    start_date?: string
    end_date?: string
    min_amount?: number
    max_amount?: number
  }
  pagination?: {
    page?: number
    limit?: number
    sort_by?: string
    sort_order?: 'asc' | 'desc'
  }
  
  // Limits management
  limit_type?: 'daily' | 'weekly' | 'monthly'
  limit_amount?: number
  
  metadata?: Record<string, any>
}

interface WithdrawalManagementResponse {
  success: boolean
  data?: any
  error?: string
  error_code?: string
  timestamp: string
}

// Fraud detection thresholds
const FRAUD_DETECTION_CONFIG = {
  HIGH_AMOUNT_THRESHOLD: 1000.00, // RM 1000
  RAPID_REQUESTS_THRESHOLD: 5, // 5 requests in short time
  RAPID_REQUESTS_WINDOW: 60 * 60 * 1000, // 1 hour in milliseconds
  SUSPICIOUS_PATTERN_THRESHOLD: 3, // 3 similar amounts
  MAX_DAILY_REQUESTS: 10,
  VELOCITY_CHECK_WINDOW: 24 * 60 * 60 * 1000 // 24 hours
}

serve(async (req) => {
  const timestamp = new Date().toISOString()
  console.log(`💰 [WITHDRAWAL-MGMT-${timestamp}] Function called - Method: ${req.method}`)

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

    const requestBody: WithdrawalManagementRequest = await req.json()
    console.log('🔍 [WITHDRAWAL-MGMT] Request action:', requestBody.action)

    const { action } = requestBody
    let response: any

    switch (action) {
      case 'create_request':
        response = await createWithdrawalRequest(supabaseClient, user.id, requestBody)
        break
      case 'update_status':
        response = await updateWithdrawalStatus(supabaseClient, user.id, requestBody)
        break
      case 'get_requests':
        response = await getWithdrawalRequests(supabaseClient, user.id, requestBody)
        break
      case 'get_request_details':
        response = await getWithdrawalRequestDetails(supabaseClient, user.id, requestBody)
        break
      case 'cancel_request':
        response = await cancelWithdrawalRequest(supabaseClient, user.id, requestBody)
        break
      case 'approve_request':
        response = await approveWithdrawalRequest(supabaseClient, user.id, requestBody)
        break
      case 'reject_request':
        response = await rejectWithdrawalRequest(supabaseClient, user.id, requestBody)
        break
      case 'process_batch':
        response = await processBatchRequests(supabaseClient, user.id, requestBody)
        break
      case 'get_limits':
        response = await getWithdrawalLimits(supabaseClient, user.id, requestBody)
        break
      case 'update_limits':
        response = await updateWithdrawalLimits(supabaseClient, user.id, requestBody)
        break
      case 'check_fraud_score':
        response = await checkFraudScore(supabaseClient, user.id, requestBody)
        break
      case 'get_analytics':
        response = await getWithdrawalAnalytics(supabaseClient, user.id, requestBody)
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
    console.error('❌ [WITHDRAWAL-MGMT] Error:', error.message)
    
    // Determine error code based on error message
    let errorCode = 'UNKNOWN_ERROR'
    if (error.message.includes('Unauthorized')) errorCode = 'UNAUTHORIZED'
    else if (error.message.includes('Insufficient')) errorCode = 'INSUFFICIENT_BALANCE'
    else if (error.message.includes('Limit exceeded')) errorCode = 'LIMIT_EXCEEDED'
    else if (error.message.includes('Fraud detected')) errorCode = 'FRAUD_DETECTED'
    else if (error.message.includes('Invalid status')) errorCode = 'INVALID_STATUS'
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

async function validateUserAccess(supabase: any, userId: string) {
  console.log('🔍 Validating user access for:', userId)

  const { data: user, error } = await supabase
    .from('users')
    .select('role')
    .eq('id', userId)
    .single()

  if (error || !user) {
    throw new Error('User profile not found')
  }

  console.log('✅ User access validated successfully')
  return user
}

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

async function createWithdrawalRequest(supabase: any, userId: string, request: WithdrawalManagementRequest) {
  const { amount, withdrawal_method = 'bank_transfer', bank_account_id, notes, metadata } = request
  
  console.log('🔍 Creating withdrawal request:', { amount, withdrawal_method })

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  // Validate amount
  if (!amount || amount <= 0) {
    throw new Error('Invalid withdrawal amount')
  }

  // Get driver wallet
  const { data: wallet, error: walletError } = await supabase
    .from('stakeholder_wallets')
    .select('id, available_balance')
    .eq('user_id', userId)
    .eq('user_role', 'driver')
    .single()

  if (walletError || !wallet) {
    throw new Error('Driver wallet not found')
  }

  // Validate bank account if specified
  let bankAccountDetails = null
  if (bank_account_id) {
    const { data: bankAccount, error: bankError } = await supabase
      .from('driver_bank_accounts')
      .select('*')
      .eq('id', bank_account_id)
      .eq('driver_id', driver.id)
      .eq('verification_status', 'verified')
      .eq('is_active', true)
      .single()

    if (bankError || !bankAccount) {
      throw new Error('Valid bank account not found')
    }

    bankAccountDetails = {
      bank_name: bankAccount.bank_name,
      bank_code: bankAccount.bank_code,
      account_number: bankAccount.account_number,
      account_holder_name: bankAccount.account_holder_name
    }
  }

  // Perform fraud detection
  const fraudScore = await performFraudDetection(supabase, driver.id, amount, withdrawal_method)
  
  if (fraudScore.risk_level === 'high') {
    throw new Error(`Fraud detected: ${fraudScore.reason}`)
  }

  // Use database function for validation and creation
  const { data: result, error } = await supabase
    .rpc('process_withdrawal_request', {
      p_driver_id: driver.id,
      p_amount: amount,
      p_withdrawal_method: withdrawal_method,
      p_destination_details: bankAccountDetails || {},
      p_notes: notes
    })

  if (error) {
    throw new Error(`Failed to create withdrawal request: ${error.message}`)
  }

  if (!result.success) {
    throw new Error(result.error || 'Withdrawal validation failed')
  }

  // Store fraud score and metadata
  if (result.request_id) {
    await supabase
      .from('driver_withdrawal_requests')
      .update({
        metadata: {
          ...metadata,
          fraud_score: fraudScore.score,
          risk_level: fraudScore.risk_level,
          fraud_checks: fraudScore.checks,
          bank_account_id: bank_account_id
        }
      })
      .eq('id', result.request_id)
  }

  console.log('✅ Withdrawal request created successfully')
  return {
    ...result,
    fraud_score: fraudScore.score,
    risk_level: fraudScore.risk_level
  }
}

async function performFraudDetection(supabase: any, driverId: string, amount: number, method: string) {
  console.log('🔍 Performing fraud detection for driver:', driverId)

  const fraudChecks = {
    high_amount: false,
    rapid_requests: false,
    suspicious_pattern: false,
    velocity_check: false,
    daily_limit_check: false
  }

  let riskScore = 0
  const reasons = []

  // Check 1: High amount threshold
  if (amount >= FRAUD_DETECTION_CONFIG.HIGH_AMOUNT_THRESHOLD) {
    fraudChecks.high_amount = true
    riskScore += 30
    reasons.push(`High amount: RM ${amount}`)
  }

  // Check 2: Rapid requests (multiple requests in short time)
  const rapidRequestsWindow = new Date(Date.now() - FRAUD_DETECTION_CONFIG.RAPID_REQUESTS_WINDOW)
  const { data: recentRequests } = await supabase
    .from('driver_withdrawal_requests')
    .select('id, amount, requested_at')
    .eq('driver_id', driverId)
    .gte('requested_at', rapidRequestsWindow.toISOString())

  if (recentRequests && recentRequests.length >= FRAUD_DETECTION_CONFIG.RAPID_REQUESTS_THRESHOLD) {
    fraudChecks.rapid_requests = true
    riskScore += 40
    reasons.push(`${recentRequests.length} requests in last hour`)
  }

  // Check 3: Suspicious pattern (similar amounts)
  const { data: recentAmounts } = await supabase
    .from('driver_withdrawal_requests')
    .select('amount')
    .eq('driver_id', driverId)
    .gte('requested_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()) // Last 7 days
    .order('requested_at', { ascending: false })
    .limit(10)

  if (recentAmounts) {
    const similarAmounts = recentAmounts.filter(req => Math.abs(req.amount - amount) < 1.0).length
    if (similarAmounts >= FRAUD_DETECTION_CONFIG.SUSPICIOUS_PATTERN_THRESHOLD) {
      fraudChecks.suspicious_pattern = true
      riskScore += 25
      reasons.push(`${similarAmounts} similar amounts recently`)
    }
  }

  // Check 4: Daily request limit
  const todayStart = new Date()
  todayStart.setHours(0, 0, 0, 0)
  const { data: todayRequests } = await supabase
    .from('driver_withdrawal_requests')
    .select('id')
    .eq('driver_id', driverId)
    .gte('requested_at', todayStart.toISOString())

  if (todayRequests && todayRequests.length >= FRAUD_DETECTION_CONFIG.MAX_DAILY_REQUESTS) {
    fraudChecks.daily_limit_check = true
    riskScore += 35
    reasons.push(`${todayRequests.length} requests today`)
  }

  // Check 5: Velocity check (total amount in 24 hours)
  const velocityWindow = new Date(Date.now() - FRAUD_DETECTION_CONFIG.VELOCITY_CHECK_WINDOW)
  const { data: velocityRequests } = await supabase
    .from('driver_withdrawal_requests')
    .select('amount')
    .eq('driver_id', driverId)
    .gte('requested_at', velocityWindow.toISOString())
    .in('status', ['pending', 'processing', 'completed'])

  if (velocityRequests) {
    const totalAmount = velocityRequests.reduce((sum, req) => sum + req.amount, 0) + amount
    if (totalAmount > 2000) { // RM 2000 in 24 hours
      fraudChecks.velocity_check = true
      riskScore += 30
      reasons.push(`High velocity: RM ${totalAmount} in 24h`)
    }
  }

  // Determine risk level
  let riskLevel = 'low'
  if (riskScore >= 80) riskLevel = 'high'
  else if (riskScore >= 50) riskLevel = 'medium'

  console.log(`🔍 Fraud detection completed - Score: ${riskScore}, Level: ${riskLevel}`)

  return {
    score: riskScore,
    risk_level: riskLevel,
    checks: fraudChecks,
    reason: reasons.join(', ') || 'No fraud indicators detected'
  }
}

async function updateWithdrawalStatus(supabase: any, userId: string, request: WithdrawalManagementRequest) {
  const { request_id, new_status, admin_notes, failure_reason, transaction_reference } = request

  console.log('🔍 Updating withdrawal status:', { request_id, new_status })

  // Validate user access (admin or driver)
  const user = await validateUserAccess(supabase, userId)

  // Get withdrawal request
  const { data: withdrawalRequest, error } = await supabase
    .from('driver_withdrawal_requests')
    .select('*')
    .eq('id', request_id)
    .single()

  if (error || !withdrawalRequest) {
    throw new Error('Withdrawal request not found')
  }

  // Check permissions
  if (user.role !== 'admin') {
    // Non-admin users can only update their own requests and only to 'cancelled'
    const driver = await validateDriverAccess(supabase, userId)
    if (withdrawalRequest.driver_id !== driver.id) {
      throw new Error('Access denied: Cannot update other drivers\' requests')
    }
    if (new_status !== 'cancelled') {
      throw new Error('Access denied: Only cancellation is allowed for drivers')
    }
  }

  // Validate status transition
  const validTransitions = {
    'pending': ['processing', 'cancelled', 'failed'],
    'processing': ['completed', 'failed'],
    'completed': [], // Final state
    'failed': ['pending'], // Allow retry
    'cancelled': [] // Final state
  }

  const allowedStatuses = validTransitions[withdrawalRequest.status] || []
  if (!allowedStatuses.includes(new_status)) {
    throw new Error(`Invalid status transition from ${withdrawalRequest.status} to ${new_status}`)
  }

  // Use database function to update status
  const { data: result, error: updateError } = await supabase
    .rpc('update_withdrawal_status', {
      p_request_id: request_id,
      p_status: new_status,
      p_transaction_reference: transaction_reference,
      p_failure_reason: failure_reason,
      p_processed_by: userId
    })

  if (updateError) {
    throw new Error(`Failed to update withdrawal status: ${updateError.message}`)
  }

  // Add admin notes if provided
  if (admin_notes && user.role === 'admin') {
    await supabase
      .from('driver_withdrawal_requests')
      .update({
        notes: admin_notes,
        updated_at: new Date().toISOString()
      })
      .eq('id', request_id)
  }

  console.log('✅ Withdrawal status updated successfully')
  return result
}

async function getWithdrawalRequests(supabase: any, userId: string, request: WithdrawalManagementRequest) {
  const { filters = {}, pagination = {} } = request

  console.log('🔍 Getting withdrawal requests with filters:', filters)

  // Validate user access
  const user = await validateUserAccess(supabase, userId)

  let query = supabase
    .from('driver_withdrawal_requests')
    .select(`
      *,
      drivers!inner(id, user_id, full_name),
      stakeholder_wallets!inner(user_id)
    `)

  // Apply role-based filtering
  if (user.role !== 'admin') {
    // Non-admin users can only see their own requests
    const driver = await validateDriverAccess(supabase, userId)
    query = query.eq('driver_id', driver.id)
  } else if (filters.driver_id) {
    // Admin can filter by specific driver
    query = query.eq('driver_id', filters.driver_id)
  }

  // Apply filters
  if (filters.status) {
    query = query.eq('status', filters.status)
  }
  if (filters.method) {
    query = query.eq('withdrawal_method', filters.method)
  }
  if (filters.start_date) {
    query = query.gte('requested_at', filters.start_date)
  }
  if (filters.end_date) {
    query = query.lte('requested_at', filters.end_date)
  }
  if (filters.min_amount) {
    query = query.gte('amount', filters.min_amount)
  }
  if (filters.max_amount) {
    query = query.lte('amount', filters.max_amount)
  }

  // Apply pagination and sorting
  const page = pagination.page || 1
  const limit = Math.min(pagination.limit || 20, 100) // Max 100 items per page
  const offset = (page - 1) * limit
  const sortBy = pagination.sort_by || 'requested_at'
  const sortOrder = pagination.sort_order || 'desc'

  query = query
    .order(sortBy, { ascending: sortOrder === 'asc' })
    .range(offset, offset + limit - 1)

  const { data: requests, error, count } = await query

  if (error) {
    throw new Error(`Failed to get withdrawal requests: ${error.message}`)
  }

  // Mask sensitive data for non-admin users
  const maskedRequests = requests?.map(req => ({
    ...req,
    destination_details: user.role === 'admin' ? req.destination_details : maskBankDetails(req.destination_details)
  }))

  console.log('✅ Withdrawal requests retrieved successfully')
  return {
    requests: maskedRequests,
    pagination: {
      page,
      limit,
      total: count,
      total_pages: Math.ceil((count || 0) / limit)
    }
  }
}

function maskBankDetails(details: any) {
  if (!details || !details.account_number) return details

  return {
    ...details,
    account_number: details.account_number.replace(/\d(?=\d{4})/g, '*')
  }
}

async function getWithdrawalRequestDetails(supabase: any, userId: string, request: WithdrawalManagementRequest) {
  const { request_id } = request

  console.log('🔍 Getting withdrawal request details:', request_id)

  // Validate user access
  const user = await validateUserAccess(supabase, userId)

  let query = supabase
    .from('driver_withdrawal_requests')
    .select(`
      *,
      drivers!inner(id, user_id, full_name, phone_number),
      stakeholder_wallets!inner(user_id, available_balance)
    `)
    .eq('id', request_id)

  // Apply role-based filtering
  if (user.role !== 'admin') {
    const driver = await validateDriverAccess(supabase, userId)
    query = query.eq('driver_id', driver.id)
  }

  const { data: requestDetails, error } = await query.single()

  if (error || !requestDetails) {
    throw new Error('Withdrawal request not found or access denied')
  }

  // Get related transactions if completed
  let relatedTransactions = []
  if (requestDetails.status === 'completed') {
    const { data: transactions } = await supabase
      .from('wallet_transactions')
      .select('*')
      .eq('reference_id', request_id)
      .eq('reference_type', 'withdrawal_request')
      .order('created_at', { ascending: false })

    relatedTransactions = transactions || []
  }

  // Mask sensitive data for non-admin users
  if (user.role !== 'admin') {
    requestDetails.destination_details = maskBankDetails(requestDetails.destination_details)
  }

  console.log('✅ Withdrawal request details retrieved successfully')
  return {
    ...requestDetails,
    related_transactions: relatedTransactions
  }
}

async function cancelWithdrawalRequest(supabase: any, userId: string, request: WithdrawalManagementRequest) {
  const { request_id, notes } = request

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

  // Use database function to update status
  const { data: result, error: updateError } = await supabase
    .rpc('update_withdrawal_status', {
      p_request_id: request_id,
      p_status: 'cancelled',
      p_failure_reason: notes || 'Cancelled by user',
      p_processed_by: userId
    })

  if (updateError) {
    throw new Error(`Failed to cancel withdrawal: ${updateError.message}`)
  }

  console.log('✅ Withdrawal request cancelled successfully')
  return result
}

async function approveWithdrawalRequest(supabase: any, userId: string, request: WithdrawalManagementRequest) {
  const { request_id, admin_notes, transaction_reference } = request

  console.log('🔍 Approving withdrawal request:', request_id)

  // Validate admin access
  const user = await validateUserAccess(supabase, userId)
  if (user.role !== 'admin') {
    throw new Error('Access denied: Only administrators can approve withdrawal requests')
  }

  // Get withdrawal request
  const { data: withdrawalRequest, error } = await supabase
    .from('driver_withdrawal_requests')
    .select('*')
    .eq('id', request_id)
    .single()

  if (error || !withdrawalRequest) {
    throw new Error('Withdrawal request not found')
  }

  // Only allow approval of pending requests
  if (withdrawalRequest.status !== 'pending') {
    throw new Error(`Cannot approve withdrawal request with status: ${withdrawalRequest.status}`)
  }

  // Update status to processing
  const { data: result, error: updateError } = await supabase
    .rpc('update_withdrawal_status', {
      p_request_id: request_id,
      p_status: 'processing',
      p_transaction_reference: transaction_reference,
      p_processed_by: userId
    })

  if (updateError) {
    throw new Error(`Failed to approve withdrawal: ${updateError.message}`)
  }

  // Add admin notes
  if (admin_notes) {
    await supabase
      .from('driver_withdrawal_requests')
      .update({
        notes: admin_notes,
        updated_at: new Date().toISOString()
      })
      .eq('id', request_id)
  }

  console.log('✅ Withdrawal request approved successfully')
  return result
}

async function rejectWithdrawalRequest(supabase: any, userId: string, request: WithdrawalManagementRequest) {
  const { request_id, admin_notes, failure_reason } = request

  console.log('🔍 Rejecting withdrawal request:', request_id)

  // Validate admin access
  const user = await validateUserAccess(supabase, userId)
  if (user.role !== 'admin') {
    throw new Error('Access denied: Only administrators can reject withdrawal requests')
  }

  // Get withdrawal request
  const { data: withdrawalRequest, error } = await supabase
    .from('driver_withdrawal_requests')
    .select('*')
    .eq('id', request_id)
    .single()

  if (error || !withdrawalRequest) {
    throw new Error('Withdrawal request not found')
  }

  // Only allow rejection of pending or processing requests
  if (!['pending', 'processing'].includes(withdrawalRequest.status)) {
    throw new Error(`Cannot reject withdrawal request with status: ${withdrawalRequest.status}`)
  }

  // Update status to failed
  const { data: result, error: updateError } = await supabase
    .rpc('update_withdrawal_status', {
      p_request_id: request_id,
      p_status: 'failed',
      p_failure_reason: failure_reason || 'Rejected by administrator',
      p_processed_by: userId
    })

  if (updateError) {
    throw new Error(`Failed to reject withdrawal: ${updateError.message}`)
  }

  // Add admin notes
  if (admin_notes) {
    await supabase
      .from('driver_withdrawal_requests')
      .update({
        notes: admin_notes,
        updated_at: new Date().toISOString()
      })
      .eq('id', request_id)
  }

  console.log('✅ Withdrawal request rejected successfully')
  return result
}

async function processBatchRequests(supabase: any, userId: string, request: WithdrawalManagementRequest) {
  const { request_ids, batch_action, admin_notes } = request

  console.log('🔍 Processing batch requests:', { request_ids, batch_action })

  // Validate admin access
  const user = await validateUserAccess(supabase, userId)
  if (user.role !== 'admin') {
    throw new Error('Access denied: Only administrators can process batch requests')
  }

  if (!request_ids || request_ids.length === 0) {
    throw new Error('No request IDs provided for batch processing')
  }

  if (!['approve', 'reject', 'process'].includes(batch_action)) {
    throw new Error('Invalid batch action. Must be approve, reject, or process')
  }

  const results = []
  const errors = []

  // Process each request
  for (const requestId of request_ids) {
    try {
      let result
      switch (batch_action) {
        case 'approve':
          result = await approveWithdrawalRequest(supabase, userId, {
            action: 'approve_request',
            request_id: requestId,
            admin_notes
          })
          break
        case 'reject':
          result = await rejectWithdrawalRequest(supabase, userId, {
            action: 'reject_request',
            request_id: requestId,
            admin_notes,
            failure_reason: 'Batch rejection'
          })
          break
        case 'process':
          result = await updateWithdrawalStatus(supabase, userId, {
            action: 'update_status',
            request_id: requestId,
            new_status: 'processing',
            admin_notes
          })
          break
      }

      results.push({
        request_id: requestId,
        success: true,
        result
      })
    } catch (error) {
      errors.push({
        request_id: requestId,
        success: false,
        error: error.message
      })
    }
  }

  console.log('✅ Batch processing completed')
  return {
    batch_action,
    total_requests: request_ids.length,
    successful: results.length,
    failed: errors.length,
    results,
    errors
  }
}

async function getWithdrawalLimits(supabase: any, userId: string, request: WithdrawalManagementRequest) {
  console.log('🔍 Getting withdrawal limits for user:', userId)

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  // Get withdrawal limits
  const { data: limits, error } = await supabase
    .from('driver_withdrawal_limits')
    .select('*')
    .eq('driver_id', driver.id)
    .single()

  if (error && error.code !== 'PGRST116') { // Not found error
    throw new Error(`Failed to get withdrawal limits: ${error.message}`)
  }

  // Get wallet settings
  const { data: settings } = await supabase
    .from('driver_wallet_settings')
    .select('minimum_withdrawal_amount, maximum_daily_withdrawal, auto_payout_threshold')
    .eq('driver_id', driver.id)
    .single()

  // Calculate usage for current periods
  const now = new Date()
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const weekStart = new Date(todayStart.getTime() - (todayStart.getDay() * 24 * 60 * 60 * 1000))
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1)

  // Get current usage
  const { data: dailyUsage } = await supabase
    .from('driver_withdrawal_requests')
    .select('amount')
    .eq('driver_id', driver.id)
    .gte('requested_at', todayStart.toISOString())
    .in('status', ['pending', 'processing', 'completed'])

  const { data: weeklyUsage } = await supabase
    .from('driver_withdrawal_requests')
    .select('amount')
    .eq('driver_id', driver.id)
    .gte('requested_at', weekStart.toISOString())
    .in('status', ['pending', 'processing', 'completed'])

  const { data: monthlyUsage } = await supabase
    .from('driver_withdrawal_requests')
    .select('amount')
    .eq('driver_id', driver.id)
    .gte('requested_at', monthStart.toISOString())
    .in('status', ['pending', 'processing', 'completed'])

  const dailyUsed = dailyUsage?.reduce((sum, req) => sum + req.amount, 0) || 0
  const weeklyUsed = weeklyUsage?.reduce((sum, req) => sum + req.amount, 0) || 0
  const monthlyUsed = monthlyUsage?.reduce((sum, req) => sum + req.amount, 0) || 0

  console.log('✅ Withdrawal limits retrieved successfully')
  return {
    limits: limits || {
      daily_limit: 1000.00,
      weekly_limit: 5000.00,
      monthly_limit: 20000.00,
      risk_level: 'low'
    },
    settings: settings || {
      minimum_withdrawal_amount: 10.00,
      maximum_daily_withdrawal: 1000.00,
      auto_payout_threshold: 100.00
    },
    current_usage: {
      daily_used: dailyUsed,
      weekly_used: weeklyUsed,
      monthly_used: monthlyUsed,
      daily_remaining: Math.max(0, (limits?.daily_limit || 1000) - dailyUsed),
      weekly_remaining: Math.max(0, (limits?.weekly_limit || 5000) - weeklyUsed),
      monthly_remaining: Math.max(0, (limits?.monthly_limit || 20000) - monthlyUsed)
    }
  }
}

async function updateWithdrawalLimits(supabase: any, userId: string, request: WithdrawalManagementRequest) {
  const { limit_type, limit_amount } = request

  console.log('🔍 Updating withdrawal limits:', { limit_type, limit_amount })

  // Validate admin access (only admins can update limits)
  const user = await validateUserAccess(supabase, userId)
  if (user.role !== 'admin') {
    throw new Error('Access denied: Only administrators can update withdrawal limits')
  }

  if (!limit_type || !limit_amount) {
    throw new Error('Limit type and amount are required')
  }

  if (!['daily', 'weekly', 'monthly'].includes(limit_type)) {
    throw new Error('Invalid limit type. Must be daily, weekly, or monthly')
  }

  if (limit_amount <= 0) {
    throw new Error('Limit amount must be positive')
  }

  // Update the limit
  const updateField = `${limit_type}_limit`
  const { error } = await supabase
    .from('driver_withdrawal_limits')
    .update({
      [updateField]: limit_amount,
      updated_at: new Date().toISOString()
    })
    .eq('driver_id', request.filters?.driver_id)

  if (error) {
    throw new Error(`Failed to update withdrawal limits: ${error.message}`)
  }

  console.log('✅ Withdrawal limits updated successfully')
  return {
    limit_type,
    new_limit: limit_amount,
    updated_at: new Date().toISOString()
  }
}

async function checkFraudScore(supabase: any, userId: string, request: WithdrawalManagementRequest) {
  const { amount, withdrawal_method = 'bank_transfer' } = request

  console.log('🔍 Checking fraud score for amount:', amount)

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  if (!amount || amount <= 0) {
    throw new Error('Valid amount is required for fraud score check')
  }

  // Perform fraud detection
  const fraudScore = await performFraudDetection(supabase, driver.id, amount, withdrawal_method)

  console.log('✅ Fraud score check completed')
  return fraudScore
}

async function getWithdrawalAnalytics(supabase: any, userId: string, request: WithdrawalManagementRequest) {
  const { filters = {} } = request

  console.log('🔍 Getting withdrawal analytics')

  // Validate admin access (only admins can view analytics)
  const user = await validateUserAccess(supabase, userId)
  if (user.role !== 'admin') {
    throw new Error('Access denied: Only administrators can view withdrawal analytics')
  }

  // Set default date range (last 30 days)
  const endDate = filters.end_date ? new Date(filters.end_date) : new Date()
  const startDate = filters.start_date ? new Date(filters.start_date) : new Date(endDate.getTime() - 30 * 24 * 60 * 60 * 1000)

  // Get withdrawal statistics
  const { data: withdrawalStats, error: statsError } = await supabase
    .from('driver_withdrawal_requests')
    .select('status, amount, withdrawal_method, requested_at, processed_at, completed_at')
    .gte('requested_at', startDate.toISOString())
    .lte('requested_at', endDate.toISOString())

  if (statsError) {
    throw new Error(`Failed to get withdrawal statistics: ${statsError.message}`)
  }

  // Calculate analytics
  const analytics = {
    period: {
      start_date: startDate.toISOString(),
      end_date: endDate.toISOString(),
      days: Math.ceil((endDate.getTime() - startDate.getTime()) / (24 * 60 * 60 * 1000))
    },
    totals: {
      total_requests: withdrawalStats.length,
      total_amount: withdrawalStats.reduce((sum, req) => sum + req.amount, 0),
      pending_requests: withdrawalStats.filter(req => req.status === 'pending').length,
      processing_requests: withdrawalStats.filter(req => req.status === 'processing').length,
      completed_requests: withdrawalStats.filter(req => req.status === 'completed').length,
      failed_requests: withdrawalStats.filter(req => req.status === 'failed').length,
      cancelled_requests: withdrawalStats.filter(req => req.status === 'cancelled').length
    },
    amounts: {
      total_completed_amount: withdrawalStats
        .filter(req => req.status === 'completed')
        .reduce((sum, req) => sum + req.amount, 0),
      average_request_amount: withdrawalStats.length > 0 ?
        withdrawalStats.reduce((sum, req) => sum + req.amount, 0) / withdrawalStats.length : 0,
      largest_request: Math.max(...withdrawalStats.map(req => req.amount), 0),
      smallest_request: withdrawalStats.length > 0 ? Math.min(...withdrawalStats.map(req => req.amount)) : 0
    },
    by_method: {
      bank_transfer: withdrawalStats.filter(req => req.withdrawal_method === 'bank_transfer').length,
      ewallet: withdrawalStats.filter(req => req.withdrawal_method === 'ewallet').length,
      cash: withdrawalStats.filter(req => req.withdrawal_method === 'cash').length
    },
    performance: {
      success_rate: withdrawalStats.length > 0 ?
        (withdrawalStats.filter(req => req.status === 'completed').length / withdrawalStats.length) * 100 : 0,
      average_processing_time_hours: calculateAverageProcessingTime(withdrawalStats),
      requests_per_day: withdrawalStats.length / Math.max(1, Math.ceil((endDate.getTime() - startDate.getTime()) / (24 * 60 * 60 * 1000)))
    }
  }

  // Get fraud statistics
  const { data: fraudStats } = await supabase
    .from('driver_withdrawal_requests')
    .select('metadata')
    .gte('requested_at', startDate.toISOString())
    .lte('requested_at', endDate.toISOString())
    .not('metadata', 'is', null)

  const fraudAnalytics = {
    high_risk_requests: 0,
    medium_risk_requests: 0,
    low_risk_requests: 0,
    average_fraud_score: 0
  }

  if (fraudStats) {
    const fraudScores = fraudStats
      .map(req => req.metadata?.fraud_score)
      .filter(score => typeof score === 'number')

    fraudAnalytics.average_fraud_score = fraudScores.length > 0 ?
      fraudScores.reduce((sum, score) => sum + score, 0) / fraudScores.length : 0

    fraudStats.forEach(req => {
      const riskLevel = req.metadata?.risk_level
      if (riskLevel === 'high') fraudAnalytics.high_risk_requests++
      else if (riskLevel === 'medium') fraudAnalytics.medium_risk_requests++
      else if (riskLevel === 'low') fraudAnalytics.low_risk_requests++
    })
  }

  console.log('✅ Withdrawal analytics retrieved successfully')
  return {
    ...analytics,
    fraud_analytics: fraudAnalytics
  }
}

function calculateAverageProcessingTime(withdrawalStats: any[]) {
  const completedRequests = withdrawalStats.filter(req =>
    req.status === 'completed' && req.requested_at && req.completed_at
  )

  if (completedRequests.length === 0) return 0

  const totalProcessingTime = completedRequests.reduce((sum, req) => {
    const requestedAt = new Date(req.requested_at)
    const completedAt = new Date(req.completed_at)
    return sum + (completedAt.getTime() - requestedAt.getTime())
  }, 0)

  // Return average processing time in hours
  return (totalProcessingTime / completedRequests.length) / (1000 * 60 * 60)
}
