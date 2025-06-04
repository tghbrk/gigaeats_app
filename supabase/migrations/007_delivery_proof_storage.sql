-- Migration: Add delivery proof storage table and related functionality
-- This migration creates the infrastructure for storing delivery proof data

-- Create delivery proof table
CREATE TABLE IF NOT EXISTS delivery_proofs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
  photo_url TEXT,
  signature_url TEXT,
  recipient_name TEXT,
  notes TEXT,
  delivered_at TIMESTAMP WITH TIME ZONE NOT NULL,
  delivered_by TEXT NOT NULL,
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  location_accuracy DECIMAL(8,2),
  delivery_address TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add unique constraint to ensure one proof per order
ALTER TABLE delivery_proofs ADD CONSTRAINT unique_delivery_proof_per_order UNIQUE (order_id);

-- Add delivery proof reference to orders table
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_proof_id UUID REFERENCES delivery_proofs(id) ON DELETE SET NULL;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_delivery_proofs_order_id ON delivery_proofs(order_id);
CREATE INDEX IF NOT EXISTS idx_delivery_proofs_delivered_at ON delivery_proofs(delivered_at);
CREATE INDEX IF NOT EXISTS idx_delivery_proofs_delivered_by ON delivery_proofs(delivered_by);
CREATE INDEX IF NOT EXISTS idx_delivery_proofs_location ON delivery_proofs(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_orders_delivery_proof_id ON orders(delivery_proof_id);

-- Enable RLS on delivery_proofs table
ALTER TABLE delivery_proofs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for delivery_proofs table
-- Users can view delivery proofs for orders they're involved in
CREATE POLICY "Users can view accessible delivery proofs" ON delivery_proofs
  FOR SELECT USING (
    order_id IN (
      SELECT o.id FROM orders o 
      WHERE 
        o.sales_agent_id IN (SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub') OR
        o.vendor_id IN (SELECT id FROM vendors WHERE firebase_uid = auth.jwt() ->> 'sub') OR
        EXISTS (SELECT 1 FROM users WHERE firebase_uid = auth.jwt() ->> 'sub' AND role = 'admin')
    )
  );

-- Users can create delivery proofs for orders they're involved in
CREATE POLICY "Users can create delivery proofs for accessible orders" ON delivery_proofs
  FOR INSERT WITH CHECK (
    order_id IN (
      SELECT o.id FROM orders o 
      WHERE 
        o.sales_agent_id IN (SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub') OR
        o.vendor_id IN (SELECT id FROM vendors WHERE firebase_uid = auth.jwt() ->> 'sub') OR
        EXISTS (SELECT 1 FROM users WHERE firebase_uid = auth.jwt() ->> 'sub' AND role = 'admin')
    )
  );

-- Users can update delivery proofs for orders they're involved in
CREATE POLICY "Users can update accessible delivery proofs" ON delivery_proofs
  FOR UPDATE USING (
    order_id IN (
      SELECT o.id FROM orders o 
      WHERE 
        o.sales_agent_id IN (SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub') OR
        o.vendor_id IN (SELECT id FROM vendors WHERE firebase_uid = auth.jwt() ->> 'sub') OR
        EXISTS (SELECT 1 FROM users WHERE firebase_uid = auth.jwt() ->> 'sub' AND role = 'admin')
    )
  );

-- Only admins can delete delivery proofs (for data integrity)
CREATE POLICY "Only admins can delete delivery proofs" ON delivery_proofs
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM users WHERE firebase_uid = auth.jwt() ->> 'sub' AND role = 'admin')
  );

-- Create function to automatically update order status when delivery proof is created
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
  
  -- Insert order status history record
  INSERT INTO order_status_history (order_id, old_status, new_status, changed_by, notes)
  SELECT 
    NEW.order_id,
    o.status,
    'delivered',
    NEW.delivered_by,
    'Order marked as delivered with proof of delivery'
  FROM orders o 
  WHERE o.id = NEW.order_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for delivery proof creation
CREATE TRIGGER trigger_delivery_proof_creation
  AFTER INSERT ON delivery_proofs
  FOR EACH ROW
  EXECUTE FUNCTION handle_delivery_proof_creation();

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION update_delivery_proof_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updating timestamps
CREATE TRIGGER trigger_delivery_proof_updated_at
  BEFORE UPDATE ON delivery_proofs
  FOR EACH ROW
  EXECUTE FUNCTION update_delivery_proof_updated_at();

-- Add comments for documentation
COMMENT ON TABLE delivery_proofs IS 'Stores proof of delivery data including photos, signatures, and location information';
COMMENT ON COLUMN delivery_proofs.order_id IS 'Reference to the order this proof belongs to';
COMMENT ON COLUMN delivery_proofs.photo_url IS 'URL to the delivery photo stored in Supabase storage';
COMMENT ON COLUMN delivery_proofs.signature_url IS 'URL to the recipient signature stored in Supabase storage';
COMMENT ON COLUMN delivery_proofs.latitude IS 'GPS latitude coordinate of delivery location';
COMMENT ON COLUMN delivery_proofs.longitude IS 'GPS longitude coordinate of delivery location';
COMMENT ON COLUMN delivery_proofs.location_accuracy IS 'GPS accuracy in meters';
COMMENT ON COLUMN delivery_proofs.delivery_address IS 'Human-readable address from reverse geocoding';
COMMENT ON FUNCTION handle_delivery_proof_creation() IS 'Automatically updates order status to delivered when proof is created';
