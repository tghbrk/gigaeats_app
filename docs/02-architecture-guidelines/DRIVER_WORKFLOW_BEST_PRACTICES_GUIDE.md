# Driver Workflow Best Practices Guide

## Overview

This guide provides comprehensive best practices for developing, maintaining, and debugging driver workflow systems in the GigaEats Flutter application. These practices are derived from extensive debugging and optimization work on the driver workflow system.

## Architecture Best Practices

### State Management Architecture

#### 1. Provider Consolidation
**Problem**: Multiple providers managing the same data can cause conflicts and infinite loops.

**Solution**: Use unified providers for related functionality.

```dart
// ❌ Avoid: Multiple conflicting providers
final currentDriverOrderProvider = StreamProvider<DriverOrder?>(...);
final enhancedCurrentDriverOrderProvider = StreamProvider<DriverOrder?>(...);
final activeOrderProvider = StreamProvider<DriverOrder?>(...);

// ✅ Recommended: Single unified provider
final unifiedDriverWorkflowProvider = StreamProvider<DriverWorkflowState>(...);
```

**Best Practices**:
- Consolidate related providers into unified state management
- Use clear naming conventions to avoid confusion
- Document provider responsibilities and relationships
- Implement proper provider disposal and cleanup

#### 2. State Machine Design
**Problem**: Complex workflows without formal state machines can lead to invalid transitions.

**Solution**: Implement formal state machines with validation.

```dart
// ✅ Recommended: Formal state machine
class DriverOrderStateMachine {
  static const Map<DriverOrderStatus, List<DriverOrderStatus>> _validTransitions = {
    DriverOrderStatus.assigned: [
      DriverOrderStatus.onRouteToVendor,
      DriverOrderStatus.cancelled,
    ],
    // ... other transitions
  };

  static bool isValidTransition(DriverOrderStatus from, DriverOrderStatus to) {
    return _validTransitions[from]?.contains(to) ?? false;
  }

  static ValidationResult validateTransition(DriverOrderStatus from, DriverOrderStatus to) {
    if (!isValidTransition(from, to)) {
      return ValidationResult.invalid('Invalid transition from $from to $to');
    }
    return ValidationResult.valid();
  }
}
```

**Best Practices**:
- Define all valid state transitions explicitly
- Implement transition validation before state changes
- Add business rule validation for complex transitions
- Document state machine behavior and constraints

#### 3. Error Handling Architecture
**Problem**: Inconsistent error handling across the workflow system.

**Solution**: Implement centralized error handling with proper classification.

```dart
// ✅ Recommended: Centralized error handling
class DriverWorkflowErrorHandler {
  Future<WorkflowOperationResult<T>> handleWorkflowOperation<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    bool requiresNetwork = true,
  }) async {
    // Implementation with retry logic, network checking, and error classification
  }
}
```

**Best Practices**:
- Centralize error handling logic
- Classify errors by type (network, validation, permission, etc.)
- Implement appropriate retry strategies
- Provide user-friendly error messages
- Log errors with sufficient context for debugging

### Database Design Best Practices

#### 1. Enum Consistency
**Problem**: Mismatched enum values between frontend and database.

**Solution**: Implement proper enum conversion and validation.

```dart
// ✅ Recommended: Consistent enum handling
class EnhancedStatusConverter {
  static String toDatabase(DriverOrderStatus status) {
    switch (status) {
      case DriverOrderStatus.onRouteToVendor:
        return 'on_route_to_vendor';
      case DriverOrderStatus.arrivedAtVendor:
        return 'arrived_at_vendor';
      // ... other conversions
    }
  }

  static DriverOrderStatus fromDatabase(String status) {
    switch (status) {
      case 'on_route_to_vendor':
        return DriverOrderStatus.onRouteToVendor;
      case 'arrived_at_vendor':
        return DriverOrderStatus.arrivedAtVendor;
      // ... other conversions
    }
  }
}
```

**Best Practices**:
- Use consistent naming conventions (snake_case in database, camelCase in frontend)
- Implement conversion utilities for enum handling
- Validate enum values at boundaries
- Document enum mappings clearly

#### 2. RLS Policy Design
**Problem**: Inadequate Row-Level Security policies can cause permission errors.

**Solution**: Design comprehensive RLS policies from the start.

```sql
-- ✅ Recommended: Comprehensive RLS policy
CREATE POLICY "Drivers can update their assigned orders" ON orders
  FOR UPDATE USING (
    assigned_driver_id = auth.uid()::text
    AND status IN ('assigned', 'on_route_to_vendor', 'arrived_at_vendor', 'picked_up', 'on_route_to_customer', 'arrived_at_customer')
  );
```

