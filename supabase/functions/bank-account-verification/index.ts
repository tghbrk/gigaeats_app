import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface VerificationRequest {
  action: 'initiate_verification' | 'submit_verification' | 'get_verification_status' | 
          'resend_verification' | 'verify_identity' | 'update_verification_documents'
  
  // Bank account details
  bank_details?: {
    bank_name: string
    bank_code: string
    account_number: string
    account_holder_name: string
    account_type?: string
  }
  
  // Verification method and data
  verification_method?: 'micro_deposit' | 'instant_verification' | 'document_verification' | 'manual_verification' | 'unified_verification'
  verification_code?: string
  verification_amounts?: number[]
  
  // Identity verification
  identity_documents?: {
    ic_number?: string // Malaysian IC number
    ic_front_image?: string // Base64 encoded image
    ic_back_image?: string // Base64 encoded image
    selfie_image?: string // Base64 encoded selfie
    bank_statement?: string // Base64 encoded bank statement
  }
  
  // Request tracking
  account_id?: string
  verification_id?: string
  
  metadata?: Record<string, any>
}

interface VerificationResponse {
  success: boolean
  data?: any
  error?: string
  error_code?: string
  timestamp: string
}

// Malaysian IC validation regex
const MALAYSIAN_IC_REGEX = /^\d{6}-\d{2}-\d{4}$/

// Encryption key for sensitive data (in production, use proper key management)
const ENCRYPTION_KEY = Deno.env.get('BANK_VERIFICATION_ENCRYPTION_KEY') || 'default-key-change-in-production'

serve(async (req) => {
  const timestamp = new Date().toISOString()
  console.log(`🔐 [BANK-VERIFICATION-${timestamp}] Function called - Method: ${req.method}`)

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client with service role key
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get the authorization header for user authentication
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('No authorization header')
    }

    // Verify the JWT token
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)

    if (authError || !user) {
      console.error('❌ Auth error:', authError)
      throw new Error('Invalid authentication token')
    }

    console.log('✅ User authenticated:', user.id)

    const requestBody: VerificationRequest = await req.json()
    console.log('🔍 [BANK-VERIFICATION] Request action:', requestBody.action)

    const { action } = requestBody
    let response: any

    switch (action) {
      case 'initiate_verification':
        response = await initiateVerification(supabaseClient, user.id, requestBody)
        break
      case 'submit_verification':
        response = await submitVerification(supabaseClient, user.id, requestBody)
        break
      case 'get_verification_status':
        response = await getVerificationStatus(supabaseClient, user.id, requestBody)
        break
      case 'resend_verification':
        response = await resendVerification(supabaseClient, user.id, requestBody)
        break
      case 'verify_identity':
        response = await verifyIdentity(supabaseClient, user.id, requestBody)
        break
      case 'update_verification_documents':
        response = await updateVerificationDocuments(supabaseClient, user.id, requestBody)
        break
      default:
        throw new Error(`Unsupported action: ${action}`)
    }

    return new Response(
      JSON.stringify({ success: true, data: response, timestamp }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('❌ [BANK-VERIFICATION] Error:', error.message)
    
    // Determine error code based on error message
    let errorCode = 'UNKNOWN_ERROR'
    if (error.message.includes('Unauthorized')) errorCode = 'UNAUTHORIZED'
    else if (error.message.includes('Invalid IC')) errorCode = 'INVALID_IC_NUMBER'
    else if (error.message.includes('Invalid bank')) errorCode = 'INVALID_BANK_DETAILS'
    else if (error.message.includes('Verification failed')) errorCode = 'VERIFICATION_FAILED'
    else if (error.message.includes('Document')) errorCode = 'INVALID_DOCUMENT'
    else if (error.message.includes('not found')) errorCode = 'NOT_FOUND'
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message,
        error_code: errorCode,
        timestamp: new Date().toISOString()
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    )
  }
})

async function validateDriverAccess(supabase: any, userId: string) {
  console.log('🔍 Validating driver access for user:', userId)

  const { data: driver, error } = await supabase
    .from('drivers')
    .select('id, status, is_active')
    .eq('user_id', userId)
    .single()

  if (error || !driver) {
    throw new Error('Driver profile not found')
  }

  if (!driver.is_active) {
    throw new Error('Driver account is not active')
  }

  console.log('✅ Driver access validated successfully')
  return driver
}

// Helper function to merge JSONB data safely
async function mergeEncryptedDetails(supabase: any, accountId: string, newData: any) {
  console.log('🔄 Merging encrypted details for account:', accountId)

  // First get the current encrypted_details
  const { data: currentAccount, error: fetchError } = await supabase
    .from('driver_bank_accounts')
    .select('encrypted_details')
    .eq('id', accountId)
    .single()

  if (fetchError) {
    console.error('❌ Error fetching current account data:', fetchError)
    throw new Error('Failed to fetch current account data')
  }

  // Merge the data
  const currentDetails = currentAccount?.encrypted_details || {}
  const mergedDetails = { ...currentDetails, ...newData }

  // Update with merged data
  const { error: updateError } = await supabase
    .from('driver_bank_accounts')
    .update({ encrypted_details: mergedDetails })
    .eq('id', accountId)

  if (updateError) {
    console.error('❌ Error updating encrypted details:', updateError)
    throw new Error('Failed to update encrypted details')
  }

  console.log('✅ Encrypted details merged successfully')
}

