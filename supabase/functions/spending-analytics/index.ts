import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface SpendingAnalyticsRequest {
  user_id: string
  start_date?: string
  end_date?: string
  period: 'daily' | 'weekly' | 'monthly' | 'yearly'
}

interface SpendingAnalyticsResponse {
  success: boolean
  data?: any
  error?: string
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

    // Verify user authentication
    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser()

    if (authError || !user) {
      throw new Error('Unauthorized')
    }

    // Parse request body
    const requestData: SpendingAnalyticsRequest = await req.json()
    const { user_id, start_date, end_date, period } = requestData

    // Verify user can access this data (RLS compliance)
    if (user.id !== user_id) {
      throw new Error('Access denied: Cannot access other user data')
    }

    console.log(`🔍 [SPENDING-ANALYTICS] Processing analytics for user: ${user_id}, period: ${period}`)

    // Calculate date range if not provided
    const endDate = end_date ? new Date(end_date) : new Date()
    let startDate: Date

    if (start_date) {
      startDate = new Date(start_date)
    } else {
      // Default date ranges based on period
      switch (period) {
        case 'daily':
          startDate = new Date(endDate.getTime() - 30 * 24 * 60 * 60 * 1000) // Last 30 days
          break
        case 'weekly':
          startDate = new Date(endDate.getTime() - 12 * 7 * 24 * 60 * 60 * 1000) // Last 12 weeks
          break
        case 'monthly':
          startDate = new Date(endDate.getFullYear(), endDate.getMonth() - 12, 1) // Last 12 months
          break
        case 'yearly':
          startDate = new Date(endDate.getFullYear() - 5, 0, 1) // Last 5 years
          break
        default:
          startDate = new Date(endDate.getTime() - 30 * 24 * 60 * 60 * 1000)
      }
    }

    // Get user's wallet
    const { data: wallet, error: walletError } = await supabaseClient
      .from('stakeholder_wallets')
      .select('id, available_balance, currency')
      .eq('user_id', user_id)
      .single()

    if (walletError || !wallet) {
      throw new Error('Wallet not found')
    }

    // Get comprehensive spending analytics
    const analytics = await getSpendingAnalytics(
      supabaseClient,
      user_id,
      wallet.id,
      startDate,
      endDate,
      period
    )

    console.log(`✅ [SPENDING-ANALYTICS] Analytics calculated successfully`)

