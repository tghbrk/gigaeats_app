import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface SecureWalletRequest {
  action: 'validate_access' | 'validate_transaction' | 'process_transaction' | 'get_audit_trail' |
          'get_balance' | 'get_transaction_history' | 'process_order_payment' | 'process_refund' |
          'validate_payment_limits' | 'get_wallet_analytics' | 'sync_wallet_state'
  wallet_id?: string
  transaction_data?: {
    amount: number
    transaction_type: string
    reference_id?: string
    description?: string
    metadata?: Record<string, any>
  }
  operation?: string
  context?: Record<string, any>
  audit_filters?: {
    start_date?: string
    end_date?: string
    event_types?: string[]
  }
  // Additional parameters for new actions
  order_id?: string
  payment_method?: string
  analytics_period?: 'day' | 'week' | 'month' | 'year'
  pagination?: {
    page: number
    limit: number
  }
}

interface SecurityValidationResult {
  valid: boolean
  error_message?: string
  risk_score?: number
  compliance_flags?: string[]
}

interface TransactionValidationResult {
  valid: boolean
  error_message?: string
  violation_type?: string
  compliance_status: 'approved' | 'requires_review' | 'blocked'
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
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

    const requestBody: SecureWalletRequest = await req.json()
    const { action } = requestBody

    let response: any

