# GigaEats Driver Earnings - End-to-End Testing Guide

## 🎯 Overview

This comprehensive guide provides step-by-step instructions for performing end-to-end testing of the GigaEats driver earnings system using Android emulator focus. The testing covers all critical user workflows and system integrations.

## 🚀 Pre-Testing Setup

### 1. Environment Preparation

```bash
# Start Android emulator (emulator-5554)
flutter emulators --launch Pixel_7_API_34

# Verify emulator is running
adb devices

# Install app on emulator
flutter install --device-id emulator-5554

# Start Supabase local development (if testing locally)
supabase start
```

### 2. Test Data Preparation

```sql
-- Create test driver account
INSERT INTO drivers (id, user_id, status, is_active) 
VALUES ('test-driver-123', 'test-user-123', 'approved', true);

-- Create sample earnings data
INSERT INTO driver_earnings (id, driver_id, earnings_type, amount, net_amount, status, created_at)
VALUES 
  ('earning-1', 'test-driver-123', 'delivery_fee', 25.50, 22.50, 'confirmed', NOW()),
  ('earning-2', 'test-driver-123', 'tip', 5.00, 5.00, 'paid', NOW()),
  ('earning-3', 'test-driver-123', 'bonus', 10.00, 10.00, 'confirmed', NOW());
```

### 3. Test Credentials

```
Test Driver Account:
- Email: test.driver@gigaeats.com
- Password: TestPass123!
- Driver ID: test-driver-123
```

## 📋 Testing Checklist

### Phase 1: Authentication & Navigation ✅

#### 1.1 Login Flow
- [ ] App launches successfully on Android emulator
- [ ] Login screen displays with proper Material Design 3 styling
- [ ] Email and password fields accept input
- [ ] Login button triggers authentication
- [ ] Successful login redirects to driver dashboard
- [ ] Error handling for invalid credentials

#### 1.2 Navigation
- [ ] Bottom navigation bar displays correctly
- [ ] Earnings tab is accessible and highlighted
- [ ] Navigation between tabs is smooth
- [ ] Back button behavior is correct
- [ ] Deep linking works for earnings screen

### Phase 2: Earnings Overview ✅

#### 2.1 Overview Cards
- [ ] Animated earnings cards display with smooth transitions
- [ ] Total earnings counter animates from 0 to actual value
- [ ] Delivery count displays correctly
- [ ] Average per delivery calculates accurately
- [ ] Trend indicators show with proper colors (green/red)
- [ ] Cards respond to touch with visual feedback

#### 2.2 Real-time Updates
- [ ] Data loads automatically on screen entry
- [ ] Loading states display during data fetch
- [ ] Real-time updates reflect new earnings
- [ ] Error states handle network failures gracefully
- [ ] Refresh functionality works correctly

### Phase 3: Interactive Charts ✅

#### 3.1 Chart Types
- [ ] Pie chart (Breakdown) displays earnings distribution
- [ ] Line chart (Trends) shows daily earnings over time
- [ ] Bar chart (Performance) compares metrics vs targets
- [ ] Tab switching between chart types works smoothly
- [ ] Charts render correctly with proper colors

#### 3.2 Interactivity
- [ ] Pie chart sections expand on touch
- [ ] Line chart shows tooltips on data points
- [ ] Bar chart displays values on hover/touch
- [ ] Chart animations are smooth and responsive
- [ ] Legend displays correctly for each chart type

### Phase 4: Filtering & Search ✅

#### 4.1 Date Range Filtering
- [ ] Date range picker opens correctly
- [ ] Predefined ranges (This Week, This Month) work
- [ ] Custom date range selection functions
- [ ] Data filters correctly based on selected range
- [ ] Clear filter option resets to default view

#### 4.2 Status Filtering
- [ ] Status dropdown displays all options
- [ ] Filtering by status (Confirmed, Paid, Pending) works
- [ ] Multiple status selection functions
- [ ] Filter combinations work correctly
- [ ] Filter state persists during navigation

#### 4.3 Search Functionality
- [ ] Search bar accepts text input
- [ ] Search filters earnings by description/order ID
- [ ] Search results update in real-time
- [ ] Clear search resets to full list
- [ ] Search works with other filters

### Phase 5: Export Functionality ✅

#### 5.1 Export Options
- [ ] Export widget displays format options (PDF, CSV)
- [ ] Date range selection for export works
- [ ] Export options (Summary, Breakdown, Charts) toggle correctly
- [ ] Export button enables when valid options selected

#### 5.2 PDF Export
- [ ] PDF generation completes successfully
- [ ] PDF contains correct data and formatting
- [ ] PDF includes selected sections (summary, breakdown)
- [ ] File sharing dialog appears
- [ ] PDF can be saved to device storage

#### 5.3 CSV Export
- [ ] CSV generation completes successfully
- [ ] CSV contains all earnings data in correct format
- [ ] CSV headers are properly formatted
- [ ] File can be opened in spreadsheet apps
- [ ] Data integrity maintained in export

### Phase 6: Notifications ✅

#### 6.1 Real-time Notifications
- [ ] Notification badge shows unread count
- [ ] Notification panel displays recent earnings updates
- [ ] Notifications show correct type icons and colors
- [ ] Tap to mark as read functionality works
- [ ] Mark all as read clears unread count

