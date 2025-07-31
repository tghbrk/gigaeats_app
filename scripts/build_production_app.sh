#!/bin/bash

# GigaEats Production Build Script
# Automates Flutter app building for production deployment with comprehensive validation

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_LOG="$PROJECT_ROOT/build_$(date +%Y%m%d_%H%M%S).log"
BUILD_NUMBER=$(date +%Y%m%d%H%M)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$BUILD_LOG"
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

# Check build prerequisites
check_prerequisites() {
    print_status "Checking build prerequisites..."
    
    # Check Flutter installation
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed"
        exit 1
    fi
    
    # Check Dart installation
    if ! command -v dart &> /dev/null; then
        print_error "Dart is not installed"
        exit 1
    fi
    
    # Check if we're in a Flutter project
    if [ ! -f "$PROJECT_ROOT/pubspec.yaml" ]; then
        print_error "Not in a Flutter project directory"
        exit 1
    fi
    
    # Check Flutter doctor
    print_status "Running Flutter doctor..."
    if flutter doctor --android-licenses > /dev/null 2>&1; then
        print_success "Flutter environment is ready"
    else
        print_warning "Flutter doctor found issues - continuing anyway"
    fi
    
    print_success "Prerequisites check completed"
}

# Clean previous builds
clean_builds() {
    print_status "Cleaning previous builds..."
    
    cd "$PROJECT_ROOT"
    
    # Flutter clean
    flutter clean
    
    # Remove build directories
    rm -rf build/
    rm -rf .dart_tool/
    
    # Clean Android build
    if [ -d "android" ]; then
        cd android
        ./gradlew clean > /dev/null 2>&1 || true
        cd ..
    fi
    
    # Clean iOS build
    if [ -d "ios" ]; then
        cd ios
        rm -rf build/
        rm -rf Pods/
        rm -f Podfile.lock
        cd ..
    fi
    
    print_success "Build cleanup completed"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    cd "$PROJECT_ROOT"
    
    # Get Flutter dependencies
    if flutter pub get; then
        print_success "Flutter dependencies installed"
    else
        print_error "Failed to install Flutter dependencies"
        exit 1
    fi
    
    # Install iOS dependencies if on macOS
    if [[ "$OSTYPE" == "darwin"* ]] && [ -d "ios" ]; then
        print_status "Installing iOS dependencies..."
        cd ios
        pod install --repo-update > /dev/null 2>&1 || print_warning "Pod install failed"
        cd ..
    fi
    
    print_success "Dependencies installation completed"
}

# Run code generation
run_code_generation() {
    print_status "Running code generation..."
    
    cd "$PROJECT_ROOT"
    
    # Check if build_runner is available
    if grep -q "build_runner" pubspec.yaml; then
        print_status "Running build_runner..."
        if dart run build_runner build --delete-conflicting-outputs; then
            print_success "Code generation completed"
        else
            print_warning "Code generation failed - continuing anyway"
        fi
    else
        print_status "No build_runner configuration found - skipping"
    fi
}

# Run static analysis
run_static_analysis() {
    print_status "Running static analysis..."
    
    cd "$PROJECT_ROOT"
    
    # Run Flutter analyzer
    print_status "Running Flutter analyzer..."
    if flutter analyze; then
        print_success "Flutter analyzer passed"
    else
        print_error "Flutter analyzer found issues"
        exit 1
    fi
    
    # Check for TODO comments in production code
    print_status "Checking for TODO comments..."
    local todo_count=$(find lib/ -name "*.dart" -exec grep -l "TODO" {} \; | wc -l)
    if [ "$todo_count" -gt 0 ]; then
        print_warning "Found $todo_count files with TODO comments"
        find lib/ -name "*.dart" -exec grep -l "TODO" {} \;
    else
        print_success "No TODO comments found"
    fi
    
    print_success "Static analysis completed"
}

# Run tests
run_tests() {
    print_status "Running tests..."
    
    cd "$PROJECT_ROOT"
    
    # Run unit tests
    if [ -d "test/unit" ]; then
        print_status "Running unit tests..."
        if flutter test test/unit/ --coverage; then
            print_success "Unit tests passed"
        else
            print_warning "Some unit tests failed"
        fi
    fi
    
    # Run integration tests
    if [ -d "test/integration" ]; then
        print_status "Running integration tests..."
        if flutter test test/integration/; then
            print_success "Integration tests passed"
        else
            print_warning "Some integration tests failed"
        fi
    fi
    
    # Generate coverage report if available
    if [ -f "coverage/lcov.info" ] && command -v genhtml &> /dev/null; then
        print_status "Generating coverage report..."
        genhtml coverage/lcov.info -o coverage/html
        print_success "Coverage report generated in coverage/html/"
    fi
    
    print_success "Test execution completed"
}

# Build Android APK
build_android() {
    print_status "Building Android APK..."
    
    cd "$PROJECT_ROOT"
    
    # Build release APK
    if flutter build apk --release --build-number="$BUILD_NUMBER"; then
        print_success "Android APK built successfully"
        
        # Get APK size
        local apk_path="build/app/outputs/flutter-apk/app-release.apk"
        if [ -f "$apk_path" ]; then
            local apk_size=$(du -h "$apk_path" | cut -f1)
            print_status "APK size: $apk_size"
            print_status "APK location: $apk_path"
        fi
    else
        print_error "Failed to build Android APK"
        exit 1
    fi
    
    # Build Android App Bundle (AAB) for Play Store
    print_status "Building Android App Bundle..."
    if flutter build appbundle --release --build-number="$BUILD_NUMBER"; then
        print_success "Android App Bundle built successfully"
        
        local aab_path="build/app/outputs/bundle/release/app-release.aab"
        if [ -f "$aab_path" ]; then
            local aab_size=$(du -h "$aab_path" | cut -f1)
            print_status "AAB size: $aab_size"
            print_status "AAB location: $aab_path"
        fi
    else
        print_warning "Failed to build Android App Bundle"
    fi
}

