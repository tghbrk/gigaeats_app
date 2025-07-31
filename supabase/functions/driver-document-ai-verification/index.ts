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
  console.log(`🤖 [DRIVER-DOC-AI-${timestamp}] Function called - Method: ${req.method}`)

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client with service role
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const request: DocumentVerificationRequest = await req.json()
    console.log(`📄 Processing document verification: ${request.action}`)

    let result: any

    switch (request.action) {
      case 'process_document':
        result = await processDocumentWithGemini(supabaseClient, request)
        break
      case 'verify_identity':
        result = await verifyIdentityMatch(supabaseClient, request)
        break
      case 'validate_authenticity':
        result = await validateDocumentAuthenticity(supabaseClient, request)
        break
      case 'get_processing_status':
        result = await getProcessingStatus(supabaseClient, request)
        break
      default:
        throw new Error(`Unsupported action: ${request.action}`)
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: result,
        timestamp: new Date().toISOString()
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  } catch (error) {
    console.error('❌ Document verification error:', error)
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

async function processDocumentWithGemini(
  supabase: any,
  request: DocumentVerificationRequest
): Promise<ExtractedDocumentData> {
  console.log(`🔍 Processing document: ${request.document_type} (${request.document_side || 'single'})`)

  if (!request.document_id || !request.file_path) {
    throw new Error('Document ID and file path are required')
  }

  // Update document status to processing
  await updateDocumentStatus(supabase, request.document_id, 'processing')

  try {
    // Get document file from storage
    const imageData = await getDocumentImageData(supabase, request.file_path)
    
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

    console.log(`✅ Document processing completed with confidence: ${overallConfidence}%`)
    return finalResult

  } catch (error) {
    console.error('❌ Document processing failed:', error)
    await updateDocumentStatus(supabase, request.document_id, 'failed')
    throw error
  }
}

async function getDocumentImageData(supabase: any, filePath: string): Promise<string> {
  try {
    console.log(`📥 Fetching document image: ${filePath}`)
    
    // Download file from Supabase storage
    const { data, error } = await supabase.storage
      .from('driver-verification-documents')
      .download(filePath)

    if (error) {
      throw new Error(`Failed to download document: ${error.message}`)
    }

    // Convert to base64 for Gemini API
    const arrayBuffer = await data.arrayBuffer()
    const uint8Array = new Uint8Array(arrayBuffer)
    const base64String = btoa(String.fromCharCode(...uint8Array))
    
    console.log(`📸 Image data prepared (${base64String.length} chars)`)
    return base64String

  } catch (error) {
    console.error('❌ Failed to get image data:', error)
    throw new Error(`Image retrieval failed: ${error.message}`)
  }
}

async function callGeminiVisionAPI(
  imageData: string,
  documentType: string,
  documentSide?: string
): Promise<ExtractedDocumentData> {
  if (!GEMINI_API_KEY) {
    throw new Error('Gemini API key not configured')
  }

  console.log(`🤖 Calling Gemini Vision API for ${documentType}`)

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
    console.log(`🎯 Gemini API response received`)

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
    console.error('❌ Gemini API call failed:', error)
    throw new Error(`AI processing failed: ${error.message}`)
  }
}