    switch (action) {
      case 'validate_access':
        response = await validateWalletAccess(supabaseClient, user.id, requestBody)
        break
      case 'validate_transaction':
        response = await validateTransaction(supabaseClient, user.id, requestBody)
        break
      case 'process_transaction':
        response = await processSecureTransaction(supabaseClient, user.id, requestBody)
        break
      case 'get_audit_trail':
        response = await getAuditTrail(supabaseClient, user.id, requestBody)
        break
      case 'get_balance':
        response = await getWalletBalance(supabaseClient, user.id, requestBody)
        break
      case 'get_transaction_history':
        response = await getTransactionHistory(supabaseClient, user.id, requestBody)
        break
      case 'process_order_payment':
        response = await processOrderPayment(supabaseClient, user.id, requestBody)
        break
      case 'process_refund':
        response = await processRefund(supabaseClient, user.id, requestBody)
        break
      case 'validate_payment_limits':
        response = await validatePaymentLimits(supabaseClient, user.id, requestBody)
        break
      case 'get_wallet_analytics':
        response = await getWalletAnalytics(supabaseClient, user.id, requestBody)
        break
      case 'sync_wallet_state':
        response = await syncWalletState(supabaseClient, user.id, requestBody)
        break
      default:
        throw new Error(`Unsupported action: ${action}`)
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    console.error('Secure wallet operations error:', error)
    
    return new Response(
      JSON.stringify({ 
        error: error.message,
        timestamp: new Date().toISOString()
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})

async function validateWalletAccess(
  supabase: any,
  userId: string,
  request: SecureWalletRequest
): Promise<SecurityValidationResult> {
  const { wallet_id, operation, context } = request

  if (!wallet_id || !operation) {
    return {
      valid: false,
      error_message: 'wallet_id and operation are required for access validation'
    }
  }

  try {
    // Check wallet ownership using RLS-protected function
    const { data: ownershipValid, error: ownershipError } = await supabase
      .rpc('validate_wallet_ownership', {
        wallet_id: wallet_id,
        user_id: userId
      })

    if (ownershipError || !ownershipValid) {
      // Log unauthorized access attempt
      await logSecurityEvent(supabase, {
        event_type: 'unauthorized_wallet_access_attempt',
        user_id: userId,
        entity_type: 'wallet',
        entity_id: wallet_id,
        event_data: {
          operation,
          context,
          ip_address: context?.ip_address,
          user_agent: context?.user_agent
        },
        severity: 'high'
      })

      return {
        valid: false,
        error_message: 'Unauthorized wallet access',
        risk_score: 90,
        compliance_flags: ['unauthorized_access']
      }
    }

    // Check for suspicious activity patterns
    const suspiciousActivity = await detectSuspiciousActivity(supabase, userId, operation, context)
    
    if (suspiciousActivity.risk_score > 80) {
      await logSecurityEvent(supabase, {
        event_type: 'suspicious_activity_detected',
        user_id: userId,
        entity_type: 'wallet',
        entity_id: wallet_id,
        event_data: {
          operation,
          suspicious_indicators: suspiciousActivity.indicators,
          risk_score: suspiciousActivity.risk_score
        },
        severity: 'critical'
      })

      return {
        valid: false,
        error_message: 'Activity blocked due to security concerns',
        risk_score: suspiciousActivity.risk_score,
        compliance_flags: ['suspicious_activity']
      }
    }

    return {
      valid: true,
      risk_score: suspiciousActivity.risk_score,
      compliance_flags: suspiciousActivity.indicators
    }

  } catch (error) {
    console.error('Wallet access validation error:', error)
    return {
      valid: false,
      error_message: `Access validation failed: ${error.message}`
    }
  }
}

async function validateTransaction(
  supabase: any,
  userId: string,
  request: SecureWalletRequest
): Promise<TransactionValidationResult> {
  const { wallet_id, transaction_data } = request

  if (!wallet_id || !transaction_data) {
    return {
      valid: false,
      error_message: 'wallet_id and transaction_data are required',
      compliance_status: 'blocked'
    }
  }

  try {
    const { amount, transaction_type, reference_id, metadata } = transaction_data

    // Check Malaysian regulatory limits using database function
    const { data: limitsValid, error: limitsError } = await supabase
      .rpc('check_transaction_limits', {
        wallet_id: wallet_id,
        transaction_amount: amount,
        transaction_type: transaction_type
      })

    if (limitsError || !limitsValid) {
      await logSecurityEvent(supabase, {
        event_type: 'transaction_limit_exceeded',
        user_id: userId,
        entity_type: 'transaction',
        entity_id: reference_id || 'unknown',
        event_data: {
          wallet_id,
          amount,
          transaction_type,
          limit_type: 'bnm_compliance'
        },
        severity: 'high'
      })

      return {
        valid: false,
        error_message: 'Transaction exceeds regulatory limits (BNM compliance)',
        violation_type: 'regulatory_limit',
        compliance_status: 'blocked'
      }
    }

    // Perform AML (Anti-Money Laundering) checks
    const amlResult = await performAMLCheck(supabase, wallet_id, amount, transaction_type, metadata)
    
    if (amlResult.requires_review) {
      await logSecurityEvent(supabase, {
        event_type: 'aml_review_required',
        user_id: userId,
        entity_type: 'transaction',
        entity_id: reference_id || 'unknown',
        event_data: {
          wallet_id,
          amount,
          transaction_type,
          aml_indicators: amlResult.indicators,
          risk_score: amlResult.risk_score
        },
        severity: 'critical'
      })

      if (amlResult.risk_score > 90) {
        return {
          valid: false,
          error_message: 'Transaction blocked for AML review',
          violation_type: 'aml_violation',
          compliance_status: 'blocked'
        }
      }

      return {
        valid: true,
        compliance_status: 'requires_review'
      }
    }

    return {
      valid: true,
      compliance_status: 'approved'
    }

  } catch (error) {
    console.error('Transaction validation error:', error)
    return {
      valid: false,
      error_message: `Transaction validation failed: ${error.message}`,
      compliance_status: 'blocked'
    }
  }
}

async function processSecureTransaction(
  supabase: any,
  userId: string,
  request: SecureWalletRequest
): Promise<any> {
  const { wallet_id, transaction_data } = request

  if (!wallet_id || !transaction_data) {
    throw new Error('wallet_id and transaction_data are required for transaction processing')
  }

  try {
    // First validate the transaction
    const validationResult = await validateTransaction(supabase, userId, request)
    
    if (!validationResult.valid) {
      throw new Error(validationResult.error_message || 'Transaction validation failed')
    }

    if (validationResult.compliance_status === 'blocked') {
      throw new Error('Transaction blocked by compliance checks')
    }

    const { amount, transaction_type, reference_id, description, metadata } = transaction_data

    // Begin database transaction
    const { data: transaction, error: transactionError } = await supabase
      .from('wallet_transactions')
      .insert({
        wallet_id: wallet_id,
        amount: transaction_type.includes('debit') || transaction_type === 'order_payment' ? -Math.abs(amount) : Math.abs(amount),
        transaction_type: transaction_type,
        reference_type: metadata?.reference_type || 'manual',
        reference_id: reference_id,
        description: description,
        status: validationResult.compliance_status === 'requires_review' ? 'pending_review' : 'completed',
        metadata: {
          ...metadata,
          compliance_status: validationResult.compliance_status,
          processed_by: 'secure_edge_function',
          processed_at: new Date().toISOString()
        }
      })
      .select()
      .single()

    if (transactionError) {
      throw new Error(`Transaction creation failed: ${transactionError.message}`)
    }

    // Update wallet balance if transaction is approved
    if (validationResult.compliance_status === 'approved') {
      const balanceChange = transaction_type.includes('debit') || transaction_type === 'order_payment' ? -Math.abs(amount) : Math.abs(amount)
      
      const { error: balanceError } = await supabase
        .from('stakeholder_wallets')
        .update({
          available_balance: supabase.sql`available_balance + ${balanceChange}`,
          updated_at: new Date().toISOString(),
          last_activity_at: new Date().toISOString()
        })
        .eq('id', wallet_id)

      if (balanceError) {
        throw new Error(`Balance update failed: ${balanceError.message}`)
      }
    }

    // Log successful transaction
    await logSecurityEvent(supabase, {
      event_type: 'transaction_processed',
      user_id: userId,
      entity_type: 'transaction',
      entity_id: transaction.id,
      event_data: {
        wallet_id,
        amount,
        transaction_type,
        compliance_status: validationResult.compliance_status,
        reference_id
      },
      severity: 'low'
    })

    return {
      success: true,
      transaction_id: transaction.id,
      compliance_status: validationResult.compliance_status,
      message: validationResult.compliance_status === 'requires_review' 
        ? 'Transaction created and pending compliance review'
        : 'Transaction processed successfully'
    }

  } catch (error) {
    console.error('Secure transaction processing error:', error)
    
    // Log failed transaction attempt
    await logSecurityEvent(supabase, {
      event_type: 'transaction_processing_failed',
      user_id: userId,
      entity_type: 'wallet',
      entity_id: wallet_id,
      event_data: {
        error_message: error.message,
        transaction_data
      },
      severity: 'medium'
    })

    throw error
  }
}

async function getAuditTrail(
  supabase: any,
  userId: string,
  request: SecureWalletRequest
): Promise<any> {
  const { wallet_id, audit_filters } = request

  try {
    let query = supabase
      .from('financial_audit_log')
      .select('*')
      .eq('user_id', userId)

    if (wallet_id) {
      query = query.eq('entity_id', wallet_id)
    }

    if (audit_filters?.start_date) {
      query = query.gte('created_at', audit_filters.start_date)
    }

    if (audit_filters?.end_date) {
      query = query.lte('created_at', audit_filters.end_date)
    }

    if (audit_filters?.event_types && audit_filters.event_types.length > 0) {
      query = query.in('event_type', audit_filters.event_types)
    }

    const { data: auditLogs, error: auditError } = await query
      .order('created_at', { ascending: false })
      .limit(100)

    if (auditError) {
      throw new Error(`Audit trail retrieval failed: ${auditError.message}`)
    }

    return {
      success: true,
      audit_logs: auditLogs,
      total_count: auditLogs.length
    }

  } catch (error) {
    console.error('Audit trail retrieval error:', error)
    throw error
  }
}

async function detectSuspiciousActivity(
  supabase: any,
  userId: string,
  operation: string,
  context?: Record<string, any>
): Promise<{ risk_score: number; indicators: string[] }> {
  try {
    // Get recent activity for pattern analysis
    const { data: recentActivity } = await supabase
      .from('financial_audit_log')
      .select('event_type, created_at, event_data')
      .eq('user_id', userId)
      .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
      .order('created_at', { ascending: false })
      .limit(50)

    const indicators: string[] = []
    let riskScore = 0

    // Check for high frequency operations
    if (recentActivity && recentActivity.length > 20) {
      indicators.push('high_frequency_operations')
      riskScore += 30
    }

    // Check for unusual timing
    const currentHour = new Date().getHours()
    if (currentHour < 6 || currentHour > 23) {
      indicators.push('unusual_timing')
      riskScore += 15
    }

    // Check for repeated operation patterns
    if (recentActivity) {
      const operationCounts: Record<string, number> = {}
      recentActivity.forEach((activity: any) => {
        const eventType = activity.event_type
        operationCounts[eventType] = (operationCounts[eventType] || 0) + 1
      })

      if (operationCounts[operation] && operationCounts[operation] > 10) {
        indicators.push('repeated_operation_pattern')
        riskScore += 25
      }
    }

    return { risk_score: riskScore, indicators }

  } catch (error) {
    console.error('Suspicious activity detection error:', error)
    return { risk_score: 0, indicators: [] }
  }
}

async function performAMLCheck(
  supabase: any,
  walletId: string,
  amount: number,
  transactionType: string,
  metadata?: Record<string, any>
): Promise<{ requires_review: boolean; indicators: string[]; risk_score: number }> {
  try {
    const indicators: string[] = []
    let riskScore = 0

    // Check for large transactions
    if (amount > 1000) {
      indicators.push('large_transaction')
      riskScore += 20
    }

    // Check for round number transactions (potential structuring)
    if (amount % 100 === 0 && amount >= 500) {
      indicators.push('round_number_transaction')
      riskScore += 15
    }

    // Get recent transactions for pattern analysis
    const { data: recentTransactions } = await supabase
      .from('wallet_transactions')
      .select('amount, transaction_type, created_at')
      .eq('wallet_id', walletId)
      .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
      .order('created_at', { ascending: false })

    if (recentTransactions) {
      // Check for structuring patterns
      const structuringTransactions = recentTransactions.filter(
        (t: any) => Math.abs(t.amount) > 900 && Math.abs(t.amount) < 1000
      ).length

      if (structuringTransactions > 3) {
        indicators.push('potential_structuring')
        riskScore += 40
      }

      // Check for rapid succession of transactions
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000)
      const rapidTransactions = recentTransactions.filter(
        (t: any) => new Date(t.created_at) > oneHourAgo
      ).length

      if (rapidTransactions > 5) {
        indicators.push('rapid_transaction_pattern')
        riskScore += 25
      }
    }

    return {
      requires_review: riskScore > 50,
      indicators,
      risk_score: riskScore
    }

  } catch (error) {
    console.error('AML check error:', error)
    return { requires_review: false, indicators: [], risk_score: 0 }
  }
}

async function logSecurityEvent(
  supabase: any,
  eventData: {
    event_type: string
    user_id: string
    entity_type: string
    entity_id: string
    event_data: Record<string, any>
    severity: string
  }
): Promise<void> {
  try {
    await supabase.rpc('log_security_event', {
      event_type: eventData.event_type,
      user_id: eventData.user_id,
      entity_type: eventData.entity_type,
      entity_id: eventData.entity_id,
      event_data: eventData.event_data,
      ip_address: eventData.event_data.ip_address || null,
      user_agent: eventData.event_data.user_agent || null
    })
  } catch (error) {
    console.error('Security event logging error:', error)
  }
}

// Enhanced wallet operations functions
async function getWalletBalance(
  supabase: any,
  userId: string,
  request: SecureWalletRequest
): Promise<any> {
  try {
    const { wallet_id } = request

    // Get wallet with balance information
    const { data: wallet, error: walletError } = await supabase
      .from('stakeholder_wallets')
      .select(`
        id,
        available_balance,
        pending_balance,
        total_earned,
        total_spent,
        is_active,
        last_activity_at,
        created_at,
        updated_at
      `)
      .eq('user_id', userId)
      .eq('id', wallet_id || '')
      .single()

    if (walletError) {
      throw new Error(`Failed to fetch wallet balance: ${walletError.message}`)
    }

    // Get pending transactions count
    const { count: pendingCount } = await supabase
      .from('wallet_transactions')
      .select('*', { count: 'exact', head: true })
      .eq('wallet_id', wallet.id)
      .eq('status', 'pending')

    return {
      success: true,
      wallet: {
        ...wallet,
        pending_transactions_count: pendingCount || 0
      }
    }
  } catch (error) {
    console.error('Get wallet balance error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

async function getTransactionHistory(
  supabase: any,
  userId: string,
  request: SecureWalletRequest
): Promise<any> {
  try {
    const { wallet_id, pagination = { page: 1, limit: 20 }, audit_filters } = request
    const offset = (pagination.page - 1) * pagination.limit

    let query = supabase
      .from('wallet_transactions')
      .select(`
        id,
        amount,
        transaction_type,
        status,
        description,
        reference_type,
        reference_id,
        metadata,
        created_at,
        updated_at
      `)
      .eq('wallet_id', wallet_id)
      .order('created_at', { ascending: false })
      .range(offset, offset + pagination.limit - 1)

    // Apply filters if provided
    if (audit_filters?.start_date) {
      query = query.gte('created_at', audit_filters.start_date)
    }
    if (audit_filters?.end_date) {
      query = query.lte('created_at', audit_filters.end_date)
    }

    const { data: transactions, error: transactionError } = await query

    if (transactionError) {
      throw new Error(`Failed to fetch transaction history: ${transactionError.message}`)
    }

    // Get total count for pagination
    const { count: totalCount } = await supabase
      .from('wallet_transactions')
      .select('*', { count: 'exact', head: true })
      .eq('wallet_id', wallet_id)

    return {
      success: true,
      transactions,
      pagination: {
        page: pagination.page,
        limit: pagination.limit,
        total: totalCount || 0,
        has_more: (totalCount || 0) > offset + pagination.limit
      }
    }
  } catch (error) {
    console.error('Get transaction history error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

// Enhanced security validation for wallet operations
async function performEnhancedSecurityValidation(
  supabase: any,
  userId: string,
  orderId: string,
  transactionData: any
): Promise<void> {
  console.log('Performing enhanced security validation for user:', userId)

  // Security Check 1: Rate limiting validation
  const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString()
  const { count: recentAttempts } = await supabase
    .from('payment_attempts')
    .select('id', { count: 'exact' })
    .eq('user_id', userId)
    .gte('created_at', fiveMinutesAgo)

  if (recentAttempts >= 5) {
    await logSecurityEvent(supabase, 'RATE_LIMIT_EXCEEDED_EDGE', userId, {
      order_id: orderId,
      recent_attempts: recentAttempts,
      amount: transactionData.amount,
    })
    throw new Error('Rate limit exceeded. Too many payment attempts.')
  }

  // Security Check 2: Transaction amount validation
  if (transactionData.amount <= 0) {
    await logSecurityEvent(supabase, 'INVALID_AMOUNT_EDGE', userId, {
      order_id: orderId,
      amount: transactionData.amount,
    })
    throw new Error('Invalid transaction amount')
  }

  if (transactionData.amount > 10000) {
    await logSecurityEvent(supabase, 'LARGE_AMOUNT_EDGE', userId, {
      order_id: orderId,
      amount: transactionData.amount,
    })
    throw new Error('Transaction amount exceeds maximum limit')
  }

  // Security Check 3: Validate transaction metadata
  if (!transactionData.description || !transactionData.currency) {
    await logSecurityEvent(supabase, 'INCOMPLETE_TRANSACTION_DATA_EDGE', userId, {
      order_id: orderId,
      missing_fields: {
        description: !transactionData.description,
        currency: !transactionData.currency,
      },
    })
    throw new Error('Incomplete transaction data')
  }

  // Security Check 4: Currency validation
  if (transactionData.currency.toUpperCase() !== 'MYR') {
    await logSecurityEvent(supabase, 'INVALID_CURRENCY_EDGE', userId, {
      order_id: orderId,
      provided_currency: transactionData.currency,
    })
    throw new Error('Invalid currency. Only MYR is supported.')
  }

  // Security Check 5: Check for suspicious patterns
  const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
  const { count: recentLargeTransactions } = await supabase
    .from('wallet_transactions')
    .select('id', { count: 'exact' })
    .eq('user_id', userId)
    .gte('created_at', oneDayAgo)
    .gte('amount', 1000)

  if (recentLargeTransactions >= 3 && transactionData.amount >= 1000) {
    await logSecurityEvent(supabase, 'SUSPICIOUS_PATTERN_EDGE', userId, {
      order_id: orderId,
      amount: transactionData.amount,
      recent_large_transactions: recentLargeTransactions,
    })
    throw new Error('Suspicious transaction pattern detected. Please contact support.')
  }

  // Log successful validation
  await logSecurityEvent(supabase, 'SECURITY_VALIDATION_PASSED_EDGE', userId, {
    order_id: orderId,
    amount: transactionData.amount,
    validation_checks: [
      'rate_limiting',
      'amount_validation',
      'metadata_validation',
      'currency_validation',
      'pattern_detection',
    ],
  })

  console.log('Enhanced security validation passed for user:', userId)
}

// Log security events for audit trail
async function logSecurityEvent(
  supabase: any,
  eventType: string,
  userId: string,
  eventData: any
): Promise<void> {
  try {
    await supabase
      .from('security_audit_log')
      .insert({
        event_type: eventType,
        user_id: userId,
        event_data: eventData,
        severity: eventType.includes('EXCEEDED') || eventType.includes('SUSPICIOUS') ? 'warning' : 'info',
        created_at: new Date().toISOString(),
      })

    console.log('Security event logged:', eventType)
  } catch (error) {
    console.error('Failed to log security event:', error)
    // Don't throw - logging failures shouldn't break the payment flow
  }
}

async function processOrderPayment(
  supabase: any,
  userId: string,
  request: SecureWalletRequest
): Promise<any> {
  try {
    const { wallet_id, order_id, transaction_data } = request

    if (!wallet_id || !order_id || !transaction_data) {
      throw new Error('wallet_id, order_id, and transaction_data are required')
    }

    // Validate wallet ownership
    const { data: ownershipValid } = await supabase
      .rpc('validate_wallet_ownership', {
        wallet_id: wallet_id,
        user_id: userId
      })

    if (!ownershipValid) {
      throw new Error('Unauthorized wallet access')
    }

    // Enhanced Security Validation
    await performEnhancedSecurityValidation(supabase, userId, order_id, transaction_data)

    // Get order details
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select('id, total_amount, status, customer_id')
      .eq('id', order_id)
      .single()

    if (orderError || !order) {
      throw new Error(`Order not found: ${orderError?.message}`)
    }

    // Verify customer owns the order
    if (order.customer_id !== userId) {
      throw new Error('Unauthorized order access')
    }

    // Check if order can be paid
    if (order.status !== 'pending') {
      throw new Error(`Order cannot be paid. Current status: ${order.status}`)
    }

    // Validate transaction amount matches order total
    if (Math.abs(transaction_data.amount - order.total_amount) > 0.01) {
      throw new Error('Transaction amount does not match order total')
    }

    // Check wallet balance
    const { data: wallet, error: walletError } = await supabase
      .from('stakeholder_wallets')
      .select('available_balance')
      .eq('id', wallet_id)
      .single()

    if (walletError || !wallet) {
      throw new Error(`Wallet not found: ${walletError?.message}`)
    }

    if (wallet.available_balance < transaction_data.amount) {
      return {
        success: false,
        error: 'Insufficient wallet balance',
        error_code: 'INSUFFICIENT_FUNDS',
        available_balance: wallet.available_balance,
        required_amount: transaction_data.amount
      }
    }

    // Process payment transaction
    const { data: transaction, error: transactionError } = await supabase
      .from('wallet_transactions')
      .insert({
        wallet_id: wallet_id,
        amount: -Math.abs(transaction_data.amount),
        transaction_type: 'order_payment',
        reference_type: 'order',
        reference_id: order_id,
        description: `Payment for order ${order_id}`,
        status: 'completed',
        metadata: {
          order_id: order_id,
          payment_method: 'wallet',
          processed_by: 'secure_wallet_operations',
          processed_at: new Date().toISOString()
        }
      })
      .select()
      .single()

    if (transactionError) {
      throw new Error(`Failed to create payment transaction: ${transactionError.message}`)
    }

    // Update wallet balance
    const { error: balanceError } = await supabase
      .from('stakeholder_wallets')
      .update({
        available_balance: wallet.available_balance - transaction_data.amount,
        total_spent: supabase.sql`total_spent + ${transaction_data.amount}`,
        updated_at: new Date().toISOString(),
        last_activity_at: new Date().toISOString()
      })
      .eq('id', wallet_id)

    if (balanceError) {
      throw new Error(`Failed to update wallet balance: ${balanceError.message}`)
    }

    // Update order status to paid
    const { error: orderUpdateError } = await supabase
      .from('orders')
      .update({
        status: 'confirmed',
        payment_method: 'wallet',
        payment_status: 'paid',
        paid_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', order_id)

    if (orderUpdateError) {
      throw new Error(`Failed to update order status: ${orderUpdateError.message}`)
    }

    // Log successful payment
    await logSecurityEvent(supabase, {
      event_type: 'order_payment_processed',
      user_id: userId,
      entity_type: 'order',
      entity_id: order_id,
      event_data: {
        wallet_id,
        amount: transaction_data.amount,
        transaction_id: transaction.id,
        payment_method: 'wallet'
      },
      severity: 'low'
    })

    return {
      success: true,
      transaction_id: transaction.id,
      order_id: order_id,
      amount_paid: transaction_data.amount,
      new_balance: wallet.available_balance - transaction_data.amount,
      message: 'Order payment processed successfully'
    }

  } catch (error) {
    console.error('Process order payment error:', error)

    // Log failed payment attempt
    await logSecurityEvent(supabase, {
      event_type: 'order_payment_failed',
      user_id: userId,
      entity_type: 'order',
      entity_id: request.order_id || 'unknown',
      event_data: {
        error_message: error.message,
        wallet_id: request.wallet_id,
        amount: request.transaction_data?.amount
      },
      severity: 'medium'
    })

    return {
      success: false,
      error: error.message
    }
  }
}
