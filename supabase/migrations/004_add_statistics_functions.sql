-- Add database functions for statistics and analytics
-- These functions support the dashboard and reporting features

-- Function to get customer statistics for sales agents
CREATE OR REPLACE FUNCTION get_customer_statistics(sales_agent_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_customers', COUNT(*),
        'active_customers', COUNT(*) FILTER (WHERE is_active = true),
        'inactive_customers', COUNT(*) FILTER (WHERE is_active = false),
        'restaurant_customers', COUNT(*) FILTER (WHERE customer_type = 'restaurant'),
        'catering_customers', COUNT(*) FILTER (WHERE customer_type = 'catering'),
        'total_spending', COALESCE(SUM(total_spent), 0),
        'total_orders', COALESCE(SUM(total_orders), 0),
        'average_order_value', CASE
            WHEN SUM(total_orders) > 0 THEN COALESCE(SUM(total_spent) / SUM(total_orders), 0)
            ELSE 0
        END,
        'customers_with_recent_orders', COUNT(*) FILTER (WHERE last_order_date >= NOW() - INTERVAL '30 days'),
        'new_customers_this_month', COUNT(*) FILTER (WHERE created_at >= DATE_TRUNC('month', NOW()))
    ) INTO result
    FROM customers 
    WHERE customers.sales_agent_id = get_customer_statistics.sales_agent_id;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update customer order statistics
CREATE OR REPLACE FUNCTION update_customer_order_stats(customer_id UUID, order_amount DECIMAL)
RETURNS VOID AS $$
BEGIN
    UPDATE customers
    SET
        total_spent = total_spent + order_amount,
        total_orders = total_orders + 1,
        last_order_date = NOW(),
        updated_at = NOW()
    WHERE id = customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get order statistics
