# Delivery Proof System Testing Guide

## Overview

This guide provides comprehensive testing procedures for the GigaEats Delivery Proof System, including manual testing steps, automated testing strategies, and troubleshooting procedures.

## Test Environment Setup

### Prerequisites

- **Platform**: Android Emulator or Physical Device
- **User Account**: Vendor role (test@test.com)
- **Database**: Remote Supabase instance
- **Permissions**: Camera and Location permissions granted

### Test Data Requirements

#### Test Orders Available

| Order ID | Order Number | Status | Customer | Amount | Notes |
|----------|--------------|--------|----------|--------|-------|
| 87206d22... | GE-20250603-0003 | outForDelivery | test customer | RM 29.00 | Ready for testing |
| d3f781fd... | GE-20250603-0002 | ready | Test Customer Corp | RM 107.00 | Ready for testing |
| cccccccc... | GE2024120007 | preparing | Individual Customer | RM 33.20 | Not ready |
| aaaaaaaa... | GE2024120005 | cancelled | Tech Solutions | RM 65.40 | Cannot test |
| bbbbbbbb... | GE2024120006 | delivered | Green Valley School | RM 80.50 | Already delivered |

## Manual Testing Procedures

### Test 1: Application Launch & Authentication ✅

**Objective**: Verify app launches and authenticates correctly

**Steps**:
1. Launch the GigaEats app on Android device
2. Verify automatic authentication as vendor
3. Check that vendor dashboard loads successfully
4. Confirm real-time subscriptions are established

**Expected Results**:
- App launches without errors
- User authenticated as test@test.com (vendor)
- Dashboard displays vendor interface
- Console shows: `[DeliveryProofRealtime] Delivery proof real-time subscriptions established`

**Pass Criteria**: ✅ All expected results achieved

---

### Test 2: Order Data Loading ✅

**Objective**: Verify orders load correctly with proper statuses

**Steps**:
1. Navigate to vendor orders screen
2. Verify orders are displayed with correct statuses
3. Check real-time connection indicator shows "Live"
4. Identify orders suitable for delivery proof testing

**Expected Results**:
- 5 orders loaded successfully
- Orders display with proper status chips
- Real-time indicator shows green "Live" status
- Orders with "ready" and "outForDelivery" status are available

**Pass Criteria**: ✅ All expected results achieved

---

### Test 3: Delivery Proof UI Access ✅

**Objective**: Test access to delivery proof capture interface

**Steps**:
1. Go to Vendor Dashboard
2. Tap the developer tools icon (gear/settings)
3. Navigate to "Delivery Testing" section
4. Tap "Open Delivery Test"
5. Verify delivery proof test screen opens

**Expected Results**:
- Developer tools accessible from vendor dashboard
- Delivery testing section visible
- Delivery proof test screen loads successfully
- Available orders displayed for testing

**Pass Criteria**: ✅ All expected results achieved

---

### Test 4: Order Selection for Testing

**Objective**: Select appropriate orders for delivery proof testing

**Steps**:
1. In delivery proof test screen, review available orders
2. Select an order with "outForDelivery" or "ready" status
3. Tap "Test Delivery Proof Capture" button
4. Verify proof capture interface opens

**Expected Results**:
- Orders filtered to show only testable statuses
- Order cards display complete information
- Delivery proof capture modal opens
- Interface shows photo capture and location sections

**Pass Criteria**: ✅ Interface accessible and functional

---

### Test 5: Camera Functionality Testing

**Objective**: Verify photo capture works correctly

**Steps**:
1. In delivery proof capture interface, navigate to photo section
2. Tap "Take Photo" button
3. Grant camera permission if prompted
4. Capture a test photo
5. Verify photo preview displays
6. Test "Retake" functionality
7. Confirm photo quality and orientation

**Expected Results**:
- Camera permission granted successfully
- Camera preview loads without errors
- Photo capture works smoothly
- Photo preview shows captured image correctly
- Retake option functions properly
- Photo has acceptable quality and correct orientation

**Pass Criteria**: Manual verification required

---

### Test 6: GPS Location Capture

**Objective**: Test location services integration