**Best Practices**:
- Design RLS policies to match business requirements
- Test RLS policies thoroughly with different user roles
- Document policy intentions and constraints
- Implement proper error handling for RLS violations

#### 3. Database Triggers and Functions
**Problem**: Manual timestamp and status management can be error-prone.

**Solution**: Use database triggers for automatic updates.

```sql
-- ✅ Recommended: Automatic timestamp updates
CREATE OR REPLACE FUNCTION update_order_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  
  IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
    NEW.delivered_at = NOW();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER order_timestamp_trigger
  BEFORE UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_order_timestamps();
```

**Best Practices**:
- Use triggers for automatic timestamp management
- Implement data validation in database functions
- Create audit trails for important state changes
- Test trigger behavior thoroughly

## Development Best Practices

### Logging and Monitoring

#### 1. Structured Logging
**Problem**: Inconsistent logging makes debugging difficult.

**Solution**: Implement structured logging with consistent formatting.

```dart
// ✅ Recommended: Structured logging
class DriverWorkflowLogger {
  static void logStatusTransition({
    required String orderId,
    required String fromStatus,
    required String toStatus,
    String? driverId,
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    final message = '$_prefix Status Transition: $fromStatus → $toStatus | Order: ${orderId.substring(0, 8)}...';
    
    _logWithHistory(
      level: LogLevel.info,
      category: 'STATUS_TRANSITION',
      message: message,
      orderId: orderId,
      context: context,
      metadata: {
        'from_status': fromStatus,
        'to_status': toStatus,
        'driver_id': driverId,
        ...?metadata,
      },
    );
  }
}
```

**Best Practices**:
- Use consistent log formatting across the application
- Include relevant context in log messages
- Implement log levels for different types of information
- Create log history for debugging sessions
- Export logs for analysis when needed

#### 2. Performance Monitoring
**Problem**: Performance issues can be difficult to identify without proper monitoring.

**Solution**: Implement performance monitoring throughout the workflow.

```dart
// ✅ Recommended: Performance monitoring
class PerformanceMonitor {
  static Future<T> monitorOperation<T>({
    required String operationName,
    required Future<T> Function() operation,
    String? context,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      DriverWorkflowLogger.logPerformance(
        operation: operationName,
        duration: stopwatch.elapsed,
        context: context,
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      DriverWorkflowLogger.logError(
        operation: operationName,
        error: e.toString(),
        context: context,
      );
      rethrow;
    }
  }
}
```

**Best Practices**:
- Monitor critical operations for performance
- Set performance thresholds and alerts
- Track performance trends over time
- Optimize based on performance data

### Testing Strategies

#### 1. Integration Testing
**Problem**: Unit tests alone don't catch integration issues.

**Solution**: Implement comprehensive integration tests.

```dart
// ✅ Recommended: Comprehensive integration testing
group('End-to-End Workflow Progression Tests', () {
  test('should complete full 7-step workflow progression successfully', () async {
    // Test complete workflow from order acceptance to delivery
    final workflowSteps = [
      (DriverOrderStatus.assigned, DriverOrderStatus.onRouteToVendor),
      (DriverOrderStatus.onRouteToVendor, DriverOrderStatus.arrivedAtVendor),
      // ... other steps
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
  });
});
```

**Best Practices**:
- Test complete end-to-end workflows
- Test error scenarios and edge cases
- Test real-time updates and synchronization
- Test performance under load
- Maintain test data and cleanup procedures

#### 2. Mock and Stub Strategies
**Problem**: External dependencies can make tests unreliable.

**Solution**: Use proper mocking strategies for external dependencies.

```dart
// ✅ Recommended: Proper mocking
class MockDriverWorkflowService extends Mock implements DriverWorkflowService {}

test('should handle service failures gracefully', () async {
  final mockService = MockDriverWorkflowService();
  
  when(mockService.processOrderStatusChange(any, any, any, any))
      .thenThrow(Exception('Service unavailable'));
  
  final result = await errorHandler.handleWorkflowOperation(
    operation: () => mockService.processOrderStatusChange(/*...*/),
    operationName: 'test_operation',
  );
  
  expect(result.isSuccess, isFalse);
  expect(result.error?.type, equals(WorkflowErrorType.unknown));
});
```

**Best Practices**:
- Mock external services and dependencies
- Test both success and failure scenarios
- Use dependency injection for testability
- Maintain mock implementations alongside real implementations

## Debugging Best Practices

### Systematic Debugging Approach

#### 1. Problem Identification
**Process**:
1. **Reproduce the Issue**: Ensure the issue can be consistently reproduced
2. **Gather Information**: Collect logs, error messages, and system state
3. **Isolate the Problem**: Identify the specific component or operation failing
4. **Analyze Dependencies**: Check related systems and dependencies

