-- Debug script to check user profile creation and trigger status

-- 1. Check if the trigger functions exist
SELECT 
    proname as function_name,
    prosrc as function_body
FROM pg_proc 
WHERE proname IN ('handle_new_user', 'handle_user_metadata_update');

-- 2. Check if triggers are active
SELECT 
    trigger_name,
    event_manipulation,
    action_statement,
    action_timing
FROM information_schema.triggers 
WHERE trigger_schema = 'auth' 
AND event_object_table = 'users';

-- 3. Check recent users in auth.users
SELECT 
    id,
    email,
    created_at,
    email_confirmed_at,
    raw_user_meta_data
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 4. Check recent users in public.users
SELECT 
    id,
    supabase_user_id,
    email,
    full_name,
    phone_number,
    role,
    created_at
FROM public.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 5. Check for users in auth.users but not in public.users (trigger failed)
SELECT 
    au.id,
    au.email,
    au.created_at as auth_created,
    pu.id as profile_id
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.supabase_user_id
WHERE pu.id IS NULL
ORDER BY au.created_at DESC
LIMIT 5;

-- 6. Test the trigger function manually with sample data
DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
    test_email TEXT := 'manual_test_' || extract(epoch from now()) || '@example.com';
    test_metadata JSONB := '{"full_name": "Manual Test User", "phone_number": "+60123456789", "role": "sales_agent"}';
    result_count INTEGER;
BEGIN
    RAISE NOTICE 'Testing manual user creation...';
    
    -- Simulate auth.users insert
    INSERT INTO auth.users (
        id,
        email,
        raw_user_meta_data,
        created_at,
        updated_at
    ) VALUES (
        test_user_id,
        test_email,
        test_metadata,
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
        RAISE NOTICE 'SUCCESS: User profile was created by trigger';
        
        -- Show the created profile
        SELECT 
            id, email, full_name, phone_number, role
        FROM public.users 
        WHERE supabase_user_id = test_user_id;
        
    ELSE
        RAISE NOTICE 'FAILED: User profile was NOT created by trigger';
    END IF;
    
    -- Clean up test data
    DELETE FROM public.users WHERE supabase_user_id = test_user_id;
    DELETE FROM auth.users WHERE id = test_user_id;
    RAISE NOTICE 'Test data cleaned up';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error during manual test: %', SQLERRM;
        -- Try to clean up anyway
        DELETE FROM public.users WHERE supabase_user_id = test_user_id;
        DELETE FROM auth.users WHERE id = test_user_id;
END $$;
