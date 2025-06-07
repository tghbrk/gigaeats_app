# GigaEats Phase 1 Setup Guide

This guide provides step-by-step instructions to set up the Phase 1 implementation of GigaEats with Firebase Auth + Supabase backend integration.

## Prerequisites

- Flutter SDK (3.8.0 or higher)
- Node.js (18 or higher) for Firebase Functions
- Firebase CLI
- Supabase CLI
- Git

## 1. Firebase Setup

### 1.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named `gigaeats`
3. Enable Google Analytics (optional)

### 1.2 Configure Firebase Authentication

1. In Firebase Console, go to **Authentication** > **Sign-in method**
2. Enable the following providers:
   - **Email/Password**: Enable
   - **Phone**: Enable (for Malaysian numbers)
3. Go to **Authentication** > **Settings** > **Authorized domains**
4. Add your domains (localhost for development)

### 1.3 Set up Firebase Functions

```bash
# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project root
firebase init functions

# Select your project: gigaeats
# Choose TypeScript
# Install dependencies: Yes
```

### 1.4 Deploy Firebase Functions

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Deploy functions
firebase deploy --only functions
```

### 1.5 Configure Firebase Environment Variables

In Firebase Console, go to **Project Settings** > **Service accounts**:
1. Generate a new private key
2. Save the JSON file securely
3. Set environment variables in Firebase Functions:

```bash
firebase functions:config:set \
  firebase.project_id="gigaeats" \
  firebase.client_email="your-service-account-email" \
  firebase.private_key="your-private-key"
```

## 2. Supabase Setup

### 2.1 Create Supabase Project

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Create a new project named `giga-eats`
3. Choose region: `Asia Southeast (Singapore)`
4. Set a strong database password

### 2.2 Configure Third-Party Authentication

1. In Supabase Dashboard, go to **Authentication** > **Providers**
2. Disable **Supabase Auth** (we're using Firebase)
3. Enable **Third Party Auth**
4. Configure Firebase as provider:
   - Provider: Firebase
   - Project ID: `gigaeats`
   - Add your Firebase project configuration

### 2.3 Set up Database

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Run migrations
supabase db reset

# This will apply all migrations and seed data
```

### 2.4 Configure Environment Variables

In Supabase Dashboard, go to **Settings** > **API**:
1. Copy your project URL and anon key
2. Update `lib/core/config/supabase_config.dart` with your values

For Edge Functions, set these environment variables:
```bash
supabase secrets set FIREBASE_PROJECT_ID=gigaeats
supabase secrets set FIREBASE_CLIENT_EMAIL=your-service-account-email
supabase secrets set FIREBASE_PRIVATE_KEY="your-private-key"
supabase secrets set SUPABASE_URL=your-supabase-url
supabase secrets set SERVICE_ROLE_KEY=your-service-role-key
```

## 3. Flutter App Setup

### 3.1 Install Dependencies

```bash
# Install Flutter dependencies
flutter pub get

# Generate code for models
flutter packages pub run build_runner build
```

### 3.2 Configure Firebase for Flutter

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your Flutter app
flutterfire configure --project=gigaeats
```

This will update `lib/firebase_options.dart` with your project configuration.

### 3.3 Update Configuration Files

1. Update `lib/core/config/firebase_config.dart`:
   - Set your Firebase project IDs
   - Configure regions and settings

2. Update `lib/core/config/supabase_config.dart`:
   - Set your Supabase URLs and keys
   - Configure bucket names

## 4. Testing the Setup

### 4.1 Test Firebase Functions

```bash
# Test the setUserRole function
firebase functions:shell

# In the shell:
setUserRole({uid: 'test-uid', role: 'sales_agent'})
```

### 4.2 Test Supabase Connection

```bash
# Test database connection
supabase db ping

# Test Edge Functions
supabase functions serve verify-firebase-token
```

### 4.3 Test Flutter App

```bash
# Run the app
flutter run

# Test authentication flow:
# 1. Register a new user
# 2. Verify email
# 3. Set user role
# 4. Check Supabase data sync
```

## 5. Verification Checklist

### ✅ Firebase Setup
- [ ] Project created and configured
- [ ] Authentication providers enabled
- [ ] Functions deployed successfully
- [ ] Custom claims working
- [ ] Phone verification configured

### ✅ Supabase Setup
- [ ] Project created and linked
- [ ] Database migrations applied
- [ ] Seed data loaded
- [ ] RLS policies enabled
- [ ] Storage buckets created
- [ ] Edge Functions deployed

### ✅ Integration
- [ ] Firebase tokens verified in Supabase
- [ ] User data syncs between platforms
- [ ] RLS policies work with Firebase JWT
- [ ] Phone verification works for +60 numbers
- [ ] File uploads work with proper permissions

### ✅ Flutter App
- [ ] App builds and runs successfully
- [ ] Authentication flow works
- [ ] Role-based navigation works
- [ ] Data loads from Supabase
- [ ] Real-time updates work

## 6. Common Issues and Solutions

### Issue: Firebase Functions deployment fails
**Solution**: Ensure you have the correct Node.js version (18+) and proper permissions.

### Issue: Supabase RLS policies block access
**Solution**: Check that Firebase JWT tokens are properly set and contain the required claims.

### Issue: Phone verification doesn't work
**Solution**: Verify that Firebase Phone Auth is enabled and Malaysian numbers (+60) are properly formatted.

### Issue: File uploads fail
**Solution**: Check storage bucket policies and ensure Firebase UID is correctly extracted from JWT.

## 7. Next Steps

After completing Phase 1 setup:

1. **Test all user roles**: Admin, Sales Agent, Vendor
2. **Verify data flow**: Registration → Authentication → Data Sync
3. **Test permissions**: Ensure users can only access their own data
4. **Performance testing**: Check query performance with RLS enabled
5. **Security audit**: Verify all endpoints are properly secured

## 8. Support

For issues or questions:
- Check the Firebase Console logs
- Review Supabase Dashboard logs
- Use Flutter debug console for client-side issues
- Refer to the project documentation in `/docs/`

---

**Phase 1 Implementation Complete!** 🎉

You now have a fully functional Firebase Auth + Supabase backend integration with:
- ✅ Custom claims for user roles
- ✅ Row Level Security with Firebase JWT
- ✅ Phone verification for Malaysian numbers
- ✅ Secure file storage with proper permissions
- ✅ Comprehensive seed data for testing
- ✅ Real-time data synchronization
