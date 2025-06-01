-- Fix the auth trigger functions to properly handle signup data
-- This migration fixes the 500 error during user signup

-- Drop existing triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;

-- Create improved function to handle user creation from Supabase auth
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  user_phone_number TEXT;
  user_role TEXT;
BEGIN
  -- Extract phone number from metadata or use the phone field
  user_phone_number := COALESCE(
    NEW.raw_user_meta_data->>'phone_number',
    NEW.phone
  );
  
  -- Extract role from metadata, default to 'sales_agent'
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'sales_agent');
  
  -- Validate role is one of the allowed values
  IF user_role NOT IN ('sales_agent', 'vendor', 'admin', 'customer') THEN
    user_role := 'sales_agent';
  END IF;
  
  INSERT INTO public.users (
    id,
    supabase_user_id,
    email,
    full_name,
    phone_number,
    role,
    is_verified,
    is_active,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    user_phone_number,
    user_role::user_role_enum,
    NEW.email_confirmed_at IS NOT NULL OR NEW.phone_confirmed_at IS NOT NULL,
    true,
    NOW(),
    NOW()
  );
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error and re-raise it
    RAISE LOG 'Error in handle_new_user trigger: %', SQLERRM;
    RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create improved function to sync user metadata changes
CREATE OR REPLACE FUNCTION handle_user_metadata_update()
RETURNS TRIGGER AS $$
DECLARE
  user_phone_number TEXT;
BEGIN
  -- Extract phone number from metadata or use the phone field
  user_phone_number := COALESCE(
    NEW.raw_user_meta_data->>'phone_number',
    NEW.phone
  );
  
  UPDATE public.users SET
    email = NEW.email,
    full_name = COALESCE(NEW.raw_user_meta_data->>'full_name', full_name),
    phone_number = user_phone_number,
    is_verified = NEW.email_confirmed_at IS NOT NULL OR NEW.phone_confirmed_at IS NOT NULL,
    updated_at = NOW()
  WHERE supabase_user_id = NEW.id;
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error and re-raise it
    RAISE LOG 'Error in handle_user_metadata_update trigger: %', SQLERRM;
    RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate triggers
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

CREATE TRIGGER on_auth_user_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_user_metadata_update();
