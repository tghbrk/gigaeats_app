import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface FundDistributionRequest {
  escrow_account_id?: string
  order_id?: string
  release_reason: 'order_delivered' | 'manual_release' | 'auto_release' | 'dispute_resolved'
  force_release?: boolean
}

interface FundDistributionResult {
  success: boolean
  escrow_account_id: string
  distributions: WalletDistribution[]
  total_distributed: number
  error_message?: string
}

interface WalletDistribution {
  wallet_id: string
  user_id: string
  user_role: string
  amount: number
  transaction_type: string
  description: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client with service role key
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

    const distributionRequest: FundDistributionRequest = await req.json()
    
    console.log(`💰 Processing fund distribution request: ${JSON.stringify(distributionRequest)}`)

    // Validate request
    if (!distributionRequest.escrow_account_id && !distributionRequest.order_id) {
      throw new Error('Either escrow_account_id or order_id must be provided')
    }

    // Process fund distribution
    const result = await distributeFundsFromEscrow(supabaseClient, distributionRequest, userId)
    
    console.log(`✅ Fund distribution completed: ${result.total_distributed} MYR distributed`)
    
    return new Response(
      JSON.stringify(result), 
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('❌ Fund distribution error:', error)
    
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

async function distributeFundsFromEscrow(
  supabase: any,
  request: FundDistributionRequest,
  userId: string
): Promise<FundDistributionResult> {
  
  // Find escrow account
  let escrowQuery = supabase
    .from('escrow_accounts')
    .select(`
      id, order_id, total_amount, status, vendor_amount, platform_fee,
      sales_agent_commission, driver_commission, delivery_fee,
      release_trigger, release_date,
      orders!inner(
        id, vendor_id, sales_agent_id, assigned_driver_id, customer_id,
        vendors!inner(user_id),
        customers!inner(user_id)
      )
    `)

  if (request.escrow_account_id) {
    escrowQuery = escrowQuery.eq('id', request.escrow_account_id)
  } else {
    escrowQuery = escrowQuery.eq('order_id', request.order_id)
  }

  const { data: escrowAccount, error: escrowError } = await escrowQuery.single()

  if (escrowError || !escrowAccount) {
    throw new Error(`Escrow account not found: ${escrowError?.message}`)
  }

  // Validate escrow status
  if (escrowAccount.status !== 'held' && !request.force_release) {
    throw new Error(`Cannot distribute funds from escrow with status: ${escrowAccount.status}`)
  }

  // Check if funds have already been released
  if (escrowAccount.release_date && !request.force_release) {
    throw new Error('Funds have already been released from this escrow account')
  }

  console.log(`💰 Distributing ${escrowAccount.total_amount} MYR from escrow ${escrowAccount.id}`)

  const distributions: WalletDistribution[] = []
  let totalDistributed = 0

  try {
    // Start transaction
    const { data: transaction, error: transactionError } = await supabase.rpc('begin_transaction')
    
    if (transactionError) {
      throw new Error(`Failed to start transaction: ${transactionError.message}`)
    }

    // 1. Distribute to vendor
    if (escrowAccount.vendor_amount > 0) {
      const vendorDistribution = await distributeToWallet(
        supabase,
        escrowAccount.orders.vendors.user_id,
        'vendor',
        escrowAccount.vendor_amount,
        'commission',
        `Vendor earnings for order ${escrowAccount.order_id}`,
        escrowAccount.id
      )
      distributions.push(vendorDistribution)
      totalDistributed += escrowAccount.vendor_amount
    }

    // 2. Distribute to sales agent
    if (escrowAccount.sales_agent_commission > 0 && escrowAccount.orders.sales_agent_id) {
      const salesAgentDistribution = await distributeToWallet(
        supabase,
        escrowAccount.orders.sales_agent_id,
        'sales_agent',
        escrowAccount.sales_agent_commission,
        'commission',
        `Sales commission for order ${escrowAccount.order_id}`,
        escrowAccount.id
      )
      distributions.push(salesAgentDistribution)
      totalDistributed += escrowAccount.sales_agent_commission
    }

    // 3. Distribute to driver
    if (escrowAccount.driver_commission > 0 && escrowAccount.orders.assigned_driver_id) {
      // Get driver user_id
      const { data: driver, error: driverError } = await supabase
        .from('drivers')
        .select('user_id')
        .eq('id', escrowAccount.orders.assigned_driver_id)
        .single()

      if (!driverError && driver) {
        const driverDistribution = await distributeToWallet(
          supabase,
          driver.user_id,
          'driver',
          escrowAccount.driver_commission,
          'commission',
          `Driver earnings for order ${escrowAccount.order_id}`,
          escrowAccount.id
        )
        distributions.push(driverDistribution)
        totalDistributed += escrowAccount.driver_commission
      }
    }

    // 4. Platform fee goes to platform wallet (admin)
    if (escrowAccount.platform_fee > 0) {
      // Create or get platform wallet
      const platformDistribution = await distributeToWallet(
        supabase,
        'platform', // Special platform user ID
        'platform',
        escrowAccount.platform_fee,
        'commission',
        `Platform fee for order ${escrowAccount.order_id}`,
        escrowAccount.id
      )
      distributions.push(platformDistribution)
      totalDistributed += escrowAccount.platform_fee
    }

    // 5. Update escrow account status
    const { error: escrowUpdateError } = await supabase
      .from('escrow_accounts')
      .update({
        status: 'released',
        release_date: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', escrowAccount.id)

    if (escrowUpdateError) {
      throw new Error(`Failed to update escrow status: ${escrowUpdateError.message}`)
    }

    // 6. Log fund distribution
    await logFinancialAudit(supabase, {
      event_type: 'funds_distributed',
      entity_type: 'escrow_account',
      entity_id: escrowAccount.id,
      user_id: userId,
      amount: totalDistributed,
      old_status: 'held',
      new_status: 'released',
      description: `Funds distributed from escrow for order ${escrowAccount.order_id}`,
      metadata: {
        order_id: escrowAccount.order_id,
        release_reason: request.release_reason,
        distributions: distributions.map(d => ({
          user_role: d.user_role,
          amount: d.amount,
          transaction_type: d.transaction_type
        })),
        total_distributed: totalDistributed
      }
    })

    // Commit transaction
    await supabase.rpc('commit_transaction')

    console.log(`✅ Successfully distributed ${totalDistributed} MYR to ${distributions.length} wallets`)

    return {
      success: true,
      escrow_account_id: escrowAccount.id,
      distributions,
      total_distributed: totalDistributed
    }

  } catch (error) {
    // Rollback transaction
    await supabase.rpc('rollback_transaction')
    
    console.error('❌ Fund distribution failed, transaction rolled back:', error)
    throw error
  }
}

async function distributeToWallet(
  supabase: any,
  userId: string,
  userRole: string,
  amount: number,
  transactionType: string,
  description: string,
  escrowAccountId: string
): Promise<WalletDistribution> {
  
  // Get or create wallet
  let { data: wallet, error: walletError } = await supabase
    .from('stakeholder_wallets')
    .select('id, available_balance')
    .eq('user_id', userId)
    .eq('user_role', userRole)
    .single()

  if (walletError || !wallet) {
    // Create wallet if it doesn't exist
    const { data: newWallet, error: createError } = await supabase
      .from('stakeholder_wallets')
      .insert({
        user_id: userId,
        user_role: userRole,
        available_balance: 0,
        currency: 'MYR',
        is_active: true
      })
      .select('id, available_balance')
      .single()

    if (createError) {
      throw new Error(`Failed to create wallet for user ${userId}: ${createError.message}`)
    }

    wallet = newWallet
  }

  const balanceBefore = wallet.available_balance

  // Create wallet transaction (this will trigger the balance update via trigger)
  const { data: walletTransaction, error: transactionError } = await supabase
    .from('wallet_transactions')
    .insert({
      wallet_id: wallet.id,
      transaction_type: transactionType,
      amount: amount,
      balance_before: balanceBefore,
      balance_after: balanceBefore + amount,
      reference_type: 'escrow_release',
      reference_id: escrowAccountId,
      escrow_account_id: escrowAccountId,
      description: description,
      processed_by: 'system',
      processed_at: new Date().toISOString()
    })
    .select()
    .single()

  if (transactionError) {
    throw new Error(`Failed to create wallet transaction: ${transactionError.message}`)
  }

  console.log(`💳 Distributed ${amount} MYR to ${userRole} wallet ${wallet.id}`)

  return {
    wallet_id: wallet.id,
    user_id: userId,
    user_role: userRole,
    amount: amount,
    transaction_type: transactionType,
    description: description
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
    // Don't throw error - audit logging failure shouldn't break fund distribution
  }
}
