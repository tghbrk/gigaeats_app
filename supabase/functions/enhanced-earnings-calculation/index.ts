// Enhanced Driver Earnings Calculation Edge Function
// Provides complex earnings calculations with performance bonuses and custom tips

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface EarningsCalculationRequest {
  orderId: string;
  driverId: string;
  includeBonus?: boolean;
  customTip?: number;
  performanceMetrics?: {
    deliveryTime?: number; // in minutes
    customerRating?: number; // 1-5 scale
    distanceKm?: number;
    isOnTime?: boolean;
  };
}

interface EarningsCalculationResponse {
  success: boolean;
  earnings?: {
    baseCommission: number;
    distanceFee: number;
    timeFee: number;
    peakHourBonus: number;
    completionBonus: number;
    ratingBonus: number;
    customTip: number;
    grossEarnings: number;
    deductions: number;
    netEarnings: number;
    breakdown: {
      [key: string]: number;
    };
  };
  error?: string;
  metadata?: {
    calculationTime: number;
    commissionStructureUsed: string;
    bonusesApplied: string[];
  };
}

serve(async (req: Request): Promise<Response> => {
  try {
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
    };

    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
      return new Response('ok', { headers: corsHeaders });
    }

    // Only allow POST requests
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ success: false, error: 'Method not allowed' }),
        { 
          status: 405, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    const startTime = Date.now();

    // Parse request body
    const body: EarningsCalculationRequest = await req.json();
    const { orderId, driverId, includeBonus = true, customTip = 0, performanceMetrics } = body;

    // Validate required fields
    if (!orderId || !driverId) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Missing required fields: orderId and driverId' 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    // Initialize Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Get order details
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select(`
        id,
        vendor_id,
        total_amount,
        delivery_fee,
        delivery_address,
        created_at,
        actual_delivery_time,
        status
      `)
      .eq('id', orderId)
      .single();

    if (orderError || !order) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: `Order not found: ${orderError?.message}` 
        }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    // Get driver commission structure
    const { data: commissionStructure, error: commissionError } = await supabase
      .from('driver_commission_structure')
      .select('*')
      .eq('driver_id', driverId)
      .eq('vendor_id', order.vendor_id)
      .eq('is_active', true)
      .lte('effective_from', new Date().toISOString())
      .or('effective_until.is.null,effective_until.gte.' + new Date().toISOString())
      .order('effective_from', { ascending: false })
      .limit(1)
      .single();

    // Use default commission structure if none found
    const commission = commissionStructure || {
      base_commission_rate: 0.15,
      distance_rate_per_km: 2.00,
      time_rate_per_minute: 0.50,
      peak_hour_multiplier: 1.5,
      weekend_multiplier: 1.2,
      holiday_multiplier: 1.8,
      completion_bonus: 5.00,
      rating_bonus_threshold: 4.5,
      rating_bonus_amount: 10.00
    };

    // Calculate base commission
    const baseCommission = (order.delivery_fee || 0) * commission.base_commission_rate;

    // Calculate distance fee
    const distanceKm = performanceMetrics?.distanceKm || 5; // Default 5km
    const distanceFee = distanceKm * commission.distance_rate_per_km;

    // Calculate time fee
    const deliveryTimeMinutes = performanceMetrics?.deliveryTime || 30; // Default 30 minutes
    const timeFee = deliveryTimeMinutes * commission.time_rate_per_minute;

    // Calculate peak hour bonus
    const currentHour = new Date().getHours();
    const isPeakHour = (currentHour >= 11 && currentHour <= 14) || (currentHour >= 18 && currentHour <= 21);
    const peakHourBonus = isPeakHour ? (baseCommission * (commission.peak_hour_multiplier - 1)) : 0;

    // Calculate completion bonus
    const completionBonus = includeBonus ? commission.completion_bonus : 0;

    // Calculate rating bonus
    const customerRating = performanceMetrics?.customerRating || 0;
    const ratingBonus = (includeBonus && customerRating >= commission.rating_bonus_threshold) 
      ? commission.rating_bonus_amount : 0;

    // Calculate gross earnings
    const grossEarnings = baseCommission + distanceFee + timeFee + peakHourBonus + 
                         completionBonus + ratingBonus + customTip;

    // Calculate deductions (platform fee, etc.)
    const platformFeeRate = 0.05; // 5% platform fee
    const deductions = grossEarnings * platformFeeRate;

    // Calculate net earnings
    const netEarnings = grossEarnings - deductions;

    // Prepare breakdown
    const breakdown = {
      baseCommission,
      distanceFee,
      timeFee,
      peakHourBonus,
      completionBonus,
      ratingBonus,
      customTip,
      platformFee: deductions
    };

    // Prepare bonuses applied list
    const bonusesApplied: string[] = [];
    if (peakHourBonus > 0) bonusesApplied.push('Peak Hour Bonus');
    if (completionBonus > 0) bonusesApplied.push('Completion Bonus');
    if (ratingBonus > 0) bonusesApplied.push('Rating Bonus');
    if (customTip > 0) bonusesApplied.push('Custom Tip');

    const calculationTime = Date.now() - startTime;

    const response: EarningsCalculationResponse = {
      success: true,
      earnings: {
        baseCommission,
        distanceFee,
        timeFee,
        peakHourBonus,
        completionBonus,
        ratingBonus,
        customTip,
        grossEarnings,
        deductions,
        netEarnings,
        breakdown
      },
      metadata: {
        calculationTime,
        commissionStructureUsed: commissionStructure ? 'custom' : 'default',
        bonusesApplied
      }
    };

    return new Response(
      JSON.stringify(response),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    console.error('Enhanced earnings calculation error:', error);
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: `Internal server error: ${error.message}` 
      }),
      { 
        status: 500, 
        headers: { 
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json' 
        }
      }
    );
  }
});
