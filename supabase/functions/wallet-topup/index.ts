import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from "https://esm.sh/stripe@14.5.0?target=deno";

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  httpClient: Stripe.createFetchHttpClient(),
  apiVersion: '2023-10-16'
});

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};

serve(async (req) => {
  const timestamp = new Date().toISOString();
  console.log(`🚀 [WALLET-TOPUP-V7-${timestamp}] Function called - Method: ${req.method}`);

  if (req.method === 'OPTIONS') {
    console.log(`🚀 [WALLET-TOPUP-V7-${timestamp}] OPTIONS request - returning CORS headers`);
    return new Response('ok', { headers: corsHeaders });
  }

  console.log(`🚀 [WALLET-TOPUP-V7-${timestamp}] Processing ${req.method} request`);

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Get user from request
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Missing authorization header');
    }

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token);
    if (authError || !user) {
      console.log(`❌ [WALLET-TOPUP-V7-${timestamp}] User authentication failed: ${authError?.message}`);
      throw new Error('Invalid authentication token');
    }

    console.log(`✅ [WALLET-TOPUP-V7-${timestamp}] User authenticated: ${user.email}`);

    // Log function call to database for debugging
    try {
      await supabaseClient
        .from('wallet_transactions')
        .insert({
          wallet_id: '00000000-0000-0000-0000-000000000000', // Placeholder
          transaction_type: 'adjustment',
          amount: 0.01, // Small amount to satisfy CHECK constraint
          currency: 'MYR',
          balance_before: 0,
          balance_after: 0,
          reference_type: 'debug',
          reference_id: `debug-${timestamp}`,
          description: `Function called V7-${timestamp}`,
          processed_by: user.id,
          processing_fee: 0,
          metadata: { debug: true, version: 'V7', timestamp, payment_method: 'debug' },
          processed_at: new Date().toISOString()
        });
      console.log(`📝 [WALLET-TOPUP-V7-${timestamp}] Debug log inserted to database`);
    } catch (debugError) {
      console.log(`❌ [WALLET-TOPUP-V7-${timestamp}] Failed to insert debug log: ${debugError.message}`);
    }

    const requestBody = await req.json();
    const { amount, currency = 'myr', payment_method_id, save_payment_method = false } = requestBody;

    // Validate request
    if (!amount || amount <= 0) {
      throw new Error('Invalid amount. Amount must be greater than 0');
    }
    if (amount < 1 || amount > 10000) {
      throw new Error('Amount must be between RM 1.00 and RM 10,000.00');
    }

    console.log(`💰 [WALLET-TOPUP-V7-${timestamp}] Processing wallet top-up for user ${user.id}: RM ${amount}`);

    // Get or create customer wallet
    let { data: wallet, error: walletError } = await supabaseClient
      .from('stakeholder_wallets')
      .select('*')
      .eq('user_id', user.id)
      .eq('user_role', 'customer')
      .single();

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
        .single();

      if (createError) {
        throw new Error(`Failed to create wallet: ${createError.message}`);
      }
      wallet = newWallet;
    } else if (walletError) {
      throw new Error(`Failed to get wallet: ${walletError.message}`);
    }

    console.log(`✅ [WALLET-TOPUP-V5] Wallet found/created for user: ${user.id}`);

    // Get Stripe customer ID - prioritize from payment method if provided
    console.log(`🔍 [WALLET-TOPUP-V7-${timestamp}] Getting Stripe customer ID for user: ${user.id}`);
    let stripeCustomerId;

    if (payment_method_id) {
      // If using saved payment method, get customer ID directly from Stripe PaymentMethod
      console.log(`🔍 [WALLET-TOPUP-V7] Getting customer ID from Stripe PaymentMethod: ${payment_method_id}`);

      // First verify the payment method exists in our database for this user
      const { data: paymentMethodRecord } = await supabaseClient
        .from('customer_payment_methods')
        .select('stripe_customer_id, stripe_payment_method_id')
        .eq('user_id', user.id)
        .eq('stripe_payment_method_id', payment_method_id)
        .eq('is_active', true)
        .single();

      if (!paymentMethodRecord) {
        throw new Error(`Payment method ${payment_method_id} not found or not active for user`);
      }

      // Get the actual customer ID from Stripe PaymentMethod
      const paymentMethod = await stripe.paymentMethods.retrieve(payment_method_id);
      if (!paymentMethod.customer) {
        throw new Error(`PaymentMethod ${payment_method_id} is not attached to any customer`);
      }

      stripeCustomerId = paymentMethod.customer as string;
      console.log(`✅ [WALLET-TOPUP-V7] Using customer ID from Stripe PaymentMethod: ${stripeCustomerId}`);
    } else {
      // For new payment methods, get/create customer from customer_profiles
      console.log(`🔍 [WALLET-TOPUP-V5] Getting customer profile for new payment method`);
      const { data: customerProfile } = await supabaseClient
        .from('customer_profiles')
        .select('stripe_customer_id, email, full_name')
        .eq('user_id', user.id)
        .single();

      if (customerProfile?.stripe_customer_id) {
        stripeCustomerId = customerProfile.stripe_customer_id;
        console.log(`✅ [WALLET-TOPUP-V5] Using existing Stripe customer: ${stripeCustomerId}`);
      } else {
        // Create new Stripe customer
        console.log(`🔄 [WALLET-TOPUP-V5] Creating new Stripe customer for user: ${user.id}`);
        const stripeCustomer = await stripe.customers.create({
          email: user.email || customerProfile?.email,
          name: customerProfile?.full_name,
          metadata: {
            supabase_user_id: user.id,
            created_via: 'wallet_topup_v5',
            created_at: new Date().toISOString(),
          }
        });
        stripeCustomerId = stripeCustomer.id;
        console.log(`✅ [WALLET-TOPUP-V5] Created Stripe customer: ${stripeCustomerId}`);

        // Update customer profile with Stripe customer ID
        await supabaseClient
          .from('customer_profiles')
          .update({ stripe_customer_id: stripeCustomerId })
          .eq('user_id', user.id);
      }
    }

    // Convert amount to cents for Stripe
    const amountInCents = Math.round(amount * 100);

    // Create payment intent parameters
    const paymentIntentParams: any = {
      amount: amountInCents,
      currency: currency.toLowerCase(),
      customer: stripeCustomerId,
      metadata: {
        user_id: user.id,
        wallet_id: wallet.id,
        type: 'wallet_topup',
        created_at: new Date().toISOString(),
      },
      description: `Wallet top-up for ${user.email || user.id}`,
    };

    // Configure payment method handling
    if (payment_method_id) {
      // Using saved payment method - specify payment method and provide return_url
      paymentIntentParams.payment_method = payment_method_id;
      paymentIntentParams.confirm = true;
      paymentIntentParams.return_url = 'gigaeats://payment/return';
      console.log(`💳 [WALLET-TOPUP-V4] Using saved payment method: ${payment_method_id} with return_url`);
    } else {
      // New payment method - use automatic payment methods with return_url
      paymentIntentParams.automatic_payment_methods = {
        enabled: true
      };
      paymentIntentParams.return_url = 'gigaeats://payment/return';
      console.log(`💳 [WALLET-TOPUP-V4] Using automatic payment methods for new card with return_url`);
    }

    console.log(`🔄 [WALLET-TOPUP-V4] Creating payment intent with customer: ${stripeCustomerId}`);

    // Create payment intent
    const paymentIntent = await stripe.paymentIntents.create(paymentIntentParams);

    console.log(`✅ [WALLET-TOPUP-V4] Payment intent created: ${paymentIntent.id}`);

    // If using saved payment method and payment succeeded, create a wallet transaction (trigger will update balance)
    if (payment_method_id && paymentIntent.status === 'succeeded') {
      console.log(`💰 [WALLET-TOPUP-V7] Payment succeeded, inserting wallet transaction`);

      const { error: transactionError } = await supabaseClient
        .from('wallet_transactions')
        .insert({
          wallet_id: wallet.id,
          transaction_type: 'credit',
          amount: amount,
          currency: currency.toUpperCase(),
          balance_before: wallet.available_balance,
          balance_after: wallet.available_balance + amount,
          reference_type: 'wallet_topup',
          reference_id: null, // Don't use reference_id for Stripe Payment Intent ID (it's UUID type)
          description: 'Wallet top-up via Stripe',
          processed_by: user.id,
          processing_fee: 0,
          metadata: {
            stripe_payment_intent_id: paymentIntent.id,
            stripe_payment_method_id: payment_method_id,
            created_via: 'wallet_topup_v7',
            payment_method: 'stripe'
          },
          processed_at: new Date().toISOString()
        });

      if (transactionError) {
        console.error(`❌ [WALLET-TOPUP-V7] Failed to create transaction: ${transactionError.message}`);
        console.error(`❌ [WALLET-TOPUP-V7] Transaction error details:`, transactionError);
      } else {
        console.log(`✅ [WALLET-TOPUP-V7] Transaction record created successfully`);
      }

      console.log(`✅ [WALLET-TOPUP-V7] Wallet top-up completed successfully`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        payment_intent: {
          id: paymentIntent.id,
          client_secret: paymentIntent.client_secret,
          status: paymentIntent.status,
          amount: paymentIntent.amount,
          currency: paymentIntent.currency
        }
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    );

  } catch (error) {
    console.error(`❌ [WALLET-TOPUP-V4] Error:`, error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    );
  }
});
