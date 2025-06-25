import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface LoyaltyTransactionsRequest {
  action: 'list'
  user_id?: string
  limit?: number
  offset?: number
  transaction_type?: string
}

interface LoyaltyTransactionsResponse {
  success: boolean
  transactions?: any[]
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

    const request: LoyaltyTransactionsRequest = await req.json()
    console.log(`🎯 Processing loyalty transactions request: ${request.action} for user: ${user.id}`)

    let result: LoyaltyTransactionsResponse

    switch (request.action) {
      case 'list':
        result = await getLoyaltyTransactions(supabaseClient, user.id, request)
        break
      default:
        throw new Error(`Unsupported action: ${request.action}`)
    }

    console.log(`✅ Loyalty transactions request processed: ${request.action}`)

    return new Response(
      JSON.stringify(result),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('❌ Loyalty transactions error:', error)

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

async function getLoyaltyTransactions(
  supabase: any,
  userId: string,
  request: LoyaltyTransactionsRequest
): Promise<LoyaltyTransactionsResponse> {
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

    // Build query
    let query = supabase
      .from('loyalty_transactions')
      .select('*')
      .eq('loyalty_account_id', loyaltyAccount.id)
      .order('created_at', { ascending: false })

    // Apply filters
    if (request.transaction_type) {
      query = query.eq('transaction_type', request.transaction_type)
    }

    // Apply pagination
    const limit = request.limit || 20
    const offset = request.offset || 0
    query = query.range(offset, offset + limit - 1)

    const { data: transactions, error } = await query

    if (error) {
      throw new Error(`Failed to get loyalty transactions: ${error.message}`)
    }

    // Get total count for pagination
    let countQuery = supabase
      .from('loyalty_transactions')
      .select('*', { count: 'exact', head: true })
      .eq('loyalty_account_id', loyaltyAccount.id)

    if (request.transaction_type) {
      countQuery = countQuery.eq('transaction_type', request.transaction_type)
    }

    const { count } = await countQuery

    return {
      success: true,
      transactions: transactions || [],
      total_count: count || 0
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}
