# GigaEats Database Migration Synchronization Guide

## Overview

This guide provides a comprehensive solution for synchronizing the GigaEats database migrations between the remote Supabase database and local migration files. The analysis revealed a significant gap with 27 unapplied migrations containing critical features.

## Migration Analysis Summary

### Current State
- **Remote Database**: 15 migrations applied (up to `20240101000015_vendor_filtered_metrics`)
- **Local Files**: 42 migration files total
- **Gap**: 27 unapplied migrations containing essential features

### Missing Features Identified
1. FCM tokens for push notifications
2. Menu customization system
3. Customer profiles and vendor details
4. Driver earnings and fleet management
5. Payment system enhancements
6. Sales agent management
7. Delivery fee system
8. Real-time notifications
9. Customer assignment system
10. Scheduled delivery support

## Synchronization Solution

### Phase 1: Analysis and Preparation

1. **Run Migration Analysis**
   ```sql
   -- Execute in Supabase SQL Editor
   -- File: supabase/migrations/20250616150000_migration_synchronization_analysis.sql
   ```
   This will provide a detailed report of missing tables, enums, and migration status.

2. **Review Current Database State**
   - Check existing tables and their structure
   - Identify any manually created tables
   - Verify data integrity before proceeding

### Phase 2: Apply Consolidated Migrations

Apply the consolidated migration files in sequence:

#### Step 1: Part 1 - Core Features
```bash
# Apply FCM tokens, menu customizations, and customer profiles
supabase db push --file supabase/migrations/20250616150001_consolidated_missing_migrations_part1.sql
```

#### Step 2: Part 2 - Vendor System
```bash
# Apply vendor details, business hours, and driver system setup
supabase db push --file supabase/migrations/20250616150002_consolidated_missing_migrations_part2.sql
```

#### Step 3: Part 3 - Fleet Management
```bash
# Apply driver earnings system and fleet management
supabase db push --file supabase/migrations/20250616150003_consolidated_missing_migrations_part3.sql
```

#### Step 4: Part 4 - Policies and Payments
```bash
# Apply RLS policies, payment system, and sales agents
supabase db push --file supabase/migrations/20250616150004_consolidated_missing_migrations_part4.sql
```

#### Step 5: Part 5 - Notifications and Functions
```bash
# Apply notifications, triggers, and enhanced functions
supabase db push --file supabase/migrations/20250616150005_consolidated_missing_migrations_part5.sql
```

### Phase 3: Verification and Testing

1. **Verify Migration Status**
   ```sql
   SELECT 
       migration_version,
       migration_name,
       sync_status,
       applied_at
   FROM migration_sync_progress 
   ORDER BY migration_version;
   ```

2. **Check Table Creation**
   ```sql
   SELECT table_name, table_type 
   FROM information_schema.tables 
   WHERE table_schema = 'public' 
   ORDER BY table_name;
   ```

3. **Verify RLS Policies**
   ```sql
   SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
   FROM pg_policies 
   WHERE schemaname = 'public' 
   ORDER BY tablename, policyname;
   ```

## Safety Measures

### Data Preservation
- All migrations use `IF NOT EXISTS` clauses to prevent conflicts
- Existing data is preserved during schema updates
- Foreign key constraints are handled gracefully
- No destructive operations are performed

### Rollback Strategy
- Each migration part can be applied independently
- Database backups should be taken before applying migrations
- Migration progress is tracked in `migration_sync_progress` table
- Individual migrations can be rolled back if needed

### Conflict Resolution
- Duplicate table creation is handled with `IF NOT EXISTS`
- Enum value additions check for existing values
- Unique constraints are handled with `ON CONFLICT DO NOTHING`
- Policy creation uses `DROP POLICY IF EXISTS` before creation

## Post-Migration Tasks

### 1. Update Local Migration Tracking
```bash
# Sync local migration status
supabase db pull
```

### 2. Test Application Functionality
- Test user authentication and role-based access
- Verify order management workflows
- Test driver assignment and tracking
- Validate payment processing
- Check notification delivery

### 3. Performance Optimization
- Analyze query performance on new tables
- Add additional indexes if needed
- Monitor database performance metrics

### 4. Data Migration (if needed)
- Migrate existing customer data to new customer_profiles table
- Update order records with new delivery methods
- Populate vendor details from existing vendor data

## Troubleshooting

### Common Issues

1. **Foreign Key Constraint Errors**
   - Ensure referenced tables exist before creating dependent tables
   - Check data integrity in existing tables

2. **RLS Policy Conflicts**
   - Policies are dropped and recreated to handle conflicts
   - Verify user permissions after policy updates

3. **Enum Type Conflicts**
   - New enum values are added only if they don't exist
   - Check enum usage in existing data

4. **Migration Timeout**
   - Large migrations may timeout in Supabase dashboard
   - Apply migrations in smaller batches if needed

### Verification Queries

```sql
-- Check migration completion
SELECT 
    COUNT(*) as total_migrations,
    COUNT(*) FILTER (WHERE sync_status = 'completed') as completed,
    COUNT(*) FILTER (WHERE sync_status = 'pending') as pending
FROM migration_sync_progress;

-- Verify critical tables exist
SELECT 
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'customer_profiles') 
         THEN '✅ customer_profiles' 
         ELSE '❌ customer_profiles' END as customer_profiles,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'drivers') 
         THEN '✅ drivers' 
         ELSE '❌ drivers' END as drivers,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'driver_earnings') 
         THEN '✅ driver_earnings' 
         ELSE '❌ driver_earnings' END as driver_earnings;

-- Check enum types
SELECT typname, array_agg(enumlabel ORDER BY enumsortorder) as values
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid 
WHERE typname LIKE '%_enum'
GROUP BY typname
ORDER BY typname;
```

## Next Steps

1. **Apply migrations in sequence** following the phase plan
2. **Test each phase** before proceeding to the next
3. **Monitor application performance** after migration completion
4. **Update documentation** to reflect new database schema
5. **Train team members** on new features and database structure

## Support

If you encounter issues during migration:
1. Check the migration progress table for detailed status
2. Review Supabase logs for error messages
3. Verify prerequisites are met for each migration phase
4. Contact the development team for assistance

---

**Important**: Always backup your database before applying migrations in production environments.
