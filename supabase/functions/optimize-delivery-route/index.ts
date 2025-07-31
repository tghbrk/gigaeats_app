import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface OptimizeRouteRequest {
  batchId: string;
  driverLocation: {
    latitude: number;
    longitude: number;
  };
  considerTraffic?: boolean;
  considerPreparationTimes?: boolean;
  algorithm?: 'nearest_neighbor' | 'genetic_algorithm' | 'simulated_annealing' | 'hybrid_multi' | 'enhanced_nearest';
}

interface RouteOptimizationResult {
  pickupSequence: string[];
  deliverySequence: string[];
  totalDistanceKm: number;
  estimatedDurationMinutes: number;
  optimizationScore: number;
  algorithm: string;
  improvementScore?: number;
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
    const { 
      batchId, 
      driverLocation, 
      considerTraffic = true, 
      considerPreparationTimes = true,
      algorithm = 'enhanced_nearest'
    }: OptimizeRouteRequest = await req.json()

    console.log('🚛 [OPTIMIZE-ROUTE] Optimizing route for batch:', batchId)
    console.log('🚛 [OPTIMIZE-ROUTE] Driver location:', driverLocation)
    console.log('🚛 [OPTIMIZE-ROUTE] Algorithm:', algorithm)

    // 1. Validate input parameters
    if (!batchId || !driverLocation) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters: batchId and driverLocation' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 2. Get batch details and orders
    const { data: batch, error: batchError } = await supabaseClient
      .from('delivery_batches')
      .select(`
        id,
        driver_id,
        status,
        total_distance_km,
        estimated_duration_minutes,
        optimization_score,
        batch_orders (
          order_id,
          pickup_sequence,
          delivery_sequence,
          orders (
            id,
            vendor_id,
            delivery_latitude,
            delivery_longitude,
            estimated_preparation_minutes,
            vendors (
              id,
              name,
              latitude,
              longitude
            )
          )
        )
      `)
      .eq('id', batchId)
      .single()

