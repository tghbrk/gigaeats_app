import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14.21.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PaymentMethodRequest {
  action: 'list' | 'add' | 'update' | 'delete' | 'set_default'
  payment_method_id?: string
  stripe_payment_method_id?: string
  nickname?: string
  is_default?: boolean
}

interface PaymentMethodResponse {
  success: boolean
  data?: any
  error?: string
  message?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Stripe
    const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
      apiVersion: '2023-10-16',
    })

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get authenticated user
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Parse request body
    const { action, payment_method_id, stripe_payment_method_id, nickname, is_default }: PaymentMethodRequest = await req.json()

    console.log(`🔍 [PAYMENT-METHODS] Processing ${action} for user: ${user.id}`)

    let response: PaymentMethodResponse

    switch (action) {
      case 'list':
        response = await listPaymentMethods(supabaseClient, stripe, user.id)
        break
      case 'add':
        if (!stripe_payment_method_id) {
          throw new Error('stripe_payment_method_id is required for add action')
        }
        response = await addPaymentMethod(supabaseClient, stripe, user.id, stripe_payment_method_id, nickname)
        break
      case 'update':
        if (!payment_method_id) {
          throw new Error('payment_method_id is required for update action')
        }
        response = await updatePaymentMethod(supabaseClient, user.id, payment_method_id, { nickname })
        break
      case 'delete':
        if (!payment_method_id) {
          throw new Error('payment_method_id is required for delete action')
        }
        response = await deletePaymentMethod(supabaseClient, stripe, user.id, payment_method_id)
        break
      case 'set_default':
        if (!payment_method_id) {
          throw new Error('payment_method_id is required for set_default action')
        }
        response = await setDefaultPaymentMethod(supabaseClient, user.id, payment_method_id)
        break
      default:
        throw new Error(`Unknown action: ${action}`)
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('❌ [PAYMENT-METHODS] Error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Internal server error',
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})

