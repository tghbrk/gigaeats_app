import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ManageBatchRequest {
  batchId: string;
  action: 'start' | 'pause' | 'resume' | 'complete' | 'cancel' | 'update_status' | 'add_order' | 'remove_order';
  orderId?: string; // For add/remove order actions
  newStatus?: 'planned' | 'active' | 'completed' | 'cancelled' | 'failed';
  driverLocation?: {
    latitude: number;
    longitude: number;
  };
  metadata?: Record<string, any>;
}

interface BatchManagementResult {
  success: boolean;
  batchId: string;
  action: string;
  newStatus?: string;
  message: string;
  data?: any;
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
      action, 
      orderId, 
      newStatus, 
      driverLocation,
      metadata = {}
    }: ManageBatchRequest = await req.json()

    console.log('🚛 [MANAGE-BATCH] Managing batch:', batchId)
    console.log('🚛 [MANAGE-BATCH] Action:', action)

    // 1. Validate input parameters
    if (!batchId || !action) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters: batchId and action' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 2. Get current batch details
    const { data: batch, error: batchError } = await supabaseClient
      .from('delivery_batches')
      .select(`
        id,
        driver_id,
        batch_number,
        status,
        total_distance_km,
        estimated_duration_minutes,
        optimization_score,
        max_orders,
        max_deviation_km,
        created_at,
        updated_at,
        batch_orders (
          order_id,
          pickup_sequence,
          delivery_sequence,
          status,
          orders (
            id,
            status,
            vendor_id,
            customer_id
          )
        )
      `)
      .eq('id', batchId)
      .single()

    if (batchError || !batch) {
      console.error('❌ [MANAGE-BATCH] Error fetching batch:', batchError)
      return new Response(
        JSON.stringify({ error: 'Batch not found' }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    console.log('🚛 [MANAGE-BATCH] Current batch status:', batch.status)

    let result: BatchManagementResult

    // 3. Execute the requested action
    switch (action) {
      case 'start':
        result = await startBatch(supabaseClient, batch, driverLocation)
        break
      case 'pause':
        result = await pauseBatch(supabaseClient, batch)
        break
      case 'resume':
        result = await resumeBatch(supabaseClient, batch)
        break
      case 'complete':
        result = await completeBatch(supabaseClient, batch)
        break
      case 'cancel':
        result = await cancelBatch(supabaseClient, batch)
        break
      case 'update_status':
        result = await updateBatchStatus(supabaseClient, batch, newStatus!)
        break
      case 'add_order':
        result = await addOrderToBatch(supabaseClient, batch, orderId!)
        break
      case 'remove_order':
        result = await removeOrderFromBatch(supabaseClient, batch, orderId!)
        break
      default:
        return new Response(
          JSON.stringify({ error: 'Invalid action' }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
    }

    // 4. Log the action
    await logBatchAction(supabaseClient, batchId, action, result, metadata)

    console.log('✅ [MANAGE-BATCH] Action completed successfully:', result.message)

    return new Response(
      JSON.stringify(result),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('❌ [MANAGE-BATCH] Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

// Action implementations

async function startBatch(
  supabaseClient: any, 
  batch: any, 
  driverLocation?: any
): Promise<BatchManagementResult> {
  if (batch.status !== 'planned') {
    return {
      success: false,
      batchId: batch.id,
      action: 'start',
      message: `Cannot start batch with status: ${batch.status}`
    }
  }

  const now = new Date().toISOString()

  // Update batch status to active
  const { error: updateError } = await supabaseClient
    .from('delivery_batches')
    .update({
      status: 'active',
      started_at: now,
      updated_at: now,
    })
    .eq('id', batch.id)

  if (updateError) {
    console.error('❌ Error starting batch:', updateError)
    return {
      success: false,
      batchId: batch.id,
      action: 'start',
      message: 'Failed to start batch'
    }
  }

  // Update driver location if provided
  if (driverLocation) {
    await supabaseClient
      .from('driver_locations')
      .upsert({
        driver_id: batch.driver_id,
        latitude: driverLocation.latitude,
        longitude: driverLocation.longitude,
        updated_at: now,
      })
  }

  return {
    success: true,
    batchId: batch.id,
    action: 'start',
    newStatus: 'active',
    message: 'Batch started successfully'
  }
}

async function pauseBatch(supabaseClient: any, batch: any): Promise<BatchManagementResult> {
  if (batch.status !== 'active') {
    return {
      success: false,
      batchId: batch.id,
      action: 'pause',
      message: `Cannot pause batch with status: ${batch.status}`
    }
  }

  const now = new Date().toISOString()

  const { error: updateError } = await supabaseClient
    .from('delivery_batches')
    .update({
      status: 'paused',
      paused_at: now,
      updated_at: now,
    })
    .eq('id', batch.id)

  if (updateError) {
    console.error('❌ Error pausing batch:', updateError)
    return {
      success: false,
      batchId: batch.id,
      action: 'pause',
      message: 'Failed to pause batch'
    }
  }

  return {
    success: true,
    batchId: batch.id,
    action: 'pause',
    newStatus: 'paused',
    message: 'Batch paused successfully'
  }
}

async function resumeBatch(supabaseClient: any, batch: any): Promise<BatchManagementResult> {
  if (batch.status !== 'paused') {
    return {
      success: false,
      batchId: batch.id,
      action: 'resume',
      message: `Cannot resume batch with status: ${batch.status}`
    }
  }

  const now = new Date().toISOString()

  const { error: updateError } = await supabaseClient
    .from('delivery_batches')
    .update({
      status: 'active',
      resumed_at: now,
      updated_at: now,
    })
    .eq('id', batch.id)

  if (updateError) {
    console.error('❌ Error resuming batch:', updateError)
    return {
      success: false,
      batchId: batch.id,
      action: 'resume',
      message: 'Failed to resume batch'
    }
  }

  return {
    success: true,
    batchId: batch.id,
    action: 'resume',
    newStatus: 'active',
    message: 'Batch resumed successfully'
  }
}

async function completeBatch(supabaseClient: any, batch: any): Promise<BatchManagementResult> {
  if (batch.status !== 'active') {
    return {
      success: false,
      batchId: batch.id,
      action: 'complete',
      message: `Cannot complete batch with status: ${batch.status}`
    }
  }

  const now = new Date().toISOString()

  // Check if all orders in batch are delivered
  const pendingOrders = batch.batch_orders.filter((batchOrder: any) => 
    batchOrder.orders.status !== 'delivered'
  )

  if (pendingOrders.length > 0) {
    return {
      success: false,
      batchId: batch.id,
      action: 'complete',
      message: `Cannot complete batch: ${pendingOrders.length} orders still pending delivery`
    }
  }

  const { error: updateError } = await supabaseClient
    .from('delivery_batches')
    .update({
      status: 'completed',
      completed_at: now,
      updated_at: now,
    })
    .eq('id', batch.id)

  if (updateError) {
    console.error('❌ Error completing batch:', updateError)
    return {
      success: false,
      batchId: batch.id,
      action: 'complete',
      message: 'Failed to complete batch'
    }
  }

  // Calculate and store performance metrics
  await calculateBatchPerformanceMetrics(supabaseClient, batch.id)

  return {
    success: true,
    batchId: batch.id,
    action: 'complete',
    newStatus: 'completed',
    message: 'Batch completed successfully'
  }
}

async function cancelBatch(supabaseClient: any, batch: any): Promise<BatchManagementResult> {
  if (batch.status === 'completed') {
    return {
      success: false,
      batchId: batch.id,
      action: 'cancel',
      message: 'Cannot cancel completed batch'
    }
  }

  const now = new Date().toISOString()

  const { error: updateError } = await supabaseClient
    .from('delivery_batches')
    .update({
      status: 'cancelled',
      cancelled_at: now,
      updated_at: now,
    })
    .eq('id', batch.id)

  if (updateError) {
    console.error('❌ Error cancelling batch:', updateError)
    return {
      success: false,
      batchId: batch.id,
      action: 'cancel',
      message: 'Failed to cancel batch'
    }
  }

  return {
    success: true,
    batchId: batch.id,
    action: 'cancel',
    newStatus: 'cancelled',
    message: 'Batch cancelled successfully'
  }
}

async function updateBatchStatus(
  supabaseClient: any, 
  batch: any, 
  newStatus: string
): Promise<BatchManagementResult> {
  const now = new Date().toISOString()

  const { error: updateError } = await supabaseClient
    .from('delivery_batches')
    .update({
      status: newStatus,
      updated_at: now,
    })
    .eq('id', batch.id)

  if (updateError) {
    console.error('❌ Error updating batch status:', updateError)
    return {
      success: false,
      batchId: batch.id,
      action: 'update_status',
      message: 'Failed to update batch status'
    }
  }

  return {
    success: true,
    batchId: batch.id,
    action: 'update_status',
    newStatus: newStatus,
    message: `Batch status updated to ${newStatus}`
  }
}

async function addOrderToBatch(
  supabaseClient: any, 
  batch: any, 
  orderId: string
): Promise<BatchManagementResult> {
  // Check if batch has room for more orders
  if (batch.batch_orders.length >= batch.max_orders) {
    return {
      success: false,
      batchId: batch.id,
      action: 'add_order',
      message: `Batch is at maximum capacity (${batch.max_orders} orders)`
    }
  }

  // Check if order is already in batch
  const existingOrder = batch.batch_orders.find((batchOrder: any) => 
    batchOrder.order_id === orderId
  )

  if (existingOrder) {
    return {
      success: false,
      batchId: batch.id,
      action: 'add_order',
      message: 'Order is already in this batch'
    }
  }

  const now = new Date().toISOString()

  // Add order to batch
  const { error: insertError } = await supabaseClient
    .from('batch_orders')
    .insert({
      batch_id: batch.id,
      order_id: orderId,
      pickup_sequence: batch.batch_orders.length + 1,
      delivery_sequence: batch.batch_orders.length + 1,
      status: 'pending',
      created_at: now,
      updated_at: now,
    })

  if (insertError) {
    console.error('❌ Error adding order to batch:', insertError)
    return {
      success: false,
      batchId: batch.id,
      action: 'add_order',
      message: 'Failed to add order to batch'
    }
  }

  return {
    success: true,
    batchId: batch.id,
    action: 'add_order',
    message: 'Order added to batch successfully',
    data: { orderId }
  }
}

async function removeOrderFromBatch(
  supabaseClient: any, 
  batch: any, 
  orderId: string
): Promise<BatchManagementResult> {
  // Check if order exists in batch
  const existingOrder = batch.batch_orders.find((batchOrder: any) => 
    batchOrder.order_id === orderId
  )

  if (!existingOrder) {
    return {
      success: false,
      batchId: batch.id,
      action: 'remove_order',
      message: 'Order not found in this batch'
    }
  }

  // Remove order from batch
  const { error: deleteError } = await supabaseClient
    .from('batch_orders')
    .delete()
    .eq('batch_id', batch.id)
    .eq('order_id', orderId)

  if (deleteError) {
    console.error('❌ Error removing order from batch:', deleteError)
    return {
      success: false,
      batchId: batch.id,
      action: 'remove_order',
      message: 'Failed to remove order from batch'
    }
  }

  return {
    success: true,
    batchId: batch.id,
    action: 'remove_order',
    message: 'Order removed from batch successfully',
    data: { orderId }
  }
}

// Helper functions

async function logBatchAction(
  supabaseClient: any,
  batchId: string,
  action: string,
  result: BatchManagementResult,
  metadata: Record<string, any>
) {
  try {
    await supabaseClient
      .from('batch_action_logs')
      .insert({
        batch_id: batchId,
        action: action,
        success: result.success,
        message: result.message,
        metadata: metadata,
        created_at: new Date().toISOString(),
      })
  } catch (error) {
    console.error('❌ Error logging batch action:', error)
  }
}

async function calculateBatchPerformanceMetrics(
  supabaseClient: any,
  batchId: string
) {
  try {
    // This would calculate actual performance metrics
    // For now, just log that metrics calculation was triggered
    console.log('📊 [MANAGE-BATCH] Calculating performance metrics for batch:', batchId)
  } catch (error) {
    console.error('❌ Error calculating performance metrics:', error)
  }
}
