# GigaEats Driver Wallet System - Integration Testing Guide

## 🎯 Overview

This comprehensive guide provides detailed instructions for running and validating the complete GigaEats Driver Wallet System integration tests. The test suite validates all components working together including wallet management, earnings processing, real-time updates, notifications, and security.

## 🚀 Quick Start

### Prerequisites

```bash
# Ensure Flutter environment is ready
flutter doctor

# Ensure Android emulator is running
flutter emulators --launch Pixel_7_API_34
adb devices  # Should show emulator-5554

# Install dependencies
flutter pub get

# Ensure Supabase connection
# Project ID: abknoalhfltlhhdbclpv
```

### Run All Integration Tests

```bash
# Run complete integration test suite
flutter test test/integration/driver_wallet_system_integration_test.dart

# Run specific component tests
flutter test test/integration/driver_wallet_earnings_test.dart
flutter test test/features/drivers/integration/driver_wallet_realtime_notifications_integration_test.dart

# Run Android emulator tests
dart test/scripts/driver_wallet_android_emulator_test.dart --verbose

# Run backend validation
dart test/integration/driver_wallet_validation_script.dart
```

## 📋 Test Suite Architecture

### Integration Test Structure

```
test/integration/
├── driver_wallet_system_integration_test.dart          # Main integration test suite
├── driver_wallet_earnings_test.dart                    # Earnings processing tests
├── driver_wallet_validation_script.dart                # Backend validation script
└── driver_wallet_realtime_notifications_integration_test.dart  # Notification tests

test/scripts/
└── driver_wallet_android_emulator_test.dart           # Android emulator testing script

test/features/drivers/
├── presentation/providers/
│   └── driver_wallet_notification_provider_test.dart  # Unit tests for notification provider
└── integration/
    └── driver_wallet_realtime_notifications_integration_test.dart  # Real-time integration tests
```

## 🧪 Test Categories

### 1. End-to-End Workflow Integration

**File:** `test/integration/driver_wallet_system_integration_test.dart`

**Coverage:**
- Complete earnings-to-wallet-to-notification flow
- Withdrawal request processing with notifications
- Real-time wallet and transaction updates
- Error handling and recovery mechanisms
- Performance validation

**Key Tests:**
- `should complete full earnings-to-wallet-to-notification flow`
- `should handle withdrawal request with notifications`
- `should handle real-time wallet updates`
- `should respect notification preferences`
- `should handle notification errors without affecting wallet operations`

### 2. Earnings Processing Integration

**File:** `test/integration/driver_wallet_earnings_test.dart`

**Coverage:**
- Earnings deposit processing
- Complex earnings breakdown handling
- Multiple earnings processing
- Wallet state management during earnings
- Performance under load

**Key Tests:**
- `should process earnings deposit successfully`
- `should handle multiple earnings deposits`
- `should handle complex earnings breakdown`
- `should maintain loading state during earnings processing`
- `should handle rapid earnings processing`

### 3. Real-time Notifications Integration

**File:** `test/features/drivers/integration/driver_wallet_realtime_notifications_integration_test.dart`

**Coverage:**
- Earnings notification triggering
- Low balance alert detection
- Withdrawal notification processing
- Notification preference handling
- Error resilience

**Key Tests:**
- `should send earnings notification when processing earnings deposit`
- `should detect low balance and provide alert data`
- `should send withdrawal notification when processing withdrawal`
- `should respect notification preferences`
- `should handle notification errors gracefully`

### 4. Android Emulator Testing

**File:** `test/scripts/driver_wallet_android_emulator_test.dart`

**Coverage:**
- Complete Android emulator workflow testing
- Hot restart methodology validation
- Performance benchmarking
- UI component integration
- Real device behavior validation

**Phases:**
1. Environment Setup
2. Wallet Creation & Loading
3. Earnings Processing Flow
4. Real-time Updates
5. Notification System
6. Withdrawal Processing
7. Low Balance Alerts
8. Error Handling
9. Performance Validation

### 5. Backend Validation

**File:** `test/integration/driver_wallet_validation_script.dart`

**Coverage:**
- Database schema validation
- CRUD operations testing
- Edge Function integration
- Real-time functionality
- Security policies (RLS)
- Transaction management

**Phases:**
1. Database Schema Validation
2. Driver Wallet CRUD Operations
3. Earnings Processing Integration
4. Transaction Management
5. Real-time Functionality
6. Security & RLS Policies
7. Edge Function Integration

## 🔧 Running Specific Test Scenarios

### Scenario 1: Complete Earnings Flow

```bash
# Test complete earnings processing from order completion to notification
flutter test test/integration/driver_wallet_earnings_test.dart \
  --name "should complete full earnings-to-wallet-to-notification flow"
```

### Scenario 2: Real-time Updates

```bash
# Test real-time wallet and transaction updates
flutter test test/integration/driver_wallet_system_integration_test.dart \
  --name "should handle real-time wallet updates"
```

### Scenario 3: Notification System

```bash
# Test notification system integration
flutter test test/features/drivers/integration/driver_wallet_realtime_notifications_integration_test.dart \
  --name "should send earnings notification when processing earnings deposit"
```

