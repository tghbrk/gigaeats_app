# Delivery Proof System Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying the GigaEats Delivery Proof System to production environments, including database migrations, storage configuration, and application deployment.

## Pre-Deployment Checklist

### Environment Requirements

- [ ] **Supabase Project**: Production Supabase instance configured
- [ ] **Flutter Environment**: Flutter 3.x SDK installed
- [ ] **Database Access**: Admin access to Supabase database
- [ ] **Storage Permissions**: Supabase storage bucket management access
- [ ] **Real-time Enabled**: Supabase real-time features activated

### Dependencies Verification

```yaml
# pubspec.yaml - Required dependencies
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  image_picker: ^1.0.4
  geolocator: ^10.1.0
  permission_handler: ^11.0.1
  cached_network_image: ^3.3.0
  flutter_riverpod: ^2.4.0
  go_router: ^12.0.0
```

### Code Review Checklist

- [ ] All delivery proof models implemented
- [ ] Database schema migration files ready
- [ ] RLS policies defined and tested
- [ ] Storage bucket configuration complete
- [ ] Real-time providers implemented
- [ ] Error handling comprehensive
- [ ] Security measures in place
- [ ] Testing completed successfully

## Database Deployment

### Step 1: Create Migration Files

Create the delivery proof migration:

```sql
-- migrations/20250101000000_create_delivery_proofs.sql

-- Create delivery_proofs table
CREATE TABLE delivery_proofs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    signature_url TEXT,
    recipient_name TEXT,
    notes TEXT,
    delivered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    delivered_by TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location_accuracy DECIMAL(8, 2),
    delivery_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_order_proof UNIQUE(order_id)
);

-- Create indexes for performance
CREATE INDEX idx_delivery_proofs_order_id ON delivery_proofs(order_id);
CREATE INDEX idx_delivery_proofs_delivered_at ON delivery_proofs(delivered_at);
CREATE INDEX idx_delivery_proofs_delivered_by ON delivery_proofs(delivered_by);

-- Add delivery_proof_id to orders table
ALTER TABLE orders ADD COLUMN delivery_proof_id UUID REFERENCES delivery_proofs(id);

-- Create automatic trigger function
CREATE OR REPLACE FUNCTION handle_delivery_proof_creation()
RETURNS TRIGGER AS $$
BEGIN
  -- Update the order status to 'delivered' and set actual delivery time
  UPDATE orders 
  SET 
    status = 'delivered',
    actual_delivery_time = NEW.delivered_at,
    delivery_proof_id = NEW.id,
    updated_at = NOW()
  WHERE id = NEW.order_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER trigger_delivery_proof_creation
    AFTER INSERT ON delivery_proofs
    FOR EACH ROW
    EXECUTE FUNCTION handle_delivery_proof_creation();

-- Create updated_at trigger
CREATE TRIGGER trigger_delivery_proofs_updated_at
    BEFORE UPDATE ON delivery_proofs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

### Step 2: Apply Database Migration

```bash
# Using Supabase CLI
supabase db push

# Or apply manually via Supabase Dashboard
# Copy and paste the migration SQL in the SQL Editor
```

### Step 3: Verify Migration

```sql
-- Verify table creation
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'delivery_proofs';

-- Verify triggers
SELECT trigger_name, event_manipulation, event_object_table 
FROM information_schema.triggers 
WHERE event_object_table = 'delivery_proofs';

-- Test trigger functionality
INSERT INTO delivery_proofs (order_id, photo_url, delivered_by) 
VALUES ('test-order-id', 'test-url', 'test-user');
```

## Storage Configuration

### Step 1: Create Storage Bucket

```sql
-- Create delivery-proofs bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('delivery-proofs', 'delivery-proofs', false);
```

### Step 2: Configure Storage Policies

```sql
-- Policy for uploading delivery proof photos
CREATE POLICY "Users can upload delivery proof photos" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'delivery-proofs' AND
  auth.role() = 'authenticated'
);

