import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface LoyaltyAccountRequest {
  action: 'get' | 'create' | 'update' | 'award_points' | 'redeem_points'
  user_id?: string
  points_amount?: number
  transaction_type?: string
  reference_type?: string
  reference_id?: string
  description?: string
  metadata?: Record<string, any>
  expires_at?: string
}

interface LoyaltyAccountResponse {
  success: boolean
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

    const request: LoyaltyAccountRequest = await req.json()
    console.log(`🎯 Processing loyalty account request: ${request.action} for user: ${user.id}`)

    let result: LoyaltyAccountResponse

    switch (request.action) {
      case 'get':
        result = await getLoyaltyAccount(supabaseClient, user.id)
        break
      case 'create':
        result = await createLoyaltyAccount(supabaseClient, user.id)
        break
      case 'award_points':
        result = await awardPoints(supabaseClient, user.id, request)
        break
      case 'redeem_points':
        result = await redeemPoints(supabaseClient, user.id, request)
        break
      default:
        throw new Error(`Unsupported action: ${request.action}`)
    }

    console.log(`✅ Loyalty account request processed: ${request.action}`)

    return new Response(
      JSON.stringify(result),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('❌ Loyalty account error:', error)

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

async function getLoyaltyAccount(
  supabase: any,
  userId: string
): Promise<LoyaltyAccountResponse> {
  try {
    const { data: loyaltyAccount, error } = await supabase
      .from('loyalty_accounts')
      .select('*')
      .eq('user_id', userId)
      .single()

    if (error && error.code !== 'PGRST116') { // PGRST116 = no rows returned
      throw new Error(`Failed to get loyalty account: ${error.message}`)
    }

    if (!loyaltyAccount) {
      // Auto-create loyalty account if it doesn't exist
      return await createLoyaltyAccount(supabase, userId)
    }

    return {
      success: true,
      loyalty_account: loyaltyAccount
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

async function createLoyaltyAccount(
  supabase: any,
  userId: string
): Promise<LoyaltyAccountResponse> {
  try {
    // Check if account already exists
    const { data: existingAccount } = await supabase
      .from('loyalty_accounts')
      .select('id')
      .eq('user_id', userId)
      .single()

    if (existingAccount) {
      return await getLoyaltyAccount(supabase, userId)
    }

    // Get user's wallet ID if exists
    const { data: wallet } = await supabase
      .from('stakeholder_wallets')
      .select('id')
      .eq('user_id', userId)
      .eq('user_role', 'customer')
      .single()

    // Generate unique referral code
    const referralCode = await generateUniqueReferralCode(supabase)

    // Create loyalty account
    const { data: loyaltyAccount, error } = await supabase
      .from('loyalty_accounts')
      .insert({
        user_id: userId,
        wallet_id: wallet?.id || '',
        available_points: 0,
        pending_points: 0,
        lifetime_earned_points: 0,
        lifetime_redeemed_points: 0,
        current_tier: 'bronze',
        tier_progress: 0,
        next_tier_requirement: 1000,
        tier_multiplier: 1.00,
        total_cashback_earned: 0.00,
        pending_cashback: 0.00,
        cashback_rate: 0.0200,
        referral_code: referralCode,
        successful_referrals: 0,
        total_referral_bonus: 0.00,
        status: 'active',
        is_verified: false,
        last_activity_at: new Date().toISOString(),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select()
      .single()

    if (error) {
      throw new Error(`Failed to create loyalty account: ${error.message}`)
    }

    console.log(`🎯 Created loyalty account for user ${userId}: ${loyaltyAccount.id}`)

    return {
      success: true,
      loyalty_account: loyaltyAccount
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

async function awardPoints(
  supabase: any,
  userId: string,
  request: LoyaltyAccountRequest
): Promise<LoyaltyAccountResponse> {
  try {
    if (!request.points_amount || request.points_amount <= 0) {
      throw new Error('Invalid points amount')
    }

    // Get loyalty account
    const { data: loyaltyAccount, error: accountError } = await supabase
      .from('loyalty_accounts')
      .select('*')
      .eq('user_id', userId)
      .single()

    if (accountError || !loyaltyAccount) {
      throw new Error('Loyalty account not found')
    }

    // Calculate new balances
    const newAvailablePoints = loyaltyAccount.available_points + request.points_amount
    const newLifetimeEarned = loyaltyAccount.lifetime_earned_points + request.points_amount

    // Create transaction record
    const { data: transaction, error: transactionError } = await supabase
      .from('loyalty_transactions')
      .insert({
        loyalty_account_id: loyaltyAccount.id,
        transaction_type: request.transaction_type || 'earned',
        points_amount: request.points_amount,
        points_balance_before: loyaltyAccount.available_points,
        points_balance_after: newAvailablePoints,
        reference_type: request.reference_type,
        reference_id: request.reference_id,
        description: request.description || 'Points awarded',
        metadata: request.metadata || {},
        expires_at: request.expires_at,
        created_at: new Date().toISOString()
      })
      .select()
      .single()

    if (transactionError) {
      throw new Error(`Failed to create transaction: ${transactionError.message}`)
    }

    // Update loyalty account
    const { data: updatedAccount, error: updateError } = await supabase
      .from('loyalty_accounts')
      .update({
        available_points: newAvailablePoints,
        lifetime_earned_points: newLifetimeEarned,
        last_activity_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', loyaltyAccount.id)
      .select()
      .single()

    if (updateError) {
      throw new Error(`Failed to update loyalty account: ${updateError.message}`)
    }

    console.log(`🎯 Awarded ${request.points_amount} points to user ${userId}`)

    return {
      success: true,
      loyalty_account: updatedAccount,
      transaction: transaction
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

async function redeemPoints(
  supabase: any,
  userId: string,
  request: LoyaltyAccountRequest
): Promise<LoyaltyAccountResponse> {
  try {
    if (!request.points_amount || request.points_amount <= 0) {
      throw new Error('Invalid points amount')
    }

    // Get loyalty account
    const { data: loyaltyAccount, error: accountError } = await supabase
      .from('loyalty_accounts')
      .select('*')
      .eq('user_id', userId)
      .single()

    if (accountError || !loyaltyAccount) {
      throw new Error('Loyalty account not found')
    }

    // Check sufficient balance
    if (loyaltyAccount.available_points < request.points_amount) {
      throw new Error('Insufficient points balance')
    }

    // Calculate new balances
    const newAvailablePoints = loyaltyAccount.available_points - request.points_amount
    const newLifetimeRedeemed = loyaltyAccount.lifetime_redeemed_points + request.points_amount

    // Create transaction record
    const { data: transaction, error: transactionError } = await supabase
      .from('loyalty_transactions')
      .insert({
        loyalty_account_id: loyaltyAccount.id,
        transaction_type: 'redeemed',
        points_amount: -request.points_amount,
        points_balance_before: loyaltyAccount.available_points,
        points_balance_after: newAvailablePoints,
        reference_type: request.reference_type,
        reference_id: request.reference_id,
        description: request.description || 'Points redeemed',
        metadata: request.metadata || {},
        created_at: new Date().toISOString()
      })
      .select()
      .single()

    if (transactionError) {
      throw new Error(`Failed to create transaction: ${transactionError.message}`)
    }

    // Update loyalty account
    const { data: updatedAccount, error: updateError } = await supabase
      .from('loyalty_accounts')
      .update({
        available_points: newAvailablePoints,
        lifetime_redeemed_points: newLifetimeRedeemed,
        last_activity_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', loyaltyAccount.id)
      .select()
      .single()

    if (updateError) {
      throw new Error(`Failed to update loyalty account: ${updateError.message}`)
    }

    console.log(`🎯 Redeemed ${request.points_amount} points for user ${userId}`)

    return {
      success: true,
      loyalty_account: updatedAccount,
      transaction: transaction
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

async function generateUniqueReferralCode(supabase: any): Promise<string> {
  let attempts = 0
  const maxAttempts = 10

  while (attempts < maxAttempts) {
    // Generate 8-character code: GIGA + 4 random chars
    const randomPart = Math.random().toString(36).substring(2, 6).toUpperCase()
    const code = `GIGA${randomPart}`

    // Check if code exists
    const { data: existing } = await supabase
      .from('loyalty_accounts')
      .select('id')
      .eq('referral_code', code)
      .single()

    if (!existing) {
      return code
    }

    attempts++
  }

  throw new Error('Failed to generate unique referral code')
}
