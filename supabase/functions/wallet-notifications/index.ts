import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface WalletNotificationRequest {
  action: 'send_transaction_notification' | 'send_balance_alert' | 'send_security_alert' | 
          'send_promotional_notification' | 'get_notification_preferences' | 'update_preferences'
  user_id?: string
  notification_data?: {
    type: string
    title: string
    message: string
    transaction_id?: string
    wallet_id?: string
    amount?: number
    metadata?: Record<string, any>
  }
  preferences?: {
    transaction_notifications: boolean
    balance_alerts: boolean
    security_alerts: boolean
    promotional_notifications: boolean
    push_notifications: boolean
    email_notifications: boolean
    sms_notifications: boolean
  }
}

interface NotificationResult {
  success: boolean
  notification_id?: string
  sent_channels?: string[]
  error?: string
  message?: string
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

    // Get user from JWT token
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)

    if (authError || !user) {
      throw new Error('Unauthorized: Invalid or missing authentication token')
    }

    const requestBody: WalletNotificationRequest = await req.json()
    const { action } = requestBody

    let response: NotificationResult

    switch (action) {
      case 'send_transaction_notification':
        response = await sendTransactionNotification(supabaseClient, user.id, requestBody)
        break
      case 'send_balance_alert':
        response = await sendBalanceAlert(supabaseClient, user.id, requestBody)
        break
      case 'send_security_alert':
        response = await sendSecurityAlert(supabaseClient, user.id, requestBody)
        break
      case 'send_promotional_notification':
        response = await sendPromotionalNotification(supabaseClient, user.id, requestBody)
        break
      case 'get_notification_preferences':
        response = await getNotificationPreferences(supabaseClient, user.id)
        break
      case 'update_preferences':
        response = await updateNotificationPreferences(supabaseClient, user.id, requestBody)
        break
      default:
        throw new Error(`Unsupported action: ${action}`)
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    console.error('Wallet notification error:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})

async function sendTransactionNotification(
  supabase: any,
  userId: string,
  request: WalletNotificationRequest
): Promise<NotificationResult> {
  try {
    const { notification_data } = request

    if (!notification_data) {
      throw new Error('notification_data is required for transaction notifications')
    }

    // Get user notification preferences
    const preferences = await getUserNotificationPreferences(supabase, userId)
    
    if (!preferences.transaction_notifications) {
      return {
        success: true,
        message: 'Transaction notifications disabled for user'
      }
    }

    // Create notification record
    const { data: notification, error: notificationError } = await supabase
      .from('notifications')
      .insert({
        user_id: userId,
        title: notification_data.title,
        message: notification_data.message,
        type: notification_data.type,
        data: {
          transaction_id: notification_data.transaction_id,
          wallet_id: notification_data.wallet_id,
          amount: notification_data.amount,
          ...notification_data.metadata
        },
        is_read: false,
        created_at: new Date().toISOString()
      })
      .select()
      .single()

    if (notificationError) {
      throw new Error(`Failed to create notification: ${notificationError.message}`)
    }

    const sentChannels: string[] = []

    // Send push notification if enabled
    if (preferences.push_notifications) {
      const pushResult = await sendPushNotification(supabase, userId, notification_data)
      if (pushResult.success) {
        sentChannels.push('push')
      }
    }

    // Send email notification if enabled
    if (preferences.email_notifications) {
      const emailResult = await sendEmailNotification(supabase, userId, notification_data)
      if (emailResult.success) {
        sentChannels.push('email')
      }
    }

    return {
      success: true,
      notification_id: notification.id,
      sent_channels: sentChannels,
      message: 'Transaction notification sent successfully'
    }

  } catch (error) {
    console.error('Send transaction notification error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

async function sendBalanceAlert(
  supabase: any,
  userId: string,
  request: WalletNotificationRequest
): Promise<NotificationResult> {
  try {
    const { notification_data } = request

    if (!notification_data) {
      throw new Error('notification_data is required for balance alerts')
    }

    // Get user notification preferences
    const preferences = await getUserNotificationPreferences(supabase, userId)
    
    if (!preferences.balance_alerts) {
      return {
        success: true,
        message: 'Balance alerts disabled for user'
      }
    }

    // Create high-priority notification for balance alerts
    const { data: notification, error: notificationError } = await supabase
      .from('notifications')
      .insert({
        user_id: userId,
        title: notification_data.title,
        message: notification_data.message,
        type: 'balance_alert',
        priority: 'high',
        data: {
          wallet_id: notification_data.wallet_id,
          current_balance: notification_data.amount,
          alert_type: notification_data.metadata?.alert_type || 'low_balance',
          ...notification_data.metadata
        },
        is_read: false,
        created_at: new Date().toISOString()
      })
      .select()
      .single()

    if (notificationError) {
      throw new Error(`Failed to create balance alert: ${notificationError.message}`)
    }

    const sentChannels: string[] = []

    // Always send push notification for balance alerts
    if (preferences.push_notifications) {
      const pushResult = await sendPushNotification(supabase, userId, {
        ...notification_data,
        title: `⚠️ ${notification_data.title}`,
        type: 'balance_alert'
      })
      if (pushResult.success) {
        sentChannels.push('push')
      }
    }

    // Send email for critical balance alerts
    if (preferences.email_notifications && notification_data.metadata?.alert_type === 'critical_low') {
      const emailResult = await sendEmailNotification(supabase, userId, notification_data)
      if (emailResult.success) {
        sentChannels.push('email')
      }
    }

    return {
      success: true,
      notification_id: notification.id,
      sent_channels: sentChannels,
      message: 'Balance alert sent successfully'
    }

  } catch (error) {
    console.error('Send balance alert error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

async function sendSecurityAlert(
  supabase: any,
  userId: string,
  request: WalletNotificationRequest
): Promise<NotificationResult> {
  try {
    const { notification_data } = request

    if (!notification_data) {
      throw new Error('notification_data is required for security alerts')
    }

    // Security alerts are always sent regardless of preferences
    const { data: notification, error: notificationError } = await supabase
      .from('notifications')
      .insert({
        user_id: userId,
        title: notification_data.title,
        message: notification_data.message,
        type: 'security_alert',
        priority: 'critical',
        data: {
          security_event: notification_data.metadata?.security_event,
          ip_address: notification_data.metadata?.ip_address,
          user_agent: notification_data.metadata?.user_agent,
          timestamp: new Date().toISOString(),
          ...notification_data.metadata
        },
        is_read: false,
        created_at: new Date().toISOString()
      })
      .select()
      .single()

    if (notificationError) {
      throw new Error(`Failed to create security alert: ${notificationError.message}`)
    }

    const sentChannels: string[] = []

    // Always send push notification for security alerts
    const pushResult = await sendPushNotification(supabase, userId, {
      ...notification_data,
      title: `🔒 ${notification_data.title}`,
      type: 'security_alert'
    })
    if (pushResult.success) {
      sentChannels.push('push')
    }

    // Always send email for security alerts
    const emailResult = await sendEmailNotification(supabase, userId, notification_data)
    if (emailResult.success) {
      sentChannels.push('email')
    }

    return {
      success: true,
      notification_id: notification.id,
      sent_channels: sentChannels,
      message: 'Security alert sent successfully'
    }

  } catch (error) {
    console.error('Send security alert error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

async function getUserNotificationPreferences(supabase: any, userId: string): Promise<any> {
  const { data: preferences, error } = await supabase
    .from('user_notification_preferences')
    .select('*')
    .eq('user_id', userId)
    .single()

  if (error || !preferences) {
    // Return default preferences if none found
    return {
      transaction_notifications: true,
      balance_alerts: true,
      security_alerts: true,
      promotional_notifications: true,
      push_notifications: true,
      email_notifications: true,
      sms_notifications: false
    }
  }

  return preferences
}

async function sendPushNotification(supabase: any, userId: string, notificationData: any): Promise<{ success: boolean }> {
  try {
    // Call the existing send-notification function
    const { error } = await supabase.functions.invoke('send-notification', {
      body: {
        recipient_id: userId,
        title: notificationData.title,
        message: notificationData.message,
        notification_type: notificationData.type,
        data: notificationData.metadata
      }
    })

    return { success: !error }
  } catch (error) {
    console.error('Push notification error:', error)
    return { success: false }
  }
}

async function sendEmailNotification(supabase: any, userId: string, notificationData: any): Promise<{ success: boolean }> {
  try {
    // Get user email
    const { data: user, error: userError } = await supabase.auth.admin.getUserById(userId)
    
    if (userError || !user?.email) {
      return { success: false }
    }

    // TODO: Implement email sending logic
    // This would typically integrate with an email service like SendGrid, AWS SES, etc.
    console.log(`Email notification would be sent to ${user.email}:`, notificationData)
    
    return { success: true }
  } catch (error) {
    console.error('Email notification error:', error)
    return { success: false }
  }
}

async function sendPromotionalNotification(supabase: any, userId: string, request: WalletNotificationRequest): Promise<NotificationResult> {
  // Implementation for promotional notifications
  return { success: true, message: 'Promotional notification feature coming soon' }
}

async function getNotificationPreferences(supabase: any, userId: string): Promise<NotificationResult> {
  try {
    const preferences = await getUserNotificationPreferences(supabase, userId)
    return {
      success: true,
      ...preferences
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}

async function updateNotificationPreferences(supabase: any, userId: string, request: WalletNotificationRequest): Promise<NotificationResult> {
  try {
    const { preferences } = request

    if (!preferences) {
      throw new Error('preferences are required for update')
    }

    const { error } = await supabase
      .from('user_notification_preferences')
      .upsert({
        user_id: userId,
        ...preferences,
        updated_at: new Date().toISOString()
      })

    if (error) {
      throw new Error(`Failed to update preferences: ${error.message}`)
    }

    return {
      success: true,
      message: 'Notification preferences updated successfully'
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}
