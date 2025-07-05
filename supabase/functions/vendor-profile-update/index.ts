import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface VendorProfileUpdateRequest {
  business_name?: string
  business_registration_number?: string
  business_address?: string
  business_type?: string
  cuisine_types?: string[]
  is_halal_certified?: boolean
  halal_certification_number?: string
  description?: string
  cover_image_url?: string
  gallery_images?: string[]
  business_hours?: Record<string, any>
  service_areas?: string[]
  minimum_order_amount?: number
  delivery_fee?: number
  free_delivery_threshold?: number
}

interface VendorProfileUpdateResponse {
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
    // Initialize Supabase client with user context
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
      console.error('❌ [VENDOR-PROFILE-UPDATE] Authentication error:', userError)
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Parse request body
    const updateData: VendorProfileUpdateRequest = await req.json()

    console.log(`🔍 [VENDOR-PROFILE-UPDATE] Processing update for user: ${user.id}`)
    console.log(`📝 [VENDOR-PROFILE-UPDATE] Update fields: ${Object.keys(updateData).join(', ')}`)

    // Debug business hours data specifically
    if (updateData.business_hours) {
      console.log(`🕒 [VENDOR-PROFILE-UPDATE] Business hours received:`, JSON.stringify(updateData.business_hours, null, 2))
      const dayKeys = Object.keys(updateData.business_hours)
      console.log(`🕒 [VENDOR-PROFILE-UPDATE] Business hours days: ${dayKeys.join(', ')}`)

      // Log each day's data structure
      for (const day of dayKeys) {
        const dayData = updateData.business_hours[day]
        console.log(`🕒 [VENDOR-PROFILE-UPDATE] ${day}: is_open=${dayData?.is_open}, open=${dayData?.open}, close=${dayData?.close}`)
      }
    } else {
      console.log(`🕒 [VENDOR-PROFILE-UPDATE] No business hours data in request`)
    }

