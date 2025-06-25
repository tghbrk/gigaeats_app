import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RedemptionRequest {
  action: 'validate_redemption' | 'process_redemption' | 'apply_redemption'
  customer_id?: string
  reward_id?: string
  points_required?: number
  order_id?: string
  order_amount?: number
  voucher_code?: string
}

interface RedemptionResponse {
  success: boolean
  valid?: boolean
  redemption?: any
  discount_amount?: number
  voucher_code?: string
  error?: string
  validation_errors?: string[]
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client with service role
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get user from JWT token
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Authorization header required')
    }

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (userError || !user) {
      throw new Error('Invalid authentication token')
    }

    const request: RedemptionRequest = await req.json()
    console.log(`🎫 Processing redemption request: ${request.action} for user: ${user.id}`)

    let result: RedemptionResponse

    switch (request.action) {
      case 'validate_redemption':
        result = await validateRedemption(supabaseClient, user.id, request)
        break
      case 'process_redemption':
        result = await processRedemption(supabaseClient, user.id, request)
        break
      case 'apply_redemption':
        result = await applyRedemption(supabaseClient, user.id, request)
        break
      default:
        throw new Error(`Unsupported action: ${request.action}`)
    }

    console.log(`✅ Redemption request processed: ${request.action}`)

    return new Response(
      JSON.stringify(result),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('❌ Redemption validation error:', error)

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

async function validateRedemption(
  supabase: any,
  userId: string,
  request: RedemptionRequest
): Promise<RedemptionResponse> {
  try {
    const validationErrors: string[] = []

    if (!request.reward_id) {
      validationErrors.push('Reward ID is required')
    }

    if (!request.points_required || request.points_required <= 0) {
      validationErrors.push('Valid points amount is required')
    }

    if (validationErrors.length > 0) {
      return {
        success: false,
        valid: false,
        validation_errors: validationErrors
      }
    }

    // Get customer's loyalty account
    const { data: loyaltyAccount, error: accountError } = await supabase
      .from('loyalty_accounts')
      .select('*')
      .eq('user_id', userId)
      .single()

    if (accountError || !loyaltyAccount) {
      validationErrors.push('Loyalty account not found')
    } else {
      // Check sufficient points
      if (loyaltyAccount.available_points < request.points_required!) {
        validationErrors.push(`Insufficient points. Available: ${loyaltyAccount.available_points}, Required: ${request.points_required}`)
      }
    }

    // Get reward details
    const { data: reward, error: rewardError } = await supabase
      .from('loyalty_rewards')
      .select('*')
      .eq('id', request.reward_id)
      .single()

    if (rewardError || !reward) {
      validationErrors.push('Reward not found')
    } else {
      // Check if reward is active
      if (!reward.is_active) {
        validationErrors.push('Reward is not currently active')
      }

      // Check validity period
      const now = new Date()
      if (new Date(reward.valid_from) > now) {
        validationErrors.push('Reward is not yet valid')
      }

      if (reward.valid_until && new Date(reward.valid_until) < now) {
        validationErrors.push('Reward has expired')
      }

      // Check points requirement
      if (reward.points_required !== request.points_required) {
        validationErrors.push(`Points requirement mismatch. Expected: ${reward.points_required}, Provided: ${request.points_required}`)
      }

      // Check customer redemption limits
      if (reward.max_redemptions_per_customer) {
        const { count: customerRedemptions } = await supabase
          .from('loyalty_redemptions')
          .select('*', { count: 'exact', head: true })
          .eq('customer_id', userId)
          .eq('reward_id', request.reward_id)
          .neq('status', 'cancelled')

        if (customerRedemptions >= reward.max_redemptions_per_customer) {
          validationErrors.push('Customer redemption limit exceeded')
        }
      }

      // Check total redemption limits
      if (reward.max_total_redemptions) {
        if (reward.current_redemptions >= reward.max_total_redemptions) {
          validationErrors.push('Total redemption limit exceeded')
        }
      }

      // Check minimum order amount if provided
      if (request.order_amount && reward.min_order_amount) {
        if (request.order_amount < reward.min_order_amount) {
          validationErrors.push(`Minimum order amount not met. Required: RM ${reward.min_order_amount}, Order: RM ${request.order_amount}`)
        }
      }
    }

    const isValid = validationErrors.length === 0

    return {
      success: true,
      valid: isValid,
      validation_errors: isValid ? undefined : validationErrors
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

async function processRedemption(
  supabase: any,
  userId: string,
  request: RedemptionRequest
): Promise<RedemptionResponse> {
  try {
    // First validate the redemption
    const validation = await validateRedemption(supabase, userId, request)
    
    if (!validation.success || !validation.valid) {
      return validation
    }

    // Get loyalty account and reward details
    const { data: loyaltyAccount } = await supabase
      .from('loyalty_accounts')
      .select('*')
      .eq('user_id', userId)
      .single()

    const { data: reward } = await supabase
      .from('loyalty_rewards')
      .select('*')
      .eq('id', request.reward_id)
      .single()

    // Calculate discount amount
    let discountAmount = 0
    if (reward.reward_type === 'discount_percentage' && reward.reward_value && request.order_amount) {
      discountAmount = (request.order_amount * reward.reward_value) / 100
    } else if (reward.reward_type === 'discount_fixed' && reward.reward_value) {
      discountAmount = reward.reward_value
    }

    // Generate voucher code if needed
    const voucherCode = generateVoucherCode()

    // Create redemption record
    const { data: redemption, error: redemptionError } = await supabase
      .from('loyalty_redemptions')
      .insert({
        customer_id: userId,
        loyalty_account_id: loyaltyAccount.id,
        reward_id: request.reward_id,
        order_id: request.order_id,
        points_used: request.points_required,
        discount_amount: discountAmount,
        status: 'active',
        expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(), // 30 days
        voucher_code: voucherCode,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select()
      .single()

    if (redemptionError) {
      throw new Error(`Failed to create redemption: ${redemptionError.message}`)
    }

    // Redeem points from loyalty account
    const redeemResult = await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/loyalty-account-manager`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        action: 'redeem_points',
        user_id: userId,
        points_amount: request.points_required,
        reference_type: 'redemption',
        reference_id: redemption.id,
        description: `Points redeemed for ${reward.name}`,
        metadata: {
          reward_id: request.reward_id,
          reward_name: reward.name,
          discount_amount: discountAmount,
          voucher_code: voucherCode
        }
      })
    })

    if (!redeemResult.ok) {
      // Rollback redemption record
      await supabase
        .from('loyalty_redemptions')
        .delete()
        .eq('id', redemption.id)

      throw new Error(`Failed to redeem points: ${redeemResult.statusText}`)
    }

    const redeemData = await redeemResult.json()

    if (!redeemData.success) {
      // Rollback redemption record
      await supabase
        .from('loyalty_redemptions')
        .delete()
        .eq('id', redemption.id)

      throw new Error(`Failed to redeem points: ${redeemData.error}`)
    }

    // Update reward redemption count
    await supabase
      .from('loyalty_rewards')
      .update({
        current_redemptions: reward.current_redemptions + 1,
        updated_at: new Date().toISOString()
      })
      .eq('id', request.reward_id)

    console.log(`🎫 Processed redemption for user ${userId}: ${reward.name}`)

    return {
      success: true,
      redemption: redemption,
      discount_amount: discountAmount,
      voucher_code: voucherCode
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

async function applyRedemption(
  supabase: any,
  userId: string,
  request: RedemptionRequest
): Promise<RedemptionResponse> {
  try {
    if (!request.voucher_code && !request.order_id) {
      throw new Error('Either voucher_code or order_id is required')
    }

    // Find redemption record
    let query = supabase
      .from('loyalty_redemptions')
      .select(`
        *,
        loyalty_rewards(name, reward_type, reward_value)
      `)
      .eq('customer_id', userId)
      .eq('status', 'active')

    if (request.voucher_code) {
      query = query.eq('voucher_code', request.voucher_code)
    } else if (request.order_id) {
      query = query.eq('order_id', request.order_id)
    }

    const { data: redemption, error: redemptionError } = await query.single()

    if (redemptionError || !redemption) {
      throw new Error('Valid redemption not found')
    }

    // Check if redemption has expired
    if (redemption.expires_at && new Date(redemption.expires_at) < new Date()) {
      throw new Error('Redemption has expired')
    }

    // Mark redemption as used
    const { error: updateError } = await supabase
      .from('loyalty_redemptions')
      .update({
        status: 'used',
        used_at: new Date().toISOString(),
        order_id: request.order_id || redemption.order_id,
        updated_at: new Date().toISOString()
      })
      .eq('id', redemption.id)

    if (updateError) {
      throw new Error(`Failed to update redemption: ${updateError.message}`)
    }

    console.log(`🎫 Applied redemption for user ${userId}: ${redemption.voucher_code}`)

    return {
      success: true,
      redemption: redemption,
      discount_amount: redemption.discount_amount
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

function generateVoucherCode(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  let result = 'GE' // GigaEats prefix
  for (let i = 0; i < 6; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return result
}
