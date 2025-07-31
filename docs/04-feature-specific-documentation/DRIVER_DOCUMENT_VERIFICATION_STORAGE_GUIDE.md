# Driver Document Verification Storage Configuration Guide

## 🎯 Overview

This document provides comprehensive information about the Supabase storage configuration for the GigaEats driver document verification system, including bucket setup, security policies, and integration patterns.

## 📦 Storage Bucket Configuration

### **Driver Verification Documents Bucket**

```sql
-- Bucket Configuration
Bucket ID: driver-verification-documents
Name: driver-verification-documents
Public: false (Private bucket for security)
File Size Limit: 20MB (20,971,520 bytes)
Allowed MIME Types:
  - image/jpeg
  - image/jpg
  - image/png
  - image/webp
  - application/pdf
```

### **Security Features**

- **Private Bucket**: All documents are stored privately with signed URL access
- **User Isolation**: Files organized by user ID to prevent cross-user access
- **File Integrity**: SHA-256 checksums for all uploaded documents
- **Encryption Support**: Ready for encryption key management
- **Audit Trail**: Complete upload and access logging

## 🔒 Row Level Security (RLS) Policies

### **Driver Access Policies**

```sql
-- Drivers can upload their own verification documents
CREATE POLICY "Drivers can upload own verification documents" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'driver-verification-documents' AND
        auth.role() = 'authenticated' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

-- Drivers can view their own verification documents
CREATE POLICY "Drivers can view own verification documents" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'driver-verification-documents' AND
        auth.role() = 'authenticated' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

-- Drivers can update their own verification documents
CREATE POLICY "Drivers can update own verification documents" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'driver-verification-documents' AND
        auth.role() = 'authenticated' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

-- Drivers can delete their own verification documents (before processing)
CREATE POLICY "Drivers can delete own verification documents" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'driver-verification-documents' AND
        auth.role() = 'authenticated' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );
```

### **Admin Access Policies**

```sql
-- Admins can access all driver verification documents
CREATE POLICY "Admins can access all driver verification documents" ON storage.objects
    FOR ALL USING (
        bucket_id = 'driver-verification-documents' AND
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );
```

### **System Access Policies**

```sql
-- Service role can manage driver verification documents (for processing)
CREATE POLICY "Service role can manage driver verification documents" ON storage.objects
    FOR ALL USING (
        bucket_id = 'driver-verification-documents' AND
        auth.role() = 'service_role'
    );

-- Edge Functions can process documents
CREATE POLICY "Edge functions can process driver verification documents" ON storage.objects
    FOR ALL USING (
        bucket_id = 'driver-verification-documents' AND
        auth.jwt() ->> 'iss' = 'https://abknoalhfltlhhdbclpv.supabase.co/auth/v1'
    );
```

## 📁 File Organization Structure

### **Directory Structure**

```
driver-verification-documents/
├── {user_id}/
│   └── driver_verification/
│       ├── driver_{driver_id}_ic_card_front_{timestamp}.jpg
│       ├── driver_{driver_id}_ic_card_back_{timestamp}.jpg
│       ├── driver_{driver_id}_passport_{timestamp}.jpg
│       ├── driver_{driver_id}_driver_license_{timestamp}.jpg
│       ├── driver_{driver_id}_utility_bill_{timestamp}.pdf
│       ├── driver_{driver_id}_bank_statement_{timestamp}.pdf
│       └── driver_{driver_id}_selfie_{timestamp}.jpg
```

### **File Naming Convention**

```
Pattern: driver_{driver_id}_{document_type}_{side}_{timestamp}.{extension}

Examples:
- driver_123e4567-e89b-12d3-a456-426614174000_ic_card_front_1640995200000.jpg
- driver_123e4567-e89b-12d3-a456-426614174000_passport_1640995200000.jpg
- driver_123e4567-e89b-12d3-a456-426614174000_selfie_1640995200000.jpg
```

## 🛠️ Integration with Flutter App

### **Service Configuration**

```dart
// lib/src/core/config/supabase_config.dart
class SupabaseConfig {
  static const String driverVerificationDocumentsBucket = 'driver-verification-documents';
}

// lib/src/core/services/file_upload_service.dart
bool _isPrivateBucket(String bucketName) {
  const privateBuckets = {
    'driver-verification-documents',
    // ... other private buckets
  };
  return privateBuckets.contains(bucketName);
}
```

