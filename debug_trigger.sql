-- Debug script to check the current state of the trigger and identify issues

-- Check the current trigger function
SELECT pg_get_functiondef(oid) as function_definition
FROM pg_proc 
WHERE proname = 'handle_new_user';

-- Check if there are any triggers currently active
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'auth' AND event_object_table = 'users';

-- Check if firebase_uid column exists and any constraints
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'users' AND column_name LIKE '%firebase%';

-- Check for any check constraints that might be failing
SELECT conname, pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conrelid = 'public.users'::regclass AND contype = 'c';

-- Test the trigger function manually with sample data
DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
    test_email TEXT := 'test@example.com';
    test_metadata JSONB := '{"full_name": "Test User", "phone_number": "+60123456789", "role": "sales_agent"}';
BEGIN
    RAISE NOTICE 'Testing trigger function with sample data...';
    RAISE NOTICE 'User ID: %', test_user_id;
    RAISE NOTICE 'Email: %', test_email;
    RAISE NOTICE 'Metadata: %', test_metadata;
    
    -- Try to insert directly to see what fails
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
            test_user_id,
            test_user_id,
            test_email,
            COALESCE(test_metadata->>'full_name', ''),
            COALESCE(test_metadata->>'phone_number', NULL),
            COALESCE(test_metadata->>'role', 'sales_agent')::user_role_enum,
            false,
            true,
            NOW(),
            NOW()
        );
        RAISE NOTICE 'Direct insert successful!';
        
        -- Clean up test data
        DELETE FROM public.users WHERE id = test_user_id;
        RAISE NOTICE 'Test data cleaned up';
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Direct insert failed: %', SQLERRM;
    END;
END $$;
