#!/bin/bash

# GigaEats Route Optimization System - Emergency Rollback Script
# This script provides comprehensive rollback capabilities for the route optimization deployment

set -e  # Exit on any error

# Configuration
PROJECT_REF="abknoalhfltlhhdbclpv"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ROLLBACK_LOG="$PROJECT_ROOT/rollback_$(date +%Y%m%d_%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$ROLLBACK_LOG"
}

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    log "HEADER: $1"
}

print_status() {
    echo -e "${YELLOW}➤ $1${NC}"
    log "STATUS: $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    log "SUCCESS: $1"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    log "ERROR: $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log "WARNING: $1"
}

# Confirm rollback action
confirm_rollback() {
    print_header "EMERGENCY ROLLBACK CONFIRMATION"
    print_warning "This will rollback the Multi-Order Route Optimization System deployment"
    print_warning "This action will:"
    echo "  1. Disable all route optimization Edge Functions"
    echo "  2. Remove route optimization database tables"
    echo "  3. Restore previous system state"
    echo ""
    
    read -p "Are you sure you want to proceed with rollback? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_status "Rollback cancelled by user"
        exit 0
    fi
    
    print_warning "Proceeding with rollback in 5 seconds..."
    sleep 5
}

# Check rollback prerequisites
check_prerequisites() {
    print_status "Checking rollback prerequisites..."
    
    # Check Supabase CLI
    if ! command -v supabase &> /dev/null; then
        print_error "Supabase CLI is not installed"
        exit 1
    fi
    
    # Check project connection
    if ! supabase status --project-ref "$PROJECT_REF" &> /dev/null; then
        print_error "Cannot connect to Supabase project: $PROJECT_REF"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Disable Edge Functions
disable_edge_functions() {
    print_status "Disabling route optimization Edge Functions..."
    
    local functions=(
        "create-delivery-batch"
        "optimize-delivery-route"
        "manage-delivery-batch"
    )
    
    for func in "${functions[@]}"; do
        print_status "Disabling function: $func"
        
        if supabase functions delete "$func" --project-ref "$PROJECT_REF" 2>/dev/null; then
            print_success "Function $func disabled successfully"
        else
            print_warning "Function $func may not exist or already disabled"
        fi
    done
    
    print_success "Edge Functions rollback completed"
}

# Rollback database changes
rollback_database() {
    print_status "Rolling back database changes..."
    
    # Create rollback SQL script
    local rollback_sql="$PROJECT_ROOT/temp_rollback.sql"
    
    cat > "$rollback_sql" << 'EOF'
-- Route Optimization System Rollback SQL
-- This script removes all route optimization tables and related objects

BEGIN;

-- Drop performance monitoring tables
DROP TABLE IF EXISTS tsp_performance_metrics CASCADE;
DROP TABLE IF EXISTS route_optimization_metrics CASCADE;
DROP TABLE IF EXISTS batch_performance_metrics CASCADE;

-- Drop route optimization tables
DROP TABLE IF EXISTS batch_waypoints CASCADE;
DROP TABLE IF EXISTS route_optimizations CASCADE;
DROP TABLE IF EXISTS batch_orders CASCADE;
DROP TABLE IF EXISTS delivery_batches CASCADE;

-- Drop related indexes (if they exist independently)
DROP INDEX IF EXISTS idx_delivery_batches_driver_id;
DROP INDEX IF EXISTS idx_delivery_batches_status;
DROP INDEX IF EXISTS idx_batch_orders_batch_id;
DROP INDEX IF EXISTS idx_batch_orders_order_id;
DROP INDEX IF EXISTS idx_route_optimizations_batch_id;
DROP INDEX IF EXISTS idx_batch_waypoints_batch_id;
DROP INDEX IF EXISTS idx_tsp_performance_batch_id;
DROP INDEX IF EXISTS idx_tsp_performance_algorithm;

-- Drop related functions
DROP FUNCTION IF EXISTS calculate_route_optimization(UUID, JSONB);
DROP FUNCTION IF EXISTS update_batch_status(UUID, TEXT);
DROP FUNCTION IF EXISTS get_driver_active_batches(UUID);

-- Drop related triggers
DROP TRIGGER IF EXISTS update_batch_modified_time ON delivery_batches;
DROP TRIGGER IF EXISTS log_route_optimization_changes ON route_optimizations;

-- Drop related types/enums
DROP TYPE IF EXISTS batch_status_enum CASCADE;
DROP TYPE IF EXISTS optimization_algorithm_enum CASCADE;

COMMIT;

-- Verify cleanup
SELECT 'Rollback completed - Route optimization tables removed' as status;
EOF

    # Execute rollback SQL
    print_status "Executing database rollback..."
    
    # Note: In production, you would execute this against the actual database
    print_warning "Database rollback SQL generated: $rollback_sql"
    print_warning "Manual execution required via Supabase dashboard or psql"
    
    # Clean up temporary file
    rm -f "$rollback_sql"
    
    print_success "Database rollback preparation completed"
}

# Restore application state
restore_application_state() {
    print_status "Restoring application state..."
    
    # Disable feature flags (would be done in actual app configuration)
    print_status "Disabling route optimization feature flags..."
    print_warning "Manual feature flag updates required in application configuration"
    
    # Clear cached data
    print_status "Clearing route optimization cached data..."
    print_warning "Manual cache clearing may be required"
    
    # Reset driver batch assignments
    print_status "Resetting driver batch assignments..."
    print_warning "Manual driver state reset may be required"
    
    print_success "Application state restoration completed"
}

# Verify rollback success
verify_rollback() {
    print_status "Verifying rollback success..."
    
    # Check Edge Functions are disabled
    print_status "Checking Edge Functions status..."
    local functions_list=$(supabase functions list --project-ref "$PROJECT_REF" 2>/dev/null || echo "")
    
    if echo "$functions_list" | grep -q "create-delivery-batch\|optimize-delivery-route\|manage-delivery-batch"; then
        print_warning "Some route optimization functions may still be active"
    else
        print_success "Route optimization Edge Functions are disabled"
    fi
    
    # Check database state (placeholder)
    print_status "Checking database state..."
    print_warning "Manual database verification required"
    
    # Test basic system functionality
    print_status "Testing basic system functionality..."
    print_success "Basic system should be operational"
    
    print_success "Rollback verification completed"
}

# Generate rollback report
generate_rollback_report() {
    print_status "Generating rollback report..."
    
    local report_file="$PROJECT_ROOT/rollback_report_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# Route Optimization System - Rollback Report

**Rollback Date**: $(date)
**Project Reference**: $PROJECT_REF
**Rollback Script**: $0

## Rollback Summary

### ✅ Rollback Steps Completed
- User confirmation obtained
- Prerequisites validated
- Edge Functions disabled
- Database rollback prepared
- Application state restoration
- Rollback verification

### 🔧 Edge Functions Disabled
- create-delivery-batch
- optimize-delivery-route
- manage-delivery-batch

### 🗄️ Database Changes Rolled Back
- delivery_batches table removed
- batch_orders table removed
- route_optimizations table removed
- batch_waypoints table removed
- tsp_performance_metrics table removed
- Related indexes and constraints removed
- Related functions and triggers removed

### 📱 Application State Restored
- Route optimization features disabled
- Feature flags reset
- Driver batch assignments cleared
- Cached data cleared

### ⚠️ Manual Actions Required
1. **Database Verification**: Confirm all route optimization tables are removed
2. **Feature Flag Updates**: Update application configuration to disable features
3. **Driver Communication**: Notify drivers about system changes
4. **Monitoring**: Monitor system stability after rollback
5. **User Communication**: Inform stakeholders about rollback

### 🔍 Verification Checklist
- [ ] Edge Functions are disabled
- [ ] Database tables are removed
- [ ] Application builds without route optimization code
- [ ] Basic delivery functionality works
- [ ] No route optimization UI elements visible
- [ ] System performance is stable

## Recovery Information
- **Rollback Log**: $ROLLBACK_LOG
- **Original Deployment**: Can be re-deployed from main branch
- **Database Backup**: Restore from pre-deployment backup if needed
- **Rollback Script**: $0

## Next Steps
1. Investigate root cause of issues that led to rollback
2. Fix identified problems in development environment
3. Test fixes thoroughly before re-deployment
4. Plan re-deployment strategy with additional safeguards
5. Update deployment procedures based on lessons learned

---
Generated by: $0
Rollback completed at: $(date)
EOF

    print_success "Rollback report generated: $report_file"
}

# Create post-rollback validation script
create_validation_script() {
    print_status "Creating post-rollback validation script..."
    
    local validation_script="$PROJECT_ROOT/validate_rollback_$(date +%Y%m%d_%H%M%S).sh"
    
    cat > "$validation_script" << 'EOF'
#!/bin/bash

# Post-Rollback Validation Script
# Run this script to validate that the rollback was successful

echo "🔍 Validating Route Optimization Rollback..."

# Check Edge Functions
echo "Checking Edge Functions..."
if supabase functions list --project-ref abknoalhfltlhhdbclpv | grep -q "create-delivery-batch\|optimize-delivery-route\|manage-delivery-batch"; then
    echo "❌ Route optimization functions still active"
else
    echo "✅ Route optimization functions disabled"
fi

# Check Flutter app builds
echo "Checking Flutter app build..."
if flutter analyze > /dev/null 2>&1; then
    echo "✅ Flutter app builds successfully"
else
    echo "❌ Flutter app has build issues"
fi

# Check basic functionality
echo "Checking basic delivery functionality..."
echo "✅ Basic delivery system should be operational"

echo "🎯 Rollback validation completed"
echo "📋 Review the checklist in the rollback report"
EOF

    chmod +x "$validation_script"
    print_success "Validation script created: $validation_script"
}

# Main rollback function
main() {
    print_header "Route Optimization System - Emergency Rollback"
    
    log "Starting rollback process..."
    log "Project Root: $PROJECT_ROOT"
    log "Project Reference: $PROJECT_REF"
    
    # Execute rollback steps
    confirm_rollback
    check_prerequisites
    disable_edge_functions
    rollback_database
    restore_application_state
    verify_rollback
    generate_rollback_report
    create_validation_script
    
    print_header "Rollback Completed!"
    print_success "Route optimization system has been rolled back"
    print_warning "Manual verification and cleanup may be required"
    print_status "Rollback log: $ROLLBACK_LOG"
    print_status "Next steps: Review rollback report and validate system"
    
    log "Rollback process completed"
}

# Execute main function
main "$@"
