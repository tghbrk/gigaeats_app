import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PaymentRequest {
  order_id: string
  payment_method: 'fpx' | 'credit_card' | 'grabpay' | 'tng' | 'boost' | 'shopeepay'
  amount: number
  currency?: string
  gateway_data?: Record<string, any>
  callback_url?: string
  redirect_url?: string
}

interface PaymentResult {
  success: boolean
  transaction_id?: string
  payment_url?: string
  status: 'pending' | 'completed' | 'failed'
  error_message?: string
  metadata?: Record<string, any>
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

    // Get the authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('No authorization header')
    }

    // Verify the JWT token
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)
    
    if (authError || !user) {
      throw new Error('Invalid authentication token')
    }

    const paymentRequest: PaymentRequest = await req.json()
    
    // Validate payment request
    const validationResult = await validatePaymentRequest(supabaseClient, paymentRequest, user.id)
    
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

    // Process payment based on method
    const paymentResult = await processPayment(supabaseClient, paymentRequest, user.id)
    
    return new Response(
      JSON.stringify(paymentResult), 
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  } catch (error) {
    console.error('Payment processing error:', error)
    
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

async function validatePaymentRequest(
  supabase: any, 
  request: PaymentRequest, 
  userId: string
): Promise<{ isValid: boolean; error?: string; order?: any }> {
  
  // Validate required fields
  if (!request.order_id) {
    return { isValid: false, error: 'Order ID is required' }
  }
  
  if (!request.payment_method) {
    return { isValid: false, error: 'Payment method is required' }
  }
  
  if (!request.amount || request.amount <= 0) {
    return { isValid: false, error: 'Valid amount is required' }
  }

  // Validate order exists and user has access
  const { data: order, error: orderError } = await supabase
    .from('orders')
    .select(`
      id, order_number, total_amount, status, payment_status,
      vendor_id, customer_id, sales_agent_id,
      vendors!inner(user_id)
    `)
    .eq('id', request.order_id)
    .single()

  if (orderError || !order) {
    return { isValid: false, error: 'Order not found' }
  }

  // Check user access to order
  const hasAccess = order.sales_agent_id === userId || 
                   order.vendors.user_id === userId ||
                   await isAdmin(supabase, userId)

  if (!hasAccess) {
    return { isValid: false, error: 'Access denied to this order' }
  }

  // Validate order status
  if (order.status === 'cancelled') {
    return { isValid: false, error: 'Cannot process payment for cancelled order' }
  }

  if (order.payment_status === 'paid') {
    return { isValid: false, error: 'Order is already paid' }
  }

  // Validate amount matches order total
  if (Math.abs(request.amount - order.total_amount) > 0.01) {
    return { isValid: false, error: 'Payment amount does not match order total' }
  }

  return { isValid: true, order }
}

async function processPayment(
  supabase: any, 
  request: PaymentRequest, 
  userId: string
): Promise<PaymentResult> {
  
  // Create payment transaction record
  const { data: transaction, error: transactionError } = await supabase
    .from('payment_transactions')
    .insert({
      order_id: request.order_id,
      amount: request.amount,
      currency: request.currency || 'MYR',
      payment_method: request.payment_method,
      payment_gateway: getGatewayForMethod(request.payment_method),
      status: 'pending',
      metadata: {
        user_id: userId,
        gateway_data: request.gateway_data,
        callback_url: request.callback_url,
        redirect_url: request.redirect_url
      }
    })
    .select()
    .single()

  if (transactionError) {
    throw new Error(`Failed to create payment transaction: ${transactionError.message}`)
  }

  // Log payment initiation
  await logPaymentAction(supabase, transaction.id, 'payment_initiated', null, 'pending', userId, {
    payment_method: request.payment_method,
    amount: request.amount
  })

  try {
    let paymentResult: PaymentResult

    // Process payment based on method
    switch (request.payment_method) {
      case 'fpx':
        paymentResult = await processFPXPayment(supabase, transaction, request)
        break
      case 'credit_card':
        paymentResult = await processCreditCardPayment(supabase, transaction, request)
        break
      case 'grabpay':
      case 'tng':
      case 'boost':
      case 'shopeepay':
        paymentResult = await processEWalletPayment(supabase, transaction, request)
        break
      default:
        throw new Error(`Unsupported payment method: ${request.payment_method}`)
    }

    // Update transaction with gateway response
    await supabase
      .from('payment_transactions')
      .update({
        gateway_transaction_id: paymentResult.transaction_id,
        status: paymentResult.status,
        metadata: {
          ...transaction.metadata,
          gateway_response: paymentResult.metadata
        },
        updated_at: new Date().toISOString()
      })
      .eq('id', transaction.id)

    return paymentResult

  } catch (error) {
    // Update transaction status to failed
    await supabase
      .from('payment_transactions')
      .update({
        status: 'failed',
        failure_reason: error.message,
        updated_at: new Date().toISOString()
      })
      .eq('id', transaction.id)

    // Log payment failure
    await logPaymentAction(supabase, transaction.id, 'payment_failed', 'pending', 'failed', userId, {
      error: error.message
    })

    return {
      success: false,
      status: 'failed',
      error_message: error.message
    }
  }
}

async function processFPXPayment(
  supabase: any, 
  transaction: any, 
  request: PaymentRequest
): Promise<PaymentResult> {
  // Simulate FPX payment processing
  // In real implementation, integrate with Billplz or other FPX gateway
  
  const billplzApiKey = Deno.env.get('BILLPLZ_API_KEY')
  const collectionId = Deno.env.get('BILLPLZ_COLLECTION_ID')
  
  if (!billplzApiKey || !collectionId) {
    throw new Error('Billplz configuration missing')
  }

  // Create bill with Billplz
  const billData = {
    collection_id: collectionId,
    email: 'customer@example.com', // TODO: Get from customer record
    name: 'Customer Name', // TODO: Get from customer record
    amount: Math.round(request.amount * 100).toString(), // Convert to cents
    description: `Payment for Order ${transaction.order_id}`,
    callback_url: request.callback_url,
    reference_1_label: 'Order ID',
    reference_1: request.order_id,
    reference_2_label: 'Transaction ID',
    reference_2: transaction.id,
  }

  // For demo purposes, simulate successful bill creation
  const billId = `bill_${Date.now()}`
  const paymentUrl = `https://www.billplz.com/bills/${billId}`

  return {
    success: true,
    transaction_id: billId,
    payment_url: paymentUrl,
    status: 'pending',
    metadata: {
      gateway: 'billplz',
      bill_id: billId,
      payment_method: 'fpx'
    }
  }
}

async function processCreditCardPayment(
  supabase: any, 
  transaction: any, 
  request: PaymentRequest
): Promise<PaymentResult> {
  // Simulate credit card payment processing
  // In real implementation, integrate with Stripe or other card processor
  
  // For demo purposes, simulate processing
  await new Promise(resolve => setTimeout(resolve, 1000))
  
  // Simulate random success/failure
  const isSuccess = Math.random() > 0.1 // 90% success rate
  
  if (isSuccess) {
    return {
      success: true,
      transaction_id: `card_${Date.now()}`,
      status: 'completed',
      metadata: {
        gateway: 'stripe',
        payment_method: 'credit_card'
      }
    }
  } else {
    throw new Error('Card payment declined')
  }
}

async function processEWalletPayment(
  supabase: any, 
  transaction: any, 
  request: PaymentRequest
): Promise<PaymentResult> {
  // Simulate e-wallet payment processing
  // In real implementation, integrate with respective e-wallet APIs
  
  const walletGateways = {
    grabpay: 'grab',
    tng: 'touchngo',
    boost: 'boost',
    shopeepay: 'shopee'
  }
  
  const gateway = walletGateways[request.payment_method as keyof typeof walletGateways]
  const transactionId = `${gateway}_${Date.now()}`
  
  return {
    success: true,
    transaction_id: transactionId,
    payment_url: `https://${gateway}.com/pay/${transactionId}`,
    status: 'pending',
    metadata: {
      gateway,
      payment_method: request.payment_method
    }
  }
}

function getGatewayForMethod(method: string): string {
  const gateways = {
    fpx: 'billplz',
    credit_card: 'stripe',
    grabpay: 'grab',
    tng: 'touchngo',
    boost: 'boost',
    shopeepay: 'shopee'
  }
  return gateways[method as keyof typeof gateways] || 'unknown'
}

async function logPaymentAction(
  supabase: any,
  transactionId: string,
  action: string,
  oldStatus: string | null,
  newStatus: string,
  userId: string,
  details: Record<string, any>
) {
  await supabase
    .from('payment_audit_log')
    .insert({
      payment_transaction_id: transactionId,
      action,
      old_status: oldStatus,
      new_status: newStatus,
      user_id: userId,
      details,
      created_at: new Date().toISOString()
    })
}

async function isAdmin(supabase: any, userId: string): Promise<boolean> {
  const { data: user } = await supabase
    .from('users')
    .select('role')
    .eq('id', userId)
    .single()
  
  return user?.role === 'admin'
}
