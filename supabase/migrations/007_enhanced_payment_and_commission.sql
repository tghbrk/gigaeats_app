-- Enhanced Payment Integration and Commission Tracking
-- This migration adds comprehensive payment processing and commission management

-- Enhanced payment transactions with audit trail
CREATE TABLE IF NOT EXISTS payment_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'MYR',
  payment_method payment_method_enum NOT NULL,
  payment_gateway TEXT NOT NULL,
  gateway_transaction_id TEXT,
  gateway_reference TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  failure_reason TEXT,
  webhook_data JSONB,
  metadata JSONB DEFAULT '{}',
  -- Audit fields
  processed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- Constraints
  CONSTRAINT unique_gateway_transaction UNIQUE (payment_gateway, gateway_transaction_id)
);

-- Payment audit log
CREATE TABLE IF NOT EXISTS payment_audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  payment_transaction_id UUID REFERENCES payment_transactions(id),
  action TEXT NOT NULL,
  old_status TEXT,
  new_status TEXT,
  user_id UUID REFERENCES users(id),
  ip_address INET,
  user_agent TEXT,
  details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Advanced commission tracking with tiers and automation
CREATE TABLE IF NOT EXISTS commission_tiers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sales_agent_id UUID REFERENCES users(id) ON DELETE CASCADE,
  tier_name TEXT NOT NULL,
  min_orders INTEGER NOT NULL,
  max_orders INTEGER,
  commission_rate DECIMAL(5,4) NOT NULL CHECK (commission_rate >= 0 AND commission_rate <= 1),
  valid_from TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  valid_until TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS commission_payouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sales_agent_id UUID REFERENCES users(id) ON DELETE CASCADE,
  period_start TIMESTAMP WITH TIME ZONE NOT NULL,
  period_end TIMESTAMP WITH TIME ZONE NOT NULL,
  total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
  transaction_count INTEGER NOT NULL DEFAULT 0,
  status TEXT DEFAULT 'pending',
  payout_reference TEXT,
  payout_date TIMESTAMP WITH TIME ZONE,
  bank_details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Commission transactions table for detailed tracking
CREATE TABLE IF NOT EXISTS commission_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  sales_agent_id UUID REFERENCES users(id) ON DELETE CASCADE,
  commission_tier_id UUID REFERENCES commission_tiers(id),
  order_amount DECIMAL(12,2) NOT NULL,
  commission_rate DECIMAL(5,4) NOT NULL,
  commission_amount DECIMAL(12,2) NOT NULL,
  platform_fee DECIMAL(12,2) DEFAULT 0,
  net_commission DECIMAL(12,2) NOT NULL,
  status TEXT DEFAULT 'pending',
  payout_id UUID REFERENCES commission_payouts(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enhanced menu management with versioning
CREATE TABLE IF NOT EXISTS menu_versions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT false,
  published_at TIMESTAMP WITH TIME ZONE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(vendor_id, version_number)
);

