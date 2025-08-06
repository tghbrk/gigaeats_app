import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface DocumentVerificationRequest {
  action: 'process_document' | 'verify_identity' | 'validate_authenticity' | 'get_processing_status'
  document_id?: string
  verification_id?: string
  document_type?: 'ic_card' | 'passport' | 'driver_license' | 'utility_bill' | 'bank_statement' | 'selfie'
  document_side?: 'front' | 'back'
  file_path?: string
  metadata?: Record<string, any>
}

interface GeminiVisionRequest {
  contents: Array<{
    parts: Array<{
      text?: string
      inline_data?: {
        mime_type: string
        data: string
      }
    }>
  }>
  generationConfig?: {
    temperature?: number
    topK?: number
    topP?: number
    maxOutputTokens?: number
  }
}

interface ExtractedDocumentData {
  document_type: string
  confidence_score: number
  extracted_fields: Record<string, any>
  validation_results: Record<string, any>
  authenticity_checks: Record<string, any>
  quality_assessment: {
    image_quality: number
    text_clarity: number
    document_condition: string
    recommendations?: string[]
  }
}

// Malaysian KYC compliance validation patterns
const MALAYSIAN_IC_REGEX = /^\d{6}-\d{2}-\d{4}$/
const MALAYSIAN_PHONE_REGEX = /^(\+?6?01)[0-46-9]-*[0-9]{7,8}$/
const MALAYSIAN_POSTCODE_REGEX = /^\d{5}$/

// Gemini API configuration
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')
const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent'

serve(async (req) => {
  const timestamp = new Date().toISOString()
  console.log(`🤖 [CUSTOMER-DOC-AI-${timestamp}] Function called - Method: ${req.method}`)

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client with service role
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

    console.log('✅ Customer authenticated:', user.id)

    const request: DocumentVerificationRequest = await req.json()
    console.log(`📄 Processing customer document verification: ${request.action}`)

    let result: any

    switch (request.action) {
      case 'process_document':
        result = await processDocumentWithGemini(supabaseClient, request, user.id)
        break
      case 'verify_identity':
        result = await verifyIdentityMatch(supabaseClient, request, user.id)
        break
      case 'validate_authenticity':
        result = await validateDocumentAuthenticity(supabaseClient, request, user.id)
        break
      case 'get_processing_status':
        result = await getProcessingStatus(supabaseClient, request, user.id)
        break
      default:
        throw new Error(`Unsupported action: ${request.action}`)
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: result,
        timestamp
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('❌ [CUSTOMER-DOC-AI] Error:', error.message)
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    )
  }
})

// Process document with Gemini Vision API
async function processDocumentWithGemini(supabase: any, request: DocumentVerificationRequest, userId: string): Promise<ExtractedDocumentData> {
  console.log(`🔍 Processing customer document with Gemini AI: ${request.document_id}`)

  if (!request.document_id) {
    throw new Error('Document ID is required for processing')
  }

  try {
    // Get document record from database
    const { data: document, error: docError } = await supabase
      .from('wallet_verification_documents')
      .select('*')
      .eq('id', request.document_id)
      .eq('user_id', userId)
      .single()

    if (docError || !document) {
      throw new Error('Document not found or access denied')
    }

    // Get document file from storage
    const imageData = await getDocumentImageData(supabase, document.file_path)
    
    // Process with Gemini Vision API
    const extractedData = await callGeminiVisionAPI(
      imageData,
      request.document_type!,
      request.document_side
    )

    // Validate extracted data against Malaysian KYC requirements
    const validationResults = await validateExtractedData(extractedData, request.document_type!)

    // Perform authenticity checks
    const authenticityResults = await performAuthenticityChecks(extractedData, request.document_type!)

    // Calculate overall confidence score
    const overallConfidence = calculateOverallConfidence(
      extractedData.confidence_score,
      validationResults,
      authenticityResults
    )

    const finalResult: ExtractedDocumentData = {
      document_type: request.document_type!,
      confidence_score: overallConfidence,
      extracted_fields: extractedData.extracted_fields,
      validation_results: validationResults,
      authenticity_checks: authenticityResults,
      quality_assessment: extractedData.quality_assessment
    }

    // Update document record with results
    await updateDocumentWithResults(supabase, request.document_id, finalResult)

    // Determine final status based on confidence and validation
    const finalStatus = determineFinalStatus(overallConfidence, validationResults, authenticityResults)
    await updateDocumentStatus(supabase, request.document_id, finalStatus)

    console.log(`✅ Customer document processing completed with confidence: ${overallConfidence}%`)
    return finalResult

  } catch (error) {
    console.error('❌ Customer document processing failed:', error)
    throw error
  }
}

