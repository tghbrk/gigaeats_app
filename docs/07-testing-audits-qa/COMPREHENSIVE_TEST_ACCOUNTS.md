# Comprehensive Test Accounts for GigaEats App

## Overview

This document provides details for all test accounts created in the GigaEats application. These accounts are fully configured with complete profile data, sample content, and are ready for testing all features and capabilities of each user role.

## Test Account Credentials

All test accounts use the same password: **Testpass123!**

### 1. Admin Account
- **Email**: admin.test@gigaeats.com
- **Password**: Testpass123!
- **Role**: Administrator
- **Full Name**: Admin Test User
- **Phone**: +60123456789
- **Status**: Verified and Active

**Capabilities**:
- Full administrative privileges
- User management
- System settings
- Analytics access
- All vendor and order management

### 2. Vendor Account
- **Email**: vendor.test@gigaeats.com
- **Password**: Testpass123!
- **Role**: Vendor
- **Full Name**: Vendor Test User
- **Phone**: +60123456790
- **Status**: Verified and Active

**Business Profile**:
- **Business Name**: Test Malaysian Kitchen
- **Registration Number**: REG123456789
- **Address**: 123 Jalan Test, Kuala Lumpur, 50000, Malaysia
- **Business Type**: Restaurant
- **Cuisine Types**: Malaysian, Asian, Halal
- **Halal Certified**: Yes (HALAL-2024-001)
- **Rating**: 4.5/5 (127 reviews)
- **Total Orders**: 89
- **Service Areas**: Kuala Lumpur, Petaling Jaya, Shah Alam

**Menu Items** (7 items):
1. **Nasi Lemak Special** - RM 18.90 (Halal)
2. **Char Kway Teow** - RM 16.50 (Non-Halal)
3. **Beef Rendang** - RM 22.90 (Halal)
4. **Hainanese Chicken Rice** - RM 15.90 (Non-Halal)
5. **Mee Goreng Mamak** - RM 14.50 (Halal)
6. **Teh Tarik** - RM 4.50 (Halal)
7. **Fresh Coconut Water** - RM 6.90 (Halal)

**Analytics Data**: 7 days of sample data with varying orders, revenue, and customer metrics

### 3. Sales Agent Account
- **Email**: salesagent.test@gigaeats.com
- **Password**: Testpass123!
- **Role**: Sales Agent
- **Full Name**: Sales Agent Test User
- **Phone**: +60123456791
- **Status**: Verified and Active

**Profile Details**:
- **Employee ID**: SA001
- **Assigned Regions**: Kuala Lumpur, Selangor
- **Territory**: Central KL and surrounding areas
- **Coverage Areas**: KLCC, Mont Kiara
- **Total Customers**: 25
- **Active Customers**: 18
- **Orders Facilitated**: 156
- **Commission Earned**: RM 2,340.50

### 4. Driver Account
- **Email**: driver.test@gigaeats.com
- **Password**: Testpass123!
- **Role**: Driver
- **Full Name**: Driver Test User
- **Phone**: +60123456792
- **Status**: Verified and Active

**Profile Details**:
- **License Number**: D1234567
- **Vehicle Type**: Motorcycle
- **Vehicle**: Honda Wave 125 (Red)
- **Plate Number**: ABC1234
- **Status**: Online
- **Total Deliveries**: 89
- **Rating**: 4.7/5
- **Total Earnings**: RM 1,250.75

**Earnings Data**: 7 days of sample earnings with commission, bonuses, and delivery metrics

### 5. Customer Account
- **Email**: customer.test@gigaeats.com
- **Password**: Testpass123!
- **Role**: Customer
- **Full Name**: Customer Test User
- **Phone**: +60123456793
- **Status**: Verified and Active

**Profile Details**:
- **Default Address**: 456 Jalan Customer, Kuala Lumpur, 50100
- **Saved Addresses**: Home and Office locations
- **Dietary Preferences**: No pork, Halal preferred
- **Preferred Cuisines**: Malaysian, Chinese, Thai
- **Loyalty Points**: 125
- **Total Orders**: 12
- **Total Spent**: RM 456.80

## Supporting Data Created

### Delivery Fee Configuration
- **Own Fleet**: RM 8.00 base fee, RM 2.50/km
- **Lalamove**: RM 12.00 base fee, RM 3.00/km
- **Customer Pickup**: Free
- **Sales Agent Pickup**: Free

### Business Hours
- **Monday-Friday**: 9:00 AM - 10:00 PM
- **Saturday**: 9:00 AM - 11:00 PM
- **Sunday**: 10:00 AM - 10:00 PM

### Analytics Data
- 7 days of vendor analytics with realistic order volumes, revenue, and customer metrics
- 7 days of driver earnings data with commission structure and performance metrics

## Testing Capabilities

### Admin Testing
- User management and role assignment
- System analytics and reporting
- Vendor verification and management
- Order oversight and management

### Vendor Testing
- Menu management (7 pre-loaded items)
- Order processing and status updates
- Analytics dashboard with 7 days of data
- Business profile management
- Delivery fee configuration

### Sales Agent Testing
- Customer assignment and management
- Territory and coverage area management
- Commission tracking and reporting
- Order facilitation

### Driver Testing
- Delivery assignment and tracking
- Earnings calculation and history
- Performance metrics and ratings
- Vehicle and profile management

### Customer Testing
- Menu browsing and ordering
- Address management (2 saved addresses)
- Order history and tracking
- Loyalty points and preferences

## Database Integration

All test accounts are properly integrated with:
- ✅ Supabase authentication system (auth.users table)
- ✅ Public user profiles (public.users table)
- ✅ Proper auth-to-public user linkage (supabase_user_id)
- ✅ Row Level Security (RLS) policies
- ✅ Role-based permissions
- ✅ Complete profile relationships
- ✅ Sample transactional data
- ✅ Analytics and reporting data

## Authentication Status

**✅ AUTHENTICATION FIXED**: All test accounts now have proper authentication records in both:
- `auth.users` table (Supabase authentication system)
- `public.users` table (Application user profiles)
- Proper linkage via `supabase_user_id` field
- Email confirmation enabled for all accounts
- Password encryption using bcrypt

## Usage Instructions

1. **Login**: Use any of the email addresses above with password "Testpass123!"
2. **Role-based Access**: Each account will automatically redirect to the appropriate dashboard
3. **Full Functionality**: All features are enabled and ready for testing
4. **Data Persistence**: All test data is stored in the Supabase database
5. **Reset**: Test data can be modified or reset as needed for testing scenarios

## Notes

- All accounts are email verified and active
- Phone numbers use Malaysian format (+60)
- Addresses are realistic Malaysian locations
- Currency is in Malaysian Ringgit (MYR)
- Business hours follow Malaysian timezone
- All data follows Malaysian market conventions

These test accounts provide a comprehensive testing environment for all GigaEats application features and user roles.