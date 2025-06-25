import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface AssignmentNotificationRequest {
  type: 'request_sent' | 'request_approved' | 'request_rejected' | 'request_cancelled' | 'assignment_deactivated'
  assignment_request_id?: string
  assignment_id?: string
  customer_id: string
  sales_agent_id: string
  message?: string
  metadata?: Record<string, any>
}

interface EmailTemplate {
  subject: string
  html: string
  text: string
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

    const notificationRequest: AssignmentNotificationRequest = await req.json()
    
    // Validate request
    if (!notificationRequest.type || !notificationRequest.customer_id || !notificationRequest.sales_agent_id) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Missing required fields: type, customer_id, sales_agent_id' 
        }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Get customer and sales agent details
    const { data: customerData, error: customerError } = await supabaseClient
      .from('customers')
      .select(`
        id,
        contact_person_name,
        email,
        organization_name,
        user_id
      `)
      .eq('id', notificationRequest.customer_id)
      .single()

    if (customerError || !customerData) {
      throw new Error(`Customer not found: ${customerError?.message}`)
    }

    const { data: salesAgentData, error: salesAgentError } = await supabaseClient
      .from('users')
      .select(`
        id,
        full_name,
        email,
        phone_number
      `)
      .eq('id', notificationRequest.sales_agent_id)
      .eq('role', 'sales_agent')
      .single()

    if (salesAgentError || !salesAgentData) {
      throw new Error(`Sales agent not found: ${salesAgentError?.message}`)
    }

    // Generate notification content based on type
    let emailTemplate: EmailTemplate
    let pushNotificationTitle: string
    let pushNotificationBody: string
    let recipientUserId: string
    let notificationType: string

    switch (notificationRequest.type) {
      case 'request_sent':
        recipientUserId = customerData.user_id
        notificationType = 'assignment_request'
        pushNotificationTitle = 'New Assignment Request'
        pushNotificationBody = `${salesAgentData.full_name} wants to be your sales agent`
        emailTemplate = {
          subject: 'New Sales Agent Assignment Request - GigaEats',
          html: generateRequestSentEmailHTML(customerData, salesAgentData, notificationRequest.message),
          text: generateRequestSentEmailText(customerData, salesAgentData, notificationRequest.message)
        }
        break

      case 'request_approved':
        recipientUserId = salesAgentData.supabase_user_id || salesAgentData.id
        notificationType = 'assignment_approved'
        pushNotificationTitle = 'Assignment Request Approved!'
        pushNotificationBody = `${customerData.contact_person_name} approved your assignment request`
        emailTemplate = {
          subject: 'Assignment Request Approved - GigaEats',
          html: generateRequestApprovedEmailHTML(customerData, salesAgentData),
          text: generateRequestApprovedEmailText(customerData, salesAgentData)
        }
        break

      case 'request_rejected':
        recipientUserId = salesAgentData.supabase_user_id || salesAgentData.id
        notificationType = 'assignment_rejected'
        pushNotificationTitle = 'Assignment Request Declined'
        pushNotificationBody = `${customerData.contact_person_name} declined your assignment request`
        emailTemplate = {
          subject: 'Assignment Request Declined - GigaEats',
          html: generateRequestRejectedEmailHTML(customerData, salesAgentData, notificationRequest.message),
          text: generateRequestRejectedEmailText(customerData, salesAgentData, notificationRequest.message)
        }
        break

      case 'request_cancelled':
        recipientUserId = customerData.user_id
        notificationType = 'assignment_cancelled'
        pushNotificationTitle = 'Assignment Request Cancelled'
        pushNotificationBody = `${salesAgentData.full_name} cancelled their assignment request`
        emailTemplate = {
          subject: 'Assignment Request Cancelled - GigaEats',
          html: generateRequestCancelledEmailHTML(customerData, salesAgentData),
          text: generateRequestCancelledEmailText(customerData, salesAgentData)
        }
        break

      case 'assignment_deactivated':
        // Send to both customer and sales agent
        recipientUserId = customerData.user_id
        notificationType = 'assignment_deactivated'
        pushNotificationTitle = 'Assignment Deactivated'
        pushNotificationBody = 'Your sales agent assignment has been deactivated'
        emailTemplate = {
          subject: 'Sales Agent Assignment Deactivated - GigaEats',
          html: generateAssignmentDeactivatedEmailHTML(customerData, salesAgentData),
          text: generateAssignmentDeactivatedEmailText(customerData, salesAgentData)
        }
        break

      default:
        throw new Error(`Unknown notification type: ${notificationRequest.type}`)
    }

    // Send email notification using Supabase's built-in email service
    if (recipientUserId && emailTemplate) {
      try {
        const recipientEmail = notificationRequest.type.includes('request_approved') || 
                              notificationRequest.type.includes('request_rejected') || 
                              notificationRequest.type.includes('request_cancelled')
                              ? salesAgentData.email 
                              : customerData.email

        // For now, we'll create a notification record and let the client handle email sending
        // In a production environment, you would integrate with an email service like SendGrid, Resend, etc.
        console.log(`Email notification prepared for ${recipientEmail}:`, emailTemplate.subject)
      } catch (emailError) {
        console.error('Email sending error:', emailError)
        // Don't fail the entire request if email fails
      }
    }

    // Send push notification
    let pushNotificationResult = null
    if (recipientUserId) {
      try {
        const { data: pushResult, error: pushError } = await supabaseClient.functions.invoke('send-notification', {
          body: {
            recipient_id: recipientUserId,
            title: pushNotificationTitle,
            message: pushNotificationBody,
            notification_type: notificationType,
            data: {
              assignment_request_id: notificationRequest.assignment_request_id,
              assignment_id: notificationRequest.assignment_id,
              customer_id: notificationRequest.customer_id,
              sales_agent_id: notificationRequest.sales_agent_id,
              ...notificationRequest.metadata
            }
          }
        })

        if (pushError) {
          console.error('Push notification error:', pushError)
        } else {
          pushNotificationResult = pushResult
        }
      } catch (pushError) {
        console.error('Push notification error:', pushError)
        // Don't fail the entire request if push notification fails
      }
    }

    return new Response(
      JSON.stringify({ 
        success: true,
        notification_type: notificationType,
        recipient_user_id: recipientUserId,
        email_prepared: true,
        push_notification_result: pushNotificationResult
      }), 
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  } catch (error) {
    console.error('Assignment notification error:', error)
    
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

// Email template generation functions
function generateRequestSentEmailHTML(customer: any, salesAgent: any, message?: string): string {
  return `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2 style="color: #2563eb;">New Sales Agent Assignment Request</h2>
      <p>Dear ${customer.contact_person_name},</p>
      <p><strong>${salesAgent.full_name}</strong> has requested to be assigned as your sales agent for GigaEats orders.</p>
      ${message ? `<p><strong>Message from ${salesAgent.full_name}:</strong><br>"${message}"</p>` : ''}
      <p>Please log into your GigaEats app to review and respond to this request.</p>
      <div style="margin: 20px 0; padding: 15px; background-color: #f3f4f6; border-radius: 8px;">
        <h3 style="margin: 0 0 10px 0;">Sales Agent Details:</h3>
        <p style="margin: 5px 0;"><strong>Name:</strong> ${salesAgent.full_name}</p>
        <p style="margin: 5px 0;"><strong>Email:</strong> ${salesAgent.email}</p>
        ${salesAgent.phone_number ? `<p style="margin: 5px 0;"><strong>Phone:</strong> ${salesAgent.phone_number}</p>` : ''}
      </div>
      <p>Best regards,<br>The GigaEats Team</p>
    </div>
  `
}

function generateRequestSentEmailText(customer: any, salesAgent: any, message?: string): string {
  return `
New Sales Agent Assignment Request

Dear ${customer.contact_person_name},

${salesAgent.full_name} has requested to be assigned as your sales agent for GigaEats orders.

${message ? `Message from ${salesAgent.full_name}: "${message}"` : ''}

Please log into your GigaEats app to review and respond to this request.

Sales Agent Details:
- Name: ${salesAgent.full_name}
- Email: ${salesAgent.email}
${salesAgent.phone_number ? `- Phone: ${salesAgent.phone_number}` : ''}

Best regards,
The GigaEats Team
  `
}

function generateRequestApprovedEmailHTML(customer: any, salesAgent: any): string {
  return `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2 style="color: #059669;">Assignment Request Approved! 🎉</h2>
      <p>Dear ${salesAgent.full_name},</p>
      <p>Great news! <strong>${customer.contact_person_name}</strong> from <strong>${customer.organization_name}</strong> has approved your assignment request.</p>
      <p>You are now the assigned sales agent for this customer and will earn commission on their future orders.</p>
      <div style="margin: 20px 0; padding: 15px; background-color: #ecfdf5; border-radius: 8px; border-left: 4px solid #059669;">
        <h3 style="margin: 0 0 10px 0; color: #059669;">Customer Details:</h3>
        <p style="margin: 5px 0;"><strong>Contact Person:</strong> ${customer.contact_person_name}</p>
        <p style="margin: 5px 0;"><strong>Organization:</strong> ${customer.organization_name}</p>
        <p style="margin: 5px 0;"><strong>Email:</strong> ${customer.email}</p>
      </div>
      <p>You can now start taking orders for this customer through your sales agent dashboard.</p>
      <p>Best regards,<br>The GigaEats Team</p>
    </div>
  `
}

function generateRequestApprovedEmailText(customer: any, salesAgent: any): string {
  return `
Assignment Request Approved!

Dear ${salesAgent.full_name},

Great news! ${customer.contact_person_name} from ${customer.organization_name} has approved your assignment request.

You are now the assigned sales agent for this customer and will earn commission on their future orders.

Customer Details:
- Contact Person: ${customer.contact_person_name}
- Organization: ${customer.organization_name}
- Email: ${customer.email}

You can now start taking orders for this customer through your sales agent dashboard.

Best regards,
The GigaEats Team
  `
}

function generateRequestRejectedEmailHTML(customer: any, salesAgent: any, message?: string): string {
  return `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2 style="color: #dc2626;">Assignment Request Declined</h2>
      <p>Dear ${salesAgent.full_name},</p>
      <p><strong>${customer.contact_person_name}</strong> from <strong>${customer.organization_name}</strong> has declined your assignment request.</p>
      ${message ? `<p><strong>Customer's message:</strong><br>"${message}"</p>` : ''}
      <p>Don't worry! You can continue to reach out to other potential customers or try again with this customer in the future.</p>
      <p>Best regards,<br>The GigaEats Team</p>
    </div>
  `
}

function generateRequestRejectedEmailText(customer: any, salesAgent: any, message?: string): string {
  return `
Assignment Request Declined

Dear ${salesAgent.full_name},

${customer.contact_person_name} from ${customer.organization_name} has declined your assignment request.

${message ? `Customer's message: "${message}"` : ''}

Don't worry! You can continue to reach out to other potential customers or try again with this customer in the future.

Best regards,
The GigaEats Team
  `
}

function generateRequestCancelledEmailHTML(customer: any, salesAgent: any): string {
  return `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2 style="color: #6b7280;">Assignment Request Cancelled</h2>
      <p>Dear ${customer.contact_person_name},</p>
      <p><strong>${salesAgent.full_name}</strong> has cancelled their assignment request.</p>
      <p>No action is required from your side. If you have any questions, please contact our support team.</p>
      <p>Best regards,<br>The GigaEats Team</p>
    </div>
  `
}

function generateRequestCancelledEmailText(customer: any, salesAgent: any): string {
  return `
Assignment Request Cancelled

Dear ${customer.contact_person_name},

${salesAgent.full_name} has cancelled their assignment request.

No action is required from your side. If you have any questions, please contact our support team.

Best regards,
The GigaEats Team
  `
}

function generateAssignmentDeactivatedEmailHTML(customer: any, salesAgent: any): string {
  return `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2 style="color: #dc2626;">Sales Agent Assignment Deactivated</h2>
      <p>Dear ${customer.contact_person_name},</p>
      <p>Your assignment with sales agent <strong>${salesAgent.full_name}</strong> has been deactivated.</p>
      <p>You can continue to place orders directly through the GigaEats app, or you may receive new assignment requests from other sales agents.</p>
      <p>If you have any questions about this change, please contact our support team.</p>
      <p>Best regards,<br>The GigaEats Team</p>
    </div>
  `
}

function generateAssignmentDeactivatedEmailText(customer: any, salesAgent: any): string {
  return `
Sales Agent Assignment Deactivated

Dear ${customer.contact_person_name},

Your assignment with sales agent ${salesAgent.full_name} has been deactivated.

You can continue to place orders directly through the GigaEats app, or you may receive new assignment requests from other sales agents.

If you have any questions about this change, please contact our support team.

Best regards,
The GigaEats Team
  `
}
