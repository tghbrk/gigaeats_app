import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface LoyaltyRedemptionsRequest {
  action: 'list'
  user_id?: string
  limit?: number
  offset?: number
  status?: string
}

interface LoyaltyRedemptionsResponse {
  success: boolean
  redemptions?: any[]
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

    const request: LoyaltyRedemptionsRequest = await req.json()
    console.log(`🎯 Processing loyalty redemptions request: ${request.action} for user: ${user.id}`)

    let result: LoyaltyRedemptionsResponse

    switch (request.action) {
      case 'list':
        result = await getLoyaltyRedemptions(supabaseClient, user.id, request)
        break
      default:
        throw new Error(`Unsupported action: ${request.action}`)
    }

    console.log(`✅ Loyalty redemptions request processed: ${request.action}`)

    return new Response(
      JSON.stringify(result),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('❌ Loyalty redemptions error:', error)

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

async function getLoyaltyRedemptions(
  supabase: any,
  userId: string,
  request: LoyaltyRedemptionsRequest
): Promise<LoyaltyRedemptionsResponse> {
  try {
    // Get user's loyalty account
    const { data: loyaltyAccount, error: accountError } = await supabase
      .from('loyalty_accounts')
      .select('id')
      .eq('user_id', userId)
      .single()

    if (accountError || !loyaltyAccount) {
      throw new Error('Loyalty account not found')
    }

    // Build query with joins to get loyalty reward details
    let query = supabase
      .from('loyalty_redemptions')
      .select(`
        *,
        loyalty_rewards (
          id,
          name,
          description,
          reward_type,
          reward_value,
          category
        )
      `)
      .eq('loyalty_account_id', loyaltyAccount.id)
      .order('created_at', { ascending: false })

    // Apply status filter if provided
    if (request.status) {
      query = query.eq('status', request.status)
    }

    // Apply pagination
    const limit = request.limit || 20
    const offset = request.offset || 0
    query = query.range(offset, offset + limit - 1)

    const { data: redemptions, error } = await query

    if (error) {
      throw new Error(`Failed to get loyalty redemptions: ${error.message}`)
    }

    // Get total count for pagination
    let countQuery = supabase
      .from('reward_redemptions')
      .select('*', { count: 'exact', head: true })
      .eq('loyalty_account_id', loyaltyAccount.id)

    if (request.status) {
      countQuery = countQuery.eq('status', request.status)
    }

    const { count } = await countQuery

    // Transform redemptions to include computed fields
    const transformedRedemptions = (redemptions || []).map(redemption => ({
      ...redemption,
      is_expired: checkIfExpired(redemption),
      is_active: redemption.status === 'confirmed' && !checkIfExpired(redemption),
      formatted_points_cost: `${redemption.points_cost} points`,
      formatted_redeemed_date: formatDate(redemption.redeemed_at),
      formatted_expiry_date: redemption.expires_at ? formatDate(redemption.expires_at) : null
    }))

    return {
      success: true,
      redemptions: transformedRedemptions,
      total_count: count || 0
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

function checkIfExpired(redemption: any): boolean {
  if (!redemption.expires_at) return false
  return new Date() > new Date(redemption.expires_at)
}

function formatDate(dateString: string): string {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}
