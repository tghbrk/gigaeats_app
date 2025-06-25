import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from "https://esm.sh/stripe@14.5.0?target=deno"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  httpClient: Stripe.createFetchHttpClient(),
  apiVersion: '2023-10-16',
})

interface MarketplacePaymentRequest {
  order_id: string
  payment_method: 'fpx' | 'credit_card' | 'grabpay' | 'tng' | 'boost' | 'shopeepay'
  amount: number
  currency?: string
  gateway_data?: Record<string, any>
  callback_url?: string
  redirect_url?: string
  // New marketplace-specific fields
  auto_escrow?: boolean
  release_trigger?: 'order_delivered' | 'manual_release' | 'auto_release'
  hold_duration_hours?: number
}

interface MarketplacePaymentResult {
  success: boolean
  transaction_id?: string
  escrow_account_id?: string
  payment_url?: string
  client_secret?: string
  status: 'pending' | 'completed' | 'failed' | 'escrowed'
  commission_breakdown?: CommissionBreakdown
  error_message?: string
  metadata?: Record<string, any>
}

interface CommissionBreakdown {
  total_amount: number
  vendor_amount: number
  platform_fee: number
  sales_agent_commission: number
  driver_commission: number
  delivery_fee: number
}

serve(async (req) => {
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

    const paymentRequest: MarketplacePaymentRequest = await req.json()
    
    console.log(`🔄 Processing marketplace payment for order ${paymentRequest.order_id}`)

    // Validate payment request
    const validationResult = await validateMarketplacePaymentRequest(supabaseClient, paymentRequest, user.id)
    
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

    // Process marketplace payment with escrow
    const paymentResult = await processMarketplacePayment(supabaseClient, paymentRequest, user.id)
    
    console.log(`✅ Marketplace payment processed: ${paymentResult.status}`)
    
    return new Response(
      JSON.stringify(paymentResult), 
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('❌ Marketplace payment error:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message,
        status: 'failed'
      }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

async function validateMarketplacePaymentRequest(
  supabase: any, 
  request: MarketplacePaymentRequest, 
  userId: string
): Promise<{ isValid: boolean; error?: string }> {
  
  // Validate required fields
  if (!request.order_id || !request.payment_method || !request.amount) {
    return { isValid: false, error: 'Missing required fields: order_id, payment_method, amount' }
  }

  if (request.amount <= 0) {
    return { isValid: false, error: 'Amount must be greater than 0' }
  }

  // Validate order exists and user has permission
  const { data: order, error: orderError } = await supabase
    .from('orders')
    .select(`
      id, status, total_amount, customer_id, vendor_id, sales_agent_id,
      vendors!inner(id, user_id),
      payment_status
    `)
    .eq('id', request.order_id)
    .single()

  if (orderError || !order) {
    return { isValid: false, error: 'Order not found or access denied' }
  }

  // Check if user has permission to process payment for this order
  const hasPermission = (
    order.customer_id === userId ||
    order.sales_agent_id === userId ||
    order.vendors.user_id === userId
  )

  if (!hasPermission) {
    return { isValid: false, error: 'Insufficient permissions to process payment for this order' }
  }

  // Check if order is in valid state for payment
  if (order.status === 'cancelled') {
    return { isValid: false, error: 'Cannot process payment for cancelled order' }
  }

  if (order.payment_status === 'paid') {
    return { isValid: false, error: 'Order has already been paid' }
  }

  // Validate amount matches order total
  if (Math.abs(request.amount - order.total_amount) > 0.01) {
    return { isValid: false, error: 'Payment amount does not match order total' }
  }

  return { isValid: true }
}

async function processMarketplacePayment(
  supabase: any, 
  request: MarketplacePaymentRequest, 
  userId: string
): Promise<MarketplacePaymentResult> {
  
  // Get order details with all related information
  const { data: order, error: orderError } = await supabase
    .from('orders')
    .select(`
      id, order_number, total_amount, subtotal, delivery_fee, tax_amount,
      customer_id, vendor_id, sales_agent_id, assigned_driver_id,
      delivery_method, status,
      vendors!inner(id, user_id, name),
      customers!inner(id, name, email)
    `)
    .eq('id', request.order_id)
    .single()

  if (orderError || !order) {
    throw new Error(`Failed to fetch order details: ${orderError?.message}`)
  }

  // Calculate commission breakdown
  const commissionBreakdown = await calculateCommissionBreakdown(supabase, order)

  // Create payment transaction record (enhanced)
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
        redirect_url: request.redirect_url,
        marketplace_enabled: true,
        auto_escrow: request.auto_escrow ?? true,
        commission_breakdown: commissionBreakdown
      }
    })
    .select()
    .single()

  if (transactionError) {
    throw new Error(`Failed to create payment transaction: ${transactionError.message}`)
  }

  // Create escrow account (if auto_escrow is enabled)
  let escrowAccountId: string | undefined
  
  if (request.auto_escrow !== false) {
    const { data: escrowAccount, error: escrowError } = await supabase
      .from('escrow_accounts')
      .insert({
        order_id: request.order_id,
        payment_transaction_id: transaction.id,
        total_amount: request.amount,
        currency: request.currency || 'MYR',
        status: 'pending',
        vendor_amount: commissionBreakdown.vendor_amount,
        platform_fee: commissionBreakdown.platform_fee,
        sales_agent_commission: commissionBreakdown.sales_agent_commission,
        driver_commission: commissionBreakdown.driver_commission,
        delivery_fee: commissionBreakdown.delivery_fee,
        release_trigger: request.release_trigger || 'order_delivered',
        hold_until: request.hold_duration_hours 
          ? new Date(Date.now() + (request.hold_duration_hours * 60 * 60 * 1000)).toISOString()
          : new Date(Date.now() + (7 * 24 * 60 * 60 * 1000)).toISOString(), // Default 7 days
        created_by: userId
      })
      .select()
      .single()

    if (escrowError) {
      console.error('Failed to create escrow account:', escrowError)
      // Continue with payment processing even if escrow creation fails
    } else {
      escrowAccountId = escrowAccount.id
      console.log(`✅ Created escrow account: ${escrowAccountId}`)
    }
  }

  // Log payment initiation
  await logFinancialAudit(supabase, {
    event_type: 'payment_initiated',
    entity_type: 'payment_transaction',
    entity_id: transaction.id,
    user_id: userId,
    amount: request.amount,
    description: `Marketplace payment initiated for order ${order.order_number}`,
    metadata: {
      order_id: request.order_id,
      payment_method: request.payment_method,
      escrow_account_id: escrowAccountId,
      commission_breakdown: commissionBreakdown
    }
  })

  try {
    let paymentResult: MarketplacePaymentResult

    // Process payment based on method (delegate to existing payment processors)
    switch (request.payment_method) {
      case 'credit_card':
        paymentResult = await processStripePayment(supabase, transaction, request, commissionBreakdown)
        break
      case 'fpx':
        paymentResult = await processFPXPayment(supabase, transaction, request, commissionBreakdown)
        break
      case 'grabpay':
      case 'tng':
      case 'boost':
      case 'shopeepay':
        paymentResult = await processEWalletPayment(supabase, transaction, request, commissionBreakdown)
        break
      default:
        throw new Error(`Unsupported payment method: ${request.payment_method}`)
    }

    // Add escrow information to result
    paymentResult.escrow_account_id = escrowAccountId
    paymentResult.commission_breakdown = commissionBreakdown

    // Update transaction with payment result
    await supabase
      .from('payment_transactions')
      .update({
        gateway_transaction_id: paymentResult.transaction_id,
        status: paymentResult.status === 'pending' ? 'pending' : 
                paymentResult.status === 'completed' ? 'completed' : 'failed',
        metadata: {
          ...transaction.metadata,
          payment_result: paymentResult
        },
        updated_at: new Date().toISOString()
      })
      .eq('id', transaction.id)

    return paymentResult

  } catch (error) {
    console.error('Payment processing failed:', error)
    
    // Update transaction status to failed
    await supabase
      .from('payment_transactions')
      .update({
        status: 'failed',
        failure_reason: error.message,
        updated_at: new Date().toISOString()
      })
      .eq('id', transaction.id)

    // Update escrow status to failed if it exists
    if (escrowAccountId) {
      await supabase
        .from('escrow_accounts')
        .update({
          status: 'refunded',
          updated_at: new Date().toISOString()
        })
        .eq('id', escrowAccountId)
    }

    throw error
  }
}

