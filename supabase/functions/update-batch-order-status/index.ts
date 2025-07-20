import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface BatchOrderStatusRequest {
  batchId: string;
  orderId: string;
  statusType: 'pickup' | 'delivery';
  status: 'pending' | 'in_progress' | 'completed' | 'failed';
  metadata?: {
    location?: {
      latitude: number;
      longitude: number;
    };
    photoUrl?: string;
    notes?: string;
    timestamp?: string;
  };
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
    const { batchId, orderId, statusType, status, metadata }: BatchOrderStatusRequest = await req.json()

    console.log(`🚛 [BATCH-ORDER-STATUS] Updating ${statusType} status for order ${orderId} to ${status}`)

    // Validate input parameters
    if (!batchId || !orderId || !statusType || !status) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters: batchId, orderId, statusType, and status' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const validStatusTypes = ['pickup', 'delivery']
    if (!validStatusTypes.includes(statusType)) {
      return new Response(
        JSON.stringify({ error: `Invalid statusType. Must be one of: ${validStatusTypes.join(', ')}` }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const validStatuses = ['pending', 'in_progress', 'completed', 'failed']
    if (!validStatuses.includes(status)) {
      return new Response(
        JSON.stringify({ error: `Invalid status. Must be one of: ${validStatuses.join(', ')}` }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Verify batch order exists
    const { data: batchOrder, error: batchOrderError } = await supabaseClient
      .from('batch_orders')
      .select('*')
      .eq('batch_id', batchId)
      .eq('order_id', orderId)
      .single()

    if (batchOrderError || !batchOrder) {
      return new Response(
        JSON.stringify({ error: 'Batch order not found' }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Verify batch is active
    const { data: batch, error: batchError } = await supabaseClient
      .from('delivery_batches')
      .select('status')
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

    if (batch.status !== 'active') {
      return new Response(
        JSON.stringify({ error: 'Batch must be active to update order status' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const now = new Date().toISOString()
    const updateData: any = {
      updated_at: now,
    }

    // Update the appropriate status field
    if (statusType === 'pickup') {
      updateData.pickup_status = status
      if (status === 'completed') {
        updateData.actual_pickup_time = now
        
        // Update main order status to picked up
        await supabaseClient
          .from('orders')
          .update({
            status: 'picked_up',
            updated_at: now,
          })
          .eq('id', orderId)
      }
    } else if (statusType === 'delivery') {
      updateData.delivery_status = status
      if (status === 'completed') {
        updateData.actual_delivery_time = now
        
        // Update main order status to delivered
        await supabaseClient
          .from('orders')
          .update({
            status: 'delivered',
            updated_at: now,
          })
          .eq('id', orderId)
      }
    }

    // Add metadata if provided
    if (metadata) {
      updateData.metadata = metadata
    }

    // Update batch order status
    const { data: updatedBatchOrder, error: updateError } = await supabaseClient
      .from('batch_orders')
      .update(updateData)
      .eq('batch_id', batchId)
      .eq('order_id', orderId)
      .select()
      .single()

    if (updateError) {
      console.error('❌ [BATCH-ORDER-STATUS] Error updating batch order status:', updateError)
      return new Response(
        JSON.stringify({ error: 'Failed to update batch order status' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // If this was a delivery completion, check if batch can be completed
    if (statusType === 'delivery' && status === 'completed') {
      await checkBatchCompletion(supabaseClient, batchId)
    }

    console.log(`✅ [BATCH-ORDER-STATUS] ${statusType} status updated successfully for order ${orderId}`)

    return new Response(
      JSON.stringify({
        success: true,
        batchOrder: updatedBatchOrder,
        message: `${statusType} status updated successfully`
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('❌ [BATCH-ORDER-STATUS] Unexpected error:', error)
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

async function checkBatchCompletion(supabaseClient: any, batchId: string) {
  try {
    // Get all batch orders
    const { data: batchOrders } = await supabaseClient
      .from('batch_orders')
      .select('delivery_status')
      .eq('batch_id', batchId)

    if (!batchOrders) return

    // Check if all deliveries are completed
    const allDelivered = batchOrders.every((bo: any) => bo.delivery_status === 'completed')

    if (allDelivered) {
      console.log(`🎉 [BATCH-ORDER-STATUS] All orders delivered, completing batch: ${batchId}`)
      
      // Auto-complete the batch
      await supabaseClient
        .from('delivery_batches')
        .update({
          status: 'completed',
          actual_completion_time: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq('id', batchId)
    }
  } catch (error) {
    console.error('❌ [BATCH-ORDER-STATUS] Error checking batch completion:', error)
  }
}
