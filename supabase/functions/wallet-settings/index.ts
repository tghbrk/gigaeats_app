import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface SettingsRequest {
  action: 'get' | 'update' | 'get_spending_limits' | 'update_spending_limits' | 'get_notifications' | 'update_notifications' | 'initialize'
  wallet_id: string
  settings?: any
  spending_limits?: any
  notification_preferences?: any
}

interface SettingsResponse {
  success: boolean
  data?: any
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
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get authenticated user
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Parse request body
    const requestData: SettingsRequest = await req.json()
    const { action, wallet_id } = requestData

    console.log(`🔍 [WALLET-SETTINGS] Processing ${action} for wallet: ${wallet_id}`)

    // Verify wallet ownership
    const { data: wallet, error: walletError } = await supabaseClient
      .from('stakeholder_wallets')
      .select('id, user_id')
      .eq('id', wallet_id)
      .eq('user_id', user.id)
      .single()

    if (walletError || !wallet) {
      return new Response(
        JSON.stringify({ success: false, error: 'Wallet not found or access denied' }),
        {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    let response: SettingsResponse

    switch (action) {
      case 'initialize':
        response = await initializeWalletSettings(supabaseClient, user.id, wallet_id)
        break
      case 'get':
        response = await getWalletSettings(supabaseClient, user.id, wallet_id)
        break
      case 'update':
        response = await updateWalletSettings(supabaseClient, user.id, wallet_id, requestData.settings)
        break
      case 'get_spending_limits':
        response = await getSpendingLimits(supabaseClient, user.id, wallet_id)
        break
      case 'update_spending_limits':
        response = await updateSpendingLimits(supabaseClient, user.id, wallet_id, requestData.spending_limits)
        break
      case 'get_notifications':
        response = await getNotificationPreferences(supabaseClient, user.id, wallet_id)
        break
      case 'update_notifications':
        response = await updateNotificationPreferences(supabaseClient, user.id, wallet_id, requestData.notification_preferences)
        break
      default:
        throw new Error(`Unknown action: ${action}`)
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('❌ [WALLET-SETTINGS] Error:', error)
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

async function initializeWalletSettings(
  supabaseClient: any,
  userId: string,
  walletId: string
): Promise<SettingsResponse> {
  try {
    console.log(`🔍 [WALLET-SETTINGS] Initializing settings for wallet: ${walletId}`)

    const { data: settingsId, error } = await supabaseClient
      .rpc('initialize_wallet_settings', {
        p_user_id: userId,
        p_wallet_id: walletId,
      })

    if (error) {
      throw new Error(`Failed to initialize settings: ${error.message}`)
    }

    console.log(`✅ [WALLET-SETTINGS] Initialized settings: ${settingsId}`)

    return {
      success: true,
      data: { settings_id: settingsId },
      message: 'Wallet settings initialized successfully',
    }
  } catch (error) {
    console.error('❌ [WALLET-SETTINGS] Initialize error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function getWalletSettings(
  supabaseClient: any,
  userId: string,
  walletId: string
): Promise<SettingsResponse> {
  try {
    console.log(`🔍 [WALLET-SETTINGS] Getting settings for wallet: ${walletId}`)

    const { data: settings, error } = await supabaseClient
      .from('wallet_settings')
      .select('*')
      .eq('user_id', userId)
      .eq('wallet_id', walletId)
      .single()

    if (error && error.code !== 'PGRST116') { // Not found error
      throw new Error(`Failed to get settings: ${error.message}`)
    }

    // If no settings found, initialize them
    if (!settings) {
      await initializeWalletSettings(supabaseClient, userId, walletId)
      
      const { data: newSettings, error: newError } = await supabaseClient
        .from('wallet_settings')
        .select('*')
        .eq('user_id', userId)
        .eq('wallet_id', walletId)
        .single()

      if (newError) {
        throw new Error(`Failed to get initialized settings: ${newError.message}`)
      }

      console.log(`✅ [WALLET-SETTINGS] Retrieved initialized settings`)
      return {
        success: true,
        data: newSettings,
      }
    }

    console.log(`✅ [WALLET-SETTINGS] Retrieved existing settings`)
    return {
      success: true,
      data: settings,
    }
  } catch (error) {
    console.error('❌ [WALLET-SETTINGS] Get settings error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function updateWalletSettings(
  supabaseClient: any,
  userId: string,
  walletId: string,
  settingsUpdate: any
): Promise<SettingsResponse> {
  try {
    console.log(`🔍 [WALLET-SETTINGS] Updating settings for wallet: ${walletId}`)

    // Validate settings update
    const validationError = validateSettingsUpdate(settingsUpdate)
    if (validationError) {
      throw new Error(validationError)
    }

    const { data: updatedSettings, error } = await supabaseClient
      .from('wallet_settings')
      .update(settingsUpdate)
      .eq('user_id', userId)
      .eq('wallet_id', walletId)
      .select()
      .single()

    if (error) {
      throw new Error(`Failed to update settings: ${error.message}`)
    }

    console.log(`✅ [WALLET-SETTINGS] Updated settings successfully`)

    return {
      success: true,
      data: updatedSettings,
      message: 'Settings updated successfully',
    }
  } catch (error) {
    console.error('❌ [WALLET-SETTINGS] Update settings error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function getSpendingLimits(
  supabaseClient: any,
  userId: string,
  walletId: string
): Promise<SettingsResponse> {
  try {
    console.log(`🔍 [WALLET-SETTINGS] Getting spending limits for wallet: ${walletId}`)

    const { data: limits, error } = await supabaseClient
      .from('spending_limits')
      .select('*')
      .eq('user_id', userId)
      .eq('wallet_id', walletId)
      .eq('is_active', true)
      .order('period')

    if (error) {
      throw new Error(`Failed to get spending limits: ${error.message}`)
    }

    console.log(`✅ [WALLET-SETTINGS] Retrieved ${limits?.length || 0} spending limits`)

    return {
      success: true,
      data: limits || [],
    }
  } catch (error) {
    console.error('❌ [WALLET-SETTINGS] Get spending limits error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function updateSpendingLimits(
  supabaseClient: any,
  userId: string,
  walletId: string,
  limitsUpdate: any[]
): Promise<SettingsResponse> {
  try {
    console.log(`🔍 [WALLET-SETTINGS] Updating spending limits for wallet: ${walletId}`)

    const updatedLimits = []

    for (const limit of limitsUpdate) {
      // Validate limit
      const validationError = validateSpendingLimit(limit)
      if (validationError) {
        throw new Error(validationError)
      }

      // Calculate period dates
      const periodDates = calculatePeriodDates(limit.period)
      
      const limitData = {
        user_id: userId,
        wallet_id: walletId,
        period: limit.period,
        limit_amount: limit.limit_amount,
        is_active: limit.is_active ?? true,
        current_period_start: periodDates.start,
        current_period_end: periodDates.end,
        current_period_spent: 0, // Reset when updating
        alert_at_percentage: limit.alert_at_percentage ?? 80,
        description: limit.description,
      }

      const { data: updatedLimit, error } = await supabaseClient
        .from('spending_limits')
        .upsert(limitData, {
          onConflict: 'user_id,wallet_id,period',
        })
        .select()
        .single()

      if (error) {
        throw new Error(`Failed to update ${limit.period} limit: ${error.message}`)
      }

      updatedLimits.push(updatedLimit)
    }

    console.log(`✅ [WALLET-SETTINGS] Updated ${updatedLimits.length} spending limits`)

    return {
      success: true,
      data: updatedLimits,
      message: 'Spending limits updated successfully',
    }
  } catch (error) {
    console.error('❌ [WALLET-SETTINGS] Update spending limits error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function getNotificationPreferences(
  supabaseClient: any,
  userId: string,
  walletId: string
): Promise<SettingsResponse> {
  try {
    console.log(`🔍 [WALLET-SETTINGS] Getting notification preferences for wallet: ${walletId}`)

    const { data: preferences, error } = await supabaseClient
      .from('wallet_notification_preferences')
      .select('*')
      .eq('user_id', userId)
      .eq('wallet_id', walletId)
      .order('notification_type, channel')

    if (error) {
      throw new Error(`Failed to get notification preferences: ${error.message}`)
    }

    console.log(`✅ [WALLET-SETTINGS] Retrieved ${preferences?.length || 0} notification preferences`)

    return {
      success: true,
      data: preferences || [],
    }
  } catch (error) {
    console.error('❌ [WALLET-SETTINGS] Get notification preferences error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function updateNotificationPreferences(
  supabaseClient: any,
  userId: string,
  walletId: string,
  preferencesUpdate: any[]
): Promise<SettingsResponse> {
  try {
    console.log(`🔍 [WALLET-SETTINGS] Updating notification preferences for wallet: ${walletId}`)

    const updatedPreferences = []

    for (const preference of preferencesUpdate) {
      const preferenceData = {
        user_id: userId,
        wallet_id: walletId,
        notification_type: preference.notification_type,
        channel: preference.channel,
        is_enabled: preference.is_enabled,
        quiet_hours_start: preference.quiet_hours_start,
        quiet_hours_end: preference.quiet_hours_end,
        timezone: preference.timezone ?? 'Asia/Kuala_Lumpur',
        max_daily_notifications: preference.max_daily_notifications,
        batch_notifications: preference.batch_notifications ?? false,
        batch_interval_minutes: preference.batch_interval_minutes,
      }

      const { data: updatedPreference, error } = await supabaseClient
        .from('wallet_notification_preferences')
        .upsert(preferenceData, {
          onConflict: 'user_id,wallet_id,notification_type,channel',
        })
        .select()
        .single()

      if (error) {
        throw new Error(`Failed to update ${preference.notification_type} preference: ${error.message}`)
      }

      updatedPreferences.push(updatedPreference)
    }

    console.log(`✅ [WALLET-SETTINGS] Updated ${updatedPreferences.length} notification preferences`)

    return {
      success: true,
      data: updatedPreferences,
      message: 'Notification preferences updated successfully',
    }
  } catch (error) {
    console.error('❌ [WALLET-SETTINGS] Update notification preferences error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

function validateSettingsUpdate(settings: any): string | null {
  if (settings.auto_reload_threshold && settings.auto_reload_amount) {
    if (settings.auto_reload_amount <= settings.auto_reload_threshold) {
      return 'Auto-reload amount must be greater than threshold'
    }
  }

  if (settings.large_amount_threshold && settings.large_amount_threshold <= 0) {
    return 'Large amount threshold must be positive'
  }

  if (settings.auto_lock_timeout_minutes && settings.auto_lock_timeout_minutes <= 0) {
    return 'Auto-lock timeout must be positive'
  }

  if (settings.transaction_history_limit) {
    if (settings.transaction_history_limit <= 0 || settings.transaction_history_limit > 100) {
      return 'Transaction history limit must be between 1 and 100'
    }
  }

  return null
}

function validateSpendingLimit(limit: any): string | null {
  if (!limit.period || !['daily', 'weekly', 'monthly'].includes(limit.period)) {
    return 'Invalid spending limit period'
  }

  if (!limit.limit_amount || limit.limit_amount <= 0) {
    return 'Spending limit amount must be positive'
  }

  if (limit.alert_at_percentage && (limit.alert_at_percentage <= 0 || limit.alert_at_percentage > 100)) {
    return 'Alert percentage must be between 1 and 100'
  }

  return null
}

function calculatePeriodDates(period: string): { start: string; end: string } {
  const now = new Date()
  let start: Date
  let end: Date

  switch (period) {
    case 'daily':
      start = new Date(now.getFullYear(), now.getMonth(), now.getDate())
      end = new Date(start.getTime() + 24 * 60 * 60 * 1000 - 1)
      break
    case 'weekly':
      const dayOfWeek = now.getDay()
      start = new Date(now.getTime() - dayOfWeek * 24 * 60 * 60 * 1000)
      start = new Date(start.getFullYear(), start.getMonth(), start.getDate())
      end = new Date(start.getTime() + 7 * 24 * 60 * 60 * 1000 - 1)
      break
    case 'monthly':
      start = new Date(now.getFullYear(), now.getMonth(), 1)
      end = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999)
      break
    default:
      throw new Error(`Invalid period: ${period}`)
  }

  return {
    start: start.toISOString(),
    end: end.toISOString(),
  }
}
