import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface SearchRequest {
  action: 'search' | 'export' | 'suggestions' | 'statistics'
  wallet_id: string
  search_query?: string
  transaction_types?: string[]
  amount_min?: number
  amount_max?: number
  start_date?: string
  end_date?: string
  sort_by?: string
  sort_order?: string
  limit?: number
  offset?: number
  export_format?: 'csv' | 'json'
}

interface SearchResponse {
  success: boolean
  data?: any
  error?: string
  message?: string
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

    // Get authenticated user
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Parse request body
    const requestData: SearchRequest = await req.json()
    const { action, wallet_id } = requestData

    console.log(`🔍 [TRANSACTION-SEARCH] Processing ${action} for wallet: ${wallet_id}`)

    // Verify wallet ownership
    const { data: wallet, error: walletError } = await supabaseClient
      .from('stakeholder_wallets')
      .select('id, user_id')
      .eq('id', wallet_id)
      .eq('user_id', user.id)
      .single()

    if (walletError || !wallet) {
      return new Response(
        JSON.stringify({ success: false, error: 'Wallet not found or access denied' }),
        {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    let response: SearchResponse

    switch (action) {
      case 'search':
        response = await searchTransactions(supabaseClient, requestData)
        break
      case 'export':
        response = await exportTransactions(supabaseClient, requestData)
        break
      case 'suggestions':
        response = await getSearchSuggestions(supabaseClient, requestData)
        break
      case 'statistics':
        response = await getTransactionStatistics(supabaseClient, requestData)
        break
      default:
        throw new Error(`Unknown action: ${action}`)
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('❌ [TRANSACTION-SEARCH] Error:', error)
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

async function searchTransactions(
  supabaseClient: any,
  requestData: SearchRequest
): Promise<SearchResponse> {
  try {
    const {
      wallet_id,
      search_query,
      transaction_types,
      amount_min,
      amount_max,
      start_date,
      end_date,
      sort_by = 'created_at',
      sort_order = 'desc',
      limit = 20,
      offset = 0,
    } = requestData

    console.log(`🔍 [TRANSACTION-SEARCH] Searching with filters:`, {
      search_query,
      transaction_types,
      amount_range: [amount_min, amount_max],
      date_range: [start_date, end_date],
      sort: `${sort_by} ${sort_order}`,
      pagination: { limit, offset },
    })

    const { data: transactions, error } = await supabaseClient.rpc(
      'search_wallet_transactions',
      {
        p_wallet_id: wallet_id,
        p_search_query: search_query || null,
        p_transaction_types: transaction_types || null,
        p_amount_min: amount_min || null,
        p_amount_max: amount_max || null,
        p_start_date: start_date ? new Date(start_date).toISOString() : null,
        p_end_date: end_date ? new Date(end_date).toISOString() : null,
        p_sort_by: sort_by,
        p_sort_order: sort_order,
        p_limit: limit,
        p_offset: offset,
      }
    )

    if (error) {
      throw new Error(`Search failed: ${error.message}`)
    }

    const totalCount = transactions && transactions.length > 0 ? transactions[0].total_count : 0
    const hasMore = offset + limit < totalCount

    console.log(`✅ [TRANSACTION-SEARCH] Found ${transactions?.length || 0} transactions (${totalCount} total)`)

    return {
      success: true,
      data: {
        transactions: transactions || [],
        pagination: {
          offset,
          limit,
          total: totalCount,
          has_more: hasMore,
          current_page: Math.floor(offset / limit),
          total_pages: Math.ceil(totalCount / limit),
        },
        filters_applied: {
          search_query,
          transaction_types,
          amount_range: amount_min || amount_max ? [amount_min, amount_max] : null,
          date_range: start_date || end_date ? [start_date, end_date] : null,
          sort: `${sort_by} ${sort_order}`,
        },
      },
    }
  } catch (error) {
    console.error('❌ [TRANSACTION-SEARCH] Search error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function exportTransactions(
  supabaseClient: any,
  requestData: SearchRequest
): Promise<SearchResponse> {
  try {
    const {
      wallet_id,
      search_query,
      transaction_types,
      amount_min,
      amount_max,
      start_date,
      end_date,
      sort_by = 'created_at',
      sort_order = 'desc',
      export_format = 'csv',
    } = requestData

    console.log(`📊 [TRANSACTION-SEARCH] Exporting transactions in ${export_format} format`)

    const { data: exportData, error } = await supabaseClient.rpc(
      'export_wallet_transactions',
      {
        p_wallet_id: wallet_id,
        p_search_query: search_query || null,
        p_transaction_types: transaction_types || null,
        p_amount_min: amount_min || null,
        p_amount_max: amount_max || null,
        p_start_date: start_date ? new Date(start_date).toISOString() : null,
        p_end_date: end_date ? new Date(end_date).toISOString() : null,
        p_sort_by: sort_by,
        p_sort_order: sort_order,
        p_export_limit: 1000, // Limit exports to 1000 records
      }
    )

    if (error) {
      throw new Error(`Export failed: ${error.message}`)
    }

    let formattedData: any
    let contentType: string
    let filename: string

    if (export_format === 'csv') {
      // Convert to CSV format
      if (!exportData || exportData.length === 0) {
        formattedData = 'No transactions found for the specified criteria'
      } else {
        const headers = Object.keys(exportData[0]).join(',')
        const rows = exportData.map((row: any) =>
          Object.values(row).map((value: any) =>
            typeof value === 'string' && value.includes(',') ? `"${value}"` : value
          ).join(',')
        ).join('\n')
        formattedData = `${headers}\n${rows}`
      }
      contentType = 'text/csv'
      filename = `transactions_${new Date().toISOString().split('T')[0]}.csv`
    } else {
      // JSON format
      formattedData = JSON.stringify(exportData, null, 2)
      contentType = 'application/json'
      filename = `transactions_${new Date().toISOString().split('T')[0]}.json`
    }

    console.log(`✅ [TRANSACTION-SEARCH] Exported ${exportData?.length || 0} transactions`)

    return {
      success: true,
      data: {
        content: formattedData,
        content_type: contentType,
        filename: filename,
        record_count: exportData?.length || 0,
        export_format: export_format,
        generated_at: new Date().toISOString(),
      },
    }
  } catch (error) {
    console.error('❌ [TRANSACTION-SEARCH] Export error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function getSearchSuggestions(
  supabaseClient: any,
  requestData: SearchRequest
): Promise<SearchResponse> {
  try {
    const { wallet_id, search_query } = requestData

    if (!search_query || search_query.length < 2) {
      return {
        success: true,
        data: { suggestions: [] },
      }
    }

    console.log(`💡 [TRANSACTION-SEARCH] Getting suggestions for: "${search_query}"`)

    const { data: suggestions, error } = await supabaseClient.rpc(
      'get_transaction_search_suggestions',
      {
        p_wallet_id: wallet_id,
        p_query: search_query,
        p_limit: 5,
      }
    )

    if (error) {
      throw new Error(`Suggestions failed: ${error.message}`)
    }

    console.log(`✅ [TRANSACTION-SEARCH] Found ${suggestions?.length || 0} suggestions`)

    return {
      success: true,
      data: {
        suggestions: suggestions || [],
        query: search_query,
      },
    }
  } catch (error) {
    console.error('❌ [TRANSACTION-SEARCH] Suggestions error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function getTransactionStatistics(
  supabaseClient: any,
  requestData: SearchRequest
): Promise<SearchResponse> {
  try {
    const { wallet_id, start_date, end_date } = requestData

    console.log(`📈 [TRANSACTION-SEARCH] Getting statistics for date range: ${start_date} to ${end_date}`)

    const { data: statistics, error } = await supabaseClient.rpc(
      'get_transaction_statistics',
      {
        p_wallet_id: wallet_id,
        p_start_date: start_date ? new Date(start_date).toISOString() : null,
        p_end_date: end_date ? new Date(end_date).toISOString() : null,
      }
    )

    if (error) {
      throw new Error(`Statistics failed: ${error.message}`)
    }

    const stats = statistics && statistics.length > 0 ? statistics[0] : null

    console.log(`✅ [TRANSACTION-SEARCH] Generated statistics:`, stats)

    return {
      success: true,
      data: {
        statistics: stats,
        date_range: {
          start_date,
          end_date,
        },
        generated_at: new Date().toISOString(),
      },
    }
  } catch (error) {
    console.error('❌ [TRANSACTION-SEARCH] Statistics error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}
