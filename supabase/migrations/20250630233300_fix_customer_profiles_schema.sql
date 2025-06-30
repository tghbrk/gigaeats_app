-- Fix customer_profiles table schema
-- Add missing is_verified column and remove date_of_birth column
-- This resolves the PostgrestException: "Could not find the 'is_verified' column"

-- Add the missing is_verified column
ALTER TABLE customer_profiles 
ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;

-- Remove the date_of_birth column as it serves no functional purpose
ALTER TABLE customer_profiles 
DROP COLUMN IF EXISTS date_of_birth;

-- Remove gender column as well since it's not used in the Flutter models
ALTER TABLE customer_profiles 
DROP COLUMN IF EXISTS gender;

-- Update the updated_at timestamp for any existing records
UPDATE customer_profiles SET updated_at = NOW() WHERE updated_at IS NOT NULL;

-- Add comment to document the schema fix
COMMENT ON COLUMN customer_profiles.is_verified IS 'Indicates if the customer profile has been verified';

-- Create index on is_verified for better query performance
CREATE INDEX IF NOT EXISTS idx_customer_profiles_verified 
ON customer_profiles(is_verified) WHERE is_verified = TRUE;
