import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface TestAccount {
  email: string;
  password: string;
  role: string;
  profile_data: any;
}

const testAccounts: TestAccount[] = [
  {
    email: 'admin.test@gigaeats.com',
    password: 'Testpass123!',
    role: 'admin',
    profile_data: {
      full_name: 'Admin Test User',
      phone: '+60123456789',
      address: 'Kuala Lumpur, Malaysia'
    }
  },
  {
    email: 'vendor.test@gigaeats.com',
    password: 'Testpass123!',
    role: 'vendor',
    profile_data: {
      full_name: 'Vendor Test User',
      phone: '+60123456790',
      address: 'Petaling Jaya, Malaysia'
    }
  },
  {
    email: 'salesagent.test@gigaeats.com',
    password: 'Testpass123!',
    role: 'sales_agent',
    profile_data: {
      full_name: 'Sales Agent Test User',
      phone: '+60123456791',
      address: 'Shah Alam, Malaysia'
    }
  },
  {
    email: 'driver.test@gigaeats.com',
    password: 'Testpass123!',
    role: 'driver',
    profile_data: {
      full_name: 'Driver Test User',
      phone: '+60123456792',
      address: 'Subang Jaya, Malaysia'
    }
  },
  {
    email: 'customer.test@gigaeats.com',
    password: 'Testpass123!',
    role: 'customer',
    profile_data: {
      full_name: 'Customer Test User',
      phone: '+60123456793',
      address: 'Bangsar, Malaysia'
    }
  }
];

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase Admin Client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    const results = []

    for (const account of testAccounts) {
      try {
        console.log(`Creating account for ${account.email}...`)

        // Create user using Admin API
        const { data: authUser, error: authError } = await supabaseAdmin.auth.admin.createUser({
          email: account.email,
          password: account.password,
          email_confirm: true, // Auto-confirm email
          user_metadata: {
            role: account.role,
            full_name: account.profile_data.full_name
          }
        })

        if (authError) {
          console.error(`Auth error for ${account.email}:`, authError)
          results.push({
            email: account.email,
            success: false,
            error: authError.message
          })
          continue
        }

        console.log(`Auth user created for ${account.email}:`, authUser.user?.id)

        // Create profile record based on role
        let profileError = null
        
        if (account.role === 'vendor') {
          // Create vendor business profile
          const { error } = await supabaseAdmin
            .from('vendor_business_profiles')
            .insert({
              user_id: authUser.user!.id,
              business_name: 'Test Restaurant',
              business_type: 'restaurant',
              cuisine_type: 'Malaysian',
              description: 'Test restaurant for development',
              address: account.profile_data.address,
              phone: account.profile_data.phone,
              email: account.email,
              operating_hours: {
                monday: { open: '09:00', close: '22:00', is_open: true },
                tuesday: { open: '09:00', close: '22:00', is_open: true },
                wednesday: { open: '09:00', close: '22:00', is_open: true },
                thursday: { open: '09:00', close: '22:00', is_open: true },
                friday: { open: '09:00', close: '22:00', is_open: true },
                saturday: { open: '09:00', close: '22:00', is_open: true },
                sunday: { open: '09:00', close: '22:00', is_open: true }
              },
              delivery_radius: 10.0,
              minimum_order_amount: 15.00,
              delivery_fee: 5.00,
              estimated_delivery_time: 30,
              is_active: true,
              verification_status: 'verified'
            })
          profileError = error
        } else if (account.role === 'sales_agent') {
          // Create sales agent profile
          const { error } = await supabaseAdmin
            .from('user_profiles')
            .insert({
              user_id: authUser.user!.id,
              full_name: account.profile_data.full_name,
              phone: account.profile_data.phone,
              address: account.profile_data.address,
              role: 'sales_agent',
              territory: 'Kuala Lumpur',
              commission_rate: 0.05,
              is_active: true
            })
          profileError = error
        } else if (account.role === 'driver') {
          // Create driver profile
          const { error } = await supabaseAdmin
            .from('drivers')
            .insert({
              user_id: authUser.user!.id,
              full_name: account.profile_data.full_name,
              phone: account.profile_data.phone,
              email: account.email,
              license_number: 'TEST123456',
              vehicle_type: 'motorcycle',
              vehicle_plate: 'ABC1234',
              vehicle_model: 'Honda Wave',
              vehicle_color: 'Red',
              status: 'available',
              is_active: true,
              current_latitude: 3.1390,
              current_longitude: 101.6869,
              last_location_update: new Date().toISOString()
            })
          profileError = error
        } else if (account.role === 'customer') {
          // Create customer profile
          const { error } = await supabaseAdmin
            .from('customer_profiles')
            .insert({
              user_id: authUser.user!.id,
              full_name: account.profile_data.full_name,
              phone: account.profile_data.phone,
              email: account.email,
              default_address: account.profile_data.address,
              is_active: true
            })
          profileError = error
        } else if (account.role === 'admin') {
          // Create admin profile
          const { error } = await supabaseAdmin
            .from('user_profiles')
            .insert({
              user_id: authUser.user!.id,
              full_name: account.profile_data.full_name,
              phone: account.profile_data.phone,
              address: account.profile_data.address,
              role: 'admin',
              is_active: true
            })
          profileError = error
        }

        if (profileError) {
          console.error(`Profile error for ${account.email}:`, profileError)
          results.push({
            email: account.email,
            success: false,
            error: `Profile creation failed: ${profileError.message}`
          })
        } else {
          console.log(`Successfully created account and profile for ${account.email}`)
          results.push({
            email: account.email,
            success: true,
            user_id: authUser.user!.id,
            role: account.role
          })
        }

      } catch (error) {
        console.error(`Unexpected error for ${account.email}:`, error)
        results.push({
          email: account.email,
          success: false,
          error: error.message
        })
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Test account creation completed',
        results: results
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )

  } catch (error) {
    console.error('Function error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
})
