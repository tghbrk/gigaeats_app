import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('🚀🚀🚀 TEST FUNCTION CALLED - WORKING! 🚀🚀🚀')
    console.log('📅 Timestamp:', new Date().toISOString())
    console.log('🌐 Request method:', req.method)
    console.log('🔗 Request URL:', req.url)
    
    const body = await req.json()
    console.log('📦 Request body:', JSON.stringify(body, null, 2))
    
    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Test function is working!',
        timestamp: new Date().toISOString(),
        receivedData: body
      }), 
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  } catch (error) {
    console.error('❌ Test function error:', error)
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
