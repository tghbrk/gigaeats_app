#!/bin/bash

# Deploy Driver Wallet Edge Function
# This script deploys the driver-wallet-operations Edge Function and runs necessary migrations

set -e

echo "🚀 Deploying Driver Wallet Edge Function..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    print_error "Supabase CLI is not installed. Please install it first:"
    echo "npm install -g supabase"
    exit 1
fi

# Check if we're in the correct directory
if [ ! -f "supabase/functions/driver-wallet-operations/index.ts" ]; then
    print_error "driver-wallet-operations Edge Function not found. Please run this script from the project root."
    exit 1
fi

# Check if Supabase is linked
if [ ! -f ".supabase/config.toml" ]; then
    print_warning "Supabase project not linked. Please run 'supabase link' first."
    exit 1
fi

print_status "Starting deployment process..."

# Step 1: Run database migrations
print_status "Running database migrations..."
if supabase db push; then
    print_success "Database migrations completed successfully"
else
    print_error "Database migrations failed"
    exit 1
fi

# Step 2: Deploy the Edge Function
print_status "Deploying driver-wallet-operations Edge Function..."
if supabase functions deploy driver-wallet-operations; then
    print_success "Edge Function deployed successfully"
else
    print_error "Edge Function deployment failed"
    exit 1
fi

# Step 3: Verify deployment
print_status "Verifying deployment..."

# Get project reference
PROJECT_REF=$(supabase status | grep "API URL" | awk '{print $3}' | sed 's/https:\/\///' | sed 's/\.supabase\.co//')

if [ -z "$PROJECT_REF" ]; then
    print_warning "Could not determine project reference for verification"
else
    FUNCTION_URL="https://${PROJECT_REF}.supabase.co/functions/v1/driver-wallet-operations"
    print_status "Function URL: $FUNCTION_URL"
    
    # Test CORS preflight
    print_status "Testing CORS preflight..."
    if curl -s -o /dev/null -w "%{http_code}" -X OPTIONS "$FUNCTION_URL" | grep -q "200"; then
        print_success "CORS preflight test passed"
    else
        print_warning "CORS preflight test failed - this might be expected"
    fi
fi

# Step 4: Display post-deployment information
print_success "Deployment completed successfully!"
echo ""
echo "📋 Post-Deployment Checklist:"
echo "1. ✅ Database migrations applied"
echo "2. ✅ Edge Function deployed"
echo "3. 🔄 Test the function with valid authentication"
echo "4. 🔄 Monitor function logs for any issues"
echo "5. 🔄 Update Flutter app to use the deployed function"
echo ""

print_status "Next steps:"
echo "• Test the function endpoints with valid JWT tokens"
echo "• Monitor function logs: supabase functions logs driver-wallet-operations"
echo "• Update environment variables if needed"
echo "• Run integration tests from the Flutter app"
echo ""

print_status "Function endpoints available:"
echo "• get_balance - Get driver wallet balance"
echo "• process_earnings_deposit - Deposit delivery earnings"
echo "• process_withdrawal - Create withdrawal requests"
echo "• get_transaction_history - Get transaction history"
echo "• validate_withdrawal - Validate withdrawal requests"
echo "• get_wallet_settings - Get wallet settings"
echo "• update_wallet_settings - Update wallet settings"
echo "• get_withdrawal_requests - Get withdrawal requests"
echo ""

print_success "Driver Wallet Edge Function deployment complete! 🎉"

# Optional: Run tests if test file exists
if [ -f "supabase/functions/driver-wallet-operations/test.ts" ]; then
    echo ""
    read -p "Do you want to run the test suite? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Running test suite..."
        cd supabase/functions/driver-wallet-operations
        if deno test --allow-net --allow-env test.ts; then
            print_success "All tests passed!"
        else
            print_warning "Some tests failed - check the output above"
        fi
        cd ../../..
    fi
fi

echo ""
print_status "For troubleshooting, check:"
echo "• Function logs: supabase functions logs driver-wallet-operations"
echo "• Database logs: supabase logs"
echo "• Function status: supabase functions list"
echo ""
print_success "Deployment script completed!"
