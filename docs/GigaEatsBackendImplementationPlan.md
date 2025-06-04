# GigaEats Backend Implementation Plan

## Overview

This implementation plan outlines the development roadmap for completing all identified missing backend features for the GigaEats platform. The plan is organized by priority level and includes specific tasks, timelines, technical requirements, and implementation approaches.

## High Priority Features (4-6 weeks)

### 1. Order Management System (1-2 weeks)

**Tasks:**
- Implement order creation API endpoint
- Develop order status transition logic
- Create order tracking and history endpoints
- Implement inventory checking during order creation
- Add order validation and error handling

**Technical Requirements:**
- Enhance existing orders table with tracking fields
- Create order status history table
- Implement database triggers for status transitions
- Add RLS policies for order access control

**Implementation Approach:**
````sql path=supabase/migrations/007_complete_order_management.sql mode=EDIT
-- Complete Order Management System Implementation
-- Add missing order tracking functionality

-- Create order status history table if not exists
CREATE TABLE IF NOT EXISTS order_status_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  previous_status order_status_enum,
  new_status order_status_enum NOT NULL,
  changed_by UUID REFERENCES users(id),
  changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reason TEXT
);

-- Function to handle order status changes and create notifications
CREATE OR REPLACE FUNCTION handle_order_status_change()
RETURNS TRIGGER AS $$
DECLARE
  recipient_id UUID;
