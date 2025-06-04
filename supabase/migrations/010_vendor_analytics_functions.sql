-- Vendor Analytics Functions
-- This migration adds comprehensive analytics functions for vendor dashboard

-- Function to get vendor sales breakdown by category
CREATE OR REPLACE FUNCTION get_vendor_sales_breakdown(
    p_vendor_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    category TEXT,
    total_sales DECIMAL(12,2),
    total_orders INTEGER,
    percentage DECIMAL(5,2)
) AS $$
DECLARE
    total_revenue DECIMAL(12,2);
BEGIN
    -- Set default date range if not provided
    IF p_start_date IS NULL THEN
        p_start_date := CURRENT_DATE - INTERVAL '30 days';
    END IF;
    IF p_end_date IS NULL THEN
        p_end_date := CURRENT_DATE;
    END IF;

    -- Get total revenue for percentage calculation
    SELECT COALESCE(SUM(oi.total_price), 0) INTO total_revenue
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    JOIN menu_items mi ON oi.menu_item_id = mi.id
    WHERE o.vendor_id = p_vendor_id
    AND o.status = 'delivered'
    AND DATE(o.created_at) BETWEEN p_start_date AND p_end_date;

    -- Return sales breakdown by category
    RETURN QUERY
    SELECT 
        mi.category,
        COALESCE(SUM(oi.total_price), 0.00) as total_sales,
        COUNT(DISTINCT o.id)::INTEGER as total_orders,
        CASE 
            WHEN total_revenue > 0 THEN 
                ROUND((COALESCE(SUM(oi.total_price), 0) / total_revenue * 100), 2)
            ELSE 0.00
        END as percentage
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    JOIN menu_items mi ON oi.menu_item_id = mi.id
    WHERE o.vendor_id = p_vendor_id
    AND o.status = 'delivered'
    AND DATE(o.created_at) BETWEEN p_start_date AND p_end_date
    GROUP BY mi.category
    ORDER BY total_sales DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get vendor top performing products
CREATE OR REPLACE FUNCTION get_vendor_top_products(
    p_vendor_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    product_id UUID,
    product_name TEXT,
    total_sales DECIMAL(12,2),
    total_orders INTEGER,
    total_quantity INTEGER,
    avg_rating DECIMAL(3,2)
) AS $$
BEGIN
    -- Set default date range if not provided
    IF p_start_date IS NULL THEN
        p_start_date := CURRENT_DATE - INTERVAL '30 days';
    END IF;
    IF p_end_date IS NULL THEN
        p_end_date := CURRENT_DATE;
    END IF;

    RETURN QUERY
    SELECT 
        mi.id as product_id,
        mi.name as product_name,
        COALESCE(SUM(oi.total_price), 0.00) as total_sales,
        COUNT(DISTINCT o.id)::INTEGER as total_orders,
        COALESCE(SUM(oi.quantity), 0)::INTEGER as total_quantity,
        COALESCE(mi.rating, 0.00) as avg_rating
    FROM menu_items mi
    LEFT JOIN order_items oi ON mi.id = oi.menu_item_id
    LEFT JOIN orders o ON oi.order_id = o.id AND o.status = 'delivered'
        AND DATE(o.created_at) BETWEEN p_start_date AND p_end_date
    WHERE mi.vendor_id = p_vendor_id
    AND mi.is_available = true
    GROUP BY mi.id, mi.name, mi.rating
    ORDER BY total_sales DESC, total_orders DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get vendor category performance
CREATE OR REPLACE FUNCTION get_vendor_category_performance(
    p_vendor_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    category TEXT,
    current_sales DECIMAL(12,2),
    previous_sales DECIMAL(12,2),
    growth_percentage DECIMAL(5,2),
    total_items INTEGER
) AS $$
DECLARE
    period_days INTEGER;
BEGIN
    -- Set default date range if not provided
    IF p_start_date IS NULL THEN
        p_start_date := CURRENT_DATE - INTERVAL '30 days';
    END IF;
    IF p_end_date IS NULL THEN
        p_end_date := CURRENT_DATE;
    END IF;

    -- Calculate period length for comparison
    period_days := p_end_date - p_start_date;

    RETURN QUERY
    WITH current_period AS (
        SELECT 
            mi.category,
            COALESCE(SUM(oi.total_price), 0.00) as sales,
            COUNT(DISTINCT mi.id) as items_count
        FROM menu_items mi
        LEFT JOIN order_items oi ON mi.id = oi.menu_item_id
        LEFT JOIN orders o ON oi.order_id = o.id AND o.status = 'delivered'
            AND DATE(o.created_at) BETWEEN p_start_date AND p_end_date
        WHERE mi.vendor_id = p_vendor_id
        GROUP BY mi.category
    ),
    previous_period AS (
        SELECT 
            mi.category,
            COALESCE(SUM(oi.total_price), 0.00) as sales
        FROM menu_items mi
        LEFT JOIN order_items oi ON mi.id = oi.menu_item_id
        LEFT JOIN orders o ON oi.order_id = o.id AND o.status = 'delivered'
            AND DATE(o.created_at) BETWEEN (p_start_date - period_days) AND p_start_date
        WHERE mi.vendor_id = p_vendor_id
        GROUP BY mi.category
    )
    SELECT 
        cp.category,
        cp.sales as current_sales,
        COALESCE(pp.sales, 0.00) as previous_sales,
        CASE 
            WHEN COALESCE(pp.sales, 0) > 0 THEN 
                ROUND(((cp.sales - COALESCE(pp.sales, 0)) / COALESCE(pp.sales, 0) * 100), 2)
            WHEN cp.sales > 0 THEN 100.00
            ELSE 0.00
        END as growth_percentage,
        cp.items_count::INTEGER as total_items
    FROM current_period cp
    LEFT JOIN previous_period pp ON cp.category = pp.category
    ORDER BY cp.sales DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get vendor revenue trends
