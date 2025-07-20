import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CreateBatchRequest {
  driverId: string;
  orderIds: string[];
  maxOrders?: number;
  maxDeviationKm?: number;
}

interface RouteOptimization {
  pickupSequence: string[];
  deliverySequence: string[];
  totalDistanceKm: number;
  estimatedDurationMinutes: number;
  optimizationScore: number;
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Parse request body
    const { driverId, orderIds, maxOrders = 3, maxDeviationKm = 5.0 }: CreateBatchRequest = await req.json()

    console.log('🚛 [CREATE-BATCH] Creating batch for driver:', driverId)
    console.log('🚛 [CREATE-BATCH] Order IDs:', orderIds)

    // 1. Validate input parameters
    if (!driverId || !orderIds || orderIds.length === 0) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters: driverId and orderIds' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    if (orderIds.length > maxOrders) {
      return new Response(
        JSON.stringify({ error: `Too many orders for batch (max: ${maxOrders})` }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 2. Validate driver availability
    const { data: driver, error: driverError } = await supabaseClient
      .from('drivers')
      .select('id, status, is_active')
      .eq('id', driverId)
      .single()

    if (driverError || !driver) {
      return new Response(
        JSON.stringify({ error: 'Driver not found' }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    if (!driver.is_active) {
      return new Response(
        JSON.stringify({ error: 'Driver is not active' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Check if driver already has an active batch
    const { data: activeBatch } = await supabaseClient
      .from('delivery_batches')
      .select('id')
      .eq('driver_id', driverId)
      .in('status', ['planned', 'active', 'paused'])
      .limit(1)

    if (activeBatch && activeBatch.length > 0) {
      return new Response(
        JSON.stringify({ error: 'Driver already has an active batch' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 3. Validate orders are eligible for batching
    const { data: orders, error: ordersError } = await supabaseClient
      .from('orders')
      .select('id, status, delivery_address, assigned_driver_id')
      .in('id', orderIds)

    if (ordersError || !orders || orders.length !== orderIds.length) {
      return new Response(
        JSON.stringify({ error: 'Some orders not found' }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Check all orders are ready and unassigned
    for (const order of orders) {
      if (order.status !== 'ready') {
        return new Response(
          JSON.stringify({ error: `Order ${order.id} is not ready for pickup` }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }
      if (order.assigned_driver_id) {
        return new Response(
          JSON.stringify({ error: `Order ${order.id} is already assigned to a driver` }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }
    }

    // 4. Get driver location for route optimization
    const { data: driverLocation } = await supabaseClient
      .from('driver_locations')
      .select('latitude, longitude')
      .eq('driver_id', driverId)
      .order('updated_at', { ascending: false })
      .limit(1)

    if (!driverLocation || driverLocation.length === 0) {
      return new Response(
        JSON.stringify({ error: 'Unable to determine driver location' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 5. Calculate optimized route (simplified version)
    const routeOptimization = calculateSimpleRoute(orders, driverLocation[0])

    // 6. Create batch in database
    const batchId = generateBatchId()
    const batchNumber = generateBatchNumber()
    const now = new Date().toISOString()

    // Create batch record
    const { data: batch, error: batchError } = await supabaseClient
      .from('delivery_batches')
      .insert({
        id: batchId,
        driver_id: driverId,
        batch_number: batchNumber,
        status: 'planned',
        total_distance_km: routeOptimization.totalDistanceKm,
        estimated_duration_minutes: routeOptimization.estimatedDurationMinutes,
        optimization_score: routeOptimization.optimizationScore,
        max_orders: maxOrders,
        max_deviation_km: maxDeviationKm,
        created_at: now,
        updated_at: now,
      })
      .select()
      .single()

    if (batchError) {
      console.error('❌ [CREATE-BATCH] Error creating batch:', batchError)
      return new Response(
        JSON.stringify({ error: 'Failed to create batch' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Create batch order records
    const batchOrdersData = orderIds.map((orderId, index) => ({
      id: generateBatchOrderId(),
      batch_id: batchId,
      order_id: orderId,
      pickup_sequence: index + 1,
      delivery_sequence: index + 1, // Simplified: same sequence for now
      pickup_status: 'pending',
      delivery_status: 'pending',
      created_at: now,
      updated_at: now,
    }))

    const { error: batchOrdersError } = await supabaseClient
      .from('batch_orders')
      .insert(batchOrdersData)

    if (batchOrdersError) {
      console.error('❌ [CREATE-BATCH] Error creating batch orders:', batchOrdersError)
      // Rollback batch creation
      await supabaseClient.from('delivery_batches').delete().eq('id', batchId)
      return new Response(
        JSON.stringify({ error: 'Failed to create batch orders' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Update orders to assigned status
    const { error: updateOrdersError } = await supabaseClient
      .from('orders')
      .update({
        status: 'assigned',
        assigned_driver_id: driverId,
        updated_at: now,
      })
      .in('id', orderIds)

    if (updateOrdersError) {
      console.error('❌ [CREATE-BATCH] Error updating orders:', updateOrdersError)
    }

    console.log('✅ [CREATE-BATCH] Batch created successfully:', batchId)

    return new Response(
      JSON.stringify({
        success: true,
        batch: batch,
        message: 'Batch created successfully'
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('❌ [CREATE-BATCH] Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

// Helper functions

function calculateSimpleRoute(orders: any[], driverLocation: any): RouteOptimization {
  // Simplified route optimization
  // In a real implementation, this would use Google Directions API or similar
  
  const totalDistanceKm = orders.length * 5 // Simplified: 5km per order
  const estimatedDurationMinutes = orders.length * 30 // Simplified: 30min per order
  const optimizationScore = Math.max(0, 100 - (totalDistanceKm * 2)) // Penalize longer routes
  
  return {
    pickupSequence: orders.map(order => order.id),
    deliverySequence: orders.map(order => order.id),
    totalDistanceKm,
    estimatedDurationMinutes,
    optimizationScore,
  }
}

function generateBatchId(): string {
  return `batch_${Date.now()}_${Math.floor(Math.random() * 1000)}`
}

function generateBatchNumber(): string {
  const now = new Date()
  const year = now.getFullYear()
  const month = (now.getMonth() + 1).toString().padStart(2, '0')
  const day = now.getDate().toString().padStart(2, '0')
  const random = Math.floor(Math.random() * 9999).toString().padStart(4, '0')
  return `B${year}${month}${day}-${random}`
}

function generateBatchOrderId(): string {
  return `bo_${Date.now()}_${Math.floor(Math.random() * 1000)}`
}
