// Test script to verify order completion with loyalty points integration
// This creates a real order and tests the complete flow

const SUPABASE_URL = 'https://abknoalhfltlhhdbclpv.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNDIxOTEsImV4cCI6MjA2MzkxODE5MX0.NAThyz5_xSTkWX7pynS7APPFZUnOc8DyjMN2K-cTt-g';

async function testOrderCompletionIntegration() {
  console.log('🧪 Testing Order Completion with Loyalty Points Integration');
  
  try {
    // First, let's check if we have any existing orders to test with
    const ordersResponse = await fetch(`${SUPABASE_URL}/rest/v1/orders?select=id,customer_id,total_amount,status&status=eq.ready&limit=1`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'apikey': SUPABASE_ANON_KEY,
        'Content-Type': 'application/json',
      }
    });

    if (!ordersResponse.ok) {
      console.error('❌ Failed to fetch orders:', ordersResponse.statusText);
      return;
    }

    const orders = await ordersResponse.json();
    console.log('📋 Found orders:', orders.length);

    if (orders.length === 0) {
      console.log('⚠️ No orders with "ready" status found. Creating a test scenario...');
      
      // Let's check for any orders we can use for testing
      const allOrdersResponse = await fetch(`${SUPABASE_URL}/rest/v1/orders?select=id,customer_id,total_amount,status&limit=5`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
          'apikey': SUPABASE_ANON_KEY,
          'Content-Type': 'application/json',
        }
      });

      const allOrders = await allOrdersResponse.json();
      console.log('📋 All orders found:', allOrders.length);
      
      if (allOrders.length > 0) {
        console.log('📋 Sample orders:', allOrders.map(o => ({ id: o.id, status: o.status, amount: o.total_amount })));
        
        // Use the first order for testing
        const testOrder = allOrders[0];
        console.log(`🎯 Using order ${testOrder.id} for testing`);
        
        await testOrderCompletion(testOrder.id, testOrder.customer_id, testOrder.total_amount);
      } else {
        console.log('⚠️ No orders found in database. Please create some test data first.');
      }
      
      return;
    }

    const testOrder = orders[0];
    console.log(`🎯 Testing with order: ${testOrder.id}`);
    console.log(`   Customer: ${testOrder.customer_id}`);
    console.log(`   Amount: RM ${testOrder.total_amount}`);

    await testOrderCompletion(testOrder.id, testOrder.customer_id, testOrder.total_amount);

  } catch (error) {
    console.error('❌ Test Failed:', error.message);
  }
}

async function testOrderCompletion(orderId, customerId, orderAmount) {
  console.log(`\n🚀 Testing order completion for order ${orderId}`);
  
  try {
    // Check loyalty account before completion
    const loyaltyBefore = await getLoyaltyAccount(customerId);
    console.log('🎯 Loyalty account before completion:', {
      points: loyaltyBefore?.available_points || 0,
      tier: loyaltyBefore?.current_tier || 'none'
    });

    // Test the order completion handler Edge Function
    const response = await fetch(`${SUPABASE_URL}/functions/v1/order-completion-handler`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        order_id: orderId,
        completion_type: 'delivered',
        completed_by: 'test-integration',
        completion_notes: 'Test delivery for loyalty points integration'
      })
    });

    console.log('📡 Order Completion Response Status:', response.status);
    
    if (!response.ok) {
      const errorText = await response.text();
      console.error('❌ Error Response:', errorText);
      return;
    }

    const result = await response.json();
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

    // Check loyalty account after completion
    const loyaltyAfter = await getLoyaltyAccount(customerId);
    console.log('\n🎯 Loyalty account after completion:', {
      points: loyaltyAfter?.available_points || 0,
      tier: loyaltyAfter?.current_tier || 'none'
    });

    // Calculate expected points change
    const expectedPoints = Math.floor(orderAmount);
    const pointsChange = (loyaltyAfter?.available_points || 0) - (loyaltyBefore?.available_points || 0);
    
    console.log(`\n📊 Points Analysis:`);
    console.log(`   Expected points: ${expectedPoints}`);
    console.log(`   Actual points change: ${pointsChange}`);
    
    if (pointsChange > 0) {
      console.log('✅ Points were successfully awarded!');
    } else {
      console.log('⚠️ No points change detected');
    }

  } catch (error) {
    console.error('❌ Order completion test failed:', error.message);
  }
}

async function getLoyaltyAccount(customerId) {
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/loyalty_accounts?select=*&user_id=eq.${customerId}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'apikey': SUPABASE_ANON_KEY,
        'Content-Type': 'application/json',
      }
    });

    if (!response.ok) {
      console.error('❌ Failed to fetch loyalty account:', response.statusText);
      return null;
    }

    const accounts = await response.json();
    return accounts.length > 0 ? accounts[0] : null;
  } catch (error) {
    console.error('❌ Error fetching loyalty account:', error.message);
    return null;
  }
}

// Run the test
testOrderCompletionIntegration();
