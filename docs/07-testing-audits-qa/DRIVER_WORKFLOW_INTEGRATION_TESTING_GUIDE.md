# Driver Workflow Integration Testing Guide

## Overview

This guide provides comprehensive instructions for running and maintaining the GigaEats driver workflow integration tests. The test suite validates the complete end-to-end driver workflow system including state management, error handling, real-time updates, and performance characteristics.

## Test Suite Architecture

### Test Structure
```
test/integration/
├── comprehensive_driver_workflow_integration_test.dart  # Main integration test suite
├── driver_workflow_integration_test.dart               # Legacy integration tests
├── enhanced_driver_workflow_test.dart                  # Enhanced workflow tests
└── test_driver_workflow_complete.dart                  # Complete workflow validation
```

### Test Categories

#### 1. End-to-End Workflow Progression Tests
- **Complete 7-Step Workflow**: Validates entire workflow from order acceptance to delivery completion
- **Workflow Interruption and Recovery**: Tests system recovery after interruptions
- **State Persistence**: Ensures workflow state is maintained across app restarts

#### 2. State Machine Validation Tests
- **Valid Transitions**: Tests all valid status transitions in the workflow
- **Invalid Transition Rejection**: Ensures invalid transitions are properly rejected
- **Available Actions**: Validates correct actions are available for each status

#### 3. Error Handling and Recovery Tests
- **Network Failure Recovery**: Tests retry logic and network failure handling
- **Database Constraint Violations**: Tests handling of database errors
- **Permission Error Handling**: Tests unauthorized access scenarios

#### 4. Real-time Updates and Synchronization Tests
- **Real-time Order Updates**: Tests Supabase real-time subscriptions
- **Concurrent Order Updates**: Tests handling of concurrent status changes
- **Subscription Management**: Tests proper subscription lifecycle management

#### 5. Performance and Load Tests
- **Multiple Workflow Operations**: Tests system performance under load
- **Stress Conditions**: Tests rapid status transitions and high-frequency operations
- **Resource Management**: Tests memory and resource usage

#### 6. Data Integrity and Consistency Tests
- **Workflow Data Consistency**: Ensures data remains consistent across workflow steps
- **Database Rollback Scenarios**: Tests transaction rollback handling
- **Timestamp Management**: Validates proper timestamp updates

#### 7. Integration with External Systems Tests
- **Earnings Tracking Integration**: Tests integration with driver earnings system
- **Notification System Integration**: Tests notification system integration
- **GPS Tracking Integration**: Tests location tracking integration

## Running the Tests

### Prerequisites
1. **Test Environment Setup**:
   ```bash
   # Ensure test environment is configured
   flutter test --help
   ```

2. **Supabase Test Configuration**:
   - Test database with proper schema
   - Test user accounts (driver, customer, vendor)
   - Proper RLS policies for testing

3. **Test Data Setup**:
   - Test driver account: `driver.test@gigaeats.com`
   - Test vendor and customer accounts
   - Clean test database state

### Running Individual Test Groups

#### Complete Integration Test Suite
```bash
# Run the comprehensive integration test suite
flutter test test/integration/comprehensive_driver_workflow_integration_test.dart

# Run with verbose output
flutter test test/integration/comprehensive_driver_workflow_integration_test.dart --verbose

# Run specific test group
flutter test test/integration/comprehensive_driver_workflow_integration_test.dart --name "End-to-End Workflow Progression Tests"
```

#### Legacy Integration Tests
```bash
# Run legacy integration tests
flutter test test/integration/driver_workflow_integration_test.dart

# Run enhanced workflow tests
flutter test test/integration/enhanced_driver_workflow_test.dart
```

#### Complete Workflow Validation
```bash
# Run complete workflow validation script
dart test/integration/test_driver_workflow_complete.dart
```

### Running All Integration Tests
```bash
# Run all integration tests
flutter test test/integration/

# Run with coverage
flutter test test/integration/ --coverage
```

## Test Configuration

### Test Helper Configuration
The tests use `DriverTestHelpers` for common operations:

