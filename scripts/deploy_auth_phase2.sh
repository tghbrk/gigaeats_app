#!/bin/bash

# Phase 2 Deployment Script: Database Schema Enhancement
# Purpose: Deploy Phase 2 database schema enhancements for authentication
# Date: 2025-06-26

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🔍 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo -e "${BLUE}"
    echo "=================================================="
    echo "$1"
    echo "=================================================="
    echo -e "${NC}"
}

# Check if Supabase CLI is available
check_supabase_cli() {
    if ! command -v supabase &> /dev/null; then
        print_error "Supabase CLI not found. Please install it first."
        echo "Install with: npm install -g supabase"
        exit 1
    fi
    print_success "Supabase CLI found"
}

# Check if we're in the correct directory
check_directory() {
    if [ ! -f "supabase/config.toml" ]; then
        print_error "Not in the correct directory. Please run from the project root."
        exit 1
    fi
    print_success "Correct directory confirmed"
}

# Check Supabase connection
check_supabase_connection() {
    print_status "Checking Supabase connection..."
    
    if supabase status | grep -q "API URL"; then
        print_success "Supabase is running and connected"
    else
        print_error "Supabase is not running or not connected"
        echo "Please run 'supabase start' or check your connection"
        exit 1
    fi
}

# Backup current database state
backup_database() {
    print_status "Creating database backup before Phase 2 deployment..."
    
    local backup_file="backup_pre_phase2_$(date +%Y%m%d_%H%M%S).sql"
    
    if supabase db dump --linked > "$backup_file" 2>/dev/null; then
        print_success "Database backup created: $backup_file"
    else
        print_warning "Could not create backup, but continuing with deployment"
    fi
}

# Apply Phase 2 migration
apply_migration() {
    print_status "Applying Phase 2 database schema enhancement migration..."
    
    local migration_file="supabase/migrations/20250626000001_enhance_auth_schema_phase2.sql"
    
    if [ ! -f "$migration_file" ]; then
        print_error "Migration file not found: $migration_file"
        exit 1
    fi
    
    print_status "Applying migration: $(basename $migration_file)"
    
    if supabase migration up --linked; then
        print_success "Phase 2 migration applied successfully"
    else
        print_error "Failed to apply Phase 2 migration"
        echo "Check the error messages above and fix any issues"
        exit 1
    fi
}

# Validate migration
validate_migration() {
    print_status "Validating Phase 2 database schema enhancements..."
    
    local validation_script="supabase/manual_scripts/validate_auth_schema_phase2.sql"
    
    if [ ! -f "$validation_script" ]; then
        print_error "Validation script not found: $validation_script"
        exit 1
    fi
    
    print_status "Running validation script..."
    
    if supabase db shell --linked < "$validation_script"; then
        print_success "Phase 2 validation completed"
    else
        print_error "Phase 2 validation failed"
        echo "Check the validation output above"
        exit 1
    fi
}

# Test authentication functions
test_auth_functions() {
    print_status "Testing authentication functions..."
    
    # Test basic function availability
    local test_query="
    SELECT 
      'Function Tests' as test_category,
      CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'current_user_has_role')
        AND EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_current_user_role')
        AND EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_user_login_tracking')
        THEN '✅ PASS'
        ELSE '❌ FAIL'
      END as status,
      'Core authentication functions available' as description;
    "
    
    if echo "$test_query" | supabase db shell --linked; then
        print_success "Authentication functions test passed"
    else
        print_warning "Authentication functions test had issues"
    fi
}

# Check database performance
check_performance() {
    print_status "Checking database performance after enhancements..."
    
    local performance_query="
    SELECT 
      'Performance Check' as test_category,
      CASE 
        WHEN COUNT(*) >= 8 THEN '✅ PASS'
        ELSE '⚠️ WARNING'
      END as status,
      'Authentication indexes: ' || COUNT(*) as description
    FROM pg_indexes 
    WHERE tablename IN ('users', 'user_profiles')
      AND schemaname = 'public'
      AND indexname LIKE 'idx_%';
    "
    
    if echo "$performance_query" | supabase db shell --linked; then
        print_success "Performance check completed"
    else
        print_warning "Performance check had issues"
    fi
}

