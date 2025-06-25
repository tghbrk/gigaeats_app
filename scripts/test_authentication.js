const { createClient } = require('@supabase/supabase-js');

// Supabase configuration
const supabaseUrl = 'https://abknoalhfltlhhdbclpv.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNDIxOTEsImV4cCI6MjA2MzkxODE5MX0.NAThyz5_xSTkWX7pynS7APPFZUnOc8DyjMN2K-cTt-g';

const testAccounts = [
  { email: 'admin.test@gigaeats.com', password: 'Testpass123!', role: 'admin' },
  { email: 'vendor.test@gigaeats.com', password: 'Testpass123!', role: 'vendor' },
  { email: 'salesagent.test@gigaeats.com', password: 'Testpass123!', role: 'sales_agent' },
  { email: 'driver.test@gigaeats.com', password: 'Testpass123!', role: 'driver' },
  { email: 'customer.test@gigaeats.com', password: 'Testpass123!', role: 'customer' }
];

async function testAuthentication() {
  console.log('🔐 Testing authentication for all test accounts...\n');
  
  const results = [];

  for (const account of testAccounts) {
    try {
      console.log(`🧪 Testing login for ${account.email} (${account.role})...`);

      // Create a new Supabase client for each test
      const supabase = createClient(supabaseUrl, supabaseAnonKey);

      // Attempt to sign in
      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email: account.email,
        password: account.password
      });

      if (authError) {
        console.error(`❌ Auth failed for ${account.email}:`, authError.message);
        results.push({
          email: account.email,
          role: account.role,
          auth_success: false,
          auth_error: authError.message,
          profile_success: false
        });
        continue;
      }

      console.log(`✅ Auth successful for ${account.email}`);

      // Check if user data is available
      const user = authData.user;
      if (!user) {
        console.error(`❌ No user data returned for ${account.email}`);
        results.push({
          email: account.email,
          role: account.role,
          auth_success: true,
          profile_success: false,
          profile_error: 'No user data returned'
        });
        continue;
      }

      // Try to fetch profile data based on role
      let profileData = null;
      let profileError = null;

      try {
        if (account.role === 'vendor') {
          const { data, error } = await supabase
            .from('vendors')
            .select('*')
            .eq('user_id', user.id)
            .single();
          profileData = data;
          profileError = error;
        } else if (account.role === 'admin' || account.role === 'sales_agent') {
          const { data, error } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('user_id', user.id)
            .single();
          profileData = data;
          profileError = error;
        } else if (account.role === 'driver') {
          const { data, error } = await supabase
            .from('drivers')
            .select('*')
            .eq('user_id', user.id)
            .single();
          profileData = data;
          profileError = error;
        } else if (account.role === 'customer') {
          const { data, error } = await supabase
            .from('customer_profiles')
            .select('*')
            .eq('user_id', user.id)
            .single();
          profileData = data;
          profileError = error;
        }

        if (profileError) {
          console.error(`❌ Profile fetch failed for ${account.email}:`, profileError.message);
          results.push({
            email: account.email,
            role: account.role,
            auth_success: true,
            profile_success: false,
            profile_error: profileError.message
          });
        } else if (profileData) {
          console.log(`✅ Profile data found for ${account.email}`);
          results.push({
            email: account.email,
            role: account.role,
            auth_success: true,
            profile_success: true,
            user_id: user.id
          });
        } else {
          console.error(`❌ No profile data found for ${account.email}`);
          results.push({
            email: account.email,
            role: account.role,
            auth_success: true,
            profile_success: false,
            profile_error: 'No profile data found'
          });
        }
      } catch (profileFetchError) {
        console.error(`❌ Profile fetch error for ${account.email}:`, profileFetchError.message);
        results.push({
          email: account.email,
          role: account.role,
          auth_success: true,
          profile_success: false,
          profile_error: profileFetchError.message
        });
      }

      // Sign out
      await supabase.auth.signOut();

    } catch (error) {
      console.error(`❌ Unexpected error for ${account.email}:`, error.message);
      results.push({
        email: account.email,
        role: account.role,
        auth_success: false,
        auth_error: error.message,
        profile_success: false
      });
    }

    console.log(''); // Empty line for readability
  }

  console.log('📊 Authentication Test Results:');
  console.log('===============================');
  results.forEach(result => {
    const authStatus = result.auth_success ? '✅ AUTH' : '❌ AUTH';
    const profileStatus = result.profile_success ? '✅ PROFILE' : '❌ PROFILE';
    console.log(`${authStatus} | ${profileStatus} | ${result.email} (${result.role})`);
    
    if (!result.auth_success && result.auth_error) {
      console.log(`   Auth Error: ${result.auth_error}`);
    }
    if (!result.profile_success && result.profile_error) {
      console.log(`   Profile Error: ${result.profile_error}`);
    }
  });

  const authSuccessCount = results.filter(r => r.auth_success).length;
  const profileSuccessCount = results.filter(r => r.profile_success).length;
  console.log(`\n🎯 Summary:`);
  console.log(`   Authentication: ${authSuccessCount}/${results.length} successful`);
  console.log(`   Profile Access: ${profileSuccessCount}/${results.length} successful`);
  console.log(`   Overall: ${profileSuccessCount}/${results.length} accounts fully functional`);
  
  return results;
}

// Run the script
if (require.main === module) {
  testAuthentication()
    .then((results) => {
      const fullyFunctional = results.filter(r => r.auth_success && r.profile_success).length;
      if (fullyFunctional === results.length) {
        console.log('\n🎉 All test accounts are fully functional!');
        process.exit(0);
      } else {
        console.log(`\n⚠️  ${fullyFunctional}/${results.length} accounts are fully functional. Some issues need to be resolved.`);
        process.exit(1);
      }
    })
    .catch((error) => {
      console.error('\n💥 Authentication test failed:', error);
      process.exit(1);
    });
}

module.exports = { testAuthentication };
