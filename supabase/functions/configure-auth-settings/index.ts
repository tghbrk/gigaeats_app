// Supabase Edge Function: Configure Authentication Settings
// Purpose: Configure Supabase auth settings, email templates, and deep link handling
// Phase: 3 - Backend Configuration

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface AuthConfigRequest {
  action: 'configure_email_templates' | 'configure_auth_settings' | 'configure_deep_links' | 'get_current_config'
  templates?: {
    confirmation?: EmailTemplate
    recovery?: EmailTemplate
    magic_link?: EmailTemplate
  }
  settings?: AuthSettings
  deep_links?: DeepLinkConfig
}

interface EmailTemplate {
  subject: string
  content: string
}

interface AuthSettings {
  site_url?: string
  jwt_expiry?: number
  refresh_token_expiry?: number
  enable_signup?: boolean
  enable_confirmations?: boolean
  double_confirm_changes?: boolean
  secure_password_change?: boolean
  max_frequency?: string
  otp_expiry?: number
  password_min_length?: number
}

interface DeepLinkConfig {
  redirect_urls: string[]
  site_url: string
}

serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
  }

  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify request method
    if (req.method !== 'POST' && req.method !== 'GET') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { 
          status: 405, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Create Supabase admin client
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Handle GET request - return current configuration
    if (req.method === 'GET') {
      return await getCurrentConfig(supabaseAdmin, corsHeaders)
    }

    // Handle POST request - configure settings
    const requestBody: AuthConfigRequest = await req.json()
    
    switch (requestBody.action) {
      case 'configure_email_templates':
        return await configureEmailTemplates(supabaseAdmin, requestBody.templates, corsHeaders)
      
      case 'configure_auth_settings':
        return await configureAuthSettings(supabaseAdmin, requestBody.settings, corsHeaders)
      
      case 'configure_deep_links':
        return await configureDeepLinks(supabaseAdmin, requestBody.deep_links, corsHeaders)
      
      case 'get_current_config':
        return await getCurrentConfig(supabaseAdmin, corsHeaders)
      
      default:
        return new Response(
          JSON.stringify({ error: 'Invalid action specified' }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          }
        )
    }

  } catch (error) {
    console.error('Error in configure-auth-settings function:', error)
    
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        details: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

async function getCurrentConfig(supabaseAdmin: any, corsHeaders: Record<string, string>) {
  try {
    // Note: Supabase doesn't provide a direct API to get current auth config
    // This function returns the expected configuration structure
    const currentConfig = {
      message: 'Current auth configuration (expected values)',
      auth_settings: {
        site_url: 'gigaeats://auth/callback',
        enable_signup: true,
        enable_confirmations: true,
        double_confirm_changes: true,
        secure_password_change: false,
        max_frequency: '1s',
        otp_expiry: 3600,
        jwt_expiry: 3600,
        refresh_token_expiry: 604800,
        password_min_length: 8
      },
      redirect_urls: [
        'gigaeats://auth/callback',
        'https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/callback',
        'http://localhost:3000/auth/callback',
        'https://localhost:3000/auth/callback'
      ],
      email_templates: {
        confirmation: {
          subject: 'Welcome to GigaEats - Verify Your Email',
          configured: true
        },
        recovery: {
          subject: 'Reset Your GigaEats Password',
          configured: true
        },
        magic_link: {
          subject: 'Your GigaEats Magic Link',
          configured: true
        }
      }
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        data: currentConfig 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ 
        error: 'Failed to get current configuration',
        details: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
}

async function configureEmailTemplates(
  supabaseAdmin: any, 
  templates: any, 
  corsHeaders: Record<string, string>
) {
  try {
    console.log('Configuring email templates:', templates)

    // Configure email templates using Supabase Admin API
    const updates: any = {}

    if (templates?.confirmation) {
      updates.MAILER_TEMPLATES_CONFIRMATION_SUBJECT = templates.confirmation.subject
      updates.MAILER_TEMPLATES_CONFIRMATION_CONTENT = templates.confirmation.content
    }

    if (templates?.recovery) {
      updates.MAILER_TEMPLATES_RECOVERY_SUBJECT = templates.recovery.subject
      updates.MAILER_TEMPLATES_RECOVERY_CONTENT = templates.recovery.content
    }

    if (templates?.magic_link) {
      updates.MAILER_TEMPLATES_MAGIC_LINK_SUBJECT = templates.magic_link.subject
      updates.MAILER_TEMPLATES_MAGIC_LINK_CONTENT = templates.magic_link.content
    }

    // Apply configuration updates
    const { data, error } = await supabaseAdmin.auth.admin.updateSettings(updates)

    if (error) {
      throw new Error(`Failed to update email templates: ${error.message}`)
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Email templates configured successfully',
        data: data 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ 
        error: 'Failed to configure email templates',
        details: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
}

async function configureAuthSettings(
  supabaseAdmin: any, 
  settings: any, 
  corsHeaders: Record<string, string>
) {
  try {
    console.log('Configuring auth settings:', settings)

    // Configure authentication settings
    const updates: any = {}

    if (settings?.site_url) {
      updates.SITE_URL = settings.site_url
    }

    if (settings?.jwt_expiry) {
      updates.JWT_EXPIRY = settings.jwt_expiry
    }

    if (settings?.refresh_token_expiry) {
      updates.REFRESH_TOKEN_EXPIRY = settings.refresh_token_expiry
    }

    if (settings?.enable_signup !== undefined) {
      updates.ENABLE_SIGNUP = settings.enable_signup
    }

    if (settings?.enable_confirmations !== undefined) {
      updates.ENABLE_CONFIRMATIONS = settings.enable_confirmations
    }

    if (settings?.double_confirm_changes !== undefined) {
      updates.DOUBLE_CONFIRM_CHANGES = settings.double_confirm_changes
    }

    if (settings?.secure_password_change !== undefined) {
      updates.SECURE_PASSWORD_CHANGE = settings.secure_password_change
    }

    if (settings?.max_frequency) {
      updates.MAX_FREQUENCY = settings.max_frequency
    }

    if (settings?.otp_expiry) {
      updates.OTP_EXPIRY = settings.otp_expiry
    }

    if (settings?.password_min_length) {
      updates.PASSWORD_MIN_LENGTH = settings.password_min_length
    }

    // Apply configuration updates
    const { data, error } = await supabaseAdmin.auth.admin.updateSettings(updates)

    if (error) {
      throw new Error(`Failed to update auth settings: ${error.message}`)
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Auth settings configured successfully',
        data: data 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ 
        error: 'Failed to configure auth settings',
        details: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
}

async function configureDeepLinks(
  supabaseAdmin: any, 
  deepLinks: any, 
  corsHeaders: Record<string, string>
) {
  try {
    console.log('Configuring deep links:', deepLinks)

    const updates: any = {}

    if (deepLinks?.site_url) {
      updates.SITE_URL = deepLinks.site_url
    }

    if (deepLinks?.redirect_urls && Array.isArray(deepLinks.redirect_urls)) {
      updates.URI_ALLOW_LIST = deepLinks.redirect_urls.join(',')
    }

    // Apply configuration updates
    const { data, error } = await supabaseAdmin.auth.admin.updateSettings(updates)

    if (error) {
      throw new Error(`Failed to update deep link settings: ${error.message}`)
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Deep link settings configured successfully',
        data: data 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ 
        error: 'Failed to configure deep link settings',
        details: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
}
