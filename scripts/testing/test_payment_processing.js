// Test script to verify payment processing after order creation
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://abknoalhfltlhhdbclpv.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNDIxOTEsImV4cCI6MjA2MzkxODE5MX0.NAThyz5_xSTkWX7pynS7APPFZUnOc8DyjMN2K-cTt-g';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testPaymentProcessing() {
  try {
    console.log('🚀 Testing Payment Processing Flow...');

    // Step 1: Test the RLS policy by checking if we can query orders as the customer
    console.log('🔍 Testing RLS policy for customer order access...');

    // First, let's try to create a test user and customer profile
    console.log('👤 Creating test user for payment testing...');

    const testEmail = `payment-test-${Date.now()}@gigaeats.com`;
    const testPassword = 'TestPassword123!';

    // Create test user
    const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
      email: testEmail,
      password: testPassword,
    });

    if (signUpError) {
      console.error('❌ Failed to create test user:', signUpError);
      return;
    }

    console.log('✅ Test user created:', testEmail);
    console.log('🆔 User ID:', signUpData.user?.id);

    // Wait a moment for the user to be created
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Sign in as the test user
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: testEmail,
      password: testPassword
    });

    if (authError) {
      console.error('❌ Authentication failed:', authError);
      return;
    }

    console.log('✅ Authenticated as test user');

    // Create a customer profile for this user
    const { data: customerProfile, error: profileError } = await supabase
      .from('customer_profiles')
      .insert({
        user_id: authData.user.id,
        full_name: 'Test Payment Customer',
        phone_number: '+60123456789'
      })
      .select()
      .single();

    if (profileError) {
      console.error('❌ Failed to create customer profile:', profileError);
      return;
    }

    console.log('✅ Customer profile created:', customerProfile.id);

    // Step 2: Test if we can access an existing order (should fail)
    console.log('🔒 Testing access to existing order (should fail)...');
    const existingOrderId = '5923d90a-58d4-4e60-8494-2888a5ada2fb';

    const { data: existingOrder, error: existingOrderError } = await supabase
      .from('orders')
      .select('id, customer_id, total_amount')
      .eq('id', existingOrderId)
      .single();

    if (existingOrderError) {
      console.log('✅ Correctly blocked access to other customer\'s order:', existingOrderError.message);
    } else {
      console.log('❌ Unexpectedly allowed access to other customer\'s order');
    }

    // Step 3: Create a test order for this customer
    console.log('📦 Creating test order for payment testing...');

    const testOrderData = {
      vendor_id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
      customer_id: customerProfile.id,
      delivery_date: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      delivery_address: {
        street: '123 Payment Test Street',
        city: 'Kuala Lumpur',
        state: 'Selangor',
        postal_code: '50000',
        country: 'Malaysia'
      },
      items: [
        {
          menu_item_id: 'test-menu-item-1',
          quantity: 1,
          unit_price: 25.00,
          customizations: {},
          notes: 'Payment test item'
        }
      ],
      special_instructions: 'Payment processing test order',
      contact_phone: '+60123456789'
    };

    // Use validate-order-v3 to create the order
    const orderResponse = await supabase.functions.invoke('validate-order-v3', {
      body: { orderData: testOrderData }
    });

    if (orderResponse.error || !orderResponse.data?.success) {
      console.error('❌ Failed to create test order:', orderResponse.error || orderResponse.data);
      return;
    }

    const testOrder = orderResponse.data.order;
    console.log('✅ Test order created:', testOrder.id);
    console.log('💰 Order total:', testOrder.total_amount);

    // Step 4: Test payment processing for our test order
    console.log('💳 Testing payment processing...');

    const paymentResponse = await supabase.functions.invoke('process-payment', {
      body: {
        order_id: testOrder.id,
        amount: testOrder.total_amount,
        currency: 'myr',
        payment_method: 'credit_card'
      }
    });

    console.log('💳 Payment function response status:', paymentResponse.status);
    console.log('💳 Payment function response data:', JSON.stringify(paymentResponse.data, null, 2));

    if (paymentResponse.error) {
      console.error('❌ Payment function error:', paymentResponse.error);
    }

    if (paymentResponse.status === 200 && paymentResponse.data?.success) {
      console.log('✅ Payment processing successful!');
      console.log('🎉 Client secret received:', paymentResponse.data.client_secret ? 'Yes' : 'No');
    } else {
      console.log('❌ Payment processing failed');
    }

    // Step 5: Clean up - sign out
    await supabase.auth.signOut();
    console.log('🔓 Signed out');

  } catch (error) {
    console.error('❌ Test error:', error);
  }
}

testPaymentProcessing();
