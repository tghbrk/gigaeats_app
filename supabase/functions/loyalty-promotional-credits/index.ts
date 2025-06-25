import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PromotionalCreditsRequest {
  action: 'list'
  user_id?: string
  limit?: number
  offset?: number
  active_only?: boolean
  status?: string
}

interface PromotionalCreditsResponse {
  success: boolean
  promotional_credits?: any[]
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

    const request: PromotionalCreditsRequest = await req.json()
    console.log(`🎯 Processing promotional credits request: ${request.action} for user: ${user.id}`)

    let result: PromotionalCreditsResponse

    switch (request.action) {
      case 'list':
        result = await getPromotionalCredits(supabaseClient, user.id, request)
        break
      default:
        throw new Error(`Unsupported action: ${request.action}`)
    }

    console.log(`✅ Promotional credits request processed: ${request.action}`)

    return new Response(
      JSON.stringify(result),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('❌ Promotional credits error:', error)

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

async function getPromotionalCredits(
  supabase: any,
  userId: string,
  request: PromotionalCreditsRequest
): Promise<PromotionalCreditsResponse> {
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

    // Build query for promotional credits
    let query = supabase
      .from('promotional_credits')
      .select('*')
      .eq('loyalty_account_id', loyaltyAccount.id)
      .order('created_at', { ascending: false })

    // Apply status filter if provided
    if (request.status) {
      query = query.eq('status', request.status)
    }

    // Apply active_only filter
    if (request.active_only) {
      const now = new Date().toISOString()
      query = query
        .eq('status', 'active')
        .lte('valid_from', now)
        .or(`valid_until.is.null,valid_until.gte.${now}`)
        .gt('remaining_amount', 0)
    }

    // Apply pagination
    const limit = request.limit || 20
    const offset = request.offset || 0
    query = query.range(offset, offset + limit - 1)

    const { data: credits, error } = await query

    if (error) {
      throw new Error(`Failed to get promotional credits: ${error.message}`)
    }

    // Get total count for pagination
    let countQuery = supabase
      .from('promotional_credits')
      .select('*', { count: 'exact', head: true })
      .eq('loyalty_account_id', loyaltyAccount.id)

    if (request.status) {
      countQuery = countQuery.eq('status', request.status)
    }

    if (request.active_only) {
      const now = new Date().toISOString()
      countQuery = countQuery
        .eq('status', 'active')
        .lte('valid_from', now)
        .or(`valid_until.is.null,valid_until.gte.${now}`)
        .gt('remaining_amount', 0)
    }

    const { count } = await countQuery

    // Transform credits to include computed fields
    const transformedCredits = (credits || []).map(credit => ({
      ...credit,
      is_expired: checkIfExpired(credit),
      is_active: checkIfActive(credit),
      usage_percentage: calculateUsagePercentage(credit),
      formatted_original_amount: formatCurrency(credit.original_amount),
      formatted_remaining_amount: formatCurrency(credit.remaining_amount),
      formatted_used_amount: formatCurrency(credit.original_amount - credit.remaining_amount),
      formatted_valid_from: formatDate(credit.valid_from),
      formatted_valid_until: credit.valid_until ? formatDate(credit.valid_until) : null,
      days_until_expiry: credit.valid_until ? calculateDaysUntilExpiry(credit.valid_until) : null
    }))

    return {
      success: true,
      promotional_credits: transformedCredits,
      total_count: count || 0
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

function checkIfExpired(credit: any): boolean {
  if (!credit.valid_until) return false
  return new Date() > new Date(credit.valid_until)
}

function checkIfActive(credit: any): boolean {
  if (credit.status !== 'active') return false
  if (credit.remaining_amount <= 0) return false
  
  const now = new Date()
  const validFrom = new Date(credit.valid_from)
  const validUntil = credit.valid_until ? new Date(credit.valid_until) : null
  
  if (now < validFrom) return false
  if (validUntil && now > validUntil) return false
  
  return true
}

function calculateUsagePercentage(credit: any): number {
  if (credit.original_amount === 0) return 0
  const usedAmount = credit.original_amount - credit.remaining_amount
  return Math.round((usedAmount / credit.original_amount) * 100)
}

function formatCurrency(amount: number): string {
  return `RM ${amount.toFixed(2)}`
}

function formatDate(dateString: string): string {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

function calculateDaysUntilExpiry(validUntil: string): number {
  const now = new Date()
  const expiry = new Date(validUntil)
  const diffTime = expiry.getTime() - now.getTime()
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  return Math.max(0, diffDays)
}
