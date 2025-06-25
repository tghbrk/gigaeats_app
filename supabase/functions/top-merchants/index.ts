import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface TopMerchantsRequest {
  user_id: string
  start_date?: string
  end_date?: string
  limit?: number
}

interface MerchantSpending {
  vendor_id: string
  vendor_name: string
  vendor_image_url?: string
  total_spent: number
  order_count: number
  avg_order_amount: number
  percentage_of_total: number
  last_order_date: string
  first_order_date: string
}

interface TopMerchantsResponse {
  success: boolean
  data?: MerchantSpending[]
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
    const requestData: TopMerchantsRequest = await req.json()
    const { user_id, start_date, end_date, limit = 10 } = requestData

    // Verify user can access this data (RLS compliance)
    if (user.id !== user_id) {
      throw new Error('Access denied: Cannot access other user data')
    }

    console.log(`🔍 [TOP-MERCHANTS] Processing top merchants for user: ${user_id}`)

    // Calculate date range if not provided
    const endDate = end_date ? new Date(end_date) : new Date()
    const startDate = start_date 
      ? new Date(start_date) 
      : new Date(endDate.getTime() - 90 * 24 * 60 * 60 * 1000) // Last 90 days

    // Get top merchants data
    const merchantData = await getTopMerchants(
      supabaseClient,
      user_id,
      startDate,
      endDate,
      limit
    )

    console.log(`✅ [TOP-MERCHANTS] Top merchants calculated: ${merchantData.merchants.length} merchants`)

    const response: TopMerchantsResponse = {
      success: true,
      data: merchantData.merchants,
      total_spending: merchantData.totalSpending,
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('❌ [TOP-MERCHANTS] Error:', error)
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

async function getTopMerchants(
  supabaseClient: any,
  userId: string,
  startDate: Date,
  endDate: Date,
  limit: number
): Promise<{ merchants: MerchantSpending[], totalSpending: number }> {
  console.log(`🔍 [TOP-MERCHANTS] Calculating top merchants from ${startDate.toISOString()} to ${endDate.toISOString()}`)

  // Get all orders for the user in the specified period
  const { data: orders, error: ordersError } = await supabaseClient
    .from('orders')
    .select(`
      id,
      vendor_id,
      total_amount,
      created_at,
      vendors!inner (
        id,
        business_name,
        cover_image_url
      )
    `)
    .eq('customer_id', userId)
    .gte('created_at', startDate.toISOString())
    .lte('created_at', endDate.toISOString())
    .in('status', ['delivered']) // Only completed orders
    .order('created_at', { ascending: false })

  if (ordersError) {
    throw new Error(`Failed to fetch orders: ${ordersError.message}`)
  }

  if (!orders || orders.length === 0) {
    return { merchants: [], totalSpending: 0 }
  }

  // Group orders by vendor
  const vendorMap = new Map<string, {
    vendorId: string
    vendorName: string
    vendorImageUrl?: string
    totalSpent: number
    orderCount: number
    orders: any[]
    firstOrderDate: Date
    lastOrderDate: Date
  }>()

  let totalSpending = 0

  for (const order of orders) {
    const vendorId = order.vendor_id
    const amount = order.total_amount
    const orderDate = new Date(order.created_at)
    
    totalSpending += amount

    if (!vendorMap.has(vendorId)) {
      vendorMap.set(vendorId, {
        vendorId,
        vendorName: order.vendors?.business_name || 'Unknown Vendor',
        vendorImageUrl: order.vendors?.cover_image_url,
        totalSpent: 0,
        orderCount: 0,
        orders: [],
        firstOrderDate: orderDate,
        lastOrderDate: orderDate
      })
    }

    const vendorData = vendorMap.get(vendorId)!
    vendorData.totalSpent += amount
    vendorData.orderCount += 1
    vendorData.orders.push(order)
    
    // Update date ranges
    if (orderDate < vendorData.firstOrderDate) {
      vendorData.firstOrderDate = orderDate
    }
    if (orderDate > vendorData.lastOrderDate) {
      vendorData.lastOrderDate = orderDate
    }
  }

  // Convert to MerchantSpending array
  const merchants: MerchantSpending[] = []

  for (const [vendorId, data] of vendorMap.entries()) {
    merchants.push({
      vendor_id: data.vendorId,
      vendor_name: data.vendorName,
      vendor_image_url: data.vendorImageUrl,
      total_spent: data.totalSpent,
      order_count: data.orderCount,
      avg_order_amount: data.orderCount > 0 ? data.totalSpent / data.orderCount : 0,
      percentage_of_total: totalSpending > 0 ? (data.totalSpent / totalSpending) * 100 : 0,
      last_order_date: data.lastOrderDate.toISOString(),
      first_order_date: data.firstOrderDate.toISOString(),
    })
  }

  // Sort by total spent (highest first)
  merchants.sort((a, b) => b.total_spent - a.total_spent)

  // Apply limit
  const limitedMerchants = merchants.slice(0, limit)

  return {
    merchants: limitedMerchants,
    totalSpending
  }
}