async function calculateCommissionBreakdown(
  supabase: any,
  order: any
): Promise<CommissionBreakdown> {

  // Get applicable commission structure
  const { data: commissionStructure, error: commissionError } = await supabase
    .from('commission_structures')
    .select('*')
    .or(`vendor_id.eq.${order.vendor_id},vendor_id.is.null`)
    .or(`sales_agent_id.eq.${order.sales_agent_id},sales_agent_id.is.null`)
    .or(`driver_id.eq.${order.assigned_driver_id},driver_id.is.null`)
    .or(`delivery_method.eq.${order.delivery_method},delivery_method.is.null`)
    .eq('is_active', true)
    .lte('effective_from', new Date().toISOString())
    .or('effective_until.is.null,effective_until.gte.' + new Date().toISOString())
    .order('effective_from', { ascending: false })
    .limit(1)
    .single()

  // Use default rates if no specific structure found
  const rates = commissionStructure || {
    platform_fee_rate: 0.0500,
    vendor_commission_rate: 0.8500,
    sales_agent_commission_rate: 0.0300,
    driver_commission_rate: 0.8000,
    fixed_delivery_fee: order.delivery_method === 'own_fleet' ? 8.00 :
                       order.delivery_method === 'sales_agent_pickup' ? 3.00 : 0.00
  }

  const totalAmount = order.total_amount
  const subtotal = order.subtotal || (totalAmount - (order.delivery_fee || 0))
  const deliveryFee = order.delivery_fee || rates.fixed_delivery_fee || 0

  // Calculate commission amounts
  const platformFee = totalAmount * rates.platform_fee_rate
  const vendorAmount = subtotal * rates.vendor_commission_rate
  const salesAgentCommission = totalAmount * rates.sales_agent_commission_rate

  // Driver commission calculation depends on delivery method
  let driverCommission = 0
  if (order.delivery_method === 'own_fleet' && order.assigned_driver_id) {
    driverCommission = (deliveryFee * rates.driver_commission_rate) +
                      (subtotal * (rates.driver_commission_rate - rates.vendor_commission_rate))
  }

  return {
    total_amount: totalAmount,
    vendor_amount: Math.round(vendorAmount * 100) / 100,
    platform_fee: Math.round(platformFee * 100) / 100,
    sales_agent_commission: Math.round(salesAgentCommission * 100) / 100,
    driver_commission: Math.round(driverCommission * 100) / 100,
    delivery_fee: deliveryFee
  }
}

