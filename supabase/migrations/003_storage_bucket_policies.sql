-- Create storage buckets and set up RLS policies for Firebase JWT authentication
-- This migration creates the storage buckets and policies for secure file access

-- Create storage buckets if they don't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('profile-images', 'profile-images', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('vendor-images', 'vendor-images', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('menu-images', 'menu-images', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('kyc-documents', 'kyc-documents', false, 20971520, ARRAY['application/pdf', 'image/jpeg', 'image/png']),
  ('order-documents', 'order-documents', false, 20971520, ARRAY['application/pdf', 'image/jpeg', 'image/png'])
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Enable RLS on storage.objects (if not already enabled)
-- Note: RLS is typically already enabled on storage.objects in Supabase

-- Drop existing storage policies if they exist
DROP POLICY IF EXISTS "Profile images are publicly viewable" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own profile images" ON storage.objects;

DROP POLICY IF EXISTS "Vendor images are publicly viewable" ON storage.objects;
DROP POLICY IF EXISTS "Vendors can upload own images" ON storage.objects;
DROP POLICY IF EXISTS "Vendors can update own images" ON storage.objects;
DROP POLICY IF EXISTS "Vendors can delete own images" ON storage.objects;

DROP POLICY IF EXISTS "Menu images are publicly viewable" ON storage.objects;
DROP POLICY IF EXISTS "Vendors can upload menu images" ON storage.objects;
DROP POLICY IF EXISTS "Vendors can update menu images" ON storage.objects;
DROP POLICY IF EXISTS "Vendors can delete menu images" ON storage.objects;

DROP POLICY IF EXISTS "Users can view own KYC documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own KYC documents" ON storage.objects;
DROP POLICY IF EXISTS "Admins can view all KYC documents" ON storage.objects;

DROP POLICY IF EXISTS "Users can view accessible order documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload order documents" ON storage.objects;

-- Profile Images Bucket Policies
CREATE POLICY "Profile images are publicly viewable" ON storage.objects
  FOR SELECT USING (bucket_id = 'profile-images');

CREATE POLICY "Users can upload own profile images" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'profile-images' AND
    (storage.foldername(name))[1] = get_firebase_uid()
  );

CREATE POLICY "Users can update own profile images" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'profile-images' AND
    (storage.foldername(name))[1] = get_firebase_uid()
  );

CREATE POLICY "Users can delete own profile images" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'profile-images' AND
    (storage.foldername(name))[1] = get_firebase_uid()
  );

-- Vendor Images Bucket Policies
CREATE POLICY "Vendor images are publicly viewable" ON storage.objects
  FOR SELECT USING (bucket_id = 'vendor-images');

CREATE POLICY "Vendors can upload own images" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'vendor-images' AND
    (
      (storage.foldername(name))[1] = get_firebase_uid() OR
      is_admin()
    )
  );

CREATE POLICY "Vendors can update own images" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'vendor-images' AND
    (
      (storage.foldername(name))[1] = get_firebase_uid() OR
      is_admin()
    )
  );

CREATE POLICY "Vendors can delete own images" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'vendor-images' AND
    (
      (storage.foldername(name))[1] = get_firebase_uid() OR
      is_admin()
    )
  );

-- Menu Images Bucket Policies
CREATE POLICY "Menu images are publicly viewable" ON storage.objects
  FOR SELECT USING (bucket_id = 'menu-images');

CREATE POLICY "Vendors can upload menu images" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'menu-images' AND
    (
      -- Check if user owns the vendor that owns the menu item
      (storage.foldername(name))[1] IN (
        SELECT v.id::text FROM vendors v WHERE v.firebase_uid = get_firebase_uid()
      ) OR
      is_admin()
    )
  );

CREATE POLICY "Vendors can update menu images" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'menu-images' AND
    (
      (storage.foldername(name))[1] IN (
        SELECT v.id::text FROM vendors v WHERE v.firebase_uid = get_firebase_uid()
      ) OR
      is_admin()
    )
  );

CREATE POLICY "Vendors can delete menu images" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'menu-images' AND
    (
      (storage.foldername(name))[1] IN (
        SELECT v.id::text FROM vendors v WHERE v.firebase_uid = get_firebase_uid()
      ) OR
      is_admin()
    )
  );

-- KYC Documents Bucket Policies (Private bucket)
CREATE POLICY "Users can view own KYC documents" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'kyc-documents' AND
    (storage.foldername(name))[1] = get_firebase_uid()
  );

CREATE POLICY "Users can upload own KYC documents" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'kyc-documents' AND
    (storage.foldername(name))[1] = get_firebase_uid()
  );

CREATE POLICY "Admins can view all KYC documents" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'kyc-documents' AND
    is_admin()
  );

-- Order Documents Bucket Policies (Private bucket)
CREATE POLICY "Users can view accessible order documents" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'order-documents' AND
    (
      -- Users can view documents for orders they're involved in
      (storage.foldername(name))[1] IN (
        SELECT o.id::text FROM orders o 
        WHERE 
          o.sales_agent_id IN (SELECT id FROM users WHERE firebase_uid = get_firebase_uid()) OR
          o.vendor_id IN (SELECT id FROM vendors WHERE firebase_uid = get_firebase_uid())
      ) OR
      is_admin()
    )
  );

CREATE POLICY "Users can upload order documents" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'order-documents' AND
    (
      -- Users can upload documents for orders they're involved in
      (storage.foldername(name))[1] IN (
        SELECT o.id::text FROM orders o 
        WHERE 
          o.sales_agent_id IN (SELECT id FROM users WHERE firebase_uid = get_firebase_uid()) OR
          o.vendor_id IN (SELECT id FROM vendors WHERE firebase_uid = get_firebase_uid())
      ) OR
      is_admin()
    )
  );

-- Create helper function for getting file owner from path
CREATE OR REPLACE FUNCTION get_file_owner_from_path(file_path text)
RETURNS text AS $$
BEGIN
  -- Extract the first folder name which should be the Firebase UID
  RETURN (string_to_array(file_path, '/'))[1];
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Note: Indexes on storage.objects are managed by Supabase

-- Note: Comments on storage policies are managed by Supabase