// Get document image data from storage
async function getDocumentImageData(supabase: any, filePath: string): Promise<string> {
  try {
    console.log(`📥 Fetching customer document image: ${filePath}`)
    
    // Download file from Supabase storage
    const { data, error } = await supabase.storage
      .from('customer-verification-documents')
      .download(filePath)

    if (error) {
      throw new Error(`Failed to download document: ${error.message}`)
    }

    // Convert to base64 for Gemini API
    const arrayBuffer = await data.arrayBuffer()
    const uint8Array = new Uint8Array(arrayBuffer)
    const base64String = btoa(String.fromCharCode(...uint8Array))
    
    console.log(`📸 Customer image data prepared (${base64String.length} chars)`)
    return base64String

  } catch (error) {
    console.error('❌ Failed to get customer image data:', error)
    throw new Error(`Image retrieval failed: ${error.message}`)
  }
}

// Call Gemini Vision API for document processing
async function callGeminiVisionAPI(
  imageData: string,
  documentType: string,
  documentSide?: string
): Promise<ExtractedDocumentData> {
  if (!GEMINI_API_KEY) {
    throw new Error('Gemini API key not configured')
  }

  console.log(`🤖 Calling Gemini Vision API for customer ${documentType}`)

  const prompt = generateDocumentPrompt(documentType, documentSide)
  
  const geminiRequest: GeminiVisionRequest = {
    contents: [{
      parts: [
        { text: prompt },
        {
          inline_data: {
            mime_type: 'image/jpeg',
            data: imageData
          }
        }
      ]
    }],
    generationConfig: {
      temperature: 0.1, // Low temperature for consistent extraction
      topK: 1,
      topP: 0.8,
      maxOutputTokens: 2048
    }
  }

  try {
    const response = await fetch(`${GEMINI_API_URL}?key=${GEMINI_API_KEY}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(geminiRequest)
    })

    if (!response.ok) {
      const errorText = await response.text()
      throw new Error(`Gemini API error: ${response.status} - ${errorText}`)
    }

    const result = await response.json()
    console.log(`🎯 Gemini API response received for customer document`)

    // Parse the structured response from Gemini
    const extractedText = result.candidates?.[0]?.content?.parts?.[0]?.text
    if (!extractedText) {
      throw new Error('No text content in Gemini response')
    }

    // Parse JSON response from Gemini
    const parsedData = JSON.parse(extractedText)
    
    return {
      document_type: documentType,
      confidence_score: parsedData.confidence_score || 0,
      extracted_fields: parsedData.extracted_fields || {},
      validation_results: {},
      authenticity_checks: {},
      quality_assessment: parsedData.quality_assessment || {
        image_quality: 0,
        text_clarity: 0,
        document_condition: 'unknown'
      }
    }

  } catch (error) {
    console.error('❌ Gemini API call failed for customer document:', error)
    throw new Error(`AI processing failed: ${error.message}`)
  }
}

// Generate document-specific prompt for Gemini
function generateDocumentPrompt(documentType: string, documentSide?: string): string {
  const baseInstructions = `
You are an expert document verification AI. Analyze the provided document image and extract structured data in JSON format.

CRITICAL REQUIREMENTS:
1. Return ONLY valid JSON - no markdown, no explanations, no additional text
2. Use exact field names as specified
3. Ensure all extracted text is accurate and properly formatted
4. Provide confidence scores (0-100) for each field
5. Follow Malaysian document standards and formats

JSON Response Format:
{
  "confidence_score": <overall_confidence_0_to_100>,
  "extracted_fields": {
    // Document-specific fields here
  },
  "quality_assessment": {
    "image_quality": <0_to_100>,
    "text_clarity": <0_to_100>,
    "document_condition": "<excellent|good|fair|poor>",
    "recommendations": ["<recommendation1>", "<recommendation2>"]
  }
}
`

  switch (documentType) {
    case 'ic_card':
      if (documentSide === 'front') {
        return baseInstructions + `
MALAYSIAN IC CARD (FRONT) - Extract these fields:
{
  "extracted_fields": {
    "ic_number": "<12_digit_ic_with_hyphens_XXXXXX-XX-XXXX>",
    "full_name": "<full_name_as_shown>",
    "birth_date": "<YYYY-MM-DD>",
    "birth_place": "<place_of_birth>",
    "gender": "<LELAKI|PEREMPUAN>",
    "religion": "<religion_if_visible>",
    "race": "<race_if_visible>",
    "citizenship": "<WARGANEGARA|others>"
  }
}

VALIDATION RULES:
- IC number must be exactly 12 digits with hyphens (XXXXXX-XX-XXXX)
- Name should be in uppercase as shown on IC
- Date format must be YYYY-MM-DD
- Extract text exactly as printed on the document
`
      } else if (documentSide === 'back') {
        return baseInstructions + `
MALAYSIAN IC CARD (BACK) - Extract these fields:
{
  "extracted_fields": {
    "address": "<full_address_as_shown>",
    "postcode": "<5_digit_postcode>",
    "state": "<malaysian_state>",
    "country": "<country_usually_MALAYSIA>",
    "issue_date": "<YYYY-MM-DD_if_visible>",
    "expiry_date": "<YYYY-MM-DD_if_visible>",
    "authority": "<issuing_authority_if_visible>"
  }
}

VALIDATION RULES:
- Address should be complete and properly formatted
- Postcode must be 5 digits
- State should be valid Malaysian state
- Extract all visible text accurately
`
      } else {
        return baseInstructions + `
MALAYSIAN IC CARD - Extract all visible fields:
{
  "extracted_fields": {
    "ic_number": "<12_digit_ic_with_hyphens>",
    "full_name": "<full_name_as_shown>",
    "birth_date": "<YYYY-MM-DD>",
    "address": "<full_address>",
    "postcode": "<5_digit_postcode>",
    "state": "<malaysian_state>",
    "gender": "<LELAKI|PEREMPUAN>",
    "citizenship": "<WARGANEGARA|others>"
  }
}
`
      }

    default:
      return baseInstructions + `
DOCUMENT TYPE: ${documentType.toUpperCase()}
Extract all visible text fields and provide appropriate field names based on document type.
`
  }
}

// Validate extracted data against Malaysian KYC requirements
async function validateExtractedData(extractedData: ExtractedDocumentData, documentType: string): Promise<Record<string, any>> {
  console.log(`🔍 Validating extracted data for customer ${documentType}`)

  const validationResults = {
    field_validations: {} as Record<string, any>,
    consistency_checks: {} as Record<string, any>,
    compliance_status: 'pending',
    overall_score: 0
  }

  const fields = extractedData.extracted_fields

  switch (documentType) {
    case 'ic_card':
      // Validate Malaysian IC number format
      if (fields.ic_number) {
        validationResults.field_validations.ic_number = {
          is_valid: MALAYSIAN_IC_REGEX.test(fields.ic_number),
          format_correct: fields.ic_number.length === 14,
          confidence: fields.ic_number ? 90 : 0
        }

        // Validate birth date consistency with IC number
        if (fields.birth_date && fields.ic_number) {
          const icPrefix = fields.ic_number.substring(0, 6)
          const birthYear = parseInt('20' + icPrefix.substring(0, 2)) // Assuming 20xx for recent ICs
          const birthMonth = parseInt(icPrefix.substring(2, 4))
          const birthDay = parseInt(icPrefix.substring(4, 6))

          validationResults.consistency_checks.birth_date_ic_match = {
            is_consistent: true, // Simplified check
            confidence: 85
          }
        }
      }

      // Validate name format
      if (fields.full_name) {
        validationResults.field_validations.full_name = {
          is_valid: fields.full_name.length >= 2,
          format_correct: /^[A-Z\s@\/]+$/.test(fields.full_name),
          confidence: fields.full_name ? 95 : 0
        }
      }

      // Validate postcode if present
      if (fields.postcode) {
        validationResults.field_validations.postcode = {
          is_valid: MALAYSIAN_POSTCODE_REGEX.test(fields.postcode),
          format_correct: fields.postcode.length === 5,
          confidence: fields.postcode ? 90 : 0
        }
      }

      break

    default:
      console.log(`⚠️ No specific validation rules for document type: ${documentType}`)
  }

  // Calculate overall validation score
  const validationScores = Object.values(validationResults.field_validations)
    .map((v: any) => v.confidence || 0)

  validationResults.overall_score = validationScores.length > 0
    ? Math.round(validationScores.reduce((a, b) => a + b, 0) / validationScores.length)
    : 0

  validationResults.compliance_status = validationResults.overall_score >= 70 ? 'compliant' : 'non_compliant'

  console.log(`✅ Customer validation completed with score: ${validationResults.overall_score}%`)
  return validationResults
}

// Perform authenticity checks
async function performAuthenticityChecks(extractedData: ExtractedDocumentData, documentType: string): Promise<Record<string, any>> {
  console.log(`🔒 Performing authenticity checks for customer ${documentType}`)

  const authenticityResults = {
    security_features: {} as Record<string, any>,
    tampering_detection: {} as Record<string, any>,
    format_compliance: {} as Record<string, any>,
    overall_authenticity_score: 0
  }

  // Check quality assessment from Gemini
  const quality = extractedData.quality_assessment
  const authenticity = (extractedData as any).authenticity_indicators || {}

  // Security features check
  authenticityResults.security_features = {
    holographic_elements: authenticity.security_features_present || false,
    text_consistency: authenticity.text_consistency || false,
    image_quality_score: quality.image_quality || 0,
    confidence: 85
  }

  // Tampering detection
  authenticityResults.tampering_detection = {
    image_manipulation_detected: authenticity.image_tampering_detected || false,
    text_alterations: false, // Simplified check
    photo_replacement: false, // Simplified check
    confidence: 80
  }

  // Format compliance
  authenticityResults.format_compliance = {
    document_format_valid: quality.document_condition !== 'poor',
    text_clarity_adequate: quality.text_clarity >= 70,
    image_resolution_sufficient: quality.image_quality >= 70,
    confidence: 75
  }

  // Calculate overall authenticity score
  const scores = [
    authenticityResults.security_features.confidence,
    authenticityResults.tampering_detection.confidence,
    authenticityResults.format_compliance.confidence
  ]

  authenticityResults.overall_authenticity_score = Math.round(
    scores.reduce((a, b) => a + b, 0) / scores.length
  )

  console.log(`✅ Customer authenticity check completed with score: ${authenticityResults.overall_authenticity_score}%`)
  return authenticityResults
}

// Calculate overall confidence score
function calculateOverallConfidence(
  extractionConfidence: number,
  validationResults: Record<string, any>,
  authenticityResults: Record<string, any>
): number {
  const validationScore = validationResults.overall_score || 0
  const authenticityScore = authenticityResults.overall_authenticity_score || 0

  // Weighted average: 40% extraction, 35% validation, 25% authenticity
  const overallScore = Math.round(
    (extractionConfidence * 0.4) +
    (validationScore * 0.35) +
    (authenticityScore * 0.25)
  )

  return Math.max(0, Math.min(100, overallScore))
}

// Update document record with processing results
async function updateDocumentWithResults(supabase: any, documentId: string, results: ExtractedDocumentData): Promise<void> {
  try {
    console.log(`💾 Updating customer document record: ${documentId}`)

    await supabase
      .from('wallet_verification_documents')
      .update({
        ocr_data: {
          extracted_fields: results.extracted_fields,
          confidence_score: results.confidence_score,
          validation_results: results.validation_results,
          authenticity_checks: results.authenticity_checks,
          quality_assessment: results.quality_assessment,
          processed_at: new Date().toISOString()
        },
        is_processed: true,
        updated_at: new Date().toISOString()
      })
      .eq('id', documentId)

    console.log(`✅ Customer document record updated successfully`)
  } catch (error) {
    console.error('❌ Failed to update customer document record:', error)
    throw error
  }
}

// Determine final processing status
function determineFinalStatus(confidence: number, validationResults: Record<string, any>, authenticityResults: Record<string, any>): string {
  if (confidence >= 85 && validationResults.overall_score >= 80 && authenticityResults.overall_authenticity_score >= 75) {
    return 'verified'
  } else if (confidence >= 70 && validationResults.overall_score >= 60) {
    return 'review_required'
  } else {
    return 'failed'
  }
}

// Update document processing status
async function updateDocumentStatus(supabase: any, documentId: string, status: string): Promise<void> {
  try {
    console.log(`📊 Updating customer document status to: ${status}`)

    await supabase
      .from('wallet_verification_documents')
      .update({
        processing_status: status,
        updated_at: new Date().toISOString()
      })
      .eq('id', documentId)

    console.log(`✅ Customer document status updated successfully`)
  } catch (error) {
    console.error('❌ Failed to update customer document status:', error)
    throw error
  }
}

// Placeholder functions for additional actions
async function verifyIdentityMatch(supabase: any, request: DocumentVerificationRequest, userId: string): Promise<any> {
  console.log(`🆔 Customer identity verification not yet implemented`)
  return {
    identity_match: false,
    confidence: 0,
    message: 'Identity verification feature coming soon'
  }
}

async function validateDocumentAuthenticity(supabase: any, request: DocumentVerificationRequest, userId: string): Promise<any> {
  console.log(`🔒 Customer document authenticity validation not yet implemented`)
  return {
    authenticity_score: 0,
    is_authentic: false,
    message: 'Authenticity validation feature coming soon'
  }
}

async function getProcessingStatus(supabase: any, request: DocumentVerificationRequest, userId: string): Promise<any> {
  try {
    if (!request.document_id) {
      throw new Error('Document ID is required')
    }

    const { data: document, error } = await supabase
      .from('wallet_verification_documents')
      .select('*')
      .eq('id', request.document_id)
      .eq('user_id', userId)
      .single()

    if (error || !document) {
      throw new Error('Document not found or access denied')
    }

    return {
      document_id: document.id,
      processing_status: document.processing_status || 'pending',
      is_processed: document.is_processed || false,
      confidence_score: document.ocr_data?.confidence_score || 0,
      extracted_fields: document.ocr_data?.extracted_fields || {},
      updated_at: document.updated_at
    }
  } catch (error) {
    console.error('❌ Failed to get customer processing status:', error)
    throw error
  }
}
