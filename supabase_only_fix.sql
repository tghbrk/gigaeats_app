-- Clean fix for Supabase-only authentication (no Firebase)
-- This removes all Firebase dependencies and fixes the 500 error

-- Drop existing triggers first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;

-- Remove Firebase-related constraints and columns
DO $$
BEGIN
    -- Drop Firebase-related constraints
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conrelid = 'public.users'::regclass 
        AND conname = 'check_user_auth_id'
    ) THEN
        ALTER TABLE public.users DROP CONSTRAINT check_user_auth_id;
        RAISE NOTICE 'Dropped Firebase auth constraint';
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conrelid = 'public.users'::regclass 
        AND conname = 'check_user_auth_id_flexible'
    ) THEN
        ALTER TABLE public.users DROP CONSTRAINT check_user_auth_id_flexible;
        RAISE NOTICE 'Dropped flexible auth constraint';
    END IF;
END $$;

-- Remove firebase_uid column if it exists (since we're Supabase-only)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'firebase_uid'
    ) THEN
        ALTER TABLE public.users DROP COLUMN firebase_uid;
        RAISE NOTICE 'Removed firebase_uid column';
    END IF;
END $$;

-- Ensure supabase_user_id is NOT NULL since it's our primary auth reference
ALTER TABLE public.users ALTER COLUMN supabase_user_id SET NOT NULL;

-- Add unique constraint on supabase_user_id
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conrelid = 'public.users'::regclass 
        AND conname = 'users_supabase_user_id_key'
    ) THEN
        ALTER TABLE public.users ADD CONSTRAINT users_supabase_user_id_key UNIQUE (supabase_user_id);
        RAISE NOTICE 'Added unique constraint on supabase_user_id';
    END IF;
END $$;

-- Create clean Supabase-only trigger function
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  user_phone_number TEXT;
  user_role TEXT;
  user_full_name TEXT;
BEGIN
  -- Extract data from Supabase auth metadata
  user_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', '');
  user_phone_number := COALESCE(NEW.raw_user_meta_data->>'phone_number', NEW.phone);
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'sales_agent');
  
  -- Validate role
  IF user_role NOT IN ('sales_agent', 'vendor', 'admin', 'customer') THEN
    user_role := 'sales_agent';
  END IF;
  
  -- Validate required fields
  IF NEW.email IS NULL OR NEW.email = '' THEN
    RAISE EXCEPTION 'Email is required';
  END IF;
  
  IF user_full_name IS NULL OR user_full_name = '' THEN
    RAISE EXCEPTION 'Full name is required';
  END IF;
  
  -- Insert user profile
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
    user_full_name,
    user_phone_number,
    user_role::user_role_enum,
    NEW.email_confirmed_at IS NOT NULL OR NEW.phone_confirmed_at IS NOT NULL,
    true,
    NOW(),
    NOW()
  );
  
  RAISE LOG 'Successfully created user profile for: %', NEW.email;
  RETURN NEW;
  
EXCEPTION
  WHEN unique_violation THEN
    -- Handle duplicate user gracefully
    RAISE LOG 'User already exists: % (supabase_user_id: %)', NEW.email, NEW.id;
    RETURN NEW;
  WHEN OTHERS THEN
    -- Log detailed error and re-raise
    RAISE LOG 'Error creating user profile for %: % (SQLSTATE: %)', NEW.email, SQLERRM, SQLSTATE;
    RAISE EXCEPTION 'Failed to create user profile: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create clean metadata update function
CREATE OR REPLACE FUNCTION handle_user_metadata_update()
RETURNS TRIGGER AS $$
DECLARE
  user_phone_number TEXT;
  user_full_name TEXT;
BEGIN
  -- Extract updated data
  user_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', OLD.raw_user_meta_data->>'full_name', '');
  user_phone_number := COALESCE(NEW.raw_user_meta_data->>'phone_number', NEW.phone);
  
  -- Update user profile
  UPDATE public.users SET
    email = NEW.email,
    full_name = user_full_name,
    phone_number = user_phone_number,
    is_verified = NEW.email_confirmed_at IS NOT NULL OR NEW.phone_confirmed_at IS NOT NULL,
    updated_at = NOW()
  WHERE supabase_user_id = NEW.id;
  
  RAISE LOG 'Updated user profile for: %', NEW.email;
  RETURN NEW;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'Error updating user profile for %: %', NEW.email, SQLERRM;
    RETURN NEW; -- Don't fail the auth operation
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate triggers
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

CREATE TRIGGER on_auth_user_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_user_metadata_update();

-- Test the setup with a dry run
DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
    test_email TEXT := 'test_' || extract(epoch from now()) || '@example.com';
BEGIN
    -- Test direct insert to validate schema
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
        test_user_id,
        test_user_id,
        test_email,
        'Test User',
        '+60123456789',
        'sales_agent'::user_role_enum,
        false,
        true,
        NOW(),
        NOW()
    );
    
    RAISE NOTICE 'Schema validation successful - user profile can be created';
    
    -- Clean up test data
    DELETE FROM public.users WHERE id = test_user_id;
    RAISE NOTICE 'Test cleanup completed';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Schema validation failed: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
        RAISE EXCEPTION 'Database schema issue: %', SQLERRM;
END $$;
