-- Fix potential constraint issues that might be causing the 500 error

-- First, check if there's a constraint requiring firebase_uid
-- If so, we need to either add the column or remove the constraint

-- Check if firebase_uid column exists
DO $$
BEGIN
    -- Try to add firebase_uid column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'firebase_uid'
    ) THEN
        -- Add firebase_uid column as nullable for backward compatibility
        ALTER TABLE public.users ADD COLUMN firebase_uid TEXT;
        RAISE NOTICE 'Added firebase_uid column';
    ELSE
        RAISE NOTICE 'firebase_uid column already exists';
    END IF;
END $$;

-- Drop any constraint that might require firebase_uid to be NOT NULL
DO $$
BEGIN
    -- Check if there's a constraint requiring firebase_uid or supabase_user_id
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conrelid = 'public.users'::regclass 
        AND conname = 'check_user_auth_id'
    ) THEN
        ALTER TABLE public.users DROP CONSTRAINT check_user_auth_id;
        RAISE NOTICE 'Dropped check_user_auth_id constraint';
    END IF;
END $$;

-- Create a more flexible constraint that allows either firebase_uid or supabase_user_id
ALTER TABLE public.users ADD CONSTRAINT check_user_auth_id_flexible 
  CHECK (firebase_uid IS NOT NULL OR supabase_user_id IS NOT NULL);

-- Update the trigger function to handle the firebase_uid column properly
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
  
  -- Insert with proper error handling
  INSERT INTO public.users (
    id,
    supabase_user_id,
    firebase_uid,
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
    NULL, -- firebase_uid is NULL for Supabase auth users
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
  WHEN unique_violation THEN
    -- Handle duplicate email or other unique constraint violations
    RAISE LOG 'Unique constraint violation in handle_new_user: %', SQLERRM;
    -- Don't re-raise, just log and continue
    RETURN NEW;
  WHEN OTHERS THEN
    -- Log the error with more details
    RAISE LOG 'Error in handle_new_user trigger: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
    RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the function with a sample insert
DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
    test_email TEXT := 'test_' || extract(epoch from now()) || '@example.com';
BEGIN
    -- Simulate what the trigger would do
    INSERT INTO public.users (
        id,
        supabase_user_id,
        firebase_uid,
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
        NULL,
        test_email,
        'Test User',
        '+60123456789',
        'sales_agent'::user_role_enum,
        false,
        true,
        NOW(),
        NOW()
    );
    
    RAISE NOTICE 'Test insert successful for user: %', test_email;
    
    -- Clean up
    DELETE FROM public.users WHERE id = test_user_id;
    RAISE NOTICE 'Test data cleaned up';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Test insert failed: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
END $$;
