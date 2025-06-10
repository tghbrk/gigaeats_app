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
    
    console.log(`🔔 Webhook received: ${event.type}`)

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    if (event.type === 'payment_intent.succeeded') {
      const paymentIntent = event.data.object as Stripe.PaymentIntent
      const orderId = paymentIntent.metadata.order_id
      const transactionId = paymentIntent.metadata.transaction_id

      console.log(`✅ Payment succeeded for order ${orderId}`)

      // Update payment transaction status
      const { error: transactionError } = await supabaseClient
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
      }

      // Update order payment status
      const { error: orderError } = await supabaseClient
        .from('orders')
        .update({ 
          payment_status: 'paid',
          payment_reference: paymentIntent.id,
          updated_at: new Date().toISOString()
        })
        .eq('id', orderId)

      if (orderError) {
        console.error('Failed to update order:', orderError)
      } else {
        console.log(`✅ Successfully updated order ${orderId} to paid`)
      }

      // Log payment completion
      if (transactionId) {
        await supabaseClient
          .from('payment_audit_log')
          .insert({
            payment_transaction_id: transactionId,
            action: 'payment_completed',
            old_status: 'pending',
            new_status: 'completed',
            user_id: 'system',
            details: {
              stripe_payment_intent_id: paymentIntent.id,
              amount: paymentIntent.amount,
              currency: paymentIntent.currency
            },
            created_at: new Date().toISOString()
          })
      }
    }

    if (event.type === 'payment_intent.payment_failed') {
      const paymentIntent = event.data.object as Stripe.PaymentIntent
      const orderId = paymentIntent.metadata.order_id
      const transactionId = paymentIntent.metadata.transaction_id

      console.log(`❌ Payment failed for order ${orderId}`)

      // Update payment transaction status
      const { error: transactionError } = await supabaseClient
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

      // Log payment failure
      if (transactionId) {
        await supabaseClient
          .from('payment_audit_log')
          .insert({
            payment_transaction_id: transactionId,
            action: 'payment_failed',
            old_status: 'pending',
            new_status: 'failed',
            user_id: 'system',
            details: {
              stripe_payment_intent_id: paymentIntent.id,
              error: paymentIntent.last_payment_error?.message || 'Payment failed'
            },
            created_at: new Date().toISOString()
          })
      }
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('Webhook Error:', err.message)
    return new Response(`Webhook Error: ${err.message}`, {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