    const response: SpendingAnalyticsResponse = {
      success: true,
      data: {
        ...analytics,
        period_type: period,
        period_start: startDate.toISOString(),
        period_end: endDate.toISOString(),
        currency: wallet.currency,
        current_balance: wallet.available_balance,
      },
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('❌ [SPENDING-ANALYTICS] Error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Internal server error',
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})

async function getSpendingAnalytics(
  supabaseClient: any,
  userId: string,
  walletId: string,
  startDate: Date,
  endDate: Date,
  period: string
) {
  console.log(`🔍 [SPENDING-ANALYTICS] Calculating analytics from ${startDate.toISOString()} to ${endDate.toISOString()}`)

  // Get all transactions in the period
  const { data: transactions, error: transactionsError } = await supabaseClient
    .from('wallet_transactions')
    .select(`
      id,
      transaction_type,
      amount,
      currency,
      balance_before,
      balance_after,
      reference_type,
      reference_id,
      description,
      metadata,
      created_at,
      processed_at
    `)
    .eq('wallet_id', walletId)
    .gte('created_at', startDate.toISOString())
    .lte('created_at', endDate.toISOString())
    .order('created_at', { ascending: true })

  if (transactionsError) {
    throw new Error(`Failed to fetch transactions: ${transactionsError.message}`)
  }

  // Calculate spending metrics (only debit transactions for spending)
  const spendingTransactions = transactions.filter(t =>
    t.amount < 0 &&
    ['debit'].includes(t.transaction_type)
  )

  const topupTransactions = transactions.filter(t =>
    t.amount > 0 &&
    ['credit'].includes(t.transaction_type)
  )

  const transferOutTransactions = transactions.filter(t => 
    t.amount < 0 && 
    t.transaction_type === 'transfer_out'
  )

  const transferInTransactions = transactions.filter(t => 
    t.amount > 0 && 
    t.transaction_type === 'transfer_in'
  )

  // Calculate totals
  const totalSpent = Math.abs(spendingTransactions.reduce((sum, t) => sum + t.amount, 0))
  const totalToppedUp = topupTransactions.reduce((sum, t) => sum + t.amount, 0)
  const totalTransferredOut = Math.abs(transferOutTransactions.reduce((sum, t) => sum + t.amount, 0))
  const totalTransferredIn = transferInTransactions.reduce((sum, t) => sum + t.amount, 0)

  // Calculate averages
  const avgTransactionAmount = spendingTransactions.length > 0 
    ? totalSpent / spendingTransactions.length 
    : 0

  const avgTopupAmount = topupTransactions.length > 0 
    ? totalToppedUp / topupTransactions.length 
    : 0

  // Find min/max transaction amounts
  const spendingAmounts = spendingTransactions.map(t => Math.abs(t.amount))
  const maxTransactionAmount = spendingAmounts.length > 0 ? Math.max(...spendingAmounts) : 0
  const minTransactionAmount = spendingAmounts.length > 0 ? Math.min(...spendingAmounts) : 0

  // Calculate balance metrics
  const balances = transactions.map(t => t.balance_after).filter(b => b !== null)
  const avgBalance = balances.length > 0 ? balances.reduce((sum, b) => sum + b, 0) / balances.length : 0
  const maxBalance = balances.length > 0 ? Math.max(...balances) : 0
  const minBalance = balances.length > 0 ? Math.min(...balances) : 0

  const periodStartBalance = transactions.length > 0 ? transactions[0].balance_before || 0 : 0
  const periodEndBalance = transactions.length > 0 ? transactions[transactions.length - 1].balance_after || 0 : 0

  // Get unique vendors count from order payments
  const orderPayments = spendingTransactions.filter(t => 
    t.reference_type === 'order' && t.reference_id
  )

  let uniqueVendorsCount = 0
  let topVendorId = null
  let topVendorSpent = 0

  if (orderPayments.length > 0) {
    // Get order details to find vendors
    const orderIds = [...new Set(orderPayments.map(t => t.reference_id))]
    
    const { data: orders } = await supabaseClient
      .from('orders')
      .select('id, vendor_id, total_amount')
      .in('id', orderIds)

    if (orders) {
      const vendorSpending = new Map<string, number>()
      
      orders.forEach(order => {
        const spending = vendorSpending.get(order.vendor_id) || 0
        vendorSpending.set(order.vendor_id, spending + order.total_amount)
      })

      uniqueVendorsCount = vendorSpending.size
      
      // Find top vendor
      let maxSpending = 0
      for (const [vendorId, spending] of vendorSpending.entries()) {
        if (spending > maxSpending) {
          maxSpending = spending
          topVendorId = vendorId
          topVendorSpent = spending
        }
      }
    }
  }

  return {
    // Spending analytics
    total_spent: totalSpent,
    total_transactions: spendingTransactions.length,
    avg_transaction_amount: avgTransactionAmount,
    max_transaction_amount: maxTransactionAmount,
    min_transaction_amount: minTransactionAmount,
    
    // Top-up analytics
    total_topped_up: totalToppedUp,
    topup_transactions: topupTransactions.length,
    avg_topup_amount: avgTopupAmount,
    
    // Transfer analytics
    total_transferred_out: totalTransferredOut,
    total_transferred_in: totalTransferredIn,
    transfer_out_count: transferOutTransactions.length,
    transfer_in_count: transferInTransactions.length,
    
    // Balance analytics
    period_start_balance: periodStartBalance,
    period_end_balance: periodEndBalance,
    avg_balance: avgBalance,
    max_balance: maxBalance,
    min_balance: minBalance,
    
    // Vendor analytics
    unique_vendors_count: uniqueVendorsCount,
    top_vendor_id: topVendorId,
    top_vendor_spent: topVendorSpent,
    
    // Summary metrics
    net_change: periodEndBalance - periodStartBalance,
    total_activity: transactions.length,
  }
}