### **Upload Service Usage**

```dart
// Upload driver verification document
final result = await driverDocumentVerificationService.uploadVerificationDocument(
  driverId: driverId,
  userId: userId,
  verificationId: verificationId,
  documentType: DocumentType.icCard,
  documentFile: selectedFile,
  documentSide: 'front',
  metadata: {'source': 'camera'},
);

if (result.success) {
  print('Document uploaded: ${result.documentId}');
  print('File URL: ${result.fileUrl}');
} else {
  print('Upload failed: ${result.errorMessage}');
}
```

## 🔐 Security Best Practices

### **File Validation**

- **Size Limits**: 20MB maximum per file
- **MIME Type Validation**: Only allowed document and image types
- **File Integrity**: SHA-256 checksums for all uploads
- **Virus Scanning**: Ready for integration with security scanners

### **Access Control**

- **User Isolation**: Files organized by user ID folders
- **Signed URLs**: Temporary access with expiration (1-24 hours)
- **Role-Based Access**: Different permissions for drivers, admins, and system
- **Audit Logging**: All access and modifications logged

### **Data Retention**

- **Malaysian Compliance**: 7-year retention for KYC documents
- **Automatic Cleanup**: Expired documents marked for deletion
- **Secure Deletion**: Complete removal from storage and database

## 📊 Monitoring and Analytics

### **Storage Metrics**

```sql
-- Monitor storage usage
SELECT 
    COUNT(*) as total_documents,
    SUM(metadata->>'size') as total_size_bytes,
    AVG(metadata->>'size') as avg_size_bytes
FROM storage.objects 
WHERE bucket_id = 'driver-verification-documents';

-- Monitor upload patterns
SELECT 
    DATE(created_at) as upload_date,
    COUNT(*) as uploads_per_day
FROM storage.objects 
WHERE bucket_id = 'driver-verification-documents'
GROUP BY DATE(created_at)
ORDER BY upload_date DESC;
```

### **Security Monitoring**

```sql
-- Monitor access patterns
SELECT 
    auth.uid() as user_id,
    COUNT(*) as access_count,
    MAX(created_at) as last_access
FROM storage.objects 
WHERE bucket_id = 'driver-verification-documents'
GROUP BY auth.uid()
ORDER BY access_count DESC;
```

## 🚀 Performance Optimization

### **Upload Optimization**

- **Image Compression**: Optimized for OCR while maintaining quality
- **Progressive Upload**: Chunked uploads for large files
- **Retry Logic**: Automatic retry on network failures
- **Background Processing**: Async document processing

### **Access Optimization**

- **Signed URL Caching**: Cache signed URLs for repeated access
- **CDN Integration**: Ready for CDN distribution
- **Thumbnail Generation**: Automatic thumbnail creation
- **Lazy Loading**: Load documents on demand

## 🔧 Troubleshooting

### **Common Issues**

1. **Upload Failures**
   - Check file size limits (20MB max)
   - Verify MIME type is allowed
   - Ensure user is authenticated
   - Check network connectivity

2. **Access Denied**
   - Verify user owns the document
   - Check RLS policies are active
   - Ensure proper authentication
   - Validate file path structure

3. **Processing Delays**
   - Monitor Edge Function logs
   - Check OCR service availability
   - Verify database triggers
   - Review processing queue

### **Debug Commands**

```sql
-- Check bucket configuration
SELECT * FROM storage.buckets WHERE name = 'driver-verification-documents';

-- Verify RLS policies
SELECT policyname, cmd, qual 
FROM pg_policies 
WHERE tablename = 'objects' 
AND qual LIKE '%driver-verification-documents%';

-- Monitor recent uploads
SELECT name, created_at, metadata 
FROM storage.objects 
WHERE bucket_id = 'driver-verification-documents' 
ORDER BY created_at DESC 
LIMIT 10;
```

---

**Last Updated**: January 2025  
**Version**: 1.0.0  
**Compatibility**: Supabase 2.x, Flutter 3.x
