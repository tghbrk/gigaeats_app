# Enhanced Driver Interface Testing Guide

This document provides comprehensive testing guidelines for the enhanced driver interface with pre-navigation overview, route information, and navigation app selection features.

## Test Structure Overview

### 1. Widget Tests
- **Location**: `test/features/drivers/presentation/widgets/`
- **Purpose**: Test individual UI components in isolation
- **Coverage**: NavigationAppSelector, ElevationProfileWidget, RouteInformationCard, etc.

### 2. Integration Tests
- **Location**: `test/features/drivers/presentation/screens/`
- **Purpose**: Test complete screen workflows and component interactions
- **Coverage**: PreNavigationOverviewScreen, driver workflow integration

### 3. Service Tests
- **Location**: `test/features/drivers/data/services/`
- **Purpose**: Test business logic, caching, and data persistence
- **Coverage**: RouteCacheService, NavigationLocationService, EnhancedRouteService

### 4. Android Emulator Tests
- **Location**: `test/scripts/`
- **Purpose**: End-to-end testing on actual Android devices/emulators
- **Coverage**: Complete user workflows, performance, real device behavior

## Running Tests

### Prerequisites
```bash
# Ensure Flutter is properly set up
flutter doctor

# Install dependencies
flutter pub get

# For Android emulator tests, ensure emulator is running
flutter emulators --launch <emulator_id>
```

### Widget Tests
```bash
# Run all widget tests
flutter test test/features/drivers/presentation/widgets/

# Run specific widget test
flutter test test/features/drivers/presentation/widgets/navigation_app_selector_test.dart

# Run with coverage
flutter test --coverage test/features/drivers/presentation/widgets/
```

### Integration Tests
```bash
# Run integration tests
flutter test test/features/drivers/presentation/screens/

# Run specific integration test
flutter test test/features/drivers/presentation/screens/pre_navigation_overview_integration_test.dart
```

### Service Tests
```bash
# Run service tests
flutter test test/features/drivers/data/services/

# Run specific service test
flutter test test/features/drivers/data/services/route_cache_service_test.dart
```

### Android Emulator Tests
```bash
# Start Android emulator (emulator-5554)
flutter emulators --launch Pixel_4_API_30

# Run integration tests on emulator
flutter test integration_test/android_emulator_test.dart

# Run with specific device
flutter test integration_test/android_emulator_test.dart -d emulator-5554
```

## Test Coverage Areas

### 1. Navigation App Selection
- **Widget Tests**: App selection UI, preference persistence, availability detection
- **Integration Tests**: Selection workflow, preference saving/loading
- **Emulator Tests**: Real app detection, deep linking functionality

### 2. Pre-Navigation Overview
- **Widget Tests**: Route information display, loading states, error handling
- **Integration Tests**: Complete navigation workflow, location integration
- **Emulator Tests**: Real location services, GPS accuracy, network conditions

### 3. Route Information & Caching
- **Widget Tests**: Route display components, elevation profiles, traffic indicators
- **Service Tests**: Cache operations, serialization, expiry handling
- **Emulator Tests**: Cache performance, offline functionality

### 4. Location Services
- **Service Tests**: Location accuracy, permission handling, error scenarios
- **Integration Tests**: Location provider integration, state management
- **Emulator Tests**: Real GPS behavior, permission dialogs, location accuracy

## Test Data and Mocking

### Mock Data Setup
```dart
// Example mock route data
final mockRouteInfo = DetailedRouteInfo(
  distance: 5.2,
  duration: 15,
  polylinePoints: [mockOrigin, mockDestination],
  distanceText: '5.2 km',
  durationText: '15 min',
  steps: [/* mock steps */],
  elevationProfile: [/* mock elevation points */],
  trafficCondition: 'Light traffic',
  origin: mockOrigin,
  destination: mockDestination,
);
```

### SharedPreferences Mocking
```dart
setUp(() {
  SharedPreferences.setMockInitialValues({
    'preferred_navigation_app': 'google_maps',
    'route_avoid_tolls': false,
    'route_cache_enabled': true,
  });
});
```

## Performance Testing

### Key Metrics to Monitor
1. **Route Calculation Time**: < 3 seconds for typical routes
2. **Cache Access Time**: < 100ms for cached routes
3. **UI Responsiveness**: < 16ms frame rendering
4. **Memory Usage**: Monitor for memory leaks during navigation

### Performance Test Commands
```bash
# Profile app performance
flutter run --profile --trace-startup

# Analyze performance
flutter analyze --performance

# Memory profiling
flutter run --profile --enable-software-rendering
```

## Error Scenarios Testing

### 1. Network Connectivity
- Test offline route calculation
- Test cache fallback behavior
- Test error recovery mechanisms

### 2. Location Services
- Test permission denied scenarios
- Test location service disabled
- Test GPS accuracy issues

### 3. Navigation Apps
- Test unavailable navigation apps
- Test deep linking failures
- Test fallback navigation options

## Continuous Integration

### GitHub Actions Example
```yaml
name: Enhanced Driver Interface Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test test/features/drivers/
      - run: flutter test --coverage
```

## Test Maintenance

### Regular Test Updates
1. **Weekly**: Run full test suite on latest Flutter version
2. **Monthly**: Update mock data to reflect real-world scenarios
3. **Quarterly**: Review and update performance benchmarks

### Test Quality Metrics
- **Code Coverage**: Target 80%+ for critical navigation components
- **Test Reliability**: < 1% flaky test rate
- **Test Performance**: Complete test suite in < 5 minutes

## Debugging Test Issues

### Common Issues and Solutions

#### 1. Widget Test Failures
```dart
// Issue: Widget not found
// Solution: Use pumpAndSettle() for async operations
await tester.pumpAndSettle();

// Issue: State not updated
// Solution: Trigger widget rebuild
await tester.pump();
```

#### 2. Integration Test Timeouts
```dart
// Issue: Long-running operations
// Solution: Increase timeout
await tester.pumpAndSettle(const Duration(seconds: 10));
```

#### 3. Emulator Test Inconsistencies
- Ensure emulator has stable internet connection
- Use consistent emulator configuration
- Reset emulator state between test runs

### Test Logging
```dart
// Enable detailed logging for debugging
debugPrint('🧪 Test checkpoint: ${testDescription}');
print('📊 Performance metric: ${stopwatch.elapsedMilliseconds}ms');
```

## Best Practices

### 1. Test Organization
- Group related tests using `group()` blocks
- Use descriptive test names that explain the scenario
- Keep tests focused on single functionality

### 2. Test Data Management
- Use factory methods for creating test data
- Keep mock data realistic and representative
- Update test data when real data structures change

### 3. Async Testing
- Always use `await` for async operations
- Use `pumpAndSettle()` for complex UI updates
- Handle timeouts appropriately

### 4. Error Testing
- Test both success and failure scenarios
- Verify error messages are user-friendly
- Test error recovery mechanisms

## Reporting and Metrics

### Test Reports
- Generate coverage reports after each test run
- Track test execution time trends
- Monitor test reliability metrics

### Quality Gates
- All tests must pass before merging
- Coverage must not decrease below threshold
- Performance tests must meet benchmarks

This testing guide ensures comprehensive validation of the enhanced driver interface across all platforms and scenarios.
