# Schedule Order Functionality Test Plan

## Overview
This document outlines the testing plan for the newly implemented schedule order functionality in the GigaEats customer interface.

## Implementation Status

### ✅ Completed Components

1. **Database Schema**
   - Created migration `20250616000001_add_scheduled_delivery_support.sql`
   - Added `scheduled_delivery_time` field to orders table
   - Updated validation functions to handle scheduled orders
   - Enhanced order status change handling for scheduled orders

2. **Order Model Updates**
   - Added `scheduledDeliveryTime` field to Order class
   - Updated constructor, copyWith, and props
   - Added helper methods: `isScheduledOrder`, `effectiveDeliveryTime`

3. **Frontend Components**
   - Created `ScheduleTimePicker` widget with comprehensive validation
   - Updated customer checkout screen with schedule time display
   - Updated customer cart screen with schedule time selection
   - Added proper time formatting and validation

4. **Backend Integration**
   - Updated customer order service to handle scheduled delivery time
   - Modified Edge Function `validate-order-v3` to validate scheduled orders
   - Added business hours and advance notice validation

### 🔄 Pending Items

1. **Database Migration**
   - Migration needs to be applied to remote database
   - Current migration conflicts need to be resolved

2. **Vendor Integration**
   - Schedule time picker needs vendor business hours integration
   - Vendor-specific scheduling constraints

## Test Cases

### Test Case 1: Schedule Time Picker UI
**Objective**: Verify the schedule time picker displays correctly and validates input

**Steps**:
1. Navigate to customer cart screen
2. Select "Scheduled" delivery method
3. Tap on "Select delivery time"
4. Verify schedule time picker dialog opens
5. Test date selection (today, tomorrow, future dates)
6. Test time selection with validation
7. Verify error messages for invalid times

**Expected Results**:
- Schedule time picker opens with proper UI
- Date selection works for future dates only
- Time validation enforces 8 AM - 10 PM hours
- 2-hour advance notice validation works
- Error messages are clear and helpful

### Test Case 2: Schedule Order Creation
**Objective**: Verify scheduled orders can be created successfully

**Steps**:
1. Add items to cart
2. Select "Scheduled" delivery method
3. Set a valid scheduled delivery time
4. Complete checkout process
5. Verify order is created with scheduled time

**Expected Results**:
- Order creation succeeds with scheduled time
- Order shows as scheduled in order list
- Scheduled time is properly stored and displayed

### Test Case 3: Validation Rules
**Objective**: Test all validation rules for scheduled orders

**Test Scenarios**:
- Schedule time in the past (should fail)
- Schedule time less than 2 hours ahead (should fail)
- Schedule time outside business hours (should fail)
- Valid scheduled time (should succeed)

### Test Case 4: Order Management Integration
**Objective**: Verify scheduled orders integrate properly with order management

**Steps**:
1. Create scheduled orders
2. Check vendor dashboard shows scheduled orders
3. Verify driver interface handles scheduled orders
4. Test order status transitions for scheduled orders

## Manual Testing Instructions

### Prerequisites
1. Ensure database migration is applied
2. Have test customer account with addresses
3. Have test vendor with menu items
4. Access to customer interface

### Testing Steps

#### 1. Basic Schedule Functionality
```
1. Login as customer
2. Add items to cart from a vendor
3. Go to cart screen
4. Select "Scheduled" delivery method
5. Verify "Scheduled Time" section appears
6. Tap "Select delivery time"
7. Test various date/time combinations
8. Verify validation messages
9. Complete order with valid scheduled time
```

#### 2. Edge Cases Testing
```
1. Try scheduling for past time
2. Try scheduling less than 2 hours ahead
3. Try scheduling outside business hours (before 8 AM, after 10 PM)
4. Try scheduling on different days
5. Verify all validation messages are appropriate
```

#### 3. Integration Testing
```
1. Create scheduled order
2. Check order appears in customer orders
3. Verify scheduled time is displayed correctly
4. Check vendor dashboard shows scheduled order
5. Verify order status workflow works
```

## Known Issues & Limitations

1. **Migration Conflicts**: Database migration needs to be resolved before full testing
2. **Vendor Business Hours**: Schedule picker doesn't yet integrate with specific vendor hours
3. **Timezone Handling**: Currently assumes Malaysian timezone
4. **Driver Interface**: Scheduled orders may need special handling in driver interface

## Success Criteria

- [ ] Schedule time picker works correctly with validation
- [ ] Scheduled orders can be created successfully
- [ ] All validation rules work as expected
- [ ] Scheduled orders integrate with existing order management
- [ ] UI displays scheduled times in user-friendly format
- [ ] Backend properly stores and validates scheduled delivery times

## Next Steps

1. **Resolve Migration Conflicts**: Apply database migration to add scheduled_delivery_time field
2. **Vendor Integration**: Add vendor business hours to schedule picker
3. **Driver Interface Updates**: Ensure drivers can handle scheduled orders appropriately
4. **Testing**: Complete comprehensive testing once migration is applied
5. **Documentation**: Update user documentation with scheduling feature

## Files Modified

### Database
- `supabase/migrations/20250616000001_add_scheduled_delivery_support.sql`
- `supabase/functions/validate-order-v3/index.ts`

### Models
- `lib/features/orders/data/models/order.dart`

### UI Components
- `lib/features/customers/presentation/widgets/schedule_time_picker.dart`
- `lib/features/customers/presentation/screens/customer_checkout_screen.dart`
- `lib/features/customers/presentation/screens/customer_cart_screen.dart`

### Services
- `lib/features/customers/data/services/customer_order_service.dart`

### Providers
- `lib/features/customers/presentation/providers/customer_cart_provider.dart` (existing)

## Conclusion

The schedule order functionality has been successfully implemented with comprehensive validation and user-friendly UI. The main remaining task is resolving the database migration conflicts to enable full testing and deployment.