    // Validate the update data
    const validationResult = validateVendorProfileData(updateData)
    if (!validationResult.isValid) {
      console.error('❌ [VENDOR-PROFILE-UPDATE] Validation failed:', validationResult.errors)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Validation failed',
          details: validationResult.errors,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Get current vendor profile to verify ownership
    const { data: currentVendor, error: vendorError } = await supabaseClient
      .from('vendors')
      .select('id, user_id, business_name')
      .eq('user_id', user.id)
      .single()

    if (vendorError || !currentVendor) {
      console.error('❌ [VENDOR-PROFILE-UPDATE] Vendor not found:', vendorError)
      return new Response(
        JSON.stringify({ success: false, error: 'Vendor profile not found' }),
        {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Prepare update payload with timestamp
    const updatePayload = {
      ...updateData,
      updated_at: new Date().toISOString(),
    }

    // Update vendor profile
    const { data: updatedVendor, error: updateError } = await supabaseClient
      .from('vendors')
      .update(updatePayload)
      .eq('id', currentVendor.id)
      .eq('user_id', user.id) // Double-check ownership
      .select()
      .single()

    if (updateError) {
      console.error('❌ [VENDOR-PROFILE-UPDATE] Update failed:', updateError)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Failed to update vendor profile',
          details: updateError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Debug: Log the updated vendor data, especially business hours
    console.log(`✅ [VENDOR-PROFILE-UPDATE] Database update successful`)
    if (updatedVendor?.business_hours) {
      console.log(`🕒 [VENDOR-PROFILE-UPDATE] Saved business hours:`, JSON.stringify(updatedVendor.business_hours, null, 2))
    } else {
      console.log(`🕒 [VENDOR-PROFILE-UPDATE] No business hours in updated vendor data`)
    }

    // Log the update for audit purposes
    await logVendorProfileUpdate(supabaseClient, user.id, currentVendor.id, updateData)

    console.log(`✅ [VENDOR-PROFILE-UPDATE] Successfully updated vendor: ${currentVendor.id}`)

    return new Response(
      JSON.stringify({
        success: true,
        data: updatedVendor,
        message: 'Vendor profile updated successfully',
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.error('❌ [VENDOR-PROFILE-UPDATE] Unexpected error:', error)
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

function validateVendorProfileData(data: VendorProfileUpdateRequest): {
  isValid: boolean
  errors: string[]
} {
  const errors: string[] = []

  // Validate business name
  if (data.business_name !== undefined) {
    if (!data.business_name || data.business_name.trim().length < 2) {
      errors.push('Business name must be at least 2 characters long')
    }
    if (data.business_name.length > 100) {
      errors.push('Business name must be less than 100 characters')
    }
  }

  // Validate business registration number
  if (data.business_registration_number !== undefined) {
    if (!data.business_registration_number || data.business_registration_number.trim().length < 5) {
      errors.push('Business registration number must be at least 5 characters long')
    }
  }

  // Validate business address
  if (data.business_address !== undefined) {
    if (!data.business_address || data.business_address.trim().length < 10) {
      errors.push('Business address must be at least 10 characters long')
    }
  }

  // Validate business type
  if (data.business_type !== undefined) {
    const validBusinessTypes = ['restaurant', 'cafe', 'food_truck', 'catering', 'bakery', 'grocery', 'other']
    if (!validBusinessTypes.includes(data.business_type)) {
      errors.push('Invalid business type')
    }
  }

  // Validate cuisine types
  if (data.cuisine_types !== undefined) {
    if (!Array.isArray(data.cuisine_types) || data.cuisine_types.length === 0) {
      errors.push('At least one cuisine type must be selected')
    }
    const validCuisineTypes = [
      'Malaysian', 'Chinese', 'Indian', 'Western', 'Japanese', 'Korean', 'Thai', 
      'Italian', 'Middle Eastern', 'Fusion', 'Vegetarian', 'Halal', 'Other'
    ]
    for (const cuisine of data.cuisine_types) {
      if (!validCuisineTypes.includes(cuisine)) {
        errors.push(`Invalid cuisine type: ${cuisine}`)
      }
    }
  }

  // Validate halal certification
  if (data.is_halal_certified === true && data.halal_certification_number !== undefined) {
    if (!data.halal_certification_number || data.halal_certification_number.trim().length < 3) {
      errors.push('Halal certification number is required when halal certified is true')
    }
  }

  // Validate description
  if (data.description !== undefined && data.description.length > 1000) {
    errors.push('Description must be less than 1000 characters')
  }

  // Validate pricing fields
  if (data.minimum_order_amount !== undefined) {
    if (data.minimum_order_amount < 0 || data.minimum_order_amount > 1000) {
      errors.push('Minimum order amount must be between 0 and 1000')
    }
  }

  if (data.delivery_fee !== undefined) {
    if (data.delivery_fee < 0 || data.delivery_fee > 100) {
      errors.push('Delivery fee must be between 0 and 100')
    }
  }

  if (data.free_delivery_threshold !== undefined) {
    if (data.free_delivery_threshold < 0 || data.free_delivery_threshold > 2000) {
      errors.push('Free delivery threshold must be between 0 and 2000')
    }
  }

  // Validate business hours structure
  if (data.business_hours !== undefined) {
    const validDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
    for (const day of validDays) {
      if (data.business_hours[day]) {
        const dayHours = data.business_hours[day]
        if (typeof dayHours.is_open !== 'boolean') {
          errors.push(`Invalid business hours format for ${day}`)
        }
        if (dayHours.is_open && (!dayHours.open || !dayHours.close)) {
          errors.push(`Open and close times required for ${day} when marked as open`)
        }
        // Validate time format (HH:MM)
        if (dayHours.is_open) {
          const timeRegex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/
          if (!timeRegex.test(dayHours.open)) {
            errors.push(`Invalid open time format for ${day}. Use HH:MM format`)
          }
          if (!timeRegex.test(dayHours.close)) {
            errors.push(`Invalid close time format for ${day}. Use HH:MM format`)
          }
        }
      }
    }
  }

  // Validate gallery images array
  if (data.gallery_images !== undefined) {
    if (!Array.isArray(data.gallery_images)) {
      errors.push('Gallery images must be an array')
    } else if (data.gallery_images.length > 10) {
      errors.push('Maximum 10 gallery images allowed')
    }
  }

  // Validate service areas
  if (data.service_areas !== undefined) {
    if (!Array.isArray(data.service_areas)) {
      errors.push('Service areas must be an array')
    } else if (data.service_areas.length > 20) {
      errors.push('Maximum 20 service areas allowed')
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  }
}

async function logVendorProfileUpdate(
  supabaseClient: any,
  userId: string,
  vendorId: string,
  updateData: VendorProfileUpdateRequest
): Promise<void> {
  try {
    await supabaseClient
      .from('security_audit_log')
      .insert({
        event_type: 'vendor_profile_update',
        user_id: userId,
        event_data: {
          vendor_id: vendorId,
          updated_fields: Object.keys(updateData),
          timestamp: new Date().toISOString(),
        },
        severity: 'info',
      })
  } catch (error) {
    console.error('❌ [VENDOR-PROFILE-UPDATE] Failed to log audit entry:', error)
    // Don't fail the main operation if audit logging fails
  }
}
