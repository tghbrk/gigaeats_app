-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types
CREATE TYPE user_role_enum AS ENUM ('sales_agent', 'vendor', 'admin', 'customer');
CREATE TYPE order_status_enum AS ENUM ('pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'cancelled');
CREATE TYPE payment_status_enum AS ENUM ('pending', 'paid', 'failed', 'refunded');
CREATE TYPE payment_method_enum AS ENUM ('fpx', 'grabpay', 'touchngo', 'credit_card');

-- Users table synchronized with Firebase Auth
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_uid TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  phone_number TEXT,
  role user_role_enum NOT NULL DEFAULT 'sales_agent',
  is_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  profile_image_url TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User profiles with extended information
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  firebase_uid TEXT NOT NULL REFERENCES users(firebase_uid),
  company_name TEXT,
  business_registration_number TEXT,
  business_address TEXT,
  business_type TEXT,
  commission_rate DECIMAL(5,4) DEFAULT 0.07, -- 7% default commission
  total_earnings DECIMAL(12,2) DEFAULT 0.00,
  total_orders INTEGER DEFAULT 0,
  assigned_regions TEXT[] DEFAULT '{}',
  preferences JSONB DEFAULT '{}',
  kyc_documents JSONB DEFAULT '{}',
  verification_status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Vendors table
CREATE TABLE vendors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  firebase_uid TEXT NOT NULL REFERENCES users(firebase_uid),
  business_name TEXT NOT NULL,
  business_registration_number TEXT UNIQUE NOT NULL,
  business_address TEXT NOT NULL,
  business_type TEXT NOT NULL,
  cuisine_types TEXT[] NOT NULL DEFAULT '{}',
  is_halal_certified BOOLEAN DEFAULT FALSE,
  halal_certification_number TEXT,
  description TEXT,
  rating DECIMAL(3,2) DEFAULT 0.00,
  total_reviews INTEGER DEFAULT 0,
  total_orders INTEGER DEFAULT 0,
  cover_image_url TEXT,
  gallery_images TEXT[] DEFAULT '{}',
  business_hours JSONB DEFAULT '{}',
  service_areas TEXT[] DEFAULT '{}',
  minimum_order_amount DECIMAL(10,2) DEFAULT 50.00,
  delivery_fee DECIMAL(8,2) DEFAULT 15.00,
  free_delivery_threshold DECIMAL(10,2) DEFAULT 200.00,
  is_active BOOLEAN DEFAULT TRUE,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Menu items/products table
CREATE TABLE menu_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  tags TEXT[] DEFAULT '{}',
  base_price DECIMAL(10,2) NOT NULL,
  bulk_price DECIMAL(10,2),
  bulk_min_quantity INTEGER,
  currency TEXT DEFAULT 'MYR',
  includes_sst BOOLEAN DEFAULT FALSE,
  is_available BOOLEAN DEFAULT TRUE,
  min_order_quantity INTEGER DEFAULT 1,
  max_order_quantity INTEGER,
  preparation_time_minutes INTEGER DEFAULT 30,
  allergens TEXT[] DEFAULT '{}',
  is_halal BOOLEAN DEFAULT FALSE,
  is_vegetarian BOOLEAN DEFAULT FALSE,
  is_vegan BOOLEAN DEFAULT FALSE,
  is_spicy BOOLEAN DEFAULT FALSE,
  spicy_level INTEGER DEFAULT 0 CHECK (spicy_level >= 0 AND spicy_level <= 5),
  image_url TEXT,
  gallery_images TEXT[] DEFAULT '{}',
  nutrition_info JSONB DEFAULT '{}',
  rating DECIMAL(3,2) DEFAULT 0.00,
  total_reviews INTEGER DEFAULT 0,
  is_featured BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Customers table
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sales_agent_id UUID REFERENCES users(id),
  organization_name TEXT NOT NULL,
  contact_person_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  alternate_phone_number TEXT,
  address JSONB NOT NULL, -- {street, city, state, postal_code, country}
  customer_type TEXT DEFAULT 'business', -- business, individual, institution
  business_info JSONB DEFAULT '{}',
  preferences JSONB DEFAULT '{}',
  total_spent DECIMAL(12,2) DEFAULT 0.00,
  total_orders INTEGER DEFAULT 0,
  average_order_value DECIMAL(10,2) DEFAULT 0.00,
  last_order_date TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT TRUE,
  is_verified BOOLEAN DEFAULT FALSE,
  notes TEXT,
  tags TEXT[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Orders table
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_number TEXT UNIQUE NOT NULL,
  status order_status_enum DEFAULT 'pending',
  vendor_id UUID REFERENCES vendors(id) NOT NULL,
  customer_id UUID REFERENCES customers(id) NOT NULL,
  sales_agent_id UUID REFERENCES users(id),
  delivery_date DATE NOT NULL,
  delivery_address JSONB NOT NULL,
  subtotal DECIMAL(12,2) NOT NULL,
  delivery_fee DECIMAL(8,2) DEFAULT 0.00,
  sst_amount DECIMAL(10,2) DEFAULT 0.00,
  total_amount DECIMAL(12,2) NOT NULL,
  commission_amount DECIMAL(10,2) DEFAULT 0.00,
  payment_status payment_status_enum DEFAULT 'pending',
  payment_method payment_method_enum,
  payment_reference TEXT,
  notes TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Order items table
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id UUID REFERENCES menu_items(id),
  name TEXT NOT NULL,
  description TEXT,
  unit_price DECIMAL(10,2) NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  total_price DECIMAL(12,2) NOT NULL,
  customizations JSONB DEFAULT '{}',
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- FCM tokens for push notifications
CREATE TABLE user_fcm_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_uid TEXT NOT NULL REFERENCES users(firebase_uid),
  fcm_token TEXT NOT NULL,
  device_type TEXT, -- ios, android, web
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(firebase_uid, fcm_token)
);

-- Create indexes for better performance
CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_user_profiles_firebase_uid ON user_profiles(firebase_uid);
CREATE INDEX idx_vendors_firebase_uid ON vendors(firebase_uid);
CREATE INDEX idx_vendors_business_name ON vendors(business_name);
CREATE INDEX idx_vendors_cuisine_types ON vendors USING GIN(cuisine_types);
CREATE INDEX idx_menu_items_vendor_id ON menu_items(vendor_id);
CREATE INDEX idx_menu_items_category ON menu_items(category);
CREATE INDEX idx_menu_items_tags ON menu_items USING GIN(tags);
CREATE INDEX idx_customers_sales_agent_id ON customers(sales_agent_id);
CREATE INDEX idx_orders_vendor_id ON orders(vendor_id);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_sales_agent_id ON orders(sales_agent_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_delivery_date ON orders(delivery_date);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_fcm_tokens_firebase_uid ON user_fcm_tokens(firebase_uid);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers to all tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vendors_updated_at BEFORE UPDATE ON vendors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_menu_items_updated_at BEFORE UPDATE ON menu_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_fcm_tokens_updated_at BEFORE UPDATE ON user_fcm_tokens FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
