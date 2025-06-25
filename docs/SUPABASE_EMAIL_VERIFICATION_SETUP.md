# Supabase Email Verification Setup for GigaEats Flutter App

This document provides step-by-step instructions to configure Supabase email verification for the GigaEats Flutter app.

## Problem Description

Users were experiencing email verification issues where clicking the verification link redirected to an error page with "otp_expired" and "access_denied" errors. This was caused by incorrect redirect URL configuration in Supabase.

## Solution Overview

The solution involves:
1. Configuring proper redirect URLs in Supabase dashboard
2. Setting up deep link handling in the Flutter app
3. Updating email templates to use correct redirect URLs

## Step 1: Configure Supabase Redirect URLs

### Access Supabase Dashboard
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select the GigaEats project (`abknoalhfltlhhdbclpv`)
3. Navigate to **Authentication** → **URL Configuration**

### Configure Site URL
Set the **Site URL** to:
```
gigaeats://auth/callback
```

### Configure Additional Redirect URLs
Add the following URLs to the **Additional Redirect URLs** list:

```
gigaeats://auth/callback
https://abknoalhfltlhhdbclpv.supabase.co/auth/v1/callback
http://localhost:3000/auth/callback
https://localhost:3000/auth/callback
```

## Step 2: Update Email Templates

### Access Email Templates
1. In Supabase Dashboard, go to **Authentication** → **Email Templates**
2. Select **Confirm signup** template

### Update Confirmation Template
Replace the existing template with:

```html
<h2>Welcome to GigaEats!</h2>
<p>Thank you for signing up with GigaEats. To complete your registration and start ordering delicious meals for your organization, please verify your email address.</p>
<p><a href="{{ .ConfirmationURL }}">Verify Email Address</a></p>
<p>If the button doesn't work, copy and paste this link into your browser:</p>
<p>{{ .ConfirmationURL }}</p>
<p>This email was sent to you because you signed up for GigaEats. If you didn't sign up, please ignore this email.</p>
```

### Update URL Path
In the **URL Path** section, set:
```
/auth/v1/verify?token={{ .TokenHash }}&type=signup
```

**IMPORTANT**: Do NOT include `redirect_to` in the URL path. The redirect URL is automatically added by Supabase when the `emailRedirectTo` parameter is used in the signup call. Including it in both places causes duplicate parameters.

## Step 3: Verify Deep Link Configuration

### Android Configuration
The following has been added to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Deep link intent filter for email verification -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https"
          android:host="abknoalhfltlhhdbclpv.supabase.co" />
</intent-filter>

<!-- Custom URL scheme for deep links -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="gigaeats" />
</intent-filter>
```

### iOS Configuration
The following has been added to `ios/Runner/Info.plist`:

```xml
<!-- URL Schemes for deep linking -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>gigaeats.app.auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>gigaeats</string>
        </array>
    </dict>
    <dict>
        <key>CFBundleURLName</key>
        <string>supabase.auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>https</string>
        </array>
    </dict>
</array>
```

## Step 4: Test Email Verification

### Testing Process
1. Register a new user account
2. Check email for verification link
3. Click the verification link
4. Verify that the app opens and shows success message
5. Attempt to sign in with the verified account

### Expected Behavior
- User receives email with verification link
- Clicking link opens the GigaEats app
- App shows "Email Verified!" success screen
- User can successfully sign in after verification

## Troubleshooting

### Common Issues

#### Issue: "otp_expired" error
**Cause**: Email verification link has expired (default: 24 hours)
**Solution**: Request a new verification email

#### Issue: "access_denied" error
**Cause**: Incorrect redirect URL configuration
**Solution**: Verify redirect URLs are correctly configured in Supabase dashboard

#### Issue: Link opens browser instead of app
**Cause**: Deep link configuration not properly set up
**Solution**: Verify AndroidManifest.xml and Info.plist configurations

### Debug Steps
1. Check Supabase dashboard URL configuration
2. Verify deep link intent filters in AndroidManifest.xml
3. Confirm URL schemes in iOS Info.plist
4. Test with fresh email verification request
5. Check app logs for deep link handling

## Security Considerations

- Only add trusted domains to redirect URLs
- Use HTTPS for production redirect URLs
- Validate deep link parameters in the app
- Implement proper error handling for failed verifications

## Additional Notes

- Email verification links expire after 24 hours by default
- Users must verify email before they can sign in
- The app handles both successful verification and error cases
- Deep link service automatically refreshes auth state after verification
