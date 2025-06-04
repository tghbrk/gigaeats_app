-- Sample Data for Vendor Analytics Testing
-- This script creates comprehensive test data for vendor analytics functionality

-- First, let's create a test vendor user in auth.users
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
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
    role,
    created_at,
    updated_at
) VALUES (
    'ddbf77e4-b74d-47b8-b425-bc015a952596',
    'ddbf77e4-b74d-47b8-b425-bc015a952596',
    'test@example.com',
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
    business_name,
    business_type,
    description,
    phone_number,
    address,
    city,
    state,
    postal_code,
    country,
    business_registration_number,
    tax_identification_number,
    bank_account_number,
    bank_name,
    account_holder_name,
    is_active,
    is_verified,
    commission_rate,
    rating,
    total_orders,
    created_at,
    updated_at
) VALUES (
    'vendor-test-001',
    'ddbf77e4-b74d-47b8-b425-bc015a952596',
    'Test Restaurant',
    'restaurant',
    'A test restaurant for analytics testing',
    '+60123456789',
    '123 Test Street',
    'Kuala Lumpur',
    'Selangor',
    '50000',
    'Malaysia',
    'REG123456789',
    'TAX987654321',
    '1234567890',
    'Test Bank',
    'Test Restaurant Sdn Bhd',
    true,
    true,
    0.15,
    4.5,
    0,
    NOW() - INTERVAL '30 days',
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    business_name = EXCLUDED.business_name,
    updated_at = NOW();

-- Create menu items with different categories
INSERT INTO menu_items (
    id,
    vendor_id,
    name,
    description,
    category,
    base_price,
    is_available,
    is_featured,
    preparation_time,
    rating,
    created_at,
    updated_at
) VALUES 
    ('menu-001', 'vendor-test-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice with sambal, anchovies, peanuts, and egg', 'Main Dishes', 12.50, true, true, 15, 4.8, NOW() - INTERVAL '25 days', NOW()),
    ('menu-002', 'vendor-test-001', 'Chicken Rice', 'Hainanese chicken rice with tender poached chicken', 'Main Dishes', 10.00, true, true, 20, 4.6, NOW() - INTERVAL '25 days', NOW()),
    ('menu-003', 'vendor-test-001', 'Mee Goreng', 'Spicy fried noodles with vegetables and egg', 'Main Dishes', 8.50, true, false, 12, 4.3, NOW() - INTERVAL '25 days', NOW()),
    ('menu-004', 'vendor-test-001', 'Teh Tarik', 'Traditional Malaysian pulled tea', 'Beverages', 3.50, true, false, 5, 4.2, NOW() - INTERVAL '25 days', NOW()),
    ('menu-005', 'vendor-test-001', 'Kopi O', 'Black coffee Malaysian style', 'Beverages', 2.50, true, false, 3, 4.0, NOW() - INTERVAL '25 days', NOW()),
    ('menu-006', 'vendor-test-001', 'Fresh Orange Juice', 'Freshly squeezed orange juice', 'Beverages', 5.00, true, false, 5, 4.4, NOW() - INTERVAL '25 days', NOW()),
    ('menu-007', 'vendor-test-001', 'Cendol', 'Traditional Malaysian dessert with coconut milk and palm sugar', 'Desserts', 6.00, true, false, 8, 4.5, NOW() - INTERVAL '25 days', NOW()),
    ('menu-008', 'vendor-test-001', 'Ice Kacang', 'Shaved ice dessert with various toppings', 'Desserts', 7.50, true, false, 10, 4.3, NOW() - INTERVAL '25 days', NOW())
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
    city,
    state,
    postal_code,
    country,
    created_at,
    updated_at
) VALUES 
    ('customer-001', 'ABC Company', 'John Doe', 'john@abc.com', '+60123456001', '100 Business St', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', NOW() - INTERVAL '20 days', NOW()),
    ('customer-002', 'XYZ Corp', 'Jane Smith', 'jane@xyz.com', '+60123456002', '200 Corporate Ave', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', NOW() - INTERVAL '18 days', NOW()),
    ('customer-003', 'Tech Solutions', 'Bob Wilson', 'bob@tech.com', '+60123456003', '300 Tech Park', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', NOW() - INTERVAL '15 days', NOW()),
    ('customer-004', 'Food Lovers Inc', 'Alice Brown', 'alice@food.com', '+60123456004', '400 Food Street', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', NOW() - INTERVAL '12 days', NOW()),
    ('customer-005', 'Office Catering', 'Charlie Green', 'charlie@office.com', '+60123456005', '500 Office Tower', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', NOW() - INTERVAL '10 days', NOW())
ON CONFLICT (id) DO UPDATE SET
    organization_name = EXCLUDED.organization_name,
    updated_at = NOW();

-- Create orders with realistic distribution over the past 30 days
-- This will create orders for different time periods to test analytics

-- Orders from 30 days ago (older period for growth comparison)
INSERT INTO orders (
    id,
    vendor_id,
    customer_id,
    status,
    total_amount,
    delivery_fee,
    service_fee,
    tax_amount,
    commission_amount,
    net_amount,
    delivery_address,
    delivery_city,
    delivery_state,
    delivery_postal_code,
    delivery_country,
    special_instructions,
    created_at,
    updated_at
) VALUES
    -- Week 1 (30-24 days ago) - Lower sales for growth comparison
    ('order-001', 'vendor-test-001', 'customer-001', 'delivered', 25.00, 3.00, 1.50, 2.50, 3.75, 21.25, '100 Business St', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Office lunch', NOW() - INTERVAL '30 days', NOW() - INTERVAL '29 days'),
    ('order-002', 'vendor-test-001', 'customer-002', 'delivered', 18.50, 3.00, 1.50, 1.85, 2.78, 15.72, '200 Corporate Ave', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', '', NOW() - INTERVAL '29 days', NOW() - INTERVAL '28 days'),
    ('order-003', 'vendor-test-001', 'customer-003', 'delivered', 32.00, 3.00, 1.50, 3.20, 4.80, 27.20, '300 Tech Park', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Team lunch', NOW() - INTERVAL '28 days', NOW() - INTERVAL '27 days'),
    ('order-004', 'vendor-test-001', 'customer-001', 'delivered', 15.50, 3.00, 1.50, 1.55, 2.33, 13.17, '100 Business St', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', '', NOW() - INTERVAL '27 days', NOW() - INTERVAL '26 days'),
    ('order-005', 'vendor-test-001', 'customer-004', 'delivered', 22.00, 3.00, 1.50, 2.20, 3.30, 18.70, '400 Food Street', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Quick delivery', NOW() - INTERVAL '26 days', NOW() - INTERVAL '25 days'),

    -- Week 2 (24-17 days ago) - Moderate sales
    ('order-006', 'vendor-test-001', 'customer-002', 'delivered', 28.50, 3.00, 1.50, 2.85, 4.28, 24.22, '200 Corporate Ave', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Meeting lunch', NOW() - INTERVAL '24 days', NOW() - INTERVAL '23 days'),
    ('order-007', 'vendor-test-001', 'customer-005', 'delivered', 45.00, 3.00, 1.50, 4.50, 6.75, 38.25, '500 Office Tower', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Large order', NOW() - INTERVAL '23 days', NOW() - INTERVAL '22 days'),
    ('order-008', 'vendor-test-001', 'customer-003', 'delivered', 19.50, 3.00, 1.50, 1.95, 2.93, 16.57, '300 Tech Park', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', '', NOW() - INTERVAL '22 days', NOW() - INTERVAL '21 days'),
    ('order-009', 'vendor-test-001', 'customer-001', 'delivered', 35.00, 3.00, 1.50, 3.50, 5.25, 29.75, '100 Business St', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Department lunch', NOW() - INTERVAL '21 days', NOW() - INTERVAL '20 days'),
    ('order-010', 'vendor-test-001', 'customer-004', 'delivered', 26.50, 3.00, 1.50, 2.65, 3.98, 22.52, '400 Food Street', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', '', NOW() - INTERVAL '20 days', NOW() - INTERVAL '19 days'),
    ('order-011', 'vendor-test-001', 'customer-002', 'delivered', 31.00, 3.00, 1.50, 3.10, 4.65, 26.35, '200 Corporate Ave', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Client meeting', NOW() - INTERVAL '19 days', NOW() - INTERVAL '18 days'),
    ('order-012', 'vendor-test-001', 'customer-005', 'delivered', 42.50, 3.00, 1.50, 4.25, 6.38, 36.12, '500 Office Tower', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Office party', NOW() - INTERVAL '18 days', NOW() - INTERVAL '17 days'),

    -- Week 3 (17-10 days ago) - Higher sales showing growth
    ('order-013', 'vendor-test-001', 'customer-003', 'delivered', 38.00, 3.00, 1.50, 3.80, 5.70, 32.30, '300 Tech Park', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Team building', NOW() - INTERVAL '16 days', NOW() - INTERVAL '15 days'),
    ('order-014', 'vendor-test-001', 'customer-001', 'delivered', 29.50, 3.00, 1.50, 2.95, 4.43, 25.07, '100 Business St', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', '', NOW() - INTERVAL '15 days', NOW() - INTERVAL '14 days'),
    ('order-015', 'vendor-test-001', 'customer-004', 'delivered', 52.00, 3.00, 1.50, 5.20, 7.80, 44.20, '400 Food Street', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Big order', NOW() - INTERVAL '14 days', NOW() - INTERVAL '13 days'),
    ('order-016', 'vendor-test-001', 'customer-002', 'delivered', 33.50, 3.00, 1.50, 3.35, 5.03, 28.47, '200 Corporate Ave', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Board meeting', NOW() - INTERVAL '13 days', NOW() - INTERVAL '12 days'),
    ('order-017', 'vendor-test-001', 'customer-005', 'delivered', 47.50, 3.00, 1.50, 4.75, 7.13, 40.37, '500 Office Tower', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Conference lunch', NOW() - INTERVAL '12 days', NOW() - INTERVAL '11 days'),
    ('order-018', 'vendor-test-001', 'customer-003', 'delivered', 24.00, 3.00, 1.50, 2.40, 3.60, 20.40, '300 Tech Park', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', '', NOW() - INTERVAL '11 days', NOW() - INTERVAL '10 days'),

    -- Week 4 (10-3 days ago) - Peak sales
    ('order-019', 'vendor-test-001', 'customer-001', 'delivered', 41.00, 3.00, 1.50, 4.10, 6.15, 34.85, '100 Business St', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Monthly meeting', NOW() - INTERVAL '9 days', NOW() - INTERVAL '8 days'),
    ('order-020', 'vendor-test-001', 'customer-004', 'delivered', 36.50, 3.00, 1.50, 3.65, 5.48, 31.02, '400 Food Street', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', '', NOW() - INTERVAL '8 days', NOW() - INTERVAL '7 days'),
    ('order-021', 'vendor-test-001', 'customer-002', 'delivered', 55.00, 3.00, 1.50, 5.50, 8.25, 46.75, '200 Corporate Ave', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Company event', NOW() - INTERVAL '7 days', NOW() - INTERVAL '6 days'),
    ('order-022', 'vendor-test-001', 'customer-005', 'delivered', 43.50, 3.00, 1.50, 4.35, 6.53, 37.02, '500 Office Tower', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Training lunch', NOW() - INTERVAL '6 days', NOW() - INTERVAL '5 days'),
    ('order-023', 'vendor-test-001', 'customer-003', 'delivered', 39.00, 3.00, 1.50, 3.90, 5.85, 33.15, '300 Tech Park', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Project celebration', NOW() - INTERVAL '5 days', NOW() - INTERVAL '4 days'),
    ('order-024', 'vendor-test-001', 'customer-001', 'delivered', 48.00, 3.00, 1.50, 4.80, 7.20, 40.80, '100 Business St', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Quarter end', NOW() - INTERVAL '4 days', NOW() - INTERVAL '3 days'),

    -- Recent orders (last 3 days) - Current period
    ('order-025', 'vendor-test-001', 'customer-004', 'delivered', 32.50, 3.00, 1.50, 3.25, 4.88, 27.62, '400 Food Street', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', '', NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day'),
    ('order-026', 'vendor-test-001', 'customer-002', 'delivered', 27.00, 3.00, 1.50, 2.70, 4.05, 22.95, '200 Corporate Ave', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Quick lunch', NOW() - INTERVAL '1 day', NOW()),
    ('order-027', 'vendor-test-001', 'customer-005', 'pending', 35.50, 3.00, 1.50, 3.55, 5.33, 30.17, '500 Office Tower', 'Kuala Lumpur', 'Selangor', '50000', 'Malaysia', 'Today order', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
    status = EXCLUDED.status,
    updated_at = NOW();

-- Create order items with realistic distribution across menu categories
-- This will help test category-based analytics

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
    ('item-001', 'order-001', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 2, 25.00, ''),

    -- Order 2 items
    ('item-002', 'order-002', 'menu-002', 'Chicken Rice', 'Hainanese chicken rice', 10.00, 1, 10.00, ''),
    ('item-003', 'order-002', 'menu-004', 'Teh Tarik', 'Traditional Malaysian pulled tea', 3.50, 1, 3.50, ''),
    ('item-004', 'order-002', 'menu-007', 'Cendol', 'Traditional Malaysian dessert', 6.00, 1, 6.00, ''),

    -- Order 3 items
    ('item-005', 'order-003', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 2, 25.00, ''),
    ('item-006', 'order-003', 'menu-005', 'Kopi O', 'Black coffee Malaysian style', 2.50, 2, 5.00, ''),
    ('item-007', 'order-003', 'menu-008', 'Ice Kacang', 'Shaved ice dessert', 7.50, 1, 7.50, ''),

    -- Order 4 items
    ('item-008', 'order-004', 'menu-003', 'Mee Goreng', 'Spicy fried noodles', 8.50, 1, 8.50, ''),
    ('item-009', 'order-004', 'menu-006', 'Fresh Orange Juice', 'Freshly squeezed orange juice', 5.00, 1, 5.00, ''),
    ('item-010', 'order-004', 'menu-008', 'Ice Kacang', 'Shaved ice dessert', 7.50, 1, 7.50, ''),

    -- Order 5 items
    ('item-011', 'order-005', 'menu-002', 'Chicken Rice', 'Hainanese chicken rice', 10.00, 2, 20.00, ''),
    ('item-012', 'order-005', 'menu-004', 'Teh Tarik', 'Traditional Malaysian pulled tea', 3.50, 1, 3.50, ''),

    -- Order 6 items
    ('item-013', 'order-006', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 2, 25.00, ''),
    ('item-014', 'order-006', 'menu-005', 'Kopi O', 'Black coffee Malaysian style', 2.50, 1, 2.50, ''),
    ('item-015', 'order-006', 'menu-007', 'Cendol', 'Traditional Malaysian dessert', 6.00, 1, 6.00, ''),

    -- Order 7 items (Large order)
    ('item-016', 'order-007', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 3, 37.50, ''),
    ('item-017', 'order-007', 'menu-002', 'Chicken Rice', 'Hainanese chicken rice', 10.00, 1, 10.00, ''),
    ('item-018', 'order-007', 'menu-004', 'Teh Tarik', 'Traditional Malaysian pulled tea', 3.50, 2, 7.00, ''),

    -- Order 8 items
    ('item-019', 'order-008', 'menu-003', 'Mee Goreng', 'Spicy fried noodles', 8.50, 2, 17.00, ''),
    ('item-020', 'order-008', 'menu-005', 'Kopi O', 'Black coffee Malaysian style', 2.50, 1, 2.50, ''),

    -- Order 9 items
    ('item-021', 'order-009', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 2, 25.00, ''),
    ('item-022', 'order-009', 'menu-002', 'Chicken Rice', 'Hainanese chicken rice', 10.00, 1, 10.00, ''),

    -- Order 10 items
    ('item-023', 'order-010', 'menu-002', 'Chicken Rice', 'Hainanese chicken rice', 10.00, 2, 20.00, ''),
    ('item-024', 'order-010', 'menu-006', 'Fresh Orange Juice', 'Freshly squeezed orange juice', 5.00, 1, 5.00, ''),
    ('item-025', 'order-010', 'menu-007', 'Cendol', 'Traditional Malaysian dessert', 6.00, 1, 6.00, ''),

    -- Order 11 items
    ('item-026', 'order-011', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 2, 25.00, ''),
    ('item-027', 'order-011', 'menu-004', 'Teh Tarik', 'Traditional Malaysian pulled tea', 3.50, 1, 3.50, ''),
    ('item-028', 'order-011', 'menu-008', 'Ice Kacang', 'Shaved ice dessert', 7.50, 1, 7.50, ''),

    -- Order 12 items (Office party)
    ('item-029', 'order-012', 'menu-001', 'Nasi Lemak Special', 'Traditional Malaysian coconut rice', 12.50, 3, 37.50, ''),
    ('item-030', 'order-012', 'menu-003', 'Mee Goreng', 'Spicy fried noodles', 8.50, 1, 8.50, ''),
    ('item-031', 'order-012', 'menu-005', 'Kopi O', 'Black coffee Malaysian style', 2.50, 2, 5.00, '')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    updated_at = NOW();