-- Policy for viewing delivery proof photos
CREATE POLICY "Users can view delivery proof photos" ON storage.objects
FOR SELECT USING (
  bucket_id = 'delivery-proofs' AND
  auth.role() = 'authenticated'
);

-- Policy for updating delivery proof photos
CREATE POLICY "Users can update delivery proof photos" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'delivery-proofs' AND
  auth.role() = 'authenticated'
);
```

### Step 3: Configure Bucket Settings

```bash
# Set bucket size limits (100MB per file)
supabase storage update delivery-proofs --file-size-limit 104857600

# Set allowed MIME types
supabase storage update delivery-proofs --allowed-mime-types "image/jpeg,image/png,image/webp"
```

## Row Level Security (RLS) Deployment

### Step 1: Enable RLS

```sql
-- Enable RLS on delivery_proofs table
ALTER TABLE delivery_proofs ENABLE ROW LEVEL SECURITY;
```

### Step 2: Create RLS Policies

```sql
-- Users can view delivery proofs for orders they're involved in
CREATE POLICY "Users can view delivery proofs for their orders" ON delivery_proofs
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM orders o
    WHERE o.id = delivery_proofs.order_id
    AND (
      o.vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()) OR
      o.sales_agent_id = auth.uid() OR
      EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    )
  )
);

-- Users can create delivery proofs for orders they're responsible for
CREATE POLICY "Users can create delivery proofs for their orders" ON delivery_proofs
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM orders o
    WHERE o.id = delivery_proofs.order_id
    AND (
      o.vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()) OR
      o.sales_agent_id = auth.uid()
    )
  )
);

-- Users can update delivery proofs for their orders
CREATE POLICY "Users can update delivery proofs for their orders" ON delivery_proofs
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM orders o
    WHERE o.id = delivery_proofs.order_id
    AND (
      o.vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()) OR
      o.sales_agent_id = auth.uid()
    )
  )
);

-- Only admins can delete delivery proofs
CREATE POLICY "Admins can delete delivery proofs" ON delivery_proofs
FOR DELETE USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);
```

### Step 3: Test RLS Policies

```sql
-- Test as vendor user
SET LOCAL role TO authenticated;
SET LOCAL request.jwt.claims TO '{"sub": "vendor-user-id", "role": "authenticated"}';

-- Should return only vendor's delivery proofs
SELECT * FROM delivery_proofs;

-- Test as admin user
SET LOCAL request.jwt.claims TO '{"sub": "admin-user-id", "role": "authenticated"}';

-- Should return all delivery proofs
SELECT * FROM delivery_proofs;
```

## Real-time Configuration

### Step 1: Enable Real-time

```sql
-- Enable real-time for delivery_proofs table
ALTER PUBLICATION supabase_realtime ADD TABLE delivery_proofs;

-- Enable real-time for orders table (if not already enabled)
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
```

### Step 2: Configure Real-time Policies

```sql
-- Real-time policy for delivery_proofs
CREATE POLICY "Users can receive real-time delivery proof updates" ON delivery_proofs
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM orders o
    WHERE o.id = delivery_proofs.order_id
    AND (
      o.vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()) OR
      o.sales_agent_id = auth.uid() OR
      EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    )
  )
);
```

### Step 3: Test Real-time Functionality

```javascript
// Test real-time subscription
const supabase = createClient(url, key);

const subscription = supabase
  .channel('delivery_proofs_test')
  .on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'delivery_proofs'
  }, (payload) => {
    console.log('Real-time update:', payload);
  })
  .subscribe();
```

## Application Deployment

### Step 1: Environment Configuration

Create production environment file:

```dart
// lib/core/config/environment.dart
class Environment {
  static const String supabaseUrl = 'YOUR_PRODUCTION_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_PRODUCTION_ANON_KEY';
  static const String deliveryProofsBucket = 'delivery-proofs';
  
