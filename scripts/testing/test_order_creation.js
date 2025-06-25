// Test script to debug delivery method classification
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://abknoalhfltlhhdbclpv.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia25vYWxoZmx0bGhoZGJjbHB2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczNDM0NzI5NCwiZXhwIjoyMDQ5OTIzMjk0fQ.Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8'

const supabase = createClient(supabaseUrl, supabaseKey)

async function debugDeliveryMethod() {
  console.log('🔍 Starting delivery method debug...')

  // Test 1: Check if delivery_method column exists
  console.log('\n📋 Test 1: Checking orders table schema...')
  try {
    const { data, error } = await supabase
      .from('orders')
      .select('id, delivery_method, metadata')
      .limit(1)

    if (error) {
      console.error('❌ Error querying orders table:', error)
      return
    }

    console.log('✅ Successfully queried orders table')
    console.log('Sample data:', data)
  } catch (e) {
    console.error('❌ Exception querying orders table:', e)
    return
  }

  // Test 2: Check existing orders for delivery_method values
  console.log('\n📋 Test 2: Checking existing orders...')
  try {
    const { data: existingOrders, error } = await supabase
      .from('orders')
      .select('id, delivery_method, metadata, status')
      .limit(5)

    if (error) {
      console.error('❌ Error fetching existing orders:', error)
    } else {
      console.log('✅ Found existing orders:')
      existingOrders.forEach(order => {
        console.log(`  Order ${order.id}:`)
        console.log(`    delivery_method: ${order.delivery_method}`)
        console.log(`    metadata: ${JSON.stringify(order.metadata)}`)
        console.log(`    status: ${order.status}`)
      })
    }
  } catch (e) {
    console.error('❌ Exception fetching existing orders:', e)
  }

  // Test 3: Create a test order with own_fleet
  console.log('\n📋 Test 3: Creating test order with own_fleet...')
  
  const testOrderData = {
    vendor_id: '550e8400-e29b-41d4-a716-446655440000', // Use a valid UUID format
    customer_id: '550e8400-e29b-41d4-a716-446655440001',
    sales_agent_id: '550e8400-e29b-41d4-a716-446655440002',
    delivery_method: 'own_fleet', // Explicitly set to own_fleet
    delivery_date: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(), // 2 hours from now
    delivery_address: {
      street: '123 Test Street',
      city: 'Kuala Lumpur',
      state: 'Selangor',
      postal_code: '50000',
      country: 'Malaysia'
    },
    subtotal: 25.00,
    delivery_fee: 5.00,
    sst_amount: 1.50,
    total_amount: 31.50,
    status: 'pending',
    payment_status: 'pending',
    metadata: {
      delivery_method: 'own_fleet', // Also store in metadata
      test_order: true
    }
  }

  console.log('Creating order with delivery_method:', testOrderData.delivery_method)

  try {
    const { data: createdOrder, error } = await supabase
      .from('orders')
      .insert(testOrderData)
      .select()
      .single()

    if (error) {
      console.error('❌ Error creating test order:', error)
      return
    }

    console.log('✅ Test order created successfully!')
    console.log('Order ID:', createdOrder.id)
    console.log('Stored delivery_method:', createdOrder.delivery_method)
    console.log('Stored metadata:', JSON.stringify(createdOrder.metadata))

    // Test 4: Retrieve the order to verify storage
    console.log('\n📋 Test 4: Retrieving order to verify storage...')
    
    const { data: retrievedOrder, error: retrieveError } = await supabase
      .from('orders')
      .select('*')
      .eq('id', createdOrder.id)
      .single()

    if (retrieveError) {
      console.error('❌ Error retrieving order:', retrieveError)
    } else {
      console.log('✅ Order retrieved successfully!')
      console.log('Retrieved delivery_method:', retrievedOrder.delivery_method)
      console.log('Retrieved metadata:', JSON.stringify(retrievedOrder.metadata))
      
      // Test the classification logic
      console.log('\n📋 Test 5: Testing classification logic...')
      
      const deliveryMethodValue = retrievedOrder.delivery_method
      console.log('Raw delivery_method value:', deliveryMethodValue)
      console.log('Type of delivery_method:', typeof deliveryMethodValue)
      console.log('Is delivery_method null?', deliveryMethodValue === null)
      console.log('Is delivery_method undefined?', deliveryMethodValue === undefined)
      console.log('Is delivery_method empty string?', deliveryMethodValue === '')
      
      if (deliveryMethodValue === 'own_fleet') {
        console.log('✅ delivery_method is correctly stored as own_fleet')
        console.log('✅ This should NOT be classified as a pickup order')
      } else if (deliveryMethodValue === null || deliveryMethodValue === undefined) {
        console.log('❌ delivery_method is null/undefined - will default to customerPickup')
        console.log('❌ This explains why orders are being classified as pickup')
      } else {
        console.log('⚠️ delivery_method has unexpected value:', deliveryMethodValue)
      }

      // Test metadata fallback
      const metadataDeliveryMethod = retrievedOrder.metadata?.delivery_method
      console.log('Metadata delivery_method:', metadataDeliveryMethod)
      
      if (metadataDeliveryMethod === 'own_fleet') {
        console.log('✅ Metadata contains correct delivery_method')
      }
    }

    // Clean up test order
    console.log('\n🧹 Cleaning up test order...')
    const { error: deleteError } = await supabase
      .from('orders')
      .delete()
      .eq('id', createdOrder.id)

    if (deleteError) {
      console.error('❌ Error deleting test order:', deleteError)
    } else {
      console.log('✅ Test order cleaned up successfully')
    }

  } catch (e) {
    console.error('❌ Exception during test order creation:', e)
  }

  console.log('\n🎯 Debug Summary:')
  console.log('This test checks:')
  console.log('1. If delivery_method column exists in the database')
  console.log('2. How existing orders store delivery_method')
  console.log('3. If new orders store delivery_method correctly')
  console.log('4. The actual values being stored and retrieved')
  console.log('5. Why the classification might be failing')
}

// Run the debug function
debugDeliveryMethod().catch(console.error)