BEGIN
  -- Only proceed if status has changed
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;
  
  -- Record status change in history
  INSERT INTO order_status_history (
    order_id, previous_status, new_status, changed_by, changed_at
  ) VALUES (
    NEW.id, OLD.status, NEW.status, auth.uid(), NOW()
  );
  
  -- Update timestamps based on status
  CASE NEW.status
    WHEN 'preparing' THEN
      NEW.preparation_started_at := NOW();
    WHEN 'ready' THEN
      NEW.ready_at := NOW();
    WHEN 'out_for_delivery' THEN
      NEW.out_for_delivery_at := NOW();
    WHEN 'delivered' THEN
      NEW.actual_delivery_time := NOW();
    ELSE NULL;
  END CASE;
  
  -- Create notifications for relevant parties
  -- For vendor
  INSERT INTO order_notifications (
    order_id, recipient_id, notification_type, title, message
  ) SELECT 
    NEW.id, 
    vendor_id, 
    'status_change',
    'Order Status Updated',
    'Order #' || NEW.order_number || ' status changed to ' || NEW.status
  FROM orders WHERE id = NEW.id;
  
  -- For sales agent
  IF NEW.sales_agent_id IS NOT NULL THEN
    INSERT INTO order_notifications (
      order_id, recipient_id, notification_type, title, message
    ) VALUES (
      NEW.id, 
      NEW.sales_agent_id, 
      'status_change',
      'Order Status Updated',
      'Order #' || NEW.order_number || ' status changed to ' || NEW.status
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
````

**Integration Points:**
- Connect with `CreateOrderScreen` in sales agent dashboard
- Integrate with vendor order management UI
- Link to inventory management system

**Dependencies:**
- None, can be implemented immediately

### 2. Payment Integration (1-2 weeks)

**Tasks:**
- Implement FPX payment gateway integration
- Add e-wallet support (GrabPay, Touch 'n Go)
- Create payment processing API endpoints
- Develop payment status tracking and updates
- Implement payment verification and reconciliation

**Technical Requirements:**
- Create payment transactions table
- Add payment gateway configuration
- Implement payment webhook handlers
- Add payment-related RLS policies

**Implementation Approach:**
````sql path=supabase/migrations/008_payment_integration.sql mode=EDIT
-- Payment Integration Implementation
-- Add payment processing and tracking functionality

-- Create payment transactions table
CREATE TABLE IF NOT EXISTS payment_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  amount DECIMAL(12,2) NOT NULL,
  payment_method payment_method_enum NOT NULL,
  payment_gateway TEXT NOT NULL,
  gateway_reference TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  error_message TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add payment gateway configurations table
CREATE TABLE IF NOT EXISTS payment_gateway_configs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gateway_name TEXT NOT NULL UNIQUE,
  is_active BOOLEAN DEFAULT true,
  config JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Function to update order payment status when transaction status changes
CREATE OR REPLACE FUNCTION update_order_payment_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' THEN
    UPDATE orders SET 
      payment_status = 'paid',
      payment_reference = NEW.gateway_reference,
      updated_at = NOW()
    WHERE id = NEW.order_id;
  ELSIF NEW.status = 'failed' THEN
    UPDATE orders SET 
      payment_status = 'failed',
      updated_at = NOW()
    WHERE id = NEW.order_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for payment status updates
CREATE TRIGGER trigger_update_order_payment_status
  AFTER UPDATE ON payment_transactions
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION update_order_payment_status();
````

**Integration Points:**
- Connect with order creation flow
- Integrate with payment service providers' APIs
- Link to order status updates

**Dependencies:**
- Order Management System should be implemented first

### 3. Sales Agent Commission Tracking (1 week)

**Tasks:**
- Implement commission calculation logic
- Create commission tracking endpoints
- Develop commission history and reporting
- Add commission payout status tracking

**Technical Requirements:**
- Create commission transactions table
- Add commission calculation triggers
- Implement commission-related RLS policies

**Implementation Approach:**
````sql path=supabase/migrations/009_commission_tracking.sql mode=EDIT
-- Commission Tracking Implementation
-- Add commission calculation and tracking functionality

-- Create commission transactions table
CREATE TABLE IF NOT EXISTS commission_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sales_agent_id UUID REFERENCES users(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  rate DECIMAL(5,4) NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- pending, approved, paid
  payout_reference TEXT,
  payout_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Function to calculate and record commission when order is delivered
CREATE OR REPLACE FUNCTION calculate_commission_on_delivery()
RETURNS TRIGGER AS $$
DECLARE
  commission_rate DECIMAL(5,4);
  commission_amount DECIMAL(10,2);
BEGIN
  -- Only calculate commission when order is delivered
  IF NEW.status = 'delivered' AND OLD.status != 'delivered' AND NEW.sales_agent_id IS NOT NULL THEN
    -- Get commission rate from user profile
    SELECT commission_rate INTO commission_rate
    FROM user_profiles
    WHERE user_id = NEW.sales_agent_id;
    
    -- Default to 7% if not set
    IF commission_rate IS NULL THEN
      commission_rate := 0.07;
    END IF;
    
    -- Calculate commission amount
    commission_amount := NEW.subtotal * commission_rate;
    
    -- Record commission transaction
    INSERT INTO commission_transactions (
      sales_agent_id, order_id, amount, rate, status
    ) VALUES (
      NEW.sales_agent_id, NEW.id, commission_amount, commission_rate, 'pending'
    );
    
    -- Update order with commission amount
    UPDATE orders SET 
      commission_amount = commission_amount,
      updated_at = NOW()
    WHERE id = NEW.id;
    
    -- Update user profile total earnings
    UPDATE user_profiles SET
      total_earnings = total_earnings + commission_amount,
      total_orders = total_orders + 1,
      updated_at = NOW()
    WHERE user_id = NEW.sales_agent_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for commission calculation
CREATE TRIGGER trigger_calculate_commission_on_delivery
  AFTER UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION calculate_commission_on_delivery();
````

**Integration Points:**
- Connect with sales agent dashboard
- Integrate with order status updates
- Link to admin commission management UI

**Dependencies:**
- Order Management System should be implemented first

### 4. Vendor Menu Management (1 week)

**Tasks:**
- Implement menu item CRUD operations
- Develop bulk pricing tier management
- Create inventory tracking endpoints
- Add menu item categorization and search

**Technical Requirements:**
- Enhance menu_items table with additional fields
- Create menu categories table
- Implement menu-related RLS policies

**Implementation Approach:**
````sql path=supabase/migrations/010_vendor_menu_management.sql mode=EDIT
-- Vendor Menu Management Implementation
-- Add menu item management and bulk pricing functionality

-- Enhance menu_items table with additional fields
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS category_id UUID;
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS preparation_time INTEGER; -- in minutes
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS minimum_order_quantity INTEGER DEFAULT 1;
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS maximum_order_quantity INTEGER;
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS lead_time_hours INTEGER DEFAULT 24; -- hours needed before delivery

-- Create menu categories table
CREATE TABLE IF NOT EXISTS menu_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create bulk pricing tiers table
CREATE TABLE IF NOT EXISTS bulk_pricing_tiers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  menu_item_id UUID REFERENCES menu_items(id) ON DELETE CASCADE,
  min_quantity INTEGER NOT NULL,
  max_quantity INTEGER,
  unit_price DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT min_less_than_max CHECK (max_quantity IS NULL OR min_quantity < max_quantity)
);

-- Add foreign key constraint for category_id
ALTER TABLE menu_items 
  ADD CONSTRAINT fk_menu_items_category 
  FOREIGN KEY (category_id) REFERENCES menu_categories(id) ON DELETE SET NULL;

-- Function to get price based on quantity
CREATE OR REPLACE FUNCTION get_bulk_price(p_menu_item_id UUID, p_quantity INTEGER)
RETURNS DECIMAL(10,2) AS $$
DECLARE
  v_price DECIMAL(10,2);
BEGIN
  -- Try to find a matching tier
  SELECT unit_price INTO v_price
  FROM bulk_pricing_tiers
  WHERE menu_item_id = p_menu_item_id
    AND p_quantity >= min_quantity
    AND (max_quantity IS NULL OR p_quantity <= max_quantity)
  ORDER BY min_quantity DESC
  LIMIT 1;
  
  -- If no tier found, use default price
  IF v_price IS NULL THEN
    SELECT price INTO v_price
    FROM menu_items
    WHERE id = p_menu_item_id;
  END IF;
  
  RETURN v_price;
END;
$$ LANGUAGE plpgsql STABLE;
````

**Integration Points:**
- Connect with vendor dashboard menu management UI
- Integrate with order creation flow
- Link to inventory management system

**Dependencies:**
- None, can be implemented in parallel with other high priority items

## Medium Priority Features (3-5 weeks)

### 5. Customer Management (CRM Lite) (1 week)

**Tasks:**
- Implement customer CRUD operations
- Develop customer history tracking
- Create customer preferences storage
- Add customer search and filtering

**Technical Requirements:**
- Enhance customers table with additional fields
- Create customer_preferences table
- Implement customer-related RLS policies

**Implementation Approach:**
````sql path=supabase/migrations/011_customer_management.sql mode=EDIT
-- Customer Management (CRM Lite) Implementation
-- Add customer tracking and preferences functionality

-- Enhance customers table with additional fields
ALTER TABLE customers ADD COLUMN IF NOT EXISTS customer_type TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS company_size TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS industry TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS total_orders INTEGER DEFAULT 0;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS total_spent DECIMAL(12,2) DEFAULT 0.00;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS last_order_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS acquisition_source TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS assigned_sales_agent_id UUID REFERENCES users(id);

-- Create customer preferences table
CREATE TABLE IF NOT EXISTS customer_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  preference_key TEXT NOT NULL,
  preference_value TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(customer_id, preference_key)
);

-- Create customer notes table
CREATE TABLE IF NOT EXISTS customer_notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  created_by UUID REFERENCES users(id),
  note TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Function to update customer stats when order is delivered
CREATE OR REPLACE FUNCTION update_customer_stats_on_delivery()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update stats when order is delivered
  IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
    UPDATE customers SET
      total_orders = total_orders + 1,
      total_spent = total_spent + NEW.total_amount,
      last_order_date = NOW(),
      updated_at = NOW()
    WHERE id = NEW.customer_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for customer stats updates
CREATE TRIGGER trigger_update_customer_stats_on_delivery
  AFTER UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_customer_stats_on_delivery();
````

**Integration Points:**
- Connect with sales agent dashboard customer management UI
- Integrate with order creation flow
- Link to customer search and filtering components

**Dependencies:**
- Order Management System should be implemented first

### 6. Push Notifications (1 week)

**Tasks:**
- Implement FCM integration
- Develop notification creation and delivery
- Create notification preferences management
- Add notification history and tracking

**Technical Requirements:**
- Enhance user_fcm_tokens table
- Create notification_preferences table
- Implement notification delivery service

**Implementation Approach:**
````sql path=supabase/migrations/012_push_notifications.sql mode=EDIT
-- Push Notifications Implementation
-- Add notification delivery and tracking functionality

-- Enhance user_fcm_tokens table
ALTER TABLE user_fcm_tokens ADD COLUMN IF NOT EXISTS device_type TEXT;
ALTER TABLE user_fcm_tokens ADD COLUMN IF NOT EXISTS app_version TEXT;
ALTER TABLE user_fcm_tokens ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMP WITH TIME ZONE;

-- Create notification preferences table
CREATE TABLE IF NOT EXISTS notification_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL,
  enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, notification_type)
);

