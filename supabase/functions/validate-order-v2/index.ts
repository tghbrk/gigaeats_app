import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface OrderItem {
  menu_item_id: string
  quantity: number
  unit_price: number
  customizations?: Record<string, any>
  notes?: string
}

interface OrderData {
  vendor_id: string
  customer_id: string
  sales_agent_id?: string
  delivery_date: string
  delivery_address: any
  items: OrderItem[]
  special_instructions?: string
  contact_phone?: string
}

interface ValidationResult {
  isValid: boolean
  errors: string[]
  warnings: string[]
  calculatedTotals?: {
    subtotal: number
    delivery_fee: number
    sst_amount: number
    total_amount: number
  }
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('🚀🚀🚀 validate-order-v2 function called - ENHANCED VERSION v10 - SERVICE ROLE FIX 🚀🚀🚀')
    console.log('📅 Timestamp:', new Date().toISOString())
    console.log('🌐 Request method:', req.method)
    console.log('🔗 Request URL:', req.url)

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    console.log('🔑 Supabase client initialized with service role')
    console.log('🔗 Supabase URL:', Deno.env.get('SUPABASE_URL'))

    // Get the authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('No authorization header')
    }

    // Verify the JWT token
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)

    if (authError || !user) {
      console.error('❌ Auth error:', authError)
      throw new Error('Invalid authentication token')
    }

    console.log('✅ User authenticated:', user.id)

    const { orderData }: { orderData: OrderData } = await req.json()
    console.log('📦 Order data received:', JSON.stringify(orderData, null, 2))
    
    // Validate order data
    const validationResult = await validateOrderData(supabaseClient, orderData, user.id)
    
    if (!validationResult.isValid) {
      console.log('❌ Validation failed:', validationResult.errors)
      return new Response(
        JSON.stringify({ 
          success: false, 
          errors: validationResult.errors,
          warnings: validationResult.warnings 
        }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // If valid, create order in database
    const order = await createOrderInDatabase(supabaseClient, orderData, validationResult.calculatedTotals!, user.id)
    console.log('✅ Order created successfully:', order.id)
    
    return new Response(
      JSON.stringify({ 
        success: true, 
        order,
        warnings: validationResult.warnings 
      }), 
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  } catch (error) {
    console.error('❌ Order validation error:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

async function validateOrderData(
  supabase: any, 
  orderData: OrderData, 
  userId: string
): Promise<ValidationResult> {
  const errors: string[] = []
  const warnings: string[] = []

  console.log('🔍 Starting validation for customer:', orderData.customer_id)

  // Basic validation
  if (!orderData.vendor_id) {
    errors.push('Vendor ID is required')
  }
  
  if (!orderData.customer_id) {
    errors.push('Customer ID is required')
  }
  
  if (!orderData.items || orderData.items.length === 0) {
    errors.push('Order must contain at least one item')
  }

  if (!orderData.delivery_date) {
    errors.push('Delivery date is required')
  }

  // Validate delivery date is not in the past
  const deliveryDate = new Date(orderData.delivery_date)
  const now = new Date()
  if (deliveryDate < now) {
    errors.push('Delivery date cannot be in the past')
  }

  // Validate vendor exists and is active
  console.log('🏪 Querying vendor:', orderData.vendor_id)
  const { data: vendor, error: vendorError } = await supabase
    .from('vendors')
    .select('id, business_name, is_active, minimum_order_amount')
    .eq('id', orderData.vendor_id)
    .single()

  console.log('🏪 Vendor query result:', vendor, vendorError)

  if (vendorError || !vendor) {
    console.log('❌ Vendor not found or error:', vendorError)
    errors.push('Vendor not found')
  } else if (!vendor.is_active) {
    console.log('❌ Vendor is inactive')
    errors.push('Vendor is currently inactive')
  } else {
    console.log('✅ Vendor found:', vendor.business_name, 'Min order:', vendor.minimum_order_amount)
  }

  // Validate customer exists (check both customers and customer_profiles tables)
  let customer = null

  console.log(`🔍 Validating customer ID: ${orderData.customer_id}`)

  // First try customers table (for business customers)
  console.log('🏢 Checking business customers table...')
  const { data: businessCustomer, error: businessError } = await supabase
    .from('customers')
    .select('id, organization_name as name')
    .eq('id', orderData.customer_id)
    .single()

  console.log(`🏢 Business customer query result:`, businessCustomer, businessError)

  if (businessCustomer) {
    customer = businessCustomer
    console.log(`✅ Found business customer: ${businessCustomer.name}`)
  } else {
    // Try customer_profiles table (for individual customers)
    console.log('👤 Checking customer_profiles table...')
    const { data: individualCustomer, error: individualError } = await supabase
      .from('customer_profiles')
      .select('id, full_name as name')
      .eq('id', orderData.customer_id)
      .single()

    console.log(`👤 Individual customer query result:`, individualCustomer, individualError)

    if (individualCustomer) {
      customer = individualCustomer
      console.log(`✅ Found individual customer: ${individualCustomer.name}`)
    } else {
      console.log(`❌ Individual customer error:`, individualError)
    }
  }

  if (!customer) {
    console.log(`❌ Customer not found for ID: ${orderData.customer_id}`)
    errors.push('Customer not found')
  }

  // Continue with rest of validation...
  let subtotal = 0
  const menuItemIds = orderData.items.map(item => item.menu_item_id)
  
  console.log('🍽️ Querying menu items:', menuItemIds)
  const { data: menuItems, error: menuError } = await supabase
    .from('menu_items')
    .select('id, name, base_price, is_available, stock_quantity, track_inventory, vendor_id')
    .in('id', menuItemIds)

  console.log('🍽️ Menu items query result:', menuItems, menuError)

  if (menuError) {
    errors.push('Error validating menu items')
  } else {
    for (const orderItem of orderData.items) {
      const menuItem = menuItems.find(mi => mi.id === orderItem.menu_item_id)
      
      if (!menuItem) {
        errors.push(`Menu item ${orderItem.menu_item_id} not found`)
        continue
      }

      if (menuItem.vendor_id !== orderData.vendor_id) {
        errors.push(`Menu item ${menuItem.name} does not belong to the selected vendor`)
        continue
      }

      if (!menuItem.is_available) {
        errors.push(`Menu item ${menuItem.name} is currently unavailable`)
        continue
      }

      if (menuItem.track_inventory && menuItem.stock_quantity < orderItem.quantity) {
        errors.push(`Insufficient stock for ${menuItem.name} (Available: ${menuItem.stock_quantity}, Requested: ${orderItem.quantity})`)
        continue
      }

      if (orderItem.quantity <= 0) {
        errors.push(`Invalid quantity for ${menuItem.name}`)
        continue
      }

      // Validate unit price matches menu item price
      if (Math.abs(orderItem.unit_price - menuItem.base_price) > 0.01) {
        warnings.push(`Price mismatch for ${menuItem.name}. Using current menu price: RM${menuItem.base_price}`)
        orderItem.unit_price = menuItem.base_price
      }

      subtotal += orderItem.unit_price * orderItem.quantity
    }
  }

  console.log(`💰 Calculated subtotal: RM${subtotal}`)

  // Calculate delivery fee
  const delivery_fee = calculateDeliveryFee(subtotal)
  
  // Calculate SST (6% in Malaysia)
  const sst_amount = subtotal * 0.06
  
  // Calculate total
  const total_amount = subtotal + delivery_fee + sst_amount

  console.log(`📊 Totals - Subtotal: RM${subtotal}, Delivery: RM${delivery_fee}, SST: RM${sst_amount}, Total: RM${total_amount}`)

  // Check minimum order amount
  if (vendor && subtotal < vendor.minimum_order_amount) {
    console.log(`❌ Order amount (RM${subtotal.toFixed(2)}) is below minimum (RM${vendor.minimum_order_amount})`)
    errors.push(`Order amount (RM${subtotal.toFixed(2)}) is below minimum order amount (RM${vendor.minimum_order_amount})`)
  } else if (vendor) {
    console.log(`✅ Order amount (RM${subtotal.toFixed(2)}) meets minimum (RM${vendor.minimum_order_amount})`)
  }

  console.log(`🎯 Validation result - Valid: ${errors.length === 0}, Errors: ${errors.length}, Warnings: ${warnings.length}`)

  return {
    isValid: errors.length === 0,
    errors,
    warnings,
    calculatedTotals: {
      subtotal,
      delivery_fee,
      sst_amount,
      total_amount
    }
  }
}

async function createOrderInDatabase(
  supabase: any,
  orderData: OrderData,
  totals: any,
  userId: string
) {
  console.log('💾 Creating order in database')
  console.log('🔑 Using service role client to bypass RLS')

  // Create a service role client to bypass RLS
  const serviceRoleClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  // Start a transaction
  const { data: order, error: orderError } = await serviceRoleClient
    .from('orders')
    .insert({
      vendor_id: orderData.vendor_id,
      customer_id: orderData.customer_id,
      sales_agent_id: orderData.sales_agent_id || null, // Don't set customer as sales agent
      delivery_date: orderData.delivery_date,
      delivery_address: orderData.delivery_address,
      subtotal: totals.subtotal,
      delivery_fee: totals.delivery_fee,
      sst_amount: totals.sst_amount,
      total_amount: totals.total_amount,
      special_instructions: orderData.special_instructions,
      contact_phone: orderData.contact_phone,
      status: 'pending',
      payment_status: 'pending'
    })
    .select()
    .single()

  if (orderError) {
    console.error('❌ Failed to create order:', orderError)
    throw new Error(`Failed to create order: ${orderError.message}`)
  }

  console.log('✅ Order created with ID:', order.id)

  // Insert order items
  const orderItems = orderData.items.map(item => ({
    order_id: order.id,
    menu_item_id: item.menu_item_id,
    name: '', // Will be populated by trigger
    unit_price: item.unit_price,
    quantity: item.quantity,
    total_price: item.unit_price * item.quantity,
    customizations: item.customizations || {},
    notes: item.notes
  }))

  const { error: itemsError } = await serviceRoleClient
    .from('order_items')
    .insert(orderItems)

  if (itemsError) {
    console.error('❌ Failed to create order items:', itemsError)
    // Rollback order creation
    await serviceRoleClient.from('orders').delete().eq('id', order.id)
    throw new Error(`Failed to create order items: ${itemsError.message}`)
  }

  console.log('✅ Order items created successfully')
  return order
}

function calculateDeliveryFee(subtotal: number): number {
  // Malaysian delivery fee calculation
  if (subtotal >= 200) return 0.0 // Free delivery for orders above RM 200
  if (subtotal >= 100) return 5.0 // RM 5 for orders above RM 100
  return 10.0 // RM 10 for smaller orders
}
