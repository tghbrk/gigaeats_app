-- Comprehensive seed data for GigaEats application
-- This file provides test data for all user roles and scenarios
-- Run with `supabase db reset` to reset database and apply all migrations and seed data

-- Disable RLS temporarily for seeding
SET session_replication_role = replica;

-- Clear existing data (in reverse dependency order)
TRUNCATE TABLE order_items CASCADE;
TRUNCATE TABLE orders CASCADE;
TRUNCATE TABLE customers CASCADE;
TRUNCATE TABLE menu_items CASCADE;
TRUNCATE TABLE vendors CASCADE;
TRUNCATE TABLE user_profiles CASCADE;
TRUNCATE TABLE user_fcm_tokens CASCADE;
TRUNCATE TABLE users CASCADE;

-- Insert test users with Firebase UIDs
INSERT INTO users (id, firebase_uid, email, full_name, phone_number, role, is_verified, is_active, profile_image_url, created_at, updated_at) VALUES
-- Admin user
('550e8400-e29b-41d4-a716-446655440001', 'firebase_admin_001', 'admin@gigaeats.com', 'Admin User', '+60123456789', 'admin', true, true, null, NOW(), NOW()),

-- Sales agents
('550e8400-e29b-41d4-a716-446655440002', 'firebase_sales_001', 'agent1@gigaeats.com', 'Ahmad Rahman', '+60123456790', 'sales_agent', true, true, null, NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440003', 'firebase_sales_002', 'agent2@gigaeats.com', 'Siti Nurhaliza', '+60123456791', 'sales_agent', true, true, null, NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440004', 'firebase_sales_003', 'agent3@gigaeats.com', 'Raj Kumar', '+60123456792', 'sales_agent', false, true, null, NOW(), NOW()),

