import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface SpendingByCategoryRequest {
  user_id: string
  start_date?: string
  end_date?: string
  limit?: number
}

interface CategorySpending {
  category: string
  category_name: string
  total_amount: number
  transaction_count: number
  percentage_of_total: number
  avg_amount: number
  color?: string
}

interface SpendingByCategoryResponse {
  success: boolean
  data?: CategorySpending[]
  error?: string
  total_spending?: number
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
    const requestData: SpendingByCategoryRequest = await req.json()
    const { user_id, start_date, end_date, limit } = requestData

    // Verify user can access this data (RLS compliance)
    if (user.id !== user_id) {
      throw new Error('Access denied: Cannot access other user data')
    }

    console.log(`🔍 [SPENDING-BY-CATEGORY] Processing category spending for user: ${user_id}`)

    // Calculate date range if not provided
    const endDate = end_date ? new Date(end_date) : new Date()
    const startDate = start_date 
      ? new Date(start_date) 
      : new Date(endDate.getTime() - 30 * 24 * 60 * 60 * 1000) // Last 30 days

    // Get user's wallet
    const { data: wallet, error: walletError } = await supabaseClient
      .from('stakeholder_wallets')
      .select('id')
      .eq('user_id', user_id)
      .single()

    if (walletError || !wallet) {
      throw new Error('Wallet not found')
    }

    // Get category spending data
    const categoryData = await getCategorySpending(
      supabaseClient,
      user_id,
      wallet.id,
      startDate,
      endDate,
      limit
    )

    console.log(`✅ [SPENDING-BY-CATEGORY] Category spending calculated: ${categoryData.categories.length} categories`)

    const response: SpendingByCategoryResponse = {
      success: true,
      data: categoryData.categories,
      total_spending: categoryData.totalSpending,
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('❌ [SPENDING-BY-CATEGORY] Error:', error)
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

async function getCategorySpending(
  supabaseClient: any,
  userId: string,
  walletId: string,
  startDate: Date,
  endDate: Date,
  limit?: number
): Promise<{ categories: CategorySpending[], totalSpending: number }> {
  console.log(`🔍 [SPENDING-BY-CATEGORY] Calculating category spending from ${startDate.toISOString()} to ${endDate.toISOString()}`)

  // Get all spending transactions in the period
  const { data: transactions, error: transactionsError } = await supabaseClient
    .from('wallet_transactions')
    .select(`
      id,
      transaction_type,
      amount,
      reference_type,
      reference_id,
      description,
      metadata,
      created_at
    `)
    .eq('wallet_id', walletId)
    .gte('created_at', startDate.toISOString())
    .lte('created_at', endDate.toISOString())
    .lt('amount', 0) // Only spending transactions (negative amounts)
    .in('transaction_type', ['debit', 'transfer_out'])
    .order('created_at', { ascending: false })

  if (transactionsError) {
    throw new Error(`Failed to fetch transactions: ${transactionsError.message}`)
  }

  // Group transactions by category
  const categoryMap = new Map<string, {
    totalAmount: number
    transactionCount: number
    transactions: any[]
  }>()

  let totalSpending = 0

  for (const transaction of transactions) {
    const amount = Math.abs(transaction.amount)
    totalSpending += amount

    const category = categorizeTransaction(transaction)
    
    if (!categoryMap.has(category)) {
      categoryMap.set(category, {
        totalAmount: 0,
        transactionCount: 0,
        transactions: []
      })
    }

    const categoryData = categoryMap.get(category)!
    categoryData.totalAmount += amount
    categoryData.transactionCount += 1
    categoryData.transactions.push(transaction)
  }

  // Convert to CategorySpending array
  const categories: CategorySpending[] = []

  for (const [categoryKey, data] of categoryMap.entries()) {
    const categoryInfo = getCategoryInfo(categoryKey)
    
    categories.push({
      category: categoryKey,
      category_name: categoryInfo.name,
      total_amount: data.totalAmount,
      transaction_count: data.transactionCount,
      percentage_of_total: totalSpending > 0 ? (data.totalAmount / totalSpending) * 100 : 0,
      avg_amount: data.transactionCount > 0 ? data.totalAmount / data.transactionCount : 0,
      color: categoryInfo.color,
    })
  }

  // Sort by total amount (highest first)
  categories.sort((a, b) => b.total_amount - a.total_amount)

  // Apply limit if specified
  if (limit && limit > 0) {
    return {
      categories: categories.slice(0, limit),
      totalSpending
    }
  }

  return {
    categories,
    totalSpending
  }
}

function categorizeTransaction(transaction: any): string {
  // Categorize based on reference_type and metadata
  if (transaction.reference_type === 'order') {
    return 'food_orders'
  } else if (transaction.reference_type === 'wallet_transfer') {
    return 'transfers'
  } else if (transaction.transaction_type === 'transfer_out') {
    return 'transfers'
  } else if (transaction.description?.toLowerCase().includes('delivery')) {
    return 'delivery_fees'
  } else if (transaction.description?.toLowerCase().includes('service')) {
    return 'service_fees'
  } else if (transaction.description?.toLowerCase().includes('tip')) {
    return 'tips'
  } else if (transaction.transaction_type === 'debit') {
    return 'payments'
  } else {
    return 'other'
  }
}

function getCategoryInfo(categoryKey: string): { name: string, color: string } {
  const categoryMap: Record<string, { name: string, color: string }> = {
    food_orders: { name: 'Food Orders', color: '#FF6B6B' },
    transfers: { name: 'Transfers', color: '#4ECDC4' },
    delivery_fees: { name: 'Delivery Fees', color: '#45B7D1' },
    service_fees: { name: 'Service Fees', color: '#96CEB4' },
    tips: { name: 'Tips', color: '#FFEAA7' },
    payments: { name: 'Payments', color: '#DDA0DD' },
    other: { name: 'Other', color: '#95A5A6' },
  }

  return categoryMap[categoryKey] || { name: 'Unknown', color: '#BDC3C7' }
}