CREATE OR REPLACE FUNCTION get_order_statistics(
    user_role TEXT,
    user_id UUID,
    start_date TIMESTAMP DEFAULT NULL,
    end_date TIMESTAMP DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    result JSON;
    date_filter TEXT := '';
BEGIN
    -- Build date filter if provided
    IF start_date IS NOT NULL AND end_date IS NOT NULL THEN
        date_filter := ' AND created_at BETWEEN ''' || start_date || ''' AND ''' || end_date || '''';
    ELSIF start_date IS NOT NULL THEN
        date_filter := ' AND created_at >= ''' || start_date || '''';
    ELSIF end_date IS NOT NULL THEN
        date_filter := ' AND created_at <= ''' || end_date || '''';
    END IF;

    -- Build query based on user role
    IF user_role = 'admin' THEN
        EXECUTE 'SELECT json_build_object(
            ''total_orders'', COUNT(*),
            ''pending_orders'', COUNT(*) FILTER (WHERE status = ''pending''),
            ''confirmed_orders'', COUNT(*) FILTER (WHERE status = ''confirmed''),
            ''preparing_orders'', COUNT(*) FILTER (WHERE status = ''preparing''),
            ''ready_orders'', COUNT(*) FILTER (WHERE status = ''ready''),
            ''delivered_orders'', COUNT(*) FILTER (WHERE status = ''delivered''),
            ''cancelled_orders'', COUNT(*) FILTER (WHERE status = ''cancelled''),
            ''total_revenue'', COALESCE(SUM(total_amount) FILTER (WHERE status = ''delivered''), 0),
            ''average_order_value'', COALESCE(AVG(total_amount), 0),
            ''orders_today'', COUNT(*) FILTER (WHERE DATE(created_at) = CURRENT_DATE),
            ''orders_this_week'', COUNT(*) FILTER (WHERE created_at >= DATE_TRUNC(''week'', NOW())),
            ''orders_this_month'', COUNT(*) FILTER (WHERE created_at >= DATE_TRUNC(''month'', NOW()))
        ) FROM orders WHERE 1=1' || date_filter INTO result;
    
    ELSIF user_role = 'sales_agent' THEN
        EXECUTE 'SELECT json_build_object(
            ''total_orders'', COUNT(*),
            ''pending_orders'', COUNT(*) FILTER (WHERE status = ''pending''),
            ''confirmed_orders'', COUNT(*) FILTER (WHERE status = ''confirmed''),
            ''preparing_orders'', COUNT(*) FILTER (WHERE status = ''preparing''),
            ''ready_orders'', COUNT(*) FILTER (WHERE status = ''ready''),
            ''delivered_orders'', COUNT(*) FILTER (WHERE status = ''delivered''),
            ''cancelled_orders'', COUNT(*) FILTER (WHERE status = ''cancelled''),
            ''total_revenue'', COALESCE(SUM(total_amount) FILTER (WHERE status = ''delivered''), 0),
            ''average_order_value'', COALESCE(AVG(total_amount), 0),
            ''commission_earned'', COALESCE(SUM(commission_amount) FILTER (WHERE status = ''delivered''), 0),
            ''orders_today'', COUNT(*) FILTER (WHERE DATE(created_at) = CURRENT_DATE),
            ''orders_this_week'', COUNT(*) FILTER (WHERE created_at >= DATE_TRUNC(''week'', NOW())),
            ''orders_this_month'', COUNT(*) FILTER (WHERE created_at >= DATE_TRUNC(''month'', NOW()))
        ) FROM orders WHERE sales_agent_id = ''' || user_id || '''' || date_filter INTO result;
    
    ELSIF user_role = 'vendor' THEN
        EXECUTE 'SELECT json_build_object(
            ''total_orders'', COUNT(*),
            ''pending_orders'', COUNT(*) FILTER (WHERE status = ''pending''),
            ''confirmed_orders'', COUNT(*) FILTER (WHERE status = ''confirmed''),
            ''preparing_orders'', COUNT(*) FILTER (WHERE status = ''preparing''),
            ''ready_orders'', COUNT(*) FILTER (WHERE status = ''ready''),
            ''delivered_orders'', COUNT(*) FILTER (WHERE status = ''delivered''),
            ''cancelled_orders'', COUNT(*) FILTER (WHERE status = ''cancelled''),
            ''total_revenue'', COALESCE(SUM(total_amount) FILTER (WHERE status = ''delivered''), 0),
            ''average_order_value'', COALESCE(AVG(total_amount), 0),
            ''orders_today'', COUNT(*) FILTER (WHERE DATE(created_at) = CURRENT_DATE),
            ''orders_this_week'', COUNT(*) FILTER (WHERE created_at >= DATE_TRUNC(''week'', NOW())),
            ''orders_this_month'', COUNT(*) FILTER (WHERE created_at >= DATE_TRUNC(''month'', NOW()))
        ) FROM orders WHERE vendor_id = ''' || user_id || '''' || date_filter INTO result;
    
    ELSE
        -- Default empty result for unknown roles
        result := '{}';
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get menu item statistics for vendors
CREATE OR REPLACE FUNCTION get_menu_item_statistics(vendor_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_menu_items', COUNT(*),
        'available_items', COUNT(*) FILTER (WHERE is_available = true),
        'unavailable_items', COUNT(*) FILTER (WHERE is_available = false),
        'featured_items', COUNT(*) FILTER (WHERE is_featured = true),
        'halal_items', COUNT(*) FILTER (WHERE is_halal = true),
        'vegetarian_items', COUNT(*) FILTER (WHERE is_vegetarian = true),
        'vegan_items', COUNT(*) FILTER (WHERE is_vegan = true),
        'spicy_items', COUNT(*) FILTER (WHERE is_spicy = true),
        'average_rating', COALESCE(AVG(rating), 0),
        'total_reviews', COALESCE(SUM(total_reviews), 0),
        'average_price', COALESCE(AVG(base_price), 0),
        'highest_rated_item', (
            SELECT json_build_object('name', name, 'rating', rating)
            FROM menu_items mi2 
            WHERE mi2.vendor_id = get_menu_item_statistics.vendor_id 
            ORDER BY rating DESC, total_reviews DESC 
            LIMIT 1
        ),
        'most_popular_item', (
            SELECT json_build_object('name', name, 'reviews', total_reviews)
            FROM menu_items mi3 
            WHERE mi3.vendor_id = get_menu_item_statistics.vendor_id 
            ORDER BY total_reviews DESC, rating DESC 
            LIMIT 1
        )
    ) INTO result
    FROM menu_items 
    WHERE menu_items.vendor_id = get_menu_item_statistics.vendor_id;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comments for documentation
COMMENT ON FUNCTION get_customer_statistics(UUID) IS 'Returns customer statistics for a sales agent';
COMMENT ON FUNCTION update_customer_order_stats(UUID, DECIMAL) IS 'Updates customer spending and order count after order completion';
COMMENT ON FUNCTION get_order_statistics(TEXT, UUID, TIMESTAMP, TIMESTAMP) IS 'Returns order statistics based on user role and date range';
COMMENT ON FUNCTION get_menu_item_statistics(UUID) IS 'Returns menu item statistics for a vendor';
