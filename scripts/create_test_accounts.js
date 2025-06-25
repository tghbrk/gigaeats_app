const { createClient } = require('@supabase/supabase-js');

// Supabase configuration
const supabaseUrl = 'https://abknoalhfltlhhdbclpv.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODM0MjE5MSwiZXhwIjoyMDYzOTE4MTkxfQ.c9U38XFDf8f4ngCNDp2XlSOLSlIaPI-Utg1GgaHwmSY';

const testAccounts = [
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

async function createTestAccounts() {
  console.log('🚀 Starting test account creation...');
  
  // Initialize Supabase Admin Client
  const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  });

  const results = [];

  for (const account of testAccounts) {
    try {
      console.log(`\n📧 Creating account for ${account.email}...`);

      // Create user using Admin API
      const { data: authUser, error: authError } = await supabaseAdmin.auth.admin.createUser({
        email: account.email,
        password: account.password,
        email_confirm: true, // Auto-confirm email
        user_metadata: {
          role: account.role,
          full_name: account.profile_data.full_name
        }
      });

      if (authError) {
        console.error(`❌ Auth error for ${account.email}:`, authError.message);
        results.push({
          email: account.email,
          success: false,
          error: authError.message
        });
        continue;
      }

      console.log(`✅ Auth user created for ${account.email}: ${authUser.user?.id}`);

      // Create profile record based on role
      let profileError = null;
      
      // First create the user record in the users table
      const { error: userError } = await supabaseAdmin
        .from('users')
        .insert({
          supabase_user_id: authUser.user.id,
          email: account.email,
          full_name: account.profile_data.full_name,
          role: account.role,
          is_verified: true,
          is_active: true
        });

      if (userError) {
        console.error(`❌ User table error for ${account.email}:`, userError.message);
        profileError = userError;
      } else if (account.role === 'vendor') {
        // Create vendor business profile
        const { error } = await supabaseAdmin
          .from('vendors')
          .insert({
            user_id: authUser.user.id,
            business_name: 'Test Restaurant',
            business_registration_number: 'TEST123456789',
            business_address: account.profile_data.address,
            business_type: 'restaurant',
            cuisine_types: ['Malaysian'],
            is_halal_certified: true,
            description: 'Test restaurant for development',
            rating: 4.5,
            total_reviews: 0,
            total_orders: 0,
            business_hours: {
              monday: { open: '09:00', close: '22:00', is_open: true },
              tuesday: { open: '09:00', close: '22:00', is_open: true },
              wednesday: { open: '09:00', close: '22:00', is_open: true },
              thursday: { open: '09:00', close: '22:00', is_open: true },
              friday: { open: '09:00', close: '22:00', is_open: true },
              saturday: { open: '09:00', close: '22:00', is_open: true },
              sunday: { open: '09:00', close: '22:00', is_open: true }
            },
            service_areas: ['Kuala Lumpur', 'Petaling Jaya'],
            minimum_order_amount: 15.00,
            delivery_fee: 5.00,
            free_delivery_threshold: 50.00,
            is_active: true,
            is_verified: true
          });
        profileError = error;
      } else if (account.role === 'sales_agent') {
        // Create sales agent profile
        const { error } = await supabaseAdmin
          .from('user_profiles')
          .insert({
            user_id: authUser.user.id,
            full_name: account.profile_data.full_name,
            phone: account.profile_data.phone,
            address: account.profile_data.address,
            role: 'sales_agent',
            territory: 'Kuala Lumpur',
            commission_rate: 0.05,
            is_active: true
          });
        profileError = error;
      } else if (account.role === 'driver') {
        // Create driver profile
        const { error } = await supabaseAdmin
          .from('drivers')
          .insert({
            user_id: authUser.user.id,
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
          });
        profileError = error;
      } else if (account.role === 'customer') {
        // Create customer profile
        const { error } = await supabaseAdmin
          .from('customer_profiles')
          .insert({
            user_id: authUser.user.id,
            full_name: account.profile_data.full_name,
            phone: account.profile_data.phone,
            email: account.email,
            default_address: account.profile_data.address,
            is_active: true
          });
        profileError = error;
      } else if (account.role === 'admin') {
        // Create admin profile
        const { error } = await supabaseAdmin
          .from('user_profiles')
          .insert({
            user_id: authUser.user.id,
            full_name: account.profile_data.full_name,
            phone: account.profile_data.phone,
            address: account.profile_data.address,
            role: 'admin',
            is_active: true
          });
        profileError = error;
      }

      if (profileError) {
        console.error(`❌ Profile error for ${account.email}:`, profileError.message);
        results.push({
          email: account.email,
          success: false,
          error: `Profile creation failed: ${profileError.message}`
        });
      } else {
        console.log(`✅ Successfully created account and profile for ${account.email}`);
        results.push({
          email: account.email,
          success: true,
          user_id: authUser.user.id,
          role: account.role
        });
      }

    } catch (error) {
      console.error(`❌ Unexpected error for ${account.email}:`, error.message);
      results.push({
        email: account.email,
        success: false,
        error: error.message
      });
    }
  }

  console.log('\n📊 Test Account Creation Results:');
  console.log('================================');
  results.forEach(result => {
    if (result.success) {
      console.log(`✅ ${result.email} - SUCCESS (${result.role})`);
    } else {
      console.log(`❌ ${result.email} - FAILED: ${result.error}`);
    }
  });

  const successCount = results.filter(r => r.success).length;
  console.log(`\n🎯 Summary: ${successCount}/${results.length} accounts created successfully`);
  
  return results;
}

// Run the script
if (require.main === module) {
  createTestAccounts()
    .then(() => {
      console.log('\n🏁 Test account creation completed!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n💥 Script failed:', error);
      process.exit(1);
    });
}

module.exports = { createTestAccounts };
