// Test script to verify loyalty points integration with order completion
// This tests the backend Edge Function integration

const SUPABASE_URL = 'https://abknoalhfltlhhdbclpv.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNDIxOTEsImV4cCI6MjA2MzkxODE5MX0.NAThyz5_xSTkWX7pynS7APPFZUnOc8DyjMN2K-cTt-g';

async function testOrderCompletionWithLoyaltyPoints() {
  console.log('🧪 Testing Order Completion with Loyalty Points Integration');
  
  try {
    // Test the order completion handler Edge Function
    const response = await fetch(`${SUPABASE_URL}/functions/v1/order-completion-handler`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        order_id: '550e8400-e29b-41d4-a716-446655440000',
        completion_type: 'delivered',
        completed_by: 'test-driver',
        completion_notes: 'Test delivery for loyalty points integration'
      })
    });

    console.log('📡 Response Status:', response.status);
    
    if (!response.ok) {
      const errorText = await response.text();
      console.error('❌ Error Response:', errorText);
      return;
    }

    const result = await response.json();
    console.log('✅ Order Completion Result:', JSON.stringify(result, null, 2));

    // Check if loyalty points were included in the response
    if (result.loyalty_points) {
      console.log('🎯 Loyalty Points Integration Working!');
      console.log('   Points Awarded:', result.loyalty_points.total_points);
      console.log('   Tier Multiplier:', result.loyalty_points.tier_multiplier);
      console.log('   Bonus Points:', result.loyalty_points.bonus_points);
      
      if (result.loyalty_points.tier_upgraded) {
        console.log('🏆 Tier Upgraded to:', result.loyalty_points.new_tier);
      }
    } else {
      console.log('⚠️ No loyalty points data in response - integration may not be working');
    }

  } catch (error) {
    console.error('❌ Test Failed:', error.message);
  }
}

async function testLoyaltyPointsCalculator() {
  console.log('\n🧮 Testing Loyalty Points Calculator Edge Function');
  
  try {
    const response = await fetch(`${SUPABASE_URL}/functions/v1/loyalty-points-calculator`, {
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

    console.log('📡 Response Status:', response.status);
    
    if (!response.ok) {
      const errorText = await response.text();
      console.error('❌ Error Response:', errorText);
      return;
    }

    const result = await response.json();
    console.log('✅ Points Calculation Result:', JSON.stringify(result, null, 2));

  } catch (error) {
    console.error('❌ Test Failed:', error.message);
  }
}

// Run the tests
async function runTests() {
  console.log('🚀 Starting Loyalty Points Integration Tests\n');
  
  await testLoyaltyPointsCalculator();
  await testOrderCompletionWithLoyaltyPoints();
  
  console.log('\n✨ Tests completed!');
}

runTests();
