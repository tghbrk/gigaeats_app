# Manual Supabase Configuration for Email Verification

## URGENT: Manual Configuration Required

The GigaEats email verification issue requires manual configuration in the Supabase dashboard. Please follow these exact steps:

## Step 1: Configure Redirect URLs

1. **Go to Supabase Dashboard**: https://supabase.com/dashboard
2. **Select Project**: `giga-eats` (ID: abknoalhfltlhhdbclpv)
3. **Navigate to**: Authentication → URL Configuration

### Site URL Configuration
Set the **Site URL** to:
```
gigaeats://auth/callback
```

### Additional Redirect URLs
Add these **exact URLs** to the Additional Redirect URLs list:
```
gigaeats://auth/callback
https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/callback
http://localhost:3000/auth/callback
https://localhost:3000/auth/callback
```

## Step 2: Configure Email Templates

1. **Navigate to**: Authentication → Email Templates
2. **Select**: "Confirm signup" template

### Email Template Content
Replace the template content with:
```html
<h2>Welcome to GigaEats!</h2>
<p>Thank you for signing up with GigaEats. To complete your registration and start ordering delicious meals for your organization, please verify your email address.</p>
<p><a href="{{ .ConfirmationURL }}">Verify Email Address</a></p>
<p>If the button doesn't work, copy and paste this link into your browser:</p>
<p>{{ .ConfirmationURL }}</p>
<p>This email was sent to you because you signed up for GigaEats. If you didn't sign up, please ignore this email.</p>
```

### URL Path Configuration
Set the **URL Path** to:
```
/auth/v1/verify?token={{ .TokenHash }}&type=signup
```

**IMPORTANT**: Do NOT include `redirect_to` in the URL path as it will be automatically added by the `emailRedirectTo` parameter in the signup call, preventing duplicate parameters.

## Step 3: Verify Configuration

After making these changes:

1. **Save all configurations**
2. **Test with a new user registration**
3. **Check that email verification links use the new format**

## Expected Email Link Format

After configuration, email verification links should look like:
```
https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/verify?token=XXXXX&type=signup&redirect_to=gigaeats://auth/callback
```

**Note**: The `redirect_to` parameter is automatically added by Supabase when the `emailRedirectTo` parameter is used in the signup call.

## Verification Steps

1. Register a new test user
2. Check the verification email
3. Verify the link format matches the expected format above
4. Click the link and confirm it opens the GigaEats app
5. Verify the success screen appears

## Troubleshooting

If issues persist after configuration:

1. **Clear browser cache** and try again
2. **Wait 5-10 minutes** for configuration to propagate
3. **Test with a fresh email address**
4. **Check app logs** for deep link handling

## Configuration Status

- ✅ Flutter app deep link handling implemented
- ✅ Android intent filters configured
- ✅ iOS URL schemes configured
- ⏳ **PENDING**: Supabase dashboard configuration (manual step required)

## Next Steps

Once the Supabase configuration is complete:
1. Test the email verification flow
2. Verify successful deep link handling
3. Confirm users can sign in after verification
4. Update documentation with final results
