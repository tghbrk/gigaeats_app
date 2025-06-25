// Test script to verify delivery_method fix in Edge Function
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://abknoalhfltlhhdbclpv.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzMzMDI0MDAsImV4cCI6MjA0ODg3ODQwMH0.mGOBYIMnGOBYIMnGOBYIMnGOBYIMnGOBYIMnGOBYIMn'

const supabase = createClient(supabaseUrl, supabaseKey)

async function testDeliveryMethodFix() {
  console.log('🧪 Testing delivery_method fix in Edge Function...')

  try {
    // Get a vendor and customer for testing
    const { data: vendors } = await supabase
      .from('vendors')
      .select('id, business_name')
      .limit(1)

    const { data: customers } = await supabase
      .from('customers')
      .select('id, name')
      .limit(1)

    if (!vendors?.length || !customers?.length) {
      console.error('❌ No vendors or customers found for testing')
      return
    }

    const vendor = vendors[0]
    const customer = customers[0]

    console.log(`📦 Using vendor: ${vendor.business_name} (${vendor.id})`)
    console.log(`👤 Using customer: ${customer.name} (${customer.id})`)

    // Create test order data with own_fleet delivery method
    const orderData = {
      vendor_id: vendor.id,
      customer_id: customer.id,
      delivery_method: 'own_fleet', // This is the key field we're testing
      delivery_date: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
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
          quantity: 1,
          unit_price: 25.00,
          customizations: {},
          notes: 'Test order for delivery method fix'
        }
      ],
      special_instructions: 'Test order to verify own_fleet delivery method is saved correctly',
      contact_phone: '+60123456789'
    }

    console.log('🚀 Calling validate-order-v3 Edge Function...')
    console.log('📋 Order data:', JSON.stringify(orderData, null, 2))

    // Call the Edge Function
    const { data, error } = await supabase.functions.invoke('validate-order-v3', {
      body: { orderData }
    })

    if (error) {
      console.error('❌ Edge Function error:', error)
      return
    }

    if (!data.success) {
      console.error('❌ Order validation failed:', data.errors)
      return
    }

    const createdOrder = data.order
    console.log('✅ Order created successfully!')
    console.log(`📋 Order ID: ${createdOrder.id}`)
    console.log(`📋 Order Number: ${createdOrder.order_number}`)
    console.log(`🚚 Delivery Method: ${createdOrder.delivery_method}`)

    // Verify the order was created with correct delivery_method
    const { data: orderFromDB } = await supabase
      .from('orders')
      .select('id, order_number, delivery_method, status')
      .eq('id', createdOrder.id)
      .single()

    if (orderFromDB) {
      console.log('🔍 Verification from database:')
      console.log(`   - Order ID: ${orderFromDB.id}`)
      console.log(`   - Order Number: ${orderFromDB.order_number}`)
      console.log(`   - Delivery Method: ${orderFromDB.delivery_method}`)
      console.log(`   - Status: ${orderFromDB.status}`)

      if (orderFromDB.delivery_method === 'own_fleet') {
        console.log('✅ SUCCESS: delivery_method was saved correctly as "own_fleet"!')

        // Now update the order status to 'ready' to test driver availability
        console.log('🔄 Updating order status to "ready" for driver testing...')

        const { error: updateError } = await supabase
          .from('orders')
          .update({ status: 'ready' })
          .eq('id', createdOrder.id)

        if (updateError) {
          console.error('❌ Failed to update order status:', updateError)
        } else {
          console.log('✅ Order status updated to "ready"')
          console.log('🚗 This order should now appear in driver Available Orders tab!')
        }
      } else {
        console.log(`❌ FAILED: delivery_method was saved as "${orderFromDB.delivery_method}" instead of "own_fleet"`)
      }
    } else {
      console.log('❌ Could not verify order from database')
    }

  } catch (error) {
    console.error('❌ Test failed with error:', error)
  }
}

// Run the test
testDeliveryMethodFix()