import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PayoutRequest {
  amount: number
  bank_account_number: string
  bank_name: string
  account_holder_name: string
  swift_code?: string
  currency?: string
}

interface PayoutResult {
  success: boolean
  payout_request_id: string
  status: 'pending' | 'processing' | 'completed' | 'failed'
  processing_fee: number
  net_amount: number
  estimated_completion: string
  error_message?: string
}

serve(async (req) => {
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
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing authorization header')
    }

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (userError || !user) {
      throw new Error('Invalid or expired token')
    }

    const payoutRequest: PayoutRequest = await req.json()
    
    console.log(`💸 Processing payout request for user ${user.id}, amount: ${payoutRequest.amount}`)

    // Validate payout request
    const validationResult = await validatePayoutRequest(supabaseClient, payoutRequest, user.id)
    
    if (!validationResult.isValid) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: validationResult.error 
        }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Process payout request
    const result = await processPayoutRequest(supabaseClient, payoutRequest, user.id, validationResult.wallet!)
    
    console.log(`✅ Payout request processed: ${result.payout_request_id}`)
    
    return new Response(
      JSON.stringify(result), 
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('❌ Payout processing error:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

async function validatePayoutRequest(
  supabase: any,
  request: PayoutRequest,
  userId: string
): Promise<{ isValid: boolean; error?: string; wallet?: any }> {
  
  // Validate required fields
  if (!request.amount || !request.bank_account_number || !request.bank_name || !request.account_holder_name) {
    return { isValid: false, error: 'Missing required fields: amount, bank_account_number, bank_name, account_holder_name' }
  }

  if (request.amount <= 0) {
    return { isValid: false, error: 'Amount must be greater than 0' }
  }

  // Get user's wallet
  const { data: wallet, error: walletError } = await supabase
    .from('stakeholder_wallets')
    .select('*')
    .eq('user_id', userId)
    .eq('is_active', true)
    .single()

  if (walletError || !wallet) {
    return { isValid: false, error: 'Wallet not found or inactive' }
  }

  // Check minimum payout amount
  const minPayoutAmount = parseFloat(Deno.env.get('MIN_PAYOUT_AMOUNT') || '10.00')
  if (request.amount < minPayoutAmount) {
    return { isValid: false, error: `Minimum payout amount is ${minPayoutAmount} MYR` }
  }

  // Check maximum payout amount
  const maxPayoutAmount = parseFloat(Deno.env.get('MAX_PAYOUT_AMOUNT') || '10000.00')
  if (request.amount > maxPayoutAmount) {
    return { isValid: false, error: `Maximum payout amount is ${maxPayoutAmount} MYR` }
  }

  // Check available balance
  if (request.amount > wallet.available_balance) {
    return { 
      isValid: false, 
      error: `Insufficient balance. Available: ${wallet.available_balance} MYR, Requested: ${request.amount} MYR` 
    }
  }

  // Check for pending payout requests
  const { data: pendingPayouts, error: pendingError } = await supabase
    .from('payout_requests')
    .select('id')
    .eq('wallet_id', wallet.id)
    .in('status', ['pending', 'processing'])

  if (pendingError) {
    return { isValid: false, error: 'Error checking pending payouts' }
  }

  if (pendingPayouts && pendingPayouts.length > 0) {
    return { isValid: false, error: 'You have pending payout requests. Please wait for them to complete.' }
  }

  return { isValid: true, wallet }
}

async function processPayoutRequest(
  supabase: any,
  request: PayoutRequest,
  userId: string,
  wallet: any
): Promise<PayoutResult> {
  
  // Calculate processing fee (e.g., 1% or minimum RM 2.00)
  const feeRate = parseFloat(Deno.env.get('PAYOUT_FEE_RATE') || '0.01') // 1%
  const minFee = parseFloat(Deno.env.get('MIN_PAYOUT_FEE') || '2.00') // RM 2.00
  const processingFee = Math.max(request.amount * feeRate, minFee)
  const netAmount = request.amount - processingFee

  try {
    // Create payout request record
    const { data: payoutRequest, error: payoutError } = await supabase
      .from('payout_requests')
      .insert({
        wallet_id: wallet.id,
        amount: request.amount,
        currency: request.currency || 'MYR',
        status: 'pending',
        bank_account_number: request.bank_account_number,
        bank_name: request.bank_name,
        account_holder_name: request.account_holder_name,
        swift_code: request.swift_code,
        processing_fee: processingFee,
        payment_gateway: 'local_bank', // Default to local bank transfer
        requested_at: new Date().toISOString()
      })
      .select()
      .single()

    if (payoutError) {
      throw new Error(`Failed to create payout request: ${payoutError.message}`)
    }

    // Create debit transaction to reserve funds
    const { error: transactionError } = await supabase
      .from('wallet_transactions')
      .insert({
        wallet_id: wallet.id,
        transaction_type: 'payout',
        amount: -request.amount, // Negative for debit
        balance_before: wallet.available_balance,
        balance_after: wallet.available_balance - request.amount,
        reference_type: 'payout_request',
        reference_id: payoutRequest.id,
        description: `Payout request to ${request.bank_name} (${request.bank_account_number})`,
        processed_by: userId,
        processed_at: new Date().toISOString()
      })

    if (transactionError) {
      // Rollback payout request
      await supabase
        .from('payout_requests')
        .delete()
        .eq('id', payoutRequest.id)
      
      throw new Error(`Failed to create wallet transaction: ${transactionError.message}`)
    }

    // Log payout request
    await logFinancialAudit(supabase, {
      event_type: 'payout_requested',
      entity_type: 'payout_request',
      entity_id: payoutRequest.id,
      user_id: userId,
      amount: request.amount,
      new_status: 'pending',
      description: `Payout request created for ${request.amount} MYR`,
      metadata: {
        bank_name: request.bank_name,
        account_holder_name: request.account_holder_name,
        processing_fee: processingFee,
        net_amount: netAmount
      }
    })

    // Initiate bank transfer (in production, integrate with actual payment gateway)
    const transferResult = await initiateBankTransfer(supabase, payoutRequest, request)

    // Update payout request with transfer details
    await supabase
      .from('payout_requests')
      .update({
        status: transferResult.success ? 'processing' : 'failed',
        gateway_transaction_id: transferResult.transaction_id,
        gateway_reference: transferResult.reference,
        failure_reason: transferResult.error_message,
        processed_at: transferResult.success ? new Date().toISOString() : null,
        updated_at: new Date().toISOString()
      })
      .eq('id', payoutRequest.id)

    // Calculate estimated completion time (e.g., 1-3 business days)
    const estimatedCompletion = new Date()
    estimatedCompletion.setDate(estimatedCompletion.getDate() + 3)

    console.log(`💸 Payout request ${payoutRequest.id} created with status: ${transferResult.success ? 'processing' : 'failed'}`)

    return {
      success: true,
      payout_request_id: payoutRequest.id,
      status: transferResult.success ? 'processing' : 'failed',
      processing_fee: processingFee,
      net_amount: netAmount,
      estimated_completion: estimatedCompletion.toISOString(),
      error_message: transferResult.error_message
    }

  } catch (error) {
    console.error('Payout processing failed:', error)
    throw error
  }
}

async function initiateBankTransfer(
  supabase: any,
  payoutRequest: any,
  request: PayoutRequest
): Promise<{ success: boolean; transaction_id?: string; reference?: string; error_message?: string }> {
  
  // In production, integrate with actual payment gateway (Wise, local banks, etc.)
  // For now, simulate the transfer process
  
  try {
    // Simulate API call to payment gateway
    const mockTransactionId = `TXN_${Date.now()}`
    const mockReference = `REF_${payoutRequest.id.substring(0, 8)}`

    // Simulate processing delay and potential failure
    const shouldSucceed = Math.random() > 0.1 // 90% success rate for demo

    if (shouldSucceed) {
      console.log(`🏦 Bank transfer initiated: ${mockTransactionId}`)
      
      return {
        success: true,
        transaction_id: mockTransactionId,
        reference: mockReference
      }
    } else {
      return {
        success: false,
        error_message: 'Bank transfer failed due to invalid account details'
      }
    }

  } catch (error) {
    console.error('Bank transfer initiation failed:', error)
    return {
      success: false,
      error_message: `Transfer initiation failed: ${error.message}`
    }
  }
}

async function logFinancialAudit(
  supabase: any,
  auditData: {
    event_type: string
    entity_type: string
    entity_id: string
    user_id: string
    amount?: number
    old_status?: string
    new_status?: string
    description?: string
    metadata?: Record<string, any>
  }
): Promise<void> {
  
  try {
    await supabase
      .from('financial_audit_log')
      .insert({
        event_type: auditData.event_type,
        entity_type: auditData.entity_type,
        entity_id: auditData.entity_id,
        user_id: auditData.user_id,
        amount: auditData.amount,
        currency: 'MYR',
        old_status: auditData.old_status,
        new_status: auditData.new_status,
        description: auditData.description,
        metadata: auditData.metadata || {},
        created_at: new Date().toISOString()
      })
  } catch (error) {
    console.error('Failed to log financial audit:', error)
    // Don't throw error - audit logging failure shouldn't break payout processing
  }
}
