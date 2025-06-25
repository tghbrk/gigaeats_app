# Driver Earnings Backend Setup Guide

This guide will help you set up the driver earnings system in your Supabase database when the migration system has conflicts.

## Prerequisites

1. Access to Supabase Dashboard
2. SQL Editor access in Supabase
3. Basic understanding of SQL

## Step-by-Step Setup

### Step 1: Check Database State

First, run the diagnostic script to see what tables already exist:

1. Open Supabase Dashboard
2. Go to SQL Editor
3. Copy and paste the content of `01_check_database_state.sql`
4. Click "Run"

This will show you:
- ✅ Which tables exist
- ❌ Which tables are missing
- Status of required enums and extensions

### Step 2: Create Fleet Management Tables

If the `drivers` table is missing (which caused your original error), run:

1. Copy and paste the content of `02_create_fleet_management_tables.sql`
2. Click "Run"

This creates:
- `drivers` table with GPS tracking support
- `delivery_tracking` table for real-time location tracking
- `driver_performance` table for metrics
- Adds `assigned_driver_id` column to `orders` table
- Sets up proper RLS policies

### Step 3: Create Driver Earnings Tables

Now create the earnings system:

1. Copy and paste the content of `03_create_driver_earnings_tables_simple.sql`
2. Click "Run"

This creates:
- `driver_earnings` table for detailed earnings records
- `driver_commission_structure` table for commission configuration
- `driver_earnings_summary` table for aggregated data
- Proper enums, indexes, and RLS policies

### Step 4: Create Sample Data (Optional)

To test the system with sample data:

1. Copy and paste the content of `04_create_sample_driver_data.sql`
2. Click "Run"

This creates:
- Sample drivers
- Sample commission structures
- Sample earnings records
- Sample performance data

## Verification

After running all scripts, verify the setup:

1. Run the diagnostic script again (`01_check_database_state.sql`)
2. All tables should show ✅ EXISTS
3. Check the sample data was created properly

## Testing the Integration

1. Open your Flutter app
2. Navigate to the test screens
3. Go to "Driver Earnings Backend Test"
4. Run the tests to verify everything works

## Common Issues and Solutions

### Issue: "relation does not exist" errors

**Solution**: Make sure you run the scripts in order:
1. Check database state first
2. Create fleet management tables
3. Create earnings tables
4. Create sample data

### Issue: RLS policy conflicts

**Solution**: The scripts use `IF NOT EXISTS` checks, so they're safe to re-run. If you get policy conflicts, you can drop existing policies first:

```sql
-- Drop existing policies if needed
DROP POLICY IF EXISTS "policy_name" ON table_name;
```

### Issue: Foreign key constraint errors

**Solution**: Ensure the referenced tables exist:
- `drivers` table must exist before creating `driver_earnings`
- `vendors` table must exist before creating `drivers`
- `orders` table must exist for order references

### Issue: PostGIS extension not available

**Solution**: PostGIS might not be enabled. Contact Supabase support or use a simpler location tracking approach:

```sql
-- Alternative: Use simple lat/lng columns instead of PostGIS
ALTER TABLE drivers ADD COLUMN latitude DECIMAL(10, 8);
ALTER TABLE drivers ADD COLUMN longitude DECIMAL(11, 8);
```

## Database Schema Overview

After setup, you'll have these new tables:

### Core Tables
- `drivers`: Driver profiles and status
- `driver_earnings`: Individual earnings records
- `driver_commission_structure`: Commission configuration
- `driver_earnings_summary`: Aggregated summaries
- `driver_performance`: Daily performance metrics
- `delivery_tracking`: GPS tracking data

### Key Relationships
- `drivers` → `vendors` (many-to-one)
- `driver_earnings` → `drivers` (many-to-one)
- `driver_earnings` → `orders` (many-to-one, optional)
- `driver_commission_structure` → `drivers` + `vendors`

## Security Features

- **Row Level Security (RLS)**: Enabled on all tables
- **Driver Access**: Drivers can only see their own data
- **Vendor Access**: Vendors can see their drivers' data
- **Admin Access**: Admins can see all data

## Next Steps

1. Test the driver earnings screen in your app
2. Create real driver accounts
3. Set up commission structures for your vendors
4. Configure automatic earnings recording when orders are delivered
5. Set up payment processing for driver payouts

## Support

If you encounter issues:
1. Check the Supabase logs for detailed error messages
2. Verify all foreign key relationships are correct
3. Ensure RLS policies allow your user role to access the data
4. Use the test screen to debug specific issues

## Performance Considerations

- Indexes are created for common query patterns
- Generated columns automatically calculate averages and rates
- Consider partitioning large tables by date for better performance
- Use the summary tables for dashboard queries instead of aggregating raw data

## Backup and Recovery

Before running these scripts on production:
1. Create a database backup
2. Test on a staging environment first
3. Have a rollback plan ready

The scripts are designed to be idempotent (safe to re-run), but it's always good practice to backup first.