```dart
// Test configuration in test/utils/driver_test_helpers.dart
static const testConfig = {
  'supabaseUrl': 'https://abknoalhfltlhhdbclpv.supabase.co',
  'testDriverId': '087132e7-e38b-4d3f-b28c-7c34b75e86c4',
  'testDriverUserId': '5a400967-c68e-48fa-a222-ef25249de974',
  'testVendorId': 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
  'testCustomerId': 'customer_test_id',
  'testDriverEmail': 'driver.test@gigaeats.com',
  'testDriverPassword': 'Testpass123!',
};
```

### Environment Variables
Set up environment variables for testing:
```bash
export SUPABASE_TEST_URL="your-test-supabase-url"
export SUPABASE_TEST_ANON_KEY="your-test-anon-key"
export TEST_DRIVER_EMAIL="driver.test@gigaeats.com"
export TEST_DRIVER_PASSWORD="Testpass123!"
```

## Test Data Management

### Test Order Creation
```dart
// Create test order
final testOrderId = await DriverTestHelpers.createTestOrder(
  supabase,
  customerId: 'test-customer-id',
  vendorId: 'test-vendor-id',
);
```

### Test Order Cleanup
```dart
// Clean up test order
await DriverTestHelpers.cleanupTestOrder(supabase, testOrderId);
```

### Bulk Test Data Management
```dart
// Create multiple test orders
final orderIds = await DriverTestHelpers.createBulkTestOrders(
  supabase,
  count: 5,
  vendorId: 'test-vendor-id',
  customerId: 'test-customer-id',
);

// Clean up bulk test orders
await DriverTestHelpers.cleanupBulkTestOrders(supabase, orderIds);
```

## Test Validation Patterns

### Workflow Progression Validation
```dart
// Validate complete workflow progression
final workflowSteps = [
  (DriverOrderStatus.assigned, DriverOrderStatus.onRouteToVendor),
  (DriverOrderStatus.onRouteToVendor, DriverOrderStatus.arrivedAtVendor),
  (DriverOrderStatus.arrivedAtVendor, DriverOrderStatus.pickedUp),
  (DriverOrderStatus.pickedUp, DriverOrderStatus.onRouteToCustomer),
  (DriverOrderStatus.onRouteToCustomer, DriverOrderStatus.arrivedAtCustomer),
  (DriverOrderStatus.arrivedAtCustomer, DriverOrderStatus.delivered),
];

for (final (fromStatus, toStatus) in workflowSteps) {
  final result = await workflowService.processOrderStatusChange(
    orderId: testOrderId,
    fromStatus: fromStatus,
    toStatus: toStatus,
    driverId: testDriverId,
  );
  
  expect(result.isSuccess, isTrue);
  
  // Verify database state
  final order = await DriverTestHelpers.getTestOrder(supabase, testOrderId);
  expect(order['status'], equals(toStatus.value));
}
```

### Error Handling Validation
```dart
// Test error handling
final result = await errorHandler.handleWorkflowOperation<void>(
  operation: () async {
    // Operation that should fail
    throw Exception('Test error');
  },
  operationName: 'test_operation',
  maxRetries: 3,
);

expect(result.isSuccess, isFalse);
expect(result.error?.type, equals(WorkflowErrorType.unknown));
```

### Real-time Updates Validation
```dart
// Test real-time updates
final statusUpdates = <String>[];
final subscription = supabase
    .from('orders')
    .stream(primaryKey: ['id'])
    .eq('id', testOrderId)
    .listen((data) {
      if (data.isNotEmpty) {
        statusUpdates.add(data.first['status'] as String);
      }
    });

// Perform status update
await workflowService.processOrderStatusChange(/*...*/);

// Verify real-time update received
expect(statusUpdates, contains('new_status'));

await subscription.cancel();
```

## Performance Testing Guidelines

