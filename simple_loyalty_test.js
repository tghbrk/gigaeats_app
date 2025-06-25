// Simple test to verify loyalty points integration without creating new data

const SUPABASE_URL = 'https://abknoalhfltlhhdbclpv.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNDIxOTEsImV4cCI6MjA2MzkxODE5MX0.NAThyz5_xSTkWX7pynS7APPFZUnOc8DyjMN2K-cTt-g';

async function testLoyaltyIntegration() {
  console.log('🧪 Testing Loyalty Points Integration (Simple Test)');
  
  try {
    // Test 1: Check if loyalty accounts exist
    console.log('\n📋 Step 1: Checking loyalty accounts...');
    const loyaltyResponse = await fetch(`${SUPABASE_URL}/rest/v1/loyalty_accounts?select=*&limit=5`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'apikey': SUPABASE_ANON_KEY,
        'Content-Type': 'application/json',
      }
    });

    if (!loyaltyResponse.ok) {
      console.error('❌ Failed to fetch loyalty accounts:', await loyaltyResponse.text());
      return;
    }

    const loyaltyAccounts = await loyaltyResponse.json();
    console.log(`✅ Found ${loyaltyAccounts.length} loyalty accounts`);
    
    if (loyaltyAccounts.length > 0) {
      console.log('📊 Sample loyalty account:', {
        user_id: loyaltyAccounts[0].user_id,
        points: loyaltyAccounts[0].available_points,
        tier: loyaltyAccounts[0].current_tier
      });
    }

    // Test 2: Check if orders exist
    console.log('\n📋 Step 2: Checking orders...');
    const ordersResponse = await fetch(`${SUPABASE_URL}/rest/v1/orders?select=id,customer_id,total_amount,status&limit=5`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'apikey': SUPABASE_ANON_KEY,
        'Content-Type': 'application/json',
      }
    });

    if (!ordersResponse.ok) {
      console.error('❌ Failed to fetch orders:', await ordersResponse.text());
      return;
    }

    const orders = await ordersResponse.json();
    console.log(`✅ Found ${orders.length} orders`);
    
    if (orders.length > 0) {
      console.log('📊 Sample orders:');
      orders.forEach((order, index) => {
        console.log(`   ${index + 1}. Order ${order.id}: RM${order.total_amount} (${order.status})`);
      });
    }

    // Test 3: Test the order completion handler with a mock request
    console.log('\n📋 Step 3: Testing order completion handler...');
    
    if (orders.length > 0) {
      const testOrder = orders[0];
      console.log(`🎯 Testing with order: ${testOrder.id}`);
      
      const completionResponse = await fetch(`${SUPABASE_URL}/functions/v1/order-completion-handler`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          order_id: testOrder.id,
          completion_type: 'delivered',
          completed_by: 'test-integration',
          completion_notes: 'Test delivery for loyalty points integration'
        })
      });

      console.log('📡 Order Completion Response Status:', completionResponse.status);
      
      if (completionResponse.ok) {
        const result = await completionResponse.json();
        console.log('✅ Order Completion Result:', JSON.stringify(result, null, 2));

        // Check if loyalty points were included in the response
        if (result.loyalty_points) {
          console.log('\n🎯 Loyalty Points Integration Working!');
          console.log('   Points Awarded:', result.loyalty_points.total_points);
          console.log('   Tier Multiplier:', result.loyalty_points.tier_multiplier);
          console.log('   Bonus Points:', result.loyalty_points.bonus_points);
          
          if (result.loyalty_points.tier_upgraded) {
            console.log('🏆 Tier Upgraded to:', result.loyalty_points.new_tier);
          }
        } else {
          console.log('⚠️ No loyalty points data in response');
          console.log('   This could mean:');
          console.log('   - Loyalty points calculator failed');
          console.log('   - Customer has no loyalty account');
          console.log('   - Points already awarded for this order');
        }
      } else {
        const error = await completionResponse.text();
        console.log('❌ Order completion failed:', error);
      }
    } else {
      console.log('⚠️ No orders found to test with');
    }

    // Test 4: Test loyalty points calculator directly
    console.log('\n📋 Step 4: Testing loyalty points calculator...');
    
    const calculatorResponse = await fetch(`${SUPABASE_URL}/functions/v1/loyalty-points-calculator`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        action: 'calculate_order_points',
        order_amount: 50.00,
        tier_multiplier: 1.2,
        bonus_campaigns: ['weekend_bonus']
      })
    });

    console.log('📡 Calculator Response Status:', calculatorResponse.status);
    
    if (calculatorResponse.ok) {
      const result = await calculatorResponse.json();
      console.log('✅ Calculator Result:', JSON.stringify(result, null, 2));
    } else {
      const error = await calculatorResponse.text();
      console.log('❌ Calculator failed:', error);
    }

    console.log('\n🎉 Integration test completed!');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

// Run the test
testLoyaltyIntegration();