CREATE TABLE IF NOT EXISTS menu_items_versioned (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  menu_version_id UUID REFERENCES menu_versions(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  category TEXT,
  image_url TEXT,
  image_alt_text TEXT,
  is_available BOOLEAN DEFAULT true,
  preparation_time INTEGER DEFAULT 30,
  nutritional_info JSONB,
  allergen_info TEXT[],
  tags TEXT[],
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Function to calculate commission automatically
CREATE OR REPLACE FUNCTION calculate_commission_on_delivery()
RETURNS TRIGGER AS $$
DECLARE
    agent_tier RECORD;
    commission_rate DECIMAL(5,4);
    commission_amount DECIMAL(12,2);
    platform_fee DECIMAL(12,2);
    net_commission DECIMAL(12,2);
BEGIN
    -- Only calculate commission when order is delivered
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' AND NEW.sales_agent_id IS NOT NULL THEN
        
        -- Get current commission tier for sales agent
        SELECT * INTO agent_tier
        FROM commission_tiers ct
        WHERE ct.sales_agent_id = NEW.sales_agent_id
          AND ct.valid_from <= NOW()
          AND (ct.valid_until IS NULL OR ct.valid_until > NOW())
          AND EXISTS (
              SELECT 1 FROM (
                  SELECT COUNT(*) as order_count
                  FROM orders o
                  WHERE o.sales_agent_id = NEW.sales_agent_id
                    AND o.status = 'delivered'
                    AND o.created_at >= ct.valid_from
              ) oc WHERE oc.order_count >= ct.min_orders
                AND (ct.max_orders IS NULL OR oc.order_count <= ct.max_orders)
          )
        ORDER BY ct.commission_rate DESC
        LIMIT 1;
        
        -- Use default rate if no tier found
        IF agent_tier IS NULL THEN
            commission_rate := 0.05; -- 5% default
        ELSE
            commission_rate := agent_tier.commission_rate;
        END IF;
        
        -- Calculate commission amounts
        commission_amount := NEW.total_amount * commission_rate;
        platform_fee := commission_amount * 0.10; -- 10% platform fee
        net_commission := commission_amount - platform_fee;
        
        -- Update order with commission amount
        NEW.commission_amount := commission_amount;
        
        -- Insert commission transaction
        INSERT INTO commission_transactions (
            order_id, sales_agent_id, commission_tier_id,
            order_amount, commission_rate, commission_amount,
            platform_fee, net_commission, status
        ) VALUES (
            NEW.id, NEW.sales_agent_id, agent_tier.id,
            NEW.total_amount, commission_rate, commission_amount,
            platform_fee, net_commission, 'earned'
        );
        
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle payment status changes
CREATE OR REPLACE FUNCTION handle_payment_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Log payment status change
    INSERT INTO payment_audit_log (
        payment_transaction_id, action, old_status, new_status,
        user_id, details, created_at
    ) VALUES (
        NEW.id, 'status_change', OLD.status, NEW.status,
        auth.uid(), 
        jsonb_build_object(
            'gateway', NEW.payment_gateway,
            'gateway_reference', NEW.gateway_reference,
            'amount', NEW.amount
        ),
        NOW()
    );
    
    -- Update order payment status if payment is successful
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        UPDATE orders 
        SET payment_status = 'paid', updated_at = NOW()
        WHERE id = NEW.order_id;
    ELSIF NEW.status = 'failed' AND OLD.status != 'failed' THEN
        UPDATE orders 
        SET payment_status = 'failed', updated_at = NOW()
        WHERE id = NEW.order_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers
DROP TRIGGER IF EXISTS trigger_calculate_commission_on_delivery ON orders;
CREATE TRIGGER trigger_calculate_commission_on_delivery
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION calculate_commission_on_delivery();

DROP TRIGGER IF EXISTS trigger_handle_payment_status_change ON payment_transactions;
CREATE TRIGGER trigger_handle_payment_status_change
    AFTER UPDATE ON payment_transactions
    FOR EACH ROW EXECUTE FUNCTION handle_payment_status_change();

-- Enable RLS on new tables
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE commission_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE commission_payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE commission_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items_versioned ENABLE ROW LEVEL SECURITY;

-- RLS Policies for payment_transactions
CREATE POLICY "Users can view payment transactions for accessible orders" ON payment_transactions
  FOR SELECT USING (
    order_id IN (
      SELECT id FROM orders WHERE
        vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()) OR
        sales_agent_id = auth.uid() OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    )
  );

CREATE POLICY "Admins can manage payment transactions" ON payment_transactions
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- RLS Policies for commission_transactions
CREATE POLICY "Sales agents can view own commission transactions" ON commission_transactions
  FOR SELECT USING (sales_agent_id = auth.uid());

CREATE POLICY "Admins can view all commission transactions" ON commission_transactions
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- RLS Policies for commission_tiers
CREATE POLICY "Sales agents can view own commission tiers" ON commission_tiers
  FOR SELECT USING (sales_agent_id = auth.uid());

CREATE POLICY "Admins can manage commission tiers" ON commission_tiers
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- RLS Policies for menu_versions
CREATE POLICY "Vendors can manage own menu versions" ON menu_versions
  FOR ALL USING (
    vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid())
  );

CREATE POLICY "Public can view active menu versions" ON menu_versions
  FOR SELECT USING (is_active = true);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_payment_transactions_order_id ON payment_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(status);
CREATE INDEX IF NOT EXISTS idx_payment_audit_log_transaction_id ON payment_audit_log(payment_transaction_id);
CREATE INDEX IF NOT EXISTS idx_commission_transactions_sales_agent_id ON commission_transactions(sales_agent_id);
CREATE INDEX IF NOT EXISTS idx_commission_transactions_order_id ON commission_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_commission_tiers_sales_agent_id ON commission_tiers(sales_agent_id);
CREATE INDEX IF NOT EXISTS idx_menu_versions_vendor_id ON menu_versions(vendor_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_versioned_menu_version_id ON menu_items_versioned(menu_version_id);

-- Add updated_at triggers
CREATE TRIGGER update_payment_transactions_updated_at
    BEFORE UPDATE ON payment_transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_commission_payouts_updated_at
    BEFORE UPDATE ON commission_payouts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_commission_transactions_updated_at
    BEFORE UPDATE ON commission_transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