#### 6.2 Notification Types
- [ ] Earnings update notifications display correctly
- [ ] Payment received notifications show proper status
- [ ] Bonus earned notifications highlight bonuses
- [ ] Notification timestamps are accurate
- [ ] Notification metadata displays correctly

### Phase 7: Offline Functionality ✅

#### 7.1 Cache Behavior
- [ ] App works when network is disabled
- [ ] Cached data displays correctly offline
- [ ] Offline indicator shows when disconnected
- [ ] Data remains accessible during network outages
- [ ] Cache expiry handled appropriately

#### 7.2 Sync on Reconnection
- [ ] App detects network reconnection
- [ ] Data syncs automatically when online
- [ ] Conflicts resolved appropriately
- [ ] User notified of sync status
- [ ] Real-time updates resume correctly

### Phase 8: Performance ✅

#### 8.1 Loading Performance
- [ ] Initial app launch < 3 seconds
- [ ] Earnings screen loads < 2 seconds
- [ ] Chart rendering < 1 second
- [ ] Large dataset handling (1000+ records) smooth
- [ ] Memory usage remains stable

#### 8.2 Animation Performance
- [ ] All animations run at 60 FPS
- [ ] No frame drops during transitions
- [ ] Smooth scrolling in large lists
- [ ] Chart interactions responsive
- [ ] Counter animations smooth

### Phase 9: UI/UX Validation ✅

#### 9.1 Material Design 3
- [ ] Color scheme follows Material Design 3
- [ ] Typography uses proper Material text styles
- [ ] Elevation and shadows applied correctly
- [ ] Surface containers used appropriately
- [ ] Interactive elements have proper touch targets

#### 9.2 Accessibility
- [ ] Screen reader compatibility
- [ ] Proper semantic labels
- [ ] Sufficient color contrast
- [ ] Touch targets meet minimum size requirements
- [ ] Focus management works correctly

#### 9.3 Responsive Design
- [ ] Layout adapts to different screen sizes
- [ ] Portrait and landscape orientations supported
- [ ] Text scaling works correctly
- [ ] Charts resize appropriately
- [ ] Navigation remains accessible

### Phase 10: Error Handling ✅

#### 10.1 Network Errors
- [ ] Network timeout handled gracefully
- [ ] Server errors display user-friendly messages
- [ ] Retry mechanisms work correctly
- [ ] Fallback to cached data when appropriate
- [ ] Error recovery after network restoration

#### 10.2 Data Errors
- [ ] Empty data states display helpful messages
- [ ] Malformed data handled without crashes
- [ ] Invalid date ranges prevented
- [ ] Export errors communicated clearly
- [ ] Data validation prevents invalid states

## 🔧 Testing Commands

### Run E2E Tests
```bash
# Run all E2E tests
flutter test integration_test/

# Run specific E2E test
flutter test integration_test/driver_earnings_e2e_test.dart

# Run with verbose output
flutter test integration_test/ --verbose

# Run on specific device
flutter test integration_test/ --device-id emulator-5554
```

### Performance Testing
```bash
# Profile app performance
flutter run --profile --device-id emulator-5554

# Analyze memory usage
flutter run --debug --device-id emulator-5554
# Then use Flutter Inspector for memory analysis

# Test with large datasets
flutter test integration_test/ --dart-define=LARGE_DATASET=true
```

### Network Condition Testing
```bash
# Simulate poor network
adb shell settings put global airplane_mode_on 1
adb shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true

# Restore network
adb shell settings put global airplane_mode_on 0
adb shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false
```

## 📊 Success Criteria

### Functional Requirements ✅
- All user workflows complete successfully
- Data accuracy maintained throughout
- Real-time updates function correctly
- Export functionality works as expected
- Offline mode provides full functionality

### Performance Requirements ✅
- App launch time < 3 seconds
- Screen transitions < 1 second
- Chart rendering < 1 second
- 60 FPS animations maintained
- Memory usage < 200MB

### Quality Requirements ✅
- Zero crashes during testing
- Graceful error handling
- Consistent UI/UX experience
- Accessibility compliance
- Material Design 3 adherence

## 🐛 Issue Reporting

### Bug Report Template
```
**Bug Title**: [Brief description]
**Severity**: Critical/High/Medium/Low
**Device**: Android Emulator (emulator-5554)
**Steps to Reproduce**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Result**: [What should happen]
**Actual Result**: [What actually happened]
**Screenshots**: [Attach if applicable]
**Logs**: [Include relevant logs]
```

### Performance Issue Template
```
**Performance Issue**: [Brief description]
**Metric**: [Loading time/FPS/Memory usage]
**Expected**: [Target performance]
**Actual**: [Measured performance]
**Test Conditions**: [Device, data size, network]
**Profiling Data**: [Attach performance traces]
```

## ✅ Sign-off Checklist

- [ ] All functional tests pass
- [ ] Performance requirements met
- [ ] No critical or high-severity bugs
- [ ] Accessibility requirements satisfied
- [ ] Documentation updated
- [ ] Test results documented
- [ ] Stakeholder approval obtained

---

**Testing Completed By**: [Tester Name]  
**Date**: [Test Date]  
**Environment**: Android Emulator (emulator-5554)  
**App Version**: [Version Number]  
**Test Duration**: [Total testing time]
