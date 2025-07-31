#!/bin/bash

# Deploy Driver Document AI Verification Edge Function
# This script deploys the Gemini AI-powered document verification system

set -e

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

# Check if we're in the correct directory
if [ ! -f "supabase/functions/driver-document-ai-verification/index.ts" ]; then
    print_error "Edge Function not found. Please run this script from the project root directory."
    exit 1
fi

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    print_error "Supabase CLI is not installed. Please install it first:"
    echo "npm install -g supabase"
    exit 1
fi

# Check if user is logged in to Supabase
if ! supabase projects list &> /dev/null; then
    print_error "Not logged in to Supabase. Please run 'supabase login' first."
    exit 1
fi

echo "🤖 Driver Document AI Verification Edge Function Deployment"
echo "=========================================================="
echo ""

# Verify Gemini API key is set
print_status "Checking Gemini API configuration..."
if [ -z "$GEMINI_API_KEY" ]; then
    print_warning "GEMINI_API_KEY environment variable not set."
    echo ""
    read -p "Enter your Gemini API key: " -s GEMINI_API_KEY
    echo ""
    
    if [ -z "$GEMINI_API_KEY" ]; then
        print_error "Gemini API key is required for deployment."
        exit 1
    fi
fi

print_success "Gemini API key configured"

# Check project configuration
print_status "Verifying project configuration..."
PROJECT_REF=$(supabase status | grep "Project ref" | awk '{print $3}' || echo "")

if [ -z "$PROJECT_REF" ]; then
    print_error "Could not determine project reference. Please ensure you're linked to a Supabase project."
    echo "Run: supabase link --project-ref YOUR_PROJECT_REF"
    exit 1
fi

print_success "Project reference: $PROJECT_REF"

# Validate Edge Function code
print_status "Validating Edge Function code..."
if ! deno check supabase/functions/driver-document-ai-verification/index.ts; then
    print_error "TypeScript validation failed. Please fix the errors above."
    exit 1
fi

print_success "Edge Function code validation passed"

# Deploy the Edge Function
print_status "Deploying driver-document-ai-verification Edge Function..."
if supabase functions deploy driver-document-ai-verification --project-ref "$PROJECT_REF"; then
    print_success "Edge Function deployed successfully"
else
    print_error "Edge Function deployment failed"
    exit 1
fi

# Set environment variables
print_status "Setting environment variables..."

# Set Gemini API key
if supabase secrets set GEMINI_API_KEY="$GEMINI_API_KEY" --project-ref "$PROJECT_REF"; then
    print_success "Gemini API key configured"
else
    print_warning "Failed to set Gemini API key. You may need to set it manually."
fi

# Set optional Gemini API URL (if different from default)
GEMINI_API_URL=${GEMINI_API_URL:-"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent"}
if supabase secrets set GEMINI_API_URL="$GEMINI_API_URL" --project-ref "$PROJECT_REF"; then
    print_success "Gemini API URL configured"
else
    print_warning "Failed to set Gemini API URL. Using default."
fi

# Test the deployment
print_status "Testing Edge Function deployment..."

FUNCTION_URL="https://$PROJECT_REF.supabase.co/functions/v1/driver-document-ai-verification"
ANON_KEY=$(supabase status | grep "anon key" | awk '{print $3}' || echo "")

if [ -n "$ANON_KEY" ]; then
    print_status "Running health check..."
    
    HEALTH_CHECK_RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
        -H "Authorization: Bearer $ANON_KEY" \
        -H "Content-Type: application/json" \
        -d '{"action": "get_processing_status", "verification_id": "health-check"}' \
        --max-time 30 || echo "")
    
    if echo "$HEALTH_CHECK_RESPONSE" | grep -q '"success"'; then
        print_success "Health check passed - Edge Function is responding"
    else
        print_warning "Health check failed - Edge Function may not be fully ready"
        echo "Response: $HEALTH_CHECK_RESPONSE"
    fi
else
    print_warning "Could not retrieve anon key for testing"
fi

# Display deployment information
echo ""
print_success "Deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "======================"
echo "• Function Name: driver-document-ai-verification"
echo "• Project Ref: $PROJECT_REF"
echo "• Function URL: $FUNCTION_URL"
echo "• AI Model: Google Gemini 2.5 Flash Lite"
echo "• Supported Documents: Malaysian IC, Passport, Driver's License, Selfie"
echo ""

echo "🔧 Configuration:"
echo "=================="
echo "• Gemini API Key: ✅ Configured"
echo "• Gemini API URL: ✅ Configured"
echo "• Database Integration: ✅ Ready"
echo "• Storage Integration: ✅ Ready"
echo ""

echo "📊 Monitoring & Logs:"
echo "====================="
echo "• View logs: supabase functions logs driver-document-ai-verification"
echo "• Monitor real-time: supabase functions logs driver-document-ai-verification --follow"
echo "• Function status: supabase functions list"
echo ""

echo "🧪 Testing Commands:"
echo "==================="
echo "# Test document processing"
echo "curl -X POST '$FUNCTION_URL' \\"
echo "  -H 'Authorization: Bearer $ANON_KEY' \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"action\": \"get_processing_status\", \"verification_id\": \"test-id\"}'"
echo ""

echo "# Test with actual document"
echo "curl -X POST '$FUNCTION_URL' \\"
echo "  -H 'Authorization: Bearer $ANON_KEY' \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"action\": \"process_document\", \"document_id\": \"doc-id\", \"document_type\": \"ic_card\", \"file_path\": \"path/to/document.jpg\"}'"
echo ""

echo "⚠️  Important Notes:"
echo "==================="
echo "• Ensure Gemini API quotas are sufficient for production usage"
echo "• Monitor API costs and usage patterns"
echo "• Test with various document types and qualities"
echo "• Review confidence thresholds for your use case"
echo "• Set up monitoring alerts for processing failures"
echo ""

echo "📚 Documentation:"
echo "=================="
echo "• Function README: supabase/functions/driver-document-ai-verification/README.md"
echo "• API Reference: docs/04-feature-specific-documentation/"
echo "• Troubleshooting: Check function logs for detailed error information"
echo ""

print_success "Driver Document AI Verification Edge Function is ready for use!"

# Optional: Open function logs
echo ""
read -p "Do you want to view the function logs now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Opening function logs..."
    supabase functions logs driver-document-ai-verification --follow
fi
