# GigaEats Authentication Flow Test Plan

## Test Environment
- **Platform**: Android Emulator (emulator-5554)
- **App Status**: ✅ Running successfully
- **Supabase**: ✅ Connected and initialized
- **Stripe**: ✅ Initialized
- **Deep Links**: ✅ Service initialized

## Database System Tests ✅ PASSED
**Function Availability:**
- ✅ `create_user_profile_from_auth` - EXISTS
- ✅ `handle_new_user` - EXISTS
- ✅ `create_user_with_role` - EXISTS

**User Role Enum:**
- ✅ `customer` - AVAILABLE
- ✅ `vendor` - AVAILABLE
- ✅ `sales_agent` - AVAILABLE
- ✅ `driver` - AVAILABLE
- ✅ `admin` - AVAILABLE

**Authentication System Status:**
- ✅ Authentication state provider working
- ✅ Router redirecting unauthenticated users to login
- ✅ Deep link service initialized
- ✅ Email verification system configured

## Test Scenarios

### 1. Customer Registration & Login
**Test Steps:**
1. Navigate to registration screen
2. Fill form with customer role
3. Submit registration
4. Verify email verification flow
5. Complete email verification
6. Login with credentials
7. Verify customer dashboard access

**Expected Results:**
- Registration creates user profile in database
- Email verification email sent
- Login successful after verification
- Redirected to customer dashboard

### 2. Vendor Registration & Login
**Test Steps:**
1. Navigate to registration screen
2. Fill form with vendor role
3. Submit registration
4. Verify email verification flow
5. Complete email verification
6. Login with credentials
7. Verify vendor dashboard access

**Expected Results:**
- Registration creates vendor profile
- Email verification works
- Login redirects to vendor dashboard

### 3. Sales Agent Registration & Login
**Test Steps:**
1. Navigate to registration screen
2. Fill form with sales agent role
3. Submit registration
4. Verify email verification flow
5. Complete email verification
6. Login with credentials
7. Verify sales agent dashboard access

**Expected Results:**
- Registration creates sales agent profile
- Email verification works
- Login redirects to sales agent dashboard

### 4. Driver Registration & Login
**Test Steps:**
1. Navigate to registration screen
2. Fill form with driver role
3. Submit registration
4. Verify email verification flow
5. Complete email verification
6. Login with credentials
7. Verify driver dashboard access

**Expected Results:**
- Registration creates driver profile
- Email verification works
- Login redirects to driver dashboard

### 5. Admin Registration & Login
**Test Steps:**
1. Navigate to registration screen
2. Fill form with admin role
3. Submit registration
4. Verify email verification flow
5. Complete email verification
6. Login with credentials
7. Verify admin dashboard access

**Expected Results:**
- Registration creates admin profile
- Email verification works
- Login redirects to admin dashboard

## Test Data
**Test Users:**
- Customer: test-customer@gigaeats.com / TestPass123!
- Vendor: test-vendor@gigaeats.com / TestPass123!
- Sales Agent: test-salesagent@gigaeats.com / TestPass123!
- Driver: test-driver@gigaeats.com / TestPass123!
- Admin: test-admin@gigaeats.com / TestPass123!

## Manual Testing Instructions

### Step 1: Customer Registration Test
1. **Navigate to Registration**: Tap "Create Account" on login screen
2. **Fill Registration Form**:
   - Full Name: "Test Customer"
   - Email: "test-customer-new@gigaeats.com"
   - Phone: "+60123456789"
   - Role: Select "Customer"
   - Password: "TestPass123!"
   - Confirm Password: "TestPass123!"
   - Check Terms & Conditions
3. **Submit Registration**: Tap "Create Account"
4. **Expected Result**:
   - Success message shown
   - Redirected to email verification screen
   - Email sent to test address

### Step 2: Email Verification Test
1. **Check Email**: Look for verification email
2. **Click Verification Link**: Should redirect to app
3. **Expected Result**:
   - App opens with success message
   - User can now login

### Step 3: Login Test
1. **Navigate to Login**: From verification success screen
2. **Enter Credentials**:
   - Email: "test-customer-new@gigaeats.com"
   - Password: "TestPass123!"
3. **Submit Login**: Tap "Sign In"
4. **Expected Result**:
   - Login successful
   - Redirected to customer dashboard

### Step 4: Database Verification
After each test, verify:
1. User record created in `users` table
2. Correct role assigned
3. Profile data populated
4. Email verification status
5. Authentication tokens valid

## Error Scenarios
Test error handling for:
1. Invalid email format
2. Weak passwords
3. Duplicate email registration
4. Network connectivity issues
5. Database connection problems

## Database Security Tests ✅ PASSED
**RLS Policies:**
- ✅ `Users can view own profile` - ACTIVE
- ✅ `Users can update own profile` - ACTIVE
- ✅ `Users can insert own profile` - ACTIVE
- ✅ `Admins can view all users` - ACTIVE
- ✅ `Admins can update all users` - ACTIVE
- ✅ `Admins can insert users` - ACTIVE

**Database Triggers:**
- ✅ `on_auth_user_created` - ENABLED (calls handle_new_user)
- ✅ `on_auth_user_updated` - ENABLED (calls handle_user_metadata_update)

## Authentication System Status ✅ READY FOR TESTING

**Backend Components:**
- ✅ Database functions created and available
- ✅ User role enum supports all roles
- ✅ RLS policies properly configured
- ✅ Database triggers enabled and functional
- ✅ Email verification system configured

**Frontend Components:**
- ✅ App running on Android emulator
- ✅ Authentication providers updated
- ✅ Router handling authentication states
- ✅ Deep link service initialized
- ✅ Error handling implemented

**Ready for Manual Testing:**
- ✅ Registration flow for all user roles
- ✅ Email verification process
- ✅ Login functionality
- ✅ Role-based dashboard routing
- ✅ Authentication state management

## Cross-Platform Testing
- Android emulator (primary) ✅ READY
- Web browser (secondary)
- iOS simulator (if available)
