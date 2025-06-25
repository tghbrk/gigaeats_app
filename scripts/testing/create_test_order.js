// Script to create test data for loyalty points integration testing

const SUPABASE_URL = 'https://abknoalhfltlhhdbclpv.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNDIxOTEsImV4cCI6MjA2MzkxODE5MX0.NAThyz5_xSTkWX7pynS7APPFZUnOc8DyjMN2K-cTt-g';

async function createTestData() {
  console.log('🏗️ Creating test data for loyalty points integration');
  
  try {
    // Check if test customer exists in auth.users
    const customerResponse = await fetch(`${SUPABASE_URL}/rest/v1/auth.users?select=id,email&email=eq.customer.test@gigaeats.com`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'apikey': SUPABASE_ANON_KEY,
        'Content-Type': 'application/json',
      }
    });

    if (!customerResponse.ok) {
      const error = await customerResponse.text();
      console.error('❌ Failed to fetch customers:', error);
      return;
    }

    const customers = await customerResponse.json();
    console.log('👤 Found customers:', customers.length);

    if (!customers || customers.length === 0) {
      console.log('⚠️ No test customer found. Please run the create-test-accounts function first.');
      return;
    }

    const testCustomer = customers[0];
    console.log(`👤 Using test customer: ${testCustomer.id}`);

    // Check if customer has loyalty account
    const loyaltyResponse = await fetch(`${SUPABASE_URL}/rest/v1/loyalty_accounts?select=*&user_id=eq.${testCustomer.id}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'apikey': SUPABASE_ANON_KEY,
        'Content-Type': 'application/json',
      }
    });

    const loyaltyAccounts = await loyaltyResponse.json();
    console.log('🎯 Found loyalty accounts:', loyaltyAccounts.length);

    if (loyaltyAccounts.length === 0) {
      console.log('🎯 Creating loyalty account for test customer...');
      
      const createLoyaltyResponse = await fetch(`${SUPABASE_URL}/rest/v1/loyalty_accounts`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
          'apikey': SUPABASE_ANON_KEY,
          'Content-Type': 'application/json',
          'Prefer': 'return=representation'
        },
        body: JSON.stringify({
          user_id: testCustomer.id,
          available_points: 0,
          lifetime_earned_points: 0,
          current_tier: 'bronze',
          tier_multiplier: 1.0,
          next_tier_requirement: 1000,
          tier_progress: 0,
          status: 'active'
        })
      });

      if (!createLoyaltyResponse.ok) {
        const error = await createLoyaltyResponse.text();
        console.error('❌ Failed to create loyalty account:', error);
        return;
      }

      const newLoyaltyAccount = await createLoyaltyResponse.json();
      console.log('✅ Created loyalty account:', newLoyaltyAccount[0].id);
    }

    // Check if test vendor exists
    const vendorResponse = await fetch(`${SUPABASE_URL}/rest/v1/vendors?select=*&limit=1`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'apikey': SUPABASE_ANON_KEY,
        'Content-Type': 'application/json',
      }
    });

    const vendors = await vendorResponse.json();
    console.log('🏪 Found vendors:', vendors.length);

    if (vendors.length === 0) {
      console.log('⚠️ No vendors found. Cannot create test order without vendor.');
      return;
    }

    const testVendor = vendors[0];
    console.log(`🏪 Using test vendor: ${testVendor.id}`);

    // Create a test order
    console.log('📝 Creating test order...');
    
    const orderData = {
      customer_id: testCustomer.id,
      vendor_id: testVendor.id,
      total_amount: 75.50, // This should give 75 loyalty points
      delivery_method: 'own_fleet',
      delivery_address: '123 Test Street, Test City',
      status: 'ready', // Ready for delivery
      payment_status: 'paid',
      payment_method: 'wallet',
      order_items: [
        {
          menu_item_id: 'test-item-1',
          quantity: 2,
          unit_price: 25.00,
          total_price: 50.00,
          customizations: {}
        },
        {
          menu_item_id: 'test-item-2',
          quantity: 1,
          unit_price: 25.50,
          total_price: 25.50,
          customizations: {}
        }
      ]
    };

    const createOrderResponse = await fetch(`${SUPABASE_URL}/rest/v1/orders`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'apikey': SUPABASE_ANON_KEY,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      },
      body: JSON.stringify(orderData)
    });

    if (!createOrderResponse.ok) {
      const error = await createOrderResponse.text();
      console.error('❌ Failed to create order:', error);
      return;
    }

    const newOrder = await createOrderResponse.json();
    console.log('✅ Created test order:', newOrder[0].id);
    console.log(`   Customer: ${newOrder[0].customer_id}`);
    console.log(`   Amount: RM ${newOrder[0].total_amount}`);
    console.log(`   Status: ${newOrder[0].status}`);

    console.log('\n🎉 Test data created successfully!');
    console.log('You can now run the order completion integration test.');

  } catch (error) {
    console.error('❌ Failed to create test data:', error.message);
  }
}

// Run the script
createTestData();
