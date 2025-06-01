# Flutter Codebase Cleanup Plan - Remove Firebase Dependencies

Since you're using Supabase-only for auth and backend, we need to remove all Firebase-related code and dependencies.

## 🗑️ Files to Remove Completely

### 1. Firebase Configuration Files
- `lib/core/config/firebase_config.dart` - Remove completely
- `lib/firebase_options.dart` - Remove if it exists
- `supabase/functions/verify-firebase-token/` - Remove entire directory

### 2. Firebase Documentation
- `docs/SUPABASE-IMPLEMENTATION.md` - Remove (it's about Firebase+Supabase hybrid)
- `docs/PHASE1_SETUP_GUIDE.md` - Remove Firebase sections
- `docs/phase1-supabase.md` - Remove Firebase references

### 3. Test Files
- `test/integration/supabase_integration_test.dart` - Remove Firebase imports

## 🔧 Files to Update

### 1. pubspec.yaml
Remove these Firebase dependencies:
```yaml
# REMOVE THESE:
firebase_core: ^3.13.1
firebase_auth: ^5.5.4
firebase_messaging: ^15.1.8
firebase_analytics: ^11.3.8
firebase_crashlytics: ^4.1.8
firebase_performance: ^0.10.0+8
firebase_remote_config: ^5.1.8
firebase_storage: ^12.3.8
```

### 2. main.dart
Remove Firebase initialization:
```dart
// REMOVE Firebase initialization code
// Keep only Supabase initialization
```

### 3. Auth Provider
Update `lib/presentation/providers/auth_provider.dart`:
- Remove any Firebase auth references
- Keep only Supabase auth service

### 4. User Model
Update `lib/data/models/user.dart`:
- Remove `firebase_uid` field completely
- Keep only `supabase_user_id`

### 5. Auth Service
Update `lib/data/services/supabase_auth_service.dart`:
- Remove any Firebase token handling
- Remove Firebase-related imports

## 🔄 Database Schema Updates

The SQL script `complete_supabase_only_fix.sql` will:
1. Remove `firebase_uid` columns from all tables
2. Update foreign key relationships to use `supabase_user_id`
3. Fix the auth trigger to work with Supabase-only
4. Remove Firebase-related constraints

## 📋 Step-by-Step Execution Plan

### Step 1: Apply Database Fix
1. Open Supabase SQL Editor
2. Run `complete_supabase_only_fix.sql`
3. Verify no errors

### Step 2: Update pubspec.yaml
1. Remove all Firebase dependencies
2. Run `flutter pub get`

### Step 3: Remove Firebase Files
1. Delete `lib/core/config/firebase_config.dart`
2. Delete `supabase/functions/verify-firebase-token/`
3. Delete Firebase documentation files

### Step 4: Update main.dart
1. Remove Firebase initialization
2. Keep only Supabase initialization

### Step 5: Update User Model
1. Remove `firebase_uid` field
2. Update JSON serialization
3. Run `flutter packages pub run build_runner build`

### Step 6: Update Auth Service
1. Remove Firebase imports
2. Remove Firebase token handling
3. Update user creation to use only Supabase

### Step 7: Test
1. Run the app
2. Test signup functionality
3. Verify user creation works

## 🎯 Expected Outcome

After cleanup:
- ✅ Pure Supabase authentication
- ✅ No Firebase dependencies
- ✅ Smaller app bundle size
- ✅ Simplified codebase
- ✅ Working signup without 500 errors

## 🚨 Important Notes

1. **Backup First**: Make sure you have a backup of your current code
2. **Test Thoroughly**: Test all auth flows after cleanup
3. **Update Documentation**: Update any remaining docs to reflect Supabase-only setup
4. **Environment Variables**: Remove any Firebase environment variables

## 🔧 Quick Commands

```bash
# Remove Firebase dependencies
flutter pub remove firebase_core firebase_auth firebase_messaging

# Clean and get dependencies
flutter clean
flutter pub get

# Rebuild generated files
flutter packages pub run build_runner build --delete-conflicting-outputs

# Test the app
flutter run
```

This cleanup will resolve the 500 error and give you a clean Supabase-only setup.