async function processStripePayment(
  supabase: any,
  transaction: any,
  request: MarketplacePaymentRequest,
  commissionBreakdown: CommissionBreakdown
): Promise<MarketplacePaymentResult> {

  try {
    // Create Stripe PaymentIntent with marketplace metadata
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(request.amount * 100), // Amount in cents
      currency: request.currency?.toLowerCase() || 'myr',
      metadata: {
        order_id: request.order_id,
        transaction_id: transaction.id,
        marketplace_payment: 'true',
        vendor_amount: commissionBreakdown.vendor_amount.toString(),
        platform_fee: commissionBreakdown.platform_fee.toString(),
        sales_agent_commission: commissionBreakdown.sales_agent_commission.toString(),
        driver_commission: commissionBreakdown.driver_commission.toString()
      },
      automatic_payment_methods: {
        enabled: true,
      },
    })

    // Update transaction with Stripe PaymentIntent ID
    await supabase
      .from('payment_transactions')
      .update({
        gateway_transaction_id: paymentIntent.id,
        metadata: {
          ...transaction.metadata,
          stripe_payment_intent_id: paymentIntent.id,
          client_secret: paymentIntent.client_secret
        }
      })
      .eq('id', transaction.id)

    return {
      success: true,
      transaction_id: paymentIntent.id,
      client_secret: paymentIntent.client_secret,
      status: 'pending',
      commission_breakdown: commissionBreakdown,
      metadata: {
        gateway: 'stripe',
        payment_method: 'credit_card',
        payment_intent_id: paymentIntent.id
      }
    }
  } catch (error) {
    console.error('Stripe PaymentIntent creation failed:', error)
    throw new Error(`Credit card payment setup failed: ${error.message}`)
  }
}

async function processFPXPayment(
  supabase: any,
  transaction: any,
  request: MarketplacePaymentRequest,
  commissionBreakdown: CommissionBreakdown
): Promise<MarketplacePaymentResult> {

  // For demo purposes - in production, integrate with actual FPX/Billplz API
  const billId = `bill_${Date.now()}`
  const paymentUrl = `https://www.billplz.com/bills/${billId}`

  return {
    success: true,
    transaction_id: billId,
    payment_url: paymentUrl,
    status: 'pending',
    commission_breakdown: commissionBreakdown,
    metadata: {
      gateway: 'billplz',
      bill_id: billId,
      payment_method: 'fpx'
    }
  }
}

async function processEWalletPayment(
  supabase: any,
  transaction: any,
  request: MarketplacePaymentRequest,
  commissionBreakdown: CommissionBreakdown
): Promise<MarketplacePaymentResult> {

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
    commission_breakdown: commissionBreakdown,
    metadata: {
      gateway,
      payment_method: request.payment_method
    }
  }
}

function getGatewayForMethod(paymentMethod: string): string {
  const gateways = {
    'credit_card': 'stripe',
    'fpx': 'billplz',
    'grabpay': 'grab',
    'tng': 'touchngo',
    'boost': 'boost',
    'shopeepay': 'shopee'
  }

  return gateways[paymentMethod as keyof typeof gateways] || 'unknown'
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
    // Don't throw error - audit logging failure shouldn't break payment flow
  }
}
