-- Fix trigger permissions and function issues
-- The trigger exists but can't insert into auth.users table directly

-- 1. Drop existing triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;

-- 2. Create a fixed trigger function with proper permissions
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
    RAISE LOG 'Email is required for user creation';
    RETURN NEW;
  END IF;
  
  IF user_full_name IS NULL OR user_full_name = '' THEN
    user_full_name := 'User'; -- Fallback name
  END IF;
  
  -- Log what we're trying to insert
  RAISE LOG 'Creating user profile: email=%, full_name=%, phone=%, role=%', 
    NEW.email, user_full_name, user_phone_number, user_role;
  
  -- Insert user profile with explicit error handling
  BEGIN
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
    
  EXCEPTION
    WHEN unique_violation THEN
      RAISE LOG 'User profile already exists: % (supabase_user_id: %)', NEW.email, NEW.id;
    WHEN invalid_text_representation THEN
      RAISE LOG 'Invalid role value: %, defaulting to sales_agent for user: %', user_role, NEW.email;
      -- Try again with default role
      INSERT INTO public.users (
        id, supabase_user_id, email, full_name, phone_number, role, is_verified, is_active, created_at, updated_at
      ) VALUES (
        NEW.id, NEW.id, NEW.email, user_full_name, user_phone_number, 'sales_agent'::user_role_enum, 
        NEW.email_confirmed_at IS NOT NULL OR NEW.phone_confirmed_at IS NOT NULL, true, NOW(), NOW()
      );
    WHEN OTHERS THEN
      RAISE LOG 'Error creating user profile for %: % (SQLSTATE: %)', NEW.email, SQLERRM, SQLSTATE;
      -- Don't re-raise the exception to avoid breaking auth
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create metadata update function
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

-- 4. Grant necessary permissions to the functions
GRANT USAGE ON SCHEMA public TO postgres;
GRANT ALL ON public.users TO postgres;

-- 5. Recreate triggers
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

CREATE TRIGGER on_auth_user_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_user_metadata_update();

-- 6. Test the fixed trigger
DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
    test_email TEXT := 'trigger_test_' || extract(epoch from now()) || '@example.com';
    test_metadata JSONB := '{"full_name": "Trigger Test User", "phone_number": "+60123456789", "role": "sales_agent"}';
    result_count INTEGER;
BEGIN
    RAISE NOTICE 'Testing fixed trigger function...';
    
    -- Simulate auth.users insert (this should trigger our function)
    INSERT INTO auth.users (
        id,
        email,
        raw_user_meta_data,
        email_confirmed_at,
        created_at,
        updated_at
    ) VALUES (
        test_user_id,
        test_email,
        test_metadata,
        NOW(), -- Mark as confirmed
        NOW(),
        NOW()
    );
    
    -- Wait a moment for trigger to execute
    PERFORM pg_sleep(1);
    
    -- Check if profile was created
    SELECT COUNT(*) INTO result_count
    FROM public.users 
    WHERE supabase_user_id = test_user_id;
    
    IF result_count > 0 THEN
        RAISE NOTICE '✅ SUCCESS: User profile was created by fixed trigger!';
        
        -- Show the created profile
        RAISE NOTICE 'Profile details:';
        PERFORM (
            SELECT RAISE(NOTICE, 'ID: %, Email: %, Name: %, Phone: %, Role: %', 
                id, email, full_name, phone_number, role)
            FROM public.users 
            WHERE supabase_user_id = test_user_id
        );
        
    ELSE
        RAISE NOTICE '❌ FAILED: User profile was still NOT created by trigger';
    END IF;
    
    -- Clean up test data
    DELETE FROM public.users WHERE supabase_user_id = test_user_id;
    DELETE FROM auth.users WHERE id = test_user_id;
    RAISE NOTICE 'Test cleanup completed';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error during trigger test: %', SQLERRM;
        -- Try to clean up anyway
        BEGIN
            DELETE FROM public.users WHERE supabase_user_id = test_user_id;
            DELETE FROM auth.users WHERE id = test_user_id;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Cleanup also failed: %', SQLERRM;
        END;
END $$;

-- 7. Create profiles for existing users who don't have them
DO $$
DECLARE
    user_record RECORD;
    created_count INTEGER := 0;
BEGIN
    RAISE NOTICE 'Creating profiles for existing users without profiles...';
    
    FOR user_record IN 
        SELECT au.id, au.email, au.raw_user_meta_data, au.phone, au.email_confirmed_at, au.phone_confirmed_at
        FROM auth.users au
        LEFT JOIN public.users pu ON au.id = pu.supabase_user_id
        WHERE pu.id IS NULL
    LOOP
        BEGIN
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
                user_record.id,
                user_record.id,
                user_record.email,
                COALESCE(user_record.raw_user_meta_data->>'full_name', 'User'),
                COALESCE(user_record.raw_user_meta_data->>'phone_number', user_record.phone),
                COALESCE(user_record.raw_user_meta_data->>'role', 'sales_agent')::user_role_enum,
                user_record.email_confirmed_at IS NOT NULL OR user_record.phone_confirmed_at IS NOT NULL,
                true,
                NOW(),
                NOW()
            );
            
            created_count := created_count + 1;
            RAISE NOTICE 'Created profile for: %', user_record.email;
            
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Failed to create profile for %: %', user_record.email, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE '✅ Created % user profiles for existing auth users', created_count;
END $$;