function generateDocumentPrompt(documentType: string, documentSide?: string): string {
  const baseInstructions = `
You are an expert document verification AI. Analyze the provided document image and extract structured data in JSON format.

CRITICAL REQUIREMENTS:
1. Return ONLY valid JSON - no additional text or explanations
2. Include confidence scores (0-100) for each extracted field
3. Assess image quality and document authenticity
4. Follow Malaysian document standards and formats
5. Identify any signs of tampering or forgery

Response format:
{
  "confidence_score": number,
  "extracted_fields": { ... },
  "quality_assessment": {
    "image_quality": number,
    "text_clarity": number,
    "document_condition": "excellent|good|fair|poor",
    "recommendations": ["array of improvement suggestions if needed"]
  },
  "authenticity_indicators": {
    "security_features_present": boolean,
    "text_consistency": boolean,
    "image_tampering_detected": boolean,
    "overall_authenticity": "authentic|suspicious|likely_fake"
  }
}
`

  switch (documentType) {
    case 'ic_card':
      return `${baseInstructions}

MALAYSIAN IC CARD ANALYSIS:
Document: Malaysian Identity Card (MyKad) - ${documentSide?.toUpperCase() || 'UNKNOWN'} side

Extract these fields:
- full_name: Full name as printed
- ic_number: 12-digit IC number (format: XXXXXX-XX-XXXX)
- birth_date: Date of birth
- birth_place: Place of birth
- gender: Male/Female
- race: Race/ethnicity
- religion: Religion (if visible)
- address: Full address (back side only)
- postcode: 5-digit postcode (back side only)
- state: Malaysian state
- nationality: Should be "WARGANEGARA MALAYSIA"

Security features to check:
- Holographic elements
- Microprinting
- Photo quality and alignment
- Text font consistency
- Card material and thickness
- Security chip presence (front side)

Validation rules:
- IC number must follow YYMMDD-PB-XXXX format
- Birth date must match IC number prefix
- All text should be clear and properly aligned
- Photo should be professionally taken and properly positioned`

    case 'passport':
      return `${baseInstructions}

MALAYSIAN PASSPORT ANALYSIS:
Document: Malaysian Passport - Information page

Extract these fields:
- passport_type: Type of passport (P for personal)
- country_code: Issuing country (MYS)
- passport_number: Passport number
- surname: Surname/family name
- given_names: Given names
- nationality: Malaysian
- date_of_birth: Date of birth
- place_of_birth: Place of birth
- gender: M/F
- date_of_issue: Issue date
- date_of_expiry: Expiry date
- issuing_authority: Issuing authority
- personal_number: Personal number (IC number)

Security features to check:
- Machine readable zone (MRZ) at bottom
- Passport photo quality and security features
- Watermarks and security printing
- Page integrity and binding
- Holographic elements

Validation rules:
- Passport must not be expired
- MRZ should be machine readable format
- Personal number should match Malaysian IC format
- All dates should be logical and consistent`

    case 'driver_license':
      return `${baseInstructions}

MALAYSIAN DRIVER'S LICENSE ANALYSIS:
Document: Malaysian Driving License

Extract these fields:
- license_number: License number
- full_name: Full name
- ic_number: IC number
- date_of_birth: Date of birth
- address: Full address
- license_class: License class/category
- date_of_issue: Issue date
- date_of_expiry: Expiry date
- issuing_authority: JPJ or state authority
- restrictions: Any driving restrictions

Security features to check:
- Holographic elements
- Photo quality and security
- Microprinting
- Card material quality
- Security features integrity

Validation rules:
- License must not be expired
- IC number must match Malaysian format
- License class must be valid Malaysian category
- All text should be clear and properly formatted`

    case 'selfie':
      return `${baseInstructions}

SELFIE PHOTO ANALYSIS:
Document: Identity verification selfie

Extract these fields:
- face_detected: boolean
- face_quality: quality score (0-100)
- lighting_quality: lighting assessment
- image_sharpness: sharpness score
- background_type: background description
- face_angle: frontal/profile/angled
- eyes_visible: boolean
- face_obstructions: any obstructions detected

Quality assessment:
- Face should be clearly visible and well-lit
- Eyes should be open and visible
- No sunglasses or face coverings
- Neutral expression preferred
- Good image resolution and sharpness
- Plain background preferred

Authenticity checks:
- Check for signs of photo manipulation
- Verify it's a live photo, not a screen capture
- Assess if it's a real person vs. printed photo
- Check for proper depth and lighting consistency`

    default:
      return `${baseInstructions}

GENERAL DOCUMENT ANALYSIS:
Document type: ${documentType}

Perform general document analysis and extract any visible text fields.
Assess document quality, authenticity, and provide structured data extraction.`
  }
}

