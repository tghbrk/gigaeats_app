// Verification script for payment processing fix
// This script can be run in the browser console or as a Node.js script
// to verify that the payment processing fix works correctly

const SUPABASE_URL = 'https://abknoalhfltlhhdbclpv.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNDIxOTEsImV4cCI6MjA2MzkxODE5MX0.NAThyz5_xSTkWX7pynS7APPFZUnOc8DyjMN2K-cTt-g';

// Test configuration
const TEST_CONFIG = {
  // Use existing test order
  existingOrderId: '5923d90a-58d4-4e60-8494-2888a5ada2fb',
  existingOrderAmount: 63.00,
  
  // Test customer credentials (update with actual test credentials)
  testCustomerEmail: 'noatensai@gmail.com',
  testCustomerPassword: 'your_test_password_here', // Update this
  
  // Payment test data
  paymentMethod: 'credit_card',
  currency: 'myr'
};

// Browser-compatible test function
async function testPaymentProcessingFix() {
  console.log('🚀 Testing Payment Processing Fix...');
  
  try {
    // Check if we're in browser environment
    const isNode = typeof window === 'undefined';
    
    if (isNode) {
      console.log('❌ This script is designed to run in the browser console');
      console.log('📝 Instructions:');
      console.log('1. Open your GigaEats app in the browser');
      console.log('2. Open browser developer tools (F12)');
      console.log('3. Go to Console tab');
      console.log('4. Copy and paste this script');
      console.log('5. Update TEST_CONFIG.testCustomerPassword with actual password');
      console.log('6. Run the script');
      return;
    }
    
    // Check if Supabase is available
    if (typeof window.supabase === 'undefined') {
      console.log('❌ Supabase client not found in window.supabase');
      console.log('💡 Make sure you\'re on a page where Supabase is loaded');
      return;
    }
    
    const supabase = window.supabase;
    
    // Step 1: Check current authentication status
    console.log('🔍 Checking authentication status...');
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError) {
      console.log('❌ Auth error:', authError);
      return;
    }
    
    if (!user) {
      console.log('🔐 No user authenticated. Please sign in first.');
      console.log('📝 You can sign in through the app UI or use:');
      console.log(`supabase.auth.signInWithPassword({email: '${TEST_CONFIG.testCustomerEmail}', password: 'your_password'})`);
      return;
    }
    
    console.log('✅ User authenticated:', user.email);
    console.log('🆔 User ID:', user.id);
    
    // Step 2: Check if user has a customer profile
    console.log('👤 Checking customer profile...');
    const { data: customerProfile, error: profileError } = await supabase
      .from('customer_profiles')
      .select('id, full_name')
      .eq('user_id', user.id)
      .single();
    
    if (profileError) {
      console.log('❌ Customer profile error:', profileError);
      return;
    }
    
    console.log('✅ Customer profile found:', customerProfile.full_name);
    console.log('🆔 Customer ID:', customerProfile.id);
    
    // Step 3: Test order access (should work with our fix)
    console.log('📦 Testing order access...');
    const { data: orders, error: ordersError } = await supabase
      .from('orders')
      .select('id, order_number, total_amount, status, payment_status')
      .eq('customer_id', customerProfile.id)
      .limit(5);
    
    if (ordersError) {
      console.log('❌ Orders access error:', ordersError);
      return;
    }
    
    console.log(`✅ Can access ${orders.length} orders`);
    if (orders.length > 0) {
      console.log('📋 Recent orders:', orders.map(o => `${o.order_number} (${o.status})`));
    }
    
    // Step 4: Test payment processing for an existing order
    const testOrderId = orders.length > 0 ? orders[0].id : TEST_CONFIG.existingOrderId;
    const testAmount = orders.length > 0 ? orders[0].total_amount : TEST_CONFIG.existingOrderAmount;
    
    console.log(`💳 Testing payment processing for order: ${testOrderId}`);
    console.log(`💰 Amount: RM${testAmount}`);
    
    const paymentResponse = await supabase.functions.invoke('process-payment', {
      body: {
        order_id: testOrderId,
        amount: parseFloat(testAmount),
        currency: TEST_CONFIG.currency,
        payment_method: TEST_CONFIG.paymentMethod
      }
    });
    
    console.log('💳 Payment response status:', paymentResponse.status);
    console.log('💳 Payment response data:', paymentResponse.data);
    
    if (paymentResponse.error) {
      console.log('❌ Payment error:', paymentResponse.error);
    }
    
    // Analyze results
    if (paymentResponse.status === 200 && paymentResponse.data?.success) {
      console.log('🎉 SUCCESS! Payment processing works correctly');
      console.log('✅ Client secret received:', paymentResponse.data.client_secret ? 'Yes' : 'No');
      console.log('✅ Transaction ID:', paymentResponse.data.transaction_id);
    } else if (paymentResponse.data?.error === 'Access denied to this order') {
      console.log('❌ FAILED! Still getting access denied error');
      console.log('🔧 The fix may not be working correctly');
    } else {
      console.log('ℹ️ Unexpected response - check the details above');
    }
    
  } catch (error) {
    console.error('❌ Test error:', error);
  }
}

// Instructions for manual testing
console.log('📋 Payment Processing Fix Verification');
console.log('=====================================');
console.log('');
console.log('🔧 SETUP INSTRUCTIONS:');
console.log('1. Make sure you\'re signed in as a customer');
console.log('2. Update TEST_CONFIG.testCustomerPassword if needed');
console.log('3. Run: testPaymentProcessingFix()');
console.log('');
console.log('✅ EXPECTED SUCCESS INDICATORS:');
console.log('- User authenticated successfully');
console.log('- Customer profile found');
console.log('- Can access customer orders');
console.log('- Payment processing returns success with client_secret');
console.log('');
console.log('❌ FAILURE INDICATORS:');
console.log('- "Access denied to this order" error');
console.log('- Cannot access customer orders');
console.log('- Authentication or profile issues');
console.log('');
console.log('🚀 Run the test with: testPaymentProcessingFix()');

// Export for Node.js if needed
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { testPaymentProcessingFix, TEST_CONFIG };
}
