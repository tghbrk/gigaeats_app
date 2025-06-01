-- Migration to replace Firebase Auth with Supabase Auth
-- This migration updates RLS policies and database schema to work with Supabase native authentication

-- First, drop all existing Firebase-based RLS policies
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Vendors can view own data" ON vendors;
DROP POLICY IF EXISTS "Vendors can update own data" ON vendors;
DROP POLICY IF EXISTS "Sales agents can view assigned vendors" ON vendors;
DROP POLICY IF EXISTS "Admins can manage all vendors" ON vendors;
DROP POLICY IF EXISTS "Vendors can manage own menu items" ON menu_items;
DROP POLICY IF EXISTS "Sales agents can view menu items for assigned vendors" ON menu_items;
DROP POLICY IF EXISTS "Admins can manage all menu items" ON menu_items;
DROP POLICY IF EXISTS "Users can view own customer data" ON customers;
DROP POLICY IF EXISTS "Sales agents can view assigned customers" ON customers;
DROP POLICY IF EXISTS "Admins can view all customers" ON customers;
DROP POLICY IF EXISTS "Users can manage accessible orders" ON orders;
DROP POLICY IF EXISTS "Users can manage order items for accessible orders" ON order_items;
DROP POLICY IF EXISTS "Users can manage own FCM tokens" ON user_fcm_tokens;
DROP POLICY IF EXISTS "Admins can view all FCM tokens" ON user_fcm_tokens;

-- Drop the Firebase-specific function (CASCADE to drop dependent objects)
DROP FUNCTION IF EXISTS get_firebase_uid() CASCADE;

-- Create new function to get current Supabase user ID
CREATE OR REPLACE FUNCTION get_current_user_id()
RETURNS UUID AS $$
BEGIN
  RETURN auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to check if current user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role = 'admin' 
    AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to check if current user has specific role
