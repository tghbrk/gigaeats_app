# 🚨 EMERGENCY ROLLBACK PLAN - Phase 2 to Phase 1
## GigaEats Database Recovery Procedure

### 🎯 Objective
Safely rollback the GigaEats database from Phase 2 (January 2025 migrations) to Phase 1 (December 2024 migrations only) to restore lost application functionality.

### ⚠️ CRITICAL SAFETY NOTES
- **STOP all application traffic** before beginning rollback
- **Verify backup integrity** before proceeding
- **Document current state** before making changes
- **Test thoroughly** after rollback completion

---

## 📋 Pre-Rollback Checklist

### 1. Create Current State Backup (Safety Net)
```bash
# Create emergency backup of current state
supabase db dump --linked > emergency_backup_before_rollback_$(date +%Y%m%d_%H%M%S).sql
```

### 2. Verify Target Backup Exists
```bash
# Confirm the Phase 1 backup exists and is readable
ls -la backup_pre_sync_20250619_015009.sql
file backup_pre_sync_20250619_015009.sql
```

### 3. Document Current Migration State
```bash
# Record current migration status for reference
supabase migration list --linked > current_migration_state_before_rollback.txt
```

---

## 🔄 ROLLBACK PROCEDURE

### Step 1: Stop Application Traffic
**CRITICAL**: Ensure no application writes are occurring during rollback

### Step 2: Restore Database from Phase 1 Backup
```bash
# Method 1: Using Supabase CLI (Recommended)
supabase db reset --linked --restore-from backup_pre_sync_20250619_015009.sql

# Method 2: If CLI method fails, use direct PostgreSQL restore
# (Replace with your actual connection details)
pg_restore --clean --if-exists --verbose \
  --host=your-project.supabase.co \
  --port=5432 \
  --username=postgres \
  --dbname=postgres \
  backup_pre_sync_20250619_015009.sql
```

### Step 3: Verify Rollback Success
```bash
# Check migration status - should show only Phase 1 migrations
supabase migration list --linked

# Verify specific tables exist/don't exist
supabase db shell --linked
```

### Step 4: Database Verification Queries
```sql
-- Verify Phase 1 tables exist (should return results)
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('customer_profiles', 'vendor_reviews', 'fcm_tokens') 
AND table_schema = 'public';

-- Verify Phase 2 tables are removed (should return empty)
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('driver_earnings', 'driver_commission_structure') 
AND table_schema = 'public';

-- Check orders table structure (delivery_method column should be absent)
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'orders' AND column_name = 'delivery_method';

-- Verify December 2024 data is intact
SELECT COUNT(*) as customer_profiles_count FROM customer_profiles;
SELECT COUNT(*) as vendor_reviews_count FROM vendor_reviews;
SELECT COUNT(*) as fcm_tokens_count FROM fcm_tokens;
```

---

## ✅ POST-ROLLBACK VERIFICATION

### 1. Database State Verification
- [ ] Phase 1 tables present and populated
- [ ] Phase 2 tables completely removed
- [ ] No orphaned data or broken references
- [ ] All December 2024 features functional

### 2. Application Functionality Testing
Test these critical functions to confirm restoration:

#### Customer Features
- [ ] Customer profile creation/editing
- [ ] Address management
- [ ] Order placement
- [ ] FCM notifications

#### Vendor Features  
- [ ] Vendor dashboard access
- [ ] Menu management
- [ ] Order status updates
- [ ] Review system

#### Driver Features
- [ ] Driver profile access
- [ ] Order assignment (basic)
- [ ] Status updates (without earnings)

#### Admin Features
- [ ] Fleet management
- [ ] User management
- [ ] System monitoring

### 3. Performance Verification
- [ ] Query response times normal
- [ ] No database errors in logs
- [ ] RLS policies functioning correctly
- [ ] Real-time subscriptions working

---

## 📝 DOCUMENTATION REQUIREMENTS

### 1. Record Broken Functionality
Document exactly what stopped working after Phase 2:

```
BROKEN FUNCTIONALITY REPORT:
- Feature: [Specific feature that broke]
- Error: [Exact error message/behavior]
- Impact: [How it affected users]
- Suspected cause: [Which migration likely caused it]
```

### 2. Migration Analysis
For each Phase 2 migration, document:
- **20250101000016_create_driver_earnings_system**
  - What broke: 
  - Suspected reason:
  - Dependencies affected:

- **20250101000017_add_delivery_method_to_orders**
  - What broke:
  - Suspected reason:
  - Dependencies affected:

### 3. Root Cause Investigation Plan
- [ ] Review application logs during Phase 2 deployment
- [ ] Check for schema conflicts with existing code
- [ ] Verify RLS policy interactions
- [ ] Test migration compatibility with app version

---

## 🔍 TROUBLESHOOTING

### If Rollback Fails
1. **Check backup file integrity**
   ```bash
   head -20 backup_pre_sync_20250619_015009.sql
   tail -20 backup_pre_sync_20250619_015009.sql
   ```

2. **Manual table cleanup** (if needed)
   ```sql
   -- Remove Phase 2 tables manually
   DROP TABLE IF EXISTS driver_earnings CASCADE;
   DROP TABLE IF EXISTS driver_commission_structure CASCADE;
   DROP TABLE IF EXISTS driver_earnings_summary CASCADE;
   
   -- Remove Phase 2 enums
   DROP TYPE IF EXISTS earnings_type CASCADE;
   DROP TYPE IF EXISTS earnings_status CASCADE;
   DROP TYPE IF EXISTS delivery_method_enum CASCADE;
   
   -- Remove delivery_method column from orders
   ALTER TABLE orders DROP COLUMN IF EXISTS delivery_method;
   ```

3. **Verify migration table state**
   ```sql
   -- Check which migrations are recorded as applied
   SELECT * FROM supabase_migrations.schema_migrations 
   ORDER BY version DESC LIMIT 10;
   ```

### If Application Still Broken After Rollback
1. **Check for cached schema** in application
2. **Restart application services**
3. **Clear application caches**
4. **Verify environment variables** haven't changed
5. **Check for code dependencies** on Phase 2 features

---

## 📞 EMERGENCY CONTACTS & NEXT STEPS

### Immediate Actions After Successful Rollback
1. **Notify stakeholders** that system is restored
2. **Resume application traffic** gradually
3. **Monitor system closely** for 24 hours
4. **Schedule root cause analysis** meeting

### Before Attempting Phase 2 Again
1. **Complete root cause analysis**
2. **Test migrations in staging environment**
3. **Update application code** if needed
4. **Plan rollback strategy** for next attempt
5. **Consider smaller migration batches**

---

**ROLLBACK STATUS**: Ready to Execute
**ESTIMATED TIME**: 30-60 minutes
**RISK LEVEL**: Low (comprehensive backup available)
**SUCCESS CRITERIA**: All December 2024 features working, Phase 2 features completely removed