async function encryptSensitiveData(data: string): Promise<string> {
  // Simple encryption for demo - in production use proper encryption libraries
  const encoder = new TextEncoder()
  const keyData = encoder.encode(ENCRYPTION_KEY)
  const dataToEncrypt = encoder.encode(data)
  
  const key = await crypto.subtle.importKey(
    'raw',
    keyData,
    { name: 'AES-GCM' },
    false,
    ['encrypt']
  )
  
  const iv = crypto.getRandomValues(new Uint8Array(12))
  const encrypted = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    key,
    dataToEncrypt
  )
  
  // Combine IV and encrypted data
  const combined = new Uint8Array(iv.length + encrypted.byteLength)
  combined.set(iv)
  combined.set(new Uint8Array(encrypted), iv.length)
  
  // Convert to base64
  return btoa(String.fromCharCode(...combined))
}

async function decryptSensitiveData(encryptedData: string): Promise<string> {
  try {
    const combined = new Uint8Array(atob(encryptedData).split('').map(c => c.charCodeAt(0)))
    const iv = combined.slice(0, 12)
    const encrypted = combined.slice(12)
    
    const encoder = new TextEncoder()
    const keyData = encoder.encode(ENCRYPTION_KEY)
    
    const key = await crypto.subtle.importKey(
      'raw',
      keyData,
      { name: 'AES-GCM' },
      false,
      ['decrypt']
    )
    
    const decrypted = await crypto.subtle.decrypt(
      { name: 'AES-GCM', iv },
      key,
      encrypted
    )
    
    const decoder = new TextDecoder()
    return decoder.decode(decrypted)
  } catch (error) {
    console.error('Decryption failed:', error)
    throw new Error('Failed to decrypt sensitive data')
  }
}

function validateMalaysianIC(icNumber: string): boolean {
  if (!MALAYSIAN_IC_REGEX.test(icNumber)) {
    return false
  }
  
  // Additional validation logic for Malaysian IC
  const cleanIC = icNumber.replace(/-/g, '')
  const birthDate = cleanIC.substring(0, 6)
  const stateCode = cleanIC.substring(6, 8)
  const serialNumber = cleanIC.substring(8, 12)
  
  // Validate birth date format (YYMMDD)
  const year = parseInt(birthDate.substring(0, 2))
  const month = parseInt(birthDate.substring(2, 4))
  const day = parseInt(birthDate.substring(4, 6))
  
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return false
  }
  
  // Validate state code (01-16 for Malaysian states)
  const stateNum = parseInt(stateCode)
  if (stateNum < 1 || stateNum > 16) {
    return false
  }
  
  return true
}

async function validateBankAccountOwnership(bankDetails: any, icNumber: string): Promise<boolean> {
  // In production, this would integrate with Malaysian banking APIs
  // to verify account ownership against IC number
  console.log('🔍 Validating bank account ownership')
  
  // Simulate validation (90% success rate for demo)
  const isValid = Math.random() > 0.1
  
  // Additional checks could include:
  // - Name matching between IC and bank account
  // - Account status verification
  // - Account holder verification through bank APIs
  
  return isValid
}

