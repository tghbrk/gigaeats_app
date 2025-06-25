import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface BillRequest {
  action: 'create_bill_split' | 'get_group_bills' | 'update_bill_split' | 'settle_bill'
  group_id?: string
  bill_split_id?: string
  title?: string
  description?: string
  total_amount?: number
  split_method?: string
  participants?: Array<{
    user_id: string
    amount_owed?: number
    percentage?: number
  }>
  receipt_image_url?: string
  category?: string
  transaction_date?: string
  limit?: number
  start_date?: string
  end_date?: string
}

interface BillResponse {
  success: boolean
  data?: any
  error?: string
  bill_split?: any
  bill_splits?: any[]
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
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

    // Verify user authentication
    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser()

    if (authError || !user) {
      throw new Error('Unauthorized')
    }

    // Parse request body
    const requestData: BillRequest = await req.json()
    const { action } = requestData

    console.log(`🔍 [SOCIAL-WALLET-BILLS] Processing action: ${action} for user: ${user.id}`)

    let response: BillResponse

    switch (action) {
      case 'create_bill_split':
        response = await createBillSplit(supabaseClient, user.id, requestData)
        break
      case 'get_group_bills':
        response = await getGroupBills(supabaseClient, user.id, requestData)
        break
      case 'update_bill_split':
        response = await updateBillSplit(supabaseClient, user.id, requestData)
        break
      case 'settle_bill':
        response = await settleBill(supabaseClient, user.id, requestData)
        break
      default:
        throw new Error(`Unknown action: ${action}`)
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('❌ [SOCIAL-WALLET-BILLS] Error:', error)
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

// Create a new bill split
async function createBillSplit(supabaseClient: any, userId: string, requestData: BillRequest): Promise<BillResponse> {
  try {
    const {
      group_id,
      title,
      description,
      total_amount,
      split_method,
      participants,
      receipt_image_url,
      category,
      transaction_date
    } = requestData

    if (!group_id || !title || !total_amount || !participants || participants.length === 0) {
      throw new Error('Group ID, title, total amount, and participants are required')
    }

    console.log(`🔍 [CREATE-BILL-SPLIT] Creating bill split: ${title} for group: ${group_id}`)

    // Check if user can create bills in this group
    const canAccess = await supabaseClient
      .rpc('user_can_access_group', { user_id: userId, group_id })

    if (!canAccess.data) {
      throw new Error('Access denied: Cannot create bills in this group')
    }

    // Validate split amounts
    const totalParticipantAmount = participants.reduce((sum, p) => sum + (p.amount_owed || 0), 0)
    if (split_method !== 'equal' && Math.abs(totalParticipantAmount - total_amount) > 0.01) {
      throw new Error('Participant amounts do not match total amount')
    }

    // Create the bill split
    const { data: billSplit, error: billError } = await supabaseClient
      .from('bill_splits')
      .insert({
        group_id,
        created_by: userId,
        title,
        description,
        total_amount,
        split_method: split_method || 'equal',
        receipt_image_url,
        category,
        transaction_date: transaction_date || new Date().toISOString()
      })
      .select()
      .single()

    if (billError) {
      throw new Error(`Failed to create bill split: ${billError.message}`)
    }

    // Calculate amounts for equal split
    let participantData = participants
    if (split_method === 'equal') {
      const amountPerPerson = total_amount / participants.length
      participantData = participants.map(p => ({
        ...p,
        amount_owed: amountPerPerson
      }))
    }

    // Add participants
    const participantInserts = participantData.map(p => ({
      bill_split_id: billSplit.id,
      user_id: p.user_id,
      amount_owed: p.amount_owed || 0,
      percentage: p.percentage || null
    }))

    const { error: participantError } = await supabaseClient
      .from('bill_participants')
      .insert(participantInserts)

    if (participantError) {
      throw new Error(`Failed to add participants: ${participantError.message}`)
    }

    console.log(`✅ [CREATE-BILL-SPLIT] Bill split created successfully: ${billSplit.id}`)

    return {
      success: true,
      bill_split: billSplit
    }
  } catch (error) {
    console.error('❌ [CREATE-BILL-SPLIT] Error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

// Get bill splits for a group
async function getGroupBills(supabaseClient: any, userId: string, requestData: BillRequest): Promise<BillResponse> {
  try {
    const { group_id, limit, start_date, end_date } = requestData

    if (!group_id) {
      throw new Error('Group ID is required')
    }

    console.log(`🔍 [GET-GROUP-BILLS] Fetching bills for group: ${group_id}`)

    // Check if user can access this group
    const canAccess = await supabaseClient
      .rpc('user_can_access_group', { user_id: userId, group_id })

    if (!canAccess.data) {
      throw new Error('Access denied: Cannot access bills for this group')
    }

    // Build query
    let query = supabaseClient
      .from('bill_splits')
      .select(`
        *,
        bill_participants (
          *,
          user_profiles:get_user_profile_for_groups(user_id)
        )
      `)
      .eq('group_id', group_id)
      .order('created_at', { ascending: false })

    if (start_date) {
      query = query.gte('transaction_date', start_date)
    }
    if (end_date) {
      query = query.lte('transaction_date', end_date)
    }
    if (limit) {
      query = query.limit(limit)
    }

    const { data: billSplits, error: billsError } = await query

    if (billsError) {
      throw new Error(`Failed to fetch bill splits: ${billsError.message}`)
    }

    console.log(`✅ [GET-GROUP-BILLS] Found ${billSplits.length} bill splits`)

    return {
      success: true,
      bill_splits: billSplits
    }
  } catch (error) {
    console.error('❌ [GET-GROUP-BILLS] Error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

// Update a bill split
async function updateBillSplit(supabaseClient: any, userId: string, requestData: BillRequest): Promise<BillResponse> {
  try {
    const { bill_split_id, title, description, total_amount, participants } = requestData

    if (!bill_split_id) {
      throw new Error('Bill split ID is required')
    }

    console.log(`🔍 [UPDATE-BILL-SPLIT] Updating bill split: ${bill_split_id}`)

    // Check if user created this bill split
    const { data: billSplit, error: billError } = await supabaseClient
      .from('bill_splits')
      .select('*')
      .eq('id', bill_split_id)
      .eq('created_by', userId)
      .single()

    if (billError || !billSplit) {
      throw new Error('Access denied: Cannot update this bill split')
    }

    // Update bill split details
    const updateData: any = {}
    if (title) updateData.title = title
    if (description !== undefined) updateData.description = description
    if (total_amount) updateData.total_amount = total_amount

    if (Object.keys(updateData).length > 0) {
      const { error: updateError } = await supabaseClient
        .from('bill_splits')
        .update(updateData)
        .eq('id', bill_split_id)

      if (updateError) {
        throw new Error(`Failed to update bill split: ${updateError.message}`)
      }
    }

    // Update participants if provided
    if (participants && participants.length > 0) {
      // Delete existing participants
      await supabaseClient
        .from('bill_participants')
        .delete()
        .eq('bill_split_id', bill_split_id)

      // Add updated participants
      const participantInserts = participants.map(p => ({
        bill_split_id,
        user_id: p.user_id,
        amount_owed: p.amount_owed || 0,
        percentage: p.percentage || null
      }))

      const { error: participantError } = await supabaseClient
        .from('bill_participants')
        .insert(participantInserts)

      if (participantError) {
        throw new Error(`Failed to update participants: ${participantError.message}`)
      }
    }

    console.log(`✅ [UPDATE-BILL-SPLIT] Bill split updated successfully: ${bill_split_id}`)

    return {
      success: true,
      data: { message: 'Bill split updated successfully' }
    }
  } catch (error) {
    console.error('❌ [UPDATE-BILL-SPLIT] Error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

// Settle a bill split
async function settleBill(supabaseClient: any, userId: string, requestData: BillRequest): Promise<BillResponse> {
  try {
    const { bill_split_id } = requestData

    if (!bill_split_id) {
      throw new Error('Bill split ID is required')
    }

    console.log(`🔍 [SETTLE-BILL] Settling bill split: ${bill_split_id}`)

    // Check if user is a participant in this bill split
    const { data: participant, error: participantError } = await supabaseClient
      .from('bill_participants')
      .select('*')
      .eq('bill_split_id', bill_split_id)
      .eq('user_id', userId)
      .single()

    if (participantError || !participant) {
      throw new Error('Access denied: You are not a participant in this bill split')
    }

    // Mark participant as settled
    const { error: settleError } = await supabaseClient
      .from('bill_participants')
      .update({
        amount_paid: participant.amount_owed,
        is_settled: true,
        settled_at: new Date().toISOString()
      })
      .eq('id', participant.id)

    if (settleError) {
      throw new Error(`Failed to settle participant: ${settleError.message}`)
    }

    // Check if all participants are settled
    const { data: allParticipants } = await supabaseClient
      .from('bill_participants')
      .select('is_settled')
      .eq('bill_split_id', bill_split_id)

    const allSettled = allParticipants?.every(p => p.is_settled) || false

    // If all settled, mark bill as settled
    if (allSettled) {
      await supabaseClient
        .from('bill_splits')
        .update({
          is_settled: true,
          settled_at: new Date().toISOString()
        })
        .eq('id', bill_split_id)
    }

    console.log(`✅ [SETTLE-BILL] Bill settlement updated for: ${bill_split_id}`)

    return {
      success: true,
      data: {
        message: 'Bill settled successfully',
        all_settled: allSettled
      }
    }
  } catch (error) {
    console.error('❌ [SETTLE-BILL] Error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}
