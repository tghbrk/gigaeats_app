import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface TierRequest {
  action: 'get_tiers' | 'check_tier_progression' | 'process_tier_upgrade' | 'get_tier_benefits'
  customer_id?: string
  current_points?: number
  tier_name?: string
}

interface TierResponse {
  success: boolean
  tiers?: any[]
  current_tier?: any
  next_tier?: any
  tier_upgraded?: boolean
  upgrade_bonus?: number
  benefits?: any
  progress_percentage?: number
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

    const request: TierRequest = await req.json()
    console.log(`🏆 Processing tier request: ${request.action}`)

    let result: TierResponse

    switch (request.action) {
      case 'get_tiers':
        result = await getTiers(supabaseClient)
        break
      case 'check_tier_progression':
        result = await checkTierProgression(supabaseClient, request)
        break
      case 'process_tier_upgrade':
        result = await processTierUpgrade(supabaseClient, request)
        break
      case 'get_tier_benefits':
        result = await getTierBenefits(supabaseClient, request)
        break
      default:
        throw new Error(`Unsupported action: ${request.action}`)
    }

    console.log(`✅ Tier request processed: ${request.action}`)

    return new Response(
      JSON.stringify(result),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('❌ Tier management error:', error)

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

async function getTiers(supabase: any): Promise<TierResponse> {
  try {
    const { data: tiers, error } = await supabase
      .from('loyalty_tiers')
      .select('*')
      .eq('is_active', true)
      .order('sort_order', { ascending: true })

    if (error) {
      throw new Error(`Failed to get tiers: ${error.message}`)
    }

    return {
      success: true,
      tiers: tiers
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

async function checkTierProgression(
  supabase: any,
  request: TierRequest
): Promise<TierResponse> {
  try {
    if (!request.customer_id) {
      throw new Error('Customer ID is required')
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

    // Get all tiers
    const { data: tiers, error: tiersError } = await supabase
      .from('loyalty_tiers')
      .select('*')
      .eq('is_active', true)
      .order('sort_order', { ascending: true })

    if (tiersError) {
      throw new Error(`Failed to get tiers: ${tiersError.message}`)
    }

    // Find current tier
    const currentTier = tiers.find(tier => tier.name === loyaltyAccount.current_tier)
    if (!currentTier) {
      throw new Error('Current tier not found')
    }

    // Find next tier
    const nextTier = tiers.find(tier => 
      tier.min_points > loyaltyAccount.lifetime_earned_points
    )

    // Calculate progress percentage
    let progressPercentage = 0
    if (nextTier) {
      const pointsInCurrentTier = loyaltyAccount.lifetime_earned_points - currentTier.min_points
      const pointsNeededForNext = nextTier.min_points - currentTier.min_points
      progressPercentage = Math.min(100, (pointsInCurrentTier / pointsNeededForNext) * 100)
    } else {
      progressPercentage = 100 // Max tier reached
    }

    // Check if tier upgrade is needed
    const newTierName = getTierFromPoints(loyaltyAccount.lifetime_earned_points)
    const tierUpgraded = newTierName !== loyaltyAccount.current_tier

    return {
      success: true,
      current_tier: currentTier,
      next_tier: nextTier,
      tier_upgraded: tierUpgraded,
      progress_percentage: Math.round(progressPercentage)
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

async function processTierUpgrade(
  supabase: any,
  request: TierRequest
): Promise<TierResponse> {
  try {
    if (!request.customer_id) {
      throw new Error('Customer ID is required')
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

    // Determine new tier based on lifetime points
    const newTierName = getTierFromPoints(loyaltyAccount.lifetime_earned_points)
    
    if (newTierName === loyaltyAccount.current_tier) {
      return {
        success: true,
        tier_upgraded: false,
        current_tier: { name: loyaltyAccount.current_tier }
      }
    }

    // Get tier details
    const { data: newTier, error: tierError } = await supabase
      .from('loyalty_tiers')
      .select('*')
      .eq('name', newTierName)
      .single()

    if (tierError || !newTier) {
      throw new Error('New tier not found')
    }

    // Calculate tier upgrade bonus
    const upgradeBonus = getTierUpgradeBonus(newTierName)
    
    // Calculate next tier requirement and progress
    const nextTierRequirement = getNextTierRequirement(newTierName)
    const tierProgress = calculateTierProgress(loyaltyAccount.lifetime_earned_points, newTierName)

    // Update loyalty account with new tier
    const { data: updatedAccount, error: updateError } = await supabase
      .from('loyalty_accounts')
      .update({
        current_tier: newTierName,
        tier_multiplier: newTier.multiplier,
        next_tier_requirement: nextTierRequirement,
        tier_progress: tierProgress,
        available_points: loyaltyAccount.available_points + upgradeBonus,
        last_activity_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', loyaltyAccount.id)
      .select()
      .single()

    if (updateError) {
      throw new Error(`Failed to update tier: ${updateError.message}`)
    }

    // Create tier upgrade bonus transaction
    if (upgradeBonus > 0) {
      await supabase
        .from('loyalty_transactions')
        .insert({
          loyalty_account_id: loyaltyAccount.id,
          transaction_type: 'bonus',
          points_amount: upgradeBonus,
          points_balance_before: loyaltyAccount.available_points,
          points_balance_after: loyaltyAccount.available_points + upgradeBonus,
          reference_type: 'tier_upgrade',
          reference_id: loyaltyAccount.id,
          description: `Tier upgrade bonus to ${newTierName}`,
          metadata: {
            old_tier: loyaltyAccount.current_tier,
            new_tier: newTierName,
            bonus_points: upgradeBonus
          },
          created_at: new Date().toISOString()
        })
    }

    console.log(`🏆 Tier upgraded for user ${request.customer_id}: ${loyaltyAccount.current_tier} → ${newTierName} (+${upgradeBonus} bonus points)`)

    return {
      success: true,
      tier_upgraded: true,
      current_tier: newTier,
      upgrade_bonus: upgradeBonus
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

async function getTierBenefits(
  supabase: any,
  request: TierRequest
): Promise<TierResponse> {
  try {
    if (!request.tier_name) {
      throw new Error('Tier name is required')
    }

    const { data: tier, error } = await supabase
      .from('loyalty_tiers')
      .select('*')
      .eq('name', request.tier_name)
      .eq('is_active', true)
      .single()

    if (error || !tier) {
      throw new Error('Tier not found')
    }

    return {
      success: true,
      benefits: tier.benefits
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

function getTierFromPoints(lifetimePoints: number): string {
  if (lifetimePoints >= 20000) return 'diamond'
  if (lifetimePoints >= 8000) return 'platinum'
  if (lifetimePoints >= 3000) return 'gold'
  if (lifetimePoints >= 1000) return 'silver'
  return 'bronze'
}

function getTierUpgradeBonus(tierName: string): number {
  switch (tierName) {
    case 'silver': return 200
    case 'gold': return 300
    case 'platinum': return 500
    case 'diamond': return 1000
    default: return 0
  }
}

function getNextTierRequirement(tierName: string): number | null {
  switch (tierName) {
    case 'bronze': return 1000
    case 'silver': return 3000
    case 'gold': return 8000
    case 'platinum': return 20000
    case 'diamond': return null // Max tier
    default: return 1000
  }
}

function calculateTierProgress(lifetimePoints: number, tierName: string): number {
  switch (tierName) {
    case 'bronze': return lifetimePoints
    case 'silver': return lifetimePoints - 1000
    case 'gold': return lifetimePoints - 3000
    case 'platinum': return lifetimePoints - 8000
    case 'diamond': return lifetimePoints - 20000
    default: return lifetimePoints
  }
}
