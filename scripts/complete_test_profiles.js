const { createClient } = require('@supabase/supabase-js');

// Supabase configuration
const supabaseUrl = 'https://abknoalhfltlhhdbclpv.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODM0MjE5MSwiZXhwIjoyMDYzOTE4MTkxfQ.c9U38XFDf8f4ngCNDp2XlSOLSlIaPI-Utg1GgaHwmSY';

async function completeTestProfiles() {
  console.log('🔧 Completing test account profiles...');
  
  // Initialize Supabase Admin Client
  const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  });

  // Get all test users
  const { data: testUsers, error: getUsersError } = await supabaseAdmin
    .from('users')
    .select('id, email, role, full_name')
    .like('email', '%@gigaeats.com');

  if (getUsersError) {
    console.error('❌ Error fetching test users:', getUsersError.message);
    return;
  }

  console.log(`📋 Found ${testUsers.length} test users to complete`);

  const results = [];

  for (const user of testUsers) {
    try {
      console.log(`\n👤 Completing profile for ${user.email} (${user.role})...`);

      let profileError = null;
      
      if (user.role === 'vendor') {
        // Create vendor business profile
        const { error } = await supabaseAdmin
          .from('vendors')
          .insert({
            user_id: user.id,
            business_name: 'Test Restaurant',
            business_registration_number: 'TEST123456789',
            business_address: 'Petaling Jaya, Malaysia',
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
      } else if (user.role === 'sales_agent') {
        // Create sales agent profile
        const { error } = await supabaseAdmin
          .from('user_profiles')
          .insert({
            user_id: user.id,
            company_name: 'GigaEats Sales',
            business_address: 'Shah Alam, Malaysia',
            business_type: 'sales',
            commission_rate: 0.05,
            total_earnings: 0,
            total_orders: 0,
            assigned_regions: ['Kuala Lumpur', 'Shah Alam'],
            verification_status: 'verified'
          });
        profileError = error;
      } else if (user.role === 'driver') {
        // Create driver profile
        const { error } = await supabaseAdmin
          .from('drivers')
          .insert({
            user_id: user.id,
            name: user.full_name,
            full_name: user.full_name,
            phone_number: '+60123456792',
            email: user.email,
            driving_license_number: 'TEST123456',
            vehicle_type: 'motorcycle',
            vehicle_make: 'Honda',
            vehicle_model: 'Wave',
            vehicle_year: 2020,
            vehicle_plate_number: 'ABC1234',
            vehicle_color: 'Red',
            status: 'available',
            is_active: true,
            is_verified: true,
            current_latitude: 3.1390,
            current_longitude: 101.6869,
            last_location_update: new Date().toISOString(),
            total_deliveries: 0,
            successful_deliveries: 0,
            average_rating: 5.0,
            total_earnings: 0
          });
        profileError = error;
      } else if (user.role === 'customer') {
        // Create customer profile
        const { error } = await supabaseAdmin
          .from('customer_profiles')
          .insert({
            user_id: user.id,
            email: user.email,
            full_name: user.full_name,
            phone_number: '+60123456793',
            default_address: 'Bangsar, Malaysia',
            loyalty_points: 0,
            total_orders: 0,
            total_spent: 0,
            is_active: true,
            email_verified: true,
            phone_verified: true,
            account_created_source: 'test'
          });
        profileError = error;
      } else if (user.role === 'admin') {
        // Create admin profile
        const { error } = await supabaseAdmin
          .from('user_profiles')
          .insert({
            user_id: user.id,
            company_name: 'GigaEats Admin',
            business_address: 'Kuala Lumpur, Malaysia',
            business_type: 'admin',
            commission_rate: 0,
            total_earnings: 0,
            total_orders: 0,
            verification_status: 'verified'
          });
        profileError = error;
      }

      if (profileError) {
        console.error(`❌ Profile error for ${user.email}:`, profileError.message);
        results.push({
          email: user.email,
          role: user.role,
          success: false,
          error: profileError.message
        });
      } else {
        console.log(`✅ Successfully completed profile for ${user.email}`);
        results.push({
          email: user.email,
          role: user.role,
          success: true
        });
      }

    } catch (error) {
      console.error(`❌ Unexpected error for ${user.email}:`, error.message);
      results.push({
        email: user.email,
        role: user.role,
        success: false,
        error: error.message
      });
    }
  }

  console.log('\n📊 Profile Completion Results:');
  console.log('==============================');
  results.forEach(result => {
    if (result.success) {
      console.log(`✅ ${result.email} (${result.role}) - SUCCESS`);
    } else {
      console.log(`❌ ${result.email} (${result.role}) - FAILED: ${result.error}`);
    }
  });

  const successCount = results.filter(r => r.success).length;
  console.log(`\n🎯 Summary: ${successCount}/${results.length} profiles completed successfully`);
  
  return results;
}

// Run the script
if (require.main === module) {
  completeTestProfiles()
    .then(() => {
      console.log('\n🏁 Profile completion finished!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n💥 Profile completion failed:', error);
      process.exit(1);
    });
}

module.exports = { completeTestProfiles };