-- Create notification delivery tracking table
CREATE TABLE IF NOT EXISTS notification_deliveries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  notification_id UUID REFERENCES order_notifications(id) ON DELETE CASCADE,
  fcm_token_id UUID REFERENCES user_fcm_tokens(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- pending, sent, delivered, failed
  error_message TEXT,
  sent_at TIMESTAMP WITH TIME ZONE,
  delivered_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Function to queue notifications for delivery
CREATE OR REPLACE FUNCTION queue_notification_delivery()
RETURNS TRIGGER AS $$
DECLARE
  token_record RECORD;
  should_notify BOOLEAN;
BEGIN
  -- Check if user has enabled this notification type
  SELECT enabled INTO should_notify
  FROM notification_preferences
  WHERE user_id = NEW.recipient_id
    AND notification_type = NEW.notification_type;
  
  -- Default to true if no preference set
  IF should_notify IS NULL THEN
    should_notify := true;
  END IF;
  
  -- Only queue if notifications are enabled
  IF should_notify THEN
    -- Queue delivery for each of the user's FCM tokens
    FOR token_record IN
      SELECT id FROM user_fcm_tokens
      WHERE user_id = NEW.recipient_id
        AND is_active = true
    LOOP
      INSERT INTO notification_deliveries (
        notification_id, fcm_token_id, status
      ) VALUES (
        NEW.id, token_record.id, 'pending'
      );
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for notification delivery
CREATE TRIGGER trigger_queue_notification_delivery
  AFTER INSERT ON order_notifications
  FOR EACH ROW
  EXECUTE FUNCTION queue_notification_delivery();
````

**Integration Points:**
- Connect with Firebase Cloud Messaging
- Integrate with order status updates
- Link to user notification preferences UI

**Dependencies:**
- Order Management System should be implemented first

### 7. Real-time Order Tracking (1-2 weeks)

**Tasks:**
- Implement Supabase real-time subscriptions
- Develop order status update broadcasts
- Create real-time location tracking (optional)
- Add delivery ETA calculations

**Technical Requirements:**
- Configure Supabase real-time channels
- Enhance order status tracking
- Implement real-time RLS policies

**Implementation Approach:**
````sql path=supabase/migrations/013_realtime_order_tracking.sql mode=EDIT
-- Real-time Order Tracking Implementation
-- Add real-time order status updates and tracking functionality

-- Configure Supabase real-time channels
-- Enable real-time for orders table
ALTER TABLE orders ENABLE REPLICA IDENTITY FULL;

-- Create delivery tracking table
CREATE TABLE IF NOT EXISTS delivery_tracking (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  accuracy DECIMAL(6,2),
  recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create delivery ETA function
CREATE OR REPLACE FUNCTION calculate_delivery_eta(p_order_id UUID)
RETURNS TIMESTAMP WITH TIME ZONE AS $$
DECLARE
  v_preparation_time INTEGER;
  v_distance DECIMAL;
  v_travel_time INTEGER;
  v_eta TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Get average preparation time from order items
  SELECT AVG(mi.preparation_time) INTO v_preparation_time
  FROM order_items oi
  JOIN menu_items mi ON oi.menu_item_id = mi.id
  WHERE oi.order_id = p_order_id;
  
  -- Default to 30 minutes if no data
  IF v_preparation_time IS NULL THEN
    v_preparation_time := 30;
  END IF;
  
  -- Get distance from vendor to delivery location (simplified)
  SELECT 
    COALESCE(o.delivery_distance, 5) INTO v_distance
  FROM orders o
  WHERE o.id = p_order_id;
  
  -- Calculate travel time (assume 1km = 3 minutes)
  v_travel_time := v_distance * 3;
  
  -- Calculate ETA
  SELECT 
    CASE
      WHEN o.status = 'pending' THEN NOW() + (v_preparation_time + v_travel_time) * INTERVAL '1 minute'
      WHEN o.status = 'preparing' THEN o.preparation_started_at + v_preparation_time * INTERVAL '1 minute' + v_travel_time * INTERVAL '1 minute'
      WHEN o.status = 'ready' THEN o.ready_at + v_travel_time * INTERVAL '1 minute'
      WHEN o.status = 'out_for_delivery' THEN o.out_for_delivery_at + v_travel_time * INTERVAL '1 minute'
      ELSE o.expected_delivery_time
    END INTO v_eta
  FROM orders o
  WHERE o.id = p_order_id;
  
  RETURN v_eta;
END;
$$ LANGUAGE plpgsql STABLE;

-- Create function to update order ETA
CREATE OR REPLACE FUNCTION update_order_eta()
RETURNS TRIGGER AS $$
BEGIN
  -- Update ETA when status changes
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    NEW.expected_delivery_time := calculate_delivery_eta(NEW.id);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for ETA updates
CREATE TRIGGER trigger_update_order_eta
  BEFORE UPDATE ON orders
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION update_order_eta();
````

**Integration Points:**
- Connect with Supabase real-time subscriptions in Flutter app
- Integrate with order status updates
- Link to delivery tracking UI components

**Dependencies:**
- Order Management System should be implemented first

### 8. Advanced Search & Filtering (1 week)

**Tasks:**
- Implement full-text search for products and vendors
- Develop advanced filtering options
- Create search history and suggestions
- Add location-based search functionality

**Technical Requirements:**
- Configure PostgreSQL full-text search
- Create search_history table
- Implement search-related RLS policies

**Implementation Approach:**
````sql path=supabase/migrations/014_advanced_search.sql mode=EDIT
-- Advanced Search & Filtering Implementation
-- Add full-text search and advanced filtering functionality

-- Enable full-text search on vendors
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS search_vector tsvector;
CREATE INDEX IF NOT EXISTS vendors_search_idx ON vendors USING GIN (search_vector);

-- Enable full-text search on menu_items
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS search_vector tsvector;
CREATE INDEX IF NOT EXISTS menu_items_search_idx ON menu_items USING GIN (search_vector);

-- Create search history table
CREATE TABLE IF NOT EXISTS search_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  query TEXT NOT NULL,
  result_count INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create function to update vendor search vector
CREATE OR REPLACE FUNCTION update_vendor_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector = 
    setweight(to_tsvector('english', COALESCE(NEW.name, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(NEW.cuisine_type, '')), 'C') ||
    setweight(to_tsvector('english', COALESCE(NEW.address, '')), 'D');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create function to update menu_item search vector
CREATE OR REPLACE FUNCTION update_menu_item_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector = 
    setweight(to_tsvector('english', COALESCE(NEW.name, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'B');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for search vector updates
CREATE TRIGGER trigger_update_vendor_search_vector
  BEFORE INSERT OR UPDATE ON vendors
  FOR EACH ROW
  EXECUTE FUNCTION update_vendor_search_vector();

CREATE TRIGGER trigger_update_menu_item_search_vector
  BEFORE INSERT OR UPDATE ON menu_items
  FOR EACH ROW
  EXECUTE FUNCTION update_menu_item_search_vector();

-- Create function for combined vendor and menu search
CREATE OR REPLACE FUNCTION search_vendors_and_items(search_query TEXT)
RETURNS TABLE (
  type TEXT,
  id UUID,
  name TEXT,
  description TEXT,
  image_url TEXT,
  rank REAL
) AS $$
BEGIN
  RETURN QUERY
    -- Search vendors
    SELECT 
      'vendor' AS type,
      v.id,
      v.name,
      v.description,
      v.logo_url AS image_url,
      ts_rank(v.search_vector, to_tsquery('english', search_query)) AS rank
    FROM vendors v
    WHERE v.search_vector @@ to_tsquery('english', search_query)
    
    UNION ALL
    
    -- Search menu items
    SELECT 
      'menu_item' AS type,
      m.id,
      m.name,
      m.description,
      m.image_url,
      ts_rank(m.search_vector, to_tsquery('english', search_query)) AS rank
    FROM menu_items m
    WHERE m.search_vector @@ to_tsquery('english', search_query)
    
    ORDER BY rank DESC
    LIMIT 50;
END;
$$ LANGUAGE plpgsql STABLE;
````

**Integration Points:**
- Connect with search UI components
- Integrate with vendor and product listings
- Link to location-based services

**Dependencies:**
- Vendor Menu Management should be implemented first

## Low Priority Features (3-4 weeks)

### 9. Advanced Analytics & Reporting (1-2 weeks)

**Tasks:**
- Implement sales performance analytics
- Develop commission tracking reports
- Create vendor performance metrics
- Add customer behavior analytics

**Technical Requirements:**
- Create analytics views and materialized views
- Implement scheduled data aggregation
- Add analytics-related RLS policies

**Implementation Approach:**
````sql path=supabase/migrations/015_analytics_reporting.sql mode=EDIT
-- Advanced Analytics & Reporting Implementation
-- Add analytics views and reporting functionality

-- Create sales performance view
CREATE OR REPLACE VIEW sales_performance_view AS
SELECT
  DATE_TRUNC('day', o.created_at) AS order_date,
  COUNT(o.id) AS total_orders,
  SUM(o.total_amount) AS total_sales,
  SUM(o.commission_amount) AS total_commission,
  COUNT(DISTINCT o.customer_id) AS unique_customers,
  COUNT(DISTINCT o.vendor_id) AS unique_vendors,
  AVG(o.total_amount) AS average_order_value
FROM orders o
WHERE o.status = 'delivered'
GROUP BY DATE_TRUNC('day', o.created_at)
ORDER BY order_date DESC;

-- Create sales agent performance view
CREATE OR REPLACE VIEW sales_agent_performance_view AS
SELECT
  u.id AS sales_agent_id,
  u.full_name AS sales_agent_name,
  COUNT(o.id) AS total_orders,
  SUM(o.total_amount) AS total_sales,
  SUM(o.commission_amount) AS total_commission,
  COUNT(DISTINCT o.customer_id) AS unique_customers,
  COUNT(DISTINCT o.vendor_id) AS unique_vendors,
  AVG(o.total_amount) AS average_order_value
FROM orders o
JOIN users u ON o.sales_agent_id = u.id
WHERE o.status = 'delivered'
GROUP BY u.id, u.full_name
ORDER BY total_sales DESC;

-- Create vendor performance view
CREATE OR REPLACE VIEW vendor_performance_view AS
SELECT
  v.id AS vendor_id,
  v.name AS vendor_name,
  COUNT(o.id) AS total_orders,
  SUM(o.subtotal) AS total_sales,
  COUNT(DISTINCT o.customer_id) AS unique_customers,
  COUNT(DISTINCT o.sales_agent_id) AS unique_sales_agents,
  AVG(o.subtotal) AS average_order_value
FROM orders o
JOIN vendors v ON o.vendor_id = v.id
WHERE o.status = 'delivered'
GROUP BY v.id, v.name
ORDER BY total_sales DESC;

-- Create customer analytics view
CREATE OR REPLACE VIEW customer_analytics_view AS
SELECT
  c.id AS customer_id,
  c.name AS customer_name,
  c.total_orders,
  c.total_spent,
  c.last_order_date,
  COUNT(DISTINCT o.vendor_id) AS unique_vendors_ordered,
  AVG(o.total_amount) AS average_order_value,
  MAX(o.total_amount) AS highest_order_value,
  MIN(o.total_amount) AS lowest_order_value
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id AND o.status = 'delivered'
GROUP BY c.id, c.name, c.total_orders, c.total_spent, c.last_order_date
ORDER BY c.total_spent DESC;

-- Create function to generate monthly sales report
CREATE OR REPLACE FUNCTION generate_monthly_sales_report(year INTEGER, month INTEGER)
RETURNS TABLE (
  sales_agent_id UUID,
  sales_agent_name TEXT,
  total_orders INTEGER,
  total_sales DECIMAL,
  total_commission DECIMAL,
  unique_customers INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id AS sales_agent_id,
    u.full_name AS sales_agent_name,
    COUNT(o.id)::INTEGER AS total_orders,
    SUM(o.total_amount) AS total_sales,
    SUM(o.commission_amount) AS total_commission,
    COUNT(DISTINCT o.customer_id)::INTEGER AS unique_customers
  FROM orders o
  JOIN users u ON o.sales_agent_id = u.id
  WHERE 
    o.status = 'delivered' AND
    EXTRACT(YEAR FROM o.created_at) = year AND
    EXTRACT(MONTH FROM o.created_at) = month
  GROUP BY u.id, u.full_name
  ORDER BY total_sales DESC;
END;
$$ LANGUAGE plpgsql STABLE;
````

**Integration Points:**
- Connect with admin dashboard analytics UI
- Integrate with sales agent performance reports
- Link to vendor performance metrics

**Dependencies:**
- Order Management System and Commission Tracking should be implemented first

### 10. Inventory Management (1 week)

**Tasks:**
- Implement inventory tracking
- Develop low stock alerts
- Create inventory history and audit logs
- Add inventory forecasting (optional)

**Technical Requirements:**
- Create inventory_items table
- Implement inventory update triggers
- Add inventory-related RLS policies

**Implementation Approach:**
````sql path=supabase/migrations/016_inventory_management.sql mode=EDIT
-- Inventory Management Implementation
-- Add inventory tracking and management functionality

-- Create inventory items table
CREATE TABLE IF NOT EXISTS inventory_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  menu_item_id UUID REFERENCES menu_items(id) ON DELETE CASCADE,
  current_stock INTEGER NOT NULL DEFAULT 0,
  minimum_stock INTEGER NOT NULL DEFAULT 10,
  unit_of_measure TEXT NOT NULL DEFAULT 'piece',
  last_restock_date TIMESTAMP WITH TIME ZONE,
  next_restock_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(vendor_id, menu_item_id)
);

-- Create inventory history table
CREATE TABLE IF NOT EXISTS inventory_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  inventory_item_id UUID REFERENCES inventory_items(id) ON DELETE CASCADE,
  previous_stock INTEGER NOT NULL,
  new_stock INTEGER NOT NULL,
  change_amount INTEGER NOT NULL,
  change_reason TEXT NOT NULL,
  changed_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create low stock alerts table
CREATE TABLE IF NOT EXISTS low_stock_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  inventory_item_id UUID REFERENCES inventory_items(id) ON DELETE CASCADE,
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  menu_item_id UUID REFERENCES menu_items(id) ON DELETE CASCADE,
  current_stock INTEGER NOT NULL,
  minimum_stock INTEGER NOT NULL,
  is_resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Function to update inventory when order is placed
CREATE OR REPLACE FUNCTION update_inventory_on_order()
RETURNS TRIGGER AS $$
DECLARE
  inv_record RECORD;
BEGIN
  -- Only reduce inventory for new orders
  IF TG_OP = 'INSERT' THEN
    -- Update inventory for each order item
    FOR inv_record IN
      SELECT 
        oi.menu_item_id,
        oi.quantity,
        ii.id AS inventory_item_id,
        ii.current_stock,
        ii.minimum_stock
      FROM order_items oi
      JOIN inventory_items ii ON oi.menu_item_id = ii.menu_item_id
      WHERE oi.order_id = NEW.id
    LOOP
      -- Update inventory
      UPDATE inventory_items
      SET 
        current_stock = current_stock - inv_record.quantity,
        updated_at = NOW()
      WHERE id = inv_record.inventory_item_id;
      
      -- Record inventory change
      INSERT INTO inventory_history (
        inventory_item_id, previous_stock, new_stock, 
        change_amount, change_reason, changed_by
      ) VALUES (
        inv_record.inventory_item_id,
        inv_record.current_stock,
        inv_record.current_stock - inv_record.quantity,
        -inv_record.quantity,
        'Order #' || NEW.order_number,
        auth.uid()
      );
      
      -- Create low stock alert if needed
      IF (inv_record.current_stock - inv_record.quantity) < inv_record.minimum_stock THEN
        INSERT INTO low_stock_alerts (
          inventory_item_id, vendor_id, menu_item_id,
          current_stock, minimum_stock
        ) 
        SELECT 
          inv_record.inventory_item_id,
          ii.vendor_id,
          ii.menu_item_id,
          (inv_record.current_stock - inv_record.quantity),
          inv_record.minimum_stock
        FROM inventory_items ii
        WHERE ii.id = inv_record.inventory_item_id
        ON CONFLICT DO NOTHING;
      END IF;
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for inventory updates
CREATE TRIGGER trigger_update_inventory_on_order
  AFTER INSERT ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_inventory_on_order();
````

**Integration Points:**
- Connect with vendor dashboard inventory UI
- Integrate with order creation flow
- Link to low stock notifications

**Dependencies:**
- Vendor Menu Management should be implemented first

### 11. Bulk Order Management (1 week)

**Tasks:**
- Implement multi-vendor order creation
- Develop bulk order splitting logic
- Create consolidated order view
- Add bulk order optimization

**Technical Requirements:**
- Create bulk_orders table
- Implement order splitting functions
- Add bulk order-related RLS policies

**Implementation Approach:**
````sql path=supabase/migrations/017_bulk_order_management.sql mode=EDIT
-- Bulk Order Management Implementation
-- Add multi-vendor order functionality

-- Create bulk orders table
CREATE TABLE IF NOT EXISTS bulk_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  sales_agent_id UUID REFERENCES users(id),
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending',
  delivery_address TEXT,
  delivery_date TIMESTAMP WITH TIME ZONE,
  special_instructions TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create bulk order to orders mapping table
CREATE TABLE IF NOT EXISTS bulk_order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bulk_order_id UUID REFERENCES bulk_orders(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  vendor_id UUID REFERENCES vendors(id),
  subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Function to create individual orders from bulk order
CREATE OR REPLACE FUNCTION split_bulk_order(p_bulk_order_id UUID)
RETURNS SETOF UUID AS $$
DECLARE
  bulk_order_record RECORD;
  vendor_record RECORD;
  new_order_id UUID;
  order_number TEXT;
BEGIN
  -- Get bulk order details
  SELECT * INTO bulk_order_record
  FROM bulk_orders
  WHERE id = p_bulk_order_id;
  
  -- Process each vendor in the bulk order
  FOR vendor_record IN
    SELECT DISTINCT vendor_id
    FROM bulk_order_items
    WHERE bulk_order_id = p_bulk_order_id
  LOOP
    -- Generate order number
    SELECT 'ORD-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
           LPAD(CAST(FLOOR(RANDOM() * 10000) AS TEXT), 4, '0')
    INTO order_number;
    
    -- Create new order for this vendor
    INSERT INTO orders (
      customer_id, vendor_id, sales_agent_id,
      order_number, status, subtotal,
      delivery_address, expected_delivery_time,
      special_instructions
    ) VALUES (
      bulk_order_record.customer_id,
      vendor_record.vendor_id,
      bulk_order_record.sales_agent_id,
      order_number,
      'pending',
      (SELECT SUM(subtotal) FROM bulk_order_items 
       WHERE bulk_order_id = p_bulk_order_id
       AND vendor_id = vendor_record.vendor_id),
      bulk_order_record.delivery_address,
      bulk_order_record.delivery_date,
      bulk_order_record.special_instructions
    )
    RETURNING id INTO new_order_id;
    
    -- Update bulk order item with the new order id
    UPDATE bulk_order_items
    SET order_id = new_order_id
    WHERE bulk_order_id = p_bulk_order_id
      AND vendor_id = vendor_record.vendor_id;
    
    -- Return the new order id
    RETURN NEXT new_order_id;
  END LOOP;
  
  -- Update bulk order status
  UPDATE bulk_orders
  SET 
    status = 'processed',
    updated_at = NOW()
  WHERE id = p_bulk_order_id;
  
  RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate bulk order total
CREATE OR REPLACE FUNCTION update_bulk_order_total()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE bulk_orders
  SET 
    total_amount = (SELECT SUM(subtotal) FROM bulk_order_items WHERE bulk_order_id = NEW.bulk_order_id),
    updated_at = NOW()
  WHERE id = NEW.bulk_order_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for bulk order total updates
CREATE TRIGGER trigger_update_bulk_order_total
  AFTER INSERT OR UPDATE OR DELETE ON bulk_order_items
  FOR EACH ROW
  EXECUTE FUNCTION update_bulk_order_total();

-- Function to get consolidated bulk order view
CREATE OR REPLACE FUNCTION get_bulk_order_details(p_bulk_order_id UUID)
RETURNS TABLE (
  bulk_order_id UUID,
  customer_name TEXT,
  sales_agent_name TEXT,
  total_amount DECIMAL(12,2),
  status TEXT,
  vendor_count INTEGER,
  order_count INTEGER,
  delivery_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE,
  vendor_details JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    bo.id AS bulk_order_id,
    c.name AS customer_name,
    u.full_name AS sales_agent_name,
    bo.total_amount,
    bo.status,
    COUNT(DISTINCT boi.vendor_id)::INTEGER AS vendor_count,
    COUNT(DISTINCT boi.order_id)::INTEGER AS order_count,
    bo.delivery_date,
    bo.created_at,
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'vendor_id', v.id,
          'vendor_name', v.name,
          'subtotal', boi.subtotal,
          'order_id', boi.order_id,
          'order_status', o.status
        )
      ) FILTER (WHERE v.id IS NOT NULL),
      '[]'::jsonb
    ) AS vendor_details
  FROM bulk_orders bo
  LEFT JOIN customers c ON bo.customer_id = c.id
  LEFT JOIN users u ON bo.sales_agent_id = u.id
  LEFT JOIN bulk_order_items boi ON bo.id = boi.bulk_order_id
  LEFT JOIN vendors v ON boi.vendor_id = v.id
  LEFT JOIN orders o ON boi.order_id = o.id
  WHERE bo.id = p_bulk_order_id
  GROUP BY bo.id, c.name, u.full_name;
END;
$$ LANGUAGE plpgsql STABLE;
````

**Integration Points:**
- Connect with sales agent dashboard bulk order UI
- Integrate with order creation flow
- Link to vendor order management

**Dependencies:**
- Order Management System should be implemented first

## Implementation Timeline Summary

### Phase 1: High Priority (4-6 weeks)
- Week 1-2: Order Management System
- Week 2-3: Payment Integration
- Week 3-4: Sales Agent Commission Tracking
- Week 4-5: Vendor Menu Management

### Phase 2: Medium Priority (3-5 weeks)
- Week 5-6: Customer Management (CRM Lite)
- Week 6-7: Push Notifications
- Week 7-9: Real-time Order Tracking
- Week 9-10: Advanced Search & Filtering

### Phase 3: Low Priority (3-4 weeks)
- Week 10-12: Advanced Analytics & Reporting
- Week 12-13: Inventory Management
- Week 13-14: Bulk Order Management

## Technical Dependencies and Integration Considerations

### Database Schema Dependencies
1. Order Management System is the foundation for most other features
2. Vendor Menu Management must be implemented before Inventory Management
3. Commission Tracking depends on Order Management System

### API Endpoint Dependencies
1. Order endpoints must be implemented before payment endpoints
2. User authentication and role management must be in place for all features
3. Real-time subscriptions depend on proper database configuration

### Frontend Integration Points
1. All backend features should expose REST API endpoints
2. Real-time features should use Supabase real-time channels
3. File uploads should use Supabase Storage with proper RLS policies

## Deployment Strategy

### Development Environment
1. Use Supabase local development with Docker
2. Implement and test migrations locally
3. Use GitHub Actions for CI/CD

### Staging Environment
1. Deploy to a separate Supabase project
2. Run automated tests against staging
3. Perform manual QA testing

### Production Environment
1. Apply migrations during scheduled maintenance windows
2. Use feature flags to gradually roll out new features
3. Monitor performance and errors closely after deployment

## Conclusion

This implementation plan provides a comprehensive roadmap for completing all identified missing backend features for the GigaEats platform. By following this structured approach, the development team can efficiently implement the required functionality while maintaining dependencies and integration points.

The plan prioritizes features based on their impact on core business functionality, with Order Management, Payment Integration, Commission Tracking, and Vendor Menu Management as the highest priorities. Medium and low priority features can be implemented in subsequent phases as the core functionality stabilizes.