CREATE OR REPLACE FUNCTION get_vendor_revenue_trends(
    p_vendor_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_period TEXT DEFAULT 'daily'
)
RETURNS TABLE (
    period_date DATE,
    revenue DECIMAL(12,2),
    orders_count INTEGER,
    avg_order_value DECIMAL(10,2)
) AS $$
BEGIN
    -- Set default date range if not provided
    IF p_start_date IS NULL THEN
        p_start_date := CURRENT_DATE - INTERVAL '30 days';
    END IF;
    IF p_end_date IS NULL THEN
        p_end_date := CURRENT_DATE;
    END IF;

    IF p_period = 'weekly' THEN
        RETURN QUERY
        SELECT 
            DATE_TRUNC('week', o.created_at)::DATE as period_date,
            COALESCE(SUM(o.total_amount), 0.00) as revenue,
            COUNT(*)::INTEGER as orders_count,
            CASE 
                WHEN COUNT(*) > 0 THEN ROUND(COALESCE(SUM(o.total_amount), 0) / COUNT(*), 2)
                ELSE 0.00
            END as avg_order_value
        FROM orders o
        WHERE o.vendor_id = p_vendor_id
        AND o.status = 'delivered'
        AND DATE(o.created_at) BETWEEN p_start_date AND p_end_date
        GROUP BY DATE_TRUNC('week', o.created_at)
        ORDER BY period_date;
    ELSIF p_period = 'monthly' THEN
        RETURN QUERY
        SELECT 
            DATE_TRUNC('month', o.created_at)::DATE as period_date,
            COALESCE(SUM(o.total_amount), 0.00) as revenue,
            COUNT(*)::INTEGER as orders_count,
            CASE 
                WHEN COUNT(*) > 0 THEN ROUND(COALESCE(SUM(o.total_amount), 0) / COUNT(*), 2)
                ELSE 0.00
            END as avg_order_value
        FROM orders o
        WHERE o.vendor_id = p_vendor_id
        AND o.status = 'delivered'
        AND DATE(o.created_at) BETWEEN p_start_date AND p_end_date
        GROUP BY DATE_TRUNC('month', o.created_at)
        ORDER BY period_date;
    ELSE -- daily
        RETURN QUERY
        SELECT 
            DATE(o.created_at) as period_date,
            COALESCE(SUM(o.total_amount), 0.00) as revenue,
            COUNT(*)::INTEGER as orders_count,
            CASE 
                WHEN COUNT(*) > 0 THEN ROUND(COALESCE(SUM(o.total_amount), 0) / COUNT(*), 2)
                ELSE 0.00
            END as avg_order_value
        FROM orders o
        WHERE o.vendor_id = p_vendor_id
        AND o.status = 'delivered'
        AND DATE(o.created_at) BETWEEN p_start_date AND p_end_date
        GROUP BY DATE(o.created_at)
        ORDER BY period_date;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_orders_vendor_status_date ON orders(vendor_id, status, created_at);
CREATE INDEX IF NOT EXISTS idx_order_items_menu_item ON order_items(menu_item_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_vendor_category ON menu_items(vendor_id, category);

-- Add RLS policies for the new functions
-- These functions use SECURITY DEFINER so they run with elevated privileges
-- but we still need to ensure vendors can only access their own data

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_vendor_sales_breakdown(UUID, DATE, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_vendor_top_products(UUID, DATE, DATE, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_vendor_category_performance(UUID, DATE, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_vendor_revenue_trends(UUID, DATE, DATE, TEXT) TO authenticated;

-- Add comments for documentation
COMMENT ON FUNCTION get_vendor_sales_breakdown(UUID, DATE, DATE) IS 'Returns sales breakdown by category for a vendor within date range';
COMMENT ON FUNCTION get_vendor_top_products(UUID, DATE, DATE, INTEGER) IS 'Returns top performing products for a vendor within date range';
COMMENT ON FUNCTION get_vendor_category_performance(UUID, DATE, DATE) IS 'Returns category performance with growth comparison for a vendor';
COMMENT ON FUNCTION get_vendor_revenue_trends(UUID, DATE, DATE, TEXT) IS 'Returns revenue trends by period (daily/weekly/monthly) for a vendor';
