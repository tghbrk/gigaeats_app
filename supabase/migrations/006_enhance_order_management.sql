-- Enhanced Order Management System
-- This migration adds comprehensive order management features including:
-- 1. Order validation and inventory management
-- 2. Automatic order status transitions
-- 3. Order tracking and notifications
-- 4. Malaysian market specific features

-- Add inventory tracking to menu items
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS stock_quantity INTEGER DEFAULT 0;
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS low_stock_threshold INTEGER DEFAULT 5;
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS track_inventory BOOLEAN DEFAULT false;

-- Add order tracking fields
ALTER TABLE orders ADD COLUMN IF NOT EXISTS estimated_delivery_time TIMESTAMP WITH TIME ZONE;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS actual_delivery_time TIMESTAMP WITH TIME ZONE;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS preparation_started_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS ready_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS out_for_delivery_at TIMESTAMP WITH TIME ZONE;

-- Add Malaysian specific fields
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_zone TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS special_instructions TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS contact_phone TEXT;

-- Create order status history table for tracking
CREATE TABLE IF NOT EXISTS order_status_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  old_status order_status_enum,
  new_status order_status_enum NOT NULL,
  changed_by UUID REFERENCES users(id),
  reason TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create order notifications table
CREATE TABLE IF NOT EXISTS order_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  recipient_id UUID REFERENCES users(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL, -- 'status_change', 'payment_update', 'delivery_update'
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE,
  metadata JSONB DEFAULT '{}'
);

-- Function to generate unique order numbers
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT AS $$
DECLARE
    order_num TEXT;
    counter INTEGER;
    date_part TEXT;
BEGIN
    -- Format: GE-YYYYMMDD-XXXX (e.g., GE-20241201-0001)
    date_part := TO_CHAR(NOW(), 'YYYYMMDD');
    
    -- Get the count of orders created today
    SELECT COUNT(*) + 1 INTO counter
    FROM orders 
    WHERE DATE(created_at) = CURRENT_DATE;
    
    -- Format with leading zeros
    order_num := 'GE-' || date_part || '-' || LPAD(counter::TEXT, 4, '0');
    
    -- Ensure uniqueness (in case of concurrent inserts)
    WHILE EXISTS (SELECT 1 FROM orders WHERE order_number = order_num) LOOP
        counter := counter + 1;
        order_num := 'GE-' || date_part || '-' || LPAD(counter::TEXT, 4, '0');
    END LOOP;
    
    RETURN order_num;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate order before creation
CREATE OR REPLACE FUNCTION validate_order_creation()
RETURNS TRIGGER AS $$
DECLARE
    item_record RECORD;
    vendor_record RECORD;
    insufficient_stock TEXT := '';
BEGIN
    -- Generate order number if not provided
    IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
        NEW.order_number := generate_order_number();
    END IF;
    
    -- Validate vendor exists and is active
    SELECT * INTO vendor_record FROM vendors WHERE id = NEW.vendor_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Vendor not found: %', NEW.vendor_id;
    END IF;
    
    -- Set estimated delivery time if not provided (default 2 hours from now)
    IF NEW.estimated_delivery_time IS NULL THEN
        NEW.estimated_delivery_time := NOW() + INTERVAL '2 hours';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check inventory when order items are added
CREATE OR REPLACE FUNCTION check_inventory_on_order_item()
RETURNS TRIGGER AS $$
DECLARE
    menu_item_record RECORD;
