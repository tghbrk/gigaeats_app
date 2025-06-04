-- Simplified Sample Data for Vendor Analytics Testing
-- This script creates test data that matches the actual database schema

-- Create a test vendor user in auth.users first
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    role
) VALUES (
    'ddbf77e4-b74d-47b8-b425-bc015a952596',
    'test@example.com',
    '$2a$10$rgl8.xQNvnl7glyE8.dqLOKrJVmjHfXYnpNgWLsJf4qrHf4p5nTjG', -- password: Testpass123!
    NOW(),
    NOW(),
    '{"provider": "email", "providers": ["email"]}',
    '{"role": "vendor"}',
    false,
    'authenticated'
) ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = NOW();

-- Create user profile
INSERT INTO users (
    id,
    supabase_user_id,
    email,
    full_name,
    role,
    created_at,
    updated_at
) VALUES (
    'ddbf77e4-b74d-47b8-b425-bc015a952596',
    'ddbf77e4-b74d-47b8-b425-bc015a952596',
    'test@example.com',
    'Test Vendor User',
    'vendor',
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = NOW();

-- Create vendor profile
INSERT INTO vendors (
    id,
    user_id,
    firebase_uid,
    business_name,
    business_registration_number,
    business_address,
    business_type,
    cuisine_types,
    description,
    rating,
    total_orders,
    created_at,
    updated_at
) VALUES (
    'vendor-test-001',
    'ddbf77e4-b74d-47b8-b425-bc015a952596',
    'test@example.com',
    'Test Restaurant',
    'REG123456789',
    '123 Test Street, Kuala Lumpur',
    'restaurant',
    ARRAY['Malaysian', 'Asian'],
    'A test restaurant for analytics testing',
    4.5,
    0,
    NOW() - INTERVAL '30 days',
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    business_name = EXCLUDED.business_name,
    updated_at = NOW();

-- Create menu items
INSERT INTO menu_items (
    id,
    vendor_id,
    name,
    description,
    category,
    base_price,
    is_available,
    is_featured,
    rating,
    created_at,
    updated_at
) VALUES 
    ('menu-001', 'vendor-test-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 'Main Dishes', 12.50, true, true, 4.8, NOW() - INTERVAL '25 days', NOW()),
    ('menu-002', 'vendor-test-001', 'Chicken Rice', 'Hainanese chicken rice', 'Main Dishes', 10.00, true, true, 4.6, NOW() - INTERVAL '25 days', NOW()),
    ('menu-003', 'vendor-test-001', 'Mee Goreng', 'Spicy fried noodles', 'Main Dishes', 8.50, true, false, 4.3, NOW() - INTERVAL '25 days', NOW()),
    ('menu-004', 'vendor-test-001', 'Teh Tarik', 'Traditional Malaysian pulled tea', 'Beverages', 3.50, true, false, 4.2, NOW() - INTERVAL '25 days', NOW()),
    ('menu-005', 'vendor-test-001', 'Kopi O', 'Black coffee Malaysian style', 'Beverages', 2.50, true, false, 4.0, NOW() - INTERVAL '25 days', NOW()),
    ('menu-006', 'vendor-test-001', 'Fresh Orange Juice', 'Freshly squeezed orange juice', 'Beverages', 5.00, true, false, 4.4, NOW() - INTERVAL '25 days', NOW()),
    ('menu-007', 'vendor-test-001', 'Cendol', 'Traditional Malaysian dessert', 'Desserts', 6.00, true, false, 4.5, NOW() - INTERVAL '25 days', NOW()),
    ('menu-008', 'vendor-test-001', 'Ice Kacang', 'Shaved ice dessert', 'Desserts', 7.50, true, false, 4.3, NOW() - INTERVAL '25 days', NOW())
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    updated_at = NOW();

-- Create test customers
INSERT INTO customers (
    id,
    organization_name,
    contact_person_name,
    email,
    phone_number,
    address,
    created_at,
    updated_at
) VALUES 
    ('customer-001', 'ABC Company', 'John Doe', 'john@abc.com', '+60123456001', '100 Business St, Kuala Lumpur', NOW() - INTERVAL '20 days', NOW()),
    ('customer-002', 'XYZ Corp', 'Jane Smith', 'jane@xyz.com', '+60123456002', '200 Corporate Ave, Kuala Lumpur', NOW() - INTERVAL '18 days', NOW()),
    ('customer-003', 'Tech Solutions', 'Bob Wilson', 'bob@tech.com', '+60123456003', '300 Tech Park, Kuala Lumpur', NOW() - INTERVAL '15 days', NOW()),
    ('customer-004', 'Food Lovers Inc', 'Alice Brown', 'alice@food.com', '+60123456004', '400 Food Street, Kuala Lumpur', NOW() - INTERVAL '12 days', NOW()),
    ('customer-005', 'Office Catering', 'Charlie Green', 'charlie@office.com', '+60123456005', '500 Office Tower, Kuala Lumpur', NOW() - INTERVAL '10 days', NOW())
ON CONFLICT (id) DO UPDATE SET
    organization_name = EXCLUDED.organization_name,
    updated_at = NOW();

-- Create orders with realistic distribution
INSERT INTO orders (
    id,
    order_number,
    vendor_id,
    customer_id,
    status,
    delivery_date,
    delivery_address,
    subtotal,
    delivery_fee,
    sst_amount,
    total_amount,
    commission_amount,
    payment_status,
    created_at,
    updated_at
) VALUES
    -- Week 1 (30-24 days ago) - Lower sales for growth comparison
    ('order-001', 'ORD-001', 'vendor-test-001', 'customer-001', 'delivered', CURRENT_DATE - 30, '{"address": "100 Business St", "city": "Kuala Lumpur"}', 25.00, 3.00, 2.50, 30.50, 3.75, 'paid', NOW() - INTERVAL '30 days', NOW() - INTERVAL '29 days'),
    ('order-002', 'ORD-002', 'vendor-test-001', 'customer-002', 'delivered', CURRENT_DATE - 29, '{"address": "200 Corporate Ave", "city": "Kuala Lumpur"}', 18.50, 3.00, 1.85, 23.35, 2.78, 'paid', NOW() - INTERVAL '29 days', NOW() - INTERVAL '28 days'),
    ('order-003', 'ORD-003', 'vendor-test-001', 'customer-003', 'delivered', CURRENT_DATE - 28, '{"address": "300 Tech Park", "city": "Kuala Lumpur"}', 32.00, 3.00, 3.20, 38.20, 4.80, 'paid', NOW() - INTERVAL '28 days', NOW() - INTERVAL '27 days'),
    ('order-004', 'ORD-004', 'vendor-test-001', 'customer-001', 'delivered', CURRENT_DATE - 27, '{"address": "100 Business St", "city": "Kuala Lumpur"}', 15.50, 3.00, 1.55, 20.05, 2.33, 'paid', NOW() - INTERVAL '27 days', NOW() - INTERVAL '26 days'),
    ('order-005', 'ORD-005', 'vendor-test-001', 'customer-004', 'delivered', CURRENT_DATE - 26, '{"address": "400 Food Street", "city": "Kuala Lumpur"}', 22.00, 3.00, 2.20, 27.20, 3.30, 'paid', NOW() - INTERVAL '26 days', NOW() - INTERVAL '25 days'),

    -- Week 2 (24-17 days ago) - Moderate sales
    ('order-006', 'ORD-006', 'vendor-test-001', 'customer-002', 'delivered', CURRENT_DATE - 24, '{"address": "200 Corporate Ave", "city": "Kuala Lumpur"}', 28.50, 3.00, 2.85, 34.35, 4.28, 'paid', NOW() - INTERVAL '24 days', NOW() - INTERVAL '23 days'),
    ('order-007', 'ORD-007', 'vendor-test-001', 'customer-005', 'delivered', CURRENT_DATE - 23, '{"address": "500 Office Tower", "city": "Kuala Lumpur"}', 45.00, 3.00, 4.50, 52.50, 6.75, 'paid', NOW() - INTERVAL '23 days', NOW() - INTERVAL '22 days'),
    ('order-008', 'ORD-008', 'vendor-test-001', 'customer-003', 'delivered', CURRENT_DATE - 22, '{"address": "300 Tech Park", "city": "Kuala Lumpur"}', 19.50, 3.00, 1.95, 24.45, 2.93, 'paid', NOW() - INTERVAL '22 days', NOW() - INTERVAL '21 days'),
    ('order-009', 'ORD-009', 'vendor-test-001', 'customer-001', 'delivered', CURRENT_DATE - 21, '{"address": "100 Business St", "city": "Kuala Lumpur"}', 35.00, 3.00, 3.50, 41.50, 5.25, 'paid', NOW() - INTERVAL '21 days', NOW() - INTERVAL '20 days'),
    ('order-010', 'ORD-010', 'vendor-test-001', 'customer-004', 'delivered', CURRENT_DATE - 20, '{"address": "400 Food Street", "city": "Kuala Lumpur"}', 26.50, 3.00, 2.65, 32.15, 3.98, 'paid', NOW() - INTERVAL '20 days', NOW() - INTERVAL '19 days'),

    -- Week 3 (17-10 days ago) - Higher sales showing growth
    ('order-011', 'ORD-011', 'vendor-test-001', 'customer-002', 'delivered', CURRENT_DATE - 16, '{"address": "200 Corporate Ave", "city": "Kuala Lumpur"}', 38.00, 3.00, 3.80, 44.80, 5.70, 'paid', NOW() - INTERVAL '16 days', NOW() - INTERVAL '15 days'),
    ('order-012', 'ORD-012', 'vendor-test-001', 'customer-001', 'delivered', CURRENT_DATE - 15, '{"address": "100 Business St", "city": "Kuala Lumpur"}', 29.50, 3.00, 2.95, 35.45, 4.43, 'paid', NOW() - INTERVAL '15 days', NOW() - INTERVAL '14 days'),
    ('order-013', 'ORD-013', 'vendor-test-001', 'customer-004', 'delivered', CURRENT_DATE - 14, '{"address": "400 Food Street", "city": "Kuala Lumpur"}', 52.00, 3.00, 5.20, 60.20, 7.80, 'paid', NOW() - INTERVAL '14 days', NOW() - INTERVAL '13 days'),
    ('order-014', 'ORD-014', 'vendor-test-001', 'customer-002', 'delivered', CURRENT_DATE - 13, '{"address": "200 Corporate Ave", "city": "Kuala Lumpur"}', 33.50, 3.00, 3.35, 39.85, 5.03, 'paid', NOW() - INTERVAL '13 days', NOW() - INTERVAL '12 days'),
    ('order-015', 'ORD-015', 'vendor-test-001', 'customer-005', 'delivered', CURRENT_DATE - 12, '{"address": "500 Office Tower", "city": "Kuala Lumpur"}', 47.50, 3.00, 4.75, 55.25, 7.13, 'paid', NOW() - INTERVAL '12 days', NOW() - INTERVAL '11 days'),

    -- Week 4 (10-3 days ago) - Peak sales
    ('order-016', 'ORD-016', 'vendor-test-001', 'customer-001', 'delivered', CURRENT_DATE - 9, '{"address": "100 Business St", "city": "Kuala Lumpur"}', 41.00, 3.00, 4.10, 48.10, 6.15, 'paid', NOW() - INTERVAL '9 days', NOW() - INTERVAL '8 days'),
    ('order-017', 'ORD-017', 'vendor-test-001', 'customer-004', 'delivered', CURRENT_DATE - 8, '{"address": "400 Food Street", "city": "Kuala Lumpur"}', 36.50, 3.00, 3.65, 43.15, 5.48, 'paid', NOW() - INTERVAL '8 days', NOW() - INTERVAL '7 days'),
    ('order-018', 'ORD-018', 'vendor-test-001', 'customer-002', 'delivered', CURRENT_DATE - 7, '{"address": "200 Corporate Ave", "city": "Kuala Lumpur"}', 55.00, 3.00, 5.50, 63.50, 8.25, 'paid', NOW() - INTERVAL '7 days', NOW() - INTERVAL '6 days'),
    ('order-019', 'ORD-019', 'vendor-test-001', 'customer-005', 'delivered', CURRENT_DATE - 6, '{"address": "500 Office Tower", "city": "Kuala Lumpur"}', 43.50, 3.00, 4.35, 50.85, 6.53, 'paid', NOW() - INTERVAL '6 days', NOW() - INTERVAL '5 days'),
    ('order-020', 'ORD-020', 'vendor-test-001', 'customer-003', 'delivered', CURRENT_DATE - 5, '{"address": "300 Tech Park", "city": "Kuala Lumpur"}', 39.00, 3.00, 3.90, 45.90, 5.85, 'paid', NOW() - INTERVAL '5 days', NOW() - INTERVAL '4 days'),

    -- Recent orders (last 3 days) - Current period
    ('order-021', 'ORD-021', 'vendor-test-001', 'customer-001', 'delivered', CURRENT_DATE - 2, '{"address": "100 Business St", "city": "Kuala Lumpur"}', 32.50, 3.00, 3.25, 38.75, 4.88, 'paid', NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day'),
    ('order-022', 'ORD-022', 'vendor-test-001', 'customer-002', 'delivered', CURRENT_DATE - 1, '{"address": "200 Corporate Ave", "city": "Kuala Lumpur"}', 27.00, 3.00, 2.70, 32.70, 4.05, 'paid', NOW() - INTERVAL '1 day', NOW()),
    ('order-023', 'ORD-023', 'vendor-test-001', 'customer-005', 'pending', CURRENT_DATE, '{"address": "500 Office Tower", "city": "Kuala Lumpur"}', 35.50, 3.00, 3.55, 42.05, 5.33, 'pending', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
    status = EXCLUDED.status,
    updated_at = NOW();

-- Create order items with realistic distribution across menu categories
INSERT INTO order_items (
    id,
    order_id,
    menu_item_id,
    name,
    description,
    unit_price,
    quantity,
    total_price,
    notes
) VALUES
    -- Order 1 items
    (uuid_generate_v4(), 'order-001', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 2, 25.00, ''),

    -- Order 2 items
    (uuid_generate_v4(), 'order-002', 'menu-002', 'Chicken Rice', 'Hainanese chicken rice', 10.00, 1, 10.00, ''),
    (uuid_generate_v4(), 'order-002', 'menu-004', 'Teh Tarik', 'Traditional Malaysian pulled tea', 3.50, 1, 3.50, ''),
    (uuid_generate_v4(), 'order-002', 'menu-007', 'Cendol', 'Traditional Malaysian dessert', 5.00, 1, 5.00, ''),

    -- Order 3 items
    (uuid_generate_v4(), 'order-003', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 2, 25.00, ''),
    (uuid_generate_v4(), 'order-003', 'menu-005', 'Kopi O', 'Black coffee Malaysian style', 2.50, 2, 5.00, ''),
    (uuid_generate_v4(), 'order-003', 'menu-008', 'Ice Kacang', 'Shaved ice dessert', 2.00, 1, 2.00, ''),

    -- Order 4 items
    (uuid_generate_v4(), 'order-004', 'menu-003', 'Mee Goreng', 'Spicy fried noodles', 8.50, 1, 8.50, ''),
    (uuid_generate_v4(), 'order-004', 'menu-006', 'Fresh Orange Juice', 'Freshly squeezed orange juice', 5.00, 1, 5.00, ''),
    (uuid_generate_v4(), 'order-004', 'menu-008', 'Ice Kacang', 'Shaved ice dessert', 2.00, 1, 2.00, ''),

    -- Order 5 items
    (uuid_generate_v4(), 'order-005', 'menu-002', 'Chicken Rice', 'Hainanese chicken rice', 10.00, 2, 20.00, ''),
    (uuid_generate_v4(), 'order-005', 'menu-004', 'Teh Tarik', 'Traditional Malaysian pulled tea', 2.00, 1, 2.00, ''),

    -- Order 6 items
    (uuid_generate_v4(), 'order-006', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 2, 25.00, ''),
    (uuid_generate_v4(), 'order-006', 'menu-005', 'Kopi O', 'Black coffee Malaysian style', 2.50, 1, 2.50, ''),
    (uuid_generate_v4(), 'order-006', 'menu-007', 'Cendol', 'Traditional Malaysian dessert', 1.00, 1, 1.00, ''),

    -- Order 7 items (Large order)
    (uuid_generate_v4(), 'order-007', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 3, 37.50, ''),
    (uuid_generate_v4(), 'order-007', 'menu-002', 'Chicken Rice', 'Hainanese chicken rice', 5.00, 1, 5.00, ''),
    (uuid_generate_v4(), 'order-007', 'menu-004', 'Teh Tarik', 'Traditional Malaysian pulled tea', 2.50, 1, 2.50, ''),

    -- Order 8 items
    (uuid_generate_v4(), 'order-008', 'menu-003', 'Mee Goreng', 'Spicy fried noodles', 8.50, 2, 17.00, ''),
    (uuid_generate_v4(), 'order-008', 'menu-005', 'Kopi O', 'Black coffee Malaysian style', 2.50, 1, 2.50, ''),

    -- Order 9 items
    (uuid_generate_v4(), 'order-009', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 2, 25.00, ''),
    (uuid_generate_v4(), 'order-009', 'menu-002', 'Chicken Rice', 'Hainanese chicken rice', 10.00, 1, 10.00, ''),

    -- Order 10 items
    (uuid_generate_v4(), 'order-010', 'menu-002', 'Chicken Rice', 'Hainanese chicken rice', 10.00, 2, 20.00, ''),
    (uuid_generate_v4(), 'order-010', 'menu-006', 'Fresh Orange Juice', 'Freshly squeezed orange juice', 5.00, 1, 5.00, ''),
    (uuid_generate_v4(), 'order-010', 'menu-007', 'Cendol', 'Traditional Malaysian dessert', 1.50, 1, 1.50, ''),

    -- More recent orders with higher sales
    (uuid_generate_v4(), 'order-011', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 3, 37.50, ''),
    (uuid_generate_v4(), 'order-011', 'menu-005', 'Kopi O', 'Black coffee Malaysian style', 0.50, 1, 0.50, ''),

    (uuid_generate_v4(), 'order-012', 'menu-002', 'Chicken Rice', 'Hainanese chicken rice', 10.00, 2, 20.00, ''),
    (uuid_generate_v4(), 'order-012', 'menu-003', 'Mee Goreng', 'Spicy fried noodles', 8.50, 1, 8.50, ''),
    (uuid_generate_v4(), 'order-012', 'menu-004', 'Teh Tarik', 'Traditional Malaysian pulled tea', 1.00, 1, 1.00, ''),

    (uuid_generate_v4(), 'order-013', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 4, 50.00, ''),
    (uuid_generate_v4(), 'order-013', 'menu-008', 'Ice Kacang', 'Shaved ice dessert', 2.00, 1, 2.00, ''),

    (uuid_generate_v4(), 'order-014', 'menu-002', 'Chicken Rice', 'Hainanese chicken rice', 10.00, 3, 30.00, ''),
    (uuid_generate_v4(), 'order-014', 'menu-006', 'Fresh Orange Juice', 'Freshly squeezed orange juice', 3.50, 1, 3.50, ''),

    (uuid_generate_v4(), 'order-015', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 3, 37.50, ''),
    (uuid_generate_v4(), 'order-015', 'menu-003', 'Mee Goreng', 'Spicy fried noodles', 8.50, 1, 8.50, ''),
    (uuid_generate_v4(), 'order-015', 'menu-007', 'Cendol', 'Traditional Malaysian dessert', 1.50, 1, 1.50, ''),

    -- Peak sales period
    (uuid_generate_v4(), 'order-016', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 3, 37.50, ''),
    (uuid_generate_v4(), 'order-016', 'menu-004', 'Teh Tarik', 'Traditional Malaysian pulled tea', 3.50, 1, 3.50, ''),

    (uuid_generate_v4(), 'order-017', 'menu-002', 'Chicken Rice', 'Hainanese chicken rice', 10.00, 3, 30.00, ''),
    (uuid_generate_v4(), 'order-017', 'menu-006', 'Fresh Orange Juice', 'Freshly squeezed orange juice', 5.00, 1, 5.00, ''),
    (uuid_generate_v4(), 'order-017', 'menu-007', 'Cendol', 'Traditional Malaysian dessert', 1.50, 1, 1.50, ''),

    (uuid_generate_v4(), 'order-018', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 4, 50.00, ''),
    (uuid_generate_v4(), 'order-018', 'menu-005', 'Kopi O', 'Black coffee Malaysian style', 2.50, 2, 5.00, ''),

    (uuid_generate_v4(), 'order-019', 'menu-002', 'Chicken Rice', 'Hainanese chicken rice', 10.00, 4, 40.00, ''),
    (uuid_generate_v4(), 'order-019', 'menu-008', 'Ice Kacang', 'Shaved ice dessert', 3.50, 1, 3.50, ''),

    (uuid_generate_v4(), 'order-020', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 3, 37.50, ''),
    (uuid_generate_v4(), 'order-020', 'menu-007', 'Cendol', 'Traditional Malaysian dessert', 1.50, 1, 1.50, ''),

    -- Recent orders
    (uuid_generate_v4(), 'order-021', 'menu-002', 'Chicken Rice', 'Hainanese chicken rice', 10.00, 3, 30.00, ''),
    (uuid_generate_v4(), 'order-021', 'menu-004', 'Teh Tarik', 'Traditional Malaysian pulled tea', 2.50, 1, 2.50, ''),

    (uuid_generate_v4(), 'order-022', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 2, 25.00, ''),
    (uuid_generate_v4(), 'order-022', 'menu-006', 'Fresh Orange Juice', 'Freshly squeezed orange juice', 2.00, 1, 2.00, ''),

    (uuid_generate_v4(), 'order-023', 'menu-003', 'Mee Goreng', 'Spicy fried noodles', 8.50, 4, 34.00, ''),
    (uuid_generate_v4(), 'order-023', 'menu-005', 'Kopi O', 'Black coffee Malaysian style', 1.50, 1, 1.50, '');