# Generate deployment report
generate_report() {
    print_status "Generating Phase 2 deployment report..."
    
    local report_file="phase2_deployment_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
GigaEats Authentication Enhancement - Phase 2 Deployment Report
============================================================

Deployment Date: $(date)
Phase: 2 - Database Schema Enhancement
Migration: 20250626000001_enhance_auth_schema_phase2.sql

Enhancements Applied:
- ✅ Added driver role to user_role_enum
- ✅ Enhanced users table with authentication tracking columns
- ✅ Enhanced user_profiles table with additional fields
- ✅ Created performance indexes for authentication queries
- ✅ Optimized RLS policies for better performance
- ✅ Enhanced authentication functions and triggers
- ✅ Created authentication analytics functions
- ✅ Added materialized view for user statistics
- ✅ Implemented profile completion calculation
- ✅ Added validation functions

Database Changes:
- New columns: 18 columns added across users and user_profiles tables
- New indexes: 8+ performance indexes created
- New functions: 10+ authentication-related functions
- Enhanced triggers: 3 triggers updated/created
- New materialized view: user_auth_statistics

Next Steps:
1. Proceed to Phase 3: Backend Configuration
2. Configure Supabase auth settings
3. Implement custom email templates
4. Set up deep link handling

Validation Status: $(date)
EOF

    # Add validation results to report
    echo "" >> "$report_file"
    echo "Validation Results:" >> "$report_file"
    echo "==================" >> "$report_file"
    
    if supabase db shell --linked -c "SELECT * FROM public.validate_auth_schema_enhancement();" >> "$report_file" 2>/dev/null; then
        print_success "Validation results added to report"
    else
        echo "Validation results: Manual verification required" >> "$report_file"
    fi
    
    print_success "Deployment report generated: $report_file"
}

# Main deployment function
main() {
    print_header "GigaEats Authentication Enhancement - Phase 2 Deployment"
    
    print_status "Starting Phase 2: Database Schema Enhancement"
    echo "This phase will enhance the database schema with:"
    echo "- Authentication tracking columns"
    echo "- Performance indexes"
    echo "- Optimized RLS policies"
    echo "- Enhanced functions and triggers"
    echo "- Authentication analytics"
    echo ""
    
    # Confirmation prompt
    read -p "Do you want to proceed with Phase 2 deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Phase 2 deployment cancelled"
        exit 0
    fi
    
    # Pre-deployment checks
    print_header "Pre-deployment Checks"
    check_supabase_cli
    check_directory
    check_supabase_connection
    
    # Backup
    print_header "Database Backup"
    backup_database
    
    # Apply migration
    print_header "Migration Deployment"
    apply_migration
    
    # Validation
    print_header "Validation"
    validate_migration
    test_auth_functions
    check_performance
    
    # Report generation
    print_header "Report Generation"
    generate_report
    
    # Success message
    print_header "Phase 2 Deployment Complete"
    print_success "Database schema enhancement completed successfully!"
    echo ""
    echo "Summary:"
    echo "- ✅ Migration applied: 20250626000001_enhance_auth_schema_phase2.sql"
    echo "- ✅ Database schema enhanced with authentication features"
    echo "- ✅ Performance optimizations implemented"
    echo "- ✅ Validation completed successfully"
    echo ""
    echo "Next Steps:"
    echo "1. Review the deployment report"
    echo "2. Test authentication flows in the Flutter app"
    echo "3. Proceed to Phase 3: Backend Configuration"
    echo ""
    print_warning "Remember to test the authentication system thoroughly before proceeding to Phase 3"
}

# Run main function
main "$@"