BEGIN
    -- Get menu item details
    SELECT * INTO menu_item_record 
    FROM menu_items 
    WHERE id = NEW.menu_item_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Menu item not found: %', NEW.menu_item_id;
    END IF;
    
    -- Check if item is available
    IF NOT menu_item_record.is_available THEN
        RAISE EXCEPTION 'Menu item "%" is currently unavailable', menu_item_record.name;
    END IF;
    
    -- Check inventory if tracking is enabled
    IF menu_item_record.track_inventory THEN
        IF menu_item_record.stock_quantity < NEW.quantity THEN
            RAISE EXCEPTION 'Insufficient stock for "%" (Available: %, Requested: %)', 
                menu_item_record.name, menu_item_record.stock_quantity, NEW.quantity;
        END IF;
        
        -- Update stock quantity
        UPDATE menu_items 
        SET stock_quantity = stock_quantity - NEW.quantity,
            updated_at = NOW()
        WHERE id = NEW.menu_item_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle order status changes
CREATE OR REPLACE FUNCTION handle_order_status_change()
RETURNS TRIGGER AS $$
DECLARE
    status_changed BOOLEAN := FALSE;
    notification_title TEXT;
    notification_message TEXT;
    recipient_ids UUID[];
BEGIN
    -- Check if status actually changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        status_changed := TRUE;
        
        -- Update timestamp fields based on new status
        CASE NEW.status
            WHEN 'confirmed' THEN
                NEW.updated_at := NOW();
            WHEN 'preparing' THEN
                NEW.preparation_started_at := NOW();
                NEW.updated_at := NOW();
            WHEN 'ready' THEN
                NEW.ready_at := NOW();
                NEW.updated_at := NOW();
            WHEN 'out_for_delivery' THEN
                NEW.out_for_delivery_at := NOW();
                NEW.updated_at := NOW();
            WHEN 'delivered' THEN
                NEW.actual_delivery_time := NOW();
                NEW.updated_at := NOW();
            WHEN 'cancelled' THEN
                NEW.updated_at := NOW();
            ELSE
                NEW.updated_at := NOW();
        END CASE;
        
        -- Insert status history record
        INSERT INTO order_status_history (
            order_id, old_status, new_status, changed_by, created_at
        ) VALUES (
            NEW.id, OLD.status, NEW.status, auth.uid(), NOW()
        );
        
        -- Prepare notification content
        notification_title := 'Order Status Updated';
        notification_message := 'Order ' || NEW.order_number || ' status changed to ' || NEW.status;
        
        -- Determine notification recipients
        recipient_ids := ARRAY[NEW.sales_agent_id];
        
        -- Add vendor user to recipients
        recipient_ids := recipient_ids || ARRAY(
            SELECT user_id FROM vendors WHERE id = NEW.vendor_id
        );
        
        -- Create notifications for all recipients
        INSERT INTO order_notifications (
            order_id, recipient_id, notification_type, title, message, metadata
        )
        SELECT 
            NEW.id,
            unnest(recipient_ids),
            'status_change',
            notification_title,
            notification_message,
            jsonb_build_object(
                'old_status', OLD.status,
                'new_status', NEW.status,
                'order_number', NEW.order_number
            )
        WHERE unnest(recipient_ids) IS NOT NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to restore inventory when order is cancelled
CREATE OR REPLACE FUNCTION restore_inventory_on_cancel()
RETURNS TRIGGER AS $$
DECLARE
    item_record RECORD;
BEGIN
    -- Only restore inventory if order was cancelled
    IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
        -- Restore inventory for all order items
        FOR item_record IN
            SELECT oi.menu_item_id, oi.quantity
            FROM order_items oi
            WHERE oi.order_id = NEW.id
        LOOP
            UPDATE menu_items
            SET stock_quantity = stock_quantity + item_record.quantity,
                updated_at = NOW()
            WHERE id = item_record.menu_item_id
              AND track_inventory = true;
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update customer statistics when order is completed
CREATE OR REPLACE FUNCTION update_customer_stats_on_delivery()
RETURNS TRIGGER AS $$
BEGIN
    -- Update customer statistics when order is delivered
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        UPDATE customers
        SET
            total_spent = total_spent + NEW.total_amount,
            total_orders = total_orders + 1,
            average_order_value = (total_spent + NEW.total_amount) / (total_orders + 1),
            last_order_date = NEW.actual_delivery_time,
            updated_at = NOW()
        WHERE id = NEW.customer_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers for order management