-- Vendors
('550e8400-e29b-41d4-a716-446655440005', 'firebase_vendor_001', 'vendor1@gigaeats.com', 'Lim Wei Ming', '+60123456793', 'vendor', true, true, null, NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440006', 'firebase_vendor_002', 'vendor2@gigaeats.com', 'Fatimah Abdullah', '+60123456794', 'vendor', true, true, null, NOW(), NOW()),
('550e8400-e29b-41d4-a716-446655440007', 'firebase_vendor_003', 'vendor3@gigaeats.com', 'Chen Wei Liang', '+60123456795', 'vendor', false, true, null, NOW(), NOW());

-- Insert user profiles
INSERT INTO user_profiles (id, user_id, firebase_uid, company_name, business_registration_number, business_address, business_type, commission_rate, total_earnings, total_orders, assigned_regions, preferences, kyc_documents, verification_status, created_at, updated_at) VALUES
-- Admin profile
('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'firebase_admin_001', 'GigaEats Sdn Bhd', 'SSM001234567', 'Kuala Lumpur, Malaysia', 'Technology', 0.0000, 0.00, 0, ARRAY['Kuala Lumpur', 'Selangor', 'Penang'], '{"notifications": true, "language": "en"}', '{}', 'verified', NOW(), NOW()),

-- Sales agent profiles
('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', 'firebase_sales_001', 'Rahman Sales Agency', 'SSM001234568', 'Petaling Jaya, Selangor', 'Sales', 0.0700, 2500.00, 15, ARRAY['Kuala Lumpur', 'Selangor'], '{"notifications": true, "language": "ms"}', '{"ic": {"url": "kyc/firebase_sales_001_ic.pdf", "status": "approved"}}', 'verified', NOW(), NOW()),
('660e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', 'firebase_sales_002', 'Siti Enterprise', 'SSM001234569', 'Shah Alam, Selangor', 'Sales', 0.0700, 1800.00, 12, ARRAY['Selangor', 'Negeri Sembilan'], '{"notifications": true, "language": "ms"}', '{"ic": {"url": "kyc/firebase_sales_002_ic.pdf", "status": "approved"}}', 'verified', NOW(), NOW()),
('660e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004', 'firebase_sales_003', 'Kumar Trading', 'SSM001234570', 'Subang Jaya, Selangor', 'Sales', 0.0700, 0.00, 0, ARRAY['Kuala Lumpur'], '{"notifications": true, "language": "en"}', '{"ic": {"url": "kyc/firebase_sales_003_ic.pdf", "status": "pending"}}', 'pending', NOW(), NOW());

-- Insert vendors
INSERT INTO vendors (id, user_id, firebase_uid, business_name, business_registration_number, business_address, business_type, cuisine_types, is_halal_certified, halal_certification_number, description, rating, total_reviews, total_orders, cover_image_url, gallery_images, business_hours, service_areas, minimum_order_amount, delivery_fee, free_delivery_threshold, is_active, is_verified, created_at, updated_at) VALUES
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440005', 'firebase_vendor_001', 'Lim''s Kitchen', 'SSM002234567', '123 Jalan Makan, Kuala Lumpur', 'Restaurant', ARRAY['Chinese', 'Malaysian'], true, 'HALAL001234', 'Authentic Chinese and Malaysian cuisine with over 20 years of experience', 4.5, 150, 45, null, ARRAY[]::text[], '{"monday": {"open": "08:00", "close": "22:00"}, "tuesday": {"open": "08:00", "close": "22:00"}}', ARRAY['Kuala Lumpur', 'Selangor'], 50.00, 15.00, 200.00, true, true, NOW(), NOW()),

('770e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440006', 'firebase_vendor_002', 'Fatimah''s Catering', 'SSM002234568', '456 Jalan Raya, Petaling Jaya', 'Catering', ARRAY['Malay', 'Indian'], true, 'HALAL001235', 'Traditional Malay and Indian catering services for corporate events', 4.7, 89, 32, null, ARRAY[]::text[], '{"monday": {"open": "06:00", "close": "20:00"}, "tuesday": {"open": "06:00", "close": "20:00"}}', ARRAY['Selangor', 'Kuala Lumpur'], 100.00, 20.00, 300.00, true, true, NOW(), NOW()),

('770e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440007', 'firebase_vendor_003', 'Chen''s Dim Sum House', 'SSM002234569', '789 Jalan Dim Sum, Subang Jaya', 'Restaurant', ARRAY['Chinese', 'Dim Sum'], false, null, 'Fresh handmade dim sum and Chinese delicacies', 4.2, 67, 18, null, ARRAY[]::text[], '{"monday": {"open": "07:00", "close": "15:00"}, "tuesday": {"open": "07:00", "close": "15:00"}}', ARRAY['Selangor'], 80.00, 12.00, 250.00, true, false, NOW(), NOW());

-- Insert menu items
INSERT INTO menu_items (id, vendor_id, name, description, category, tags, base_price, bulk_price, bulk_min_quantity, currency, is_available, min_order_quantity, max_order_quantity, preparation_time_minutes, allergens, is_halal, is_vegetarian, is_vegan, is_spicy, spicy_level, image_url, rating, total_reviews, is_featured, created_at, updated_at) VALUES
-- Lim's Kitchen menu items
('880e8400-e29b-41d4-a716-446655440001', '770e8400-e29b-41d4-a716-446655440001', 'Char Kway Teow', 'Stir-fried flat rice noodles with prawns, Chinese sausage, and bean sprouts', 'Main Course', ARRAY['signature', 'spicy'], 12.50, 11.00, 10, 'MYR', true, 1, 50, 20, ARRAY['shellfish', 'soy'], true, false, false, true, 2, null, 4.6, 95, true, NOW(), NOW()),

('880e8400-e29b-41d4-a716-446655440002', '770e8400-e29b-41d4-a716-446655440001', 'Hainanese Chicken Rice', 'Tender poached chicken with fragrant rice and ginger sauce', 'Main Course', ARRAY['signature', 'comfort'], 15.00, 13.50, 10, 'MYR', true, 1, 30, 25, ARRAY[]::text[], true, false, false, false, 0, null, 4.7, 120, true, NOW(), NOW()),

('880e8400-e29b-41d4-a716-446655440003', '770e8400-e29b-41d4-a716-446655440001', 'Wonton Noodle Soup', 'Fresh egg noodles with pork and prawn wontons in clear broth', 'Soup', ARRAY['comfort', 'traditional'], 10.00, 9.00, 15, 'MYR', true, 1, 40, 15, ARRAY['shellfish', 'gluten'], true, false, false, false, 0, null, 4.4, 78, false, NOW(), NOW()),

-- Fatimah's Catering menu items
('880e8400-e29b-41d4-a716-446655440004', '770e8400-e29b-41d4-a716-446655440002', 'Nasi Lemak Set', 'Coconut rice with sambal, anchovies, peanuts, egg, and chicken rendang', 'Set Meal', ARRAY['traditional', 'spicy'], 18.00, 16.00, 20, 'MYR', true, 10, 100, 30, ARRAY['nuts', 'eggs'], true, false, false, true, 2, null, 4.8, 156, true, NOW(), NOW()),

('880e8400-e29b-41d4-a716-446655440005', '770e8400-e29b-41d4-a716-446655440002', 'Biryani Rice', 'Fragrant basmati rice with spiced chicken and raita', 'Main Course', ARRAY['indian', 'aromatic'], 22.00, 20.00, 15, 'MYR', true, 5, 80, 35, ARRAY['dairy'], true, false, false, true, 1, null, 4.6, 89, true, NOW(), NOW()),

('880e8400-e29b-41d4-a716-446655440006', '770e8400-e29b-41d4-a716-446655440002', 'Roti Canai with Curry', 'Flaky flatbread served with chicken curry', 'Appetizer', ARRAY['traditional', 'bread'], 8.00, 7.00, 25, 'MYR', true, 1, 50, 10, ARRAY['gluten'], true, true, false, true, 2, null, 4.3, 67, false, NOW(), NOW()),

-- Chen's Dim Sum House menu items
('880e8400-e29b-41d4-a716-446655440007', '770e8400-e29b-41d4-a716-446655440003', 'Har Gow (Prawn Dumplings)', 'Steamed crystal dumplings filled with fresh prawns', 'Dim Sum', ARRAY['steamed', 'seafood'], 8.50, 7.50, 20, 'MYR', true, 3, 60, 12, ARRAY['shellfish'], false, false, false, false, 0, null, 4.5, 92, true, NOW(), NOW()),

('880e8400-e29b-41d4-a716-446655440008', '770e8400-e29b-41d4-a716-446655440003', 'Siu Mai (Pork Dumplings)', 'Steamed open-topped dumplings with pork and shrimp', 'Dim Sum', ARRAY['steamed', 'pork'], 7.50, 6.50, 20, 'MYR', true, 3, 60, 12, ARRAY['shellfish'], false, false, false, false, 0, null, 4.2, 78, false, NOW(), NOW()),

('880e8400-e29b-41d4-a716-446655440009', '770e8400-e29b-41d4-a716-446655440003', 'Char Siu Bao', 'Steamed BBQ pork buns with sweet and savory filling', 'Dim Sum', ARRAY['steamed', 'sweet'], 6.00, 5.50, 25, 'MYR', true, 2, 50, 15, ARRAY['gluten'], false, false, false, false, 0, null, 4.4, 65, false, NOW(), NOW());

-- Insert customers
INSERT INTO customers (id, sales_agent_id, organization_name, contact_person_name, email, phone_number, address, customer_type, total_spent, total_orders, is_active, is_verified, created_at, updated_at) VALUES
('990e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', 'Tech Solutions Sdn Bhd', 'Ahmad Rahman', 'ahmad@techsolutions.com', '+60123456796', '{"street": "789 Jalan Tech", "city": "Kuala Lumpur", "state": "Kuala Lumpur", "postal_code": "50000", "country": "Malaysia"}', 'business', 1250.00, 8, true, true, NOW(), NOW()),

('990e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', 'Green Valley School', 'Siti Nurhaliza', 'siti@greenvalley.edu.my', '+60123456797', '{"street": "321 Jalan Pendidikan", "city": "Petaling Jaya", "state": "Selangor", "postal_code": "47000", "country": "Malaysia"}', 'institution', 2100.00, 12, true, true, NOW(), NOW()),

('990e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', 'Sunrise Cafe', 'Raj Kumar', 'raj@sunrisecafe.com', '+60123456798', '{"street": "456 Jalan Rumah", "city": "Subang Jaya", "state": "Selangor", "postal_code": "47500", "country": "Malaysia"}', 'business', 850.00, 5, true, true, NOW(), NOW());

-- Insert sample orders
INSERT INTO orders (id, order_number, status, vendor_id, customer_id, sales_agent_id, delivery_date, delivery_address, subtotal, delivery_fee, sst_amount, total_amount, commission_amount, payment_status, payment_method, notes, created_at, updated_at) VALUES
('aa0e8400-e29b-41d4-a716-446655440001', 'GE20241201000001', 'delivered', '770e8400-e29b-41d4-a716-446655440001', '990e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', '2024-12-01', '{"street": "789 Jalan Tech", "city": "Kuala Lumpur", "state": "Kuala Lumpur", "postal_code": "50000", "country": "Malaysia"}', 125.00, 15.00, 8.40, 148.40, 10.39, 'paid', 'fpx', 'Office lunch order', NOW(), NOW()),

('aa0e8400-e29b-41d4-a716-446655440002', 'GE20241202000002', 'preparing', '770e8400-e29b-41d4-a716-446655440002', '990e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', '2024-12-02', '{"street": "321 Jalan Pendidikan", "city": "Petaling Jaya", "state": "Selangor", "postal_code": "47000", "country": "Malaysia"}', 280.00, 20.00, 18.00, 318.00, 22.26, 'paid', 'grabpay', 'School event catering', NOW(), NOW()),

('aa0e8400-e29b-41d4-a716-446655440003', 'GE20241203000003', 'pending', '770e8400-e29b-41d4-a716-446655440003', '990e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', '2024-12-03', '{"street": "456 Jalan Rumah", "city": "Subang Jaya", "state": "Selangor", "postal_code": "47500", "country": "Malaysia"}', 45.00, 15.00, 3.60, 63.60, 4.45, 'pending', 'fpx', 'Cafe supply order', NOW(), NOW());

-- Insert order items
INSERT INTO order_items (id, order_id, menu_item_id, name, description, unit_price, quantity, total_price, notes, created_at) VALUES
-- Order 1 items (Lim's Kitchen)
('bb0e8400-e29b-41d4-a716-446655440001', 'aa0e8400-e29b-41d4-a716-446655440001', '880e8400-e29b-41d4-a716-446655440001', 'Char Kway Teow', 'Stir-fried flat rice noodles with prawns, Chinese sausage, and bean sprouts', 12.50, 8, 100.00, 'Extra spicy', NOW()),
('bb0e8400-e29b-41d4-a716-446655440002', 'aa0e8400-e29b-41d4-a716-446655440001', '880e8400-e29b-41d4-a716-446655440002', 'Hainanese Chicken Rice', 'Tender poached chicken with fragrant rice and ginger sauce', 15.00, 1, 15.00, null, NOW()),
('bb0e8400-e29b-41d4-a716-446655440003', 'aa0e8400-e29b-41d4-a716-446655440001', '880e8400-e29b-41d4-a716-446655440003', 'Wonton Noodle Soup', 'Fresh egg noodles with pork and prawn wontons in clear broth', 10.00, 1, 10.00, null, NOW()),

-- Order 2 items (Fatimah's Catering)
('bb0e8400-e29b-41d4-a716-446655440004', 'aa0e8400-e29b-41d4-a716-446655440002', '880e8400-e29b-41d4-a716-446655440004', 'Nasi Lemak Set', 'Coconut rice with sambal, anchovies, peanuts, egg, and chicken rendang', 18.00, 10, 180.00, 'For school event', NOW()),
('bb0e8400-e29b-41d4-a716-446655440005', 'aa0e8400-e29b-41d4-a716-446655440002', '880e8400-e29b-41d4-a716-446655440005', 'Biryani Rice', 'Fragrant basmati rice with spiced chicken and raita', 22.00, 3, 66.00, null, NOW()),
('bb0e8400-e29b-41d4-a716-446655440006', 'aa0e8400-e29b-41d4-a716-446655440002', '880e8400-e29b-41d4-a716-446655440006', 'Roti Canai with Curry', 'Flaky flatbread served with chicken curry', 8.00, 5, 40.00, 'Extra curry sauce', NOW()),

-- Order 3 items (Chen's Dim Sum House)
('bb0e8400-e29b-41d4-a716-446655440007', 'aa0e8400-e29b-41d4-a716-446655440003', '880e8400-e29b-41d4-a716-446655440007', 'Har Gow (Prawn Dumplings)', 'Steamed crystal dumplings filled with fresh prawns', 8.50, 3, 25.50, null, NOW()),
('bb0e8400-e29b-41d4-a716-446655440008', 'aa0e8400-e29b-41d4-a716-446655440003', '880e8400-e29b-41d4-a716-446655440008', 'Siu Mai (Pork Dumplings)', 'Steamed open-topped dumplings with pork and shrimp', 7.50, 2, 15.00, null, NOW()),
('bb0e8400-e29b-41d4-a716-446655440009', 'aa0e8400-e29b-41d4-a716-446655440003', '880e8400-e29b-41d4-a716-446655440009', 'Char Siu Bao', 'Steamed BBQ pork buns with sweet and savory filling', 6.00, 1, 6.00, null, NOW());

-- Insert FCM tokens for testing notifications
INSERT INTO user_fcm_tokens (id, firebase_uid, fcm_token, device_type, is_active, created_at, updated_at) VALUES
('cc0e8400-e29b-41d4-a716-446655440001', 'firebase_admin_001', 'sample-fcm-token-admin', 'android', true, NOW(), NOW()),
('cc0e8400-e29b-41d4-a716-446655440002', 'firebase_sales_001', 'sample-fcm-token-sales-1', 'ios', true, NOW(), NOW()),
('cc0e8400-e29b-41d4-a716-446655440003', 'firebase_sales_002', 'sample-fcm-token-sales-2', 'android', true, NOW(), NOW()),
('cc0e8400-e29b-41d4-a716-446655440004', 'firebase_vendor_001', 'sample-fcm-token-vendor-1', 'android', true, NOW(), NOW()),
('cc0e8400-e29b-41d4-a716-446655440005', 'firebase_vendor_002', 'sample-fcm-token-vendor-2', 'ios', true, NOW(), NOW());

-- Insert vendor settings for test vendors
INSERT INTO vendor_settings (id, vendor_id, auto_accept_orders, notification_preferences, order_capacity_limit, preparation_buffer_minutes, created_at, updated_at) VALUES
('dd0e8400-e29b-41d4-a716-446655440001', '770e8400-e29b-41d4-a716-446655440001', true, '{"email": true, "push": true, "sms": true}', 30, 10, NOW(), NOW()),
('dd0e8400-e29b-41d4-a716-446655440002', '770e8400-e29b-41d4-a716-446655440002', false, '{"email": true, "push": true, "sms": false}', 50, 15, NOW(), NOW()),
('dd0e8400-e29b-41d4-a716-446655440003', '770e8400-e29b-41d4-a716-446655440003', true, '{"email": false, "push": true, "sms": false}', 25, 20, NOW(), NOW());

-- Insert vendor analytics for the past week
INSERT INTO vendor_analytics (id, vendor_id, date, total_orders, total_revenue, average_order_value, new_customers, repeat_customers, preparation_time_avg, rating_average, rating_count, created_at, updated_at) VALUES
-- Lim's Kitchen analytics
('ee0e8400-e29b-41d4-a716-446655440001', '770e8400-e29b-41d4-a716-446655440001', CURRENT_DATE - INTERVAL '6 days', 8, 320.00, 40.00, 3, 5, 22, 4.5, 8, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440002', '770e8400-e29b-41d4-a716-446655440001', CURRENT_DATE - INTERVAL '5 days', 12, 480.00, 40.00, 4, 8, 20, 4.6, 12, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440003', '770e8400-e29b-41d4-a716-446655440001', CURRENT_DATE - INTERVAL '4 days', 15, 600.00, 40.00, 5, 10, 18, 4.7, 15, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440004', '770e8400-e29b-41d4-a716-446655440001', CURRENT_DATE - INTERVAL '3 days', 10, 400.00, 40.00, 2, 8, 25, 4.4, 10, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440005', '770e8400-e29b-41d4-a716-446655440001', CURRENT_DATE - INTERVAL '2 days', 18, 720.00, 40.00, 6, 12, 19, 4.8, 18, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440006', '770e8400-e29b-41d4-a716-446655440001', CURRENT_DATE - INTERVAL '1 day', 14, 560.00, 40.00, 4, 10, 21, 4.6, 14, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440007', '770e8400-e29b-41d4-a716-446655440001', CURRENT_DATE, 6, 240.00, 40.00, 2, 4, 23, 4.5, 6, NOW(), NOW()),

-- Fatimah's Catering analytics
('ee0e8400-e29b-41d4-a716-446655440008', '770e8400-e29b-41d4-a716-446655440002', CURRENT_DATE - INTERVAL '6 days', 5, 450.00, 90.00, 2, 3, 35, 4.7, 5, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440009', '770e8400-e29b-41d4-a716-446655440002', CURRENT_DATE - INTERVAL '5 days', 7, 630.00, 90.00, 3, 4, 32, 4.8, 7, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440010', '770e8400-e29b-41d4-a716-446655440002', CURRENT_DATE - INTERVAL '4 days', 9, 810.00, 90.00, 4, 5, 30, 4.9, 9, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440011', '770e8400-e29b-41d4-a716-446655440002', CURRENT_DATE - INTERVAL '3 days', 6, 540.00, 90.00, 2, 4, 38, 4.6, 6, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440012', '770e8400-e29b-41d4-a716-446655440002', CURRENT_DATE - INTERVAL '2 days', 8, 720.00, 90.00, 3, 5, 33, 4.7, 8, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440013', '770e8400-e29b-41d4-a716-446655440002', CURRENT_DATE - INTERVAL '1 day', 4, 360.00, 90.00, 1, 3, 36, 4.5, 4, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440014', '770e8400-e29b-41d4-a716-446655440002', CURRENT_DATE, 3, 270.00, 90.00, 1, 2, 34, 4.8, 3, NOW(), NOW()),

-- Chen's Dim Sum House analytics
('ee0e8400-e29b-41d4-a716-446655440015', '770e8400-e29b-41d4-a716-446655440003', CURRENT_DATE - INTERVAL '6 days', 12, 180.00, 15.00, 5, 7, 15, 4.2, 12, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440016', '770e8400-e29b-41d4-a716-446655440003', CURRENT_DATE - INTERVAL '5 days', 15, 225.00, 15.00, 6, 9, 12, 4.3, 15, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440017', '770e8400-e29b-41d4-a716-446655440003', CURRENT_DATE - INTERVAL '4 days', 18, 270.00, 15.00, 7, 11, 14, 4.4, 18, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440018', '770e8400-e29b-41d4-a716-446655440003', CURRENT_DATE - INTERVAL '3 days', 10, 150.00, 15.00, 3, 7, 16, 4.1, 10, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440019', '770e8400-e29b-41d4-a716-446655440003', CURRENT_DATE - INTERVAL '2 days', 20, 300.00, 15.00, 8, 12, 13, 4.5, 20, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440020', '770e8400-e29b-41d4-a716-446655440003', CURRENT_DATE - INTERVAL '1 day', 16, 240.00, 15.00, 6, 10, 15, 4.3, 16, NOW(), NOW()),
('ee0e8400-e29b-41d4-a716-446655440021', '770e8400-e29b-41d4-a716-446655440003', CURRENT_DATE, 8, 120.00, 15.00, 3, 5, 14, 4.2, 8, NOW(), NOW());

-- Insert vendor notifications
INSERT INTO vendor_notifications (id, vendor_id, title, message, type, is_read, action_url, metadata, created_at) VALUES
-- Lim's Kitchen notifications
('ff0e8400-e29b-41d4-a716-446655440001', '770e8400-e29b-41d4-a716-446655440001', 'New Order Received', 'You have received a new order #GE20241201000004 for RM 125.50', 'info', false, '/orders/aa0e8400-e29b-41d4-a716-446655440004', '{"order_id": "aa0e8400-e29b-41d4-a716-446655440004", "amount": 125.50}', NOW() - INTERVAL '2 hours'),
('ff0e8400-e29b-41d4-a716-446655440002', '770e8400-e29b-41d4-a716-446655440001', 'Menu Item Low Stock', 'Char Kway Teow is running low on stock (5 remaining)', 'warning', true, '/menu', '{"menu_item": "Char Kway Teow", "stock": 5}', NOW() - INTERVAL '1 day'),
('ff0e8400-e29b-41d4-a716-446655440003', '770e8400-e29b-41d4-a716-446655440001', 'Great Rating!', 'You received a 5-star rating from a customer', 'success', true, '/reviews', '{"rating": 5, "customer": "Ahmad Rahman"}', NOW() - INTERVAL '3 days'),

-- Fatimah's Catering notifications
('ff0e8400-e29b-41d4-a716-446655440004', '770e8400-e29b-41d4-a716-446655440002', 'Large Order Alert', 'You have received a large catering order for 50 people', 'info', false, '/orders/aa0e8400-e29b-41d4-a716-446655440005', '{"order_size": 50, "event_type": "corporate"}', NOW() - INTERVAL '1 hour'),
('ff0e8400-e29b-41d4-a716-446655440005', '770e8400-e29b-41d4-a716-446655440002', 'Payment Received', 'Payment of RM 850.00 has been confirmed for order #GE20241202000005', 'success', true, '/orders/aa0e8400-e29b-41d4-a716-446655440005', '{"payment_amount": 850.00}', NOW() - INTERVAL '2 days'),

-- Chen's Dim Sum House notifications
('ff0e8400-e29b-41d4-a716-446655440006', '770e8400-e29b-41d4-a716-446655440003', 'Order Cancelled', 'Order #GE20241203000006 has been cancelled by customer', 'error', false, '/orders/aa0e8400-e29b-41d4-a716-446655440006', '{"reason": "customer_request"}', NOW() - INTERVAL '30 minutes'),
('ff0e8400-e29b-41d4-a716-446655440007', '770e8400-e29b-41d4-a716-446655440003', 'Business Hours Updated', 'Your business hours have been successfully updated', 'success', true, '/settings', '{}', NOW() - INTERVAL '1 week');

-- Insert additional test orders with various statuses for vendor testing
INSERT INTO orders (id, order_number, status, vendor_id, customer_id, sales_agent_id, delivery_date, delivery_address, subtotal, delivery_fee, sst_amount, total_amount, commission_amount, payment_status, payment_method, notes, created_at, updated_at) VALUES
-- Recent orders for testing vendor dashboard
('aa0e8400-e29b-41d4-a716-446655440004', 'GE20241204000004', 'confirmed', '770e8400-e29b-41d4-a716-446655440001', '990e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', CURRENT_DATE, '{"street": "789 Jalan Tech", "city": "Kuala Lumpur", "state": "Kuala Lumpur", "postal_code": "50000", "country": "Malaysia"}', 110.00, 15.00, 7.50, 132.50, 9.28, 'paid', 'fpx', 'Rush order for meeting', NOW() - INTERVAL '2 hours', NOW()),

('aa0e8400-e29b-41d4-a716-446655440005', 'GE20241204000005', 'preparing', '770e8400-e29b-41d4-a716-446655440002', '990e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', CURRENT_DATE, '{"street": "321 Jalan Pendidikan", "city": "Petaling Jaya", "state": "Selangor", "postal_code": "47000", "country": "Malaysia"}', 750.00, 20.00, 46.20, 816.20, 57.13, 'paid', 'grabpay', 'Corporate event catering for 50 people', NOW() - INTERVAL '1 hour', NOW()),

('aa0e8400-e29b-41d4-a716-446655440006', 'GE20241204000006', 'cancelled', '770e8400-e29b-41d4-a716-446655440003', '990e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', CURRENT_DATE, '{"street": "456 Jalan Rumah", "city": "Subang Jaya", "state": "Selangor", "postal_code": "47500", "country": "Malaysia"}', 35.00, 15.00, 3.00, 53.00, 3.71, 'refunded', 'fpx', 'Customer requested cancellation', NOW() - INTERVAL '30 minutes', NOW()),

('aa0e8400-e29b-41d4-a716-446655440007', 'GE20241204000007', 'ready', '770e8400-e29b-41d4-a716-446655440001', '990e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', CURRENT_DATE, '{"street": "789 Jalan Tech", "city": "Kuala Lumpur", "state": "Kuala Lumpur", "postal_code": "50000", "country": "Malaysia"}', 75.00, 15.00, 5.40, 95.40, 6.68, 'paid', 'touchngo', 'Lunch delivery', NOW() - INTERVAL '45 minutes', NOW());

-- Insert corresponding order items for the new orders
INSERT INTO order_items (id, order_id, menu_item_id, name, description, unit_price, quantity, total_price, notes, created_at) VALUES
-- Order 4 items (Lim's Kitchen - confirmed)
('bb0e8400-e29b-41d4-a716-446655440010', 'aa0e8400-e29b-41d4-a716-446655440004', '880e8400-e29b-41d4-a716-446655440002', 'Hainanese Chicken Rice', 'Tender poached chicken with fragrant rice and ginger sauce', 15.00, 5, 75.00, 'Extra ginger sauce', NOW()),
('bb0e8400-e29b-41d4-a716-446655440011', 'aa0e8400-e29b-41d4-a716-446655440004', '880e8400-e29b-41d4-a716-446655440003', 'Wonton Noodle Soup', 'Fresh egg noodles with pork and prawn wontons in clear broth', 10.00, 3, 30.00, null, NOW()),

-- Order 5 items (Fatimah's Catering - preparing)
('bb0e8400-e29b-41d4-a716-446655440012', 'aa0e8400-e29b-41d4-a716-446655440005', '880e8400-e29b-41d4-a716-446655440004', 'Nasi Lemak Set', 'Coconut rice with sambal, anchovies, peanuts, egg, and chicken rendang', 18.00, 30, 540.00, 'Corporate event - 50 people', NOW()),
('bb0e8400-e29b-41d4-a716-446655440013', 'aa0e8400-e29b-41d4-a716-446655440005', '880e8400-e29b-41d4-a716-446655440005', 'Biryani Rice', 'Fragrant basmati rice with spiced chicken and raita', 22.00, 10, 220.00, 'Extra raita', NOW()),

-- Order 6 items (Chen's Dim Sum House - cancelled)
('bb0e8400-e29b-41d4-a716-446655440014', 'aa0e8400-e29b-41d4-a716-446655440006', '880e8400-e29b-41d4-a716-446655440007', 'Har Gow (Prawn Dumplings)', 'Steamed crystal dumplings filled with fresh prawns', 8.50, 4, 34.00, null, NOW()),

-- Order 7 items (Lim's Kitchen - ready)
('bb0e8400-e29b-41d4-a716-446655440015', 'aa0e8400-e29b-41d4-a716-446655440007', '880e8400-e29b-41d4-a716-446655440001', 'Char Kway Teow', 'Stir-fried flat rice noodles with prawns, Chinese sausage, and bean sprouts', 12.50, 6, 75.00, 'Medium spicy', NOW());

-- Re-enable RLS after seeding
SET session_replication_role = DEFAULT;