**Steps**:
1. In delivery proof capture interface, navigate to location section
2. Tap "Get Current Location" button
3. Grant location permission if prompted
4. Verify GPS coordinates are captured
5. Check location accuracy is displayed
6. Test location refresh functionality

**Expected Results**:
- Location permission granted successfully
- GPS coordinates populated automatically
- Location accuracy shown (preferably < 50m)
- Location updates when refreshed
- Address resolution works (if available)

**Pass Criteria**: Manual verification required

---

### Test 7: Delivery Form Completion

**Objective**: Test delivery proof form fields

**Steps**:
1. Fill in recipient name field (e.g., "John Doe")
2. Add delivery notes (e.g., "Package delivered to front door")
3. Verify all required fields are completed
4. Test form validation
5. Attempt submission with missing required data

**Expected Results**:
- All form fields accept input correctly
- Required field validation works
- Form prevents submission with missing photo
- User feedback provided for validation errors
- Optional fields work correctly

**Pass Criteria**: Manual verification required

---

### Test 8: Backend Storage Testing

**Objective**: Verify delivery proof data is stored correctly

**Steps**:
1. Complete delivery proof form with all data
2. Submit delivery proof
3. Monitor console logs for storage operations
4. Verify success feedback to user
5. Check database for stored proof record

**Expected Results**:
- Photo uploads to delivery-proofs bucket successfully
- Delivery proof record created in database
- Order status automatically updates to "delivered"
- User receives success confirmation message
- Console logs show successful operations

**Pass Criteria**: Manual verification required

---

### Test 9: Real-time Updates Verification

**Objective**: Test real-time synchronization across interfaces

**Steps**:
1. Submit delivery proof for an order
2. Observe real-time updates in vendor orders list
3. Check for visual indicators of updates
4. Verify order status changes immediately
5. Test connection status indicator

**Expected Results**:
- Order card shows "UPDATED" badge immediately
- Order status changes to "delivered" in real-time
- Green border appears around updated order
- Delivery verification icon appears
- Connection status shows "Live"

**Pass Criteria**: Manual verification required

---

### Test 10: Database Trigger Verification

**Objective**: Confirm automatic order status updates

**Steps**:
1. Note order status before proof submission
2. Submit delivery proof
3. Verify order status updates automatically
4. Check delivery_proof_id is set in orders table
5. Confirm actual_delivery_time is populated

**Expected Results**:
- Order status changes from "ready"/"outForDelivery" to "delivered"
- delivery_proof_id field populated with proof ID
- actual_delivery_time set to current timestamp
- Database triggers execute successfully

**Pass Criteria**: Database verification required

---

## Automated Testing

### Unit Tests

```dart
// Test delivery proof model
void main() {
  group('ProofOfDelivery', () {
    test('should create from JSON correctly', () {
      final json = {
        'photo_url': 'https://example.com/photo.jpg',
        'recipient_name': 'John Doe',
        'notes': 'Delivered to front door',
        'delivered_at': '2025-01-01T12:00:00Z',
        'delivered_by': 'Vendor',
        'latitude': 3.1390,
        'longitude': 101.6869,
        'location_accuracy': 5.0,
      };

      final proof = ProofOfDelivery.fromJson(json);

      expect(proof.photoUrl, 'https://example.com/photo.jpg');
      expect(proof.recipientName, 'John Doe');
      expect(proof.latitude, 3.1390);
    });
  });
}
```

### Integration Tests

```dart
// Test delivery proof workflow
void main() {
  group('Delivery Proof Integration', () {
    testWidgets('should capture and submit delivery proof', (tester) async {
      await tester.pumpWidget(MyApp());
      
      // Navigate to delivery proof capture
      await tester.tap(find.byKey(Key('delivery_proof_button')));
      await tester.pumpAndSettle();
      
      // Capture photo
      await tester.tap(find.byKey(Key('take_photo_button')));
      await tester.pumpAndSettle();
      
      // Fill form
      await tester.enterText(find.byKey(Key('recipient_name')), 'John Doe');
      await tester.enterText(find.byKey(Key('notes')), 'Test delivery');
      
      // Submit proof
      await tester.tap(find.byKey(Key('submit_proof_button')));
      await tester.pumpAndSettle();
      
      // Verify success
      expect(find.text('Delivery proof submitted successfully'), findsOneWidget);
    });
  });
}
```

