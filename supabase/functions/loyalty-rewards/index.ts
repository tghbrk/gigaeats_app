import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface LoyaltyRewardsRequest {
  action: 'list_available'
  limit?: number
  offset?: number
  category?: string
}

interface LoyaltyRewardsResponse {
  success: boolean
  rewards?: any[]
  total_count?: number
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

    const request: LoyaltyRewardsRequest = await req.json()
    console.log(`🎯 Processing loyalty rewards request: ${request.action}`)

    let result: LoyaltyRewardsResponse

    switch (request.action) {
      case 'list_available':
        result = await getAvailableRewards(supabaseClient, request)
        break
      default:
        throw new Error(`Unsupported action: ${request.action}`)
    }

    console.log(`✅ Loyalty rewards request processed: ${request.action}`)

    return new Response(
      JSON.stringify(result),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('❌ Loyalty rewards error:', error)

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

async function getAvailableRewards(
  supabase: any,
  request: LoyaltyRewardsRequest
): Promise<LoyaltyRewardsResponse> {
  try {
    // Build query for active loyalty rewards
    let query = supabase
      .from('loyalty_rewards')
      .select('*')
      .eq('is_active', true)
      .lte('valid_from', new Date().toISOString())
      .order('points_required', { ascending: true })

    // Filter by valid_until (null means no expiry)
    query = query.or(`valid_until.is.null,valid_until.gte.${new Date().toISOString()}`)

    // Apply category filter if provided
    if (request.category) {
      query = query.eq('category', request.category)
    }

    // Apply pagination
    const limit = request.limit || 20
    const offset = request.offset || 0
    query = query.range(offset, offset + limit - 1)

    const { data: rewards, error } = await query

    if (error) {
      throw new Error(`Failed to get available rewards: ${error.message}`)
    }

    // Get total count for pagination
    let countQuery = supabase
      .from('loyalty_rewards')
      .select('*', { count: 'exact', head: true })
      .eq('is_active', true)
      .lte('valid_from', new Date().toISOString())

    countQuery = countQuery.or(`valid_until.is.null,valid_until.gte.${new Date().toISOString()}`)

    if (request.category) {
      countQuery = countQuery.eq('category', request.category)
    }

    const { count } = await countQuery

    // Transform rewards to include availability status
    const transformedRewards = (rewards || []).map(reward => ({
      ...reward,
      is_currently_available: checkRewardAvailability(reward),
      formatted_points_cost: `${reward.points_cost} points`
    }))

    return {
      success: true,
      rewards: transformedRewards,
      total_count: count || 0
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

function checkRewardAvailability(reward: any): boolean {
  const now = new Date()
  const validFrom = new Date(reward.valid_from)
  const validUntil = reward.valid_until ? new Date(reward.valid_until) : null

  // Check if reward is within valid date range
  if (now < validFrom) return false
  if (validUntil && now > validUntil) return false

  // Check if reward has reached max redemptions
  if (reward.max_total_redemptions && reward.current_redemptions >= reward.max_total_redemptions) {
    return false
  }

  return reward.is_active
}
