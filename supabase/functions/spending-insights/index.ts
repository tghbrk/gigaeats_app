import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface SpendingInsightsRequest {
  user_id: string
  limit?: number
}

interface SpendingInsight {
  id: string
  type: 'trend' | 'comparison' | 'recommendation' | 'achievement' | 'warning'
  title: string
  description: string
  value?: number
  formatted_value?: string
  change_percentage?: number
  icon: string
  color: string
  priority: number
  action_text?: string
  action_url?: string
}

interface SpendingInsightsResponse {
  success: boolean
  data?: SpendingInsight[]
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
    const requestData: SpendingInsightsRequest = await req.json()
    const { user_id, limit = 5 } = requestData

    // Verify user can access this data (RLS compliance)
    if (user.id !== user_id) {
      throw new Error('Access denied: Cannot access other user data')
    }

    console.log(`🔍 [SPENDING-INSIGHTS] Generating insights for user: ${user_id}`)

    // Generate spending insights
    const insights = await generateSpendingInsights(
      supabaseClient,
      user_id,
      limit
    )

    console.log(`✅ [SPENDING-INSIGHTS] Generated ${insights.length} insights`)

    const response: SpendingInsightsResponse = {
      success: true,
      data: insights,
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('❌ [SPENDING-INSIGHTS] Error:', error)
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

async function generateSpendingInsights(
  supabaseClient: any,
  userId: string,
  limit: number
): Promise<SpendingInsight[]> {
  console.log(`🔍 [SPENDING-INSIGHTS] Analyzing spending patterns for insights`)

  const insights: SpendingInsight[] = []

  // Get user's wallet
  const { data: wallet, error: walletError } = await supabaseClient
    .from('stakeholder_wallets')
    .select('id, available_balance')
    .eq('user_id', userId)
    .single()

  if (walletError || !wallet) {
    throw new Error('Wallet not found')
  }

  // Date ranges for analysis
  const now = new Date()
  const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1)
  const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1)
  const lastMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0)
  const thisWeek = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
  const last30Days = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)

  // 1. Monthly spending comparison
  const monthlyComparison = await getMonthlySpendingComparison(
    supabaseClient,
    wallet.id,
    thisMonth,
    lastMonth,
    lastMonthEnd
  )

  if (monthlyComparison) {
    insights.push(monthlyComparison)
  }

  // 2. Weekly spending trend
  const weeklyTrend = await getWeeklySpendingTrend(
    supabaseClient,
    wallet.id,
    thisWeek
  )

  if (weeklyTrend) {
    insights.push(weeklyTrend)
  }

  // 3. Top category insight
  const topCategoryInsight = await getTopCategoryInsight(
    supabaseClient,
    wallet.id,
    last30Days
  )

  if (topCategoryInsight) {
    insights.push(topCategoryInsight)
  }

  // 4. Balance warning or achievement
  const balanceInsight = getBalanceInsight(wallet.available_balance)
  if (balanceInsight) {
    insights.push(balanceInsight)
  }

  // 5. Spending frequency insight
  const frequencyInsight = await getSpendingFrequencyInsight(
    supabaseClient,
    wallet.id,
    last30Days
  )

  if (frequencyInsight) {
    insights.push(frequencyInsight)
  }

  // Sort by priority and limit results
  insights.sort((a, b) => b.priority - a.priority)
  return insights.slice(0, limit)
}

async function getMonthlySpendingComparison(
  supabaseClient: any,
  walletId: string,
  thisMonth: Date,
  lastMonth: Date,
  lastMonthEnd: Date
): Promise<SpendingInsight | null> {
  try {
    // Get this month's spending
    const { data: thisMonthTxns } = await supabaseClient
      .from('wallet_transactions')
      .select('amount')
      .eq('wallet_id', walletId)
      .gte('created_at', thisMonth.toISOString())
      .lt('amount', 0)
      .in('transaction_type', ['debit'])

    // Get last month's spending
    const { data: lastMonthTxns } = await supabaseClient
      .from('wallet_transactions')
      .select('amount')
      .eq('wallet_id', walletId)
      .gte('created_at', lastMonth.toISOString())
      .lte('created_at', lastMonthEnd.toISOString())
      .lt('amount', 0)
      .in('transaction_type', ['debit'])

    const thisMonthSpending = thisMonthTxns?.reduce((sum, t) => sum + Math.abs(t.amount), 0) || 0
    const lastMonthSpending = lastMonthTxns?.reduce((sum, t) => sum + Math.abs(t.amount), 0) || 0

    if (lastMonthSpending === 0) return null

    const changePercentage = ((thisMonthSpending - lastMonthSpending) / lastMonthSpending) * 100
    const isIncrease = changePercentage > 0

    return {
      id: 'monthly-comparison',
      type: isIncrease ? 'warning' : 'achievement',
      title: isIncrease ? 'Spending Increased' : 'Spending Decreased',
      description: `You've ${isIncrease ? 'spent' : 'saved'} ${Math.abs(changePercentage).toFixed(1)}% ${isIncrease ? 'more' : 'less'} this month compared to last month`,
      value: thisMonthSpending,
      formatted_value: `RM ${thisMonthSpending.toFixed(2)}`,
      change_percentage: changePercentage,
      icon: isIncrease ? '📈' : '📉',
      color: isIncrease ? '#FF6B6B' : '#4ECDC4',
      priority: 90,
    }
  } catch (error) {
    console.error('Error calculating monthly comparison:', error)
    return null
  }
}

