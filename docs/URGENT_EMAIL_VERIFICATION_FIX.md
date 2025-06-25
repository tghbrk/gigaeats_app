# URGENT: Fix Email Verification Duplicate Redirect Parameters

## Problem
The email verification link contains duplicate `redirect_to` parameters:
```
https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/verify?token=...&type=signup&redirect_to=gigaeats://auth/callback&redirect_to=gigaeats://auth/callback
```

## Root Cause
The `redirect_to` parameter is being added twice:
1. Once by the email template URL path configuration
2. Once by the `emailRedirectTo` parameter in the Flutter signup call

## Immediate Fix Required

### Step 1: Update Supabase Email Template (MANUAL)
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select project: `giga-eats` (ID: abknoalhfltlhhdbclpv)
3. Navigate to: **Authentication** → **Email Templates**
4. Select: **Confirm signup** template
5. In the **URL Path** field, change from:
   ```
   /auth/v1/verify?token={{ .TokenHash }}&type=signup&redirect_to=gigaeats://auth/callback
   ```
   To:
   ```
   /auth/v1/verify?token={{ .TokenHash }}&type=signup
   ```
6. **Save** the template

### Step 2: Verify Redirect URLs Configuration
Ensure these URLs are configured in **Authentication** → **URL Configuration**:

**Site URL:**
```
gigaeats://auth/callback
```

**Additional Redirect URLs:**
```
gigaeats://auth/callback
https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/callback
http://localhost:3000/auth/callback
https://localhost:3000/auth/callback
```

## Why This Fixes the Issue

- The Flutter app calls `signUp()` with `emailRedirectTo: 'gigaeats://auth/callback'`
- Supabase automatically appends `&redirect_to=gigaeats://auth/callback` to the verification URL
- If the email template URL path also includes `redirect_to`, it creates duplicates
- Removing it from the template prevents duplication

## Expected Result

After the fix, email verification links will have the correct format:
```
https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/verify?token=...&type=signup&redirect_to=gigaeats://auth/callback
```

## Testing Steps

1. Register a new test user
2. Check the verification email
3. Verify the link has only one `redirect_to` parameter
4. Click the link and confirm it opens the GigaEats app
5. Verify successful email verification

## Code Changes Made

The following files have been updated to reflect the correct configuration:
- `scripts/configure_supabase_auth.dart`
- `scripts/supabase_config_instructions.md`
- `docs/SUPABASE_EMAIL_VERIFICATION_SETUP.md`
- `docs/EMAIL_VERIFICATION_FIX_SUMMARY.md`

## Next Steps

1. **IMMEDIATE**: Apply the manual Supabase configuration above
2. **TEST**: Register a new user and verify the email link works
3. **MONITOR**: Check that existing users can also verify their emails
4. **DOCUMENT**: Update any additional documentation as needed