### Load Testing
```dart
test('should handle multiple workflow operations efficiently', () async {
  final stopwatch = Stopwatch()..start();
  
  // Create multiple test orders
  final orderIds = <String>[];
  for (int i = 0; i < 5; i++) {
    final orderId = await DriverTestHelpers.createTestOrder(/*...*/);
    orderIds.add(orderId);
  }
  
  // Process all orders concurrently
  final futures = orderIds.map((orderId) async {
    await DriverTestHelpers.updateOrderStatus(/*...*/);
    return workflowService.processOrderStatusChange(/*...*/);
  });
  
  final results = await Future.wait(futures);
  stopwatch.stop();
  
  // Verify performance
  expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds max
  
  // Verify all operations succeeded
  for (final result in results) {
    expect(result.isSuccess, isTrue);
  }
});
```

### Stress Testing
```dart
test('should maintain performance under stress conditions', () async {
  // Test rapid status transitions
  final stopwatch = Stopwatch()..start();
  
  // Rapid workflow progression
  await workflowService.processOrderStatusChange(/*...*/);
  await workflowService.processOrderStatusChange(/*...*/);
  await workflowService.processOrderStatusChange(/*...*/);
  
  stopwatch.stop();
  
  // Should complete rapid transitions efficiently
  expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // 3 seconds max
});
```

## Debugging Test Failures

### Common Test Failure Scenarios

#### 1. Authentication Failures
```dart
// Ensure proper test authentication
await DriverTestHelpers.authenticateAsTestDriver(supabase);
```

#### 2. Database State Issues
```dart
// Clean up test data before each test
await DriverTestHelpers.cleanupTestOrder(supabase, testOrderId);
```

#### 3. Provider State Issues
```dart
// Dispose provider container properly
container.dispose();
```

#### 4. Real-time Subscription Issues
```dart
// Cancel subscriptions properly
await subscription.cancel();
```

### Test Debugging Tools

#### Enhanced Logging
```dart
// Enable comprehensive logging
DriverWorkflowLogger.setEnabled(true);

// Log test operations
DriverWorkflowLogger.logDatabaseOperation(
  operation: 'test_operation',
  orderId: testOrderId,
  context: 'integration_test',
);
```

#### Test State Inspection
```dart
// Inspect test order state
final order = await DriverTestHelpers.getTestOrder(supabase, testOrderId);
print('Order state: ${order['status']}');
print('Driver assigned: ${order['assigned_driver_id']}');
```

## Continuous Integration

### CI/CD Integration
```yaml
# .github/workflows/integration-tests.yml
name: Integration Tests
on: [push, pull_request]

jobs:
  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test test/integration/
```

### Test Reporting
```bash
# Generate test coverage report
flutter test test/integration/ --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Maintenance Guidelines

### Regular Test Maintenance
1. **Update Test Data**: Keep test data current with schema changes
2. **Review Test Coverage**: Ensure new features have corresponding tests
3. **Performance Monitoring**: Monitor test execution times
4. **Cleanup Procedures**: Ensure proper test cleanup procedures

### Test Environment Maintenance
1. **Database Schema Updates**: Keep test database schema current
2. **Test Account Management**: Maintain test user accounts
3. **Configuration Updates**: Update test configuration as needed
4. **Dependency Updates**: Keep test dependencies current

## Best Practices

### Test Design Principles
1. **Isolation**: Each test should be independent and isolated
2. **Repeatability**: Tests should produce consistent results
3. **Clarity**: Test names and structure should be clear and descriptive
4. **Coverage**: Tests should cover all critical workflow paths
5. **Performance**: Tests should complete in reasonable time

### Test Data Management
1. **Clean State**: Start each test with clean state
2. **Proper Cleanup**: Clean up test data after each test
3. **Realistic Data**: Use realistic test data that matches production patterns
4. **Data Isolation**: Ensure test data doesn't interfere with other tests

### Error Handling in Tests
1. **Expected Failures**: Test both success and failure scenarios
2. **Error Validation**: Validate specific error types and messages
3. **Recovery Testing**: Test system recovery from error conditions
4. **Timeout Handling**: Handle test timeouts appropriately

This comprehensive integration testing guide ensures reliable, maintainable, and effective testing of the GigaEats driver workflow system.