async function initiateVerification(supabase: any, userId: string, request: VerificationRequest) {
  const { bank_details, verification_method = 'micro_deposit', identity_documents } = request

  console.log('🔍 Initiating bank account verification:', { verification_method })

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  if (!bank_details) {
    throw new Error('Bank details are required for verification')
  }

  // Validate Malaysian IC if provided
  if (identity_documents?.ic_number) {
    if (!validateMalaysianIC(identity_documents.ic_number)) {
      throw new Error('Invalid Malaysian IC number format')
    }
  }

  // Check if account already exists
  const { data: existingAccount } = await supabase
    .from('driver_bank_accounts')
    .select('*')
    .eq('driver_id', driver.id)
    .eq('account_number', bank_details.account_number)
    .eq('bank_code', bank_details.bank_code)
    .maybeSingle()

  if (existingAccount && existingAccount.verification_status === 'verified') {
    return {
      account_id: existingAccount.id,
      verification_status: 'verified',
      message: 'Bank account already verified'
    }
  }

  // Encrypt sensitive data
  const encryptedAccountNumber = await encryptSensitiveData(bank_details.account_number)
  const encryptedICNumber = identity_documents?.ic_number ?
    await encryptSensitiveData(identity_documents.ic_number) : null

  // Create or update bank account record
  const accountData = {
    driver_id: driver.id,
    user_id: userId,
    bank_name: bank_details.bank_name,
    bank_code: bank_details.bank_code.toUpperCase(),
    account_number: bank_details.account_number, // Store plain for queries
    account_holder_name: bank_details.account_holder_name,
    account_type: bank_details.account_type || 'savings',
    verification_method,
    verification_status: 'pending',
    verification_attempts: (existingAccount?.verification_attempts || 0) + 1,
    encrypted_details: {
      encrypted_account_number: encryptedAccountNumber,
      encrypted_ic_number: encryptedICNumber,
      verification_initiated_at: new Date().toISOString()
    }
  }

  let accountId: string

  if (existingAccount) {
    // Update existing account
    const { data: updatedAccount, error } = await supabase
      .from('driver_bank_accounts')
      .update(accountData)
      .eq('id', existingAccount.id)
      .select('id')
      .single()

    if (error) {
      throw new Error(`Failed to update bank account: ${error.message}`)
    }
    accountId = updatedAccount.id
  } else {
    // Create new account
    const { data: newAccount, error } = await supabase
      .from('driver_bank_accounts')
      .insert(accountData)
      .select('id')
      .single()

    if (error) {
      throw new Error(`Failed to create bank account: ${error.message}`)
    }
    accountId = newAccount.id
  }

  // Process verification based on method
  let verificationResult
  switch (verification_method) {
    case 'micro_deposit':
      verificationResult = await initiateMicroDepositVerification(supabase, accountId, bank_details)
      break
    case 'instant_verification':
      verificationResult = await initiateInstantVerification(supabase, accountId, bank_details, identity_documents)
      break
    case 'document_verification':
      verificationResult = await initiateDocumentVerification(supabase, accountId, identity_documents)
      break
    case 'manual_verification':
      verificationResult = await initiateManualVerification(supabase, accountId, bank_details, identity_documents)
      break
    case 'unified_verification':
      verificationResult = await initiateUnifiedVerification(supabase, accountId, bank_details, identity_documents)
      break
    default:
      throw new Error(`Unsupported verification method: ${verification_method}`)
  }

  // Update verification reference
  await supabase
    .from('driver_bank_accounts')
    .update({
      verification_reference: verificationResult.reference,
      updated_at: new Date().toISOString()
    })
    .eq('id', accountId)

  console.log('✅ Bank account verification initiated')
  return {
    account_id: accountId,
    verification_method,
    verification_reference: verificationResult.reference,
    verification_result: verificationResult,
    next_steps: verificationResult.next_steps
  }
}

async function initiateMicroDepositVerification(supabase: any, accountId: string, bankDetails: any) {
  console.log('🔍 Initiating micro deposit verification')

  // Generate random micro deposit amounts (RM 0.01 to RM 0.99)
  const amount1 = Math.floor(Math.random() * 99) + 1 // 1-99 cents
  const amount2 = Math.floor(Math.random() * 99) + 1 // 1-99 cents

  const reference = `MICRO_${Date.now()}_${accountId.substring(0, 8)}`

  // In production, integrate with Malaysian payment gateway to send micro deposits
  // For now, simulate the process

  // Store verification details (encrypted)
  const verificationData = {
    amounts: [amount1, amount2],
    initiated_at: new Date().toISOString(),
    expected_completion: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // 24 hours
    attempts_remaining: 3
  }

  const encryptedVerificationData = await encryptSensitiveData(JSON.stringify(verificationData))

  // Store in database using helper function
  await mergeEncryptedDetails(supabase, accountId, {
    micro_deposit_data: encryptedVerificationData
  })

  return {
    reference,
    status: 'pending',
    message: 'Micro deposits will be sent to your account within 1-2 business days. Please check your account and enter the amounts received.',
    expected_completion: verificationData.expected_completion,
    next_steps: [
      'Check your bank account for two small deposits within 1-2 business days',
      'Note the exact amounts received (in cents)',
      'Return to submit the verification amounts'
    ]
  }
}