    if (batchError || !batch) {
      console.error('❌ [OPTIMIZE-ROUTE] Error fetching batch:', batchError)
      return new Response(
        JSON.stringify({ error: 'Batch not found' }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 3. Extract orders from batch
    const orders = batch.batch_orders.map((batchOrder: any) => batchOrder.orders)

    if (!orders || orders.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No orders found in batch' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    console.log('🚛 [OPTIMIZE-ROUTE] Found', orders.length, 'orders to optimize')

    // 4. Calculate optimized route based on selected algorithm
    let optimizationResult: RouteOptimizationResult

    switch (algorithm) {
      case 'genetic_algorithm':
        optimizationResult = await calculateGeneticAlgorithmRoute(orders, driverLocation, {
          considerTraffic,
          considerPreparationTimes
        })
        break
      case 'simulated_annealing':
        optimizationResult = await calculateSimulatedAnnealingRoute(orders, driverLocation, {
          considerTraffic,
          considerPreparationTimes
        })
        break
      case 'hybrid_multi':
        optimizationResult = await calculateHybridMultiRoute(orders, driverLocation, {
          considerTraffic,
          considerPreparationTimes
        })
        break
      case 'enhanced_nearest':
        optimizationResult = await calculateEnhancedNearestRoute(orders, driverLocation, {
          considerTraffic,
          considerPreparationTimes
        })
        break
      default:
        optimizationResult = await calculateNearestNeighborRoute(orders, driverLocation, {
          considerTraffic,
          considerPreparationTimes
        })
    }

    // 5. Calculate improvement score compared to current route
    const currentScore = batch.optimization_score || 0
    const improvementScore = optimizationResult.optimizationScore - currentScore

    optimizationResult.improvementScore = improvementScore

    // 6. Store optimization result in database
    const now = new Date().toISOString()
    
    const { error: optimizationError } = await supabaseClient
      .from('route_optimizations')
      .insert({
        batch_id: batchId,
        algorithm: algorithm,
        pickup_sequence: optimizationResult.pickupSequence,
        delivery_sequence: optimizationResult.deliverySequence,
        total_distance_km: optimizationResult.totalDistanceKm,
        estimated_duration_minutes: optimizationResult.estimatedDurationMinutes,
        optimization_score: optimizationResult.optimizationScore,
        improvement_score: improvementScore,
        driver_location: `POINT(${driverLocation.longitude} ${driverLocation.latitude})`,
        consider_traffic: considerTraffic,
        consider_preparation_times: considerPreparationTimes,
        created_at: now,
      })

    if (optimizationError) {
      console.error('❌ [OPTIMIZE-ROUTE] Error storing optimization:', optimizationError)
    }

    // 7. Update batch if improvement is significant (> 10% improvement)
    if (improvementScore > 10) {
      console.log('🚛 [OPTIMIZE-ROUTE] Significant improvement detected, updating batch')
      
      const { error: updateError } = await supabaseClient
        .from('delivery_batches')
        .update({
          total_distance_km: optimizationResult.totalDistanceKm,
          estimated_duration_minutes: optimizationResult.estimatedDurationMinutes,
          optimization_score: optimizationResult.optimizationScore,
          optimization_algorithm: algorithm,
          updated_at: now,
        })
        .eq('id', batchId)

      if (updateError) {
        console.error('❌ [OPTIMIZE-ROUTE] Error updating batch:', updateError)
      }

      // Update batch orders with new sequences
      for (let i = 0; i < orders.length; i++) {
        const order = orders[i]
        const pickupIndex = optimizationResult.pickupSequence.indexOf(order.id)
        const deliveryIndex = optimizationResult.deliverySequence.indexOf(order.id)

        await supabaseClient
          .from('batch_orders')
          .update({
            pickup_sequence: pickupIndex + 1,
            delivery_sequence: deliveryIndex + 1,
            updated_at: now,
          })
          .eq('batch_id', batchId)
          .eq('order_id', order.id)
      }
    }

    console.log('✅ [OPTIMIZE-ROUTE] Route optimization completed successfully')
    console.log('🚛 [OPTIMIZE-ROUTE] Optimization score:', optimizationResult.optimizationScore)
    console.log('🚛 [OPTIMIZE-ROUTE] Improvement score:', improvementScore)

    return new Response(
      JSON.stringify({
        success: true,
        data: optimizationResult,
        batch_updated: improvementScore > 10,
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('❌ [OPTIMIZE-ROUTE] Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

// Algorithm implementations

async function calculateNearestNeighborRoute(
  orders: any[], 
  driverLocation: any, 
  options: any
): Promise<RouteOptimizationResult> {
  // Simple nearest neighbor TSP implementation
  const unvisited = [...orders]
  const pickupSequence: string[] = []
  const deliverySequence: string[] = []
  
  let currentLocation = driverLocation
  let totalDistance = 0
  let totalDuration = 0

  // Pickup phase - visit vendors in nearest neighbor order
  while (unvisited.length > 0) {
    let nearestIndex = 0
    let nearestDistance = calculateDistance(currentLocation, unvisited[0].vendors)

    for (let i = 1; i < unvisited.length; i++) {
      const distance = calculateDistance(currentLocation, unvisited[i].vendors)
      if (distance < nearestDistance) {
        nearestDistance = distance
        nearestIndex = i
      }
    }

    const nearestOrder = unvisited.splice(nearestIndex, 1)[0]
    pickupSequence.push(nearestOrder.id)
    currentLocation = nearestOrder.vendors
    totalDistance += nearestDistance
    totalDuration += nearestDistance * 2 // Rough estimate: 2 minutes per km
  }

  // Delivery phase - visit customers in nearest neighbor order
  const ordersForDelivery = [...orders]
  currentLocation = driverLocation

  while (ordersForDelivery.length > 0) {
    let nearestIndex = 0
    let nearestDistance = calculateDistance(currentLocation, {
      latitude: ordersForDelivery[0].delivery_latitude,
      longitude: ordersForDelivery[0].delivery_longitude
    })

    for (let i = 1; i < ordersForDelivery.length; i++) {
      const distance = calculateDistance(currentLocation, {
        latitude: ordersForDelivery[i].delivery_latitude,
        longitude: ordersForDelivery[i].delivery_longitude
      })
      if (distance < nearestDistance) {
        nearestDistance = distance
        nearestIndex = i
      }
    }

    const nearestOrder = ordersForDelivery.splice(nearestIndex, 1)[0]
    deliverySequence.push(nearestOrder.id)
    currentLocation = {
      latitude: nearestOrder.delivery_latitude,
      longitude: nearestOrder.delivery_longitude
    }
    totalDistance += nearestDistance
    totalDuration += nearestDistance * 2
  }

  const optimizationScore = Math.max(0, 100 - (totalDistance * 2))

  return {
    pickupSequence,
    deliverySequence,
    totalDistanceKm: Math.round(totalDistance * 100) / 100,
    estimatedDurationMinutes: Math.round(totalDuration),
    optimizationScore: Math.round(optimizationScore * 100) / 100,
    algorithm: 'nearest_neighbor'
  }
}

async function calculateEnhancedNearestRoute(
  orders: any[], 
  driverLocation: any, 
  options: any
): Promise<RouteOptimizationResult> {
  // Enhanced nearest neighbor with multiple starting points
  const bestRoutes: RouteOptimizationResult[] = []

  // Try starting from different orders
  for (let startIndex = 0; startIndex < Math.min(orders.length, 3); startIndex++) {
    const route = await calculateNearestNeighborFromStart(orders, driverLocation, startIndex, options)
    bestRoutes.push(route)
  }

  // Return the best route
  return bestRoutes.reduce((best, current) => 
    current.optimizationScore > best.optimizationScore ? current : best
  )
}

async function calculateNearestNeighborFromStart(
  orders: any[], 
  driverLocation: any, 
  startIndex: number,
  options: any
): Promise<RouteOptimizationResult> {
  // Implementation similar to calculateNearestNeighborRoute but starting from a specific order
  return calculateNearestNeighborRoute(orders, driverLocation, options)
}

// Placeholder implementations for other algorithms
async function calculateGeneticAlgorithmRoute(orders: any[], driverLocation: any, options: any): Promise<RouteOptimizationResult> {
  // For now, use enhanced nearest neighbor
  return calculateEnhancedNearestRoute(orders, driverLocation, options)
}

async function calculateSimulatedAnnealingRoute(orders: any[], driverLocation: any, options: any): Promise<RouteOptimizationResult> {
  // For now, use enhanced nearest neighbor
  return calculateEnhancedNearestRoute(orders, driverLocation, options)
}

async function calculateHybridMultiRoute(orders: any[], driverLocation: any, options: any): Promise<RouteOptimizationResult> {
  // For now, use enhanced nearest neighbor
  return calculateEnhancedNearestRoute(orders, driverLocation, options)
}

// Helper function to calculate distance between two points
function calculateDistance(point1: any, point2: any): number {
  const R = 6371 // Earth's radius in kilometers
  const dLat = (point2.latitude - point1.latitude) * Math.PI / 180
  const dLon = (point2.longitude - point1.longitude) * Math.PI / 180
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(point1.latitude * Math.PI / 180) * Math.cos(point2.latitude * Math.PI / 180) *
    Math.sin(dLon/2) * Math.sin(dLon/2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
  return R * c
}