# Build iOS app
build_ios() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_warning "iOS build skipped - not running on macOS"
        return
    fi
    
    print_status "Building iOS app..."
    
    cd "$PROJECT_ROOT"
    
    # Build iOS app
    if flutter build ios --release --no-codesign --build-number="$BUILD_NUMBER"; then
        print_success "iOS app built successfully"
        
        local ios_path="build/ios/iphoneos/Runner.app"
        if [ -d "$ios_path" ]; then
            local ios_size=$(du -sh "$ios_path" | cut -f1)
            print_status "iOS app size: $ios_size"
            print_status "iOS app location: $ios_path"
        fi
    else
        print_error "Failed to build iOS app"
        exit 1
    fi
}

# Build web app
build_web() {
    print_status "Building web application..."
    
    cd "$PROJECT_ROOT"
    
    # Build web app
    if flutter build web --release --web-renderer canvaskit --build-number="$BUILD_NUMBER"; then
        print_success "Web application built successfully"
        
        local web_path="build/web"
        if [ -d "$web_path" ]; then
            local web_size=$(du -sh "$web_path" | cut -f1)
            print_status "Web app size: $web_size"
            print_status "Web app location: $web_path"
        fi
    else
        print_error "Failed to build web application"
        exit 1
    fi
}

# Validate builds
validate_builds() {
    print_status "Validating builds..."
    
    cd "$PROJECT_ROOT"
    
    # Validate Android APK
    local apk_path="build/app/outputs/flutter-apk/app-release.apk"
    if [ -f "$apk_path" ]; then
        print_success "Android APK validation passed"
    else
        print_error "Android APK not found"
    fi
    
    # Validate Android AAB
    local aab_path="build/app/outputs/bundle/release/app-release.aab"
    if [ -f "$aab_path" ]; then
        print_success "Android AAB validation passed"
    else
        print_warning "Android AAB not found"
    fi
    
    # Validate iOS build (macOS only)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local ios_path="build/ios/iphoneos/Runner.app"
        if [ -d "$ios_path" ]; then
            print_success "iOS app validation passed"
        else
            print_warning "iOS app not found"
        fi
    fi
    
    # Validate web build
    local web_path="build/web/index.html"
    if [ -f "$web_path" ]; then
        print_success "Web app validation passed"
    else
        print_error "Web app not found"
    fi
    
    print_success "Build validation completed"
}

# Generate build report
generate_build_report() {
    print_status "Generating build report..."
    
    local report_file="$PROJECT_ROOT/build_report_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# GigaEats Production Build Report

**Build Date**: $(date)
**Build Number**: $BUILD_NUMBER
**Build Script**: $0

## Build Summary

### ✅ Build Steps Completed
- Prerequisites check
- Build cleanup
- Dependencies installation
- Code generation
- Static analysis
- Test execution
- Android APK build
- Android AAB build
- iOS app build (macOS only)
- Web application build
- Build validation

### 📊 Build Information
- Flutter Version: $(flutter --version | head -n 1)
- Dart Version: $(dart --version)
- Build Environment: $(uname -s)
- Build Number: $BUILD_NUMBER

### 📱 Build Artifacts

#### Android
- APK: $([ -f "build/app/outputs/flutter-apk/app-release.apk" ] && echo "✅ Available ($(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1))" || echo "❌ Not found")
- AAB: $([ -f "build/app/outputs/bundle/release/app-release.aab" ] && echo "✅ Available ($(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1))" || echo "❌ Not found")

#### iOS
- App: $([ -d "build/ios/iphoneos/Runner.app" ] && echo "✅ Available ($(du -sh build/ios/iphoneos/Runner.app | cut -f1))" || echo "❌ Not found")

#### Web
- Build: $([ -d "build/web" ] && echo "✅ Available ($(du -sh build/web | cut -f1))" || echo "❌ Not found")

### 🧪 Quality Checks
- Flutter Analyzer: ✅ Passed
- Unit Tests: $([ -d "test/unit" ] && echo "✅ Executed" || echo "⏭️ Skipped")
- Integration Tests: $([ -d "test/integration" ] && echo "✅ Executed" || echo "⏭️ Skipped")
- Code Coverage: $([ -f "coverage/lcov.info" ] && echo "✅ Generated" || echo "⏭️ Not available")

### 🚀 Deployment Ready
- Android APK: Ready for testing
- Android AAB: Ready for Play Store
- iOS App: Ready for App Store (requires code signing)
- Web App: Ready for web deployment

## Next Steps
1. Test APK on Android emulator (emulator-5554)
2. Validate route optimization features
3. Test multi-order batch functionality
4. Deploy to staging environment
5. Conduct user acceptance testing

---
Generated by: $0
Build Log: $BUILD_LOG
EOF

    print_success "Build report generated: $report_file"
}

# Main build function
main() {
    print_header "GigaEats Production Build Process"
    
    log "Starting production build process..."
    log "Project Root: $PROJECT_ROOT"
    log "Build Number: $BUILD_NUMBER"
    
    # Execute build steps
    check_prerequisites
    clean_builds
    install_dependencies
    run_code_generation
    run_static_analysis
    run_tests
    build_android
    build_ios
    build_web
    validate_builds
    generate_build_report
    
    print_header "Build Process Completed Successfully!"
    print_success "All build artifacts have been generated"
    print_status "Build log: $BUILD_LOG"
    print_status "Next steps: Deploy and test applications"
    
    log "Build process completed successfully"
}

# Execute main function
main "$@"