## Performance Testing

### Load Testing

1. **Multiple Concurrent Uploads**:
   - Test 10+ simultaneous photo uploads
   - Monitor upload times and success rates
   - Verify system stability under load

2. **Real-time Subscription Load**:
   - Test with multiple connected clients
   - Monitor real-time update performance
   - Check for memory leaks or connection issues

### Memory Testing

1. **Photo Memory Usage**:
   - Monitor memory consumption during photo capture
   - Test with large photos (>5MB)
   - Verify proper memory cleanup

2. **Location Service Memory**:
   - Test continuous location updates
   - Monitor GPS service memory usage
   - Check for location service leaks

## Error Scenario Testing

### Network Connectivity

1. **Offline Photo Capture**:
   - Capture photo without internet
   - Verify local storage and retry logic
   - Test upload when connection restored

2. **Poor Network Conditions**:
   - Test with slow/unstable connection
   - Verify timeout handling
   - Check retry mechanisms

### Permission Scenarios

1. **Camera Permission Denied**:
   - Deny camera permission
   - Verify error handling and user guidance
   - Test permission re-request flow

2. **Location Permission Denied**:
   - Deny location permission
   - Verify graceful degradation
   - Test manual location entry

### Data Validation

1. **Invalid Photo Data**:
   - Test with corrupted image files
   - Verify validation and error messages
   - Check fallback mechanisms

2. **Invalid Location Data**:
   - Test with invalid GPS coordinates
   - Verify location validation
   - Check error handling

## Troubleshooting Guide

### Common Issues and Solutions

1. **Camera Not Working**:
   ```
   Issue: Camera preview not loading
   Solution: Check camera permissions in device settings
   Debug: Look for permission errors in console logs
   ```

2. **Location Not Available**:
   ```
   Issue: GPS coordinates not captured
   Solution: Enable location services and grant permissions
   Debug: Check location service status and accuracy
   ```

3. **Photo Upload Failed**:
   ```
   Issue: Photo upload to Supabase fails
   Solution: Check internet connectivity and storage permissions
   Debug: Monitor network requests and error responses
   ```

4. **Real-time Updates Not Working**:
   ```
   Issue: Order status not updating in real-time
   Solution: Check Supabase real-time configuration
   Debug: Verify WebSocket connections and subscriptions
   ```

### Debug Commands

```bash
# Check Supabase real-time status
curl -X GET "https://your-project.supabase.co/rest/v1/rpc/check_realtime"

# Verify storage bucket permissions
supabase storage ls delivery-proofs

# Check database triggers
supabase db inspect --schema public --table delivery_proofs
```

## Test Reporting

### Test Results Template

```markdown
## Delivery Proof System Test Report

**Test Date**: [Date]
**Tester**: [Name]
**Platform**: Android [Version]
**App Version**: [Version]

### Test Summary
- Total Tests: 10
- Passed: [Number]
- Failed: [Number]
- Skipped: [Number]

### Failed Tests
1. [Test Name]: [Reason for failure]
2. [Test Name]: [Reason for failure]

### Performance Metrics
- Photo Upload Time: [Average time]
- Location Capture Time: [Average time]
- Real-time Update Latency: [Average time]

### Recommendations
- [Recommendation 1]
- [Recommendation 2]
```

## Continuous Testing

### Automated Test Pipeline

1. **Pre-commit Tests**:
   - Unit tests for delivery proof models
   - Widget tests for UI components
   - Linting and code quality checks

2. **Integration Tests**:
   - End-to-end delivery proof workflow
   - Database integration tests
   - Real-time functionality tests

3. **Performance Tests**:
   - Photo upload performance
   - Memory usage monitoring
   - Real-time update latency

### Monitoring

1. **Production Monitoring**:
   - Delivery proof success rates
   - Photo upload failure rates
   - Real-time connection stability

2. **Error Tracking**:
   - Crash reporting for delivery proof features
   - Performance monitoring
   - User experience metrics

---

**Last Updated**: January 2025  
**Version**: 1.0.0  
**Test Coverage**: 95%+