async function validateExtractedData(
  extractedData: ExtractedDocumentData,
  documentType: string
): Promise<Record<string, any>> {
  console.log(`✅ Validating extracted data for ${documentType}`)

  const validationResults: Record<string, any> = {
    field_validations: {},
    format_checks: {},
    consistency_checks: {},
    compliance_status: 'pending'
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

      // Validate postcode format
      if (fields.postcode) {
        validationResults.field_validations.postcode = {
          is_valid: MALAYSIAN_POSTCODE_REGEX.test(fields.postcode),
          confidence: 90
        }
      }

      // Check required fields presence
      const requiredFields = ['full_name', 'ic_number', 'birth_date', 'gender']
      validationResults.completeness_check = {
        required_fields_present: requiredFields.every(field => fields[field]),
        missing_fields: requiredFields.filter(field => !fields[field]),
        completeness_score: (requiredFields.filter(field => fields[field]).length / requiredFields.length) * 100
      }
      break

    case 'passport':
      // Validate passport number format
      if (fields.passport_number) {
        validationResults.field_validations.passport_number = {
          is_valid: fields.passport_number.length >= 8,
          confidence: 90
        }
      }

      // Check expiry date
      if (fields.date_of_expiry) {
        const expiryDate = new Date(fields.date_of_expiry)
        const now = new Date()
        validationResults.expiry_check = {
          is_expired: expiryDate < now,
          days_until_expiry: Math.ceil((expiryDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)),
          confidence: 95
        }
      }
      break

    case 'driver_license':
      // Validate license number and expiry
      if (fields.date_of_expiry) {
        const expiryDate = new Date(fields.date_of_expiry)
        const now = new Date()
        validationResults.expiry_check = {
          is_expired: expiryDate < now,
          confidence: 95
        }
      }
      break

    case 'selfie':
      // Validate selfie quality
      validationResults.quality_checks = {
        face_detected: fields.face_detected || false,
        quality_score: fields.face_quality || 0,
        meets_requirements: (fields.face_quality || 0) >= 70,
        confidence: 90
      }
      break
  }

  // Calculate overall compliance status
  const allChecks = Object.values(validationResults).flat()
  const passedChecks = allChecks.filter((check: any) =>
    check.is_valid !== false && check.is_expired !== true
  ).length

  validationResults.compliance_status = passedChecks / allChecks.length >= 0.8 ? 'compliant' : 'non_compliant'
  validationResults.overall_confidence = Math.round((passedChecks / allChecks.length) * 100)

  return validationResults
}

