-- Fix RLS policies for Supabase authentication and enable realtime
-- This migration fixes the realtime subscription timeout issues

-- Drop old Firebase-based policies that are causing issues
DROP POLICY IF EXISTS "Vendors can view own orders" ON orders;
DROP POLICY IF EXISTS "Vendors can update own orders" ON orders;
DROP POLICY IF EXISTS "Sales agents can manage own orders" ON orders;
DROP POLICY IF EXISTS "Admins can manage all orders" ON orders;
DROP POLICY IF EXISTS "Users can manage accessible orders" ON orders;

-- Create new RLS policies for orders table that work with Supabase auth and realtime
CREATE POLICY "Vendors can view own orders" ON orders
  FOR SELECT USING (
    vendor_id IN (
      SELECT id FROM vendors WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Vendors can update own orders" ON orders
  FOR UPDATE USING (
    vendor_id IN (
      SELECT id FROM vendors WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Sales agents can view assigned orders" ON orders
  FOR SELECT USING (
    sales_agent_id IN (
      SELECT id FROM users WHERE supabase_user_id = auth.uid() AND role = 'sales_agent'
    )
  );

CREATE POLICY "Sales agents can manage assigned orders" ON orders
  FOR ALL USING (
    sales_agent_id IN (
      SELECT id FROM users WHERE supabase_user_id = auth.uid() AND role = 'sales_agent'
    )
  );

CREATE POLICY "Admins can manage all orders" ON orders
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE supabase_user_id = auth.uid() AND role = 'admin'
    )
  );

-- Fix order_items policies
DROP POLICY IF EXISTS "Users can view order items for accessible orders" ON order_items;
DROP POLICY IF EXISTS "Users can manage order items for accessible orders" ON order_items;

CREATE POLICY "Users can view order items for accessible orders" ON order_items
  FOR SELECT USING (
    order_id IN (
      SELECT id FROM orders WHERE
        vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()) OR
        sales_agent_id IN (SELECT id FROM users WHERE supabase_user_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM users WHERE supabase_user_id = auth.uid() AND role = 'admin')
    )
  );

CREATE POLICY "Users can manage order items for accessible orders" ON order_items
  FOR ALL USING (
    order_id IN (
      SELECT id FROM orders WHERE
        vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()) OR
        sales_agent_id IN (SELECT id FROM users WHERE supabase_user_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM users WHERE supabase_user_id = auth.uid() AND role = 'admin')
    )
  );

-- Enable realtime for orders table
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE order_items;

-- Create indexes to improve RLS policy performance
CREATE INDEX IF NOT EXISTS idx_vendors_user_id ON vendors(user_id);
CREATE INDEX IF NOT EXISTS idx_users_supabase_user_id ON users(supabase_user_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_orders_vendor_id_status ON orders(vendor_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_sales_agent_id_status ON orders(sales_agent_id, status);

-- Fix menu_items RLS policies
DROP POLICY IF EXISTS "Vendors can manage own menu items" ON menu_items;
DROP POLICY IF EXISTS "Sales agents can view menu items for assigned vendors" ON menu_items;
DROP POLICY IF EXISTS "Sales agents can view all menu items" ON menu_items;
DROP POLICY IF EXISTS "Admins can manage all menu items" ON menu_items;

CREATE POLICY "Vendors can manage own menu items" ON menu_items
  FOR ALL USING (
    vendor_id IN (
      SELECT id FROM vendors WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Sales agents can view menu items" ON menu_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE supabase_user_id = auth.uid() AND role = 'sales_agent'
    )
  );

CREATE POLICY "Admins can manage all menu items" ON menu_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE supabase_user_id = auth.uid() AND role = 'admin'
    )
  );

-- Grant necessary permissions for realtime
GRANT SELECT ON orders TO authenticated;
GRANT SELECT ON order_items TO authenticated;
GRANT SELECT ON menu_items TO authenticated;
GRANT SELECT ON vendors TO authenticated;
GRANT SELECT ON users TO authenticated;

-- Ensure realtime is enabled on the tables
ALTER TABLE orders REPLICA IDENTITY FULL;
ALTER TABLE order_items REPLICA IDENTITY FULL;
ALTER TABLE menu_items REPLICA IDENTITY FULL;
