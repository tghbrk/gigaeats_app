import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RequestRequest {
  action: 'create_request' | 'get_user_requests' | 'respond_to_request' | 'send_reminder'
  from_user_id?: string
  to_user_id?: string
  amount?: number
  title?: string
  description?: string
  group_id?: string
  bill_split_id?: string
  due_date?: string
  request_id?: string
  status?: string
  response_message?: string
  custom_message?: string
  incoming?: boolean
  limit?: number
}

interface RequestResponse {
  success: boolean
  data?: any
  error?: string
  payment_request?: any
  payment_requests?: any[]
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
    const requestData: RequestRequest = await req.json()
    const { action } = requestData

    console.log(`🔍 [SOCIAL-WALLET-REQUESTS] Processing action: ${action} for user: ${user.id}`)

    let response: RequestResponse

    switch (action) {
      case 'create_request':
        response = await createRequest(supabaseClient, user.id, requestData)
        break
      case 'get_user_requests':
        response = await getUserRequests(supabaseClient, user.id, requestData)
        break
      case 'respond_to_request':
        response = await respondToRequest(supabaseClient, user.id, requestData)
        break
      case 'send_reminder':
        response = await sendReminder(supabaseClient, user.id, requestData)
        break
      default:
        throw new Error(`Unknown action: ${action}`)
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('❌ [SOCIAL-WALLET-REQUESTS] Error:', error)
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

// Create a new payment request
async function createRequest(supabaseClient: any, userId: string, requestData: RequestRequest): Promise<RequestResponse> {
  try {
    const {
      to_user_id,
      amount,
      title,
      description,
      group_id,
      bill_split_id,
      due_date
    } = requestData

    if (!to_user_id || !amount || !title) {
      throw new Error('Recipient, amount, and title are required')
    }

    if (to_user_id === userId) {
      throw new Error('Cannot create payment request to yourself')
    }

    console.log(`🔍 [CREATE-REQUEST] Creating payment request: ${title} for ${amount}`)

    // Verify recipient exists
    const { data: recipient, error: recipientError } = await supabaseClient
      .from('auth.users')
      .select('id, email')
      .eq('id', to_user_id)
      .single()

    if (recipientError || !recipient) {
      throw new Error('Recipient not found')
    }

    // Create the payment request
    const { data: paymentRequest, error: requestError } = await supabaseClient
      .from('payment_requests')
      .insert({
        from_user_id: userId,
        to_user_id,
        amount,
        title,
        description,
        group_id,
        bill_split_id,
        due_date: due_date || new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString() // 7 days from now
      })
      .select()
      .single()

    if (requestError) {
      throw new Error(`Failed to create payment request: ${requestError.message}`)
    }

    console.log(`✅ [CREATE-REQUEST] Payment request created successfully: ${paymentRequest.id}`)

    return {
      success: true,
      payment_request: paymentRequest
    }
  } catch (error) {
    console.error('❌ [CREATE-REQUEST] Error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

// Get user's payment requests
async function getUserRequests(supabaseClient: any, userId: string, requestData: RequestRequest): Promise<RequestResponse> {
  try {
    const { incoming, status, limit } = requestData

    console.log(`🔍 [GET-USER-REQUESTS] Fetching requests for user: ${userId}`)

    // Build query based on incoming/outgoing requests - get basic payment requests first
    let query = supabaseClient
      .from('payment_requests')
      .select(`
        *,
        payment_reminders (*)
      `)
      .order('created_at', { ascending: false })

    if (incoming === true) {
      query = query.eq('to_user_id', userId)
    } else if (incoming === false) {
      query = query.eq('from_user_id', userId)
    } else {
      // Get both incoming and outgoing
      query = query.or(`from_user_id.eq.${userId},to_user_id.eq.${userId}`)
    }

    if (status) {
      query = query.eq('status', status)
    }

    if (limit) {
      query = query.limit(limit)
    }

    const { data: paymentRequests, error: requestsError } = await query

    if (requestsError) {
      throw new Error(`Failed to fetch payment requests: ${requestsError.message}`)
    }

    console.log(`✅ [GET-USER-REQUESTS] Found ${paymentRequests.length} payment requests`)

    // Enhance payment requests with user profile data
    const enhancedRequests = await Promise.all(
      paymentRequests.map(async (request) => {
        try {
          // Get from_user profile
          const { data: fromUser } = await supabaseClient
            .rpc('get_user_profile_for_groups', { user_id: request.from_user_id })

          // Get to_user profile
          const { data: toUser } = await supabaseClient
            .rpc('get_user_profile_for_groups', { user_id: request.to_user_id })

          return {
            ...request,
            from_user: fromUser?.[0] || null,
            to_user: toUser?.[0] || null
          }
        } catch (profileError) {
          console.warn(`⚠️ [GET-USER-REQUESTS] Could not fetch profiles for request ${request.id}:`, profileError)
          return {
            ...request,
            from_user: null,
            to_user: null
          }
        }
      })
    )

    return {
      success: true,
      payment_requests: enhancedRequests
    }
  } catch (error) {
    console.error('❌ [GET-USER-REQUESTS] Error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

// Respond to a payment request
async function respondToRequest(supabaseClient: any, userId: string, requestData: RequestRequest): Promise<RequestResponse> {
  try {
    const { request_id, status, response_message } = requestData

    if (!request_id || !status) {
      throw new Error('Request ID and status are required')
    }

    if (!['accepted', 'declined'].includes(status)) {
      throw new Error('Status must be either "accepted" or "declined"')
    }

    console.log(`🔍 [RESPOND-TO-REQUEST] Responding to request: ${request_id} with status: ${status}`)

    // Check if user is the recipient of this request
    const { data: paymentRequest, error: requestError } = await supabaseClient
      .from('payment_requests')
      .select('*')
      .eq('id', request_id)
      .eq('to_user_id', userId)
      .eq('status', 'pending')
      .single()

    if (requestError || !paymentRequest) {
      throw new Error('Payment request not found or access denied')
    }

    // Update the request status
    const { error: updateError } = await supabaseClient
      .from('payment_requests')
      .update({
        status,
        responded_at: new Date().toISOString(),
        response_message
      })
      .eq('id', request_id)

    if (updateError) {
      throw new Error(`Failed to update payment request: ${updateError.message}`)
    }

    // If accepted, create a group transaction record
    if (status === 'accepted') {
      await supabaseClient
        .from('group_transactions')
        .insert({
          group_id: paymentRequest.group_id,
          payment_request_id: request_id,
          from_user_id: userId,
          to_user_id: paymentRequest.from_user_id,
          amount: paymentRequest.amount,
          transaction_type: 'request_payment',
          description: `Payment for: ${paymentRequest.title}`,
          status: 'completed'
        })
    }

    console.log(`✅ [RESPOND-TO-REQUEST] Request response recorded: ${request_id}`)

    return {
      success: true,
      data: { message: `Payment request ${status} successfully` }
    }
  } catch (error) {
    console.error('❌ [RESPOND-TO-REQUEST] Error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

// Send a payment reminder
async function sendReminder(supabaseClient: any, userId: string, requestData: RequestRequest): Promise<RequestResponse> {
  try {
    const { request_id, custom_message } = requestData

    if (!request_id) {
      throw new Error('Request ID is required')
    }

    console.log(`🔍 [SEND-REMINDER] Sending reminder for request: ${request_id}`)

    // Check if user is involved in this request (sender or recipient)
    const { data: paymentRequest, error: requestError } = await supabaseClient
      .from('payment_requests')
      .select('*')
      .eq('id', request_id)
      .or(`from_user_id.eq.${userId},to_user_id.eq.${userId}`)
      .single()

    if (requestError || !paymentRequest) {
      throw new Error('Payment request not found or access denied')
    }

    // Only allow reminders for pending requests
    if (paymentRequest.status !== 'pending') {
      throw new Error('Can only send reminders for pending requests')
    }

    // Create reminder record
    const { error: reminderError } = await supabaseClient
      .from('payment_reminders')
      .insert({
        payment_request_id: request_id,
        sent_by: userId,
        message: custom_message || 'Friendly reminder about your pending payment request'
      })

    if (reminderError) {
      throw new Error(`Failed to send reminder: ${reminderError.message}`)
    }

    console.log(`✅ [SEND-REMINDER] Reminder sent successfully for request: ${request_id}`)

    return {
      success: true,
      data: { message: 'Reminder sent successfully' }
    }
  } catch (error) {
    console.error('❌ [SEND-REMINDER] Error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}
