-- Fix customer table RLS policies to allow sales agents to update and delete customers
-- This migration addresses issues with customer management in the sales agent dashboard

-- Drop existing policies that might conflict
DROP POLICY IF EXISTS "Sales agents can update assigned customers" ON customers;
DROP POLICY IF EXISTS "Sales agents can delete assigned customers" ON customers;
DROP POLICY IF EXISTS "Admins can update all customers" ON customers;
DROP POLICY IF EXISTS "Admins can delete all customers" ON customers;

-- Create comprehensive policies for sales agents
CREATE POLICY "Sales agents can update assigned customers" ON customers
  FOR UPDATE USING (
    has_role('sales_agent') AND (
      sales_agent_id = auth.uid() OR
      sales_agent_id IN (SELECT id FROM users WHERE supabase_user_id = auth.uid())
    )
  );

CREATE POLICY "Sales agents can delete assigned customers" ON customers
  FOR DELETE USING (
    has_role('sales_agent') AND (
      sales_agent_id = auth.uid() OR
      sales_agent_id IN (SELECT id FROM users WHERE supabase_user_id = auth.uid())
    )
  );

-- Create comprehensive policies for admins
CREATE POLICY "Admins can update all customers" ON customers
  FOR UPDATE USING (is_admin());

CREATE POLICY "Admins can delete all customers" ON customers
  FOR DELETE USING (is_admin());

-- Verify policies are working by checking current policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'customers' 
ORDER BY cmd, policyname;