async function listPaymentMethods(supabaseClient: any, stripe: Stripe, userId: string): Promise<PaymentMethodResponse> {
  try {
    // Get payment methods from database
    const { data: paymentMethods, error } = await supabaseClient
      .rpc('get_user_payment_methods', { p_user_id: userId })

    if (error) {
      throw new Error(`Database error: ${error.message}`)
    }

    console.log(`✅ [PAYMENT-METHODS] Found ${paymentMethods?.length || 0} payment methods for user: ${userId}`)

    return {
      success: true,
      data: paymentMethods || [],
    }
  } catch (error) {
    console.error('❌ [PAYMENT-METHODS] List error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function addPaymentMethod(
  supabaseClient: any,
  stripe: Stripe,
  userId: string,
  stripePaymentMethodId: string,
  nickname?: string
): Promise<PaymentMethodResponse> {
  try {
    // Get user's Stripe customer ID
    const { data: userProfile } = await supabaseClient
      .from('user_profiles')
      .select('stripe_customer_id')
      .eq('user_id', userId)
      .single()

    if (!userProfile?.stripe_customer_id) {
      throw new Error('User does not have a Stripe customer ID')
    }

    // Retrieve payment method from Stripe
    const paymentMethod = await stripe.paymentMethods.retrieve(stripePaymentMethodId)

    // Attach payment method to customer if not already attached
    if (paymentMethod.customer !== userProfile.stripe_customer_id) {
      await stripe.paymentMethods.attach(stripePaymentMethodId, {
        customer: userProfile.stripe_customer_id,
      })
    }

    // Determine if this should be the default (if user has no payment methods)
    const { data: existingMethods } = await supabaseClient
      .from('customer_payment_methods')
      .select('id')
      .eq('user_id', userId)
      .eq('is_active', true)

    const isFirstMethod = !existingMethods || existingMethods.length === 0

    // Prepare payment method data
    const paymentMethodData: any = {
      user_id: userId,
      stripe_payment_method_id: stripePaymentMethodId,
      stripe_customer_id: userProfile.stripe_customer_id,
      type: paymentMethod.type,
      is_default: isFirstMethod,
      nickname: nickname || null,
    }

    // Add type-specific details
    if (paymentMethod.type === 'card' && paymentMethod.card) {
      paymentMethodData.card_brand = paymentMethod.card.brand
      paymentMethodData.card_last4 = paymentMethod.card.last4
      paymentMethodData.card_exp_month = paymentMethod.card.exp_month
      paymentMethodData.card_exp_year = paymentMethod.card.exp_year
      paymentMethodData.card_funding = paymentMethod.card.funding
      paymentMethodData.card_country = paymentMethod.card.country
    }

    // Insert into database
    const { data: newPaymentMethod, error } = await supabaseClient
      .from('customer_payment_methods')
      .insert(paymentMethodData)
      .select()
      .single()

    if (error) {
      throw new Error(`Database error: ${error.message}`)
    }

    console.log(`✅ [PAYMENT-METHODS] Added payment method: ${newPaymentMethod.id}`)

    return {
      success: true,
      data: newPaymentMethod,
      message: 'Payment method added successfully',
    }
  } catch (error) {
    console.error('❌ [PAYMENT-METHODS] Add error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function updatePaymentMethod(
  supabaseClient: any,
  userId: string,
  paymentMethodId: string,
  updates: { nickname?: string }
): Promise<PaymentMethodResponse> {
  try {
    const { data: updatedMethod, error } = await supabaseClient
      .from('customer_payment_methods')
      .update(updates)
      .eq('id', paymentMethodId)
      .eq('user_id', userId)
      .select()
      .single()

    if (error) {
      throw new Error(`Database error: ${error.message}`)
    }

    console.log(`✅ [PAYMENT-METHODS] Updated payment method: ${paymentMethodId}`)

    return {
      success: true,
      data: updatedMethod,
      message: 'Payment method updated successfully',
    }
  } catch (error) {
    console.error('❌ [PAYMENT-METHODS] Update error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function deletePaymentMethod(
  supabaseClient: any,
  stripe: Stripe,
  userId: string,
  paymentMethodId: string
): Promise<PaymentMethodResponse> {
  try {
    // Get payment method details
    const { data: paymentMethod, error: fetchError } = await supabaseClient
      .from('customer_payment_methods')
      .select('stripe_payment_method_id, is_default')
      .eq('id', paymentMethodId)
      .eq('user_id', userId)
      .single()

    if (fetchError || !paymentMethod) {
      throw new Error('Payment method not found')
    }

    // Detach from Stripe
    await stripe.paymentMethods.detach(paymentMethod.stripe_payment_method_id)

    // Delete from database
    const { error: deleteError } = await supabaseClient
      .from('customer_payment_methods')
      .delete()
      .eq('id', paymentMethodId)
      .eq('user_id', userId)

    if (deleteError) {
      throw new Error(`Database error: ${deleteError.message}`)
    }

    // If this was the default method, set another method as default
    if (paymentMethod.is_default) {
      const { data: remainingMethods } = await supabaseClient
        .from('customer_payment_methods')
        .select('id')
        .eq('user_id', userId)
        .eq('is_active', true)
        .limit(1)

      if (remainingMethods && remainingMethods.length > 0) {
        await supabaseClient
          .from('customer_payment_methods')
          .update({ is_default: true })
          .eq('id', remainingMethods[0].id)
      }
    }

    console.log(`✅ [PAYMENT-METHODS] Deleted payment method: ${paymentMethodId}`)

    return {
      success: true,
      message: 'Payment method deleted successfully',
    }
  } catch (error) {
    console.error('❌ [PAYMENT-METHODS] Delete error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function setDefaultPaymentMethod(
  supabaseClient: any,
  userId: string,
  paymentMethodId: string
): Promise<PaymentMethodResponse> {
  try {
    const { data: updatedMethod, error } = await supabaseClient
      .from('customer_payment_methods')
      .update({ is_default: true })
      .eq('id', paymentMethodId)
      .eq('user_id', userId)
      .select()
      .single()

    if (error) {
      throw new Error(`Database error: ${error.message}`)
    }

    console.log(`✅ [PAYMENT-METHODS] Set default payment method: ${paymentMethodId}`)

    return {
      success: true,
      data: updatedMethod,
      message: 'Default payment method updated successfully',
    }
  } catch (error) {
    console.error('❌ [PAYMENT-METHODS] Set default error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}
