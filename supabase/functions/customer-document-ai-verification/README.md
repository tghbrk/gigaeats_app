# Customer Document AI Verification Edge Function

## Overview

This Edge Function provides AI-powered document verification for customer wallet verification using Google Gemini Vision API. It processes Malaysian IC cards and other identity documents to extract structured data for KYC compliance.

## Features

- **AI Vision Processing**: Uses Google Gemini 2.5 Flash Lite for document analysis
- **Malaysian IC Support**: Specialized processing for Malaysian Identity Cards (front and back)
- **Data Extraction**: Extracts IC number, full name, address, and other key fields
- **Validation & Compliance**: Validates extracted data against Malaysian KYC requirements
- **Authenticity Checks**: Performs document authenticity and tampering detection
- **Secure Processing**: User authentication and data isolation
- **Comprehensive Logging**: Detailed audit trails for compliance and debugging

## Supported Actions

### 1. **process_document**
Processes a single document using AI vision analysis.

```typescript
POST /customer-document-ai-verification
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

**Response:**
```typescript
{
  "success": true,
  "data": {
    "document_type": "ic_card",
    "confidence_score": 92,
    "extracted_fields": {
      "ic_number": "123456-12-1234",
      "full_name": "AHMAD BIN ALI",
      "birth_date": "1990-12-15",
      "address": "123 JALAN MERDEKA",
      "postcode": "50000",
      "state": "KUALA LUMPUR"
    },
    "validation_results": {
      "field_validations": {
        "ic_number": {
          "is_valid": true,
          "format_correct": true,
          "confidence": 95
        }
      },
      "overall_score": 90,
      "compliance_status": "compliant"
    },
    "authenticity_checks": {
      "overall_authenticity_score": 85
    },
    "quality_assessment": {
      "image_quality": 90,
      "text_clarity": 88,
      "document_condition": "excellent"
    }
  }
}
```

### 2. **get_processing_status**
Retrieves the current processing status of a document.

```typescript
POST /customer-document-ai-verification
{
  "action": "get_processing_status",
  "document_id": "uuid"
}
```

### 3. **verify_identity** (Coming Soon)
Performs cross-document identity verification and matching.

### 4. **validate_authenticity** (Coming Soon)
Advanced document authenticity validation.

## Document Types

### Malaysian IC Card (ic_card)

**Front Side Fields:**
- `ic_number`: 12-digit IC with hyphens (XXXXXX-XX-XXXX)
- `full_name`: Full name as shown on IC
- `birth_date`: Date of birth (YYYY-MM-DD)
- `birth_place`: Place of birth
- `gender`: LELAKI/PEREMPUAN
- `religion`: Religion if visible
- `race`: Race if visible
- `citizenship`: WARGANEGARA/others

**Back Side Fields:**
- `address`: Full address as shown
- `postcode`: 5-digit Malaysian postcode
- `state`: Malaysian state
- `country`: Country (usually MALAYSIA)
- `issue_date`: Issue date if visible
- `expiry_date`: Expiry date if visible

## Validation Rules

### IC Number Validation
- Must be exactly 12 digits with hyphens (XXXXXX-XX-XXXX)
- Follows Malaysian IC format standards
- Cross-validated with birth date consistency

### Address Validation
- Postcode must be 5 digits
- State must be valid Malaysian state
- Address format compliance

### Data Quality Checks
- Image quality assessment (0-100)
- Text clarity evaluation (0-100)
- Document condition analysis
- Tampering detection

## Security Features

### Authentication
- JWT token validation required
- User-specific document access control
- Service role key for Supabase operations

### Data Protection
- Secure storage bucket access
- User isolation (documents only accessible by owner)
- Audit logging for all operations

### Privacy Compliance
- No sensitive data in logs
- Secure image processing
- Malaysian KYC compliance

## Configuration

### Environment Variables
```bash
GEMINI_API_KEY=your_gemini_api_key
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### Storage Bucket
- Bucket: `customer-verification-documents`
- Path structure: `customer-verification-documents/{user_id}/{customer_id}/{document_type}/{side}_{timestamp}.{ext}`

### Database Tables
- `wallet_verification_documents`: Document records and OCR results
- User authentication via Supabase Auth

## Error Handling

### Common Errors
- `No authorization header`: Missing authentication
- `Invalid authentication token`: Invalid or expired JWT
- `Document not found or access denied`: Document doesn't exist or user lacks access
- `Gemini API key not configured`: Missing API key
- `AI processing failed`: Gemini API error or parsing failure

### Error Response Format
```typescript
{
  "success": false,
  "error": "Error message",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## Performance

### Processing Times
- IC Card (front): ~2-4 seconds
- IC Card (back): ~2-4 seconds
- Quality assessment: ~1 second
- Total processing: ~3-6 seconds per document

### Confidence Scoring
- **Extraction Confidence**: 40% weight
- **Validation Score**: 35% weight  
- **Authenticity Score**: 25% weight

### Status Determination
- **Verified**: Confidence ≥85%, Validation ≥80%, Authenticity ≥75%
- **Review Required**: Confidence ≥70%, Validation ≥60%
- **Failed**: Below review thresholds

## Integration

### Flutter Service Integration
```dart
final response = await supabase.functions.invoke(
  'customer-document-ai-verification',
  body: {
    'action': 'process_document',
    'document_id': documentId,
    'document_type': 'ic_card',
    'document_side': 'front',
  },
);
```

### Real-time Updates
- Document status updates via database triggers
- Real-time subscriptions for processing status
- Notification integration for completion

## Monitoring

### Logging
- Comprehensive request/response logging
- Performance metrics tracking
- Error rate monitoring
- User activity audit trails

### Health Checks
- API availability monitoring
- Gemini API status tracking
- Database connectivity checks
- Storage bucket accessibility

## Development

### Local Testing
```bash
supabase functions serve customer-document-ai-verification --env-file .env.local
```

### Deployment
```bash
supabase functions deploy customer-document-ai-verification
```

### Testing
- Unit tests for validation functions
- Integration tests with mock documents
- End-to-end workflow testing
- Performance benchmarking
