import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface AnalyticsRequest {
  action: 'get_spending_analytics' | 'get_transaction_trends' | 'get_category_breakdown' | 
          'get_monthly_summary' | 'get_comparison_data' | 'export_analytics'
  wallet_id?: string
  period?: 'day' | 'week' | 'month' | 'quarter' | 'year'
  start_date?: string
  end_date?: string
  comparison_period?: string
  export_format?: 'json' | 'csv' | 'pdf'
}

interface AnalyticsResult {
  success: boolean
  data?: any
  error?: string
  metadata?: {
    period: string
    generated_at: string
    total_records: number
  }
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
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get user from JWT token
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)

    if (authError || !user) {
      throw new Error('Unauthorized: Invalid or missing authentication token')
    }

    const requestBody: AnalyticsRequest = await req.json()
    const { action } = requestBody

    let response: AnalyticsResult

    switch (action) {
      case 'get_spending_analytics':
        response = await getSpendingAnalytics(supabaseClient, user.id, requestBody)
        break
      case 'get_transaction_trends':
        response = await getTransactionTrends(supabaseClient, user.id, requestBody)
        break
      case 'get_category_breakdown':
        response = await getCategoryBreakdown(supabaseClient, user.id, requestBody)
        break
      case 'get_monthly_summary':
        response = await getMonthlySummary(supabaseClient, user.id, requestBody)
        break
      case 'get_comparison_data':
        response = await getComparisonData(supabaseClient, user.id, requestBody)
        break
      case 'export_analytics':
        response = await exportAnalytics(supabaseClient, user.id, requestBody)
        break
      default:
        throw new Error(`Unsupported action: ${action}`)
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    console.error('Wallet analytics error:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})

async function getSpendingAnalytics(
  supabase: any,
  userId: string,
  request: AnalyticsRequest
): Promise<AnalyticsResult> {
  try {
    const { wallet_id, period = 'month', start_date, end_date } = request

    // Get user's wallet if not specified
    let walletId = wallet_id
    if (!walletId) {
      const { data: wallet } = await supabase
        .from('stakeholder_wallets')
        .select('id')
        .eq('user_id', userId)
        .eq('user_role', 'customer')
        .single()
      
      walletId = wallet?.id
    }

    if (!walletId) {
      throw new Error('Wallet not found')
    }

    // Calculate date range
    const dateRange = calculateDateRange(period, start_date, end_date)

    // Get spending transactions
    const { data: transactions, error: transactionError } = await supabase
      .from('wallet_transactions')
      .select(`
        id,
        amount,
        transaction_type,
        reference_type,
        reference_id,
        description,
        created_at,
        metadata
      `)
      .eq('wallet_id', walletId)
      .lt('amount', 0) // Only debit transactions (spending)
      .gte('created_at', dateRange.start)
      .lte('created_at', dateRange.end)
      .order('created_at', { ascending: false })

    if (transactionError) {
      throw new Error(`Failed to fetch transactions: ${transactionError.message}`)
    }

    // Calculate analytics
    const totalSpent = transactions.reduce((sum, t) => sum + Math.abs(t.amount), 0)
    const transactionCount = transactions.length
    const averageTransaction = transactionCount > 0 ? totalSpent / transactionCount : 0

    // Group by transaction type
    const spendingByType = transactions.reduce((acc, t) => {
      const type = t.transaction_type || 'other'
      acc[type] = (acc[type] || 0) + Math.abs(t.amount)
      return acc
    }, {} as Record<string, number>)

    // Group by reference type (order, transfer, etc.)
    const spendingByCategory = transactions.reduce((acc, t) => {
      const category = t.reference_type || 'other'
      acc[category] = (acc[category] || 0) + Math.abs(t.amount)
      return acc
    }, {} as Record<string, number>)

    // Daily spending trend
    const dailySpending = transactions.reduce((acc, t) => {
      const date = new Date(t.created_at).toISOString().split('T')[0]
      acc[date] = (acc[date] || 0) + Math.abs(t.amount)
      return acc
    }, {} as Record<string, number>)

    return {
      success: true,
      data: {
        summary: {
          total_spent: totalSpent,
          transaction_count: transactionCount,
          average_transaction: averageTransaction,
          period: period,
          date_range: dateRange
        },
        spending_by_type: spendingByType,
        spending_by_category: spendingByCategory,
        daily_spending: dailySpending,
        recent_transactions: transactions.slice(0, 10)
      },
      metadata: {
        period: period,
        generated_at: new Date().toISOString(),
        total_records: transactionCount
      }
    }

  } catch (error) {
    console.error('Get spending analytics error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

async function getTransactionTrends(
  supabase: any,
  userId: string,
  request: AnalyticsRequest
): Promise<AnalyticsResult> {
  try {
    const { wallet_id, period = 'month' } = request

    // Get user's wallet if not specified
    let walletId = wallet_id
    if (!walletId) {
      const { data: wallet } = await supabase
        .from('stakeholder_wallets')
        .select('id')
        .eq('user_id', userId)
        .eq('user_role', 'customer')
        .single()
      
      walletId = wallet?.id
    }

    if (!walletId) {
      throw new Error('Wallet not found')
    }

    // Get transaction trends for the last 12 periods
    const trends = []
    const now = new Date()

    for (let i = 11; i >= 0; i--) {
      const periodStart = new Date(now)
      const periodEnd = new Date(now)

      if (period === 'month') {
        periodStart.setMonth(now.getMonth() - i, 1)
        periodEnd.setMonth(now.getMonth() - i + 1, 0)
      } else if (period === 'week') {
        const weekStart = new Date(now.getTime() - (i * 7 * 24 * 60 * 60 * 1000))
        periodStart.setTime(weekStart.getTime() - (weekStart.getDay() * 24 * 60 * 60 * 1000))
        periodEnd.setTime(periodStart.getTime() + (6 * 24 * 60 * 60 * 1000))
      } else if (period === 'day') {
        periodStart.setDate(now.getDate() - i)
        periodEnd.setDate(now.getDate() - i)
        periodStart.setHours(0, 0, 0, 0)
        periodEnd.setHours(23, 59, 59, 999)
      }

      // Get transactions for this period
      const { data: transactions } = await supabase
        .from('wallet_transactions')
        .select('amount, transaction_type')
        .eq('wallet_id', walletId)
        .gte('created_at', periodStart.toISOString())
        .lte('created_at', periodEnd.toISOString())

      const credits = transactions?.filter(t => t.amount > 0).reduce((sum, t) => sum + t.amount, 0) || 0
      const debits = transactions?.filter(t => t.amount < 0).reduce((sum, t) => sum + Math.abs(t.amount), 0) || 0
      const netFlow = credits - debits

      trends.push({
        period: periodStart.toISOString().split('T')[0],
        credits,
        debits,
        net_flow: netFlow,
        transaction_count: transactions?.length || 0
      })
    }

    return {
      success: true,
      data: {
        trends,
        period_type: period
      },
      metadata: {
        period: period,
        generated_at: new Date().toISOString(),
        total_records: trends.length
      }
    }

  } catch (error) {
    console.error('Get transaction trends error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

async function getCategoryBreakdown(
  supabase: any,
  userId: string,
  request: AnalyticsRequest
): Promise<AnalyticsResult> {
  try {
    const { wallet_id, period = 'month' } = request

    // Get user's wallet if not specified
    let walletId = wallet_id
    if (!walletId) {
      const { data: wallet } = await supabase
        .from('stakeholder_wallets')
        .select('id')
        .eq('user_id', userId)
        .eq('user_role', 'customer')
        .single()
      
      walletId = wallet?.id
    }

    if (!walletId) {
      throw new Error('Wallet not found')
    }

    const dateRange = calculateDateRange(period)

    // Get transactions with order details for better categorization
    const { data: transactions, error } = await supabase
      .from('wallet_transactions')
      .select(`
        amount,
        transaction_type,
        reference_type,
        reference_id,
        created_at,
        metadata
      `)
      .eq('wallet_id', walletId)
      .lt('amount', 0) // Only spending transactions
      .gte('created_at', dateRange.start)
      .lte('created_at', dateRange.end)

    if (error) {
      throw new Error(`Failed to fetch transactions: ${error.message}`)
    }

    // Categorize transactions
    const categories = {
      'Food & Dining': 0,
      'Transfers': 0,
      'Top-ups': 0,
      'Fees': 0,
      'Other': 0
    }

    transactions.forEach(transaction => {
      const amount = Math.abs(transaction.amount)
      
      if (transaction.reference_type === 'order') {
        categories['Food & Dining'] += amount
      } else if (transaction.transaction_type === 'transfer') {
        categories['Transfers'] += amount
      } else if (transaction.transaction_type === 'top_up') {
        categories['Top-ups'] += amount
      } else if (transaction.transaction_type === 'fee') {
        categories['Fees'] += amount
      } else {
        categories['Other'] += amount
      }
    })

    const totalSpent = Object.values(categories).reduce((sum, amount) => sum + amount, 0)

    // Calculate percentages
    const categoryBreakdown = Object.entries(categories).map(([category, amount]) => ({
      category,
      amount,
      percentage: totalSpent > 0 ? (amount / totalSpent) * 100 : 0,
      transaction_count: transactions.filter(t => {
        if (category === 'Food & Dining') return t.reference_type === 'order'
        if (category === 'Transfers') return t.transaction_type === 'transfer'
        if (category === 'Top-ups') return t.transaction_type === 'top_up'
        if (category === 'Fees') return t.transaction_type === 'fee'
        return !['order', 'transfer', 'top_up', 'fee'].includes(t.reference_type || t.transaction_type)
      }).length
    })).filter(item => item.amount > 0)

    return {
      success: true,
      data: {
        categories: categoryBreakdown,
        total_spent: totalSpent,
        period: period,
        date_range: dateRange
      },
      metadata: {
        period: period,
        generated_at: new Date().toISOString(),
        total_records: transactions.length
      }
    }

  } catch (error) {
    console.error('Get category breakdown error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

function calculateDateRange(period: string, startDate?: string, endDate?: string) {
  const now = new Date()
  let start: Date
  let end: Date = endDate ? new Date(endDate) : now

  if (startDate) {
    start = new Date(startDate)
  } else {
    start = new Date(now)
    
    switch (period) {
      case 'day':
        start.setHours(0, 0, 0, 0)
        end.setHours(23, 59, 59, 999)
        break
      case 'week':
        start.setDate(now.getDate() - 7)
        break
      case 'month':
        start.setMonth(now.getMonth() - 1)
        break
      case 'quarter':
        start.setMonth(now.getMonth() - 3)
        break
      case 'year':
        start.setFullYear(now.getFullYear() - 1)
        break
      default:
        start.setMonth(now.getMonth() - 1)
    }
  }

  return {
    start: start.toISOString(),
    end: end.toISOString()
  }
}

// Placeholder implementations for remaining functions
async function getMonthlySummary(supabase: any, userId: string, request: AnalyticsRequest): Promise<AnalyticsResult> {
  return { success: true, data: { message: 'Monthly summary feature coming soon' } }
}

async function getComparisonData(supabase: any, userId: string, request: AnalyticsRequest): Promise<AnalyticsResult> {
  return { success: true, data: { message: 'Comparison data feature coming soon' } }
}

async function exportAnalytics(supabase: any, userId: string, request: AnalyticsRequest): Promise<AnalyticsResult> {
  return { success: true, data: { message: 'Export analytics feature coming soon' } }
}
