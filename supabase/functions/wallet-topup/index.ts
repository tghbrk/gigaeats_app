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

interface WalletTopupRequest {
  amount: number
  currency?: string
  payment_method_id?: string
  save_payment_method?: boolean
}

interface WalletTopupResponse {
  success: boolean
  client_secret?: string
  transaction_id?: string
  error?: string
  requires_action?: boolean
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

    // Get user from request
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing authorization header')
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)
    
    if (authError || !user) {
      throw new Error('Invalid authentication token')
    }

    const requestBody: WalletTopupRequest = await req.json()
    const { amount, currency = 'myr', payment_method_id, save_payment_method = false } = requestBody

    // Validate request
    if (!amount || amount <= 0) {
      throw new Error('Invalid amount. Amount must be greater than 0')
    }

    if (amount < 1 || amount > 10000) {
      throw new Error('Amount must be between RM 1.00 and RM 10,000.00')
    }

    console.log(`💰 Processing wallet top-up for user ${user.id}: RM ${amount}`)

    // Get or create customer wallet
    let { data: wallet, error: walletError } = await supabaseClient
      .from('stakeholder_wallets')
      .select('*')
      .eq('user_id', user.id)
      .eq('user_role', 'customer')
      .single()

    if (walletError && walletError.code === 'PGRST116') {
      // Wallet doesn't exist, create it
      const { data: newWallet, error: createError } = await supabaseClient
        .from('stakeholder_wallets')
        .insert({
          user_id: user.id,
          user_role: 'customer',
          currency: currency.toUpperCase(),
          is_active: true,
          is_verified: true
        })
        .select()
        .single()

      if (createError) {
        throw new Error(`Failed to create wallet: ${createError.message}`)
      }
      wallet = newWallet
    } else if (walletError) {
      throw new Error(`Failed to get wallet: ${walletError.message}`)
    }

    // Create wallet transaction record
    const { data: transaction, error: transactionError } = await supabaseClient
      .from('wallet_transactions')
      .insert({
        wallet_id: wallet.id,
        transaction_type: 'credit',
        amount: amount,
        currency: currency.toUpperCase(),
        balance_before: wallet.available_balance,
        balance_after: wallet.available_balance + amount,
        reference_type: 'wallet_topup',
        description: `Wallet top-up via Stripe`,
        metadata: {
          payment_method: 'stripe',
          save_payment_method: save_payment_method
        },
        processed_by: user.id
      })
      .select()
      .single()

    if (transactionError) {
      throw new Error(`Failed to create transaction: ${transactionError.message}`)
    }

    // Get or create Stripe customer
    let stripeCustomerId: string

    const { data: userProfile } = await supabaseClient
      .from('user_profiles')
      .select('stripe_customer_id, email, full_name')
      .eq('user_id', user.id)
      .single()

    if (userProfile?.stripe_customer_id) {
      stripeCustomerId = userProfile.stripe_customer_id
    } else {
      // Create new Stripe customer
      const stripeCustomer = await stripe.customers.create({
        email: user.email || userProfile?.email,
        name: userProfile?.full_name,
        metadata: {
          user_id: user.id,
          role: 'customer'
        }
      })

      stripeCustomerId = stripeCustomer.id

      // Update user profile with Stripe customer ID
      await supabaseClient
        .from('user_profiles')
        .update({ stripe_customer_id: stripeCustomerId })
        .eq('user_id', user.id)
    }

    // Create Stripe PaymentIntent
    const paymentIntentParams: Stripe.PaymentIntentCreateParams = {
      amount: Math.round(amount * 100), // Convert to cents
      currency: currency,
      customer: stripeCustomerId,
      metadata: {
        user_id: user.id,
        wallet_id: wallet.id,
        transaction_id: transaction.id,
        type: 'wallet_topup'
      },
      description: `GigaEats Wallet Top-up - RM ${amount.toFixed(2)}`,
      automatic_payment_methods: {
        enabled: true,
      },
    }

    // Add payment method if provided
    if (payment_method_id) {
      paymentIntentParams.payment_method = payment_method_id
      paymentIntentParams.confirmation_method = 'manual'
      paymentIntentParams.confirm = true
    }

    // Setup future usage if saving payment method
    if (save_payment_method) {
      paymentIntentParams.setup_future_usage = 'off_session'
    }

    const paymentIntent = await stripe.paymentIntents.create(paymentIntentParams)

    // Update transaction with Stripe PaymentIntent ID
    await supabaseClient
      .from('wallet_transactions')
      .update({
        metadata: {
          ...transaction.metadata,
          stripe_payment_intent_id: paymentIntent.id,
          client_secret: paymentIntent.client_secret
        }
      })
      .eq('id', transaction.id)

    console.log(`✅ PaymentIntent created: ${paymentIntent.id}`)

    const response: WalletTopupResponse = {
      success: true,
      client_secret: paymentIntent.client_secret!,
      transaction_id: transaction.id,
      requires_action: paymentIntent.status === 'requires_action'
    }

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('❌ Wallet top-up error:', error)
    
    const response: WalletTopupResponse = {
      success: false,
      error: error.message
    }

    return new Response(JSON.stringify(response), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
