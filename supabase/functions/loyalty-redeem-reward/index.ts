import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RedeemRewardRequest {
  user_id: string
  reward_program_id: string
  points_cost: number
}

interface RedeemRewardResponse {
  success: boolean
  redemption?: any
  error?: string
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

    const request: RedeemRewardRequest = await req.json()
    console.log(`🎯 Processing reward redemption for user: ${user.id}, reward: ${request.reward_program_id}`)

    const result = await redeemReward(supabaseClient, user.id, request)

    console.log(`✅ Reward redemption processed for user: ${user.id}`)

    return new Response(
      JSON.stringify(result),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('❌ Reward redemption error:', error)

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

async function redeemReward(
  supabase: any,
  userId: string,
  request: RedeemRewardRequest
): Promise<RedeemRewardResponse> {
  try {
    // Start transaction by getting loyalty account
    const { data: loyaltyAccount, error: accountError } = await supabase
      .from('loyalty_accounts')
      .select('*')
      .eq('user_id', userId)
      .single()

    if (accountError || !loyaltyAccount) {
      throw new Error('Loyalty account not found')
    }

    // Get loyalty reward details
    const { data: loyaltyReward, error: rewardError } = await supabase
      .from('loyalty_rewards')
      .select('*')
      .eq('id', request.reward_program_id)
      .single()

    if (rewardError || !loyaltyReward) {
      throw new Error('Loyalty reward not found')
    }

    // Validate reward availability
    if (!loyaltyReward.is_active) {
      throw new Error('Loyalty reward is not active')
    }

    const now = new Date()
    const validFrom = new Date(loyaltyReward.valid_from)
    const validUntil = loyaltyReward.valid_until ? new Date(loyaltyReward.valid_until) : null

    if (now < validFrom || (validUntil && now > validUntil)) {
      throw new Error('Loyalty reward is not currently valid')
    }

    // Check if user has sufficient points
    if (loyaltyAccount.available_points < request.points_cost) {
      throw new Error('Insufficient points balance')
    }

    // Verify points cost matches
    if (loyaltyReward.points_required !== request.points_cost) {
      throw new Error('Points cost mismatch')
    }

    // Check max redemptions per customer
    if (loyaltyReward.max_redemptions_per_customer) {
      const { count: userRedemptions } = await supabase
        .from('loyalty_redemptions')
        .select('*', { count: 'exact', head: true })
        .eq('loyalty_account_id', loyaltyAccount.id)
        .eq('reward_id', request.reward_program_id)

      if (userRedemptions >= loyaltyReward.max_redemptions_per_customer) {
        throw new Error('Maximum redemptions per customer reached')
      }
    }

    // Check max total redemptions
    if (loyaltyReward.max_total_redemptions &&
        loyaltyReward.current_redemptions >= loyaltyReward.max_total_redemptions) {
      throw new Error('Maximum total redemptions reached')
    }

    // Generate redemption code
    const redemptionCode = generateRedemptionCode()

    // Create redemption record
    const { data: redemption, error: redemptionError } = await supabase
      .from('loyalty_redemptions')
      .insert({
        loyalty_account_id: loyaltyAccount.id,
        reward_id: request.reward_program_id,
        points_used: request.points_cost,
        voucher_code: redemptionCode,
        status: 'active',
        created_at: new Date().toISOString(),
        expires_at: calculateExpiryDate(loyaltyReward)
      })
      .select()
      .single()

    if (redemptionError) {
      throw new Error(`Failed to create redemption: ${redemptionError.message}`)
    }

    // Deduct points using loyalty-account-manager
    const pointsResponse = await supabase.functions.invoke('loyalty-account-manager', {
      body: {
        action: 'redeem_points',
        points_amount: request.points_cost,
        reference_type: 'reward_redemption',
        reference_id: redemption.id,
        description: `Redeemed reward: ${loyaltyReward.name}`,
        metadata: {
          reward_program_id: request.reward_program_id,
          redemption_code: redemptionCode
        }
      }
    })

    if (!pointsResponse.data?.success) {
      // Rollback redemption if points deduction fails
      await supabase
        .from('loyalty_redemptions')
        .delete()
        .eq('id', redemption.id)
      
      throw new Error('Failed to deduct points')
    }

    // Update loyalty reward redemption count
    await supabase
      .from('loyalty_rewards')
      .update({
        current_redemptions: loyaltyReward.current_redemptions + 1,
        updated_at: new Date().toISOString()
      })
      .eq('id', request.reward_program_id)

    return {
      success: true,
      redemption: {
        ...redemption,
        loyalty_reward: loyaltyReward
      }
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

function generateRedemptionCode(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  let result = 'RDM'
  for (let i = 0; i < 8; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return result
}

function calculateExpiryDate(loyaltyReward: any): string | null {
  if (!loyaltyReward.redemption_validity_days) return null

  const expiryDate = new Date()
  expiryDate.setDate(expiryDate.getDate() + loyaltyReward.redemption_validity_days)
  return expiryDate.toISOString()
}
