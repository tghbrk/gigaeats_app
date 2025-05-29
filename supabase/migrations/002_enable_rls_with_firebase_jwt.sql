-- Re-enable RLS and create policies that work with Firebase JWT tokens
-- This migration replaces the temporarily disabled RLS with proper Firebase JWT validation

-- First, re-enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;

-- Create a function to extract Firebase UID from JWT
CREATE OR REPLACE FUNCTION get_firebase_uid()
RETURNS TEXT AS $$
BEGIN
  -- Extract the 'sub' claim from the JWT token which contains the Firebase UID
  RETURN COALESCE(
    current_setting('request.jwt.claims', true)::json->>'sub',
    current_setting('request.jwt.claim.sub', true)
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  -- Check if the user has admin role in JWT claims
  RETURN COALESCE(
    (current_setting('request.jwt.claims', true)::json->>'role') = 'admin',
    false
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to check if user is verified
CREATE OR REPLACE FUNCTION is_verified()
RETURNS BOOLEAN AS $$
BEGIN
  -- Check if the user is verified in JWT claims
  RETURN COALESCE(
    (current_setting('request.jwt.claims', true)::json->>'verified')::boolean,
    false
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Users table policies
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (firebase_uid = get_firebase_uid());

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (firebase_uid = get_firebase_uid());

CREATE POLICY "Users can insert own profile" ON users
  FOR INSERT WITH CHECK (firebase_uid = get_firebase_uid());

CREATE POLICY "Admins can view all users" ON users
  FOR SELECT USING (is_admin());

CREATE POLICY "Admins can update all users" ON users
  FOR UPDATE USING (is_admin());

CREATE POLICY "Admins can insert users" ON users
  FOR INSERT WITH CHECK (is_admin());

-- User profiles table policies
DROP POLICY IF EXISTS "Users can view own profile details" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile details" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile details" ON user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON user_profiles;

CREATE POLICY "Users can view own profile details" ON user_profiles
  FOR SELECT USING (firebase_uid = get_firebase_uid());

CREATE POLICY "Users can update own profile details" ON user_profiles
  FOR UPDATE USING (firebase_uid = get_firebase_uid());

CREATE POLICY "Users can insert own profile details" ON user_profiles
  FOR INSERT WITH CHECK (firebase_uid = get_firebase_uid());

CREATE POLICY "Admins can view all profiles" ON user_profiles
  FOR SELECT USING (is_admin());

CREATE POLICY "Admins can update all profiles" ON user_profiles
  FOR UPDATE USING (is_admin());

-- Vendors table policies
DROP POLICY IF EXISTS "Vendors can view own vendor profile" ON vendors;
DROP POLICY IF EXISTS "Vendors can update own vendor profile" ON vendors;
DROP POLICY IF EXISTS "Vendors can insert own vendor profile" ON vendors;
DROP POLICY IF EXISTS "Sales agents can view all vendors" ON vendors;
DROP POLICY IF EXISTS "Admins can manage all vendors" ON vendors;

CREATE POLICY "Vendors can view own vendor profile" ON vendors
  FOR SELECT USING (firebase_uid = get_firebase_uid());

CREATE POLICY "Vendors can update own vendor profile" ON vendors
  FOR UPDATE USING (firebase_uid = get_firebase_uid());

CREATE POLICY "Vendors can insert own vendor profile" ON vendors
  FOR INSERT WITH CHECK (firebase_uid = get_firebase_uid());

CREATE POLICY "Sales agents can view all vendors" ON vendors
  FOR SELECT USING (
    COALESCE(
      (current_setting('request.jwt.claims', true)::json->>'role') = 'sales_agent',
      false
    )
  );

CREATE POLICY "Admins can manage all vendors" ON vendors
  FOR ALL USING (is_admin());

-- Menu items table policies
CREATE POLICY "Vendors can manage own menu items" ON menu_items
  FOR ALL USING (
    vendor_id IN (
      SELECT id FROM vendors WHERE firebase_uid = get_firebase_uid()
    )
  );

CREATE POLICY "Sales agents can view all menu items" ON menu_items
  FOR SELECT USING (
    COALESCE(
      (current_setting('request.jwt.claims', true)::json->>'role') = 'sales_agent',
      false
    )
  );

CREATE POLICY "Admins can manage all menu items" ON menu_items
  FOR ALL USING (is_admin());

-- Customers table policies
CREATE POLICY "Sales agents can manage own customers" ON customers
  FOR ALL USING (
    sales_agent_id IN (
      SELECT id FROM users WHERE firebase_uid = get_firebase_uid()
    )
  );

CREATE POLICY "Admins can manage all customers" ON customers
  FOR ALL USING (is_admin());

-- Orders table policies
CREATE POLICY "Vendors can view own orders" ON orders
  FOR SELECT USING (
    vendor_id IN (
      SELECT id FROM vendors WHERE firebase_uid = get_firebase_uid()
    )
  );

CREATE POLICY "Vendors can update own orders" ON orders
  FOR UPDATE USING (
    vendor_id IN (
      SELECT id FROM vendors WHERE firebase_uid = get_firebase_uid()
    )
  );

CREATE POLICY "Sales agents can manage own orders" ON orders
  FOR ALL USING (
    sales_agent_id IN (
      SELECT id FROM users WHERE firebase_uid = get_firebase_uid()
    )
  );

CREATE POLICY "Admins can manage all orders" ON orders
  FOR ALL USING (is_admin());

-- Order items table policies
CREATE POLICY "Users can view order items for accessible orders" ON order_items
  FOR SELECT USING (
    order_id IN (
      SELECT id FROM orders WHERE
        vendor_id IN (SELECT id FROM vendors WHERE firebase_uid = get_firebase_uid()) OR
        sales_agent_id IN (SELECT id FROM users WHERE firebase_uid = get_firebase_uid()) OR
        is_admin()
    )
  );

CREATE POLICY "Users can manage order items for accessible orders" ON order_items
  FOR ALL USING (
    order_id IN (
      SELECT id FROM orders WHERE
        vendor_id IN (SELECT id FROM vendors WHERE firebase_uid = get_firebase_uid()) OR
        sales_agent_id IN (SELECT id FROM users WHERE firebase_uid = get_firebase_uid()) OR
        is_admin()
    )
  );

-- FCM tokens table policies
CREATE POLICY "Users can manage own FCM tokens" ON user_fcm_tokens
  FOR ALL USING (firebase_uid = get_firebase_uid());

CREATE POLICY "Admins can view all FCM tokens" ON user_fcm_tokens
  FOR SELECT USING (is_admin());

-- Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Create indexes for better performance with RLS
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid_active ON users(firebase_uid) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_vendors_firebase_uid_active ON vendors(firebase_uid) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_orders_vendor_sales_agent ON orders(vendor_id, sales_agent_id);

-- Add comments for documentation
COMMENT ON FUNCTION get_firebase_uid() IS 'Extracts Firebase UID from JWT token for RLS policies';
COMMENT ON FUNCTION is_admin() IS 'Checks if current user has admin role in JWT claims';
COMMENT ON FUNCTION is_verified() IS 'Checks if current user is verified in JWT claims';