async function initiateInstantVerification(supabase: any, accountId: string, bankDetails: any, identityDocs?: any) {
  console.log('🔍 Initiating instant verification')

  const reference = `INSTANT_${Date.now()}_${accountId.substring(0, 8)}`

  // In production, integrate with Malaysian banking APIs for instant verification
  // This could include services like:
  // - Bank Negara Malaysia's Credit Bureau
  // - Individual bank APIs (Maybank, CIMB, etc.)
  // - Third-party verification services

  // Simulate instant verification process
  let verificationSuccess = false
  let failureReason = ''

  // Check if we have IC number for enhanced verification
  if (identityDocs?.ic_number) {
    const icValid = validateMalaysianIC(identityDocs.ic_number)
    const accountOwnershipValid = await validateBankAccountOwnership(bankDetails, identityDocs.ic_number)

    verificationSuccess = icValid && accountOwnershipValid
    if (!icValid) failureReason = 'Invalid IC number'
    else if (!accountOwnershipValid) failureReason = 'Account ownership verification failed'
  } else {
    // Basic verification without IC (lower success rate)
    verificationSuccess = Math.random() > 0.3 // 70% success rate
    if (!verificationSuccess) failureReason = 'Unable to verify account instantly'
  }

  if (verificationSuccess) {
    // Update account status to verified
    await supabase
      .from('driver_bank_accounts')
      .update({
        verification_status: 'verified',
        verified_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', accountId)

    return {
      reference,
      status: 'verified',
      message: 'Bank account verified successfully through instant verification',
      verified_at: new Date().toISOString(),
      next_steps: ['Your bank account is now verified and ready for withdrawals']
    }
  } else {
    return {
      reference,
      status: 'failed',
      message: `Instant verification failed: ${failureReason}`,
      failure_reason: failureReason,
      next_steps: [
        'Try micro deposit verification instead',
        'Ensure your IC number matches your bank account',
        'Contact support if the issue persists'
      ]
    }
  }
}

async function initiateDocumentVerification(supabase: any, accountId: string, identityDocs?: any) {
  console.log('🔍 Initiating document verification')

  const reference = `DOC_${Date.now()}_${accountId.substring(0, 8)}`

  if (!identityDocs) {
    throw new Error('Identity documents are required for document verification')
  }

  // Validate required documents
  const requiredDocs = ['ic_front_image', 'ic_back_image', 'selfie_image']
  const missingDocs = requiredDocs.filter(doc => !identityDocs[doc])

  if (missingDocs.length > 0) {
    throw new Error(`Missing required documents: ${missingDocs.join(', ')}`)
  }

  // In production, integrate with document verification services like:
  // - Jumio
  // - Onfido
  // - Local Malaysian KYC providers

  // Store encrypted document data
  const documentData = {
    documents_uploaded: Object.keys(identityDocs).filter(key => identityDocs[key]),
    uploaded_at: new Date().toISOString(),
    verification_status: 'pending_review',
    estimated_completion: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString() // 2 days
  }

  const encryptedDocumentData = await encryptSensitiveData(JSON.stringify(documentData))

  // Update account with document verification data
  await mergeEncryptedDetails(supabase, accountId, {
    document_verification_data: encryptedDocumentData
  })

  await supabase
    .from('driver_bank_accounts')
    .update({
      verification_status: 'pending',
      updated_at: new Date().toISOString()
    })
    .eq('id', accountId)

  return {
    reference,
    status: 'pending_review',
    message: 'Documents uploaded successfully. Our team will review them within 1-2 business days.',
    estimated_completion: documentData.estimated_completion,
    next_steps: [
      'Our verification team will review your documents',
      'You will be notified once verification is complete',
      'Ensure all documents are clear and readable'
    ]
  }
}

async function initiateManualVerification(supabase: any, accountId: string, bankDetails: any, identityDocs?: any) {
  console.log('🔍 Initiating manual verification')

  const reference = `MANUAL_${Date.now()}_${accountId.substring(0, 8)}`

  // Manual verification requires admin intervention
  const verificationData = {
    bank_details: bankDetails,
    identity_documents_provided: identityDocs ? Object.keys(identityDocs).filter(key => identityDocs[key]) : [],
    initiated_at: new Date().toISOString(),
    status: 'pending_admin_review',
    estimated_completion: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString() // 3 days
  }

  const encryptedVerificationData = await encryptSensitiveData(JSON.stringify(verificationData))

  // Update account status
  await mergeEncryptedDetails(supabase, accountId, {
    manual_verification_data: encryptedVerificationData
  })

  await supabase
    .from('driver_bank_accounts')
    .update({
      verification_status: 'pending',
      updated_at: new Date().toISOString()
    })
    .eq('id', accountId)

  // Create admin notification (in production, send to admin dashboard)
  console.log('📧 Admin notification: Manual verification required for account:', accountId)

  return {
    reference,
    status: 'pending_admin_review',
    message: 'Your account has been queued for manual verification by our team.',
    estimated_completion: verificationData.estimated_completion,
    next_steps: [
      'Our verification team will manually review your account',
      'You may be contacted for additional information',
      'Verification typically takes 2-3 business days'
    ]
  }
}

async function initiateUnifiedVerification(supabase: any, accountId: string, bankDetails: any, identityDocs?: any) {
  console.log('🔍 Initiating unified verification (bank account + document verification)')

  const reference = `UNIFIED_${Date.now()}_${accountId.substring(0, 8)}`

  // Validate that we have both bank details and identity documents
  if (!bankDetails) {
    throw new Error('Bank details are required for unified verification')
  }

  if (!identityDocs) {
    throw new Error('Identity documents are required for unified verification')
  }

  // Validate required documents for unified verification
  const requiredDocs = ['ic_front_image', 'ic_back_image']
  const missingDocs = requiredDocs.filter(doc => !identityDocs[doc])

  if (missingDocs.length > 0) {
    throw new Error(`Missing required documents for unified verification: ${missingDocs.join(', ')}`)
  }

  // Step 1: Attempt instant bank account verification with IC validation
  console.log('🏦 Step 1: Attempting instant bank account verification...')
  let bankVerificationSuccess = false
  let bankFailureReason = ''

  // Enhanced verification with IC number
  if (identityDocs.ic_number) {
    const icValid = validateMalaysianIC(identityDocs.ic_number)
    const accountOwnershipValid = await validateBankAccountOwnership(bankDetails, identityDocs.ic_number)

    bankVerificationSuccess = icValid && accountOwnershipValid
    if (!icValid) bankFailureReason = 'Invalid IC number format'
    else if (!accountOwnershipValid) bankFailureReason = 'Account ownership verification failed'
  } else {
    // Try basic bank verification without IC
    bankVerificationSuccess = Math.random() > 0.5 // 50% success rate without IC
    if (!bankVerificationSuccess) bankFailureReason = 'Unable to verify bank account without IC number'
  }

  // Step 2: Process document verification regardless of bank verification result
  console.log('📄 Step 2: Processing document verification...')
  const documentData = {
    documents_uploaded: Object.keys(identityDocs).filter(key => identityDocs[key]),
    uploaded_at: new Date().toISOString(),
    verification_status: 'pending_review',
    estimated_completion: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString() // 1 day for unified
  }

  // Step 3: Determine overall verification status and next steps
  let overallStatus: string
  let message: string
  let nextSteps: string[]
  let estimatedCompletion: string

  if (bankVerificationSuccess) {
    // Bank verification succeeded, documents still need review
    overallStatus = 'bank_verified_docs_pending'
    message = 'Bank account verified instantly. Document verification is in progress.'
    nextSteps = [
      '✅ Bank account verification completed',
      '⏳ Document verification in progress',
      'You will be notified once document review is complete',
      'Partial withdrawals may be available with verified bank account'
    ]
    estimatedCompletion = documentData.estimated_completion

    // Update account status to verified for bank, pending for documents
    await supabase
      .from('driver_bank_accounts')
      .update({
        verification_status: 'verified', // Bank is verified
        verified_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', accountId)

  } else {
    // Bank verification failed, fall back to document-based verification
    overallStatus = 'pending_document_review'
    message = `Bank instant verification failed (${bankFailureReason}). Processing document-based verification.`
    nextSteps = [
      '❌ Instant bank verification failed',
      '⏳ Document-based verification in progress',
      'Our team will verify both your identity and bank account through documents',
      'Verification typically takes 1-2 business days'
    ]
    estimatedCompletion = documentData.estimated_completion

    // Keep account status as pending
    await supabase
      .from('driver_bank_accounts')
      .update({
        verification_status: 'pending',
        updated_at: new Date().toISOString()
      })
      .eq('id', accountId)
  }

  // Step 4: Store unified verification data
  const unifiedVerificationData = {
    verification_type: 'unified_verification',
    bank_verification: {
      attempted: true,
      success: bankVerificationSuccess,
      failure_reason: bankFailureReason,
      verified_at: bankVerificationSuccess ? new Date().toISOString() : null
    },
    document_verification: {
      documents_uploaded: documentData.documents_uploaded,
      uploaded_at: documentData.uploaded_at,
      status: 'pending_review'
    },
    overall_status: overallStatus,
    initiated_at: new Date().toISOString(),
    estimated_completion: estimatedCompletion
  }

  const encryptedUnifiedData = await encryptSensitiveData(JSON.stringify(unifiedVerificationData))

  // Update account with unified verification data
  await mergeEncryptedDetails(supabase, accountId, {
    unified_verification_data: encryptedUnifiedData
  })

  // Step 5: Update stakeholder wallet verification status if bank verification succeeded
  if (bankVerificationSuccess) {
    console.log('💰 Updating stakeholder wallet verification status...')

    // Get the driver's user_id from the bank account
    const { data: bankAccount } = await supabase
      .from('driver_bank_accounts')
      .select('user_id')
      .eq('id', accountId)
      .single()

    if (bankAccount) {
      await supabase
        .from('stakeholder_wallets')
        .update({
          is_verified: true,
          verification_documents: {
            bank_account_verified: true,
            documents_pending: true,
            verified_at: new Date().toISOString(),
            verification_method: 'unified_verification'
          },
          updated_at: new Date().toISOString()
        })
        .eq('user_id', bankAccount.user_id)
        .eq('user_role', 'driver')
    }
  }

  console.log('✅ Unified verification initiated successfully')
  return {
    reference,
    status: overallStatus,
    message,
    bank_verification_success: bankVerificationSuccess,
    documents_uploaded: documentData.documents_uploaded.length,
    estimated_completion: estimatedCompletion,
    next_steps: nextSteps
  }
}

async function submitVerification(supabase: any, userId: string, request: VerificationRequest) {
  const { account_id, verification_code, verification_amounts } = request

  console.log('🔍 Submitting verification for account:', account_id)

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  // Get account details
  const { data: account, error } = await supabase
    .from('driver_bank_accounts')
    .select('*')
    .eq('id', account_id)
    .eq('driver_id', driver.id)
    .single()

  if (error || !account) {
    throw new Error('Bank account not found or access denied')
  }

  if (account.verification_status === 'verified') {
    return {
      account_id,
      verification_status: 'verified',
      message: 'Account already verified'
    }
  }

  // Process based on verification method
  let verificationResult
  switch (account.verification_method) {
    case 'micro_deposit':
      verificationResult = await processMicroDepositVerification(supabase, account, verification_amounts)
      break
    case 'instant_verification':
      verificationResult = await processInstantVerificationCode(supabase, account, verification_code)
      break
    default:
      throw new Error(`Verification submission not supported for method: ${account.verification_method}`)
  }

  // Update account status based on result
  const newStatus = verificationResult.success ? 'verified' : 'failed'
  await supabase
    .from('driver_bank_accounts')
    .update({
      verification_status: newStatus,
      verified_at: verificationResult.success ? new Date().toISOString() : null,
      verification_attempts: account.verification_attempts + 1,
      updated_at: new Date().toISOString()
    })
    .eq('id', account_id)

  console.log('✅ Verification submission processed')
  return {
    account_id,
    verification_status: newStatus,
    verification_result: verificationResult
  }
}

async function processMicroDepositVerification(supabase: any, account: any, submittedAmounts?: number[]) {
  if (!submittedAmounts || submittedAmounts.length !== 2) {
    throw new Error('Two verification amounts are required for micro deposit verification')
  }

  // Decrypt stored verification data
  const encryptedData = account.encrypted_details?.micro_deposit_data
  if (!encryptedData) {
    throw new Error('Micro deposit verification data not found')
  }

  const decryptedData = await decryptSensitiveData(encryptedData)
  const verificationData = JSON.parse(decryptedData)

  // Check if verification has expired (24 hours)
  const expirationTime = new Date(verificationData.expected_completion)
  if (new Date() > expirationTime) {
    return {
      success: false,
      error: 'Verification has expired. Please initiate a new verification.',
      expired: true
    }
  }

  // Validate amounts
  const expectedAmounts = verificationData.amounts.sort((a: number, b: number) => a - b)
  const submittedSorted = submittedAmounts.sort((a, b) => a - b)

  const amountsMatch = expectedAmounts.length === submittedSorted.length &&
    expectedAmounts.every((amount: number, index: number) => amount === submittedSorted[index])

  if (amountsMatch) {
    return {
      success: true,
      message: 'Micro deposit verification successful',
      verified_at: new Date().toISOString()
    }
  } else {
    const attemptsRemaining = Math.max(0, verificationData.attempts_remaining - 1)

    // Update attempts remaining
    verificationData.attempts_remaining = attemptsRemaining
    const updatedEncryptedData = await encryptSensitiveData(JSON.stringify(verificationData))

    await mergeEncryptedDetails(supabase, account.id, {
      micro_deposit_data: updatedEncryptedData
    })

    return {
      success: false,
      error: 'Verification amounts do not match',
      attempts_remaining: attemptsRemaining,
      locked: attemptsRemaining === 0
    }
  }
}

async function processInstantVerificationCode(supabase: any, account: any, verificationCode?: string) {
  if (!verificationCode) {
    throw new Error('Verification code is required')
  }

  // In production, validate the verification code against the expected value
  // For demo, accept specific codes
  const validCodes = ['123456', '000000', 'VERIFY']

  if (validCodes.includes(verificationCode.toUpperCase())) {
    return {
      success: true,
      message: 'Instant verification successful',
      verified_at: new Date().toISOString()
    }
  } else {
    return {
      success: false,
      error: 'Invalid verification code'
    }
  }
}

async function getVerificationStatus(supabase: any, userId: string, request: VerificationRequest) {
  const { account_id } = request

  console.log('🔍 Getting verification status for account:', account_id)

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  // Get account details
  const { data: account, error } = await supabase
    .from('driver_bank_accounts')
    .select('*')
    .eq('id', account_id)
    .eq('driver_id', driver.id)
    .single()

  if (error || !account) {
    throw new Error('Bank account not found or access denied')
  }

  // Prepare response with masked sensitive data
  const response = {
    account_id: account.id,
    bank_name: account.bank_name,
    bank_code: account.bank_code,
    account_number: maskAccountNumber(account.account_number),
    account_holder_name: account.account_holder_name,
    verification_status: account.verification_status,
    verification_method: account.verification_method,
    verification_reference: account.verification_reference,
    verification_attempts: account.verification_attempts,
    created_at: account.created_at,
    verified_at: account.verified_at,
    is_primary: account.is_primary,
    is_active: account.is_active
  }

  // Add method-specific status information
  if (account.verification_method === 'micro_deposit' && account.encrypted_details?.micro_deposit_data) {
    try {
      const decryptedData = await decryptSensitiveData(account.encrypted_details.micro_deposit_data)
      const verificationData = JSON.parse(decryptedData)

      response.micro_deposit_status = {
        expected_completion: verificationData.expected_completion,
        attempts_remaining: verificationData.attempts_remaining,
        expired: new Date() > new Date(verificationData.expected_completion)
      }
    } catch (error) {
      console.error('Failed to decrypt micro deposit data:', error)
    }
  }

  console.log('✅ Verification status retrieved')
  return response
}

async function resendVerification(supabase: any, userId: string, request: VerificationRequest) {
  const { account_id } = request

  console.log('🔍 Resending verification for account:', account_id)

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  // Get account details
  const { data: account, error } = await supabase
    .from('driver_bank_accounts')
    .select('*')
    .eq('id', account_id)
    .eq('driver_id', driver.id)
    .single()

  if (error || !account) {
    throw new Error('Bank account not found or access denied')
  }

  if (account.verification_status === 'verified') {
    throw new Error('Account is already verified')
  }

  // Check if enough time has passed since last attempt (prevent spam)
  const lastAttempt = new Date(account.updated_at)
  const timeSinceLastAttempt = Date.now() - lastAttempt.getTime()
  const minimumWaitTime = 5 * 60 * 1000 // 5 minutes

  if (timeSinceLastAttempt < minimumWaitTime) {
    const remainingWait = Math.ceil((minimumWaitTime - timeSinceLastAttempt) / 1000 / 60)
    throw new Error(`Please wait ${remainingWait} minutes before requesting verification resend`)
  }

  // Process based on verification method
  let resendResult
  switch (account.verification_method) {
    case 'micro_deposit':
      resendResult = await resendMicroDepositVerification(supabase, account)
      break
    case 'instant_verification':
      resendResult = await resendInstantVerification(supabase, account)
      break
    case 'document_verification':
      resendResult = await resendDocumentVerification(supabase, account)
      break
    default:
      throw new Error(`Resend not supported for verification method: ${account.verification_method}`)
  }

  // Update verification reference and attempt count
  await supabase
    .from('driver_bank_accounts')
    .update({
      verification_reference: resendResult.reference,
      verification_attempts: account.verification_attempts + 1,
      updated_at: new Date().toISOString()
    })
    .eq('id', account_id)

  console.log('✅ Verification resent successfully')
  return resendResult
}

async function resendMicroDepositVerification(supabase: any, account: any) {
  // Generate new micro deposit amounts
  const amount1 = Math.floor(Math.random() * 99) + 1
  const amount2 = Math.floor(Math.random() * 99) + 1

  const reference = `MICRO_RESEND_${Date.now()}_${account.id.substring(0, 8)}`

  const verificationData = {
    amounts: [amount1, amount2],
    initiated_at: new Date().toISOString(),
    expected_completion: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    attempts_remaining: 3,
    resent: true
  }

  const encryptedVerificationData = await encryptSensitiveData(JSON.stringify(verificationData))

  // Update stored verification data
  await mergeEncryptedDetails(supabase, account.id, {
    micro_deposit_data: encryptedVerificationData
  })

  return {
    reference,
    status: 'resent',
    message: 'New micro deposits will be sent to your account within 1-2 business days.',
    expected_completion: verificationData.expected_completion
  }
}

async function resendInstantVerification(supabase: any, account: any) {
  const reference = `INSTANT_RESEND_${Date.now()}_${account.id.substring(0, 8)}`

  return {
    reference,
    status: 'resent',
    message: 'Instant verification has been reset. Please try again.',
    next_steps: ['Submit verification with your IC number and bank details']
  }
}

async function resendDocumentVerification(supabase: any, account: any) {
  const reference = `DOC_RESEND_${Date.now()}_${account.id.substring(0, 8)}`

  return {
    reference,
    status: 'resent',
    message: 'Document verification has been reset. Please upload your documents again.',
    next_steps: ['Upload clear photos of your IC (front and back)', 'Upload a clear selfie photo']
  }
}

function maskAccountNumber(accountNumber: string): string {
  if (!accountNumber || accountNumber.length < 4) {
    return '****'
  }

  const visibleDigits = 4
  const maskedPart = '*'.repeat(accountNumber.length - visibleDigits)
  const visiblePart = accountNumber.slice(-visibleDigits)

  return maskedPart + visiblePart
}

async function verifyIdentity(supabase: any, userId: string, request: VerificationRequest) {
  const { account_id, identity_documents } = request

  console.log('🔍 Verifying identity for account:', account_id)

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  if (!identity_documents) {
    throw new Error('Identity documents are required for identity verification')
  }

  // Get account details
  const { data: account, error } = await supabase
    .from('driver_bank_accounts')
    .select('*')
    .eq('id', account_id)
    .eq('driver_id', driver.id)
    .single()

  if (error || !account) {
    throw new Error('Bank account not found or access denied')
  }

  // Validate Malaysian IC
  if (identity_documents.ic_number && !validateMalaysianIC(identity_documents.ic_number)) {
    throw new Error('Invalid Malaysian IC number format')
  }

  // Perform identity verification checks
  const verificationChecks = {
    ic_validation: false,
    document_quality: false,
    face_match: false,
    name_match: false,
    overall_score: 0
  }

  // IC validation
  if (identity_documents.ic_number) {
    verificationChecks.ic_validation = validateMalaysianIC(identity_documents.ic_number)
  }

  // Document quality check (simulated)
  if (identity_documents.ic_front_image && identity_documents.ic_back_image) {
    verificationChecks.document_quality = await simulateDocumentQualityCheck(
      identity_documents.ic_front_image,
      identity_documents.ic_back_image
    )
  }

  // Face matching (simulated)
  if (identity_documents.selfie_image && identity_documents.ic_front_image) {
    verificationChecks.face_match = await simulateFaceMatching(
      identity_documents.selfie_image,
      identity_documents.ic_front_image
    )
  }

  // Name matching
  if (identity_documents.ic_number && account.account_holder_name) {
    verificationChecks.name_match = await simulateNameMatching(
      identity_documents.ic_number,
      account.account_holder_name
    )
  }

  // Calculate overall score
  const checks = Object.values(verificationChecks).slice(0, -1) // Exclude overall_score
  const passedChecks = checks.filter(check => check === true).length
  verificationChecks.overall_score = (passedChecks / checks.length) * 100

  // Determine verification result
  const isVerified = verificationChecks.overall_score >= 80 // 80% threshold

  // Store verification result
  const verificationResult = {
    verification_checks: verificationChecks,
    verified: isVerified,
    verified_at: isVerified ? new Date().toISOString() : null,
    verification_score: verificationChecks.overall_score
  }

  const encryptedResult = await encryptSensitiveData(JSON.stringify(verificationResult))

  // Update account with identity verification result
  await mergeEncryptedDetails(supabase, account_id, {
    identity_verification_result: encryptedResult
  })

  const updateData = {
    updated_at: new Date().toISOString()
  }

  if (isVerified) {
    updateData.verification_status = 'verified'
    updateData.verified_at = new Date().toISOString()
  }

  await supabase
    .from('driver_bank_accounts')
    .update(updateData)
    .eq('id', account_id)

  console.log('✅ Identity verification completed')
  return {
    account_id,
    verification_status: isVerified ? 'verified' : 'failed',
    verification_score: verificationChecks.overall_score,
    verification_checks: {
      ic_validation: verificationChecks.ic_validation,
      document_quality: verificationChecks.document_quality,
      face_match: verificationChecks.face_match,
      name_match: verificationChecks.name_match
    },
    message: isVerified ?
      'Identity verification successful' :
      'Identity verification failed. Please ensure all documents are clear and accurate.'
  }
}

async function updateVerificationDocuments(supabase: any, userId: string, request: VerificationRequest) {
  const { account_id, identity_documents } = request

  console.log('🔍 Updating verification documents for account:', account_id)

  // Validate driver access
  const driver = await validateDriverAccess(supabase, userId)

  if (!identity_documents) {
    throw new Error('Identity documents are required')
  }

  // Get account details
  const { data: account, error } = await supabase
    .from('driver_bank_accounts')
    .select('*')
    .eq('id', account_id)
    .eq('driver_id', driver.id)
    .single()

  if (error || !account) {
    throw new Error('Bank account not found or access denied')
  }

  if (account.verification_status === 'verified') {
    throw new Error('Cannot update documents for already verified account')
  }

  // Encrypt and store updated documents
  const documentData = {
    documents_updated: Object.keys(identity_documents).filter(key => identity_documents[key]),
    updated_at: new Date().toISOString(),
    previous_documents: account.encrypted_details?.document_verification_data || null
  }

  const encryptedDocumentData = await encryptSensitiveData(JSON.stringify(documentData))

  // Update account with new document data
  await mergeEncryptedDetails(supabase, account_id, {
    document_verification_data: encryptedDocumentData
  })

  await supabase
    .from('driver_bank_accounts')
    .update({
      verification_status: 'pending',
      updated_at: new Date().toISOString()
    })
    .eq('id', account_id)

  console.log('✅ Verification documents updated')
  return {
    account_id,
    status: 'documents_updated',
    message: 'Verification documents updated successfully. Review process will restart.',
    documents_updated: documentData.documents_updated,
    next_steps: [
      'Our verification team will review your updated documents',
      'You will be notified once verification is complete'
    ]
  }
}

// Simulation functions for document verification (replace with real services in production)
async function simulateDocumentQualityCheck(frontImage: string, backImage: string): Promise<boolean> {
  // Simulate document quality analysis
  // In production, use services like Jumio, Onfido, or local providers
  return Math.random() > 0.2 // 80% pass rate
}

async function simulateFaceMatching(selfieImage: string, icImage: string): Promise<boolean> {
  // Simulate face matching between selfie and IC photo
  // In production, use facial recognition services
  return Math.random() > 0.15 // 85% pass rate
}

async function simulateNameMatching(icNumber: string, accountHolderName: string): Promise<boolean> {
  // Simulate name matching between IC and bank account
  // In production, integrate with Malaysian government databases
  return Math.random() > 0.1 // 90% pass rate
}
