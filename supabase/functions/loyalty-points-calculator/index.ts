import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PointsCalculationRequest {
  action: 'calculate_order_points' | 'process_order_completion' | 'calculate_tier_progress'
  order_id?: string
  customer_id?: string
  order_amount?: number
  tier_multiplier?: number
  bonus_campaigns?: string[]
}

interface PointsCalculationResponse {
  success: boolean
  points_awarded?: number
  tier_multiplier?: number
  bonus_points?: number
  total_points?: number
  new_tier?: string
  tier_upgraded?: boolean
  loyalty_account?: any
  transaction?: any
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

    const request: PointsCalculationRequest = await req.json()
    console.log(`🧮 Processing points calculation: ${request.action}`)

    let result: PointsCalculationResponse

    switch (request.action) {
      case 'calculate_order_points':
        result = await calculateOrderPoints(supabaseClient, request)
        break
      case 'process_order_completion':
        result = await processOrderCompletion(supabaseClient, request)
        break
      case 'calculate_tier_progress':
        result = await calculateTierProgress(supabaseClient, request)
        break
      default:
        throw new Error(`Unsupported action: ${request.action}`)
    }

    console.log(`✅ Points calculation processed: ${request.action}`)

    return new Response(
      JSON.stringify(result),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('❌ Points calculation error:', error)

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

async function calculateOrderPoints(
  supabase: any,
  request: PointsCalculationRequest
): Promise<PointsCalculationResponse> {
  try {
    if (!request.order_amount || request.order_amount <= 0) {
      throw new Error('Invalid order amount')
    }

    // Base rate: 1 point per RM spent
    const basePoints = Math.floor(request.order_amount)
    
    // Apply tier multiplier (default 1.0 for bronze)
    const tierMultiplier = request.tier_multiplier || 1.0
    const tierPoints = Math.floor(basePoints * tierMultiplier)
    
    // Calculate bonus points from campaigns
    let bonusPoints = 0
    if (request.bonus_campaigns && request.bonus_campaigns.length > 0) {
      bonusPoints = await calculateBonusPoints(supabase, basePoints, request.bonus_campaigns)
    }
    
    const totalPoints = tierPoints + bonusPoints

    console.log(`🧮 Points calculation: Base=${basePoints}, Tier=${tierPoints} (${tierMultiplier}x), Bonus=${bonusPoints}, Total=${totalPoints}`)

    return {
      success: true,
      points_awarded: basePoints,
      tier_multiplier: tierMultiplier,
      bonus_points: bonusPoints,
      total_points: totalPoints
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

async function processOrderCompletion(
  supabase: any,
  request: PointsCalculationRequest
): Promise<PointsCalculationResponse> {
  try {
    if (!request.order_id || !request.customer_id) {
      throw new Error('Missing order_id or customer_id')
    }

    // Get order details
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select('id, total_amount, status, customer_id')
      .eq('id', request.order_id)
      .single()

    if (orderError || !order) {
      throw new Error(`Order not found: ${orderError?.message}`)
    }

    if (order.customer_id !== request.customer_id) {
      throw new Error('Order does not belong to specified customer')
    }

    // Get customer's loyalty account
    const { data: loyaltyAccount, error: accountError } = await supabase
      .from('loyalty_accounts')
      .select('*')
      .eq('user_id', request.customer_id)
      .single()

    if (accountError || !loyaltyAccount) {
      throw new Error('Loyalty account not found')
    }

    // Check if points already awarded for this order
    const { data: existingTransaction } = await supabase
      .from('loyalty_transactions')
      .select('id')
      .eq('reference_type', 'order')
      .eq('reference_id', request.order_id)
      .eq('transaction_type', 'earned')
      .single()

    if (existingTransaction) {
      throw new Error('Points already awarded for this order')
    }

    // Calculate points to award
    const pointsCalculation = await calculateOrderPoints(supabase, {
      action: 'calculate_order_points',
      order_amount: order.total_amount,
      tier_multiplier: loyaltyAccount.tier_multiplier
    })

    if (!pointsCalculation.success || !pointsCalculation.total_points) {
      throw new Error('Failed to calculate points')
    }

    // Award points using loyalty account manager
    const awardResult = await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/loyalty-account-manager`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        action: 'award_points',
        user_id: request.customer_id,
        points_amount: pointsCalculation.total_points,
        transaction_type: 'earned',
        reference_type: 'order',
        reference_id: request.order_id,
        description: `Points earned from order #${order.id}`,
        metadata: {
          order_amount: order.total_amount,
          base_points: pointsCalculation.points_awarded,
          tier_multiplier: pointsCalculation.tier_multiplier,
          bonus_points: pointsCalculation.bonus_points
        },
        expires_at: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString() // 1 year expiry
      })
    })

    if (!awardResult.ok) {
      throw new Error(`Failed to award points: ${awardResult.statusText}`)
    }

    const awardData = await awardResult.json()

    if (!awardData.success) {
      throw new Error(`Failed to award points: ${awardData.error}`)
    }

    // Check for tier progression
    const tierResult = await calculateTierProgress(supabase, {
      action: 'calculate_tier_progress',
      customer_id: request.customer_id
    })

    console.log(`🎯 Awarded ${pointsCalculation.total_points} points for order ${request.order_id}`)

    return {
      success: true,
      points_awarded: pointsCalculation.points_awarded,
      tier_multiplier: pointsCalculation.tier_multiplier,
      bonus_points: pointsCalculation.bonus_points,
      total_points: pointsCalculation.total_points,
      new_tier: tierResult.new_tier,
      tier_upgraded: tierResult.tier_upgraded,
      loyalty_account: awardData.loyalty_account,
      transaction: awardData.transaction
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

async function calculateTierProgress(
  supabase: any,
  request: PointsCalculationRequest
): Promise<PointsCalculationResponse> {
  try {
    if (!request.customer_id) {
      throw new Error('Missing customer_id')
    }

    // Get loyalty account
    const { data: loyaltyAccount, error: accountError } = await supabase
      .from('loyalty_accounts')
      .select('*')
      .eq('user_id', request.customer_id)
      .single()

    if (accountError || !loyaltyAccount) {
      throw new Error('Loyalty account not found')
    }

    // Determine new tier based on lifetime earned points
    const newTier = getTierFromPoints(loyaltyAccount.lifetime_earned_points)
    const tierUpgraded = newTier !== loyaltyAccount.current_tier

    if (tierUpgraded) {
      // Update tier in loyalty account
      const newMultiplier = getTierMultiplier(newTier)
      const nextTierRequirement = getNextTierRequirement(newTier)
      const tierProgress = calculateTierProgress(loyaltyAccount.lifetime_earned_points, newTier)

      const { error: updateError } = await supabase
        .from('loyalty_accounts')
        .update({
          current_tier: newTier,
          tier_multiplier: newMultiplier,
          next_tier_requirement: nextTierRequirement,
          tier_progress: tierProgress,
          updated_at: new Date().toISOString()
        })
        .eq('id', loyaltyAccount.id)

      if (updateError) {
        throw new Error(`Failed to update tier: ${updateError.message}`)
      }

      console.log(`🏆 Tier upgraded for user ${request.customer_id}: ${loyaltyAccount.current_tier} → ${newTier}`)
    }

    return {
      success: true,
      new_tier: newTier,
      tier_upgraded: tierUpgraded
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

async function calculateBonusPoints(
  supabase: any,
  basePoints: number,
  campaigns: string[]
): Promise<number> {
  // Placeholder for bonus campaign logic
  // In production, this would query active campaigns and calculate bonuses
  let bonusPoints = 0

  for (const campaign of campaigns) {
    switch (campaign) {
      case 'weekend_bonus':
        bonusPoints += Math.floor(basePoints * 0.1) // 10% weekend bonus
        break
      case 'new_customer':
        bonusPoints += 100 // Fixed 100 points for new customers
        break
      case 'double_points':
        bonusPoints += basePoints // Double points campaign
        break
    }
  }

  return bonusPoints
}

function getTierFromPoints(lifetimePoints: number): string {
  if (lifetimePoints >= 20000) return 'diamond'
  if (lifetimePoints >= 8000) return 'platinum'
  if (lifetimePoints >= 3000) return 'gold'
  if (lifetimePoints >= 1000) return 'silver'
  return 'bronze'
}

function getTierMultiplier(tier: string): number {
  switch (tier) {
    case 'bronze': return 1.0
    case 'silver': return 1.2
    case 'gold': return 1.5
    case 'platinum': return 2.0
    case 'diamond': return 3.0
    default: return 1.0
  }
}

function getNextTierRequirement(tier: string): number | null {
  switch (tier) {
    case 'bronze': return 1000
    case 'silver': return 3000
    case 'gold': return 8000
    case 'platinum': return 20000
    case 'diamond': return null // Max tier
    default: return 1000
  }
}

function calculateTierProgress(lifetimePoints: number, tier: string): number {
  switch (tier) {
    case 'bronze': return lifetimePoints
    case 'silver': return lifetimePoints - 1000
    case 'gold': return lifetimePoints - 3000
    case 'platinum': return lifetimePoints - 8000
    case 'diamond': return lifetimePoints - 20000
    default: return lifetimePoints
  }
}
