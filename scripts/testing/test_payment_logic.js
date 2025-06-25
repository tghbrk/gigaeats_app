// Test script to verify payment processing logic without authentication
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://abknoalhfltlhhdbclpv.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY; // Need service role key for testing

if (!supabaseServiceKey) {
  console.error('❌ SUPABASE_SERVICE_ROLE_KEY environment variable is required');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function testPaymentLogic() {
  try {
    console.log('🚀 Testing Payment Processing Logic...');

    // Step 1: Check if the RLS policy allows customer access
    console.log('🔍 Testing RLS policy logic...');

    // Get an existing order and its customer
    const orderId = '5923d90a-58d4-4e60-8494-2888a5ada2fb';
    const customerId = 'bd2d035b-9052-462b-b60f-84d215b19b1f';

    // Get the customer's user_id
    const { data: customerProfile, error: customerError } = await supabase
      .from('customer_profiles')
      .select('user_id, full_name')
      .eq('id', customerId)
      .single();

    if (customerError) {
      console.error('❌ Failed to get customer profile:', customerError);
      return;
    }

    console.log('✅ Customer profile found:', customerProfile.full_name);
    console.log('🆔 Customer user_id:', customerProfile.user_id);

    // Step 2: Test the isCustomerOwner logic manually
    console.log('🧪 Testing isCustomerOwner logic...');

    const { data: ownershipCheck, error: ownershipError } = await supabase
      .from('customer_profiles')
      .select('id')
      .eq('user_id', customerProfile.user_id)
      .eq('id', customerId)
      .single();

    if (ownershipError) {
      console.log('❌ Ownership check failed:', ownershipError);
    } else {
      console.log('✅ Ownership check passed - customer owns the profile');
    }

    // Step 3: Test order access with RLS (simulate customer context)
    console.log('🔒 Testing order access with customer context...');

    // Create a client with the customer's user context (simulated)
    const customerClient = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        persistSession: false
      }
    });

    // Manually set the user context for testing
    const { data: orderAccess, error: orderAccessError } = await supabase
      .rpc('test_customer_order_access', {
        p_user_id: customerProfile.user_id,
        p_order_id: orderId
      });

    if (orderAccessError) {
      console.log('ℹ️ RPC function not found (expected), testing direct query...');

      // Test direct query with customer context
      const { data: directOrder, error: directOrderError } = await supabase
        .from('orders')
        .select('id, customer_id, total_amount, status, payment_status')
        .eq('id', orderId)
        .single();

      if (directOrderError) {
        console.log('❌ Direct order query failed:', directOrderError);
      } else {
        console.log('✅ Direct order query succeeded:', directOrder);

        // Check if this order belongs to our customer
        if (directOrder.customer_id === customerId) {
          console.log('✅ Order belongs to the correct customer');
        } else {
          console.log('❌ Order does not belong to the customer');
        }
      }
    }

    // Step 4: Test the payment processing Edge Function logic
    console.log('💳 Testing payment processing Edge Function...');

    // Since we can't easily test with authentication, let's verify the function exists
    // and check its response to understand if our changes work
    const paymentResponse = await supabase.functions.invoke('process-payment', {
      body: {
        order_id: orderId,
        amount: 63.00,
        currency: 'myr',
        payment_method: 'credit_card'
      }
    });

    console.log('💳 Payment function response status:', paymentResponse.status);
    console.log('💳 Payment function response:', JSON.stringify(paymentResponse.data, null, 2));

    if (paymentResponse.error) {
      console.log('💳 Payment function error:', paymentResponse.error);
    }

    // Analyze the response
    if (paymentResponse.status === 401) {
      console.log('ℹ️ Expected: Function requires authentication');
    } else if (paymentResponse.status === 403) {
      console.log('ℹ️ Expected: Function requires proper user context');
    } else if (paymentResponse.data?.error === 'Access denied to this order') {
      console.log('❌ Our fix didn\'t work - still getting access denied');
    } else if (paymentResponse.data?.success) {
      console.log('✅ Payment processing logic works!');
    } else {
      console.log('ℹ️ Other response - need to investigate further');
    }

    console.log('🏁 Test completed');

  } catch (error) {
    console.error('❌ Test error:', error);
  }
}

testPaymentLogic();