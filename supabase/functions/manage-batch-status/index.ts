import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface BatchStatusRequest {
  batchId: string;
  action: 'start' | 'pause' | 'resume' | 'complete' | 'cancel';
  reason?: string; // For cancellation
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
    const { batchId, action, reason }: BatchStatusRequest = await req.json()

    console.log(`🚛 [BATCH-STATUS] ${action.toUpperCase()} batch:`, batchId)

    // Validate input parameters
    if (!batchId || !action) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters: batchId and action' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const validActions = ['start', 'pause', 'resume', 'complete', 'cancel']
    if (!validActions.includes(action)) {
      return new Response(
        JSON.stringify({ error: `Invalid action. Must be one of: ${validActions.join(', ')}` }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Get current batch status
    const { data: batch, error: batchError } = await supabaseClient
      .from('delivery_batches')
      .select('id, status, driver_id')
      .eq('id', batchId)
      .single()

    if (batchError || !batch) {
      return new Response(
        JSON.stringify({ error: 'Batch not found' }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const now = new Date().toISOString()
    let updateData: any = {
      updated_at: now,
    }
    let statusValidation: string | null = null

    // Handle different actions
    switch (action) {
      case 'start':
        if (batch.status !== 'planned') {
          statusValidation = 'Batch can only be started if it is in planned status'
        } else {
          updateData.status = 'active'
          updateData.actual_start_time = now
          
          // Update all orders in batch to assigned status
          await updateBatchOrdersStatus(supabaseClient, batchId, 'assigned')
        }
        break

      case 'pause':
        if (batch.status !== 'active') {
          statusValidation = 'Batch can only be paused if it is currently active'
        } else {
          updateData.status = 'paused'
        }
        break

      case 'resume':
        if (batch.status !== 'paused') {
          statusValidation = 'Batch can only be resumed if it is currently paused'
        } else {
          updateData.status = 'active'
        }
        break

      case 'complete':
        if (!['active', 'paused'].includes(batch.status)) {
          statusValidation = 'Batch can only be completed if it is active or paused'
        } else {
          // Check if all orders in batch are delivered
          const { data: batchOrders } = await supabaseClient
            .from('batch_orders')
            .select('delivery_status')
            .eq('batch_id', batchId)

          const undeliveredOrders = batchOrders?.filter(bo => bo.delivery_status !== 'completed') || []
          
          if (undeliveredOrders.length > 0) {
            return new Response(
              JSON.stringify({ 
                error: `Cannot complete batch: ${undeliveredOrders.length} orders not yet delivered` 
              }),
              { 
                status: 400, 
                headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
              }
            )
          }

          updateData.status = 'completed'
          updateData.actual_completion_time = now
        }
        break

      case 'cancel':
        if (!['planned', 'active', 'paused'].includes(batch.status)) {
          statusValidation = 'Batch can only be cancelled if it is planned, active, or paused'
        } else {
          updateData.status = 'cancelled'
          if (reason) {
            updateData.metadata = { cancellation_reason: reason }
          }
          
          // Reset orders back to ready status
          await resetBatchOrdersToReady(supabaseClient, batchId)
        }
        break
    }

    // Check status validation
    if (statusValidation) {
      return new Response(
        JSON.stringify({ error: statusValidation }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Update batch status
    const { data: updatedBatch, error: updateError } = await supabaseClient
      .from('delivery_batches')
      .update(updateData)
      .eq('id', batchId)
      .select()
      .single()

    if (updateError) {
      console.error(`❌ [BATCH-STATUS] Error updating batch status:`, updateError)
      return new Response(
        JSON.stringify({ error: 'Failed to update batch status' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    console.log(`✅ [BATCH-STATUS] Batch ${action} successful:`, batchId)

    return new Response(
      JSON.stringify({
        success: true,
        batch: updatedBatch,
        message: `Batch ${action} successful`
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error(`❌ [BATCH-STATUS] Unexpected error:`, error)
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

async function updateBatchOrdersStatus(supabaseClient: any, batchId: string, status: string) {
  try {
    // Get order IDs from batch
    const { data: batchOrders } = await supabaseClient
      .from('batch_orders')
      .select('order_id')
      .eq('batch_id', batchId)

    if (batchOrders && batchOrders.length > 0) {
      const orderIds = batchOrders.map((row: any) => row.order_id)
      
      await supabaseClient
        .from('orders')
        .update({
          status: status,
          updated_at: new Date().toISOString(),
        })
        .in('id', orderIds)
    }
  } catch (error) {
    console.error('❌ [BATCH-STATUS] Error updating batch orders status:', error)
  }
}

async function resetBatchOrdersToReady(supabaseClient: any, batchId: string) {
  try {
    // Get order IDs from batch
    const { data: batchOrders } = await supabaseClient
      .from('batch_orders')
      .select('order_id')
      .eq('batch_id', batchId)

    if (batchOrders && batchOrders.length > 0) {
      const orderIds = batchOrders.map((row: any) => row.order_id)
      
      await supabaseClient
        .from('orders')
        .update({
          status: 'ready',
          assigned_driver_id: null,
          updated_at: new Date().toISOString(),
        })
        .in('id', orderIds)
    }
  } catch (error) {
    console.error('❌ [BATCH-STATUS] Error resetting batch orders to ready:', error)
  }
}
