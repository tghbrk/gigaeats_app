import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface TransferRequest {
  action: 'initiate' | 'validate_recipient' | 'get_limits' | 'get_fees' | 'get_history'
  recipient_identifier?: string // email, phone, or user_id
  amount?: number
  description?: string
  transfer_id?: string
  page?: number
  limit?: number
}

interface TransferResponse {
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
    const { action, recipient_identifier, amount, description, transfer_id, page, limit }: TransferRequest = await req.json()

    console.log(`🔍 [WALLET-TRANSFER] Processing ${action} for user: ${user.id}`)

    let response: TransferResponse

    switch (action) {
      case 'validate_recipient':
        if (!recipient_identifier) {
          throw new Error('recipient_identifier is required for validate_recipient action')
        }
        response = await validateRecipient(supabaseClient, user.id, recipient_identifier)
        break
      case 'get_limits':
        response = await getTransferLimits(supabaseClient, user.id)
        break
      case 'get_fees':
        if (!amount) {
          throw new Error('amount is required for get_fees action')
        }
        response = await calculateTransferFees(supabaseClient, user.id, amount)
        break
      case 'initiate':
        if (!recipient_identifier || !amount) {
          throw new Error('recipient_identifier and amount are required for initiate action')
        }
        response = await initiateTransfer(supabaseClient, user.id, {
          recipient_identifier,
          amount,
          description,
        })
        break
      case 'get_history':
        response = await getTransferHistory(supabaseClient, user.id, page || 0, limit || 20)
        break
      default:
        throw new Error(`Unknown action: ${action}`)
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('❌ [WALLET-TRANSFER] Error:', error)
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

async function validateRecipient(
  supabaseClient: any,
  senderId: string,
  recipientIdentifier: string
): Promise<TransferResponse> {
  try {
    // Check if recipient identifier is email, phone, or user_id
    let recipientQuery = supabaseClient
      .from('user_profiles')
      .select('user_id, email, phone, full_name')

    if (recipientIdentifier.includes('@')) {
      recipientQuery = recipientQuery.eq('email', recipientIdentifier)
    } else if (recipientIdentifier.startsWith('+') || /^\d+$/.test(recipientIdentifier)) {
      recipientQuery = recipientQuery.eq('phone', recipientIdentifier)
    } else {
      recipientQuery = recipientQuery.eq('user_id', recipientIdentifier)
    }

    const { data: recipient, error } = await recipientQuery.single()

    if (error || !recipient) {
      return {
        success: false,
        error: 'Recipient not found',
      }
    }

    // Check if trying to transfer to self
    if (recipient.user_id === senderId) {
      return {
        success: false,
        error: 'Cannot transfer to yourself',
      }
    }

    // Check if recipient has a wallet
    const { data: recipientWallet, error: walletError } = await supabaseClient
      .from('stakeholder_wallets')
      .select('id, is_active, is_verified')
      .eq('user_id', recipient.user_id)
      .eq('user_role', 'customer')
      .single()

    if (walletError || !recipientWallet) {
      return {
        success: false,
        error: 'Recipient does not have an active wallet',
      }
    }

    if (!recipientWallet.is_active) {
      return {
        success: false,
        error: 'Recipient wallet is not active',
      }
    }

    return {
      success: true,
      data: {
        user_id: recipient.user_id,
        wallet_id: recipientWallet.id,
        name: recipient.full_name,
        email: recipient.email,
        phone: recipient.phone,
        is_verified: recipientWallet.is_verified,
      },
      message: 'Recipient validated successfully',
    }
  } catch (error) {
    console.error('❌ [WALLET-TRANSFER] Validate recipient error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function getTransferLimits(
  supabaseClient: any,
  userId: string
): Promise<TransferResponse> {
  try {
    // Get user-specific limits first, then fall back to global limits
    const { data: userLimits } = await supabaseClient
      .from('transfer_limits')
      .select('*')
      .eq('user_id', userId)
      .eq('is_active', true)
      .order('created_at', { ascending: false })
      .limit(1)

    const { data: globalLimits } = await supabaseClient
      .from('transfer_limits')
      .select('*')
      .eq('is_global', true)
      .eq('is_active', true)
      .eq('user_tier', 'standard') // Default tier
      .order('created_at', { ascending: false })
      .limit(1)

    const limits = userLimits?.[0] || globalLimits?.[0]

    if (!limits) {
      throw new Error('No transfer limits configured')
    }

    // Get current usage for the day and month
    const now = new Date()
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1)

    const { data: dailyTransfers } = await supabaseClient
      .from('wallet_transfers')
      .select('amount')
      .eq('sender_user_id', userId)
      .eq('status', 'completed')
      .gte('created_at', startOfDay.toISOString())

    const { data: monthlyTransfers } = await supabaseClient
      .from('wallet_transfers')
      .select('amount')
      .eq('sender_user_id', userId)
      .eq('status', 'completed')
      .gte('created_at', startOfMonth.toISOString())

    const dailyUsed = dailyTransfers?.reduce((sum, t) => sum + parseFloat(t.amount), 0) || 0
    const monthlyUsed = monthlyTransfers?.reduce((sum, t) => sum + parseFloat(t.amount), 0) || 0
    const dailyCount = dailyTransfers?.length || 0
    const monthlyCount = monthlyTransfers?.length || 0

    return {
      success: true,
      data: {
        limits: {
          daily_limit: limits.daily_limit,
          monthly_limit: limits.monthly_limit,
          per_transaction_limit: limits.per_transaction_limit,
          daily_transaction_count: limits.daily_transaction_count,
          monthly_transaction_count: limits.monthly_transaction_count,
          minimum_transfer_amount: limits.minimum_transfer_amount,
        },
        usage: {
          daily_used: dailyUsed,
          monthly_used: monthlyUsed,
          daily_count: dailyCount,
          monthly_count: monthlyCount,
          daily_remaining: Math.max(0, limits.daily_limit - dailyUsed),
          monthly_remaining: Math.max(0, limits.monthly_limit - monthlyUsed),
          daily_count_remaining: Math.max(0, limits.daily_transaction_count - dailyCount),
          monthly_count_remaining: Math.max(0, limits.monthly_transaction_count - monthlyCount),
        },
      },
    }
  } catch (error) {
    console.error('❌ [WALLET-TRANSFER] Get limits error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function calculateTransferFees(
  supabaseClient: any,
  userId: string,
  amount: number
): Promise<TransferResponse> {
  try {
    // Get active transfer fees
    const { data: fees, error } = await supabaseClient
      .from('transfer_fees')
      .select('*')
      .eq('is_active', true)
      .eq('currency', 'MYR')
      .order('created_at', { ascending: false })

    if (error || !fees || fees.length === 0) {
      return {
        success: true,
        data: {
          transfer_fee: 0,
          net_amount: amount,
          fee_breakdown: [],
        },
      }
    }

    let totalFee = 0
    const feeBreakdown = []

    for (const fee of fees) {
      let calculatedFee = 0

      switch (fee.fee_type) {
        case 'fixed':
          calculatedFee = fee.fixed_amount
          break
        case 'percentage':
          calculatedFee = amount * fee.percentage_rate
          break
        case 'tiered':
          // Implement tiered fee calculation
          if (fee.tier_ranges) {
            for (const tier of fee.tier_ranges) {
              if (amount >= tier.min && (tier.max === null || amount <= tier.max)) {
                calculatedFee = tier.fee
                break
              }
            }
          }
          break
      }

      // Apply minimum and maximum fee constraints
      if (fee.minimum_fee && calculatedFee < fee.minimum_fee) {
        calculatedFee = fee.minimum_fee
      }
      if (fee.maximum_fee && calculatedFee > fee.maximum_fee) {
        calculatedFee = fee.maximum_fee
      }

      totalFee += calculatedFee
      feeBreakdown.push({
        name: fee.fee_name,
        type: fee.fee_type,
        amount: calculatedFee,
      })
    }

    return {
      success: true,
      data: {
        transfer_fee: totalFee,
        net_amount: amount - totalFee,
        fee_breakdown: feeBreakdown,
      },
    }
  } catch (error) {
    console.error('❌ [WALLET-TRANSFER] Calculate fees error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function initiateTransfer(
  supabaseClient: any,
  senderId: string,
  transferData: { recipient_identifier: string; amount: number; description?: string }
): Promise<TransferResponse> {
  try {
    const { recipient_identifier, amount, description } = transferData

    // Validate recipient
    const recipientValidation = await validateRecipient(supabaseClient, senderId, recipient_identifier)
    if (!recipientValidation.success) {
      return recipientValidation
    }

    const recipient = recipientValidation.data

    // Get sender wallet
    const { data: senderWallet, error: senderWalletError } = await supabaseClient
      .from('stakeholder_wallets')
      .select('*')
      .eq('user_id', senderId)
      .eq('user_role', 'customer')
      .single()

    if (senderWalletError || !senderWallet) {
      return {
        success: false,
        error: 'Sender wallet not found',
      }
    }

    // Check transfer limits
    const limitsResponse = await getTransferLimits(supabaseClient, senderId)
    if (!limitsResponse.success) {
      return limitsResponse
    }

    const { limits, usage } = limitsResponse.data

    // Validate transfer amount against limits
    if (amount < limits.minimum_transfer_amount) {
      return {
        success: false,
        error: `Minimum transfer amount is RM ${limits.minimum_transfer_amount}`,
      }
    }

    if (amount > limits.per_transaction_limit) {
      return {
        success: false,
        error: `Maximum transfer amount is RM ${limits.per_transaction_limit}`,
      }
    }

    if (usage.daily_used + amount > limits.daily_limit) {
      return {
        success: false,
        error: `Daily transfer limit exceeded. Remaining: RM ${usage.daily_remaining}`,
      }
    }

    if (usage.monthly_used + amount > limits.monthly_limit) {
      return {
        success: false,
        error: `Monthly transfer limit exceeded. Remaining: RM ${usage.monthly_remaining}`,
      }
    }

    if (usage.daily_count >= limits.daily_transaction_count) {
      return {
        success: false,
        error: `Daily transaction count limit exceeded`,
      }
    }

    if (usage.monthly_count >= limits.monthly_transaction_count) {
      return {
        success: false,
        error: `Monthly transaction count limit exceeded`,
      }
    }

    // Calculate transfer fees
    const feesResponse = await calculateTransferFees(supabaseClient, senderId, amount)
    if (!feesResponse.success) {
      return feesResponse
    }

    const { transfer_fee, net_amount } = feesResponse.data

    // Check if sender has sufficient balance (including fees)
    if (senderWallet.available_balance < amount) {
      return {
        success: false,
        error: `Insufficient balance. Available: RM ${senderWallet.available_balance}`,
      }
    }

    // Get recipient wallet
    const { data: recipientWallet, error: recipientWalletError } = await supabaseClient
      .from('stakeholder_wallets')
      .select('*')
      .eq('id', recipient.wallet_id)
      .single()

    if (recipientWalletError || !recipientWallet) {
      return {
        success: false,
        error: 'Recipient wallet not found',
      }
    }

    // Generate reference number
    const { data: referenceData, error: refError } = await supabaseClient
      .rpc('generate_transfer_reference')

    if (refError) {
      throw new Error(`Failed to generate reference number: ${refError.message}`)
    }

    const referenceNumber = referenceData

    // Start database transaction
    const { data: transfer, error: transferError } = await supabaseClient
      .from('wallet_transfers')
      .insert({
        sender_wallet_id: senderWallet.id,
        recipient_wallet_id: recipientWallet.id,
        sender_user_id: senderId,
        recipient_user_id: recipient.user_id,
        amount: amount,
        transfer_fee: transfer_fee,
        net_amount: net_amount,
        description: description,
        reference_number: referenceNumber,
        status: 'processing',
        sender_balance_before: senderWallet.available_balance,
        sender_balance_after: senderWallet.available_balance - amount,
        recipient_balance_before: recipientWallet.available_balance,
        recipient_balance_after: recipientWallet.available_balance + net_amount,
        ip_address: '127.0.0.1', // TODO: Get real IP from request
        user_agent: 'GigaEats Mobile App', // TODO: Get real user agent
      })
      .select()
      .single()

    if (transferError) {
      throw new Error(`Failed to create transfer record: ${transferError.message}`)
    }

    // Process the actual transfer (atomic operation)
    const transferResult = await processTransfer(supabaseClient, transfer)

    return transferResult
  } catch (error) {
    console.error('❌ [WALLET-TRANSFER] Initiate transfer error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function processTransfer(supabaseClient: any, transfer: any): Promise<TransferResponse> {
  try {
    // Create sender transaction (debit)
    const { data: senderTransaction, error: senderTxnError } = await supabaseClient
      .from('wallet_transactions')
      .insert({
        wallet_id: transfer.sender_wallet_id,
        transaction_type: 'transfer_out',
        amount: -transfer.amount, // Negative for debit
        currency: transfer.currency,
        balance_before: transfer.sender_balance_before,
        balance_after: transfer.sender_balance_after,
        reference_type: 'wallet_transfer',
        reference_id: transfer.id,
        description: `Transfer to ${transfer.recipient_user_id}: ${transfer.description || 'Wallet transfer'}`,
        processed_by: transfer.sender_user_id,
        processing_fee: transfer.transfer_fee,
        processed_at: new Date().toISOString(),
      })
      .select()
      .single()

    if (senderTxnError) {
      throw new Error(`Failed to create sender transaction: ${senderTxnError.message}`)
    }

    // Create recipient transaction (credit)
    const { data: recipientTransaction, error: recipientTxnError } = await supabaseClient
      .from('wallet_transactions')
      .insert({
        wallet_id: transfer.recipient_wallet_id,
        transaction_type: 'transfer_in',
        amount: transfer.net_amount, // Positive for credit
        currency: transfer.currency,
        balance_before: transfer.recipient_balance_before,
        balance_after: transfer.recipient_balance_after,
        reference_type: 'wallet_transfer',
        reference_id: transfer.id,
        description: `Transfer from ${transfer.sender_user_id}: ${transfer.description || 'Wallet transfer'}`,
        processed_by: transfer.sender_user_id,
        processing_fee: 0, // Recipient doesn't pay fees
        processed_at: new Date().toISOString(),
      })
      .select()
      .single()

    if (recipientTxnError) {
      // Rollback sender transaction
      await supabaseClient
        .from('wallet_transactions')
        .delete()
        .eq('id', senderTransaction.id)

      throw new Error(`Failed to create recipient transaction: ${recipientTxnError.message}`)
    }

    // Update sender wallet balance
    const { error: senderWalletError } = await supabaseClient
      .from('stakeholder_wallets')
      .update({
        available_balance: transfer.sender_balance_after,
        last_activity_at: new Date().toISOString(),
      })
      .eq('id', transfer.sender_wallet_id)

    if (senderWalletError) {
      throw new Error(`Failed to update sender wallet: ${senderWalletError.message}`)
    }

    // Update recipient wallet balance
    const { error: recipientWalletError } = await supabaseClient
      .from('stakeholder_wallets')
      .update({
        available_balance: transfer.recipient_balance_after,
        last_activity_at: new Date().toISOString(),
      })
      .eq('id', transfer.recipient_wallet_id)

    if (recipientWalletError) {
      throw new Error(`Failed to update recipient wallet: ${recipientWalletError.message}`)
    }

    // Update transfer status to completed
    const { data: completedTransfer, error: updateError } = await supabaseClient
      .from('wallet_transfers')
      .update({
        status: 'completed',
        processed_at: new Date().toISOString(),
        sender_transaction_id: senderTransaction.id,
        recipient_transaction_id: recipientTransaction.id,
      })
      .eq('id', transfer.id)
      .select()
      .single()

    if (updateError) {
      throw new Error(`Failed to update transfer status: ${updateError.message}`)
    }

    console.log(`✅ [WALLET-TRANSFER] Transfer completed: ${transfer.reference_number}`)

    return {
      success: true,
      data: completedTransfer,
      message: 'Transfer completed successfully',
    }
  } catch (error) {
    // Mark transfer as failed
    await supabaseClient
      .from('wallet_transfers')
      .update({
        status: 'failed',
        failed_at: new Date().toISOString(),
        failure_reason: error.message,
      })
      .eq('id', transfer.id)

    console.error('❌ [WALLET-TRANSFER] Process transfer error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}

async function getTransferHistory(
  supabaseClient: any,
  userId: string,
  page: number,
  limit: number
): Promise<TransferResponse> {
  try {
    const offset = page * limit

    const { data: transfers, error } = await supabaseClient
      .from('wallet_transfers')
      .select(`
        *,
        sender_profile:sender_user_id(full_name, email),
        recipient_profile:recipient_user_id(full_name, email)
      `)
      .or(`sender_user_id.eq.${userId},recipient_user_id.eq.${userId}`)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1)

    if (error) {
      throw new Error(`Failed to fetch transfer history: ${error.message}`)
    }

    // Get total count for pagination
    const { count, error: countError } = await supabaseClient
      .from('wallet_transfers')
      .select('*', { count: 'exact', head: true })
      .or(`sender_user_id.eq.${userId},recipient_user_id.eq.${userId}`)

    if (countError) {
      throw new Error(`Failed to get transfer count: ${countError.message}`)
    }

    return {
      success: true,
      data: {
        transfers: transfers || [],
        pagination: {
          page,
          limit,
          total: count || 0,
          has_more: (count || 0) > offset + limit,
        },
      },
    }
  } catch (error) {
    console.error('❌ [WALLET-TRANSFER] Get history error:', error)
    return {
      success: false,
      error: error.message,
    }
  }
}
