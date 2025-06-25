import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface OrderCompletionRequest {
  order_id: string
  completion_type: 'delivered' | 'picked_up' | 'cancelled' | 'refunded'
  completed_by?: string
  completion_notes?: string
  force_release?: boolean
}

interface OrderCompletionResult {
  success: boolean
  order_id: string
  escrow_released: boolean
  funds_distributed: boolean
  total_distributed?: number
  error_message?: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get user from JWT token (optional for system calls)
    let userId = 'system'
    const authHeader = req.headers.get('Authorization')
    
    if (authHeader && !authHeader.includes('Bearer ' + Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'))) {
      const { data: { user }, error: userError } = await supabaseClient.auth.getUser(
        authHeader.replace('Bearer ', '')
      )
      
      if (user) {
        userId = user.id
      }
    }

    const completionRequest: OrderCompletionRequest = await req.json()
    
    console.log(`📦 Processing order completion: ${completionRequest.order_id} - ${completionRequest.completion_type}`)

    // Validate request
    if (!completionRequest.order_id || !completionRequest.completion_type) {
      throw new Error('Missing required fields: order_id, completion_type')
    }

    // Process order completion
    const result = await processOrderCompletion(supabaseClient, completionRequest, userId)
    
    console.log(`✅ Order completion processed: ${result.order_id}`)
    
    return new Response(
      JSON.stringify(result), 
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('❌ Order completion error:', error)
    
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

async function processOrderCompletion(
  supabase: any,
  request: OrderCompletionRequest,
  userId: string
): Promise<OrderCompletionResult> {
  
  // Get order details
  const { data: order, error: orderError } = await supabase
    .from('orders')
    .select(`
      id, status, payment_status, delivery_method,
      total_amount, created_at
    `)
    .eq('id', request.order_id)
    .single()

  if (orderError || !order) {
    throw new Error(`Order not found: ${orderError?.message}`)
  }

  // Validate order state
  if (order.payment_status !== 'paid' && !request.force_release) {
    throw new Error('Cannot complete order that has not been paid')
  }

  let escrowReleased = false
  let fundsDistributed = false
  let totalDistributed = 0

  try {
    // Update order status based on completion type
    const newOrderStatus = getOrderStatusFromCompletion(request.completion_type)
    
    const { error: orderUpdateError } = await supabase
      .from('orders')
      .update({
        status: newOrderStatus,
        actual_delivery_time: request.completion_type === 'delivered' ? new Date().toISOString() : null,
        updated_at: new Date().toISOString()
      })
      .eq('id', request.order_id)

    if (orderUpdateError) {
      throw new Error(`Failed to update order status: ${orderUpdateError.message}`)
    }

    console.log(`📦 Order ${request.order_id} status updated to: ${newOrderStatus}`)

    // Handle escrow release based on completion type
    if (request.completion_type === 'delivered' || request.completion_type === 'picked_up') {
      const escrowResult = await handleEscrowRelease(supabase, request.order_id, request.completion_type, userId)
      escrowReleased = escrowResult.released
      fundsDistributed = escrowResult.distributed
      totalDistributed = escrowResult.total_distributed || 0
    } else if (request.completion_type === 'cancelled' || request.completion_type === 'refunded') {
      await handleOrderRefund(supabase, request.order_id, request.completion_type, userId)
    }

    // Award loyalty points for delivered orders
    let loyaltyPointsResult = null
    if (request.completion_type === 'delivered') {
      try {
        loyaltyPointsResult = await awardLoyaltyPoints(supabase, request.order_id, order.customer_id)
        console.log(`🎯 Loyalty points awarded for order ${request.order_id}: ${loyaltyPointsResult?.total_points || 0} points`)
      } catch (loyaltyError) {
        console.error(`⚠️ Failed to award loyalty points for order ${request.order_id}:`, loyaltyError)
        // Don't fail the order completion if loyalty points fail
        // This will be logged for manual review
      }
    }

    // Log order completion
    await logFinancialAudit(supabase, {
      event_type: 'order_completed',
      entity_type: 'order',
      entity_id: request.order_id,
      user_id: userId,
      amount: order.total_amount,
      old_status: order.status,
      new_status: newOrderStatus,
      description: `Order ${request.completion_type} by ${request.completed_by || 'system'}`,
      metadata: {
        completion_type: request.completion_type,
        completed_by: request.completed_by,
        completion_notes: request.completion_notes,
        escrow_released: escrowReleased,
        funds_distributed: fundsDistributed,
        total_distributed: totalDistributed
      }
    })

    return {
      success: true,
      order_id: request.order_id,
      escrow_released,
      funds_distributed,
      total_distributed: totalDistributed > 0 ? totalDistributed : undefined,
      loyalty_points: loyaltyPointsResult ? {
        points_awarded: loyaltyPointsResult.points_awarded,
        tier_multiplier: loyaltyPointsResult.tier_multiplier,
        bonus_points: loyaltyPointsResult.bonus_points,
        total_points: loyaltyPointsResult.total_points,
        new_tier: loyaltyPointsResult.new_tier,
        tier_upgraded: loyaltyPointsResult.tier_upgraded
      } : undefined
    }

  } catch (error) {
    console.error('Order completion processing failed:', error)
    throw error
  }
}

async function handleEscrowRelease(
  supabase: any,
  orderId: string,
  completionType: string,
  userId: string
): Promise<{ released: boolean; distributed: boolean; total_distributed?: number }> {
  
  // Find escrow account for this order
  const { data: escrowAccount, error: escrowError } = await supabase
    .from('escrow_accounts')
    .select('id, status, total_amount, release_trigger')
    .eq('order_id', orderId)
    .single()

  if (escrowError || !escrowAccount) {
    console.log(`No escrow account found for order ${orderId}`)
    return { released: false, distributed: false }
  }

  if (escrowAccount.status !== 'held') {
    console.log(`Escrow account ${escrowAccount.id} is not in 'held' status: ${escrowAccount.status}`)
    return { released: false, distributed: false }
  }

  // Check if release trigger matches completion type
  const shouldRelease = (
    escrowAccount.release_trigger === 'order_delivered' ||
    escrowAccount.release_trigger === 'auto_release' ||
    completionType === 'picked_up' // Always release for pickup orders
  )

  if (!shouldRelease) {
    console.log(`Escrow release trigger (${escrowAccount.release_trigger}) does not match completion type (${completionType})`)
    return { released: false, distributed: false }
  }

  try {
    // Call fund distribution function
    const response = await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/distribute-escrow-funds`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        escrow_account_id: escrowAccount.id,
        release_reason: 'order_delivered'
      })
    })

    if (!response.ok) {
      throw new Error(`Fund distribution failed: ${response.statusText}`)
    }

    const distributionResult = await response.json()

    if (distributionResult.success) {
      console.log(`✅ Funds released from escrow ${escrowAccount.id}: ${distributionResult.total_distributed} MYR`)
      return {
        released: true,
        distributed: true,
        total_distributed: distributionResult.total_distributed
      }
    } else {
      throw new Error(`Fund distribution failed: ${distributionResult.error}`)
    }

  } catch (error) {
    console.error('Error releasing escrow funds:', error)
    return { released: false, distributed: false }
  }
}

async function handleOrderRefund(
  supabase: any,
  orderId: string,
  refundType: string,
  userId: string
): Promise<void> {
  
  // Find escrow account for this order
  const { data: escrowAccount, error: escrowError } = await supabase
    .from('escrow_accounts')
    .select('id, status, total_amount')
    .eq('order_id', orderId)
    .single()

  if (escrowError || !escrowAccount) {
    console.log(`No escrow account found for order ${orderId}`)
    return
  }

  if (escrowAccount.status === 'refunded') {
    console.log(`Escrow account ${escrowAccount.id} already refunded`)
    return
  }

  try {
    // Update escrow status to refunded
    const { error: escrowUpdateError } = await supabase
      .from('escrow_accounts')
      .update({
        status: 'refunded',
        updated_at: new Date().toISOString()
      })
      .eq('id', escrowAccount.id)

    if (escrowUpdateError) {
      throw new Error(`Failed to update escrow status: ${escrowUpdateError.message}`)
    }

    // In production, initiate actual refund to customer's payment method
    // For now, just log the refund
    await logFinancialAudit(supabase, {
      event_type: 'order_refunded',
      entity_type: 'escrow_account',
      entity_id: escrowAccount.id,
      user_id: userId,
      amount: escrowAccount.total_amount,
      old_status: escrowAccount.status,
      new_status: 'refunded',
      description: `Order ${refundType} - funds marked for refund`,
      metadata: {
        order_id: orderId,
        refund_type: refundType,
        refund_amount: escrowAccount.total_amount
      }
    })

    console.log(`💰 Escrow ${escrowAccount.id} marked for refund: ${escrowAccount.total_amount} MYR`)

  } catch (error) {
    console.error('Error handling order refund:', error)
    throw error
  }
}

async function awardLoyaltyPoints(
  supabase: any,
  orderId: string,
  customerId: string
): Promise<any> {
  try {
    console.log(`🎯 Awarding loyalty points for order ${orderId} to customer ${customerId}`)

    // Call loyalty points calculator Edge Function
    const response = await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/loyalty-points-calculator`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        action: 'process_order_completion',
        order_id: orderId,
        customer_id: customerId
      })
    })

