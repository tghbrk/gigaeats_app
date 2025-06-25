import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from "https://esm.sh/stripe@14.5.0?target=deno"

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  httpClient: Stripe.createFetchHttpClient(),
  apiVersion: '2023-10-16',
})

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const signature = req.headers.get('Stripe-Signature')
  const body = await req.text()
  const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')

  if (!signature || !webhookSecret) {
    return new Response('Missing signature or webhook secret', {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    const event = await stripe.webhooks.constructEventAsync(
      body,
      signature,
      webhookSecret
    )
    
    console.log(`🔔 Marketplace webhook received: ${event.type}`)

    // Initialize Supabase client with service role
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    // Handle payment success
    if (event.type === 'payment_intent.succeeded') {
      await handlePaymentSuccess(supabaseClient, event.data.object as Stripe.PaymentIntent)
    }

    // Handle payment failure
    if (event.type === 'payment_intent.payment_failed') {
      await handlePaymentFailure(supabaseClient, event.data.object as Stripe.PaymentIntent)
    }

    // Handle payment cancellation
    if (event.type === 'payment_intent.canceled') {
      await handlePaymentCancellation(supabaseClient, event.data.object as Stripe.PaymentIntent)
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('❌ Marketplace webhook error:', err.message)
    return new Response(`Webhook Error: ${err.message}`, {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

async function handlePaymentSuccess(
  supabase: any,
  paymentIntent: Stripe.PaymentIntent
): Promise<void> {

  const orderId = paymentIntent.metadata.order_id
  const transactionId = paymentIntent.metadata.transaction_id
  const walletId = paymentIntent.metadata.wallet_id
  const isMarketplacePayment = paymentIntent.metadata.marketplace_payment === 'true'
  const isWalletTopup = paymentIntent.metadata.type === 'wallet_topup'

  console.log(`✅ Payment succeeded for ${isWalletTopup ? 'wallet top-up' : `order ${orderId}`} (marketplace: ${isMarketplacePayment})`)

  try {
    // Handle wallet top-up payments
    if (isWalletTopup && walletId && transactionId) {
      await handleWalletTopupSuccess(supabase, paymentIntent, walletId, transactionId)
      return
    }
    // Update payment transaction status
    const { error: transactionError } = await supabase
      .from('payment_transactions')
      .update({ 
        status: 'completed',
        gateway_response: JSON.stringify(paymentIntent),
        completed_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('gateway_transaction_id', paymentIntent.id)

    if (transactionError) {
      console.error('Failed to update transaction:', transactionError)
      throw transactionError
    }

    // Update order payment status
    const { error: orderError } = await supabase
      .from('orders')
      .update({ 
        payment_status: 'paid',
        payment_reference: paymentIntent.id,
        updated_at: new Date().toISOString()
      })
      .eq('id', orderId)

    if (orderError) {
      console.error('Failed to update order:', orderError)
      throw orderError
    }

    // If this is a marketplace payment, handle escrow and fund distribution
    if (isMarketplacePayment) {
      await handleMarketplacePaymentSuccess(supabase, paymentIntent, orderId)
    }

    // Log successful payment
    await logFinancialAudit(supabase, {
      event_type: 'payment_completed',
      entity_type: 'payment_transaction',
      entity_id: transactionId || paymentIntent.id,
      user_id: 'system',
      amount: paymentIntent.amount / 100, // Convert from cents
      new_status: 'completed',
      description: `Payment completed for order ${orderId}`,
      metadata: {
        stripe_payment_intent_id: paymentIntent.id,
        marketplace_payment: isMarketplacePayment,
        amount_received: paymentIntent.amount_received / 100
      }
    })

    console.log(`✅ Successfully processed payment success for order ${orderId}`)

  } catch (error) {
    console.error(`❌ Error processing payment success for order ${orderId}:`, error)
    
    // Log the error for audit purposes
    await logFinancialAudit(supabase, {
      event_type: 'payment_processing_error',
      entity_type: 'payment_transaction',
      entity_id: transactionId || paymentIntent.id,
      user_id: 'system',
      amount: paymentIntent.amount / 100,
      description: `Error processing payment success: ${error.message}`,
      metadata: {
        stripe_payment_intent_id: paymentIntent.id,
        error_details: error.message
      }
    })
  }
}

async function handleMarketplacePaymentSuccess(
  supabase: any,
  paymentIntent: Stripe.PaymentIntent,
  orderId: string
): Promise<void> {
  
  console.log(`🏪 Processing marketplace payment success for order ${orderId}`)

  try {
    // Find and update escrow account
    const { data: escrowAccount, error: escrowFindError } = await supabase
      .from('escrow_accounts')
      .select('*')
      .eq('order_id', orderId)
      .eq('status', 'pending')
      .single()

    if (escrowFindError || !escrowAccount) {
      console.error('Escrow account not found for order:', orderId)
      return
    }

    // Update escrow status to 'held' - funds are now secured
    const { error: escrowUpdateError } = await supabase
      .from('escrow_accounts')
      .update({
        status: 'held',
        updated_at: new Date().toISOString()
      })
      .eq('id', escrowAccount.id)

    if (escrowUpdateError) {
      console.error('Failed to update escrow account:', escrowUpdateError)
      throw escrowUpdateError
    }

    console.log(`✅ Escrow account ${escrowAccount.id} updated to 'held' status`)

    // Log escrow status change
    await logFinancialAudit(supabase, {
      event_type: 'funds_escrowed',
      entity_type: 'escrow_account',
      entity_id: escrowAccount.id,
      user_id: 'system',
      amount: escrowAccount.total_amount,
      old_status: 'pending',
      new_status: 'held',
      description: `Funds escrowed for order ${orderId}`,
      metadata: {
        order_id: orderId,
        stripe_payment_intent_id: paymentIntent.id,
        commission_breakdown: {
          vendor_amount: escrowAccount.vendor_amount,
          platform_fee: escrowAccount.platform_fee,
          sales_agent_commission: escrowAccount.sales_agent_commission,
          driver_commission: escrowAccount.driver_commission,
          delivery_fee: escrowAccount.delivery_fee
        }
      }
    })

    // Check if funds should be released immediately (for certain delivery methods)
    const shouldAutoRelease = await checkAutoReleaseConditions(supabase, orderId)
    
    if (shouldAutoRelease) {
      console.log(`🚀 Auto-releasing funds for order ${orderId}`)
      await releaseFundsFromEscrow(supabase, escrowAccount.id, 'auto_release')
    }

  } catch (error) {
    console.error('Error in marketplace payment success handling:', error)
    throw error
  }
}

async function handlePaymentFailure(
  supabase: any,
  paymentIntent: Stripe.PaymentIntent
): Promise<void> {
  
  const orderId = paymentIntent.metadata.order_id
  const transactionId = paymentIntent.metadata.transaction_id

  console.log(`❌ Payment failed for order ${orderId}`)

  try {
    // Update payment transaction status
    const { error: transactionError } = await supabase
      .from('payment_transactions')
      .update({ 
        status: 'failed',
        failure_reason: paymentIntent.last_payment_error?.message || 'Payment failed',
        gateway_response: JSON.stringify(paymentIntent),
        updated_at: new Date().toISOString()
      })
      .eq('gateway_transaction_id', paymentIntent.id)

    if (transactionError) {
      console.error('Failed to update transaction:', transactionError)
    }

    // Update order payment status
    const { error: orderError } = await supabase
      .from('orders')
      .update({ 
        payment_status: 'failed',
        updated_at: new Date().toISOString()
      })
      .eq('id', orderId)

    if (orderError) {
      console.error('Failed to update order:', orderError)
    }

    // Update any associated escrow account
    const { error: escrowError } = await supabase
      .from('escrow_accounts')
      .update({
        status: 'refunded',
        updated_at: new Date().toISOString()
      })
      .eq('order_id', orderId)
      .eq('status', 'pending')

    if (escrowError) {
      console.error('Failed to update escrow account:', escrowError)
    }

    // Log payment failure
    await logFinancialAudit(supabase, {
      event_type: 'payment_failed',
      entity_type: 'payment_transaction',
      entity_id: transactionId || paymentIntent.id,
      user_id: 'system',
      amount: paymentIntent.amount / 100,
      old_status: 'pending',
      new_status: 'failed',
      description: `Payment failed for order ${orderId}`,
      metadata: {
        stripe_payment_intent_id: paymentIntent.id,
        error: paymentIntent.last_payment_error?.message || 'Payment failed',
        failure_code: paymentIntent.last_payment_error?.code
      }
    })

  } catch (error) {
    console.error('Error handling payment failure:', error)
  }
}

async function handlePaymentCancellation(
  supabase: any,
  paymentIntent: Stripe.PaymentIntent
): Promise<void> {
  
  const orderId = paymentIntent.metadata.order_id
  
  console.log(`🚫 Payment cancelled for order ${orderId}`)

  // Similar to failure handling but with cancelled status
  await handlePaymentFailure(supabase, paymentIntent)
}

async function checkAutoReleaseConditions(
  supabase: any,
  orderId: string
): Promise<boolean> {
  
  // Get order details to check delivery method and other conditions
  const { data: order, error } = await supabase
    .from('orders')
    .select('delivery_method, status')
    .eq('id', orderId)
    .single()

  if (error || !order) {
    return false
  }

  // Auto-release for customer pickup orders (no delivery required)
  if (order.delivery_method === 'customer_pickup') {
    return true
  }

  // Add other auto-release conditions as needed
  return false
}

async function releaseFundsFromEscrow(
  supabase: any,
  escrowAccountId: string,
  releaseReason: string
): Promise<void> {
  
  // This function will be implemented in the fund distribution Edge Function
  // For now, just log the intent
  console.log(`📤 Funds release requested for escrow ${escrowAccountId}, reason: ${releaseReason}`)
  
  // Call the fund distribution function
  try {
    const response = await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/distribute-escrow-funds`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        escrow_account_id: escrowAccountId,
        release_reason: releaseReason
      })
    })

    if (!response.ok) {
      throw new Error(`Fund distribution failed: ${response.statusText}`)
    }

    console.log(`✅ Funds successfully released from escrow ${escrowAccountId}`)
  } catch (error) {
    console.error('Error releasing funds from escrow:', error)
  }
}

async function handleWalletTopupSuccess(
  supabase: any,
  paymentIntent: Stripe.PaymentIntent,
  walletId: string,
  transactionId: string
): Promise<void> {

  console.log(`💰 Processing wallet top-up success for wallet ${walletId}`)

  try {
    const amount = paymentIntent.amount / 100 // Convert from cents

    // Get current wallet balance
    const { data: wallet, error: walletError } = await supabase
      .from('stakeholder_wallets')
      .select('available_balance')
      .eq('id', walletId)
      .single()

    if (walletError || !wallet) {
      throw new Error(`Wallet not found: ${walletError?.message}`)
    }

    // Update wallet balance
    const newBalance = wallet.available_balance + amount
    const { error: updateError } = await supabase
      .from('stakeholder_wallets')
      .update({
        available_balance: newBalance,
        total_earned: supabase.rpc('increment_total_earned', { wallet_id: walletId, amount: amount }),
        updated_at: new Date().toISOString(),
        last_activity_at: new Date().toISOString()
      })
      .eq('id', walletId)

    if (updateError) {
      throw new Error(`Failed to update wallet balance: ${updateError.message}`)
    }

    // Update transaction status
    const { error: transactionError } = await supabase
      .from('wallet_transactions')
      .update({
        balance_after: newBalance,
        processed_at: new Date().toISOString(),
        metadata: {
          stripe_payment_intent_id: paymentIntent.id,
          payment_status: 'completed',
          amount_received: amount
        }
      })
      .eq('id', transactionId)

    if (transactionError) {
      throw new Error(`Failed to update transaction: ${transactionError.message}`)
    }

    // Log successful wallet top-up
    await logFinancialAudit(supabase, {
      event_type: 'wallet_topup_completed',
      entity_type: 'wallet_transaction',
      entity_id: transactionId,
      user_id: paymentIntent.metadata.user_id || 'system',
      amount: amount,
      old_status: 'pending',
      new_status: 'completed',
      description: `Wallet top-up completed via Stripe`,
      metadata: {
        stripe_payment_intent_id: paymentIntent.id,
        wallet_id: walletId,
        amount_added: amount,
        new_balance: newBalance
      }
    })

    console.log(`✅ Wallet top-up completed: RM ${amount} added to wallet ${walletId}`)

  } catch (error) {
    console.error(`❌ Error processing wallet top-up for wallet ${walletId}:`, error)

    // Log the error
    await logFinancialAudit(supabase, {
      event_type: 'wallet_topup_error',
      entity_type: 'wallet_transaction',
      entity_id: transactionId,
      user_id: paymentIntent.metadata.user_id || 'system',
      amount: paymentIntent.amount / 100,
      description: `Error processing wallet top-up: ${error.message}`,
      metadata: {
        stripe_payment_intent_id: paymentIntent.id,
        wallet_id: walletId,
        error_details: error.message
      }
    })
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
    // Don't throw error - audit logging failure shouldn't break webhook processing
  }
}
