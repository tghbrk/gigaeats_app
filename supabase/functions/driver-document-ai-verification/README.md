# 🤖 Driver Document AI Verification Edge Function

## Overview

The Driver Document AI Verification Edge Function provides comprehensive document verification capabilities using Google Gemini 2.5 Flash Lite AI vision model. It processes uploaded driver verification documents, extracts structured data, validates authenticity, and ensures Malaysian KYC compliance.

## Features

- **AI Vision Processing**: Uses Google Gemini 2.5 Flash Lite for intelligent document analysis
- **Multi-Document Support**: Malaysian IC, passport, driver's license, utility bills, bank statements, and selfies
- **Structured Data Extraction**: Extracts and validates document fields with confidence scoring
- **Authenticity Verification**: Detects tampering, validates security features, and assesses document quality
- **Malaysian KYC Compliance**: Validates documents according to Malaysian regulatory requirements
- **Real-time Processing**: Provides instant feedback with status updates via Supabase subscriptions
- **Identity Matching**: Cross-references multiple documents for identity verification
- **Comprehensive Logging**: Detailed audit trails for compliance and debugging

## Supported Actions

### 1. **process_document**
Processes a single document using AI vision analysis.

```typescript
POST /driver-document-ai-verification
{
  "action": "process_document",
  "document_id": "uuid",
  "verification_id": "uuid",
  "document_type": "ic_card|passport|driver_license|utility_bill|bank_statement|selfie",
  "document_side": "front|back", // Optional, for cards
  "file_path": "storage/path/to/document.jpg",
  "metadata": {}
}
```

### 2. **verify_identity**
Performs cross-document identity verification and matching.

```typescript
POST /driver-document-ai-verification
{
  "action": "verify_identity",
  "verification_id": "uuid"
}
```

### 3. **validate_authenticity**
Validates document authenticity and detects potential forgery.

```typescript
POST /driver-document-ai-verification
{
  "action": "validate_authenticity",
  "document_id": "uuid"
}
```

### 4. **get_processing_status**
Retrieves current processing status and results.

```typescript
POST /driver-document-ai-verification
{
  "action": "get_processing_status",
  "verification_id": "uuid", // OR
  "document_id": "uuid"
}
```

## Document Types & Extraction

### **Malaysian IC Card (MyKad)**
- **Front Side**: Name, IC number, photo, birth date, gender, race, religion
- **Back Side**: Address, postcode, state, nationality
- **Validation**: IC number format (YYMMDD-PB-XXXX), birth date consistency
- **Security**: Holographic elements, microprinting, security chip

### **Malaysian Passport**
- **Information Page**: Passport number, names, nationality, dates, MRZ
- **Validation**: Expiry date, MRZ format, personal number matching
- **Security**: Watermarks, security printing, photo authentication

### **Driver's License**
- **Fields**: License number, name, IC number, address, license class, dates
- **Validation**: Expiry date, license class validity, IC number consistency
- **Security**: Holographic elements, card material quality

### **Selfie Photo**
- **Analysis**: Face detection, quality assessment, lighting evaluation
- **Validation**: Live photo detection, face visibility, image sharpness
- **Identity**: Facial matching with document photos (simplified)

## AI Processing Pipeline

### 1. **Image Preprocessing**
- Download document from Supabase Storage
- Convert to base64 for Gemini API
- Validate image format and quality

### 2. **Gemini Vision Analysis**
- Send structured prompts to Gemini 2.5 Flash Lite
- Extract document-specific fields with confidence scores
- Assess image quality and document condition
- Detect potential tampering or authenticity issues

### 3. **Data Validation**
- Validate extracted fields against Malaysian standards
- Check format compliance (IC numbers, postcodes, dates)
- Verify document expiry and validity
- Cross-reference data consistency

### 4. **Authenticity Assessment**
- Analyze security features and document integrity
- Detect signs of tampering or manipulation
- Evaluate document quality and condition
- Generate authenticity confidence scores