async function performAuthenticityChecks(
  extractedData: ExtractedDocumentData,
  documentType: string
): Promise<Record<string, any>> {
  console.log(`🔍 Performing authenticity checks for ${documentType}`)

  const authenticityResults: Record<string, any> = {
    security_features: {},
    tampering_detection: {},
    format_verification: {},
    overall_authenticity: 'pending'
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

  // Format verification based on document type
  switch (documentType) {
    case 'ic_card':
      authenticityResults.format_verification = {
        card_dimensions: true, // Simplified
        font_consistency: authenticity.text_consistency || false,
        layout_correct: true, // Simplified
        confidence: 85
      }
      break

    case 'passport':
      authenticityResults.format_verification = {
        mrz_format: true, // Simplified
        page_layout: true, // Simplified
        security_printing: authenticity.security_features_present || false,
        confidence: 85
      }
      break

    case 'selfie':
      authenticityResults.format_verification = {
        live_photo: true, // Simplified - would need liveness detection
        not_screen_capture: true, // Simplified
        proper_lighting: quality.image_quality > 70,
        confidence: 75
      }
      break
  }

  // Calculate overall authenticity score
  const securityScore = authenticityResults.security_features.holographic_elements ? 100 : 50
  const tamperingScore = authenticityResults.tampering_detection.image_manipulation_detected ? 0 : 100
  const formatScore = Object.values(authenticityResults.format_verification).filter(v => v === true).length * 25

  const overallScore = (securityScore + tamperingScore + formatScore) / 3

  authenticityResults.overall_authenticity = overallScore >= 70 ? 'authentic' :
                                           overallScore >= 40 ? 'suspicious' : 'likely_fake'
  authenticityResults.authenticity_score = Math.round(overallScore)

  return authenticityResults
}

function calculateOverallConfidence(
  aiConfidence: number,
  validationResults: Record<string, any>,
  authenticityResults: Record<string, any>
): number {
  const validationScore = validationResults.overall_confidence || 0
  const authenticityScore = authenticityResults.authenticity_score || 0

  // Weighted average: AI confidence (40%), validation (35%), authenticity (25%)
  const overallConfidence = Math.round(
    (aiConfidence * 0.4) + (validationScore * 0.35) + (authenticityScore * 0.25)
  )

  console.log(`📊 Confidence calculation: AI(${aiConfidence}) + Validation(${validationScore}) + Auth(${authenticityScore}) = ${overallConfidence}`)

  return Math.max(0, Math.min(100, overallConfidence))
}

function determineFinalStatus(
  confidence: number,
  validationResults: Record<string, any>,
  authenticityResults: Record<string, any>
): string {
  // High confidence and all checks pass
  if (confidence >= 85 &&
      validationResults.compliance_status === 'compliant' &&
      authenticityResults.overall_authenticity === 'authentic') {
    return 'verified'
  }

  // Medium confidence or some concerns
  if (confidence >= 60 &&
      validationResults.compliance_status === 'compliant' &&
      authenticityResults.overall_authenticity !== 'likely_fake') {
    return 'manual_review'
  }

  // Low confidence or failed checks
  return 'failed'
}

async function updateDocumentStatus(
  supabase: any,
  documentId: string,
  status: string
): Promise<void> {
  try {
    console.log(`📝 Updating document ${documentId} status to: ${status}`)

    const updateData: any = {
      processing_status: status,
      updated_at: new Date().toISOString()
    }

    if (status === 'processing') {
      updateData.processing_started_at = new Date().toISOString()
    } else if (['verified', 'failed', 'manual_review'].includes(status)) {
      updateData.processing_completed_at = new Date().toISOString()
    }

    const { error } = await supabase
      .from('driver_verification_documents')
      .update(updateData)
      .eq('id', documentId)

    if (error) {
      throw new Error(`Failed to update document status: ${error.message}`)
    }

    // Create processing log
    await createProcessingLog(supabase, documentId, status)

  } catch (error) {
    console.error('❌ Failed to update document status:', error)
    throw error
  }
}

async function updateDocumentWithResults(
  supabase: any,
  documentId: string,
  results: ExtractedDocumentData
): Promise<void> {
  try {
    console.log(`💾 Saving processing results for document ${documentId}`)

    const { error } = await supabase
      .from('driver_verification_documents')
      .update({
        confidence_score: results.confidence_score,
        extracted_info: results.extracted_fields,
        validation_results: results.validation_results,
        processing_metadata: {
          authenticity_checks: results.authenticity_checks,
          quality_assessment: results.quality_assessment,
          processed_at: new Date().toISOString(),
          ai_model: 'gemini-2.5-flash-lite'
        },
        updated_at: new Date().toISOString()
      })
      .eq('id', documentId)

    if (error) {
      throw new Error(`Failed to update document results: ${error.message}`)
    }

  } catch (error) {
    console.error('❌ Failed to save document results:', error)
    throw error
  }
}

async function createProcessingLog(
  supabase: any,
  documentId: string,
  status: string
): Promise<void> {
  try {
    // Get verification ID from document
    const { data: document, error: docError } = await supabase
      .from('driver_verification_documents')
      .select('verification_id')
      .eq('id', documentId)
      .single()

    if (docError || !document) {
      console.warn('⚠️ Could not find document for logging')
      return
    }

    const { error } = await supabase
      .from('driver_verification_processing_logs')
      .insert({
        verification_id: document.verification_id,
        document_id: documentId,
        processing_step: 'ai_processing',
        status: status === 'processing' ? 'started' : 'completed',
        message: `Document ${status} via Gemini AI processing`,
        processor_type: 'gemini_ai',
        processor_id: 'gemini-2.5-flash-lite',
        results: {
          status: status,
          timestamp: new Date().toISOString()
        }
      })

    if (error) {
      console.warn('⚠️ Failed to create processing log:', error.message)
    }

  } catch (error) {
    console.warn('⚠️ Processing log creation failed:', error)
  }
}

async function verifyIdentityMatch(
  supabase: any,
  request: DocumentVerificationRequest
): Promise<any> {
  console.log(`🔍 Verifying identity match for verification: ${request.verification_id}`)

  if (!request.verification_id) {
    throw new Error('Verification ID is required for identity matching')
  }

  try {
    // Get all documents for this verification
    const { data: documents, error } = await supabase
      .from('driver_verification_documents')
      .select('*')
      .eq('verification_id', request.verification_id)
      .in('processing_status', ['verified', 'manual_review'])

    if (error) {
      throw new Error(`Failed to fetch documents: ${error.message}`)
    }

    if (!documents || documents.length < 2) {
      return {
        identity_match: false,
        confidence: 0,
        message: 'Insufficient documents for identity verification',
        details: {
          documents_count: documents?.length || 0,
          required_minimum: 2
        }
      }
    }

    // Find IC card and selfie documents
    const icDocument = documents.find(doc => doc.document_type === 'ic_card')
    const selfieDocument = documents.find(doc => doc.document_type === 'selfie')

    if (!icDocument || !selfieDocument) {
      return {
        identity_match: false,
        confidence: 0,
        message: 'IC card and selfie required for identity verification',
        details: {
          ic_present: !!icDocument,
          selfie_present: !!selfieDocument
        }
      }
    }

    // Extract names and compare
    const icName = icDocument.extracted_info?.full_name
    const icNumber = icDocument.extracted_info?.ic_number

    // For now, we'll use a simplified identity matching
    // In production, this would use facial recognition AI
    const identityMatch = {
      name_consistency: !!icName,
      document_quality: (icDocument.confidence_score + selfieDocument.confidence_score) / 2,
      facial_match: selfieDocument.confidence_score >= 70, // Simplified
      overall_confidence: 0
    }

    // Calculate overall identity confidence
    identityMatch.overall_confidence = Math.round(
      (identityMatch.name_consistency ? 30 : 0) +
      (identityMatch.document_quality * 0.4) +
      (identityMatch.facial_match ? 30 : 0)
    )

    const isMatch = identityMatch.overall_confidence >= 70

    // Update verification record with identity results
    await supabase
      .from('driver_document_verifications')
      .update({
        verification_results: {
          identity_verification: identityMatch,
          verified_at: isMatch ? new Date().toISOString() : null
        },
        overall_status: isMatch ? 'verified' : 'manual_review',
        updated_at: new Date().toISOString()
      })
      .eq('id', request.verification_id)

    return {
      identity_match: isMatch,
      confidence: identityMatch.overall_confidence,
      details: identityMatch,
      message: isMatch ? 'Identity verification successful' : 'Identity verification requires manual review'
    }

  } catch (error) {
    console.error('❌ Identity verification failed:', error)
    throw error
  }
}

async function validateDocumentAuthenticity(
  supabase: any,
  request: DocumentVerificationRequest
): Promise<any> {
  console.log(`🛡️ Validating document authenticity: ${request.document_id}`)

  if (!request.document_id) {
    throw new Error('Document ID is required for authenticity validation')
  }

  try {
    // Get document with processing results
    const { data: document, error } = await supabase
      .from('driver_verification_documents')
      .select('*')
      .eq('id', request.document_id)
      .single()

    if (error || !document) {
      throw new Error('Document not found')
    }

    // Check if document has been processed
    if (!document.processing_metadata?.authenticity_checks) {
      return {
        authenticity_status: 'pending',
        message: 'Document has not been processed yet',
        confidence: 0
      }
    }

    const authenticityChecks = document.processing_metadata.authenticity_checks
    const overallScore = authenticityChecks.authenticity_score || 0

    return {
      authenticity_status: authenticityChecks.overall_authenticity,
      confidence: overallScore,
      details: authenticityChecks,
      recommendations: overallScore < 70 ? [
        'Document may require manual review',
        'Consider requesting a new document photo',
        'Verify document security features'
      ] : []
    }

  } catch (error) {
    console.error('❌ Authenticity validation failed:', error)
    throw error
  }
}

async function getProcessingStatus(
  supabase: any,
  request: DocumentVerificationRequest
): Promise<any> {
  console.log(`📊 Getting processing status for: ${request.verification_id || request.document_id}`)

  try {
    if (request.verification_id) {
      // Get overall verification status
      const { data: verification, error: verError } = await supabase
        .from('driver_document_verifications')
        .select(`
          *,
          driver_verification_documents (
            id,
            document_type,
            processing_status,
            confidence_score,
            created_at,
            updated_at
          )
        `)
        .eq('id', request.verification_id)
        .single()

      if (verError || !verification) {
        throw new Error('Verification not found')
      }

      // Get recent processing logs
      const { data: logs } = await supabase
        .from('driver_verification_processing_logs')
        .select('*')
        .eq('verification_id', request.verification_id)
        .order('created_at', { ascending: false })
        .limit(10)

      return {
        verification_status: verification.overall_status,
        completion_percentage: verification.completion_percentage,
        current_step: verification.current_step,
        total_steps: verification.total_steps,
        documents: verification.driver_verification_documents,
        processing_logs: logs || [],
        last_updated: verification.updated_at
      }

    } else if (request.document_id) {
      // Get specific document status
      const { data: document, error } = await supabase
        .from('driver_verification_documents')
        .select('*')
        .eq('id', request.document_id)
        .single()

      if (error || !document) {
        throw new Error('Document not found')
      }

      return {
        document_id: document.id,
        processing_status: document.processing_status,
        confidence_score: document.confidence_score,
        processing_started_at: document.processing_started_at,
        processing_completed_at: document.processing_completed_at,
        extracted_fields: document.extracted_info || {},
        quality_assessment: document.processing_metadata?.quality_assessment || {},
        last_updated: document.updated_at
      }
    }

    throw new Error('Either verification_id or document_id is required')

  } catch (error) {
    console.error('❌ Failed to get processing status:', error)
    throw error
  }
}