### Scenario 4: Error Handling

```bash
# Test error handling and recovery
flutter test test/integration/driver_wallet_system_integration_test.dart \
  --name "should handle notification errors without affecting wallet operations"
```

### Scenario 5: Performance Testing

```bash
# Run Android emulator performance tests
dart test/scripts/driver_wallet_android_emulator_test.dart \
  --include-performance --verbose
```

## 📊 Test Reporting

### Automated Reports

All test scripts generate comprehensive reports:

- **Integration Test Reports:** `test_reports/driver_wallet_integration_report.html`
- **Android Emulator Reports:** `test_reports/driver_wallet_android_emulator_test_report.md`
- **Backend Validation Reports:** `test_reports/driver_wallet_validation_report.md`

### Report Contents

Each report includes:
- Test execution summary (passed/failed/total)
- Detailed test results with timing
- Error details and stack traces
- Performance metrics
- Configuration details
- Recommendations for failed tests

## 🛠️ Debugging Failed Tests

### Common Issues and Solutions

#### 1. Supabase Connection Errors

```bash
# Check Supabase connection
dart test/integration/driver_wallet_validation_script.dart

# Verify environment variables
echo $SUPABASE_URL
echo $SUPABASE_ANON_KEY
```

#### 2. Android Emulator Issues

```bash
# Restart emulator
flutter emulators --launch Pixel_7_API_34

# Verify emulator connection
adb devices
adb shell getprop ro.build.version.release
```

#### 3. Provider State Issues

```bash
# Run with verbose logging
flutter test test/integration/driver_wallet_system_integration_test.dart --verbose

# Check provider dependencies
flutter analyze lib/src/features/drivers/presentation/providers/
```

#### 4. Mock Service Issues

```bash
# Regenerate mocks
flutter packages pub run build_runner build --delete-conflicting-outputs

# Verify mock implementations
flutter test test/features/drivers/presentation/providers/driver_wallet_notification_provider_test.dart
```

## 🔄 Continuous Integration

### CI/CD Pipeline Integration

```yaml
# .github/workflows/driver_wallet_tests.yml
name: Driver Wallet Integration Tests

on: [push, pull_request]

jobs:
  integration_tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test test/integration/driver_wallet_system_integration_test.dart
      - run: dart test/integration/driver_wallet_validation_script.dart
```

### Test Coverage Requirements

- **Unit Tests:** >90% coverage for all providers and services
- **Integration Tests:** 100% coverage for critical user flows
- **End-to-End Tests:** Complete wallet lifecycle validation
- **Performance Tests:** Response time <2s for all operations

## 📈 Performance Benchmarks

### Expected Performance Metrics

| Operation | Target Time | Acceptable Range |
|-----------|-------------|------------------|
| Wallet Loading | <500ms | <1s |
| Earnings Processing | <1s | <2s |
| Notification Delivery | <200ms | <500ms |
| Real-time Updates | <100ms | <300ms |
| Withdrawal Request | <1s | <2s |

### Performance Test Commands

```bash
# Run performance benchmarks
dart test/scripts/driver_wallet_android_emulator_test.dart \
  --include-performance \
  --test-timeout 30

# Monitor real-time performance
flutter test test/integration/driver_wallet_system_integration_test.dart \
  --name "should handle rapid earnings processing"
```

## 🎯 Test Validation Checklist

Before considering the Driver Wallet System ready for production:

### ✅ Core Functionality
- [ ] Wallet creation and initialization
- [ ] Earnings processing and deposit
- [ ] Balance updates and calculations
- [ ] Transaction history management
- [ ] Withdrawal request processing

### ✅ Real-time Features
- [ ] Real-time wallet balance updates
- [ ] Real-time transaction notifications
- [ ] Supabase subscription management
- [ ] Connection recovery handling

### ✅ Notification System
- [ ] Earnings notifications
- [ ] Low balance alerts
- [ ] Withdrawal status updates
- [ ] Notification preferences
- [ ] Multi-channel delivery

### ✅ Security & Compliance
- [ ] RLS policy enforcement
- [ ] Data encryption validation
- [ ] Authentication integration
- [ ] Permission management
- [ ] Audit trail completeness

### ✅ Performance & Reliability
- [ ] Load testing under concurrent users
- [ ] Error handling and recovery
- [ ] Network failure resilience
- [ ] Memory usage optimization
- [ ] Battery usage optimization

### ✅ Integration Points
- [ ] Driver workflow integration
- [ ] Order completion integration
- [ ] Earnings calculation integration
- [ ] Marketplace payment integration
- [ ] Notification service integration

## 🚀 Production Readiness

Once all tests pass and validation is complete:

1. **Generate Final Report:** Run complete test suite and generate comprehensive report
2. **Performance Validation:** Confirm all performance benchmarks are met
3. **Security Audit:** Verify all security requirements are satisfied
4. **Documentation Review:** Ensure all documentation is up-to-date
5. **Deployment Preparation:** Prepare production deployment checklist

The Driver Wallet System is considered production-ready when all integration tests pass, performance benchmarks are met, and security requirements are validated.
