// Test script to directly call the validate-order-v2 Edge Function
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://abknoalhfltlhhdbclpv.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNDIxOTEsImV4cCI6MjA2MzkxODE5MX0.NAThyz5_xSTkWX7pynS7APPFZUnOc8DyjMN2K-cTt-g';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testEdgeFunction() {
  try {
    console.log('🚀 Testing validate-order-v2 Edge Function...');
    
    // Test validate-order-v2 function directly
    console.log('🧪 Testing validate-order-v2 function...');

    const orderData = {
      vendor_id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', // Test vendor ID
      customer_id: 'bd2d035b-9052-462b-b60f-84d215b19b1f', // The customer ID from the error
      delivery_date: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // Tomorrow
      delivery_address: {
        street: '123 Test Street',
        city: 'Kuala Lumpur',
        state: 'Selangor',
        postal_code: '50000',
        country: 'Malaysia'
      },
      items: [
        {
          menu_item_id: 'test-menu-item-1',
          quantity: 2,
          unit_price: 15.50,
          customizations: {},
          notes: 'Test order item'
        }
      ],
      special_instructions: 'Test order from Edge Function test',
      contact_phone: '+60123456789'
    };

    const validateResponse = await supabase.functions.invoke('validate-order-v2', {
      body: { orderData }
    });

    console.log('🧪 Validate function response status:', validateResponse.status);
    console.log('🧪 Validate function response data:', JSON.stringify(validateResponse.data, null, 2));
    console.log('🧪 Validate function response error:', validateResponse.error);

    return;
    
  } catch (error) {
    console.error('❌ Test error:', error);
  }
}

testEdgeFunction();
