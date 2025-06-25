import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface AssignmentRequest {
  action: 'create_request' | 'respond_to_request' | 'cancel_request' | 'deactivate_assignment' | 'get_status'
  customer_id?: string
  sales_agent_id?: string
  request_id?: string
  assignment_id?: string
  response?: 'approve' | 'reject'
  message?: string
  priority?: 'low' | 'normal' | 'high' | 'urgent'
  reason?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get the authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('No authorization header')
    }

    // Verify the JWT token
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)
    
    if (authError || !user) {
      throw new Error('Invalid authentication token')
    }

    const assignmentRequest: AssignmentRequest = await req.json()
    
    // Validate request
    if (!assignmentRequest.action) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Missing required field: action' 
        }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    let result: any = { success: false, error: 'Unknown action' }

    switch (assignmentRequest.action) {
      case 'create_request':
        result = await handleCreateRequest(supabaseClient, user.id, assignmentRequest)
        break

      case 'respond_to_request':
        result = await handleRespondToRequest(supabaseClient, user.id, assignmentRequest)
        break

      case 'cancel_request':
        result = await handleCancelRequest(supabaseClient, user.id, assignmentRequest)
        break

      case 'deactivate_assignment':
        result = await handleDeactivateAssignment(supabaseClient, user.id, assignmentRequest)
        break

      case 'get_status':
        result = await handleGetStatus(supabaseClient, user.id, assignmentRequest)
        break

      default:
        result = { success: false, error: `Unknown action: ${assignmentRequest.action}` }
    }

    return new Response(
      JSON.stringify(result), 
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  } catch (error) {
    console.error('Assignment management error:', error)
    
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

async function handleCreateRequest(supabaseClient: any, userId: string, request: AssignmentRequest) {
  if (!request.customer_id || !request.sales_agent_id) {
    return { success: false, error: 'Missing customer_id or sales_agent_id' }
  }

  try {
    // Call the database function
    const { data, error } = await supabaseClient.rpc('create_assignment_request', {
      p_customer_id: request.customer_id,
      p_sales_agent_id: request.sales_agent_id,
      p_message: request.message || null,
      p_priority: request.priority || 'normal'
    })

    if (error) {
      throw error
    }

    const result = data[0]
    if (result.success) {
      // Send notification
      try {
        await supabaseClient.functions.invoke('send-assignment-notification', {
          body: {
            type: 'request_sent',
            assignment_request_id: result.request_id,
            customer_id: request.customer_id,
            sales_agent_id: request.sales_agent_id,
            message: request.message,
            metadata: {
              priority: request.priority,
              expires_at: result.expires_at
            }
          }
        })
      } catch (notificationError) {
        console.error('Notification sending failed:', notificationError)
        // Don't fail the request if notification fails
      }
    }

    return result
  } catch (error) {
    console.error('Create request error:', error)
    return { success: false, error: error.message }
  }
}

async function handleRespondToRequest(supabaseClient: any, userId: string, request: AssignmentRequest) {
  if (!request.request_id || !request.response) {
    return { success: false, error: 'Missing request_id or response' }
  }

  try {
    // Call the database function
    const { data, error } = await supabaseClient.rpc('respond_to_assignment_request', {
      p_request_id: request.request_id,
      p_customer_user_id: userId,
      p_response: request.response,
      p_customer_message: request.message || null
    })

    if (error) {
      throw error
    }

    const result = data[0]
    if (result.success || request.response === 'reject') {
      // Get request details for notification
      const { data: requestData } = await supabaseClient
        .from('customer_assignment_requests')
        .select('customer_id, sales_agent_id')
        .eq('id', request.request_id)
        .single()

      if (requestData) {
        // Send notification
        try {
          await supabaseClient.functions.invoke('send-assignment-notification', {
            body: {
              type: request.response === 'approve' ? 'request_approved' : 'request_rejected',
              assignment_request_id: request.request_id,
              assignment_id: result.assignment_id,
              customer_id: requestData.customer_id,
              sales_agent_id: requestData.sales_agent_id,
              message: request.message
            }
          })
        } catch (notificationError) {
          console.error('Notification sending failed:', notificationError)
          // Don't fail the request if notification fails
        }
      }
    }

    return result
  } catch (error) {
    console.error('Respond to request error:', error)
    return { success: false, error: error.message }
  }
}

async function handleCancelRequest(supabaseClient: any, userId: string, request: AssignmentRequest) {
  if (!request.request_id) {
    return { success: false, error: 'Missing request_id' }
  }

  try {
    // Get sales agent ID from user
    const { data: userData } = await supabaseClient
      .from('users')
      .select('id')
      .eq('supabase_user_id', userId)
      .eq('role', 'sales_agent')
      .single()

    if (!userData) {
      return { success: false, error: 'Sales agent not found' }
    }

    // Call the database function
    const { data, error } = await supabaseClient.rpc('cancel_assignment_request', {
      p_request_id: request.request_id,
      p_sales_agent_id: userData.id,
      p_reason: request.reason || null
    })

    if (error) {
      throw error
    }

    const result = data[0]
    if (result.success) {
      // Get request details for notification
      const { data: requestData } = await supabaseClient
        .from('customer_assignment_requests')
        .select('customer_id, sales_agent_id')
        .eq('id', request.request_id)
        .single()

      if (requestData) {
        // Send notification
        try {
          await supabaseClient.functions.invoke('send-assignment-notification', {
            body: {
              type: 'request_cancelled',
              assignment_request_id: request.request_id,
              customer_id: requestData.customer_id,
              sales_agent_id: requestData.sales_agent_id,
              message: request.reason
            }
          })
        } catch (notificationError) {
          console.error('Notification sending failed:', notificationError)
          // Don't fail the request if notification fails
        }
      }
    }

    return result
  } catch (error) {
    console.error('Cancel request error:', error)
    return { success: false, error: error.message }
  }
}

async function handleDeactivateAssignment(supabaseClient: any, userId: string, request: AssignmentRequest) {
  if (!request.assignment_id || !request.reason) {
    return { success: false, error: 'Missing assignment_id or reason' }
  }

  try {
    // Call the database function
    const { data, error } = await supabaseClient.rpc('deactivate_assignment', {
      p_assignment_id: request.assignment_id,
      p_deactivated_by: userId,
      p_reason: request.reason
    })

    if (error) {
      throw error
    }

    const result = data[0]
    if (result.success) {
      // Get assignment details for notification
      const { data: assignmentData } = await supabaseClient
        .from('customer_assignments')
        .select('customer_id, sales_agent_id')
        .eq('id', request.assignment_id)
        .single()

      if (assignmentData) {
        // Send notification to customer
        try {
          await supabaseClient.functions.invoke('send-assignment-notification', {
            body: {
              type: 'assignment_deactivated',
              assignment_id: request.assignment_id,
              customer_id: assignmentData.customer_id,
              sales_agent_id: assignmentData.sales_agent_id,
              message: request.reason
            }
          })
        } catch (notificationError) {
          console.error('Notification sending failed:', notificationError)
          // Don't fail the request if notification fails
        }
      }
    }

    return result
  } catch (error) {
    console.error('Deactivate assignment error:', error)
    return { success: false, error: error.message }
  }
}

async function handleGetStatus(supabaseClient: any, userId: string, request: AssignmentRequest) {
  if (!request.customer_id) {
    return { success: false, error: 'Missing customer_id' }
  }

  try {
    // Call the database function
    const { data, error } = await supabaseClient.rpc('get_customer_assignment_status', {
      p_customer_id: request.customer_id
    })

    if (error) {
      throw error
    }

    return { success: true, data: data[0] }
  } catch (error) {
    console.error('Get status error:', error)
    return { success: false, error: error.message }
  }
}