#### 2. Investigation Methodology
**Process**:
1. **Database Layer**: Check database schema, RLS policies, and data integrity
2. **Provider Layer**: Analyze provider state management and dependencies
3. **Service Layer**: Examine business logic and external service integration
4. **UI Layer**: Verify UI state synchronization and user interactions

#### 3. Fix Validation
**Process**:
1. **Unit Testing**: Verify the fix works in isolation
2. **Integration Testing**: Test the fix in the complete system
3. **Regression Testing**: Ensure the fix doesn't break existing functionality
4. **Performance Testing**: Verify the fix doesn't impact performance

### Common Debugging Patterns

#### 1. Provider State Issues
**Symptoms**: Infinite loops, stale data, provider conflicts

**Debugging Steps**:
```dart
// Add comprehensive provider logging
ref.listen(enhancedCurrentDriverOrderProvider, (previous, next) {
  DriverWorkflowLogger.logProviderState(
    providerName: 'enhancedCurrentDriverOrderProvider',
    state: next.toString(),
    context: 'provider_listener',
  );
});
```

#### 2. Real-time Subscription Issues
**Symptoms**: Missing updates, subscription leaks, performance issues

**Debugging Steps**:
```dart
// Monitor subscription lifecycle
final subscription = supabase
    .from('orders')
    .stream(primaryKey: ['id'])
    .listen((data) {
      DriverWorkflowLogger.logDatabaseOperation(
        operation: 'realtime_update',
        orderId: data.isNotEmpty ? data.first['id'] : 'unknown',
        data: {'update_count': data.length},
        context: 'subscription_listener',
      );
    });
```

#### 3. Database Permission Issues
**Symptoms**: RLS policy violations, unauthorized access errors

**Debugging Steps**:
```sql
-- Check RLS policy evaluation
SELECT * FROM orders WHERE id = 'order-id';  -- Should respect RLS
SET row_security = off;  -- Temporarily disable RLS for debugging
SELECT * FROM orders WHERE id = 'order-id';  -- Should show all data
SET row_security = on;   -- Re-enable RLS
```

## Maintenance Best Practices

### Regular Maintenance Tasks

#### 1. Performance Monitoring
- Monitor workflow operation performance
- Track database query performance
- Monitor real-time subscription performance
- Analyze user interaction patterns

#### 2. Error Analysis
- Review error logs regularly
- Identify recurring error patterns
- Update error handling based on new error types
- Improve error messages based on user feedback

#### 3. Test Maintenance
- Update tests for new features
- Review test coverage regularly
- Update test data and configurations
- Maintain test environment consistency

### Documentation Maintenance

#### 1. Architecture Documentation
- Keep architecture diagrams current
- Document design decisions and rationale
- Update API documentation
- Maintain troubleshooting guides

#### 2. Process Documentation
- Document debugging procedures
- Maintain deployment procedures
- Update testing procedures
- Document configuration management

## Security Best Practices

### Authentication and Authorization

#### 1. Secure Authentication
```dart
// ✅ Recommended: Secure authentication handling
class SecureAuthService {
  Future<AuthResult> authenticateDriver(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user?.userMetadata?['role'] != 'driver') {
        throw AuthException('Invalid user role');
      }
      
      return AuthResult.success(response.user!);
    } catch (e) {
      DriverWorkflowLogger.logError(
        operation: 'driver_authentication',
        error: e.toString(),
        context: 'auth_service',
      );
      return AuthResult.failure(e.toString());
    }
  }
}
```

#### 2. Data Access Control
```dart
// ✅ Recommended: Proper data access validation
class SecureDriverService {
  Future<DriverOrder?> getDriverOrder(String orderId) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw AuthException('User not authenticated');
    }
    
    // RLS policies will ensure driver can only access their orders
    final response = await supabase
        .from('orders')
        .select()
        .eq('id', orderId)
        .eq('assigned_driver_id', user.id)
        .maybeSingle();
    
    return response != null ? DriverOrder.fromJson(response) : null;
  }
}
```

### Data Protection

#### 1. Sensitive Data Handling
- Never log sensitive information (passwords, tokens, personal data)
- Use secure storage for sensitive configuration
- Implement proper data encryption for stored data
- Follow data retention policies

#### 2. Network Security
- Use HTTPS for all network communications
- Implement proper certificate validation
- Use secure authentication tokens
- Implement token refresh mechanisms

This comprehensive best practices guide provides the foundation for building robust, maintainable, and secure driver workflow systems in the GigaEats application.