CREATE OR REPLACE FUNCTION has_role(required_role TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role = required_role 
    AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update users table to use Supabase auth.users.id as primary key
-- First, add a new column for Supabase user ID
ALTER TABLE users ADD COLUMN IF NOT EXISTS supabase_user_id UUID REFERENCES auth.users(id);

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_users_supabase_user_id ON users(supabase_user_id);

-- Update the table to make firebase_uid nullable (for migration period)
ALTER TABLE users ALTER COLUMN firebase_uid DROP NOT NULL;

-- Add constraint to ensure either firebase_uid or supabase_user_id is present
ALTER TABLE users ADD CONSTRAINT check_user_auth_id 
  CHECK (firebase_uid IS NOT NULL OR supabase_user_id IS NOT NULL);

-- Create new RLS policies for users table using Supabase auth
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (id = auth.uid() OR supabase_user_id = auth.uid());

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (id = auth.uid() OR supabase_user_id = auth.uid());

CREATE POLICY "Users can insert own profile" ON users
  FOR INSERT WITH CHECK (supabase_user_id = auth.uid());

CREATE POLICY "Admins can view all users" ON users
  FOR SELECT USING (is_admin());

CREATE POLICY "Admins can update all users" ON users
  FOR UPDATE USING (is_admin());

-- Create new RLS policies for user_profiles table
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (
    user_id = auth.uid() OR 
    user_id IN (SELECT id FROM users WHERE supabase_user_id = auth.uid())
  );

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (
    user_id = auth.uid() OR 
    user_id IN (SELECT id FROM users WHERE supabase_user_id = auth.uid())
  );

CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT WITH CHECK (
    user_id = auth.uid() OR 
    user_id IN (SELECT id FROM users WHERE supabase_user_id = auth.uid())
  );

CREATE POLICY "Admins can view all profiles" ON user_profiles
  FOR SELECT USING (is_admin());

CREATE POLICY "Admins can update all profiles" ON user_profiles
  FOR UPDATE USING (is_admin());

-- Create new RLS policies for vendors table
CREATE POLICY "Vendors can view own data" ON vendors
  FOR SELECT USING (
    user_id = auth.uid() OR
    user_id IN (SELECT id FROM users WHERE supabase_user_id = auth.uid())
  );

CREATE POLICY "Vendors can update own data" ON vendors
  FOR UPDATE USING (
    user_id = auth.uid() OR
    user_id IN (SELECT id FROM users WHERE supabase_user_id = auth.uid())
  );

CREATE POLICY "Sales agents can view assigned vendors" ON vendors
  FOR SELECT USING (
    has_role('sales_agent')
  );

CREATE POLICY "Admins can manage all vendors" ON vendors
  FOR ALL USING (is_admin());

-- Create new RLS policies for menu_items table
CREATE POLICY "Vendors can manage own menu items" ON menu_items
  FOR ALL USING (
    vendor_id IN (
      SELECT id FROM vendors WHERE
      user_id = auth.uid() OR
      user_id IN (SELECT id FROM users WHERE supabase_user_id = auth.uid())
    )
  );

CREATE POLICY "Sales agents can view menu items for assigned vendors" ON menu_items
  FOR SELECT USING (
    has_role('sales_agent')
  );

CREATE POLICY "Admins can manage all menu items" ON menu_items
  FOR ALL USING (is_admin());

-- Create new RLS policies for customers table
CREATE POLICY "Users can view own customer data" ON customers
  FOR SELECT USING (
    sales_agent_id = auth.uid() OR
    sales_agent_id IN (SELECT id FROM users WHERE supabase_user_id = auth.uid())
  );

CREATE POLICY "Sales agents can view assigned customers" ON customers
  FOR SELECT USING (
    has_role('sales_agent')
  );

CREATE POLICY "Admins can view all customers" ON customers
  FOR SELECT USING (is_admin());

-- Create new RLS policies for orders table
CREATE POLICY "Users can manage accessible orders" ON orders
  FOR ALL USING (
    vendor_id IN (
      SELECT id FROM vendors WHERE
      user_id = auth.uid() OR
      user_id IN (SELECT id FROM users WHERE supabase_user_id = auth.uid())
    ) OR
    sales_agent_id = auth.uid() OR
    sales_agent_id IN (SELECT id FROM users WHERE supabase_user_id = auth.uid()) OR
    is_admin()
  );

-- Create new RLS policies for order_items table
CREATE POLICY "Users can manage order items for accessible orders" ON order_items
  FOR ALL USING (
    order_id IN (
      SELECT id FROM orders WHERE
        vendor_id IN (
          SELECT id FROM vendors WHERE
          user_id = auth.uid() OR
          user_id IN (SELECT id FROM users WHERE supabase_user_id = auth.uid())
        ) OR
        sales_agent_id = auth.uid() OR
        sales_agent_id IN (SELECT id FROM users WHERE supabase_user_id = auth.uid()) OR
        is_admin()
    )
  );

-- Create new RLS policies for FCM tokens table
CREATE POLICY "Users can manage own FCM tokens" ON user_fcm_tokens
  FOR ALL USING (
    firebase_uid IN (SELECT firebase_uid FROM users WHERE supabase_user_id = auth.uid())
  );

CREATE POLICY "Admins can view all FCM tokens" ON user_fcm_tokens
  FOR SELECT USING (is_admin());

-- Create a function to handle user creation from Supabase auth
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  user_phone_number TEXT;
  user_role TEXT;
BEGIN
  -- Extract phone number from metadata or use the phone field
  user_phone_number := COALESCE(
    NEW.raw_user_meta_data->>'phone_number',
    NEW.phone
  );

  -- Extract role from metadata, default to 'sales_agent'
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'sales_agent');

  -- Validate role is one of the allowed values
  IF user_role NOT IN ('sales_agent', 'vendor', 'admin', 'customer') THEN
    user_role := 'sales_agent';
  END IF;

  INSERT INTO public.users (
    id,
    supabase_user_id,
    email,
    full_name,
    phone_number,
    role,
    is_verified,
    is_active,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    user_phone_number,
    user_role::user_role_enum,
    NEW.email_confirmed_at IS NOT NULL OR NEW.phone_confirmed_at IS NOT NULL,
    true,
    NOW(),
    NOW()
  );
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error and re-raise it
    RAISE LOG 'Error in handle_new_user trigger: %', SQLERRM;
    RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create user profile when Supabase user is created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Create function to sync user metadata changes
CREATE OR REPLACE FUNCTION handle_user_metadata_update()
RETURNS TRIGGER AS $$
DECLARE
  user_phone_number TEXT;
BEGIN
  -- Extract phone number from metadata or use the phone field
  user_phone_number := COALESCE(
    NEW.raw_user_meta_data->>'phone_number',
    NEW.phone
  );

  UPDATE public.users SET
    email = NEW.email,
    full_name = COALESCE(NEW.raw_user_meta_data->>'full_name', full_name),
    phone_number = user_phone_number,
    is_verified = NEW.email_confirmed_at IS NOT NULL OR NEW.phone_confirmed_at IS NOT NULL,
    updated_at = NOW()
  WHERE supabase_user_id = NEW.id;
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error and re-raise it
    RAISE LOG 'Error in handle_user_metadata_update trigger: %', SQLERRM;
    RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to sync user metadata updates
DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;
CREATE TRIGGER on_auth_user_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_user_metadata_update();
