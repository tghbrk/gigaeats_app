const { createClient } = require('@supabase/supabase-js');

// Supabase configuration
const supabaseUrl = 'https://abknoalhfltlhhdbclpv.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODM0MjE5MSwiZXhwIjoyMDYzOTE4MTkxfQ.c9U38XFDf8f4ngCNDp2XlSOLSlIaPI-Utg1GgaHwmSY';

const testEmails = [
  'admin.test@gigaeats.com',
  'vendor.test@gigaeats.com',
  'salesagent.test@gigaeats.com',
  'driver.test@gigaeats.com',
  'customer.test@gigaeats.com'
];

async function cleanupTestAccounts() {
  console.log('🧹 Starting test account cleanup...');
  
  // Initialize Supabase Admin Client
  const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  });

  const results = [];

  for (const email of testEmails) {
    try {
      console.log(`\n🔍 Checking account for ${email}...`);

      // Get user by email
      const { data: users, error: getUserError } = await supabaseAdmin.auth.admin.listUsers();
      
      if (getUserError) {
        console.error(`❌ Error listing users:`, getUserError.message);
        continue;
      }

      const existingUser = users.users.find(user => user.email === email);
      
      if (!existingUser) {
        console.log(`ℹ️  No existing user found for ${email}`);
        results.push({
          email: email,
          action: 'none',
          success: true
        });
        continue;
      }

      console.log(`🔍 Found existing user for ${email}: ${existingUser.id}`);

      // Delete profile records first
      try {
        // Try to delete from all possible profile tables
        await supabaseAdmin.from('vendor_business_profiles').delete().eq('user_id', existingUser.id);
        await supabaseAdmin.from('user_profiles').delete().eq('user_id', existingUser.id);
        await supabaseAdmin.from('drivers').delete().eq('user_id', existingUser.id);
        await supabaseAdmin.from('customer_profiles').delete().eq('user_id', existingUser.id);
        console.log(`🗑️  Deleted profile records for ${email}`);
      } catch (profileError) {
        console.log(`⚠️  Profile deletion warning for ${email}:`, profileError.message);
      }

      // Delete the auth user
      const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(existingUser.id);
      
      if (deleteError) {
        console.error(`❌ Error deleting user ${email}:`, deleteError.message);
        results.push({
          email: email,
          action: 'delete_failed',
          success: false,
          error: deleteError.message
        });
      } else {
        console.log(`✅ Successfully deleted user ${email}`);
        results.push({
          email: email,
          action: 'deleted',
          success: true
        });
      }

    } catch (error) {
      console.error(`❌ Unexpected error for ${email}:`, error.message);
      results.push({
        email: email,
        action: 'error',
        success: false,
        error: error.message
      });
    }
  }

  console.log('\n📊 Cleanup Results:');
  console.log('===================');
  results.forEach(result => {
    if (result.success) {
      console.log(`✅ ${result.email} - ${result.action.toUpperCase()}`);
    } else {
      console.log(`❌ ${result.email} - FAILED: ${result.error}`);
    }
  });

  const successCount = results.filter(r => r.success).length;
  console.log(`\n🎯 Summary: ${successCount}/${results.length} operations completed successfully`);
  
  return results;
}

// Run the script
if (require.main === module) {
  cleanupTestAccounts()
    .then(() => {
      console.log('\n🏁 Cleanup completed!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n💥 Cleanup failed:', error);
      process.exit(1);
    });
}

module.exports = { cleanupTestAccounts };
