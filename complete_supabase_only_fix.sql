-- Complete Supabase-only fix - Remove all Firebase dependencies
-- This script completely removes Firebase references and sets up pure Supabase auth

-- 1. Drop existing triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;

-- 2. Remove all Firebase-related constraints
DO $$
BEGIN
    -- Drop Firebase auth constraints
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

-- 3. Remove firebase_uid column completely (we don't need it)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'firebase_uid'
    ) THEN
        -- First drop any foreign key constraints that reference firebase_uid
        ALTER TABLE public.user_profiles DROP CONSTRAINT IF EXISTS user_profiles_firebase_uid_fkey;
        ALTER TABLE public.vendors DROP CONSTRAINT IF EXISTS vendors_firebase_uid_fkey;
        ALTER TABLE public.user_fcm_tokens DROP CONSTRAINT IF EXISTS user_fcm_tokens_firebase_uid_fkey;
        
        -- Drop indexes
        DROP INDEX IF EXISTS idx_users_firebase_uid;
        DROP INDEX IF EXISTS idx_user_profiles_firebase_uid;
        DROP INDEX IF EXISTS idx_vendors_firebase_uid;
        DROP INDEX IF EXISTS idx_fcm_tokens_firebase_uid;
        
        -- Drop the column
        ALTER TABLE public.users DROP COLUMN firebase_uid;
        RAISE NOTICE 'Removed firebase_uid column and related constraints';
    END IF;
END $$;

-- 4. Update related tables to remove firebase_uid references
DO $$
BEGIN
    -- Update user_profiles table
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_profiles' 
        AND column_name = 'firebase_uid'
    ) THEN
        ALTER TABLE public.user_profiles DROP COLUMN firebase_uid;
        RAISE NOTICE 'Removed firebase_uid from user_profiles';
    END IF;
    
    -- Update vendors table
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'vendors' 
        AND column_name = 'firebase_uid'
    ) THEN
        ALTER TABLE public.vendors DROP COLUMN firebase_uid;
        RAISE NOTICE 'Removed firebase_uid from vendors';
    END IF;
    
    -- Update user_fcm_tokens table
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_fcm_tokens' 
        AND column_name = 'firebase_uid'
    ) THEN
        -- Add supabase_user_id column if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'user_fcm_tokens' 
            AND column_name = 'supabase_user_id'
        ) THEN
            ALTER TABLE public.user_fcm_tokens ADD COLUMN supabase_user_id UUID REFERENCES auth.users(id);
        END IF;
        
        ALTER TABLE public.user_fcm_tokens DROP COLUMN firebase_uid;
        RAISE NOTICE 'Updated user_fcm_tokens to use supabase_user_id';
    END IF;
END $$;

-- 5. Ensure supabase_user_id is properly configured
ALTER TABLE public.users ALTER COLUMN supabase_user_id SET NOT NULL;

-- Add unique constraint on supabase_user_id if it doesn't exist
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

-- 6. Create clean Supabase-only trigger function
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
    RAISE EXCEPTION 'Email is required for user creation';
  END IF;
  
  IF user_full_name IS NULL OR user_full_name = '' THEN
    user_full_name := 'User'; -- Fallback name
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
  
  RAISE LOG 'Successfully created user profile for: % (ID: %)', NEW.email, NEW.id;
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

-- 7. Create metadata update function
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
  
  RAISE LOG 'Updated user profile for: % (ID: %)', NEW.email, NEW.id;
  RETURN NEW;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'Error updating user profile for %: %', NEW.email, SQLERRM;
    RETURN NEW; -- Don't fail the auth operation
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Recreate triggers
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

CREATE TRIGGER on_auth_user_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_user_metadata_update();

-- 9. Test the setup
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
    
    RAISE NOTICE 'SUCCESS: Schema validation passed - user profile can be created';
    
    -- Clean up test data
    DELETE FROM public.users WHERE id = test_user_id;
    RAISE NOTICE 'Test cleanup completed';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'FAILED: Schema validation failed: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
        RAISE EXCEPTION 'Database schema issue: %', SQLERRM;
END $$;