async function getWeeklySpendingTrend(
  supabaseClient: any,
  walletId: string,
  weekStart: Date
): Promise<SpendingInsight | null> {
  try {
    const { data: weeklyTxns } = await supabaseClient
      .from('wallet_transactions')
      .select('amount, created_at')
      .eq('wallet_id', walletId)
      .gte('created_at', weekStart.toISOString())
      .lt('amount', 0)
      .in('transaction_type', ['debit'])

    if (!weeklyTxns || weeklyTxns.length === 0) return null

    const totalSpending = weeklyTxns.reduce((sum, t) => sum + Math.abs(t.amount), 0)
    const avgDaily = totalSpending / 7

    return {
      id: 'weekly-trend',
      type: 'trend',
      title: 'Weekly Spending',
      description: `You've spent RM ${totalSpending.toFixed(2)} this week, averaging RM ${avgDaily.toFixed(2)} per day`,
      value: totalSpending,
      formatted_value: `RM ${totalSpending.toFixed(2)}`,
      icon: '📊',
      color: '#45B7D1',
      priority: 70,
    }
  } catch (error) {
    console.error('Error calculating weekly trend:', error)
    return null
  }
}

async function getTopCategoryInsight(
  supabaseClient: any,
  walletId: string,
  startDate: Date
): Promise<SpendingInsight | null> {
  try {
    const { data: transactions } = await supabaseClient
      .from('wallet_transactions')
      .select('amount, reference_type, description')
      .eq('wallet_id', walletId)
      .gte('created_at', startDate.toISOString())
      .lt('amount', 0)
      .in('transaction_type', ['debit'])

    if (!transactions || transactions.length === 0) return null

    // Categorize and sum
    const categories = new Map<string, number>()
    
    transactions.forEach(t => {
      const category = t.reference_type === 'order' ? 'Food Orders' : 'Other'
      categories.set(category, (categories.get(category) || 0) + Math.abs(t.amount))
    })

    // Find top category
    let topCategory = ''
    let topAmount = 0
    
    for (const [category, amount] of categories.entries()) {
      if (amount > topAmount) {
        topAmount = amount
        topCategory = category
      }
    }

    if (topAmount === 0) return null

    return {
      id: 'top-category',
      type: 'comparison',
      title: `Top Spending: ${topCategory}`,
      description: `${topCategory} accounts for RM ${topAmount.toFixed(2)} of your spending in the last 30 days`,
      value: topAmount,
      formatted_value: `RM ${topAmount.toFixed(2)}`,
      icon: '🍽️',
      color: '#96CEB4',
      priority: 60,
    }
  } catch (error) {
    console.error('Error calculating top category:', error)
    return null
  }
}

function getBalanceInsight(balance: number): SpendingInsight | null {
  if (balance < 50) {
    return {
      id: 'low-balance',
      type: 'warning',
      title: 'Low Balance Warning',
      description: `Your wallet balance is running low. Consider topping up to avoid payment issues.`,
      value: balance,
      formatted_value: `RM ${balance.toFixed(2)}`,
      icon: '⚠️',
      color: '#FF6B6B',
      priority: 100,
      action_text: 'Top Up Now',
      action_url: '/customer/wallet/topup',
    }
  } else if (balance > 500) {
    return {
      id: 'high-balance',
      type: 'achievement',
      title: 'Great Balance!',
      description: `You're maintaining a healthy wallet balance. Keep up the good financial habits!`,
      value: balance,
      formatted_value: `RM ${balance.toFixed(2)}`,
      icon: '💰',
      color: '#4ECDC4',
      priority: 50,
    }
  }
  
  return null
}

async function getSpendingFrequencyInsight(
  supabaseClient: any,
  walletId: string,
  startDate: Date
): Promise<SpendingInsight | null> {
  try {
    const { data: transactions } = await supabaseClient
      .from('wallet_transactions')
      .select('created_at')
      .eq('wallet_id', walletId)
      .gte('created_at', startDate.toISOString())
      .lt('amount', 0)
      .in('transaction_type', ['debit'])

    if (!transactions || transactions.length === 0) return null

    const avgPerDay = transactions.length / 30
    
    if (avgPerDay > 2) {
      return {
        id: 'high-frequency',
        type: 'recommendation',
        title: 'Frequent Spending',
        description: `You make ${avgPerDay.toFixed(1)} transactions per day on average. Consider setting spending limits to track your habits.`,
        value: avgPerDay,
        formatted_value: `${avgPerDay.toFixed(1)} per day`,
        icon: '🔄',
        color: '#FFEAA7',
        priority: 40,
        action_text: 'Set Limits',
        action_url: '/customer/wallet/settings',
      }
    }

    return null
  } catch (error) {
    console.error('Error calculating frequency insight:', error)
    return null
  }
}
