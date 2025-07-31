# Driver Dashboard Backend Integration

This document explains the implementation of backend integration for the driver dashboard screen in the GigaEats app.

## Overview

The driver dashboard has been integrated with the Supabase backend to display real-time data including:
- Driver status (online/offline)
- Active orders
- Today's performance summary
- Real-time data updates

> **Note**: The dashboard map tab has been removed as it didn't serve a functional purpose in the driver workflow. The dashboard now focuses on order management, earnings tracking, and profile management. Map functionality is preserved in the navigation features used during order delivery.

## Architecture

### Data Flow
```
UI Components → Providers → Services → Supabase Database
     ↑                                        ↓
     └── Real-time Updates ←── Subscriptions ←┘
```

### Key Components

#### 1. Data Models
- **`DriverDashboardData`**: Main data structure containing all dashboard information
- **`DriverTodaySummary`**: Today's performance metrics
- **`DriverPerformanceMetrics`**: Extended performance data

#### 2. Services
- **`DriverDashboardService`**: Aggregates data from multiple sources
- **`DriverPerformanceService`**: Handles performance calculations
- **`DriverOrderRepository`**: Manages order data

#### 3. Providers
- **`driverDashboardDataProvider`**: Main provider for dashboard data
- **`driverDashboardActionsProvider`**: Actions for user interactions
- Individual providers for specific data points

## Implementation Details

### 1. Dashboard Data Model

```dart
class DriverDashboardData {
  final DriverStatus driverStatus;
  final bool isOnline;
  final List<DriverOrder> activeOrders;
  final DriverTodaySummary todaySummary;
  final DriverPerformanceMetrics? performanceMetrics;
  final DateTime lastUpdated;
}
```

### 2. Dashboard Service

The `DriverDashboardService` aggregates data from multiple sources:

```dart
Future<DriverDashboardData> getDashboardData(String driverId) async {
  // Fetch data concurrently for better performance
  final futures = await Future.wait([
    _getDriverStatus(driverId),
    _getActiveOrders(driverId),
    _getTodaysSummary(driverId),
    _getPerformanceMetrics(driverId),
  ]);
  
  // Combine data into dashboard model
  return DriverDashboardData(...);
}
```

### 3. Provider Integration

The main provider handles async data loading:

```dart
final driverDashboardDataProvider = FutureProvider<DriverDashboardData>((ref) async {
  final driverIdAsync = ref.watch(currentDriverIdProvider);
  final dashboardService = ref.read(driverDashboardServiceProvider);

  return driverIdAsync.when(
    data: (driverId) async {
      if (driverId == null) throw Exception('Driver ID not found');
      return await dashboardService.getDashboardData(driverId);
    },
    loading: () => throw Exception('Loading driver ID'),
    error: (error, stack) => throw Exception('Error getting driver ID: $error'),
  );
});
```

### 4. UI Integration

The dashboard UI consumes data through providers:

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final dashboardDataAsync = ref.watch(driverDashboardDataProvider);
  final dashboardActions = ref.read(driverDashboardActionsProvider);

  return dashboardDataAsync.when(
    data: (dashboardData) => _buildDashboard(dashboardData),
    loading: () => _buildLoadingState(),
    error: (error, stack) => _buildErrorState(error),
  );
}
```

## Features Implemented

### 1. Real Driver Status
- Displays actual driver status from database
- Toggle switch to update status (online/offline)
- Visual indicators with appropriate colors

### 2. Active Orders Display
- Shows real active orders assigned to the driver
- Order count in quick actions
- Order preview cards with real data
- Empty state when no orders

### 3. Today's Summary
- Real-time calculation of today's metrics:
  - Deliveries completed
  - Earnings
  - Success rate
  - Average rating

### 4. Refresh Functionality
- Pull-to-refresh gesture
- Refresh button in app bar
- Automatic data invalidation

### 5. Error Handling
- Loading states during data fetch
- Error states with retry functionality
- Graceful fallbacks for missing data

## Usage Examples

### Basic Usage
```dart
// Watch dashboard data
final dashboardDataAsync = ref.watch(driverDashboardDataProvider);

// Use individual providers for specific data
final activeOrdersCount = ref.watch(activeOrdersCountProvider);
final todaysEarnings = ref.watch(todaysEarningsProvider);
```

### Actions
```dart
// Get dashboard actions
final dashboardActions = ref.read(driverDashboardActionsProvider);

// Update driver status
await dashboardActions.updateDriverStatus(DriverStatus.online);

// Refresh dashboard
await dashboardActions.refreshDashboard();
```

### Refresh Implementation
```dart
RefreshIndicator(
  onRefresh: () async {
    await dashboardActions.refreshDashboard();
  },
  child: SingleChildScrollView(
    child: DashboardContent(),
  ),
);
```

## Performance Considerations

1. **Concurrent Data Fetching**: Multiple data sources are fetched concurrently using `Future.wait()`
2. **Provider Caching**: Riverpod automatically caches provider results
3. **Selective Updates**: Only invalidate specific providers when needed
4. **Error Boundaries**: Each data source has independent error handling

## Testing

The implementation includes:
- Unit tests for services
- Provider tests for state management
- Integration tests for UI components
- Example usage in `driver_dashboard_integration_example.dart`

## Future Enhancements

1. **Real-time Subscriptions**: Add Supabase real-time subscriptions for live updates
2. **Offline Support**: Cache data for offline viewing
3. **Performance Metrics**: Add more detailed analytics
4. **Push Notifications**: Integrate with notification system

## Files Modified/Created

### Created:
- `lib/features/drivers/data/models/driver_dashboard_data.dart`
- `lib/features/drivers/data/services/driver_dashboard_service.dart`
- `lib/features/drivers/presentation/providers/driver_dashboard_provider.dart`
- `lib/features/drivers/presentation/examples/driver_dashboard_integration_example.dart`

### Modified:
- `lib/features/drivers/presentation/screens/driver_dashboard.dart`

## Dependencies

The implementation uses existing services and models:
- `DriverPerformanceService`
- `DriverOrderRepository`
- `DriverOrder` model
- `DriverStatus` enum
- Riverpod for state management
- Supabase for backend integration