  static const bool isProduction = true;
  static const bool enableDebugLogging = false;
}
```

### Step 2: Build Configuration

```yaml
# android/app/build.gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Step 3: Permission Configuration

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### Step 4: Build and Deploy

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Build for Android
flutter build apk --release

# Or build for Android App Bundle
flutter build appbundle --release

# Build for iOS (if applicable)
flutter build ios --release
```

## Post-Deployment Verification

### Step 1: Database Verification

```sql
-- Verify table structure
\d delivery_proofs

-- Check triggers
SELECT * FROM information_schema.triggers 
WHERE event_object_table = 'delivery_proofs';

-- Verify RLS policies
SELECT * FROM pg_policies WHERE tablename = 'delivery_proofs';
```

### Step 2: Storage Verification

```bash
# List storage buckets
supabase storage ls

# Check bucket policies
supabase storage get-policy delivery-proofs
```

### Step 3: Application Testing

1. **Functional Testing**:
   - Test delivery proof capture workflow
   - Verify photo upload functionality
   - Test GPS location capture
   - Confirm real-time updates

2. **Performance Testing**:
   - Monitor photo upload times
   - Check real-time update latency
   - Verify memory usage

3. **Security Testing**:
   - Test RLS policy enforcement
   - Verify storage access controls
   - Check authentication requirements

## Monitoring and Maintenance

### Step 1: Set Up Monitoring

```sql
-- Create monitoring views
CREATE VIEW delivery_proof_stats AS
SELECT 
    DATE(created_at) as date,
    COUNT(*) as total_proofs,
    COUNT(CASE WHEN photo_url IS NOT NULL THEN 1 END) as with_photos,
    COUNT(CASE WHEN latitude IS NOT NULL THEN 1 END) as with_location,
    AVG(location_accuracy) as avg_accuracy
FROM delivery_proofs
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

### Step 2: Performance Monitoring

```sql
-- Monitor storage usage
SELECT 
    bucket_id,
    COUNT(*) as file_count,
    SUM(metadata->>'size')::bigint as total_size
FROM storage.objects 
WHERE bucket_id = 'delivery-proofs'
GROUP BY bucket_id;

-- Monitor delivery proof success rates
SELECT 
    DATE(created_at) as date,
    COUNT(*) as total_attempts,
    COUNT(CASE WHEN photo_url IS NOT NULL THEN 1 END) as successful_uploads,
    ROUND(
        COUNT(CASE WHEN photo_url IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 
        2
    ) as success_rate
FROM delivery_proofs
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

### Step 3: Backup Strategy

```bash
# Database backup
pg_dump -h your-db-host -U postgres -d your-database > delivery_proof_backup.sql

# Storage backup (if needed)
supabase storage download delivery-proofs --recursive
```

## Rollback Procedures

### Database Rollback

```sql
-- Rollback migration (if needed)
DROP TRIGGER IF EXISTS trigger_delivery_proof_creation ON delivery_proofs;
DROP FUNCTION IF EXISTS handle_delivery_proof_creation();
ALTER TABLE orders DROP COLUMN IF EXISTS delivery_proof_id;
DROP TABLE IF EXISTS delivery_proofs;
```

### Application Rollback

```bash
# Revert to previous app version
flutter build apk --release --build-number=previous-version

# Or use version control
git revert commit-hash
flutter build apk --release
```

## Support and Troubleshooting

### Common Deployment Issues

1. **Migration Failures**:
   - Check database permissions
   - Verify foreign key constraints
   - Review migration syntax

2. **Storage Issues**:
   - Verify bucket creation
   - Check storage policies
   - Confirm CORS settings

3. **Real-time Problems**:
   - Enable real-time on tables
   - Check subscription policies
   - Verify WebSocket connections

### Support Contacts

- **Database Issues**: Database Administrator
- **Storage Issues**: DevOps Team
- **Application Issues**: Development Team
- **Security Issues**: Security Team

---

**Last Updated**: January 2025  
**Version**: 1.0.0  
**Deployment Status**: Production Ready