### 5. **Results Processing**
- Calculate overall confidence scores
- Determine verification status (verified/manual_review/failed)
- Update database with structured results
- Create audit logs for compliance

## Configuration

### Environment Variables

```bash
# Required
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
GEMINI_API_KEY=your_gemini_api_key

# Optional
GEMINI_API_URL=https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent
```

### Gemini API Setup

1. **Enable Gemini API** in Google Cloud Console
2. **Create API Key** with appropriate permissions
3. **Configure Quotas** for production usage
4. **Set up Billing** for API usage

## Response Format

### Success Response
```json
{
  "success": true,
  "data": {
    "document_type": "ic_card",
    "confidence_score": 92,
    "extracted_fields": {
      "full_name": "AHMAD BIN ALI",
      "ic_number": "901234-12-3456",
      "birth_date": "1990-12-34",
      "gender": "LELAKI"
    },
    "validation_results": {
      "compliance_status": "compliant",
      "overall_confidence": 88
    },
    "authenticity_checks": {
      "overall_authenticity": "authentic",
      "authenticity_score": 85
    },
    "quality_assessment": {
      "image_quality": 90,
      "text_clarity": 88,
      "document_condition": "excellent"
    }
  },
  "timestamp": "2025-01-29T10:30:00Z"
}
```

### Error Response
```json
{
  "success": false,
  "error": "AI processing failed: Invalid image format",
  "timestamp": "2025-01-29T10:30:00Z"
}
```

## Security & Compliance

### **Data Protection**
- All documents processed in secure environment
- No persistent storage of document images in AI service
- Encrypted data transmission and storage
- Audit trails for all processing activities

### **Malaysian KYC Compliance**
- Validates documents according to Malaysian standards
- Supports required document types for financial services
- Maintains 7-year data retention as required
- Provides comprehensive audit trails

### **PCI DSS Compliance**
- Secure handling of sensitive document data
- Encrypted storage and transmission
- Access controls and authentication
- Regular security assessments

## Performance & Monitoring

### **Processing Times**
- Document analysis: 2-5 seconds
- Identity verification: 3-7 seconds
- Authenticity validation: 1-3 seconds

### **Confidence Thresholds**
- **Verified**: ≥85% confidence + compliant validation + authentic
- **Manual Review**: 60-84% confidence or suspicious authenticity
- **Failed**: <60% confidence or failed validation

### **Monitoring Metrics**
- Processing success rate
- Average confidence scores
- Processing duration
- Error rates by document type
- API usage and costs

## Deployment

### Prerequisites
```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login
```

### Deploy Function
```bash
# Deploy to Supabase
supabase functions deploy driver-document-ai-verification

# Set environment variables
supabase secrets set GEMINI_API_KEY=your_api_key
```

### Testing
```bash
# Test function locally
supabase functions serve driver-document-ai-verification

# Run integration tests
curl -X POST http://localhost:54321/functions/v1/driver-document-ai-verification \
  -H "Content-Type: application/json" \
  -d '{"action": "get_processing_status", "verification_id": "test-id"}'
```

## Troubleshooting

### Common Issues

1. **Gemini API Errors**
   - Check API key configuration
   - Verify quota limits
   - Validate image format and size

2. **Low Confidence Scores**
   - Improve image quality
   - Ensure proper lighting
   - Check document condition

3. **Validation Failures**
   - Verify document format compliance
   - Check expiry dates
   - Validate required fields

### Debug Logging
```bash
# View function logs
supabase functions logs driver-document-ai-verification

# Monitor real-time logs
supabase functions logs driver-document-ai-verification --follow
```

---

**Last Updated**: January 2025  
**Version**: 1.0.0  
**AI Model**: Google Gemini 2.5 Flash Lite  
**Compatibility**: Supabase Edge Functions, Malaysian KYC Standards
