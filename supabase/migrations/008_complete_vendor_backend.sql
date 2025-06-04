-- Complete Vendor Backend Implementation
-- This migration completes the vendor role functionality with enhanced features

-- Add vendor analytics table for dashboard metrics
CREATE TABLE IF NOT EXISTS vendor_analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  total_orders INTEGER DEFAULT 0,
  total_revenue DECIMAL(12,2) DEFAULT 0.00,
  average_order_value DECIMAL(10,2) DEFAULT 0.00,
  new_customers INTEGER DEFAULT 0,
  repeat_customers INTEGER DEFAULT 0,
  cancelled_orders INTEGER DEFAULT 0,
  preparation_time_avg INTEGER DEFAULT 0, -- in minutes
  rating_average DECIMAL(3,2) DEFAULT 0.00,
  rating_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(vendor_id, date)
);

-- Add vendor notifications table
CREATE TABLE IF NOT EXISTS vendor_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'info', -- info, warning, success, error
  is_read BOOLEAN DEFAULT FALSE,
  action_url TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add vendor settings table
CREATE TABLE IF NOT EXISTS vendor_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  auto_accept_orders BOOLEAN DEFAULT FALSE,
  notification_preferences JSONB DEFAULT '{"email": true, "push": true, "sms": false}',
  business_hours_override JSONB DEFAULT '{}',
  holiday_schedule JSONB DEFAULT '{}',
  order_capacity_limit INTEGER DEFAULT 50,
  preparation_buffer_minutes INTEGER DEFAULT 15,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(vendor_id)
);

-- Enhanced RLS policies for vendor analytics
ALTER TABLE vendor_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendors can view own analytics" ON vendor_analytics
  FOR SELECT USING (
    vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid())
  );

CREATE POLICY "Admins can view all vendor analytics" ON vendor_analytics
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- RLS policies for vendor notifications
ALTER TABLE vendor_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendors can manage own notifications" ON vendor_notifications
  FOR ALL USING (
    vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid())
  );

CREATE POLICY "Admins can manage all vendor notifications" ON vendor_notifications
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- RLS policies for vendor settings
ALTER TABLE vendor_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendors can manage own settings" ON vendor_settings
  FOR ALL USING (
    vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid())
  );

CREATE POLICY "Admins can view all vendor settings" ON vendor_settings
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- Enhanced RLS policies for menu_items_versioned table
CREATE POLICY "Vendors can manage own versioned menu items" ON menu_items_versioned
  FOR ALL USING (
    menu_version_id IN (
      SELECT id FROM menu_versions WHERE vendor_id IN (
        SELECT id FROM vendors WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Public can view active versioned menu items" ON menu_items_versioned
  FOR SELECT USING (
    menu_version_id IN (
      SELECT id FROM menu_versions WHERE is_active = true
    )
  );

-- Function to update vendor analytics daily
CREATE OR REPLACE FUNCTION update_vendor_analytics()
RETURNS TRIGGER AS $$
DECLARE
    vendor_record RECORD;
    analytics_date DATE;
BEGIN
    -- Only process when order status changes to delivered
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        analytics_date := NEW.delivery_date;
        
        -- Get vendor info
        SELECT * INTO vendor_record FROM vendors WHERE id = NEW.vendor_id;
        
        -- Insert or update analytics record
        INSERT INTO vendor_analytics (
            vendor_id, date, total_orders, total_revenue, 
            average_order_value, created_at, updated_at
        ) VALUES (
            NEW.vendor_id, analytics_date, 1, NEW.total_amount,
            NEW.total_amount, NOW(), NOW()
        )
        ON CONFLICT (vendor_id, date) 
        DO UPDATE SET
            total_orders = vendor_analytics.total_orders + 1,
            total_revenue = vendor_analytics.total_revenue + NEW.total_amount,
            average_order_value = (vendor_analytics.total_revenue + NEW.total_amount) / (vendor_analytics.total_orders + 1),
            updated_at = NOW();
            
        -- Update vendor total orders and rating
        UPDATE vendors SET
            total_orders = total_orders + 1,
            updated_at = NOW()
        WHERE id = NEW.vendor_id;
        
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for vendor analytics
DROP TRIGGER IF EXISTS trigger_update_vendor_analytics ON orders;
CREATE TRIGGER trigger_update_vendor_analytics
    AFTER UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_vendor_analytics();

-- Function to create vendor notification
CREATE OR REPLACE FUNCTION create_vendor_notification(
    p_vendor_id UUID,
    p_title TEXT,
    p_message TEXT,
    p_type TEXT DEFAULT 'info',
    p_action_url TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    notification_id UUID;
BEGIN
    INSERT INTO vendor_notifications (
        vendor_id, title, message, type, action_url, metadata
    ) VALUES (
        p_vendor_id, p_title, p_message, p_type, p_action_url, p_metadata
    ) RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get vendor dashboard metrics
CREATE OR REPLACE FUNCTION get_vendor_dashboard_metrics(p_vendor_id UUID)
RETURNS TABLE (
    today_orders INTEGER,
    today_revenue DECIMAL(12,2),
    pending_orders INTEGER,
    avg_preparation_time INTEGER,
    rating DECIMAL(3,2),
    total_reviews INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(va.total_orders, 0)::INTEGER as today_orders,
        COALESCE(va.total_revenue, 0.00) as today_revenue,
        COALESCE(pending.count, 0)::INTEGER as pending_orders,
        COALESCE(va.preparation_time_avg, 0)::INTEGER as avg_preparation_time,
        COALESCE(v.rating, 0.00) as rating,
        COALESCE(v.total_reviews, 0)::INTEGER as total_reviews
    FROM vendors v
    LEFT JOIN vendor_analytics va ON v.id = va.vendor_id AND va.date = CURRENT_DATE
    LEFT JOIN (
        SELECT vendor_id, COUNT(*) as count
        FROM orders 
        WHERE vendor_id = p_vendor_id 
        AND status IN ('pending', 'confirmed', 'preparing')
        GROUP BY vendor_id
    ) pending ON v.id = pending.vendor_id
    WHERE v.id = p_vendor_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_vendor_analytics_vendor_date ON vendor_analytics(vendor_id, date);
CREATE INDEX IF NOT EXISTS idx_vendor_notifications_vendor_id ON vendor_notifications(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vendor_notifications_is_read ON vendor_notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_vendor_settings_vendor_id ON vendor_settings(vendor_id);

-- Add updated_at triggers
CREATE TRIGGER update_vendor_analytics_updated_at
    BEFORE UPDATE ON vendor_analytics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vendor_settings_updated_at
    BEFORE UPDATE ON vendor_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