    if (!response.ok) {
      throw new Error(`Loyalty points calculation failed: ${response.statusText}`)
    }

    const result = await response.json()

    if (!result.success) {
      throw new Error(`Loyalty points calculation failed: ${result.error || 'Unknown error'}`)
    }

    console.log(`✅ Loyalty points awarded successfully: ${result.total_points} points`)
    return result
  } catch (error) {
    console.error(`❌ Error awarding loyalty points:`, error)
    throw error
  }
}

function getOrderStatusFromCompletion(completionType: string): string {
  switch (completionType) {
    case 'delivered':
      return 'delivered'
    case 'picked_up':
      return 'delivered'
    case 'cancelled':
      return 'cancelled'
    case 'refunded':
      return 'cancelled'
    default:
      return 'completed'
  }
}

async function logFinancialAudit(
  supabase: any,
  auditData: {
    event_type: string
    entity_type: string
    entity_id: string
    user_id: string
    amount?: number
    old_status?: string
    new_status?: string
    description?: string
    metadata?: Record<string, any>
  }
): Promise<void> {
  
  try {
    await supabase
      .from('financial_audit_log')
      .insert({
        event_type: auditData.event_type,
        entity_type: auditData.entity_type,
        entity_id: auditData.entity_id,
        user_id: auditData.user_id,
        amount: auditData.amount,
        currency: 'MYR',
        old_status: auditData.old_status,
        new_status: auditData.new_status,
        description: auditData.description,
        metadata: auditData.metadata || {},
        created_at: new Date().toISOString()
      })
  } catch (error) {
    console.error('Failed to log financial audit:', error)
    // Don't throw error - audit logging failure shouldn't break order completion
  }
}