DROP TRIGGER IF EXISTS trigger_validate_order_creation ON orders;
CREATE TRIGGER trigger_validate_order_creation
    BEFORE INSERT ON orders
    FOR EACH ROW EXECUTE FUNCTION validate_order_creation();

DROP TRIGGER IF EXISTS trigger_handle_order_status_change ON orders;
CREATE TRIGGER trigger_handle_order_status_change
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION handle_order_status_change();

DROP TRIGGER IF EXISTS trigger_restore_inventory_on_cancel ON orders;
CREATE TRIGGER trigger_restore_inventory_on_cancel
    AFTER UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION restore_inventory_on_cancel();

DROP TRIGGER IF EXISTS trigger_update_customer_stats_on_delivery ON orders;
CREATE TRIGGER trigger_update_customer_stats_on_delivery
    AFTER UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_customer_stats_on_delivery();

DROP TRIGGER IF EXISTS trigger_check_inventory_on_order_item ON order_items;
CREATE TRIGGER trigger_check_inventory_on_order_item
    BEFORE INSERT ON order_items
    FOR EACH ROW EXECUTE FUNCTION check_inventory_on_order_item();

-- Enable RLS on new tables
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_notifications ENABLE ROW LEVEL SECURITY;

-- RLS policies for order_status_history
CREATE POLICY "Users can view order status history for accessible orders" ON order_status_history
  FOR SELECT USING (
    order_id IN (
      SELECT id FROM orders WHERE
        vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()) OR
        sales_agent_id = auth.uid() OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    )
  );

CREATE POLICY "Users can insert order status history for accessible orders" ON order_status_history
  FOR INSERT WITH CHECK (
    order_id IN (
      SELECT id FROM orders WHERE
        vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()) OR
        sales_agent_id = auth.uid() OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    )
  );

-- RLS policies for order_notifications
CREATE POLICY "Users can view own notifications" ON order_notifications
  FOR SELECT USING (recipient_id = auth.uid());

CREATE POLICY "Users can update own notifications" ON order_notifications
  FOR UPDATE USING (recipient_id = auth.uid());

CREATE POLICY "System can create notifications" ON order_notifications
  FOR INSERT WITH CHECK (true);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_vendor_id ON orders(vendor_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_sales_agent_id ON orders(sales_agent_id);
CREATE INDEX IF NOT EXISTS idx_orders_delivery_date ON orders(delivery_date);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_menu_item_id ON order_items(menu_item_id);
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(order_id);
CREATE INDEX IF NOT EXISTS idx_order_notifications_recipient_id ON order_notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_order_notifications_is_read ON order_notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_menu_items_stock_quantity ON menu_items(stock_quantity) WHERE track_inventory = true;

-- Add updated_at triggers to new tables
CREATE TRIGGER update_order_status_history_updated_at
    BEFORE UPDATE ON order_status_history
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Add comments for documentation
COMMENT ON TABLE order_status_history IS 'Tracks all order status changes for audit trail';
COMMENT ON TABLE order_notifications IS 'Stores notifications for order-related events';
COMMENT ON FUNCTION generate_order_number() IS 'Generates unique order numbers in format GE-YYYYMMDD-XXXX';
COMMENT ON FUNCTION validate_order_creation() IS 'Validates order data before creation and sets defaults';
COMMENT ON FUNCTION check_inventory_on_order_item() IS 'Checks inventory and updates stock when order items are added';
COMMENT ON FUNCTION handle_order_status_change() IS 'Handles order status transitions and creates notifications';
COMMENT ON FUNCTION restore_inventory_on_cancel() IS 'Restores inventory when orders are cancelled';
COMMENT ON FUNCTION update_customer_stats_on_delivery() IS 'Updates customer statistics when orders are delivered';
