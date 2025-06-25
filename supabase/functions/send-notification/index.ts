import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationRequest {
  recipient_id: string
  title: string
  message: string
  notification_type: string
  order_id?: string
  data?: Record<string, any>
}

interface FCMMessage {
  to?: string
  registration_ids?: string[]
  notification: {
    title: string
    body: string
    icon?: string
    click_action?: string
  }
  data?: Record<string, any>
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

    const notificationRequest: NotificationRequest = await req.json()
    
    // Validate request
    if (!notificationRequest.recipient_id || !notificationRequest.title || !notificationRequest.message) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Missing required fields: recipient_id, title, message' 
        }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Create notification record in database
    const { data: notification, error: notificationError } = await supabaseClient
      .from('order_notifications')
      .insert({
        recipient_id: notificationRequest.recipient_id,
        title: notificationRequest.title,
        message: notificationRequest.message,
        notification_type: notificationRequest.notification_type,
        order_id: notificationRequest.order_id,
        metadata: notificationRequest.data || {},
        sent_at: new Date().toISOString(),
        is_read: false
      })
      .select()
      .single()

    if (notificationError) {
      throw new Error(`Failed to create notification: ${notificationError.message}`)
    }

    // Get FCM tokens for the recipient
    const { data: fcmTokens, error: tokenError } = await supabaseClient
      .from('user_fcm_tokens')
      .select('id, fcm_token, device_type')
      .eq('user_id', notificationRequest.recipient_id)
      .eq('is_active', true)

    if (tokenError) {
      console.error('Error fetching FCM tokens:', tokenError)
    }

    let deliveryResults = []

    if (fcmTokens && fcmTokens.length > 0) {
      // Send FCM notifications
      const fcmServerKey = Deno.env.get('FCM_SERVER_KEY')
      
      if (fcmServerKey) {
        for (const tokenRecord of fcmTokens) {
          try {
            const fcmMessage: FCMMessage = {
              to: tokenRecord.fcm_token,
              notification: {
                title: notificationRequest.title,
                body: notificationRequest.message,
                icon: '/icons/icon-192x192.png',
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
              },
              data: {
                notification_id: notification.id,
                order_id: notificationRequest.order_id || '',
                type: notificationRequest.notification_type,
                ...notificationRequest.data
              }
            }

            const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
              method: 'POST',
              headers: {
                'Authorization': `key=${fcmServerKey}`,
                'Content-Type': 'application/json',
              },
              body: JSON.stringify(fcmMessage)
            })

            const fcmResult = await fcmResponse.json()
            
            // Record delivery attempt
            const deliveryStatus = fcmResult.success === 1 ? 'sent' : 'failed'
            const errorMessage = fcmResult.results?.[0]?.error || null

            await supabaseClient
              .from('notification_deliveries')
              .insert({
                notification_id: notification.id,
                fcm_token_id: tokenRecord.id,
                fcm_token: tokenRecord.fcm_token,
                delivery_status: deliveryStatus,
                error_message: errorMessage,
                response_data: fcmResult,
                sent_at: deliveryStatus === 'sent' ? new Date().toISOString() : null
              })

            deliveryResults.push({
              token_id: tokenRecord.id,
              device_type: tokenRecord.device_type,
              status: deliveryStatus,
              error: errorMessage
            })

            // Update token last used timestamp if successful
            if (deliveryStatus === 'sent') {
              await supabaseClient
                .from('user_fcm_tokens')
                .update({ last_used_at: new Date().toISOString() })
                .eq('id', tokenRecord.id)
            }

          } catch (error) {
            console.error(`Error sending FCM to token ${tokenRecord.id}:`, error)
            
            // Record failed delivery
            await supabaseClient
              .from('notification_deliveries')
              .insert({
                notification_id: notification.id,
                fcm_token_id: tokenRecord.id,
                fcm_token: tokenRecord.fcm_token,
                delivery_status: 'failed',
                error_message: error.message
              })

            deliveryResults.push({
              token_id: tokenRecord.id,
              device_type: tokenRecord.device_type,
              status: 'failed',
              error: error.message
            })
          }
        }
      } else {
        console.warn('FCM_SERVER_KEY not configured, skipping push notifications')
      }
    }

    return new Response(
      JSON.stringify({ 
        success: true,
        notification_id: notification.id,
        delivery_results: deliveryResults,
        tokens_found: fcmTokens?.length || 0
      }), 
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  } catch (error) {
    console.error('Notification sending error:', error)
    
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
