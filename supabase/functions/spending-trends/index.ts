import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface SpendingTrendsRequest {
  user_id: string
  period: 'daily' | 'weekly' | 'monthly'
  start_date?: string
  end_date?: string
  limit?: number
}

interface TrendDataPoint {
  date_period: string
  daily_spent: number
  daily_transactions: number
  running_balance: number
  category_breakdown: Record<string, number>
}

interface SpendingTrendsResponse {
  success: boolean
  data?: TrendDataPoint[]
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
    const requestData: SpendingTrendsRequest = await req.json()
    const { user_id, period, start_date, end_date, limit } = requestData

    // Verify user can access this data (RLS compliance)
    if (user.id !== user_id) {
      throw new Error('Access denied: Cannot access other user data')
    }

    console.log(`🔍 [SPENDING-TRENDS] Processing trends for user: ${user_id}, period: ${period}`)

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
        default:
          startDate = new Date(endDate.getTime() - 30 * 24 * 60 * 60 * 1000)
      }
    }

    // Get user's wallet
    const { data: wallet, error: walletError } = await supabaseClient
      .from('stakeholder_wallets')
      .select('id')
      .eq('user_id', user_id)
      .single()

    if (walletError || !wallet) {
      throw new Error('Wallet not found')
    }

    // Get spending trends data
    const trends = await getSpendingTrends(
      supabaseClient,
      user_id,
      wallet.id,
      startDate,
      endDate,
      period,
      limit
    )

    console.log(`✅ [SPENDING-TRENDS] Trends calculated successfully: ${trends.length} data points`)

    const response: SpendingTrendsResponse = {
      success: true,
      data: trends,
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('❌ [SPENDING-TRENDS] Error:', error)
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

async function getSpendingTrends(
  supabaseClient: any,
  userId: string,
  walletId: string,
  startDate: Date,
  endDate: Date,
  period: string,
  limit?: number
): Promise<TrendDataPoint[]> {
  console.log(`🔍 [SPENDING-TRENDS] Calculating trends from ${startDate.toISOString()} to ${endDate.toISOString()}`)

  // Get all transactions in the period
  const { data: transactions, error: transactionsError } = await supabaseClient
    .from('wallet_transactions')
    .select(`
      id,
      transaction_type,
      amount,
      balance_after,
      reference_type,
      reference_id,
      created_at,
      metadata
    `)
    .eq('wallet_id', walletId)
    .gte('created_at', startDate.toISOString())
    .lte('created_at', endDate.toISOString())
    .order('created_at', { ascending: true })

  if (transactionsError) {
    throw new Error(`Failed to fetch transactions: ${transactionsError.message}`)
  }

  // Group transactions by period
  const groupedData = new Map<string, {
    date: Date
    transactions: any[]
    totalSpent: number
    transactionCount: number
    balance: number
    categoryBreakdown: Record<string, number>
  }>()

  // Initialize date periods
  const currentDate = new Date(startDate)
  while (currentDate <= endDate) {
    const periodKey = getPeriodKey(currentDate, period)
    
    if (!groupedData.has(periodKey)) {
      groupedData.set(periodKey, {
        date: new Date(currentDate),
        transactions: [],
        totalSpent: 0,
        transactionCount: 0,
        balance: 0,
        categoryBreakdown: {}
      })
    }

    // Increment date based on period
    switch (period) {
      case 'daily':
        currentDate.setDate(currentDate.getDate() + 1)
        break
      case 'weekly':
        currentDate.setDate(currentDate.getDate() + 7)
        break
      case 'monthly':
        currentDate.setMonth(currentDate.getMonth() + 1)
        break
    }
  }

  // Process transactions
  for (const transaction of transactions) {
    const transactionDate = new Date(transaction.created_at)
    const periodKey = getPeriodKey(transactionDate, period)
    
    const periodData = groupedData.get(periodKey)
    if (periodData) {
      periodData.transactions.push(transaction)
      
      // Only count spending transactions (negative amounts)
      if (transaction.amount < 0 &&
          ['debit'].includes(transaction.transaction_type)) {
        periodData.totalSpent += Math.abs(transaction.amount)
        periodData.transactionCount += 1

        // Categorize spending
        const category = categorizeTransaction(transaction)
        periodData.categoryBreakdown[category] = 
          (periodData.categoryBreakdown[category] || 0) + Math.abs(transaction.amount)
      }
      
      // Update balance (use the latest balance in the period)
      if (transaction.balance_after !== null) {
        periodData.balance = transaction.balance_after
      }
    }
  }

  // Convert to trend data points
  const trendData: TrendDataPoint[] = []
  
  for (const [periodKey, data] of groupedData.entries()) {
    trendData.push({
      date_period: data.date.toISOString().split('T')[0],
      daily_spent: data.totalSpent,
      daily_transactions: data.transactionCount,
      running_balance: data.balance,
      category_breakdown: data.categoryBreakdown
    })
  }

  // Sort by date
  trendData.sort((a, b) => new Date(a.date_period).getTime() - new Date(b.date_period).getTime())

  // Apply limit if specified
  if (limit && limit > 0) {
    return trendData.slice(-limit) // Get the most recent data points
  }

  return trendData
}

function getPeriodKey(date: Date, period: string): string {
  switch (period) {
    case 'daily':
      return date.toISOString().split('T')[0] // YYYY-MM-DD
    case 'weekly':
      // Get Monday of the week
      const monday = new Date(date)
      monday.setDate(date.getDate() - date.getDay() + 1)
      return `${monday.getFullYear()}-W${getWeekNumber(monday)}`
    case 'monthly':
      return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`
    default:
      return date.toISOString().split('T')[0]
  }
}

function getWeekNumber(date: Date): number {
  const firstDayOfYear = new Date(date.getFullYear(), 0, 1)
  const pastDaysOfYear = (date.getTime() - firstDayOfYear.getTime()) / 86400000
  return Math.ceil((pastDaysOfYear + firstDayOfYear.getDay() + 1) / 7)
}

function categorizeTransaction(transaction: any): string {
  // Categorize based on reference_type and metadata
  if (transaction.reference_type === 'order') {
    return 'food_orders'
  } else if (transaction.reference_type === 'wallet_transfer') {
    return 'transfers'
  } else if (transaction.reference_type === 'wallet_topup') {
    return 'top_ups'
  } else if (transaction.transaction_type === 'payment') {
    return 'payments'
  } else {
    return 'other'
  }
}
